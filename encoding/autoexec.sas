%let path=%substr(&_sasprogramfile,1,%index(&_sasprogramfile,autoexec.sas)-2);
libname source "&path/rawdata";
libname library "&path/library";
libname target "&path/SDTM/Data";

options ls=256 nocenter
        EXTENDOBSCOUNTER=NO
        mautosource 
        SASAUTOS = ( SASAUTOS,    
                    "&path/macros");

                    proc options option=sasautos; run; 
