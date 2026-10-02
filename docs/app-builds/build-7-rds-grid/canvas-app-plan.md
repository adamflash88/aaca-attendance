# Canvas App Plan - AACA Billing build 7 (RDS grid)

## Mode

EDIT. Existing app "AACA Billing" (app 1d5dc650-cc68-4a25-8f71-a7cb591ed3c7, Dev env a4c9f4ce-b971-edf2-beba-e3c29552a316).
Source folder `C:\src\aaca-attendance\billing-app` (HomeScreen, FundersScreen, ServicesScreen, StudentsScreen; compiled
and saved by the user).

## Requirements

Authoritative and unmodified: `C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid\canvas-app-requirements.md`.
Summary: new read-only `RdsScreen` (Register of Daily Services) for one student + funder + month: pickers (month with
Previous/Next, funder, student), a document-style header, a day grid (SAI attendance row, day-service rows, clinical
minute rows, totals), school-day shading per campus, amber review flag, footer (legend, totals, CodeMetro data note,
open upload exceptions), empty states, finance gate. Plus ONE new nav button "RDS Grid" on each of the four existing
screens (add only; never move, rename or re-parent existing controls).

## Original Request Capability Inventory

The requirements contract is prose; the planner assigns these stable keys.

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Observer(s) | Scenario(s) |
| --- | --- | --- | --- | --- | --- | --- |
| R7-01 | New nav button "RDS Grid" in the header nav of all four existing screens; new screen RdsScreen | 1 Shell | `btn<P>NavRds` appended to `con<P>Nav` on Home/Funders/Services/Students, plus 5-button nav on RdsScreen | A-RDS-NAV, A-NAV-REG | `btnHomeNavRds`, `btnFunNavRds`, `btnSvcNavRds`, `btnStuNavRds`, `btnRdsNavRds` (current) | S-RDS-NAV, S-NAV-REG |
| R7-02 | Month picker (month + year), default latest month with Service Deliveries else this month; Prev / Next | 6 Time | `varRdsMonth` first-of-month; default set once on first visit | A-RDS-LOAD, A-RDS-MONTH-PREV, A-RDS-MONTH-NEXT | `lblRdsMonth` | S-RDS-MONTH-DEFAULT, S-RDS-MONTH-PREV, S-RDS-MONTH-NEXT |
| R7-03 | Funder dropdown: active funders with deliveries in the month, or DoR / Student Services overlapping the month; label "ABBR - Full name (type)" | 3 Exploration | `colRdsFunderOpts` built by `btnRdsMonthEngine` | A-RDS-MONTH-OPTS, A-RDS-FUNDER | `ddRdsFunder` options | S-RDS-FUNDER-OPTS |
| R7-04 | Student dropdown: students with something for that funder in the month; label "Last, First (KEY)" | 3 | `colRdsStudentOpts` built by `btnRdsGridEngine` | A-RDS-FUNDER, A-RDS-STUDENT | `ddRdsStudent` options | S-RDS-STUDENT-OPTS |
| R7-05 | Changing month or funder keeps the student if still valid | 3 / 2 | selection IDs retained when present in rebuilt option lists, else cleared | A-RDS-KEEP | `ddRdsStudent.Default`, grid | S-RDS-KEEP, S-RDS-KEEP-INVALID |
| R7-06 | Header block: "Register of Daily Services", student name + key, funder abbreviation + full name + type, month + year, campus (enrollment overlapping month; "Regional Center Only" for RC students), district of record for the month | 2 Read | document header | A-RDS-GRID | `lblRdsDocTitle`, `lblRdsDocStudent`, `lblRdsDocMeta1`, `lblRdsDocMeta2` | S-RDS-HEADER, S-RDS-RC |
| R7-07 | Grid: label column (code + name, "#n" for repeated services), one column per day 1..last (day number + weekday letter), Total column | 7 Visualization | `galRdsDayHead` + `galRdsRows` / `galRdsCells` | A-RDS-GRID | `lblRdsDayNum`, `lblRdsDayDow`, `lblRdsRowLabel`, `lblRdsCell`, `lblRdsRowTotalMain/Sub` | S-RDS-GRID-COLS, S-RDS-DAYSVC-MULTI |
| R7-08 | Row A SAI - Special Education (funder not RC and student's DoR for part of month), from Attendance not deleted: "1" present, "0" absent green excused / red unexcused / plain unclassified; blank when no record; total present days + "absent n" | 7 / 6 | SAI row + cells | A-RDS-GRID | SAI row cells and totals | S-RDS-SAI, S-RDS-SAI-ABSENT, S-RDS-SAI-DORPART |
| R7-09 | Day-service rows (funder not RC): Student Services for student + funder, Excluded false, Kind School Day, overlapping month; "1" when present and date in row Start/End; total days; each row its own grid row | 7 / 5 | DAY rows | A-RDS-GRID | DAY row cells, totals | S-RDS-DAYSVC, S-RDS-DAYSVC-MULTI |
| R7-10 | Clinical rows: deliveries for student + funder in month grouped by service, sorted by Sort Order; cell = minutes; total minutes + hours (2 dp) + billing unit; Billable = false shows "not billable" muted | 7 | CLIN rows | A-RDS-GRID | CLIN row cells, totals | S-RDS-CLIN, S-RDS-CLIN-NOTBILL |
| R7-11 | RC grids: only RC clinical services, no attendance rows; District / private-pay grids: only non-RC services | 7 / 10 | rows scoped by selected funder; SAI/DAY rows only when funder TypeText <> "Regional Center" | A-RDS-GRID | row set | S-RDS-RC, S-RDS-PRIVPAY |
| R7-12 | Non-school days (weekends, campus holidays) shaded on all rows except services billable on non-school days; same rule as attendance app; RC-only (no campus) weekends only | 6 Time | `colRdsDays.IsSchoolDay` per day per campus; cell State "nonschool" unless row NonSchool | A-RDS-GRID | `lblRdsCell.Fill`, `conRdsDayHeadCell.Fill`, `lblRdsNonSchool` | S-RDS-SHADE, S-RDS-SHADE-NS, S-RDS-RC-WEEKEND |
| R7-13 | Clinical minutes on a shaded non-school day for a service not billable on non-school days flagged amber with a legend entry | 7 / 4 | cell State "flag" -> `ColorFlag` | A-RDS-GRID | `lblRdsCell.Fill`, `lblRdsLegFlag` | S-RDS-FLAG |
| R7-14 | Footer: legend; "Totals: SAI n days, <service> n days ..., clinical n min (h.hh h)"; latest CodeMetro upload name, date range, Rows in = matched + exceptions; count of Open Upload Exceptions dated in the month | 7 / 9 | footer labels | A-RDS-GRID, A-RDS-MONTH-OPTS | `conRdsLegend`, `lblRdsTotals`, `lblRdsDataNote`, `lblRdsExcNote` | S-RDS-FOOTER, S-RDS-NOUPLOAD |
| R7-15 | Absences shown excused/unexcused/unclassified only with caption that billable-absence flags are coming; no month close / export / PDF buttons | 1 | `lblRdsAbsenceNote`; no such buttons | A-RDS-GRID | `lblRdsAbsenceNote` | S-RDS-FOOTER, S-RDS-READONLY |
| R7-16 | Empty states: no funder/student selected; no rows for the selection | 1 | `conRdsEmpty`, `lblRdsNoRows` | A-RDS-EMPTY | `lblRdsEmptyText`, `lblRdsNoRows` | S-RDS-EMPTY-SEL, S-RDS-EMPTY-NOFUNDERS, S-RDS-EMPTY-ROWS |
| R7-17 | Same access gate; read-only (no writes) | 10 | `conRdsGate`; no Patch/Remove on the screen | A-RDS-GATE | `conRdsGate.Visible` | S-RDS-GATE, S-RDS-READONLY |
| R7-18 | Delegation-safe loading; ~2,900 deliveries/month; do not rely on the row limit | 9 / 10 | day-paged pairs load; per-selection loads delegable; page-cap warning | A-RDS-MONTH-OPTS, A-RDS-GRID | `lblRdsStatus` | S-RDS-DELEG, S-RDS-LOAD-FAIL |
| R7-19 | Fit 31 days at 1366 (day ~30, label ~220, totals ~110); horizontal scroll inside grid below that; printable look | 1 | `conRdsGridScroll` / `conRdsGridInner` width math | A-RDS-GRID | grid geometry | S-RDS-FIT-1366, S-RDS-FIT-1024 |
| R7-20 | Regression: existing screens unchanged except the added button (Home "Coming next" text corrected) | 1 | existing nav/controls untouched | A-NAV-REG, A-HOME-NEXT | existing nav buttons, `lblHomeNextBody` | S-NAV-REG, S-HOME-NEXT |

## Requirement Coverage

| Requirement | Planned affordance | Fidelity |
| --- | --- | --- |
| "RDS Grid" nav button | `btn<P>NavRds` ModernButton (Secondary, "RDS Grid", 110 wide) appended LAST in each existing `con<P>Nav`; RdsScreen nav shows it as current (teal Primary) | Exact (appended after Students; Studio ScreensOrder puts RdsScreen after Home) |
| Month picker + Prev/Next | "Previous" / "Next" ModernButtons around `lblRdsMonth` ("September 2026") | Exact |
| Default month | First visit only: month of the latest Service Delivery (delegated `First(Sort(... Date desc))`), else this month; Sep 2026 in Dev | Exact |
| Funder dropdown | `ddRdsFunder` over `colRdsFunderOpts`; text "ABBR – Full name (type)" (en dash) | Exact |
| Student dropdown | `ddRdsStudent` over `colRdsStudentOpts`; text "Last, First (KEY)" | Exact |
| Keep student when still valid | engines clear `varRdsFunderId` / `varRdsStudentId` only when absent from rebuilt options | Exact |
| Document header | `conRdsDocHead`: title, student, funder + month line, campus + DoR line | Exact |
| Campus | campus name(s) of enrollments overlapping the month (comma list if transferred); "Regional Center Only"; "No enrollment in this month" | Exact; per-day shading uses the enrollment covering that day |
| Grid | ModernText cells in horizontal galleries (same colours, thin rules) | Approximation: reference grid uses Classic/Button cells; this screen is read-only so cells are non-interactive ModernText (accessible, nothing clickable). Holiday names appear in `lblRdsNonSchool` instead of tooltips |
| SAI row | Row only if funder not RC and a DoR row for this student + funder overlaps the month; cells outside the DoR dates are blank with the "outside" fill | Exact (outside-DoR days blank = district not billed those days) |
| Day-service rows | one row per Student Services row; excludes SPED (SAI is from attendance) | Exact |
| Clinical rows | every service with deliveries for student + funder + month, sorted by Sort Order then label | Exact (a School Day service that appears in deliveries also shows as a minutes row, so no delivered minutes are hidden) |
| Non-school shading | per-day campus rule copied from attendance app (term for campus, weekend unless Make-up, any non-Make-up exception for campus or all) | Exact; Calendar Exceptions types are Holiday/Break/Staff Development/Closure (all non-school) |
| Amber review flag | `ColorFlag` fill (new named colour) + legend chip | Exact |
| Footer | legend chips, non-school list, totals line, absence caption, data note with tie-out, open exceptions count | Exact |
| Read-only | no Patch/Remove anywhere on RdsScreen | Exact |
| Printable | white document panel, 1px rules, no buttons inside the document | Exact (no print/PDF button, per requirements) |

## Required Record Fields

| Field key | Screen | Record surface | Required field | Source field | Presentation requirement |
| --- | --- | --- | --- | --- | --- |
| RF-RDS-STUDENT | RdsScreen | document header | student name + key | colStudents.DisplayName, StudentKey | `lblRdsDocStudent` 16 Semibold full text |
| RF-RDS-FUNDER | RdsScreen | document header | funder abbr + full name + type | colFunders.Abbr, FullName, TypeText | `lblRdsDocMeta1` |
| RF-RDS-MONTH | RdsScreen | document header | month name + year | varRdsMonth | `lblRdsDocMeta1` |
| RF-RDS-CAMPUS | RdsScreen | document header | campus | varRdsCampusText | `lblRdsDocMeta2` |
| RF-RDS-DOR | RdsScreen | document header | district(s) of record for the month | colDor overlapping month + colFunders.Abbr | `lblRdsDocMeta2` |
| RF-RDS-ROWLABEL | RdsScreen | grid row | service code + name (+ "#n", "not billable") | colRdsRows.Label, IsBillable | `lblRdsRowLabel` 220 wide, 2 lines |
| RF-RDS-CELL | RdsScreen | grid cell | day value + state colour | colRdsCells.CellText, State | `lblRdsCell` |
| RF-RDS-TOTAL | RdsScreen | grid row | total (+ absent n / hours + unit) | Sum of colRdsCells.CellNum | `lblRdsRowTotalMain`, `lblRdsRowTotalSub` |
| RF-RDS-DAYHEAD | RdsScreen | grid header | day number + weekday letter | colRdsDays.DayNum, DowLetter | `lblRdsDayNum`, `lblRdsDayDow` |

## State-Driven Surface Visibility

| Surface key | Owner screen | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- | --- |
| SV-RDS-GATE | RdsScreen | `conRdsGate` | `=!IsFinance` | non-finance only |
| SV-RDS-PICKERS | RdsScreen | `conRdsPickers` | `=IsFinance` | finance only |
| SV-RDS-EMPTY | RdsScreen | `conRdsEmpty` | `=IsFinance && (IsBlank(varRdsFunderId) \|\| IsBlank(varRdsStudentId))` | until both picked |
| SV-RDS-DOC | RdsScreen | `conRdsDoc` | `=IsFinance && !IsBlank(varRdsFunderId) && !IsBlank(varRdsStudentId)` | both picked |
| SV-RDS-NOROWS | RdsScreen | `lblRdsNoRows` | `=CountRows(colRdsRows) = 0` | selection has no rows (or loading) |
| SV-RDS-GRID | RdsScreen | `conRdsGridScroll` | `=CountRows(colRdsRows) > 0` | rows exist |

## Action Contracts

Read-only build: no mutations, so write set / proof set are N/A on every row and the mutation ledgers are omitted.

| Requested action | Preconditions | Entry point | Owner screen | Control and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-RDS-NAV | IsFinance | "RDS Grid" in any header nav | Home, Funders, Services, Students, RdsScreen | `btn<P>NavRds.OnSelect: =Navigate(RdsScreen)` | N/A | RdsScreen shown | N/A | N/A | `btnRdsNavRds` teal Primary, `conRdsPickers` visible |
| A-NAV-REG | IsFinance | existing nav buttons | all | existing `btn<P>Nav*` unchanged | N/A | unchanged navigation | N/A | N/A | destination nav button Primary |
| A-HOME-NEXT | always | Home | Home | `lblHomeNextBody.Text` | N/A | text no longer lists the RDS grid as a later phase | N/A | N/A | `lblHomeNextBody` |
| A-RDS-GATE | not finance | open RdsScreen | RdsScreen | `conRdsGate.Visible`; `btnRdsLoadEngine` `!IsFinance` branch clears collections | Staff via IsFinance | only gate shows; no data | N/A | N/A | `conRdsGate.Visible = !IsFinance` |
| A-RDS-LOAD | IsFinance | `RdsScreen.OnVisible: =Select(btnRdsLoadEngine)` | RdsScreen | `btnRdsLoadEngine.OnSelect` | Funders, Services, Students, Districts of Record, Student Services (shared verbatim ClearCollects); Service Deliveries for default month | collections loaded; if `varRdsMonth` blank -> month of latest delivery else this month; then `Select(btnRdsMonthEngine)` | N/A | N/A | `lblRdsMonth`, `lblRdsStatus` |
| A-RDS-MONTH-PREV | not loading | "Previous" | RdsScreen | `btnRdsPrevMonth.OnSelect` | varRdsMonth | month - 1 (Date() rollover), `Select(btnRdsMonthEngine)` | N/A | N/A | `lblRdsMonth` "August 2026" |
| A-RDS-MONTH-NEXT | not loading | "Next" | RdsScreen | `btnRdsNextMonth.OnSelect` | varRdsMonth | month + 1, `Select(btnRdsMonthEngine)` | N/A | N/A | `lblRdsMonth` |
| A-RDS-MONTH-OPTS | month set | month engine | RdsScreen | `btnRdsMonthEngine.OnSelect` | Service Deliveries (31 day pages), Terms, Calendar Exceptions, CodeMetro Uploads, Upload Exceptions | colRdsMonthPairs, colRdsPageLog, colRdsTerms, colRdsCalEx, colRdsUploads, colRdsExc, colRdsFunderOpts rebuilt; invalid funder cleared; `Select(btnRdsGridEngine)` | N/A | N/A | `ddRdsFunder` options, `lblRdsStatus`, `lblRdsDataNote`, `lblRdsExcNote` |
| A-RDS-FUNDER | options loaded | `ddRdsFunder` pick | RdsScreen | `ddRdsFunder.OnChange` | `Selected.FunderId` -> `varRdsFunderId` | `Select(btnRdsGridEngine)` rebuilds student options and grid | N/A | N/A | `ddRdsStudent` options, header |
| A-RDS-STUDENT | funder chosen | `ddRdsStudent` pick | RdsScreen | `ddRdsStudent.OnChange` | `Selected.StudentId` -> `varRdsStudentId` | grid loaded for student + funder + month | N/A | N/A | `conRdsDoc` visible |
| A-RDS-KEEP | month or funder changed | Previous/Next or funder pick | RdsScreen | month / grid engines | varRdsFunderId, varRdsStudentId | each ID kept when `LookUp(<opts>, Id = var)` is non-blank, else `Blank()` | N/A | N/A | dropdown Defaults, grid |
| A-RDS-GRID | funder + student set | grid engine | RdsScreen | `btnRdsGridEngine.OnSelect` | Service Deliveries (student+funder+month), Attendance (student+month), Enrollments (student overlapping month), colDor, colStuSvc, colServices | colRdsDays, colRdsRows, colRdsCells rebuilt; varRdsCampusText | N/A | N/A | grid, header, footer totals |
| A-RDS-EMPTY | selection incomplete or no rows | automatic | RdsScreen | Visible predicates | state | empty panel / no-rows label | N/A | N/A | `lblRdsEmptyText`, `lblRdsNoRows` |

## Functional Test Matrix

Given data = Dev as captured (Sep 2026: 2,846 deliveries, 105 students, 24 funders; Attendance through 2026-09; 249
Student Services; 103 DoR). Testers pick concrete records from the lists; each row names what to pick.

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-RDS-NAV | Finance user on Home | Select "RDS Grid" (repeat from Funders, Services, Students) | RdsScreen opens | `btnRdsNavRds` teal Primary; pickers visible | N/A |
| S-NAV-REG | Finance user | On each existing screen use Home/Funders/Services/Students | unchanged navigation; existing controls render normally (no black boxes) | existing nav buttons | 5 buttons fit one row at 1024 |
| S-HOME-NEXT | Home | read Coming next | RDS grid no longer listed as a later phase | `lblHomeNextBody` | N/A |
| S-RDS-GATE | Finance Access = No | open RdsScreen | gate only; no pickers, no data; collections cleared | `conRdsGate` | no Staff row -> "not linked" text |
| S-RDS-MONTH-DEFAULT | first visit this session; latest delivery 2026-09-30 | open RdsScreen | month = September 2026 | `lblRdsMonth` | no deliveries at all -> current month |
| S-RDS-MONTH-PREV | September 2026 | Previous | August 2026; funder list rebuilt for August | `lblRdsMonth`, `ddRdsFunder` | Jan 2026 -> Previous -> December 2025 |
| S-RDS-MONTH-NEXT | August 2026 | Next | September 2026 | `lblRdsMonth` | Dec -> Next -> January next year |
| S-RDS-FUNDER-OPTS | Sep 2026 | open funder list | every active funder with a delivery in Sep 2026 (24 used), plus active funders with a DoR or Student Services row overlapping Sep; inactive funders absent; sorted by abbreviation | `ddRdsFunder` | funder with only an ended (Aug) DoR and no Sep deliveries absent |
| S-RDS-STUDENT-OPTS | funder F = a District with Sep deliveries | pick F; open student list | students with an F delivery in Sep, or DoR / Student Services for F overlapping Sep; "Last, First (KEY)"; sorted by name | `ddRdsStudent` | student with deliveries only for another funder absent |
| S-RDS-KEEP | student S has F deliveries in Aug and Sep | Sep, F, S shown; Previous | Aug grid for F + S loads without re-picking | `ddRdsStudent` shows S; header month August | N/A |
| S-RDS-KEEP-INVALID | S has nothing for F in Aug | Previous | student cleared; empty state "Choose a student..." | `conRdsEmpty` | funder absent in Aug -> funder cleared too |
| S-RDS-HEADER | F (District) + School student S at campus CW, DoR F from 7/1/2026 ongoing | pick | title, "Last, First (KEY)", "Funder: F – Full (District) · Month: September 2026", "Campus: <CW name> · District of record: F 7/1/2026 to ongoing" | `conRdsDocHead` | transfer mid-month -> both campus names listed |
| S-RDS-GRID-COLS | Sep 2026 | grid shown | 30 day columns 1..30 with letters (Sep 1 2026 = Tuesday "T"); Total column | `galRdsDayHead` | Feb 2027 -> 28 columns |
| S-RDS-SAI | S present 18 days in Sep, F is DoR all month | grid | SAI row first: "1" on 18 days; total "18 days" | SAI row | no attendance record -> blank cell |
| S-RDS-SAI-ABSENT | S absent: one Excused, one Unexcused, one unclassified | grid | green "0", red "0" (white text), plain "0"; sub-line "absent 3" | SAI cells, `lblRdsRowTotalSub` | deleted attendance rows ignored |
| S-RDS-SAI-DORPART | DoR for F ends 9/15 | grid | SAI cells 16..30 blank with "outside" fill; total counts 1..15 only | SAI row | funder Private Pay -> no SAI row |
| S-RDS-DAYSVC | S has Student Services 1:1 Aide for F, 9/1 ongoing, not excluded | grid | row "<code> – 1:1 Aide": "1" on each present day; total days = SAI present days in range | DAY row | Excluded row -> no grid row |
| S-RDS-DAYSVC-MULTI | S has two aide rows (2:1) | grid | two rows "... #1", "... #2"; second row starting 9/10 shows "outside" fill for 1..9 | DAY rows | N/A |
| S-RDS-CLIN | S has 97153 deliveries for F | grid | row "97153 – <name>": minutes per day; total "n min", "h.hh h · Hours"; rows ordered by Sort Order | CLIN row | day without delivery blank |
| S-RDS-CLIN-NOTBILL | a delivered service with Billable = false | grid | label "... · not billable" in muted colour | `lblRdsRowLabel` | N/A |
| S-RDS-RC | RC funder R; RC-only student with deliveries | pick R + student | no SAI / DAY rows; only R's clinical rows; campus "Regional Center Only"; DoR "None (Regional Center Only)" | grid, header | N/A |
| S-RDS-PRIVPAY | Private Pay funder P | pick P + student | no SAI row; P's clinical rows (and P's day-service rows if any) | grid | N/A |
| S-RDS-SHADE | CW campus, Sep 7 2026 Labor Day holiday (campus or all) | grid | Sep 5, 6, 7 shaded grey on SAI/DAY rows and on clinical rows of services not billable on non-school days | `lblRdsCell.Fill`, `conRdsDayHeadCell.Fill`, `lblRdsNonSchool` lists "Sep 7 Holiday - Labor Day" | Make-up School Day on a Saturday -> not shaded |
| S-RDS-SHADE-NS | FT service (Billable on Non-School Days) with Saturday minutes | grid | FT Saturday cell not shaded, not flagged | FT row | N/A |
| S-RDS-FLAG | 97153 (not billable on non-school days) has minutes on a Saturday | grid | that cell amber (`ColorFlag`), ink text | `lblRdsCell`, legend chip "Review: minutes on a non-school day" | same minutes on a school day -> plain |
| S-RDS-RC-WEEKEND | RC-only student, month with a campus holiday | grid | only Sat/Sun shaded | cells | N/A |
| S-RDS-FOOTER | grid with SAI, 1 aide row, 2 clinical rows | read footer | "Totals: SAI 18 days · <aide code> 18 days · clinical n min (h.hh h)"; legend; absence caption; data note "CodeMetro upload <file> (9/1/2026 to 9/30/2026, uploaded ...) · Rows in 3521 = matched m + exceptions e (ties out)"; "2 open upload exception(s) dated in September 2026" | footer labels | Rows in <> matched + exceptions -> "(DOES NOT TIE OUT)" in warning colour |
| S-RDS-NOUPLOAD | month with no Complete upload overlapping | read footer | "No completed CodeMetro upload covers <month>." | `lblRdsDataNote` | N/A |
| S-RDS-READONLY | any | inspect screen | no Patch/Remove/Save/Export/Close/PDF control exists | YAML + UI | N/A |
| S-RDS-EMPTY-SEL | no funder chosen | open | "Choose a funder ..." panel | `lblRdsEmptyText` | funder chosen, no student -> "Choose a student ..." |
| S-RDS-EMPTY-NOFUNDERS | month far in future (e.g. Next x6) | Next | "No funders have deliveries, districts of record or student services in <month>." | `lblRdsEmptyText` | N/A |
| S-RDS-EMPTY-ROWS | student in list only via a Student Services row for an RC funder (no deliveries) | pick | "No rows for this student, funder and month ..." | `lblRdsNoRows` | N/A |
| S-RDS-DELEG | Sep 2026 (~2,846 deliveries, max day page well under 500) | load | funder list complete (24 delivery funders present); no capped warning | `ddRdsFunder`, `lblRdsStatus` | a day page returning >= 500 rows -> warning text in `lblRdsStatus` |
| S-RDS-LOAD-FAIL | data source error | load | "Could not load - <error>" | `lblRdsStatus` | N/A |
| S-RDS-FIT-1366 | 1366 x 768, 31-day month | view grid | label 220 + 31 x 31 + total 119 = 1300 fits, no horizontal scroll | grid | N/A |
| S-RDS-FIT-1024 | 1024 wide | view grid | grid inner 1260 wide (day 30, total 110) scrolls horizontally inside `conRdsGridScroll`; pickers wrap to 2 lines | grid | N/A |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| `ddRdsFunder` | `lblRdsFunderCap` "Funder" | `conRdsFunderField` |
| `ddRdsStudent` | `lblRdsStudentCap` "Student" | `conRdsStudentField` |
| month (buttons, not an input) | `lblRdsMonthCap` "Month" | `conRdsMonthField` |

## Layout Budget Contracts

Root inner width W = conRdsRoot.Width - 32; panel inner w = conRdsRoot.Width - 66 (root pad 32 + panel pad 32 + border 2).
1366 -> w 1300; 1024 -> w 958; 640 -> w 574.

| Screen / container | Branch / screen-width source | Horizontal total-width arithmetic | Vertical height arithmetic | Protected controls |
| --- | --- | --- | --- | --- |
| all 5 / `con<P>Nav` | none (static) | 5 x 110 + 4 x 8 = 582 <= 608 (640 - 32) | 44 | all nav buttons incl. RDS Grid |
| RdsScreen / `conRdsPickerRow` (wrap) | w | 356 + 460 + 320 + 2 x 12 = 1160; 2 lines when w >= 828 (356 + 12 + 460); else 3 | If(w >= 1160, 66, w >= 828, 144, 222) | dropdowns, Previous/Next |
| RdsScreen / `conRdsMonthRow` | static | 96 + 8 + 140 + 8 + 96 = 348 <= 356 | 44 | Previous, Next |
| RdsScreen / `conRdsPickers` | w | N/A | 16 + rowH + 8 + 36 + 16 | status |
| RdsScreen / `conRdsDocHead` | static | Stretch | 28 + 24 + 40 + 40 + 3 x 4 = 144 | header fields |
| RdsScreen / grid | `conRdsGridInner.Width = Max(Parent.Width, 330 + 30 x days)` | 1366: 220 + 31 x 31 + 119 = 1300; 1024: inner 1260 scrolls in 958 | head 40 + rows Min(880, 44 x n) + 16 scrollbar | all day columns, totals |
| RdsScreen / `conRdsLegend` (wrap) | w | 90+96+110+130+130+260+140 + 6 x 8 = 1004 | If(w >= 1004, 28, w >= 560, 64, 100) | flag legend chip |
| RdsScreen / `conRdsFooter` | w | Stretch | legendH + 40 + 40 + 36 + 40 + 20 + 5 x 6 = legendH + 206 | totals, data note |
| RdsScreen / `conRdsDoc` | w | Stretch | 16 + 144 + 12 + If(rows = 0, 40, 56 + Min(880, 44 x rows)) + 12 + footerH + 16 | grid |

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| --- | --- | --- | --- | --- | --- |
| RdsScreen | `conRdsRoot` | AutoLayout | `conRdsRoot.Width: =Parent.Width` | `conRdsRoot.Height: =Parent.Height` | vertical scroll; grid scrolls horizontally inside `conRdsGridScroll` |
| Home / Funders / Services / Students | existing roots | AutoLayout | unchanged | unchanged | unchanged |

## Delegation approach (R7-18)

- Month-scoped option lists never request a month of deliveries at once. `btnRdsMonthEngine` pages Service Deliveries
  by DAY: `ForAll(Sequence(days) As n, ... Filter('Service Deliveries', Date = d) ...)` and keeps only
  `{StudentId, FunderId}` per row in `colRdsMonthPairs`. Sep 2026 averages ~130 rows per weekday, far under the 500
  default (and 2000 raised) row limit. Each page's count goes to `colRdsPageLog`; any page >= 500 sets
  `varRdsPageCapped` and `lblRdsStatus` warns that lists may be incomplete. Cost: up to 31 small sequential requests
  per month change.
- Funder options = active `colFunders` whose id is in `colRdsMonthPairs.FunderId` or that have a `colDor` / `colStuSvc`
  row overlapping the month (both collections are small full loads: 103 and 249 rows). Student options are built from the
  same `colRdsMonthPairs` filtered to the funder, plus `colDor` / `colStuSvc`. All of this is local after the pages.
- Grid loads are tiny and delegable: Service Deliveries `Student.Student = sid && Funder.Funder = fid && Date >= ms &&
  Date <= me` (<= ~31 x services rows), Attendance `Student.Student = sid` + month (<= ~31), Enrollments for the student
  overlapping the month, Terms / Calendar Exceptions / CodeMetro Uploads / Upload Exceptions filtered by month. All
  comparisons use With() scalars; deleted attendance is removed locally.
- Default month: delegated `First(Sort('Service Deliveries', Date, SortOrder.Descending)).Date`.

## Working Directory

Plans: `C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid`
App source (screen targets): `C:\src\aaca-attendance\billing-app`

## Discovery Summary

- Existing screens: HomeScreen (Home), FundersScreen (Fun), ServicesScreen (Svc), StudentsScreen (Stu); AutoLayout
  roots; named-formula palette and finance gate in App.Formulas.
- Controls used by this build: GroupContainer (AutoLayout), ModernText, ModernButton, ModernDropdown, Gallery
  (Vertical, Horizontal), Classic/Button (hidden engines). All described in the packet; no Canvas/Code components.
- Data sources read: Funders, Services, Students, Districts of Record, Student Services, Service Deliveries,
  Attendance, Enrollments, Terms, Calendar Exceptions, CodeMetro Uploads, Upload Exceptions (plus Staff/Users via
  existing App formulas). No writes. Connectors: none.

## Dispatch

| Action | Screen | Target File | YAML Key | Name Prefix | Screen Brief |
| --- | --- | --- | --- | --- | --- |
| Create | RDS Grid | `C:\src\aaca-attendance\billing-app\RdsScreen.pa.yaml` | RdsScreen | Rds | `C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid\RdsScreen.screen-plan.md` |
| Modify | Home | `C:\src\aaca-attendance\billing-app\HomeScreen.pa.yaml` | HomeScreen | Home | `C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid\HomeScreen.screen-plan.md` |
| Modify | Funders | `C:\src\aaca-attendance\billing-app\FundersScreen.pa.yaml` | FundersScreen | Fun | `C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid\FundersScreen.screen-plan.md` |
| Modify | Services | `C:\src\aaca-attendance\billing-app\ServicesScreen.pa.yaml` | ServicesScreen | Svc | `C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid\ServicesScreen.screen-plan.md` |
| Modify | Students | `C:\src\aaca-attendance\billing-app\StudentsScreen.pa.yaml` | StudentsScreen | Stu | `C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid\StudentsScreen.screen-plan.md` |

The four Modify rows reference `RdsScreen`, so their compile reports `Name isn't recognized: RdsScreen` until
RdsScreen.pa.yaml exists. Run RdsScreen in the first wave and compile the whole app after all five builders.
RdsScreen ~71 controls (most are small labels inside 3 galleries); each Modify adds 1 control.

## App Changes

### Before builders

The planner does not edit .pa.yaml in EDIT mode. Orchestrator applies these two exact edits to
`C:\src\aaca-attendance\billing-app\App.pa.yaml`, then compiles App alone:

1. In `App.Properties.Formulas`, after the line `      ColorWarnInk = RGBA(138, 74, 0, 1);` add:

```
      ColorFlag = RGBA(240, 173, 78, 1);
```

2. In `App.Properties.OnStart`, replace the final line
`      Set(varStuSsReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid})` with:

```
      Set(varStuSsReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid});
      // RDS grid
      Set(varRdsLoading, false);
      Set(varRdsLoadError, "");
      Set(varRdsPageCapped, false);
      Set(varRdsMonth, Today());
      Set(varRdsMonth, Blank());
      Set(varRdsMonthEnd, Today());
      Set(varRdsMonthEnd, Blank());
      Set(varRdsFunderId, ZeroGuid);
      Set(varRdsFunderId, Blank());
      Set(varRdsStudentId, ZeroGuid);
      Set(varRdsStudentId, Blank());
      Set(varRdsCampusText, "")
```

(Indentation: six spaces, matching the existing `|-` block.)

### After builders

None (StartScreen stays HomeScreen).

## Editor State Changes

Final `C:\src\aaca-attendance\billing-app\_EditorState.pa.yaml` (orchestrator applies after builders):

```yaml
EditorState:
  ScreensOrder:
    - HomeScreen
    - RdsScreen
    - FundersScreen
    - ServicesScreen
    - StudentsScreen
```

ComponentDefinitionsOrder: None (the app has no component definitions; leave the key out as today).
