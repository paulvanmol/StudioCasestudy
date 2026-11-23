/*--------------------------------------------------------------------
  05b_create_legacy_wlatin1.sas
  Purpose : simulate a LEGACY study (WLATIN1) for the encoding demo.
  RUN THIS ONLY IN THE WLATIN1 / LATIN1 COMPUTE CONTEXT.
--------------------------------------------------------------------*/

/* Safety check - stop if we are not in a single-byte session */
%macro assert_latin1;
  %if %sysfunc(find(%upcase(&sysencoding),LATIN1)) = 0 %then %do;
    %put ERROR: Session encoding is &sysencoding.. Switch the compute context to WLATIN1/LATIN1 first.;
    %abort cancel;
  %end;
  %else %put NOTE: OK - session encoding is &sysencoding..;
%mend assert_latin1;
%assert_latin1

%let work = %sysget(HOME)/servier_work;
options dlcreatedir;
libname legacy "&work/legacy_wlatin1";

/* Lengths are 'just big enough' for single-byte characters.        */
/* e, e-acute, e-grave and the micro sign take 1 byte in WLATIN1    */
/* but 2 bytes in UTF-8 -> expected truncation later.               */
data legacy.ae_legacy(label="Legacy AE listing - WLATIN1");
  length usubjid $11 aeterm $8 aedose 8 aeunit $2;
  infile datalines dsd dlm='|';
  input usubjid aeterm aedose aeunit;
  label usubjid = "Unique Subject Identifier"
        aeterm  = "Reported Term for the Adverse Event"
        aedose  = "Dose"
        aeunit  = "Dose Unit";
datalines;
SRV-001-001|Fièvre|250|µg
SRV-001-002|Nausée|100|mg
SRV-001-003|Céphalée|50|µg
SRV-001-004|Asthénie|10|mg
SRV-001-005|Headache|5|mg
;
run;

/* User-defined format in the legacy study (stored in a catalog) */
proc format lib=legacy;
  value $sev 'L' = 'Légère'
             'M' = 'Modérée'
             'S' = 'Sévère';
run;

proc contents data=legacy.ae_legacy; ods select attributes variables; run;
proc print data=legacy.ae_legacy label noobs; run;
