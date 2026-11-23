/*--------------------------------------------------------------------
  00_setup_paths.sas
  Servier - SAS Studio on SAS Viya for Clinical Programmers
  Purpose : define the course-file location and a personal work folder.
  Usage   : run once at the start of every SAS session
            (or copy the %LET lines into Options > Autoexec file).
--------------------------------------------------------------------*/

/* Folder that contains Diabetes.csv and diabetesdataprepfinal.sas.   */
/* Change this if you uploaded/cloned the files somewhere else.       */
%let path = %sysget(HOME)/StudioCasestudy;

/* Personal output folder for demo data - kept OUTSIDE the Git clone  */
/* so that generated data is never committed by accident.             */
%let work = %sysget(HOME)/servier_work;

options dlcreatedir;                       /* create folders if missing */
libname demo   "&work";
libname legacy "&work/legacy_wlatin1";
libname utf8   "&work/utf8";
libname demo clear; libname legacy clear; libname utf8 clear;
options nodlcreatedir;

%put NOTE: ------------------------------------------------------------;
%put NOTE: Course files   : &path;
%put NOTE: Work folder    : &work;
%put NOTE: Session encoding: &sysencoding;
%put NOTE: ------------------------------------------------------------;

/* Quick check that the course files are where we expect them */
%macro check_file(f);
  %if %sysfunc(fileexist(&path/&f)) %then %put NOTE: Found   &path/&f;
  %else %put WARNING: Missing &path/&f - check the value of PATH.;
%mend check_file;
%check_file(Diabetes.csv)
%check_file(diabetesdataprepfinal.sas)
