/*--------------------------------------------------------------------
  05a_check_encoding.sas
  Purpose : document the encoding situation BEFORE you run study code.
  Run it  : in every compute context you use (UTF-8 and WLATIN1).
--------------------------------------------------------------------*/

/* 1. Session encoding and locale of the current compute context */
%put NOTE: Session encoding = &sysencoding;
proc options option=(encoding locale) value;
run;

/* 2. Encoding of a SAS data set: see 'Encoding' in PROC CONTENTS */
proc contents data=sashelp.class;
  ods select attributes;
run;

/* 3. Encoding of all data sets in a library (one row per table) */
%macro list_encoding(lib);
  proc sql;
    title "Data set encoding in library %upcase(&lib)";
    select libname, memname, encoding, nobs
      from dictionary.tables
      where libname = "%upcase(&lib)" and memtype = 'DATA';
  quit;
  title;
%mend list_encoding;

/* Example - run after demo 05b has created the legacy library:
   libname legacy "&work/legacy_wlatin1" access=readonly;
   %list_encoding(legacy)
*/
