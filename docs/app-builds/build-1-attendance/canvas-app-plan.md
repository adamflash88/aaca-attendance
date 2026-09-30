# Canvas App Plan

## Mode

CREATE

## Requirements

Build 1 of the AACA Attendance canvas app: app shell + Attendance Matrix on live Dataverse
(no mock data). One screen (Screen1 = Attendance) with a monthly student x day grid, phone
Day view, per-cell upsert (Student + Service + Date), soft delete with audit, day "All
present", totals, validation (school day, enrollment, future, month lock, role), per-cell
saving/saved/failed with retry, Modified On conflict warning, and a cell detail panel with
editable notes. Full original clauses: `C:\src\aaca-attendance\app\canvas-app-requirements.md`
(immutable). Approved plan and orchestrator decisions are reproduced in the screen brief.

## Original Request Capability Inventory

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Observer(s) | Scenario(s) |
| --- | --- | --- | --- | --- | --- | --- |
| R-IDENTITY | Role from the Staff row for the signed-in user; no Staff row = not-set-up | Security, persistence, and resilience | CurrentStaff, role flags, campus scope; not-set-up panel | A-LOAD-IDENTITY | lblAttIdentity.Text; conAttNotSetUp.Visible | S-IDENT-ROLE, S-IDENT-MISSING |
| R-SCOPE | Teacher own students; office own campus teachers; admin/read-only any | Security, persistence, and resilience | Picker DisplayMode per role; teacher fixed to self | A-PICK-CAMPUS, A-PICK-TEACHER | ddAttCampus.DisplayMode, ddAttTeacher.Items/DisplayMode | S-SCOPE-TEACHER, S-SCOPE-OFFICE, S-PICK-CAMPUS-ADMIN |
| R-MONTH | Month/year picker on top | Time and scheduling | Prev/next/This month; reload | A-NAV-MONTH | lblAttMonth.Text; galAttDayHead (colMonthDays) | S-MONTH-NEXT |
| R-LOAD | Load only teacher + month, delegable, Concurrent() | Integration and automation | Enrollments, Attendance, Calendar Exceptions, Terms, Month Lock, Settings | A-LOAD-MONTH | galAttRows.Items (colMonthStudents); spnAttLoading; lblAttNotice | S-LOAD-MONTH |
| R-ROWS | Rows = teacher's students active in month; mid-month transfer | Relationships and hierarchy | One row per student; per-day segment eligibility | A-LOAD-MONTH | colMonthCells.State via btnAttCell.Text/Tooltip | S-ROWS-TRANSFER |
| R-CELL-STATES | blank / present / absent; P, A, E, U by colour AND letter | Data lifecycle | Letter + fill from colMonthAtt, ignoring Is Deleted = Yes | A-MARK-CELL | btnAttCell.Text / Fill | S-MARK-PRESENT, S-MARK-ABSENT |
| R-MARK | Tap to cycle; ONE record per save, upsert on key | Data lifecycle | blank→P (create/restore), P→A (update), snapshots | A-MARK-CELL | btnAttCell; lblAttReceipt | S-MARK-PRESENT, S-MARK-ABSENT, S-MARK-RESTORE |
| R-CLEAR | Clear = confirm, soft delete, audit | Data lifecycle | Is Deleted = Yes + Audit Events Soft Delete; cancel unchanged | A-CLEAR-CELL | btnAttCell; lblAttReceipt; Audit Events | S-CLEAR-CONFIRM, S-CLEAR-CANCEL |
| R-BULK | All present for a day, overrides after | Data lifecycle | Eligible students without active record → Present; summary | A-DAY-ALL-PRESENT | column btnAttCell; lblAttDayTotal; lblAttReceipt | S-BULK-DAY |
| R-NONSCHOOL | Non-school days shaded, read-only | Time and scheduling | Weekend (unless make-up), outside term, closure exceptions | A-VALIDATE-SAVE | btnAttCell Fill/DisplayMode/Tooltip; conAttDayHeadCell.Fill | S-BLOCK-NONSCHOOL |
| R-ENROLLED | Days outside enrollment greyed and locked | Relationships and hierarchy | "–" cells disabled | A-VALIDATE-SAVE | btnAttCell.Text "–" | S-BLOCK-NOTENROLLED |
| R-FUTURE | No future dates unless setting allows | Time and scheduling | State "Future" unless AllowFutureDates | A-VALIDATE-SAVE | btnAttCell BorderStyle Dashed / Disabled | S-BLOCK-FUTURE |
| R-LOCK | Month must not be locked | Workflow and review | Banner with reason; all read-only | A-VALIDATE-SAVE | lblAttNotice; varCanEditMonth | S-BLOCK-LOCKED |
| R-READONLY | Read-only role cannot edit | Security, persistence, and resilience | All save actions disabled | A-VALIDATE-SAVE | lblAttNotice; disabled controls | S-BLOCK-READONLY |
| R-STATUS | saving / saved / failed per cell; retry | Security, persistence, and resilience | colCellState by StudentId+DayNum; rollback; "!" retries | A-MARK-CELL, A-RETRY-CELL | btnAttCell.Text "…"/"✓"/"!"; lblAttDayStatus | S-FAIL-RETRY |
| R-CONFLICT | Warn on concurrent edit (Modified On) | Security, persistence, and resilience | Skip write, refresh cell, banner | A-MARK-CELL | lblAttReceipt Kind Conflict; btnAttCell | S-CONFLICT |
| R-TOTALS | Row and column totals from loaded month | Analytics and visualization | Count Present, !IsDeleted in colMonthAtt | A-MARK-CELL (observer) | lblAttRowTotal, lblAttDayTotal, lblAttFootTotal | S-MARK-PRESENT, S-CLEAR-CONFIRM |
| R-DETAIL | Detail panel; notes editable; classification read-only | Data lifecycle | Details mode tap → panel; Save notes patches Notes only | A-OPEN-DETAIL, A-SAVE-NOTES | lblAttDetailTitle/Facts; txtAttDetailNotes; lblAttReceipt | S-DETAIL-NOTES |
| R-DAYVIEW | Phone-friendly Day view | App shell and navigation | Month/Day switch; Present/Absent per student for a date | A-SWITCH-VIEW, A-DAY-MARK | conAttDayView; lblAttDayStatus | S-DAYVIEW-MARK |
| R-STATES | Empty, loading, error states | App shell and navigation | Spinner; "No students…"; load-error banner | A-LOAD-MONTH | spnAttLoading; lblAttEmpty; lblAttNotice | S-EMPTY |
| R-A11Y | Keyboard/screen-reader labels, contrast, non-colour cues | App shell and navigation | Labels on modern controls; Tooltip + letter on Classic cells | All | AccessibleLabel / Tooltip bindings | All |

## Requirement Coverage

| Requirement | Planned affordance | Fidelity |
| --- | --- | --- |
| Monthly matrix | galAttRows × galAttCells (Classic/Button cells) in one horizontal scroll region with day header + totals footer | Exact |
| Month/year picker | ◀ / "September 2026" / ▶ / This month | Exact |
| Campus + teacher picker | ddAttCampus, ddAttTeacher enabled per role | Exact |
| Tap to set/cycle | cell tap blank→P→A→confirm clear | Exact |
| Mark all present for a day | "All" Classic button under each day number (tooltip "All present – date"); full "All present" button in Day view | Approximation: 34–40 px columns cannot fit the words "All present"; label shortened to "All" with full tooltip |
| Non-school shading | grey cells + grey day header, disabled, tooltip reason | Exact |
| Not-enrolled locked | "–" pale disabled cells | Exact |
| One record per save, upsert | server LookUp by Student+Service+Date → Patch(Coalesce(server, Defaults)) | Exact |
| saved / saving / failed | "✓" / "…" / "!" in the cell, Day view status line | Exact |
| Concurrent edit warning | Modified On compare; conflict receipt strip | Exact |
| Soft delete with confirm + audit | conAttConfirm panel; Is Deleted; Audit Events row | Exact |
| Row/column totals | lblAttRowTotal, lblAttDayTotal, lblAttFootTotal | Exact |
| Detail panel | Details mode toggle + conAttDetail | Exact |
| Phone Day view | ModernTabList Month/Day (Day default < 640) | Exact |
| Screen-reader labels | AccessibleLabel on modern controls; Classic/Button cells use Tooltip | Approximation: Classic/Button has no AccessibleLabel (approved) |
| 44 px touch targets | ModernButtons 44 px; grid cells 34–40 × 40 | Approximation: approved dense desktop grid; phone uses Day view |

## Required Record Fields

| Field key | Screen | Record surface | Required field | Source field | Presentation requirement |
| --- | --- | --- | --- | --- | --- |
| ATT-ROW-NAME | Screen1 | Grid row | Student full name | Students.'Display Name' | Full text, first column, 2-line wrap |
| ATT-CELL-STATUS | Screen1 | Grid cell | P/A/E/U letter or "–" | Attendance.Present, 'Absence Classification'; enrollment | Letter + colour |
| ATT-CELL-SAVE | Screen1 | Grid cell | saving/saved/failed | colCellState | "…" / "✓" / "!" |
| ATT-CELL-REASON | Screen1 | Grid cell | Why locked | colMonthCells.Reason | Tooltip |
| ATT-ROW-TOTAL | Screen1 | Grid row | Days present | Attendance.Present | Number, last column |
| ATT-COL-TOTAL | Screen1 | Grid footer | Students present per day | Attendance.Present | Number under each day |
| ATT-HEAD-DAY | Screen1 | Grid header | Weekday + day number | colMonthDays | "Mon" / "28" |
| ATT-DAY-NAME | Screen1 | Day view row | Student full name | Students.'Display Name' | Line 1 |
| ATT-DAY-STATUS | Screen1 | Day view row | Status + save state | Attendance / colCellState | Line 2 |
| ATT-DETAIL-ID | Screen1 | Detail panel | Student + date | Students, varDetailKey | Title |
| ATT-DETAIL-FACTS | Screen1 | Detail panel | Status, IEP ratio, classification, reason, key | Attendance | One wrapped line, labelled |
| ATT-DETAIL-NOTES | Screen1 | Detail panel | Notes | Attendance.Notes | Editable multiline |
| ATT-HEADER-ID | Screen1 | Header | User, role, campus | Users.'Full Name', Staff | Always visible |

## State-Driven Surface Visibility

| Surface key | Owner screen | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- | --- |
| SV-NOTSETUP | Screen1 | conAttNotSetUp | `=!StaffReady` | No/inactive Staff row / otherwise |
| SV-TOOLBAR | Screen1 | conAttToolbar | `=StaffReady` | Set up / not set up |
| SV-NOTICE | Screen1 | conAttNotice | `=StaffReady && lblAttNotice.Text <> ""` | Lock, read-only, load error / none |
| SV-LOADING | Screen1 | spnAttLoading | `=varLoading` | During load / idle |
| SV-RECEIPT | Screen1 | conAttReceipt | `=varLastAction.Kind <> ""` | After mutation/cancel/block / dismissed |
| SV-CONFIRM | Screen1 | conAttConfirm | `=varConfirmOpen` | Clear requested / confirmed, cancelled, reloaded |
| SV-DETAIL | Screen1 | conAttDetail | `=varDetailOpen` | Details tap / closed |
| SV-MONTH | Screen1 | conAttMonthView | `=StaffReady && tabAttView.Selected.Value <> "Day"` | Month tab / Day tab |
| SV-DAY | Screen1 | conAttDayView | `=StaffReady && tabAttView.Selected.Value = "Day"` | Day tab / Month tab |
| SV-EMPTY | Screen1 | lblAttEmpty | `=CountRows(colMonthStudents) = 0 && !varLoading` | No students / students |
| SV-GRID | Screen1 | conAttGridScroll | `=CountRows(colMonthStudents) > 0` | Students / none |

## Action Contracts

| Requested action | Preconditions | Entry point | Owner screen | Control and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-LOAD-IDENTITY | App start | Header | Screen1 | App.Formulas CurrentStaff; App.OnStart | Users 'Primary Email' → Staff.User | role flags; varCampus/varTeacher | N/A | N/A | lblAttIdentity; SV-NOTSETUP |
| A-PICK-CAMPUS | CanPickCampus | ddAttCampus | Screen1 | ddAttCampus.OnChange | Campuses.Campus | varCampus; varTeacher = first teacher; reload | N/A | N/A | ddAttTeacher.Items; galAttRows |
| A-PICK-TEACHER | CanPickTeacher | ddAttTeacher | Screen1 | ddAttTeacher.OnChange | Staff.Staff | varTeacher; reload | N/A | N/A | galAttRows |
| A-NAV-MONTH | StaffReady, !varLoading | ◀ ▶ This month | Screen1 | btnAttPrevMonth/NextMonth/ThisMonth.OnSelect | varMonthStart | month change; reload | N/A | N/A | lblAttMonth; galAttDayHead |
| A-LOAD-MONTH | any | OnVisible, pickers, nav, ↻ | Screen1 | btnAttLoadEngine.OnSelect | Dataverse filters by Teacher.Staff + month | collections rebuilt; varCanEditMonth | N/A | N/A | galAttRows; lblAttEmpty; spnAttLoading; lblAttNotice |
| A-MARK-CELL (blank→P, P→A, restore) | cell Open, varCanEditMonth, not details mode, not saving | btnAttCell | Screen1 | btnAttCell.OnSelect → varSaveReq → btnAttSaveEngine.OnSelect | Attendance by Student+Service+Date; row GUID `Attendance` | conflict check; Patch(Coalesce(server, Defaults)) Present per Target, Is Deleted=No, snapshots; colMonthAtt replaced from result | Present, Is Deleted, Record Key, Date, Student, Service, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio | name, date, Status, IEP, Teacher, Term, Key from `written`; Kind Saved/Restored | btnAttCell letter/fill + teal focus border; row/column totals; lblAttReceipt |
| A-CLEAR-CELL | active row (A/E/U in Month; any in Day view), Editable | absent cell tap / btnAttDayClear | Screen1 | conAttConfirm → btnAttConfirmClear.OnSelect → btnAttSaveEngine | same GUID | Patch Is Deleted=Yes; Audit Events Soft Delete (Entity ID = GUID) | Is Deleted; Audit Events Summary, Action, Entity, Entity ID, Before, After, Reason | name, date, "Is Deleted = Yes", Key, audit written/NOT | cell blank; totals; lblAttReceipt |
| A-CLEAR-CELL (cancel) | confirm visible | Cancel | Screen1 | btnAttConfirmCancel.OnSelect | N/A | no write | N/A | "Clear cancelled · name · date · record unchanged" | cell unchanged; receipt |
| A-DAY-ALL-PRESENT | varCanEditMonth; ≥1 Open cell that day | "All" (header) / "All present" (Day view) | Screen1 | btnAttDayAll / btnAttDayAllPresent.OnSelect → btnAttBulkEngine | per student key | Open cells w/o active row → Present=Yes; others skipped | per row as blank→P | date; marked/skipped/failed counts | column "P✓"; lblAttDayTotal; receipt |
| A-VALIDATE-SAVE | cell not Open / locked / read-only / future | cells, Day buttons, All | Screen1 | DisplayMode gates + engine guards | colMonthCells.State, varCanEditMonth | no write | N/A | Blocked receipt if engine reached | disabled + tooltip; lblAttNotice |
| A-RETRY-CELL | SaveState failed | "!" cell / Day button | Screen1 | btnAttCell.OnSelect (stored Target) | same key | engine re-run | as retried action | as retried action | "!" → letter; receipt |
| A-OPEN-DETAIL | Details mode, active row | Details mode + cell | Screen1 | btnAttDetailsMode.OnSelect; btnAttCell.OnSelect | colMonthAtt StudentId+DayNum | panel open | N/A | N/A | conAttDetail |
| A-SAVE-NOTES | panel open, active row, varCanEditMonth | Save notes | Screen1 | btnAttDetailSave.OnSelect | Attendance GUID | Modified On check; Patch Notes | Notes | name, date, Notes, Key | txtAttDetailNotes; lblAttReceipt |
| A-SWITCH-VIEW | StaffReady | Month/Day tabs | Screen1 | tabAttView selection | N/A | Selected.Value switches SV-MONTH/SV-DAY | N/A | N/A | panel visibility |
| A-DAY-MARK | Day row Editable | Present / Absent | Screen1 | btnAttDayPresent/btnAttDayAbsent.OnSelect → btnAttSaveEngine | as A-MARK-CELL | as A-MARK-CELL | as A-MARK-CELL | as A-MARK-CELL | lblAttDayStatus; receipt; grid |

No arithmetic or listed opposing directional pair (Receive/Issue etc.) exists; Present/Absent
and Clear/Restore are explicit literal targets ("P", "A", "clear") with separate scenarios, so
the Directional Mutation Evidence and Compound Sequence tables are not applicable. No
create-to-later continuation contract. No time-of-day ordering (dates are typed Date).

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-MARK-CELL / A-DAY-MARK | `written` → varLastAction.Message → lblAttReceipt | Attendance row by alternate key | btnAttCell / lblAttDayStatus / totals via colMonthAtt | key → `written.Attendance` = AttId | RemoveIf + Collect(ATT_ROW(written)) on success only | teal 3 px border on the cell matching varLastAction StudentId+DayNum |
| A-CLEAR-CELL | `written` + `audit` → lblAttReceipt | Attendance.'Is Deleted'; Audit Events Entity ID | cell blank (`!IsDeleted` filter) | same GUID | as above | as above |
| A-DAY-ALL-PRESENT | colBulkLog counts → lblAttReceipt | per-row Attendance | column cells, lblAttDayTotal | per key | per-row ATT_ROW(written) | "✓" on each written cell |
| A-SAVE-NOTES | `written` → lblAttReceipt | Attendance.Notes by GUID | txtAttDetailNotes (colMonthAtt) | AttId | ATT_ROW(written) | panel keyed by varDetailKey |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| Mark | Present | Changed | varSaveReq.Target | `Present: req.Target = "P"` | "Status " & WORD(written) | btnAttCell |
| Mark | Is Deleted | Changed (→ No) | server | `'Is Deleted': false` | Kind Saved/Restored | btnAttCell |
| Mark | Record Key, Date, Student, Service | Changed (identity) | cell, enrollment segment | write set | "Key " & written.'Record Key' | lblAttDetailFacts |
| Mark | IEP Ratio, Teacher, Term | Changed (snapshot) | enrollment segment, varTeacher, term | write set | "IEP", "Teacher", "Term" in receipt | lblAttDetailFacts (IEP) |
| Mark | Enrollment, Campus, School Year | Changed (system snapshot) | seg.EnrRec | write set | not rendered; verify on Dataverse row | Dataverse |
| Mark | Absence Classification, Absence Reason, Notes | Preserved | server row | omitted from Patch | lblAttDetailFacts | lblAttDetailFacts |
| Clear | Is Deleted | Changed (→ Yes) | active local row | `{'Is Deleted': true}` | "Is Deleted = Yes" | cell blank |
| Clear | Present, Notes, snapshots | Preserved | server row | omitted | restored value on re-mark | colMonthAtt row kept (IsDeleted) |
| Clear | Audit Events row | Changed (created) | — | Patch('Audit Events', Defaults(...)) | "audit event written"/"NOT written" | Audit Events table |
| Notes | Notes | Changed | txtAttDetailNotes.Text | `{Notes: newNotes}` | "Notes \"…\"" | txtAttDetailNotes |
| Notes | all other fields | Preserved | server row | omitted | — | lblAttDetailFacts |

## Functional Test Matrix

Seed: Seed Campus Alpha, first teacher alphabetically (T1), its first students S1..S4;
Sep 2026; today Mon Sep 28 2026 (no records yet; Sep 26–27 weekend; Sep 29–30 future);
AllowFutureDates "false"; developer Adam = System Admin (blank campus).

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-IDENT-ROLE | Adam signs in | open | admin flags; campus Alpha; teacher T1 | lblAttIdentity; pickers enabled | N/A |
| S-IDENT-MISSING | user without Staff row | open | nothing loads | conAttNotSetUp | inactive Staff same |
| S-SCOPE-TEACHER | App Role Teacher at Alpha | open | varTeacher = self | pickers Disabled | cannot pick another teacher |
| S-SCOPE-OFFICE | Attendance Office, Beta | pick 2nd Beta teacher | reload | campus Disabled = Beta; teacher list Beta only | N/A |
| S-PICK-CAMPUS-ADMIN | Adam | pick Gamma | first Gamma teacher; reload | ddAttTeacher; galAttRows | N/A |
| S-MONTH-NEXT | Sep 2026 | ▶, This month | Oct 2026 (future cells dashed) then Sep | lblAttMonth | N/A |
| S-LOAD-MONTH | Adam, T1, Sep 2026 | open | colMonthAtt = T1 Sep rows | letters Sep 1–25; spinner hides | load error banner |
| S-ROWS-TRANSFER | X: T1 Sep 1–14, T2 Sep 15– (create if absent) | view T1, T2 | complementary Open / "–" days | btnAttCell | N/A |
| S-MARK-PRESENT | S1 Sep 28 no row | tap cell | row key 20260928\|STU…\|SPED Present=Yes | "P✓"; totals +1; receipt Saved | N/A |
| S-MARK-ABSENT | S1 Sep 28 = P | tap | same GUID Present=No | "A✓"; totals −1; receipt | N/A |
| S-CLEAR-CONFIRM | S1 Sep 28 = A | tap → Confirm clear | Is Deleted=Yes; Audit Soft Delete | cell blank; receipt Cleared | audit failure → "NOT written" |
| S-CLEAR-CANCEL | S1 Sep 28 = A | tap → Cancel | no write | "A" stays; receipt cancelled | N/A |
| S-MARK-RESTORE | S1 Sep 28 soft-deleted | tap | same GUID Is Deleted=No, Present=Yes | receipt Restored | one row per key |
| S-BULK-DAY | Sep 28: S1 = P, others blank | "All" on 28 | others Present; S1 untouched | column "P✓"; footer; receipt counts | no Open cells → disabled |
| S-BLOCK-NONSCHOOL | Sat Sep 26 | tap | no write | grey, disabled, tooltip Weekend | holiday exception reason |
| S-BLOCK-NOTENROLLED | X in T1, Sep 21 | tap | no write | "–" disabled | N/A |
| S-BLOCK-FUTURE | Tue Sep 29 | tap / Day view | no write | dashed disabled; Day buttons disabled | AllowFutureDates "true" |
| S-BLOCK-LOCKED | Month Lock Alpha 2026-08-01 Locked "Audit close" | ◀ to Aug | read-only | lblAttNotice with reason | N/A |
| S-BLOCK-READONLY | Read-only role | open | read-only | notice "View only"; notes View | N/A |
| S-FAIL-RETRY | offline | tap S2 Sep 28 | no row; rollback | "!"; receipt Failed | online → tap "!" → "P✓" |
| S-CONFLICT | 2nd session marks S3 Sep 28 P | 1st session taps S3 Sep 28 | no write; local refreshed | "P"; receipt Conflict | Modified On mismatch same |
| S-DETAIL-NOTES | Details mode; S1 Sep 25 recorded | tap; type; Save notes | Notes updated | receipt Notes saved; panel | conflict → not saved |
| S-DAYVIEW-MARK | Day tab, Sep 28 | Present then Absent on S4 | same engine writes | lblAttDayStatus; receipt; grid | non-school → notice |
| S-EMPTY | teacher/month without enrollments | load | empty | lblAttEmpty | N/A |

24 scenarios, all assigned to `Screen1.screen-plan.md`.

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| ddAttCampus | lblAttCampus `="Campus"` | conAttCampusField |
| ddAttTeacher | lblAttTeacher `="Teacher"` | conAttTeacherField |
| txtAttDetailNotes | lblAttDetailNotesLabel `="Notes"` | conAttDetailNotesField |

## Layout Budget Contracts

| Screen / container | Branch / screen-width source | Horizontal total-width arithmetic | Vertical height arithmetic | Protected controls |
| --- | --- | --- | --- | --- |
| Screen1 / conAttToolbar | conAttRoot.Width ≥ 1240 | 16+380+8+300+8+350+16 = 1078 ≤ 1240 | 8+58+8 = 74 | month nav, pickers, view switch |
| Screen1 / conAttToolbar | < 1240 (stacked) | each group ≤ 358 (300 / 300 / 350) | 8+3×58+2×8+8 = 206 | same |
| Screen1 / conAttGridInner | conAttRoot.Width | 180 + days×CellW + total; Wd ≥ 236+34×days (1290 for 31) → no scroll at 1366, scroll below | 64 + RowsH(132–528) + 36 | cells, All buttons, totals |
| Screen1 / conAttReceipt | < 640 / < 1024 / else | text + 8 + 88 + 24 | 124 / 64 / 56 (6 / 2 / 1 lines) | full receipt message |
| Screen1 / conAttDetail | < 640 / else | 120+8+88 ≤ 326 | 308 / 264 | notes input, Save notes |
| Screen1 / conAttConfirm | < 640 / else | 132+8+96 ≤ 334 | 140 / 116 | Confirm clear, Cancel |
| Screen1 / conAttDayRow | galAttDayList template | 100+8+100+8+88 = 304 ≤ 322 | 112 ≤ TemplateSize 116 | Present, Absent, Clear |
| Screen1 / conAttDayNav | phone 358 | 232 + label ≥ 100 | 44 | All present |

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| --- | --- | --- | --- | --- | --- |
| Screen1 | conAttRoot | AutoLayout | `conAttRoot.Width: =Parent.Width` | `conAttRoot.Height: =Parent.Height` | Vertical scroll; grid region scrolls horizontally |

## Working Directory

C:\src\aaca-attendance\app

## Discovery Summary

- Controls: GroupContainer, ModernText, ModernButton, Classic/Button, Gallery,
  ModernDropdown, ModernTabList, ModernTextInput, ModernSpinner (definitions in the brief).
- Data sources (Dataverse): Users, Staff, Campuses, Enrollments, Attendance, Calendar
  Exceptions, Terms, Month Locks, App Settings, Audit Events (Students, Services, School
  Years, Absence Reasons via lookups).
- Connectors: none (Users API not used).
- Gap: Absence Reasons primary-name column is absent from the packet; the brief assumes
  `'Absence Reason'.Name` in one binding (lblAttDetailFacts). Verify at compile.
- Runtime notes (not settable in YAML): raise App settings → Data row limit to 2000 so
  `ForAll(Filter(...))` month loads are not truncated at 500 rows; apps must have "Scale to
  fit" off for responsive widths.

## Dispatch

| Action | Screen | Target File | YAML Key | Name Prefix | Screen Brief |
| --- | --- | --- | --- | --- | --- |
| Create | Attendance | `C:\src\aaca-attendance\app\Screen1.pa.yaml` | Screen1 | Att | `C:\src\aaca-attendance\app\Screen1.screen-plan.md` |

## Editor State Changes

None (ScreensOrder stays `Screen1`; no component definitions).
