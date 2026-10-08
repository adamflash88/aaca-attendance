# Canvas App Plan

## Mode

EDIT (build 13 - NEW CalendarScreen (System Admin calendar management) + NEW CalendarPrintScreen (print / PDF view);
"Calendar" nav button on the five existing screens)

## Requirements

Source of truth: `C:\src\aaca-attendance\docs\app-builds\build-13-calendar\canvas-app-requirements.md` (immutable);
approved plan `plan.md` (Adam, 2026-10-08: all calendar functions System Admin only).

## Original Request Capability Inventory

The requirements file has no keyed inventory; keys below are assigned from its sections.

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Observer(s) | Scenario(s) |
| --- | --- | --- | --- | --- | --- | --- |
| R-CAL-SHELL | A "NEW CalendarScreen (System Admin only; others see the not available panel); same header/nav/NEXUS help" | App shell and navigation; Security | `conCalHeader`, `conCalHelp`, `conCalDenied` (`!IsAdminRole`) | A-NAV-CAL | `conCalDenied.Visible`, `btnCalNavCalendar` current | S-NAV-CAL, S-CAL-DENIED |
| R-NAV-CAL | A "nav gets a NEW Calendar button (IsAdminRole) on every screen" | App shell and navigation | `btn{Att,Stu,Abs,Trn,Stf,Cal}NavCalendar` after Staff, before spacer; nav heights | A-NAV-CAL | button Visible; CalendarScreen opens | S-NAV-CAL, S-NAV-ROLE, S-NAV-LAYOUT, S-REG-ATT, S-REG-STU, S-REG-ABS, S-REG-TRN, S-REG-STF |
| R-CAL-PICKERS | A1 School Year dropdown newest first default CurrentSchoolYear; Campus dropdown | Data exploration | `ddCalYear` (colCalYearOpts desc), `ddCalCampus` | A-CAL-YEAR, A-CAL-CAMPUS | year view, `lblCalImpTitle` | S-CAL-LOAD, S-CAL-YEAR, S-CAL-CAMPUS |
| R-CAL-LOAD | A1 load engine reads the year's Terms (campus + all-campus), Calendar Exceptions (in the year, campus or all-campus), campus Month Locks | Integration; Data lifecycle (read) | btnCalLoadEngine -> btnCalBuildEngine (effective rows) | A-CAL-YEAR, A-CAL-CAMPUS | colCalTermsEff, colCalExcEff, colCalMonths.Locked | S-CAL-LOAD, S-CAL-CAMPUS |
| R-CAL-YEARVIEW | A2 12 month grids Aug..Jul, Sunday-first, title band, S M T W T F S, 6x7 cells, legend colours, today outlined | Analytics and visualization; Time | `galCalLegend`, `galCalMonths` > `galCalDays` (49 cells), colours from `Cal*` | A-CAL-YEAR | `btnCalDay` Fill/Text/Border | S-CAL-LOAD |
| R-CAL-SELECT | A2 clicking a day sets From; a second click on another day sets To | Data exploration (select) | `btnCalDay.OnSelect` -> varCalFrom / varCalTo | A-CAL-SELECT | dpCalFrom / dpCalTo, teal cell borders | S-CAL-SELECT |
| R-CAL-DAYS | A3 From, To, Type (Holiday/Break/Closed; SDD; Inclement; Make-up; Clear), Name (required unless Clear), also-apply campuses; weekdays (Make-up + Saturday); patch existing / create | Data lifecycle (create/update) | btnCalSaveDays (non-Clear) | A-CAL-DAYS-SET | receipt; cell colours after reload | S-CAL-DAYS-SET, S-CAL-DAYS-UPDATE, S-CAL-DAYS-MULTI, S-CAL-DAYS-WEEKEND, S-CAL-DAYS-INVALID, S-CAL-DAYS-FAIL |
| R-CAL-CLEAR | A3 Clear -> remove the row (no-op if none) | Data lifecycle (delete) | btnCalSaveDays (Clear) | A-CAL-DAYS-CLEAR | receipt "Removed" / "Nothing to clear" | S-CAL-DAYS-CLEAR, S-CAL-DAYS-CLEAR-NONE, S-CAL-SET-CLEAR |
| R-CAL-GUARDS | A3 locked month blocks; attendance marks on closure types require a confirm tick with the count text | Workflow (confirm); Security | C-DAY check; chkCalConfirm; live recount in S-DAYS | A-CAL-DAYS-SET | `lblCalDayCheck`, `chkCalConfirm` | S-CAL-DAYS-LOCKED, S-CAL-DAYS-ATT |
| R-CAL-AUDIT | A3/A4/A7/A8 writes IfError-wrapped, one Audit Event per save, receipt | Security, persistence, resilience | every Patch/Remove in IfError; audit per operation | A-CAL-DAYS-SET, A-CAL-DAYS-CLEAR, A-CAL-PER-SAVE, A-CAL-NEWYEAR, A-CAL-COPY | receipt "Audit event" line | all mutation scenarios |
| R-CAL-PERIODS | A4 Q1-Q4, ESY, Testing pickers prefilled; validate inside year, order, back-to-back next school day, testing inside Q1..Q4; upsert six Terms rows for the campus | Time and scheduling; Data lifecycle | Periods tab, C-PER, S-PER | A-CAL-PER-SAVE, A-CAL-PER-UNDO | `lblCalPerCheck`, receipt, Important Dates Qtr lines | S-CAL-PER-SAVE, S-CAL-PER-GAP, S-CAL-PER-INVALID, S-CAL-PER-UNDO |
| R-CAL-IMPORTANT | A5 Important Dates (First/Last RSY/ESY, grouped named exceptions), SDD n with ordinal, Quarterly Periods, Testing Period | Analytics (report) | colCalImportant -> galCalImp / galCalPImp | A-CAL-YEAR | `lblCalImpLine` | S-CAL-IMPORTANT |
| R-CAL-CHECK | A6 Check calendar button + list: missing, gap (dates) / overlap, ESY not after Q4, testing outside, closures on weekends, closures with attendance marks; "All good" | Analytics (alerts) | btnCalCheck -> btnCalCheckEngine | A-CAL-CHECK | `galCalChk`, `lblCalChkStamp` | S-CAL-CHECK, S-CAL-CHECK-OLD |
| R-CAL-NEWYEAR | A7 create school year: name default next, dates +1 year, template = shown campus/year, Planned if missing, copy Terms + Exceptions shifted 364 days for the campus (optionally all), federal holidays computed not copied, open the new year | Data lifecycle (create); Time | New year tab, btnCalCreateEngine | A-CAL-NEWYEAR | receipt; year picker shows the new year; year view | S-CAL-NEWYEAR, S-CAL-NEWYEAR-ALL, S-CAL-NEWYEAR-INVALID |
| R-CAL-COPY | A8 copy to campus: replace another campus's Terms and Exceptions for the year; confirm shows rows removed/added; audit | Data lifecycle (replace) | Copy tab, btnCalCopyEngine | A-CAL-COPY | `lblCalCopyPreview`, receipt; target campus view | S-CAL-COPY, S-CAL-COPY-LOCKED, S-CAL-COPY-FAIL |
| R-CAL-VIEW | A9 View calendar -> CalendarPrintScreen for the shown campus/year | App shell and navigation | `btnCalView` | A-CAL-VIEW | print title | S-CAL-VIEW |
| R-CALP-LAYOUT | B one landscape page: title "<Year> AACA <Campus Name>", legend, 12 months 3x4, right column lists, white, thin rules | Analytics (report); Files (print) | CalendarPrintScreen tree | A-CAL-VIEW | `lblCalPTitle`, `galCalPMonths`, `galCalPImp` | S-CAL-VIEW, S-CALP-PHONE, S-CALP-EMPTY |
| R-CALP-PRINT | B toolbar Print (Print() -> printer or Save as PDF) and Back; toolbar hides while printing (variable + Timer) | Files (print/export) | btnCalPPrint, tmrCalPPrint, btnCalPBack | A-CALP-PRINT, A-CALP-BACK | `conCalPToolbar.Visible` | S-CALP-PRINT, S-CALP-BACK |
| R-NF-COLOURS | Non-functional: legend colours as NEW named formulas | App shell | `CalRsy` ... `CalMonthBand`, `CalLegend`, `CalTypeOptions` | N/A | cell / legend fills | S-CAL-LOAD |

## Requirement Coverage

| Requirement | Planned affordance | Fidelity |
| --- | --- | --- |
| Calendar tab, System Admin only | Nav button `Visible: =IsAdminRole` on all screens; `conCalDenied` for everyone else | Exact |
| Same header/nav/help | conCalHeader / conCalHelp copied from StaffScreen | Exact |
| School Year newest first, default current; Campus picker | `ddCalYear` (desc by Start Date, default `CurrentSchoolYear`), `ddCalCampus` | Exact |
| Load engine, no per-cell data calls | E1 loads 3 sources; E2 builds 588 cells in memory; galleries read collections only | Exact |
| 12 Sunday-first month grids, header row, 6x7, legend colours, today outlined | `galCalMonths` (WrapCount 4 / 3 / 1) > `galCalDays` (WrapCount 7, 7 header + 42 day cells) | Exact |
| Click day -> From, second click -> To | `btnCalDay.OnSelect` with varCalPickTo; a click before From restarts the range | Exact |
| Type list incl. Clear; Name required unless Clear; also apply to campuses | `rdoCalType` (CalTypeOptions), `txtCalName`, `galCalAlso` checkboxes | Exact |
| Weekdays only (Make-up also Saturday); patch / create / remove (no-op) | S-DAYS over colCalDayWork; outcomes created / updated / unchanged / removed / none | Exact |
| Locked month guard | C-DAY blocks when any target campus has a locked month in the range | Exact |
| Attendance confirm with "N attendance marks exist on these days; they will no longer count" | E4 count + `chkCalConfirm`; S-DAYS re-counts live | Approximation: the count covers every date From..To per campus (weekend dates included) because CountRows per range is delegable while per-date counting is not; weekend marks are not expected |
| One Audit Event per save + receipt | S-DAYS / S-PER / E5 / E6 | Exact |
| Periods with validation + upsert six rows | Periods tab; C-PER; S-PER (Testing optional: both empty = no Testing row written) | Exact (Testing optional is an explicit rule) |
| Important Dates / SDD / Quarterly / Testing | colCalImportant (E2) shown in `galCalImp` and on the print page | Exact |
| Check calendar | `btnCalCheck` + `galCalChk`; structural checks also run after every load; attendance-mark check only on the button | Exact |
| Create school year with 364-day shift and computed federal holidays | E5; template rows whose name contains labor day / veteran / thanksgiving / martin luther / mlk / president / memorial / juneteenth / independence are not copied | Approximation: the whole template Thanksgiving week (if named "Thanksgiving ...") is replaced by the computed Thu + Fri only; Mon-Wed must be re-added by hand (the requirement says "everything else is adjusted by hand") |
| Optionally all campuses | `chkCalNewAll`: every campus gets the SHOWN campus's template (literal reading of "template = currently shown campus/year"); campuses that already have rows in the new year are skipped | Exact |
| Copy to campus with confirm counts | Copy tab preview + confirm; add-then-remove with rollback; rows in the target's locked months kept | Exact plus a safety rule (locked months are not changed) |
| View calendar | `btnCalView` -> CalendarPrintScreen | Exact |
| Print screen layout + Print / Back + toolbar hidden while printing | CalendarPrintScreen; `varCalPPrinting` + `tmrCalPPrint` | Exact once the Timer definition is supplied (see Discovery Summary) |

## Required Record Fields

| Field key | Screen | Record surface | Required field | Source field | Presentation requirement |
| --- | --- | --- | --- | --- | --- |
| cal-cell-date | CalendarScreen | galCalDays cell | day number | colCalCells.Txt (from D) | centred, Size 11 / 13 |
| cal-cell-kind | CalendarScreen | galCalDays cell | day type colour | colCalCells.Kind | shared Fill / Color switch; makeup green outline; today ink outline; selected teal outline |
| cal-cell-label | CalendarScreen | galCalDays cell | date + type + exception name | colCalCells.Tip | Tooltip (Classic/Button has no AccessibleLabel) |
| cal-month-title | CalendarScreen | month band | "August 2026" (+ " · locked") | colCalMonths.Title, Locked | white on CalMonthBand |
| cal-imp-line | CalendarScreen, CalendarPrintScreen | Important list row | section heads + lines | colCalImportant.Line | full text, Wrap false |
| cal-check-line | CalendarScreen | check row | problem text, severity | colCalChecks.Line, Sev | up to 3 lines, red / green / ink |
| cal-period-row | CalendarScreen | Periods row | period, start, end | colCalPerEdit | label + two date pickers |
| cal-receipt-line | CalendarScreen | receipt | label + value per outcome | colCalReceiptLines | two columns, wraps |
| calp-title | CalendarPrintScreen | page | "<Year> AACA <Campus Name>" | YearName, CampusName | 20 Bold centred |

## State-Driven Surface Visibility

| Surface key | Owner screen | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- | --- |
| cal-denied | CalendarScreen | conCalDenied | `=!IsAdminRole` | not System Admin / admin |
| cal-body | CalendarScreen | conCalBody | `=IsAdminRole` | admin / others |
| cal-receipt | CalendarScreen | conCalReceipt | `=varCalReceipt.Kind <> ""` | after a write attempt until Close |
| cal-days | CalendarScreen | conCalDaysPanel | `=!(varCalPanel in ["Periods", "New year", "Copy"])` | Days tab |
| cal-periods | CalendarScreen | conCalPerPanel | `=varCalPanel = "Periods"` | Periods tab |
| cal-new | CalendarScreen | conCalNewPanel | `=varCalPanel = "New year"` | New year tab |
| cal-copy | CalendarScreen | conCalCopyPanel | `=varCalPanel = "Copy"` | Copy tab |
| cal-confirm | CalendarScreen | chkCalConfirm | `=varCalDayAtt.N > 0` | closure range with attendance marks |
| calp-toolbar | CalendarPrintScreen | conCalPToolbar | `=!varCalPPrinting` | hidden while printing |

## Action Contracts

| Requested action | Preconditions | Entry point | Owner screen | Control and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-NAV-CAL | IsAdminRole | "Calendar" | all six screens | `btn{Att,Stu,Abs,Trn,Stf}NavCalendar.OnSelect: =Navigate(CalendarScreen)`; `btnCalNavCalendar` current | N/A | CalendarScreen shown | N/A | N/A | `btnCalNavCalendar` teal |
| A-CAL-YEAR | admin, not busy | `ddCalYear` | CalendarScreen | OnChange | 'School Years'.'School Year' -> varCalYearId | range cleared; E1 -> E2 -> E3 | N/A | N/A | month titles, `lblCalImpTitle` |
| A-CAL-CAMPUS | admin, not busy | `ddCalCampus` | CalendarScreen | OnChange | Campuses.Campus -> varCalCampusId | colCalAlso rebuilt; range + copy target cleared; reload | N/A | N/A | cell colours, `lblCalImpTitle` |
| A-CAL-SELECT | in-month day, not saving | day cell | CalendarScreen | `btnCalDay.OnSelect` | colCalCells.D | 1st click From = To = D; 2nd click (D >= From) To = D; tab -> Days; E4 recount | N/A | N/A | teal cell borders; dpCalFrom / dpCalTo; rdoCalType / txtCalName prefilled from the From day |
| A-CAL-TAB | not saving | tab list | CalendarScreen | `tabCalPanel.OnChange` | N/A | varCalPanel | N/A | N/A | panel visibility |
| A-CAL-DAYS-SET | C-DAY Ready (range in year, <= 45 days, weekdays exist, name, no locked month, count fresh, confirm ticked if marks) | "Save days" | CalendarScreen | `btnCalSaveDays.OnSelect` (S-DAYS, branch `typ <> "Clear"`) | per (date, campus) live `ex` by Date + Campus.Campus; new id `wr.'Calendar Exception'` | created / updated / unchanged per row; Audit Update; E1 reload | Calendar Exceptions: Description, Date, Type, Campus (create); Description, Type (update); Audit row | Title (type, name, dates, campuses, counts); Type, Name, Dates, Campuses, Created / updated / removed, Unchanged / failed, Attendance marks, Audit; one line per row from `wr` | `conCalReceipt`; cells of the range recoloured from reloaded colCalExcEff |
| A-CAL-DAYS-CLEAR | C-DAY Ready with Type Clear | "Clear days" | CalendarScreen | same, branch `typ = "Clear"` | live `ex` (snapshot `before`, `exId`) | removed / none per row; Audit Update; reload | Remove row; Audit row | Operation "Clear days", Dates, Campuses, counts; per row "Removed (was type · name)" / "Nothing to clear" | receipt; cells back to school / weekend / nonterm |
| A-CAL-PER-SAVE | C-PER Ready | "Save periods" | CalendarScreen | `btnCalSavePer.OnSelect` (S-PER) | live Terms by School Year + Campus + Term; `wr.'Term (aaca_termid)'` | created / updated / unchanged per period; Audit Update; reload | Terms: Name, Start Date, End Date (+ School Year, Campus, Term on create) | per period `Text(wr.'Start Date') to Text(wr.'End Date') · wr.Name (was ...)`; Audit | receipt; Qtr lines in Important Dates; cell colours (rsy / esy / test / nonterm) |
| A-CAL-PER-UNDO | Periods tab | "Undo changes" | CalendarScreen | `btnCalPerUndo.OnSelect` | colCalTermsEff | colCalPerEdit restored | N/A | N/A | picker values |
| A-CAL-CHECK | admin, not busy | "Check calendar" | CalendarScreen | `btnCalCheck.OnSelect` -> E3 (with attendance) | colCalTermsEff, colCalYearDays, colCalExcEff, Attendance counts | colCalChecks rebuilt; stamp | N/A | N/A | `galCalChk`, `lblCalChkStamp` |
| A-CAL-NEWYEAR | C-NEW Ready | "Create school year" | CalendarScreen | `btnCalCreate.OnSelect` -> `btnCalCreateEngine` (E5) | `yr.'School Year'` (Patch result or existing by Name); per campus new Terms / Exceptions ids | School Year Planned (if missing); per target campus without rows: periods + template days (+364) + federal holidays; Audit Rollover; year opened | School Years: Name, Start Date, End Date, Status; Terms; Calendar Exceptions; Audit row | School year line from `yr` (name, dates, status, created / existed), Template, Campuses, Periods / days / holidays, Federal holidays with dates, Not copied, skipped / failed lines, Audit | receipt; `ddCalYear` shows the new year; year view of the new year |
| A-CAL-COPY | C-COPY Ready (target chosen, confirm ticked) | "Replace calendar" | CalendarScreen | `btnCalCopy.OnSelect` -> `btnCalCopyEngine` (E6) | target `varCalCopyTargetId`; old ids `colCalCopyOld.Id`; new ids `colCalLog.Id` | add effective periods + days (not in target locked months) at target; then remove old target rows (outside locked months); on any add failure remove the new rows instead; Audit Update | Terms + Calendar Exceptions at target | From / to, Periods added (from `wr`), Days added, Old rows removed, Locked months kept, Failed / rolled back, Audit | receipt; switch `ddCalCampus` to the target: same colours |
| A-CAL-VIEW | loaded, no error | "View calendar" | CalendarScreen | `btnCalView.OnSelect: =Navigate(CalendarPrintScreen)` | varCalYearId, varCalCampusId | print screen shows the same calendar | N/A | N/A | `lblCalPTitle` |
| A-CALP-PRINT | cells loaded | "Print" | CalendarPrintScreen | `btnCalPPrint.OnSelect: =Set(varCalPPrinting, true); Print()` | N/A | toolbar hidden; print dialog; timer restores | N/A | N/A | printout / PDF without toolbar |
| A-CALP-BACK | any | "Back" | CalendarPrintScreen | `btnCalPBack.OnSelect: =Back()` | N/A | CalendarScreen | N/A | N/A | CalendarScreen visible |

Opposing pair: Set days / Clear days act on the same Calendar Exceptions record (create-or-update vs remove). They
are non-arithmetic, so the Directional Mutation Evidence table does not apply; they share one event
(`btnCalSaveDays.OnSelect`) with literal guards `typ = "Clear"` vs the non-Clear branches, the type comes from
`rdoCalType` (valid default Holiday, explicitly re-selected per day from the existing row), and a same-record
compound scenario is S-CAL-SET-CLEAR.
Continuation Contracts: none (Create school year opens the new year for review; no downstream mutation is chained to
the returned id).

## Compound Sequence Evidence

| Pair | Same-record ID expression | Sequence | Second-op old-value binding |
| --- | --- | --- | --- |
| Set / Clear days | (Date 2026-10-09, Campus AV) -> `'Calendar Exception'` | none -> Set Inclement Weather "Smoke day" -> row R -> Clear -> none | S-DAYS Clear branch reads `ex: With({q: w.D, c0: w.CampusId}, LookUp('Calendar Exceptions', Date = q && Campus.Campus = c0))` live, so it removes R created by the first save (receipt "Removed (was Inclement Weather · Smoke day)") |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-CAL-DAYS-SET | `wr` per row -> colCalLog -> colCalReceiptLines -> `galCalReceipt` | 'Calendar Exceptions' row (Date, Campus) | year view cells, Important Dates, print page | log Id = `wr.'Calendar Exception'` (create) or `ex.'Calendar Exception'` (update) | `Select(btnCalLoadEngine)` re-queries; E2 rebuilds cells | range stays selected (teal outline) on the edited dates |
| A-CAL-DAYS-CLEAR | `before` snapshot + `exId` -> receipt | same | same | log Id = removed row id | reload | same |
| A-CAL-PER-SAVE | `wr` per period -> receipt | Terms row (Year, Campus, Term) | Qtr lines, RSY/ESY/testing cells, gap check | log Id = `wr.'Term (aaca_termid)'` | reload | Periods tab stays open on the saved values |
| A-CAL-NEWYEAR | `yr` + log counts -> receipt | 'School Years' row + Terms + Exceptions | year picker and year view of the new year | `yr.'School Year'` -> varCalYearId | colCalYearOpts re-queried inline; then reload | `ddCalYear` reset to the new year id |
| A-CAL-COPY | log (added ids, removed ids) -> receipt | target campus Terms + Exceptions | target campus calendar (pick it in `ddCalCampus`) | old ids from live snapshot; new ids from `wr` | reload (all-campus collections refresh the preview) | target not auto-selected; receipt names it |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| A-CAL-DAYS-SET | Description | Changed | `Trim(txtCalName.Text)` | Patch create / update | "Name"; per row `wr.Description` | Tip, Important Dates line |
| A-CAL-DAYS-SET | Type | Changed | `rdoCalType.Selected.Value` -> choice | Patch | "Type"; per row `Text(wr.Type)` | cell Kind colour |
| A-CAL-DAYS-SET | Date, Campus | Changed (create) / Preserved (update: omitted) | colCalDayWork | Patch Defaults only | per row key "ddd m/d/yyyy · Campus", `Text(wr.Date)` | cell position |
| A-CAL-DAYS-CLEAR | whole row | Changed (removed) | live `ex` | Remove | "Removed (was type · name)" | cell kind school / weekend / nonterm |
| A-CAL-PER-SAVE | Start Date, End Date, Name | Changed | colCalPerEdit (picker OnChange) | Patch | per period from `wr` | Qtr lines, cell colours |
| A-CAL-PER-SAVE | School Year, Campus, Term | Changed (create) / Preserved (update) | yrRec, cRec, ch | Patch Defaults only | "(new campus row)" | colCalTermsEff.IsCampus |
| A-CAL-NEWYEAR | School Year Name, Start, End, Status | Changed (create) / Preserved (existing) | inputs | Patch Defaults or reuse | "School year" line from `yr` | `ddCalYear` |
| A-CAL-NEWYEAR | Terms (Name, Year, Campus, Term, Start, End) | Changed (created) | template + 364 | Patch Defaults | counts + failures | new year view |
| A-CAL-NEWYEAR | Exceptions (Description, Date, Type, Campus) | Changed (created) | template + 364 / colCalFed | Patch Defaults | counts, Federal holidays list | new year view |
| A-CAL-COPY | target Terms / Exceptions | Changed (replaced) | live snapshot colCalCopyOld + effective source | add, then Remove old (or roll back new) | counts + per-period lines | target campus view |
| A-CAL-COPY | target rows in locked months; all-campus rows | Preserved | colCalLocksAll / CampusId blank | excluded from add and remove | "Locked months kept" | target view |

## Functional Test Matrix

Fixtures (Dev, today Thu 2026-10-08): admin M "Mendez, Mia" (System Admin); office O "Ortiz, Olga" (Attendance
Office, CW). Campuses AV Antelope Valley, CW Chatsworth, OX Oxnard. School year 2026-2027 (Current, Aug 2026 - Jul
2027). For each campus (campus rows): Q1 8/12-10/16/2026, Q2 10/19-12/18, Q3 1/5-3/19/2027, Q4 3/29-5/28, ESY
6/14-7/23, Testing 3/1-5/27; exceptions Post-ESY Break 8/3-8/10 (Closed), SDD 8/11, 10/23, 1/15, 4/9 (Work Only),
Labor Day 9/7, Veterans Day 11/11, Thanksgiving 11/23-27, Winter Recess 12/21-1/4, MLK 1/18, Presidents 2/15,
Spring Recess 3/22-26, Memorial Day 5/31, Pre-ESY Break 6/1-6/11, Independence Day 7/5, Post-ESY Break 7/26-30.
Month Locks: Aug 2026 Locked at CW (test lock). AV has attendance marks on Fri 10/9/2026 (call the live count N).
2025-2026 at AV has no winter recess rows.

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-NAV-CAL | M on each of the 5 screens | press Calendar | CalendarScreen opens, Calendar button teal | `btnCalNavCalendar` | N/A |
| S-NAV-ROLE | O on any screen | look at nav | no Calendar button | button Visible | O at CalendarScreen (via Back history) sees `conCalDenied` |
| S-NAV-LAYOUT | M | resize 1366 / 760 / 375 | nav one row / two rows / three rows, logo visible, nothing clipped | header | office at 760: one-row content inside a 96 band (whitespace only) |
| S-CAL-DENIED | teacher or O | open CalendarScreen | denied title "Calendar is not available for your role"; no body | `conCalDenied` | not linked user: sign-in text |
| S-CAL-LOAD | M, AV 2026-2027 | open Calendar | 12 months Aug 2026 - Jul 2027; 8/12 and 5/28 green; 6/14 and 7/23 blue; 9/7, 11/23-27, 12/21-1/4 black; 8/11, 10/23, 1/15, 4/9 purple; 3/1 and 5/27 orange; weekends muted; today 10/8 ink outline; check "All good ... (calendar only)" | `galCalDays`, `galCalChk` | load error -> `lblCalNote` "Could not load: ..." |
| S-CAL-YEAR | S-CAL-LOAD | pick another year | view and lists switch; range cleared | month titles | year without periods -> `lblCalNote` hint |
| S-CAL-CAMPUS | S-CAL-LOAD | pick OX | OX calendar; Also-apply list = AV, CW | cells, `galCalAlso` | Aug 2026 band at CW shows " · locked" |
| S-CAL-SELECT | S-CAL-LOAD | click 10/9, then 10/13 | From 10/9, To 10/13; 3 weekday cells + weekend outlined teal; Type default Holiday, Name "" | dpCalFrom / dpCalTo | then click 10/5 -> From = To = 10/5; click 9/7 -> Type "No school - Holiday", Name "Labor Day" prefilled |
| S-CAL-DAYS-ATT | From = To = 10/9, Type Inclement Weather, Name "Smoke day", AV only | look at check | "N attendance marks exist on these days; they will no longer count. Tick the confirmation below to continue."; Save disabled; `chkCalConfirm` visible | `lblCalDayCheck` | untick after ticking -> disabled again |
| S-CAL-DAYS-SET | S-CAL-DAYS-ATT, tick confirm | Save days | AV row Date 2026-10-09, Type Inclement Weather, Description "Smoke day", Campus AV created; Audit Update After.AttendanceMarks = N | receipt "Days saved · Inclement Weather (closed) · Smoke day · 10/9/2026 · Antelope Valley · 1 created, 0 updated, 0 removed, 0 failed"; line "Fri 10/9/2026 · Antelope Valley - Created · Inclement Weather · Smoke day · 10/9/2026"; cell red | marks changed meanwhile -> live recount blocks if confirm not ticked |
| S-CAL-DAYS-UPDATE | after S-CAL-DAYS-SET | 10/9: Type Closed, Name "Power outage", confirm, Save | same row patched: Type Closed, Description "Power outage" | receipt "Updated · Closed · Power outage (was Inclement Weather · Smoke day)"; cell black | same type + name -> "Unchanged" line, 0 writes |
| S-CAL-DAYS-CLEAR | after S-CAL-DAYS-UPDATE | 10/9 Type Clear, Save ("Clear days", red) | row removed | receipt "Removed (was Closed · Power outage)"; cell white (school day) | N/A |
| S-CAL-DAYS-CLEAR-NONE | 10/14 has no row | Clear 10/14 | nothing written | receipt line "Nothing to clear"; Kind Saved; Audit Update Unchanged 1 | N/A |
| S-CAL-SET-CLEAR | no row on 10/9 AV | Set Inclement "Smoke day" then Clear the same day | see Compound Sequence Evidence | receipts of both saves | N/A |
| S-CAL-DAYS-MULTI | AV, 11/23-11/27, also CW + OX ticked, Holiday "Thanksgiving Break" | Save | 15 rows (5 days x 3 campuses) updated or created with that name; Audit Campuses "Antelope Valley, Chatsworth, Oxnard" | receipt counts + 15 lines | rows already identical -> Unchanged |
| S-CAL-DAYS-WEEKEND | Sat 11/21 - Sun 11/22, Holiday | look at check | "There are no weekdays in this range." | `lblCalDayCheck` | Make-up School Day on Sat 11/21 -> Ready, 1 day; cell white with green outline |
| S-CAL-DAYS-LOCKED | AV, 8/11, Closed "Test", CW ticked | look at check | "August 2026 is locked at Chatsworth. Days in a locked month cannot be changed." | `lblCalDayCheck`, Save disabled | untick CW -> Ready |
| S-CAL-DAYS-INVALID | Days tab | (a) Type Holiday, Name blank; (b) 10/1 - 12/31; (c) To before From | (a) "Enter the name shown on the calendar, for example Labor Day."; (b) "Choose at most 45 days at a time."; (c) "The To date is before the From date." | `lblCalDayCheck` | pickers limited to the school year |
| S-CAL-DAYS-FAIL | remove write privilege on Calendar Exceptions (test) | Save a Holiday | each row "FAILED · not created: <error>"; Kind Failed | receipt (error fill) | Audit still written with Failed count |
| S-CAL-PER-SAVE | AV periods (campus rows) | Periods: Testing end 5/26/2027 -> check "Ready: saves 1 period(s) ..." -> Save periods | Testing row End Date 2027-05-26; other 5 "Unchanged"; Audit Update | receipt "Periods saved · Antelope Valley 2026-2027 · 0 created, 1 updated, 5 unchanged, 0 failed"; line "Testing - Updated · 3/1/2027 to 5/26/2027 · 2026-2027 Testing (AV) (was 3/1/2027 to 5/27/2027)"; cell 5/26 orange, 5/27 plain | all-campus-only periods -> rows "Created (new campus row)" |
| S-CAL-PER-GAP | Periods | Q2 start 10/26/2026 | "Q2 must start on the next school day after Q1 ends: Mon 10/19/2026." Save disabled | `lblCalPerCheck` | Q3 start 1/4/2027 (in Winter Recess) -> "Q3 must start ... Tue 1/5/2027." |
| S-CAL-PER-INVALID | Periods | (a) Q1 end blank; (b) ESY start 5/20/2027; (c) Testing start 8/1/2026; (d) Testing end only | (a) "Enter start and end dates for Q1."; (b) order message; (c) "Testing must be inside Q1 start to Q4 end (...)"; (d) "Enter both Testing dates, or leave both empty." | `lblCalPerCheck` | no changes -> "No changes to save." |
| S-CAL-PER-UNDO | edited Q2 start | Undo changes | pickers back to the loaded dates | `dpCalPerStart` | N/A |
| S-CAL-IMPORTANT | S-CAL-LOAD | read the Important dates panel | "Important Dates", "First Day RSY - 8/12/2026", "Post-ESY Break - 8/3/2026 - 8/10/2026", "Labor Day - 9/7/2026", "Thanksgiving ... - 11/23/2026 - 11/27/2026", "Winter Recess - 12/21/2026 - 1/4/2027", ..., "Last Day RSY - 5/28/2027", "First Day ESY - 6/14/2027", "Last Day ESY - 7/23/2027"; "SDD 1: August 11th, 2026", "SDD 2: October 23rd, 2026", "SDD 3: January 15th, 2027", "SDD 4: April 9th, 2027"; "Qtr.1: 08/12/2026 to 10/16/2026" ... "Qtr.4: 03/29/2027 to 05/28/2027"; "03/01/2027 to 05/27/2027" | `galCalImp` | no SDDs -> "None entered" |
| S-CAL-CHECK | S-CAL-LOAD | Check calendar | "All good. No problems found, including attendance marks." (or one warning per no-school date with marks); stamp "Checked h:mm including attendance marks" | `galCalChk`, `lblCalChkStamp` | a Holiday row on a Saturday -> "Holiday on a weekend: ..." warning |
| S-CAL-CHECK-OLD | AV 2025-2026 | open year | error "Gap between Q2 and Q3: school days 12/22/2025, ... are in no quarter." listing the missing winter-recess weekdays | `galCalChk` (red) | missing ESY -> "Missing ESY for this campus." |
| S-CAL-NEWYEAR | M, AV 2026-2027 shown; no 2027-2028 rows | New year: defaults "2027-2028", 8/1/2027-7/31/2028 (shown +1 year) -> Create school year | 'School Years' 2027-2028 Planned; AV Terms Q1 8/11/2027-10/15/2027 ... (each +364 days), Testing 2/28-5/25/2028; template days +364 except federal-named rows; holidays Labor Day 9/6/2027, Veterans Day 11/11/2027, Thanksgiving 11/25 + 11/26/2027, MLK 1/17/2028, Presidents 2/21/2028, Memorial Day 5/29/2028, Juneteenth 6/19/2028, Independence Day 7/4/2028; Audit Rollover; view switches to 2027-2028 | receipt "School year 2027-2028 created · 6 periods, n days copied, 9 holidays added"; lines incl. Federal holidays list and "Not copied (recalculated)" names | name exists with the same dates -> "already existed", rows added |
| S-CAL-NEWYEAR-ALL | after S-CAL-NEWYEAR | tick all campuses, create again | AV skipped ("already has n calendar row(s) in 2027-2028"); CW and OX created from the AV template | receipt Kind Partial; skipped line | all skipped -> Kind Blocked, view stays |
| S-CAL-NEWYEAR-INVALID | New year tab | (a) "2027/28"; (b) "2027-2029"; (c) end before start; (d) existing name with other dates | (a) "Enter the name as YYYY-YYYY..."; (b) "The second year must follow the first..."; (c) "The end date must be after the start date."; (d) "... already exists (...). Use the same dates ..." | `lblCalNewCheck`, button disabled | shown year has no periods -> blocked message |
| S-CAL-COPY | AV 2026-2027 shown; OX has its own rows | Copy: target Oxnard -> preview "Removes 6 period row(s) and m day row(s) at Oxnard, then adds 6 period(s) and k day(s)." -> tick -> Replace calendar | OX campus rows replaced by copies of AV effective rows; Audit Update (Before = old rows) | receipt "Copied · Antelope Valley 2026-2027 to Oxnard · 6 periods and k days added, r old rows removed"; then pick Oxnard: identical colours | untick confirm -> "Tick the confirmation ..." |
| S-CAL-COPY-LOCKED | Aug 2026 locked at CW | Copy AV -> CW | CW rows in Aug 2026 kept; other months replaced | preview "Locked months stay as they are: August 2026."; receipt "Locked months kept: n row(s)" | N/A |
| S-CAL-COPY-FAIL | create privilege removed on Terms (test) | Copy | period adds fail -> every new row removed; old rows kept | receipt Kind Failed "Not copied · ... keeps its calendar"; "Failed / rolled back" counts | a rollback failure -> "Rollback FAILED" line |
| S-CAL-VIEW | S-CAL-LOAD | View calendar | CalendarPrintScreen title "2026-2027 AACA Antelope Valley"; legend row; 3 x 4 months; right column lists | `lblCalPTitle`, `galCalPMonths`, `galCalPImp` | button disabled while loading or on load error |
| S-CALP-PRINT | S-CAL-VIEW | Print | toolbar hidden, browser print dialog; choose Landscape + Save as PDF -> one page without toolbar; toolbar back about 3 s after the dialog closes | printed PDF; `conCalPToolbar` | Timer unavailable -> fallback (toolbar may print) |
| S-CALP-BACK | print screen | Back | CalendarScreen, same year/campus, reloaded | CalendarScreen | N/A |
| S-CALP-PHONE | print screen at 375 | scroll | 1 month per row, list below, no clipping | screen | N/A |
| S-CALP-EMPTY | colCalCells empty | open print screen | "Nothing to print yet ..."; Print disabled | `lblCalPEmpty` | N/A |
| S-REG-ATT / S-REG-STU / S-REG-ABS / S-REG-TRN / S-REG-STF | each existing screen | use as before | only change is the Calendar button and nav height band 640-799 | header | teacher: no nav buttons, unchanged |

## Data Entry Label Contracts

Owned by CalendarScreen; exact rows in `CalendarScreen.screen-plan.md` "Data Entry Label Contracts" (ddCalYear,
ddCalCampus, dpCalFrom, dpCalTo, rdoCalType, txtCalName, dpCalPerStart/End, txtCalNewName, dpCalNewStart,
dpCalNewEnd, ddCalCopyTarget). Each label is a sibling in the same field container or panel.

## Layout Budget Contracts

| Screen / container | Branch / screen-width source | Horizontal total-width arithmetic | Vertical height arithmetic | Protected controls |
| --- | --- | --- | --- | --- |
| Nav rows (all 6 screens) | root Width: >= 800 / 640-799 / < 640 | 650 + 56 + 44 = 750 <= inner (root - 32) at >= 782; 582 row 1 at 640; phone 228 / 258 / 240 <= 343 | 44 / 96 / 148 (+8 where the screen adds it) | Calendar, logo |
| conCalHdrBar | root >= 728 / >= 576 / phone | 272 + 8 + 264 + 8 + 140 + 32 = 724 | 60 / 112 / 164 | View calendar |
| galCalMonths cells | root >= 1280 / >= 1024 / >= 640 / phone | 31 / 28 / 26 / 45 px cells (see brief) | template 222 / 320 = shell + 8 | day cells |
| conCalSide panels | side inner 348 (desktop) / 327 (phone) | From/To 156 + 8 + 156 = 320; periods 60 + 8 + 2 x 125 + 8 = 326 | Days 596 + 36n (+56), Periods 518, New 496, Copy 442 | Save days, Save periods, Create, Replace |
| CalendarPrintScreen page | 1366 x 768 | 1034 / 4 = 258 per month + 300 list | 606 with toolbar, 556 printing <= 768 | whole page |

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| --- | --- | --- | --- | --- | --- |
| CalendarScreen | conCalRoot (sole top-level child) | AutoLayout | `=Parent.Width` | `=Parent.Height` | LayoutOverflowY Scroll; LayoutMinWidth/Height 0 |
| CalendarPrintScreen | conCalPRoot (sole top-level child) | AutoLayout | `=Parent.Width` | `=Parent.Height` | LayoutOverflowY Scroll (page fits 768 at desktop) |
| Screen1 / StudentsScreen / AbsencesScreen / TransportScreen / StaffScreen | existing roots | AutoLayout | unchanged | unchanged | unchanged |

## Temporal Ordering Contracts

None. Only typed Date values are compared and sorted; no time-of-day ordering.

## Working Directory

C:\src\aaca-attendance\app

Plan artifacts: C:\src\aaca-attendance\docs\app-builds\build-13-calendar\

## Discovery Summary

- Existing screens: Screen1 (Att), StudentsScreen (Stu), AbsencesScreen (Abs), TransportScreen (Trn), StaffScreen
  (Stf); AutoLayout, one scroll root each; nav = 5 buttons + spacer + NEXUS logo.
- Data sources: School Years, Terms (Term choice incl. Testing), Calendar Exceptions (Type incl. Inclement Weather;
  name column `Description`), Campuses, Month Locks, Attendance (count only), Audit Events (Update, Rollover).
- Controls (describe_control results in the build-1/2/3 packets, all already used in the app): GroupContainer,
  ModernText, ModernButton, Classic/Button, Gallery (LoadingSpinner enum), ModernDropdown, ModernTextInput,
  ModernDatePicker, ModernRadio, ModernCheckbox, ModernTabList; copied header/help controls Image, Spinner, HtmlViewer.
- **Gap: Timer has no `describe_control` result in any packet.** Only `tmrCalPPrint` on CalendarPrintScreen needs it.
  The orchestrator must run `describe_control` for Timer and paste the creation keyword(s) and input property names
  into `CalendarPrintScreen.screen-plan.md` (Control Definitions) before dispatching that brief.
- Writing tool: the planner had no `apply_patch`; artifacts were written with the file Write tool.

## Dispatch

Order matters (navigation targets must exist in the session before a screen that navigates to them compiles):

1. Orchestrator: supply the Timer definition (above); apply "App.pa.yaml changes (orchestrator)" from the shared
   plan; compile App.
2. Wave 1: CalendarPrintScreen (small; no references to other new screens).
3. Wave 2: CalendarScreen (large; navigates to CalendarPrintScreen).
4. Wave 3 (after CalendarScreen compiles): Screen1, StudentsScreen, AbsencesScreen in parallel; then TransportScreen,
   StaffScreen (same wave if more than three builders are allowed). Each is a one-button insert + two Height edits.
5. Orchestrator: append CalendarScreen, CalendarPrintScreen to `_EditorState.pa.yaml`; compile all; Studio save
   (coauthoring).

| Action | Screen | Target File | YAML Key | Name Prefix | Screen Brief |
| --- | --- | --- | --- | --- | --- |
| Create | Calendar print view | `C:\src\aaca-attendance\app\CalendarPrintScreen.pa.yaml` | CalendarPrintScreen | CalP | `C:\src\aaca-attendance\docs\app-builds\build-13-calendar\CalendarPrintScreen.screen-plan.md` |
| Create | Calendar | `C:\src\aaca-attendance\app\CalendarScreen.pa.yaml` | CalendarScreen | Cal | `C:\src\aaca-attendance\docs\app-builds\build-13-calendar\CalendarScreen.screen-plan.md` |
| Modify | Attendance | `C:\src\aaca-attendance\app\Screen1.pa.yaml` | Screen1 | Att (new: AttNavCalendar) | `C:\src\aaca-attendance\docs\app-builds\build-13-calendar\Screen1.screen-plan.md` |
| Modify | Students | `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml` | StudentsScreen | Stu (new: StuNavCalendar) | `C:\src\aaca-attendance\docs\app-builds\build-13-calendar\StudentsScreen.screen-plan.md` |
| Modify | Absences | `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml` | AbsencesScreen | Abs (new: AbsNavCalendar) | `C:\src\aaca-attendance\docs\app-builds\build-13-calendar\AbsencesScreen.screen-plan.md` |
| Modify | Transportation | `C:\src\aaca-attendance\app\TransportScreen.pa.yaml` | TransportScreen | Trn (new: TrnNavCalendar) | `C:\src\aaca-attendance\docs\app-builds\build-13-calendar\TransportScreen.screen-plan.md` |
| Modify | Staff | `C:\src\aaca-attendance\app\StaffScreen.pa.yaml` | StaffScreen | Stf (new: StfNavCalendar) | `C:\src\aaca-attendance\docs\app-builds\build-13-calendar\StaffScreen.screen-plan.md` |

## App Changes

### Before builders

See `canvas-app-shared.md` section "App.pa.yaml changes (orchestrator)": (1) Formulas `CalRsy`, `CalEsy`,
`CalNoSchool`, `CalSdd`, `CalTesting`, `CalWeather`, `CalNonTerm`, `CalMonthBand`, `CalTypeOptions`, `CalLegend`
appended after the `HelpContextPrefix` line; (2) OnStart Cal seeds appended after `Set(varAttQtrError, "")` (which
gains a semicolon; the new last line `Clear(colCalReceiptLines)` has none).

### After builders

None (StartScreen unchanged).

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
    - CalendarScreen
    - CalendarPrintScreen
```

`ComponentDefinitionsOrder`: none (no components).
