# Canvas App Shared Plan - AACA Billing build 7 (RDS grid)

This build keeps every convention of the build-6 shared plan
(`C:\src\aaca-attendance\docs\app-builds\build-6-billing-foundations\canvas-app-shared.md`). The rules a build-7
builder needs are restated here so this file plus the screen brief is sufficient. Builders never edit App.pa.yaml or
`_EditorState.pa.yaml`; the orchestrator applies the App changes listed in the plan index before builders run.

## Aesthetic Direction

"Classroom register" applied to a finance ledger: warm paper page, ink-navy header band, teal accent, white bordered
panels. The RDS grid is a printable document: white panel, 1px `ColorRule` lines, no shadows, no decoration.
All colours are App.Formulas named constants; never write a new RGBA:

- Page `ColorPaper`; panels `ColorWhite`; borders/rules `ColorRule`
- Text primary `ColorInk`; secondary/caption `ColorMuted`; on the ink header `ColorWhite` / `ColorInkSoft`
- Accent / primary action `ColorTeal` (white text on it)
- Warning text on white: `ColorWarnInk` Semibold; error text: `ColorUnexcused`
- Grid states (cells and legend chips): present/plain `ColorWhite` + ink; excused `ColorExcused` + white text;
  unexcused `ColorUnexcused` + white text; non-school day `ColorNonSchool` + ink; review flag `ColorFlag` (NEW,
  RGBA(240,173,78,1) amber) + ink; outside the row's dates `ColorNotEnrolled` + ink

## Visual Contract

- Type roles (ModernText `Size` / `FontWeight`): app title 20 Bold `ColorWhite`; document title 20 Bold ink; panel
  heading 18 Bold; student line 16 Semibold; body 13 Normal; field caption 12 Semibold `ColorMuted`; caption/meta 12
  `ColorMuted`; grid text 11 (day letters 9, total sub-line 10).
- Every ModernText sets all four `Padding*` (0 unless stated), `AccessibleLabel`, `AlignInContainer` (when its parent is
  AutoLayout), `FillPortions`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, explicit `Height` (or FillPortions 1 in a
  horizontal row); single-line labels `Wrap: =false`; multi-line text `VerticalAlign: =VerticalAlign.Top`.
- Spacing: container gap 8 (field groups 4, footer 6, grid 0); panel padding 16; radius 6 on panels, 0 on the document
  panel, root, header and grid.
- Every GroupContainer: `DropShadow: =DropShadow.None`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`.
- Actions: ModernButton `Height: =44`, `Layout: =ButtonLayout.TextOnly`, `Size: =14`, explicit `Width`.
  Primary: `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite` (Appearance omitted). Secondary:
  `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk`. Disabled only via `DisplayMode.Disabled`.
- No symbol glyphs in button text (no arrows); "Previous" / "Next". En dash and middle dot are allowed in ModernText and
  dropdown display text only.

## Layout Strategy

- Desktop-first 1366x768, must work at 1024; nothing may clip narrower. Exactly one top-level child per screen: the
  root `con<P>Root` (AutoLayout Vertical, `Width: =Parent.Width`, `Height: =Parent.Height`, `LayoutMinWidth: =0`,
  `LayoutMinHeight: =0`, `LayoutOverflowY: =LayoutOverflow.Scroll`, `LayoutAlignItems: =LayoutAlignItems.Stretch`,
  `LayoutGap: =12`, `PaddingLeft/Right: =16`, `PaddingBottom: =16`, `PaddingTop: =0`, `Fill: =ColorPaper`).
- Direct root children: `FillPortions: =0` and an explicit numeric Height built from literals and state. Width-based
  formulas read the root width directly (`con<P>Root.Width`); never store breakpoints in variables. Every horizontal row
  either wraps (`LayoutWrap: =true`) or fits a static budget.
- Galleries: explicit numeric Height, explicit TemplateSize, `TemplatePadding: =0`, `Selectable: =false`,
  `LayoutMinWidth: =0`, `LayoutMinHeight: =0` (Gallery defaults are 320 / 287). A gallery with one full-template control
  needs no shell; otherwise exactly one AutoLayout shell child sized `Parent.TemplateWidth` / `Parent.TemplateHeight`.
- HARD LESSON: never re-parent, move or rename an existing control (Studio renders it as a black box). Add new controls
  only, in place.

## Named State

App.Formulas (existing): `IsFinance`, `StaffReady`, `UserLabel`, `ZeroGuid`, `FarFuture` (Date 2999-12-31), palette
incl. new `ColorFlag`.

New globals (seeded in App.OnStart by the orchestrator; Set exactly these types):

| Variable | Type / values | Owner |
| --- | --- | --- |
| `varRdsLoading`, `varRdsPageCapped` | Boolean | RdsScreen |
| `varRdsLoadError`, `varRdsCampusText` | Text | RdsScreen |
| `varRdsMonth` | Date, first of month; Blank until first visit sets the default | RdsScreen |
| `varRdsMonthEnd` | Date, last day of `varRdsMonth` (set by the month engine) | RdsScreen |
| `varRdsFunderId`, `varRdsStudentId` | GUID, nullable (Blank = none); persist across navigation | RdsScreen |

Shared collections reloaded by RdsScreen with the build-6 VERBATIM ClearCollect text (copied in the RdsScreen brief):
`colFunders`, `colServices`, `colStudents`, `colDor`, `colStuSvc`. Screen-owned collections are all prefixed `colRds`
(schemas in the RdsScreen brief).

## Control Naming

`con` container, `lbl` ModernText, `btn` ModernButton or hidden Classic/Button engine, `dd` ModernDropdown, `gal`
Gallery. Namespaces: Home `Home`, Funders `Fun`, Services `Svc`, Students `Stu`, RDS grid `Rds`. Names are app-unique;
repeated blocks are instantiated under each screen's own prefix.

## Cross-Screen Contracts

### Header band + navigation (identical values on all five screens)

`con<P>Header`: Vertical, `Fill: =ColorInk`, `FillPortions: =0`,
`Height: =If(con<P>Root.Width < 640, 92, 76) + If(IsFinance, 48, 0)`, `LayoutGap: =4`, padding 12/16/12/16, Stretch,
radius 0. Children: `lbl<P>Title` ("AACA Billing", 20 Bold white, Height 28, Wrap false), `lbl<P>Identity`
(`=UserLabel & " · " & If(IsFinance, "Finance access", "No finance access")`, 12 `ColorInkSoft`,
`Height: =If(con<P>Root.Width < 640, 36, 20)`, Top), `con<P>Nav` (Horizontal, Height 44, `FillPortions: =0`, gap 8,
`LayoutAlignItems: =LayoutAlignItems.Center`, `Visible: =IsFinance`).

`con<P>Nav` holds exactly FIVE ModernButtons in this order (supersedes build-6 "exactly four"): Home, Funders,
Services, Students, RDS Grid. Each: `Width: =110`, `Height: =44`, `AlignInContainer: =AlignInContainer.Center`,
`Layout: =ButtonLayout.TextOnly`, `Size: =14`.

| Button | Text | OnSelect |
| --- | --- | --- |
| `btn<P>NavHome` | "Home" | `=Navigate(HomeScreen)` |
| `btn<P>NavFunders` | "Funders" | `=Navigate(FundersScreen)` |
| `btn<P>NavServices` | "Services" | `=Navigate(ServicesScreen)` |
| `btn<P>NavStudents` | "Students" | `=Navigate(StudentsScreen)` |
| `btn<P>NavRds` | "RDS Grid" | `=Navigate(RdsScreen)` |

Current screen's button: `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite`, no Appearance, AccessibleLabel
"<Text> (current screen)". Others: `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk`, AccessibleLabel
"Go to <Text>" (RDS: "Go to RDS Grid"). Budget 5 x 110 + 4 x 8 = 582 <= 608 (640 - 32).

### Access gate (identical)

`con<P>Gate` right after the header: `Visible: =!IsFinance`, white panel (border `ColorRule` 1, radius 6, padding 16,
gap 8, Vertical, Stretch), `FillPortions: =0`, `Height: =16 + 24 + 8 + 40 + 16`; `lbl<P>GateTitle`
"You don't have access to AACA Billing" (16 Semibold ink, Height 24, Wrap false); `lbl<P>GateBody`
`=If(!StaffReady, "Your sign-in is not linked to an active Staff record. Ask Adam Bernstein to set up Finance Access.", "AACA Billing is limited to the finance team. Ask Adam Bernstein if you need Finance Access.")`
(13 ink, Height 40, Top). Every data surface's Visible includes `IsFinance`; engines clear collections when `!IsFinance`.

### Hidden engines

`btn<P>...Engine`: `Control: Classic/Button`, `Visible: =false`, `AutoDisableOnSelect: =false`, `Text: ="load"`,
`AlignInContainer: =AlignInContainer.Stretch`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, `FillPortions: =0`,
`Height: =0`, last children of the root. `IfError` success branches end with `; true`, fallbacks with `; false`.

### Navigation state

RDS selections (`varRdsMonth`, `varRdsFunderId`, `varRdsStudentId`) persist across navigation; RdsScreen OnVisible
reloads data and keeps them when still valid. No other screen reads or writes `varRds*`.

## Grid Conventions (RdsScreen)

- Column geometry: label column 220, total column FillPortions 1 (>= 110), day width
  `RoundDown((conRdsGridInner.Width - 330) / Max(1, CountRows(colRdsDays)), 0)`; inner width
  `Max(Parent.Width, 330 + 30 * CountRows(colRdsDays))` so 31 days fit at 1366 and scroll horizontally below.
- Cells are read-only ModernText (no OnSelect, no buttons in the document). Row template 44, header 40.
- Every cell value, fill and total is derived from `colRdsCells` (built once by the grid engine). Totals and the footer
  sum `colRdsCells.CellNum` so the grid and the totals cannot disagree.
- School-day rule (same as attendance app): a day is a school day for campus c when a term for c (or all campuses)
  covers it AND (a Make-up School Day exception for c/all exists OR (it is Mon-Fri AND no other exception for c/all
  exists)). No campus (RC-only, or no enrollment in the month): school day = Mon-Fri.

## YAML Conventions

- Every property value starts with `=`; multi-line formulas use `|-` with `=` on the first content line.
- Any value containing `: ` (captions such as "Funder: ", record literals `{A: 1}`) or ` #` (e.g. `" #" & n`) MUST be a
  `|-` block. An unquoted ` #` starts a YAML comment and silently truncates the formula.
- Dataverse predicates compare against With() scalars; choice columns compare `= Blank()` when filtering for blank
  (never `IsBlank(choice)` server-side). Yes/No columns are Booleans (`a.Present = true`).
- Choice literals used: `'Absence Classification (Attendance)'.Excused`, `'Absence Classification (Attendance)'.Unexcused`,
  `'Status (Upload Exceptions)'.Open`, `'Status (CodeMetro Uploads)'.Complete`; status column display name
  `'Status (aaca_status)'`.
- Enum literals used: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `Appearance.Outline`, `FontWeight.Bold`,
  `FontWeight.Semibold`, `FontWeight.Normal`, `LayoutDirection.Vertical`, `LayoutDirection.Horizontal`,
  `LayoutAlignItems.Stretch`, `LayoutAlignItems.Center`, `LayoutAlignItems.Start`, `AlignInContainer.Stretch`,
  `AlignInContainer.Center`, `AlignInContainer.Start`, `LayoutOverflow.Scroll`, `DisplayMode.Edit`,
  `DisplayMode.Disabled`, `VerticalAlign.Top`, `VerticalAlign.Middle`, `VerticalAlign.Bottom`, `Align.Center`,
  `Align.Left`, `Align.Right`, `DropShadow.None`, `SortOrder.Ascending`, `SortOrder.Descending`, `TimeUnit.Days`,
  `TimeUnit.Months`, `StartOfWeek.Monday`.
- Never re-parent an existing control; never use symbol glyphs in button text.
- Before returning, run the plugin QA checks 1-44 on the written file.
