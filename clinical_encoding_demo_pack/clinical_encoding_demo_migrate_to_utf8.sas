/*=============================================================================
  6. UTF-8 migration options
     Run Sections 6-8 in a UTF-8 SAS session after creating legacy data.
=============================================================================*/

%put NOTE: UTF-8 migration section. Current encoding is %sysfunc(getoption(encoding));

/* 6A. Quick read using CEDA/CVP. Useful for reading and copying, not the full answer
       for indexes/catalogs/integrity constraints. */
libname SDTMCVP cvp "&_demo_root/legacy_sdtm" cvpmultiplier=4;
libname ADAMCVP cvp "&_demo_root/legacy_adam" cvpmultiplier=4;

/* Copy with CVP to prevent character truncation when byte length expands in UTF-8. */
proc copy in=SDTMCVP out=MIGU8 memtype=data;
  select DM AE LB;
run;
proc copy in=ADAMCVP out=MIGU8 memtype=data;
  select ADSL ADAE ADLB;
run;

libname SDTMCVP clear;
libname ADAMCVP clear;

%show_encoding(lib=MIGU8, mem=DM);
%show_encoding(lib=MIGU8, mem=ADSL);

/* 6B. Library-level migration option.
       Use this as the preferred demonstration when indexes/catalogs must be preserved.
       If PROC MIGRATE is available in your environment, uncomment and run.

libname MIGPREF "&_demo_root/utf8_migrate_proc_migrate";
proc migrate in=ADAM out=MIGPREF;
run;
%show_encoding(lib=MIGPREF, mem=ADSL);
*/

/*=============================================================================
  7. Validation after UTF-8 migration
=============================================================================*/

/* Record count validation. */
proc sql;
  title "Record counts before and after UTF-8 migration";
  select 'SDTM.DM' as DOMAIN length=16, count(*) as N from SDTM.DM union all
  select 'MIGU8.DM', count(*) from MIGU8.DM union all
  select 'SDTM.AE', count(*) from SDTM.AE union all
  select 'MIGU8.AE', count(*) from MIGU8.AE union all
  select 'ADAM.ADSL', count(*) from ADAM.ADSL union all
  select 'MIGU8.ADSL', count(*) from MIGU8.ADSL;
quit;
title;

/* Sort and compare selected domains. */
proc sort data=SDTM.DM out=work.dm_base; by USUBJID; run;
proc sort data=MIGU8.DM out=work.dm_u8; by USUBJID; run;
%compare_domain(base=work.dm_base, comp=work.dm_u8, id=USUBJID);

proc sort data=ADAM.ADSL out=work.adsl_base; by USUBJID; run;
proc sort data=MIGU8.ADSL out=work.adsl_u8; by USUBJID; run;
%compare_domain(base=work.adsl_base, comp=work.adsl_u8, id=USUBJID);

/* Hex display to prove byte representation differs but rendered value is intact. */
title "Byte-level illustration after migration";
data _null_;
  set MIGU8.DM(obs=5);
  put USUBJID= INVNAM= / 'HEX INVNAM=' INVNAM $hex120. /;
run;
title;

/* Index inspection. If indexes disappeared, rebuild them deliberately and document it. */
title "Index metadata after migration";
proc contents data=MIGU8.ADSL; run;
title;

proc datasets lib=MIGU8 nolist;
  modify ADSL;
  index create USUBJID / unique;
  modify ADAE;
  index create USUBJID;
  modify ADLB;
  index create USUBJID;
quit;

options msglevel=i;
title "Index usage check after rebuild";
proc print data=MIGU8.ADSL(idxwhere=yes) noobs;
  where USUBJID='ENCODE01-002-0003';
  var USUBJID TRT01A AGE RACENOTE;
run;
title;

/*=============================================================================
  8. Demo wrap-up: suggested talking points
=============================================================================*/

data _null_;
  put 'NOTE: Demo talking points:';
  put 'NOTE: 1) Legacy programs and data can be demonstrated in a LATIN1/WLATIN1 context when editor and compute encodings are aligned.';
  put 'NOTE: 2) UTF-8 migration requires checking the source encoding, character lengths, indexes, catalogs, and validation evidence.';
  put 'NOTE: 3) CVP helps expand character storage during transcoding.';
  put 'NOTE: 4) PROC COMPARE and PROC CONTENTS provide simple validation evidence for demos.';
  put 'NOTE: 5) Rebuild or verify indexes after copy-based migration paths; prefer migration methods that preserve metadata when required.';
run;

ods html path="&_demo_root/reports" file="clinical_encoding_demo_summary.html";
title "Clinical Encoding Demo Summary";
proc contents data=MIGU8.ADSL varnum; run;
proc print data=MIGU8.ADSL noobs; var USUBJID TRT01A AGE RACENOTE; run;
ods html close;

%put NOTE: Demo completed. Review &_demo_root, especially xpt and reports directories.;
