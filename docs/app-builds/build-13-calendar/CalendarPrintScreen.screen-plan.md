# Screen Plan: Calendar print view (NEW)

## Assignment

- Action: Create
- Target file: `C:\src\aaca-attendance\app\CalendarPrintScreen.pa.yaml`
- YAML key: CalendarPrintScreen
- Control name prefix: CalP
- Build FIRST (before CalendarScreen): this screen references no other new screen (Back uses `Back()`).

Read `canvas-app-shared.md` first (legend colours `Cal*`, `CalLegend`, fill/colour switches, collections owned by
CalendarScreen, YAML rules).

> **DISCOVERY GAP (blocking only for `tmrCalPPrint`).** No packet contains a `describe_control` result for `Timer`.
> The orchestrator must run `describe_control` for Timer and paste its creation keyword(s) and input property names
> into the "Control Definitions" section below before dispatching this brief. Until then the builder must not guess
> the Timer keyword or properties. If Timer cannot be used, apply the documented fallback in A-CALP-PRINT (an
> approximation that needs Adam's OK).

## Specification

- Purpose: one landscape page laid out like the Excel/PDF calendar for the campus and school year shown on
  CalendarScreen: title, legend row, 12 months in 3 rows x 4 (Aug..Jul), right column with Important Dates, Staff
  Development Days, Quarterly Periods, Testing Period. White background, thin rules, print-friendly sizes. A small
  toolbar (Back, Print, hint) that hides while printing.
- Data: read-only. Reads `varCalYearId`, `varCalCampusId`, `colCalYearOpts`, `colCalCampusOpts`, `CalLegend`,
  `colCalMonths`, `colCalCells`, `colCalImportant` exactly as CalendarScreen built them. No Dataverse calls.
- Breakpoint source: `conCalPRoot.Width` (phone `< 640`, narrow `< 1024`). Screen `Fill: =ColorWhite`.
- Screen `OnVisible: =Set(varCalPPrinting, false)`.

### Control tree (exact names and order)

```
CalendarPrintScreen
└ conCalPRoot                    root (sole top-level child)
  ├ conCalPToolbar               btnCalPBack, btnCalPPrint, lblCalPHint
  ├ tmrCalPPrint                 Timer (hidden) - see discovery gap
  ├ lblCalPTitle
  ├ lblCalPEmpty
  ├ galCalPLegend                lblCalPLegendItem
  └ conCalPBody
    ├ galCalPMonths              conCalPMonth: lblCalPMonthTitle, galCalPDays (lblCalPDay)
    └ galCalPImp                 lblCalPImpLine
```

## Layout and properties

### Root `conCalPRoot`
GroupContainer AutoLayout, DropShadow None, Fill `=ColorWhite`, Width `=Parent.Width`, Height `=Parent.Height`,
LayoutMinWidth `=0`, LayoutMinHeight `=0`, Vertical, LayoutAlignItems Stretch, LayoutGap 6,
LayoutOverflowY `=LayoutOverflow.Scroll`, Padding* 12, Radius* 0.

### `conCalPToolbar`
Horizontal, LayoutWrap `=true`, LayoutAlignItems Center, gap 8, FillPortions 0, no fill, Radius* 0, Height
`=If(conCalPRoot.Width < 640, 96, 44)`, Visible `=!varCalPPrinting`.
- `btnCalPBack`: Secondary, Text `="Back"`, Width 90, AccessibleLabel `="Back to the Calendar screen"`, OnSelect `=Back()`.
- `btnCalPPrint`: Primary teal, Text `="Print"`, Width 100, AccessibleLabel `="Print or save as PDF"`, DisplayMode
  `=If(CountRows(colCalCells) > 0, DisplayMode.Edit, DisplayMode.Disabled)`, OnSelect
  `=Set(varCalPPrinting, true); Print()`.
- `lblCalPHint`: ModernText 12 `ColorMuted`, FillPortions 1, LayoutMinWidth 220, Height 36, AlignInContainer Center,
  VerticalAlign Middle, Padding* 0, Text `="In the print dialog choose Landscape, then a printer or Save as PDF."`,
  AccessibleLabel `=Self.Text`.

### Timer control definition (describe_control, supplied by the orchestrator 2026-10-08)
`Control: Timer` (Classic family; no Variant). Input properties: Align, AutoPause, AutoStart, BorderColor, BorderStyle,
BorderThickness, Color, ContentLanguage, DisabledBorderColor, DisabledColor, DisabledFill, DisplayMode, Duration,
Fill, FocusedBorderColor, FocusedBorderThickness, Font, FontWeight, Height, HoverBorderColor, HoverColor, HoverFill,
Italic, OnSelect, OnTimerEnd, OnTimerStart, PaddingBottom/Left/Right/Top, PressedBorderColor, PressedColor,
PressedFill, Radius*, Repeat, Reset, Size, Start, Strikethrough, TabIndex, Text, Tooltip, Underline, VerticalAlign,
Visible, Width, X, Y; as an AutoLayout child also AlignInContainer, FillPortions, LayoutMaxHeight, LayoutMaxWidth,
LayoutMinHeight (default 40), LayoutMinWidth (default 160) - set LayoutMinHeight/LayoutMinWidth =0, Height =0, Width =0.
Output: Value. The discovery gap above is resolved: use the Timer as intended (not the fallback).

### `tmrCalPPrint`
Intended values: Duration `=3000`, Start `=varCalPPrinting`, AutoStart `=false`, Repeat `=false`, OnTimerEnd
`=Set(varCalPPrinting, false)`, Visible `=false`. Use only property names that appear in the Timer
`describe_control` result supplied by the orchestrator. If the Timer needs AutoLayout child properties, use
`AlignInContainer: =AlignInContainer.Start`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`.

### `lblCalPTitle`
ModernText, Size 20 Bold ink, Align `=Align.Center`, Height 30, Wrap false, Padding* 0, AlignInContainer Stretch,
FillPortions 0, Text
`=LookUp(colCalYearOpts, YearId = varCalYearId).YearName & " AACA " & LookUp(colCalCampusOpts, CampusId = varCalCampusId).CampusName`,
AccessibleLabel `=Self.Text`.

### `lblCalPEmpty`
ModernText 13 ink, Height 36, VerticalAlign Top, Padding* 0, Visible `=CountRows(colCalCells) = 0`, Text
`="Nothing to print yet. Open this page with View calendar on the Calendar screen."`, AccessibleLabel `=Self.Text`.

### `galCalPLegend`
Gallery `Variant: Vertical`, AccessibleLabel `="Calendar legend"`, Items `=CalLegend`, WrapCount
`=If(conCalPRoot.Width >= 1024, 8, conCalPRoot.Width >= 640, 4, 2)`, TemplateSize 22, TemplatePadding 0, Height
`=RoundUp(CountRows(CalLegend) / If(conCalPRoot.Width >= 1024, 8, conCalPRoot.Width >= 640, 4, 2), 0) * 22`,
FillPortions 0, AlignInContainer Stretch, LoadingSpinner `=LoadingSpinner.None`, Selectable false, ShowScrollbar false.
- `lblCalPLegendItem` (only child): Width `=Parent.TemplateWidth - 4`, Height `=Parent.TemplateHeight - 3`, Text
  `=ThisItem.Txt`, AccessibleLabel `="Legend " & ThisItem.Txt`, Size `=If(conCalPRoot.Width < 640, 11, 9)`, Align
  Center, Wrap false, Padding* 1, Fill / Color = shared switches (`k` = `ThisItem.Kind`), BorderColor
  `=If(ThisItem.Kind = "makeup", CalRsy, ColorRule)`, BorderThickness `=If(ThisItem.Kind = "makeup", 2, 1)`.

### `conCalPBody`
FillPortions 0, gap 8, no fill, Radius* 0, LayoutDirection
`=If(conCalPRoot.Width >= 1024, LayoutDirection.Horizontal, LayoutDirection.Vertical)`, LayoutAlignItems
`=If(conCalPRoot.Width >= 1024, LayoutAlignItems.Start, LayoutAlignItems.Stretch)`, Height
`=If(conCalPRoot.Width >= 1024, Max(galCalPMonths.Height, galCalPImp.Height), galCalPMonths.Height + 8 + galCalPImp.Height)`.

- `galCalPMonths`: Gallery `Variant: Vertical`, AccessibleLabel `="Calendar months"`, Items `=colCalMonths`,
  WrapCount `=If(conCalPRoot.Width >= 1024, 4, conCalPRoot.Width >= 640, 3, 1)`, TemplateSize
  `=If(conCalPRoot.Width < 640, 240, 156)`, TemplatePadding 0, Height
  `=RoundUp(CountRows(colCalMonths) / If(conCalPRoot.Width >= 1024, 4, conCalPRoot.Width >= 640, 3, 1), 0) * If(conCalPRoot.Width < 640, 240, 156)`,
  FillPortions `=If(conCalPRoot.Width >= 1024, 1, 0)`, AlignInContainer
  `=If(conCalPRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)`, LoadingSpinner None,
  Selectable false, ShowScrollbar false.
  - `conCalPMonth` (shell): vertical, Stretch, gap 2, Padding* 2, Fill `=ColorWhite`, BorderColor `=ColorRule`,
    BorderThickness 1, Radius* 0, Width `=Parent.TemplateWidth - 6`, Height `=Parent.TemplateHeight - 6`.
    - `lblCalPMonthTitle`: Fill `=CalMonthBand`, Color `=ColorWhite`, Size `=If(conCalPRoot.Width < 640, 12, 10)`
      Bold, Align Center, Height 18, Wrap false, Padding* 0, FillPortions 0, Text `=ThisItem.Title`,
      AccessibleLabel `=Self.Text`. (No "locked" suffix on the printed page.)
    - `galCalPDays`: Gallery `Variant: Vertical`, AccessibleLabel `="Days of " & ThisItem.Title`, Items
      `=Filter(colCalCells, MonthKey = ThisItem.MonthKey)`, WrapCount 7, TemplateSize
      `=If(conCalPRoot.Width < 640, 30, 18)`, Height `=7 * If(conCalPRoot.Width < 640, 30, 18)`, TemplatePadding 0,
      FillPortions 0, AlignInContainer Stretch, LoadingSpinner None, Selectable false, ShowScrollbar false.
      - `lblCalPDay` (only child, ModernText): X 0, Y 0, Width `=Parent.TemplateWidth`, Height
        `=Parent.TemplateHeight`, Text `=ThisItem.Txt`, AccessibleLabel `=If(ThisItem.InMonth, ThisItem.Tip, ThisItem.Txt)`,
        Size `=If(conCalPRoot.Width < 640, 12, 9)`, FontWeight `=If(ThisItem.IsHdr, FontWeight.Bold, FontWeight.Normal)`,
        Align Center, VerticalAlign `=VerticalAlign.Middle`, Wrap false, Padding* 0, Fill / Color = shared
        switches, BorderColor `=If(ThisItem.Kind = "makeup", CalRsy, ColorRule)`, BorderThickness
        `=If(ThisItem.IsHdr || !ThisItem.InMonth, 0, ThisItem.Kind = "makeup", 2, 1)`.
- `galCalPImp`: Gallery `Variant: Vertical`, AccessibleLabel `="Important dates, staff development days, quarters and testing"`,
  Items `=SortByColumns(colCalImportant, "Sec", SortOrder.Ascending, "SortD", SortOrder.Ascending)`, TemplateSize
  `=If(conCalPRoot.Width < 640, 22, 15)`, TemplatePadding 0, Height
  `=CountRows(colCalImportant) * If(conCalPRoot.Width < 640, 22, 15)`, FillPortions 0, Width 300, AlignInContainer
  `=If(conCalPRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)`, BorderColor `=ColorRule`,
  BorderThickness 1, LoadingSpinner None, Selectable false, ShowScrollbar false.
  - `lblCalPImpLine` (only child): X 0, Y 0, Width `=Parent.TemplateWidth`, Height `=Parent.TemplateHeight`, Text
    `=ThisItem.Line`, AccessibleLabel `=ThisItem.Line`, Size
    `=If(ThisItem.IsHead, If(conCalPRoot.Width < 640, 13, 10), If(conCalPRoot.Width < 640, 12, 9))`, FontWeight
    `=If(ThisItem.IsHead, FontWeight.Bold, FontWeight.Normal)`, Fill `=If(ThisItem.IsHead, CalMonthBand, ColorWhite)`,
    Color `=If(ThisItem.IsHead, ColorWhite, ColorInk)`, PaddingLeft 6, PaddingRight 4, PaddingTop 0, PaddingBottom 0,
    Wrap false, VerticalAlign Middle.

## Numeric layout budgets

- Desktop 1366 x 768: root inner 1342. Body: months 1342 - 8 - 300 = 1034 / 4 = 258 per month -> shell 252 ->
  inner 248 / 7 = 35 px cells. Month shell 2 + 18 + 2 + 7 x 18 + 2 = 150 = 156 - 6.
- Page height: 12 + toolbar 44 + 6 + title 30 + 6 + legend 22 (8 per row: 1342 / 8 = 167 px chips) + 6 + body
  max(3 x 156 = 468, ~30 lines x 15 = 450) + 12 = 606 <= 768; while printing the toolbar is hidden: 556.
- 1024: months 1000 - 8 - 300 = 692 / 4 = 173 -> 167 -> 163 / 7 = 23 px cells (Size 9 fits "30").
- 640-1023: stacked; 3 months per row; side list below at full width.
- Phone 375: toolbar 90 + 8 + 100 = 198 on row 1, hint on row 2 = 96; 1 month per row (351 / 7 = 50 px cells);
  12 x 240 = 2880 + list, scroll root.
- Side list longest line "Winter Recess - 12/21/2026 - 1/4/2027" ~ 190 px at Size 9 <= 290.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| calp-title | page | "<Year> AACA <Campus Name>" | colCalYearOpts.YearName, colCalCampusOpts.CampusName | lblCalPTitle | see above | top, always |
| calp-cell | month day cell | day number + colour | colCalCells.Txt, Kind | lblCalPDay | `=ThisItem.Txt` + switches | 12 months |
| calp-month | month band | month + year | colCalMonths.Title | lblCalPMonthTitle | `=ThisItem.Title` | above each month |
| calp-lists | right column | Important Dates / SDD n / Qtr.n / Testing lines | colCalImportant.Line | lblCalPImpLine | `=ThisItem.Line` | right column (below on narrow) |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| calp-toolbar | conCalPToolbar | `=!varCalPPrinting` | hidden from Print press until the timer ends |
| calp-empty | lblCalPEmpty | `=CountRows(colCalCells) = 0` | opened without a loaded calendar |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-CALP-PRINT | calendar loaded | `btnCalPPrint.OnSelect: =Set(varCalPPrinting, true); Print()` | N/A | toolbar hidden; browser print dialog opens; `tmrCalPPrint` (Start = varCalPPrinting) ends after 3 s and sets varCalPPrinting false | N/A | N/A | `conCalPToolbar.Visible: =!varCalPPrinting`; printed page / PDF shows no toolbar. Fallback if Timer is unavailable (approximation, needs approval): OnSelect `=Set(varCalPPrinting, true); Print(); Set(varCalPPrinting, false)` - the toolbar may appear on the printout |
| A-CALP-BACK | any | `btnCalPBack.OnSelect: =Back()` | N/A | returns to CalendarScreen (its OnVisible reloads) | N/A | N/A | CalendarScreen visible with the same year/campus |

## Functional Test Scenarios

Owned: S-CAL-VIEW (render part), S-CALP-PRINT, S-CALP-BACK, S-CALP-PHONE, S-CALP-EMPTY - copy the rows from the plan
index Functional Test Matrix.

## Required Variants

- GroupContainer -> `Variant: AutoLayout`.
- Gallery -> `Variant: Vertical` (galCalPLegend, galCalPMonths, galCalPDays, galCalPImp).

## Control Definitions

- GroupContainer (`Control: GroupContainer` + Variant): BorderColor, BorderStyle, BorderThickness, DropShadow, Fill,
  Height, RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft, RadiusTopRight, Visible, Width; AutoLayout:
  LayoutAlignItems, LayoutDirection (required), LayoutGap, LayoutJustifyContent, LayoutOverflowX, LayoutOverflowY,
  LayoutWrap, PaddingBottom/Left/Right/Top; as child: AlignInContainer, FillPortions, LayoutMaxHeight, LayoutMaxWidth,
  LayoutMinHeight, LayoutMinWidth.
- ModernText (`Control: ModernText`): AccessibleLabel, Align [Align], AlignInContainer, AutoHeight, BorderColor,
  BorderStyle, BorderThickness, Color, Fill, FillPortions, FontWeight [FontWeight], Height, LayoutMinHeight,
  LayoutMinWidth, PaddingBottom/Left/Right/Top, Size, Text, VerticalAlign [VerticalAlign], Visible, Width, Wrap, X, Y.
- ModernButton (`Control: ModernButton`; NO Fill): AccessibleLabel, AlignInContainer, Appearance [ButtonAppearance],
  BasePaletteColor, Color, DisplayMode, FillPortions, Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth,
  OnSelect, Size, Text, Tooltip, Visible, Width.
- Gallery (`Control: Gallery` + Variant): AccessibleLabel, AlignInContainer, BorderColor, BorderThickness,
  FillPortions, Height, Items, LayoutMinHeight, LayoutMinWidth, LoadingSpinner [LoadingSpinner], Selectable,
  ShowScrollbar, TabIndex, TemplatePadding, TemplateSize, Visible, Width, WrapCount. Outputs TemplateWidth,
  TemplateHeight.
- Timer: **PENDING** - orchestrator pastes the `describe_control` creation keyword(s) and input property names here.

Compile-ready enum literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `LoadingSpinner.None`,
`Align.Center`, `FontWeight.Bold`, `FontWeight.Normal`, `VerticalAlign.Top`, `VerticalAlign.Middle`,
`DisplayMode.Edit`, `DisplayMode.Disabled`, `LayoutDirection.Horizontal`, `LayoutDirection.Vertical`,
`LayoutAlignItems.Stretch`, `LayoutAlignItems.Center`, `LayoutAlignItems.Start`, `AlignInContainer.Stretch`,
`AlignInContainer.Center`, `AlignInContainer.Start`, `LayoutOverflow.Scroll`, `DropShadow.None`,
`SortOrder.Ascending`.

YAML: no `: ` or ` #` occurs in this screen's formulas except where noted; if any caption gains one, use `|-`.
Every nav-less print control still needs `AccessibleLabel` (except the Timer and containers).
