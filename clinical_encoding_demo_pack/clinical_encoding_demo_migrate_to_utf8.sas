/*=============================================================================
  0. Demo parameters
=============================================================================*/
options mprint mlogic symbolgen msglevel=i validvarname=upcase;

/* Change this root path to a writable path on your SAS Compute server. */
%let _demo_root = /home/student/StudioCasestudy/clinical_encoding_demo_pack;

/* Create directories. Works on Linux-based SAS Viya compute servers. */

*x "mkdir -p &_demo_root/legacy_sdtm &_demo_root/legacy_adam &_demo_root/xpt &_demo_root/utf8_migrate &_demo_root/reports";
options dlcreatedir; 
libname SDTM   "&_demo_root/sdtm";
libname ADAM   "&_demo_root/adam";
libname MIGU8  "&_demo_root/utf8_migrate";

%put NOTE: Demo root is &_demo_root;
%put NOTE: Current SAS session encoding is %sysfunc(getoption(encoding));
%put NOTE: Current SAS locale is %sysfunc(getoption(locale));

title "Clinical Encoding Demo - Session Encoding Check";
proc options group=languagecontrol; run;
title;

/*=============================================================================
  1. Helper formats and macro utilities
=============================================================================*/
proc format ;
  value $sex     'M'='Male' 'F'='Female';
  value $yn      'Y'='Yes' 'N'='No';
  value $trt     'PBO'='Placebo' 'DRUGA'='Drug A 50 mg' 'DRUGB'='Drug B 100 mg';
  value $sev     'MILD'='Mild' 'MODERATE'='Moderate' 'SEVERE'='Severe';
  value $rel     'NOT RELATED'='Not Related' 'POSSIBLY RELATED'='Possibly Related' 'RELATED'='Related';
run;

%macro show_encoding(lib=, mem=);
  title "Encoding and descriptor check: &lib..&mem";
  proc contents data=&lib..&mem varnum; run;
  title;
%mend;

%macro compare_domain(base=, comp=, id=);
  title "PROC COMPARE validation: &base vs &comp";
  proc compare base=&base compare=&comp criterion=0.0000001 method=absolute listall;
    id &id;
  run;
  title;
%mend;

%macro create_index(lib=, data=, indexname=, vars=);
  proc datasets lib=&lib nolist;
    modify &data;
    index create &indexname ;
  quit;
%mend;

/*=============================================================================
  6. UTF-8 migration options
     Run Sections 6-8 in a UTF-8 SAS session after creating legacy data.
=============================================================================*/

%put NOTE: UTF-8 migration section. Current encoding is %sysfunc(getoption(encoding));

/* 6A. Quick read using CEDA/CVP. Useful for reading and copying, not the full answer
       for indexes/catalogs/integrity constraints. */
libname SDTMCVP cvp "&_demo_root/legacy_sdtm" cvpmultiplier=2;
libname ADAMCVP cvp "&_demo_root/legacy_adam" cvpmultiplier=2;
libname sdtm "&_demo_root/sdtm";
libname adam "&_demo_root/adam";

/* Copy with CVP to prevent character truncation when byte length expands in UTF-8. */
proc datasets lib=SDTM kill;
run;
quit;
proc datasets lib=ADAM kill;
run;
quit;
proc datasets lib=SDTMCVP ;
  copy out=sdtm  NOCLONE;
run;
proc datasets lib=ADAMCVP ;
  copy out=adam NOCLONE;
run;


*libname SDTMCVP clear;
*libname ADAMCVP clear;

%show_encoding(lib=SDTM, mem=DM);
%show_encoding(lib=ADAM, mem=ADSL);

/* 6B. Library-level migration option.
       Use this as the preferred demonstration when indexes/catalogs must be preserved.
       If PROC MIGRATE is available in your environment, uncomment and run.
*/
proc datasets lib=migpref kill;
quit; 
libname ADAMCVP cvp "&_demo_root/legacy_adam" cvpmultiplier=2;
libname MIGPREF "&_demo_root/utf8_migrate_proc_migrate";
proc migrate in=ADAMCVP out=MIGPREF;
run;
%show_encoding(lib=MIGPREF, mem=ADSL);


/*=============================================================================
  7. Validation after UTF-8 migration
=============================================================================*/

/* Record count validation. */
proc sql;
  title "Record counts before and after UTF-8 migration";
  select 'SDTMCVP.DM' as DOMAIN length=16, count(*) as N from SDTMCVP.DM union all
  select 'SDTM.DM', count(*) from SDTM.DM union all
  select 'SDTMCVP.AE', count(*) from SDTMCVP.AE union all
  select 'SDTM.AE', count(*) from SDTM.AE union all
  select 'ADAMCVP.ADSL', count(*) from ADAMCVP.ADSL union all
  select 'ADAM.ADSL', count(*) from ADAM.ADSL;
quit;
title;

/* Sort and compare selected domains. */
proc sort data=SDTMCVP.DM out=work.dm_base; by USUBJID; run;
proc sort data=SDTM.DM out=work.dm_u8; by USUBJID; run;
%compare_domain(base=work.dm_base, comp=work.dm_u8, id=USUBJID);

proc sort data=ADAMCVP.ADSL out=work.adsl_base; by USUBJID; run;
proc sort data=ADAM.ADSL out=work.adsl_u8; by USUBJID; run;
%compare_domain(base=work.adsl_base, comp=work.adsl_u8, id=USUBJID);

/* Hex display to prove byte representation differs but rendered value is intact. */
title "Byte-level illustration after migration";
data _null_;
  set SDTM.DM(obs=5);
  put USUBJID= INVNAM= / 'HEX INVNAM=' INVNAM $hex120. /;
run;
title;

/* Index inspection. If indexes disappeared, rebuild them deliberately and document it. */
title "Index metadata after migration";
proc contents data=ADAM.ADSL; run;
title;

proc datasets lib=ADAM nolist;
  modify ADSL;
  index create USUBJID / unique;
  modify ADAE;
  index create USUBJID;
  modify ADLB;
  index create USUBJID;
quit;

options msglevel=i;
title "Index usage check after rebuild";
proc print data=ADAM.ADSL(idxwhere=yes) noobs;
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
proc contents data=ADAM.ADSL varnum; run;
proc print data=ADAM.ADSL noobs; var USUBJID TRT01A AGE RACENOTE; run;
ods html close;

%put NOTE: Demo completed. Review &_demo_root, especially xpt and reports directories.;
