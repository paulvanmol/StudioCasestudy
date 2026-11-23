# Demo 2 – Programming workflow: run the diabetes data preparation

⏱️ 25 min · Slides: *Programming Workflow* · [← Demo 1](01-access-and-interface.md) · [README](../README.md) · [Demo 3 →](03-background-submit-and-scheduling.md)

## Goal

Open, adapt and run `diabetesdataprepfinal.sas`, read the log like a reviewer, and use the editor features: keyboard shortcuts, autocomplete, snippets, the DATA step debugger and document recovery.

The program:

1. imports `Diabetes.csv` into `WORK.DIABETESTEMP` (PROC IMPORT),
2. creates `WORK.DIABETESFINAL` with the derived columns `Diagnosis` and `BMI_Range` and the column labels (DATA step),
3. produces a frequency table and plot of `Diagnosis` (PROC FREQ),
4. loads and promotes `DIABETESFINAL` to the `CASUSER` caslib (PROC CASUTIL).

## Part A – Open the program and fix the path

1. In **SAS Server**, double-click `StudioCasestudy/diabetesdataprepfinal.sas`.
2. Find the `PROC IMPORT` statement. If the `file=` path does not match your folder, replace it:
   - Delete the quoted path.
   - Type `"&path/Diabetes.csv"` **or** right-click `Diabetes.csv` in **SAS Server > Insert as path**.

```sas
proc import file="&path/Diabetes.csv"
            dbms=csv
            out=work.DiabetesTemp
            replace;
run;
```

3. Make sure `&path` exists in this session: run `00_setup_paths.sas` or the autoexec from Demo 1.

🛡️ **Good practice** – avoid hard-coded personal paths in study programs. One macro variable (or a study-level autoexec) makes the program portable between users and environments.

## Part B – Run and review the log

1. Press **F8** (Run all). SAS Studio shows **Results** when there are no errors.
2. Open the **Log** tab (**Alt+5**). Use the **log summary** at the top: Errors / Warnings / Notes.
3. Check these notes and tell the trainer how many rows you got:
   - `NOTE: The data set WORK.DIABETESTEMP has … observations and … variables.`
   - `NOTE: The data set WORK.DIABETESFINAL has … observations and … variables.`
4. Open **Results** (**Alt+6**): frequency table and bar chart for `Diagnosis`.
5. Open **Output Data**: `WORK.DIABETESFINAL`.

✅ **Checkpoint** – no ERROR or WARNING in the log summary; `DIABETESFINAL` is visible in **Library Connections > WORK** and in **CASUSER**.

## Part C – Make an error on purpose

1. In the DATA step, change `set work.diabetestemp;` to `set work.diabetestmp;`.
2. Select only the DATA step and press **F3** (Run selected).
3. The **Log** opens automatically. Click the error in the log summary – SAS Studio jumps to the line.
4. Fix the typo and run the step again.

🛡️ **Good practice** – a clean log is part of your evidence. Review it every time, not only when results look wrong. Also look for `NOTE: Variable … is uninitialized` and `NOTE: Invalid data` – they are not errors, but they matter.

## Part D – Editor productivity

| Try | Shortcut |
|---|---|
| Comment / uncomment the PROC FREQ step | **Ctrl+/** |
| Autocomplete after typing `proc me` | **Ctrl+Space** |
| Go to line 10 | **Ctrl+G** |
| Find `BMI_Range` / replace | **Ctrl+F** / **Ctrl+H** |
| Format the code | **Format code** button on the editor toolbar |
| See all shortcuts | **Options > Manage keyboard shortcuts** |

Hover over a keyword (for example `tables`) to see the pop-up syntax help.

## Part E – Snippets

1. Open **Snippets > SAS Snippets > Viya Foundation > Cloud Analytic Services**.
2. Double-click **New CAS Session** – compare it with the `cas` statement in the program.
3. Create your own snippet: select the PROC FREQ step, right-click > **Add to My Snippets**, name it `Freq with plot`.
4. Under **My Snippets**, right-click your snippet > **Export** – you get a `.csm` file you can share with colleagues.

## Part F – DATA step debugger

1. On the editor toolbar click **Debug**. DATA steps are highlighted.
2. Click the debugger icon in the margin next to the DATA step that creates `DIABETESFINAL`.
3. Step through the code (**Step**). Watch `Class`, `BMI`, `Diagnosis` and `BMI_Range` in the variables pane – changed values are shown in red.
4. Set a breakpoint on the `BMI_Range` assignment and use **Continue**.
5. In the console, type `examine BMI BMI_Range` and press Enter.
6. Close the debugger.

**Question for the group:** what value does `BMI_Range` get when BMI is 24.95? (Hint: look at the boundaries `18.4/18.5`, `24.9/25`, `29.9/30`.)

## Part G – Document recovery

1. Type a comment in the program and **do not save**.
2. Close the browser tab and open SAS Studio again.
3. At the bottom of the work area open **Document recovery** and restore the program.

## Part H – Save

Save the adapted program (**Ctrl+S**). Keep it on **SAS Server** in `StudioCasestudy`.

## Trainer notes

- The boundary question in Part F is a nice segue to validation/QC: gaps in ranges are classic findings.
- Mention that ODS output can also be RTF/PDF/Excel via **Settings > Results**.
