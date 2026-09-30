# Canvas App Plan

## Mode

EDIT (build 5 — attendance roles + parent-report approval)

## Requirements

Source of truth: `C:\src\aaca-attendance\app\canvas-app-requirements.md` (verbatim request, clarifications, approved
plan, capability inventory). Summary of the approved edit:

- Teachers: mark "1" only, and only on their own grid (selected teacher = own Staff row); tap a 1 -> confirm -> undo
  (soft delete + audit). No path to "0"/"A" anywhere. 0 cells are never actionable for anyone. Teachers may view other
  teachers' grids at their own campus read-only (campus picker fixed). "All" day-present unchanged but gated the same.
- Office and Admin (and Read-only): grid is view only with a "View only" banner. Office picks teachers at own campus;
  admin / read-only pick any campus.
- 0 cells show the source in tooltip and Details: "Absent – Excused: Illness (parent report #515)".
- Absences > Parent reports gets a second queue "Ready to approve": matched Student Absence Log items
  (Exact / Approved Variation / Manually Resolved), parseable AbsenceDate >= cut-over (App Settings
  ParentReportCutoverDate, 2026-01-01), no Report Decisions row. Office sees own campus; admin sees all.
- Approve panel: per school day planned outcome from the live Attendance row; Excused/Unexcused (required), Absence
  Reason (required), optional note (pre-filled from parent Reason, max 200); Approve writes attendance 0s (create /
  restore / classify with Source Report ID + full snapshots), one Report Decisions row, one Audit Events row, and a
  receipt listing every day. Dismiss requires a note, records a Dismissed decision, writes no attendance.
- Classify view default From date = 2026-01-01 (cut-over), never earlier.
- Needs Review queue and StudentsScreen unchanged.

## Original Request Capability Inventory

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Observer(s) | Scenario(s) |
| --- | --- | --- | --- | --- | --- | --- |
| R-ROLE-NAV | Teachers can't access Students/Absences; office all three (own campus); admin everything | Security, persistence, and resilience | Nav hidden for Teacher/Read-only; screens show not-authorised panel; unchanged for Office/Admin | A-NAV | `conAttNav.Visible: =CanManageStudents`; `conAbsDenied.Visible: =!CanClassify` | S-NAV-TEACHER, S-NAV-OFFICE |
| R-TEACHER-MARK | Teacher marks 1 only, own students | Data lifecycle | blank -> 1 upsert (existing engine), no path to 0 | A-MARK-PRESENT | `btnAttCell.Text` ("1"), `lblAttReceipt.Text` (varLastAction.Message) | S-MARK-1 |
| R-TEACHER-UNDO | Teacher can undo a 1 | Data lifecycle | 1 -> confirm -> soft delete + audit | A-UNDO-PRESENT | `conAttConfirm`, `lblAttReceipt.Text`, `btnAttCell.Text` ("") | S-UNDO-1, S-UNDO-CANCEL |
| R-VIEW-ONLY | Teachers view other teachers' grids at their campus read-only; office and admin view-only | Security, persistence, and resilience | Editable only for own-teacher grid by a Teacher; View only banner otherwise; 0 cells never editable | A-VIEW-OTHER | `lblAttNotice.Text`, `btnAttCell.DisplayMode`, `btnAttCell.Tooltip`, `lblAttDetailFacts.Text` | S-VIEW-OTHER-TEACHER, S-VIEW-OFFICE, S-ZERO-LOCKED |
| R-READY-QUEUE | Office sees matched parent reports to approve | Workflow and review | Ready to approve list (matched, >= cutover, undecided), campus-scoped | A-LOAD-READY | `galAbsApList.Items`, `lblAbsApCount.Text`, `btnAbsApViewReady.Text` | S-READY-LIST, S-READY-EMPTY |
| R-APPROVE | Office hits Excused/Unexcused, brief reason, Approve; grid updates with 0 and colour | Workflow and review | Per-day outcomes; create/restore/classify 0s with Source Report ID; decision + audit; receipt | A-APPROVE-EXCUSED, A-APPROVE-UNEXCUSED | `lblAbsApReceiptTitle`, `lblAbsApReceiptBody`, `galAbsApRcptDays`; Screen1 `btnAttCell.Text/Fill/Tooltip` after reload | S-APPROVE-NEW-DAYS, S-APPROVE-CLASSIFY-EXISTING, S-APPROVE-SKIP-PRESENT, S-APPROVE-NO-REASON, S-APPROVE-ALREADY-DECIDED |
| R-DISMISS | (approved plan) dismiss duplicates/errors | Workflow and review | Decision Dismissed with note; no attendance writes | A-DISMISS | `lblAbsApReceiptBody.Text`, `galAbsApList.Items` (row gone) | S-DISMISS |
| R-BACKLOG | Classify view for 2026 backlog; hide pre-2026 | Data exploration | Default From = 2026-01-01 | A-FILTER-ABSENCES | `dpAbsFromV.DefaultDate: =varAbsFrom`, `lblAbsCountV.Text` | S-BACKLOG-DEFAULT |
| R-REGRESSION | Needs Review matching, Students screen unchanged | App shell and navigation | No behaviour change outside the listed items | A-NAV | `galAbsNrList`, `btnAbsNrResolve`, StudentsScreen untouched | S-REGRESSION |

## Requirement Coverage

| Requirement | Planned affordance | Fidelity |
| --- | --- | --- |
| Teacher adds present ("1") | Screen1 `btnAttCell` tap on a blank Open cell (own grid) and Day view `btnAttDayPresent` -> `btnAttSaveEngine` Target "P" | Exact |
| Teacher undoes a 1 | Tap a "1" cell (or Day view `btnAttDayClear`, relabelled "Undo") -> `conAttConfirm` -> `btnAttConfirmClear` "Confirm undo" -> soft delete + audit | Exact |
| No absent path for teachers | "A" target removed from `btnAttCell.OnSelect`; `btnAttDayAbsent` hidden + neutralised; save engine rejects any Target other than "P"/"clear" and any change to an active 0 row | Exact |
| Teachers view other teachers read-only | `ddAttTeacher` enabled for teachers (own campus list); `varCanEditMonth` false when selected teacher is not self; `lblAttNotice` "View only" banner | Exact |
| Office / admin view only | `varCanEditMonth` requires `IsTeacherRole`; banner shows role reason | Exact |
| 0s locked, show source | 0 cells never actionable outside Details mode; tooltip + Day view status + Details facts show "Absent – Excused: Illness (parent report #515)" | Exact (tooltip on a disabled classic button may not show in every browser; Details mode is the guaranteed path) |
| Ready to approve queue | New `btnAbsApViewReady` third toggle "Parent reports – Ready to approve (N)" -> `conAbsApView` with `galAbsApList` | Exact |
| Excused / Unexcused, reason, Approve | `rdoAbsApClass`, `ddAbsApReason`, `txtAbsApNote`, `btnAbsApApprove` in `conAbsApDetail` | Exact |
| Grid updates with 0 and colour | Approve writes Attendance; Screen1 reloads on visit; receipt `btnAbsApShowGrid` opens the teacher/month and highlights the first day | Exact |
| Dismiss | `btnAbsApDismiss` -> `conAbsApDismissPanel` with required `txtAbsApDismissNote` -> `btnAbsApDismissConfirm` | Exact |
| Hide pre-2026 backlog by default | `varAbsFrom` default and Clear filters = `ParentReportCutover` (2026-01-01) | Exact |

## Required Record Fields

| Field key | Screen | Record surface | Required field | Source field | Presentation requirement |
| --- | --- | --- | --- | --- | --- |
| ap-row-student | AbsencesScreen | galAbsApList row | App student name + matched Student_ID | colAbsAp.StudentName, StudentKey | `lblAbsApRowName`, full text, semibold 14, wraps to 2 lines |
| ap-row-parent | AbsencesScreen | galAbsApList row | Report #, names as typed by parent, campus, absence/return dates | ID, FirstName, LastName, CampusName/SchoolSite, AbsenceDateText, ReturnDateText | `lblAbsApRowMeta`, one combined line (wraps to 2) |
| ap-row-reason | AbsencesScreen | galAbsApList row | Reason, submitted by, notified | Reason, SubmittedBy, DateNotified | `lblAbsApRowSub`, reason truncated at 80 chars with "…" |
| ap-detail-facts | AbsencesScreen | conAbsApDetail | All report facts + matched student + match status | colAbsAp fields | `lblAbsApFacts`, 7 labelled lines |
| ap-detail-days | AbsencesScreen | galAbsApDays | Each school day + planned outcome | colAbsApPlan.DayDate, OutcomeText, TeacherName | `lblAbsApDayLine` per row |
| att-zero-source | Screen1 | btnAttCell tooltip, lblAttDayStatus, lblAttDetailFacts | Classification, reason, parent report # | colMonthAtt.Letter, ReasonName, SourceReportId | "Absent – Excused: Illness (parent report #515)" |

## State-Driven Surface Visibility

| Surface key | Owner screen | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- | --- |
| att-viewonly-banner | Screen1 | conAttNotice | `=StaffReady && lblAttNotice.Text <> ""` | Visible for load error, role view-only, or month lock; hidden for a teacher on own unlocked grid |
| abs-ready-view | AbsencesScreen | conAbsApView | `=CanClassify && varAbsView = "ready"` | Visible after Ready to approve toggle; hidden in Classify / Needs review views and for teachers |
| abs-ready-dismiss | AbsencesScreen | conAbsApDismissPanel | `=varAbsApDismissOpen && !IsBlank(varAbsApSelId)` | Visible after Dismiss pressed; hidden after confirm/cancel/open another report |
| abs-ready-receipt | AbsencesScreen | conAbsApReceipt | `=varAbsApReceipt.Kind <> ""` | Visible after any approve/dismiss attempt until Dismiss |

## Action Contracts

| Requested action | Preconditions | Entry point | Owner screen | Control and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-NAV (regression) | Role from CurrentStaff | Header nav | Screen1 / AbsencesScreen | `conAttNav.Visible`, `conAbsDenied.Visible` (unchanged) | N/A | No change | N/A | N/A | Teacher: no nav; Absences shows denied panel |
| A-MARK-PRESENT | `varCanEditMonth` (Teacher && varTeacher = self && no lock && no load error); cell State "Open"; no active row | Blank cell `btnAttCell` / Day `btnAttDayPresent` | Screen1 | `btnAttCell.OnSelect` / `btnAttDayPresent.OnSelect` -> `btnAttSaveEngine.OnSelect` Target "P" | Attendance by Student+Service+Date (AttId) | Upsert Present=Yes, Is Deleted=No + snapshots | Record Key, Date, Student, Service, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio, Present, Is Deleted | Saved/Restored · student · date · Status · IEP · Teacher · Term · Key | `lblAttReceipt.Text` + cell "1✓" with teal border |
| A-UNDO-PRESENT | `varCanEditMonth`; active row Letter "P" | Tap "1" cell / Day `btnAttDayClear` "Undo" | Screen1 | `btnAttCell.OnSelect` -> `conAttConfirm` -> `btnAttConfirmClear.OnSelect` -> engine Target "clear"; cancel `btnAttConfirmCancel.OnSelect` | Attendance AttId | Is Deleted=Yes; Audit Soft Delete | Is Deleted (+ Audit Events row) | Cleared · student · date · Is Deleted = Yes · Key · audit written | `lblAttReceipt.Text`; cell blank |
| A-BULK-PRESENT (regression) | `varCanEditMonth`; ≥1 Open cell that day | `btnAttDayAll` / `btnAttDayAllPresent` | Screen1 | unchanged -> `btnAttBulkEngine` | Attendance per student | Present=Yes for blanks, skip any active row | as A-MARK-PRESENT | "All present · date · N marked, N skipped, N failed" | `lblAttReceipt.Text` |
| A-VIEW-OTHER | Teacher; other teacher at own campus | `ddAttTeacher` | Screen1 | `ddAttTeacher.OnChange` (enabled for Teacher) | Staff.Staff | varTeacher = picked; `varCanEditMonth` false | N/A | N/A | `lblAttNotice.Text` "View only — …'s grid…"; all cells disabled |
| A-ZERO-SOURCE | Any role; active row Letter E/U/A | `btnAttDetailsToggle` then tap a 0 cell; or hover | Screen1 | `btnAttCell.OnSelect` (details branch) | colMonthAtt AttId | Opens `conAttDetail` (read-only for 0 rows) | N/A | N/A | `lblAttDetailFacts.Text` includes classification, reason, "parent report #N"; `btnAttCell.Tooltip` |
| A-LOAD-READY | CanClassify | `btnAbsApViewReady` / `btnAbsApReload` / screen OnVisible | AbsencesScreen | `btnAbsApEngine.OnSelect` | Student Absence Log ID | colAbsAp = matched, AbsDate >= ParentReportCutover, ID not in Report Decisions, campus-scoped | N/A | N/A | `galAbsApList.Items`, `lblAbsApCount.Text`, toggle count |
| A-OPEN-READY | Row in colAbsAp | `btnAbsApRowOpen` "Open" | AbsencesScreen | `btnAbsApRowOpen.OnSelect` -> `btnAbsApPlanEngine.OnSelect` | varAbsApSelId (SP ID) | colAbsApPlan = one row per school day with outcome from live Attendance | N/A | N/A | `lblAbsApFacts`, `lblAbsApDaysHead`, `galAbsApDays` |
| A-APPROVE-EXCUSED | varAbsApSelId set, plan loaded for it without error, StudentId mapped, `varAbsApClass = "Excused"`, reason picked, no prior decision | `rdoAbsApClass` "Excused" + `ddAbsApReason` + `btnAbsApApprove` | AbsencesScreen | selection-only `rdoAbsApClass.OnChange` -> guarded `btnAbsApApprove.OnSelect` | SP item ID `qid`; Attendance by Student+Service+Date; Report Decisions by Report Item ID | Per day: create/restore -> active 0 Excused; unclassified active 0 -> Excused; skips unchanged. Then Report Decisions Approved + Audit Reclassify; item leaves queue | Attendance (create/restore): Record Key, Date, Student, Service, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio, Present=No, Is Deleted=No, Absence Classification=Excused, Absence Reason, Classified By, Classified On, Notes, Source Report ID. Attendance (classify): Absence Classification, Absence Reason, Classified By, Classified On, Notes (if note given), Source Report ID. Report Decisions: Summary, Report Item ID, Decision, Classification, Absence Reason, Student, Campus, Student Key, Note, Days Created/Classified/Skipped. Audit Events row | Title (report #, student, Excused); Body: report #, student + key + campus, Decision Approved, Classification, Reason, Note, day counts, audit; per-day lines: date · outcome · "0 · Excused (reason) · report #N · Teacher · Key" | `conAbsApReceipt` (receipt); canonical Attendance via Screen1 reload (`btnAttCell.Text` "0", Fill ColorExcused, Tooltip) |
| A-APPROVE-UNEXCUSED | as above with `varAbsApClass = "Unexcused"` | `rdoAbsApClass` "Unexcused" + reason + `btnAbsApApprove` | AbsencesScreen | same event, literal guard `cls = "Unexcused"` | same | same with Unexcused | same (Classification=Unexcused; reason still required and written) | same with Unexcused | same; Fill ColorUnexcused |
| A-DISMISS | Report selected; dismiss note non-blank; no prior decision | `btnAbsApDismiss` -> `txtAbsApDismissNote` -> `btnAbsApDismissConfirm` | AbsencesScreen | `btnAbsApDismissConfirm.OnSelect` | SP item ID; Report Decisions | Report Decisions Dismissed row; Audit Update; no Attendance writes; item leaves queue | Report Decisions: Summary, Report Item ID, Decision=Dismissed, Student, Campus, Student Key, Note, Days*=0; Audit row | Title; Body: report #, student, Decision Dismissed, Note, "Attendance: not changed", audit | `conAbsApReceipt`; `galAbsApList` no longer lists the ID |
| A-CANCEL-READY | Report selected | `btnAbsApCancel`, `btnAbsApDismissCancel` | AbsencesScreen | OnSelect | N/A | Clear selection / close dismiss panel; no writes | N/A | N/A | Detail returns to empty state / panel hidden |
| A-SHOW-ON-GRID | Last receipt Kind "Approved" with a changed day | `btnAbsApShowGrid` | AbsencesScreen -> Screen1 | `btnAbsApShowGrid.OnSelect` | varAbsApGridLink StudentId/TeacherId/CampusId/FirstDay | Sets varCampus, varTeacher, varMonthStart, varViewDate, varLastAction(StudentId, DayNum); Navigate(Screen1) | N/A | N/A | Screen1 `lblAttReceipt` message + teal-bordered 0 cell for that student/day |
| A-FILTER-ABSENCES | Classify view | App start / `btnAbsClearFiltersV` | AbsencesScreen | `App.OnStart`, `btnAbsClearFiltersV.OnSelect` | N/A | varAbsFrom = ParentReportCutover (2026-01-01) | N/A | N/A | `dpAbsFromV` shows 1/1/2026; `lblAbsCountV.Text` range starts "Jan 1, 2026" |

Directional note: Excused/Unexcused is a shared-operation flow. `rdoAbsApClass.OnChange` only sets
`varAbsApClass`; `btnAbsApApprove` is the single guarded mutation; each direction has its own literal guard
(`cls = "Excused"`, `cls = "Unexcused"`); `varAbsApClass` resets to `""` on Open and after success; the receipt reads
the classification from the returned Report Decisions / Attendance records (not the reset state). No arithmetic, so no
Compound Sequence table applies.

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-MARK-PRESENT | `written` Patch result -> varLastAction -> `lblAttReceipt` | Attendance; colMonthAtt refreshed from `written` | Grid cell `btnAttCell` | StudentId+DayNum and written.Attendance | Engine replaces colMonthAtt row from `written` | varLastAction.StudentId/DayNum teal border |
| A-UNDO-PRESENT | same, Kind "Cleared" | Attendance Is Deleted | Grid cell blank | same | same | same |
| A-APPROVE-EXCUSED / -UNEXCUSED | `dec` (Report Decisions Patch result) -> varAbsApReceipt.Body; per-day `wr` -> colAbsApLog.Detail -> `galAbsApRcptDays` | Attendance (per-day `wr`), Report Decisions (`dec`) | Screen1 grid for the enrollment teacher/month; Ready queue (row removed) | SP item ID `qid` = Source Report ID = Report Item ID; Attendance AttId in colAbsApLog.AttId | Screen1 OnVisible runs btnAttLoadEngine (reloads colMonthAtt incl. SourceReportId/ReasonName); queue: RemoveIf(colAbsAp, ID = qid) + Collect(colAbsApDecided) only on success | `btnAbsApShowGrid` sets varTeacher/varCampus/varMonthStart and varLastAction {StudentId, DayNum} -> teal border on that cell |
| A-DISMISS | `dec` -> varAbsApReceipt | Report Decisions | Ready queue (row removed) | qid = Report Item ID | RemoveIf(colAbsAp, ID = qid) on success | N/A — row leaves queue |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| A-MARK-PRESENT | Present / Is Deleted | Changed | Target "P" | Patch Present true, Is Deleted false | "Status Present" in varLastAction.Message | colMonthAtt.Letter "P" -> cell "1" |
| A-MARK-PRESENT | Absence Classification / Reason / Source Report ID | Preserved | server row (only a deleted row can be restored) | omitted from Patch | N/A | N/A |
| A-UNDO-PRESENT | Is Deleted | Changed | local active P | Patch {'Is Deleted': true} | "Is Deleted = Yes" | cell blank |
| A-UNDO-PRESENT | all other fields | Preserved | server row | partial Patch | "Key <Record Key>" | Details after re-mark ("Restored") |
| A-APPROVE-* (create/restore) | Present, Is Deleted | Changed | "create"/"restore" outcome | Patch false/false on Coalesce(srv, Defaults) | per-day Detail "0" | Screen1 cell "0" |
| A-APPROVE-* | Absence Classification | Changed | varAbsApClass (literal guards) | `If(cls = "Excused", …Excused, cls = "Unexcused", …Unexcused)` | Detail `Text(wr.'Absence Classification')`; Body `Text(dec.Classification)` | cell Fill green/red |
| A-APPROVE-* | Absence Reason | Changed | varAbsApReasonId -> live 'Absence Reasons' row `rsn` | `'Absence Reason': rsn` | Detail `wr.'Absence Reason'.Name`; Body `dec.'Absence Reason'.Name` | tooltip "…: Illness…" |
| A-APPROVE-* | Notes | Changed (create/restore; classify when note non-blank) / Preserved (classify, blank note) | `Left(Trim(txtAbsApNote.Text), 200)` / srv.Notes | `Notes: note` / `Notes: If(note = "", srv.Notes, note)` | Body "Note: …" from dec.Note | Screen1 Details notes |
| A-APPROVE-* | Source Report ID | Changed | qid | `'Source Report ID': qid` | Detail "report #" & wr.'Source Report ID' | tooltip "(parent report #N)" |
| A-APPROVE-* | Classified By / On | Changed | CurrentUserRow / Now() | Patch | Detail "by " & wr.'Classified By'.'Full Name' | classify view list |
| A-APPROVE-* | Record Key, Date, Student, Service, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio | Changed (create/restore) / Preserved (classify) | seg (enrollment covering day), term | Full snapshot Patch / omitted | Detail "Teacher <name> · Key <Record Key>" | Screen1 grid of that teacher |
| A-APPROVE-* | Report Decisions row | Changed | qid, cls, rsn, note, counts | Patch Defaults('Report Decisions') | Body lines | queue excludes qid on reload |
| A-DISMISS | Report Decisions row (Decision Dismissed, Note) | Changed | txtAbsApDismissNote | Patch Defaults | Body "Decision: Dismissed", "Note: …" | queue excludes qid |
| A-DISMISS | Attendance | Preserved | — | no Attendance write | Body "Attendance: not changed" | Screen1 unchanged |

## Functional Test Matrix

Fixtures (arrange in the dev environment): campus CW (Chatsworth); teacher A = "Smith, Ana" (Teacher, CW, the
signed-in teacher); teacher B = "Lee, Ben" (Teacher, CW); office user O (Attendance Office, CW); admin M; student
"Doe, Jane" (STU-000123, External Client ID CW-1001) enrolled with teacher A, service SPED, from 2026-08-01;
school days Mon 9/14, Tue 9/15, Wed 9/16/2026 (September unlocked); reasons Illness, Other.

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-NAV-TEACHER | Signed in as teacher A | Open app | No nav row on Screen1 | `conAttNav` hidden | Direct Absences visit shows `conAbsDenied` |
| S-NAV-OFFICE | Office O | Open app | Nav row shows Attendance/Students/Absences | `conAttNav` visible | N/A |
| S-MARK-1 | Teacher A, own grid Sep 2026, Jane 9/17 blank Open | Tap cell 9/17 | Attendance row Jane+SPED+2026-09-17 Present=Yes, Is Deleted=No, Teacher A | cell "1✓", `lblAttReceipt` "Saved · Doe, Jane · Thu Sep 17 · Status Present · … Key 20260917\|STU-000123\|SPED" | Future date cell disabled |
| S-UNDO-1 | Jane 9/17 = 1 (active P) | Tap "1" -> Confirm undo | Row Is Deleted=Yes; Audit Soft Delete | cell blank; `lblAttReceipt` "Cleared · … Is Deleted = Yes · … audit event written" | Tapping a 0 cell does nothing (no confirm opens) |
| S-UNDO-CANCEL | Same | Tap "1" -> Cancel | Row unchanged | `lblAttReceipt` "Undo cancelled · … record unchanged"; cell "1" | N/A |
| S-BULK-GATED | Teacher A viewing teacher B | Look at "All" buttons | Disabled | `btnAttDayAll.DisplayMode` Disabled | Own grid: enabled, skips active rows |
| S-VIEW-OTHER-TEACHER | Teacher A | Pick "Lee, Ben" in `ddAttTeacher` | Grid loads B's students; `varCanEditMonth` false | `lblAttNotice` "View only — this is Lee, Ben's grid…"; cells disabled | `ddAttCampus` disabled; list shows only CW teachers |
| S-VIEW-OFFICE | Office O | Open Screen1, pick teacher A | Grid visible, not editable | `lblAttNotice` "View only — teachers mark attendance…"; cells disabled | Admin: campus picker enabled, same banner |
| S-ZERO-LOCKED | Jane 9/14 active 0 Excused, Reason Illness, Source Report ID 515; teacher A own grid | Tap cell 9/14; then Details mode + tap | Normal tap: nothing (disabled). Details: panel opens, notes read-only | Tooltip / `lblAttDetailFacts` "Absent – Excused: Illness (parent report #515)"; `btnAttDetailSave` disabled | Engine blocks Target "P"/"clear" on active 0 rows |
| S-READY-LIST | SP item #515: Match_Status "Exact", Student_ID CW-1001, SchoolSite Chatsworth, Absence Date "9/14/2026", Return "9/17/2026", no Report Decisions row; #410 Needs Review; #300 Exact dated "12/15/2025" | Office O opens Absences > Ready to approve | Queue lists #515 only | `galAbsApList` row "Doe, Jane · CW-1001"; `btnAbsApViewReady` "(1)" | #300 excluded (before cut-over), #410 excluded (Needs Review) |
| S-READY-SCOPE-OFFICE | #600 Exact for a student enrolled at Oxnard, SchoolSite Oxnard | Office O (CW) loads queue | #600 not listed; admin sees it | `galAbsApList.Items` | Report with SchoolSite Chatsworth but student at OX is listed for O |
| S-READY-EMPTY | No eligible items | Open Ready to approve | Empty queue | `lblAbsApCount` "No parent reports are ready to approve…" | Load error -> red count text, queue cleared |
| S-APPROVE-NEW-DAYS | #515 open; no Attendance rows 9/14-9/16 | Excused, Illness, note "Flu", Approve | 3 rows created: Present=No, Excused, Illness, Source Report ID 515, Teacher A snapshot; Report Decisions Approved (Days Created 3, Classified 0, Skipped 0); Audit row | Receipt Title "Approved · parent report #515 · Doe, Jane · Excused"; Body counts "3 created or restored"; 3 day lines "New 0 created · 0 · Excused (Illness) · report #515 · …" ; Screen1 cells 9/14-9/16 "0" green | Double-click: `varAbsApSaving` disables Approve |
| S-APPROVE-UNEXCUSED | #516 (1 day, 9/15) | Unexcused, Other, Approve | Row Unexcused, reason Other | Receipt "Unexcused"; cell red | N/A |
| S-APPROVE-RESTORE-DELETED | 9/16 row exists Is Deleted=Yes (undone 1) | Approve #515 | Row restored: Present=No, Is Deleted=No, Excused, snapshots rewritten | day line "Deleted row restored as 0" | N/A |
| S-APPROVE-CLASSIFY-EXISTING | 9/15 active 0 unclassified (legacy) | Approve #515 Excused | Row classified Excused, Source Report ID 515; Notes kept if note blank | day line "Existing 0 classified"; counts Classified 1 | 9/15 already Excused -> "Skipped · already classified" |
| S-APPROVE-SKIP-PRESENT | 9/16 active 1 (teacher marked present) | Approve #515 | 9/16 unchanged | day line "Skipped · marked present by teacher" (flagged in plan `lblAbsApDaysHead`); Days Skipped 1 | Locked month -> "Skipped · month locked"; no enrollment -> "Skipped · not enrolled" |
| S-APPROVE-NO-REASON | #515 open, Excused picked, no reason | Look at Approve | Disabled; `lblAbsApCheck` "Choose an absence reason…" | `btnAbsApApprove.DisplayMode` | No classification -> disabled, "Choose Excused or Unexcused" |
| S-APPROVE-ALREADY-DECIDED | #515 listed; another user recorded a decision meanwhile | Approve | No Attendance or decision writes | Receipt Kind Blocked "Not approved · report #515 was already approved…"; row removed from queue | Report Decisions alternate key rejects a race -> Failed receipt "decision NOT recorded" |
| S-APPROVE-UNMAPPED | #700 Exact, Student_ID "CW-9999" not in Students | Open #700 | Plan not built | `lblAbsApCheck` "No app student has Student Key CW-9999…"; Approve disabled | Dismiss still allowed |
| S-APPROVE-CANCEL | #515 open | Cancel | No writes | Detail empty state | N/A |
| S-DISMISS | #515 open | Dismiss -> note "Duplicate of #514" -> Confirm dismiss | Report Decisions Dismissed + Audit Update; no Attendance change | Receipt "Dismissed · parent report #515"; Body "Attendance: not changed"; row gone | S-DISMISS-NO-NOTE: blank note -> Confirm disabled |
| S-SHOW-ON-GRID | After S-APPROVE-NEW-DAYS | Press "Show on grid" | Screen1 opens teacher A, Sep 2026 | 9/14 cell "0" green with teal border; `lblAttReceipt` "Parent report #515 approved…" | Hidden when no day changed |
| S-BACKLOG-DEFAULT | Fresh app start; setting 2026-01-01 | Open Absences (Classify) | varAbsFrom = 2026-01-01 | `dpAbsFromV` 1/1/2026; `lblAbsCountV` "… Jan 1, 2026 – …" | Clear filters restores 1/1/2026 |
| S-REGRESSION | Needs Review item #410 | Review, pick student, Resolve Match | Unchanged build-4 behaviour | `conAbsNrReceipt` | Students screen untouched |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| rdoAbsApClass | lblAbsApClass `="Classification *"` | conAbsApClassField |
| ddAbsApReason | lblAbsApReason `="Absence reason *"` | conAbsApReasonField |
| txtAbsApNote | lblAbsApNote `="Note for the attendance record (optional, 200 max)"` | conAbsApNoteField |
| txtAbsApDismissNote | lblAbsApDismissNote `="Why dismiss? (required)"` | conAbsApDismissField |
| ddAttTeacher (existing) | lblAttTeacher `="Teacher"` | conAttTeacherField |

## Layout Budget Contracts

| Screen / container | Branch / screen-width source | Horizontal total-width arithmetic | Vertical height arithmetic | Protected controls |
| --- | --- | --- | --- | --- |
| AbsencesScreen / conAbsViewBar | conAbsRoot.Width >= 1024 horizontal | 16+170+8+320+8+310+16 = 848 ≤ 1024 | 44 | three view buttons |
| AbsencesScreen / conAbsViewBar | conAbsRoot.Width < 1024 vertical | buttons Width = Parent.Width - 32 | 3×44 + 2×8 = 148 | same |
| AbsencesScreen / galAbsApList row | < 640 / ≥ 640 | top row: name FillPortions 1 + Open 90 + gap 8; at 390: 390-32-16-16 = 326 → name 228 | desktop 8+44+4+36+4+36+8 = 140 ≤ 150; phone 8+44+4+54+4+54+8 = 176 ≤ 200 | Open |
| AbsencesScreen / conAbsApActions | all | 120+8+110+8+96 = 342 ≤ 358 (phone inner) | 44 | Approve, Dismiss, Cancel |
| AbsencesScreen / conAbsApDetail | selected | N/A | 16+28+8+facts(150/200)+8+head(40/60)+8+days(216/260)+8+58+8+58+8+94+8+check(36/54)+8+44 [+8+170 dismiss] +16 | Approve |
| AbsencesScreen / conAbsApReceipt | all | title FillPortions 1 + Dismiss 88 | 8+top(44/84)+4+body(150/180/240)+4+days(Min(216/260, 36/52×n))+4+44+8 | receipt body + day lines |
| Screen1 / galAttDayList row | all | Present 100 + 8 + Undo 88 = 196 | 8+24+4+36+4+44+8 = 128 ≤ 132 TemplateSize | Present, Undo |
| Screen1 / conAttNotice | <640 68, <1024 56, else 44 | text ≤ 140 chars: phone 3 lines×17+8 = 59 ≤ 68 | as left | banner text |

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| --- | --- | --- | --- | --- | --- |
| Screen1 | conAttRoot (sole top-level child) | AutoLayout | `conAttRoot.Width: =Parent.Width` | `conAttRoot.Height: =Parent.Height` | LayoutOverflowY Scroll |
| AbsencesScreen | conAbsRoot (sole top-level child) | AutoLayout | `conAbsRoot.Width: =Parent.Width` | `conAbsRoot.Height: =Parent.Height` | LayoutOverflowY Scroll |

## Working Directory

C:\src\aaca-attendance\app

## Discovery Summary

- Existing screens: Screen1 (Attendance, prefix Att), StudentsScreen (Stu, untouched), AbsencesScreen (Abs; build-5 additions AbsAp)
- Layout: AutoLayout throughout; scroll roots conAttRoot / conAbsRoot
- Data sources: Attendance (+ 'Source Report ID'), Enrollments, Students, Staff, Campuses, Terms, Calendar Exceptions,
  Month Locks, Absence Reasons, App Settings (ParentReportCutoverDate), Audit Events, Report Decisions (new),
  Student Absence Log (SharePoint), Users
- Controls: GroupContainer, Gallery, ModernText, ModernButton, Classic/Button, ModernDropdown, ModernRadio,
  ModernTextInput, ModernSpinner (all already in the app; definitions in the discovery packet)
- Open risk for the orchestrator: display names of Report Decisions aaca_dayscreated / aaca_daysclassified /
  aaca_daysskipped are assumed to be 'Days Created' / 'Days Classified' / 'Days Skipped' (per the approved plan
  wording). If compile reports them unknown, check `get_data_source_schema` and substitute the display names.

## Dispatch

| Action | Screen | Target File | YAML Key | Name Prefix | Screen Brief |
| --- | --- | --- | --- | --- | --- |
| Modify | Attendance | `C:\src\aaca-attendance\app\Screen1.pa.yaml` | Screen1 | Att | `C:\src\aaca-attendance\app\Screen1.screen-plan.md` |
| Modify | Absences | `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml` | AbsencesScreen | Abs (new controls AbsAp) | `C:\src\aaca-attendance\app\AbsencesScreen.screen-plan.md` |

## App Changes

### Before builders

Edit `App.pa.yaml` (the orchestrator applies these and compiles App before dispatch):

1. `App.Formulas` — append after the line `CurrentSchoolYear = LookUp('School Years', 'Start Date' <= Today() && 'End Date' >= Today());`:

```
      // ---------- Parent-report approval (build 5) ----------
      ParentReportCutover = With({v: Trim(Coalesce(LookUp('App Settings', Key = "ParentReportCutoverDate").Value, ""))}, If(Len(v) = 10, IfError(Date(Value(Left(v, 4)), Value(Mid(v, 6, 2)), Value(Mid(v, 9, 2))), Date(2026, 1, 1)), Date(2026, 1, 1)));
```

2. `App.OnStart` — replace
   `Set(varAbsFrom, Coalesce(CurrentSchoolYear.'Start Date', Date(Year(Today()) - If(Month(Today()) < 7, 1, 0), 7, 1)));`
   with `Set(varAbsFrom, ParentReportCutover);`

3. `App.OnStart` — change the final line `Set(varAbsNrReceipt, {Kind: "", Title: "", Body: "", ItemId: 0})` to end with
   `;` and append exactly:

```
      Set(varAbsApLoading, false);
      Set(varAbsApLoaded, false);
      Set(varAbsApSaving, false);
      Set(varAbsApLoadError, "");
      Set(varAbsApPlanErr, "");
      Set(varAbsApSelId, 0);
      Set(varAbsApSelId, Blank());
      Set(varAbsApPlanFor, 0);
      Set(varAbsApPlanFor, Blank());
      Set(varAbsApClass, "");
      Set(varAbsApReasonId, ZeroGuid);
      Set(varAbsApReasonId, Blank());
      Set(varAbsApDismissOpen, false);
      Set(varAbsApReceipt, {Kind: "", Title: "", Body: "", ItemId: 0});
      Set(varAbsApGridLink, {StudentId: ZeroGuid, TeacherId: ZeroGuid, CampusId: ZeroGuid, FirstDay: Today()});
      ClearCollect(colAbsApPlan, {DayDate: Today(), EnrId: ZeroGuid, TermId: ZeroGuid, CampusId: ZeroGuid, ServiceId: ZeroGuid, TeacherId: ZeroGuid, TeacherName: "", Outcome: "", OutcomeText: ""});
      Clear(colAbsApPlan);
      ClearCollect(colAbsApLog, {DayDate: Today(), Outcome: "", Detail: "", AttId: ZeroGuid});
      Clear(colAbsApLog)
```

No other App changes. `CanEditRole` stays defined (StudentsScreen may use it) but Screen1 no longer uses it for the grid gate.

### After builders

None

## Editor State Changes

None
