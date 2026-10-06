# Change Encoding – Convert SAS Programs to UTF-8

`encode-changer.py` converts SAS programs from legacy encodings (WLATIN1, LATIN9, WLATIN2, …) to **UTF-8**, so they can be used safely in a SAS Viya / UTF-8 SAS session and versioned consistently in Git.

The script detects the encoding of each file, converts it without silently corrupting characters, and writes an **audit CSV** so every decision can be reviewed.

---

## Contents

- [Folder structure](#folder-structure)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Command-line options](#command-line-options)
- [How encoding detection works](#how-encoding-detection-works)
- [The audit report](#the-audit-report)
- [Handling REVIEW and FAILED files](#handling-review-and-failed-files)
- [Encoding name mapping (Python ↔ SAS)](#encoding-name-mapping-python--sas)
- [Using the converted programs in SAS](#using-the-converted-programs-in-sas)
- [Limitations](#limitations)

---

## Folder structure

```text
changeencoding/
├── README.md                 # this documentation
├── encode-changer.py         # conversion script
├── old/                      # source SAS programs (original encodings)
│   └── ...
└── new/                      # converted UTF-8 programs (generated)
    ├── ...
    └── conversion_audit.csv  # audit report (generated)
```

The subfolder structure of `old/` is reproduced in `new/`. Files in `old/` are never modified.

---

## Requirements

- Python **3.7+**
- Optional: [`chardet`](https://pypi.org/project/chardet/). If it's installed, the audit report includes chardet's guess as a second opinion. The script works without it.

```bash
pip install chardet      # optional
```

---

## Quick start

```bash
cd ~/StudioCasestudy/changeencoding

# 1. Preview: write only the audit report, no converted files
python encode-changer.py --dry-run

# 2. Convert old/ -> new/
python encode-changer.py
```

Example console output:

```text
OK      UNCHANGED ascii       ascii.sas
REVIEW  CONVERTED mixed       mixed.sas  REVIEW: 1 UTF-8 + 1 legacy lines
FIXED   CONVERTED utf-8       mojibake.sas  FIXED: double-encoded UTF-8 repaired
OK      CONVERTED cp1250      sub/wlatin2.sas
OK      UNCHANGED utf-8       utf8.sas
OK      CONVERTED cp1252      wlatin1.sas

Summary: {'OK': 4, 'REVIEW': 1, 'FIXED': 1}
Audit:   new/conversion_audit.csv
```

---

## Command-line options

| Option | Default | Description |
|---|---|---|
| `--source DIR` | `/home/student/StudioCasestudy/changeencoding/old` | Folder with the original programs (searched recursively) |
| `--output DIR` | `/home/student/StudioCasestudy/changeencoding/new` | Folder for the converted programs and the audit CSV |
| `--ext EXT [EXT ...]` | `.sas` | File extensions to process, e.g. `--ext .sas .csv .txt` |
| `--legacy ENC [ENC ...]` | `cp1252 iso-8859-15 cp1250` | Legacy encodings to try, **in order of preference** |
| `--override FILE=ENC [...]` | – | Force the encoding of a specific file (matched by file name) |
| `--dry-run` | off | Write only the audit report; no converted files |

Examples:

```bash
# Use relative paths
python encode-changer.py --source old --output new

# Also convert CSV files
python encode-changer.py --ext .sas .csv

# Central European source code: prefer WLATIN2
python encode-changer.py --legacy cp1250 cp1252

# Force the encoding of two files
python encode-changer.py --override adsl.sas=cp1250 macros.sas=cp1252
```

---

## How encoding detection works

Most SAS programs are almost entirely ASCII, with only a few accented characters in comments, labels or formats. That isn't enough data for statistical detectors such as chardet, which is why they often guess wrong. This script uses **deterministic checks first** and scores the text only as a last step.

| Step | Check | Result |
|---|---|---|
| 1 | Empty file | Copied as-is |
| 2 | Byte Order Mark (UTF-8 / UTF-16) | Encoding is certain; BOM is removed |
| 3 | Pure ASCII | Already valid UTF-8, copied unchanged |
| 4 | Strict UTF-8 decode succeeds | UTF-8, copied unchanged (double-encoded text such as `DonnÃ©es` is repaired to `Données`) |
| 5 | Some lines are UTF-8, others are not | **Mixed** file, decoded line by line, flagged `REVIEW` |
| 6 | Otherwise | Each `--legacy` encoding is tried strictly; the result that looks most like real text wins. Close calls are flagged `REVIEW` |

Safety measures:

- **Strict decoding.** Nothing is replaced with `?` or `�`. A file that can't be decoded is reported, not corrupted.
- **Byte-identical copies.** ASCII and UTF-8 files are copied unchanged, so Git shows no false changes.
- **Line endings are preserved.** CRLF stays CRLF and LF stays LF.
- **Verification.** Each written file is read back and checked against the converted text.

---

## The audit report

`new/conversion_audit.csv` contains one row per file:

| Column | Meaning |
|---|---|
| `File` | Path relative to the source folder |
| `DetectedEncoding` | Python encoding name used to decode the file |
| `SASEncoding` | Equivalent SAS encoding name (e.g. `wlatin1`) |
| `Method` | How the encoding was determined: `ascii`, `bom`, `utf8-strict`, `line-by-line`, `legacy-scored`, `override`, `empty` |
| `Action` | `CONVERTED`, `UNCHANGED` or `FAILED` |
| `Status` | `OK`, `FIXED`, `REVIEW` or `FAILED` |
| `Note` | Explanation for non-OK statuses |
| `ChardetGuess` / `ChardetConfidence` | chardet's opinion (if installed), for comparison only |
| `NonAsciiSample` | First line containing non-ASCII characters, for a quick visual check |

Status values:

| Status | Meaning | Action needed |
|---|---|---|
| `OK` | Detection was clear | None |
| `FIXED` | Double-encoded UTF-8 was repaired | Spot-check the file |
| `REVIEW` | Mixed file, or two encodings scored almost the same | Check `NonAsciiSample`; use `--override` if wrong |
| `FAILED` | The file couldn't be processed | See `Note` |

---

## Handling REVIEW and FAILED files

1. Open `conversion_audit.csv` and filter on `Status` = `REVIEW` or `FAILED`.
2. Look at `NonAsciiSample`. Do the characters look right (`é`, `ü`, `€`, `ł`, …)?
3. If not, rerun the script with the correct encoding for that file:

   ```bash
   python encode-changer.py --override problem_program.sas=cp1250
   ```

4. Compare the result with the original in SAS Studio or VS Code before committing it.

Tip: `--override` matches on the **file name only**. Rename files first if the same name appears in several subfolders and they need different encodings.

---

## Encoding name mapping (Python ↔ SAS)

| Python | SAS `ENCODING=` | Typical source |
|---|---|---|
| `ascii` | `us-ascii` | Plain code without accents |
| `utf-8` | `utf-8` | SAS Viya, modern editors |
| `cp1252` | `wlatin1` | SAS 9.4 on Windows, Western Europe |
| `iso-8859-1` | `latin1` | SAS 9 on UNIX/Linux |
| `iso-8859-15` | `latin9` | UNIX/Linux with the `€` sign |
| `cp1250` | `wlatin2` | Windows, Central/Eastern Europe |

---

## Using the converted programs in SAS

Run the converted programs in a **UTF-8 SAS session** (the default in SAS Viya). Check the session encoding with:

```sas
%put Session encoding: &=sysencoding;
```

To read an **unconverted** program from a UTF-8 session, specify its encoding explicitly:

```sas
filename legacy "/workshop/old/adsl.sas" encoding="wlatin1";
%include legacy;
```

Converting the code doesn't convert the **data**. SAS datasets created in WLATIN1 still need CVP / `ENCODING=` handling or a migration (for example PROC MIGRATE, or a DATA step with `ENCODING='ANY'` plus `KCVT`). Also review character variable lengths, because accented characters take 2 or more bytes in UTF-8.

---

## Limitations

- Detection of legacy single-byte encodings is a **best judgement**, not a certainty. Files with very few accented characters can still score close between encodings. These are flagged `REVIEW`.
- Only the encodings listed in `--legacy` are tried. Add others if needed (e.g. `cp1257` for the Baltic states, `cp1251` for Cyrillic).
- Double-byte encodings (Shift-JIS, GBK, …) aren't detected unless they're added to `--legacy`.
- The whole file is read into memory. This is fine for SAS programs but not designed for very large data files.
