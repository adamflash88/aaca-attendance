# Canvas App Shared Plan — AACA Attendance, build 2 (Student Management)

## Aesthetic Direction

"Classroom register": warm paper page, ink-navy header band, white ruled panels, one teal accent
for primary actions and current state. Utilitarian and dense; hierarchy comes from weight and
size, not colour. Every colour is an existing App.Formulas named formula — never write a new RGBA.

- Page background: `ColorPaper`
- Header band: `ColorInk` with `ColorWhite` title and `ColorInkSoft` identity line
- Panels: `ColorWhite`, border `ColorRule` 1px, radius 6 (all four corners), `DropShadow.None`
- Accent / primary action / current nav item / selected row edge: `ColorTeal`
- Text primary: `ColorInk`; text secondary / field labels: `ColorMuted`
- Status surfaces: success/info `ColorInfoBg`, warning `ColorWarnBg`, error `ColorErrorBg`
- Destructive action base: `ColorUnexcused`; "ready" validation text: `ColorExcused`

## Visual Contract

- Type roles (ModernText `Size` / `FontWeight`):
  - Wordmark (header): 20 Bold, `ColorWhite`, text exactly `"AACA Attendance"`
  - Identity line (header): 12 Normal, `ColorInkSoft`
  - Page heading (e.g. "Students"): 20 Bold, `ColorInk`
  - Panel/record title (selected student name, form title): 18–20 Bold, `ColorInk`
  - Section heading (e.g. "Enrollment history"): 16 Semibold, `ColorInk`
  - Body / facts / validation: 13–14 Normal, `ColorInk`
  - Field label / caption / metadata: 12 Normal (labels Semibold allowed), `ColorMuted`
- Spacing scale: gaps 2, 4, 8; padding 6, 8, 12, 16. Nothing else.
- Every ModernText sets all four `Padding*` explicitly (0 unless a value above is stated).
- Actions (ModernButton, `Layout: =ButtonLayout.TextOnly`, `Size: =14`, `Height: =44`):
  - Primary: `Appearance: =ButtonAppearance.Primary`, `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite`
  - Destructive primary (Discharge, Archive submit): same with `BasePaletteColor: =ColorUnexcused`
  - Secondary: `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk` (never a light Color on Secondary)
  - Disabled: via `DisplayMode.Disabled` only; never hide a required action to disable it
- Inputs: `Appearance: =Appearance.Outline`, `Color: =ColorInk`, `Height: =36` (multiline 64)
- Density: desktop 1366 and tablet 1024 show list and profile side by side; below 1024 they
  stack and the list hides while a student or form is open (a "Back to list" button returns).

## Layout Strategy

- Target: Responsive, desktop-first 1366x768; tablet 1024; phone 390. Narrowest supported
  rendered root width: 390.
- Breakpoints (from the screen root's `Width`, e.g. `conStuRoot.Width` / `conAttRoot.Width`):
  phone `< 640`, stacked `< 1024`, side-by-side `>= 1024`. Inner panels may additionally
  branch on their own panel width where the brief says so (for text wrap budgets only).
- Never store layout in variables; never initialise breakpoint state in `OnVisible`.
- Each screen has exactly one top-level child: its AutoLayout root with exact
  `Width: =Parent.Width`, `Height: =Parent.Height`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`,
  `LayoutDirection: =LayoutDirection.Vertical`, `LayoutOverflowY: =LayoutOverflow.Scroll`,
  `LayoutAlignItems: =LayoutAlignItems.Stretch`, `LayoutGap: =8`, `PaddingBottom: =16`, `Fill: =ColorPaper`,
  all radii 0, `DropShadow: =DropShadow.None`. Every header, alert, receipt, form, panel and hidden
  engine button is nested under it.
- Direct children of the root use `FillPortions: =0` with an explicit `Height`.
- Every GroupContainer sets `LayoutMinWidth: =0` and `LayoutMinHeight: =0`; every AutoLayout child
  sets `AlignInContainer` and `FillPortions` explicitly.
- Galleries: explicit numeric `Height`, positive `TemplateSize`, `TemplatePadding: =0`, exactly one
  AutoLayout row-shell child sized `Width: =Parent.TemplateWidth`, `Height: =Parent.TemplateHeight`.
  Never size a gallery from `Self.TemplateHeight`/`AllItemsCount`.

## Header + Navigation Pattern (instantiate under each screen's own prefix)

Header container `con<P>Header` (vertical AutoLayout, direct child of the root):
- `Fill: =ColorInk`, `LayoutAlignItems: =LayoutAlignItems.Stretch`, `LayoutGap: =4`,
  padding Top 12 / Bottom 12 / Left 16 / Right 16, radii 0, `DropShadow: =DropShadow.None`,
  `FillPortions: =0`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`
- `Height: =If(<root>.Width < 640, 92, 76) + If(CanManageStudents, 48, 0)`
  (12 + title 28 + 4 + identity 20|36 + 12 = 76|92; nav adds 4 gap + 44)
- Children, in this order:
  1. `lbl<P>Title` — ModernText, Text `="AACA Attendance"`, Size 20, Bold, `Color: =ColorWhite`,
     Height 28, `Wrap: =false`, `AlignInContainer: =AlignInContainer.Stretch`, padding 0
  2. `lbl<P>Identity` — ModernText, Size 12, `Color: =ColorInkSoft`,
     `Height: =If(<root>.Width < 640, 36, 20)`, Text (copy exactly):
     `=Coalesce(CurrentUserRow.'Full Name', User().FullName) & " · " & RoleLabel & " · " & If(!StaffReady, "no campus", IsBlank(CurrentStaff.Campus), "All campuses", CurrentStaff.Campus.Name)`
  3. `con<P>Nav` — horizontal AutoLayout, `Visible: =CanManageStudents`, `Height: =44`,
     `FillPortions: =0`, `LayoutGap: =8`, `LayoutAlignItems: =LayoutAlignItems.Center`,
     `AlignInContainer: =AlignInContainer.Stretch`, no fill, radii 0, `DropShadow: =DropShadow.None`.
     Exactly two ModernButtons, in this order, nothing else:
     - `btn<P>NavAttendance` — Text `="Attendance"`, `OnSelect: =Navigate(Screen1)`
     - `btn<P>NavStudents` — Text `="Students"`, `OnSelect: =Navigate(StudentsScreen)`
     Both: `Width: =120`, `Height: =44`, `FillPortions: =0`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`,
     `AlignInContainer: =AlignInContainer.Center`, `Layout: =ButtonLayout.TextOnly`, `Size: =14`.
     Current-screen item: `Appearance: =ButtonAppearance.Primary`, `BasePaletteColor: =ColorTeal`,
     `Color: =ColorWhite`, AccessibleLabel `"<Name> (current screen)"`.
     Other item: `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk`,
     AccessibleLabel `"Go to <Name>"`.
     Width budget: 120 + 8 + 120 = 248 <= 358 (390 - 32 header padding).

## Named State

App.Formulas (existing, unchanged): palette `Color*`, `CurrentUserRow`, `CurrentStaff`, `StaffReady`,
`IsTeacherRole`, `IsOfficeRole`, `IsAdminRole`, `IsReadOnlyRole`, `CanEditRole`, `CanPickCampus`,
`CanPickTeacher`, `RoleLabel`, `AllowFutureDates`, `ZeroGuid`.

App.Formulas (added before builders — see plan index App Changes):
- `CanManageStudents = IsOfficeRole || IsAdminRole` — gates nav buttons and the Students screen
- `StudentCampusLock` — Office user's own campus GUID; `ZeroGuid` = may act on any campus (Admin, or Office with blank campus)
- `StudentDefaultScope` — default campus filter GUID (`ZeroGuid` = all campuses)
- `ActiveService` — the single active `Services` row used for new enrollments

App.OnStart (added before builders): `varStuSelId` (GUID, blank = no selection), `varStuMode` (""),
`varStuSaving` (false), `varStuLoading` (false), `varStuLoadError` (""), `varStuAttAfter` (0),
`varStuFormCampusId` (ZeroGuid), `varStuScopeCampusId` (StudentDefaultScope),
`varStuTeacherFilterId` (ZeroGuid), `varStuReceipt` ({Kind, Title, StudentId}), `colStuReceiptLines` ({Label, Value}, empty).

Screen-owned collections (created by the StudentsScreen engines): `colStuEnr`, `colStuRaw`, `colStuList`,
`colStuHistory`, `colStuYears`, `colStuCampusSrc`, `colStuCampusOpts`, `colStuTeacherSrc`, `colStuTeacherOpts`;
`varStuEditBase` (live Students record for edit prefill). Screen1 state (`varCampus`, `varTeacher`,
`varMonthStart`, `colMonth*`, etc.) is untouched and not read by StudentsScreen.

## Control Naming

`<type><Prefix><Purpose>`: `con` GroupContainer, `lbl` ModernText, `btn` ModernButton / Classic/Button,
`gal` Gallery, `dd` ModernDropdown, `txt` ModernTextInput, `dp` ModernDatePicker, `rdo` ModernRadio,
`chk` ModernCheckbox, `tgl` ModernToggle, `badge` Badge, `spn` ModernSpinner.
Prefixes: Screen1 = `Att`, StudentsScreen = `Stu`. Names are unique app-wide; repeated blocks (header,
nav) are instantiated per screen with that screen's prefix — never copy another screen's names.

## Cross-Screen Contracts

- Navigation is only the header ModernButton pair above (not ModernTabList). Order: Attendance, Students.
- Screen1 keeps `OnVisible: =Select(btnAttLoadEngine)` (reload on return is accepted).
- StudentsScreen `OnVisible` resets `varStuMode` and reloads its caches; it never writes Screen1 variables.
- Screen key is `StudentsScreen` (not `Students`) because `Students` is a Dataverse table name; a screen
  with the same name would shadow the table in every formula.
- Attendance grid semantics are unchanged: it is driven by Enrollment Start/End Date per teacher, so
  closing an enrollment at E-1 and opening one at E moves the student between grids on E.

## YAML Conventions

- Every property value starts with `=`; multi-line or `: `-containing formulas use a `|-` block with `=` on
  the first content line.
- Record literals are quoted or in a `|-` block (e.g. `Default: '={Value: "Active"}'`).
- Option-set values are fully qualified and quoted: `'Status (Students)'.Active`,
  `'IEP Ratio (Enrollments)'.'1:1'`, `'Grade (Students)'.'12+'`, `'End Reason (Enrollments)'.'Ratio Change'`.
- Enum literals: `LayoutDirection.Vertical`, `ButtonAppearance.Primary`, `Appearance.Outline`,
  `'BadgeCanvas.ThemeColor'.Success`, `DatePickerFormat.Short`, `OptionLayout.Horizontal`,
  `TextInputType.Multiline`, `TriggerOutput.Delayed`, `ToggleLabelPosition.After`, `DisplayMode.Edit`.
- Dataverse lookups compare GUID id fields: `Student.Student = q`, `Campus.Campus = x`,
  `ThisRecord.Enrollment = q`. Wrap an outer value in `With({q: ...}, LookUp(Table, ThisRecord.Id = q))`
  so a column never shadows the value. Never key on display names.
- Hidden engine buttons are `Control: Classic/Button`, `Visible: =false`, `AutoDisableOnSelect: =false`,
  invoked with `Select(...)` exactly one level deep (an engine never Selects another engine).
- Text inputs are normalised with `Trim(...)` before validation and writes.
