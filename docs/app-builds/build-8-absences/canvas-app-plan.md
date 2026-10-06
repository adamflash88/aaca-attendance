# Canvas App Plan

## Mode

EDIT (build 8 - Absences simplification: Classify absences + Mapping Errors)

## Requirements

Source of truth: `C:\src\aaca-attendance\docs\app-builds\build-8-absences\canvas-app-requirements.md` (immutable).
Summary of the approved edit, AbsencesScreen only (plus App.OnStart seeds):

- Delete the "Parent reports - Needs review" and "Parent reports - Ready to approve" views, their toggles, panels,
  galleries and engines (nr load / ap load / ap plan / approve / dismiss / match). Delete, never hide. Never re-parent
  or rename a surviving control.
- View toggle = two buttons: **Classify absences** (default) and **Mapping Errors (n)**, n = List A + List B.
- Classify absences keeps the existing filter / tick / Mark Excused / Mark Unexcused flow, plus:
  - each row shows source ("Parent report #id" / "Teacher" / "Office"), "Reported <date time> (Pacific)" and the
    parent's reason (from Notes) when present; legacy rows look as today;
  - **Remove ticked (n)** (office/admin): required reason; soft delete (Is Deleted = Yes) + Audit Soft Delete per row;
  - **Needs a decision** panel at the top (only when non-empty): present rows flagged Parent Reported Absent for the
    campus/period with **Keep present** and **Mark absent**.
- Mapping Errors view: List A "No Student ID" (SharePoint items since ParentReportCutover, blank Student_ID, campus
  scoped, no Report Decisions row) and List B "Could not process" (Report Decisions, Processing Status = Error).
  Actions: **Map student** (A and B; writes Student_ID + Match_Status only), **Fix dates** (B; writes Absence Date +
  Return Date only), **Dismiss** (A creates / B updates a Report Decisions row: Dismissed, Processed, Note).
- SharePoint writes touch only Student_ID, Match_Status, Absence Date, Return Date. Every write uses IfError with a
  visible receipt and writes an Audit Events row.
- Screen must end below the App Checker complexity limit (was 328 > 300).

## Original Request Capability Inventory

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Observer(s) | Scenario(s) |
| --- | --- | --- | --- | --- | --- | --- |
| R-REMOVE-VIEWS | Remove the parent-report Needs review / Ready to approve views, toggles, panels, galleries, engines, vars | App shell and navigation | Controls deleted from AbsencesScreen.pa.yaml; NR/AP OnStart seeds deleted | A-TOGGLE-CLASSIFY | Absence of `conAbsNrView`, `conAbsApView`, `btnAbsViewNr`, `btnAbsApViewReady`, `btnAbsNrEngine`, `btnAbsApEngine`, `btnAbsApPlanEngine` | S-VIEWS-GONE |
| R-TOGGLE | Two toggle buttons: Classify absences (default) and Mapping Errors (n) | App shell and navigation | varAbsView "classify" / "errors"; count = List A + List B | A-TOGGLE-CLASSIFY, A-TOGGLE-ERRORS | `btnAbsViewClassify`, `btnAbsMeViewErrors.Text`, `conAbsClassifyView.Visible`, `conAbsMeView.Visible` | S-TOGGLE, S-ME-COUNT |
| R-CLASSIFY-KEEP | Keep the classify view and Mark Excused / Mark Unexcused flow | Workflow and review | Unchanged classify engine; colAbsList gains display fields only | A-CLASSIFY-EXCUSED, A-CLASSIFY-UNEXCUSED, A-LOAD-ABSENCES | `galAbsListV`, `conAbsReceiptV` | S-CLASSIFY-REGRESSION |
| R-ROW-SOURCE | Row shows parent's reason (Notes), "Reported <date time> (Pacific)", source; legacy rows as today | Data exploration | New row line bound to Source, Source Report ID, Notice Received On, Notes | A-LOAD-ABSENCES | `lblAbsRowSrcV.Text` | S-ROW-PARENT, S-ROW-OFFICE, S-ROW-LEGACY |
| R-REMOVE-ABSENCE | Remove absence for selected rows, office/admin, reason required, soft delete + Audit Soft Delete; 0 leaves grid | Data lifecycle | Is Deleted = Yes per ticked eligible row; audit per row; row leaves list | A-REMOVE-ABSENCE | `conAbsReceiptV` (varAbsReceipt + colAbsReceiptLines), `galAbsListV.Items`, Screen1 grid on next visit | S-REMOVE-OK, S-REMOVE-NO-REASON, S-REMOVE-LOCKED |
| R-CONFLICTS | Needs a decision section at top, only when non-empty: Present = Yes and Parent Reported Absent = Yes for campus/period; row student, date, teacher, reason / report #, reported time | Workflow and review | colAbsCf loaded with the classify filters (campus, From, To) | A-LOAD-ABSENCES | `conAbsCfPanel.Visible`, `galAbsCfList` rows | S-CF-LIST, S-CF-HIDDEN-EMPTY |
| R-KEEP-PRESENT | Keep present: clear the flag; audit Update reason "Teacher marked present" | Workflow and review | Parent Reported Absent = false; Present stays true | A-KEEP-PRESENT | `conAbsReceiptV`, `galAbsCfList` (row gone) | S-KEEP-PRESENT, S-CF-STALE |
| R-MARK-ABSENT | Mark absent: Present = false, flag cleared, Source = Office, then appears in classify list; audit Update | Workflow and review | Present false, flag false, Source Office; classify list reloaded | A-MARK-ABSENT | `conAbsReceiptV`, `galAbsListV` after reload | S-MARK-ABSENT, S-MARK-ABSENT-LOCKED |
| R-ME-LIST-A | List A: SP items on/after ParentReportCutover, blank Student_ID, School Site = user's campus (admin all + picker), no Report Decisions row; row fields | Data exploration | colAbsMe Kind "A" | A-ME-LOAD, A-ME-CAMPUS | `galAbsMeA`, `lblAbsMeAName`, `lblAbsMeAMeta` | S-ME-A-LIST, S-ME-A-SCOPE |
| R-ME-LIST-B | List B: Report Decisions with Processing Status = Error; row report #, error detail, student key, created on | Data exploration | colAbsMe Kind "B" | A-ME-LOAD | `galAbsMeB`, `lblAbsMeBName`, `lblAbsMeBMeta` | S-ME-B-LIST |
| R-ME-MAP | Map: pick campus student (search), Patch Student_ID = External Client ID, Match_Status = "Manually Resolved"; nothing else; notice about the flow | Integration and automation | Two SP columns written; audit Update | A-ME-OPEN, A-ME-MAP | `conAbsMeReceipt`, `galAbsMeA` (row gone) / `lblAbsMeBName` (pending status) | S-ME-MAP-A, S-ME-MAP-B, S-ME-MAP-NOKEY, S-ME-MAP-RACE |
| R-ME-FIXDATES | Fix dates (List B): edit Absence Date / Return Date text (M/D/YYYY), Patch only those two; notice | Integration and automation | Two SP columns written; audit Update | A-ME-OPEN, A-ME-FIXDATES | `conAbsMeReceipt`, `lblAbsMeBMeta` / facts | S-ME-DATES-OK, S-ME-DATES-INVALID |
| R-ME-DISMISS | Dismiss (both lists): reason required; create (A) / update (B) Report Decisions Decision = Dismissed, Processing Status = Processed, Note, Report Item ID, Student Key if known; audit | Workflow and review | Report Decisions row; row leaves list | A-ME-OPEN, A-ME-DISMISS | `conAbsMeReceipt`, gallery row gone | S-ME-DISMISS-A, S-ME-DISMISS-B, S-ME-DISMISS-NO-NOTE |
| R-ME-COUNT | Count in the toggle = List A + List B | Analytics and visualization | CountRows(colAbsMe) | A-ME-LOAD | `btnAbsMeViewErrors.Text` | S-ME-COUNT |
| R-ROLES | Teachers no access; Read-only view only (no action buttons) | Security, persistence, and resilience | Existing `conAbsDenied` for !CanClassify; every new action gated by CanClassify | A-TOGGLE-CLASSIFY | `conAbsDenied.Visible`, action `DisplayMode` | S-ROLE-TEACHER, S-ROLE-READONLY |
| R-WRITES | All writes: IfError with visible notice; Audit Events row per change; finance-owned SP columns never written | Security, persistence, and resilience | Every Patch wrapped; receipts report audit outcome | A-REMOVE-ABSENCE, A-KEEP-PRESENT, A-MARK-ABSENT, A-ME-MAP, A-ME-FIXDATES, A-ME-DISMISS | receipt "Audit event" lines | S-REMOVE-OK, S-ME-MAP-A, S-ME-DATES-OK |

## Requirement Coverage

| Requirement | Planned affordance | Fidelity |
| --- | --- | --- |
| Remove parent-report views | Delete `btnAbsViewNr`, `btnAbsApViewReady`, `conAbsNrView`, `conAbsApView` (with all descendants), `btnAbsNrEngine`, `btnAbsApEngine`, `btnAbsApPlanEngine`; OnVisible no longer selects them; App.OnStart NR/AP seeds deleted after builders | Exact |
| Classify absences toggle (default) | Existing `btnAbsViewClassify` (breakpoint 640) | Exact |
| Mapping Errors (n) toggle | NEW `btnAbsMeViewErrors` "Mapping Errors (n)" | Exact |
| Parent reason / Reported time / source on each row | NEW `lblAbsRowSrcV` in each classify row | Exact; "(Pacific)" = the device's local time, which is Pacific for AACA staff (Approximation: no explicit time-zone conversion) |
| Remove absence for selected rows with required reason | NEW `conAbsRmRowV`: `txtAbsRmReason` + `btnAbsRmRemove` "Remove ticked (n)" acting on the ticked rows | Exact |
| Needs a decision at the top, only when non-empty | NEW `conAbsCfPanel` above the list body, `galAbsCfList` rows with `btnAbsCfKeep` "Keep present" and `btnAbsCfAbsent` "Mark absent" | Exact |
| List A "No Student ID" / List B "Could not process" | NEW `galAbsMeA`, `galAbsMeB` under headings `lblAbsMeAHead`, `lblAbsMeBHead` | Exact |
| Campus scoping (office own campus; admin all + picker) | NEW `ddAbsMeCampus` ("All campuses" + campuses; disabled and fixed for office) | Approximation: the classify view's picker is not visible in this view and has no "all" option, so the Mapping Errors view has its own picker of the same pattern |
| Map (search box student picker) | `btnAbsMeModeMap` -> `cboAbsMeStudent` (searchable combobox, NEW names) -> `btnAbsMeMapSave` | Exact |
| Fix dates | `btnAbsMeModeDates` (List B rows only) -> `txtAbsMeAbsDate`, `txtAbsMeRetDate` -> `btnAbsMeDatesSave` | Exact; shown on every List B row because the flow's Error Detail categories are free text |
| Map on List B "unknown student" | Map is offered on every List B row | Approximation: same reason (no machine-readable error category) |
| Dismiss with reason | `btnAbsMeModeDismiss` -> `txtAbsMeDismissNote` -> `btnAbsMeDismissSave` "Confirm dismiss" | Exact |
| "The intake flow picks the change up" notice | `lblAbsMeReceiptBody` "Next: the intake flow picks this up within a few minutes..." | Exact |
| Read-only: view only | Read-only keeps the existing denied panel (no nav to this screen exists for Read-only); every action is also gated by `CanClassify` | Approximation: granting Read-only a view needs nav changes on Screen1/StudentsScreen (out of scope); see open risk |

## Required Record Fields

| Field key | Screen | Record surface | Required field | Source field | Presentation requirement |
| --- | --- | --- | --- | --- | --- |
| cls-row-identity (existing) | AbsencesScreen | galAbsListV row | Student name + number, badge | StudentName, StudentNumber, ClassText | unchanged `lblAbsRowNameV`, `badgeAbsRowStatusV` |
| cls-row-date (existing) | AbsencesScreen | galAbsListV row | date, teacher, campus | AbsDate, TeacherName, CampusName | unchanged `lblAbsRowMetaV` |
| cls-row-source | AbsencesScreen | galAbsListV row | source, reported time (Pacific), parent reason | SrcText, NoticeOn, ParentReason | NEW `lblAbsRowSrcV`, one combined wrapping line, hidden when all three are empty |
| cf-row-student | AbsencesScreen | galAbsCfList row | student | StudentName, StudentNumber | `lblAbsCfRowName`, semibold 14 |
| cf-row-facts | AbsencesScreen | galAbsCfList row | date, teacher, report #, reported time, parent reason | AbsDate, TeacherName, ReportId, NoticeOn, colAbsCfRpt.Reason | `lblAbsCfRowMeta`, one combined wrapping line |
| me-a-identity | AbsencesScreen | galAbsMeA row | report #, typed first/last name | ItemId, FirstName, LastName | `lblAbsMeAName` |
| me-a-facts | AbsencesScreen | galAbsMeA row | school site, absence/return date text, reason, submitted by, date notified | SchoolSite, AbsText, RetText, Reason, SubmittedBy, Notified | `lblAbsMeAMeta` |
| me-b-identity | AbsencesScreen | galAbsMeB row | report #, student key, pending status | ItemId, StudentKey, Status | `lblAbsMeBName` |
| me-b-facts | AbsencesScreen | galAbsMeB row | error detail, created on | ErrorDetail, DecCreated | `lblAbsMeBMeta` |
| me-detail-facts | AbsencesScreen | conAbsMeDetail | all report facts | colAbsMe row | `lblAbsMeFacts`, labelled lines |

## State-Driven Surface Visibility

| Surface key | Owner screen | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- | --- |
| abs-classify-view | AbsencesScreen | conAbsClassifyView | `=varAbsView = "classify"` (unchanged) | Visible on Classify absences; hidden on Mapping Errors |
| abs-errors-view | AbsencesScreen | conAbsMeView | `=CanClassify && varAbsView = "errors"` | Visible after Mapping Errors toggle; hidden otherwise and for !CanClassify |
| abs-conflicts | AbsencesScreen | conAbsCfPanel | `=CanClassify && CountRows(colAbsCf) > 0` | Visible when conflicts exist in campus/period; hidden when none |
| abs-me-receipt | AbsencesScreen | conAbsMeReceipt | `=varAbsMeReceipt.Kind <> ""` | Visible after any Map / Fix dates / Dismiss attempt until Close |
| abs-me-map | AbsencesScreen | conAbsMeMapPanel | `=!IsBlank(varAbsMeSelId) && varAbsMeMode = "map"` | After Map student; hidden otherwise |
| abs-me-dates | AbsencesScreen | conAbsMeDatesPanel | `=!IsBlank(varAbsMeSelId) && varAbsMeMode = "dates" && LookUp(colAbsMe, ItemId = varAbsMeSelId).Kind = "B"` | After Fix dates on a List B report |
| abs-me-dismiss | AbsencesScreen | conAbsMeDismissPanel | `=!IsBlank(varAbsMeSelId) && varAbsMeMode = "dismiss"` | After Dismiss |

## Action Contracts

| Requested action | Preconditions | Entry point | Owner screen | Control and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-TOGGLE-CLASSIFY | CanClassify | Classify absences | AbsencesScreen | `btnAbsViewClassify.OnSelect` (unchanged) | N/A | varAbsView = "classify" | N/A | N/A | `conAbsClassifyView.Visible` |
| A-TOGGLE-ERRORS | CanClassify | Mapping Errors (n) | AbsencesScreen | `btnAbsMeViewErrors.OnSelect` | N/A | varAbsView = "errors"; loads if not loaded | N/A | N/A | `conAbsMeView.Visible`; count in toggle text |
| A-LOAD-ABSENCES (changed) | CanClassify, campus, From <= To | OnVisible, filters, Reload | AbsencesScreen | `btnAbsLoadEngine.OnSelect` | Attendance.Attendance | colAbsList (+SrcText, ParentReason, NoticeOn), colAbsCf, colAbsCfRpt | N/A | N/A | `galAbsListV`, `lblAbsRowSrcV`, `galAbsCfList` |
| A-CLASSIFY-EXCUSED / -UNEXCUSED (regression) | unchanged | unchanged | AbsencesScreen | `btnAbsClassifyEngine` (unchanged) | unchanged | unchanged | unchanged | unchanged | unchanged |
| A-REMOVE-ABSENCE | CanClassify; >= 1 ticked visible unlocked row; reason non-blank; not saving/loading | `txtAbsRmReason` + `btnAbsRmRemove` "Remove ticked (n)" | AbsencesScreen | `btnAbsRmRemove.OnSelect` (direct action) | Attendance.Attendance per ticked AttId | Live row still an active absence, month unlocked, Modified On unchanged -> Patch Is Deleted = true; Audit Soft Delete; row removed from colAbsList and colAbsTicked | Attendance: Is Deleted. Audit Events row (Summary, Action Soft Delete, Entity, Entity ID, Before, After, Reason) | Title counts + reason; per row label student · date, value "Is Deleted = Yes · was <class> · audit Soft Delete written" (from `wr.'Is Deleted'`) | `conAbsReceiptV` (`lblAbsReceiptTitleV`, `galAbsReceiptV`); `galAbsListV` row gone; Screen1 cell blank on next visit |
| A-KEEP-PRESENT | CanClassify; conflict row; not saving/loading | `btnAbsCfKeep` "Keep present" on the row | AbsencesScreen | `btnAbsCfKeep.OnSelect` (direct) | Attendance.Attendance = ThisItem.AttId | Live row Present true, flag true, not deleted -> Patch flag false; audit Update reason "Teacher marked present"; row leaves colAbsCf | Attendance: Parent Reported Absent. Audit row | Student, Date, Teacher, Parent report, Present (w.Present), Parent Reported Absent (w.'Parent Reported Absent'), Audit | `conAbsReceiptV`; `galAbsCfList` row gone |
| A-MARK-ABSENT | CanClassify; conflict row; month unlocked; not saving/loading | `btnAbsCfAbsent` "Mark absent" on the same row | AbsencesScreen | `btnAbsCfAbsent.OnSelect` (direct) | Attendance.Attendance = ThisItem.AttId | Live row checks + live month-lock check -> Patch Present false, flag false, Source Office; audit Update; reload list | Attendance: Present, Parent Reported Absent, Source. Audit row | Student, Date, Teacher, Parent report, Present (w.Present), Parent Reported Absent, Source (Text(w.Source)), Classification "Not classified", Audit | `conAbsReceiptV`; `galAbsCfList` row gone; `galAbsListV` (Not classified) shows the row after `Select(btnAbsLoadEngine)` |
| A-ME-LOAD | CanClassify | OnVisible, toggle (first time), Reload, campus change | AbsencesScreen | `btnAbsMeEngine.OnSelect` | SP item ID (`ItemId`) | colAbsMe = in-scope List A + List B rows | N/A | N/A | `galAbsMeA`, `galAbsMeB`, `lblAbsMeCount`, toggle count |
| A-ME-CAMPUS | Admin (StudentCampusLock = ZeroGuid) | `ddAbsMeCampus` | AbsencesScreen | `ddAbsMeCampus.OnChange` | Campuses.Campus | varAbsMeCampusId; reload | N/A | N/A | `lblAbsMeCount` scope text; lists |
| A-ME-OPEN / A-ME-CLOSE | Row present | `btnAbsMeAOpen` / `btnAbsMeBOpen`; `btnAbsMeClose` | AbsencesScreen | OnSelect | ItemId | varAbsMeSelId set / blank; mode set / blank; inputs reset | N/A | N/A | `lblAbsMeFacts`; selected row fill |
| A-ME-MAP | Selected row; mode "map"; exactly one student with a Student Key; not saving | `btnAbsMeModeMap` -> `cboAbsMeStudent` -> `btnAbsMeMapSave` | AbsencesScreen | `btnAbsMeMapSave.OnSelect` | SP item ID `qid` | Guards (A: SP Student_ID still blank and no decision row; B: decision still Error) -> Patch SP {Student_ID, Match_Status}; audit Update; A row removed / B row Status pending | SharePoint: Student_ID, Match_Status. Audit row | Report #, list, typed name/site, student picked, Student_ID (w), Match_Status (w), "Other SharePoint columns: not written", audit, flow notice | `conAbsMeReceipt` (`lblAbsMeReceiptTitle`, `lblAbsMeReceiptBody`); `galAbsMeA` row gone or `lblAbsMeBName` "Mapped to ..." |
| A-ME-FIXDATES | Selected List B row; mode "dates"; valid dates; not saving | `btnAbsMeModeDates` -> `txtAbsMeAbsDate`, `txtAbsMeRetDate` -> `btnAbsMeDatesSave` | AbsencesScreen | `btnAbsMeDatesSave.OnSelect` | SP item ID `qid` | Patch SP {'Absence Date', 'Return Date'} normalized M/D/YYYY; audit Update; B row Status pending, dates updated | SharePoint: Absence Date, Return Date. Audit row | Report #, Absence Date before -> after (w), Return Date before -> after (w), other columns not written, audit, flow notice | `conAbsMeReceipt`; `lblAbsMeBName` status; `lblAbsMeFacts` dates |
| A-ME-DISMISS | Selected row; mode "dismiss"; reason non-blank; not saving | `btnAbsMeModeDismiss` -> `txtAbsMeDismissNote` -> `btnAbsMeDismissSave` | AbsencesScreen | `btnAbsMeDismissSave.OnSelect` | Report Item ID = SP item ID `qid` | A: guard no decision row -> create Report Decisions; B: update existing row. Decision Dismissed, Processing Status Processed, Note; audit Create (A) / Update (B); row leaves colAbsMe | Report Decisions: (A) Summary, Report Item ID, Decision, Processing Status, Note, Campus; (B) Decision, Processing Status, Note. Audit row | Report #, list, typed name, Decision (dec), Processing Status (dec), Note (dec), row created/updated, "Attendance and SharePoint: not changed", audit | `conAbsMeReceipt`; row gone from `galAbsMeA`/`galAbsMeB`; toggle count |

Opposing pair note: Keep present / Mark absent are independent direct actions on the same eligible row (each owns
its mutation, gates and receipt); no shared operation state. Not arithmetic, so no Directional or Compound tables.

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-REMOVE-ABSENCE | per-row `wr` (Patch result) -> colAbsLog -> colAbsReceiptLines -> `galAbsReceiptV`; title -> `lblAbsReceiptTitleV` | Attendance Is Deleted (`wr.'Is Deleted'`) | Classify list `galAbsListV`; Screen1 grid | AttId (ticked) = live.Attendance = wr.Attendance = audit Entity ID | `RemoveIf(colAbsList, AttId in removed)`; Screen1 reloads on visit | N/A - row leaves the list |
| A-KEEP-PRESENT | `w` -> varAbsReceipt + colAbsReceiptLines | Attendance 'Parent Reported Absent' (`w`) | Needs a decision list `galAbsCfList` | ThisItem.AttId = w.Attendance | `RemoveIf(colAbsCf, AttId = qid)` on success only | N/A - row leaves the list |
| A-MARK-ABSENT | `w` -> receipt | Attendance Present / flag / Source (`w`) | `galAbsListV` (Not classified) | same AttId | `Select(btnAbsLoadEngine)` after success (reloads colAbsList and colAbsCf) | N/A - receipt names the row; list sorted by date |
| A-ME-MAP | `w` (SP Patch result) -> varAbsMeReceipt | SharePoint item Student_ID / Match_Status | List A / List B | qid = w.ID = audit Entity ID | A: `RemoveIf(colAbsMe, ItemId = qid)`; B: `Patch(colAbsMe, it, {StudentKey, Status})` | N/A |
| A-ME-FIXDATES | `w` -> varAbsMeReceipt | SharePoint item Absence Date / Return Date | List B row | qid = w.ID | `Patch(colAbsMe, it, {AbsText, RetText, Status})` | N/A |
| A-ME-DISMISS | `dec` (Report Decisions Patch result) -> varAbsMeReceipt | Report Decisions row (`dec`) | List A / List B, toggle count | qid = dec.'Report Item ID' | `RemoveIf(colAbsMe, ItemId = qid)` | N/A - row leaves the list |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| A-REMOVE-ABSENCE | Is Deleted | Changed | live row (false) | `Patch(Attendance, live, {'Is Deleted': true})` | line value "Is Deleted = Yes" from `wr.'Is Deleted'` | row absent from colAbsList; Screen1 cell blank |
| A-REMOVE-ABSENCE | Present, Classification, Reason, Source, Notes, snapshots | Preserved | live row | omitted from partial Patch | Audit Before JSON | N/A |
| A-REMOVE-ABSENCE | Audit Events row | Changed | why (txtAbsRmReason) | Patch Defaults('Audit Events') Action Soft Delete, Reason why | line "audit Soft Delete written" / "NOT written"; Reason line | Audit Events |
| A-KEEP-PRESENT | Parent Reported Absent | Changed | true | `{'Parent Reported Absent': false}` | "Parent Reported Absent: No (cleared)" from `w` | row gone from colAbsCf |
| A-KEEP-PRESENT | Present, Source, Source Report ID, Notice Received On | Preserved | live row | omitted | "Present: Yes (1, unchanged)" from `w.Present` | Screen1 cell "1" |
| A-MARK-ABSENT | Present | Changed | true | `Present: false` | "Present: No (0)" from `w.Present` | classify list row |
| A-MARK-ABSENT | Parent Reported Absent | Changed | true | `false` | from `w.'Parent Reported Absent'` | row gone from colAbsCf |
| A-MARK-ABSENT | Source | Changed | Teacher / blank | `Source: 'Source (Attendance)'.Office` | "Source: " & Text(w.Source) | `lblAbsRowSrcV` "Office (parent report #id)" |
| A-MARK-ABSENT | Absence Classification, Source Report ID, Notice Received On, Notes | Preserved | live row | omitted | Classification "Not classified" line | `lblAbsRowSrcV` reported time |
| A-ME-MAP | Student_ID | Changed | blank / old | `Student_ID: key` (External Client ID) | "Student_ID: " & w.Student_ID | facts / B row name |
| A-ME-MAP | Match_Status | Changed | any | `{Value: "Manually Resolved"}` | "Match_Status: " & w.Match_Status.Value | SharePoint |
| A-ME-MAP | every other SP column (incl. Matched_Student and finance-owned) | Preserved | SP item | omitted from Patch | "Other SharePoint columns: not written" | SharePoint |
| A-ME-FIXDATES | Absence Date / Return Date | Changed | txtAbsMeAbsDate / txtAbsMeRetDate (validated, normalized `Text(d, "m/d/yyyy")`) | Patch two columns | before -> after lines from `live` and `w` | facts / B row |
| A-ME-FIXDATES | every other SP column | Preserved | SP item | omitted | "Other SharePoint columns: not written" | SharePoint |
| A-ME-DISMISS | Decision | Changed | - / prior | `'Decision (Report Decisions)'.Dismissed` | "Decision: " & Text(dec.Decision) | row gone |
| A-ME-DISMISS | Processing Status | Changed | - / Error | `'Processing Status (Report Decisions)'.Processed` | "Processing Status: " & Text(dec.'Processing Status') | row gone from List B |
| A-ME-DISMISS | Note | Changed | txtAbsMeDismissNote | `Note: why` | "Note: " & dec.Note | Report Decisions |
| A-ME-DISMISS | Report Item ID, Summary, Campus (A only) | Changed (A create) | qid, it.CampusId | Patch Defaults | "Report: #" & dec.'Report Item ID' | List A excludes qid on reload |
| A-ME-DISMISS | Student Key, Error Detail, counts (B) | Preserved | prior row | omitted | N/A | Report Decisions |

## Functional Test Matrix

Fixtures (Dev): campus CW = Chatsworth; office O (Attendance Office, CW); admin M (System Admin, no campus); teacher A
"Smith, Ana" (CW); student "Doe, Jane" STU-000123, External Client ID CW-1001, enrolled with A; student "Roe, Max"
STU-000200 with no External Client ID; reasons Illness, Other; September 2026 unlocked, August 2026 locked at CW.
ParentReportCutover = 2026-01-01.

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-VIEWS-GONE | Built screen | Open Absences as O | Only two toggles; no Needs review / Ready to approve UI | `conAbsViewBar` shows Classify absences + Mapping Errors (n) | Session where varAbsView was "nr"/"ready": OnVisible resets to "classify" |
| S-TOGGLE | O on Absences | Press Mapping Errors, then Classify absences | Views swap | `conAbsMeView.Visible` / `conAbsClassifyView.Visible`; active toggle teal | N/A |
| S-ROW-PARENT | Att row Jane 9/14/2026 Present No, Source 'Parent report', Source Report ID 515, Notice Received On 2026-09-13 22:56 local, Notes "Parent report #515: Flu" | Load classify (Not classified, CW, 1/1-today) | Row line | `lblAbsRowSrcV` "Parent report #515 · Reported Sep 13, 2026 10:56 PM (Pacific) · Reason: Flu" | Notes without ": " -> whole Notes shown as reason |
| S-ROW-OFFICE | Row Source Office, Source Report ID 600, Notes blank | Load | Row line | "Office (parent report #600) · Reported ..." | N/A |
| S-ROW-LEGACY | Imported 0 row, Source blank, no report ID, no notice | Load | Row as today | `lblAbsRowSrcV.Visible` false | Teacher row with Source Teacher -> "Teacher" |
| S-REMOVE-OK | Jane 9/14 and 9/15 active 0 (unlocked), ticked | Type "Child came to school" -> Remove ticked (2) | Both rows Is Deleted = Yes; 2 Audit Soft Delete rows (Reason = typed text) | Receipt title "2 absence(s) removed (Is Deleted = Yes), 0 failed · reason: Child came to school"; lines "Doe, Jane · Sep 14 - Is Deleted = Yes · was Not classified · audit Soft Delete written"; rows gone; Screen1 cells blank | Row changed by someone else (Modified On differs) -> "Skipped · changed" |
| S-REMOVE-NO-REASON | 1 ticked, reason blank | Look at button | Disabled | `btnAbsRmRemove.DisplayMode` Disabled; label "Reason to remove ticked absences *" | 0 ticked -> disabled, text "Remove ticked (0)" |
| S-REMOVE-LOCKED | Ticked row in locked Aug 2026 | Select all shown | Locked rows never ticked; if lock appears after load -> "Skipped · locked" | receipt line | N/A |
| S-CF-LIST | Jane 9/16 Present Yes, Parent Reported Absent Yes, Source Report ID 516, Notice 2026-09-15 07:10; SP #516 Reason "Dentist" | Load classify CW Sep | Needs a decision (1) above the list | `lblAbsCfRowName` "Doe, Jane · STU-000123"; `lblAbsCfRowMeta` "Wed Sep 16, 2026 · Teacher Smith, Ana · Parent report #516 · Reported Sep 15, 2026 7:10 AM (Pacific) · Reason: Dentist" | Conflict outside From/To or other campus not listed |
| S-CF-HIDDEN-EMPTY | No flagged present rows in scope | Load | Panel hidden | `conAbsCfPanel.Visible` false | N/A |
| S-KEEP-PRESENT | S-CF-LIST row | Keep present | Flag false, Present true; Audit Update reason "Teacher marked present" | Receipt "Kept present · Doe, Jane · Wed Sep 16, 2026 · flag cleared"; lines Present "Yes (1, unchanged)", Parent Reported Absent "No (cleared)", Audit "Update written"; row gone | N/A |
| S-MARK-ABSENT | S-CF-LIST row | Mark absent | Present false, flag false, Source Office; Audit Update | Receipt "Marked absent · Doe, Jane · Wed Sep 16, 2026"; lines Present "No (0)", Source "Office", Classification "Not classified (classify it in the list below)"; after reload the row is in `galAbsListV` with `lblAbsRowSrcV` "Office (parent report #516) · Reported ..." | N/A |
| S-MARK-ABSENT-LOCKED | Conflict row in locked month | Look at Mark absent | Disabled; meta ends "Month locked" | `btnAbsCfAbsent.DisplayMode` | Lock added after load -> Blocked receipt "month is locked", no write |
| S-CF-STALE | Teacher cleared the 1 after load | Keep present | No write | Blocked receipt "this day changed since the list loaded"; row removed | N/A |
| S-ME-A-LIST | SP #700 Created 2026-09-20, Student_ID blank, School Site Chatsworth, no decision; #701 same but Oxnard; #702 Created 2025-12-01 blank; #703 Student_ID CW-1001 | O opens Mapping Errors | List A = #700 only | `galAbsMeA` row "#700 · Lee, Sam (as typed)"; meta "Chatsworth · absent 9/21/2026 · back 9/22/2026 · Reason ... · submitted by ... · notified ..." | #700 with a Report Decisions row -> excluded |
| S-ME-A-SCOPE | Same data | Admin M opens view; then picks Oxnard | All campuses: #700 and #701; Oxnard: #701 only | `lblAbsMeCount` "... · all campuses" / "... · Oxnard" | O: picker disabled showing Chatsworth |
| S-ME-B-LIST | Report Decisions #710 Processing Status Error, Error Detail "Student key CW-9999 not found", Student Key CW-9999 | Open view | List B shows #710 | `lblAbsMeBName` "#710 · Student key CW-9999"; `lblAbsMeBMeta` "Error: Student key CW-9999 not found · created ..." | Processed rows not listed |
| S-ME-COUNT | 1 in A, 1 in B | Look at toggle | "Mapping Errors (2)" | `btnAbsMeViewErrors.Text` | Before load "(…)" |
| S-ME-MAP-A | #700 open, Map student, pick Doe, Jane (CW-1001) | Save mapping | SP #700 Student_ID CW-1001, Match_Status Manually Resolved; nothing else; Audit Update | Receipt "Report #700 mapped · Student_ID CW-1001 · Doe, Jane"; body Student_ID / Match_Status from `w`, "Other SharePoint columns: not written", "Next: the intake flow picks this up..."; #700 gone from List A | N/A |
| S-ME-MAP-B | #710 open | Map to Doe, Jane | SP #710 Student_ID CW-1001, Match_Status Manually Resolved | Receipt as above; `lblAbsMeBName` "#710 · Student key CW-1001 · Mapped to CW-1001, waiting for the intake flow" | N/A |
| S-ME-MAP-NOKEY | #700 open | Pick Roe, Max (no key) | Save disabled | `lblAbsMeMapCheck` "Roe, Max has no Student Key..."; `btnAbsMeMapSave` Disabled | No pick -> disabled, "Pick the student..." |
| S-ME-MAP-RACE | #700 open; someone set Student_ID meanwhile | Save mapping | No write | Blocked receipt "Not saved · report #700 was already handled" | B row whose decision became Processed -> Blocked |
| S-ME-DATES-OK | #711 Error "dates cannot be read", SP Absence Date "9/31/2026" | Fix dates: Absence "9/30/2026", Return "10/2/2026" | SP Absence Date "9/30/2026", Return Date "10/2/2026"; Audit Update | Receipt "Report #711 dates saved · 9/30/2026 to 10/2/2026"; body "Absence Date: 9/31/2026 -> 9/30/2026" | N/A |
| S-ME-DATES-INVALID | #711 open | Absence "13/1/2026" or Return before Absence or > 180 days | Save disabled | `lblAbsMeDatesCheck` explains; `btnAbsMeDatesSave` Disabled | Blank Return accepted (one day) |
| S-ME-DISMISS-A | #700 open | Dismiss -> "Duplicate of #699" -> Confirm dismiss | New Report Decisions: Report Item ID 700, Decision Dismissed, Processing Status Processed, Note; Audit Create | Receipt "Dismissed · report #700"; Decision / Processing Status / Note from `dec`; row gone; count -1 | #700 got a decision meanwhile -> Blocked, row removed |
| S-ME-DISMISS-B | #710 open | Dismiss -> "Not our student" | #710 row updated: Decision Dismissed, Processing Status Processed, Note; Audit Update | Receipt "Report Decisions row: updated"; row gone from List B | N/A |
| S-ME-DISMISS-NO-NOTE | Dismiss panel open, note blank | Look at Confirm dismiss | Disabled | `btnAbsMeDismissSave.DisplayMode` | N/A |
| S-ROLE-TEACHER | Teacher A | Navigate to Absences directly | Denied panel only | `conAbsDenied` visible; no view bar | N/A |
| S-ROLE-READONLY | Read-only user | Open Absences | Denied panel; no action buttons anywhere | `conAbsDenied` | See open risk (view-only access) |
| S-CLASSIFY-REGRESSION | Jane 9/14 unclassified | Excused… -> Illness -> Save as Excused; Unexcused on another row | Unchanged build-3/5 behaviour | `conAbsReceiptV` | N/A |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| txtAbsRmReason | lblAbsRmReason `="Reason to remove ticked absences *"` | conAbsRmField |
| ddAbsMeCampus | lblAbsMeCampus `="Campus"` | conAbsMeCampusField |
| cboAbsMeStudent | lblAbsMeStudent `="Student *"` | conAbsMeMapField |
| txtAbsMeAbsDate | lblAbsMeAbsDate `="Absence Date * (M/D/YYYY)"` | conAbsMeAbsField |
| txtAbsMeRetDate | lblAbsMeRetDate `="Return Date (M/D/YYYY, blank = one day)"` | conAbsMeRetField |
| txtAbsMeDismissNote | lblAbsMeDismissNote `="Why dismiss? *"` | conAbsMeDismissField |

## Layout Budget Contracts

| Screen / container | Branch / screen-width source | Horizontal total-width arithmetic | Vertical height arithmetic | Protected controls |
| --- | --- | --- | --- | --- |
| conAbsViewBar | conAbsRoot.Width >= 640 horizontal | 16+170+8+220+16 = 430 <= 640 | 44 | both toggles |
| conAbsViewBar | < 640 vertical | buttons Parent.Width - 32 | 44+8+44 = 96 | same |
| galAbsListV row | < 640 / >= 640 | unchanged | desktop 8+44+4+18+4+36+4+44+8 = 170 = TemplateSize 170; phone 8+44+4+36+4+72+4+88+8 = 268 = 268 | row actions |
| conAbsRmRowV | >= 640 horizontal / < 640 vertical | field min 140 + 8 + 200 = 348 <= 576 (narrowest horizontal: 640-32-32) | 58 / 58+8+44 = 110 | Remove ticked |
| conAbsListPanelV | both | N/A | adds 8 + (58 / 110) to the existing formula | list |
| conAbsCfPanel | <640 / <1024 / desktop | actions 130+8+130 = 268 <= 334 (390-24-16-16) | 12 + title(44/44/24) + 8 + hint(54/36/18) + 8 + gallery + 12 | Keep present, Mark absent |
| galAbsCfList row | <640 / >= 640 | name FillPortions; actions 268 | phone 8+40+4+72+4+44+8 = 180 <= 184; desktop 8+22+4+36+4+44+8 = 126 <= 130 | both actions |
| galAbsMeA / galAbsMeB row | <640 / >= 640 | name FillPortions + Open 90 + gap 8 | phone 8+44+4+90+8 = 154 <= 158; desktop 8+44+4+72+8 = 136 <= 140 | Open |
| conAbsMeModeBar | >= 640 / < 640 (LayoutWrap) | 130+8+110+8+100+8+90 = 454 <= 472 (1024 two-panel detail inner) | 44 / 96 (two rows at 358) | Map, Fix dates, Dismiss, Close |
| conAbsMeDatesRow | >= 640 / < 640 | 140+8+140 = 288 <= 358 | 58 / 58+8+58 = 124 | both date inputs |
| conAbsMeMapPanel | both | N/A | 58+8+(54/72)+8+44 = 172 / 190 | Save mapping |
| conAbsMeDatesPanel | both | N/A | (58/124)+8+(54/72)+8+44 = 172 / 256 | Save dates |
| conAbsMeDismissPanel | both | N/A | 94+8+44 = 146 | Confirm dismiss |
| conAbsMeReceipt | both | title FillPortions + Close 88 | 8+(44/84)+[4+(190/300)]+8 | full receipt body (10 lines) |

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| --- | --- | --- | --- | --- | --- |
| AbsencesScreen | conAbsRoot (sole top-level child; existing) | AutoLayout | `conAbsRoot.Width: =Parent.Width` | `conAbsRoot.Height: =Parent.Height` | LayoutOverflowY Scroll (add LayoutMinWidth/Height 0) |

## Working Directory

C:\src\aaca-attendance\app

Plan artifacts: C:\src\aaca-attendance\docs\app-builds\build-8-absences\

## Discovery Summary

- Existing screens: Screen1 (Att, untouched), StudentsScreen (Stu, untouched), AbsencesScreen (Abs, rebuilt here).
- Layout: AutoLayout; scroll root `conAbsRoot`.
- Data sources used: Attendance (new: Source / 'Source (Attendance)', 'Notice Received On', 'Parent Reported Absent'),
  Report Decisions (new: 'Processing Status' / 'Processing Status (Report Decisions)', 'Error Detail'), Student Absence
  Log (SharePoint), Students, Enrollments, Campuses, Month Locks, Absence Reasons, Staff, Audit Events.
- Controls: GroupContainer, Gallery, ModernText, ModernButton, Classic/Button, ModernDropdown, ModernTextInput,
  ModernCombobox, ModernCheckbox, ModernRadio, ModernDatePicker, ModernSpinner, Badge - all already in this screen and
  described in the discovery packet. No new control types.

## Dispatch

| Action | Screen | Target File | YAML Key | Name Prefix | Screen Brief |
| --- | --- | --- | --- | --- | --- |
| Modify | Absences | `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml` | AbsencesScreen | Abs (new controls: AbsCf, AbsRm, AbsMe, plus `lblAbsRowSrcV`) | `C:\src\aaca-attendance\docs\app-builds\build-8-absences\AbsencesScreen.screen-plan.md` |

## App Changes

### Before builders

`App.pa.yaml` `OnStart`: change the final line `Clear(colAbsApLog)` to `Clear(colAbsApLog);` and append exactly
(indent 6 spaces like the surrounding lines):

```
      Set(varAbsMeLoading, false);
      Set(varAbsMeLoaded, false);
      Set(varAbsMeSaving, false);
      Set(varAbsMeLoadError, "");
      Set(varAbsMeErr, "");
      Set(varAbsMeCampusId, ZeroGuid);
      Set(varAbsMeSelId, 0);
      Set(varAbsMeSelId, Blank());
      Set(varAbsMeMode, "");
      Set(varAbsMeReceipt, {Kind: "", Title: "", Body: ""})
```

No Formulas changes (`ParentReportCutover`, `CanClassify`, `StudentCampusLock`, `CurrentUserRow`, `ZeroGuid` stay).

### After builders

After AbsencesScreen compiles clean, delete from `App.OnStart` the 32 lines from `Set(varAbsNrLoading, false);` through
`Clear(colAbsApLog);` inclusive (all `varAbsNr*`, `varAbsAp*`, `colAbsApPlan`, `colAbsApLog` seeds). Keep
`Set(varAbsView, "classify");` and the build-8 `varAbsMe*` seeds; the last statement stays
`Set(varAbsMeReceipt, {Kind: "", Title: "", Body: ""})` with no trailing `;`. Recompile App: if Screen1 or
StudentsScreen reports `Name isn't recognized` for one of the removed variables, restore just that seed (none expected;
Show-on-grid only wrote Screen1 globals `varCampus`/`varTeacher`/`varMonthStart`/`varViewDate`/`varLastAction`,
which stay).

Optional cosmetic: rename the Formulas comment `// ---------- Parent-report approval (build 5) ----------` to
`// ---------- Parent reports (build 5/8) ----------`.

## Editor State Changes

None
