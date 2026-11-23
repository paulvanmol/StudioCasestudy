/*--------------------------------------------------------------------
  05c_read_legacy_in_utf8.sas
  Purpose : what happens when a UTF-8 session reads WLATIN1 data.
  RUN THIS IN THE DEFAULT (UTF-8) COMPUTE CONTEXT.
--------------------------------------------------------------------*/
%put NOTE: Session encoding = &sysencoding;   /* expect utf-8 */

%let work = %sysget(HOME)/servier_work;
libname legacy "&work/legacy_wlatin1" access=readonly;  /* never write to legacy */

/* 1. Which encoding does the data set have? */
proc contents data=legacy.ae_legacy; ods select attributes; run;

/* 2. Read it with CEDA (automatic transcoding).                      */
/*    Look in the log for the CEDA NOTE and the transcoding ERROR.    */
data work.ae_ceda;
  set legacy.ae_legacy;
run;

/* 3. Read it through the CVP engine: character columns are widened, */
/*    so no data is lost. This is a READ technique - for a full       */
/*    migration (formats, indexes, ...) see advanced/                 */
libname legcvp cvp "&work/legacy_wlatin1" cvpmultiplier=2 access=readonly;

data work.ae_cvp;
  set legcvp.ae_legacy;
run;

/* 4. Compare the column lengths */
proc sql;
  title "Column lengths: legacy (WLATIN1) vs read through CVP (UTF-8)";
  select a.name, a.length as legacy_length, b.length as cvp_length
    from dictionary.columns a
         inner join dictionary.columns b
         on upcase(a.name) = upcase(b.name)
    where a.libname='LEGACY' and a.memname='AE_LEGACY'
      and b.libname='WORK'   and b.memname='AE_CVP'
      and a.type='char';
quit;
title;

proc print data=work.ae_cvp label noobs; run;

/* 5. The format catalog is NOT transcoded by CEDA - try to use it */
options fmtsearch=(legacy work);
data _null_;
  sev = 'S';
  put 'Format test: ' sev $sev.;
run;
options fmtsearch=(work library);

libname legcvp clear;
libname legacy clear;
