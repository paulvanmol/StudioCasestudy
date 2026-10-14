/*****************************************************************************
  Program : xpt_latin1_demo.sas
  Purpose : Create SAS V5 transport (XPT) files whose character data is
            encoded in WLATIN1 (Windows-1252) or LATIN1 (ISO-8859-1)
            from a UTF-8 SAS session.
  Runs in : SAS Studio on SAS Viya, SAS Viya Workbench (SAS kernel),
            any SAS 9.4 session started with ENCODING=UTF-8
  Verify  : verify_xpt_pcsas.sas  (run in PC SAS, English / WLATIN1 session)

  Sections
    0. Parameters and session check
    1. Sample UTF-8 SDTM AE data (good + bad rows)
    2. DEMO 1 - The problem: a naive XPT from a UTF-8 session
    3. DEMO 2 - Pre-check: can every value be represented in the target?
    4. DEMO 3 - Create the WLATIN1/LATIN1 XPT
    5. DEMO 4 - Verify the XPT inside SAS Studio / Workbench
*****************************************************************************/

/*============================================================================
  0. Parameters and session check
============================================================================*/
/* Folder that you can download from (SAS Studio: Explorer > Download file,
   Workbench: Explorer > right-click > Download).
   SAS Studio example : ~/xpt_demo
   Workbench example  : /workspaces/myfolder/xpt_demo                       */
%let outdir = ~/xpt_demo;

/* Target encoding of the XPT character data
   wlatin1 = Windows-1252 = what PC SAS (English) uses on Windows  (default)
   latin1  = ISO-8859-1   = no curly quotes, en/em dash, euro sign          */
%let target = wlatin1;

options dlcreatedir validvarname=upcase;
libname _mk "&outdir";
libname _mk clear;

%put NOTE: Session encoding = &sysencoding;
%put NOTE: XPT target encoding = &target;
%put NOTE: XPT output folder = &outdir;

/*============================================================================
  1. Sample UTF-8 data
     WORK.AE      : every value can be represented in WLATIN1
     WORK.AE_BAD  : contains Greek alpha and the >= sign (not in WLATIN1)
============================================================================*/
data work.ae(label='Adverse Events');
  length STUDYID $12 DOMAIN $2 USUBJID $20 AESEQ 8 AETERM $100 AELOC $40;
  label STUDYID = 'Study Identifier'
        DOMAIN  = 'Domain Abbreviation'
        USUBJID = 'Unique Subject Identifier'
        AESEQ   = 'Sequence Number'
        AETERM  = 'Reported Term for the Adverse Event'
        AELOC   = 'Location of Event';
  infile datalines dlm='|' truncover;
  input STUDYID :$12. DOMAIN :$2. USUBJID :$20. AESEQ AETERM :$100. AELOC :$40.;
datalines;
XPT01|AE|XPT01-001|1|Céphalée après café|Liège
XPT01|AE|XPT01-002|1|Übelkeit nach Mahlzeit|München
XPT01|AE|XPT01-003|1|Creatinine 82 µmol/L|Göteborg
XPT01|AE|XPT01-004|1|Patient’s rash – mild|Bruxelles
XPT01|AE|XPT01-005|1|Headache|Leuven
;
run;

data work.ae_bad(label='Adverse Events (contains non-WLATIN1 characters)');
  set work.ae;
  if USUBJID = 'XPT01-005' then AETERM = 'α-blocker reaction, ALT ≥ 3x ULN';
run;

/*============================================================================
  2. DEMO 1 - The problem
     The V5 XPORT format has NO encoding attribute. The XPORT engine writes
     the bytes exactly as they are in the session. In a UTF-8 session the
     é in "café" is written as two bytes C3 A9 -> PC SAS shows "cafÃ©".
============================================================================*/
libname naive xport "&outdir/ae_naive_utf8.xpt";
data naive.ae;
  set work.ae;
run;
libname naive clear;

title "DEMO 1 - Bytes in the naive XPT (UTF-8 session)";
libname naive xport "&outdir/ae_naive_utf8.xpt" access=readonly;
data _null_;
  set naive.ae(obs=4);
  put USUBJID= / AETERM= / AETERM= $hex60. /;
run;
libname naive clear;
title;

/*============================================================================
  3. DEMO 2 - Pre-check macro
     a) Values   : UTF-8 -> target -> UTF-8 round trip must give the same value
     b) Metadata : V5 limits (names <= 8, labels <= 40, char length <= 200)
                   and ASCII-only names and labels
============================================================================*/
%macro enc_check(lib=WORK, mem=, target=wlatin1, out=work.enc_issues);
  %local n_val n_meta;

  /* a) Character values that cannot survive transcoding */
  data &out(keep=_OBS _VAR _VALUE _HEX);
    set &lib..&mem;
    array _c{*} _character_;          /* defined BEFORE helper variables */
    length _VAR $32 _VALUE $200 _HEX $400 _rt $32767;
    _OBS = _n_;
    do _i = 1 to dim(_c);
      if not missing(_c{_i}) then do;
        _rt = kcvt(kcvt(_c{_i}, 'utf-8', "&target"), "&target", 'utf-8');
        if trim(_rt) ne trim(_c{_i}) then do;
          _VAR   = vname(_c{_i});
          _VALUE = _c{_i};
          _HEX   = put(trim(_c{_i}), $hex400.);
          output;
        end;
      end;
    end;
  run;

  /* b) V5 transport and ASCII metadata rules */
  proc sql;
    create table &out._meta as
    select name, type, length, label,
           case when length(name) > 8                      then 'Name > 8'
                when length(label) > 40                    then 'Label > 40 bytes'
                when type = 'char' and length > 200        then 'Char length > 200'
                when prxmatch('/[^\x20-\x7E]/', trim(label)) then 'Non-ASCII label'
                else ' ' end as issue length=20
    from dictionary.columns
    where libname = upcase("&lib") and memname = upcase("&mem")
      and calculated issue ne ' ';
  quit;

  proc sql noprint;
    select count(*) into :n_val  trimmed from &out;
    select count(*) into :n_meta trimmed from &out._meta;
  quit;

  %if &n_val > 0 %then %do;
    %put ERROR: [enc_check] &n_val value(s) in &lib..&mem cannot be represented in %upcase(&target). See &out..;
    title "Values in &lib..&mem that are not representable in %upcase(&target)";
    proc print data=&out noobs; run;
    title;
  %end;
  %else %put NOTE: [enc_check] All character values in &lib..&mem are representable in %upcase(&target).;

  %if &n_meta > 0 %then %do;
    %put WARNING: [enc_check] &n_meta metadata issue(s) for V5 transport. See &out._meta.;
    title "V5 / ASCII metadata issues in &lib..&mem";
    proc print data=&out._meta noobs; run;
    title;
  %end;
  %else %put NOTE: [enc_check] Metadata of &lib..&mem complies with V5 transport limits.;
%mend enc_check;

%enc_check(lib=WORK, mem=AE,     target=&target, out=work.issues_ae)
%enc_check(lib=WORK, mem=AE_BAD, target=&target, out=work.issues_ae_bad)

/*============================================================================
  4. DEMO 3 - Create the WLATIN1 / LATIN1 XPT
     Step 4a: write a staging copy through a library with OUTENCODING=&target
              -> SAS transcodes UTF-8 to the target and reports lost characters
     Step 4b: copy the staged bytes into the XPT with ENCODING='ANY'
              -> no transcoding back to UTF-8, the target bytes land in the XPT
============================================================================*/
%macro xpt_latin1(lib=WORK, mem=, xptdir=, target=wlatin1);
  %local stage dsid dslabel lblopt rc xptfile;
  %let stage   = %sysfunc(pathname(WORK))/xpt_stage_&target;
  %let xptfile = &xptdir/%lowcase(&mem).xpt;

  /* keep the data set label */
  %let dsid    = %sysfunc(open(&lib..&mem));
  %let dslabel = %qsysfunc(attrc(&dsid, LABEL));
  %let rc      = %sysfunc(close(&dsid));
  %if %length(&dslabel) %then %let lblopt = (label="&dslabel");
  %else %let lblopt = ;

  /* 4a. transcode UTF-8 -> target into a staging library */
  options dlcreatedir;
  libname _stg "&stage" outencoding=&target;
  data _stg.&mem;
    set &lib..&mem;
  run;
  %if &syserr > 0 %then %do;
    %put ERROR: [xpt_latin1] Transcoding of &lib..&mem to %upcase(&target) failed or lost data. XPT not created.;
    %put ERROR- Run %nrstr(%enc_check) to list the offending values.;
    libname _stg clear;
    %return;
  %end;

  /* 4b. write the raw target bytes to the V5 transport file */
  libname _xpt xport "&xptfile";
  data _xpt.&mem %unquote(&lblopt);
    set _stg.&mem(encoding='any');
  run;
  %let rc = &syserr;
  libname _xpt clear;
  libname _stg clear;

  %if &rc > 0 %then %put ERROR: [xpt_latin1] Writing &xptfile failed (SYSERR=&rc).;
  %else %put NOTE: [xpt_latin1] &xptfile created with %upcase(&target) character data.;
%mend xpt_latin1;

/* Good data: XPT is created */
%xpt_latin1(lib=WORK, mem=AE,     xptdir=&outdir, target=&target)

/* Bad data: macro stops and no XPT is written (expected ERROR in the log) */
%xpt_latin1(lib=WORK, mem=AE_BAD, xptdir=&outdir, target=&target)

/*============================================================================
  5. DEMO 4 - Verify the XPT inside SAS Studio / Workbench
     a) First record must be the V5 library header (not CPORT, not V8)
     b) Read the XPT back: the XPORT engine returns the stored bytes as-is,
        so we can inspect them byte by byte in the UTF-8 session.
        - _NONASCII > 0 and _UTF8SEQ = 0  -> single-byte Latin data  (good)
        - _UTF8SEQ > 0                    -> UTF-8 bytes leaked       (bad)
        - _AS_UTF8 shows the value converted back for human reading
============================================================================*/
%macro xpt_verify(file=, mem=, target=wlatin1);
  %local n_nonascii n_utf8;

  /* a) header check */
  data _null_;
    infile "&file" recfm=n;
    input hdr $char80.;
    if hdr =: 'HEADER RECORD*******LIBRARY HEADER RECORD!!!!!!!' then
      put "NOTE: [xpt_verify] &file is a SAS V5 XPORT transport file.";
    else if hdr =: 'HEADER RECORD*******LIBV8' then
      put "WARNING: [xpt_verify] &file is a V8 transport file (not V5).";
    else
      put "ERROR: [xpt_verify] &file is not an XPORT file (CPORT file?).";
    stop;
  run;

  /* b) byte inspection of every character value */
  libname _v xport "&file" access=readonly;
  data work.xpt_verify(keep=_OBS _VAR _BYTES _NONASCII _UTF8SEQ _HEX _AS_UTF8);
    set _v.&mem;
    array _c{*} _character_;
    length _VAR $32 _HEX $400 _AS_UTF8 $400;
    _OBS = _n_;
    do _i = 1 to dim(_c);
      _NONASCII = 0;
      _UTF8SEQ  = 0;
      _BYTES    = lengthn(_c{_i});
      do _j = 1 to _BYTES;
        _b = rank(substr(_c{_i}, _j, 1));               /* byte value 0-255 */
        if _b >= 128 then _NONASCII = _NONASCII + 1;
        if _j < _BYTES then do;
          _b2 = rank(substr(_c{_i}, _j + 1, 1));
          if 194 <= _b <= 244 and 128 <= _b2 <= 191 then _UTF8SEQ = _UTF8SEQ + 1;
        end;
      end;
      if _NONASCII > 0 then do;
        _VAR     = vname(_c{_i});
        _HEX     = put(trim(_c{_i}), $hex400.);
        _AS_UTF8 = kcvt(trim(_c{_i}), "&target", 'utf-8');
        output;
      end;
    end;
  run;
  libname _v clear;

  proc sql noprint;
    select count(*), coalesce(sum(_UTF8SEQ > 0), 0)
      into :n_nonascii trimmed, :n_utf8 trimmed
      from work.xpt_verify;
  quit;

  title "XPT byte check: &file";
  proc print data=work.xpt_verify noobs; run;
  title;

  %if &n_utf8 > 0 %then
    %put ERROR: [xpt_verify] &n_utf8 value(s) contain UTF-8 byte sequences. The XPT is NOT %upcase(&target).;
  %else %if &n_nonascii > 0 %then
    %put NOTE: [xpt_verify] &n_nonascii value(s) contain single-byte non-ASCII characters - consistent with %upcase(&target).;
  %else
    %put NOTE: [xpt_verify] Pure ASCII content - identical in UTF-8, LATIN1 and WLATIN1.;
%mend xpt_verify;

%xpt_verify(file=&outdir/ae.xpt,            mem=AE, target=&target)   /* expect NOTE  */
%xpt_verify(file=&outdir/ae_naive_utf8.xpt, mem=AE, target=&target)   /* expect ERROR */
