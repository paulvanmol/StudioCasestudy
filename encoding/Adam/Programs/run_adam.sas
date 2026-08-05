** run all ADaM programs and then convert them to XPTs;
%let sasroot=%sysget(SASROOT);
%let sysin = %sysfunc(getoption(sysin));
%let path=%substr(&_sasprogramfile,1,%index(%upcase(&_sasprogramfile),/ADAM/)-1);
%let progpath=&path/Adam/Programs;
options nomstored extendobscounter=NO; *symbolgen;
%put &=path &=progpath;
%include "&progpath/setup.sas";
%include "&progpath/adsl.sas";
%include "&progpath/adae.sas";
%include "&progpath/adef.sas";
%include "&progpath/adtte.sas";

%include "&path/macros/xpt_macros.sas";
%let outdir=&path/Adam/xpt;
%let  indir=&path/Adam/Data;
%toexp(&indir, &outdir);

** validate the data sets;
/*%include "&path/macros/run_p21v.sas";
%run_p21v(type=ADaM, sources=&path/Adam/xpt, files=*.xpt, define=N, ctdatadate=2014-09-26, make_bat=N);
*/