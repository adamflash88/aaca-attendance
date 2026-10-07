# Canvas App Plan

## Mode

EDIT (build 10 - NEW StaffScreen: staff list, Add teacher, Edit, Transfer class (bulk), Retire / Reactivate; Staff
nav button on the four existing screens; active-only teacher pickers; StaffPending sign-in state on Screen1)

## Requirements

Source of truth: `C:\src\aaca-attendance\docs\app-builds\build-10-staff\canvas-app-requirements.md` (immutable).

## Original Request Capability Inventory

The requirements file has no keyed inventory; keys below are assigned from its sections.

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Observer(s) | Scenario(s) |
| --- | --- | --- | --- | --- | --- | --- |
| R-STF-SHELL | A "NEW screen StaffScreen (CanManageStudents); same header/nav/look as TransportScreen" | App shell and navigation | `conStfHeader`, `conStfNav`, `conStfDenied` | A-NAV-STAFF | `btnStfNavStaff` current; `conStfDenied.Visible` | S-NAV-STAFF, S-NAV-ROLE |
| R-STF-CAMPUS | A "Campus picker like Transportation: office locked, admins choose any campus" | Data exploration | `ddStfCampus` in `conStfHdrBar` | A-STF-CAMPUS | `ddStfCampus.DisplayMode`, `lblStfListTitle` | S-STF-CAMPUS |
| R-STF-RETIRED-TOGGLE | A "Toggle Show retired (default off)" | Data exploration | `tglStfRetired` -> varStfShowRetired | A-STF-SHOW-RETIRED | `galStfList.Items` | S-STF-RETIRED-TOGGLE |
| R-STF-SEARCH | A "Search box (name or email)" | Data exploration | `txtStfSearch` over SearchKey | A-STF-SEARCH | `galStfList.Items`, `lblStfListNote` | S-STF-SEARCH |
| R-STF-LIST | A List: Name, Email, Role, Students now, Account, Status; sort by Name; retired greyed; select row | Data exploration | `galStfList` rows | A-STF-SELECT | `lblStfRowName`, `lblStfRowMeta`, `lblStfRowStatus`, row Fill | S-STF-LIST |
| R-STF-PANEL | A right-hand panel: guidance idle, form when action open, receipt after save; Edit / Transfer class (teachers) / Retire (active); Add teacher at top of list | App shell and navigation | `conStfPanel`, `conStfSelActions`, `btnStfAdd`, `conStfReceipt` | A-STF-SELECT, A-STF-ADD-OPEN | panel title, `lblStfFacts` | S-STF-LIST |
| R-STF-ADD | A.1 Add teacher fields, validation, Patch, User blank, audit Create, receipt sentence | Data lifecycle | `btnStfSave` mode add | A-STF-ADD | `conStfReceipt`, new row selected | S-STF-ADD, S-STF-ADD-ADMIN, S-STF-ADD-INVALID |
| R-STF-EDIT | A.2 Edit Name, Email (excl. self), Start date; admin Campus + Role; office shows as text; audit Update Before/After | Data lifecycle | `btnStfSave` mode edit | A-STF-EDIT | receipt; row | S-STF-EDIT, S-STF-EDIT-OFFICE, S-STF-EDIT-BLOCK |
| R-STF-XFER-FORM | A.3 active Teacher with >= 1 student; new teacher picker; effective date Today-30..Today+90; locked month; note; help text about attendance | Workflow and review | `ddStfXferTeacher`, `dpStfDate`, `txtStfNote`, `lblStfXferHelp`, `lblStfCheck` | A-STF-XFER-OPEN | `lblStfCheck`, `btnStfSave.DisplayMode` | S-STF-XFER-INVALID, S-STF-XFER-DISABLED |
| R-STF-XFER-PREVIEW | A.3 preview: students who will move (name, number, ratio, current start) + skipped with reason | Workflow and review | btnStfPlanEngine -> colStfPlan; `galStfPlan` | A-STF-XFER-PREVIEW | `lblStfPlanSummary`, `galStfPlan` | S-STF-XFER-PREVIEW |
| R-STF-XFER-ENGINE | A.3 close old (eff-1, Transfer, Ended if eff <= Today), new enrollment (same fields, Previous), future -> reassign, eff = start -> reassign, audit Transfer per student, one at a time, IfError per student, colStfLog, receipt Moved / Reassigned / Failed + totals | Data lifecycle | btnStfXferEngine | A-STF-XFER | receipt lines; list counts | S-STF-XFER, S-STF-XFER-TODAY, S-STF-XFER-SAMEDAY, S-STF-XFER-PARTIAL |
| R-STF-RETIRE | A.4 End date (default Today, >= Start); blocked while open/future enrollments "Transfer their class first (N students)."; Active No + End Date; audit Update; receipt | Data lifecycle | btnStfSave mode retire | A-STF-RETIRE | receipt; row "Retired since" | S-STF-RETIRE-BLOCK, S-STF-RETIRE, S-STF-RETIRE-INVALID |
| R-STF-REACTIVATE | A.4 Reactivate retired (Active Yes, clear End Date), admin and office | Data lifecycle | btnStfSave mode reactivate | A-STF-REACTIVATE | receipt; row "Active" | S-STF-REACTIVATE, S-STF-RETIRE-REACTIVATE |
| R-NAV-STAFF | B "Staff" nav button (CanManageStudents) next to Transportation on 4 screens | App shell and navigation | `btnAttNavStaff`, `btnStuNavStaff`, `btnAbsNavStaff`, `btnTrnNavStaff` | A-NAV-STAFF | StaffScreen opens | S-NAV-STAFF |
| R-PICKERS-ACTIVE | C Students form teacher dropdown; colStuTeacherSrc IsActive (not filtered); Screen1 picker, campus OnChange, OnVisible; App OnStart default = first ACTIVE teacher; Absences unchanged | Data lifecycle (reference integrity) | Items / defaults filtered `Active = true` | A-ATT-ACTIVE-PICKER, A-STU-ACTIVE-PICKER, A-STU-TEACHER-SRC | dropdown lists | S-ATT-PICKER, S-ATT-REMEMBERED, S-STU-PICKER, S-STU-HISTORY-NAMES, S-ABS-REGRESSION |
| R-SIGNIN | D StaffPending formula; Screen1 not-set-up title/body texts | Security, persistence, and resilience | App.Formulas StaffPending; `lblAttNotSetUpTitle/Body` | A-SIGNIN-STATE | label texts | S-SIGNIN-PENDING, S-SIGNIN-NOTSETUP |
| R-NF-AUDIT | Non-functional: all writes IfError + Audit Events | Security, persistence, and resilience | every Patch wrapped; audit per write | A-STF-ADD, A-STF-EDIT, A-STF-XFER, A-STF-RETIRE, A-STF-REACTIVATE | receipt "Audit event" lines | all mutation scenarios |

## Requirement Coverage

| Requirement | Planned affordance | Fidelity |
| --- | --- | --- |
| StaffScreen, same header/nav/look | `conStfHeader` copied from `conTrnHeader`; nav row + paper strip with campus | Exact |
| Campus picker (office locked) | `ddStfCampus` DisplayMode Edit only when `StudentCampusLock = ZeroGuid` | Exact |
| Show retired toggle, default off | `tglStfRetired` (ModernToggle) | Exact |
| Search name or email | `txtStfSearch` (Search input), case-insensitive `in` over SearchKey | Exact |
| List columns | Row line 1 Name · Email; line 2 Role · Students now · Account; line 3 Status | Exact (three text lines per row instead of a column grid; same fields) |
| Students now = enrollments End blank or >= Today() | colStfEnr count by TeacherId | Exact |
| Retired rows greyed, sorted by Name | Fill `ColorNonSchool`, text `ColorMuted`; SortByColumns StaffName | Exact |
| Selecting a row selects the person | Row button "Select" (gallery is non-selectable by convention) sets varStfSelId; row highlighted | Approximation: a visible per-row Select button instead of tapping anywhere on the row (galleries in this app are `Selectable: false`; the button is the pointer target) |
| Right panel guidance / form / receipt | `conStfPanel` modes + `conStfReceipt` above the body (Transport pattern) | Exact |
| Edit / Transfer class (teachers only) / Retire (active only) / Add teacher at list top | `btnStfEdit`, `btnStfXfer` (Visible Teacher), `btnStfRetire` (Visible active), `btnStfReactivate` (Visible retired), `btnStfAdd` in list head | Exact |
| Add teacher validation + Patch + receipt sentence | C1 check + S1 add branch; receipt title is the exact requested sentence | Exact |
| Office role fixed Teacher; admin picks 4 roles | `lblStfRole` text for office; `rdoStfRole` (StaffRoleOptions) for admin, default Teacher | Exact |
| Edit (office cannot change campus / role) | `ddStfFormCampus` / `rdoStfRole` admin-only; office sees text | Exact; added guard: changing campus or role of a teacher with students is blocked ("Transfer their class first") |
| Transfer class form + preview + engine | `ddStfXferTeacher`, `dpStfDate`, `txtStfNote`, `lblStfXferHelp`, `galStfPlan`, btnStfXferEngine | Exact |
| Locked-month rule "same as Students Change class" | `Date(Year(d), Month(d), 1) in colStfLocks.MonthStart` (Month Locks at the campus) | Approximation: StudentsScreen Change class has no month-lock check in the current source; the Absences / Month Locks lookup rule is used instead |
| Retire blocked + reason text | `btnStfRetire` disabled, `lblStfActionHint` "Transfer their class first (N students)." | Exact |
| Reactivate | `btnStfReactivate` -> mode reactivate | Exact |
| Staff nav button on 4 screens | `btn{Att,Stu,Abs,Trn}NavStaff` appended; phone nav height 96 -> 148 | Exact |
| Active-only pickers | Screen1 / Students form / App OnStart / StaffScreen new-teacher picker | Exact |
| StaffPending + texts | App.Formulas; Screen1 labels | Exact |

## Required Record Fields

| Field key | Screen | Record surface | Required field | Source field | Presentation requirement |
| --- | --- | --- | --- | --- | --- |
| stf-identity | StaffScreen | galStfList row | Name, Email (canonical identity = Name) | colStfAll.StaffName, Email | `lblStfRowName` 14 Semibold, full text |
| stf-role-count-account | StaffScreen | galStfList row | Role, Students now, Account | RoleText, StudentsNow, Linked | `lblStfRowMeta` |
| stf-status | StaffScreen | galStfList row | Active / "Retired since mmm d, yyyy" | IsActive, EndDate | `lblStfRowStatus` |
| stf-detail | StaffScreen | conStfPanel | name, role, email, campus, students now, account, status, start/end | colStfAll | `lblStfFacts` |
| stf-plan-row | StaffScreen | galStfPlan row | student name, student number, ratio, current start, outcome/reason | colStfPlan | `lblStfPlanName`, `lblStfPlanMeta` |
| stf-receipt-line | StaffScreen | galStfReceipt line | per-student outcome | colStfLog | `lblStfRcptLabel` / `lblStfRcptValue` |

## State-Driven Surface Visibility

| Surface key | Owner screen | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- | --- |
| stf-denied | StaffScreen | conStfDenied | `=!CanManageStudents` | Teacher / Read-only / not set up |
| stf-receipt | StaffScreen | conStfReceipt | `=varStfReceipt.Kind <> ""` | after a save attempt until Close |
| stf-list | StaffScreen | conStfListPanel | `=!(conStfRoot.Width < 1024 && varStfMode <> "")` | hidden on narrow while a form is open |
| stf-panel | StaffScreen | conStfPanel | `=conStfRoot.Width >= 1024 \|\| varStfMode <> "" \|\| !IsBlank(varStfSelId)` | always on desktop |
| stf-sel-actions | StaffScreen | conStfSelActions | `=varStfMode = "" && !IsBlank(varStfSelId)` | person selected, no form |
| att-pending | Screen1 | conAttNotSetUp (unchanged Visible `=!StaffReady`) | title/body switch on `StaffPending` | pending vs not set up |

## Action Contracts

| Requested action | Preconditions | Entry point | Owner screen | Control and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-NAV-STAFF | CanManageStudents | "Staff" | Screen1, StudentsScreen, AbsencesScreen, TransportScreen, StaffScreen | `btn{Att,Stu,Abs,Trn,Stf}NavStaff.OnSelect: =Navigate(StaffScreen)` | N/A | StaffScreen shown | N/A | N/A | `btnStfNavStaff` teal (current) |
| A-STF-CAMPUS | Admin (StudentCampusLock = ZeroGuid) | `ddStfCampus` | StaffScreen | OnChange | Campuses.Campus | varStfCampusId; mode/selection cleared; reload | N/A | N/A | `lblStfListTitle` campus name |
| A-STF-SEARCH | list loaded | `txtStfSearch` | StaffScreen | Text (Keypress) | SearchKey | filter F | N/A | N/A | `galStfList`, `lblStfListNote` |
| A-STF-SHOW-RETIRED | list loaded | `tglStfRetired` | StaffScreen | OnCheck / OnUncheck | N/A | varStfShowRetired | N/A | N/A | retired rows shown greyed |
| A-STF-SELECT | row visible | row "Select" | StaffScreen | `btnStfRowSelect.OnSelect` | colStfAll.StaffId | varStfSelId = StaffId; mode "" | N/A | N/A | row Fill ColorInfoBg; `lblStfFacts` |
| A-STF-ADD-OPEN | not saving | "Add teacher" | StaffScreen | `btnStfAdd.OnSelect` | N/A | selection cleared; mode "add"; inputs reset | N/A | N/A | panel title "Add teacher" |
| A-STF-ADD | mode add; C1 Ready (name, valid unique email, campus, role, start date) | "Add teacher" (save) | StaffScreen | `btnStfSave.OnSelect` branch `mode = "add"` | new `wr.Staff` | live duplicate check by Email; Patch Defaults; audit Create; varStfSelId = wr.Staff; reload | Staff: Name, Email (lower-trimmed), Campus, Start Date, App Role, Active=true, Finance Access=false, Site Administrator=false; Audit row | title = requested sentence; Name, Work email, Campus, App role, Start date, Status, Finance / Site admin, Account, Audit | `conStfReceipt`; new row selected in `galStfList` ("Waiting for account") |
| A-STF-EDIT | person selected; office: Teacher row only; C1 Ready | "Edit" -> "Save changes" | StaffScreen | `btnStfSave` branch `"edit"` | varStfSelId -> live LookUp | live dup check excl. self; admin campus/role change blocked while teacher has students; Patch; audit Update | Name, Email, Start Date; admin also Campus, App Role; Audit row | Name, Work email, Campus, App role, Start date, Before, Audit | receipt; `lblStfRowName` |
| A-STF-XFER-OPEN | selected active Teacher, StudentsNow >= 1 | "Transfer class" | StaffScreen | `btnStfXfer.OnSelect` | varStfSelId | mode "transfer"; varStfXferDate Today(); E2 load; E3 plan | N/A | N/A | panel title "Transfer class"; preview |
| A-STF-XFER-PREVIEW | transfer mode | date change | StaffScreen | `dpStfDate.OnChange` -> `btnStfPlanEngine` | colStfXferEnr.EnrId | colStfPlan rebuilt for the date | N/A | N/A | `lblStfPlanSummary`, `galStfPlan` |
| A-STF-XFER | C1 Ready (new active teacher at campus <> selected, date in range and unlocked, preview current, >= 1 move/reassign) | "Transfer class (n)" | StaffScreen | `btnStfSave` branch `"transfer"` -> `btnStfXferEngine` | per row `w.EnrId`; live `old`; returned `closed`, `ne`, `up` | ForAll colStfXferWork one at a time: move = close old + create new (Change class logic, rollback on failure); reassign = Patch Teacher; skip on live re-check; audit Transfer per student; colStfLog; reload list | move: old End Date = eff-1, End Reason Transfer, Status Ended if eff <= Today; new Name, Student, Campus, Teacher, Service, School Year, Program, IEP Ratio, Start Date, Status, Previous Enrollment; Owners (as Change class). reassign: Teacher (+ enrollment Owner, student Owner if started). Audit row per student | title "Class transfer · From to To · date · m moved, r reassigned, f failed[, s skipped]"; Operation, From, To, Effective date, Moved, Reassigned, Failed, Skipped; per student "Moved · old ends ... ; new from ... with <ne.Teacher> · IEP <ne ratio> · <ne status> · audit" / "Future enrollment reassigned · enrollment from ... now with <up.Teacher>" / "FAILED · <error>" / "Skipped · <reason>" | `conStfReceipt`; `lblStfRowMeta` Students now for both teachers after reload |
| A-STF-RETIRE | active; StudentsNow = 0; office: Teacher row; not self; end date >= start | "Retire" -> "Retire" | StaffScreen | `btnStfSave` branch `"retire"` | varStfSelId -> live | live count of open/future enrollments must be 0; Patch Active false + End Date; audit Update | Active=false, End Date; Audit row | Name, Status (`wr.Active`), End date (`wr`), Students now, Teacher pickers, Audit | receipt; row hidden unless Show retired, then "Retired since" |
| A-STF-REACTIVATE | retired; office: Teacher row | "Reactivate" -> "Reactivate" | StaffScreen | `btnStfSave` branch `"reactivate"` | varStfSelId -> live | Patch Active true + End Date blank; audit Update | Active=true, End Date=blank; Audit row | Name, Status, End date "Cleared", Audit | receipt; row "Active" |
| A-STF-CANCEL | form open | "Cancel" | StaffScreen | `btnStfCancel.OnSelect` | N/A | mode ""; plan cleared; inputs reset; selection kept | N/A | N/A | panel shows details + actions |
| A-ATT-ACTIVE-PICKER | Screen1 | campus change / visit / picker | Screen1 | `ddAttTeacher.Items`, `ddAttCampus.OnChange`, OnVisible | Staff.Staff | only Active teachers offered; remembered retired teacher replaced by first active | N/A | N/A | `ddAttTeacher` list |
| A-STU-ACTIVE-PICKER | Students form | add / change class / re-enroll | StudentsScreen | `ddStuFormTeacher.Items` | Staff.Staff | only Active teachers | N/A | N/A | dropdown list |
| A-STU-TEACHER-SRC | Students load | visit | StudentsScreen | `btnStuLoadEngine` | Staff.Staff | colStuTeacherSrc gains IsActive; nothing filtered | N/A | N/A | list/history names of retired teachers still shown |
| A-SIGNIN-STATE | !StaffReady | app open | Screen1 | `lblAttNotSetUpTitle/Body.Text` | StaffPending | pending vs not set up text | N/A | N/A | label texts |

Opposing pair: Retire / Reactivate (Disable / Enable) on the same Staff record - see Directional Mutation Evidence.
Continuation Contracts: none (Add teacher only selects the new row; no downstream action is triggered).

## Directional Mutation Evidence

| Pair | Selected ID binding | Operation state | Invalid gate | Submit gate | Retire formula | Reactivate formula | Canonical observer | Receipt values |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Retire / Reactivate | `varStfSelId` (set only by `btnStfRowSelect` or Add) | `varStfMode` literal `"retire"` / `"reactivate"` set by `btnStfRetire` / `btnStfReactivate` (selection-only; Cancel resets to "") | C1 retire: `IsBlank(p) \|\| !p.IsActive`, office non-Teacher, self, `p.StudentsNow > 0`, blank / pre-start date; reactivate: `IsBlank(p) \|\| p.IsActive`, office non-Teacher | `btnStfSave.DisplayMode` Edit only when `StartsWith(lblStfCheck.Text, "Ready")`; S1 literal guards `mode = "retire"` and `mode = "reactivate"` (no else-arm writes) | `Patch(Staff, live, {Active: false, 'End Date': d})` after live `live.Active = false` / live count guard | `Patch(Staff, live, {Active: true, 'End Date': Blank()})` after live `live.Active = true` guard | `colStfAll.IsActive` / `EndDate` after `btnStfLoadEngine` (reads Staff.Active, 'End Date') -> `lblStfRowStatus` | operation (title), name, Status before (facts) / after (`wr.Active`), End date (`wr.'End Date'`), audit |

## Compound Sequence Evidence

| Record | Sequence | Second operation's old-value binding | Expected |
| --- | --- | --- | --- |
| Lee, Bo (0 students) | Retire (end 10/6) then Reactivate | Reactivate guard reads `live = LookUp(Staff, ThisRecord.Staff = q)` (fresh), so `live.Active = false`, `live.'End Date' = 2026-10-06` | After step 1: Active false, End 10/6, row "Retired since Oct 6, 2026"; after step 2: Active true, End blank, row "Active"; audit Before of step 2 = `{Active: false, EndDate: "2026-10-06"}` |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-STF-ADD | `wr` -> varStfReceipt + colStfReceiptLines -> `galStfReceipt` | Staff row (`wr.Staff`) | `galStfList` row; teacher pickers on Screen1 / Students | `wr.Staff` = audit Entity ID = varStfSelId | `Select(btnStfLoadEngine)` re-queries Staff | varStfSelId highlights the new row |
| A-STF-EDIT | `wr` + `live` -> receipt | Staff row | `galStfList` row | varStfSelId = live.Staff = wr.Staff | reload | row stays selected (cleared if moved to another campus) |
| A-STF-XFER | colStfLog (per student from `closed`/`ne`/`up`) -> colStfReceiptLines | Enrollments rows | Students screen history / list (new teacher), Screen1 grid for the new teacher, StaffScreen Students now | `w.EnrId` -> `closed.Enrollment`; `ne.Enrollment` -> colStfLog.NewEnrId; audit Entity ID = student | `Select(btnStfLoadEngine)` recounts; other screens re-query on visit | selected (old) teacher stays selected |
| A-STF-RETIRE | `wr` -> receipt | Staff row (`wr.Active`, `wr.'End Date'`) | `galStfList` row; pickers no longer list | varStfSelId = live.Staff | reload | row selected; visible with Show retired |
| A-STF-REACTIVATE | `wr` -> receipt | Staff row | `galStfList` row; pickers list again | same | reload | row selected |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| A-STF-ADD | Name | Changed | txtStfName | Patch | "Name" `wr.Name` | lblStfRowName |
| A-STF-ADD | Email | Changed | Lower(Trim(txtStfEmail)) | Patch | "Work email" `wr.Email` | lblStfRowName |
| A-STF-ADD | Campus | Changed | ddStfFormCampus (admin) / varStfCampusId | Patch | "Campus" `wr.Campus.Name` | list membership |
| A-STF-ADD | Start Date | Changed | dpStfDate | Patch | "Start date" | lblStfFacts |
| A-STF-ADD | App Role | Changed | rdoStfRole (admin) / Teacher | Patch | "App role" | lblStfRowMeta |
| A-STF-ADD | Active, Finance Access, Site Administrator | Changed | true / false / false | Patch | "Status", "Finance / Site admin" | lblStfRowStatus |
| A-STF-ADD | User | Preserved (blank) | - | omitted (the access flow links it) | "Account" | lblStfRowMeta "Waiting for account" |
| A-STF-EDIT | Name, Email, Start Date | Changed | inputs | Patch live | lines from `wr` + "Before" | row / facts |
| A-STF-EDIT | Campus, App Role | Changed (admin) / Preserved (office: `live.Campus`, `live.'App Role'` carried) | picker / live | Patch | "Campus", "App role" | row meta |
| A-STF-EDIT | Active, End Date, User, Finance Access, Site Administrator | Preserved | live | omitted | N/A | row status |
| A-STF-XFER (move) | old End Date, End Reason, Status | Changed | eff | Patch old | per-student "old ends <closed.'End Date'> (<closed status>)" | Students history |
| A-STF-XFER (move) | new enrollment fields (Name, Student, Campus, Teacher, Service, School Year, Program, IEP Ratio, Start Date, Status, Previous Enrollment) | Changed (created) | old + tch + eff | Patch Defaults | "new from <ne.'Start Date'> with <ne.Teacher.Name> · IEP <ne.'IEP Ratio'> · <ne status>" | Students history; Screen1 grid of new teacher |
| A-STF-XFER (move) | Student Owner, new enrollment Owner | Changed when teacher has a linked user (Change class rule) | tch.User | Patch | "owner unchanged / owner update FAILED" suffix | N/A |
| A-STF-XFER (move) | Attendance rows on/after eff | Preserved | live | not written | "n recorded day(s) stay with the old teacher" | Screen1 grid old teacher |
| A-STF-XFER (reassign) | Teacher (+ Owner) | Changed | tch | Patch existing | "enrollment from <up.'Start Date'> now with <up.Teacher.Name>" | Students history |
| A-STF-XFER (reassign) | Start/End Date, Status, IEP Ratio | Preserved | live | omitted | "enrollment from <start>" | history |
| A-STF-RETIRE | Active, End Date | Changed | false, dpStfDate | Patch live | "Status", "End date" from `wr` | lblStfRowStatus |
| A-STF-RETIRE | Name, Email, Campus, Role, User | Preserved | live | omitted | "Name" | row |
| A-STF-REACTIVATE | Active, End Date | Changed | true, Blank() | Patch live | "Status", "End date: Cleared" | lblStfRowStatus |

## Functional Test Matrix

Fixtures (Dev): today = Tue 2026-10-06. Campus CW = Chatsworth; OX = Oxnard. Office O "Ortiz, Olga" (Attendance
Office, CW, linked). Admin M "Mendez, Mia" (System Admin, no campus). Staff at CW: teacher A "Smith, Ana"
(ana.smith@autismacademy.org, linked, active, start 2024-08-01); teacher B "Lee, Bo" (bo.lee@autismacademy.org, User
blank, active, start 2026-08-01, no students); teacher R "Ray, Rick" (Active No, End 2026-06-30). Teacher T "Tan, Tom"
at OX. A's enrollments (service SPED, school year 2026-27 ending 2027-06-11): Jane STU-000123 1:1 open since
2026-08-17; Max STU-000200 2:1 open since 2026-08-17; Ida STU-000210 No Aide open since 2026-08-17; Pat STU-000220 1:1
Planned from 2026-10-19; Ann STU-000230 ended 2026-09-30 (not counted). Month Locks: Aug 2026 Locked at CW. Students
list: Kim STU-000240 enrollment with R (ended 2026-06-30).

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-NAV-STAFF | O on Screen1 / Students / Absences / Transportation | Press Staff | StaffScreen opens; its Staff button teal | `btnStfNavStaff` | Phone 375: nav shows three rows, Staff visible |
| S-NAV-ROLE | Teacher A | Look at headers; navigate directly | No nav row; StaffScreen shows denied panel | `conStfDenied` | Read-only same |
| S-STF-LIST | fixtures | O opens Staff | Campus locked "Chatsworth"; rows sorted: "Lee, Bo · bo.lee@..." (Teacher · Students now: 0 · Account: Waiting for account · Active); "Ortiz, Olga" (Attendance Office · 0 · Linked); "Smith, Ana" (Teacher · Students now: 4 · Linked · Active). Ray hidden | `lblStfListTitle` "Staff at Chatsworth (3)", row labels | Ann's ended enrollment not counted |
| S-STF-RETIRED-TOGGLE | S-STF-LIST | Toggle Show retired on | "Ray, Rick" appears greyed "Retired since Jun 30, 2026"; title count 4 | row Fill ColorNonSchool | Off again hides it |
| S-STF-SEARCH | list | type "ANA.SM" then "lee" | only Smith, Ana; then only Lee, Bo | `galStfList` | "zzz" -> "No staff match the search." |
| S-STF-CAMPUS | O / M | O: campus picker; M picks Oxnard | O disabled; M sees Tan, Tom only | `ddStfCampus.DisplayMode`, list | N/A |
| S-STF-ADD | O | Add teacher: "Park, Kim", " Kim.Park@AutismAcademy.org ", start 10/6 -> Add teacher | Staff row: Name "Park, Kim", Email "kim.park@autismacademy.org", Campus CW, Start 2026-10-06, App Role Teacher, Active Yes, Finance No, Site Admin No, User blank; Audit Create (Entity aaca_staff) | Receipt title "Added. They can sign in once they are in the app's security group; their access is set up automatically within about 15 minutes of their first sign-in."; lines Name, Work email, Campus Chatsworth, App role Teacher, Status Active, Account "Waiting for account (linked automatically)", Audit "Create written"; new row selected | Office sees "App role: Teacher" and "Campus: Chatsworth (your campus)" (no pickers) |
| S-STF-ADD-ADMIN | M | Add: campus Oxnard, role Attendance Office | Row created at OX with that role | receipt App role "Attendance Office" | default role radio = Teacher |
| S-STF-ADD-INVALID | add mode | (a) blank name; (b) "kim.park@gmail.com"; (c) "ana.smith@autismacademy.org"; (d) email equal to a linked user's Primary Email on a Staff row with blank Email; (e) "a b@autismacademy.org" | Save disabled with the reason | `lblStfCheck` e.g. "That email already belongs to Smith, Ana." | Another user adds the same email meanwhile -> Blocked receipt from the live check |
| S-STF-EDIT | O selects Lee, Bo | Edit -> name "Lee, Bob" -> Save changes | Staff Name "Lee, Bob"; Email unchanged; Audit Update Before {Name: "Lee, Bo"...} After {Name: "Lee, Bob"...} | receipt "Saved · Lee, Bob · bo.lee@..."; "Before" line; row updated | Same values -> "No changes to save." |
| S-STF-EDIT-OFFICE | O selects Ortiz, Olga | look at actions | Edit disabled; hint "Office staff can change teacher records only. Ask a System Admin." | `btnStfEdit.DisplayMode`, `lblStfActionHint` | O editing Lee sees campus/role as text |
| S-STF-EDIT-BLOCK | M selects Smith (4 students) | change campus to Oxnard or role to Read-only | Save disabled: "Transfer their class first (4 students) before changing campus or role." | `lblStfCheck` | Name/email edit still allowed |
| S-STF-XFER-PREVIEW | O selects Smith | Transfer class; new teacher Lee, Bo; effective 10/12 | Preview: Jane, Max, Ida "Will move to the new teacher"; Pat "Future enrollment reassigned: planned enrollment starting Oct 19, 2026 gets the new teacher"; summary "Preview · 3 will move, 1 future enrollment(s) reassigned, 0 skipped"; button "Transfer class (4)" | `lblStfPlanSummary`, `galStfPlan`, `btnStfSave.Text` | Help text about attendance staying with the old teacher visible |
| S-STF-XFER | S-STF-XFER-PREVIEW | Transfer class (4) | Jane: old End 2026-10-11, End Reason Transfer, Status Active (eff > today, unchanged); new "STU-000123 2026-10-12", Teacher Lee, Campus CW, Service/School Year/Program same, IEP 1:1, Start 10/12, Status Planned, Previous = old; same for Max (2:1) and Ida (No Aide); Pat's enrollment Teacher = Lee (start 10/19 unchanged); 4 Audit Transfer rows (Entity aaca_student, Reason "Class transfer to Lee, Bo") | Receipt "Class transfer · Smith, Ana to Lee, Bo · Oct 12, 2026 · 3 moved, 1 reassigned, 0 failed"; lines Moved 3, Reassigned 1, Failed 0, Skipped 0, "Doe, Jane · STU-000123 -> Moved · old ends Oct 11, 2026 (Active); new from Oct 12, 2026 with Lee, Bo · IEP 1:1 · Planned · owner unchanged (teacher has no linked user) · audit Transfer written"; list Students now: Smith 3 (old enrollments end 10/11 >= today), Lee 4 | Old owner patches skipped because Lee has no linked user |
| S-STF-XFER-TODAY | A has Jane/Max/Ida open | Transfer to Lee effective 10/6 | old End 10/5, Status Ended; new Start 10/6 Status Active; attendance already recorded on 10/6 stays with Smith (count shown) | per-student line "... (Ended); new from Oct 6, 2026 ... Active · 1 recorded day(s) stay with the old teacher" | Pat (from 10/19) is reassigned in the same run, so Smith's Students now becomes 0 and Retire is enabled |
| S-STF-XFER-SAMEDAY | Pat Planned from 10/19 | Transfer effective 10/19 | Pat's enrollment only Teacher patched (no zero-length enrollment); Jane/Max/Ida move with eff 10/19 | preview "starts on the effective date, so only the teacher changes"; receipt "Future enrollment reassigned" | N/A |
| S-STF-XFER-PARTIAL | Max also has a second open SPED enrollment (data issue); Ida's close Patch refused (test: remove write privilege on that row) | Transfer | Max "Skipped · the new enrollment would overlap ..."; Ida "FAILED · nothing saved: <error>"; Jane moved; Pat reassigned; one failure does not stop the rest | receipt Kind "Partial" (warning fill), totals "2 moved... " | New-enrollment failure -> old enrollment reopened, line says so |
| S-STF-XFER-INVALID | transfer mode | (a) no new teacher; (b) date 9/5 (today-31) or 1/5/2027 (+91); (c) Sep 2026 locked at CW (test lock) and date 9/15 | Save disabled; (c) "September 2026 is locked at this campus. Choose a date in an open month." | `lblStfCheck` | Picker range already limits (b) |
| S-STF-XFER-DISABLED | Lee (0 students) / Ortiz (not teacher) | select | Lee: Transfer class disabled; Ortiz: button hidden | `btnStfXfer` | Retired teacher: disabled |
| S-STF-RETIRE-BLOCK | Smith (4 students) | select | Retire disabled; hint "Retire is not available. Transfer their class first (4 students)." | `btnStfRetire.DisplayMode`, `lblStfActionHint` | Live re-check at save also blocks |
| S-STF-RETIRE | Lee, Bo (0 students, before any transfer) | Retire -> end 10/6 -> Retire | Active No, End Date 2026-10-06; Audit Update Before {Active: true, EndDate: ""} After {Active: false, EndDate: "2026-10-06"} | receipt "Retired · Lee, Bo · end date Oct 6, 2026"; row hidden (visible with Show retired as "Retired since Oct 6, 2026"); Screen1 / Students pickers no longer list Lee | O cannot retire self |
| S-STF-RETIRE-INVALID | retire mode, Lee start 2026-08-01 | end date 2026-07-01 (picker min = start) | disabled: "The end date cannot be before the start date (Aug 1, 2026)." | `lblStfCheck` | N/A |
| S-STF-REACTIVATE | Ray retired | Show retired -> select Ray -> Reactivate | Active Yes, End Date blank; Audit Update | receipt "Reactivated · Ray, Rick", End date "Cleared"; row "Active"; pickers list Ray again | N/A |
| S-STF-RETIRE-REACTIVATE | Lee active | Retire (10/6) then Reactivate | see Compound Sequence Evidence | row status after each step | N/A |
| S-ATT-PICKER | after S-STF-RETIRE | O on Screen1, campus CW | teacher picker lists Smith only (Lee, Ray hidden) | `ddAttTeacher` | M switching campus picks first active teacher |
| S-ATT-REMEMBERED | varTeacher = Lee, then Lee retired | revisit Screen1 | varTeacher replaced by first active teacher at CW | `ddAttTeacher` selection | App start defaults to first active teacher |
| S-STU-PICKER | Ray retired | Students form Add / Change class | teacher dropdown excludes Ray | `ddStuFormTeacher` | N/A |
| S-STU-HISTORY-NAMES | Kim's old enrollment with Ray | open Students list / history | "Ray, Rick" still shown as teacher; teacher filter still offers Ray | list row, history | N/A |
| S-STU-CHANGE-CLASS-REGRESSION | Students Change class on Jane | as before | unchanged behaviour | receipt "Class change saved" | N/A |
| S-SIGNIN-PENDING | Kim Park (S-STF-ADD) signs in before the access flow links User | open app | Screen1 panel title "Your access is being set up"; body "Your Staff record was found. Access is set up automatically ..." | `lblAttNotSetUpTitle/Body` | After linking, panel hidden |
| S-SIGNIN-NOTSETUP | unknown email | open app | "You're not set up yet"; body ends "Ask your office manager to add you on the Staff screen, then reopen the app." | same | Retired person (Active No, linked) -> not pending, not set up text |
| S-ABS-REGRESSION | Absences | teacher filter | still lists Ray (history) | `colAbsTeacherOpts` | N/A |
| S-TRN-REGRESSION | Transportation | header | nav one row desktop; Staff button present; tabs strip unchanged | header | N/A |
| S-ATT-REGRESSION | Teacher A | Screen1 | grid unchanged; no nav row | Screen1 | N/A |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| ddStfCampus | lblStfCampus `="Campus"` | conStfHdrBar |
| txtStfName | lblStfName `="Name * (Last, First)"` | conStfPanel |
| txtStfEmail | lblStfEmail `="Work email *"` | conStfPanel |
| ddStfFormCampus | lblStfFormCampus `="Campus *"` (admin) | conStfPanel |
| rdoStfRole | lblStfRole `="App role *"` (admin) | conStfPanel |
| ddStfXferTeacher | lblStfXferTeacher `="New teacher *"` | conStfPanel |
| dpStfDate | lblStfDate (mode text, e.g. "Effective date (first day with the new teacher) *") | conStfPanel |
| txtStfNote | lblStfNote `="Note for the audit log (optional)"` | conStfPanel |

## Layout Budget Contracts

| Screen / container | Branch / screen-width source | Horizontal total-width arithmetic | Vertical height arithmetic | Protected controls |
| --- | --- | --- | --- | --- |
| Nav rows (all 5 screens) | root Width < 640 | 110+8+110+8+110+8+140+8+80 = 582; +32 padding = 614 <= 640 | 44 (>= 640) / 148 three rows (< 640: 228 / 258 / 80 at 343) | Staff, Transportation |
| conStfHdrBar | any | 16+56+8+220+16 = 316 <= 343 | 60 | campus picker |
| conStfListHead / Tools | < 640 | 150+8+130 = 288 <= 311; tools 240+8+150 = 398 > 311 -> wrap | 44; tools 44 / 88 | Add teacher |
| galStfList row | < 640 vertical / >= 640 horizontal | desktop inner 581 at 1024 >= 260+8+100 | 82 <= 88; phone 170 <= 176 | Select |
| conStfPanel | >= 1024 panel inner 306 | actions 190+8+100 = 298; selection actions 326 -> wrap 96 | idle 136/276, add 544/396, edit 620/472, transfer 588 + gallery, retire 304, reactivate 242 | Save, Cancel |
| galStfPlan row | panel width | text wraps in 36 | 66 <= 72 | N/A |

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| --- | --- | --- | --- | --- | --- |
| StaffScreen | conStfRoot (sole top-level child) | AutoLayout | `=Parent.Width` | `=Parent.Height` | LayoutOverflowY Scroll; LayoutMinWidth/Height 0 |
| Screen1 / StudentsScreen / AbsencesScreen / TransportScreen | existing roots | AutoLayout | unchanged | unchanged | unchanged |

## Temporal Ordering Contracts

None. Lists sort by name; dates are typed Date values and only displayed.

## Working Directory

C:\src\aaca-attendance\app

Plan artifacts: C:\src\aaca-attendance\docs\app-builds\build-10-staff\

## Discovery Summary

- Existing screens: Screen1 (Att), StudentsScreen (Stu), AbsencesScreen (Abs), TransportScreen (Trn); AutoLayout,
  one scroll root each.
- Data sources: Staff (Email, Start Date, End Date NEW; Active / Finance Access / Site Administrator Yes/No), Enrollments,
  Students, Attendance, 'Month Locks', Campuses, Users, 'Audit Events'.
- Controls (all in the build-9 packet, all already used in the app): GroupContainer, ModernText, ModernButton,
  Classic/Button, Gallery, ModernDropdown, ModernTextInput, ModernDatePicker, ModernRadio, ModernToggle. No new types.
- Plugin reference guides (QAChecks, PlanTemplates, ...) were not available to this planner (no plugin root supplied);
  the artifact shape follows the build-9 plan.

## Dispatch

Order matters: StaffScreen must exist in the session before any `Navigate(StaffScreen)` compiles.

1. Orchestrator: apply "App.pa.yaml changes (orchestrator)" from the shared plan; compile App.
2. Wave 1: StaffScreen (alone; the large build).
3. Wave 2 (after StaffScreen compiles): Screen1, StudentsScreen, AbsencesScreen in parallel; TransportScreen in the
   same wave if four builders are allowed, otherwise wave 3. The four modify briefs are small and independent.
4. Orchestrator: append StaffScreen to `_EditorState.pa.yaml` ScreensOrder; Studio save (coauthoring).

| Action | Screen | Target File | YAML Key | Name Prefix | Screen Brief |
| --- | --- | --- | --- | --- | --- |
| Create | Staff | `C:\src\aaca-attendance\app\StaffScreen.pa.yaml` | StaffScreen | Stf | `C:\src\aaca-attendance\docs\app-builds\build-10-staff\StaffScreen.screen-plan.md` |
| Modify | Attendance | `C:\src\aaca-attendance\app\Screen1.pa.yaml` | Screen1 | Att (new: AttNavStaff) | `C:\src\aaca-attendance\docs\app-builds\build-10-staff\Screen1.screen-plan.md` |
| Modify | Students | `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml` | StudentsScreen | Stu (new: StuNavStaff) | `C:\src\aaca-attendance\docs\app-builds\build-10-staff\StudentsScreen.screen-plan.md` |
| Modify | Absences | `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml` | AbsencesScreen | Abs (new: AbsNavStaff) | `C:\src\aaca-attendance\docs\app-builds\build-10-staff\AbsencesScreen.screen-plan.md` |
| Modify | Transportation | `C:\src\aaca-attendance\app\TransportScreen.pa.yaml` | TransportScreen | Trn (new: TrnNavStaff) | `C:\src\aaca-attendance\docs\app-builds\build-10-staff\TransportScreen.screen-plan.md` |

## App Changes

### Before builders

See `canvas-app-shared.md` section "App.pa.yaml changes (orchestrator)": (1) Formulas `StaffPending`,
`StaffRoleOptions`; (2) OnStart default teacher `&& Active = true`; (3) OnStart Stf seeds appended after
`Clear(colTrnLog)` (final line `Clear(colStfReceiptLines)` without semicolon).

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
    - StaffScreen
```

`ComponentDefinitionsOrder`: none (no components).
