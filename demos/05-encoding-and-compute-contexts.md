# Demo 5 – Encoding: switch compute context and default text encoding safely

⏱️ 30 min · Slides: *Working with Encoding* · [← Demo 4](04-table-viewer-and-data-access.md) · [README](../README.md) · [Demo 6 →](06-python-and-r.md)

## Goal

Recognise the encoding of your session, your data and your programs; switch **safely** between the default UTF-8 compute context and a WLATIN1 compute context for legacy studies; and see what goes wrong when the settings are not aligned.

> This demo is about *recognising and avoiding* problems. How to **migrate** legacy data to UTF-8 is covered in the advanced topic [Encoding – migrating data to UTF-8](../advanced/encoding-utf8-migration.md).

## The two settings you must align

| Setting | Where | Controls |
|---|---|---|
| **Compute context** | Top right of SAS Studio | Encoding of the **SAS session** (`&SYSENCODING`): how data is read, written and transcoded |
| **Default text encoding** | **Settings > SAS Studio > General** | Encoding SAS Studio uses to **open and save program and text files** on disk |

They are **independent**. Switching one does not switch the other.

| Study type | Compute context | Default text encoding |
|---|---|---|
| New study (default) | SAS Studio compute context (UTF-8) | UTF-8 |
| Legacy study | WLATIN1/LATIN1 compute context (set up by your administrator) | Western European (WLATIN1 / Windows-1252) – **only if** the legacy programs were saved in that encoding |

> The context names in your environment may differ – ask your trainer for the exact WLATIN1 context name.

## Part A – Where am I? (UTF-8)

1. Check that the compute context at the top right is the **default** context.
2. Open and run `programs/05a_check_encoding.sas`.

✅ **Checkpoint** – the log shows `Session encoding = utf-8`; PROC OPTIONS shows `ENCODING=UTF-8`; PROC CONTENTS of SASHELP.CLASS shows the data set encoding.

## Part B – Switch safely to the WLATIN1 compute context

**Safe-switch checklist** – do this *before* you switch:

- [ ] Save all open programs (**Save all** on the toolbar).
- [ ] Anything in **WORK** you still need? Switching starts a **new session**: WORK, macro variables, librefs assigned in code and CAS sessions from code are gone.
- [ ] Wait until running or background submissions you depend on have finished.

Switch:

1. Click the compute context name at the top right and select the **WLATIN1** context.
2. Confirm the message that the session will be reset.
3. Run `programs/05a_check_encoding.sas` again.

✅ **Checkpoint** – `Session encoding = wlatin1` (or `latin1`). The autoexec was executed again – check that `CSTUDY` is still in Library Connections.

## Part C – Create a "legacy study" (in WLATIN1)

1. Open `programs/05b_create_legacy_wlatin1.sas`. Read the safety check at the top: the program stops if the session is not LATIN1/WLATIN1.
2. Run it.
3. Review the PROC CONTENTS output: **Encoding = wlatin1 Western (Windows)** (or latin1).
4. Look at the lengths: `AETERM $8`, `AEUNIT $2` – exactly enough for single-byte characters such as `é`, `è`, `µ`.

> The program file itself is stored in UTF-8 (it comes from Git). SAS Studio opens it with the **default text encoding UTF-8** and sends the code to the WLATIN1 session, which transcodes the submitted text. That is why `é` is still correct in the data. Editor encoding = *file on disk*; compute context = *session*.

## Part D – Back to UTF-8: what goes wrong?

1. Use the safe-switch checklist and switch back to the **default (UTF-8)** compute context.
2. Open and run `programs/05c_read_legacy_in_utf8.sas`.
3. Read the log and find:
   - the **CEDA note** – the data set encoding differs from the session encoding, so Cross Environment Data Access is used to transcode;
   - the **ERROR** that *some character data was lost during transcoding* – `Céphalée`, `Asthénie` and `µg` need more bytes in UTF-8 than the column length allows.
4. Look at the CVP part of the program: the same data read through the **CVP engine** (`cvpmultiplier=2`) has wider character columns and no data is lost. Compare the lengths in the SQL report.
5. Look at the **format test**: the format catalog created in WLATIN1 is *not* transcoded by CEDA – the format cannot be used correctly in the UTF-8 session.

**Questions for the group**

- Why did `Fièvre` and `Nausée` survive, but `Céphalée` not?
- Would you accept `WORK.AE_CEDA` as input for an analysis data set?
- Why is `legacy` assigned with `access=readonly`?

🛡️ **Good practice** – never let an encoding problem pass silently. A transcoding ERROR or truncated value in a clinical data set is a data-integrity issue: stop, document, and use the agreed migration procedure.

## Part E – Default text encoding of programs

Legacy programs may contain characters (in comments, titles, footnotes, formats) that were saved in WLATIN1.

1. Create a legacy-encoded program file – run this in the **UTF-8** session:

```sas
data _null_;
  file "&work/legacy_program.sas" encoding=wlatin1;
  put '/* Programme : Tableau des événements indésirables */';
  put 'title "Événements indésirables - population de tolérance";';
  put 'proc print data=sashelp.class(obs=3); run;';
run;
```

2. In **SAS Server**, open `servier_work/legacy_program.sas`. The accented characters display as `�` – the file is WLATIN1 but the editor reads it as UTF-8.
3. **Close the file without saving** (saving now would make the damage permanent).
4. Change **Settings > SAS Studio > General > Default text encoding** to **Western European (Windows-1252 / WLATIN1)**.
5. Open the file again – the characters display correctly.
6. Set the default text encoding back to **UTF-8**.

To *include* a legacy program without opening it, tell SAS its encoding:

```sas
%include "&work/legacy_program.sas" / encoding='wlatin1';
```

And for an external text/CSV file from a legacy study:

```sas
filename dm "&work/dm_legacy.csv" encoding='wlatin1';
```

## Part F – Checklist before running study code

Copy this checklist into your study notes:

- ✔ Verify the **study encoding** (legacy WLATIN1 or UTF-8) – PROC CONTENTS / `05a_check_encoding.sas`.
- ✔ Verify the **SAS Studio compute context** (default UTF-8 or WLATIN1) – `&SYSENCODING`.
- ✔ Verify the **default text encoding** of the editor matches the encoding of the program files.
- ✔ Verify that the program **opens correctly** – special characters display correctly before you save.
- ✔ Never save a legacy program after it opened with wrong characters.
- ✔ Assign legacy libraries **read-only**; write migrated data to a new location.

## Trainer notes

- If no WLATIN1 compute context is available, skip Parts B and C and use a legacy library prepared once by the trainer (run `05b_create_legacy_wlatin1.sas` in a WLATIN1 session and share the folder read-only).
- The exact wording of the CEDA NOTE and transcoding ERROR depends on the release – show it live rather than from the slides.
