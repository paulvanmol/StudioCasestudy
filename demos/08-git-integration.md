# Demo 8 – Git integration: clone, branch, commit

⏱️ 20 min · Slides: *Git Integration & Collaboration* · [← Demo 7](07-cloud-data-gcs-bigquery.md) · [README](../README.md)

## Goal

Clone this repository into SAS Studio, create a feature branch, change the data preparation program, and stage and commit the change.

> To **push**, you need write access to the remote repository. Use your own fork, or the Servier GitLab project given by your trainer. Without write access you can do everything except Part E.

## Part A – Git profile

1. **Options > Manage Git connections > Profiles > Add**.
2. Enter your name and e-mail. Choose **HTTPS** (or SSH, depending on your environment) and the authentication method set up by your administrator.
3. Save.

## Part B – Clone the repository

1. **Options > Manage Git connections > Repositories > Clone**.
2. Repository URL: `https://github.com/paulvanmol/StudioCasestudy.git` (or your fork / GitLab URL).
3. Server location: a **new, empty** folder, for example `/home/<your-user>/git/StudioCasestudy`.
   The clone fails if the folder is not empty – do not reuse the `StudioCasestudy` folder from Demo 0.
4. Click **Clone**.

✅ **Checkpoint** – the repository appears under **Git Repositories** and in **SAS Server > Files > Home > git**.

> Want to use the clone for the course from now on? Change `%let path=` in your autoexec to the clone folder.

## Part C – Create a feature branch

1. Double-click the repository under **Git Repositories** to open it in the work area.
2. **Pull** to get the latest commits.
3. Open **Branches**, create `feature/<your-initials>-encoding-check` and check it out.

## Part D – Change, stage, commit

1. In the clone, open `diabetesdataprepfinal.sas`.
2. Add a header block and an encoding check at the top:

```sas
/*--------------------------------------------------------------------
  Program  : diabetesdataprepfinal.sas
  Purpose  : Prepare DIABETESFINAL for reporting
  Change   : <date> <your initials> - log session encoding
--------------------------------------------------------------------*/
%put NOTE: Session encoding = &sysencoding;
```

3. Save. In the repository tab the file appears under **Unstaged changes**. Click it to see the **diff**.
4. Stage the file (move it to **Staged changes**).
5. Enter a commit message, for example `Add header and encoding note to data prep`, and click **Commit**.
6. Open the **History** to see your commit.

🛡️ **Good practice** – one logical change per commit, with a message that explains *why*. Commit only programs and documentation – not data, logs or key files.

## Part E – Push and merge (with write access)

1. Click **Push**.
2. In SAS Studio: check out `main`, **Merge** your feature branch, and push – **or** in GitLab/GitHub create a **merge/pull request** so a reviewer approves the change.

## Recap – trunk-based workflow

Profile → Clone → Pull → Branch → Develop → Stage → Commit → Push → Merge (request)

## Trainer notes

- If participants see all files as changed after cloning, check line endings (CRLF/LF) and the `core.fileMode` Git setting.
- The advanced Git/GitLab workshop covers merge conflicts, tags/releases and CI/CD.
