# WLATIN1 → UTF-8 Clinical Data Demo (SDTM/ADaM on SAS Viya)

## What this demonstrates

A clinical program originally built on **Windows (session encoding `wlatin1`)** needs to:

1. Run **as-is** on SAS Viya, in a compute session that also uses `wlatin1` — no
   transcoding, byte-for-byte the same behavior the customer already trusts.
2. **Or** be migrated safely to a **UTF-8** Viya environment, with proof that no
   character data was lost or corrupted in the process.

Sample SDTM (`DM`, `AE`, `VS`) and ADaM (`ADSL`, `ADAE`) datasets are generated with
real Western-European accented characters (French/Spanish/Portuguese/Dutch — matches
Benelux/Iberia site data), plus one deliberately "hostile" record containing a
character that **wlatin1 cannot represent**, to show what happens when transcoding
hits a wall — a very real scenario in multi-country trials (e.g. a Polish site using
codepage windows-1250 instead of windows-1252/wlatin1).

## Why the datasets aren't shipped as pre-built .sas7bdat/.xpt files

The encoding tag inside a `.sas7bdat` header (what `PROC CONTENTS` reports as
"Data Set Encoding") has to be written by a real SAS session running in that
encoding — faking it from outside SAS risks a demo that silently breaks (data
readable, metadata wrong). Instead, the three programs below **generate the data
natively** the first time you run them, in whichever session encoding you launch
them under, so the encoding metadata is always genuine.

## Files

| File | Purpose | Run in |
|---|---|---|
| `00_create_sample_sdtm_adam_wlatin1.sas` | Builds `SDTM.DM/AE/VS` + `ADAM.ADSL/ADAE`, exports `.sas7bdat` and `.xpt` | **wlatin1** session |
| `01_demo_run_program_wlatin1_session.sas` | "The customer's program" — reads the data, proves encoding, produces AE summary | **wlatin1** session |
| `02_demo_migrate_to_utf8.sas` | Three safe migration paths + validation + the hostile-character edge case | **UTF-8** session |

## One thing to fix before you run this: the source file's own encoding

This `.sas` file is UTF-8 (so accented characters like `é`, `ñ`, `ã` survive in git/
email/chat). If you run it directly inside a `wlatin1`-encoded SAS Studio session,
SAS will read the *source code itself* using session encoding by default, and the
UTF-8 bytes for those accents will show as mojibake. Two options, both shown at the
top of `00_create_sample_sdtm_adam_wlatin1.sas`:

```sas
/* Option A: tell SAS the source file's real encoding, let it transcode on read */
filename src "/path/00_create_sample_sdtm_adam_wlatin1.sas" encoding="utf-8";
%include src;

/* Option B: in your editor, re-save this .sas file as Windows-1252 first,
   then just open/run it normally inside the wlatin1 session */
```

Option A is the better demo point — it's the same mechanism (`ENCODING=` on
`FILENAME`/`%INCLUDE`) you'd use for any external file whose encoding doesn't match
the session.

## Setting up a wlatin1 compute context on Viya

Session encoding in SAS Viya is a property of the **SAS Compute Server /
service**, not something you flip per-session with an option — it's set at
launch time. Two ways teams do this:

- **Dedicated wlatin1 compute service**: an additional SAS Compute Server
  configured with `-ENCODING WLATIN1`, exposed to users as a distinct compute
  context (e.g. "SAS Compute Server – wlatin1 legacy") alongside the default
  UTF-8 one. This is the setup you'd point to for "run it as-is."
- **Single UTF-8 Viya environment** (far more common in new Viya deployments,
  since Viya defaults to and strongly favors UTF-8): legacy wlatin1 data is
  transcoded on the way in, and nothing ever runs natively in wlatin1 on Viya.
  This is the setup that makes `02_demo_migrate_to_utf8.sas` the answer, not a
  fallback.

Worth naming explicitly in the demo: which of these two the target customer
actually has, since it changes which half of this demo is "the answer" and which
is "the option."

## XPT caveat

Classic SAS Transport (XPT, V5, via `PROC COPY`/`PROC CPORT` to an `xport`-engine
libref) is a fixed, ASCII-oriented format — it is **not** a safe carrier for
wlatin1 accented bytes across systems. The demo still produces `.xpt` files (some
customers require them for archival/regulatory reasons), but the script flags
where transport-format limitations bite, and `.sas7bdat` is the format actually
used for the encoding comparison.
