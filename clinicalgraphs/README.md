# Clinical Graphs – SAS Studio Custom Steps

Ready-to-use **SAS Studio custom steps** that produce standard clinical trial graphs, plus **synthetic ADaM-style sample data** to demonstrate them.

The steps use ODS Graphics (`PROC SGPLOT`, `PROC LIFETEST`) and can be used in SAS Studio flows or as stand-alone steps.

> ⚠️ All data in this folder is **synthetic** (randomly generated with a fixed seed). It contains no real patient data and must not be used to draw clinical conclusions.

---

## Contents

- [Folder structure](#folder-structure)
- [Graphs overview](#graphs-overview)
- [Requirements](#requirements)
- [Getting started](#getting-started)
- [Custom step reference](#custom-step-reference)
  - [Kaplan-Meier plot](#1-kaplan-meier-plot)
  - [Forest plot](#2-forest-plot)
  - [Waterfall plot](#3-waterfall-plot)
  - [Swimmer plot](#4-swimmer-plot)
  - [Mean over time](#5-mean-over-time)
  - [eDISH plot](#6-edish-plot)
- [Sample data dictionary](#sample-data-dictionary)
- [Using your own data](#using-your-own-data)
- [Troubleshooting](#troubleshooting)
- [Limitations](#limitations)

---

## Folder structure

```text
clinicalgraphs/
├── README.md
├── load_sample_data.sas        # imports the CSV files into SAS tables
├── test_all_graphs.sas         # quick test without custom steps
├── data/
│   ├── adtte.csv               # time-to-event (OS)
│   ├── forest_os.csv           # subgroup hazard ratios
│   ├── adtr.csv                # tumour response (best % change)
│   ├── adswim.csv              # treatment / response duration
│   ├── adlb.csv                # lab values by visit (HbA1c)
│   └── adlb_edish.csv          # peak ALT and bilirubin (xULN)
└── steps/
    ├── Clinical_Kaplan_Meier_Plot.step
    ├── Clinical_Forest_Plot.step
    ├── Clinical_Waterfall_Plot.step
    ├── Clinical_Swimmer_Plot.step
    ├── Clinical_Mean_Over_Time.step
    └── Clinical_eDISH_Plot.step
```

---

## Graphs overview

| Graph | Typical use in a clinical trial | Domain | Sample table |
|---|---|---|---|
| **Kaplan-Meier plot** | Time-to-event endpoints (OS, PFS), number at risk, log-rank test | Efficacy | `ADTTE` |
| **Forest plot** | Treatment effect (hazard ratio, 95% CI) across subgroups | Efficacy | `FOREST_OS` |
| **Waterfall plot** | Best % change in tumour size per subject (RECIST) | Oncology efficacy | `ADTR` |
| **Swimmer plot** | Treatment duration, response periods, ongoing treatment per subject | Oncology efficacy | `ADSWIM` |
| **Mean over time** | Mean (± SE or 95% CI) by visit and treatment, with N at risk | Efficacy / safety | `ADLB_CHG` |
| **eDISH plot** | Drug-induced liver injury screening (Hy's Law) | Safety | `ADLB_EDISH` |

---

## Requirements

- **SAS Viya** (SAS Studio), or **SAS 9.4M5+** with SAS Studio 5.x
  - `XAXISTABLE` / `YAXISTABLE` (Forest and Mean over time) need SAS 9.4M5 or later.
- SAS/STAT for `PROC LIFETEST` (Kaplan-Meier).
- The repository cloned in SAS Studio, e.g. `/workshop/<userid>/StudioCasestudy`.

---

## Getting started

### 1. Load the sample data

Open `load_sample_data.sas`, set the repository path and run it:

```sas
%let repo=/workshop/&sysuserid/StudioCasestudy/clinicalgraphs;
```

By default the tables go to a `CGDATA` library pointing to WORK. Change the `LIBNAME` statement to make them permanent.

| Table created | Source |
|---|---|
| `CGDATA.ADTTE` | `adtte.csv` |
| `CGDATA.FOREST_OS` | `forest_os.csv` |
| `CGDATA.ADTR` | `adtr.csv` |
| `CGDATA.ADSWIM` | `adswim.csv` |
| `CGDATA.ADLB` | `adlb.csv` |
| `CGDATA.ADLB_CHG` | `ADLB` where `AVISITN > 0` (post-baseline only) |
| `CGDATA.ADLB_EDISH` | `adlb_edish.csv` |

### 2. Check the environment (optional)

Run `test_all_graphs.sas`. It draws a Kaplan-Meier plot and an eDISH plot directly with SAS code, without the custom steps.

### 3. Use the custom steps

1. In SAS Studio, open **Explorer** and browse to `clinicalgraphs/steps/`.
2. Open a `.step` file. To make it available in the **Steps** pane, save a copy to *My Folder* or to a shared custom-steps folder.
3. Create a new **Flow**, drag in the input table (e.g. `CGDATA.ADTTE`), then drag in the custom step and connect them.
4. Fill in the options (see the [reference](#custom-step-reference) below) and run.

---

## Custom step reference

All steps have one input port (`inputtable1`) and write the graph to the Results tab. Every step also has a **Graph title** option.

### 1. Kaplan-Meier plot

Survival curves by treatment with censoring marks, number-at-risk table and log-rank p-value.

| Option | Sample value | Notes |
|---|---|---|
| Input table | `CGDATA.ADTTE` | One record per subject (filter on `PARAMCD` first if needed) |
| Time variable | `AVAL` | Numeric |
| Censor variable | `CNSR` | `1` = censored, `0` = event (ADaM convention) |
| Treatment variable | `TRT01P` | Strata |
| Number-at-risk interval | `90` | Same unit as `AVAL` (days) |

### 2. Forest plot

Subgroup hazard ratios with 95% CI on a log scale, with subgroup headers, N column and "HR (95% CI)" text column.

| Option | Sample value | Notes |
|---|---|---|
| Input table | `CGDATA.FOREST_OS` | One row per subgroup category, **sorted in display order** |
| Subgroup variable | `SUBGROUP` | Shown as a bold header row |
| Category variable | `CATEGORY` | Indented below the header |
| N variable | `N` | |
| Estimate | `HR` | Must be > 0 (log axis) |
| Lower / Upper CL | `LCL` / `UCL` | |
| Reference line | `1` | No-effect line |
| X-axis label | `Hazard Ratio (95% CI)` | |

> The step plots estimates that have already been calculated. In a real study, derive them with `PROC PHREG` (e.g. `BY` subgroup with `ODS OUTPUT ParameterEstimates=` and `HAZARDRATIO`).

### 3. Waterfall plot

One bar per subject, sorted from worst to best change, coloured by best overall response.

| Option | Sample value | Notes |
|---|---|---|
| Input table | `CGDATA.ADTR` | One record per subject |
| Best % change | `PCHG` | |
| Colour by | `BOR` | CR / PR / SD / PD |
| Upper reference line | `20` | RECIST progression threshold |
| Lower reference line | `-30` | RECIST partial-response threshold |

### 4. Swimmer plot

Horizontal bar per subject showing treatment duration, with an optional response-duration line and ongoing-treatment arrows.

| Option | Sample value | Notes |
|---|---|---|
| Input table | `CGDATA.ADSWIM` | One record per subject |
| Subject ID | `USUBJID` | |
| Treatment duration | `TRTDURM` | Months |
| Colour by | `BOR` | |
| Response start / end | `RSPSTM` / `RSPENDM` | Optional, leave both empty to skip |
| Ongoing flag | `ONGOING` | Optional, `Y` draws an arrow |
| X-axis label | `Months since start of treatment` | |

> Best for about 50 subjects or fewer. The graph height grows with the number of subjects.

### 5. Mean over time

Calculates summary statistics with `PROC MEANS` and plots the mean ± error bar per visit and treatment, with a "Number of subjects" table below the x-axis.

| Option | Sample value | Notes |
|---|---|---|
| Input table | `CGDATA.ADLB_CHG` | Long format: one record per subject per visit |
| Visit number variable | `AVISITN` | Numeric, used for ordering |
| Analysis value | `CHG` | Or `AVAL` for absolute values |
| Treatment variable | `TRT01P` | |
| Error bar | `SE` or `95% CI` | |
| Y-axis label | `Mean change from baseline` | |

> Filter to a single parameter (`PARAMCD`) before the step when the table holds several lab tests.

### 6. eDISH plot

Peak ALT vs. peak total bilirubin (both as multiples of the upper limit of normal) on log scales, divided into four quadrants.

| Option | Sample value | Notes |
|---|---|---|
| Input table | `CGDATA.ADLB_EDISH` | One record per subject |
| Peak ALT/ULN | `ALTULN` | |
| Peak bilirubin/ULN | `BILIULN` | |
| Treatment variable | `TRT01P` | |

| Quadrant | Criteria | Interpretation |
|---|---|---|
| Upper right | ALT ≥ 3×ULN and bilirubin ≥ 2×ULN | **Potential Hy's Law**, needs medical review |
| Lower right | ALT ≥ 3×ULN, bilirubin < 2×ULN | Temple's Corollary (hepatocellular injury) |
| Upper left | ALT < 3×ULN, bilirubin ≥ 2×ULN | Hyperbilirubinemia / cholestasis |
| Lower left | Both below threshold | Normal range |

---

## Sample data dictionary

All tables: 180 subjects (`XYZ123-0101` to `XYZ123-0280`) in three treatment arms: `Placebo`, `Drug A 10 mg`, `Drug A 20 mg`.

### adtte.csv – time to event

| Variable | Description |
|---|---|
| `USUBJID` | Unique subject identifier |
| `PARAMCD` / `PARAM` | `OS` / Overall Survival (days) |
| `TRT01P` | Planned treatment |
| `AGEGR1`, `SEX`, `REGION`, `ECOG` | Subgroup variables |
| `AVAL` | Time to event or censoring (days) |
| `CNSR` | `0` = event, `1` = censored |

### forest_os.csv – subgroup estimates

| Variable | Description |
|---|---|
| `SUBGROUP` | Overall, Age group, Sex, Region, ECOG |
| `CATEGORY` | Subgroup level |
| `N` | Number of subjects |
| `HR`, `LCL`, `UCL` | Hazard ratio and 95% confidence limits (illustrative values) |

### adtr.csv – tumour response (90 subjects)

| Variable | Description |
|---|---|
| `USUBJID`, `TRT01P` | Subject and treatment |
| `PCHG` | Best % change from baseline in sum of target lesions |
| `BOR` | Best overall response (CR, PR, SD, PD) |

### adswim.csv – duration (30 subjects)

| Variable | Description |
|---|---|
| `USUBJID`, `TRT01P` | Subject and treatment |
| `TRTDURM` | Treatment duration (months) |
| `BOR` | Best overall response |
| `RSPSTM`, `RSPENDM` | Response start and end (months). Empty for SD/PD |
| `ONGOING` | `Y` = still on treatment |

### adlb.csv – lab values by visit

| Variable | Description |
|---|---|
| `USUBJID`, `TRT01P` | Subject and treatment |
| `PARAMCD` / `PARAM` | `HBA1C` / HbA1c (%) |
| `AVISITN` / `AVISIT` | 0 = Baseline, 2, 4, 8, 12, 24 = Week n |
| `AVAL`, `BASE`, `CHG` | Value, baseline value, change from baseline |

### adlb_edish.csv – liver function

| Variable | Description |
|---|---|
| `USUBJID`, `TRT01P` | Subject and treatment |
| `ALTULN` | Peak ALT / ULN |
| `BILIULN` | Peak total bilirubin / ULN |

---

## Using your own data

The steps work with any table that has the required columns. Some common preparation steps:

```sas
/* Kaplan-Meier: one parameter only */
data work.pfs; set adam.adtte; where paramcd='PFS'; run;

/* Mean over time: one lab parameter, post-baseline */
data work.alt; set adam.adlb; where paramcd='ALT' and avisitn>0 and anl01fl='Y'; run;

/* eDISH: peak values per subject as multiples of ULN */
proc sql;
  create table work.edish as
  select usubjid, trt01a as trt01p,
         max(case when paramcd='ALT'  then aval/anrhi end) as altuln,
         max(case when paramcd='BILI' then aval/anrhi end) as biliuln
  from adam.adlb
  where anl01fl='Y'
  group by usubjid, trt01a;
quit;
```

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `ERROR: Unrecognized SAS option name XAXISTABLE` / `YAXISTABLE` | SAS release older than 9.4M5. Use SAS Viya or upgrade |
| Kaplan-Meier curves look wrong | Check the censor convention: the step uses `CNSR=1` as censored |
| Forest plot rows in the wrong order | Sort the input table in the display order before the step |
| Forest plot error on log axis | Estimates or limits ≤ 0 or missing |
| Swimmer plot unreadable | Too many subjects. Filter to responders or a subset |
| Mean over time mixes parameters | Filter to one `PARAMCD` first |
| Characters such as `≥` or `×` show as `?` | Session encoding isn't UTF-8 (see `changeencoding/README.md`) |

---

## Limitations

- The steps produce **exploratory / demonstration graphs**. For submission-ready outputs, add your own templates, footnotes, page layout (ODS RTF/PDF) and validation (QC double programming).
- The forest plot doesn't calculate hazard ratios itself.
- Sample data is synthetic. Treatment effects were built in to make the graphs look realistic.
- The custom steps haven't been validated on every SAS release. Review the generated code in the Custom Step designer before production use.

---

← Back to the [main README](../README.md)
