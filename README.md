# SAS Studio on SAS Viya for Clinical Programmers – Case Study

Hands-on demos that accompany the **Servier – SAS Studio on SAS Viya for Clinical Programmers** training.
After each section of the slide deck there is a short demo. Follow them **in order** – each demo builds on the result of the previous one.

The case study uses one small data set: `Diabetes.csv` (lab values, BMI and diabetes class per subject). You will import it, prepare it with `diabetesdataprepfinal.sas`, explore the result, run it in the background, and then learn how to work **safely with encoding** when you switch between UTF-8 and legacy WLATIN1 studies.

---

## 1. What you need

| Item | Where |
|---|---|
| SAS Viya URL | `https://<your-server>/SASLanding` (given by your trainer) |
| User ID / password | Given by your trainer |
| Course files | This repository (download as ZIP or clone with Git) |
| Browser | Chrome or Edge (recommended for the Progressive Web App) |

## 2. Repository content

```text
StudioCasestudy/
├── README.md                         <- you are here
├── .gitignore                        <- keeps logs, data and key files out of Git
├── Diabetes.csv                      <- raw case-study data
├── diabetesdataprepfinal.sas         <- data preparation program (Demo 2)
├── diabetesreportfinal.json          <- OPTIONAL Visual Analytics report (see Advanced topics)
├── demos/                            <- one Markdown file per slide-deck section
│   ├── 00-setup.md
│   ├── 01-access-and-interface.md
│   ├── 02-programming-workflow.md
│   ├── 03-background-submit-and-scheduling.md
│   ├── 04-table-viewer-and-data-access.md
│   ├── 05-encoding-and-compute-contexts.md
│   ├── 06-python-and-r.md
│   ├── 07-cloud-data-gcs-bigquery.md
│   └── 08-git-integration.md
├── programs/                         <- helper programs used in the demos
│   ├── 00_setup_paths.sas
│   ├── 05a_check_encoding.sas
│   ├── 05b_create_legacy_wlatin1.sas
│   └── 05c_read_legacy_in_utf8.sas
└── advanced/                         <- optional, after the course
    └── encoding-utf8-migration.md
```

## 3. Course path – slide section → demo

| # | Slide-deck section | Demo | Time |
|---|---|---|---|
| 0 | Before you start | [Setup: get the course files on SAS Server](demos/00-setup.md) | 10 min |
| 1 | Accessing SAS Studio & Interface | [Access SAS Studio, navigate, create a library, user settings](demos/01-access-and-interface.md) | 15 min |
| 2 | Programming Workflow | [Run the diabetes data preparation, read the log, snippets, debugger](demos/02-programming-workflow.md) | 25 min |
| 3 | Submission Status, Background Submit, Scheduling | [Background submit and schedule the data prep program](demos/03-background-submit-and-scheduling.md) | 15 min |
| 4 | Table Viewer and Data Access | [Explore DiabetesFinal, import a CSV, export to Excel](demos/04-table-viewer-and-data-access.md) | 15 min |
| 5 | Working with Encoding | [Check encoding and switch compute context safely](demos/05-encoding-and-compute-contexts.md) | 30 min |
| 6 | Submit Python and R code | [Summarize the diabetes data with Python and R](demos/06-python-and-r.md) | 10 min |
| 7 | Google Cloud Storage & BigQuery | [Write Parquet and (optionally) connect to GCS/BigQuery](demos/07-cloud-data-gcs-bigquery.md) | 10 min |
| 8 | Git Integration & Collaboration | [Clone this repository, branch, commit](demos/08-git-integration.md) | 20 min |

> **Tip:** open this README in a second browser tab (or on a second screen) while you work in SAS Studio.

## 4. Conventions used in the demos

- **Bold** = something you click or select in SAS Studio, for example **New > SAS Program**.
- `code` = something you type, a file name, or a path.
- ✅ **Checkpoint** = what you should see before you continue.
- 🛡️ **Good practice** = the regulated-environment habit behind the step.
- All programs use the macro variable `&path` for the location of the course files. Set it once in [Demo 0](demos/00-setup.md).

## 5. Advanced topics (optional, after the course)

The basic course teaches you to *recognise* encoding situations and to switch **compute context** and **default text encoding** safely. The advanced topics show you how to actually **migrate** data and programs.

| Topic | What you learn |
|---|---|
| [Encoding – migrating data to UTF-8](advanced/encoding-utf8-migration.md) | Determine data set encoding, size requirements, CEDA vs CVP, PROC MIGRATE, format catalogs, indexes, CPORT/CIMPORT, validation |
| Visual Analytics reports <!-- update link to existing folder --> | Import and explore the optional `diabetesreportfinal.json` report on `CASUSER.DIABETESFINAL` |
| SAS Studio Flows <!-- update link to existing folder --> | Build the same data preparation as a low-code flow |
| Scheduling <!-- update link to existing folder --> | Deploy as a job, job definitions, Environment Manager jobs and flows |

## 6. Data source

Rashid, Ahlam (2020), "Diabetes Dataset", Mendeley Data, V1, doi: 10.17632/wj9rwkp9c2.1.
Supplemental feature description: <https://www.kaggle.com/datasets/yasserhessein/multiclass-diabetes-dataset>

## 7. Help

- SAS Studio documentation: <https://go.documentation.sas.com/doc/en/sasstudiocdc/default/webeditorcdc/sasstudiowlcm/home.htm>
- SAS Viya Quick Start videos: <https://video.sas.com/category/videos/sas-viya-quick-start>
- SAS Communities – SAS Studio: <https://communities.sas.com/t5/tag/SAS%20Studio/tg-p>
