# Advanced topic – Migrating legacy WLATIN1 data to UTF-8

[Back to README](../README.md) · Prerequisite: [Demo 5](../demos/05-encoding-and-compute-contexts.md)

## Goal

Migrate the legacy study created in Demo 5 (`LEGACY.AE_LEGACY` + format catalog) to a **UTF-8** library **without losing characters**, migrate the formats and indexes, and **validate** the result.

| Step | Technique | Session |
|---|---|---|
| 0 | Prepare the legacy study (index + format export) | WLATIN1 |
| 1 | Determine the encoding of each data set | UTF-8 |
| 2 | Determine storage-size requirements | UTF-8 |
| 3a | Copy with the CVP engine | UTF-8 |
| 3b | Migrate a whole library with PROC MIGRATE + CVP | UTF-8 |
| 3c | Alternative: CPORT (WLATIN1) / CIMPORT (UTF-8) | both |
| 4 | Re-create format catalogs (CNTLOUT / CNTLIN) | both |
| 5 | Re-create indexes and integrity constraints | UTF-8 |
| 6 | Validate the migrated data | UTF-8 |

Folders used (from `programs/00_setup_paths.sas`):

```sas
%let work = %sysget(HOME)/servier_work;
/* &work/legacy_wlatin1 : source (read-only)  */
/* &work/utf8           : target              */
/* &work/transfer       : CPORT transport file */
```

---

## Step 0 – Prepare the legacy study (WLATIN1 compute context)

Run `programs/05b_create_legacy_wlatin1.sas` first, then:

```sas
%let work = %sysget(HOME)/servier_work;
libname legacy "&work/legacy_wlatin1";

/* An index, so we can show index migration */
proc datasets lib=legacy nolist;
  modify ae_legacy;
  index create usubjid / unique;
quit;

/* Export the format catalog to a data set (CNTLOUT=)          */
/* Must be done in the encoding in which the format was created */
proc format lib=legacy cntlout=legacy.formats_cntlout;
run;

/* Transport file for the CPORT/CIMPORT alternative (step 3c) */
options dlcreatedir;
filename xpt "&work/transfer/legacy_study.cpt";
proc cport lib=legacy file=xpt memtype=all;
run;
```

Switch back to the **default UTF-8** compute context for all following steps (use the safe-switch checklist from Demo 5).

## Step 1 – Determine the encoding of each data set

```sas
%let work = %sysget(HOME)/servier_work;
libname legacy "&work/legacy_wlatin1" access=readonly;

proc sql;
  title "Encoding of the legacy data sets";
  select memname, encoding, nobs
    from dictionary.tables
    where libname='LEGACY' and memtype='DATA';
quit;
title;
```

## Step 2 – Determine storage-size requirements

How many **bytes** does each character column need in UTF-8? Read through CVP (so nothing is truncated) and measure with `LENGTHN` (byte length).

```sas
libname legcvp cvp "&work/legacy_wlatin1" cvpmultiplier=2 access=readonly;

proc sql noprint;
  select cats('max(lengthn(', name, ')) as ', name)
    into :maxlist separated by ', '
    from dictionary.columns
    where libname='LEGCVP' and memname='AE_LEGACY' and type='char';
quit;

proc sql;
  title "Bytes needed in UTF-8 per character column";
  create table work.utf8_needed as
    select &maxlist from legcvp.ae_legacy;
  select * from work.utf8_needed;
quit;
title;
```

Compare with the original lengths (`AETERM $8`, `AEUNIT $2`). Decide your rule:

- **Multiplier** (`CVPMULTIPLIER=`) – simple, may waste space;
- **Fixed extra bytes** (`CVPBYTES=`) – predictable;
- **Right-size** – use the measured lengths in an explicit LENGTH statement (best for submission data where lengths matter).

## Step 3a – Copy data sets with the CVP engine

```sas
options dlcreatedir;
libname utf8 "&work/utf8";

proc datasets lib=legcvp nolist;
  copy out=utf8 noclone;
  select ae_legacy;
quit;

proc contents data=utf8.ae_legacy; ods select attributes variables; run;
```

`NOCLONE` makes the output data set take the **session encoding (UTF-8)** instead of copying the input attributes.

✅ The log contains **no** transcoding error, `Encoding` is `utf-8 Unicode (UTF-8)`, and `AETERM`/`AEUNIT` are wider.

## Step 3b – Migrate a whole library with PROC MIGRATE

```sas
libname utf8b "&work/utf8_migrate";

proc migrate in=legcvp out=utf8b;
run;

proc contents data=utf8b._all_ nods; run;
```

## Step 3c – Alternative: CPORT / CIMPORT

The transport file was created in step 0 in the WLATIN1 session. Import it in UTF-8:

```sas
libname utf8c "&work/utf8_cimport";
filename xpt "&work/transfer/legacy_study.cpt";

proc cimport lib=utf8c infile=xpt extendvar=2;
run;
```

CIMPORT transcodes to the session encoding and restores data sets, catalogs and indexes. `EXTENDVAR=` widens character columns to avoid truncation – check that your release supports it in the PROC CIMPORT documentation.

## Step 4 – Re-create the format catalog in UTF-8

CEDA does **not** transcode format catalogs. Use the CNTLOUT data set from step 0, read it through **CVP** (so long labels such as `Modérée` are not truncated), and rebuild the format:

```sas
proc format lib=utf8 cntlin=legcvp.formats_cntlout;
run;

options fmtsearch=(utf8 work library);
data _null_;
  do sev = 'L', 'M', 'S';
    put sev= sev $sev.;
  end;
run;
```

✅ The log shows `Légère`, `Modérée`, `Sévère` correctly.

## Step 5 – Re-create indexes and integrity constraints

CEDA cannot always use or transcode indexes – re-create them on the migrated data.

```sas
/* 1. Get the index definitions (OUT2= has a 'Recreate' column with code) */
proc contents data=legacy.ae_legacy out2=work.idx_def noprint;
run;
proc print data=work.idx_def; var name type recreate; run;

/* 2. Re-create the index on the UTF-8 copy */
proc datasets lib=utf8 nolist;
  modify ae_legacy;
  index create usubjid / unique;
quit;

proc contents data=utf8.ae_legacy; ods select indexes; run;
```

## Step 6 – Validate the migrated data

Compare the source (read through CVP, so nothing is lost) with the target:

```sas
proc compare base=legcvp.ae_legacy compare=utf8.ae_legacy
             listall criterion=0;
run;
```

Expected: no value differences. Differences in **lengths** are expected and are reported as attribute differences.

Extra checks:

```sas
/* Row counts */
proc sql;
  select 'legacy' as src, count(*) as n from legcvp.ae_legacy
  union all
  select 'utf8',          count(*)      from utf8.ae_legacy;
quit;

/* Any invalid UTF-8 or replacement characters left? */
data work.suspect;
  set utf8.ae_legacy;
  array c _character_;
  do over c;
    if index(c, 'EFBFBD'x) then do; output; leave; end;   /* U+FFFD replacement character */
  end;
run;
```

🛡️ **Good practice** – keep the legacy library read-only, keep the migration program and its log under version control, and document the length rule you used. The validation output is part of the migration evidence.

## Clean up

```sas
libname legcvp clear; libname legacy clear;
libname utf8 clear; libname utf8b clear; libname utf8c clear;
filename xpt clear;
```
