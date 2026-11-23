# Demo 7 – External data: Parquet, Google Cloud Storage and BigQuery

⏱️ 10 min · Slides: *Google Cloud Storage & BigQuery* · [← Demo 6](06-python-and-r.md) · [README](../README.md) · [Demo 8 →](08-git-integration.md)

## Goal

Write and read the diabetes data as **Parquet**, and see the code pattern for Google Cloud Storage (GCS) and BigQuery.

> Parts B and C need a GCS bucket, a BigQuery dataset and a service-account key file. They are **trainer-led** unless your trainer gives you these details. Never store key files in a Git repository.

## Part A – Parquet on SAS Server (everyone)

```sas
options dlcreatedir;
libname pq parquet "&work/parquet";

data pq.diabetesfinal;
  set work.diabetesfinal;
run;

proc datasets lib=pq; quit;

proc contents data=pq.diabetesfinal; run;

data work.from_parquet;
  set pq.diabetesfinal;
  where Diagnosis = 'Diabetic';
run;
```

**Question for the group:** compare the PROC CONTENTS of `WORK.DIABETESFINAL` and `PQ.DIABETESFINAL`. Which metadata (labels, formats) is kept?

## Part B – Google Cloud Storage (trainer-led)

Replace the values in `< >`.

```sas
/* Files of any type: FILENAME GCS */
filename gcsin gcs "<path/in/bucket>/Diabetes.csv"
         key="<path/to/sa_key.json>" bucket="<bucket>";

proc import datafile=gcsin out=work.diabetes_gcs dbms=csv replace;
  getnames=yes;
run;

/* Parquet data sets on GCS: Parquet LIBNAME engine */
libname pqgcs parquet "<path/in/bucket>"
        storage_platform="gcs"
        storage_bucket_name="<bucket>"
        storage_gcs_key_file="<path/to/sa_key.json>";

/* CAS: GCS caslib (CSV and Parquet) */
caslib gcs datasource=(srctype="gcs" bucket="<bucket>"
       gcsauthfile="<path/to/sa_key.json>")
       path="<path/in/bucket>" subdirs libref=gcs;
```

## Part C – BigQuery (trainer-led)

```sas
libname bq bigquery cred_path="<path/to/sa_key.json>"
        project="<gcp-project>" schema="<bigquery-dataset>"
        scanstringcolumns=yes;

proc datasets lib=bq; quit;
```

🛡️ **Good practice** – document which external source and which snapshot you used (table name, date/time, row count in the log). External data can change between runs.
