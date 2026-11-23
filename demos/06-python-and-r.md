# Demo 6 – Submit Python and R code

⏱️ 10 min · Slides: *Submit Python and R code* · [← Demo 5](05-encoding-and-compute-contexts.md) · [README](../README.md) · [Demo 7 →](07-cloud-data-gcs-bigquery.md)

## Goal

Use the diabetes data from SAS in Python (PROC PYTHON and a `.py` program) and run a first PROC R step.

> Python and R must be configured by an administrator. If the steps below fail with a configuration error, follow along with the trainer.
> Make sure `WORK.DIABETESFINAL` exists (run `diabetesdataprepfinal.sas` in the **UTF-8** context).

## Part A – PROC PYTHON

```sas
proc python;
submit;
df = SAS.sd2df('work.diabetesfinal')            # SAS data set -> pandas DataFrame
print(df.shape)
summary = (df.groupby('Diagnosis')['HbA1c']
             .agg(['count', 'mean', 'min', 'max'])
             .reset_index())
print(summary)
SAS.df2sd(summary, 'work.hba1c_by_diagnosis')   # DataFrame -> SAS data set
endsubmit;
run;

proc print data=work.hba1c_by_diagnosis noobs;
run;
```

✅ **Checkpoint** – `WORK.HBA1C_BY_DIAGNOSIS` has one row per diagnosis.

## Part B – A Python program (.py)

1. **New > Python program**.
2. Paste only the Python lines (between `submit;` and `endsubmit;`) and click **Run**.
3. SAS Studio generates the PROC PYTHON wrapper for you – check the submitted code in the log.
4. Save it as `servier_work/hba1c_summary.py`.

## Part C – PROC R (if available in your release)

```sas
proc r;
submit;
print("Hello from R - inside SAS!")
print(R.version.string)
endsubmit;
run;
```

For exchanging data between SAS and R, see the *Introducing PROC R* blog series (Part 1–3) referenced on the slide.

🛡️ **Good practice** – Python/R code that produces regulated output needs the same controls as SAS code: version the `.py`/`.R` files, record package versions, keep the log.
