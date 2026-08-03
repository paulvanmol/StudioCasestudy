/*******************************************************************************
 02_demo_migrate_to_utf8.sas

 PURPOSE : Show two safe ways to move the wlatin1 SDTM/ADaM data to a UTF-8
           Viya environment with no character loss, plus a validation step,
           plus the one record that genuinely cannot round-trip cleanly
           (Polish diacritics that windows-1252/wlatin1 never had a slot for
           in the first place) - and how UTF-8 actually fixes that record
           rather than just carrying it along.

 RUN THIS : in a UTF-8 compute context. The source libraries below still
            point at the wlatin1-encoded data written by 00_*.sas; SAS reads
            foreign-encoded data through CEDA and auto-transcodes on the fly
            whenever the session and source encodings differ and the pair is
            supported - wlatin1 -> utf-8 is a supported pair.
*******************************************************************************/

%put NOTE: Session encoding is &sysencoding;
%if %upcase(&sysencoding) ne UTF-8 %then
    %put WARNING: This program expects SYSENCODING=UTF-8. Switch compute context.;

%let outpath = /demo/latin1;      /* source, still wlatin1-encoded on disk */
%let newpath = /demo/utf8;        /* migration target */

libname src_dm   "&outpath./sdtm";     /* wlatin1 data, read from a UTF-8 session */
libname src_adam "&outpath./adam";

libname tgt_sdtm "&newpath./sdtm";     /* UTF-8 target */
libname tgt_adam "&newpath./adam";

/*==============================================================*
 * METHOD 1 - implicit CEDA transcoding via PROC COPY            *
 * The simplest path for a handful of libraries: just read the   *
 * wlatin1 data from a UTF-8 session and copy it out. Watch the  *
 * log for the automatic transcoding NOTE.                       *
 *==============================================================*/
proc copy in=src_dm out=tgt_sdtm;
run;
proc copy in=src_adam out=tgt_adam;
run;

/* Expect a log NOTE similar to:
   "NOTE: Data file SRC_DM.DM.DATA was created under a host with a different
    encoding (WLATIN1). Cross Environment Data Access will be used, which
    might require the file to be re-encoded."
   -> that IS the transcode happening; no further action required for
   characters that exist in both encodings. */

/*==============================================================*
 * METHOD 2 - PROC MIGRATE                                      *
 * The recommended approach for a whole library at once,        *
 * including catalogs / indexes / audit trails, not just         *
 * individual tables. Prefer this for a real migration project.  *
 *==============================================================*/
proc migrate inlib=src_dm outlib=tgt_sdtm;
run;
proc migrate inlib=src_adam outlib=tgt_adam;
run;

/*==============================================================*
 * VALIDATION - prove nothing was silently dropped               *
 *==============================================================*/

/* 1. Row counts match, source vs. migrated target */
%macro check_n(src=, tgt=, label=);
    proc sql noprint;
        select count(*) into :n_src from &src;
        select count(*) into :n_tgt from &tgt;
    quit;
    %put NOTE: &label - source=&n_src target=&n_tgt %sysfunc(ifc(&n_src=&n_tgt,MATCH,%str(*** MISMATCH ***)));
%mend;
%check_n(src=src_dm.dm,     tgt=tgt_sdtm.dm,  label=DM);
%check_n(src=src_dm.ae,     tgt=tgt_sdtm.ae,  label=AE);
%check_n(src=src_dm.vs,     tgt=tgt_sdtm.vs,  label=VS);
%check_n(src=src_adam.adsl, tgt=tgt_adam.adsl, label=ADSL);
%check_n(src=src_adam.adae, tgt=tgt_adam.adae, label=ADAE);

/* 2. Character length sufficiency - UTF-8 accented characters can take up
      to 2-4 bytes where wlatin1 used 1. If the target variable length
      wasn't widened, values can silently truncate. Check both. */
proc sql;
    select name, length as wlatin1_length
    from dictionary.columns
    where libname='SRC_DM' and memname='DM' and name='INVNAM';
    select name, length as utf8_length
    from dictionary.columns
    where libname='TGT_SDTM' and memname='DM' and name='INVNAM';
quit;

/* 3. Content check on the accented fields specifically */
title "Post-migration investigator names (UTF-8 session)";
proc print data=tgt_sdtm.dm noobs label;
    var siteid invnam invctry;
run;
title;

/* 4. PROC COMPARE as a belt-and-braces check on the non-character content */
proc compare base=src_dm.dm compare=tgt_sdtm.dm listall;
    id usubjid;
run;

/*==============================================================*
 * THE EDGE CASE - Polish diacritics                            *
 * wlatin1/windows-1252 has no code point for l-with-stroke (l)  *
 * or n-with-acute (n), so the source record was already stored  *
 * as a transliteration/placeholder on Windows - it's not a      *
 * migration bug, it's a pre-existing limitation of wlatin1       *
 * itself. UTF-8 is the first encoding in this chain that CAN     *
 * hold the real characters, so this is the point in the demo    *
 * where migrating to UTF-8 is a net improvement, not just a      *
 * safe copy.                                                     *
 *==============================================================*/
data tgt_sdtm.dm;
    set tgt_sdtm.dm;
    if usubjid = 'CT2026EU01-450-010' then
        invnam = 'Dr hab. n. med. Łukasz Kamiński';  /* now representable */
run;

title "Site 450 investigator - before vs. after UTF-8 migration";
proc print data=tgt_sdtm.dm noobs label;
    where usubjid = 'CT2026EU01-450-010';
    var invnam;
run;
title;

%put NOTE: Migration + validation complete. See log for CEDA transcoding notes.;
