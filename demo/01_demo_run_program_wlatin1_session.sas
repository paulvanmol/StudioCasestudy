/*******************************************************************************
 01_demo_run_program_wlatin1_session.sas

 PURPOSE : Stand-in for "the customer's existing clinical program" - reads the
           wlatin1 SDTM/ADaM data created in 00_*.sas and produces a simple
           AE summary, proving the program runs unmodified on SAS Viya as
           long as the compute session encoding matches the data (wlatin1).

 RUN THIS : in the SAME wlatin1 compute context used for 00_*.sas.
*******************************************************************************/

%put NOTE: Session encoding is &sysencoding;

%let outpath = /demo/latin1;   /* must match 00_*.sas */
libname sdtm "&outpath./sdtm";
libname adam "&outpath./adam";

/* Step 1 - prove the data's own encoding tag matches the session.
   This is the check worth pointing at during the demo: no WARNING/NOTE
   about cross-environment transcoding appears in the log below, because
   session encoding and data encoding already agree. */
proc contents data=sdtm.dm short;
    ods select EngineHost;
run;

/* Step 2 - read and display the accented investigator / AE term fields
   exactly as authored, no transcoding involved. */
title "Site Investigators (wlatin1 session, wlatin1 data - no transcoding)";
proc print data=sdtm.dm noobs label;
    var siteid invnam invctry country;
run;

title "Adverse Event Terms as Originally Reported";
proc print data=sdtm.ae noobs label;
    var usubjid aeterm aesev aestdtc;
run;

/* Step 3 - the kind of summary output the customer actually cares about:
   AE frequency by treatment arm, from ADAM.ADAE. */
title "AE Summary by Treatment Arm";
proc freq data=adam.adae;
    tables aedecod * trta / nocol norow nopercent;
run;

title;

%put NOTE: Program completed with 0 transcoding warnings expected -;
%put NOTE: session encoding (&sysencoding) matches source data encoding.;
