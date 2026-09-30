# Flow spec — Dataverse → SharePoint Student Directory sync

Keeps the SharePoint **Student Directory** list (site `https://autismacademy.sharepoint.com/sites/FinanceMain`) an
exact, automatically maintained copy of the app's student roster in Dataverse. One direction only:
**Dataverse → SharePoint**. Never edit the directory by hand after this is live — the next sync overwrites it.

Why: the parent absence form's matching flow and the app's "Resolve Match" both depend on the directory having
every student, with the right `Student_ID`, campus and `Match_Name`.

## Build it inside the solution

Create all four flows from **make.powerapps.com → AACA Attendance - Dev → Solutions → AACA Attendance → New →
Automation → Cloud flow** (so they deploy to Test/Prod with the app). The first time you add a Dataverse or
SharePoint action inside the solution, Power Automate creates a **connection reference** — name them:

| Connection reference | Connector | Connection |
|---|---|---|
| `AACA Dataverse` | Microsoft Dataverse | the flow owner's account |
| `AACA SharePoint FinanceMain` | SharePoint | an account with **Edit** on Student Directory |

**Licence:** the Dataverse trigger/actions are premium — the flow owner needs **Power Automate Premium** (or a
per-flow/process licence). Prefer a service account as owner; you can change owner later.

## Flow structure

```
[1] AACA - Directory Upsert (child)      <- does all the work for ONE student
      ^            ^             ^
[2] Student changed   [3] Enrollment changed   [4] Nightly reconcile (+ one-time backfill)
```

One child flow means the mapping logic lives in one place.

---

## [1] AACA - Directory Upsert (child flow)

**Trigger:** *Manually trigger a flow* (in a solution this is the child-flow trigger) with one input:
- Text input **StudentRowId** (the Dataverse Students row GUID)

**Action 1 — Dataverse › Get a row by ID** (rename: `Get student`)
- Table name: **Students**
- Row ID: `StudentRowId`
- Select columns: `aaca_firstname,aaca_lastname,aaca_externalclientid,aaca_status`

**Action 2 — Condition** (rename: `Has student key`)
- `outputs('Get_student')?['body/aaca_externalclientid']` **is not equal to** *(empty — leave blank)*
- **If no:** *Respond to a PowerApp or flow* (output text `Result` = `skipped: no student key`) — then stop.

(Everything below goes in the **If yes** branch.)

**Action 3 — Dataverse › List rows** (rename: `Latest enrollment`)
- Table name: **Enrollments**
- Select columns: `aaca_startdate,aaca_enddate`
- Filter rows:
  `_aaca_student_value eq @{triggerBody()?['text']} and aaca_startdate le @{formatDateTime(utcNow(), 'yyyy-MM-dd')}`
  (use the **StudentRowId** dynamic value where `triggerBody()?['text']` appears)
- Sort by: `aaca_startdate desc`
- Expand Query: `aaca_campus($select=aaca_code)`
- Row count: `1`

> "Latest enrollment that has started" = today's campus for active students, last campus for archived ones.
> A future-dated transfer doesn't move them in the directory until its start date (the nightly run picks it up).

**Action 4 — Compose** (rename: `Campus code`)
```
first(outputs('Latest_enrollment')?['body/value'])?['aaca_campus']?['aaca_code']
```

**Action 5 — Compose** (rename: `Match name`) — must match the format your matching flow compares against
(lower-case "first last", single spaces):
```
toLower(trim(concat(trim(outputs('Get_student')?['body/aaca_firstname']), ' ', trim(outputs('Get_student')?['body/aaca_lastname']))))
```

**Action 6 — Compose** (rename: `Active flag`) — Students status *Active* = `582100000`
```
if(equals(outputs('Get_student')?['body/aaca_status'], 582100000), 'Yes', 'No')
```

**Action 7 — SharePoint › Get items** (rename: `Find directory item`)
- Site: FinanceMain · List: **Student Directory**
- Filter Query: `Student_ID eq '@{outputs('Get_student')?['body/aaca_externalclientid']}'`
- Top Count: `1`

**Action 8 — Condition** (rename: `Exists in directory`)
- `length(outputs('Find_directory_item')?['body/value'])` **is greater than** `0`

**If yes → SharePoint › Update item**
- Id: `first(outputs('Find_directory_item')?['body/value'])?['ID']`
- Student_ID: student key · First_Name: `aaca_firstname` · Last_Name: `aaca_lastname`
- Match_Name: output of `Match name` · Active: output of `Active flag`
- Campus: `if(empty(outputs('Campus_code')), first(outputs('Find_directory_item')?['body/value'])?['Campus'], outputs('Campus_code'))`
  (keeps the existing campus if the student has no started enrollment)
- Leave **Title** and **FirstName** (legacy) untouched.

**If no → SharePoint › Create item** — same fields (Campus = `Campus code` output, may be blank).

**Action 9 — Respond to a PowerApp or flow** (after the condition, both branches): text output `Result` =
`updated` / `created` (or simply `done`).

> Child flows must end with *Respond to a PowerApp or flow*, and in the flow's **Details → Run only users**
> set the connections to **Use this connection** (not "Provided by run-only user").

---

## [2] AACA - Directory Sync: Student changed

**Trigger:** Dataverse › *When a row is added, modified or deleted*
- Change type: **Added or Modified** · Table: **Students** · Scope: **Organization**
- Select columns: `aaca_firstname,aaca_lastname,aaca_externalclientid,aaca_status`
  (only these changes fire the flow)

**Action:** *Run a Child Flow* → `AACA - Directory Upsert`, StudentRowId = `triggerOutputs()?['body/aaca_studentid']`

## [3] AACA - Directory Sync: Enrollment changed

**Trigger:** Dataverse › *When a row is added, modified or deleted*
- Change type: **Added or Modified** · Table: **Enrollments** · Scope: **Organization**
- Select columns: `aaca_startdate,aaca_enddate,aaca_campus,aaca_student`

**Action:** *Run a Child Flow* → `AACA - Directory Upsert`, StudentRowId = `triggerOutputs()?['body/_aaca_student_value']`

## [4] AACA - Directory Sync: Nightly reconcile

**Trigger:** *Recurrence* — every 1 day at 2:00 AM, time zone **(UTC-08:00) Pacific Time**

**Action 1 — Dataverse › List rows** (`All students`)
- Table: **Students** · Select columns: `aaca_studentid` · Settings → **Pagination on**, threshold `5000`

**Action 2 — Apply to each** over `value` of `All students` (Settings → **Concurrency control on, degree 5**)
- *Run a Child Flow* → `AACA - Directory Upsert`, StudentRowId = `items('Apply_to_each')?['aaca_studentid']`

This also covers anything the event triggers missed (throttling, a failed run) and future-dated transfers that
became effective overnight.

**One-time backfill:** after building [1]–[4], open [4] and click **Run** once. Then check the directory has one
item per Dataverse student (126 today), including the six Chatsworth students added on 9/30.

---

## Test checklist (in Dev)

1. **Rename test:** in the app, edit a test student's first name → within a minute the directory item's First_Name
   and Match_Name update.
2. **Add test:** add a student in the app (Student Key e.g. `CW-1127`) → a new directory item appears with Campus CW,
   Active Yes.
3. **Transfer test:** change class to another campus effective today → directory Campus changes.
4. **End enrollment test:** end a test student's enrollment → Active becomes `No` (after the student is archived).
5. **Nightly:** run [4] manually → no errors, run history shows one child run per student.
6. Check the parent-report matching flow still matches by `Match_Name` for a new student.

## Deploying to Test / Production

The flows travel in the AACA Attendance solution. On import, Power Platform asks for the two connection
references — pick connections for that environment. Then **turn the four flows on** and run [4] once.
If Test should use a different SharePoint site/list, change the site/list in [1] via the solution's
environment variables (ask before we add them).
