# Canvas App Shared Plan — AACA Attendance (build 5 edit)

## Aesthetic Direction

"Classroom register": warm paper page, ink-navy header band, teal accent, green/red absence classification. All
colours are App.Formulas named constants — always use the name, never a new RGBA:

- Page `ColorPaper` RGBA(247,245,240,1); panels `ColorWhite`; rules/borders `ColorRule` RGBA(214,209,199,1)
- Text primary `ColorInk` RGBA(27,42,65,1); secondary `ColorMuted` RGBA(92,86,77,1); on-ink text `ColorWhite` / `ColorInkSoft`
- Accent / primary action `ColorTeal` RGBA(0,110,97,1)
- Excused `ColorExcused` RGBA(46,125,50,1) (white text on it); Unexcused `ColorUnexcused` RGBA(183,28,28,1) (white text)
- Status surfaces (ink text on them): `ColorInfoBg` (success/info), `ColorWarnBg` (warning, view-only, dismiss panel),
  `ColorErrorBg` (failed/blocked), `ColorSaving`, `ColorNonSchool`, `ColorNotEnrolled`, `ColorInfoBg` for selected rows

## Visual Contract

- Type roles (ModernText `Size`/`FontWeight`): app title 20 Bold white; panel heading 18–20 Bold ink; row identity 14
  Semibold ink; body 13 Normal ink; field label 12 Semibold muted; caption/meta 12 muted.
- Every ModernText sets all four Padding* (0 unless stated), `AccessibleLabel`, `AlignInContainer`, `LayoutMinWidth: =0`,
  `LayoutMinHeight: =0`; single-line labels `Wrap: =false`; multi-line text `VerticalAlign: =VerticalAlign.Top`.
- Spacing: container gap 8 (field groups 4); panel padding 16; receipt/notice padding 8–12; radius 6 on panels.
- Surfaces: panels `Fill: =ColorWhite`, `BorderColor: =ColorRule`, `BorderThickness: =1`, `DropShadow: =DropShadow.None`.
- Actions (ModernButton, Height 44, `Layout: =ButtonLayout.TextOnly`, `Size: =14`):
  - Primary: `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite` (Appearance default Primary)
  - Excused-coloured primary: `BasePaletteColor: =ColorExcused`; destructive/undo confirm: `BasePaletteColor: =ColorUnexcused`; both `Color: =ColorWhite`
  - Secondary: `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk` (never light text on Secondary)
  - Toggle buttons: `Appearance: =If(active, ButtonAppearance.Primary, ButtonAppearance.Secondary)`, `BasePaletteColor: =ColorTeal`, `Color: =If(active, ColorWhite, ColorInk)`
  - Disabled via `DisplayMode: =DisplayMode.Disabled`.
- No symbol glyphs (◀ ▶ ↻ etc.) in button text.

## Layout Strategy

- Responsive, desktop-first (1366×768), usable at 1024 and 390. Each screen has one scroll root
  (`conAttRoot`, `conAbsRoot`): the sole top-level child, `Width: =Parent.Width`, `Height: =Parent.Height`,
  `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, vertical, `LayoutOverflowY: =LayoutOverflow.Scroll`,
  `LayoutAlignItems: =LayoutAlignItems.Stretch`. Every section and every hidden engine button lives under it.
- Breakpoints read the screen root width directly: phone `conXRoot.Width < 640`, tablet `< 1024`, desktop `>= 1024`.
  Never store breakpoints in variables.
- Direct children of the root: `FillPortions: =0` with explicit `Height`. Height formulas use literal numbers
  (never bare `PaddingTop`/`LayoutGap` names).
- Two-panel bodies (list + detail): horizontal with `FillPortions` 1:1 at `>= 1024`, vertical below; on `< 1024` the
  list hides while a record is selected and the detail shows (existing Needs Review pattern).
- Galleries: exactly one AutoLayout shell child sized `Parent.TemplateWidth - 16` / `Parent.TemplateHeight`; fixed
  numeric `Height`, explicit `TemplateSize`, `TemplatePadding: =0`, `TabIndex: =0`, `Selectable: =false`.
- **HARD LESSON: never move (re-parent) an existing control.** Studio renders moved controls as black boxes. Add
  properties in place or add NEW controls with NEW names.

## Named State (App-owned; see plan index "App Changes / Before builders")

- Role formulas: `IsTeacherRole`, `IsOfficeRole`, `IsAdminRole`, `IsReadOnlyRole`, `StaffReady`, `CurrentStaff`
  (Staff record), `CurrentUserRow` (Users record), `CanPickCampus`, `CanPickTeacher`, `CanManageStudents`,
  `CanClassify` (= Office || Admin), `StudentCampusLock` (office campus GUID or `ZeroGuid`), `ZeroGuid`,
  `AllowFutureDates`, `CurrentSchoolYear`, `FirstSchoolYear`, `MonthOptions`.
- NEW `ParentReportCutover` (Date) — parsed App Settings "ParentReportCutoverDate", fallback Date(2026,1,1).
- Grid edit gate (Screen1 only, written inline in btnAttLoadEngine):
  `varCanEditMonth = IsTeacherRole && !IsBlank(varTeacher) && varTeacher.Staff = CurrentStaff.Staff && IsBlank(varMonthLock) && varLoadError = ""`.
  Role view-only predicate (banner): `!(IsTeacherRole && !IsBlank(varTeacher) && varTeacher.Staff = CurrentStaff.Staff)`.
- Screen1 globals also written by AbsencesScreen (Show on grid): `varCampus` (Campuses record), `varTeacher`
  (Staff record), `varMonthStart` (Date, first of month), `varViewDate` (Date),
  `varLastAction` = `{Kind: Text, Message: Text, StudentId: GUID, DayNum: Number}` (always supply all four fields).
- AbsencesScreen Ready-to-approve state (seeded in OnStart): `varAbsApLoading`, `varAbsApLoaded`, `varAbsApSaving`
  (Boolean); `varAbsApLoadError`, `varAbsApPlanErr`, `varAbsApClass` ("" / "Excused" / "Unexcused") (Text);
  `varAbsApSelId`, `varAbsApPlanFor` (Number, nullable); `varAbsApReasonId` (GUID, nullable);
  `varAbsApDismissOpen` (Boolean); `varAbsApReceipt` = `{Kind, Title, Body: Text, ItemId: Number}`;
  `varAbsApGridLink` = `{StudentId, TeacherId, CampusId: GUID, FirstDay: Date}`;
  `colAbsApPlan` = `{DayDate, EnrId, TermId, CampusId, ServiceId, TeacherId, TeacherName, Outcome, OutcomeText}`;
  `colAbsApLog` = `{DayDate, Outcome, Detail, AttId}`. Every Set/Collect must supply exactly these fields.
- `varAbsView` values: "classify", "nr", "ready".

## Control Naming

Standard abbreviations (`con` container, `lbl` ModernText, `btn` button, `dd` dropdown, `rdo` radio, `txt` text input,
`gal` gallery, `spn` spinner) + screen namespace. Screen1: `Att`. AbsencesScreen existing: `Abs…` (classify view ends
in `V`, Needs Review `AbsNr`); all NEW build-5 controls on AbsencesScreen use `AbsAp` (e.g. `conAbsApView`,
`btnAbsApApprove`). Names are app-unique; never reuse an existing name.

## Cross-Screen Contracts

- Header nav (existing, unchanged): row `con<P>Nav` visible only when `CanManageStudents`; items in order
  Attendance (Screen1), Students (StudentsScreen), Absences (AbsencesScreen), ModernButton Width 110, Height 44;
  current screen = Primary teal/white, others Secondary/ink. Do not add items.
- Screen1 `OnVisible` always re-runs `btnAttLoadEngine`, so any Attendance written on AbsencesScreen appears on the
  grid at the next visit. AbsencesScreen's "Show on grid" sets the Screen1 globals listed above before
  `Navigate(Screen1)`.
- Attendance letters: "P" present (shows "1"), "E"/"U"/"A" absent Excused/Unexcused/not classified (shows "0";
  green / red / uncoloured). 0 rows are never changed on Screen1.

## YAML Conventions

- Every property value starts with `=`; multi-line formulas use `|-` with `=` on the first content line.
- Any value containing `: ` (caption formatting, record literals like `{Value: "x"}`) or ` #` (e.g. `"report #"`)
  MUST be a `|-` block (preferred) or single-quoted. Unquoted ` #` starts a YAML comment and silently truncates.
- Dataverse predicates: use `With()` scalars inside every LookUp/Filter over a data source (never `record.Field`
  inside the predicate); choice columns compare `= Blank()` inside delegated filters, `IsBlank()` only on
  already-fetched records.
- `IfError(A, B)`: both branches same type; table-returning success branches end with `; true`.
- Enum literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `Appearance.Outline`,
  `OptionLayout.Horizontal`, `TextInputType.Multiline`, `FontWeight.Semibold`, `LayoutDirection.Vertical`,
  `LayoutAlignItems.Stretch`, `AlignInContainer.Stretch`, `LayoutOverflow.Scroll`, `DisplayMode.Edit`,
  `VerticalAlign.Top`, `DropShadow.None`.
