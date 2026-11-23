# Demo 1 – Access SAS Studio, navigate the interface, user settings

⏱️ 15 min · Slides: *Accessing SAS Studio & Interface* · [← Demo 0](00-setup.md) · [README](../README.md) · [Demo 2 →](02-programming-workflow.md)

## Goal

Open SAS Studio in the browser and as a Progressive Web App (PWA), find your way in the navigation pane, create a library on the course folder, and set the user settings you will use for the rest of the course.

## Part A – Open SAS Studio

1. Go to `https://<your-server>/SASLanding`.
2. Click the **Applications menu** (top left) and select **Develop Code and Flows**.
   Alternatively, click the **Develop Code and Flows** tile on the landing page.
3. In the Applications menu, click the ☆ next to **Develop Code and Flows** to add it to **Favorites**.
4. Open a **second browser tab** with the same URL. Notice that this tab starts a **second, independent SAS compute session** (its own WORK library, its own macro variables).
5. Close the second tab.

### Optional – install as a Progressive Web App

6. In Chrome/Edge, click the **Install** icon in the address bar > **Install**.
7. Pin the app to the taskbar. Right-click the app window title to rename it, for example `SAS Studio – TRAINING`.

🛡️ **Good practice** – when you have access to several environments (development, validation, production), give each PWA a clear name so you never run code in the wrong environment.

## Part B – Navigate the interface

1. Point out the three areas: **application bar and toolbar** (top), **navigation pane** (left), **work area** (right, tabs).
2. Visit each navigation section:

| Section | Try this |
|---|---|
| **Open Items** | Shows what is open in this session |
| **SAS Server** | Expand **Files > Home > StudioCasestudy**. Right-click `Diabetes.csv` and look at **Copy path**, **Insert as path**, **Download file** |
| **SAS Content** | Expand **My Folder**. Note: shared Viya objects (reports, jobs, flows). Not the place to version programs with Git |
| **Steps** | Expand **Data** – point-and-click steps that generate code |
| **Snippets** | Expand **SAS Snippets > Viya Foundation > Cloud Analytic Services** |
| **Library Connections** | Expand **SASHELP > CLASS** to see the columns |
| **Git Repositories** | Empty for now – used in Demo 8 |

3. Check the **compute context** shown at the top right of SAS Studio (for example `SAS Studio compute context`). Remember where it is – you will switch it in Demo 5.

## Part C – Create a library on the course folder

You will see three ways; use **one**.

**Option 1 – Point and click**

1. In **SAS Server**, right-click the `StudioCasestudy` folder > **Create library**.
2. Name: `CSTUDY`. Select **Assign and connect to data sources at startup**. Click **OK**.

**Option 2 – Library Connections**

1. **Library Connections > Add (+) > Path/DNFS**, name `CSTUDY`, path `/home/<your-user>/StudioCasestudy`.

**Option 3 – Code in the autoexec**

1. **Options > Autoexec file**. Add:

```sas
%let path = %sysget(HOME)/StudioCasestudy;
%let work = %sysget(HOME)/servier_work;
libname cstudy "&path";
```

2. Click **Run** to test, then **Save**.

✅ **Checkpoint** – `CSTUDY` appears in **Library Connections** and stays there after **Options > Reset SAS session**.

> If you used option 1 or 2, open **Options > Autoexec file** and notice that SAS Studio added the LIBNAME statement for you.

## Part D – User settings for this course

Open your **user icon (top right) > Settings** and set:

| Setting | Value | Why |
|---|---|---|
| **SAS Studio > General > Default text encoding** | Leave **UTF-8** | Encoding used to open and save programs and text files – we change it in Demo 5 |
| **SAS Studio > SAS Programs > Code and Log > Detail tab layout** | **Standard** | One tab at a time: Code / Log / Results / Output Data |
| **SAS Studio > SAS Programs > Results** | Keep **HTML**, optionally add **RTF** or **Excel** | Downloadable output |
| **SAS Studio > Editors > Suggestions** | Clear **Show suggestions when a special trigger character is typed** | Less interruption; use **Ctrl+Space** when you want suggestions |
| **SAS Studio > Tables > Column headers** | **Show names and labels** | Clinical data relies on labels |
| **Global > General > Theme** | Your choice (Light, Dark, High contrast) | |
| **Start-up** | **Develop Code and Flows** (optional) | Open SAS Studio directly after sign-in |

✅ **Checkpoint** – open **SASHELP.CLASS** from Library Connections: the column headers show names and labels.

## Trainer notes

- Mention the 30-minute session time-out in the browser (configurable by the administrator) versus the PWA.
- Emphasise *SAS Server vs SAS Content*: programs under Git control must live on **SAS Server**.
