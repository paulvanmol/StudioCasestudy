# SAS Studio Overview Case Studies

This repository contains demonstration assets for SAS Studio on SAS Viya.

The examples are organized into three main areas:

1. Diabetes Case Study
2. Clinical Encoding and UTF-8 Migration
3. Clinical Graphs

---

## 1. Diabetes Case Study

This example supports the SAS Viya Overview Case Study and demonstrates
data import, data preparation, flows, and reporting.

### Files

| File | Description |
|------|-------------|
| `Diabetes.csv` | Source data used in the case study |
| `Diabetes_structure.csv` | Structure information used during the import step |
| `diabetesDataPrep.sas` | SAS program for preparing the diabetes data |
| `diabetes_flow.flw` | SAS Studio flow containing the diabetes data preparation process |
| `diabetesReportFinal.json` | JSON package containing the Diabetes Report |

---

## 2. Clinical Encoding and UTF-8 Migration

The `encoding` directory contains a small clinical study example,
**XYZ123**, that can be used to demonstrate character encoding and
migration from a legacy WLATIN1 environment to UTF-8.

### Example study structure

The example includes:

- `autoexec.sas`
- raw data
- format/library definitions
- SDTM data and programs
- ADaM data and programs
- macros

### Creating the legacy WLATIN1 environment

Run:

`clinical_encoding_demo_wlatin1.sas`

using a **LATIN1 / WLATIN1 Compute Context**.

The program creates legacy SDTM and ADaM data that can subsequently
be used for the migration demonstration.

### Migrating to UTF-8

Run:

`clinical_encoding_demo_migrate_to_utf8.sas`

using a **UTF-8 Compute Context**.

This demonstrates conversion of the legacy clinical data to UTF-8
encoding.

---

## 3. Clinical Graphs

The `clinicalgraphs` directory contains examples that demonstrate
clinical visualization capabilities.

### Prerequisite

Import:

`clinicalgraphs.json`

using **SAS Environment Manager**.

This provides the required clinical graph steps.

### Create the sample data

Run:

`Sample data for clinical graph steps.sas`

The program creates the WORK tables required by the graph examples.

### Clinical Waterfall Graph

File:

`Clinical Waterfall Graph.step`

Uses the `WORK.WATERFALL` table.

Important variables:

- Subject: `SUBJID`
- Change from baseline: `PCHG`
- Group: `TRT`

### Clinical Profile Graph with Discrete Axes

File:

`Clinical Profile Graph with Discrete Axes.step`

Uses the `WORK.PROFILE` table.

Important variables:

- Treatment: `TRTGRP`
- Visit: `VISIT`
- Median: `MEDIAN`
- Lower confidence limit: `LCL`
- Upper confidence limit: `UCL`

### Clinical Grouped Bar Chart

File:

`Clinical Grouped Bar Chart.step`

Uses the `WORK.INJECTION` table.

Important variables:

- Time: `VISIT`
- Response: `INCIDENCE`
- Group: `COHORT`
