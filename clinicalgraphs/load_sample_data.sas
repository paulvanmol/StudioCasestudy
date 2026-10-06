/* Load sample data for the clinical graph steps.
   Set REPO to the location of the clinicalgraphs folder (Git clone in SAS Studio). */
%let repo=/workshop/&sysuserid/StudioCasestudy/clinicalgraphs;
libname cgdata "%sysfunc(getoption(work))"; /* replace with a permanent path if needed */

%macro imp(ds);
  proc import datafile="&repo/data/&ds..csv" out=cgdata.&ds dbms=csv replace;
    guessingrows=max;
  run;
%mend;
%imp(adtte) %imp(forest_os) %imp(adtr) %imp(adswim) %imp(adlb) %imp(adlb_edish)

/* subset for the mean-over-time step: post-baseline change */
data cgdata.adlb_chg; set cgdata.adlb; where avisitn>0; run;
