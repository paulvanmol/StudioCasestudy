/*****************************************************************************
Clinical Trial Encoding Demo for SAS Viya / SAS Studio
Developed for: SAS Viya demo of legacy Windows WLATIN1 clinical programs
Author: Paul Van Mol / generated with Microsoft Copilot

Purpose
  1. Run a legacy clinical-trial style program in a LATIN1 / WLATIN1 SAS session.
  2. Create realistic SDTM and ADaM sample data with Western European characters.
  3. Export SDTM/ADaM domains to SAS V5 XPT transport files.
  4. Demonstrate safe migration from WLATIN1 to UTF-8 with validation checks.

How to use
  SCENARIO A: LATIN1/WLATIN1 compatibility demo
    - Start a SAS Studio Compute context configured with -ENCODING WLATIN1 or LATIN1.
    - Ensure SAS Studio default text encoding is aligned with the program encoding.
    - Run this file from top to bottom.

  SCENARIO B: UTF-8 migration demo
    - First run Sections 0-4 in a WLATIN1 session to create the legacy study data.
    - Then start a UTF-8 SAS session and run Sections 5-8.

Important
  - This .sas file is saved as Windows-1252 / WLATIN1. If you store it in Git,
    set the repository/editor encoding deliberately before demonstrating.
  - Replace &_demo_root with a path that exists in your SAS Viya compute server.
*****************************************************************************/

/*=============================================================================
  0. Demo parameters
=============================================================================*/
options mprint mlogic symbolgen msglevel=i validvarname=upcase;

/* Change this root path to a writable path on your SAS Compute server. */
%let _demo_root = %sysfunc(pathname(WORK))/clinenc_demo;
%let _demo_root = /home/student/StudioCasestudy/clinical_encoding_demo;

/* Create directories. Works on Linux-based SAS Viya compute servers with allowXCMD enabled  */
options noxwait xsync;
/*x "mkdir -p &_demo_root/legacy_sdtm &_demo_root/legacy_adam &_demo_root/xpt &_demo_root/utf8_migrate &_demo_root/reports";*/
options dlcreatedir;
libname SDTM   "&_demo_root/legacy_sdtm";
libname ADAM   "&_demo_root/legacy_adam";
libname MIGU8  "&_demo_root/utf8_migrate";
libname xpt    "&_demo_root/xpt";

%put NOTE: Demo root is &_demo_root;
%put NOTE: Current SAS session encoding is %sysfunc(getoption(encoding));
%put NOTE: Current SAS locale is %sysfunc(getoption(locale));

title "Clinical Encoding Demo - Session Encoding Check";
proc options group=languagecontrol; run;
title;

/*=============================================================================
  1. Helper formats and macro utilities
=============================================================================*/
proc format lib=sdtm cntlout=sdtm.formats;
  value $sex     'M'='Male' 'F'='Female';
  value $yn      'Y'='Yes' 'N'='No';
  value $trt     'PBO'='Placebo' 'DRUGA'='Drug A 50 mg' 'DRUGB'='Drug B 100 mg';
  value $sev     'MILD'='Mild' 'MODERATE'='Moderate' 'SEVERE'='Severe';
  value $rel     'NOT RELATED'='Not Related' 'POSSIBLY RELATED'='Possibly Related' 'RELATED'='Related';
run;
options fmtsearch=(work sdtm library);

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
  2. Create SDTM-style data with WLATIN1-sensitive values
     Domains: DM, AE, LB
=============================================================================*/

data SDTM.DM(label='Demographics');
  length STUDYID $12 DOMAIN $2 USUBJID $24 SUBJID $8 RFSTDTC RFENDTC BRTHDTC $10
         SITEID $6 SEX $1 RACE $40 ETHNIC $30 ARMCD $8 ARM $40 COUNTRY $3
         INVNAM $60 CITY $40 COMMENT $80;
  format SEX $sex. ARMCD $trt.;
  infile datalines dlm='|' dsd truncover;
  input STUDYID :$12. DOMAIN :$2. USUBJID :$24. SUBJID :$8. RFSTDTC :$10. RFENDTC :$10.
        BRTHDTC :$10. SITEID :$6. SEX :$1. RACE :$40. ETHNIC :$30. ARMCD :$8.
        ARM :$40. COUNTRY :$3. INVNAM :$60. CITY :$40. COMMENT :$80.;
datalines;
ENCODE01|DM|ENCODE01-001-0001|0001|2026-01-15|2026-03-15|1978-05-21|001|F|WHITE|NOT HISPANIC OR LATINO|DRUGA|Drug A 50 mg|FRA|Dr François Lemaître|Lyon|Legacy note: crème brûlée preference
ENCODE01|DM|ENCODE01-001-0002|0002|2026-01-16|2026-03-16|1969-11-02|001|M|WHITE|NOT HISPANIC OR LATINO|PBO|Placebo|BEL|Dr Chloé Dubois|Liège|Accent check: déjà vu and naïve text
ENCODE01|DM|ENCODE01-002-0003|0003|2026-01-17|2026-03-20|1985-07-14|002|F|WHITE|NOT HISPANIC OR LATINO|DRUGB|Drug B 100 mg|DEU|Dr Jürgen Müller|München|German umlaut: Größe and Straße
ENCODE01|DM|ENCODE01-002-0004|0004|2026-01-19|2026-03-21|1958-02-08|002|M|WHITE|NOT HISPANIC OR LATINO|DRUGA|Drug A 50 mg|ESP|Dr José García|Sevilla|Spanish name: señor and año
ENCODE01|DM|ENCODE01-003-0005|0005|2026-01-20|2026-03-22|1991-09-30|003|F|WHITE|NOT HISPANIC OR LATINO|PBO|Placebo|SWE|Dr Åsa Björk|Göteborg|Nordic letters: Å Ä Ö
;
run;

data SDTM.AE(label='Adverse Events');
  length STUDYID $12 DOMAIN $2 USUBJID $24 AESEQ 8 AETERM $80 AEDECOD $60 AEBODSYS $60
         AESTDTC AEENDTC $10 AESEV $8 AESER $1 AEREL $18 AEOUT $24 COMMENT $100;
  format AESEV $sev. AESER $yn. AEREL $rel.;
  infile datalines dlm='|' dsd truncover;
  input STUDYID :$12. DOMAIN :$2. USUBJID :$24. AESEQ AETERM :$80. AEDECOD :$60.
        AEBODSYS :$60. AESTDTC :$10. AEENDTC :$10. AESEV :$8. AESER :$1.
        AEREL :$18. AEOUT :$24. COMMENT :$100.;
datalines;
ENCODE01|AE|ENCODE01-001-0001|1|Headache after café intake|HEADACHE|NERVOUS SYSTEM DISORDERS|2026-01-20|2026-01-21|MILD|N|NOT RELATED|RECOVERED|Investigator text includes café
ENCODE01|AE|ENCODE01-001-0002|1|Nausea, déjà vu sensation|NAUSEA|GASTROINTESTINAL DISORDERS|2026-01-22|2026-01-23|MODERATE|N|POSSIBLY RELATED|RECOVERED|Reported in Liège
ENCODE01|AE|ENCODE01-002-0003|1|Injection-site pruritus|PRURITUS|SKIN DISORDERS|2026-01-25|2026-01-27|MILD|N|RELATED|RECOVERED|German note Straße
ENCODE01|AE|ENCODE01-002-0004|1|Fatigue - señor reported tiredness|FATIGUE|GENERAL DISORDERS|2026-01-28|2026-02-02|MODERATE|N|POSSIBLY RELATED|RECOVERED|Spanish accent in verbatim
ENCODE01|AE|ENCODE01-003-0005|1|Dizziness after 100 mg dose|DIZZINESS|NERVOUS SYSTEM DISORDERS|2026-01-30|2026-02-01|SEVERE|Y|RELATED|RECOVERED|Includes micro symbol in lab: 5 µmol/L
;
run;

data SDTM.LB(label='Laboratory Test Results');
  length STUDYID $12 DOMAIN $2 USUBJID $24 LBSEQ 8 LBTESTCD $8 LBTEST $40 LBCAT $40
         LBORRES $20 LBORRESU $12 LBSTRESC $20 LBSTRESU $12 LBDTC $10 LBNAM $60 COMMENT $80;
  infile datalines dlm='|' dsd truncover;
  input STUDYID :$12. DOMAIN :$2. USUBJID :$24. LBSEQ LBTESTCD :$8. LBTEST :$40.
        LBCAT :$40. LBORRES :$20. LBORRESU :$12. LBSTRESC :$20. LBSTRESU :$12.
        LBDTC :$10. LBNAM :$60. COMMENT :$80.;
datalines;
ENCODE01|LB|ENCODE01-001-0001|1|ALT|Alanine Aminotransferase|CHEMISTRY|32|U/L|32|U/L|2026-01-15|Laboratoire Saint-Étienne|Contains Étienne
ENCODE01|LB|ENCODE01-001-0002|1|CRP|C-Reactive Protein|CHEMISTRY|4.2|mg/L|4.2|mg/L|2026-01-16|Clinique de Liège|Contains Liège
ENCODE01|LB|ENCODE01-002-0003|1|CREAT|Creatinine|CHEMISTRY|82|µmol/L|82|µmol/L|2026-01-17|München Zentrallabor|Contains µ and ü
ENCODE01|LB|ENCODE01-002-0004|1|HGB|Hemoglobin|HEMATOLOGY|13.3|g/dL|13.3|g/dL|2026-01-19|Laboratorio José García|Contains José García
ENCODE01|LB|ENCODE01-003-0005|1|BILI|Bilirubin|CHEMISTRY|11|µmol/L|11|µmol/L|2026-01-20|Göteborg Kliniskt Lab|Contains Göteborg
;
run;

/* Show descriptor metadata and source encoding. */
%show_encoding(lib=SDTM, mem=DM);
%show_encoding(lib=SDTM, mem=AE);
%show_encoding(lib=SDTM, mem=LB);

/*=============================================================================
  3. Create ADaM-style data
     Datasets: ADSL, ADAE, ADLB
=============================================================================*/

data ADAM.ADSL(label='Subject-Level Analysis Dataset');
  length STUDYID $12 USUBJID $24 SUBJID $8 SITEID $6 TRT01P TRT01A $40 TRT01PN TRT01AN 8
         SAFFL ITTFL $1 AGE 8 AGEGR1 $20 SEX $1 COUNTRY $3 REGION1 $30 RACENOTE $80;
  set SDTM.DM;
  AGE = intck('year', input(BRTHDTC,yymmdd10.), input(RFSTDTC,yymmdd10.), 'c');
  TRT01P = ARM; TRT01A = ARM;
  TRT01PN = ifn(ARMCD='PBO',0,ifn(ARMCD='DRUGA',1,2));
  TRT01AN = TRT01PN;
  SAFFL='Y'; ITTFL='Y';
  if AGE < 65 then AGEGR1='<65'; else AGEGR1='>=65';
  REGION1='Western Europe';
  RACENOTE=catx(' - ', CITY, COMMENT);
  keep STUDYID USUBJID SUBJID SITEID TRT01P TRT01A TRT01PN TRT01AN SAFFL ITTFL AGE AGEGR1 SEX COUNTRY REGION1 RACENOTE;
run;

data ADAM.ADAE(label='Adverse Events Analysis Dataset');
  length STUDYID $12 USUBJID $24 TRT01A $40 SAFFL TRTEMFL $1 AEDECOD $60 AEBODSYS $60
         AESEV $8 AESER $1 AEREL $18 ASTDT AENDT 8 ADURN 8 AETERM $80 COMMENT $120;
  merge SDTM.AE(in=a) ADAM.ADSL(keep=USUBJID TRT01A SAFFL);
  by USUBJID;
  if a;
  ASTDT=input(AESTDTC,yymmdd10.);
  AENDT=input(AEENDTC,yymmdd10.);
  format ASTDT AENDT date9.;
  ADURN=AENDT-ASTDT+1;
  TRTEMFL='Y';
run;

data ADAM.ADLB(label='Laboratory Analysis Dataset');
  length STUDYID $12 USUBJID $24 TRT01A $40 PARAMCD $8 PARAM $40 AVAL 8 AVALU $12
         ADT 8 ANL01FL $1 LBNAM $60 COMMENT $100;
  merge SDTM.LB(in=l) ADAM.ADSL(keep=USUBJID TRT01A);
  by USUBJID;
  if l;
  PARAMCD=LBTESTCD; PARAM=LBTEST; AVAL=input(LBSTRESC,best.); AVALU=LBSTRESU;
  ADT=input(LBDTC,yymmdd10.); format ADT date9.;
  ANL01FL='Y';
run;

/* Add indexes to demonstrate index handling during migration. */
%create_index(lib=ADAM, data=ADSL, indexname=USUBJID, vars=USUBJID);
%create_index(lib=ADAM, data=ADAE, indexname=USUBJID, vars=USUBJID);
%create_index(lib=ADAM, data=ADLB, indexname=USUBJID, vars=USUBJID);

%show_encoding(lib=ADAM, mem=ADSL);
%show_encoding(lib=ADAM, mem=ADAE);
%show_encoding(lib=ADAM, mem=ADLB);

/*=============================================================================
  4. Export SDTM and ADaM to XPT transport files
     Note: XPT V5 has structural constraints. Keep variable names <= 8 chars.
=============================================================================*/

libname DMXPT xport "&_demo_root/xpt/dm.xpt";
proc copy in=SDTM out=DMXPT memtype=data;
  select DM;
run;
libname DMXPT clear;

libname AEXPT xport "&_demo_root/xpt/ae.xpt";
proc copy in=SDTM out=AEXPT memtype=data;
  select AE;
run;
libname AEXPT clear;

libname LBXPT xport "&_demo_root/xpt/lb.xpt";
proc copy in=SDTM out=LBXPT memtype=data;
  select LB;
run;
libname LBXPT clear;

libname ADSLXPT xport "&_demo_root/xpt/adsl.xpt";
proc copy in=ADAM out=ADSLXPT memtype=data;
  select ADSL;
run;
libname ADSLXPT clear;

libname ADAEXPT xport "&_demo_root/xpt/adae.xpt";
proc copy in=ADAM out=ADAEXPT memtype=data;
  select ADAE;
run;
libname ADAEXPT clear;

libname ADLBXPT xport "&_demo_root/xpt/adlb.xpt";
proc copy in=ADAM out=ADLBXPT memtype=data;
  select ADLB;
run;
libname ADLBXPT clear;

/*=============================================================================
  5. Compatibility demo in LATIN1 / WLATIN1 session
=============================================================================*/

title "LATIN1/WLATIN1 rerun demo - SDTM and ADaM print checks";
proc print data=SDTM.DM(obs=5) noobs; var USUBJID INVNAM CITY COMMENT; run;
proc print data=SDTM.AE(obs=5) noobs; var USUBJID AETERM COMMENT; run;
proc print data=ADAM.ADSL(obs=5) noobs; var USUBJID TRT01A RACENOTE; run;
title;

/* Demonstrate index usage with a WHERE clause. Look for index usage notes in log. */
options msglevel=i;
title "Index usage check in legacy ADaM library";
proc print data=ADAM.ADSL(idxwhere=yes) noobs;
  where USUBJID='ENCODE01-002-0003';
  var USUBJID TRT01A AGE RACENOTE;
run;
title;

