# Canvas App Plan

## Mode

EDIT (build 9 - Add absence + Left early on Absences, left-early marker on the grid, Transportation nav, NEW
TransportScreen with Daily confirmation + Students tabs)

## Requirements

Source of truth: `C:\src\aaca-attendance\docs\app-builds\build-9-transport\canvas-app-requirements.md` (immutable).
Summary:

- AbsencesScreen (office/admin) Classify view, right-hand detail column: **Add absence** (student, From/To, Excused +
  reason / Unexcused, note; one Attendance 0 per school day the student is enrolled; skip present / already absent /
  locked; reuse deleted rows; Source Office; audit Create per row; receipt of created/skipped days) and **Left early**
  (student, date <= today, time h:mm AM/PM, reason; present row -> set Left Early fields; absent -> refuse; no row ->
  create present row Source Office with left-early fields; audit Update/Create). Nav button **Transportation**.
- Screen1: present + Left Early cell shows `1*`; legend gains "1* left early (office)"; undo blocked on left-early days.
  Nav button **Transportation**.
- StudentsScreen: nav button **Transportation**.
- NEW TransportScreen (CanClassify; campus picker locked for office): tabs **Daily** (date, list of students with an
  active Student Transportation row covering the date and enrolled at the campus that day; usual pattern, attendance,
  four status buttons, pre-fill rules, "Confirmed by X at h:mm", **Confirm day** upsert by Log Key, single-row change
  after confirmation, banner "N school days not confirmed" for the last 10 school days with clickable days, deadline
  text) and **Students** (Student Transportation list, Show ended, **Add**, **Change pattern**, **End
  transportation**, audit per write).

## Original Request Capability Inventory

The requirements file has no keyed inventory; keys below are assigned here from its numbered clauses.

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Observer(s) | Scenario(s) |
| --- | --- | --- | --- | --- | --- | --- |
| R-ABS-ADD-ENTRY | A.1 "Add absence panel (button opens it in the right-hand detail column)" | App shell and navigation | `btnAbsAddOpenV` in `conAbsDecideV`; panel `conAbsAddPanelV` | A-ABS-ADD-OPEN | `conAbsAddPanelV.Visible`, `lblAbsDecideTitleV` "Add absence" | S-ABS-ADD-OPEN |
| R-ABS-ADD-INPUTS | A.1 student picker (campus students, search), From / To (To optional = same day; future up to Today()+90), Excused needs reason / Unexcused, optional note | Data lifecycle | `cboAbsAddStuV` (colAbsAddStu), `dpAbsAddFromV`, `dpAbsAddToV`, `rdoAbsAddClassV`, `ddAbsAddReasonV`, `txtAbsAddNoteV`; gate `lblAbsAddCheckV` | A-ABS-ADD-SAVE | `lblAbsAddCheckV.Text`, `btnAbsAddSaveV.DisplayMode` | S-ABS-ADD-RANGE, S-ABS-ADD-INVALID |
| R-ABS-ADD-SCHOOLDAY | A.1 one Attendance row per school day in range with an enrollment (term, weekday/make-up, no closing exception); skip locked months | Time and scheduling | School-day rule (shared plan) over colAbsAddTerms / colAbsAddExc; enrollment from colAbsAddEnr; lock from colAbsLocks | A-ABS-ADD-SAVE | receipt lines per day; Non-school count in title | S-ABS-ADD-RANGE, S-ABS-ADD-LOCKED |
| R-ABS-ADD-FIELDS | A.1 row fields: Present false, Source Office, classification + reason / Unexcused, Classified On/By, Notes, Enrollment/Teacher/Campus/School Year/Term/IEP Ratio, Service, Record Key, Is Deleted false, Notice Received On blank | Data lifecycle | Patch write set (ledger) | A-ABS-ADD-SAVE | receipt Classification / Classified by / Note lines from `wr`; Screen1 grid 0 coloured | S-ABS-ADD-RANGE, S-ABS-ADD-UNEXCUSED, S-GRID-ABSENCE-VISIBLE |
| R-ABS-ADD-EXISTING | A.1 existing non-deleted present -> skip "teacher marked present - use Needs a decision / ask the teacher"; already absent -> skip; deleted -> reuse | Workflow and review | outcome per day | A-ABS-ADD-SAVE | receipt per-day lines | S-ABS-ADD-RANGE |
| R-ABS-ADD-AUDIT-RECEIPT | A.1 Audit Event (Create) per row; receipt lists created / skipped days | Security, persistence, and resilience | Audit Create per created row; `conAbsReceiptV` lines | A-ABS-ADD-SAVE | `lblAbsReceiptTitleV`, `galAbsReceiptV` | S-ABS-ADD-RANGE |
| R-LE-ENTRY | A.2 Left early panel (button) | App shell and navigation | `btnAbsLeOpenV`; same panel in leftearly mode | A-LE-OPEN | `conAbsAddPanelV.Visible`, title "Left early" | S-LE-OPEN |
| R-LE-INPUTS | A.2 student picker (campus), date (today default, past allowed, no future), time left (h:mm AM/PM), reason required | Data lifecycle | `cboAbsAddStuV`, `dpAbsAddFromV` (EndDate Today()), `txtAbsLeTimeV`, `txtAbsAddNoteV` | A-LE-SAVE | `lblAbsAddCheckV`, `btnAbsLeSaveV.DisplayMode` | S-LE-INVALID |
| R-LE-PRESENT | A.2 non-deleted present row -> Left Early = true, Left Early At, Left Early Reason | Workflow and review | partial Patch on live row | A-LE-SAVE | receipt lines from `w` | S-LE-PRESENT |
| R-LE-ABSENT | A.2 absent row -> refuse ("marked absent") | Workflow and review | no write | A-LE-SAVE | Blocked receipt | S-LE-ABSENT |
| R-LE-NOROW | A.2 no row -> create present row Source Office, enrollment fields, left-early fields; office can record even if teacher has not marked | Data lifecycle | Patch Coalesce(live deleted, Defaults) | A-LE-SAVE | receipt; Screen1 `1*` | S-LE-NOROW, S-GRID-MARKER |
| R-LE-AUDIT | A.2 Audit Event (Update/Create) | Security, persistence, and resilience | Audit Update (existing present) / Create (new or reused deleted) | A-LE-SAVE | receipt "Audit event" line | S-LE-PRESENT, S-LE-NOROW |
| R-ABS-LIST-UNCHANGED | A.3 no left-early display in classify list | Data exploration | classify list untouched | N/A (regression) | `galAbsListV` unchanged | S-ABS-CLASSIFY-REGRESSION |
| R-GRID-MARKER | B grid cell present + Left Early shows "1*"; legend "1* left early (office)" | Analytics and visualization | colMonthAtt.LeftEarly; `btnAttCell.Text`; `lblAttLegend.Text` | A-GRID-LOAD | `btnAttCell.Text`, tooltip, `lblAttDayStatus`, legend | S-GRID-MARKER |
| R-GRID-NO-UNDO | B teachers cannot change it; block undo on left-early day | Security, persistence, and resilience | Editable/Actionable false; save-engine guard | A-GRID-UNDO-BLOCK | `btnAttCell.DisplayMode`, `btnAttDayClear.DisplayMode`, Blocked `lblAttReceipt` | S-GRID-UNDO-BLOCK, S-GRID-UNDO-REGRESSION |
| R-NAV-TRANSPORT | B, C, D, E "Transportation" nav button (CanClassify) next to Absences on Screen1, StudentsScreen, AbsencesScreen (+ TransportScreen current) | App shell and navigation | `btnAttNavTransport`, `btnStuNavTransport`, `btnAbsNavTransport`, `btnTrnNavTransport` | A-NAV-TRANSPORT | buttons visible for O/M; TransportScreen opens | S-NAV-TRANSPORT, S-NAV-ROLE |
| R-TRN-SHELL | E same header/nav/look; campus picker (office locked via StudentCampusLock, admins choose); CanClassify | App shell and navigation | `conTrnHeader`, `ddTrnCampus`, `conTrnDenied` | A-TRN-CAMPUS | `ddTrnCampus.DisplayMode`, denied panel | S-TRN-CAMPUS, S-TRN-ROLE |
| R-TRN-TABS | E two views via tabs in the header strip: Daily (default), Students | App shell and navigation | `conTrnHdrTabs` with `btnTrnHdrDaily`, `btnTrnHdrStudents`; varTrnView | A-TRN-TAB-DAILY, A-TRN-TAB-STUDENTS | `conTrnDailyView.Visible`, `conTrnStuView.Visible` | S-TRN-TABS |
| R-TRN-DAILY-LIST | E.1 date picker (default Today, school days, no future), list = active ST row covering date AND enrolled at campus that day; row: student, usual pattern, attendance (present / absent / left early h:mm / not marked) | Data exploration | btnTrnLoadEngine -> colTrnDaily | A-TRN-LOAD-DAY | `galTrnDayList`, `lblTrnDayName`, `lblTrnDayMeta`, `lblTrnDayCount` | S-TRN-DAILY-LIST, S-TRN-NONSCHOOL |
| R-TRN-STATUS-BUTTONS | E.1 four toggle buttons Round trip / Drop off only / Pick up only / No transportation | Workflow and review | `btnTrnOptRound`, `btnTrnOptDrop`, `btnTrnOptPick`, `btnTrnOptNone` set Pick | A-TRN-PICK | button Appearance, `lblTrnDayStatus` | S-TRN-CONFIRM |
| R-TRN-PREFILL | E.1 pre-fill when no Daily Transport row: absent -> No transportation; left early -> Drop off only; else blank "Not confirmed" | Workflow and review | colTrnDaily.Pick at load | A-TRN-LOAD-DAY | `lblTrnDayStatus`, active button | S-TRN-DAILY-LIST |
| R-TRN-CONFIRMED-BY | E.1 row shows saved status and "Confirmed by X at h:mm" | Data exploration | colTrnDaily.SavedStatus/ByName/OnTime from Daily Transport | A-TRN-LOAD-DAY, A-TRN-CONFIRM-DAY | `lblTrnDayStatus` | S-TRN-CONFIRM |
| R-TRN-CONFIRM-DAY | E.1 Confirm day saves every row (all must have status; disabled until then); upsert by Log Key; Confirmed On/By, Campus, Student; owner = creator | Data lifecycle | btnTrnSaveEngine (scope "day") | A-TRN-CONFIRM-DAY | receipt; `lblTrnDayStatus`; banner | S-TRN-CONFIRM, S-TRN-CONFIRM-DISABLED, S-TRN-UPSERT |
| R-TRN-ROW-CHANGE | E.1 single-row change after confirmation updates that row (re-confirm) | Data lifecycle | status button on a saved row -> btnTrnSaveEngine (scope "row") | A-TRN-ROW-CHANGE | receipt; `lblTrnDayStatus` | S-TRN-ROW-CHANGE |
| R-TRN-BANNER | E.1 banner "N school days not confirmed" for last 10 school days at campus (unconfirmed = any listed student lacks a row); click a day to open it; deadline text | Analytics and visualization | btnTrnBannerEngine -> colTrnDays | A-TRN-BANNER, A-TRN-BANNER-OPEN | `lblTrnBannerTitle`, `galTrnBannerDays`, `lblTrnDeadline` | S-TRN-BANNER |
| R-TRN-STU-LIST | E.2 Student Transportation rows at campus (active default; Show ended): student, key, pattern, start-end, source | Data exploration | btnTrnStuLoadEngine -> colTrnStAll; `chkTrnShowEnded` | A-TRN-STU-LOAD, A-TRN-SHOW-ENDED | `galTrnStuList`, `lblTrnStuRowName`, `lblTrnStuRowMeta` | S-TRN-STU-LIST |
| R-TRN-STU-ADD | E.2 Add (student picker = campus students without an active row; start date default today; pattern) | Data lifecycle | Patch Student Transportation (new, Source Manual) | A-TRN-STU-ADD | receipt; new row highlighted | S-TRN-STU-ADD, S-TRN-STU-ADD-INVALID |
| R-TRN-STU-CHANGE | E.2 Change pattern (pattern + note) | Data lifecycle | Patch Usual Pattern, Note | A-TRN-STU-CHANGE | receipt; row meta | S-TRN-STU-CHANGE |
| R-TRN-STU-END | E.2 End transportation (end date default today) | Data lifecycle | Patch End Date | A-TRN-STU-END | receipt; row meta "– <end>" | S-TRN-STU-END |
| R-TRN-AUDIT | E.2 / Non-functional: Audit Event per write; IfError on all writes | Security, persistence, and resilience | Audit Create/Update per Daily Transport / Student Transportation write | A-TRN-CONFIRM-DAY, A-TRN-ROW-CHANGE, A-TRN-STU-ADD, A-TRN-STU-CHANGE, A-TRN-STU-END | receipt "audit ... written" | S-TRN-CONFIRM, S-TRN-STU-ADD |
| R-NF-LEAN | AbsencesScreen complexity 311: keep additions lean, reuse detail column | Security, persistence, and resilience | 22 new controls + 1 engine on Absences; logic in two Save buttons | N/A | App Checker after build | N/A (reported in risks) |

## Requirement Coverage

| Requirement | Planned affordance | Fidelity |
| --- | --- | --- |
| Add absence button opens panel in right-hand detail column | NEW `conAbsAddBarV` (inside existing `conAbsDecideV`, after `conAbsDecideActionsV`) with `btnAbsAddOpenV` "Add absence"; NEW `conAbsAddPanelV` below it | Exact |
| Student picker (campus, search) | `cboAbsAddStuV` (ModernCombobox, searchable) over `colAbsAddStu` (students with an enrollment at `varAbsCampusId` not ended more than 365 days ago) | Exact |
| From / To, To optional = same day, future up to +90 | `dpAbsAddFromV` (Default Today), `dpAbsAddToV` (Default blank); gate 0..60-day span, To <= Today()+90 | Exact; 61-day cap added (Approximation: keeps one Save inside canvas limits; matches the intake flow's 60-day limit) |
| Classification (Excused requires reason; Unexcused) | `rdoAbsAddClassV` Excused / Unexcused (no default) + `ddAbsAddReasonV` (Absence Reasons) shown for Excused | Exact |
| Optional note | `txtAbsAddNoteV` label "Note (optional)" -> Notes | Exact |
| One row per school day with enrollment; skip locked months | `btnAbsAddSaveV.OnSelect` loops days; shared school-day rule; enrollment segment per day; colAbsLocks | Exact |
| Existing row rules (present -> skip with message; absent -> skip; deleted -> reuse) | outcome per day in the same handler | Exact |
| Audit Create per row; receipt created/skipped days | existing `conAbsReceiptV` (varAbsReceipt + colAbsReceiptLines), one line per non-weekend day | Exact (non-school days are counted, not listed one by one) |
| Left early button / panel | `btnAbsLeOpenV` "Left early" -> same `conAbsAddPanelV` in leftearly mode | Exact |
| Time left (h:mm AM/PM) | `txtAbsLeTimeV` parsed with `TimeValue(tt, "en-US")`, must end in AM/PM | Exact (text option from the request) |
| Reason required | `txtAbsAddNoteV` labelled "Reason *" in leftearly mode | Exact |
| Left early on present / absent / no row | `btnAbsLeSaveV.OnSelect` three branches | Exact |
| Grid marker `1*` + legend | `btnAttCell.Text`, `lblAttLegend.Text`; Day view `lblAttDayStatus` via StatusWord | Exact (text marker, no new fill) |
| Block undo on left-early day | `galAttCells`/`galAttDayList` Editable+Actionable exclude LeftEarly; `btnAttSaveEngine` guard | Exact |
| Transportation nav buttons (CanClassify) | `btnAttNavTransport`, `btnStuNavTransport`, `btnAbsNavTransport` appended to existing nav containers; `btnTrnNavTransport` current | Exact |
| TransportScreen header/nav/look, campus picker | `conTrnHeader` (Abs pattern) + `ddTrnCampus` inside `conTrnHdrTabs` | Exact |
| Daily / Students tabs in header strip | `conTrnHdrTabs` buttons `btnTrnHdrDaily`, `btnTrnHdrStudents` | Exact |
| Daily date picker (default Today, school days, no future) | `dpTrnDate` EndDate Today(); non-school dates show a notice and disable all writes | Approximation: the picker cannot grey out non-school days; it explains and blocks instead |
| Daily list rows (student, pattern, attendance) | `galTrnDayList` row: `lblTrnDayName`, `lblTrnDayMeta`, `lblTrnDayStatus` | Exact |
| Four toggle buttons | `btnTrnOptRound`, `btnTrnOptDrop`, `btnTrnOptPick`, `btnTrnOptNone` (active = Primary teal) | Exact |
| Pre-fill rules | `colTrnDaily.Pick` at load (absent -> No transportation; left early -> Drop off only; else blank) | Exact |
| "Confirmed by X at h:mm" | `lblTrnDayStatus` from Daily Transport `Confirmed By`/`Confirmed On` | Exact |
| Confirm day upsert by Log Key | `btnTrnConfirm` -> `btnTrnSaveEngine` (live `LookUp` by Log Key, then Patch existing or Defaults) | Exact |
| Daily Transport "Student Transportation link" | not written | Approximation: discovery says the lookup is not exposed in the app's metadata; Student + Date (+ Log Key) identify the row |
| Single-row change after confirmation | status buttons on a saved row save immediately (scope "row") | Exact |
| Banner N unconfirmed days, last 10 school days, click a day, deadline text | `conTrnBanner`: `lblTrnBannerTitle`, `lblTrnDeadline` "Confirm each school day by the end of the day.", `galTrnBannerDays` chips | Exact (window = last 10 school days inside the past 28 calendar days, today included) |
| Students tab list + Show ended | `galTrnStuList`, `chkTrnShowEnded` | Exact |
| Add / Change pattern / End transportation | `btnTrnStuAdd`, row `btnTrnStuRowChange`, `btnTrnStuRowEnd` -> right panel `conTrnStuPanel` -> `btnTrnStuSave` (mode-guarded) | Exact |
| Audit per write, IfError | every Patch wrapped; receipts show audit outcome | Exact |

## Required Record Fields

| Field key | Screen | Record surface | Required field | Source field | Presentation requirement |
| --- | --- | --- | --- | --- | --- |
| trn-day-identity | TransportScreen | galTrnDayList row | student name + key | colTrnDaily.StudentName, KeyBase | `lblTrnDayName` 14 Semibold, full text |
| trn-day-pattern-att | TransportScreen | galTrnDayList row | usual pattern; attendance (Present / Absent / Left early h:mm AM/PM / Not marked) | Pattern, AttText | `lblTrnDayMeta` "Usual: X · Attendance: Y" |
| trn-day-status | TransportScreen | galTrnDayList row | saved status + "Confirmed by X at h:mm" or "Not confirmed" + pre-fill note | SavedStatus, ByName, OnTime, Pick, Prefill | `lblTrnDayStatus` |
| trn-day-choice | TransportScreen | galTrnDayList row | current choice | Pick | active (Primary) state of the four buttons |
| trn-stu-identity | TransportScreen | galTrnStuList row | student + key | StudentName, KeyBase | `lblTrnStuRowName` |
| trn-stu-meta | TransportScreen | galTrnStuList row | pattern, start - end ("ongoing"), source, note | Pattern, StartDate, EndDate, SourceText, Note | `lblTrnStuRowMeta` |
| trn-banner-day | TransportScreen | galTrnBannerDays chip | date + missing count | colTrnDays.D, Missing | `btnTrnBannerDay.Text` "Thu 10/1 (1)" |
| att-cell-left-early | Screen1 | galAttCells cell / galAttDayList row | 1* marker; status word with time | colMonthAtt.LeftEarly, LeftEarlyAt | `btnAttCell.Text`, Tooltip, `lblAttDayStatus` |
| abs-rcpt-day (receipt) | AbsencesScreen | galAbsReceiptV line | per-day outcome | colAbsLog | `lblAbsRcptLabelV` / `lblAbsRcptValueV` (existing) |

## State-Driven Surface Visibility

| Surface key | Owner screen | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- | --- |
| abs-add-bar | AbsencesScreen | conAbsAddBarV | `=CanClassify && IsBlank(varAbsSelId)` | Visible when no Excused row is open; hidden while Excused… is in progress |
| abs-add-panel | AbsencesScreen | conAbsAddPanelV | `=CanClassify && IsBlank(varAbsSelId) && varAbsAddMode in ["absence", "leftearly"]` | Visible after Add absence / Left early; hidden after Save success, Cancel, campus change, Excused… |
| trn-daily | TransportScreen | conTrnDailyView | `=CanClassify && varTrnView = "daily"` | Daily tab |
| trn-students | TransportScreen | conTrnStuView | `=CanClassify && varTrnView = "students"` | Students tab |
| trn-denied | TransportScreen | conTrnDenied | `=!CanClassify` | Teachers / Read-only / not set up |
| trn-receipt | TransportScreen | conTrnReceipt | `=CanClassify && varTrnReceipt.Kind <> ""` | After any save attempt until Close |
| trn-stu-panel | TransportScreen | conTrnStuPanel | `=conTrnRoot.Width >= 1024 \|\| varTrnStuMode <> ""` | Always on desktop; on narrow only while a mode is open |

## Action Contracts

| Requested action | Preconditions | Entry point | Owner screen | Control and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-ABS-ADD-OPEN | CanClassify, classify view | "Add absence" | AbsencesScreen | `btnAbsAddOpenV.OnSelect` | N/A | varAbsSelId Blank; varAbsAddMode "absence"; inputs reset; `Select(btnAbsAddLoadEngine)` loads colAbsAddEnr/colAbsAddStu for varAbsCampusId | N/A | N/A | `conAbsAddPanelV.Visible`; title "Add absence" |
| A-LE-OPEN | same | "Left early" | AbsencesScreen | `btnAbsLeOpenV.OnSelect` | N/A | mode "leftearly"; same resets/load | N/A | N/A | panel visible; title "Left early" |
| A-ABS-ADD-SAVE | CanClassify; mode "absence"; 1 student; From set; From <= To <= Today()+90; span <= 60 days; class chosen; Excused => reason; not saving/loading | panel -> "Save absence" | AbsencesScreen | `btnAbsAddSaveV.OnSelect` (direct) | Attendance by Student + Service + Date (live LookUp per day); returned `wr.Attendance` | per school day with enrollment & unlocked month: none/deleted -> Patch absent row; present/absent -> skip; audit Create per created row; `Select(btnAbsLoadEngine)` | Attendance: Record Key, Date, Student, Service, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio, Present=false, Is Deleted=false, Source=Office, Absence Classification, Absence Reason, Classified On, Classified By, Notes, Notice Received On=blank, Parent Reported Absent=false, Source Report ID=blank, Left Early=false, Left Early At=blank, Left Early Reason=blank. Audit Events row per created day | Title: student, date range, created/skipped/failed counts, non-school count. Lines: Operation, Student, Dates, Classification (`wr`), Classified by + on (`wr`), Note (`wr.Notes`), Created, Skipped, Failed, one line per day (Created · class · teacher · reused? · audit / Skipped · reason / FAILED) | `conAbsReceiptV` (`lblAbsReceiptTitleV`, `galAbsReceiptV`); classify list (Excused/Unexcused filter) after reload; Screen1 grid 0 green/red |
| A-LE-SAVE | CanClassify; mode "leftearly"; 1 student; date <= Today(); time parses h:mm AM/PM and not in the future; reason non-blank; not saving/loading | panel -> "Save left early" | AbsencesScreen | `btnAbsLeSaveV.OnSelect` (direct) | Attendance by Student + Service + Date; `w.Attendance` | not enrolled / not school day / locked / live absent -> Blocked, no write; live present -> partial Patch left-early fields (audit Update); none or deleted -> Patch present row Source Office + left-early fields (audit Create) | Present path: Left Early, Left Early At, Left Early Reason. Create path: Record Key, Date, Student, Service, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio, Present=true, Is Deleted=false, Source=Office, Absence Classification=blank, Absence Reason=blank, Classified By=blank, Classified On=blank, Parent Reported Absent=false, Source Report ID=blank, Notice Received On=blank, Left Early, Left Early At, Left Early Reason. Audit row | Title "Left early recorded · student · date · h:mm"; Lines: Student, Date, Before, Present (`w.Present`), Left Early (`w.'Left Early'`), Left at (`w.'Left Early At'`), Reason (`w.'Left Early Reason'`), Source (`Text(w.Source)`), Teacher, Record key (`w.'Record Key'`), Audit | `conAbsReceiptV`; Screen1 `1*` |
| A-ABS-ADD-CANCEL | panel open | "Cancel" | AbsencesScreen | `btnAbsAddCancelV.OnSelect` | N/A | mode ""; inputs reset; receipt "Cancelled · nothing was changed" | N/A | Title | `conAbsReceiptV` |
| A-GRID-LOAD (changed) | Staff ready | Screen1 visit / Reload | Screen1 | `btnAttLoadEngine.OnSelect` | Attendance.Attendance | colMonthAtt gains LeftEarly, LeftEarlyAt | N/A | N/A | `btnAttCell.Text` "1*"; Tooltip; `lblAttDayStatus` |
| A-GRID-UNDO-BLOCK | cell Letter P and LeftEarly | tap the 1* cell / Day view Undo | Screen1 | `btnAttCell` (DisplayMode Disabled), `btnAttDayClear` (Disabled), `btnAttSaveEngine` guard | colMonthAtt | no write; if reached, Blocked message | N/A | Blocked message "left early was recorded by the office and can't be undone here" | `lblAttReceipt` |
| A-NAV-TRANSPORT | CanClassify | "Transportation" | Screen1, StudentsScreen, AbsencesScreen, TransportScreen | `btn{Att,Stu,Abs,Trn}NavTransport.OnSelect: =Navigate(TransportScreen)` | N/A | TransportScreen shown | N/A | N/A | TransportScreen header (current button teal) |
| A-TRN-CAMPUS | Admin (StudentCampusLock = ZeroGuid) | `ddTrnCampus` | TransportScreen | `ddTrnCampus.OnChange` | Campuses.Campus | varTrnCampusId; mode cleared; reload ST, day, banner | N/A | N/A | `lblTrnDayCount`, `lblTrnStuListTitle` campus name |
| A-TRN-TAB-DAILY / A-TRN-TAB-STUDENTS | CanClassify | "Daily" / "Students" | TransportScreen | `btnTrnHdrDaily.OnSelect`, `btnTrnHdrStudents.OnSelect` | N/A | varTrnView "daily" (reload day + banner) / "students" | N/A | N/A | `conTrnDailyView.Visible` / `conTrnStuView.Visible` |
| A-TRN-STU-LOAD | CanClassify, campus | OnVisible, campus change, after ST writes (local patch) | TransportScreen | `btnTrnStuLoadEngine.OnSelect` | 'Student Transportation'.'Student Transportation' (StId) | colTrnStAll, colTrnCampEnr, colTrnCampStu | N/A | N/A | `galTrnStuList` |
| A-TRN-LOAD-DAY | CanClassify, campus, date | OnVisible, date change, Reload, tab, banner chip | TransportScreen | `btnTrnLoadEngine.OnSelect` | StudentId per row; Daily Transport `LogId` | colTrnDaily (Pick pre-filled), varTrnIsSchoolDay, varTrnDayReason | N/A | N/A | `galTrnDayList`, `lblTrnDayCount` |
| A-TRN-PICK | school day, date <= today, row unsaved (LogId = ZeroGuid), not saving | status buttons on an unsaved row | TransportScreen | `btnTrnOpt*.OnSelect` (first branch) | colTrnDaily by StudentId | `Patch(colTrnDaily, LookUp(colTrnDaily, StudentId = ThisItem.StudentId), {Pick: "<status>"})` (staging only, no Dataverse write) | N/A (local staging) | N/A | active button; `lblTrnDayStatus` "Not confirmed · <status> (chosen, not saved)"; `btnTrnConfirm.Text` count |
| A-TRN-CONFIRM-DAY | CanClassify; school day; date <= today; >= 1 row; no row with blank Pick; >= 1 row to write; not saving/loading | "Confirm day (n)" | TransportScreen | `btnTrnConfirm.OnSelect` -> `btnTrnSaveEngine.OnSelect` (scope "day") then `btnTrnBannerEngine` | 'Daily Transport' by Log Key `KeyBase & "|" & Text(d, "yyyy-mm-dd")`; returned `wr.'Daily Transport'` | per work row: live LookUp by Log Key -> Patch(Coalesce(live, Defaults)) ; audit Create/Update; colTrnDaily row updated from `wr` | Daily Transport: Summary, Student, Campus, Date, Transport Status, Confirmed On, Confirmed By, Log Key. Audit row per write | Title "Day confirmed · date · n saved (c created, u updated), f failed"; lines: Operation, Date, Campus, Confirmed by (`wr`), one line per student "status (`wr`) · created/updated · audit" | `conTrnReceipt`; `lblTrnDayStatus` "Confirmed by X at h:mm · status"; banner recount |
| A-TRN-ROW-CHANGE | row saved (LogId <> ZeroGuid); clicked status <> SavedStatus; school day; not saving | status button on a confirmed row | TransportScreen | `btnTrnOpt*.OnSelect` (second branch) -> `btnTrnSaveEngine` (scope "row") | same Log Key; same `LogId` | Patch existing row Transport Status + Confirmed On/By; audit Update | Daily Transport: Transport Status, Confirmed On, Confirmed By (Summary, Student, Campus, Date, Log Key rewritten with identical values) | Title "Updated · student · date · new (was old)"; lines Student, Date, Before (live), Now (`wr`), Confirmed by, Confirmed at, Log key, Audit | `conTrnReceipt`; `lblTrnDayStatus` |
| A-TRN-BANNER | CanClassify, campus | OnVisible, campus change, Daily tab, after Confirm day | TransportScreen | `btnTrnBannerEngine.OnSelect` | Daily Transport (fresh query) | colTrnDays (last 10 school days, Missing per day) | N/A | N/A | `lblTrnBannerTitle`, `galTrnBannerDays` |
| A-TRN-BANNER-OPEN | chip shown | day chip | TransportScreen | `btnTrnBannerDay.OnSelect` | colTrnDays.D | varTrnDate = D; Reset(dpTrnDate); reload day | N/A | N/A | `dpTrnDate`, `lblTrnDayCount` date |
| A-TRN-SHOW-ENDED | Students tab | "Show ended" | TransportScreen | `chkTrnShowEnded.OnCheck/OnUncheck` | N/A | varTrnShowEnded | N/A | N/A | `galTrnStuList.Items` |
| A-TRN-STU-ADD | mode "add"; 1 student without active row; start date set; pattern chosen; not saving | "Add student" -> panel -> "Add transportation" | TransportScreen | `btnTrnStuSave.OnSelect` (branch `varTrnStuMode = "add"`) | new 'Student Transportation' row, `wr.'Student Transportation'` | guard: still no active row for the student (live query) -> Patch Defaults; audit Create; Collect into colTrnStAll; varTrnSelStId = new ID | Student Transportation: Summary, Student, Campus, Start Date, Usual Pattern, Source=Manual, Note. Audit row | Title "Transportation added · student"; lines Student, Key, Pattern (`wr`), Start (`wr`), End "ongoing", Source (`wr`), Note (`wr`), Audit | `conTrnReceipt`; new row highlighted in `galTrnStuList` |
| A-TRN-STU-CHANGE | mode "change"; selected active row; pattern chosen; not saving | row "Change pattern" -> panel -> "Save pattern" | TransportScreen | `btnTrnStuSave.OnSelect` (branch `"change"`) | StId = varTrnSelStId (live LookUp) | Patch Usual Pattern + Note; audit Update; Patch colTrnStAll | Usual Pattern, Note. Audit row | Title "Pattern saved · student · new (was old)"; lines Student, Pattern before/after (`wr`), Note (`wr`), Audit | `conTrnReceipt`; `lblTrnStuRowMeta` |
| A-TRN-STU-END | mode "end"; selected active row; end date >= start; not saving | row "End transportation" -> panel -> "End transportation" | TransportScreen | `btnTrnStuSave.OnSelect` (branch `"end"`) | StId = varTrnSelStId (live LookUp) | Patch End Date; audit Update; Patch colTrnStAll (Active recomputed) | End Date. Audit row | Title "Transportation ended · student · end date"; lines Student, Start, End (`wr`), Pattern, Audit | `conTrnReceipt`; `lblTrnStuRowMeta` "Sep 1, 2026 - Oct 6, 2026"; row hidden unless Show ended once the date passes |
| A-TRN-STU-CANCEL | panel open | "Cancel" | TransportScreen | `btnTrnStuCancel.OnSelect` | N/A | mode ""; varTrnSelStId Blank; inputs reset | N/A | N/A | panel shows guidance |

Opposing pairs: none (not arithmetic; status buttons are explicit literal values, each guarded by its own literal).
No Directional / Compound tables. No continuation contracts (Add transportation does not feed a later action
automatically; the new row is only highlighted).

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-ABS-ADD-SAVE | per-day `wr` -> colAbsLog -> colAbsReceiptLines -> `galAbsReceiptV`; title -> `lblAbsReceiptTitleV` | Attendance row (`wr.'Absence Classification'`, `wr.Present`) | Classify list `galAbsListV` (status filter Excused/Unexcused/All); Screen1 grid | live/defaults -> `wr.Attendance` = audit Entity ID = colAbsLog.AttId | `Select(btnAbsLoadEngine)` after the loop when >= 1 created; Screen1 reloads on visit | N/A - receipt lists each day; list sorted by date |
| A-LE-SAVE | `w` -> varAbsReceipt + colAbsReceiptLines | Attendance row (`w.'Left Early'`, `w.'Left Early At'`) | Screen1 grid cell `1*`; TransportScreen attendance text | `w.Attendance` = audit Entity ID | Screen1 / TransportScreen reload on visit | N/A |
| A-TRN-CONFIRM-DAY | `wr` -> colTrnLog -> colTrnReceiptLines -> `galTrnReceipt`; title `lblTrnReceiptTitle` | Daily Transport row by Log Key | `galTrnDayList` row status; banner | Log Key = `wr.'Log Key'`; `wr.'Daily Transport'` -> colTrnDaily.LogId = audit Entity ID | `Patch(colTrnDaily, r, {...from wr})` per success; `Select(btnTrnBannerEngine)` re-queries Daily Transport | N/A - row keyed by StudentId, list sorted by name |
| A-TRN-ROW-CHANGE | same | same | same row | same Log Key and LogId | same Patch of colTrnDaily | N/A |
| A-TRN-STU-ADD | `wr` -> varTrnReceipt + colTrnReceiptLines | Student Transportation row | `galTrnStuList`; Daily list after Daily tab reload | `wr.'Student Transportation'` -> colTrnStAll.StId -> varTrnSelStId | `Collect(colTrnStAll, {...from wr})`; Daily tab reloads from colTrnStAll | `varTrnSelStId` highlights the row (Fill ColorInfoBg) |
| A-TRN-STU-CHANGE | `wr` -> receipt | Student Transportation row | `galTrnStuList` row meta; Daily list Pattern | varTrnSelStId = live.StId = wr.StId | `Patch(colTrnStAll, LookUp(colTrnStAll, StId = id), {Pattern, Note})` | row stays highlighted |
| A-TRN-STU-END | `wr` -> receipt | Student Transportation row | `galTrnStuList` row meta; Daily list membership | same | `Patch(colTrnStAll, ..., {EndDate, Active})` | row highlighted (visible while active or Show ended) |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| A-ABS-ADD-SAVE | Present | Changed | none/deleted row | `Present: false` | per-day line "Created · <class>" (only when `wr` returned) | Screen1 cell 0 |
| A-ABS-ADD-SAVE | Absence Classification | Changed | `varAbsAddClass` | `Switch(cls, "Excused", ...Excused, "Unexcused", ...Unexcused)` | "Classification: " & `g.NewClass` (from `Text(wr.'Absence Classification')`) | badge in `galAbsListV` |
| A-ABS-ADD-SAVE | Absence Reason | Changed | `varAbsAddReasonId` (Excused) / blank | `If(cls = "Excused", rsn, Blank())` | NewClass suffix "(Illness)" from `wr.'Absence Reason'.Name` | list reason |
| A-ABS-ADD-SAVE | Classified On / By | Changed | Now(), CurrentUserRow | Patch | "Classified by" line `g.ByName · g.OnText` from `wr` | list note line |
| A-ABS-ADD-SAVE | Notes | Changed | `txtAbsAddNoteV` | `Notes: note` | "Note" line from `g.ReasonName` (carries `wr.Notes`) | N/A |
| A-ABS-ADD-SAVE | Source | Changed | - | `'Source (Attendance)'.Office` | per-day line text "Source Office" via Operation line | `lblAbsRowSrcV` "Office" |
| A-ABS-ADD-SAVE | Record Key, Date, Student, Service, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio, Is Deleted | Changed | enrollment segment `seg`, term `t`, day `d` | Patch | "teacher <name>" in day line; Record Key in audit | Screen1 grid under that teacher |
| A-ABS-ADD-SAVE | Notice Received On, Parent Reported Absent, Source Report ID, Left Early(+At, Reason) | Changed (cleared) | reused deleted row values | set Blank()/false | N/A (Operation line "no parent notice") | `lblAbsRowSrcV` shows no "Reported" text |
| A-ABS-ADD-SAVE | skipped days (present / absent rows) | Preserved | live row | not written | "Skipped · <reason>" line | unchanged grid cell |
| A-LE-SAVE | Left Early / Left Early At / Left Early Reason | Changed | true, DateTime(d + tm), why | Patch | lines from `w` | Screen1 `1*`, tooltip time |
| A-LE-SAVE | Present, Source, Notes, Teacher etc. (present path) | Preserved | live row | omitted from partial Patch | "Present: Yes (1)", "Source: <Text(w.Source)>" from `w` | grid 1* |
| A-LE-SAVE | Present / Source / snapshots (create path) | Changed | seg, t, d | Patch Coalesce(live, Defaults) | Present + Source lines from `w` | grid 1* |
| A-TRN-CONFIRM-DAY | Transport Status | Changed | colTrnDaily.Pick | `st` from literal Switch | per-student line `Text(wr.'Transport Status')` | `lblTrnDayStatus` |
| A-TRN-CONFIRM-DAY | Confirmed On / Confirmed By | Changed | Now(), CurrentUserRow | Patch | "Confirmed by" line `wr.'Confirmed By'.'Full Name'` + time | `lblTrnDayStatus` |
| A-TRN-CONFIRM-DAY | Log Key, Summary, Student, Campus, Date | Changed (create) / rewritten identical (update) | KeyBase, StRec.Student, StRec.Campus, d | Patch | Log key in row-scope receipt | banner Missing count |
| A-TRN-CONFIRM-DAY | Owner, Note | Preserved | Dataverse default (creating user) / existing | omitted | N/A | N/A |
| A-TRN-ROW-CHANGE | Transport Status, Confirmed On, Confirmed By | Changed | clicked literal; Now(); CurrentUserRow | Patch existing (live by Log Key) | Before (live) / Now (`wr`) / Confirmed by / at lines | `lblTrnDayStatus` |
| A-TRN-STU-ADD | Summary, Student, Campus, Start Date, Usual Pattern, Source, Note | Changed | KeyBase, cbo selection, dpTrnStuStart, rdoTrnStuPattern, Manual, txtTrnStuNote | Patch Defaults | lines from `wr` | `lblTrnStuRowName/Meta` |
| A-TRN-STU-ADD | End Date | Preserved (blank) | - | omitted | "End: ongoing" | meta "ongoing" |
| A-TRN-STU-CHANGE | Usual Pattern, Note | Changed | rdoTrnStuPattern, txtTrnStuNote | Patch live | before/after lines (`live`, `wr`) | meta |
| A-TRN-STU-CHANGE | Start/End Date, Source, Student | Preserved | live | omitted | Start line from `wr` | meta |
| A-TRN-STU-END | End Date | Changed | dpTrnStuEnd | Patch live | "End: " & Text(wr.'End Date') | meta |
| A-TRN-STU-END | Pattern, Start, Source, Note | Preserved | live | omitted | Pattern line from `wr` | meta |

## Functional Test Matrix

Fixtures (Dev): today = Tue 2026-10-06. Campus CW = Chatsworth; office O "Ortiz, Olga" (Attendance Office, CW); admin M
(System Admin, no campus); teacher A "Smith, Ana" (CW). Students at CW, enrolled with A from 2026-08-17 (open):
"Doe, Jane" STU-000123 key CW-1001; "Roe, Max" STU-000200 key CW-1002; "Kim, Ida" STU-000210 key CW-1003;
"Kim, Pat" STU-000220 key CW-1005 (no Student Transportation row). "Poe, Ann" CW-1004 enrollment ended 2026-09-30.
Term Q1 2026-08-17..2026-10-30 (Campus blank). Calendar Exception 2026-09-07 Holiday "Labor Day" (blank campus).
August 2026 locked at CW; Sep/Oct unlocked. Absence Reasons: Illness, Other. Student Transportation (CodeMetro, Round
trip, start 2026-08-17, open): Jane, Max, Ida, Ann; "Lee, Sam" CW-1006 ended 2026-09-30.
Attendance: Jane Tue 9/8 Present (teacher); Jane Wed 9/9 absent (parent report); Jane Thu 9/10 deleted row;
Jane Mon 10/5 Present (teacher); Max Mon 10/5 absent; Ida Mon 10/5 Present; Max Thu 10/1 and Fri 10/2 Present.
Daily Transport: complete for Jane and Ida on 9/23 .. 10/2; Max has rows except 10/1 and 10/2.

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-ABS-ADD-OPEN | O on Absences, classify view | Press Add absence | Panel opens in the right column; Excused selection cleared | title "Add absence"; `cboAbsAddStuV` lists CW students (Jane, Max, Ida, Pat; not Oxnard students) | Narrow (<1024): list hides, panel shows |
| S-ABS-ADD-RANGE | fixtures | Jane, From Fri 9/4, To Thu 9/10, Excused, Illness, note "Mom called" -> Save absence | 9/4 created (no row); 9/5, 9/6, 9/7 non-school ignored; 9/8 skipped (present); 9/9 skipped (already absent); 9/10 created by reusing the deleted row (Is Deleted false). Both rows Present false, Source Office, Excused/Illness, Classified By O, Notes "Mom called", Notice Received On blank, Record Key 20260904/20260910|STU-000123|SPED. 2 Audit Create rows | Receipt title "Add absence · Doe, Jane · Sep 4 – Sep 10, 2026 · 2 created, 2 skipped, 0 failed · 3 non-school day(s) ignored"; lines "Fri Sep 4 -> Created · Excused (Illness) · teacher Smith, Ana · audit Create written", "Tue Sep 8 -> Skipped · teacher marked present - use Needs a decision / ask the teacher", "Wed Sep 9 -> Skipped · already absent", "Thu Sep 10 -> Created · ... · reused deleted row ..."; classify list (Excused) shows both; Screen1 Sep cells green 0 | All days skipped -> Kind "Failed", panel stays open |
| S-ABS-ADD-UNEXCUSED | fixtures | Max, From Tue 10/6 (To blank), Unexcused, no note -> Save absence | One row 10/6 Present false, Unexcused, Reason blank, Notes "" | Receipt "1 created"; Classification "Unexcused"; Note "None" | To blank = same day |
| S-ABS-ADD-LOCKED | Aug 2026 locked | Jane From Mon 8/31 To Tue 9/1, Unexcused | 8/31 skipped "month locked"; 9/1 created | lines "Mon Aug 31 -> Skipped · month locked" | N/A |
| S-ABS-ADD-INVALID | panel open | (a) no student; (b) Excused without reason; (c) To before From; (d) To = today+91; (e) span 62 days | Save absence disabled | `lblAbsAddCheckV` text names the problem; `btnAbsAddSaveV.DisplayMode` Disabled | Not enrolled on a day -> "Skipped · not enrolled" line |
| S-LE-OPEN | O on Absences | Press Left early | Panel in leftearly mode | title "Left early"; date label "Date *"; time + "Reason *" fields; To/class/reason hidden | N/A |
| S-LE-PRESENT | Jane Mon 10/5 Present (teacher) | Jane, 10/5, "1:30 PM", "Doctor appointment" -> Save left early | Same row: Left Early true, Left Early At 2026-10-05 13:30, Reason; Present true; Source Teacher unchanged; Audit Update | Receipt "Left early recorded · Doe, Jane · Mon Oct 5, 2026 · 1:30 PM"; lines Before "Present (marked by the teacher)", Present "Yes (1)", Source "Teacher", Audit "Update written" | Same student/day again with 2:00 PM -> overwrites time (Update) |
| S-LE-NOROW | Kim, Pat 10/5 not marked (enrolled) | Pat, 10/5, "11:15 AM", "Fever" | New row Present true, Source Office, enrollment snapshots, left-early fields; Audit Create | lines Before "Not marked", Present "Yes (1)", Source "Office" | Deleted row on that day -> reused, Before "Deleted row (reused)" |
| S-LE-ABSENT | Jane Wed 9/9 absent | Jane, 9/9, "10:00 AM", "x" | No write | Blocked receipt "Not saved · Doe, Jane · Wed Sep 9, 2026 · the day is marked absent; left early is only for present days" | Not a school day (Sat) -> Blocked "not a school day"; locked month -> Blocked |
| S-LE-INVALID | panel open | time "13:30" or "1:30"; reason blank; date tomorrow (picker max today); today with time later than now | Save left early disabled | `lblAbsAddCheckV` explains | N/A |
| S-ABS-CLASSIFY-REGRESSION | Jane 9/14 unclassified | Excused… -> Illness -> Save as Excused; Unexcused on another row | Unchanged; while Excused… is open the Add bar/panel are hidden; title "Mark as Excused" | `conAbsReceiptV`, `conAbsAddBarV.Visible` false | Cancel Excused -> Add bar returns |
| S-GRID-MARKER | after S-LE-PRESENT | Teacher A opens Oct 2026 | Jane 10/5 cell text "1*"; legend contains "1* left early (office)"; tooltip "... Present – left early 1:30 PM (office)"; Day view status same | `btnAttCell.Text`, `lblAttLegend`, `lblAttDayStatus` | Plain present cell still "1" |
| S-GRID-ABSENCE-VISIBLE | after S-ABS-ADD-RANGE | Teacher A opens Sep 2026 | 9/4 and 9/10 cells "0" green | `btnAttCell` Fill ColorExcused | N/A |
| S-GRID-UNDO-BLOCK | Jane 10/5 left early | Teacher A taps the 1* cell; Day view | Cell disabled (no confirm); Day view Undo disabled; save engine with Target "clear" on it -> Blocked "left early was recorded by the office and can't be undone here" | `btnAttCell.DisplayMode`, `btnAttDayClear.DisplayMode`, `lblAttReceipt` | N/A |
| S-GRID-UNDO-REGRESSION | Ida 10/5 plain 1 | Teacher tap 1 -> Confirm undo | Soft delete as before | `lblAttReceipt` "Undone · ..." | N/A |
| S-NAV-TRANSPORT | O on each of Screen1, Students, Absences | Press Transportation | TransportScreen opens, its Transportation button teal | `btnTrnNavTransport` current | N/A |
| S-NAV-ROLE | Teacher A | Look at headers | No nav row (existing), so no Transportation button; direct navigation -> `conTrnDenied` | `conTrnDenied.Visible` | Read-only same |
| S-TRN-TABS | O on TransportScreen | Students, then Daily | Views swap; Daily default on entry | `conTrnStuView.Visible`, `conTrnDailyView.Visible` | N/A |
| S-TRN-CAMPUS | O | Look at campus | `ddTrnCampus` disabled showing Chatsworth | DisplayMode | Admin M picks Oxnard -> lists reload for Oxnard |
| S-TRN-DAILY-LIST | fixtures, after S-LE-PRESENT | O picks date Mon 10/5 | Rows Jane, Max, Ida (Ann not listed: enrollment ended 9/30; Lee ended); Jane "Attendance: Left early 1:30 PM", Pick Drop off only (pre-filled); Max "Absent", Pick No transportation (pre-filled); Ida "Present", Pick blank "Not confirmed · choose a status" | `lblTrnDayMeta`, `lblTrnDayStatus`, active buttons, `lblTrnDayCount` "3 students with transportation · Mon Oct 5, 2026 · 0 confirmed, 3 not confirmed" | Not marked attendance -> "Not marked" |
| S-TRN-CONFIRM-DISABLED | S-TRN-DAILY-LIST | Look at Confirm day | Disabled because Ida has no status | `btnTrnConfirm.DisplayMode`; `lblTrnConfirmHint` "1 row(s) still need a status ..." | N/A |
| S-TRN-CONFIRM | same | Ida -> Round trip; Confirm day (3) | 3 Daily Transport rows: Log Keys CW-1001|2026-10-05 (Drop off only), CW-1002|2026-10-05 (No transportation), CW-1003|2026-10-05 (Round trip); Confirmed By O, Confirmed On now, Campus CW, Date 10/5; 3 Audit Create | Receipt "Day confirmed · Mon Oct 5, 2026 · 3 saved (3 created, 0 updated), 0 failed"; rows "Confirmed by Ortiz, Olga at 3:05 PM · Round trip"; button "All confirmed" disabled; banner no longer counts 10/5 | N/A |
| S-TRN-UPSERT | another user saved Jane 10/5 after O loaded | O Confirm day | Jane's existing row updated (no duplicate); outcome "updated"; Audit Update | receipt line "Doe, Jane -> Drop off only · updated" | Patch failure -> "FAILED · not saved" line, row stays Not confirmed |
| S-TRN-ROW-CHANGE | after S-TRN-CONFIRM | Jane -> Round trip | Same row (same Log Key / ID): Transport Status Round trip, Confirmed On updated; Audit Update reason "Changed after confirmation" | Receipt "Updated · Doe, Jane · Mon Oct 5 · Round trip (was Drop off only)"; status line shows new time | Clicking the already-saved status does nothing |
| S-TRN-BANNER | fixtures (10/5 not confirmed yet) | Open Daily | Last 10 school days = 9/23..10/6; unconfirmed: 10/1 (Max), 10/2 (Max), 10/5 (all), 10/6 (all) -> "4 school days not confirmed" | `lblTrnBannerTitle`; chips "Tue 10/6 (3)", "Mon 10/5 (3)", "Fri 10/2 (1)", "Thu 10/1 (1)"; `lblTrnDeadline` | Chip "Thu 10/1 (1)" -> date 10/1 loads |
| S-TRN-NONSCHOOL | O | pick Sat 10/3 | Count text "Not a school day at Chatsworth – weekend. Nothing to confirm."; status buttons + Confirm disabled | `lblTrnDayCount`, DisplayModes | Labor Day 9/7 -> "Holiday – Labor Day" |
| S-TRN-STU-LIST | fixtures | Students tab | Active rows Jane, Max, Ida, Ann ("Round trip · Aug 17, 2026 - ongoing · CodeMetro"); Show ended adds Lee ("... - Sep 30, 2026"), grey fill | `galTrnStuList`, `lblTrnStuRowMeta` | N/A |
| S-TRN-STU-ADD | Pat has no row | Add student -> Pat, start 10/6, Drop off only, note "New in October" -> Add transportation | ST row: Summary "CW-1005 - transportation", Student Pat, Campus CW, Start 10/6, Drop off only, Source Manual, Note; Audit Create | Receipt "Transportation added · Kim, Pat"; row highlighted; picker no longer lists Pat | N/A |
| S-TRN-STU-ADD-INVALID | add mode | no student / no start date | Save disabled; picker never lists Jane (active row) | `lblTrnStuCheck` | Another user added Pat meanwhile -> Blocked "already has active transportation" |
| S-TRN-STU-CHANGE | Jane active | Change pattern -> Pick up only, note "Grandma drops off" -> Save pattern | ST Jane Usual Pattern Pick up only, Note; Audit Update | Receipt "Pattern saved · Doe, Jane · Pick up only (was Round trip)"; meta | Ended row: Change/End buttons disabled |
| S-TRN-STU-END | Max active | End transportation -> 10/6 -> End transportation | End Date 10/6; Audit Update; still listed today; 10/7 Daily list excludes Max | Receipt "Transportation ended · Roe, Max · Oct 6, 2026"; meta "Aug 17, 2026 - Oct 6, 2026" | End before start -> disabled |
| S-TRN-ROLE | Teacher A navigates directly | Open TransportScreen | Denied panel only; no views | `conTrnDenied` | N/A |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| cboAbsAddStuV | lblAbsAddStuV `="Student *"` | conAbsAddPanelV |
| dpAbsAddFromV | lblAbsAddFromV `=If(varAbsAddMode = "leftearly", "Date *", "From date *")` | conAbsAddPanelV |
| dpAbsAddToV | lblAbsAddToV `="To date (blank = same day)"` | conAbsAddPanelV |
| rdoAbsAddClassV | lblAbsAddClassV `="Classification *"` | conAbsAddPanelV |
| ddAbsAddReasonV | lblAbsAddReasonV `="Absence reason *"` | conAbsAddPanelV |
| txtAbsLeTimeV | lblAbsLeTimeV `="Time left * (h:mm AM/PM)"` | conAbsAddPanelV |
| txtAbsAddNoteV | lblAbsAddNoteV `=If(varAbsAddMode = "leftearly", "Reason *", "Note (optional)")` | conAbsAddPanelV |
| ddTrnCampus | lblTrnCampus `="Campus"` | conTrnHdrTabs |
| dpTrnDate | lblTrnDate `="Date"` | conTrnDateField |
| cboTrnStuPick | lblTrnStuPick `="Student *"` | conTrnStuPanel |
| dpTrnStuStart | lblTrnStuStart `="Start date *"` | conTrnStuPanel |
| rdoTrnStuPattern | lblTrnStuPattern `="Usual pattern *"` | conTrnStuPanel |
| txtTrnStuNote | lblTrnStuNote `="Note (optional)"` | conTrnStuPanel |
| dpTrnStuEnd | lblTrnStuEnd `="End date *"` | conTrnStuPanel |

## Layout Budget Contracts

| Screen / container | Branch / screen-width source | Horizontal total-width arithmetic | Vertical height arithmetic | Protected controls |
| --- | --- | --- | --- | --- |
| Nav rows (all 4 screens) | root Width; wrap below ~526 | 16+110+8+110+8+110+8+140+16 = 526 (Abs/Trn, padded nav); Att/Stu header padding 16+16 same | 44 (>=640) / 96 two rows (<640) | Transportation |
| conAbsDecideV detail column | >=1024: (W-8)/3; 1024 -> 339 outer, 307 inner; <1024 full width | bar 130+8+110 = 248 <= 307; actions 150+8+100 = 258 <= 307 | idle 16+28+8+60+8+44+16 = 180; absence 16+28+8+44+8+430+16 = 550 (Excused 612); leftearly 16+28+8+44+8+368+16 = 488 | Save absence / Save left early |
| conAbsAddPanelV (gap 4) | same | inputs stretch | absence (12 children): 5 label/input pairs 5*54 = 270 + check 72 + actions 44 = 386 + 11*4 = 430; Excused (14 children): 386+54 = 440 + 13*4 = 492; leftearly (10 children): 4*54 = 216 + 72 + 44 = 332 + 9*4 = 368 | Save, Cancel |
| conTrnHdrTabs | conTrnRoot.Width < 640 | 16+130+8+130+8+56+8+220+16 = 592 <= 640 | 60 / wrap 112 (<640) | Daily, Students, campus |
| galTrnDayList row | conTrnRoot.Width < 1024 vertical / >= 1024 horizontal | >=1024: row inner 1024-32-16-16 = 960 >= info 300 + 8 + options 110+8+130+8+120+8+160 = 544 -> 852 | desktop 8 + max(22+4+18+4+18 = 66, 44) + 8 = 82 <= 88; narrow 8 + info (22+4+36+4+36 = 102) + 8 + opts (44+8+44 = 96) + 8 = 222 <= 224 (TemplateSize) | four status buttons |
| conTrnBanner | <640 | chips gallery scrolls horizontally | 12 + (44/24) + 4 + 18 + [4 + 44] + 12 | day chips |
| conTrnDayPanel | <640 | Confirm 190 + hint fill | 16+44+8+58+8+(54/36)+8+[gallery+8]+(88/44)+16 | Confirm day |
| galTrnStuList row | <640 / >= 640 | actions 150+8+170 = 328 <= 629 (1024 list inner) | desktop 8+22+4+36+4+44+8 = 126 <= 130; phone 8+40+4+54+4+96+8 = 214 <= 216 | Change pattern, End transportation |
| conTrnStuPanel (gap 4) | >= 1024 detail column 307 inner at 1024 | actions 170+8+100 = 278 <= 307 | idle 32+86; add 32+442; change 32+376; end 32+254 | Save, Cancel |

(Exact per-branch formulas are in the screen briefs; the briefs are authoritative where they refine these sums.)

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| --- | --- | --- | --- | --- | --- |
| TransportScreen | conTrnRoot (sole top-level child) | AutoLayout | `conTrnRoot.Width: =Parent.Width` | `conTrnRoot.Height: =Parent.Height` | LayoutOverflowY Scroll; LayoutMinWidth/Height 0 |
| AbsencesScreen | conAbsRoot (existing) | AutoLayout | unchanged `=Parent.Width` | unchanged `=Parent.Height` | Scroll (unchanged) |
| Screen1 | conAttRoot (existing) | AutoLayout | unchanged | unchanged | Scroll (unchanged) |
| StudentsScreen | conStuRoot (existing) | AutoLayout | unchanged | unchanged | Scroll (unchanged) |

## Temporal Ordering Contracts

None. No time-of-day ordering: Left Early At is a typed DateTime shown, not sorted; lists sort by student name or date.

## Working Directory

C:\src\aaca-attendance\app

Plan artifacts: C:\src\aaca-attendance\docs\app-builds\build-9-transport\

## Discovery Summary

- Existing screens: Screen1 (Att), StudentsScreen (Stu), AbsencesScreen (Abs). Layout: AutoLayout, one scroll root each.
- Data sources: Attendance (+ 'Left Early', 'Left Early At', 'Left Early Reason'), 'Student Transportation' (NEW),
  'Daily Transport' (NEW; its Student Transportation lookup is NOT exposed - not used), Enrollments, Students, Terms,
  'Calendar Exceptions', 'Month Locks', 'Absence Reasons', Campuses, Users, 'Audit Events'.
- Controls (all described in the packet, all already used in the app): GroupContainer, ModernText, ModernButton,
  Classic/Button, Gallery, ModernDropdown, ModernCombobox, ModernDatePicker, ModernTextInput, ModernRadio,
  ModernCheckbox. No new control types.

## Dispatch

Compile/dispatch order matters: TransportScreen must exist before the nav buttons that `Navigate(TransportScreen)`
compile. Wave 1: TransportScreen + AbsencesScreen. Wave 2 (or same wave if the orchestrator compiles TransportScreen
first): Screen1, StudentsScreen.

| Action | Screen | Target File | YAML Key | Name Prefix | Screen Brief |
| --- | --- | --- | --- | --- | --- |
| Create | Transportation | `C:\src\aaca-attendance\app\TransportScreen.pa.yaml` | TransportScreen | Trn | `C:\src\aaca-attendance\docs\app-builds\build-9-transport\TransportScreen.screen-plan.md` |
| Modify | Absences | `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml` | AbsencesScreen | Abs (new: AbsAdd / AbsLe / AbsNavTransport) | `C:\src\aaca-attendance\docs\app-builds\build-9-transport\AbsencesScreen.screen-plan.md` |
| Modify | Attendance | `C:\src\aaca-attendance\app\Screen1.pa.yaml` | Screen1 | Att (new: AttNavTransport) | `C:\src\aaca-attendance\docs\app-builds\build-9-transport\Screen1.screen-plan.md` |
| Modify | Students | `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml` | StudentsScreen | Stu (new: StuNavTransport) | `C:\src\aaca-attendance\docs\app-builds\build-9-transport\StudentsScreen.screen-plan.md` |

## App Changes

### Before builders

1. `App.Formulas`: append at the end (after the `ParentReportCutover = ...;` line, same 6-space indent):

```
      // ---------- Transportation (build 9) ----------
      TransportStatusOptions = ["Round trip", "Drop off only", "Pick up only", "No transportation"];
      TransportPatternOptions = ["Round trip", "Drop off only", "Pick up only"];
```

2. `App.OnStart`: change the final line `Set(varAbsMeReceipt, {Kind: "", Title: "", Body: ""})` to end with `;` and
   append exactly (6-space indent):

```
      Set(varAbsAddMode, "");
      Set(varAbsAddClass, "");
      Set(varAbsAddReasonId, ZeroGuid);
      Set(varAbsAddReasonId, Blank());
      Set(varAbsAddErr, "");
      Set(varTrnView, "daily");
      Set(varTrnCampusId, If(StudentCampusLock <> ZeroGuid, StudentCampusLock, !IsBlank(CurrentStaff.Campus), CurrentStaff.Campus.Campus, Coalesce(First(Sort(Campuses, Name, SortOrder.Ascending)).Campus, ZeroGuid)));
      Set(varTrnDate, Today());
      Set(varTrnIsSchoolDay, false);
      Set(varTrnDayReason, "");
      Set(varTrnLoading, false);
      Set(varTrnSaving, false);
      Set(varTrnLoadError, "");
      Set(varTrnShowEnded, false);
      Set(varTrnStuMode, "");
      Set(varTrnSelStId, ZeroGuid);
      Set(varTrnSelStId, Blank());
      Set(varTrnReq, {Scope: ""});
      Set(varTrnReceipt, {Kind: "", Title: ""});
      ClearCollect(colTrnReceiptLines, {Label: "", Value: ""});
      Clear(colTrnReceiptLines);
      ClearCollect(colTrnWork, {StudentId: ZeroGuid, Status: ""});
      Clear(colTrnWork);
      ClearCollect(colTrnLog, {StudentName: "", Before: "", Status: "", ByName: "", OnText: "", LogKey: "", Outcome: "", AuditOk: false});
      Clear(colTrnLog)
```

The App compile needs no screen to exist (no screen names referenced).

### After builders

None (StartScreen stays `=Screen1`).

## Editor State Changes

`_EditorState.pa.yaml` final `ScreensOrder`:

```
EditorState:
  ScreensOrder:
    - Screen1
    - StudentsScreen
    - AbsencesScreen
    - TransportScreen
```

`ComponentDefinitionsOrder`: none (no components).
