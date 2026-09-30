# Canvas App Shared Plan (build 4 edit)

## Aesthetic Direction

"Classroom register" is already established. Keep it. Use the App.Formulas color names only; never write new RGBA
literals.

- Page: `ColorPaper`. Panels: `ColorWhite` with a 1px `ColorRule` border and radius 6
- Header band: `ColorInk` with `ColorWhite` title and `ColorInkSoft` identity text
- Accent / primary action: `ColorTeal`
- Text primary: `ColorInk`. Text secondary / field labels: `ColorMuted`
- Status: `ColorExcused` (ok / ready), `ColorUnexcused` (error / blocked text)
- Receipt fills: `ColorInfoBg` (success), `ColorErrorBg` (Failed / Blocked), `ColorWarnBg` (Cancelled)

## Visual Contract

- Type roles (ModernText `Size` / `FontWeight`): panel title 20 Bold; section title 18 Bold; body 13 Normal;
  row name 14 Semibold; field label 12 Semibold `ColorMuted` with `Wrap: =false`; meta/caption 12 Normal
- Spacing: panel padding 16; container gaps 8; field-group gaps 4; receipt padding 8/12
- Surfaces: `DropShadow: =DropShadow.None` on every GroupContainer. Panels radius 6; structural wrappers radius 0
- Actions (ModernButton, Height 44, `Layout: =ButtonLayout.TextOnly`, `Size: =14`):
  - Primary: default Primary appearance, `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite`
  - Secondary: `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk`
  - Disabled: through `DisplayMode.Disabled` only
- Every ModernText sets all four `Padding*` to 0, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, and an
  explicit `Height`
- Every GroupContainer sets `LayoutMinWidth: =0` and `LayoutMinHeight: =0`

## Layout Strategy

- Responsive, desktop-first (1366×768), usable on tablet (1024) and phone (390)
- Breakpoints read the screen root width directly: `conAbsRoot.Width` on Absences, `conStuRoot.Width` on
  Students. `< 640` = phone; `< 1024` = stacked panels; `>= 1024` = side-by-side panels
- Never store breakpoints in variables
- Each screen keeps its existing sole top-level scroll root (`Width: =Parent.Width`,
  `Height: =Parent.Height`, `LayoutOverflowY: =LayoutOverflow.Scroll`). Every new section nests under it as
  a `FillPortions: =0` child with an explicit `Height`
- Galleries: exactly one AutoLayout shell child (`Width: =Parent.TemplateWidth - 16`,
  `Height: =Parent.TemplateHeight`); a fixed numeric `Height`; explicit `TemplateSize` and
  `TemplatePadding: =0`; `Selectable: =false`; row actions are ModernButtons
- Container heights are literal sums of child heights + gaps + padding, as in the existing screens

## Named State

Existing App.Formulas used by this build: `CanClassify`, `CanManageStudents`, `StudentCampusLock`, `ZeroGuid`,
`CurrentUserRow`, `ActiveService`, palette names.

New app variables (initialised in App.OnStart; see the plan index App Changes):

| Name | Type / seed | Owner | Meaning |
| ---- | ----------- | ----- | ------- |
| varAbsView | Text "classify" | Absences | Current view: "classify" or "nr" |
| varAbsNrLoading / varAbsNrSaving | Boolean false | Absences | Parent-report load / resolve in progress |
| varAbsNrLoaded | Boolean false | Absences | The queue has been loaded at least once (the toggle shows N) |
| varAbsNrLoadError | Text "" | Absences | Last load error message |
| varAbsNrErr | Text "" | Absences | Last Resolve Patch error message |
| varAbsNrSelId | Number, Blank | Absences | Selected SharePoint item ID (stable identity) |
| varAbsNrCalFor | Number, Blank | Absences | Item ID the calendar collections were loaded for |
| varAbsNrPickId | GUID, Blank | Absences | Picked Students.Student |
| varAbsNrAllCampuses | Boolean false | Absences | Search all campuses |
| varAbsNrReceipt | {Kind, Title, Body, ItemId} | Absences | Resolve receipt ("" / "Resolved" / "Blocked" / "Failed") |

Screen-owned collections (created by Absences formulas): `colAbsNr`, `colAbsNrCampuses`, `colAbsNrStuRaw`,
`colAbsNrEnr`, `colAbsNrStudents`, `colAbsNrTerms`, `colAbsNrExc`. Students keeps `colStuList` (includes
`ExternalId`).

## Control Naming

Type abbreviation + screen prefix + purpose: `con` GroupContainer, `lbl` ModernText, `btn` ModernButton /
Classic/Button, `gal` Gallery, `cbo` ModernCombobox, `chk` ModernCheckbox, `spn` ModernSpinner, `txt`
ModernTextInput. Absences uses prefix `Abs`, and the new parent-report controls use `AbsNr` (e.g.
`galAbsNrList`). Students uses `Stu`. Names must be unique app-wide. Never reuse an existing name.

## Cross-Screen Contracts

- The 3-button header nav (Attendance · Students · Absences) is unchanged on both screens. Do not add a nav item
  for parent reports. The parent-report view is an in-screen toggle on Absences
- Student Key = Dataverse `Students.'External Client ID'` = SharePoint `Student_ID` (identical values). A key
  created on Students appears in the Absences picker after the next parent-report load (OnVisible / Reload)

## YAML Conventions

- Every property value starts with `=`. Multi-line formulas use `|-` with `=` on the first content line
- Any value containing `: ` (captions such as `"Student_ID: "`) or a record literal (`{Value: ...}`) must be
  a `|-` block or single-quoted
- Enum names are copied from the control definitions: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`,
  `Appearance.Outline`, `'BadgeCanvas.Appearance'.Tint`, `DisplayMode.View`, `DropShadow.None`
- SharePoint and Dataverse predicates never reference record fields directly. Bind scalars with `With()` first
  (`With({qid: varAbsNrSelId}, LookUp('Student Absence Log', ID = qid))`)
- Do not change formulas of existing controls unless the brief lists the exact change
