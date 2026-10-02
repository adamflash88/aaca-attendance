# Canvas App Shared Plan — AACA Billing (build 6, Phase 1 foundations)

Source folder: `C:\src\aaca-attendance\billing-app`. App.pa.yaml is already written by the planner (named formulas,
palette, OnStart state seeds). Builders never edit App.pa.yaml or `_EditorState.pa.yaml`.

## Aesthetic Direction

Same "classroom register" language as AACA Attendance, applied to a finance ledger: warm paper page, ink-navy header
band, teal accent, white bordered panels. Calm and dense; no decoration beyond rules and fills. All colours are the
App.Formulas named constants below — always use the name, never a new RGBA:

- Page `ColorPaper`; panels `ColorWhite`; borders/rules `ColorRule`
- Text primary `ColorInk`; secondary/caption `ColorMuted`; text on the ink header `ColorWhite` / `ColorInkSoft`
- Accent and primary action `ColorTeal` (white text on it)
- Warning text on white (e.g. "No QuickBooks customer", "No district of record"): `ColorWarnInk`, FontWeight Semibold
- Status surfaces (always `ColorInk` text on them): `ColorInfoBg` success/selected row, `ColorWarnBg` warning/confirm,
  `ColorErrorBg` failed/blocked, `ColorNotEnrolled` muted (Excluded student-service rows)
- Destructive confirm button: `BasePaletteColor: =ColorUnexcused`, `Color: =ColorWhite`

## Visual Contract

- Type roles (ModernText `Size` / `FontWeight`): app title 20 Bold `ColorWhite`; screen/panel heading 18 Bold ink;
  sub-heading 14 Semibold ink; row identity 14 Semibold ink; body 13 Normal ink; field label 12 Semibold `ColorMuted`;
  caption/meta 12 `ColorMuted`; Home card count 32 Bold.
- Every ModernText sets all four `Padding*` (0 unless stated), `AccessibleLabel`, `AlignInContainer`, `FillPortions`,
  `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, an explicit `Height` (or `FillPortions: =1` in a horizontal row);
  single-line labels `Wrap: =false`; multi-line text `VerticalAlign: =VerticalAlign.Top`.
- Spacing: container gap 8 (form panels 6, row internals 2); panel padding 16; row shell padding 8; radius 6 on panels,
  0 on root/header/rows.
- Surfaces: panels `Fill: =ColorWhite`, `BorderColor: =ColorRule`, `BorderThickness: =1`, `DropShadow: =DropShadow.None`.
  Every GroupContainer sets `DropShadow: =DropShadow.None`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`.
- Actions (ModernButton, `Height: =44`, `Layout: =ButtonLayout.TextOnly`, `Size: =14`, explicit `Width`):
  - Primary: `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite` (Appearance omitted = Primary)
  - Secondary: `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk` (never light text on Secondary)
  - Destructive confirm: `BasePaletteColor: =ColorUnexcused`, `Color: =ColorWhite`
  - Filter chip / nav item: `Appearance: =If(<active>, ButtonAppearance.Primary, ButtonAppearance.Secondary)`,
    `BasePaletteColor: =ColorTeal`, `Color: =If(<active>, ColorWhite, ColorInk)`
  - Disabled via `DisplayMode: =DisplayMode.Disabled` only.
- No symbol glyphs in any button text (no arrows, no refresh glyph, no "+"); write words ("Reload", "New funder").
  The middle dot " · " is allowed inside ModernText labels only. Use "..." not the ellipsis character.

## Layout Strategy

- Target: tablet/desktop, desktop-first 1366x768, must work at 1024; narrower widths stack (not a phone target, but
  nothing may clip). Each screen has exactly one top-level child, the root `con<P>Root`: GroupContainer AutoLayout,
  `Width: =Parent.Width`, `Height: =Parent.Height`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`,
  `LayoutDirection: =LayoutDirection.Vertical`, `LayoutOverflowY: =LayoutOverflow.Scroll`,
  `LayoutAlignItems: =LayoutAlignItems.Stretch`, `LayoutGap: =12`, `PaddingLeft/Right: =16`, `PaddingBottom: =16`,
  `PaddingTop: =0`, `Fill: =ColorPaper`. Every section and every hidden engine button lives under it.
- Breakpoints read the root width directly: `con<P>Root.Width >= 1024` = two-panel (list | detail), below = stacked.
  Never store breakpoints in variables. Logical width may stay at design width in a scale-to-fit host, so every
  horizontal row also uses `LayoutWrap: =true` or fits its static budget (see each brief).
- Direct children of the root: `FillPortions: =0` plus an explicit numeric `Height` formula built from literal numbers
  and state (never bare `PaddingTop`/`LayoutGap` names). A parent may read a child's `.Height` only when that child's
  Height formula is itself literal/state based (never `Parent`-derived).
- List + detail body (`con<P>Body`): `LayoutDirection: =If(con<P>Root.Width >= 1024, LayoutDirection.Horizontal,
  LayoutDirection.Vertical)`, `LayoutGap: =12`, `LayoutAlignItems: =If(con<P>Root.Width >= 1024,
  LayoutAlignItems.Start, LayoutAlignItems.Stretch)`. List panel and right column both `FillPortions: =If(con<P>Root
  .Width >= 1024, 1, 0)` (1:1). Below 1024 the list panel hides while a record/form is open and the detail shows a
  "Back to list" button (`Visible: =con<P>Root.Width < 1024`).
- Galleries: Variant Vertical, exactly one AutoLayout shell child (`Width: =Parent.TemplateWidth - 16`,
  `Height: =Parent.TemplateHeight`), fixed numeric `Height`, explicit `TemplateSize`, `TemplatePadding: =0`,
  `TabIndex: =0`, `Selectable: =false`, `ShowScrollbar: =true`. Row actions are ModernButtons inside the shell.
  Empty states are driven by source/filter counts, never `AllItemsCount`.
- Form panels: label and input are siblings inside the same vertical form container (label 18 high, input 36 high,
  gap 6). Toggles/checkboxes use their own `Label` property.
- HARD LESSON: never re-parent a control between compiles (Studio renders it as a black box). If structure must change,
  create a NEW control with a NEW name.

## Named State

App.Formulas (already in App.pa.yaml — reference, do not redefine):
`CurrentUserRow` (Users record), `CurrentStaff` (Staff record), `StaffReady`, `IsFinance` (the gate),
`UserLabel` (Text), `ZeroGuid`, `FarFuture` (= Date(2999,12,31)), `NormAlias(t: Text): Text` (UDF; Upper(Trim(...))
after turning tabs/non-breaking spaces into spaces; Power Fx Trim collapses internal runs to one space), palette.

Global variables (all seeded with their type in App.OnStart; always Set exactly these shapes):

| Variable | Type / values | Owner |
| --- | --- | --- |
| `varFunType` | Text "All" / "District" / "Regional Center" / "Private Pay" | Funders (Home writes) |
| `varFunMissingQbo`, `varFunShowInactive` | Boolean | Funders (Home writes) |
| `varSvcKind` | Text "All" / "School Day" / "Clinical" | Services (Home writes) |
| `varSvcMissingQbo`, `varSvcShowInactive` | Boolean | Services (Home writes) |
| `varStuType` | Text "All" / "School" / "Regional Center Only" | Students (Home writes) |
| `varStuNoDor` | Boolean | Students (Home writes) |
| `varStuStatus` | Text "Active" / "All" | Students (Home writes) |
| `varHomeLoading` / `varHomeLoadError` / `varHomeLoadedAt` | Boolean / Text / DateTime (nullable) | Home |
| `varFunLoading`, `varFunSaving`, `varFunAuditOk` / `varFunLoadError`, `varFunErr`, `varFunMode` ("" / "new" / "edit") | Boolean / Text | Funders |
| `varFunSelId`, `varFunAliasDelId` | GUID, nullable (Blank = none) | Funders |
| `varFunReceipt`, `varFunAliasReceipt` | `{Kind: Text, Msg: Text, RecordId: GUID}` | Funders |
| `varFunLastRec` / `varFunLastAlias` | Patch result record (Funders / 'Funder Aliases') | Funders |
| `varSvc*` | same set as Funders with Svc prefix (`varSvcLastRec` Services, `varSvcLastAlias` 'Service Aliases') | Services |
| `varStuLoading`, `varStuSaving`, `varStuAuditOk` / `varStuLoadError`, `varStuErr` | Boolean / Text | Students |
| `varStuSelId`, `varStuDorEditId`, `varStuDorDelId`, `varStuSsEditId`, `varStuSsDelId` | GUID, nullable | Students |
| `varStuDorMode`, `varStuSsMode` | Text "" / "new" / "edit" | Students |
| `varStuDorReceipt`, `varStuSsReceipt` | `{Kind: Text, Msg: Text, RecordId: GUID}` | Students |
| `varStuLastDor` / `varStuLastSs` | Patch result record ('Districts of Record' / 'Student Services') | Students |

Receipt `Kind` values: "" (hidden), "Created", "Updated", "Moved", "Added", "Removed", "Deleted", "Blocked", "Failed".
Clearing a receipt: `Set(varXReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid})`.

### Collections (shared schemas — copy these ClearCollect formulas VERBATIM; any screen that loads a collection uses
exactly this text so the app-wide type never diverges)

```
ClearCollect(colFunders, ForAll(Funders As f, {FunderId: f.Funder, Abbr: Coalesce(f.Abbreviation, ""), FullName: Coalesce(f.'Full Name', ""), TypeText: Coalesce(Text(f.'Funder Type'), ""), QboCustomer: Coalesce(f.'QuickBooks Customer', ""), IsActive: Coalesce(f.Active, false)}))
ClearCollect(colFunderAliases, ForAll('Funder Aliases' As a, {AliasId: a.'Funder Alias', AliasText: Coalesce(a.'CodeMetro Name', ""), FunderId: a.Funder.Funder}))
ClearCollect(colServices, ForAll(Services As s, {ServiceId: s.Service, Code: Coalesce(s.'Service Code', ""), Name: Coalesce(s.Name, ""), KindText: Coalesce(Text(s.Kind), ""), KindRank: If(Text(s.Kind) = "School Day", 1, 2), UnitText: Coalesce(Text(s.'Billing Unit'), ""), QboItem: Coalesce(s.'QuickBooks Item', ""), SortNum: s.'Sort Order', IsBillable: Coalesce(s.Billable, false), NonSchool: Coalesce(s.'Billable on Non-School Days', false), IsActive: Coalesce(s.Active, false)}))
ClearCollect(colServiceAliases, ForAll('Service Aliases' As a, {AliasId: a.'Service Alias', AliasText: Coalesce(a.Alias, ""), AliasTypeText: Coalesce(Text(a.'Alias Type'), ""), ServiceId: a.Service.Service}))
ClearCollect(colStudents, ForAll(Students As s, {StudentId: s.Student, StudentKey: Coalesce(s.'External Client ID', ""), DisplayName: Coalesce(s.'Display Name', ""), StatusText: Coalesce(Text(s.'Status (aaca_status)'), ""), TypeText: If(Text(s.'Student Type') = "Regional Center Only", "Regional Center Only", "School")}))
ClearCollect(colDor, ForAll('Districts of Record' As d, {DorId: d.'District of Record', StudentId: d.Student.Student, FunderId: d.Funder.Funder, StartDate: d.'Start Date', EndDate: d.'End Date', SourceText: Coalesce(Text(d.Source), ""), Note: Coalesce(d.Note, "")}))
ClearCollect(colStuSvc, ForAll('Student Services' As x, {SsId: x.'Student Service', StudentId: x.Student.Student, ServiceId: x.Service.Service, FunderId: x.Funder.Funder, SvcSort: Coalesce(x.Service.'Sort Order', 9999), StartDate: x.'Start Date', EndDate: x.'End Date', Frequency: Coalesce(x.Frequency, ""), Minutes: x.'Minutes per Frequency', IsEsy: Coalesce(x.ESY, false), SourceText: Coalesce(Text(x.Source), ""), IsExcluded: Coalesce(x.Excluded, false), Note: Coalesce(x.Note, ""), Summary: Coalesce(x.Summary, "")}))
```

Column names deliberately avoid Power Fx names: the service sort column is `SortNum` (a column named `SortOrder`
would shadow the `SortOrder` enum inside `Sort(...)`). Never add a projected column named after a function or enum.

Loads are non-delegable ForAll projections (fine for the current volumes; the app's data row limit must stay >= 500).
Display text for related records always comes from the loaded collections by GUID
(`LookUp(colFunders, FunderId = x).Abbr`), never from display text matching.

### Shared derived predicates (use exactly these meanings everywhere — Home counts and list filters must agree)

- Funder needs QuickBooks customer: `IsActive && Trim(QboCustomer) = ""`
- Private Pay funder from CodeMetro: `TypeText = "Private Pay" && Trim(QboCustomer) = ""` (any Active value)
- Service needs QuickBooks item: `IsActive && Trim(QboItem) = ""`
- Current district of record row (for a student id `sid`): `StudentId = sid && StartDate <= Today() && (IsBlank(EndDate) || EndDate >= Today())`
- Student with no current district of record: `StatusText = "Active" && TypeText = "School" && CountIf(colDor, <current row for s.StudentId>) = 0`
  (inside a Filter over colStudents always write `Filter(colStudents As s, ...)` and use `s.StudentId` so the inner
  colDor scope is unambiguous)
- Active day-service row: `!IsExcluded && StartDate <= Today() && (IsBlank(EndDate) || EndDate >= Today())`

## Shared Patterns (each screen instantiates under its own prefix `<P>`)

### Header band + navigation (identical values on every screen)

`con<P>Header` (direct root child): AutoLayout Vertical, `Fill: =ColorInk`, `FillPortions: =0`,
`Height: =If(con<P>Root.Width < 640, 92, 76) + If(IsFinance, 48, 0)`, `LayoutGap: =4`, padding 12/16/12/16,
`LayoutAlignItems: =LayoutAlignItems.Stretch`, radius 0. Children in order:
1. `lbl<P>Title`: `Text: ="AACA Billing"`, Size 20 Bold `ColorWhite`, Height 28, `Wrap: =false`.
2. `lbl<P>Identity`: `Text: =UserLabel & " · " & If(IsFinance, "Finance access", "No finance access")`, Size 12
   `ColorInkSoft`, `Height: =If(con<P>Root.Width < 640, 36, 20)`, `VerticalAlign: =VerticalAlign.Top`.
3. `con<P>Nav`: AutoLayout Horizontal, Height 44, `FillPortions: =0`, `LayoutGap: =8`,
   `LayoutAlignItems: =LayoutAlignItems.Center`, `Visible: =IsFinance`. Exactly four ModernButtons, in this order, each
   `Width: =110`, `Height: =44`, `FillPortions: =0`, `AlignInContainer: =AlignInContainer.Center`, TextOnly, Size 14:
   `btn<P>NavHome` "Home" -> `Navigate(HomeScreen)`; `btn<P>NavFunders` "Funders" -> `Navigate(FundersScreen)`;
   `btn<P>NavServices` "Services" -> `Navigate(ServicesScreen)`; `btn<P>NavStudents` "Students" ->
   `Navigate(StudentsScreen)`. Current screen: Primary (`BasePaletteColor: =ColorTeal`, `Color: =ColorWhite`,
   `AccessibleLabel` "<Name> (current screen)"); others: `Appearance: =ButtonAppearance.Secondary`,
   `Color: =ColorInk`, `AccessibleLabel` "Go to <Name>". Budget: 4 x 110 + 3 x 8 = 464 <= 608 (narrowest supported
   inner width 640 - 32); no extra nav items.

### Access gate panel (identical on every screen)

`con<P>Gate` (direct root child, immediately after the header): `Visible: =!IsFinance`, white panel (border rule,
radius 6, padding 16, gap 8, Vertical, Stretch), `FillPortions: =0`, `Height: =16 + 24 + 8 + 40 + 16`.
- `lbl<P>GateTitle`: `="You don't have access to AACA Billing"`, Size 16 Semibold ink, Height 24, `Wrap: =false`.
- `lbl<P>GateBody`: `=If(!StaffReady, "Your sign-in is not linked to an active Staff record. Ask Adam Bernstein to set up Finance Access.", "AACA Billing is limited to the finance team. Ask Adam Bernstein if you need Finance Access.")`,
  Size 13 ink, Height 40, Top aligned.
Every data-bearing section on the screen has `Visible` that includes `IsFinance`; load engines clear their
collections when `!IsFinance`. No data, counts, or nav are shown to non-finance users.

### Load engine (hidden Classic/Button, per screen)

`btn<P>LoadEngine`: `Control: Classic/Button`, `Visible: =false`, `AutoDisableOnSelect: =false`, `Text: ="load"`,
`AlignInContainer: =AlignInContainer.Stretch`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, last child of the root.
OnSelect shape:

```
=Set(var<P>Loading, true);
Set(var<P>LoadError, "");
If(
    !IsFinance,
    Clear(colA); Clear(colB),
    IfError(
        Refresh(A); Refresh(B);
        Concurrent(<verbatim ClearCollect A>, <verbatim ClearCollect B>);
        true,
        Set(var<P>LoadError, FirstError.Message);
        false
    )
);
Set(var<P>Loading, false)
```

Screen `OnVisible` always ends with `Select(btn<P>LoadEngine)`; the visible Reload button also calls it.

### Mutation skeleton (every Patch / Remove in the app)

```
Set(var<P>Saving, true);
Set(var<P>Err, "");
IfError(Set(var<P>LastRec, Patch(<Table>, <target>, <changes>)); true, Set(var<P>Err, FirstError.Message); false);
If(
    var<P>Err <> "",
    Set(var<X>Receipt, {Kind: "Failed", Msg: "<Thing> not saved. " & var<P>Err, RecordId: <id or ZeroGuid>}),
    IfError(Patch('Audit Events', Defaults('Audit Events'), {<audit record>}); Set(var<P>AuditOk, true), Set(var<P>AuditOk, false));
    Set(var<X>Receipt, {Kind: "<Created/Updated/...>", Msg: <proof text built from var<P>LastRec>, RecordId: <returned GUID>});
    <close form / set selection to returned GUID>;
    Select(btn<P>LoadEngine)
);
Set(var<P>Saving, false)
```

- `IfError` branches always return the same type: the success branch ends with `; true`, the fallback with `; false`.
- For Remove use `IfError(Remove(<Table>, LookUp(<Table>, <PK> = id)); true, ...)` and capture the snapshot from the
  collection BEFORE removing.
- Every Save/Confirm button: `DisplayMode` Disabled while `var<P>Saving` or the screen's validation label is not
  exactly "Ready to save."; the OnSelect repeats the guard (`If(<valid> && !var<P>Saving && IsFinance, ...)`).
- Text inputs are always `Trim(...)`-ed before writing; alias text always goes through `NormAlias(...)`.
- Target records are always located by GUID with a With() scalar: `LookUp(Funders, Funder = idx)`; never by name.

### Audit Events row (every successful write)

```
Patch('Audit Events', Defaults('Audit Events'), {
    Summary: Left("<Create|Update|Soft Delete> <Entity> " & <identity text>, 100),
    Action: 'Action (Audit Events)'.Create / 'Action (Audit Events)'.Update / 'Action (Audit Events)'.'Soft Delete',
    Entity: "<table display name: Funders | Funder Aliases | Services | Service Aliases | Districts of Record | Student Services>",
    'Entity ID': Text(<record GUID>),
    Before: <"" for Create, else JSON({<changed fields from the pre-save collection row>})>,
    After: <"" for delete, else JSON({<fields as written>})>,
    Reason: "<short text, e.g. Funder saved in AACA Billing>"
})
```

Alias removal and district-of-record / student-service deletion use `'Action (Audit Events)'.'Soft Delete'` (the option
set has no hard-delete value) with Reason "... removed (row deleted)". The receipt always ends with
`" | Audit " & If(var<P>AuditOk, "written", "FAILED - tell Adam")`.

### Section receipt strip (per mutating section)

`con<X>Receipt` (first child of its section panel): `Visible: =var<X>Receipt.Kind <> ""`, AutoLayout Horizontal,
`Fill: =Switch(var<X>Receipt.Kind, "Failed", ColorErrorBg, "Blocked", ColorErrorBg, ColorInfoBg)`, border rule,
radius 6, padding 8/12/8/12, gap 8, `FillPortions: =0`,
`Height: =16 + Max(44, 18 * RoundUp(Len(var<X>Receipt.Msg) / 45, 0) + 8)`,
`LayoutAlignItems: =LayoutAlignItems.Start`. Children: `lbl<X>Receipt` (`Text: =var<X>Receipt.Msg`, Size 13 ink,
`FillPortions: =1`, `Height: =18 * RoundUp(Len(var<X>Receipt.Msg) / 45, 0) + 8`, Top aligned, wraps) and
`btn<X>ReceiptDismiss` (Secondary "Dismiss", Width 88, Height 44, clears the receipt). Messages are labeled values
joined with " | " so each proof-set field is readable, e.g. `"Updated funder ZZTEST1. Abbreviation ZZTEST1 | Full name
ZZ Test District | ..."`. The receipt sits inside the panel where the action happened so it is in the viewport.

## Control Naming

Abbreviations: `con` container, `lbl` ModernText, `btn` ModernButton or engine Classic/Button, `txt` ModernTextInput,
`dd` ModernDropdown, `rdo` ModernRadio, `dp` ModernDatePicker, `tgl` ModernToggle, `chk` ModernCheckbox, `gal`
Gallery, `bad` Badge. Then the screen namespace: Home `Home`, Funders `Fun`, Services `Svc`, Students `Stu`
(e.g. `conFunRoot`, `btnSvcNavHome`, `galStuDor`). Names are app-unique; the shared patterns above are instantiated
under each screen's own prefix — never copy another screen's names.

## Cross-Screen Contracts

- Navigation: only the four header nav buttons and the four Home cards navigate. All use `Navigate(<Screen>)` with no
  transition argument.
- Home card pre-filters (set immediately before Navigate; destination screens never reset these in OnVisible):
  - Funders, missing QuickBooks customer: `Set(varFunType, "All"); Set(varFunMissingQbo, true); Set(varFunShowInactive, false); Navigate(FundersScreen)`
  - Private Pay from CodeMetro: `Set(varFunType, "Private Pay"); Set(varFunMissingQbo, true); Set(varFunShowInactive, true); Navigate(FundersScreen)`
  - Services, missing QuickBooks item: `Set(varSvcKind, "All"); Set(varSvcMissingQbo, true); Set(varSvcShowInactive, false); Navigate(ServicesScreen)`
  - Students, no district of record: `Set(varStuType, "All"); Set(varStuNoDor, true); Set(varStuStatus, "Active"); Navigate(StudentsScreen)`
- Destination OnVisible: clears selection/mode/receipts, `Reset()`s its search box and show-inactive toggle (whose
  Default reads the global), then `Select(btn<P>LoadEngine)`. Filter variables persist, so the header nav shows the
  last-used filters and a Home card shows its pre-filter.
- Every screen reloads its collections on visit, so a change made on one screen appears on the next screen visited.

## YAML Conventions

- Every property value starts with `=`; multi-line formulas use `|-` with `=` on the first content line.
- Any value containing `: ` (captions, record literals like `{Value: "District"}`) or ` #` (e.g. the student-service
  summary `" #" & n`) MUST be a `|-` block. Unquoted ` #` starts a YAML comment and silently truncates the formula.
- Dataverse predicates: compare against With() scalars (never `record.Field` inside a server predicate); choice
  columns compare `= Blank()` in delegated filters; `IsBlank()` only on already-loaded records.
- Yes/No columns are Booleans: `Active: true`, `Excluded: false` — never `'X (Table)'.Yes`.
- Choice literals: `'Funder Type (Funders)'.District`, `'Funder Type (Funders)'.'Regional Center'`,
  `'Funder Type (Funders)'.'Private Pay'`, `'Kind (Services)'.'School Day'`, `'Kind (Services)'.Clinical`,
  `'Billing Unit (Services)'.Days`, `'Billing Unit (Services)'.Hours`, `'Alias Type (Service Aliases)'.'CPT Code'`,
  `'Alias Type (Service Aliases)'.'Service Name'`, `'Source (Districts of Record)'.Manual`,
  `'Source (Student Services)'.Manual`, `'Action (Audit Events)'.Create`, `'Action (Audit Events)'.Update`,
  `'Action (Audit Events)'.'Soft Delete'`. Student status column is `'Status (aaca_status)'` (never `Status`).
- Map radio text to a choice with explicit arms and no default arm, e.g.
  `Switch(t, "District", 'Funder Type (Funders)'.District, "Regional Center", 'Funder Type (Funders)'.'Regional Center', "Private Pay", 'Funder Type (Funders)'.'Private Pay')`.
- Enum literals used in this app: `ButtonAppearance.Primary`, `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`,
  `Appearance.Outline` (inputs/dropdowns/date pickers), `TextInputType.Search`, `TextInputType.SingleLine`,
  `TextInputType.Multiline`, `TriggerOutput.Delayed`, `TriggerOutput.Keypress`, `OptionLayout.Horizontal`,
  `DatePickerFormat.Short`, `FontWeight.Bold`, `FontWeight.Semibold`, `FontWeight.Normal`,
  `LayoutDirection.Vertical`, `LayoutDirection.Horizontal`, `LayoutAlignItems.Stretch`, `LayoutAlignItems.Center`,
  `LayoutAlignItems.Start`, `LayoutJustifyContent.Start`, `AlignInContainer.Stretch`, `AlignInContainer.Center`,
  `AlignInContainer.Start`, `LayoutOverflow.Scroll`, `DisplayMode.Edit`, `DisplayMode.Disabled`, `DisplayMode.View`,
  `VerticalAlign.Top`, `VerticalAlign.Middle`, `DropShadow.None`, `'BadgeCanvas.Appearance'.Tint`,
  `'BadgeCanvas.Shape'.Rounded`, `'BadgeCanvas.ThemeColor'.Subtle`.
- Never re-parent an existing control; never use symbol glyphs in button text.
- Before returning, run the plugin QA checks 1-44 on the written file.
