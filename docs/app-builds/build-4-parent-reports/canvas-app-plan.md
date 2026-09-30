# Canvas App Plan

## Mode

EDIT (build 4: parent-report matching + Student Key rule)

## Requirements

Source of truth: `C:\src\aaca-attendance\app\canvas-app-requirements.md` (immutable; approved 2026-09-30).
Summary:

- Absences screen gets an in-screen view toggle "Classify absences | Parent reports – Needs review (N)". The
  existing classify view is wrapped by the toggle with no formula changes.
- Parent reports view: queue of SharePoint `Student Absence Log` items whose `Match_Status.Value = "Needs Review"`,
  newest first. Selecting a report shows what the parent submitted (first and last name, school site, dates,
  reason, submitted by, date notified, title) plus computed "Days of absence" (school days only).
- The student picker is a searchable, single-select ModernCombobox over Dataverse Students (every status,
  including Archived). It shows "Last, First · <campus code> · <Student Key> · <status>". It filters to the
  report's campus (`SchoolSite` = `Campuses.Name` -> `Campuses.Code`) unless "Search all campuses" is ticked.
  The picker resets when you switch reports.
- The **Resolve Match** button stays disabled until a student is picked. When clicked, it re-reads the item.
  If the item still has Needs Review status and a `Student Directory` item has that Student_ID, one Patch writes
  `Matched_Student {Id, Value}`, `Student_ID` and `Match_Status {Value: "Manually Resolved"}`. It then writes an
  Audit Events row, shows a receipt and removes the item from the queue. If the Patch fails, the screen shows
  an error and keeps the selection. No other columns are written.
- Students screen, Add student: Student Key (`External Client ID`) is required. It is pre-filled with the
  campus code, a dash and (highest numeric key suffix + 1). The user can edit it. It must match
  `^[A-Z]{2,3}-\d+$` and be unique. In Edit, the key is read-only with the note "Student Key can't be changed".
- Access: Office and Admin only (`CanClassify`).

## Original Request Capability Inventory

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Observer(s) | Scenario(s) |
| --------------- | ----------------------- | ----------------- | ------------------------ | ------------------ | ----------- | ----------- |
| R-TOGGLE | Toggle inside Absences between Classify and Parent reports – Needs review (N) | App shell and navigation | Two in-screen view buttons; N = queue count; classify view unchanged | A-SWITCH-ABS-VIEW | `btnAbsViewNr.Text` (count from `colAbsNr`), `conAbsClassifyView.Visible`, `conAbsNrView.Visible` | S-TOGGLE |
| R-NR-QUEUE | Show Absence Log records with Match_Status = Needs Review | Data exploration | Delegable filter, newest first (Created desc); first/last, SchoolSite, AbsenceDate, ReturnDate, Reason, Submitted By, Date Notified, Title; zero state | A-LOAD-NR | `galAbsNrList` rows, `lblAbsNrCount` | S-NR-LIST, S-NR-EMPTY |
| R-NR-DETAIL | Selecting a record shows its submitted names, campus, dates (+ computed days) | Time and scheduling | Detail for `varAbsNrSelId`; school days from campus Terms and Calendar Exceptions | A-SELECT-NR | `lblAbsNrFacts`, `lblAbsNrDays` | S-NR-DAYS, S-NR-BADDATE, S-NR-CANCEL |
| R-PICKER | Searchable single-select picker, campus-filtered with search-all, includes inactive | Data exploration | `cboAbsNrStudent` (SelectMultiple false, DefaultSelectedItems []) over `colAbsNrStudents` (all statuses); campus filter unless `varAbsNrAllCampuses`; reset on record switch | A-PICK-STUDENT, A-SEARCH-ALL | `cboAbsNrStudent`, `lblAbsNrPickHint`, `lblAbsNrCheck` | S-PICK-CAMPUS, S-PICK-ALL, S-PICK-RESET |
| R-RESOLVE | Resolve Match: one save of Matched_Student, Student_ID, Match_Status; preserve other fields; success/error handling | Workflow and review | Disabled until picked; live re-check; directory item required; Patch 3 columns; audit; success -> receipt + queue removal + clear; failure -> error, keep selection | A-RESOLVE | `conAbsNrReceipt` (`lblAbsNrReceiptTitle`, `lblAbsNrReceiptBody`), `galAbsNrList`, `btnAbsViewNr.Text` | S-RESOLVE-OK, S-RESOLVE-FAIL, S-RESOLVE-ALREADY, S-RESOLVE-NO-DIR |
| R-KEY | Student Key required, unique, auto-suggested on Add; read-only on Edit | Data lifecycle | `txtStuFormExt` suggestion + validation in `lblStuFormCheck` and the "add" submit arm; Edit shows the key read-only and the edit Patch omits it; Dataverse alternate key backs uniqueness | A-ADD-STUDENT, A-EDIT-STUDENT | `txtStuFormExt`, `lblStuFormCheck`, `conStuReceipt`/`galStuReceipt` "Student Key" line | S-KEY-SUGGEST, S-KEY-DUP, S-KEY-FORMAT, S-KEY-READONLY |
| R-REGRESSION | Existing classify queue and Students behaviour unchanged | App shell and navigation | Classify controls moved into a wrapper, formulas untouched; other Students modes untouched | A-SWITCH-ABS-VIEW | `conAbsBody`, `galAbsList`, `conAbsReceipt`, Students receipts | S-REGRESSION |

## Requirement Coverage

| Requirement | Planned affordance | Fidelity |
| ----------- | ------------------ | -------- |
| Toggle "Classify absences \| Parent reports – Needs review (N)" | Two ModernButtons `btnAbsViewClassify` and `btnAbsViewNr` in `conAbsViewBar`, directly below the header. The current view uses Primary/teal and the other view uses Secondary. N = `CountRows(colAbsNr)` | Approximation: button pair instead of ModernTabList. The requirement allows either. The tab label changes when N changes, and that would re-render TabList items and reset the selected tab |
| Needs Review queue | `galAbsNrList` over `colAbsNr`, loaded by hidden `btnAbsNrEngine` with the verified delegable filter and sorted by Created descending | Exact |
| Selecting a record shows submitted names, campus, dates | Each row has a **Review** button (`btnAbsNrRowReview`). The detail panel shows `lblAbsNrFacts` | Exact |
| Computed days of absence | `lblAbsNrDays` counts school days from the Terms and Calendar Exceptions that the Review handler loads | Exact. Only Closed and Work Only are non-school, as approved. Holiday and Break exceptions are **not** excluded, because the approval names only Closed and Work Only |
| Searchable single-select student picker | `cboAbsNrStudent` (ModernCombobox, `SelectMultiple: =false`, `IsSearchable: =true`, `DefaultSelectedItems: =[]`) | Exact |
| Display "Last, First · code · key · status" | `ItemDisplayText: =ThisItem.Label` (Label built in the engine) | Exact |
| Campus filter by mapped code; search all campuses | `SchoolSite` -> `colAbsNrCampuses` (from Campuses) -> CampusCode. Checkbox `chkAbsNrAll` "Search all campuses" | Exact |
| Include inactive and archived students | `colAbsNrStudents` loads every Students row with no status filter | Exact |
| Resolve Match disabled until a student is picked | `btnAbsNrResolve.DisplayMode` gate | Exact |
| One save of the three columns; preserve the rest | A single `Patch('Student Absence Log', live, {Matched_Student, Student_ID, Match_Status})` | Exact |
| Directory item required | `LookUp('Student Directory', Student_ID = key)` with `key` from With(). If none is found, nothing is written and a Blocked receipt is shown | Exact |
| Re-check before saving | Re-read by ID. If Match_Status is not Needs Review, nothing is written and a Blocked receipt is shown | Exact |
| Audit row | `Patch('Audit Events', ...)` Action Update, Entity "sharepoint:Student Absence Log" | Exact |
| Success message + queue refresh only after success | `conAbsNrReceipt` (Kind "Resolved") + `RemoveIf(colAbsNr, ID = qid)` on the success path only | Exact |
| Error + keep selection on failure | Receipt Kind "Failed". `varAbsNrSelId` and `varAbsNrPickId` are unchanged | Exact |
| Reset student selection when switching records | The Review handler sets `varAbsNrPickId` to Blank and runs `Reset(cboAbsNrStudent)` | Exact |
| Student Key required + suggested on Add | `txtStuFormExt.Default` suggestion. `lblStuFormCheck` enforces required, format and uniqueness. The submit arm re-checks against live Dataverse | Exact |
| Student Key read-only on Edit | `txtStuFormExt.DisplayMode = View` in edit mode, plus note `lblStuFormExtNote`. The edit Patch omits the key | Exact |

## Required Record Fields

| Field key | Screen | Record surface | Required field | Source field | Presentation requirement |
| --------- | ------ | -------------- | -------------- | ------------ | ------------------------ |
| NR-ROW-NAME | AbsencesScreen | galAbsNrList row | Parent-typed student name (identity) | StudentFirstName, StudentLastName | `lblAbsNrRowName`, "Last, First (as typed)", full text, wraps to 2 lines |
| NR-ROW-META | AbsencesScreen | galAbsNrList row | Report ID, Title, school site, absence and return dates | ID, Title, SchoolSite, AbsenceDate, ReturnDate | `lblAbsNrRowMeta`, one combined wrapped label |
| NR-ROW-SUB | AbsencesScreen | galAbsNrList row | Reason, Submitted By, Date Notified | Reason, ParentName, DateNotified | `lblAbsNrRowSub`, one combined wrapped label |
| NR-DET-FACTS | AbsencesScreen | conAbsNrDetail | Report, typed first and last name, school site (+ code), absence/return dates, reason, submitted by, date notified | ID, Title, StudentFirstName, StudentLastName, SchoolSite, AbsenceDate, ReturnDate, Reason, ParentName, DateNotified | `lblAbsNrFacts`, 5 labeled lines |
| NR-DET-DAYS | AbsencesScreen | conAbsNrDetail | Days of absence | Computed from AbsenceDate/ReturnDate + Terms + Calendar Exceptions | `lblAbsNrDays` |
| NR-PICK-OPTION | AbsencesScreen | cboAbsNrStudent options | Last, First · campus code · Student Key · status | Students.'Display Name', current/latest Enrollment.Campus.Code, 'External Client ID', 'Status (aaca_status)' | `ItemDisplayText: =ThisItem.Label` |
| STU-FORM-KEY | StudentsScreen | conStuForm (add/edit) | Student Key | Students.'External Client ID' | `txtStuFormExt` with label `lblStuFormExt` and note `lblStuFormExtNote` |

## State-Driven Surface Visibility

| Surface key | Owner screen | Surface control | State predicate | Visible and hidden states |
| ----------- | ------------ | --------------- | --------------- | ------------------------- |
| SURF-ABS-VIEWBAR | AbsencesScreen | conAbsViewBar | `=CanClassify` | Visible for Office/Admin. Hidden for other roles, which see conAbsDenied |
| SURF-ABS-CLASSIFY | AbsencesScreen | conAbsClassifyView | `=varAbsView = "classify"` | Visible in the Classify view (default). Hidden in Parent reports |
| SURF-ABS-NR | AbsencesScreen | conAbsNrView | `=CanClassify && varAbsView = "nr"` | Visible in Parent reports for Office/Admin. Hidden otherwise |
| SURF-NR-RECEIPT | AbsencesScreen | conAbsNrReceipt | `=varAbsNrReceipt.Kind <> ""` | Visible after any Resolve attempt until Dismiss. Hidden initially |
| SURF-NR-LIST | AbsencesScreen | conAbsNrListPanel | `=!(conAbsRoot.Width < 1024 && !IsBlank(varAbsNrSelId))` | Hidden only on narrow widths while a report is selected |
| SURF-NR-DETAIL | AbsencesScreen | conAbsNrDetail | `=conAbsRoot.Width >= 1024 \|\| !IsBlank(varAbsNrSelId)` | Always visible at wide widths. On narrow widths, visible only while a report is selected |

## Action Contracts

| Requested action | Preconditions | Entry point | Owner screen | Control and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| ---------------- | ------------- | ----------- | ------------ | ----------------- | -------------------- | ---------------------------- | ------------------ | ----------------- | --------------------- |
| A-SWITCH-ABS-VIEW | CanClassify | conAbsViewBar buttons | AbsencesScreen | `btnAbsViewClassify.OnSelect: =Set(varAbsView, "classify")`; `btnAbsViewNr.OnSelect` sets `"nr"` and loads if not loaded | N/A (UI state `varAbsView`) | Swaps the visible view. Classify state and formulas are untouched | N/A | N/A | `conAbsClassifyView.Visible=varAbsView = "classify"`; `conAbsNrView.Visible=CanClassify && varAbsView = "nr"`; current button uses Primary/teal |
| A-LOAD-NR | CanClassify | Screen OnVisible, `btnAbsNrReload`, first switch to Parent reports | AbsencesScreen | `Select(btnAbsNrEngine)` -> `btnAbsNrEngine.OnSelect` | 'Student Absence Log' ID; Students.Student; Campuses.Campus | Fills `colAbsNr` (Needs Review only, Created desc), `colAbsNrCampuses`, `colAbsNrStudents` (all statuses). Clears the selection and pick | N/A (read) | N/A | `galAbsNrList.Items`; `lblAbsNrCount` (count, zero state, load error); `btnAbsViewNr.Text` N |
| A-SELECT-NR | A row exists in `colAbsNr` | Row button **Review** | AbsencesScreen | `btnAbsNrRowReview.OnSelect` | `colAbsNr.ID` -> `varAbsNrSelId` | Sets `varAbsNrSelId=ThisItem.ID`, clears pick + search-all, resets combobox, loads Terms/Calendar Exceptions for the span, sets `varAbsNrCalFor`. **Cancel** (`btnAbsNrCancel`) clears all of these | N/A | N/A | `lblAbsNrFacts`, `lblAbsNrDays` read `LookUp(colAbsNr, ID = varAbsNrSelId)`; the row fill highlights the selected ID |
| A-PICK-STUDENT | Report selected | `cboAbsNrStudent` | AbsencesScreen | `cboAbsNrStudent.OnChange` | `colAbsNrStudents.StudentId` -> `varAbsNrPickId` | Sets `varAbsNrPickId` from the single selected item, or Blank when cleared | N/A | N/A | `lblAbsNrCheck` names the picked student + key; `btnAbsNrResolve.DisplayMode` |
| A-SEARCH-ALL | Report selected | `chkAbsNrAll` "Search all campuses" | AbsencesScreen | `chkAbsNrAll.OnCheck` / `OnUncheck` | N/A (`varAbsNrAllCampuses`) | Check -> all campuses. Uncheck -> campus-only, and the pick is cleared | N/A | N/A | `cboAbsNrStudent.Items` filter; `lblAbsNrPickHint` names the active scope and count |
| A-RESOLVE | CanClassify, a report is selected and in the queue, one student is picked and has a Student Key, not saving/loading | `btnAbsNrResolve` "Resolve Match" | AbsencesScreen | `btnAbsNrResolve.OnSelect` | 'Student Absence Log' item `ID = varAbsNrSelId` (re-read live); Student Directory item by `Student_ID = key` | Guard: live status is "Needs Review" and the directory item exists. Then one Patch of 3 columns; Audit Events row; receipt; `RemoveIf(colAbsNr, ID = qid)`; clear selection + pick. On failure: Failed receipt, selection kept | Matched_Student {Id, Value}; Student_ID; Match_Status {Value "Manually Resolved"}; (side record: Audit Events row) | Item ID (+Title); Student_ID; Matched_Student Value + Id; Match_Status; picked student; audit outcome | `lblAbsNrReceiptTitle.Text` / `lblAbsNrReceiptBody.Text` bound to Patch result `w`; queue no longer contains the ID; `btnAbsViewNr.Text` N decremented |
| A-ADD-STUDENT (changed) | CanManageStudents; varStuMode "add" | `btnStuAdd` -> form -> `btnStuFormSubmit` | StudentsScreen | `btnStuFormSubmit.OnSelect` "add" arm | New Students row (`s.Student`) | Existing create flow, plus: Student Key required, must match the format, and must be unique (cache + live Dataverse) | Existing fields + 'External Client ID' = key (now always written) | Existing receipt lines + "Student Key" = `s.'External Client ID'` | `galStuReceipt` line "Student Key"; `colStuList` reload; `lblStuDetailFacts` "Student Key" |
| A-EDIT-STUDENT (changed) | CanManageStudents; varStuMode "edit" | `btnStuActEdit` -> form | StudentsScreen | `txtStuFormExt.DisplayMode`, `btnStuFormSubmit.OnSelect` "edit" arm | Students row `varStuSelId` | The key is shown read-only and **omitted** from the edit Patch. Other fields are unchanged from the existing flow | First/Last/Display/DOB/Grade (unchanged); 'External Client ID' removed | Existing lines; "Student Key" line reads `s.'External Client ID' & " (unchanged)"` | `galStuReceipt`; audit Before/After show the same key |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| ------ | --------------- | ----------------------------- | ---------------------------------- | -------------------- | ----------------------------------- | ----------------- |
| A-RESOLVE | `varAbsNrReceipt` built from Patch result `w` (+ `ItemId: w.ID`), rendered by `lblAbsNrReceiptTitle` / `lblAbsNrReceiptBody` | SharePoint 'Student Absence Log' item `ID = qid`. After Reload, `btnAbsNrEngine` re-queries `Filter(... Match_Status.Value = "Needs Review")`, which no longer returns that ID | Review queue `galAbsNrList` (`colAbsNr`) + toggle count `btnAbsViewNr.Text` | `qid = varAbsNrSelId` -> `LookUp('Student Absence Log', ID = qid)` -> `w.ID` -> `varAbsNrReceipt.ItemId` -> `RemoveIf(colAbsNr, ID = qid)` | Success-only `RemoveIf(colAbsNr, ID = qid)`. Failure/blocked paths do not touch `colAbsNr` | N/A (the item leaves the queue; the receipt names ID + Title) |
| A-ADD-STUDENT | Existing `varStuReceipt` + `colStuReceiptLines` from `s` (now incl. "Student Key") | Dataverse Students `s.Student` | `colStuList` / `galStuList` + detail (`varStuSelId = s.Student`) | `s.Student` throughout | Existing `Select(btnStuLoadEngine)` on success | Existing `Set(varStuSelId, s.Student)` |
| A-EDIT-STUDENT | Existing receipt from `s` | Students `q` | Existing | `q` / `s.Student` | Existing | Existing |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| ------ | ----- | -------------- | ---------------------------- | ------------------------------- | --------------------- | ------------------- |
| A-RESOLVE | Matched_Student | Changed | `dir` = `LookUp('Student Directory', Student_ID = key)` | `Matched_Student: {Id: dir.ID, Value: dir.Match_Name}` | Body line `"Matched_Student: " & w.Matched_Student.Value & " (Student Directory item #" & w.Matched_Student.Id & ")"` | SharePoint item view; audit After JSON |
| A-RESOLVE | Student_ID | Changed | `dir.Student_ID` (= picked Student Key) | `Student_ID: dir.Student_ID` | Body line `"Student_ID: " & w.Student_ID` | SharePoint item; audit After |
| A-RESOLVE | Match_Status | Changed | "Needs Review" (live re-check) | `Match_Status: {Value: "Manually Resolved"}` | Body line `"Match_Status: " & w.Match_Status.Value` | Queue re-query excludes the ID; audit After |
| A-RESOLVE | Student First/Last Name, School Site, Absence Date, Return Date, Reason, Submitted By, Date Notified, Title | Preserved | Live item `live` | Omitted from the partial Patch change record | Body line "Other columns: not written" | SharePoint item view (not rendered in the app after removal) |
| A-RESOLVE | Absence_x0020_Month, Billable_x0020_Days, Billing_x0020_Status, First_x0020_Eligible_x0020_Date, Total_x0020_Absence_x0020_Days (finance-owned) | Preserved | Live item | Omitted from the Patch; never referenced in any write | Same body line | SharePoint item view (finance) |
| A-ADD-STUDENT | 'External Client ID' (Student Key) | Changed | `Trim(txtStuFormExt.Text)` (validated) | `'External Client ID': ext` | Receipt line `{Label: "Student Key", Value: s.'External Client ID'}` | `colStuList` ExternalId after reload; `lblStuDetailFacts` |
| A-EDIT-STUDENT | 'External Client ID' | Preserved | `varStuEditBase.'External Client ID'` | Omitted from the edit Patch; the input is read-only | Receipt line `{Label: "Student Key", Value: Coalesce(s.'External Client ID', "—") & " (unchanged)"}` | Audit Before/After ExternalClientId equal |

## Functional Test Matrix

Test data note: SharePoint content is live. Scenarios name illustrative test items. Create them in the
FinanceMain `Student Absence Log` list, or substitute real item IDs.

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| -------- | ----- | ---- | ---- | ---------------- | ------------------------- |
| S-TOGGLE | Office user on Absences; 3 Needs Review items exist | Press "Parent reports – Needs review (3)", then "Classify absences" | `varAbsView` = "nr" then "classify"; the classify queue, filters and receipt are unchanged | `conAbsNrView` / `conAbsClassifyView` visibility; button label shows (3) | Teacher role: conAbsViewBar hidden, conAbsDenied shown |
| S-NR-LIST | Items #515 (Needs Review, Created 9/13), #516 (Needs Review, Created 9/14), #517 (Exact) | Open Parent reports | `colAbsNr` holds #516 and #515 (newest first); #517 is absent | Rows show name, #ID · Title · site · dates, reason · submitted by · notified; `lblAbsNrCount` "2 parent reports need review" | N/A |
| S-NR-EMPTY | No Needs Review items | Open Parent reports | `colAbsNr` is empty | `lblAbsNrCount` zero-state text; gallery hidden; button "(0)" | Load error: `lblAbsNrCount` shows "Could not load parent reports — …" in red |
| S-NR-DAYS | #515 Chatsworth, Absence "9/18/2026" (Fri), Return "09/22/2026" (Tue); CW term covers September; all-campus Closed exception on 9/21 | Review #515 | Span is Fri 9/18 – Mon 9/21. Sat/Sun are excluded and Mon is Closed | `lblAbsNrDays` "Days of absence: 1 school day · Fri 9/18/2026 – Mon 9/21/2026" | Without the 9/21 exception the result is 2. A Make-up School Day on Sat 9/19 adds 1. Return blank or <= Absence -> 1 day (Absence Date only) |
| S-NR-BADDATE | #518 Absence Date "13/45/2026" | Review #518 | No calendar load | `lblAbsNrDays` "Days of absence: check dates — …" showing the raw text in red | Return Date that can't be parsed -> same note |
| S-NR-CANCEL | #515 selected, student picked | Press Cancel | `varAbsNrSelId`/`varAbsNrPickId` are Blank; nothing written | Detail shows the empty prompt; on phone the list reappears | N/A |
| S-PICK-CAMPUS | #515 SchoolSite "Chatsworth" (Campuses.Code "CW"); students at CW (Active, Inactive, Archived) and at AV | Review #515, open the picker | Options = CW students of every status only | `lblAbsNrPickHint` "CW students · n, all statuses incl. archived…"; option text "Garcia, Ana · CW · CW-1083 · Active" | SchoolSite matching no campus -> all campuses shown with a note |
| S-PICK-ALL | As S-PICK-CAMPUS | Tick Search all campuses, then untick | Options = all students; after untick, CW only and the pick is cleared | `lblAbsNrPickHint`; `lblAbsNrCheck` returns to "Pick the student…" | N/A |
| S-PICK-RESET | #515 selected and "Garcia, Ana" picked | Review #516 | The picker is empty, `varAbsNrPickId` is Blank, search-all is off, and Resolve is disabled | `cboAbsNrStudent` empty; `lblAbsNrCheck` | N/A |
| S-RESOLVE-OK | #515 Needs Review; directory item #88 Student_ID "CW-1083", Match_Name "ana garcia"; picked Garcia, Ana (CW-1083) | Press Resolve Match | #515: Matched_Student {Id 88, Value "ana garcia"}, Student_ID "CW-1083", Match_Status "Manually Resolved". Other columns are unchanged. One Audit Events row (Update, Entity "sharepoint:Student Absence Log", Entity ID "515", Summary "Parent report #515 matched to CW-1083") | Receipt "Parent report #515 matched · CW-1083 · Garcia, Ana" with body lines; #515 is gone from the queue; the toggle count drops by 1; selection and picker are cleared | N/A |
| S-RESOLVE-FAIL | As S-RESOLVE-OK but the user has read-only permission on the list (Patch errors) | Press Resolve Match | Nothing written; no audit row | Receipt Kind "Failed" (red), with the error in the body; #515 stays selected with the same pick; the queue is unchanged | Button re-enabled for retry |
| S-RESOLVE-ALREADY | #515 was changed to "Exact" by the flow after the queue loaded | Press Resolve Match | Nothing written | Receipt Kind "Blocked": "Not saved · report #515 is now Exact"; the selection is kept | Reload removes it from the queue |
| S-RESOLVE-NO-DIR | Picked student key "OX-1130" has no Student Directory item | Press Resolve Match | Nothing written | Receipt Kind "Blocked": "Not saved · no Student Directory item for OX-1130"; the selection is kept | Picked student with no key -> Resolve disabled; `lblAbsNrCheck` explains |
| S-KEY-SUGGEST | The highest numeric suffix across Students keys is 1126 (e.g. AV-1126) | + Add student, choose campus Oxnard (Code OX) | `txtStuFormExt` shows "OX-1127"; the user can edit it | Input text; `lblStuFormExtNote` | No campus chosen -> empty key; `lblStuFormCheck` asks for a key after the campus |
| S-KEY-DUP | CW-1083 belongs to Garcia, Ana | Add with key "CW-1083" (all else valid) | Save blocked; nothing written | `lblStuFormCheck` "Student Key CW-1083 is already used by Garcia, Ana (STU-…)…"; submit disabled | Race: another user takes the key between check and save -> submit arm `liveKey > 0` gives a Blocked receipt; alternate-key violation -> existing Failed receipt |
| S-KEY-FORMAT | Add form valid except key "cw1083" | Type the key | Blocked | `lblStuFormCheck` "Student Key must be 2–3 capital letters, a dash and digits, like CW-1083." | "" -> "Enter a Student Key…" |
| S-KEY-READONLY | Student with key CW-1083 | Edit details, change the first name, Save details | First name saved; the key is not written and stays CW-1083 | `txtStuFormExt` in View mode; note "Student Key can't be changed."; receipt line "Student Key: CW-1083 (unchanged)" | N/A |
| S-REGRESSION | Classify view with absences loaded | Filter, tick, Mark Excused/Unexcused, row Excused… flow | Behaviour identical to build 3 | `galAbsList`, `conAbsReceipt`, `conAbsDecide` | Students transfer/ratio/end/reenroll unchanged |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| -------------- | ------------------------ | ------------------- |
| cboAbsNrStudent (ModernCombobox) | `lblAbsNrPick.Text: ="Student *"` | `conAbsNrPickField` |
| txtStuFormExt (ModernTextInput) | `lblStuFormExt.Text: =If(varStuMode = "edit", "Student Key (read-only)", "Student Key *")` | `conStuFormIdentity` |

## Layout Budget Contracts

| Screen / container | Branch / screen-width source | Horizontal total-width arithmetic | Vertical height arithmetic | Protected controls |
| ------------------ | ---------------------------- | --------------------------------- | -------------------------- | ------------------ |
| AbsencesScreen / conAbsViewBar | `conAbsRoot.Width` (<640 vertical) | ≥640: 16 + 170 + 8 + 320 + 16 = 530 ≤ 640 | <640: 44 + 8 + 44 = 96; ≥640: 44 | Both view buttons |
| AbsencesScreen / conAbsNrBody | `conAbsRoot.Width` (≥1024 horizontal, 1:1) | ≥1024: two FillPortions=1 panels (min 0) + gap 8; each ≥ 508 | Wide: Max(list, detail); stacked: visible sum + 8 | Resolve Match |
| AbsencesScreen / conAbsNrListPanel | same | N/A | 16 + 44 + 8 + (54 \| 36) + (8 + 520 if rows) + 16 → 666 phone / 648 desktop | Review buttons |
| AbsencesScreen / galAbsNrList row | same breakpoint for TemplateSize and label heights | Row top: name FillPortions 1 + Review 90 + gap 8 ≤ 326 (phone inner) | Phone: 8+44+4+54+4+54+8 = 176 ≤ 180; ≥640: 8+44+4+36+4+36+8 = 140 ≤ 144 | Review |
| AbsencesScreen / conAbsNrDetail | same | Actions 150 + 8 + 100 = 258 ≤ 326 | Empty: 16+28+8+60+16 = 128. Selected phone: 16+28+8+200+8+80+8+98+8+44+8+54+8+44+16 = 628; ≥640: 16+28+8+130+8+40+8+98+8+44+8+36+8+44+16 = 500 | cboAbsNrStudent, Resolve Match, Cancel |
| AbsencesScreen / conAbsNrReceipt | same | Title FillPortions 1 + Dismiss 88 | 8 + (84 \| 44) + (4 + (220 \| 148) if body) + 8 | Receipt title + all 8 body lines |
| StudentsScreen / conStuFormIdentity | `conStuForm.Width < 700` (existing form breakpoint) | N/A | 5 labels × 18 (90) + 5 inputs × 36 (180) + note (36 \| 54 narrow) + 10 gaps × 4 (40) = 346 \| 364 (was 306); conStuForm add/edit term becomes `If(n, 364, 346) + 8` | txtStuFormExt + note |

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| ------ | ------------ | -------------- | ------------- | -------------- | --------------- |
| AbsencesScreen | conAbsRoot (existing, sole top-level child) | AutoLayout | `conAbsRoot.Width: =Parent.Width` | `conAbsRoot.Height: =Parent.Height` | Vertical scroll (existing). New sections nest under it |
| StudentsScreen | conStuRoot (existing, sole top-level child) | AutoLayout | `conStuRoot.Width: =Parent.Width` | `conStuRoot.Height: =Parent.Height` | Vertical scroll (existing); no layout change beyond the form height |

## Temporal Ordering Contracts

| Ordering key | Source | Sort field | Storage semantics | Input validation / normalization | Canonical sort binding | Accepted formats | Invalid / blank behavior |
| ------------ | ------ | ---------- | ----------------- | -------------------------------- | ---------------------- | ---------------- | ------------------------ |
| NR-QUEUE-ORDER | colAbsNr (from 'Student Absence Log') | Created | Typed DateTime (SharePoint system column) | N/A (system-set) | Load: `Sort(Filter(...), Created, SortOrder.Descending)`; gallery `Sort(colAbsNr, Created, SortOrder.Descending)` | N/A | Never blank |

## Working Directory

C:\src\aaca-attendance\app

## Discovery Summary

- Existing screens: Screen1 (Att, untouched), StudentsScreen (Stu), AbsencesScreen (Abs)
- Layout: AutoLayout, scroll roots `conStuRoot` / `conAbsRoot`; breakpoints 640 / 1024 on root width
- Data sources: Dataverse Students, Enrollments, Campuses, Terms, Calendar Exceptions, Audit Events (+ existing);
  SharePoint Student Absence Log, Student Directory (build 4 addendum)
- Controls used by the edit: GroupContainer, ModernText, ModernButton, Classic/Button, Gallery, ModernSpinner,
  ModernCombobox (new to the app), ModernCheckbox, ModernTextInput. All are in the discovery packet

## Dispatch

| Action | Screen | Target File | YAML Key | Name Prefix | Screen Brief |
| ------ | ------ | ----------- | -------- | ----------- | ------------ |
| Modify | Absences | `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml` | AbsencesScreen | Abs | `C:\src\aaca-attendance\app\AbsencesScreen.screen-plan.md` |
| Modify | Students | `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml` | StudentsScreen | Stu | `C:\src\aaca-attendance\app\StudentsScreen.screen-plan.md` |

## App Changes

### Before builders

In `App.pa.yaml` `OnStart`, the current last statement is `Clear(colAbsReceiptLines)`. Append `;` after it,
then append these statements verbatim. Formulas are unchanged.

```
Set(varAbsView, "classify");
Set(varAbsNrLoading, false);
Set(varAbsNrSaving, false);
Set(varAbsNrLoaded, false);
Set(varAbsNrLoadError, "");
Set(varAbsNrErr, "");
Set(varAbsNrAllCampuses, false);
Set(varAbsNrSelId, 0);
Set(varAbsNrSelId, Blank());
Set(varAbsNrCalFor, 0);
Set(varAbsNrCalFor, Blank());
Set(varAbsNrPickId, ZeroGuid);
Set(varAbsNrPickId, Blank());
Set(varAbsNrReceipt, {Kind: "", Title: "", Body: "", ItemId: 0})
```

### After builders

None

## Editor State Changes

None
