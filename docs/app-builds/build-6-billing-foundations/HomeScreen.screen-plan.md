# Screen Plan: Home

## Assignment

- Action: Create
- Target file: `C:\src\aaca-attendance\billing-app\HomeScreen.pa.yaml`
- YAML key: HomeScreen
- Control name prefix: Home
- Read with: `canvas-app-shared.md` (palette, visual contract, header/gate/engine patterns, collections, YAML rules).

## Specification

- Purpose: landing page for finance. Four "needs attention" count cards that open the right screen pre-filtered,
  plus a plain-text "Coming next" note. Non-finance users see only the access panel.
- Screen properties: `Fill: =ColorPaper`; `OnVisible: =Select(btnHomeLoadEngine)` (no Navigate here).
- Layout (root `conHomeRoot` per shared Layout Strategy; the screen's `Children:` contains only `conHomeRoot`).
  Root children in order:
  1. `conHomeHeader` — shared header pattern; nav: `btnHomeNavHome` is current (Primary), others Secondary.
  2. `conHomeGate` — shared gate pattern (`lblHomeGateTitle`, `lblHomeGateBody`).
  3. `conHomeBody` — Vertical, no fill, `FillPortions: =0`, `LayoutGap: =12`, Stretch, `Visible: =IsFinance`,
     `Height: =conHomeStatusRow.Height + 12 + conHomeCards.Height + 12 + conHomeNext.Height`
     (all three children have literal/state Height formulas, no Parent-derived heights).
     - `conHomeStatusRow` — Horizontal, `LayoutWrap: =true`, `LayoutGap: =8`, `LayoutAlignItems:
       =LayoutAlignItems.Center`, `FillPortions: =0`, `Height: =If(conHomeRoot.Width - 32 >= 516, 44, 96)`.
       - `lblHomeHeading` "Needs attention" Size 18 Bold ink, Width 200, Height 28, FillPortions 0, Wrap false.
       - `lblHomeStatus` Size 12, FillPortions 1, `LayoutMinWidth: =160`, Height 40, wraps, VerticalAlign Middle.
         `Text`: `=If(varHomeLoading, "Loading counts...", varHomeLoadError <> "", "Could not load counts - " & varHomeLoadError, IsBlank(varHomeLoadedAt), "", "Counts as of " & Text(varHomeLoadedAt, "h:mm AM/PM"))`
         (write as `|-` block). `Color: =If(varHomeLoadError <> "", ColorUnexcused, ColorMuted)`.
       - `btnHomeRefresh` Secondary "Refresh counts", Width 140, Height 44, FillPortions 0,
         `DisplayMode: =If(varHomeLoading, DisplayMode.Disabled, DisplayMode.Edit)`, `OnSelect: =Select(btnHomeLoadEngine)`.
     - `conHomeCards` — Horizontal, `LayoutWrap: =true`, `LayoutGap: =12`, `LayoutAlignItems: =LayoutAlignItems.Start`,
       no fill, `FillPortions: =0`,
       `Height: =With({cols: Max(1, RoundDown((conHomeRoot.Width - 32 + 12) / 244, 0))}, RoundUp(4 / cols, 0) * 196 + (RoundUp(4 / cols, 0) - 1) * 12)` (|- block).
       Four card panels, identical structure (white panel, border rule, radius 6, padding 16, gap 8, Vertical,
       Stretch, `Width: =232`, `Height: =196`, `FillPortions: =0`, `AlignInContainer: =AlignInContainer.Start`):
       - `lblHome<C>Count`: Size 32 Bold, Height 40, Wrap false, `Text: =If(varHomeLoading, "...", Text(<count>))`,
         `Color: =If(<count> > 0, ColorWarnInk, ColorTeal)`, `AccessibleLabel: =Text(<count>) & " " & "<title>"`.
       - `lblHome<C>Title`: Size 14 Semibold ink, Height 60 (3 lines), wraps, VerticalAlign Top, Text = title.
       - `btnHome<C>`: Primary teal, Width 200, Height 44, text below, OnSelect = Cross-Screen pre-filter + Navigate.
     - `conHomeNext` — white panel, padding 16, gap 8, Vertical, Stretch, `FillPortions: =0`,
       `Height: =32 + 20 + 8 + If(conHomeRoot.Width < 640, 120, 60)`.
       - `lblHomeNextTitle` "Coming next" Size 14 Semibold ink, Height 20, Wrap false.
       - `lblHomeNextBody` Size 13 ink, `Height: =If(conHomeRoot.Width < 640, 120, 60)`, wraps, Top. `Text` (|- block):
         `="Later phases, not in this version: CodeMetro upload and exceptions; Register of Daily Services (RDS) grid per student, funder and month; month close and QuickBooks Online invoice export; RDS PDFs."`
         Plain text only — no buttons or links.
  4. `btnHomeLoadEngine` — hidden Classic/Button (shared engine pattern), last child.

- Cards (`<C>` / title / button text / count formula / OnSelect):

| `<C>` | Title | Button text | Count formula | OnSelect (|- block) |
| --- | --- | --- | --- | --- |
| FunQbo | "Funders with no QuickBooks customer" | "Review funders" | `CountRows(Filter(colFunders, IsActive && Trim(QboCustomer) = ""))` | `=Set(varFunType, "All"); Set(varFunMissingQbo, true); Set(varFunShowInactive, false); Navigate(FundersScreen)` |
| SvcQbo | "Active services with no QuickBooks item" | "Review services" | `CountRows(Filter(colServices, IsActive && Trim(QboItem) = ""))` | `=Set(varSvcKind, "All"); Set(varSvcMissingQbo, true); Set(varSvcShowInactive, false); Navigate(ServicesScreen)` |
| StuDor | "Active School students with no current district of record" | "Review students" | `CountRows(Filter(colStudents As s, s.StatusText = "Active" && s.TypeText = "School" && CountIf(colDor, StudentId = s.StudentId && StartDate <= Today() && (IsBlank(EndDate) \|\| EndDate >= Today())) = 0))` | `=Set(varStuType, "All"); Set(varStuNoDor, true); Set(varStuStatus, "Active"); Navigate(StudentsScreen)` |
| PrivPay | "Private Pay funders from CodeMetro with no QuickBooks customer" | "Review Private Pay" | `CountRows(Filter(colFunders, TypeText = "Private Pay" && Trim(QboCustomer) = ""))` | `=Set(varFunType, "Private Pay"); Set(varFunMissingQbo, true); Set(varFunShowInactive, true); Navigate(FundersScreen)` |

  (In the table `\|\|` means `||`.) Button `AccessibleLabel`: e.g. "Review funders with no QuickBooks customer".
  Buttons are enabled even when the count is 0 (destination shows its own zero-result text).

- Load engine `btnHomeLoadEngine.OnSelect` (|- block): shared engine shape with
  `Clear(colFunders); Clear(colServices); Clear(colStudents); Clear(colDor)` in the non-finance branch, and in the
  IfError success branch: `Refresh(Funders); Refresh(Services); Refresh(Students); Refresh('Districts of Record');`
  then `Concurrent(` the four VERBATIM ClearCollect formulas for colFunders, colServices, colStudents, colDor from
  the shared plan `);` then `Set(varHomeLoadedAt, Now()); true`; fallback `Set(varHomeLoadError, FirstError.Message); false`.
  Wrap with `Set(varHomeLoading, true); Set(varHomeLoadError, "");` ... `Set(varHomeLoading, false)`.

- Breakpoint source: `conHomeRoot.Width` only.
- Numeric layout budgets:
  - Header: finance 12 + 28 + 4 + 20 + 4 + 44 + 12 = 124 = `76 + 48`; phone 92 + 48 = 140.
  - Gate: 16 + 24 + 8 + 40 + 16 = 104.
  - Status row at 1024: 200 + 8 + status (>= 160) + 8 + 140 = 516 <= 992; below 548 width it wraps to 2 rows
    (44 + 8 + 44 = 96).
  - Card: 16 + 40 + 8 + 60 + 8 + 44 + 16 = 192 <= 196. Cards row at 1024: 4 x 232 + 3 x 12 = 964 <= 992 (1 row,
    196); at 640: cols = RoundDown((608 + 12) / 244) = 2 -> 2 rows = 404; at 390: 1 col -> 4 rows = 820.
  - Next panel: 32 + 20 + 8 + 60 = 120 (desktop; body text about 175 chars at ~80 chars/line = 3 lines x 20); phone 180.
- Text fit: card titles wrap to at most 3 lines in 200 px at Size 14 (longest title 62 chars, ~28 chars/line).
  Card count values are at most 3 digits at Size 32 (~60 px). Heading single line.
- Visual hierarchy: header band; "Needs attention" heading 18 Bold; card counts 32 Bold (warn colour when > 0, teal
  when 0); card titles 14 Semibold; "Coming next" sub-heading 14 Semibold; body 13.

## Required Record Fields

None (no record list on Home).

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| SV-GATE | `conHomeGate` | `=!IsFinance` | non-finance / finance |
| SV-BODY | `conHomeBody`, `conHomeNav` | `=IsFinance` | finance / non-finance |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-GATE | any user | screen open | Staff via CurrentStaff | non-finance: collections cleared, gate only | N/A | N/A | `conHomeGate.Visible` |
| A-NAV | IsFinance | `btnHomeNav*.OnSelect` | N/A | Navigate | N/A | N/A | destination nav highlight |
| A-HOME-LOAD | IsFinance | `OnVisible`, `btnHomeRefresh.OnSelect` -> `btnHomeLoadEngine` | four tables | collections reloaded, `varHomeLoadedAt` set | N/A | N/A | four counts + `lblHomeStatus` |
| A-HOME-FUNQBO / SVCQBO / STUDOR / PRIVPAY | IsFinance | `btnHomeFunQbo` / `btnHomeSvcQbo` / `btnHomeStuDor` / `btnHomePrivPay` OnSelect | filter globals | globals set as in the card table, then Navigate | N/A | N/A | destination chip highlight and count equal to the Home count |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-GATE-DENY | Staff Finance Access = No / no Staff row | open app | only gate panel | `conHomeGate` visible; `conHomeBody`, `conHomeNav` hidden | no-Staff text variant |
| S-GATE-ALLOW | Finance Access = Yes | open app | body shows | `conHomeBody` | N/A |
| S-NAV | IsFinance | select each nav button | correct screen; current button Primary | nav buttons | N/A |
| S-HOME-LOAD | Dev data (14 active School students with no DoR at capture) | open Home | counts = predicates; status "Counts as of ..."; Coming next text | `lblHome*Count`, `lblHomeStatus`, `lblHomeNextBody` | Refresh reloads |
| S-LOAD-FAIL | read failure | Refresh counts | "Could not load counts - <error>" in red | `lblHomeStatus` | N/A |
| S-HOME-FUNQBO / SVCQBO / STUDOR / PRIVPAY | card count N | select the card button | destination opens pre-filtered; its count label shows N | destination `lbl<P>Count` | N/A |

## Relevant Data Source Schemas

Read-only on this screen (through the shared ClearCollect formulas): Funders (Funder, Abbreviation, Full Name,
Funder Type, QuickBooks Customer, Active), Services (Service, Service Code, Name, Kind, Billing Unit, QuickBooks
Item, Sort Order, Billable, Billable on Non-School Days, Active), Students (Student, External Client ID, Display
Name, 'Status (aaca_status)', Student Type), Districts of Record (District of Record, Student, Funder, Start Date,
End Date, Source, Note). Identity: Users, Staff via App formulas.

## Required Variants

- GroupContainer -> `Variant: AutoLayout` (every container on this screen).

## Control Definitions

- **GroupContainer** (`Control: GroupContainer`, `Variant: AutoLayout`). Inputs: BorderColor, BorderStyle,
  BorderThickness, ContentLanguage, DropShadow, EnableChildFocus, Fill, Height, RadiusBottomLeft, RadiusBottomRight,
  RadiusTopLeft, RadiusTopRight, Visible, Width, X, Y, LayoutAlignItems, LayoutDirection, LayoutGap,
  LayoutJustifyContent, LayoutOverflowX, LayoutOverflowY, LayoutWrap, PaddingBottom, PaddingLeft, PaddingRight,
  PaddingTop; as AutoLayout child: AlignInContainer, FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight,
  LayoutMinWidth. Enums: `DropShadow: =DropShadow.None`; `LayoutDirection: =LayoutDirection.Vertical` /
  `.Horizontal`; `LayoutAlignItems: =LayoutAlignItems.Stretch` / `.Center` / `.Start`;
  `LayoutOverflowY: =LayoutOverflow.Scroll`; `AlignInContainer: =AlignInContainer.Start` / `.Stretch` / `.Center`.
- **ModernText** (`Control: ModernText`). Inputs: AccessibleLabel, Align, AutoHeight, BorderColor, BorderStyle,
  BorderThickness, Color, ContentLanguage, DisplayMode, Fill, Font, FontWeight, Height, Italic, OnSelect,
  PaddingBottom, PaddingLeft, PaddingRight, PaddingTop, RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft,
  RadiusTopRight, Size, Strikethrough, Text, Underline, VerticalAlign, Visible, Width, Wrap, X, Y, AlignInContainer,
  FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth. Enums:
  `FontWeight: =FontWeight.Bold` / `.Semibold` / `.Normal`; `VerticalAlign: =VerticalAlign.Top` / `.Middle`.
- **ModernButton** (`Control: ModernButton`). Inputs: AccessibleLabel, Align, Appearance, BasePaletteColor,
  BorderColor, BorderStyle, BorderThickness, Color, ContentLanguage, DisplayMode, Font, FontWeight, Height, Icon,
  IconRotation, IconStyle, Italic, Layout, OnSelect, PaddingBottom, PaddingLeft, PaddingRight, PaddingTop,
  RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft, RadiusTopRight, Size, Strikethrough, Text, Tooltip, Underline,
  VerticalAlign, Visible, Width, X, Y, AlignInContainer, FillPortions, LayoutMaxHeight, LayoutMaxWidth,
  LayoutMinHeight, LayoutMinWidth. NO `Fill`. Enums: `Appearance: =ButtonAppearance.Secondary` (Enum name
  ButtonAppearance); `Layout: =ButtonLayout.TextOnly` (Enum name ButtonLayout); `DisplayMode: =DisplayMode.Disabled`.
- **Classic/Button** (`Control: Classic/Button`, hidden engine only). Inputs used: AutoDisableOnSelect, OnSelect,
  Text, Visible, AlignInContainer, LayoutMinHeight, LayoutMinWidth. NO AccessibleLabel property.
