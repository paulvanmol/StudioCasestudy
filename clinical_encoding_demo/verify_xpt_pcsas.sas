/*****************************************************************************
  Program : verify_xpt_pcsas.sas
  Purpose : Verify in PC SAS (Windows) that an XPT file created in
            SAS Studio / SAS Viya Workbench contains valid WLATIN1 data.
  Start   : PC SAS with the "SAS 9.4 (English)" shortcut  -> WLATIN1
            NOT "SAS 9.4 (Unicode Support)"                -> UTF-8
*****************************************************************************/

%let xptdir = C:\temp\xpt_demo;      /* folder with the downloaded XPT files */
%let mem    = AE;

/* 1. The verifier session must be WLATIN1, otherwise the test is meaningless */
%put NOTE: PC SAS session encoding = &sysencoding;
%macro chk_session;
  %if %upcase(&sysencoding) ne WLATIN1 %then
    %put WARNING: This session is &sysencoding.. Restart PC SAS with the English (WLATIN1) shortcut.;
%mend chk_session;
%chk_session

/* 2. Open the transport file and look at the structure */
libname xin xport "&xptdir\%lowcase(&mem).xpt" access=readonly;

title "1 - Structure of %lowcase(&mem).xpt";
proc contents data=xin._all_ varnum; run;

/* 3. Restore into WORK and look at the values */
proc copy in=xin out=work memtype=data;
run;
libname xin clear;

title "2 - Values as PC SAS (&sysencoding) displays them";
proc print data=work.&mem noobs; run;

/* 4. Mojibake detector
      UTF-8 bytes read as WLATIN1 appear as 'Ã©', 'Ã¼', 'Â µ', 'â€™' ...
      Pattern: lead byte C2-F4 followed by continuation byte 80-BF          */
data work.mojibake(keep=_OBS _VAR _VALUE _HEX);
  set work.&mem;
  array _c{*} _character_;
  length _VAR $32 _VALUE $200 _HEX $400;
  _OBS = _n_;
  do _i = 1 to dim(_c);
    if prxmatch('/[\xC2-\xF4][\x80-\xBF]/', _c{_i}) then do;
      _VAR   = vname(_c{_i});
      _VALUE = _c{_i};
      _HEX   = put(trim(_c{_i}), $hex400.);
      output;
    end;
  end;
run;

title "3 - Suspected UTF-8 leftovers (should be EMPTY)";
proc print data=work.mojibake noobs; run;

/* 5. Show the bytes of the accented values: é must be E9, ü FC, µ B5 */
title "4 - Byte view of non-ASCII values";
data _null_;
  set work.&mem;
  array _c{*} _character_;
  length _name $32 _val $200;
  do _i = 1 to dim(_c);
    if prxmatch('/[\x80-\xFF]/', _c{_i}) then do;
      _name = vname(_c{_i});
      _val  = _c{_i};
      put _n_= _name= _val= / @5 _val $hex60.;
    end;
  end;
run;
title;

/* 6. Optional: compare with a trusted WLATIN1 reference data set
libname ref "C:\study\legacy_sdtm" access=readonly;
proc compare base=ref.&mem compare=work.&mem listall;
run;
*/
