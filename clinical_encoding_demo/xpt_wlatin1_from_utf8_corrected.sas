/*=============================================================================
  Create a SAS V5 XPT containing WLATIN1 bytes from a UTF-8 SAS session

  Why the original direct PROC COPY can fail
  ------------------------------------------
  The XPORT engine does not store an encoding attribute. If a UTF-8 session
  writes directly to an XPORT libref, the XPT contains UTF-8 bytes. A WLATIN1
  reader can then display mojibake (for example, cafe with an accented e can
  appear as caf followed by two incorrect characters).

  Correct method
  --------------
  1. Write a normal SAS data set through OUTENCODING=WLATIN1.
  2. Read that staged data set with ENCODING='ANY' so CEDA does not transcode
     the bytes back to UTF-8.
  3. Write those unchanged bytes with the XPORT engine.

  Important
  ---------
  * This creates V5 XPT files. Check the current submission specification.
  * V5 limits checked below: variable name <= 8, label <= 40, character
    length <= 200.
  * Characters not representable in WLATIN1 must be corrected or replaced
    according to the study/SOP before release.
=============================================================================*/

%macro xpt_wlatin1(
    lib=WORK,
    mem=,
    xptdir=,
    target=WLATIN1
  );

  %local _mem _xptfile _stage _stage_rc _write_rc _badmeta;
  %let _mem=%upcase(&mem);

  %if %superq(mem)= %then %do;
    %put ERROR: MEM= is required.;
    %goto exit;
  %end;
  %if %superq(xptdir)= %then %do;
    %put ERROR: XPTDIR= is required.;
    %goto exit;
  %end;
  %if not %sysfunc(exist(&lib..&_mem)) %then %do;
    %put ERROR: Input data set &lib..&_mem does not exist.;
    %goto exit;
  %end;

  %put NOTE: SAS session encoding is &sysencoding.;
  %put NOTE: Creating a V5 XPT with &target bytes from &lib..&_mem.;

  /* Check the structural limits of the V5 transport format. */
  proc sql noprint;
    create table work._xpt_v5_issues as
    select libname, memname, name, type, length, label,
           case
             when lengthn(name) > 8 then 'Variable name exceeds 8 characters'
             when lengthn(label) > 40 then 'Variable label exceeds 40 characters'
             when upcase(type) = 'CHAR' and length > 200
               then 'Character length exceeds 200 bytes'
             else 'Other V5 metadata issue'
           end as issue length=48
    from dictionary.columns
    where libname=upcase("&lib")
      and memname=upcase("&_mem")
      and (lengthn(name) > 8
           or lengthn(label) > 40
           or (upcase(type)='CHAR' and length > 200));
    select count(*) into :_badmeta trimmed
    from work._xpt_v5_issues;
  quit;

  %if &_badmeta > 0 %then %do;
    %put ERROR: &_badmeta V5 metadata issue(s) found. XPT not created.;
    proc print data=work._xpt_v5_issues noobs; run;
    %goto exit;
  %end;

  /* Create the output directory if needed. */
  options dlcreatedir;
  libname _xptdir "&xptdir";
  libname _xptdir clear;

  /* Use a separate physical staging library so OUTENCODING= is applied. */
  %let _stage=%sysfunc(pathname(work))/xpt_stage_%sysfunc(lowcase(&_mem));
  libname _stg "&_stage" outencoding=&target;
  options nodlcreatedir;

  /* Step 1: UTF-8 -> WLATIN1. Review the log for unrepresentable values. */
  data _stg.&_mem;
    set &lib..&_mem;
  run;
  %let _stage_rc=&syserr;

  %if &_stage_rc ne 0 %then %do;
    %put ERROR: Staging/transcoding returned SYSERR=&_stage_rc..;
    %put ERROR: Review the log and correct characters not representable in &target..;
    libname _stg clear;
    %goto exit;
  %end;

  /* Remove an earlier file so the new XPT starts as a clean transport file. */
  %let _xptfile=&xptdir/%sysfunc(lowcase(&_mem)).xpt;
  filename _oldxpt "&_xptfile";
  data _null_;
    if fexist('_oldxpt') then do;
      rc=fdelete('_oldxpt');
      if rc ne 0 then put 'ERROR: Could not delete prior XPT file. ' rc=;
    end;
  run;
  filename _oldxpt clear;

  /* Step 2: pass the staged WLATIN1 bytes unchanged to the XPORT engine. */
  libname _xpt xport "&_xptfile";
  data _xpt.&_mem;
    set _stg.&_mem(encoding='any');
  run;
  %let _write_rc=&syserr;
  libname _xpt clear;

  %if &_write_rc ne 0 %then %do;
    %put ERROR: Writing the XPT returned SYSERR=&_write_rc..;
  %end;
  %else %do;
    %put NOTE: Created &_xptfile with &target bytes.;
  %end;

  /* Remove staged data. */
  proc datasets lib=_stg nolist kill; quit;
  libname _stg clear;

%exit:
%mend xpt_wlatin1;


/* Optional first-pass verification for one character variable.
   The XPT is read without transcoding and KCVT converts the displayed copy
   from the target encoding to UTF-8 for the SAS Studio Results viewer. */
%macro verify_xpt(
    file=,
    mem=,
    charvar=,
    target=WLATIN1,
    obs=10
  );
  libname _xin xport "&file" access=readonly;

  data work.xpt_verify;
    set _xin.%upcase(&mem)(encoding='any', obs=&obs);
    length _as_utf8 $800 _hex $1600;
    _as_utf8=kcvt(&charvar, "&target", 'utf-8');
    _hex=put(&charvar, $hex400.);
  run;

  title "XPT byte check: &mem..&charvar";
  proc print data=work.xpt_verify noobs;
    var &charvar _as_utf8 _hex;
  run;
  title;

  libname _xin clear;
%mend verify_xpt;


/* Example calls: update paths and library names for the study. */
/*
%xpt_wlatin1(lib=SDTM, mem=DM,   xptdir=/study/xyz/xpt);
%xpt_wlatin1(lib=SDTM, mem=AE,   xptdir=/study/xyz/xpt);
%xpt_wlatin1(lib=ADAM, mem=ADSL, xptdir=/study/xyz/xpt);
%xpt_wlatin1(lib=ADAM, mem=ADAE, xptdir=/study/xyz/xpt);
%xpt_wlatin1(lib=ADAM, mem=ADLB, xptdir=/study/xyz/xpt);

%verify_xpt(file=/study/xyz/xpt/ae.xpt,
            mem=AE, charvar=AETERM, target=WLATIN1);
*/
