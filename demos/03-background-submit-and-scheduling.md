# Demo 3 – Submission status, background submit and scheduling

⏱️ 15 min · Slides: *Submission Status / Using Background Submit / Scheduling Jobs* · [← Demo 2](02-programming-workflow.md) · [README](../README.md) · [Demo 4 →](04-table-viewer-and-data-access.md)

## Goal

Run `diabetesdataprepfinal.sas` without blocking your SAS Studio session, find the log and listing it produces, and schedule it as a job.

## Part A – Submissions and job status

1. Run `diabetesdataprepfinal.sas` again (**F8**).
2. Select **View > Submissions and job status**.
3. On the **Submissions** tab, select the two runs (from Demo 2 and now). Open the **log** and **code** of the earlier run.

Remember: interactive submissions are removed when your SAS Studio session ends – background submissions are kept.

## Part B – Background submit

1. **Before you start**, add this line at the top of the program and save it:

```sas
%put NOTE: Run by &sysuserid on &sysdate9 &systime - session encoding &sysencoding;
```

2. In **SAS Server**, right-click `diabetesdataprepfinal.sas` > **Background submit**.
   (Or use the **Background submit** button on the program toolbar.)
3. Notice the two messages: *submission started* and *submission completed*.
4. Open **View > Submissions and job status > Monitoring jobs**, select the submission and open the log and results.
5. Refresh the `StudioCasestudy` folder in **SAS Server**: a `.log` and an output file (`.lst`/`.html`) are created next to the program.

**Question for the group:** does the background run know `&path`? Why (not)?

> A background submission runs in a **separate SAS session**. It runs the autoexec, but not the code you submitted interactively. If `&path` was only defined by running `00_setup_paths.sas`, the background job fails. → Put shared settings in the **autoexec** (Demo 1, Part C option 3) or `%include` a setup program at the top.

✅ **Checkpoint** – the background log contains the NOTE line with your user ID, date/time and session encoding.

### Customise background submit

**Settings > SAS Studio > Background submit**:
- Change the location of log and output files (for example to `servier_work/logs`).
- Choose whether files are **replaced** or **time-stamped**.

🛡️ **Good practice** – choose *time-stamped* logs when the log is evidence of a run; replacing the log destroys the previous evidence. Remember that results in Monitoring jobs are cleared after 72 hours: the files on disk are your record.

## Part C – Schedule as a job

1. Right-click `diabetesdataprepfinal.sas` > **Schedule as a job**.
2. Set **Daily** at **01:00**, choose your time zone and an end date (for example end of the week). Click **Save**.
3. Open **View > Submissions and job status > Scheduled jobs** and confirm the job is there.
4. Delete the schedule again (right-click > **Delete**) – we do not want training jobs running at night.

## Part D – Deploy as a job (demo by trainer)

1. Right-click the program > **Deploy as a job**, give it a name, click **Deploy**.
2. Show the job in **SAS Environment Manager > Jobs and Flows**.
3. Change the program, then **Redeploy** – the job keeps the same job ID.

More on jobs, job flows and scheduling: see the **Scheduling** advanced topic in the [README](../README.md#5-advanced-topics-optional-after-the-course).
