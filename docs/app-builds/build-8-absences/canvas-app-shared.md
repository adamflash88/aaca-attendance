# Canvas App Shared Plan - AACA Attendance (build 8 edit)

Only AbsencesScreen is modified in this build. This file holds the conventions that brief relies on.

## Aesthetic Direction

"Classroom register": warm paper page, ink-navy header band, teal accent, green/red absence classification. All
colours are App.Formulas named constants - always use the name, never a new RGBA:

- Page `ColorPaper`; panels `ColorWhite`; rules/borders `ColorRule`
- Text primary `ColorInk`; secondary `ColorMuted`; on-ink text `ColorWhite` / `ColorInkSoft`
- Accent / primary action `ColorTeal`
- Excused `ColorExcused` (white text on it); Unexcused / destructive `ColorUnexcused` (white text)
- Status surfaces (always `ColorInk` text on them): `ColorInfoBg` (success/info, selected rows), `ColorWarnBg`
  (warning, Needs a decision panel), `ColorErrorBg` (failed/blocked), `ColorNonSchool` (locked rows)

## Visual Contract

- Type roles (ModernText `Size`/`FontWeight`): panel heading 18-20 Bold ink; section heading 16 Semibold ink; row
  identity 14 Semibold ink; body 13 Normal ink; field label 12 Semibold muted; caption/meta 12 ink or muted.
- Every ModernText sets all four Padding* (0), `AccessibleLabel`, `AlignInContainer`, `LayoutMinWidth: =0`,
  `LayoutMinHeight: =0`; single-line labels `Wrap: =false`; multi-line text `VerticalAlign: =VerticalAlign.Top`.
- Spacing: container gap 8 (field groups 4); panel padding 16; receipt/notice padding 8 top/bottom, 12 sides;
  Needs a decision panel padding 12; radius 6 on panels.
- Panels: `Fill: =ColorWhite`, `BorderColor: =ColorRule`, `BorderThickness: =1`, `DropShadow: =DropShadow.None`, radius 6.
- Actions (ModernButton, `Height: =44`, `Layout: =ButtonLayout.TextOnly`, `Size: =14`, `LayoutMinHeight: =0`,
  `LayoutMinWidth: =0`):
  - Primary: `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite` (Appearance default Primary)
  - Destructive (Remove ticked, Confirm dismiss): `BasePaletteColor: =ColorUnexcused`, `Color: =ColorWhite`
  - Secondary: `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk` (never light text on Secondary)
  - Toggles / mode buttons: `Appearance: =If(active, ButtonAppearance.Primary, ButtonAppearance.Secondary)`,
    `BasePaletteColor: =ColorTeal`, `Color: =If(active, ColorWhite, ColorInk)`
  - Disabled via `DisplayMode: =DisplayMode.Disabled`.
- No symbol glyphs (arrows, triangles, refresh marks) in any text. Use plain "->" in receipt text if needed.

## Layout Strategy

- Responsive, desktop-first (1366x768), usable at 1024 and 390. One scroll root `conAbsRoot`: the sole top-level child,
  `Width: =Parent.Width`, `Height: =Parent.Height`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, vertical,
  `LayoutOverflowY: =LayoutOverflow.Scroll`, `LayoutAlignItems: =LayoutAlignItems.Stretch`. Every section and every
  hidden engine button lives under it.
- Breakpoints read `conAbsRoot.Width` directly: phone `< 640`, tablet `< 1024`, desktop `>= 1024`. Never store
  breakpoints in variables.
- Direct children of the root and of view containers: `FillPortions: =0` with explicit `Height`. Height formulas use
  literal numbers (never bare `PaddingTop`/`LayoutGap` names).
- Two-panel bodies (list + detail): horizontal at `>= 1024` (list/detail FillPortions), vertical below; on `< 1024` the
  list hides while a record is selected and the detail shows (existing pattern).
- Galleries: exactly one AutoLayout shell child sized `Parent.TemplateWidth - 16` / `Parent.TemplateHeight`; numeric
  `Height`, explicit `TemplateSize`, `TemplatePadding: =0`, `TabIndex: =0`, `Selectable: =false`.
- **HARD LESSON: never move (re-parent) or rename an existing control.** Studio renders moved controls as black boxes.
  Edit properties in place, delete removed controls, and add NEW controls with NEW names. Inserting a new sibling
  into an existing container is allowed.

## Named State

- App formulas (unchanged): `CanClassify` (= Office || Admin), `StudentCampusLock` (office campus GUID or `ZeroGuid`),
  `CurrentUserRow`, `CurrentStaff`, `ZeroGuid`, `ParentReportCutover` (Date), `FirstSchoolYear`.
- Existing classify state (unchanged types): `varAbsView` (now "classify" | "errors"), `varAbsCampusId`,
  `varAbsTeacherId`, `varAbsStatus`, `varAbsFrom`, `varAbsTo`, `varAbsLoading`, `varAbsSaving`, `varAbsLoadError`,
  `varAbsSelId`, `varAbsReasonId`, `varAbsBulkReasonId`, `varAbsReq`;
  `varAbsReceipt` = `{Kind: Text, Title: Text}` (always both fields); `colAbsReceiptLines` = `{Label, Value}`;
  `colAbsTicked` / `colAbsWork` = `{AttId}`; `colAbsLog` = `{AttId, StudentName, AbsDate, TeacherName, CampusName,
  OldClass, NewClass, ReasonName, ByName, OnText, Outcome, AuditOk}` (every Collect supplies all 12 fields).
- Build-8 Mapping Errors state (seeded in App.OnStart, see plan index): `varAbsMeLoading`, `varAbsMeLoaded`,
  `varAbsMeSaving` (Boolean); `varAbsMeLoadError`, `varAbsMeErr`, `varAbsMeMode` ("" | "map" | "dates" | "dismiss")
  (Text); `varAbsMeCampusId` (GUID, ZeroGuid = all campuses); `varAbsMeSelId` (Number, nullable SP item ID);
  `varAbsMeReceipt` = `{Kind: Text, Title: Text, Body: Text}` (always all three fields).
- Screen-built collections (defined by the engines in the brief): `colAbsList` (+ `SrcText`, `ParentReason`,
  `NoticeOn`), `colAbsCf`, `colAbsCfRpt`, `colAbsMe`, `colAbsMeSrc`, `colAbsMeErrDec`, `colAbsMeDecIds`,
  `colAbsMeStuRaw`, `colAbsMeEnr`, `colAbsMeStudents`, `colAbsMeCampusOpts`.
- Removed in this build (must not be referenced anywhere afterwards): every `varAbsNr*`, `varAbsAp*`, `colAbsNr*`,
  `colAbsAp*`.

## Control Naming

Standard abbreviations (`con` container, `lbl` ModernText, `btn` button, `dd` dropdown, `cbo` combobox, `txt` text
input, `gal` gallery, `spn` spinner) + screen namespace `Abs`. Existing classify controls end in `V`. NEW build-8
controls: Needs a decision `AbsCf…`, Remove absence `AbsRm…`, Mapping Errors `AbsMe…`, plus the row label
`lblAbsRowSrcV`. Names are app-unique; never reuse a deleted name (`…AbsNr…`, `…AbsAp…`).

## Cross-Screen Contracts

- Header nav (existing, unchanged): `conAbsNav` visible only when `CanManageStudents`; Attendance, Students, Absences.
- Screen1 `OnVisible` re-runs its load engine, so Attendance changes made here (soft delete, Mark absent) appear on the
  grid at the next visit. No Screen1 globals are written by this screen any more (Show on grid is removed).

## YAML Conventions

- Every property value starts with `=`; multi-line formulas use `|-` with `=` on the first content line.
- Any value containing `: ` (caption text, record literals like `{Value: "x"}`) or ` #` (e.g. `"report #"`) MUST be a
  `|-` block. Unquoted ` #` starts a YAML comment and silently truncates the formula.
- Dataverse/SharePoint predicates: use `With()` scalars inside every LookUp/Filter over a data source (never
  `record.Field` inside the predicate); choice columns compare `= Blank()` in delegated filters.
- `IfError(A, B)`: both branches same type; table-returning success branches end with `; true`;
  `IfError(Patch(...), Set(varX, FirstError.Message); Blank())` is the verified record pattern.
- Yes/No columns are Booleans (`'Parent Reported Absent' = true`, `{'Is Deleted': true}`).
- Choice literals: `'Source (Attendance)'.Office`, `'Source (Attendance)'.'Parent report'`, `'Source (Attendance)'.Teacher`,
  `'Processing Status (Report Decisions)'.Error`, `'Processing Status (Report Decisions)'.Processed`,
  `'Decision (Report Decisions)'.Dismissed`, `'Action (Audit Events)'.'Soft Delete'`, `'Action (Audit Events)'.Update`,
  `'Action (Audit Events)'.Create`.
- Enum literals: `ButtonAppearance.Secondary`, `ButtonAppearance.Primary`, `ButtonLayout.TextOnly`,
  `Appearance.Outline`, `TextInputType.Multiline`, `TextInputType.SingleLine`, `FontWeight.Semibold`,
  `FontWeight.Bold`, `LayoutDirection.Vertical`, `LayoutDirection.Horizontal`, `LayoutAlignItems.Stretch`,
  `LayoutAlignItems.Center`, `LayoutAlignItems.End`, `LayoutAlignItems.Start`, `AlignInContainer.Stretch`,
  `AlignInContainer.Center`, `AlignInContainer.Start`, `AlignInContainer.End`, `LayoutOverflow.Scroll`,
  `DisplayMode.Edit`, `DisplayMode.Disabled`, `VerticalAlign.Top`, `DropShadow.None`.
- SharePoint 'Student Absence Log': write ONLY `Student_ID`, `Match_Status` (`{Value: "Manually Resolved"}`),
  `'Absence Date'`, `'Return Date'`. Never write Matched_Student or any finance-owned column
  (Absence_x0020_Month, Billable_x0020_Days, Billing_x0020_Status, First_x0020_Eligible_x0020_Date,
  Total_x0020_Absence_x0020_Days).
