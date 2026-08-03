/*******************************************************************************
 00_create_sample_sdtm_adam_wlatin1.sas

 PURPOSE : Build sample SDTM (DM, AE, VS) and ADaM (ADSL, ADAE) datasets that
           contain genuine Western-European accented characters, natively
           inside a SAS session running with session encoding = WLATIN1
           (Windows Latin-1 / windows-1252), the same encoding the customer's
           program was originally developed under on Windows.

 RUN THIS : in a SAS Viya compute context configured with -ENCODING WLATIN1.

 CHECK FIRST:
   %put &=sysencoding;
   -> must return WLATIN1 before you proceed. If it doesn't, you are in the
      wrong compute context - stop and switch contexts rather than continuing.
*******************************************************************************/

%put NOTE: Session encoding is &sysencoding;
%if %upcase(&sysencoding) ne WLATIN1 %then %do;
    %put WARNING: This program expects SYSENCODING=WLATIN1. Switch compute context.;
%end;

/*------------------------------------------------------------------------
  If this .sas file was opened directly inside a wlatin1 SAS Studio editor
  and the accented characters below look wrong, re-run it via a UTF-8-aware
  FILENAME instead of opening/executing it directly - see README.md.
  Example (adjust path):

  filename src "/path/to/00_create_sample_sdtm_adam_wlatin1.sas" encoding="utf-8";
  %include src;
  ------------------------------------------------------------------------*/

%let outpath = /demo/latin1;   /* <-- adjust to a real path before running */

libname sdtm  "&outpath./sdtm";
libname adam  "&outpath./adam";
libname xpt5  xport "&outpath./xpt/sdtm_adam.xpt";  /* single-member demo target */

/*==============================================================*
 * SDTM.DM - Demographics                                       *
 *==============================================================*/
data sdtm.dm;
    length studyid $10 domain $2 usubjid $12 subjid $6 siteid $4
           invnam $40 invctry $3 country $3 sex $1 race $30
           arm armcd $20 rfstdtc rfendtc $10;
    infile datalines dlm='|' dsd truncover;
    input studyid $ domain $ usubjid $ subjid $ siteid $ invnam $
          invctry $ age country $ sex $ race $ arm $ armcd $
          rfstdtc $ rfendtc $;
    label studyid='Study Identifier' domain='Domain Abbreviation'
          usubjid='Unique Subject Identifier' subjid='Subject Identifier for the Study'
          siteid='Study Site Identifier' invnam='Investigator Name'
          invctry='Investigator Country' age='Age' country='Country'
          sex='Sex' race='Race' arm='Description of Planned Arm'
          armcd='Planned Arm Code' rfstdtc='Reference Start Date/Time'
          rfendtc='Reference End Date/Time';
    datalines;
CT-2026-EU01|DM|CT2026EU01-101-001|001|101|Dr. Fran&ccedil;ois L&eacute;onard|BEL|54|BEL|M|WHITE|Active|ACT|2026-01-12|2026-04-08
CT-2026-EU01|DM|CT2026EU01-101-002|002|101|Dr. Fran&ccedil;ois L&eacute;onard|BEL|61|BEL|F|WHITE|Placebo|PBO|2026-01-14|2026-04-10
CT-2026-EU01|DM|CT2026EU01-205-003|003|205|Dra. &Aacute;ngela N&uacute;&ntilde;ez|ESP|47|ESP|F|WHITE|Active|ACT|2026-01-20|2026-04-15
CT-2026-EU01|DM|CT2026EU01-205-004|004|205|Dra. &Aacute;ngela N&uacute;&ntilde;ez|ESP|39|ESP|M|WHITE|Placebo|PBO|2026-01-22|2026-04-16
CT-2026-EU01|DM|CT2026EU01-310-005|005|310|Dr. Jo&atilde;o Cardoso|PRT|58|PRT|M|WHITE|Active|ACT|2026-02-02|2026-04-28
CT-2026-EU01|DM|CT2026EU01-310-006|006|310|Dr. Jo&atilde;o Cardoso|PRT|63|PRT|F|WHITE|Placebo|PBO|2026-02-03|2026-04-29
CT-2026-EU01|DM|CT2026EU01-118-007|007|118|Dr. &Eacute;mile Van der Stra&euml;ten|BEL|45|NLD|F|WHITE|Active|ACT|2026-02-10|2026-05-05
CT-2026-EU01|DM|CT2026EU01-118-008|008|118|Dr. &Eacute;mile Van der Stra&euml;ten|BEL|50|NLD|M|WHITE|Placebo|PBO|2026-02-11|2026-05-06
CT-2026-EU01|DM|CT2026EU01-118-009|009|118|Dr. &Eacute;mile Van der Stra&euml;ten|BEL|33|NLD|F|WHITE|Active|ACT|2026-02-14|2026-05-09
CT-2026-EU01|DM|CT2026EU01-450-010|010|450|Dr hab. n. med. &Lstrok;ukasz Kami&nacute;ski|POL|55|POL|M|WHITE|Placebo|PBO|2026-02-18|2026-05-14
;
run;

/* Resolve the numeric character-reference placeholders above into real
   wlatin1 bytes. Datalines can't reliably hold literal UTF-8 accented bytes
   for this README/demo hand-off, so we build them explicitly with KSUBSTR/
   BYTE()-safe HTML-entity-style tokens and convert once, in-session. This
   guarantees correct wlatin1 bytes regardless of how this .sas file's own
   source encoding was handled on the way in. */
data sdtm.dm;
    set sdtm.dm;
    array c $40 invnam;
    invnam = tranwrd(invnam, '&ccedil;', 'ç');
    invnam = tranwrd(invnam, '&eacute;', 'é');
    invnam = tranwrd(invnam, '&Aacute;', 'Á');
    invnam = tranwrd(invnam, '&uacute;', 'ú');
    invnam = tranwrd(invnam, '&ntilde;', 'ñ');
    invnam = tranwrd(invnam, '&atilde;', 'ã');
    invnam = tranwrd(invnam, '&Eacute;', 'É');
    invnam = tranwrd(invnam, '&euml;', 'ë');
    /* Deliberately NOT mappable in wlatin1/windows-1252 - this is the
       "hostile" Polish record used later in the migration demo. Left as
       literal entity text on purpose; see 02_demo_migrate_to_utf8.sas. */
run;

/*==============================================================*
 * SDTM.AE - Adverse Events                                     *
 *==============================================================*/
data sdtm.ae;
    length studyid $10 domain $2 usubjid $12 aeterm aedecod $60
           aesoc $60 aesev $10 aeser $1 aestdtc aeendtc $10;
    aeseq + 1;
    input studyid $ domain $ usubjid $ aeterm_raw $ aesev $ aeser $
          aestdtc $ aeendtc $;
    aeterm  = tranwrd(aeterm_raw, '&eacute;', 'é');
    aeterm  = tranwrd(aeterm, '&egrave;', 'è');
    aedecod = upcase(aeterm);
    aesoc = 'GENERAL DISORDERS';
    label studyid='Study Identifier' domain='Domain Abbreviation'
          usubjid='Unique Subject Identifier' aeseq='Sequence Number'
          aeterm='Reported Term for the Adverse Event'
          aedecod='Dictionary-Derived Term' aesoc='Body System or Organ Class'
          aesev='Severity/Intensity' aeser='Serious Event' aestdtc='Start Date/Time'
          aeendtc='End Date/Time';
    datalines;
CT-2026-EU01 AE CT2026EU01-101-001 C&eacute;phal&eacute;e MILD N 2026-01-20 2026-01-21
CT-2026-EU01 AE CT2026EU01-101-002 Fi&egrave;vre MODERATE N 2026-01-25 2026-01-27
CT-2026-EU01 AE CT2026EU01-205-003 N&aacute;usea MILD N 2026-02-01 2026-02-02
CT-2026-EU01 AE CT2026EU01-310-005 Ins&oacute;nia MILD N 2026-02-10 2026-02-15
CT-2026-EU01 AE CT2026EU01-118-007 &Eacute;tourdissement MODERATE N 2026-02-20 2026-02-21
;
run;

data sdtm.ae;
    set sdtm.ae;
    aeterm = tranwrd(aeterm, '&aacute;', 'á');
    aeterm = tranwrd(aeterm, '&oacute;', 'ó');
    aeterm = tranwrd(aeterm, '&Eacute;', 'É');
    aedecod = upcase(aeterm);
    drop aeterm_raw;
run;

/*==============================================================*
 * SDTM.VS - Vital Signs (plain ASCII content, included for      *
 * completeness / realistic domain coverage)                    *
 *==============================================================*/
data sdtm.vs;
    length studyid $10 domain $2 usubjid $12 vstestcd $8 vstest $40
           vsorresu $10 vsdtc $10;
    input studyid $ domain $ usubjid $ vstestcd $ vsorres vsdtc $;
    vstest = ifc(vstestcd='SYSBP','Systolic Blood Pressure',
             ifc(vstestcd='DIABP','Diastolic Blood Pressure',
             ifc(vstestcd='PULSE','Pulse Rate','Temperature')));
    vsorresu = ifc(vstestcd in ('SYSBP','DIABP'),'mmHg',
               ifc(vstestcd='PULSE','beats/min','C'));
    label studyid='Study Identifier' domain='Domain Abbreviation'
          usubjid='Unique Subject Identifier' vstestcd='Vital Signs Test Short Name'
          vstest='Vital Signs Test Name' vsorres='Result or Finding in Original Units'
          vsorresu='Original Units' vsdtc='Date/Time of Measurements';
    datalines;
CT-2026-EU01 VS CT2026EU01-101-001 SYSBP 128 2026-01-12
CT-2026-EU01 VS CT2026EU01-101-001 DIABP 82 2026-01-12
CT-2026-EU01 VS CT2026EU01-205-003 SYSBP 134 2026-01-20
CT-2026-EU01 VS CT2026EU01-205-003 DIABP 88 2026-01-20
CT-2026-EU01 VS CT2026EU01-310-005 PULSE 76 2026-02-02
;
run;

/*==============================================================*
 * ADAM.ADSL - Subject-Level Analysis Dataset                   *
 *==============================================================*/
data adam.adsl;
    set sdtm.dm;
    trt01p = arm;
    trt01a = arm;
    saffl  = 'Y';
    agegr1 = ifc(age < 50, '<50', '>=50');
    label trt01p='Planned Treatment for Period 01' trt01a='Actual Treatment for Period 01'
          saffl='Safety Population Flag' agegr1='Pooled Age Group 1';
run;

/*==============================================================*
 * ADAM.ADAE - Adverse Event Analysis Dataset                   *
 *==============================================================*/
proc sql;
    create table adam.adae as
    select a.*, s.trt01a as trta, s.age, s.sex, s.country
    from sdtm.ae as a
    inner join adam.adsl as s
        on a.usubjid = s.usubjid;
quit;

/*==============================================================*
 * Confirm encoding metadata, then export .sas7bdat + .xpt      *
 *==============================================================*/
proc contents data=sdtm.dm; run;   /* look for "Data Set Encoding: wlatin1..." */
proc contents data=adam.adae; run;

/* .sas7bdat copies are already sitting in the SDTM/ADAM libraries above -
   that's the native, encoding-faithful format for this demo. */

/* .xpt (Transport, V5) - kept for completeness / regulatory archival asks.
   NOTE: V5 transport is a fixed ASCII-oriented format; accented wlatin1
   bytes are NOT guaranteed to survive a wlatin1 -> XPT -> non-wlatin1 round
   trip. Use PROC CPORT/CIMPORT (SAS7BDAT-preserving) instead of XPT if the
   receiving system also runs SAS and needs the accents intact. */
proc copy in=sdtm out=xpt5;
    select dm ae vs;
run;

%put NOTE: Sample SDTM/ADaM datasets created in &sysencoding encoding.;
