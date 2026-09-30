# Canvas App Plan

## Mode

EDIT (Build 3, "Step 1" pilot readiness; approved by the user 2026-09-30)

## Requirements

Authoritative source: `C:\src\aaca-attendance\app\canvas-app-requirements.md` (not modified). Summary:

- Header switch Attendance / Students / Absences on all three screens (Office and Admin only).
- Students: Discharge + Archive become one **End enrollment** action; Unarchive becomes **Re-enroll**.
- New Absences screen: office classification queue (campus / teacher / date range / status filters, count,
  zero state), classify one (Excused needs a reason, Unexcused clears the reason), classify in bulk (tick
  rows or Select all shown, one Patch per row, receipt "18 marked Excused (Illness), 0 failed"),
  reclassify with audit old -> new, lock rule, Teachers / Read-only never see it.
- App: `CanClassify` named formula; OnStart initial values for the new screen's filters, ticks and receipt.
- Domain rules: enrollments are continuous (no split at quarters / ESY / school years); an End Date with no
  following enrollment means Archived; Program is internal ('Regular Year'); dates are day-strict.

Build note: Screen1.pa.yaml and StudentsScreen.pa.yaml reference `AbsencesScreen`, so compile only after
all three dispatch rows are written (one wave of three builders).

## Original Request Capability Inventory

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Observer(s) | Scenario(s) |
| --------------- | ----------------------- | ----------------- | ------------------------ | ------------------ | ----------- | ----------- |
| R-NAV3 | Header switch Attendance / Students / Absences for Office and Admin | App shell and navigation | Same 3-button nav on all three screens, current screen highlighted; hidden for Teacher/Read-only; Absences shows a not-authorised panel otherwise | A-NAV-ATTENDANCE, A-NAV-STUDENTS, A-NAV-ABSENCES | conAttNav/conStuNav/conAbsNav `.Visible = CanManageStudents`; current button BasePaletteColor ColorTeal; conAbsDenied `.Visible = !CanClassify` | S-NAV3-OFFICE, S-NAV3-TEACHER-HIDDEN |
| R-END | End enrollment replaces Discharge + Archive | Workflow and review | Open enrollment ended (End Reason Archived, Status Ended or Active until a future end date); student Archived with On/By; audit Archive; receipt | A-END-ENROLLMENT | conStuReceipt/galStuReceipt lines; badgeStuDetailStatus; galStuHistory lblStuHistDates/lblStuHistEnd; galStuList with status Archived | S-END-OK, S-END-FUTURE, S-END-NO-NOTE, S-END-CANCEL |
| R-REENROLL | Re-enroll replaces Unarchive | Workflow and review | New enrollment after last end date, linked by Previous Enrollment; student Active; Archived On/By cleared; audit Unarchive; receipt | A-REENROLL | conStuReceipt lines; badgeStuDetailStatus; galStuHistory (gap + new start, "continues from"); Screen1 grid for the new teacher | S-REENROLL-OK, S-REENROLL-BAD-DATE, S-REENROLL-CANCEL |
| R-QUEUE | Absences queue with campus/teacher/date/status filters and count | Data exploration | Delegable filter on Attendance (Present = false, Is Deleted = false, classification per status, campus, date range) into colAbsList; teacher filter local; count + zero state | A-LOAD-ABSENCES, A-FILTER-ABSENCES | galAbsList.Items; lblAbsCount | S-QUEUE-DEFAULT, S-QUEUE-FILTER, S-QUEUE-EMPTY |
| R-CLASSIFY-ONE | Classify one absence Excused (reason) / Unexcused | Workflow and review | Patch classification + reason + Classified By/On; audit Reclassify; row updates; receipt; Attendance grid E/U | A-CLASSIFY-EXCUSED, A-CLASSIFY-UNEXCUSED | conAbsReceipt/galAbsReceipt; row badgeAbsRowStatus + lblAbsRowNote; Screen1 colMonthAtt.Letter | S-ONE-EXCUSED, S-ONE-EXCUSED-NO-REASON, S-ONE-UNEXCUSED |
| R-CLASSIFY-BULK | Tick rows / Select all shown, then Mark Excused (one reason) or Mark Unexcused | Workflow and review | One Patch per ticked row; marked/failed/skipped counts; marked ticks cleared; rows leave the Not classified queue | A-BULK-EXCUSED, A-BULK-UNEXCUSED, A-TICK | lblAbsReceiptTitle; galAbsReceipt per-row lines; lblAbsBulkHint; galAbsList | S-BULK-EXCUSED, S-BULK-UNEXCUSED, S-BULK-NONE-TICKED |
| R-RECLASSIFY | Change an existing classification, audit old -> new | Workflow and review | Same write path from the Excused/Unexcused status filter; Before/After in audit | A-CLASSIFY-EXCUSED, A-CLASSIFY-UNEXCUSED | galAbsReceipt "Before" + "Classification" lines; Audit Events Before/After | S-RECLASSIFY |
| R-LOCK | Locked campus/month can't be classified | Security, persistence, and resilience | Rows in a Locked Month Locks campus/month show a lock note; tick + Excused… + Unexcused disabled; engine re-checks live locks | A-CLASSIFY-EXCUSED, A-BULK-EXCUSED | lblAbsRowNote "Month locked"; receipt "Skipped · locked" | S-LOCKED |
| R-REGRESSION | Existing Attendance/Students behaviour unchanged except the listed changes | App shell and navigation | Only header nav (Screen1) and End/Re-enroll (Students) change; add/edit/transfer/ratio unchanged | A-NAV-ATTENDANCE | Screen1 grid; Students add/edit/transfer/ratio receipts | S-REGRESSION |

## Requirement Coverage

| Requirement | Planned affordance | Fidelity |
| ----------- | ------------------ | -------- |
| Header switch Attendance / Students / Absences | Three ModernButtons (110 wide, gap 8) in conAttNav / conStuNav / conAbsNav, `Navigate(...)`, current screen Primary teal | Exact |
| Office and Admin only | Nav rows `Visible: =CanManageStudents`; AbsencesScreen body `Visible: =CanClassify`, conAbsDenied otherwise | Exact |
| End enrollment (end date default today, note required, confirm) | btnStuActEnd opens mode "end" in conStuForm: dpStuFormDate (DefaultDate Today()), txtStuFormReason (required), btnStuFormSubmit "End enrollment" | Exact |
| Re-enroll (campus, teacher, IEP ratio, start date after last end date) | btnStuActReenroll opens mode "reenroll": ddStuFormCampus (Office locked), ddStuFormTeacher, ddStuFormRatio, dpStuFormDate, optional note | Exact |
| Absences filters: campus (office fixed), teacher, date range (default this school year), status (Not classified default / Excused / Unexcused / All) | ddAbsCampus (disabled for Office), ddAbsTeacher, dpAbsFrom/dpAbsTo, rdoAbsStatus | Exact. Campus list has no "All campuses" entry so every server query stays delegable (Admin picks one campus at a time) |
| List: student, date, teacher, campus, current status | galAbsList rows: lblAbsRowName, lblAbsRowMeta, badgeAbsRowStatus, lblAbsRowNote | Exact |
| Count ("247 not classified") and zero-result state | lblAbsCount | Exact |
| Classify one: Excused or Unexcused on a row; Excused asks for a reason | Row buttons "Excused…" (opens conAbsDecide with rdoAbsReason + "Save as Excused") and "Unexcused" (saves directly) | Exact |
| Classify in bulk: tick rows or Select all shown, Mark Excused (one reason) / Mark Unexcused | chkAbsRowTick, btnAbsSelectAll, btnAbsClearTicks, ddAbsBulkReason, btnAbsBulkExcused, btnAbsBulkUnexcused | Exact |
| Receipt "18 marked Excused (Illness), 0 failed" | lblAbsReceiptTitle for bulk scope | Exact (adds ", N skipped" only when rows were skipped) |
| Present days never classified; Excused always needs a reason; locked months blocked | Server filter Present = false; engine re-checks live row, reason and live locks | Exact |
| Attendance grid shows green/red for that day | Screen1 OnVisible reloads colMonthAtt from Attendance (Letter E/U), unchanged existing rendering | Exact (existing Screen1 behaviour, no Screen1 change) |

## Required Record Fields

| Field key | Screen | Record surface | Required field | Source field | Presentation requirement |
| --------- | ------ | -------------- | -------------- | ------------ | ------------------------ |
| abs/row/student | AbsencesScreen | galAbsList row | Student (canonical identity) | Attendance.Student -> Display Name, Student Number | lblAbsRowName full text, wraps to 2 lines |
| abs/row/date | AbsencesScreen | galAbsList row | Absence date | Attendance.Date | lblAbsRowMeta, "ddd mmm d, yyyy" |
| abs/row/teacher | AbsencesScreen | galAbsList row | Teacher | Attendance.Teacher -> Name | lblAbsRowMeta |
| abs/row/campus | AbsencesScreen | galAbsList row | Campus | Attendance.Campus -> Name | lblAbsRowMeta |
| abs/row/status | AbsencesScreen | galAbsList row | Current status | Attendance.'Absence Classification' | badgeAbsRowStatus.Content (Not classified / Excused / Unexcused) |
| abs/row/reason | AbsencesScreen | galAbsList row | Reason, classified by/on, or lock | 'Absence Reason'.Name, 'Classified By'.'Full Name', 'Classified On', Month Locks | lblAbsRowNote |
| abs/decide/identity | AbsencesScreen | conAbsDecide | Student, date, teacher, campus, current status | same as row | lblAbsDecideWho |
| stu/detail/status | StudentsScreen | conStuProfile | Student status (Archived after End, Active after Re-enroll) | Students.'Status (aaca_status)' | badgeStuDetailStatus (unchanged) |
| stu/history/dates | StudentsScreen | galStuHistory row | Start - end, status, end reason, "continues from" | Enrollments fields | lblStuHistDates, lblStuHistEnd (unchanged) |

## State-Driven Surface Visibility

| Surface key | Owner screen | Surface control | State predicate | Visible and hidden states |
| ----------- | ------------ | --------------- | --------------- | ------------------------- |
| abs-denied | AbsencesScreen | conAbsDenied | `=!CanClassify` | Teacher / Read-only / not set up: visible; Office / Admin: hidden |
| abs-body | AbsencesScreen | conAbsBody | `=CanClassify` | Office / Admin: visible; others hidden |
| abs-decide | AbsencesScreen | conAbsDecide | `=conAbsRoot.Width >= 1024 \|\| !IsBlank(varAbsSelId)` | Desktop always (hint when nothing picked); narrow only while an absence is picked |
| abs-list-narrow | AbsencesScreen | conAbsListPanel | `=!(conAbsRoot.Width < 1024 && !IsBlank(varAbsSelId))` | Hidden on narrow while the reason prompt is open |
| abs-receipt | AbsencesScreen | conAbsReceipt | `=varAbsReceipt.Kind <> ""` | Visible after any classify attempt/cancel until Dismiss or screen re-entry |

## Action Contracts

| Requested action | Preconditions | Entry point | Owner screen | Control and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| ---------------- | ------------- | ----------- | ------------ | ----------------- | -------------------- | ---------------------------- | ------------------ | ----------------- | --------------------- |
| A-NAV-ATTENDANCE | CanManageStudents | Header "Attendance" | all three | btnAttNavAttendance / btnStuNavAttendance / btnAbsNavAttendance.OnSelect `=Navigate(Screen1)` | N/A | Screen1 shown; OnVisible reloads grid | N/A | N/A | Screen1 visible; its Attendance button teal |
| A-NAV-STUDENTS | CanManageStudents | Header "Students" | all three | btn*NavStudents.OnSelect `=Navigate(StudentsScreen)` | N/A | StudentsScreen shown | N/A | N/A | Students button teal |
| A-NAV-ABSENCES | CanManageStudents | Header "Absences" | all three | btn*NavAbsences.OnSelect `=Navigate(AbsencesScreen)` | N/A | AbsencesScreen shown; OnVisible loads queue | N/A | N/A | Absences button teal; lblAbsCount |
| A-END-ENROLLMENT | Selected student StatusText "Active", open enrollment exists, Office campus lock satisfied, not saving/loading | btnStuActEnd "End enrollment" -> form mode "end" | StudentsScreen | btnStuFormSubmit.OnSelect arm "end" | Enrollments by open.EnrId; Students by varStuSelId | Open enrollment End Date = eff, End Reason Archived, Status Ended if eff < Today() else Active; Student Archived, Archived On = eff, Archived By = CurrentUserRow; Audit Archive | Enrollment: End Date, End Reason, Status. Student: Status, Archived On, Archived By. Audit Events row | Student number, name, end date, end reason, enrollment status, previous + new student status, archived on/by, days after end, note, audit | conStuReceipt (varStuReceipt Kind "Ended") + galStuReceipt; badgeStuDetailStatus "Archived"; galStuHistory end date |
| A-REENROLL | Selected student StatusText "Archived", no open enrollment, Office campus lock satisfied | btnStuActReenroll "Re-enroll" -> form mode "reenroll" | StudentsScreen | btnStuFormSubmit.OnSelect arm "reenroll" | Students by varStuSelId; new Enrollment returned by Patch | New enrollment (Campus, Teacher, IEP Ratio, Start Date > last End Date, Service ActiveService, School Year containing start, Program Regular Year, Status Active if start <= Today() else Planned, Previous Enrollment = latest ended enrollment); Student Active, Archived On/By cleared; Owner = teacher User when not blank; Audit Unarchive | New Enrollment all fields; Student Status, Archived On, Archived By, Owner; Enrollment Owner; Audit row | Student number, prev/new status, archived on/by cleared, campus, teacher, IEP ratio, start date, enrollment status, school year, service, previous-enrollment link, gap days, owner, note, audit | conStuReceipt (Kind "Reenrolled"); badgeStuDetailStatus "Active"; galStuHistory new row with "continues from" |
| A-LOAD-ABSENCES | CanClassify, campus chosen, From <= To | Screen entry, filter change, ↻ | AbsencesScreen | AbsencesScreen.OnVisible -> btnAbsLoadEngine.OnSelect; btnAbsReload.OnSelect | Attendance.Attendance -> colAbsList.AttId | colAbsList = delegable Filter per status/campus/dates, Locked computed from colAbsLocks | N/A (read) | N/A | galAbsList.Items; lblAbsCount |
| A-FILTER-ABSENCES | CanClassify | ddAbsCampus, ddAbsTeacher, dpAbsFrom, dpAbsTo, rdoAbsStatus, btnAbsClearFilters | AbsencesScreen | OnChange of each (campus/dates/status reload; teacher local) | varAbsCampusId, varAbsTeacherId, varAbsFrom, varAbsTo, varAbsStatus | Items and count reflect all active filters; Clear filters restores defaults | N/A | N/A | lblAbsCount states count, status, campus, teacher, date range |
| A-TICK | Row not Locked, not saving | chkAbsRowTick, btnAbsSelectAll, btnAbsClearTicks | AbsencesScreen | chkAbsRowTick.OnCheck/OnUncheck; btnAbsSelectAll.OnSelect; btnAbsClearTicks.OnSelect | colAbsTicked.AttId | colAbsTicked holds the ticked AttIds | N/A (UI state) | N/A | lblAbsBulkHint "N ticked" |
| A-CLASSIFY-EXCUSED | Row not Locked; reason chosen (varAbsReasonId in colAbsReasons); CanClassify | Row btnAbsRowExcused "Excused…" -> conAbsDecide | AbsencesScreen | btnAbsDecideSave.OnSelect -> btnAbsClassifyEngine.OnSelect (Kind "Excused", Scope "one") | Attendance by varAbsSelId (AttId) | Live row re-checked (exists, Present false, not deleted, not locked, not changed); Patch Excused + reason + Classified By/On; Audit Reclassify; colAbsList row updated; varAbsSelId cleared | 'Absence Classification', 'Absence Reason', 'Classified By', 'Classified On'; Audit row | Student, date, teacher, campus, before, classification, reason, classified by, classified on, audit | conAbsReceipt (Kind "Classified"); badgeAbsRowStatus / row leaves Not classified queue; Screen1 Letter "E" |
| A-CLASSIFY-UNEXCUSED | Row not Locked; ClassText <> "Unexcused"; CanClassify | Row btnAbsRowUnexcused "Unexcused" | AbsencesScreen | btnAbsRowUnexcused.OnSelect -> btnAbsClassifyEngine.OnSelect (Kind "Unexcused", Scope "one") | Attendance by ThisItem.AttId | Same checks; Patch Unexcused, Absence Reason Blank(), Classified By/On; Audit Reclassify | same four fields | same proof set; Reason shows "None (cleared)" | conAbsReceipt; badge "Unexcused"; Screen1 Letter "U" |
| A-BULK-EXCUSED | >= 1 ticked, shown, unlocked row; bulk reason chosen | btnAbsBulkExcused "Mark Excused" | AbsencesScreen | btnAbsBulkExcused.OnSelect -> btnAbsClassifyEngine (Kind "Excused", Scope "bulk") | Attendance by each colAbsWork.AttId | One Patch per row as above; marked ticks removed | same four fields per row; one Audit row per marked row | Operation, reason, ticked, marked, failed, skipped + one line per row (student · date -> new classification · by, or outcome) | lblAbsReceiptTitle "N marked Excused (Reason), F failed"; galAbsReceipt |
| A-BULK-UNEXCUSED | >= 1 ticked, shown, unlocked row | btnAbsBulkUnexcused "Mark Unexcused" | AbsencesScreen | btnAbsBulkUnexcused.OnSelect -> engine (Kind "Unexcused", Scope "bulk") | same | same; reason cleared | same | same | same |

Excused / Unexcused are a paired review decision (not an arithmetic pair). Both decisions sit on every eligible
row; the engine guards each with a literal `req.Kind = "Excused"` / `"Unexcused"` arm and writes nothing for any
other value. Directional Mutation Evidence and Compound Sequence Evidence: N/A (no quantity arithmetic).

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| ------ | --------------- | ----------------------------- | ---------------------------------- | -------------------- | ----------------------------------- | ----------------- |
| A-END-ENROLLMENT | `closed` and `s2` Patch results -> varStuReceipt + colStuReceiptLines | Enrollments/Students; colStuHistory + colStuList after reload | Detail badge + history; archived list (status Archived + Include archived) | open.EnrId -> closed.Enrollment; varStuSelId = s2.Student | `Select(btnStuLoadEngine)` on success (reloads colStuList and colStuHistory) | `Set(varStuSelId, s2.Student)` keeps the detail open on that student |
| A-REENROLL | `ne` and `s2` Patch results -> varStuReceipt + colStuReceiptLines | Enrollments/Students; colStuHistory | Detail + history; Screen1 grid of the new teacher from the start date | ne.Enrollment; varStuSelId = s2.Student | `Select(btnStuLoadEngine)`; Screen1 OnVisible reload | varStuSelId = s2.Student |
| A-CLASSIFY-EXCUSED / A-CLASSIFY-UNEXCUSED | `wr` Patch result captured into colAbsLog -> varAbsReceipt + colAbsReceiptLines | Attendance by AttId | galAbsList row (colAbsList) and Screen1 grid (colMonthAtt) | w.AttId -> wr.Attendance -> colAbsLog.AttId -> colAbsList.AttId | Engine `Patch(colAbsList, c, {...from wr})` on success only; Screen1 OnVisible -> btnAttLoadEngine | Row matched by AttId; row leaves the list when the status filter no longer matches |
| A-BULK-EXCUSED / A-BULK-UNEXCUSED | per-row `wr` -> colAbsLog -> receipt title + per-row lines | Attendance by each AttId | galAbsList, lblAbsBulkHint | colAbsWork.AttId per row | Same local Patch per row; `RemoveIf(colAbsTicked, AttId in marked)` | Per-row receipt line labelled student · date |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| ------ | ----- | -------------- | ---------------------------- | ------------------------------- | --------------------- | ------------------- |
| A-END-ENROLLMENT | Enrollment End Date | Changed | dpStuFormDate.SelectedDate (eff) | Patch(Enrollments, old, {'End Date': eff}) | "End date" = Text(closed.'End Date') | lblStuHistDates |
| A-END-ENROLLMENT | Enrollment End Reason | Changed | constant Archived | 'End Reason (Enrollments)'.Archived | "End reason" = Text(closed.'End Reason') | lblStuHistEnd |
| A-END-ENROLLMENT | Enrollment Status | Changed | eff vs Today() | If(eff < Today(), Ended, Active) | "Enrollment status" = Text(closed.'Status (aaca_status)') | lblStuHistDates |
| A-END-ENROLLMENT | Student Status | Changed | Active | 'Status (Students)'.Archived | "Previous student status" / "Student status" = Text(s2...) | badgeStuDetailStatus |
| A-END-ENROLLMENT | Archived On / Archived By | Changed | eff / CurrentUserRow | Patch(Students, stu, {...}) | "Archived on" / "Archived by" from s2 | lblStuDetailFacts |
| A-END-ENROLLMENT | Note | Changed (audit only) | txtStuFormReason.Text | Audit Reason | "Note" = noteShort | Audit Events |
| A-END-ENROLLMENT | Start Date, Teacher, Campus, IEP Ratio | Preserved | old enrollment | omitted from partial Patch | "Teacher", "Campus", "Enrollment start" from closed | lblStuHistPlacement |
| A-REENROLL | Campus, Teacher, IEP Ratio, Start Date | Changed (new record) | ddStuFormCampus, ddStuFormTeacher, ddStuFormRatio, dpStuFormDate | Patch(Enrollments, Defaults(...)) | "Campus", "Teacher", "IEP ratio", "Start date" from ne | galStuHistory new row |
| A-REENROLL | Status, School Year, Service, Program, Previous Enrollment | Changed (derived) | eff, colStuYears/'School Years', ActiveService, Regular Year, liveLast | same Patch | "Enrollment status", "School year", "Service", "Previous enrollment" from ne | lblStuHistEnd "continues from" |
| A-REENROLL | Student Status, Archived On, Archived By | Changed | Archived / date / user | Patch(Students, stu, {Active, Blank(), Blank()}) | "Student status", "Archived on" Cleared, "Archived by" Cleared | badgeStuDetailStatus |
| A-REENROLL | Owner (student + enrollment) | Changed when tch.User not blank | tch.User | Patch Owner | "Record owner" | N/A (receipt) |
| A-REENROLL | Previous enrollment End Date / End Reason | Preserved | liveLast | not written | "Previous enrollment ... ended <date>" | galStuHistory older row |
| A-CLASSIFY-* / A-BULK-* | Absence Classification | Changed | req.Kind | Excused / Unexcused literal arm | "Classification" / per-row value (g.NewClass from wr) | badgeAbsRowStatus; Screen1 Letter |
| A-CLASSIFY-* / A-BULK-* | Absence Reason | Changed | Excused: rsn (varAbsReasonId / varAbsBulkReasonId); Unexcused: Blank() | Patch | "Reason" (g.ReasonName from wr, "None (cleared)") | lblAbsRowNote |
| A-CLASSIFY-* / A-BULK-* | Classified By / Classified On | Changed | CurrentUserRow / Now() | Patch | "Classified by" / "Classified on" from wr | lblAbsRowNote |
| A-CLASSIFY-* / A-BULK-* | Present, Is Deleted, Date, Student, Teacher, Campus, Record Key | Preserved | live row | omitted from partial Patch | "Student", "Date", "Teacher", "Campus" | lblAbsRowName/Meta |

## Functional Test Matrix

Real Dataverse data (126 students, 1,252 unclassified absences). "Given" rows name the record picked at test time;
record its Display Name, Attendance ID and date before acting.

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| -------- | ----- | ---- | ---- | ---------------- | ------------------------- |
| S-NAV3-OFFICE | Office user (campus North) on Screen1 | Tap Absences, then Students, then Attendance | Each screen opens; its own button is teal, the other two Secondary | conAttNav / conStuNav / conAbsNav | Buttons stay on one row at 390 wide (3x110 + 2x8 = 346 <= 358) |
| S-NAV3-TEACHER-HIDDEN | Teacher user | Open app | No nav row on Screen1; AbsencesScreen (if reached) shows conAbsDenied, no queue | conAttNav.Visible false; conAbsDenied | Read-only same |
| S-QUEUE-DEFAULT | Office user, North, current school year, unclassified absences exist | Open Absences | colAbsList = North absences in [school-year start, Today] with Present false, not deleted, unclassified | lblAbsCount "N not classified · North · All teachers · <dates>"; galAbsList sorted by date | ddAbsCampus disabled for Office |
| S-QUEUE-FILTER | Admin; campus with >= 2 absences for teacher T1 and >= 1 for T2 | Pick T1 in ddAbsTeacher; then Clear filters | Only T1 rows shown (both T1 rows present, T2 row gone); clear restores all teachers + defaults | galAbsList; lblAbsCount names T1 | Status radio Excused reloads with server predicate Excused |
| S-QUEUE-EMPTY | From = To = a Sunday with no absences | Set dates | colAbsList empty | lblAbsCount "0 not classified · Nothing matches these filters…"; galAbsList hidden | From > To -> "Choose a From date on or before the To date." and empty list |
| S-ONE-EXCUSED | Unclassified absence A1 (student S, date D, unlocked) | Row "Excused…", choose Illness, "Save as Excused" | A1 Absence Classification Excused, Reason Illness, Classified By = me, Classified On now; Audit Reclassify | Receipt "Marked Excused (Illness) · S · D" with lines Before "Not classified", Classification, Reason, Classified by/on, Audit; A1 leaves Not classified queue; Screen1 cell E (green) | Cancel -> receipt "Excused cancelled … nothing was changed", source unchanged |
| S-ONE-EXCUSED-NO-REASON | A1 picked in conAbsDecide, no reason | Look at Save | btnAbsDecideSave disabled; lblAbsDecideCheck "Choose a reason. Excused always needs one." | conAbsDecide | Engine also blocks: "Not saved. Excused needs a reason…" |
| S-ONE-UNEXCUSED | Unclassified absence A2 | Row "Unexcused" | A2 Unexcused, Reason blank, Classified By/On set; Audit | Receipt "Marked Unexcused · …" Reason "None (cleared)"; Screen1 cell U (red) | Button disabled on rows already Unexcused |
| S-RECLASSIFY | A1 now Excused (Illness) | Status radio Excused; row A1 "Unexcused" | A1 Unexcused, reason cleared; audit Before "Excused (Illness)" After "Unexcused" | Receipt Before/Classification lines; row leaves Excused filter | Row "Excused…" on an Excused row pre-selects its current reason |
| S-BULK-EXCUSED | 3 unclassified, unlocked rows ticked (A3, A4, A5) | Choose Illness in ddAbsBulkReason; Mark Excused | 3 Patches; all Excused (Illness) | Receipt title "3 marked Excused (Illness), 0 failed" + 3 per-row lines; rows leave queue; hint "No absences ticked…" | Tick hidden by teacher filter is not processed |
| S-BULK-UNEXCUSED | Select all shown with 2 rows | Mark Unexcused | 2 rows Unexcused, reasons cleared | Title "2 marked Unexcused, 0 failed" | — |
| S-BULK-NONE-TICKED | Nothing ticked | Look at bulk buttons | Both disabled; hint "No absences ticked. Tick rows or use Select all shown." | lblAbsBulkHint | Mark Excused also disabled until a bulk reason is chosen |
| S-LOCKED | Admin created Month Locks (campus North, Month 2026-08-01, Locked) outside the app | Open queue covering August | August rows show "Month locked · cannot classify", tick/Excused…/Unexcused disabled, excluded from Select all | lblAbsRowNote | A row locked after load is skipped by the engine: receipt "Skipped · locked", row flagged |
| S-END-OK | Active student S1 with open enrollment E1 (start 2026-08-12) | Detail -> End enrollment; end date 2026-09-26 (past); note "Moved out of state"; tick confirmation if shown; End enrollment | E1 End Date 2026-09-26, End Reason Archived, Status Ended; S1 Archived, Archived On 2026-09-26, By me; Audit Archive | Receipt "Enrollment ended · S1 · … archived from Sep 26, 2026" + lines; badge Archived; history row end date | Receipt Kind "Ended" |
| S-END-FUTURE | Active S2, open enrollment | End date Today()+10 | Enrollment Status stays Active (until the date); S2 Archived | Receipt "Enrollment status Active"; S2 still on Screen1 grid until that date | End date before E start -> blocked message |
| S-END-NO-NOTE | S1 form in mode end, note blank | Look at submit | Disabled; lblStuFormCheck "Enter a note for the audit log." | lblStuFormCheck | — |
| S-END-CANCEL | Form in mode end | Cancel | Nothing written | Receipt "End enrollment cancelled · S1 · nothing was changed" | — |
| S-REENROLL-OK | Archived S1 (last end 2026-09-26) | Re-enroll; campus North, teacher T1, ratio 2:1, start 2026-10-05 | New enrollment E2 (Planned, start 2026-10-05, Previous Enrollment E1); S1 Active, Archived On/By cleared; Owner T1 user; Audit Unarchive | Receipt lines incl. "Previous enrollment Linked · ended Sep 26, 2026" and "Gap 8 days…"; history shows both rows; T1 grid from Oct 5 | — |
| S-REENROLL-BAD-DATE | Archived S1 (last end 2026-09-26) | Start date 2026-09-26 | Submit disabled; "The start date must be after Sep 26, 2026, the last end date." | lblStuFormCheck | Engine re-checks live last End Date |
| S-REENROLL-CANCEL | Form in mode reenroll | Cancel | Nothing written | Receipt "Re-enroll cancelled · …" | — |
| S-REGRESSION | Existing data | Screen1 record P/A, bulk all present; Students add / edit / change class / change ratio | Behaviour identical to build 2 | Existing receipts (varLastAction, varStuReceipt) | Discharge / Archive / Unarchive buttons no longer exist |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| -------------- | ------------------------ | ------------------- |
| ddAbsCampus | lblAbsCampus.Text `="Campus"` | conAbsCampusField |
| ddAbsTeacher | lblAbsTeacher.Text `="Teacher"` | conAbsTeacherField |
| dpAbsFrom | lblAbsFrom.Text `="From date"` | conAbsFromField |
| dpAbsTo | lblAbsTo.Text `="To date"` | conAbsToField |
| rdoAbsStatus | lblAbsStatus.Text `="Status"` | conAbsStatusField |
| ddAbsBulkReason | lblAbsBulkReason.Text `="Reason for Mark Excused"` | conAbsBulkReasonField |
| rdoAbsReason | lblAbsReason.Text `="Reason *"` | conAbsReasonField |
| Students re-enroll/end inputs | existing lblStuFormCampus / lblStuFormTeacher / lblStuFormRatio / lblStuFormDate / lblStuFormReason (texts updated) | existing conStuFormPlace / conStuFormRatio / conStuFormDate / conStuFormReason |

## Layout Budget Contracts

Width source on every screen: the screen root's `Width` (conAttRoot / conStuRoot / conAbsRoot); breakpoints 640 and
1024. Narrowest supported: 390 wide -> 358 inside a 16-padded panel.

| Screen / container | Branch / screen-width source | Horizontal total-width arithmetic | Vertical height arithmetic | Protected controls |
| ------------------ | ---------------------------- | ----------------------------------- | -------------------------- | ------------------ |
| all / c*Nav | header inner 390-32 = 358 | 3 x 110 + 2 x 8 = 346 <= 358 | 44 | all three nav buttons |
| StudentsScreen / conStuActions | conStuDetail.Width - 32 | >= 600: 120+120+120+150+3x8 = 534 (1 line, 44); 376-599: 2 lines (96); < 376: 2 lines of 2 (<= 148) | as existing formula | End enrollment / Re-enroll |
| AbsencesScreen / conAbsNav | as above | 346 <= 358 | 44 | nav |
| AbsencesScreen / conAbsListPanel | conAbsRoot.Width | children stretch | wide 990; phone 1158 (see brief) | bulk buttons, gallery |
| AbsencesScreen / conAbsScopeRow, conAbsDateRow | phone 358 | 140 + 8 + 140 = 288 | 58 | filters |
| AbsencesScreen / conAbsBulkRow | < 640 vertical, else horizontal | wide: 140 + 8 + 288 = 436 <= 608; phone: 288 <= 358 | wide 58; phone 58 + 8 + 44 = 110 | Mark Excused / Mark Unexcused |
| AbsencesScreen / galAbsList row | template width phone ~340 | top: 44+8+110+8 = 170 + name; bottom: 100+8+110+8 = 226 + note | 8+44+4+meta+4+44+8 = 130 wide / 148 phone = TemplateSize | tick, Excused…, Unexcused |
| AbsencesScreen / conAbsDecide | side inner >= 307 | actions 160 + 8 + 100 = 268 | picked: 16+28+8+72+8+(22+radio)+8+36+8+44+16 | Save as Excused |

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| ------ | ------------ | -------------- | ------------- | -------------- | --------------- |
| Screen1 | conAttRoot (existing, unchanged) | AutoLayout | `conAttRoot.Width: =Parent.Width` | `conAttRoot.Height: =Parent.Height` | LayoutOverflow.Scroll |
| StudentsScreen | conStuRoot (existing, unchanged) | AutoLayout | `conStuRoot.Width: =Parent.Width` | `conStuRoot.Height: =Parent.Height` | LayoutOverflow.Scroll |
| AbsencesScreen | conAbsRoot (sole top-level child) | AutoLayout | `conAbsRoot.Width: =Parent.Width` | `conAbsRoot.Height: =Parent.Height` | LayoutOverflow.Scroll |

## Working Directory

C:\src\aaca-attendance\app

## Discovery Summary

- Existing screens: Screen1 (Attendance, prefix Att), StudentsScreen (prefix Stu). New: AbsencesScreen (prefix Abs).
- Layout: AutoLayout responsive roots; Gallery rows use one AutoLayout shell.
- Data sources: Attendance, Absence Reasons, Month Locks, Campuses, Staff, Users, Enrollments, Students, School Years, Services, Audit Events.
- Controls: GroupContainer, ModernText, ModernButton, Classic/Button (hidden engines), Gallery, ModernDropdown,
  ModernDatePicker, ModernRadio, ModernCheckbox, ModernSpinner, Badge (all described in the packet).
- Verified syntax: `'Absence Classification' = Blank()` (delegable, not IsBlank); classification Patch + Reclassify audit;
  'End Reason (Enrollments)'.Archived.

## Dispatch

| Action | Screen | Target File | YAML Key | Name Prefix | Screen Brief |
| ------ | ------ | ----------- | -------- | ----------- | ------------ |
| Modify | Attendance | `C:\src\aaca-attendance\app\Screen1.pa.yaml` | Screen1 | Att | `C:\src\aaca-attendance\app\Screen1.screen-plan.md` |
| Modify | Students | `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml` | StudentsScreen | Stu | `C:\src\aaca-attendance\app\StudentsScreen.screen-plan.md` |
| Create | Absences | `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml` | AbsencesScreen | Abs | `C:\src\aaca-attendance\app\AbsencesScreen.screen-plan.md` |

## App Changes

### Before builders

1. `App.Formulas` — append after the `FirstSchoolYear` line (keep every existing formula):

```
      // ---------- Absence classification (build 3) ----------
      CanClassify = IsOfficeRole || IsAdminRole;
      CurrentSchoolYear = LookUp('School Years', 'Start Date' <= Today() && 'End Date' >= Today());
```

2. `App.OnStart` — append after `Clear(colStuReceiptLines)` (add `;` after that line first):

```
      Set(varAbsCampusId, If(StudentCampusLock <> ZeroGuid, StudentCampusLock, !IsBlank(CurrentStaff.Campus), CurrentStaff.Campus.Campus, Coalesce(First(Sort(Campuses, Name, SortOrder.Ascending)).Campus, ZeroGuid)));
      Set(varAbsTeacherId, ZeroGuid);
      Set(varAbsStatus, "Not classified");
      Set(varAbsFrom, Coalesce(CurrentSchoolYear.'Start Date', Date(Year(Today()) - If(Month(Today()) < 7, 1, 0), 7, 1)));
      Set(varAbsTo, Today());
      Set(varAbsLoading, false);
      Set(varAbsSaving, false);
      Set(varAbsLoadError, "");
      Set(varAbsSelId, ZeroGuid);
      Set(varAbsSelId, Blank());
      Set(varAbsReasonId, ZeroGuid);
      Set(varAbsReasonId, Blank());
      Set(varAbsBulkReasonId, ZeroGuid);
      Set(varAbsBulkReasonId, Blank());
      Set(varAbsReq, {Kind: "", Scope: "", ReasonId: ZeroGuid});
      Set(varAbsReceipt, {Kind: "", Title: ""});
      ClearCollect(colAbsTicked, {AttId: ZeroGuid});
      Clear(colAbsTicked);
      ClearCollect(colAbsWork, {AttId: ZeroGuid});
      Clear(colAbsWork);
      ClearCollect(colAbsLog, {AttId: ZeroGuid, StudentName: "", AbsDate: Today(), TeacherName: "", CampusName: "", OldClass: "", NewClass: "", ReasonName: "", ByName: "", OnText: "", Outcome: "", AuditOk: false});
      Clear(colAbsLog);
      ClearCollect(colAbsReceiptLines, {Label: "", Value: ""});
      Clear(colAbsReceiptLines)
```

(OnStart is a `|-` block, so the record literals need no extra YAML quoting.) No existing OnStart line is removed.
The Discharge/Archive/Unarchive removal needs no App change.

### After builders

None. (StartScreen stays `=Screen1`.)

## Editor State Changes

ScreensOrder: Screen1, StudentsScreen, AbsencesScreen. ComponentDefinitionsOrder: none (unchanged, empty).
