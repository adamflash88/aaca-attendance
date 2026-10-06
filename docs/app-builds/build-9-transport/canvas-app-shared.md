# Canvas App Shared Plan - AACA Attendance (build 9 edit: Add absence, Left early, Transportation)

Screens touched: TransportScreen (NEW, prefix `Trn`), AbsencesScreen (`Abs`), Screen1 (`Att`), StudentsScreen (`Stu`).
Every builder reads this file plus its own brief.

## Aesthetic Direction

"Classroom register": warm paper page, ink-navy header band, teal accent, green/red absence classification. All
colours are App.Formulas named constants - always use the name, never a new RGBA:

- Page `ColorPaper`; panels `ColorWhite`; rules/borders `ColorRule`
- Text primary `ColorInk`; secondary `ColorMuted`; on-ink text `ColorWhite` / `ColorInkSoft`
- Accent / primary action `ColorTeal`
- Excused `ColorExcused` (white text on it); Unexcused / destructive `ColorUnexcused` (white text)
- Status surfaces (always `ColorInk` text on them): `ColorInfoBg` (success/info, selected rows), `ColorWarnBg`
  (warning, unconfirmed-days banner), `ColorErrorBg` (failed/blocked), `ColorNonSchool` (ended / locked rows)

## Visual Contract

- Type roles (ModernText `Size`/`FontWeight`): app title 20 Bold white; panel heading 18-20 Bold ink; section heading
  16 Semibold ink; row identity 14 Semibold ink; body 13 Normal ink; field label 12 Semibold muted; caption/meta 12.
- Every NEW ModernText sets all four Padding* (0) unless the brief says otherwise, `AccessibleLabel`,
  `AlignInContainer`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, an explicit `Height`; single-line labels
  `Wrap: =false`; multi-line text `VerticalAlign: =VerticalAlign.Top`.
- Spacing: container gap 8 (field groups and form panels 4); panel padding 16; receipt/notice padding 8 top/bottom,
  12 sides; banner padding 12; radius 6 on panels, 0 on header/strip containers.
- Panels: `Fill: =ColorWhite`, `BorderColor: =ColorRule`, `BorderThickness: =1`, `DropShadow: =DropShadow.None`,
  radius 6 (all four Radius* properties).
- Every NEW GroupContainer: `Variant: AutoLayout`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`,
  `DropShadow: =DropShadow.None`, explicit `LayoutDirection`, `LayoutAlignItems`, `FillPortions`, and `Height` (or
  `FillPortions > 0`).
- Actions (ModernButton, `Height: =44`, `Layout: =ButtonLayout.TextOnly`, `Size: =14`, `LayoutMinHeight: =0`,
  `LayoutMinWidth: =0`, explicit `Width`, `AlignInContainer: =AlignInContainer.Center` in rows):
  - Primary: `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite` (Appearance default Primary)
  - Destructive (End transportation save): `BasePaletteColor: =ColorUnexcused`, `Color: =ColorWhite`
  - Secondary: `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk` (never light text on Secondary)
  - Toggles / mode / status-choice buttons: `Appearance: =If(active, ButtonAppearance.Primary,
    ButtonAppearance.Secondary)`, `BasePaletteColor: =ColorTeal`, `Color: =If(active, ColorWhite, ColorInk)`
  - Disabled via `DisplayMode: =DisplayMode.Disabled`.
- No symbol glyphs (arrows, triangles, check marks, refresh marks) in any NEW text. Use plain words, "-" or "·".

## Layout Strategy

- Responsive, desktop-first (1366x768), usable at 1024 and on a 375 phone. Each screen has ONE scroll root (the sole
  top-level child): `Width: =Parent.Width`, `Height: =Parent.Height`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`,
  vertical, `LayoutOverflowY: =LayoutOverflow.Scroll`, `LayoutAlignItems: =LayoutAlignItems.Stretch`, no side
  padding, `PaddingBottom: =16`, `LayoutGap: =8`. Every section and every hidden engine button lives under it.
- Breakpoints read the screen root's `Width` directly (`conTrnRoot.Width`, `conAbsRoot.Width`, `conAttRoot.Width`,
  `conStuRoot.Width`): phone `< 640`, tablet `< 1024`, desktop `>= 1024`. Never store breakpoints in variables or set
  them in `OnVisible`.
- Direct children of the root and of view containers: `FillPortions: =0` with explicit `Height`. Height formulas use
  literal numbers (never bare `PaddingTop`/`LayoutGap` names).
- Two-panel bodies (list + right-hand detail column): horizontal at `>= 1024` (list `FillPortions` 2, detail 1),
  vertical below; on `< 1024` the list hides while the detail column is in use (existing Absences pattern).
- Galleries: exactly one AutoLayout shell child sized `Parent.TemplateWidth - 16` / `Parent.TemplateHeight` (a
  horizontal chip gallery with a single button child needs no shell); numeric fixed `Height`; explicit
  `TemplateSize`; `TemplatePadding: =0`; `TabIndex: =0`; `Selectable: =false`.
- **Root-order rule (learned in build 8):** Studio may reorder a screen's ROOT children on compile. Anything that must
  render at the top (title, nav, view tabs, campus picker) lives INSIDE the header container. The header has no side
  padding; its children carry `PaddingLeft/Right: =16` (labels) or the nav/tab containers carry 16 side padding. The
  view-tab strip is a full-width `ColorPaper` strip and is the header's LAST child (pattern: `conAbsHdrTabs`).
- **HARD LESSON: never move (re-parent) or rename an existing control.** Studio renders moved controls as black boxes.
  Edit properties in place and add NEW controls with NEW names. Inserting a new sibling into an existing container is
  allowed. Delete nothing in this build.

## Named State

App formulas (existing, unchanged): `CurrentUserRow`, `CurrentStaff`, `StaffReady`, `CanClassify` (= Office || Admin),
`CanManageStudents` (same set), `StudentCampusLock` (office campus GUID or `ZeroGuid`), `ZeroGuid`, `FirstSchoolYear`,
`ParentReportCutover`, `RoleLabel`, `AllowFutureDates`, palette `Color*`.

App formulas NEW (added before builders, see plan index App Changes):
- `TransportStatusOptions = ["Round trip", "Drop off only", "Pick up only", "No transportation"]` (single column `Value`)
- `TransportPatternOptions = ["Round trip", "Drop off only", "Pick up only"]` (single column `Value`)

App.OnStart NEW seeds (added before builders):
- AbsencesScreen: `varAbsAddMode` ("" | "absence" | "leftearly"), `varAbsAddClass` ("" | "Excused" | "Unexcused"),
  `varAbsAddReasonId` (GUID, nullable, starts Blank), `varAbsAddErr` (Text).
- TransportScreen: `varTrnView` ("daily" | "students"), `varTrnCampusId` (GUID), `varTrnDate` (Date),
  `varTrnIsSchoolDay` (Boolean), `varTrnDayReason` (Text), `varTrnLoading`, `varTrnSaving`, `varTrnShowEnded`
  (Boolean), `varTrnLoadError` (Text), `varTrnStuMode` ("" | "add" | "change" | "end"), `varTrnSelStId` (GUID,
  nullable, starts Blank), `varTrnReq` = `{Scope: Text}` ("day" | "row"), `varTrnReceipt` = `{Kind: Text, Title:
  Text}` (always both fields), `colTrnReceiptLines` = `{Label, Value}`, `colTrnWork` = `{StudentId: GUID, Status:
  Text}`, `colTrnLog` = `{StudentName, Before, Status, ByName, OnText, LogKey, Outcome, AuditOk}` (every Collect
  supplies all 8 fields).

Existing AbsencesScreen state reused (types unchanged): `varAbsCampusId`, `varAbsSaving`, `varAbsLoading`,
`varAbsSelId`, `varAbsReasonId`, `varAbsReceipt` = `{Kind, Title}`, `colAbsReceiptLines` = `{Label, Value}`,
`colAbsLocks` = `{CampusId, MonthStart}`, `colAbsReasons` = `{ReasonId, ReasonName, SortOrder}`, `colAbsLog` =
`{AttId, StudentName, AbsDate, TeacherName, CampusName, OldClass, NewClass, ReasonName, ByName, OnText, Outcome,
AuditOk}` (every Collect supplies all 12 fields).

Screen1 collection change: every record written to `colMonthAtt` gains `LeftEarly` (Boolean) and `LeftEarlyAt`
(DateTime). Only Screen1 reads `colMonthAtt`.

### School-day rule (shared semantics, implemented per screen over cached collections)

A date `d` is a school day for campus `c` when: a Terms row covers `d` (`'Start Date' <= d && 'End Date' >= d`) with
blank Campus or Campus = `c`; AND either a Calendar Exceptions row on `d` (blank Campus or `c`) has Type
`'Type (Calendar Exceptions)'.'Make-up School Day'`, or (`Weekday(d, StartOfWeek.Monday) < 6` and no Calendar
Exceptions row on `d` for blank Campus or `c` with any other Type). This is exactly Screen1's `colMonthDays.IsSchoolDay`.
It is NOT a named formula: named formulas take no parameters and user-defined functions are not verified in this app.
Each brief gives the exact inline formula over its own cached `Terms` / `'Calendar Exceptions'` collections
(always compare with `ThisRecord.` on collection columns, as Screen1 does).

## Control Naming

Standard abbreviations (`con` container, `lbl` ModernText, `btn` button, `dd` dropdown, `cbo` combobox, `txt` text
input, `dp` date picker, `rdo` radio, `chk` checkbox, `gal` gallery) + screen namespace. Names are app-unique.
- TransportScreen: `Trn` (`conTrnRoot`, `btnTrnNavAbsences`, `galTrnDayList`, ...).
- AbsencesScreen NEW controls: `AbsAdd…V` / `AbsLe…V` (+ `btnAbsNavTransport`, `btnAbsAddLoadEngine`).
- Screen1 NEW: `btnAttNavTransport`. StudentsScreen NEW: `btnStuNavTransport`.

## Cross-Screen Contracts

### Header nav pattern (each screen instantiates it under its own prefix; values are fixed)

Order and exact values (every button: ModernButton, `Height: =44`, `Layout: =ButtonLayout.TextOnly`, `Size: =14`,
`LayoutMinHeight: =0`, `LayoutMinWidth: =0`, `AlignInContainer: =AlignInContainer.Center`):

| # | Text | Width | OnSelect | Non-current | Current screen |
| - | ---- | ----- | -------- | ----------- | -------------- |
| 1 | `"Attendance"` | 110 | `=Navigate(Screen1)` | `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk`, AccessibleLabel `"Go to Attendance"` | `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite`, AccessibleLabel `"Attendance (current screen)"` |
| 2 | `"Students"` | 110 | `=Navigate(StudentsScreen)` | same pattern, `"Go to Students"` | same, `"Students (current screen)"` |
| 3 | `"Absences"` | 110 | `=Navigate(AbsencesScreen)` | same pattern, `"Go to Absences"` | same, `"Absences (current screen)"` |
| 4 | `"Transportation"` | 140 | `=Navigate(TransportScreen)` | same pattern, `"Go to Transportation"` | same, `"Transportation (current screen)"` |

- Button 4 sets `Visible: =CanClassify` on every screen (its nav container is already `Visible: =CanManageStudents`,
  the same role set). No other children in the nav container.
- Nav container: horizontal, `LayoutGap: =8`, `LayoutAlignItems: =LayoutAlignItems.Center`, `LayoutWrap: =true`,
  `Height: =If(<root>.Width < 640, 96, 44)` (+8 on AbsencesScreen/TransportScreen, see below). Width budget:
  110+8+110+8+110+8+140 = 494; wraps to two rows below ~526 px (phone 375: 228 / 258 per row).
- Wordmark: `"AACA Attendance"` (lbl…Title, Size 20 Bold white). Identity line: `Coalesce(CurrentUserRow.'Full Name',
  User().FullName) & " · " & RoleLabel & " · " & If(!StaffReady, "no campus", IsBlank(CurrentStaff.Campus),
  "All campuses", CurrentStaff.Campus.Name)` (Size 12, `ColorInkSoft`).

### View tabs strip (AbsencesScreen `conAbsHdrTabs`, TransportScreen `conTrnHdrTabs`)

Last child of the header; `Fill: =ColorPaper`, Padding 8 top/bottom, 16 sides, gap 8, `Visible: =CanClassify`;
tab buttons use the toggle pattern (Primary teal + white when active, Secondary + ink otherwise), Width 130-220.

### Navigation and freshness

- Screen1 `OnVisible` re-runs its load engine: Attendance rows written on AbsencesScreen (Add absence, Left early)
  appear on the grid at the next visit (`1*` for left early, `0` coloured by classification for absences).
- TransportScreen `OnVisible` reloads everything and resets `varTrnDate` to `Today()`.
- `Navigate(TransportScreen)` on Screen1 / StudentsScreen / AbsencesScreen requires TransportScreen to exist in the
  session: the orchestrator compiles TransportScreen first.

## YAML Conventions

- Every property value starts with `=`; multi-line formulas use `|-` with `=` on the first content line.
- Any value containing `: ` (caption text such as `"Date: "`, record literals like `{Value: "x"}`, `{Scope: "day"}`)
  or ` #` MUST be a `|-` block. Unquoted ` #` starts a YAML comment and silently truncates the formula.
- Dataverse predicates: use `With()` scalars inside every LookUp/Filter over a data source (never `record.Field` inside
  the predicate); choice columns compare `= Blank()` (not `IsBlank`) in delegated filters; disambiguate primary-key
  columns that share the table name with `ThisRecord.` (`LookUp('Daily Transport', ThisRecord.'Daily Transport' = q)`).
- `IfError(A, B)`: both branches same type; table-returning success branches end with `; true`;
  `IfError(Patch(...), Blank())` is the verified record pattern.
- Yes/No columns are Booleans: `'Left Early' = true`, `{'Left Early': true}`, `'Is Deleted' = false`, `Present = true`.
- Choice literals (exact):
  - `'Source (Attendance)'.Office`, `'Absence Classification (Attendance)'.Excused` / `.Unexcused`
  - `'Transport Status (Daily Transport)'.'Round trip'` / `.'Drop off only'` / `.'Pick up only'` / `.'No transportation'`
  - `'Usual Pattern (Student Transportation)'.'Round trip'` / `.'Drop off only'` / `.'Pick up only'`
  - `'Source (Student Transportation)'.Manual` / `.CodeMetro`
  - `'Action (Audit Events)'.Create` / `.Update`
  - `'Type (Calendar Exceptions)'.'Make-up School Day'`, `'Status (Month Locks)'.Locked`
  - IEP map (copy from Screen1): `'IEP Ratio (Enrollments)'.'No Aide'` -> `'IEP Ratio (Attendance)'.'No Aide'`, same for
    `'1:1'`, `'2:1'`, `'3:1'`, `'4:1'`.
- Enum literals: `ButtonAppearance.Secondary`, `ButtonAppearance.Primary`, `ButtonLayout.TextOnly`,
  `Appearance.Outline`, `TextInputType.Multiline`, `TextInputType.SingleLine`, `FontWeight.Semibold`, `FontWeight.Bold`,
  `LayoutDirection.Vertical`, `LayoutDirection.Horizontal`, `LayoutAlignItems.Stretch`, `LayoutAlignItems.Center`,
  `LayoutAlignItems.Start`, `AlignInContainer.Stretch`, `AlignInContainer.Center`, `AlignInContainer.Start`,
  `LayoutOverflow.Scroll`, `DisplayMode.Edit`, `DisplayMode.Disabled`, `VerticalAlign.Top`, `DropShadow.None`,
  `DatePickerFormat.Short`, `OptionLayout.Horizontal`, `OptionLayout.Vertical`, `Align.Center`.
- Audit Events rows: `Summary` (Left(..., 100)), `Action`, `Entity` (logical table name), `'Entity ID'`
  (`Text(<guid>)`), `Before` / `After` (`JSON({...})` or ""), `Reason`. Every write is wrapped in IfError and the
  receipt reports "audit ... written" / "audit NOT written".
- `Select(engine)` calls queue in order; an engine may be selected from inside a gallery row.
