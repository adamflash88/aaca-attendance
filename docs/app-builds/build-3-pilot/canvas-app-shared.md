# Canvas App Shared Plan — AACA Attendance (Build 3)

## Aesthetic Direction

"Classroom register": warm paper page, deep ink header band, teal primary actions, green/red reserved for
excused/unexcused meaning. Utilitarian and dense; one clear page title per screen. All colours are App named
formulas; never write RGBA literals in a screen.

- Page background: `ColorPaper` (RGBA 247,245,240)
- Header band: `ColorInk` (RGBA 27,42,65); header text `ColorWhite`, identity line `ColorInkSoft`
- Accent / primary action: `ColorTeal` (RGBA 0,110,97)
- Text primary: `ColorInk`; field labels and captions: `ColorMuted`
- Borders: `ColorRule`; panels `ColorWhite`
- Meaning colours: `ColorExcused` (green), `ColorUnexcused` (red); backgrounds `ColorInfoBg`, `ColorWarnBg`, `ColorErrorBg`, `ColorNonSchool` (locked row)

## Visual Contract

- Type roles (ModernText `Size` / `FontWeight`): app title 20 Bold white; panel title 20 Bold ink; section heading
  16 Semibold; form title 18 Bold; body 13–14 Normal; field label / caption 12 Semibold `ColorMuted`; row meta 12.
- Every ModernText sets all four `Padding*: =0`, an explicit `Height` (>= Size x 1.5 per line) and
  `AccessibleLabel`; single-line labels `Wrap: =false`.
- Spacing scale: gaps 2 / 4 / 8; container padding 8 / 12 / 16. No other values.
- Surfaces: panels `Fill: =ColorWhite`, `BorderColor: =ColorRule`, `BorderThickness: =1`, radius 6 on all four
  corners, `DropShadow: =DropShadow.None`. Header band and root radius 0.
- Actions (ModernButton, `Layout: =ButtonLayout.TextOnly`, `Height: =44`, `Size: =14`):
  - Primary: default appearance (omit Appearance), `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite`.
  - Secondary: `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk`.
  - Destructive (End enrollment submit, Unexcused): `BasePaletteColor: =ColorUnexcused`, `Color: =ColorWhite`.
  - Excused actions: `BasePaletteColor: =ColorExcused`, `Color: =ColorWhite`.
  - Disabled: via `DisplayMode` only.
- Status badges: `Badge`, `Appearance: ='BadgeCanvas.Appearance'.Tint`, `Shape: ='BadgeCanvas.Shape'.Rounded`,
  `FontColor: =ColorInk`, `FontSize: =12`, `Height: =24`, fixed `Width` for the longest value.
- Density: desktop two columns (list + side panel) at >= 1024; one column below 1024; phone 390.

## Layout Strategy

- Responsive, desktop-first (1366x768), usable at 1024 and 390.
- One root per screen: `con<Prefix>Root`, GroupContainer AutoLayout Vertical, `Width: =Parent.Width`,
  `Height: =Parent.Height`, `LayoutOverflowY: =LayoutOverflow.Scroll`, `LayoutGap: =8`, `PaddingBottom: =16`,
  `Fill: =ColorPaper`. It is the only screen-level child; header, alerts, receipt, body and hidden engines are all
  nested under it. Direct children of the root use `FillPortions: =0` with explicit `Height`.
- Breakpoints read the root width directly: `con<Prefix>Root.Width < 640` (phone) and `>= 1024` (desktop). Never
  store layout in variables.
- Every GroupContainer sets `LayoutMinWidth: =0`, `LayoutMinHeight: =0`; every AutoLayout child sets
  `AlignInContainer` and `FillPortions`. Inputs (dropdown, date picker, text input, radio) set `LayoutMinWidth: =0`
  (their defaults are 320).
- Galleries: fixed numeric `Height`, explicit `TemplateSize`, `TemplatePadding: =0`, one AutoLayout shell child
  using `Parent.TemplateWidth` / `Parent.TemplateHeight`; `Selectable: =false`, `TabIndex: =0`.
- Container heights are sums of literal child heights, gaps and padding (never bare `LayoutGap`/`Padding*` names).

## Named State

App.Formulas (existing unless marked new): CurrentUserRow, CurrentStaff, StaffReady, IsTeacherRole, IsOfficeRole,
IsAdminRole, IsReadOnlyRole, CanEditRole, CanPickCampus, CanPickTeacher, RoleLabel, AllowFutureDates, ZeroGuid,
palette, CanManageStudents, StudentCampusLock (Office's own campus id, else ZeroGuid), StudentDefaultScope,
ActiveService, MonthOptions, FirstSchoolYear, **CanClassify (new) = IsOfficeRole || IsAdminRole**,
**CurrentSchoolYear (new) = School Years row containing Today()**.

Absences state (App.OnStart, new; owned by AbsencesScreen):

| Name | Type | Meaning |
| ---- | ---- | ------- |
| varAbsCampusId | GUID | Campus filter (Office = StudentCampusLock) |
| varAbsTeacherId | GUID | Teacher filter, ZeroGuid = all |
| varAbsStatus | Text | "Not classified" / "Excused" / "Unexcused" / "All" |
| varAbsFrom, varAbsTo | Date | Date range (default school-year start .. Today()) |
| varAbsLoading, varAbsSaving | Boolean | Engine running flags |
| varAbsLoadError | Text | Last load error |
| varAbsSelId | GUID (nullable) | Absence picked for the Excused reason prompt |
| varAbsReasonId | GUID (nullable) | Reason chosen in the prompt |
| varAbsBulkReasonId | GUID (nullable) | Reason for Mark Excused |
| varAbsReq | {Kind, Scope, ReasonId} | Request consumed by btnAbsClassifyEngine |
| varAbsReceipt | {Kind, Title} | Receipt header |
| colAbsTicked | {AttId} | Ticked absence ids |
| colAbsWork | {AttId} | Snapshot of ids the engine will process |
| colAbsLog | {AttId, StudentName, AbsDate, TeacherName, CampusName, OldClass, NewClass, ReasonName, ByName, OnText, Outcome, AuditOk} | Per-row outcome captured from Patch results |
| colAbsReceiptLines | {Label, Value} | Receipt lines |

Screen-created collections (AbsencesScreen only): colAbsList, colAbsLocks, colAbsReasons, colAbsCampusOpts,
colAbsTeacherSrc, colAbsTeacherOpts. Students (existing): varStuMode now uses "add", "edit", "transfer", "ratio",
"end", "reenroll".

## Control Naming

Type abbreviation + screen prefix + purpose: `con` GroupContainer, `lbl` ModernText, `btn` ModernButton /
Classic/Button, `gal` Gallery, `dd` ModernDropdown, `dp` ModernDatePicker, `rdo` ModernRadio, `chk` ModernCheckbox,
`spn` ModernSpinner, `badge` Badge, `txt` ModernTextInput. Prefixes: Screen1 `Att`, StudentsScreen `Stu`,
AbsencesScreen `Abs`. Names are unique app-wide; never reuse another screen's name.

## Cross-Screen Contracts

### Header navigation pattern (instantiate per screen under its own prefix)

Inside `con<P>Header` (existing on Att/Stu; copy the Students header for Abs) the nav row is:

- `con<P>Nav`: GroupContainer AutoLayout, `LayoutDirection: =LayoutDirection.Horizontal`, `LayoutGap: =8`,
  `LayoutAlignItems: =LayoutAlignItems.Center`, `Height: =44`, `FillPortions: =0`, `DropShadow: =DropShadow.None`,
  radius 0, `Visible: =CanManageStudents`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`.
- Exactly three children in this order, no others:
  1. `btn<P>NavAttendance` — Text `="Attendance"`, `OnSelect: =Navigate(Screen1)`
  2. `btn<P>NavStudents` — Text `="Students"`, `OnSelect: =Navigate(StudentsScreen)`
  3. `btn<P>NavAbsences` — Text `="Absences"`, `OnSelect: =Navigate(AbsencesScreen)`
- Every nav button: `Width: =110`, `Height: =44`, `Size: =14`, `Layout: =ButtonLayout.TextOnly`,
  `AlignInContainer: =AlignInContainer.Center`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`.
- Current screen's button: no Appearance (Primary), `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite`,
  `AccessibleLabel: ="<Name> (current screen)"`.
- Other buttons: `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk`, `AccessibleLabel: ="Go to <Name>"`.
- Header band: `Fill: =ColorInk`, padding 12/16/12/16, gap 4, vertical, Stretch,
  `Height: =If(con<P>Root.Width < 640, 92, 76) + If(CanManageStudents, 48, 0)`; title "AACA Attendance" 20 Bold
  white (h28, wrap false); identity line ColorInkSoft 12 (h `If(root < 640, 36, 20)`).

### Receipt pattern

Mutation results render in `con<P>Receipt` directly after the header/alerts (initial viewport), bound to captured
Patch results: title text + Dismiss, and a `{Label, Value}` gallery (WrapCount 1/2/3 at <640/<1024/else,
TemplateSize 40, Height `Min(400, RoundUp(CountRows(lines) / cols, 0) * 40)`). Fill by Kind: "Failed"/"Blocked"
ColorErrorBg, "Cancelled" ColorWarnBg, otherwise ColorInfoBg; text ColorInk. Visible while Kind <> "".

### Engines

Heavy formulas live in hidden `Classic/Button` engines (`Visible: =false`, `AutoDisableOnSelect: =false`,
`Text` short word) triggered with `Select(...)` as the last statement of a behaviour formula. Engines re-check
eligibility against live Dataverse before writing.

### Data and freshness

- Screen1 reloads its month (Attendance -> colMonthAtt, Letter E/U) in OnVisible, so classifications made on
  AbsencesScreen appear green/red when the user returns. No Screen1 formula changes.
- Absence queue predicate (delegable; use `= Blank()`, never IsBlank, on the choice column):
  `Present = false && 'Is Deleted' = false && <status> && Campus.Campus = c0 && Date >= d0 && Date <= d1`.
- Month lock key: campus id + `Date(Year(d), Month(d), 1)` against Month Locks rows with
  `'Status (aaca_status)' = 'Status (Month Locks)'.Locked`.

## YAML Conventions

- Every property value starts with `=`; multi-line formulas use `|-` with `=` on the first content line.
- Any value containing `: ` (caption text or a record literal such as `{AttId: ThisItem.AttId}`) must be a `|-`
  block or wrapped in single quotes.
- Enum literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `LayoutDirection.Vertical`,
  `LayoutAlignItems.Stretch`, `AlignInContainer.Center`, `LayoutOverflow.Scroll`, `DropShadow.None`,
  `FontWeight.Semibold`, `VerticalAlign.Top`, `Appearance.Outline`, `DatePickerFormat.Short`,
  `OptionLayout.Vertical`, `DisplayMode.Disabled`, `'BadgeCanvas.Appearance'.Tint`, `'BadgeCanvas.ThemeColor'.Success`.
- Choice values: `'Absence Classification (Attendance)'.Excused` / `.Unexcused`; `'Status (Month Locks)'.Locked`;
  `'Action (Audit Events)'.Reclassify` / `.Archive` / `.Unarchive`; `'End Reason (Enrollments)'.Archived`;
  `'Status (Enrollments)'.Active` / `.Planned` / `.Ended`; `'Status (Students)'.Active` / `.Archived`;
  `'Program (Enrollments)'.'Regular Year'`.
- GUID lookups compare the raw id: `LookUp(Attendance, ThisRecord.Attendance = qid)` with `qid` captured by `With`.
- Do not edit `_EditorState.pa.yaml` or `App.pa.yaml` in screen builds.
