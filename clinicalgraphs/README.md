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
