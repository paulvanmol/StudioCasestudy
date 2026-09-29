# SAS Studio Overview Case Study
This repository contains the Diabetes.csv file that is being used in the SAS Viya Overview Case Study
- Diabetes.csv
- Diabetes_structure.csv (for import step)
- diabetesDataPrep.sas
- diabetesReportFinal.json (contains the DiabetesReport in json package)
- diabetes_flow.flw (contains the diabetes data preparation flow)
clinical_encoding_demo:
- encoding: contains a clinical study XYZ123 with examples of autoexec, rawdata, library (formats), SDTM, Adam data
- clinical_encoding_demo: contains a
- clinical_encoding_demo_wlatin1.sas: runs in a LATIN1 compute context. Creates a legacy_sdtm and adam folder
- clinical_encoding_migrate_to_utf8.sas: runs in UTF8 compute context. Converts legacy data to UTF8 encoding
clinicalgraphs:
- prerequisites: import clinicalgraphs.json in SAS Environment Manager
- contains 3 Clinical Graphs and a program to create the data for the clinical graphs
- Sample data for clinical graph steps.sas
- Clincial Waterfall graph.step: uses work.waterfall table (Subject: subjid, Change from baseline: pchg,group:trt)
- Clinical Profile Graph with Discrete: used work.profile table (with treatment:trtgrp,visit, median, lcl, ucl)
- Clinical Grouped Bar Chart.step: uses work.injection table (with time: visit, response: incidence, group:cohort)
