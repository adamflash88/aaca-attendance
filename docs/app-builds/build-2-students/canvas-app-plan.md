# Canvas App Plan

## Mode

EDIT — Build 2 / Milestone 3: Student Management.

## Requirements

Source of truth: `C:\src\aaca-attendance\app\canvas-app-requirements.md` (immutable). Approved plan: add an
Attendance / Students switch to the Screen1 header (Office + Admin only; nothing else on Screen1 changes) and a
new Students screen — list on the left, selected-student profile + actions + enrollment history on the right,
stacked below 1024 px — where Attendance Office (own campus) and System Admin (any campus) find, add, edit,
change class (teacher and/or campus, future-dated allowed, cross-campus supported), change IEP ratio,
discharge, archive and unarchive students. Every write produces an Audit Events row. Teachers and Read-only
never see the screen (no nav button; not-authorised panel if reached). Deferred: year rollover, summer roster,
attendance totals.

Planner decisions (non-semantic):
- Screen key/file is `StudentsScreen` / `StudentsScreen.pa.yaml`, not `Students`: `Students` is the Dataverse
  table name, and a screen of that name would shadow the table in every formula. The visible title is "Students".
- Office users may transfer only within their own campus (target campus fixed); Admin may transfer across campuses.
- Student Status becomes Inactive at discharge time (when no other open/future enrollment), even if the end date
  is in the future; the attendance grid is driven by enrollment dates, not student status.
- A Student's Owner moves to the new teacher only when the effective date is today or earlier (approved rule); no
  scheduler moves it later — the receipt says so.

## Original Request Capability Inventory

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Observer(s) | Scenario(s) |
| --------------- | ----------------------- | ----------------- | ------------------------ | ------------------ | ----------- | ----------- |
| R-NAV | Office manager reaches a management screen; teachers never see it | App shell and navigation | Switch on both headers visible only when CanManageStudents; not-authorised panel otherwise | A-NAV-STUDENTS, A-NAV-ATTENDANCE | conAttNav / conStuNav Visible; btnStuNavStudents Primary; conStuDenied | S-NAV-OFFICE, S-NAV-TEACHER-HIDDEN |
| R-LIST | Find students; archived hidden unless "Include archived" | Data exploration | Search name/number (+external ID); status filter; campus scope (office fixed, admin picker); optional teacher filter; zero-result state | A-LOAD-STUDENTS, A-FILTER-STUDENTS | galStuList (F-LIST over colStuList), lblStuCount | S-SEARCH, S-ARCHIVED-HIDDEN, S-OFFICE-SCOPE |
| R-ADD | Add student with duplicate detection, required fields, campus, teacher, program, ratio, start date; audit | Data lifecycle | Student + Enrollment + Audit Event; receipt with every entered value and new Student Number | A-ADD-STUDENT | galStuReceipt lines from Patch results; lblStuDetailName; galStuHistory | S-ADD-OK, S-ADD-DUPLICATE, S-ADD-MISSING |
| R-TRANSFER | Transfer teacher and/or campus with effective date; future-dated; no overlap; history kept | Relationships and hierarchy | Old enrollment closed E−1 (Transfer); new from E linked via Previous Enrollment; owner moves; audit | A-TRANSFER | galStuReceipt; galStuHistory (both rows, "continues from"); lblStuDetailPlacement | S-TRANSFER-TODAY, S-TRANSFER-FUTURE, S-TRANSFER-CAMPUS, S-TRANSFER-BACKDATED, S-TRANSFER-INVALID-DATE |
| R-RATIO | Change IEP (aide) ratio with effective date | Data lifecycle | Close/open, End Reason Ratio Change, same teacher; audit | A-CHANGE-RATIO | galStuReceipt Old/New ratio; galStuHistory | S-RATIO-OK, S-RATIO-SAME |
| R-DISCHARGE | Discharge / end services | Workflow and review | Enrollment ended (Discharge); student Inactive when nothing else open; audit | A-DISCHARGE | galStuReceipt; badgeStuDetailStatus; galStuHistory | S-DISCHARGE-OK, S-DISCHARGE-CANCEL |
| R-ARCHIVE | Archive / Unarchive; archiving requires all enrollments closed | Workflow and review | Archived + Archived On/By; blocked with reason while any enrollment open/future; unarchive → Inactive; audit | A-ARCHIVE, A-UNARCHIVE | galStuReceipt (Operation/Previous/Expected/Status); badgeStuDetailStatus; lblStuActionHint | S-ARCHIVE-OK, S-ARCHIVE-BLOCKED, S-UNARCHIVE-OK |
| R-EDIT | Corrections to name, DOB, grade, external ID are audited | Data lifecycle | Prefilled edit; saves only those fields; Audit Before/After | A-EDIT-STUDENT | galStuReceipt; lblStuDetailName; F-FACTS | S-EDIT-OK, S-EDIT-CANCEL |
| R-HISTORY | Student profile with enrollment history | Relationships and hierarchy | Timeline of all enrollments (dates, teacher, campus, ratio, program, status, end reason) | A-SELECT-STUDENT | galStuHistory over colStuHistory (live Enrollments for varStuSelId) | S-HISTORY |
| R-REGRESSION | Existing Attendance screen behaviour unchanged | App shell and navigation | Only the header gains the switch | A-NAV-STUDENTS | Screen1 diff = header Height + conAttNav | S-NAV-OFFICE, S-REGRESSION-ATTENDANCE |

## Requirement Coverage

| Requirement | Planned affordance | Fidelity |
| ----------- | ------------------ | -------- |
| Attendance / Students switch | Two header ModernButtons (current = Primary teal) on both screens, `Visible: =CanManageStudents` | Exact |
| Not-authorised panel | conStuDenied with "Back to Attendance" | Exact |
| Search by name or student number | txtStuSearch over SearchKey (display name, number, external ID) | Exact (external ID added) |
| Status filter + Include archived | rdoStuStatus (Active/Inactive/Archived/All) + tglStuArchived; archived excluded unless toggle on | Exact |
| Campus scope | ddStuCampus: Admin picks (incl. All campuses); Office disabled on own campus + StudentCampusLock predicate | Exact |
| Optional teacher filter | ddStuTeacher ("All teachers" default) | Exact |
| List columns | Row: name; number · grade · IEP; placement teacher · campus; status badge; View | Exact |
| Add student + duplicate warning | Form (identity, campus, teacher, program radio, ratio, start date); conStuDup with Open existing + "This is a different person" | Exact |
| Change class / cross-campus / future-dated | Form mode "transfer"; campus editable for Admin | Exact |
| Change ratio | Form mode "ratio" | Exact |
| Discharge (end date + reason + confirm) | Form mode "discharge"; confirm = the explicit "Discharge student" submit (destructive red) plus the backdate tick when attendance exists after the date | Exact |
| Archive / Unarchive | Separate buttons; Archive disabled with reason while any enrollment is open/future | Exact |
| Edit details | Form mode "edit" prefilled from live Students record | Exact |
| Enrollment history timeline | galStuHistory newest first with status bar, dates, placement, end reason, previous link | Exact |
| Backdate warning | conStuBackdate with live Attendance count + required tick | Exact |
| Receipts | conStuReceipt at top of screen: title + labeled line per written value | Exact |

## Required Record Fields

Owner screen StudentsScreen (full binding table in its brief):

| Field key | Screen | Record surface | Required field | Source field | Presentation requirement |
| --------- | ------ | -------------- | -------------- | ------------ | ------------------------ |
| STU/list/name | StudentsScreen | galStuList row | Canonical identity | Students.'Display Name' | Full text, 2-line wrap |
| STU/list/number | StudentsScreen | galStuList row | Student number | Students.'Student Number' | Line 2 |
| STU/list/grade | StudentsScreen | galStuList row | Grade | Students.Grade | Line 2 "Grade K" |
| STU/list/ratio | StudentsScreen | galStuList row | IEP ratio | placement Enrollment.'IEP Ratio' | Line 2 "IEP 1:1" |
| STU/list/teacher | StudentsScreen | galStuList row | Current teacher | placement Enrollment.Teacher | Line 3 (Planned/Last prefix when not current) |
| STU/list/campus | StudentsScreen | galStuList row | Campus | placement Enrollment.Campus | Line 3 |
| STU/list/status | StudentsScreen | galStuList row | Status | Students status | Badge text |
| STU/detail/name, status, facts, placement | StudentsScreen | conStuProfile | Identity, status, number, grade, DOB, external ID, current + planned placement | Students + live Enrollments | Labeled text lines |
| STU/history/dates, placement, end | StudentsScreen | galStuHistory row | Dates, status, teacher, campus, ratio, program, school year, end reason, previous link | Enrollments | 3 lines per row |

## State-Driven Surface Visibility

| Surface key | Owner screen | Surface control | State predicate | Visible and hidden states |
| ----------- | ------------ | --------------- | --------------- | ------------------------- |
| SURF-ATT-NAV | Screen1 | conAttNav | `=CanManageStudents` | Office/Admin; hidden for Teacher/Read-only/not set up |
| SURF-STU-NAV | StudentsScreen | conStuNav | `=CanManageStudents` | same |
| SURF-STU-DENIED | StudentsScreen | conStuDenied | `=!CanManageStudents` | Non-managers only |
| SURF-STU-BODY | StudentsScreen | conStuBody | `=CanManageStudents` | Managers only |
| SURF-STU-RECEIPT | StudentsScreen | conStuReceipt | `=varStuReceipt.Kind <> ""` | After submit/cancel until Dismiss |
| SURF-STU-LIST | StudentsScreen | conStuListPanel | `=!(conStuRoot.Width < 1024 && (!IsBlank(varStuSelId) \|\| varStuMode <> ""))` | Hidden only when stacked and a student/form is open |
| SURF-STU-FORM | StudentsScreen | conStuForm | `=varStuMode <> ""` | Action form open |
| SURF-STU-F-IDENTITY / PLACE / PROGRAM / RATIO / DATE / REASON | StudentsScreen | conStuFormIdentity / conStuFormPlace / conStuFormProgram / conStuFormRatio / conStuFormDate / conStuFormReason | `varStuMode in [...]` per brief | Per mode |
| SURF-STU-DUP | StudentsScreen | conStuDup | F-DUPVIS (add + name/DOB match) | Duplicate found |
| SURF-STU-BACKDATE | StudentsScreen | conStuBackdate | `=varStuMode in ["transfer", "ratio", "discharge"] && varStuAttAfter > 0` | Attendance recorded on/after date |
| SURF-STU-PROFILE | StudentsScreen | conStuProfile | `=!IsBlank(varStuSelId)` | Student selected |

## Action Contracts

| Requested action | Preconditions | Entry point | Owner screen | Control and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| ---------------- | ------------- | ----------- | ------------ | ----------------- | -------------------- | ---------------------------- | ------------------ | ----------------- | --------------------- |
| A-NAV-STUDENTS | CanManageStudents | Header "Students" | Screen1 | btnAttNavStudents.OnSelect `=Navigate(StudentsScreen)` | N/A | StudentsScreen shown | N/A | N/A | btnStuNavStudents Primary; list |
| A-NAV-ATTENDANCE | CanManageStudents | Header "Attendance" | StudentsScreen | btnStuNavAttendance.OnSelect `=Navigate(Screen1)` | N/A | Screen1 shown (OnVisible reloads month) | N/A | N/A | btnAttNavAttendance Primary; month grid |
| A-LOAD-STUDENTS | CanManageStudents | Screen entry, ↻ | StudentsScreen | OnVisible / btnStuReload → btnStuLoadEngine.OnSelect | Students, Enrollments (open or ended ≥ Jul 1 prior year), School Years, Campuses, Staff | colStuList/colStuEnr/colStuHistory rebuilt | N/A | N/A | galStuList; lblStuCount; lblStuNotice on error |
| A-FILTER-STUDENTS | Loaded | Filter controls | StudentsScreen | txtStuSearch, rdoStuStatus, tglStuArchived, ddStuCampus.OnChange, ddStuTeacher.OnChange, btnStuClearFilters | colStuList | galStuList.Items = Sort(Filter(colStuList, PRED)) | N/A | N/A | galStuList; lblStuCount lists criteria / zero-result text |
| A-SELECT-STUDENT | Row visible | Row "View" | StudentsScreen | btnStuRowView.OnSelect → varStuSelId + btnStuHistoryEngine | Students.Student | Profile + history for ID | N/A | N/A | lblStuDetailName, galStuHistory, row highlight |
| A-ADD-STUDENT | Check = "Ready to save." (required fields, own campus for Office, teacher at campus, date in a school year, active service, duplicate acknowledged) | "+ Add student" | StudentsScreen | btnStuFormSubmit.OnSelect arm "add" | New Students.Student / Enrollments.Enrollment from Patch results | Student Active ("Last, First", trimmed); Enrollment Active (start ≤ today) or Planned; Owner = teacher user if linked; Audit Create | Students: First/Last/Display Name, DOB, Grade, External Client ID, Status, Owner*; Enrollment: Name, Student, Campus, Teacher, Service, School Year, Program, IEP Ratio, Start Date, Status, Owner*; Audit | Student number + every written value (19 labeled lines) | galStuReceipt; varStuSelId = s.Student → highlighted row, profile, history |
| A-EDIT-STUDENT | Selected; Office campus match; values changed | "Edit details" | StudentsScreen | btnStuActEdit → btnStuFormSubmit arm "edit" | Students.Student = varStuSelId | Six identity fields updated; others preserved; Audit Update Before/After JSON | First/Last/Display Name, DOB, Grade, External Client ID; Audit | Number + 6 new values + before summary + status unchanged + note + audit | receipt; profile |
| A-EDIT-CANCEL (all forms) | Form open | "Cancel" | StudentsScreen | btnStuFormCancel.OnSelect | none | No write; mode cleared | N/A | "… cancelled · name · nothing was changed" | conStuReceipt Cancelled |
| A-TRANSFER | Active; open enrollment; E > open start, ≤ school-year end, no overlap; teacher at campus; teacher or campus differs; backdate ticked if needed; Office target = own campus | "Change class" | StudentsScreen | btnStuActTransfer → submit arm "transfer" | OPEN enrollment id; new `ne`; Students.Student | Old End Date E−1, End Reason Transfer, Status Ended if E ≤ today; new enrollment from E (Active/Planned), same program/ratio/service/year, Previous Enrollment = old; Student Owner → new teacher user if E ≤ today; Audit Transfer | see brief | 19 labeled lines incl. old/new teacher, campus, dates, statuses, link, owners, kept days | receipt; galStuHistory both rows |
| A-CHANGE-RATIO | as transfer; ratio differs | "Change ratio" | StudentsScreen | btnStuActRatio → arm "ratio" | as transfer | Same close/open, End Reason Ratio Change, same teacher/campus, new ratio; Audit Update "IEP ratio change" | see brief | old ratio, new ratio, dates, statuses, teacher, campus, link, owner, kept days, note, audit | receipt; history |
| A-DISCHARGE | Active; open enrollment; D ≥ open start; reason; backdate tick | "Discharge" | StudentsScreen | btnStuActDischarge → arm "discharge" | OPEN id; Students.Student | End Date D, End Reason Discharge, Status Ended if D ≤ today; Student Inactive if no other open/future; Audit Discharge | Enrollment End Date/End Reason/Status; Student Status; Audit | number, teacher, campus, start, end, reason code, statuses, others count, days after, reason, audit | receipt; badge; history |
| A-ARCHIVE | Not archived; zero enrollments with blank End Date or End Date ≥ today (checked from history and live) | "Archive" (selector) | StudentsScreen | btnStuActArchive sets varStuMode "archive" → submit arm "archive" | Students.Student | Status Archived, Archived On today, Archived By current user; Audit Archive | Status, Archived On, Archived By; Audit | Operation, previous, expected, actual status, archived on/by, note, audit | receipt; badge; hidden from default list |
| A-UNARCHIVE | Archived | "Unarchive" (selector) | StudentsScreen | btnStuActUnarchive sets "unarchive" → arm "unarchive" | Students.Student | Status Inactive; Archived On/By cleared; Audit Unarchive | Status, Archived On, Archived By; Audit | Operation, previous, expected, actual, cleared on/by, note, audit | receipt; badge |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| ------ | --------------- | ----------------------------- | ---------------------------------- | -------------------- | ----------------------------------- | ----------------- |
| A-ADD-STUDENT | Patch results `s`, `e`, `audit` → varStuReceipt + colStuReceiptLines | Students/Enrollments (Dataverse) | galStuList row, conStuProfile, galStuHistory | s.Student → varStuSelId | `Select(btnStuLoadEngine)` on the success path requeries colStuList/colStuHistory | Row Fill highlight + profile by varStuSelId |
| A-EDIT-STUDENT | `s`, `old` | Students | profile + row | q = varStuSelId = s.Student | reload | same |
| A-TRANSFER | `closed`, `ne` | Enrollments | galStuHistory, lblStuDetailPlacement, row placement | open.EnrId = closed.Enrollment; ne.'Previous Enrollment' = closed | reload (incl. history requery) | profile stays on q |
| A-CHANGE-RATIO | `closed`, `ne` | Enrollments | same | same | reload | same |
| A-DISCHARGE | `closed`, `s2` | Enrollments, Students | history, badge, row | open.EnrId, q | reload | same |
| A-ARCHIVE | `s`, `stu` | Students | badge; default list excludes | q | reload | same |
| A-UNARCHIVE | `s`, `stu` | Students | badge | q | reload | same |

## Mutation Field Ledger

Full ledger in `StudentsScreen.screen-plan.md` → Mutation Field Ledger. Summary: every handler write is a Changed
row with a labeled receipt line from the Patch result; Preserved rows — Edit omits Status/Number/Archive fields and
enrollments; Transfer carries IEP Ratio/Program/Service/School Year from the live old enrollment and never writes
Attendance; Ratio carries Teacher/Campus/Program/Service/School Year; Archive/Unarchive omit identity fields.

## Functional Test Matrix

Seed facts: 3 campuses (ALP/BET/GAM), 12 "Seed …" teachers (no linked Users), 112 students SEED-0001..0112,
school years 2025-2026 (Closed) and 2026-2027 (Current, 2026-08-12 – 2027-07-30), one Planned future transfer;
today 2026-09-29. S1 = Active ALP student, open since 2026-08-12, IEP 1:1, teacher T_A; T_B another ALP teacher; T_C a BET teacher.

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| -------- | ----- | ---- | ---- | ---------------- | ------------------------- |
| S-NAV-OFFICE | Office/Admin | Header "Students", then "Attendance" | Screens switch | Nav Primary state; list; month grid | — |
| S-NAV-TEACHER-HIDDEN | Teacher/Read-only | Open app / reach StudentsScreen | No nav row; denied panel | conAttNav hidden; conStuDenied | — |
| S-REGRESSION-ATTENDANCE | Any role | Use Screen1 as in build 1 | Unchanged behaviour | Screen1 controls | Diff limited to header |
| S-OFFICE-SCOPE | Office at ALP | Open screen | Campus fixed ALP; ALP placements only | ddStuCampus disabled; galStuList | Non-ALP student actions disabled + hint |
| S-SEARCH | Admin, All campuses | Search `SEED-000` | 0001–0009 shown, 0100 hidden | galStuList; lblStuCount | Clear filters restores; zero-result text |
| S-ARCHIVED-HIDDEN | S3 archived | Default filters → status Archived → toggle on | Hidden → hint → shown | galStuList; lblStuCount | — |
| S-ADD-OK | Admin | Add Test/Pupil 2016-05-10 Grade 4 ALP T_A Regular 1:1 start 2026-09-29 | Student Active + STU number; enrollment Active; audit Create | 19 receipt lines; highlighted row; history 1 row | Owner "Unchanged (no linked user)" |
| S-ADD-DUPLICATE | S1 exists | Add S1's name (other case) + DOB | Warning; Save disabled until tick | conStuDup; lblStuFormCheck | Open existing selects S1 |
| S-ADD-MISSING | Add form | Grade blank | "Choose a grade." | lblStuFormCheck; Save disabled | Future DOB rejected |
| S-EDIT-OK | S4 grade 3 / SEED-0004 | Edit → Grade 4, SEED-0004A | Updated; audit Before/After | receipt | No-change rejected |
| S-EDIT-CANCEL | Edit with change | Cancel | No write | receipt Cancelled; profile unchanged | — |
| S-TRANSFER-TODAY | S1 | Change class → T_B, 2026-09-29 | Old ends 09-28 Transfer Ended; new Active linked | receipt; history 2 rows | Same teacher+campus rejected |
| S-TRANSFER-FUTURE | S2 | Effective 2026-10-15 | Old ends 10-14 stays Active; new Planned; owner unchanged | receipt; F-PLACE "Planned from" | — |
| S-TRANSFER-CAMPUS | Admin, S5 at ALP | → BET, T_C, 2026-10-01 | New campus BET | receipt New campus | Office cannot pick another campus |
| S-TRANSFER-BACKDATED | S6, 12 attendance rows since 09-01 | Effective 2026-09-01 | Warning with 12; tick required; attendance unchanged | conStuBackdate; receipt kept days 12 | Date change resets tick |
| S-TRANSFER-INVALID-DATE | S1 | Effective 2026-08-12 / 2027-08-02 | Rejected with messages | lblStuFormCheck | Planned-transfer student: before planned start rejected |
| S-RATIO-OK | S7 1:1 | → 2:1 on 2026-10-01 | Old ends 09-30 Ratio Change; new Planned 2:1 | receipt Old/New ratio | — |
| S-RATIO-SAME | S7 1:1 | Choose 1:1 | "must differ" | lblStuFormCheck | Save disabled |
| S-DISCHARGE-OK | S3 | End 2026-09-28, reason | Ended Discharge; student Inactive; audit | receipt; badge | Blank reason blocked |
| S-DISCHARGE-CANCEL | Discharge form | Cancel | No write | receipt Cancelled | — |
| S-ARCHIVE-OK | S3 discharged | Archive | Archived, On 2026-09-29, By user | receipt Operation/Previous/Expected/Status | — |
| S-ARCHIVE-BLOCKED | S1 open | View S1 | Archive disabled with reason | lblStuActionHint | End date = today still counts as open |
| S-UNARCHIVE-OK | S3 archived | Unarchive | Inactive; On/By cleared | receipt | Compound Inactive → Archived → Inactive |
| S-HISTORY | Planned-transfer seed student | View | Current + Planned rows, "continues from" | galStuHistory; F-PLACE | No enrollments → empty text |

All 24 scenarios are assigned: S-NAV-OFFICE, S-NAV-TEACHER-HIDDEN, S-REGRESSION-ATTENDANCE to Screen1 (and
StudentsScreen for the nav half); all others to StudentsScreen.

## Directional Mutation Evidence

| Pair | Selected-record expression | Operation-state reset binding | Invalid-submit gate | Receive/increase mutation | Issue/decrease mutation | Canonical-source observer | Receipt bindings |
| ---- | -------------------------- | ----------------------------- | ------------------- | ------------------------- | ----------------------- | ------------------------- | ---------------- |
| Archive/Unarchive (state pair) | `varStuSelId` (OnStart `Set(varStuSelId, Blank())`; assigned `btnStuRowView.OnSelect: =Set(varStuSelId, ThisItem.StudentId); ...`; consumed as `q` in submit arms) | `StudentsScreen.OnVisible: =Set(varStuMode, ""); Set(varStuAttAfter, 0); Select(btnStuLoadEngine)` and `Set(varStuMode, "")` in each success path | `btnStuFormSubmit.DisplayMode: =If(varStuMode <> "" && lblStuFormCheck.Text = "Ready to save." && !varStuSaving && !varStuLoading, DisplayMode.Edit, DisplayMode.Disabled)` | `btnStuFormSubmit.OnSelect` arm `"archive"`: `Patch(Students, stu, {'Status (aaca_status)': 'Status (Students)'.Archived, 'Archived On': Today(), 'Archived By': CurrentUserRow})` (selector `btnStuActArchive.OnSelect: =Set(varStuMode, "archive"); Set(varStuAttAfter, 0); Select(btnStuFormResetEngine)`) | arm `"unarchive"`: `Patch(Students, stu, {'Status (aaca_status)': 'Status (Students)'.Inactive, 'Archived On': Blank(), 'Archived By': Blank()})` (selector `btnStuActUnarchive.OnSelect: =Set(varStuMode, "unarchive"); ...`) | `badgeStuDetailStatus.Content: =LookUp(colStuList, StudentId = varStuSelId).StatusText` after `Select(btnStuLoadEngine)` | operation=`lblStuRcptValue.Text: =ThisItem.Value` for line "Operation" (`"Archive"`/`"Unarchive"`), title `lblStuReceiptTitle.Text: =varStuReceipt.Title`<br>old=line "Previous status" `Text(stu.'Status (aaca_status)')`<br>amount=N/A (state transition, no amount)<br>expected=line "Expected status" `"Archived"`/`"Inactive"`<br>actual=line "Status" `Text(s.'Status (aaca_status)')` |

## Compound Sequence Evidence

| Pair | Same-record ID expression | Sequence | Second-op old-value binding |
| ---- | ------------------------- | -------- | --------------------------- |
| Archive/Unarchive | `varStuSelId` | S3 Inactive → Archive → Archived → Unarchive → Inactive | `btnStuFormSubmit.OnSelect` arm "unarchive": `With({stu: LookUp(Students, ThisRecord.Student = q)}, ...)` → receipt "Previous status" = `Text(stu.'Status (aaca_status)')` = "Archived" |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| -------------- | ------------------------ | ------------------- |
| txtStuSearch | lblStuSearch | conStuSearchField |
| ddStuCampus / ddStuTeacher | lblStuCampus / lblStuTeacher | conStuCampusField / conStuTeacherField |
| rdoStuStatus | lblStuStatus | conStuStatusField |
| txtStuFormFirst, txtStuFormLast, dpStuFormDob, ddStuFormGrade, txtStuFormExt | lblStuFormFirst, lblStuFormLast, lblStuFormDob, lblStuFormGrade, lblStuFormExt | conStuFormIdentity |
| ddStuFormCampus, ddStuFormTeacher | lblStuFormCampus, lblStuFormTeacher | conStuFormPlace |
| rdoStuFormProgram | lblStuFormProgram | conStuFormProgram |
| ddStuFormRatio | lblStuFormRatio | conStuFormRatio |
| dpStuFormDate | lblStuFormDate | conStuFormDate |
| txtStuFormReason | lblStuFormReason | conStuFormReason |

## Layout Budget Contracts

| Screen / container | Branch / screen-width source | Horizontal total-width arithmetic | Vertical height arithmetic | Protected controls |
| ------------------ | ---------------------------- | ----------------------------------- | -------------------------- | ------------------ |
| Screen1 / conAttHeader + conAttNav | conAttRoot.Width (390 narrowest) | 32 + 120 + 8 + 120 = 280 ≤ 390 | 12+28+4+20+4+44+12 = 124; phone 140; no nav 76/92 | Nav buttons |
| StudentsScreen / conStuBody | conStuRoot.Width ≥ 1024 horizontal (2:3) else vertical | 1024: list 406 + 8 + right 610 = 1024 | side-by-side Max(844, right); stacked 852 + right | List, form, profile |
| StudentsScreen / list rows (head, scope, filter actions) | list inner 358 phone / 374 at 1024 | 280 / 288 / 308 ≤ 358 | fixed 44 / 58 / 44 | + Add student, Clear filters |
| StudentsScreen / galStuList row | TemplateSize 116 | 342 = name ≥178 + 8 + 84 + 8 + 64 | 6+44+2+18+2+36+6 = 114 ≤ 116 | View |
| StudentsScreen / conStuActions | conStuDetail.Width − 32 | 1 row needs 600; 2 rows 376; 3 rows 248 | 44 / 96 / 148 | Edit, Change class, Change ratio, Discharge, Archive/Unarchive |
| StudentsScreen / conStuForm | conStuForm.Width < 700 | actions 190+8+96 = 294 ≤ 326 | F-FORMH sum (desktop add 868) | Submit, Cancel, check text |
| StudentsScreen / conStuReceipt | conStuRoot.Width | label 150 + 8 + value fill | 8 + 44/84 + 4 + Min(400, rows × 40) + 8 | Every receipt line |
| StudentsScreen / galStuHistory row | TemplateSize 116 | text col ≈ 314 on phone | 8+20+2+36+2+36+8 = 112 | — |

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| ------ | ------------ | -------------- | ------------- | -------------- | --------------- |
| Screen1 | conAttRoot (unchanged) | AutoLayout | `conAttRoot.Width: =Parent.Width` | `conAttRoot.Height: =Parent.Height` | Vertical scroll (existing) |
| StudentsScreen | conStuRoot | AutoLayout | `conStuRoot.Width: =Parent.Width` | `conStuRoot.Height: =Parent.Height` | `LayoutOverflowY: =LayoutOverflow.Scroll` |

## Working Directory

C:\src\aaca-attendance\app

## Discovery Summary

- Existing screens: Screen1 (Attendance, prefix Att, 86 controls, AutoLayout root)
- Layout: AutoLayout throughout
- Data sources: Students, Enrollments, Staff, Campuses, 'School Years', Services, Attendance (read), 'Audit Events', Users (all Dataverse, writable)
- Controls (from packet): GroupContainer, ModernText, ModernButton, Classic/Button, Gallery, ModernDropdown, ModernTextInput, ModernDatePicker, ModernRadio, ModernCheckbox, ModernToggle, ModernSpinner, Badge
- Verified formulas used: Patch(Students/Enrollments/'Audit Events'), `{Owner: t.User}`, Student Number from Patch result, duplicate CountRows on Students, `IsBlank('End Date') || 'End Date' >= d` filter

## Dispatch

| Action | Screen | Target File | YAML Key | Name Prefix | Screen Brief |
| ------ | ------ | ----------- | -------- | ----------- | ------------ |
| Modify | Attendance | `C:\src\aaca-attendance\app\Screen1.pa.yaml` | Screen1 | Att | `C:\src\aaca-attendance\app\Screen1.screen-plan.md` |
| Create | Students | `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml` | StudentsScreen | Stu | `C:\src\aaca-attendance\app\StudentsScreen.screen-plan.md` |

Compile order: Screen1 now calls `Navigate(StudentsScreen)`, so compile Screen1 only once StudentsScreen exists
(same wave, compile after both are written, or StudentsScreen first).

## App Changes

### Before builders

1. `App.Formulas` — append after the `ColorErrorBg = ...;` line:
```
      // ---------- Student management (build 2) ----------
      CanManageStudents = IsOfficeRole || IsAdminRole;
      StudentCampusLock = If(IsOfficeRole && !IsBlank(CurrentStaff.Campus), CurrentStaff.Campus.Campus, ZeroGuid);
      StudentDefaultScope = If(!StaffReady || IsBlank(CurrentStaff.Campus), ZeroGuid, CurrentStaff.Campus.Campus);
      ActiveService = First(Filter(Services, Active = true));
```
2. `App.OnStart` — change the final `Clear(colBulkLog)` to `Clear(colBulkLog);` and append:
```
      Set(varStuSelId, ZeroGuid);
      Set(varStuSelId, Blank());
      Set(varStuMode, "");
      Set(varStuSaving, false);
      Set(varStuLoading, false);
      Set(varStuLoadError, "");
      Set(varStuAttAfter, 0);
      Set(varStuFormCampusId, ZeroGuid);
      Set(varStuScopeCampusId, StudentDefaultScope);
      Set(varStuTeacherFilterId, ZeroGuid);
      Set(varStuReceipt, {Kind: "", Title: "", StudentId: ZeroGuid});
      ClearCollect(colStuReceiptLines, {Label: "", Value: ""});
      Clear(colStuReceiptLines)
```
No other App property changes (StartScreen stays `=Screen1`).

### After builders

None.

## Editor State Changes

ScreensOrder: `Screen1`, `StudentsScreen`. ComponentDefinitionsOrder: None (unchanged).
