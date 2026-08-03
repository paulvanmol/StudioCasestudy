# Clinical Trial Encoding Demo for SAS Viya

This pack contains a ready-to-run SAS demo script for a clinical-trial programming scenario where legacy SAS programs and data were created on Windows using WLATIN1 / Windows-1252, and the target runtime is SAS Viya.

## Files

- `clinical_encoding_demo_wlatin1.sas`  
  The main demo script. It is saved as Windows-1252 / WLATIN1 so that accented clinical text is represented in the legacy source encoding.

## What the script creates

The script creates synthetic clinical trial data only, with SDTM-style and ADaM-style domains:

- SDTM: `DM`, `AE`, `LB`
- ADaM: `ADSL`, `ADAE`, `ADLB`
- XPT exports for each domain
- Validation output and an HTML summary report

## Demo flow

1. Run the script in a custom LATIN1 / WLATIN1 SAS Compute context to show compatibility with legacy Windows-encoded clinical programs.
2. Rerun the migration sections in a UTF-8 session to show safe migration practices.
3. Validate with `PROC CONTENTS`, `PROC COMPARE`, record counts, byte-level checks, and index usage checks.

## Notes

- The script intentionally includes Western European characters such as `é`, `ü`, `ñ`, `Å`, `µ`, and `€`-style scenarios.
- For a live customer demo, align the SAS Studio editor encoding with the Compute context encoding before opening or saving the source program.
- Replace `_demo_root` at the top of the program with a writable server-side path if you do not want to use the WORK directory.
