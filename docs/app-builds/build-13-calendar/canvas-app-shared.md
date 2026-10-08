# Canvas App Shared Plan - AACA Attendance (build 13 edit: Calendar management + print view)

Screens touched: CalendarScreen (NEW, prefix `Cal`), CalendarPrintScreen (NEW, prefix `CalP`), and the nav row of
Screen1 (`Att`), StudentsScreen (`Stu`), AbsencesScreen (`Abs`), TransportScreen (`Trn`), StaffScreen (`Stf`).
Every builder reads this file plus its own brief. App.pa.yaml and _EditorState.pa.yaml are edited by the
orchestrator only (section "App.pa.yaml changes (orchestrator)" at the end).

## Aesthetic Direction (unchanged)

NEXUS palette, all App.Formulas named constants - always use the name, never a new RGBA:

- Page `ColorPaper`; panels `ColorWhite`; rules/borders `ColorRule`
- Text primary `ColorInk`; secondary `ColorMuted`; on-ink text `ColorWhite` / `ColorInkSoft`
- Accent / primary action `ColorTeal`; destructive (Clear days, Copy to campus) `ColorUnexcused` with white text;
  "Ready" check text `ColorExcused`, blocking check text `ColorUnexcused`
- Status surfaces (always `ColorInk` text): `ColorInfoBg` (success), `ColorWarnBg` (partial, warnings),
  `ColorErrorBg` (failed/blocked)

### Calendar legend colours (NEW named formulas, added by the orchestrator before builders)

| Name | Value | Used for (cell `Kind`) | Text colour on it |
| --- | --- | --- | --- |
| `CalRsy` | `RGBA(21, 128, 61, 1)` | First / Last Day RSY (`"rsy"`); also the Make-up outline (`"makeup"`) | `ColorWhite` |
| `CalEsy` | `RGBA(29, 78, 216, 1)` | First / Last Day ESY (`"esy"`) | `ColorWhite` |
| `CalNoSchool` | `RGBA(17, 17, 17, 1)` | Holiday / Break / Closed (`"noschool"`) | `ColorWhite` |
| `CalSdd` | `RGBA(112, 48, 160, 1)` | Staff Development = Work Only (`"sdd"`) | `ColorWhite` |
| `CalTesting` | `RGBA(245, 158, 11, 1)` | Testing start / end (`"test"`) | `ColorInk` |
| `CalWeather` | `RGBA(185, 28, 28, 1)` | Inclement Weather (`"weather"`) | `ColorWhite` |
| `CalNonTerm` | `RGBA(217, 217, 217, 1)` | weekday outside every quarter/ESY (`"nonterm"`) | `ColorInk` |
| `CalMonthBand` | `RGBA(31, 56, 100, 1)` | month title band | `ColorWhite` |

Other kinds: `"school"` white fill / ink text; `"weekend"` white fill / `ColorMuted` text; `"makeup"` white fill,
ink text, 2px `CalRsy` border; `"hdr"` (S M T W T F S) white fill, ink bold; `"out"` (days of other months) white,
empty text.

Exact fill / text switches (copy verbatim; `k` = the cell's `ThisItem.Kind`):

```
Fill:  Switch(k, "rsy", CalRsy, "esy", CalEsy, "noschool", CalNoSchool, "sdd", CalSdd, "test", CalTesting, "weather", CalWeather, "nonterm", CalNonTerm, ColorWhite)
Color: Switch(k, "rsy", ColorWhite, "esy", ColorWhite, "noschool", ColorWhite, "sdd", ColorWhite, "weather", ColorWhite, "weekend", ColorMuted, ColorInk)
```

## Visual Contract

- Type roles (ModernText `Size`/`FontWeight`): app title 20 Bold white; panel heading 16 Bold ink; body 13 ink;
  field label 12 Semibold `ColorMuted`; caption / list line 12; calendar cells 11 (desktop) / 13 (phone); month band
  12 Bold white; print view: title 20 Bold, cells 10, side list 10.
- Every NEW ModernText: all four Padding* `=0` (unless stated), `AccessibleLabel`, `AlignInContainer`,
  `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, explicit `Height`; single-line labels `Wrap: =false`; multi-line text
  `VerticalAlign: =VerticalAlign.Top`.
- Spacing: container gap 8 (form panels 4); panel padding 12-16; receipt padding 8 top/bottom, 12 sides.
- Panels: `Fill: =ColorWhite`, `BorderColor: =ColorRule`, `BorderThickness: =1`, `DropShadow: =DropShadow.None`,
  all four Radius* `=6`.
- Every NEW GroupContainer: `Variant: AutoLayout`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`,
  `DropShadow: =DropShadow.None`, explicit `LayoutDirection`, `LayoutAlignItems`, `FillPortions`, and `Height`.
- Actions (ModernButton, `Height: =44`, `Layout: =ButtonLayout.TextOnly`, `Size: =14`, `LayoutMinHeight: =0`,
  `LayoutMinWidth: =0`, explicit `Width`, `AlignInContainer: =AlignInContainer.Center` in rows):
  - Primary: `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite` (Appearance default Primary)
  - Destructive: `BasePaletteColor: =ColorUnexcused`, `Color: =ColorWhite`
  - Secondary: `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk` (never light text on Secondary)
  - Disabled via `DisplayMode: =DisplayMode.Disabled`.
- No symbol glyphs (arrows, check marks) in any NEW text. Use plain words, "-" or "·".

## Layout Strategy

- Responsive, desktop-first (1366x768), usable at 1024; calendar editing is a desktop task, a 375 phone must not
  break. Each screen has ONE scroll root (sole top-level child): `Width: =Parent.Width`, `Height: =Parent.Height`,
  `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, vertical, `LayoutOverflowY: =LayoutOverflow.Scroll`,
  `LayoutAlignItems: =LayoutAlignItems.Stretch`. Every section and every hidden engine button lives under it.
- Breakpoints read the screen root's `Width` directly (`conCalRoot.Width`, `conCalPRoot.Width`, `conAttRoot.Width`,
  ...): phone `< 640`, nav two-row band `640..799`, narrow `< 1024`, wide `>= 1280`. Never store breakpoints in
  variables.
- Nested day galleries (`galCalDays`, `galCalPDays`): WrapCount 7, 49 items per month (7 header cells + 42 day
  cells), `TemplatePadding: =0`, `LoadingSpinner: =LoadingSpinner.None`, `Selectable: =false`,
  `ShowScrollbar: =false`, numeric `Height` = 7 x cell height, one full-size control per template (no shell needed).
- Month galleries (`galCalMonths`, `galCalPMonths`): one AutoLayout shell child sized
  `Parent.TemplateWidth - 8` x `Parent.TemplateHeight - 8`; numeric `Height` = rows x `TemplateSize`, never
  `Self.TemplateHeight`; `LoadingSpinner: =LoadingSpinner.None`, `ShowScrollbar: =false`.
- **HARD LESSON: never move (re-parent) or rename an existing control.** Edit properties in place, insert NEW
  siblings with NEW names. Delete nothing in this build.

## Named State

App formulas (existing, unchanged): `IsAdminRole`, `CanManageStudents`, `CanClassify`, `StaffReady`, `CurrentStaff`,
`CurrentUserRow`, `RoleLabel`, `CurrentSchoolYear`, `ZeroGuid`, `NexusLogo`, `HelpContextPrefix`, palette `Color*`.

App formulas NEW (orchestrator, before builders): the eight `Cal*` colours above, plus

- `CalTypeOptions` - 7 rows `{Value, Show}`: Value = exact choice label, or `"Clear"`:
  Holiday "No school - Holiday"; Break "No school - Break"; Closed "No school - Closed"; Work Only "Staff
  Development (no students)"; Inclement Weather "Inclement Weather (closed)"; Make-up School Day "Make-up School
  Day"; Clear "Clear (remove the entry)".
- `CalLegend` - 8 rows `{Kind, Txt}` in legend order: rsy "First / Last Day RSY", esy "First / Last Day ESY",
  noschool "No School / Work", sdd "Staff Development", test "Testing start / end", weather "Inclement Weather",
  makeup "Make-up School Day", nonterm "Not in a quarter".

App.OnStart NEW seeds (all names start with `Cal`; CalendarPrintScreen reads the CalendarScreen collections):

| Name | Type / shape | Meaning / owner |
| --- | --- | --- |
| `varCalYearId` | GUID | shown school year (`'School Years'.'School Year'`) |
| `varCalCampusId` | GUID | shown campus (`Campuses.Campus`) |
| `varCalLoading`, `varCalSaving` | Boolean | busy flags |
| `varCalLoadError` | Text | last load error |
| `varCalPanel` | Text: `"Days"` \| `"Periods"` \| `"New year"` \| `"Copy"` | side panel (= tab text) |
| `varCalFrom`, `varCalTo` | Date, nullable (start Blank) | selected range (single source of truth for the Days panel) |
| `varCalPickTo` | Boolean | next day click sets To |
| `varCalDayAtt` | `{Key: Text, N: Number}` | attendance marks on the selected range/campuses/type; Key = freshness key |
| `varCalCopyTargetId` | GUID, nullable (start Blank) | Copy-to-campus target |
| `varCalReceipt` | `{Kind: Text, Title: Text}` | receipt banner |
| `varCalCheckWithAtt` | Boolean | next check run includes attendance counts |
| `varCalCheckStamp` | Text | "Checked h:mm ..." line |
| `varCalPPrinting` | Boolean | print screen: toolbar hidden while printing |
| `colCalYearOpts` | `{YearId, YearName, S, E, StatusText}` | year picker, newest first |
| `colCalCampusOpts` | `{CampusId, CampusName, Code}` | campus picker |
| `colCalTermsAll` | `{TermId, TermText, S, E, CampusId, Name}` | Terms of the shown year, all campuses (CampusId ZeroGuid = all-campus row) |
| `colCalExcAll` | `{ExcId, D, Label, TypeText, CampusId}` | Calendar Exceptions dated in the shown year, all campuses |
| `colCalLocksAll` | `{CampusId, MonthStart}` | Locked Month Locks, all campuses |
| `colCalTermsEff` | `{TermText, S, E, TermId, IsCampus, Has}` | 6 rows Q1, Q2, Q3, Q4, ESY, Testing - effective for the shown campus |
| `colCalExcEff` | `{ExcId, D, Label, TypeText, IsCampus}` | effective exceptions for the shown campus |
| `colCalYearDays` | `{D, Open}` | every date of the shown year; Open = school can be in session (weekday not closed, or make-up) |
| `colCalMonths` | `{MonthKey, MonthStart, Title, Locked}` | 12 months Aug..Jul |
| `colCalCells` | `{MonthKey, Idx, D, IsHdr, InMonth, Txt, Kind, Label, Tip}` | 588 cells (12 x 49) |
| `colCalExcFlag` | `{D, Label, IsStart, IsEnd}` | run detection for Important Dates |
| `colCalImportant` | `{Sec, SortD, IsHead, Line, Keep}` | right-column lists (Sec 1 Important Dates, 2 Staff Development Days, 3 Quarterly Periods, 4 Testing Period) |
| `colCalChecks` | `{Sev, Line}` | check results; Sev `"ok"` \| `"warn"` \| `"error"` |
| `colCalAlso` | `{CampusId, CampusName, Ticked}` | "Also apply to" other campuses |
| `colCalTargets` | `{CampusId, CampusName, Code}` | campuses a write applies to |
| `colCalPerEdit` | `{N, TermText, S, E}` | Periods panel working copy (6 rows) |
| `colCalDayWork` | `{D, CampusId, CampusName}` | dates x campuses for a day save |
| `colCalLog`, `colCalCopyNew` | `{Key, Outcome, Detail, Id}` | write logs (every Collect supplies all 4 fields; Id ZeroGuid when none) |
| `colCalCopyOld` | `{Kind, Id, Txt, Ms}` | rows to replace at the copy target |
| `colCalFed` | `{D, Label}` | federal holidays computed for a new year |
| `colCalTplTerms` | `{TermText, S, E}` | template periods shifted 364 days |
| `colCalTplExc` | `{D, Label, TypeText, Fed}` | template days shifted 364 days |
| `colCalReceiptLines` | `{Label, Value}` | receipt lines |

### Calendar data semantics (one definition, used everywhere)

- **Effective term** for a campus: the campus's own Terms row for that Term value, else the all-campus row (Campus
  blank). Testing is informational and never a quarter.
- **Effective exception** for a campus on a date: the campus's own Calendar Exceptions row, else the all-campus row.
- **Closed (no students)** = exception Type Holiday, Break, Closed, Inclement Weather, or Work Only (staff
  development). **No school (black)** = Holiday, Break, Closed only.
- **Open day** (`colCalYearDays.Open`) = Make-up School Day, or a Monday-Friday that is not closed.
- **Next school day after E** = `Min(Filter(colCalYearDays, Open && D > E), D)`. Quarters are back to back when
  `Q(n+1).Start = next school day after Q(n).End` (n = 1..3).
- **First/Last Day RSY** = Q1 start / Q4 end; **First/Last Day ESY** = ESY start / end.
- **Locked month** = `'Month Locks'` row with `'Status (aaca_status)' = 'Status (Month Locks)'.Locked` for that
  campus and `Month` = first day of the month. Days in a locked month are read-only for that campus.
- **Run of a named exception** (Important Dates grouping) = same Label, consecutive weekdays (Friday -> Monday
  counts as consecutive). Work Only days are listed separately as "SDD n".
- Day writes apply to Monday-Friday in the range (Make-up also Saturday), one row per date per campus.

## Control Naming

Standard abbreviations (`con`, `lbl`, `btn`, `dd`, `txt`, `dp`, `rdo`, `chk`, `tab`, `gal`, `tmr`, `img`, `spn`,
`htm`) + screen namespace. Names are app-unique. CalendarScreen `Cal` (`conCalRoot`, `galCalMonths`,
`btnCalLoadEngine`, ...); CalendarPrintScreen `CalP` (`conCalPRoot`, `galCalPMonths`, `tmrCalPPrint`, ...). New nav
buttons on the existing screens: `btnAttNavCalendar`, `btnStuNavCalendar`, `btnAbsNavCalendar`,
`btnTrnNavCalendar`, `btnStfNavCalendar`.

## Cross-Screen Contracts

### Header nav pattern (each screen instantiates it under its own prefix; values are fixed)

Every button: ModernButton, `Height: =44`, `Layout: =ButtonLayout.TextOnly`, `Size: =14`, `LayoutMinHeight: =0`,
`LayoutMinWidth: =0`, `AlignInContainer: =AlignInContainer.Center`.

| # | Text | Width | OnSelect | Visible | Non-current | Current screen |
| - | ---- | ----- | -------- | ------- | ----------- | -------------- |
| 1 | `"Attendance"` | 110 | `=Navigate(Screen1)` | `=CanManageStudents` | `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk`, AccessibleLabel `"Go to Attendance"` | `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite`, AccessibleLabel `"Attendance (current screen)"` |
| 2 | `"Students"` | 110 | `=Navigate(StudentsScreen)` | `=CanManageStudents` | same, `"Go to Students"` | same pattern |
| 3 | `"Absences"` | 110 | `=Navigate(AbsencesScreen)` | `=CanManageStudents` | same, `"Go to Absences"` | same pattern |
| 4 | `"Transportation"` | 140 | `=Navigate(TransportScreen)` | `=CanClassify` | same, `"Go to Transportation"` | same pattern |
| 5 | `"Staff"` | 80 | `=Navigate(StaffScreen)` | `=CanManageStudents` | same, `"Go to Staff"` | same pattern |
| 6 NEW | `"Calendar"` | 100 | `=Navigate(CalendarScreen)` | `=IsAdminRole` | same, `"Go to Calendar"` | same, `"Calendar (current screen)"` |

then the existing spacer `con<P>NavSpacer` (Visible `>= 640`) and the NEXUS logo `img<P>NavHelp` (44x44).

- Button 6 is inserted AFTER `btn<P>NavStaff` and BEFORE `con<P>NavSpacer` on every screen.
- Width budget (admin): 110+110+110+140+80+100 = 650 + 7 gaps x 8 = 56 + logo 44 = 750 (spacer shrinks to 0):
  one row when the nav's inner width >= 750, i.e. root >= 782 (nav inner = root - 32 on every screen).
  - root >= 800: one row, nav content 44.
  - 640..799: two rows (row 1: five buttons = 582 <= 608; row 2: Calendar + spacer + logo), content 44+8+44 = 96.
  - < 640 (343 inner on a 375 phone): three rows 228 / 258 / 240 (Staff 80 + Calendar 100 + logo 44 + 2 gaps),
    content 148 - unchanged from build 10.
- Height formulas therefore gain a middle branch `<root>.Width < 800, 96` (nav) and `<root>.Width < 800, 100`
  (header nav term = nav + 4 gap). Exact per-screen edits are in each brief.
- Wordmark `"AACA Attendance"` (Size 20 Bold white). Identity line unchanged.

### Calendar -> print view

- `btnCalView` (CalendarScreen header) runs `Navigate(CalendarPrintScreen)` only when the shown calendar is loaded.
- CalendarPrintScreen reads `varCalYearId`, `varCalCampusId`, `colCalYearOpts`, `colCalCampusOpts`, `CalLegend`,
  `colCalMonths`, `colCalCells`, `colCalImportant` exactly as CalendarScreen left them. It never queries Dataverse
  and never references CalendarScreen (its Back button uses `Back()`), so it can be built first.
- CalendarScreen `OnVisible` reloads the shown year/campus, so returning from print or from another screen shows
  fresh data.

### Navigation build order

`Navigate(CalendarPrintScreen)` requires CalendarPrintScreen in the session; `Navigate(CalendarScreen)` on the other
five screens requires CalendarScreen. Build CalendarPrintScreen, then CalendarScreen, then the five nav edits.

## YAML Conventions

- Every property value starts with `=`; multi-line formulas use `|-` with `=` on the first content line.
- Any value containing `: ` (record literals, captions like `"Ready: "`, `"SDD 1: "`, `"Qtr.1: "`) or ` #` MUST be
  a `|-` block. Unquoted ` #` starts a YAML comment.
- Dataverse predicates: `With()` scalars inside every LookUp/Filter over a data source (never `record.Field` in the
  predicate); lookup ids compare by id column (`Campus.Campus = c0`, `'School Year'.'School Year' = y0`); choice
  columns compare to option-set literals (`'Term (aaca_term)' = qt` where `qt` is a choice value) and use `= Blank()`
  (never `IsBlank`) for blank choice filters in delegated queries; disambiguate primary keys with `ThisRecord.`
  (`LookUp(Terms, ThisRecord.'Term (aaca_termid)' = q)`, `LookUp('Calendar Exceptions', ThisRecord.'Calendar Exception' = q)`).
- `IfError(A, B)`: both branches same type. Records: `IfError(Patch(...), Blank())`. Removes:
  `IfError(Remove(src, row); true, false)`. Table-returning success branches end with `; true`. Read a failure text
  with `Coalesce(First(Errors(<source>)).Message, "unknown error")` immediately, before any other write to that source.
- Never `Set` inside `ForAll`; `Collect` inside `ForAll` is fine. Never `Collect` into the collection a `ForAll` is
  iterating (snapshot it first). `Select(engine)` calls queue and run after the current formula, in order.
- Exact choice literals:
  - `'Type (Calendar Exceptions)'.Holiday` / `.Break` / `.Closed` / `.'Work Only'` / `.'Make-up School Day'` /
    `.'Inclement Weather'` (column `Type`; name column `Description`; date `Date`; lookup `Campus`; id
    `'Calendar Exception'`)
  - `'Term (Terms)'.Q1` / `.Q2` / `.Q3` / `.Q4` / `.ESY` / `.Testing` (column `'Term (aaca_term)'`; id
    `'Term (aaca_termid)'`; `Name`, `'Start Date'`, `'End Date'`, `'School Year'`, `Campus`)
  - `'Status (School Years)'.Planned` (column `'Status (aaca_status)'`; id `'School Year'`; `Name`, `'Start Date'`,
    `'End Date'`)
  - `'Status (Month Locks)'.Locked` (column `'Status (aaca_status)'`; `Campus`, `Month`)
  - `'Action (Audit Events)'.Update` (day saves, period saves, copy to campus) / `.Rollover` (create school year)
  - Type text to choice (write inline wherever needed):
    `Switch(tx, "Holiday", 'Type (Calendar Exceptions)'.Holiday, "Break", 'Type (Calendar Exceptions)'.Break, "Closed", 'Type (Calendar Exceptions)'.Closed, "Work Only", 'Type (Calendar Exceptions)'.'Work Only', "Inclement Weather", 'Type (Calendar Exceptions)'.'Inclement Weather', "Make-up School Day", 'Type (Calendar Exceptions)'.'Make-up School Day')`
  - Term text to choice:
    `Switch(tt, "Q1", 'Term (Terms)'.Q1, "Q2", 'Term (Terms)'.Q2, "Q3", 'Term (Terms)'.Q3, "Q4", 'Term (Terms)'.Q4, "ESY", 'Term (Terms)'.ESY, "Testing", 'Term (Terms)'.Testing)`
- Weekday math: `Weekday(d, StartOfWeek.Monday)` is 1 (Mon) .. 7 (Sun); `Weekday(d, StartOfWeek.Sunday)` and
  `Weekday(d)` are 1 (Sun) .. 7 (Sat). Date math: `DateAdd(d, n, TimeUnit.Days | TimeUnit.Months | TimeUnit.Years)`,
  `DateDiff(a, b, TimeUnit.Days)`.
- Audit Events rows: `Summary` (`Left(..., 100)`), `Action`, `Entity` (`"aaca_calendarexception"`, `"aaca_term"`,
  `"aaca_schoolyear"`), `'Entity ID'` (`Text(<guid>)`), `Before` / `After` (`JSON({...})` or `""`), `Reason`.
  Every write is IfError-wrapped and the receipt reports "Update written" / "NOT written".

## App.pa.yaml changes (orchestrator)

Apply BEFORE any builder runs; compile App first. No screen names are referenced, so App compiles on its own.

### 1. `App.Formulas` - append after the line beginning `      HelpContextPrefix = ` (same 6-space indent)

```
      // ---------- Calendar (build 13) ----------
      CalRsy = RGBA(21, 128, 61, 1);         // First / Last Day RSY; Make-up outline
      CalEsy = RGBA(29, 78, 216, 1);         // First / Last Day ESY
      CalNoSchool = RGBA(17, 17, 17, 1);     // Holiday, Break, Closed
      CalSdd = RGBA(112, 48, 160, 1);        // Staff Development (Work Only)
      CalTesting = RGBA(245, 158, 11, 1);    // Testing start / end (ink text)
      CalWeather = RGBA(185, 28, 28, 1);     // Inclement Weather
      CalNonTerm = RGBA(217, 217, 217, 1);   // weekday outside every quarter / ESY
      CalMonthBand = RGBA(31, 56, 100, 1);   // month title band
      CalTypeOptions = Table({Value: "Holiday", Show: "No school - Holiday"}, {Value: "Break", Show: "No school - Break"}, {Value: "Closed", Show: "No school - Closed"}, {Value: "Work Only", Show: "Staff Development (no students)"}, {Value: "Inclement Weather", Show: "Inclement Weather (closed)"}, {Value: "Make-up School Day", Show: "Make-up School Day"}, {Value: "Clear", Show: "Clear (remove the entry)"});
      CalLegend = Table({Kind: "rsy", Txt: "First / Last Day RSY"}, {Kind: "esy", Txt: "First / Last Day ESY"}, {Kind: "noschool", Txt: "No School / Work"}, {Kind: "sdd", Txt: "Staff Development"}, {Kind: "test", Txt: "Testing start / end"}, {Kind: "weather", Txt: "Inclement Weather"}, {Kind: "makeup", Txt: "Make-up School Day"}, {Kind: "nonterm", Txt: "Not in a quarter"});
```

(The Formulas property is already a `|-` block, so `: ` inside the record literals is safe. The `//` comments
contain no ` #`.)

### 2. `App.OnStart` - new seeds

Change the current final line `      Set(varAttQtrError, "")` to `      Set(varAttQtrError, "");` and append exactly
(6-space indent; the LAST line keeps NO trailing semicolon):

```
      Set(varCalYearId, Coalesce(CurrentSchoolYear.'School Year', ZeroGuid));
      Set(varCalCampusId, If(!IsBlank(CurrentStaff.Campus), CurrentStaff.Campus.Campus, Coalesce(First(Sort(Campuses, Name, SortOrder.Ascending)).Campus, ZeroGuid)));
      Set(varCalLoading, false);
      Set(varCalSaving, false);
      Set(varCalLoadError, "");
      Set(varCalPanel, "Days");
      Set(varCalFrom, Today());
      Set(varCalFrom, Blank());
      Set(varCalTo, Today());
      Set(varCalTo, Blank());
      Set(varCalPickTo, false);
      Set(varCalDayAtt, {Key: "", N: 0});
      Set(varCalCopyTargetId, ZeroGuid);
      Set(varCalCopyTargetId, Blank());
      Set(varCalReceipt, {Kind: "", Title: ""});
      Set(varCalCheckWithAtt, false);
      Set(varCalCheckStamp, "");
      Set(varCalPPrinting, false);
      ClearCollect(colCalYearOpts, {YearId: ZeroGuid, YearName: "", S: Today(), E: Today(), StatusText: ""});
      Clear(colCalYearOpts);
      ClearCollect(colCalCampusOpts, {CampusId: ZeroGuid, CampusName: "", Code: ""});
      Clear(colCalCampusOpts);
      ClearCollect(colCalTermsAll, {TermId: ZeroGuid, TermText: "", S: Today(), E: Today(), CampusId: ZeroGuid, Name: ""});
      Clear(colCalTermsAll);
      ClearCollect(colCalExcAll, {ExcId: ZeroGuid, D: Today(), Label: "", TypeText: "", CampusId: ZeroGuid});
      Clear(colCalExcAll);
      ClearCollect(colCalLocksAll, {CampusId: ZeroGuid, MonthStart: Today()});
      Clear(colCalLocksAll);
      ClearCollect(colCalTermsEff, {TermText: "", S: Today(), E: Today(), TermId: ZeroGuid, IsCampus: false, Has: false});
      Clear(colCalTermsEff);
      ClearCollect(colCalExcEff, {ExcId: ZeroGuid, D: Today(), Label: "", TypeText: "", IsCampus: false});
      Clear(colCalExcEff);
      ClearCollect(colCalYearDays, {D: Today(), Open: false});
      Clear(colCalYearDays);
      ClearCollect(colCalMonths, {MonthKey: 0, MonthStart: Today(), Title: "", Locked: false});
      Clear(colCalMonths);
      ClearCollect(colCalCells, {MonthKey: 0, Idx: 0, D: Today(), IsHdr: false, InMonth: false, Txt: "", Kind: "", Label: "", Tip: ""});
      Clear(colCalCells);
      ClearCollect(colCalExcFlag, {D: Today(), Label: "", IsStart: false, IsEnd: false});
      Clear(colCalExcFlag);
      ClearCollect(colCalImportant, {Sec: 0, SortD: Today(), IsHead: false, Line: "", Keep: false});
      Clear(colCalImportant);
      ClearCollect(colCalChecks, {Sev: "", Line: ""});
      Clear(colCalChecks);
      ClearCollect(colCalAlso, {CampusId: ZeroGuid, CampusName: "", Ticked: false});
      Clear(colCalAlso);
      ClearCollect(colCalTargets, {CampusId: ZeroGuid, CampusName: "", Code: ""});
      Clear(colCalTargets);
      ClearCollect(colCalPerEdit, {N: 0, TermText: "", S: Today(), E: Today()});
      Clear(colCalPerEdit);
      ClearCollect(colCalDayWork, {D: Today(), CampusId: ZeroGuid, CampusName: ""});
      Clear(colCalDayWork);
      ClearCollect(colCalLog, {Key: "", Outcome: "", Detail: "", Id: ZeroGuid});
      Clear(colCalLog);
      ClearCollect(colCalCopyNew, {Key: "", Outcome: "", Detail: "", Id: ZeroGuid});
      Clear(colCalCopyNew);
      ClearCollect(colCalCopyOld, {Kind: "", Id: ZeroGuid, Txt: "", Ms: Today()});
      Clear(colCalCopyOld);
      ClearCollect(colCalFed, {D: Today(), Label: ""});
      Clear(colCalFed);
      ClearCollect(colCalTplTerms, {TermText: "", S: Today(), E: Today()});
      Clear(colCalTplTerms);
      ClearCollect(colCalTplExc, {D: Today(), Label: "", TypeText: "", Fed: false});
      Clear(colCalTplExc);
      ClearCollect(colCalReceiptLines, {Label: "", Value: ""});
      Clear(colCalReceiptLines)
```

(OnStart is already a `|-` block, so the `: ` inside record literals is safe.)

### 3. `_EditorState.pa.yaml` (after both new screens exist)

`ScreensOrder`: Screen1, StudentsScreen, AbsencesScreen, TransportScreen, StaffScreen, CalendarScreen,
CalendarPrintScreen. `StartScreen` is unchanged.
