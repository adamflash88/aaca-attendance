# Canvas App Shared Plan — AACA Attendance, build 1

Single-screen app (Screen1 = Attendance). This file holds the values a builder must copy
exactly; the screen brief holds the screen structure and formulas.

## Aesthetic Direction

"Classroom register" — calm, dense, paper-like grid for all-day use. Ink-navy header band,
paper page, white cards with thin rule borders, teal for primary actions, status colours
always paired with a letter.

All colours are App.Formulas named formulas (already in `App.pa.yaml`). Reference the
name, never retype the RGBA:

| Name | RGBA | Use |
| ---- | ---- | --- |
| `ColorPaper` | 247,245,240,1 | Screen `Fill`, root `Fill` |
| `ColorInk` | 27,42,65,1 | Header band fill; all primary text on light surfaces |
| `ColorInkSoft` | 206,216,230,1 | Secondary text on the ink header only |
| `ColorWhite` | 255,255,255,1 | Card/section surfaces; text on ink and on status fills |
| `ColorTeal` | 0,110,97,1 | Primary action `BasePaletteColor`; focus/last-action cell border; "today" day number |
| `ColorRule` | 214,209,199,1 | Card borders, grid cell borders |
| `ColorMuted` | 92,86,77,1 | Captions, legend, "–" on not-enrolled cells |
| `ColorPresent` | 46,125,50,1 | P cells; Present button |
| `ColorAbsent` | 178,106,0,1 | A cells; Absent button |
| `ColorExcused` | 21,101,192,1 | E cells |
| `ColorUnexcused` | 183,28,28,1 | U cells; failed "!" text; destructive Confirm clear |
| `ColorNonSchool` | 222,219,212,1 | Non-school day cells and day-header shells |
| `ColorNotEnrolled` | 238,236,231,1 | Not-enrolled cells |
| `ColorSaving` | 230,242,240,1 | Cell fill while saving |
| `ColorInfoBg` | 224,240,237,1 | Receipt strip (Saved/Cleared/Restored/Bulk/Notes/Cancelled) |
| `ColorWarnBg` | 252,240,220,1 | Notice banner (lock / read-only); receipt strip for Conflict |
| `ColorErrorBg` | 250,228,228,1 | Notice banner for load error; receipt strip for Failed/Blocked; clear-confirm panel |

Contrast: white letters on Present/Excused/Unexcused fills are >= 5:1. White on
`ColorAbsent` is ~4.2:1, so status letters are always `Size: =14` + `FontWeight.Bold`
(large-text threshold 3:1). Every text control on a coloured surface sets its colour
explicitly (`Color` on ModernText/ModernButton/Classic Button).

## Visual Contract

- Type roles (ModernText `Size` / weight): app title 20 Bold (white, header); month label
  16 Bold; section heading 16 Semibold; body 14 Normal; caption/legend 12 Normal
  (`ColorMuted`); grid student name 12 Normal; day header weekday 9, day number 12 Bold;
  grid cell letters (Classic/Button) 14 Bold; totals 12 Semibold.
- Spacing scale: 4, 8, 12, 16. Section side padding 16. Root `LayoutGap` 8.
- Surfaces: page `ColorPaper`; sections are white cards (`Fill: =ColorWhite`,
  `BorderColor: =ColorRule`, `BorderThickness: =1`, all four radii 6,
  `DropShadow: =DropShadow.None`). Header band: `Fill: =ColorInk`, radii 0. Banners use the
  tinted backgrounds above with `BorderThickness: =1` and `BorderColor: =ColorRule`.
- Actions (ModernButton): primary = `Appearance: =ButtonAppearance.Primary`,
  `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite`. Secondary =
  `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk` (never a light colour on a
  Secondary surface). Destructive = Primary with `BasePaletteColor: =ColorUnexcused`,
  `Color: =ColorWhite`. Disabled = `DisplayMode.Disabled` (platform styling). Minimum
  touch target 44x44 for ModernButtons.
- Density: desktop shows the whole month without horizontal scroll at >= 1280 px; tablet
  scrolls the grid horizontally; phone defaults to Day view with 44 px buttons.

## Layout Strategy

- Target: Responsive, desktop-first (1366x768), usable at 1024 and 390.
- One screen-level width source for every breakpoint: `conAttRoot.Width` (the sole root).
  Breakpoints: `< 640` phone, `< 1024` tablet, `>= 1240` wide toolbar row.
- Narrowest supported rendered width: 390 px → section inner width 390 − 32 = 358 px.
- Responsive properties derive from the current width in the property formula. No layout
  variables (`varIsMobile`, `varColumns`) and nothing layout-related in `OnVisible`.
- Every horizontal group is budgeted to fit 358 px, so the layout stays safe if a
  scale-to-fit host keeps the logical wide branch.
- AutoLayout everywhere. The only ManualLayout-style positioning is inside Gallery
  templates whose single child is either an AutoLayout shell or one full-template control.
- Root scrolls vertically (`LayoutOverflowY: =LayoutOverflow.Scroll`); every direct root
  child uses `FillPortions: =0` and an explicit `Height`.
- The month grid is one horizontally scrolling region (`LayoutOverflowX: =LayoutOverflow.Scroll`)
  containing the day header, student rows and totals footer so columns stay aligned.
- Every GroupContainer sets `LayoutMinWidth: =0` and `LayoutMinHeight: =0`. Every
  AutoLayout child sets `AlignInContainer` and `FillPortions` explicitly and overrides the
  control's default `LayoutMinWidth`/`LayoutMinHeight` (ModernText 150/32, ModernButton
  96/32, Classic/Button 160/40, ModernDropdown 320/32, ModernTabList 300/60, Gallery
  320/287, ModernSpinner 48/48) with the value the brief gives (usually `=0`).

## Named State

App.Formulas (defined in `App.pa.yaml`; read-only):
`CurrentUserRow`, `CurrentStaff`, `StaffReady`, `IsTeacherRole`, `IsOfficeRole`,
`IsAdminRole`, `IsReadOnlyRole`, `CanEditRole`, `CanPickCampus`, `CanPickTeacher`,
`RoleLabel`, `AllowFutureDates`, `ZeroGuid`, and the `Color*` palette.

Global variables (initialised in `App.OnStart`; the schema of each record variable is
fixed — every `Set` must supply exactly these fields):

| Variable | Type / shape | Owner |
| -------- | ------------ | ----- |
| `varMonthStart`, `varMonthEnd` | Date (first / last day of selected month) | month nav, load engine |
| `varViewDate` | Date (Day view date, always inside the loaded month) | Day view nav, load engine |
| `varCampus` | Campuses record | campus picker |
| `varTeacher` | Staff record | teacher picker |
| `varMonthLock` | Month Locks record or blank | load engine |
| `varCanEditMonth` | Boolean = `CanEditRole && IsBlank(varMonthLock) && varLoadError = ""` | load engine |
| `varLoading` | Boolean | load engine |
| `varLoadError` | Text | load engine |
| `varDetailsMode` | Boolean | Details mode toggle |
| `varDetailOpen`, `varConfirmOpen` | Boolean | detail panel / clear confirm |
| `varBulkDay` | Number (day of month) | All present buttons → bulk engine |
| `varSaveReq` | `{StudentId: GUID, DayNum: Number, Target: Text}` Target ∈ "P","A","clear" | cell, Day view, confirm → save engine |
| `varClearKey`, `varDetailKey` | `{StudentId: GUID, DayNum: Number}` | cell taps |
| `varLastAction` | `{Kind: Text, Message: Text, StudentId: GUID, DayNum: Number}` | every mutation; receipt strip |

Collections (all built by Screen1 engines except the two typed in `App.OnStart`):

| Collection | Row shape | Built by |
| ---------- | --------- | -------- |
| `colMonthEnr` | EnrId, StudentId, StudentName, StudentNumber, ServiceId, ServiceCode, StartDate, EndDate, IsSummer, IepText, EnrRec (Enrollments record) | load engine |
| `colMonthAtt` | AttId, StudentId, DayNum, AttDate, Present, IsDeleted, Letter, ClassText, IepText, Notes, RecordKey, ModifiedOn | load engine; replaced per row by every successful write/conflict refresh |
| `colMonthExceptions` | Calendar Exceptions records in month | load engine |
| `colMonthTerms` | Terms records overlapping month | load engine |
| `colMonthDays` | DayNum, CellDate, DowLabel, TermId, TermKind, IsSchoolDay, NonSchoolReason | load engine |
| `colMonthStudents` | StudentId, StudentName, StudentNumber | load engine |
| `colMonthCells` | StudentId, StudentName, DayNum, CellDate, EnrId, State ("Open","NonSchool","NotEnrolled","Future"), Reason | load engine |
| `colCellState` | StudentId, DayNum, SaveState ("saving","saved","failed"), Target | typed in OnStart; save/bulk engines |
| `colBulkLog` | StudentId, Outcome ("marked","skipped","failed") | typed in OnStart; bulk engine |

Single source of truth: `colMonthAtt` (a projection of Dataverse `Attendance`) is the only
render source for cell letters, totals, Day view status and the detail panel. It is changed
only from a Dataverse `Patch` result or a fresh server `LookUp`, never from input values.

## Control Naming

Standard abbreviations + the screen namespace `Att`: `conAtt…` (GroupContainer), `lblAtt…`
(ModernText), `btnAtt…` (ModernButton or Classic/Button), `galAtt…` (Gallery), `ddAtt…`
(ModernDropdown), `tabAtt…` (ModernTabList), `txtAtt…` (ModernTextInput), `spnAtt…`
(ModernSpinner). Only one screen exists, so no repeated cross-screen blocks.

## Cross-Screen Contracts

None. One screen; no navigation; `App.StartScreen = Screen1`; never `Navigate` from
`OnStart` or `OnVisible`.

## YAML Conventions

- Every property value starts with `=`. Multi-line formulas use `|-` with `=` on the first
  content line.
- Any value containing `: ` (caption concatenation, record literal) must be a `|-` block or
  wrapped in single quotes. Prefer `|-` blocks for every formula that contains a record
  literal, a `: `, or an apostrophe.
- Enum literals are written exactly as listed in the brief, e.g. `=ButtonAppearance.Primary`,
  `=LayoutOverflow.Scroll`, `=TabListAppearance.Subtle`.
- Dataverse option-set literals are quoted: `'App Role (Staff)'.'Read-only'`,
  `'IEP Ratio (Attendance)'.'1:1'`, `'Action (Audit Events)'.'Soft Delete'`.
- Never write `LayoutGap`/`Padding*` as bare names inside formulas; use the literal numbers.
- Gallery templates: exactly one direct child; `Parent.TemplateWidth`/`TemplateHeight` only
  on that child.
