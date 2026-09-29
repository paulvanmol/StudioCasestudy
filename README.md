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

### Case Study

In this case study, you will use SAS Viya applications to access, explore,
and analyze data related to diabetes diagnoses.

> **Important:** The steps in the case study must be completed in sequence.

The `Diabetes.csv` file is included in the course files and contains the
following information.

### Data Description

| Feature | Description |
|---------|-------------|
| **Class** | Indicates diabetes status. Coded as: **N = Non-Diabetic**, **Y = Diabetic**, **P = Pre-Diabetic**. |
| **BMI (Body Mass Index)** | A measure of body fat based on height and weight (kg/m²). Obesity (BMI ≥ 30) is a major risk factor for Type 2 diabetes. **Underweight:** < 18.5; **Normal:** 18.5–24.9; **Overweight:** 25–29.9; **Obese:** ≥ 30. |
| **Age** | Age of the subject in years. Age is an important risk factor for diabetes, with risk increasing with age. |
| **Gender** | Biological sex of the individual assigned at birth. Coded as: **0 = Female**, **1 = Male**. |
| **Urea** | Measurement of urea in the blood (mg/dL). Elevated levels may indicate kidney issues. **Normal range:** approximately 7–20 mg/dL. |
| **Cr (Creatinine)** | Measures creatinine in the blood (mg/dL) and is a marker of kidney function. Elevated levels may suggest impaired kidney function. **Normal range:** approximately 0.6–1.3 mg/dL. |
| **HbA1c (Glycated Hemoglobin)** | Indicator of average blood glucose levels over the preceding 2–3 months. Expressed as a percentage. **Non-Diabetic:** < 5.7%; **Pre-Diabetic:** 5.7–6.4%; **Diabetic:** ≥ 6.5%. |
| **Chol (Cholesterol)** | Total cholesterol in the blood (mg/dL). **Normal:** < 200 mg/dL. |
| **TG (Triglycerides)** | Measures the amount of triglycerides in the blood (mg/dL). **Normal:** < 150 mg/dL. |
| **HDL (High-Density Lipoprotein)** | Often referred to as "good" cholesterol (mg/dL). Higher levels are generally considered better. **Ideal:** > 40 mg/dL for men and > 50 mg/dL for women. |
| **LDL (Low-Density Lipoprotein)** | Often referred to as "bad" cholesterol (mg/dL). **Optimal:** < 100 mg/dL. |
| **VLDL (Very Low-Density Lipoprotein)** | Another form of cholesterol (mg/dL) that carries triglycerides. It is often estimated from TG/5. **Normal range:** 2–30 mg/dL. |

### Data Sources

**Original data source**

Rashid, Ahlam (2020), *Diabetes Dataset*, Mendeley Data, V1.  
DOI: https://data.mendeley.com/datasets/wj9rwkp9c2/1

**Supplemental feature descriptions**

[Multiclass Diabetes Dataset - Kaggle](https://www.kaggle.com/datasets/yasserhessein/multiclass-diabetes-dataset)

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
