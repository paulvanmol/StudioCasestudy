# Demo 4 – Table Viewer, dataset metadata, import and export

⏱️ 15 min · Slides: *Table Viewer and Data Access* · [← Demo 3](03-background-submit-and-scheduling.md) · [README](../README.md) · [Demo 5 →](05-encoding-and-compute-contexts.md)

## Goal

Browse `DIABETESFINAL` with the Table Viewer, review its metadata, import `Diabetes.csv` with the point-and-click Import, and export a filtered subset to Excel.

> Run `diabetesdataprepfinal.sas` first if `WORK.DIABETESFINAL` is no longer in your session (for example after a session reset).

## Part A – Table Viewer

1. **Library Connections > WORK**, double-click `DIABETESFINAL`.
2. Column headers show **names and labels** (setting from Demo 1). Toggle with the **View** options of the table.
3. Right-click the `HbA1c` column > **Sort > Descending**.
4. Right-click `Diagnosis` > **Pin to left**.
5. Use **Columns** to hide `Urea`, `Cr` and `VLDL`.
6. Type this in the filter expression field and press Enter:

```text
HbA1c >= 6.5 and Diagnosis ne 'Diabetic'
```

**Question for the group:** what do these rows tell you about the data? (HbA1c ≥ 6.5 % is the diabetic threshold.)

7. Click **Filter** to open the expression builder, change the condition to `BMI_Range = 'Obese'` and **Save** the filter. Close and reopen the table: saved filters persist across sessions.
8. Select a range of cells and **Copy** – paste into Excel or Notepad.

## Part B – Dataset metadata

1. Switch to the **Column view** of the table (or expand `DIABETESFINAL` in Library Connections and right-click > **Properties**).
2. Review **name, label, type, length, format** for each column.
3. Which columns have *no* format? Which have a label?

The same information in code:

```sas
proc contents data=work.diabetesfinal varnum;
run;
```

🛡️ **Good practice** – note the **Encoding** line in the PROC CONTENTS output. You will need it in Demo 5.

## Part C – Import a CSV file (two ways)

**Way 1 – Standalone Import**

1. **New > Import file** (or *Import a file* on the Start page).
2. Drag `Diabetes.csv` from **SAS Server** onto the import tab.
3. Output table: `WORK.DIABETES_IMPORT`. Click **Update** under the file options, then **View and Analyze file** / preview the columns.
4. Click **Run**. Then open the **Code** tab and copy the generated PROC IMPORT code into a new program.

**Way 2 – Snippet**

1. **Snippets > SAS Snippets > Data > Import CSV File**, double-click.
2. Replace the path in the FILENAME statement: right-click `Diabetes.csv` > **Insert as path**.
3. Run it.

✅ **Checkpoint** – compare `WORK.DIABETES_IMPORT` and `WORK.DIABETESTEMP`: same number of rows and columns?

## Part D – Export a subset to Excel

1. In the Table Viewer of `DIABETESFINAL`, keep the filter `BMI_Range = 'Obese'`.
2. Use **Export** in the Table Viewer toolbar (export respects the applied filter) **or** right-click `DIABETESFINAL` in **Library Connections > Export**.
3. Location: `servier_work`, name `obese_subjects`, type **XLSX**. Click **Export**.
4. In **SAS Server**, right-click `obese_subjects.xlsx` > **Download file** and open it in Excel.

🛡️ **Good practice** – exports leave the controlled environment. Only export what is needed and follow your SOP for where exported files may be stored.
