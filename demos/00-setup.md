# Demo 0 – Setup: get the course files on SAS Server

⏱️ 10 min · [Back to README](../README.md) · Next: [Demo 1 →](01-access-and-interface.md)

## Goal

Put `Diabetes.csv` and `diabetesdataprepfinal.sas` in a folder on **SAS Server** (the compute server file system) so that every demo can use the same path.

> In [Demo 8](08-git-integration.md) you will learn the *Git* way to get these files. For now we use the simplest way: download and upload.

## Steps

1. In your browser, open <https://github.com/paulvanmol/StudioCasestudy>.
2. Click **Code > Download ZIP** and unzip it on your laptop.
3. Sign in to SAS Viya and open **Develop Code and Flows** (SAS Studio).
4. In the navigation pane select **SAS Server**. Expand **Files > Home**.
5. Right-click **Home > New folder** and name it `StudioCasestudy`.
6. Right-click the new folder > **Upload files** and select from the unzipped folder:
   - `Diabetes.csv`
   - `diabetesdataprepfinal.sas`
   - the `programs` folder content (`00_setup_paths.sas`, `05a_…`, `05b_…`, `05c_…`)
7. Double-click `00_setup_paths.sas` and click **Run** (or press **F8**).

✅ **Checkpoint** – the log shows:

```text
NOTE: Course files   : /home/<your-user>/StudioCasestudy
NOTE: Work folder    : /home/<your-user>/servier_work
NOTE: Session encoding: utf-8
NOTE: Found   /home/<your-user>/StudioCasestudy/Diabetes.csv
NOTE: Found   /home/<your-user>/StudioCasestudy/diabetesdataprepfinal.sas
```

If you see `WARNING: Missing …`, check the folder name and the upper/lower case of the file names – Linux paths are **case sensitive**.

🛡️ **Good practice** – generated data goes to `servier_work`, *outside* the folder that holds the programs. That keeps the program folder clean when you later put it under Git control.
