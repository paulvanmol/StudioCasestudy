# SAS Studio Overview Case Studies

This repository contains demonstration assets and examples for SAS Studio
and related SAS Viya applications.

The repository contains three main demonstration areas:

1. Diabetes Case Study
2. Clinical Encoding and UTF-8 Migration
3. Clinical Graphs

---

# 1. Diabetes Case Study

In this case study, you will use SAS Viya applications to access, prepare,
explore, and analyze data related to diabetes diagnoses.

> **Important:** The steps in this case study must be completed in sequence.
> The output from one step is used as input to subsequent steps.

## Case Study Sequence

The case study follows this workflow:

### Step 1 - Import the Diabetes Data

In SAS Studio, create a **new SAS program** and import:

`Diabetes.csv`

The file:

`Diabetes_structure.csv`

contains the structure information used during the import step.

### Step 2 - Prepare the Data

Run the SAS program:

`diabetesDataPrep.sas`

This program performs the data preparation for the case study and creates
the following CAS table:

`CASUSER.DIABETESFINAL`

### Step 3 - Explore the Results in SAS Visual Analytics

The CAS table:

`CASUSER.DIABETESFINAL`

is used as the data source for the SAS Visual Analytics report:

**DiabetesFinal**

The report package is provided in:

`diabetesReportFinal.json`

and can be imported into SAS Viya.

## Workflow Summary

```text
Diabetes.csv
     |
     v
Import the data using a new SAS Studio program
     |
     v
Run diabetesDataPrep.sas
     |
     v
CASUSER.DIABETESFINAL
     |
     v
SAS Visual Analytics
     |
     v
DiabetesFinal Report
```
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


