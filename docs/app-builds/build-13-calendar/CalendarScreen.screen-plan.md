# Screen Plan: Calendar (NEW)

## Assignment

- Action: Create
- Target file: `C:\src\aaca-attendance\app\CalendarScreen.pa.yaml`
- YAML key: CalendarScreen
- Control name prefix: Cal
- Build after CalendarPrintScreen exists in the session (`btnCalView` navigates to it).

Read `canvas-app-shared.md` first (palette incl. `Cal*` colours, nav pattern, calendar data semantics, YAML rules,
App seeds). Copy property shapes from `C:\src\aaca-attendance\app\StaffScreen.pa.yaml`: header `conStfHeader`
(lines 36-281), help panel `conStfHelp` (282-486), denied panel `conStfDenied` (487-559), receipt `conStfReceipt`
(578-715), and the Classic/Button engine shape (1834-1874) - renamed to `Cal` with the values below. Do not edit
StaffScreen.pa.yaml.

## Specification

- Purpose: System Admins view and maintain each campus's school-year calendar: 12-month colour-coded year view,
  day / range editing (with "also apply to" campuses), periods (Q1-Q4, ESY, Testing), Important Dates, Check calendar,
  create the next school year from the shown one, copy the shown calendar to another campus, and open the print view.
  Everyone else sees the denied panel.
- Breakpoint source: `conCalRoot.Width` only (phone `< 640`, nav band `< 800`, narrow `< 1024`, wide `>= 1280`).
  Screen `Fill: =ColorPaper`.
- Selected range: `varCalFrom` / `varCalTo` (nullable dates) are the single source of truth; cells, pickers, check
  and save all read them.

### Control tree (exact names and order)

```
CalendarScreen
└ conCalRoot                         root (sole top-level child)
  ├ conCalHeader                     Ink band (copy of conStfHeader)
  │ ├ lblCalTitle
  │ ├ lblCalIdentity
  │ ├ conCalNav                      btnCalNavAttendance, btnCalNavStudents, btnCalNavAbsences, btnCalNavTransport,
  │ │                                btnCalNavStaff, btnCalNavCalendar (CURRENT), conCalNavSpacer, imgCalNavHelp
  │ └ conCalHdrBar                   paper strip: conCalYearField(lblCalYear, ddCalYear),
  │                                  conCalCampusField(lblCalCampus, ddCalCampus), btnCalView
  ├ conCalHelp                       copy of conStfHelp: conCalHelpHead(lblCalHelpTitle, btnCalHelpNew, btnCalHelpClose),
  │                                  spnCalHelpBusy, conCalHelpChat(htmCalHelpChat), conCalHelpAsk(txtCalHelpQ, btnCalHelpAsk), lblCalHelpNote
  ├ conCalDenied                     lblCalDeniedTitle, lblCalDeniedBody, btnCalDeniedBack
  ├ conCalBody
  │ ├ conCalReceipt                  conCalReceiptTop(lblCalReceiptTitle, btnCalReceiptClose),
  │ │                                galCalReceipt(conCalRcptRow: lblCalRcptLabel, lblCalRcptValue)
  │ ├ lblCalNote
  │ └ conCalView
  │   ├ conCalMain                   white panel
  │   │ ├ galCalLegend               lblCalLegendItem
  │   │ ├ galCalMonths               conCalMonth: lblCalMonthTitle, galCalDays (btnCalDay)
  │   │ └ conCalLower
  │   │   ├ conCalImpPanel           lblCalImpTitle, galCalImp (lblCalImpLine)
  │   │   └ conCalChkPanel           conCalChkHead(lblCalChkTitle, btnCalCheck), lblCalChkStamp, galCalChk (lblCalChkLine)
  │   └ conCalSide
  │     ├ tabCalPanel
  │     ├ conCalDaysPanel            lblCalDaysHelp, conCalFromTo(conCalFromField(lblCalFrom, dpCalFrom),
  │     │                            conCalToField(lblCalTo, dpCalTo)), lblCalType, rdoCalType, lblCalName, txtCalName,
  │     │                            lblCalAlso, galCalAlso (chkCalAlso), lblCalDayCheck, chkCalConfirm, btnCalSaveDays
  │     ├ conCalPerPanel             lblCalPerHelp, conCalPerHead(lblCalPerHPeriod, lblCalPerHStart, lblCalPerHEnd),
  │     │                            galCalPer(conCalPerRow: lblCalPerName, dpCalPerStart, dpCalPerEnd), lblCalPerCheck,
  │     │                            conCalPerActions(btnCalSavePer, btnCalPerUndo)
  │     ├ conCalNewPanel             lblCalNewHelp, lblCalNewName, txtCalNewName, conCalNewDates(
  │     │                            conCalNewStartField(lblCalNewStart, dpCalNewStart), conCalNewEndField(lblCalNewEnd, dpCalNewEnd)),
  │     │                            chkCalNewAll, lblCalNewCheck, btnCalCreate
  │     └ conCalCopyPanel            lblCalCopyHelp, lblCalCopyTarget, ddCalCopyTarget, lblCalCopyPreview, chkCalCopyConfirm,
  │                                  lblCalCopyCheck, btnCalCopy
  ├ btnCalLoadEngine                 hidden Classic/Button engines (Visible false)
  ├ btnCalBuildEngine
  ├ btnCalCheckEngine
  ├ btnCalCountEngine
  ├ btnCalCreateEngine
  └ btnCalCopyEngine
```

About 130 controls (StaffScreen is ~95; the year view itself is only 4 controls because the 588 cells are one
nested gallery). Do not add wrappers beyond this tree.

## Screen OnVisible

```
=Set(varCalSaving, false);
Set(varCalLoading, false);
Set(varCalReceipt, {Kind: "", Title: ""});
Clear(colCalReceiptLines);
ClearCollect(colCalCampusOpts, ForAll(Sort(Campuses, Name, SortOrder.Ascending) As c, {CampusId: c.Campus, CampusName: c.Name, Code: Coalesce(c.Code, "")}));
ClearCollect(colCalYearOpts, ForAll(Sort('School Years', 'Start Date', SortOrder.Descending) As yy, {YearId: yy.'School Year', YearName: yy.Name, S: yy.'Start Date', E: yy.'End Date', StatusText: Text(yy.'Status (aaca_status)')}));
If(IsBlank(LookUp(colCalYearOpts, YearId = varCalYearId)), Set(varCalYearId, Coalesce(CurrentSchoolYear.'School Year', First(colCalYearOpts).YearId, ZeroGuid)));
If(IsBlank(LookUp(colCalCampusOpts, CampusId = varCalCampusId)), Set(varCalCampusId, Coalesce(First(colCalCampusOpts).CampusId, ZeroGuid)));
ClearCollect(colCalAlso, ForAll(Filter(colCalCampusOpts, CampusId <> varCalCampusId) As c, {CampusId: c.CampusId, CampusName: c.CampusName, Ticked: false}));
Set(varCalCopyTargetId, Blank());
Select(btnCalLoadEngine)
```

## Layout and properties by section

### Root `conCalRoot`
As `conStfRoot`: DropShadow None, Fill `=ColorPaper`, Width `=Parent.Width`, Height `=Parent.Height`, LayoutMinWidth
`=0`, LayoutMinHeight `=0`, Vertical, Stretch, gap 8, LayoutOverflowY `=LayoutOverflow.Scroll`, PaddingBottom 16,
Radius* 0.

### Header `conCalHeader` (copy of `conStfHeader`)
Same properties except:
- Height: `=If(conCalRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conCalRoot.Width < 640, 152, conCalRoot.Width < 800, 100, 48), 48) + If(IsAdminRole, If(conCalRoot.Width >= 728, 60, conCalRoot.Width >= 576, 112, 164), 0)`
- PaddingBottom: `=If(IsAdminRole, 0, 12)`
- `lblCalTitle`, `lblCalIdentity`: exactly as `lblStfTitle` / `lblStfIdentity` (with `conCalRoot`).
- `conCalNav`: as `conStfNav` but Height `=If(CanManageStudents, If(conCalRoot.Width < 640, 148, conCalRoot.Width < 800, 96, 44) + If(IsAdminRole, 8, 0), 44)`.
  Buttons per the shared nav table: `btnCalNavAttendance`, `btnCalNavStudents`, `btnCalNavAbsences`,
  `btnCalNavTransport` (Visible `=CanClassify`), `btnCalNavStaff` all Secondary (non-current values);
  `btnCalNavCalendar` CURRENT: Text `="Calendar"`, Width 100, BasePaletteColor `=ColorTeal`, Color `=ColorWhite`,
  AccessibleLabel `="Calendar (current screen)"`, OnSelect `=Navigate(CalendarScreen)`, Visible `=IsAdminRole`, no
  Appearance. Then `conCalNavSpacer` (Visible `=conCalRoot.Width >= 640`) and `imgCalNavHelp` exactly as in StaffScreen.
- `conCalHdrBar`: as `conStfHdrBar` but LayoutWrap `=true`, Visible `=IsAdminRole`, Height
  `=If(conCalRoot.Width >= 728, 60, conCalRoot.Width >= 576, 112, 164)`. Children:
  - `conCalYearField`: horizontal, LayoutAlignItems Center, gap 8, FillPortions 0, Width 272, Height 44,
    AlignInContainer Center.
    - `lblCalYear`: field label, Text `="School year"`, Width 84, Height 20, Wrap false, AlignInContainer Center.
    - `ddCalYear`: ModernDropdown, Appearance Outline, Color ink, Width 180, Height 36, AlignInContainer Center,
      AccessibleLabel `="School year"`, Items `=colCalYearOpts`, ItemDisplayText
      `=ThisItem.YearName & If(ThisItem.StatusText = "", "", " (" & ThisItem.StatusText & ")")`, Default
      `=LookUp(colCalYearOpts, YearId = varCalYearId)`, DisplayMode
      `=If(!varCalLoading && !varCalSaving, DisplayMode.Edit, DisplayMode.Disabled)`, OnChange (block):
      ```
      =Set(varCalYearId, Coalesce(Self.Selected.YearId, varCalYearId));
      Set(varCalFrom, Blank());
      Set(varCalTo, Blank());
      Set(varCalPickTo, false);
      Select(btnCalLoadEngine)
      ```
  - `conCalCampusField`: same shape, Width 264.
    - `lblCalCampus`: Text `="Campus"`, Width 56.
    - `ddCalCampus`: as ddCalYear with Width 200, AccessibleLabel `="Campus"`, Items `=colCalCampusOpts`,
      ItemDisplayText `=ThisItem.CampusName`, Default `=LookUp(colCalCampusOpts, CampusId = varCalCampusId)`,
      OnChange (block):
      ```
      =Set(varCalCampusId, Coalesce(Self.Selected.CampusId, varCalCampusId));
      ClearCollect(colCalAlso, ForAll(Filter(colCalCampusOpts, CampusId <> varCalCampusId) As c, {CampusId: c.CampusId, CampusName: c.CampusName, Ticked: false}));
      Set(varCalFrom, Blank());
      Set(varCalTo, Blank());
      Set(varCalPickTo, false);
      Set(varCalCopyTargetId, Blank());
      Select(btnCalLoadEngine)
      ```
  - `btnCalView`: Primary teal, Text `="View calendar"`, Width 140, AccessibleLabel
    `="View the printable calendar"`, DisplayMode
    `=If(IsAdminRole && !varCalLoading && !varCalSaving && varCalLoadError = "" && CountRows(colCalCells) > 0, DisplayMode.Edit, DisplayMode.Disabled)`,
    OnSelect `=Navigate(CalendarPrintScreen)`.

### Help `conCalHelp`
Copy `conStfHelp` and its whole subtree; rename every `Stf` to `Cal` (`conStfRoot` -> `conCalRoot`, `txtStfHelpQ`
-> `txtCalHelpQ`), and change only the context string inside `btnCalHelpAsk.OnSelect` to
`HelpContextPrefix & " The user is on the Calendar screen (System Admin school calendar: days, periods, new school year, copy to campus, print view)."`.

### `conCalDenied` (copy of `conStfDenied`)
Visible `=!IsAdminRole`. `lblCalDeniedTitle` Text and AccessibleLabel `="Calendar is not available for your role"`;
`lblCalDeniedBody` Text
`=If(!StaffReady, "Your sign-in is not linked to an active Staff record. Ask your office manager to add you on the Staff screen.", "Only System Admins manage the school calendar. Ask a System Admin if a calendar date needs to change.")`;
`btnCalDeniedBack` "Back to Attendance" `=Navigate(Screen1)`. Height formula as `conStfDenied` with `conCalRoot`.

### `conCalBody`
Vertical, Stretch, gap 8, FillPortions 0, no fill, PaddingLeft 8, PaddingRight 8, Visible `=IsAdminRole`, Height
`=If(conCalReceipt.Visible, conCalReceipt.Height + 8, 0) + If(lblCalNote.Visible, 36 + 8, 0) + conCalView.Height`.

### Receipt `conCalReceipt` (copy of `conStfReceipt`, names `Cal`)
Fill `=Switch(varCalReceipt.Kind, "Failed", ColorErrorBg, "Blocked", ColorErrorBg, "Partial", ColorWarnBg, ColorInfoBg)`,
Visible `=varCalReceipt.Kind <> ""`, Height
`=8 + If(conCalRoot.Width < 640, 124, 64) + If(CountRows(colCalReceiptLines) > 0, 4 + galCalReceipt.Height, 0) + 8`.
`lblCalReceiptTitle.Text: =varCalReceipt.Title`; `btnCalReceiptClose` OnSelect (block)
`=Set(varCalReceipt, {Kind: "", Title: ""}); Clear(colCalReceiptLines)`; `galCalReceipt` Items `=colCalReceiptLines`,
WrapCount `=If(conCalRoot.Width < 1024, 1, 2)`, TemplateSize `=If(conCalRoot.Width < 640, 88, 56)`, Height
`=Min(560, RoundUp(CountRows(colCalReceiptLines) / If(conCalRoot.Width < 1024, 1, 2), 0) * If(conCalRoot.Width < 640, 88, 56))`,
ShowScrollbar true; row `conCalRcptRow` / `lblCalRcptLabel` / `lblCalRcptValue` as in StaffScreen.

### `lblCalNote`
13 ink, Height 36, VerticalAlign Top, AlignInContainer Stretch, Visible `=Self.Text <> ""`, Color
`=If(varCalLoadError <> "", ColorUnexcused, ColorInk)`, Text (block):
```
=If(
    varCalLoading, "Loading the calendar...",
    varCalLoadError <> "", "Could not load: " & varCalLoadError & ". Pick the year or campus again to retry.",
    CountRows(colCalYearOpts) = 0, "No school years exist yet.",
    CountRows(Filter(colCalTermsEff, Has)) = 0, "This campus has no periods for " & LookUp(colCalYearOpts, YearId = varCalYearId).YearName & " yet. Enter them on the Periods tab, or use Copy from another campus.",
    ""
)
```

### `conCalView`
FillPortions 0, gap 8, no fill, Radius* 0, LayoutDirection
`=If(conCalRoot.Width >= 1024, LayoutDirection.Horizontal, LayoutDirection.Vertical)`, LayoutAlignItems
`=If(conCalRoot.Width >= 1024, LayoutAlignItems.Start, LayoutAlignItems.Stretch)`, Height
`=If(conCalRoot.Width >= 1024, Max(conCalMain.Height, conCalSide.Height), conCalMain.Height + 8 + conCalSide.Height)`.

### Main panel `conCalMain`
Panel style (white, rule border, radius 6), vertical, Stretch, gap 8, padding 12, FillPortions
`=If(conCalRoot.Width >= 1024, 1, 0)`, AlignInContainer
`=If(conCalRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)`, Height
`=12 + galCalLegend.Height + 8 + galCalMonths.Height + 8 + conCalLower.Height + 12`.

- `galCalLegend`: Gallery `Variant: Vertical`, AccessibleLabel `="Calendar legend"`, Items `=CalLegend`, WrapCount
  `=If(conCalRoot.Width < 640, 2, 4)`, TemplateSize 28, TemplatePadding 0, Height
  `=RoundUp(CountRows(CalLegend) / If(conCalRoot.Width < 640, 2, 4), 0) * 28`, FillPortions 0, AlignInContainer
  Stretch, LoadingSpinner `=LoadingSpinner.None`, Selectable false, ShowScrollbar false.
  - `lblCalLegendItem` (only child): ModernText, Width `=Parent.TemplateWidth - 6`, Height `=Parent.TemplateHeight - 4`,
    Text `=ThisItem.Txt`, AccessibleLabel `="Legend " & ThisItem.Txt`, Size 11, Align `=Align.Center`, Wrap false,
    Padding* 2, Fill / Color = the shared switches with `k` = `ThisItem.Kind`, BorderColor
    `=If(ThisItem.Kind = "makeup", CalRsy, ColorRule)`, BorderThickness `=If(ThisItem.Kind = "makeup", 2, 1)`.
- `galCalMonths`: Gallery `Variant: Vertical`, AccessibleLabel `="School year months"`, Items `=colCalMonths`, WrapCount
  `=If(conCalRoot.Width >= 1280, 4, conCalRoot.Width >= 640, 3, 1)`, TemplateSize
  `=If(conCalRoot.Width < 640, 320, 222)`, TemplatePadding 0, Height
  `=RoundUp(CountRows(colCalMonths) / If(conCalRoot.Width >= 1280, 4, conCalRoot.Width >= 640, 3, 1), 0) * If(conCalRoot.Width < 640, 320, 222)`,
  FillPortions 0, AlignInContainer Stretch, LoadingSpinner None, Selectable false, ShowScrollbar false, TabIndex 0.
  - `conCalMonth` (shell): vertical, Stretch, gap 2, Padding* 4, Fill `=ColorWhite`, BorderColor `=ColorRule`,
    BorderThickness 1, Radius* 0, Width `=Parent.TemplateWidth - 8`, Height `=Parent.TemplateHeight - 8`.
    - `lblCalMonthTitle`: Fill `=CalMonthBand`, Color `=ColorWhite`, Size 12 Bold, Align Center, Height 22, Wrap false,
      FillPortions 0, Text `=ThisItem.Title & If(ThisItem.Locked, " · locked", "")`, AccessibleLabel `=Self.Text`.
    - `galCalDays`: Gallery `Variant: Vertical`, AccessibleLabel `="Days of " & ThisItem.Title`, Items
      `=Filter(colCalCells, MonthKey = ThisItem.MonthKey)`, WrapCount 7, TemplateSize
      `=If(conCalRoot.Width < 640, 40, 26)`, Height `=7 * If(conCalRoot.Width < 640, 40, 26)`, TemplatePadding 0,
      FillPortions 0, AlignInContainer Stretch, LoadingSpinner None, Selectable false, ShowScrollbar false, TabIndex 0.
      - `btnCalDay` (only child, Classic/Button): X 0, Y 0, Width `=Parent.TemplateWidth`, Height
        `=Parent.TemplateHeight`, Text `=ThisItem.Txt`, Tooltip `=ThisItem.Tip`, Size
        `=If(conCalRoot.Width < 640, 13, 11)`, FontWeight `=If(ThisItem.IsHdr, FontWeight.Bold, FontWeight.Normal)`,
        Align `=Align.Center`, VerticalAlign `=VerticalAlign.Middle`, Padding* 0, Radius* 0, AutoDisableOnSelect false,
        Fill / Color = shared switches (`k` = `ThisItem.Kind`), plus:
        ```
        BorderColor: =If(ThisItem.InMonth && !IsBlank(varCalFrom) && ThisItem.D >= varCalFrom && ThisItem.D <= Coalesce(varCalTo, varCalFrom), ColorTeal, ThisItem.Kind = "makeup", CalRsy, ThisItem.InMonth && ThisItem.D = Today(), ColorInk, ColorRule)
        BorderThickness: =If(ThisItem.IsHdr || !ThisItem.InMonth, 0, (!IsBlank(varCalFrom) && ThisItem.D >= varCalFrom && ThisItem.D <= Coalesce(varCalTo, varCalFrom)) || ThisItem.Kind = "makeup" || ThisItem.D = Today(), 2, 1)
        DisplayMode: =If(ThisItem.InMonth && !ThisItem.IsHdr && !varCalSaving, DisplayMode.Edit, DisplayMode.Disabled)
        DisabledFill: =Self.Fill
        DisabledColor: =Self.Color
        DisabledBorderColor: =Self.BorderColor
        HoverFill: =Self.Fill
        HoverColor: =Self.Color
        HoverBorderColor: =ColorTeal
        PressedFill: =Self.Fill
        PressedColor: =Self.Color
        PressedBorderColor: =ColorTeal
        FocusedBorderColor: =ColorTeal
        FocusedBorderThickness: =2
        TabIndex: =If(ThisItem.InMonth && !ThisItem.IsHdr, 0, -1)
        ```
        OnSelect (block):
        ```
        =If(
            ThisItem.InMonth && !ThisItem.IsHdr && !varCalSaving,
            If(
                varCalPickTo && !IsBlank(varCalFrom) && ThisItem.D >= varCalFrom,
                Set(varCalTo, ThisItem.D); Set(varCalPickTo, false),
                Set(varCalFrom, ThisItem.D); Set(varCalTo, ThisItem.D); Set(varCalPickTo, true)
            );
            Set(varCalPanel, "Days");
            Select(btnCalCountEngine)
        )
        ```
- `conCalLower`: FillPortions 0, gap 8, LayoutDirection
  `=If(conCalRoot.Width >= 1280, LayoutDirection.Horizontal, LayoutDirection.Vertical)`, LayoutAlignItems
  `=If(conCalRoot.Width >= 1280, LayoutAlignItems.Start, LayoutAlignItems.Stretch)`, Height
  `=If(conCalRoot.Width >= 1280, Max(conCalImpPanel.Height, conCalChkPanel.Height), conCalImpPanel.Height + 8 + conCalChkPanel.Height)`.
  - `conCalImpPanel`: panel style, vertical, Stretch, gap 8, padding 12, FillPortions
    `=If(conCalRoot.Width >= 1280, 1, 0)`, AlignInContainer `=If(conCalRoot.Width >= 1280, AlignInContainer.Start, AlignInContainer.Stretch)`,
    Height `=12 + 24 + 8 + galCalImp.Height + 12`.
    - `lblCalImpTitle`: 16 Bold ink, Height 24, Wrap false, Text
      `="Important dates · " & LookUp(colCalCampusOpts, CampusId = varCalCampusId).CampusName & " · " & LookUp(colCalYearOpts, YearId = varCalYearId).YearName`.
    - `galCalImp`: Gallery Vertical, AccessibleLabel `="Important dates, staff development days, quarters and testing"`,
      Items `=SortByColumns(colCalImportant, "Sec", SortOrder.Ascending, "SortD", SortOrder.Ascending)`, TemplateSize 22,
      TemplatePadding 0, Height `=CountRows(colCalImportant) * 22`, FillPortions 0, LoadingSpinner None, Selectable
      false, ShowScrollbar false.
      - `lblCalImpLine` (only child): Width `=Parent.TemplateWidth`, Height 22, Text `=ThisItem.Line`, AccessibleLabel
        `=ThisItem.Line`, Color ink, Size `=If(ThisItem.IsHead, 13, 12)`, FontWeight
        `=If(ThisItem.IsHead, FontWeight.Bold, FontWeight.Normal)`, PaddingLeft `=If(ThisItem.IsHead, 0, 8)`, other
        Padding 0, Wrap false.
  - `conCalChkPanel`: same panel shape but LayoutGap 4, Height `=12 + 44 + 4 + 18 + 4 + galCalChk.Height + 12`.
    - `conCalChkHead`: horizontal, Center, gap 8, Height 44, FillPortions 0:
      `lblCalChkTitle` (16 Bold, FillPortions 1, Height 24, Text `="Calendar check"`, Wrap false);
      `btnCalCheck` (Secondary, Text `="Check calendar"`, Width 150, AccessibleLabel
      `="Check the calendar including attendance marks"`, DisplayMode
      `=If(IsAdminRole && !varCalLoading && !varCalSaving, DisplayMode.Edit, DisplayMode.Disabled)`, OnSelect
      `=Set(varCalCheckWithAtt, true); Select(btnCalCheckEngine)`).
    - `lblCalChkStamp`: 12 `ColorMuted`, Height 18, Wrap false, Text `=varCalCheckStamp`.
    - `galCalChk`: Gallery Vertical, AccessibleLabel `="Calendar check results"`, Items `=colCalChecks`, TemplateSize 56,
      TemplatePadding 0, Height `=Min(CountRows(colCalChecks), 10) * 56`, ShowScrollbar true, LoadingSpinner None,
      Selectable false, FillPortions 0.
      - `lblCalChkLine` (only child): Width `=Parent.TemplateWidth - 16`, Height 56, Size 12, VerticalAlign Top,
        Text `=ThisItem.Line`, AccessibleLabel `=ThisItem.Line`, Color
        `=Switch(ThisItem.Sev, "error", ColorUnexcused, "ok", ColorExcused, ColorInk)`, FontWeight
        `=If(ThisItem.Sev = "error", FontWeight.Semibold, FontWeight.Normal)`.

### Side column `conCalSide`
Vertical, Stretch, gap 8, no fill, FillPortions 0, Width 380, AlignInContainer
`=If(conCalRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)`, Height
`=44 + 8 + Switch(varCalPanel, "Periods", conCalPerPanel.Height, "New year", conCalNewPanel.Height, "Copy", conCalCopyPanel.Height, conCalDaysPanel.Height)`.

- `tabCalPanel`: ModernTabList, AccessibleLabel `="Calendar tools"`, Items `=["Days", "Periods", "New year", "Copy"]`,
  Default (block) `={Value: varCalPanel}`, TabSize `=TabSize.Small`, Appearance `=TabListAppearance.Transparent`,
  BasePaletteColor `=ColorTeal`, Color `=ColorInk`, Height 44, AlignInContainer Stretch, FillPortions 0, DisplayMode
  `=If(varCalSaving, DisplayMode.Disabled, DisplayMode.Edit)`, OnChange
  `=Set(varCalPanel, Self.Selected.Value); Set(varCalCopyTargetId, Blank()); Reset(chkCalCopyConfirm)`.
- Every panel: panel style, vertical, Stretch, gap 4, padding 16, FillPortions 0. Labels = field label style (12
  Semibold `ColorMuted`, Height 18, Wrap false). Inputs: Appearance Outline, Color ink, AlignInContainer Stretch,
  DisplayMode `=If(varCalSaving, DisplayMode.Disabled, DisplayMode.Edit)`. Year bounds:
  `y` = `LookUp(colCalYearOpts, YearId = varCalYearId)`.

#### `conCalDaysPanel` (Visible `=!(varCalPanel in ["Periods", "New year", "Copy"])`)
Height `=32 + 54 + 4 + 58 + 4 + 18 + 4 + 210 + 4 + 18 + 4 + 36 + 4 + 18 + 4 + CountRows(colCalAlso) * 36 + 4 + 72 + If(chkCalConfirm.Visible, 4 + 52, 0) + 4 + 44`
(= 596 + 36 per other campus [+56 with the confirmation]).

| # | Control | Key properties | Height |
| - | ------- | -------------- | ------ |
| 1 | lblCalDaysHelp | 12 ink, VerticalAlign Top, Text `="Click a day to set From, then click a later day to set To. Saves apply to weekdays in the range (Make-up days may also use Saturdays)."` | 54 |
| 2 | conCalFromTo | horizontal, gap 8, Start, FillPortions 0, children 3a/3b | 58 |
| 3a | conCalFromField | vertical, Stretch, gap 4, Width 156, FillPortions 0: `lblCalFrom` `="From *"`; `dpCalFrom` ModernDatePicker, AccessibleLabel `="From date"`, Format Short, Height 36, DefaultDate `=varCalFrom`, StartDate `=LookUp(colCalYearOpts, YearId = varCalYearId).S`, EndDate `=LookUp(colCalYearOpts, YearId = varCalYearId).E`, OnChange F-DP1 | 58 |
| 3b | conCalToField | same: `lblCalTo` `="To *"`; `dpCalTo` AccessibleLabel `="To date"`, DefaultDate `=varCalTo`, StartDate `=Coalesce(varCalFrom, LookUp(colCalYearOpts, YearId = varCalYearId).S)`, EndDate as From, OnChange F-DP2 | 58 |
| 4 | lblCalType | `="Type *"` | 18 |
| 5 | rdoCalType | ModernRadio, AccessibleLabel `="Day type"`, Items `=CalTypeOptions`, ItemDisplayText `=ThisItem.Show`, Layout `=OptionLayout.Vertical`, Default `=LookUp(CalTypeOptions, Value = Coalesce(LookUp(colCalExcEff, D = varCalFrom).TypeText, "Holiday"))`, OnChange `=Select(btnCalCountEngine)` | 210 |
| 6 | lblCalName | `=If(rdoCalType.Selected.Value = "Clear", "Name (not used when clearing)", "Name shown on the calendar *")` | 18 |
| 7 | txtCalName | ModernTextInput, AccessibleLabel `="Name shown on the calendar"`, Placeholder `="For example Labor Day"`, MaxLength 100, Default `=Coalesce(LookUp(colCalExcEff, D = varCalFrom).Label, "")`, DisplayMode `=If(varCalSaving \|\| rdoCalType.Selected.Value = "Clear", DisplayMode.Disabled, DisplayMode.Edit)` | 36 |
| 8 | lblCalAlso | `="Also apply to"` | 18 |
| 9 | galCalAlso | Gallery Vertical, AccessibleLabel `="Other campuses"`, Items `=colCalAlso`, TemplateSize 36, TemplatePadding 0, Height `=CountRows(colCalAlso) * 36`, LoadingSpinner None, Selectable false, ShowScrollbar false, FillPortions 0; only child `chkCalAlso` (ModernCheckbox, X 0, Y 0, Width `=Parent.TemplateWidth`, Height 36, Label `=ThisItem.CampusName`, AccessibleLabel `="Also apply to " & ThisItem.CampusName`, Color ink, Default `=ThisItem.Ticked`, OnCheck `=Patch(colCalAlso, ThisItem, {Ticked: true}); Select(btnCalCountEngine)`, OnUncheck `=Patch(colCalAlso, ThisItem, {Ticked: false}); Select(btnCalCountEngine)`, DisplayMode as inputs) | 36 x n |
| 10 | lblCalDayCheck | 12, VerticalAlign Top, Color `=If(StartsWith(Self.Text, "Ready"), ColorExcused, ColorUnexcused)`, Text C-DAY | 72 |
| 11 | chkCalConfirm | ModernCheckbox, Color ink, Label `=varCalDayAtt.N & " attendance marks exist on these days; they will no longer count. I understand."`, AccessibleLabel `=Self.Label`, Default false, Visible `=varCalDayAtt.N > 0` | 52 |
| 12 | btnCalSaveDays | Width 160, AlignInContainer Start, Color ColorWhite, BasePaletteColor `=If(rdoCalType.Selected.Value = "Clear", ColorUnexcused, ColorTeal)`, Text `=If(rdoCalType.Selected.Value = "Clear", "Clear days", "Save days")`, AccessibleLabel `=Self.Text`, DisplayMode `=If(IsAdminRole && !varCalSaving && !varCalLoading && StartsWith(lblCalDayCheck.Text, "Ready"), DisplayMode.Edit, DisplayMode.Disabled)`, OnSelect S-DAYS | 44 |

F-DP1 `dpCalFrom.OnChange` (block):
```
=Set(varCalFrom, Self.SelectedDate);
If(IsBlank(varCalTo) || varCalTo < Self.SelectedDate, Set(varCalTo, Self.SelectedDate));
Set(varCalPickTo, false);
Select(btnCalCountEngine)
```
F-DP2 `dpCalTo.OnChange`: `=Set(varCalTo, Self.SelectedDate); Set(varCalPickTo, false); Select(btnCalCountEngine)`

Freshness key K (write it out identically in C-DAY and E4):
`Text(f, "yyyy-mm-dd") & "|" & Text(t, "yyyy-mm-dd") & "|" & typ & "|" & Text(varCalCampusId) & Concat(Filter(colCalAlso, Ticked), "," & Text(CampusId))`

C-DAY `lblCalDayCheck.Text`:
```
=With(
    {f: varCalFrom, t: varCalTo, typ: rdoCalType.Selected.Value, nm: Trim(txtCalName.Text), y: LookUp(colCalYearOpts, YearId = varCalYearId)},
    With(
        {
            key: Text(f, "yyyy-mm-dd") & "|" & Text(t, "yyyy-mm-dd") & "|" & typ & "|" & Text(varCalCampusId) & Concat(Filter(colCalAlso, Ticked), "," & Text(CampusId)),
            days: CountRows(Filter(colCalYearDays, D >= f && D <= t && (Weekday(D, StartOfWeek.Monday) <= 5 || (typ = "Make-up School Day" && Weekday(D, StartOfWeek.Monday) = 6)))),
            lk: First(Filter(colCalLocksAll, (CampusId = varCalCampusId || CampusId in Filter(colCalAlso, Ticked).CampusId) && MonthStart >= Date(Year(f), Month(f), 1) && MonthStart <= Date(Year(t), Month(t), 1)))
        },
        If(
            !IsAdminRole, "Only System Admins can change the calendar.",
            varCalLoading, "Loading the calendar...",
            IsBlank(y), "Choose a school year.",
            IsBlank(f), "Click a day in the calendar (or choose From) to start.",
            IsBlank(t), "Choose the To date.",
            t < f, "The To date is before the From date.",
            DateDiff(f, t, TimeUnit.Days) > 44, "Choose at most 45 days at a time.",
            f < y.S || t > y.E, "The dates must be inside the " & y.YearName & " school year (" & Text(y.S, "m/d/yyyy") & " to " & Text(y.E, "m/d/yyyy") & ").",
            IsBlank(typ), "Choose a type.",
            typ <> "Clear" && nm = "", "Enter the name shown on the calendar, for example Labor Day.",
            days = 0, "There are no weekdays in this range" & If(typ = "Make-up School Day", " (Make-up days may also use Saturdays)", "") & ".",
            !IsBlank(lk), Text(lk.MonthStart, "mmmm yyyy") & " is locked at " & LookUp(colCalCampusOpts, CampusId = lk.CampusId).CampusName & ". Days in a locked month cannot be changed.",
            varCalDayAtt.Key <> key, "Counting attendance marks...",
            varCalDayAtt.N > 0 && !chkCalConfirm.Checked, varCalDayAtt.N & " attendance marks exist on these days; they will no longer count. Tick the confirmation below to continue.",
            "Ready: " & If(typ = "Clear", "clears ", "sets ") & days & If(days = 1, " day", " days") & If(typ = "Clear", "", " to " & LookUp(CalTypeOptions, Value = typ).Show & " (" & nm & ")") & " at " & LookUp(colCalCampusOpts, CampusId = varCalCampusId).CampusName & Concat(Filter(colCalAlso, Ticked), ", " & CampusName) & "."
        )
    )
)
```

S-DAYS `btnCalSaveDays.OnSelect` (the mutation owner; literal guards per outcome):
```
=With(
    {f: varCalFrom, t: varCalTo, typ: rdoCalType.Selected.Value, typShow: rdoCalType.Selected.Show, nm: Trim(txtCalName.Text), conf: chkCalConfirm.Checked},
    If(
        !IsAdminRole || varCalSaving || !StartsWith(lblCalDayCheck.Text, "Ready"),
        Set(varCalReceipt, {Kind: "Blocked", Title: "Not saved. " & lblCalDayCheck.Text}); Clear(colCalReceiptLines),
        Set(varCalSaving, true);
        ClearCollect(
            colCalTargets,
            ForAll(Filter(colCalCampusOpts, CampusId = varCalCampusId) As c, {CampusId: c.CampusId, CampusName: c.CampusName, Code: c.Code}),
            ForAll(Filter(colCalAlso, Ticked) As a, {CampusId: a.CampusId, CampusName: a.CampusName, Code: LookUp(colCalCampusOpts, CampusId = a.CampusId).Code})
        );
        Clear(colCalDayWork);
        ForAll(
            colCalTargets As c,
            Collect(colCalDayWork, ForAll(Filter(colCalYearDays, D >= f && D <= t && (Weekday(D, StartOfWeek.Monday) <= 5 || (typ = "Make-up School Day" && Weekday(D, StartOfWeek.Monday) = 6))) As dd, {D: dd.D, CampusId: c.CampusId, CampusName: c.CampusName}))
        );
        With(
            {liveN: If(typ in ["Holiday", "Break", "Closed", "Work Only", "Inclement Weather"], Sum(ForAll(colCalTargets As c, With({c0: c.CampusId, f0: f, t0: t}, CountRows(Filter(Attendance, Campus.Campus = c0 && Date >= f0 && Date <= t0 && 'Is Deleted' <> true)))), Value), 0)},
            If(
                liveN > 0 && !conf,
                Select(btnCalCountEngine);
                Set(varCalReceipt, {Kind: "Blocked", Title: "Not saved · " & liveN & " attendance marks exist on these days; they will no longer count. Tick the confirmation and press Save again."});
                Clear(colCalReceiptLines),
                With(
                    {typCh: Switch(typ, "Holiday", 'Type (Calendar Exceptions)'.Holiday, "Break", 'Type (Calendar Exceptions)'.Break, "Closed", 'Type (Calendar Exceptions)'.Closed, "Work Only", 'Type (Calendar Exceptions)'.'Work Only', "Inclement Weather", 'Type (Calendar Exceptions)'.'Inclement Weather', "Make-up School Day", 'Type (Calendar Exceptions)'.'Make-up School Day')},
                    Clear(colCalLog);
                    ForAll(
                        colCalDayWork As w,
                        With(
                            {ex: With({q: w.D, c0: w.CampusId}, LookUp('Calendar Exceptions', Date = q && Campus.Campus = c0)), k: Text(w.D, "ddd m/d/yyyy") & " · " & w.CampusName},
                            If(
                                typ = "Clear",
                                If(
                                    IsBlank(ex),
                                    Collect(colCalLog, {Key: k, Outcome: "none", Detail: "nothing to clear", Id: ZeroGuid}),
                                    With(
                                        {before: Text(ex.Type) & " · " & ex.Description, exId: ex.'Calendar Exception'},
                                        With(
                                            {ok: IfError(Remove('Calendar Exceptions', ex); true, false)},
                                            Collect(colCalLog, {Key: k, Outcome: If(ok, "removed", "failed"), Detail: If(ok, "removed (was " & before & ")", "not removed: " & Coalesce(First(Errors('Calendar Exceptions')).Message, "unknown error")), Id: exId})
                                        )
                                    )
                                ),
                                IsBlank(ex),
                                With(
                                    {wr: IfError(Patch('Calendar Exceptions', Defaults('Calendar Exceptions'), {Description: nm, Date: w.D, Type: typCh, Campus: With({c0: w.CampusId}, LookUp(Campuses, ThisRecord.Campus = c0))}), Blank())},
                                    Collect(colCalLog, {Key: k, Outcome: If(IsBlank(wr), "failed", "created"), Detail: If(IsBlank(wr), "not created: " & Coalesce(First(Errors('Calendar Exceptions')).Message, "unknown error"), Text(wr.Type) & " · " & wr.Description & " · " & Text(wr.Date, "m/d/yyyy")), Id: If(IsBlank(wr), ZeroGuid, wr.'Calendar Exception')})
                                ),
                                ex.Type = typCh && ex.Description = nm,
                                Collect(colCalLog, {Key: k, Outcome: "unchanged", Detail: "already " & Text(ex.Type) & " · " & ex.Description, Id: ex.'Calendar Exception'}),
                                With(
                                    {before: Text(ex.Type) & " · " & ex.Description},
                                    With(
                                        {wr: IfError(Patch('Calendar Exceptions', ex, {Description: nm, Type: typCh}), Blank())},
                                        Collect(colCalLog, {Key: k, Outcome: If(IsBlank(wr), "failed", "updated"), Detail: If(IsBlank(wr), "not updated: " & Coalesce(First(Errors('Calendar Exceptions')).Message, "unknown error"), Text(wr.Type) & " · " & wr.Description & " (was " & before & ")"), Id: ex.'Calendar Exception'})
                                    )
                                )
                            )
                        )
                    );
                    With(
                        {
                            cr: CountRows(Filter(colCalLog, Outcome = "created")),
                            up: CountRows(Filter(colCalLog, Outcome = "updated")),
                            rm: CountRows(Filter(colCalLog, Outcome = "removed")),
                            un: CountRows(Filter(colCalLog, Outcome in ["unchanged", "none"])),
                            fl: CountRows(Filter(colCalLog, Outcome = "failed"))
                        },
                        With(
                            {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Calendar " & typ & " " & nm & " " & Text(f, "yyyy-mm-dd") & " to " & Text(t, "yyyy-mm-dd") & " (" & Concat(colCalTargets, Code, ",") & ")", 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_calendarexception", 'Entity ID': Text(varCalCampusId), Before: "", After: JSON({YearId: Text(varCalYearId), From: Text(f, "yyyy-mm-dd"), To: Text(t, "yyyy-mm-dd"), Type: typ, Name: nm, Campuses: Concat(colCalTargets, CampusName, ", "), Dates: Concat(Filter(colCalDayWork, CampusId = varCalCampusId), Text(D, "yyyy-mm-dd"), ","), Created: cr, Updated: up, Removed: rm, Unchanged: un, Failed: fl, AttendanceMarks: liveN}), Reason: "Calendar days " & If(typ = "Clear", "cleared", "set") & " on the Calendar screen"}), Blank())},
                            Set(varCalReceipt, {Kind: If(cr + up + rm + un = 0, "Failed", fl > 0, "Partial", "Saved"), Title: If(typ = "Clear", "Days cleared · ", "Days saved · " & typShow & " · " & nm & " · ") & Text(f, "m/d/yyyy") & If(t > f, " to " & Text(t, "m/d/yyyy"), "") & " · " & Concat(colCalTargets, CampusName, ", ") & " · " & cr & " created, " & up & " updated, " & rm & " removed, " & fl & " failed"});
                            ClearCollect(
                                colCalReceiptLines,
                                {Label: "Operation", Value: If(typ = "Clear", "Clear days", "Set days")},
                                {Label: "Type", Value: typShow},
                                {Label: "Name", Value: If(typ = "Clear", "(not used)", nm)},
                                {Label: "Dates", Value: Text(f, "m/d/yyyy") & " to " & Text(t, "m/d/yyyy") & " · " & CountRows(Filter(colCalDayWork, CampusId = varCalCampusId)) & " day(s) per campus"},
                                {Label: "Campuses", Value: Concat(colCalTargets, CampusName, ", ")},
                                {Label: "Created / updated / removed", Value: cr & " / " & up & " / " & rm},
                                {Label: "Unchanged / failed", Value: un & " / " & fl},
                                {Label: "Attendance marks", Value: If(liveN > 0, liveN & " marks on these days no longer count (confirmed)", "None affected")},
                                {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Update written")},
                                ForAll(colCalLog As g, {Label: g.Key, Value: Switch(g.Outcome, "created", "Created", "updated", "Updated", "removed", "Removed", "unchanged", "Unchanged", "none", "Nothing to clear", "FAILED") & " · " & g.Detail})
                            );
                            Select(btnCalLoadEngine)
                        )
                    )
                )
            )
        );
        Set(varCalSaving, false)
    )
)
```

#### `conCalPerPanel` (Visible `=varCalPanel = "Periods"`)
Height `=32 + 72 + 4 + 18 + 4 + 264 + 4 + 72 + 4 + 44` (= 518).

| # | Control | Key properties | Height |
| - | ------- | -------------- | ------ |
| 1 | lblCalPerHelp | 12 ink, VerticalAlign Top, Text (block) `="Quarters run back to back: each quarter starts on the next school day after the previous one ends. ESY follows Q4. Testing is informational; leave both Testing dates empty if there is none."` | 72 |
| 2 | conCalPerHead | horizontal, Center, gap 8, FillPortions 0: `lblCalPerHPeriod` `="Period"` Width 60; `lblCalPerHStart` `="Start *"` FillPortions 1; `lblCalPerHEnd` `="End *"` FillPortions 1 (field-label style) | 18 |
| 3 | galCalPer | Gallery Vertical, AccessibleLabel `="Period dates"`, Items `=colCalPerEdit`, TemplateSize 44, TemplatePadding 0, Height `=CountRows(colCalPerEdit) * 44`, LoadingSpinner None, Selectable false, ShowScrollbar false, FillPortions 0, TabIndex 0 | 264 |
| 3a | conCalPerRow (shell) | horizontal, Center, gap 8, Width `=Parent.TemplateWidth`, Height `=Parent.TemplateHeight`, no fill | 44 |
| 3b | lblCalPerName | 13 Semibold ink, Width 60, Height 36, Wrap false, AlignInContainer Center, Text `=ThisItem.TermText`, AccessibleLabel `=ThisItem.TermText & " period"` | 36 |
| 3c | dpCalPerStart | ModernDatePicker, FillPortions 1, Height 36, AlignInContainer Center, Format Short, AccessibleLabel `=ThisItem.TermText & " start date"`, DefaultDate `=ThisItem.S`, StartDate `=LookUp(colCalYearOpts, YearId = varCalYearId).S`, EndDate `=LookUp(colCalYearOpts, YearId = varCalYearId).E`, OnChange `=Patch(colCalPerEdit, ThisItem, {S: Self.SelectedDate})` | 36 |
| 3d | dpCalPerEnd | same with AccessibleLabel `=ThisItem.TermText & " end date"`, DefaultDate `=ThisItem.E`, OnChange `=Patch(colCalPerEdit, ThisItem, {E: Self.SelectedDate})` | 36 |
| 4 | lblCalPerCheck | 12, VerticalAlign Top, Color as lblCalDayCheck, Text C-PER | 72 |
| 5 | conCalPerActions | horizontal, Center, gap 8, FillPortions 0: `btnCalSavePer` (Primary, Text `="Save periods"`, Width 150, DisplayMode `=If(IsAdminRole && !varCalSaving && !varCalLoading && StartsWith(lblCalPerCheck.Text, "Ready"), DisplayMode.Edit, DisplayMode.Disabled)`, OnSelect S-PER); `btnCalPerUndo` (Secondary, Text `="Undo changes"`, Width 130, OnSelect `=ClearCollect(colCalPerEdit, ForAll(Sequence(6) As n, With({tr: Index(colCalTermsEff, n.Value)}, {N: n.Value, TermText: tr.TermText, S: tr.S, E: tr.E})))`) | 44 |

C-PER `lblCalPerCheck.Text`:
```
=With(
    {
        y: LookUp(colCalYearOpts, YearId = varCalYearId),
        q1: LookUp(colCalPerEdit, TermText = "Q1"),
        q2: LookUp(colCalPerEdit, TermText = "Q2"),
        q3: LookUp(colCalPerEdit, TermText = "Q3"),
        q4: LookUp(colCalPerEdit, TermText = "Q4"),
        es: LookUp(colCalPerEdit, TermText = "ESY"),
        ts: LookUp(colCalPerEdit, TermText = "Testing")
    },
    With(
        {
            nx1: Min(Filter(colCalYearDays, Open && D > q1.E), D),
            nx2: Min(Filter(colCalYearDays, Open && D > q2.E), D),
            nx3: Min(Filter(colCalYearDays, Open && D > q3.E), D),
            miss: Concat(Filter(colCalPerEdit, TermText <> "Testing" && (IsBlank(S) || IsBlank(E))), TermText, ", "),
            bad: Concat(Filter(colCalPerEdit, !IsBlank(S) && !IsBlank(E) && E < S), TermText, ", "),
            outY: Concat(Filter(colCalPerEdit, !IsBlank(S) && !IsBlank(E) && (S < y.S || E > y.E)), TermText, ", "),
            chg: Sum(ForAll(colCalPerEdit As p, With({o: LookUp(colCalTermsEff, TermText = p.TermText)}, If((IsBlank(p.S) && IsBlank(p.E)) || (o.IsCampus && o.S = p.S && o.E = p.E), 0, 1))), Value)
        },
        If(
            !IsAdminRole, "Only System Admins can change the calendar.",
            varCalLoading, "Loading the calendar...",
            IsBlank(y), "Choose a school year.",
            miss <> "", "Enter start and end dates for " & miss & ".",
            IsBlank(ts.S) <> IsBlank(ts.E), "Enter both Testing dates, or leave both empty.",
            bad <> "", "The end date is before the start date for " & bad & ".",
            outY <> "", "These periods are outside the " & y.YearName & " school year (" & Text(y.S, "m/d/yyyy") & " to " & Text(y.E, "m/d/yyyy") & "): " & outY & ".",
            q2.S <= q1.E || q3.S <= q2.E || q4.S <= q3.E || es.S <= q4.E, "Periods must be in order without overlap: Q1, Q2, Q3, Q4, then ESY.",
            q2.S <> nx1, "Q2 must start on the next school day after Q1 ends: " & Text(nx1, "ddd m/d/yyyy") & ".",
            q3.S <> nx2, "Q3 must start on the next school day after Q2 ends: " & Text(nx2, "ddd m/d/yyyy") & ".",
            q4.S <> nx3, "Q4 must start on the next school day after Q3 ends: " & Text(nx3, "ddd m/d/yyyy") & ".",
            !IsBlank(ts.S) && (ts.S < q1.S || ts.E > q4.E), "Testing must be inside Q1 start to Q4 end (" & Text(q1.S, "m/d/yyyy") & " to " & Text(q4.E, "m/d/yyyy") & ").",
            chg = 0, "No changes to save.",
            "Ready: saves " & chg & " period(s) for " & LookUp(colCalCampusOpts, CampusId = varCalCampusId).CampusName & " " & y.YearName & "."
        )
    )
)
```

S-PER `btnCalSavePer.OnSelect`:
```
=With(
    {y: LookUp(colCalYearOpts, YearId = varCalYearId), c0: varCalCampusId, cc: LookUp(colCalCampusOpts, CampusId = varCalCampusId)},
    If(
        !IsAdminRole || varCalSaving || !StartsWith(lblCalPerCheck.Text, "Ready"),
        Set(varCalReceipt, {Kind: "Blocked", Title: "Not saved. " & lblCalPerCheck.Text}); Clear(colCalReceiptLines),
        Set(varCalSaving, true);
        Clear(colCalLog);
        With(
            {yrRec: With({q: y.YearId}, LookUp('School Years', ThisRecord.'School Year' = q)), cRec: With({q: c0}, LookUp(Campuses, ThisRecord.Campus = q))},
            ForAll(
                Filter(colCalPerEdit, !IsBlank(S) && !IsBlank(E)) As p,
                With(
                    {ch: Switch(p.TermText, "Q1", 'Term (Terms)'.Q1, "Q2", 'Term (Terms)'.Q2, "Q3", 'Term (Terms)'.Q3, "Q4", 'Term (Terms)'.Q4, "ESY", 'Term (Terms)'.ESY, "Testing", 'Term (Terms)'.Testing), nmT: y.YearName & " " & p.TermText & " (" & cc.Code & ")"},
                    With(
                        {ex: With({q: y.YearId, qc: c0, qt: ch}, LookUp(Terms, 'School Year'.'School Year' = q && Campus.Campus = qc && 'Term (aaca_term)' = qt))},
                        If(
                            !IsBlank(ex) && ex.'Start Date' = p.S && ex.'End Date' = p.E && ex.Name = nmT,
                            Collect(colCalLog, {Key: p.TermText, Outcome: "unchanged", Detail: Text(ex.'Start Date', "m/d/yyyy") & " to " & Text(ex.'End Date', "m/d/yyyy") & " · " & ex.Name, Id: ex.'Term (aaca_termid)'}),
                            With(
                                {before: If(IsBlank(ex), "", Text(ex.'Start Date', "m/d/yyyy") & " to " & Text(ex.'End Date', "m/d/yyyy"))},
                                With(
                                    {wr: If(IsBlank(ex), IfError(Patch(Terms, Defaults(Terms), {Name: nmT, 'School Year': yrRec, Campus: cRec, 'Term (aaca_term)': ch, 'Start Date': p.S, 'End Date': p.E}), Blank()), IfError(Patch(Terms, ex, {Name: nmT, 'Start Date': p.S, 'End Date': p.E}), Blank()))},
                                    Collect(colCalLog, {Key: p.TermText, Outcome: If(IsBlank(wr), "failed", IsBlank(ex), "created", "updated"), Detail: If(IsBlank(wr), "not saved: " & Coalesce(First(Errors(Terms)).Message, "unknown error"), Text(wr.'Start Date', "m/d/yyyy") & " to " & Text(wr.'End Date', "m/d/yyyy") & " · " & wr.Name & If(IsBlank(ex), " (new campus row)", " (was " & before & ")")), Id: If(IsBlank(wr), ZeroGuid, wr.'Term (aaca_termid)')})
                                )
                            )
                        )
                    )
                )
            )
        );
        With(
            {cr: CountRows(Filter(colCalLog, Outcome = "created")), up: CountRows(Filter(colCalLog, Outcome = "updated")), un: CountRows(Filter(colCalLog, Outcome = "unchanged")), fl: CountRows(Filter(colCalLog, Outcome = "failed"))},
            With(
                {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Calendar periods " & cc.Code & " " & y.YearName, 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_term", 'Entity ID': Text(c0), Before: "", After: JSON({YearId: Text(y.YearId), Year: y.YearName, Campus: cc.CampusName, Periods: Concat(colCalLog, Key & " " & Outcome & " " & Detail, "; "), Created: cr, Updated: up, Unchanged: un, Failed: fl}), Reason: "Periods saved on the Calendar screen"}), Blank())},
                Set(varCalReceipt, {Kind: If(cr + up + un = 0, "Failed", fl > 0, "Partial", "Saved"), Title: "Periods saved · " & cc.CampusName & " " & y.YearName & " · " & cr & " created, " & up & " updated, " & un & " unchanged, " & fl & " failed"});
                ClearCollect(
                    colCalReceiptLines,
                    {Label: "Operation", Value: "Save periods"},
                    {Label: "Campus / year", Value: cc.CampusName & " · " & y.YearName},
                    ForAll(colCalLog As g, {Label: g.Key, Value: Switch(g.Outcome, "created", "Created", "updated", "Updated", "unchanged", "Unchanged", "FAILED") & " · " & g.Detail}),
                    {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Update written")}
                );
                Select(btnCalLoadEngine)
            )
        );
        Set(varCalSaving, false)
    )
)
```

#### `conCalNewPanel` (Visible `=varCalPanel = "New year"`)
Height `=32 + 144 + 4 + 18 + 4 + 36 + 4 + 58 + 4 + 52 + 4 + 88 + 4 + 44` (= 496).

| # | Control | Key properties | Height |
| - | ------- | -------------- | ------ |
| 1 | lblCalNewHelp | 12 ink, VerticalAlign Top, Text `="Creates the next school year (Planned) and copies the calendar shown above into it, moved forward 364 days so weekdays match. Federal holidays (Labor Day, Veterans Day, Thanksgiving, MLK Day, Presidents Day, Memorial Day, Juneteenth, Independence Day) are recalculated instead of copied. Review and adjust the new calendar afterwards."` | 144 |
| 2 | lblCalNewName | `="New school year name * (YYYY-YYYY)"` | 18 |
| 3 | txtCalNewName | AccessibleLabel `="New school year name"`, MaxLength 9, Placeholder `="2027-2028"`, Default `=With({y: LookUp(colCalYearOpts, YearId = varCalYearId)}, If(IsBlank(y), "", Text(Year(y.S) + 1) & "-" & Text(Year(y.S) + 2)))` | 36 |
| 4 | conCalNewDates | horizontal, gap 8, Start, FillPortions 0: `conCalNewStartField` (vertical, gap 4, Width 156: `lblCalNewStart` `="Start date *"`, `dpCalNewStart` AccessibleLabel `="New school year start date"`, Format Short, Height 36, DefaultDate `=DateAdd(LookUp(colCalYearOpts, YearId = varCalYearId).S, 1, TimeUnit.Years)`); `conCalNewEndField` (same: `lblCalNewEnd` `="End date *"`, `dpCalNewEnd` AccessibleLabel `="New school year end date"`, DefaultDate `=DateAdd(LookUp(colCalYearOpts, YearId = varCalYearId).E, 1, TimeUnit.Years)`) | 58 |
| 5 | chkCalNewAll | ModernCheckbox, Color ink, Default false, Label `="Create it for all campuses (each starts from this campus's calendar)"`, AccessibleLabel `=Self.Label` | 52 |
| 6 | lblCalNewCheck | 12, VerticalAlign Top, Color as lblCalDayCheck, Text C-NEW | 88 |
| 7 | btnCalCreate | Primary, Text `="Create school year"`, Width 180, AlignInContainer Start, DisplayMode `=If(IsAdminRole && !varCalSaving && !varCalLoading && StartsWith(lblCalNewCheck.Text, "Ready"), DisplayMode.Edit, DisplayMode.Disabled)`, OnSelect (block): `=If(IsAdminRole && !varCalSaving && StartsWith(lblCalNewCheck.Text, "Ready"), Select(btnCalCreateEngine), Set(varCalReceipt, {Kind: "Blocked", Title: "Not created. " & lblCalNewCheck.Text}); Clear(colCalReceiptLines))` | 44 |

C-NEW `lblCalNewCheck.Text`:
```
=With(
    {nm: Trim(txtCalNewName.Text), s: dpCalNewStart.SelectedDate, e: dpCalNewEnd.SelectedDate, y: LookUp(colCalYearOpts, YearId = varCalYearId), src: LookUp(colCalCampusOpts, CampusId = varCalCampusId)},
    With(
        {ex: LookUp(colCalYearOpts, YearName = nm)},
        If(
            !IsAdminRole, "Only System Admins can create school years.",
            varCalLoading, "Loading the calendar...",
            IsBlank(y), "Choose the school year to use as the template.",
            CountRows(Filter(colCalTermsEff, Has)) = 0, "The shown calendar has no periods to copy. Enter them on the Periods tab first.",
            !IsMatch(nm, "\d{4}-\d{4}"), "Enter the name as YYYY-YYYY, for example 2027-2028.",
            Value(Right(nm, 4)) <> Value(Left(nm, 4)) + 1, "The second year must follow the first, for example 2027-2028.",
            !IsBlank(ex) && ex.YearId = y.YearId, "That is the year shown. Enter the new year.",
            IsBlank(s) || IsBlank(e), "Choose the start and end dates.",
            e <= s, "The end date must be after the start date.",
            Year(s) <> Value(Left(nm, 4)), "The start date should be in " & Left(nm, 4) & ".",
            !IsBlank(ex) && (ex.S <> s || ex.E <> e), nm & " already exists (" & Text(ex.S, "m/d/yyyy") & " to " & Text(ex.E, "m/d/yyyy") & "). Use the same dates to add calendars to it.",
            "Ready: " & If(IsBlank(ex), "creates " & nm & " (Planned) and copies ", "copies ") & "the " & src.CampusName & " " & y.YearName & " calendar into it for " & If(chkCalNewAll.Checked, "all campuses", src.CampusName) & ". Campuses that already have rows in " & nm & " are skipped."
        )
    )
)
```

#### `conCalCopyPanel` (Visible `=varCalPanel = "Copy"`)
Height `=32 + 54 + 4 + 18 + 4 + 36 + 4 + 128 + 4 + 52 + 4 + 54 + 4 + 44` (= 442).

| # | Control | Key properties | Height |
| - | ------- | -------------- | ------ |
| 1 | lblCalCopyHelp | 12 ink, VerticalAlign Top, Text `="Replaces another campus's periods and days for the shown school year with the ones shown here. Days in that campus's locked months are kept as they are."` | 54 |
| 2 | lblCalCopyTarget | `="Campus to replace *"` | 18 |
| 3 | ddCalCopyTarget | ModernDropdown, AccessibleLabel `="Campus to replace"`, Items `=Filter(colCalCampusOpts, CampusId <> varCalCampusId)`, ItemDisplayText `=ThisItem.CampusName`, Default `=LookUp(colCalCampusOpts, CampusId = varCalCopyTargetId)`, OnChange `=Set(varCalCopyTargetId, Self.Selected.CampusId); Reset(chkCalCopyConfirm)` | 36 |
| 4 | lblCalCopyPreview | 12 ink, VerticalAlign Top, Text C-COPYPREV | 128 |
| 5 | chkCalCopyConfirm | ModernCheckbox, Color ink, Default false, Label `="I understand that the calendar at the chosen campus is replaced for this school year."`, AccessibleLabel `=Self.Label` | 52 |
| 6 | lblCalCopyCheck | 12, VerticalAlign Top, Color as lblCalDayCheck, Text C-COPY | 54 |
| 7 | btnCalCopy | Destructive (`BasePaletteColor: =ColorUnexcused`, `Color: =ColorWhite`), Text `="Replace calendar"`, Width 170, AlignInContainer Start, DisplayMode `=If(IsAdminRole && !varCalSaving && !varCalLoading && StartsWith(lblCalCopyCheck.Text, "Ready"), DisplayMode.Edit, DisplayMode.Disabled)`, OnSelect (block): `=If(IsAdminRole && !varCalSaving && StartsWith(lblCalCopyCheck.Text, "Ready"), Select(btnCalCopyEngine), Set(varCalReceipt, {Kind: "Blocked", Title: "Not copied. " & lblCalCopyCheck.Text}); Clear(colCalReceiptLines))` | 44 |

C-COPYPREV `lblCalCopyPreview.Text`:
```
=With(
    {tg: LookUp(colCalCampusOpts, CampusId = varCalCopyTargetId), y: LookUp(colCalYearOpts, YearId = varCalYearId), src: LookUp(colCalCampusOpts, CampusId = varCalCampusId)},
    If(
        IsBlank(tg), "Choose the campus whose calendar will be replaced.",
        With(
            {lockedTg: Filter(colCalLocksAll, CampusId = tg.CampusId)},
            With(
                {
                    rt: CountRows(Filter(colCalTermsAll, CampusId = tg.CampusId)),
                    rx: CountRows(Filter(colCalExcAll, CampusId = tg.CampusId && !(Date(Year(D), Month(D), 1) in lockedTg.MonthStart))),
                    at: CountRows(Filter(colCalTermsEff, Has)),
                    ax: CountRows(Filter(colCalExcEff, !(Date(Year(D), Month(D), 1) in lockedTg.MonthStart))),
                    kept: Concat(Filter(colCalMonths, MonthStart in lockedTg.MonthStart), Title, ", ")
                },
                "Replaces the " & y.YearName & " calendar at " & tg.CampusName & " with the one shown for " & src.CampusName & ". Removes " & rt & " period row(s) and " & rx & " day row(s) at " & tg.CampusName & ", then adds " & at & " period(s) and " & ax & " day(s)." & If(kept <> "", " Locked months stay as they are: " & kept & ".", "") & " All-campus rows are not changed."
            )
        )
    )
)
```

C-COPY `lblCalCopyCheck.Text`:
```
=With(
    {tg: LookUp(colCalCampusOpts, CampusId = varCalCopyTargetId)},
    If(
        !IsAdminRole, "Only System Admins can copy calendars.",
        varCalLoading, "Loading the calendar...",
        IsBlank(tg), "Choose the campus to replace.",
        tg.CampusId = varCalCampusId, "Choose a different campus.",
        CountRows(Filter(colCalTermsEff, Has)) = 0, "The shown calendar has no periods to copy.",
        !chkCalCopyConfirm.Checked, "Tick the confirmation to replace the calendar at " & tg.CampusName & ".",
        "Ready: replaces the calendar at " & tg.CampusName & "."
    )
)
```

## Engines (Classic/Button: AlignInContainer Stretch, AutoDisableOnSelect `=false`, LayoutMinHeight/Width 0, Visible `=false`, Text = short name)

### E1 `btnCalLoadEngine.OnSelect` (Text "load")
```
=Set(varCalLoading, true);
Set(varCalLoadError, "");
With(
    {y: LookUp(colCalYearOpts, YearId = varCalYearId)},
    If(
        !IsAdminRole || IsBlank(y) || varCalCampusId = ZeroGuid,
        Clear(colCalTermsAll); Clear(colCalExcAll); Clear(colCalLocksAll),
        With(
            {y0: y.YearId, d0: y.S, d1: y.E},
            IfError(
                Concurrent(
                    ClearCollect(colCalTermsAll, ForAll(Filter(Terms, 'School Year'.'School Year' = y0) As tr, {TermId: tr.'Term (aaca_termid)', TermText: Text(tr.'Term (aaca_term)'), S: tr.'Start Date', E: tr.'End Date', CampusId: If(IsBlank(tr.Campus), ZeroGuid, tr.Campus.Campus), Name: tr.Name})),
                    ClearCollect(colCalExcAll, ForAll(Filter('Calendar Exceptions', Date >= d0 && Date <= d1) As x, {ExcId: x.'Calendar Exception', D: x.Date, Label: Coalesce(x.Description, ""), TypeText: Text(x.Type), CampusId: If(IsBlank(x.Campus), ZeroGuid, x.Campus.Campus)})),
                    ClearCollect(colCalLocksAll, ForAll(Filter('Month Locks', 'Status (aaca_status)' = 'Status (Month Locks)'.Locked) As m, {CampusId: m.Campus.Campus, MonthStart: m.Month}))
                ); true,
                Set(varCalLoadError, FirstError.Message)
            )
        )
    )
);
Set(varCalLoading, false);
Select(btnCalBuildEngine)
```

### E2 `btnCalBuildEngine.OnSelect` (Text "build") - all in memory, no Dataverse calls
```
=With(
    {y: LookUp(colCalYearOpts, YearId = varCalYearId), c0: varCalCampusId, cd: Filter(colCalExcAll, CampusId = varCalCampusId).D},
    If(
        IsBlank(y),
        Clear(colCalTermsEff); Clear(colCalExcEff); Clear(colCalYearDays); Clear(colCalMonths); Clear(colCalCells); Clear(colCalImportant); Clear(colCalPerEdit),
        ClearCollect(
            colCalTermsEff,
            ForAll(
                ["Q1", "Q2", "Q3", "Q4", "ESY", "Testing"] As k,
                With(
                    {rc: LookUp(colCalTermsAll, TermText = k.Value && CampusId = c0), ra: LookUp(colCalTermsAll, TermText = k.Value && CampusId = ZeroGuid)},
                    With({r: If(IsBlank(rc), ra, rc)}, {TermText: k.Value, S: r.S, E: r.E, TermId: r.TermId, IsCampus: !IsBlank(rc), Has: !IsBlank(r)})
                )
            )
        );
        ClearCollect(
            colCalExcEff,
            ForAll(Filter(colCalExcAll, CampusId = c0) As x, {ExcId: x.ExcId, D: x.D, Label: x.Label, TypeText: x.TypeText, IsCampus: true}),
            ForAll(Filter(colCalExcAll, CampusId = ZeroGuid && !(D in cd)) As x, {ExcId: x.ExcId, D: x.D, Label: x.Label, TypeText: x.TypeText, IsCampus: false})
        );
        ClearCollect(
            colCalYearDays,
            ForAll(
                Sequence(DateDiff(y.S, y.E, TimeUnit.Days) + 1, 0) As k,
                With(
                    {d: DateAdd(y.S, k.Value, TimeUnit.Days)},
                    With({ty: LookUp(colCalExcEff, D = d).TypeText}, {D: d, Open: If(ty = "Make-up School Day", true, Weekday(d, StartOfWeek.Monday) <= 5 && !(ty in ["Holiday", "Break", "Closed", "Inclement Weather", "Work Only"]))})
                )
            )
        );
        ClearCollect(
            colCalMonths,
            ForAll(
                Sequence(12) As k,
                With(
                    {ms: DateAdd(Date(Year(y.S), Month(y.S), 1), k.Value - 1, TimeUnit.Months)},
                    {MonthKey: k.Value, MonthStart: ms, Title: Text(ms, "mmmm yyyy"), Locked: !IsBlank(LookUp(colCalLocksAll, CampusId = c0 && MonthStart = ms))}
                )
            )
        );
        With(
            {
                q1: LookUp(colCalTermsEff, TermText = "Q1"), q2: LookUp(colCalTermsEff, TermText = "Q2"), q3: LookUp(colCalTermsEff, TermText = "Q3"),
                q4: LookUp(colCalTermsEff, TermText = "Q4"), es: LookUp(colCalTermsEff, TermText = "ESY"), ts: LookUp(colCalTermsEff, TermText = "Testing"),
                m0: Date(Year(y.S), Month(y.S), 1),
                sdd: Sort(Filter(colCalExcEff, TypeText = "Work Only"), D, SortOrder.Ascending)
            },
            ClearCollect(
                colCalCells,
                ForAll(
                    Sequence(588, 0) As k,
                    With(
                        {mk: RoundDown(k.Value / 49, 0) + 1, ix: Mod(k.Value, 49)},
                        With(
                            {ms: DateAdd(m0, mk - 1, TimeUnit.Months)},
                            With(
                                {d: DateAdd(ms, ix - 7 - (Weekday(ms, StartOfWeek.Sunday) - 1), TimeUnit.Days)},
                                With(
                                    {inM: ix >= 7 && Month(d) = Month(ms), ex: LookUp(colCalExcEff, D = d), inQ: !IsBlank(LookUp(colCalTermsEff, Has && TermText <> "Testing" && S <= d && E >= d))},
                                    With(
                                        {kd: If(ix < 7, "hdr", !inM, "out", ex.TypeText in ["Holiday", "Break", "Closed"], "noschool", ex.TypeText = "Work Only", "sdd", ex.TypeText = "Inclement Weather", "weather", ex.TypeText = "Make-up School Day", "makeup", d = q1.S || d = q4.E, "rsy", d = es.S || d = es.E, "esy", d = ts.S || d = ts.E, "test", Weekday(d, StartOfWeek.Monday) > 5, "weekend", inQ, "school", "nonterm")},
                                        {
                                            MonthKey: mk, Idx: ix, D: d, IsHdr: ix < 7, InMonth: inM,
                                            Txt: If(ix < 7, Mid("SMTWTFS", ix + 1, 1), inM, Text(Day(d)), ""),
                                            Kind: kd,
                                            Label: If(inM, Coalesce(ex.Label, ""), ""),
                                            Tip: If(!inM, "", Text(d, "dddd mmm d, yyyy") & " · " & Switch(kd, "noschool", "No school (" & ex.TypeText & ")", "sdd", "Staff Development", "weather", "Inclement Weather (closed)", "makeup", "Make-up School Day", "rsy", If(d = q1.S, "First Day RSY", "Last Day RSY"), "esy", If(d = es.S, "First Day ESY", "Last Day ESY"), "test", If(d = ts.S, "Testing starts", "Testing ends"), "weekend", "Weekend", "school", "School day", "Not in a quarter") & If(Coalesce(ex.Label, "") <> "", " · " & ex.Label, ""))
                                        }
                                    )
                                )
                            )
                        )
                    )
                )
            );
            ClearCollect(
                colCalExcFlag,
                ForAll(
                    Filter(colCalExcEff, TypeText <> "Work Only") As r,
                    {
                        D: r.D, Label: r.Label,
                        IsStart: IsBlank(LookUp(colCalExcEff, TypeText <> "Work Only" && Label = r.Label && D = DateAdd(r.D, If(Weekday(r.D, StartOfWeek.Monday) = 1, -3, -1), TimeUnit.Days))),
                        IsEnd: IsBlank(LookUp(colCalExcEff, TypeText <> "Work Only" && Label = r.Label && D = DateAdd(r.D, If(Weekday(r.D, StartOfWeek.Monday) = 5, 3, 1), TimeUnit.Days)))
                    }
                )
            );
            ClearCollect(
                colCalImportant,
                Filter(
                    Table(
                        {Sec: 1, SortD: Date(1900, 1, 1), IsHead: true, Line: "Important Dates", Keep: true},
                        {Sec: 1, SortD: q1.S, IsHead: false, Line: "First Day RSY - " & Text(q1.S, "m/d/yyyy"), Keep: q1.Has},
                        {Sec: 1, SortD: q4.E, IsHead: false, Line: "Last Day RSY - " & Text(q4.E, "m/d/yyyy"), Keep: q4.Has},
                        {Sec: 1, SortD: es.S, IsHead: false, Line: "First Day ESY - " & Text(es.S, "m/d/yyyy"), Keep: es.Has},
                        {Sec: 1, SortD: es.E, IsHead: false, Line: "Last Day ESY - " & Text(es.E, "m/d/yyyy"), Keep: es.Has},
                        {Sec: 2, SortD: Date(1900, 1, 1), IsHead: true, Line: "Staff Development Days", Keep: true},
                        {Sec: 2, SortD: Date(1900, 1, 2), IsHead: false, Line: "None entered", Keep: CountRows(sdd) = 0},
                        {Sec: 3, SortD: Date(1900, 1, 1), IsHead: true, Line: "Quarterly Periods", Keep: true},
                        {Sec: 3, SortD: q1.S, IsHead: false, Line: "Qtr.1: " & Text(q1.S, "mm/dd/yyyy") & " to " & Text(q1.E, "mm/dd/yyyy"), Keep: q1.Has},
                        {Sec: 3, SortD: q2.S, IsHead: false, Line: "Qtr.2: " & Text(q2.S, "mm/dd/yyyy") & " to " & Text(q2.E, "mm/dd/yyyy"), Keep: q2.Has},
                        {Sec: 3, SortD: q3.S, IsHead: false, Line: "Qtr.3: " & Text(q3.S, "mm/dd/yyyy") & " to " & Text(q3.E, "mm/dd/yyyy"), Keep: q3.Has},
                        {Sec: 3, SortD: q4.S, IsHead: false, Line: "Qtr.4: " & Text(q4.S, "mm/dd/yyyy") & " to " & Text(q4.E, "mm/dd/yyyy"), Keep: q4.Has},
                        {Sec: 4, SortD: Date(1900, 1, 1), IsHead: true, Line: "Testing Period", Keep: true},
                        {Sec: 4, SortD: Coalesce(ts.S, Date(1900, 1, 2)), IsHead: false, Line: If(ts.Has, Text(ts.S, "mm/dd/yyyy") & " to " & Text(ts.E, "mm/dd/yyyy"), "None entered"), Keep: true}
                    ),
                    Keep
                ),
                ForAll(
                    Filter(colCalExcFlag, IsStart) As s,
                    With({e: Min(Filter(colCalExcFlag, IsEnd && Label = s.Label && D >= s.D), D)}, {Sec: 1, SortD: s.D, IsHead: false, Line: s.Label & " - " & Text(s.D, "m/d/yyyy") & If(e > s.D, " - " & Text(e, "m/d/yyyy"), ""), Keep: true})
                ),
                ForAll(
                    Sequence(CountRows(sdd)) As n,
                    With({r: Index(sdd, n.Value)}, With({dd: Day(r.D)}, {Sec: 2, SortD: r.D, IsHead: false, Line: "SDD " & n.Value & ": " & Text(r.D, "mmmm") & " " & dd & If(dd in [11, 12, 13], "th", Mod(dd, 10) = 1, "st", Mod(dd, 10) = 2, "nd", Mod(dd, 10) = 3, "rd", "th") & ", " & Year(r.D), Keep: true}))
                )
            )
        );
        ClearCollect(colCalPerEdit, ForAll(Sequence(6) As n, With({tr: Index(colCalTermsEff, n.Value)}, {N: n.Value, TermText: tr.TermText, S: tr.S, E: tr.E})))
    );
    Select(btnCalCheckEngine)
)
```

### E3 `btnCalCheckEngine.OnSelect` (Text "check")
```
=Clear(colCalChecks);
With(
    {q1: LookUp(colCalTermsEff, TermText = "Q1"), q4: LookUp(colCalTermsEff, TermText = "Q4"), es: LookUp(colCalTermsEff, TermText = "ESY"), ts: LookUp(colCalTermsEff, TermText = "Testing")},
    ForAll(Filter(colCalTermsEff, !Has && TermText <> "Testing") As m, Collect(colCalChecks, {Sev: "error", Line: "Missing " & m.TermText & " for this campus."}));
    ForAll(
        Sequence(3) As n,
        With(
            {a: LookUp(colCalTermsEff, TermText = "Q" & n.Value), b: LookUp(colCalTermsEff, TermText = "Q" & (n.Value + 1))},
            If(
                a.Has && b.Has,
                With(
                    {nx: Min(Filter(colCalYearDays, Open && D > a.E), D)},
                    If(
                        b.S <= a.E,
                        Collect(colCalChecks, {Sev: "error", Line: "Q" & n.Value & " and Q" & (n.Value + 1) & " overlap: Q" & (n.Value + 1) & " starts " & Text(b.S, "m/d/yyyy") & " but Q" & n.Value & " ends " & Text(a.E, "m/d/yyyy") & "."}),
                        !IsBlank(nx) && b.S > nx,
                        Collect(colCalChecks, {Sev: "error", Line: "Gap between Q" & n.Value & " and Q" & (n.Value + 1) & ": school days " & Concat(Filter(colCalYearDays, Open && D >= nx && D < b.S), Text(D, "m/d/yyyy"), ", ") & " are in no quarter."})
                    )
                )
            )
        )
    );
    If(q4.Has && es.Has && es.S <= q4.E, Collect(colCalChecks, {Sev: "error", Line: "ESY starts " & Text(es.S, "m/d/yyyy") & ", before Q4 ends (" & Text(q4.E, "m/d/yyyy") & ")."}));
    If(ts.Has && q1.Has && q4.Has && (ts.S < q1.S || ts.E > q4.E), Collect(colCalChecks, {Sev: "warn", Line: "Testing " & Text(ts.S, "m/d/yyyy") & " to " & Text(ts.E, "m/d/yyyy") & " is outside Q1 start to Q4 end."}));
    ForAll(
        Filter(colCalExcEff, TypeText in ["Holiday", "Break", "Closed", "Inclement Weather", "Work Only"] && Weekday(D, StartOfWeek.Monday) > 5) As w,
        Collect(colCalChecks, {Sev: "warn", Line: If(w.TypeText = "Work Only", "Staff Development", w.TypeText) & " on a weekend: " & w.Label & " " & Text(w.D, "ddd m/d/yyyy") & "."})
    );
    If(
        varCalCheckWithAtt,
        ForAll(
            Filter(colCalExcEff, TypeText in ["Holiday", "Break", "Closed", "Inclement Weather", "Work Only"] && D <= Today()) As z,
            With(
                {nA: With({q: z.D, c0: varCalCampusId}, CountRows(Filter(Attendance, Campus.Campus = c0 && Date = q && 'Is Deleted' <> true)))},
                If(nA > 0, Collect(colCalChecks, {Sev: "warn", Line: Text(z.D, "ddd m/d/yyyy") & " (" & z.Label & ") is a no-school day but has " & nA & " attendance mark(s)."}))
            )
        )
    );
    If(CountRows(colCalChecks) = 0, Collect(colCalChecks, {Sev: "ok", Line: "All good. No problems found" & If(varCalCheckWithAtt, ", including attendance marks.", ". Press Check calendar to also look for attendance marks on no-school days.")}));
    Set(varCalCheckStamp, "Checked " & Text(Now(), "h:mm AM/PM") & If(varCalCheckWithAtt, " including attendance marks", " (calendar only)"));
    Set(varCalCheckWithAtt, false)
)
```

### E4 `btnCalCountEngine.OnSelect` (Text "count") - attendance marks for the selected range
```
=With(
    {f: varCalFrom, t: varCalTo, typ: rdoCalType.Selected.Value},
    With(
        {key: Text(f, "yyyy-mm-dd") & "|" & Text(t, "yyyy-mm-dd") & "|" & typ & "|" & Text(varCalCampusId) & Concat(Filter(colCalAlso, Ticked), "," & Text(CampusId))},
        Reset(chkCalConfirm);
        Reset(tabCalPanel);
        ClearCollect(
            colCalTargets,
            ForAll(Filter(colCalCampusOpts, CampusId = varCalCampusId) As c, {CampusId: c.CampusId, CampusName: c.CampusName, Code: c.Code}),
            ForAll(Filter(colCalAlso, Ticked) As a, {CampusId: a.CampusId, CampusName: a.CampusName, Code: LookUp(colCalCampusOpts, CampusId = a.CampusId).Code})
        );
        If(
            IsBlank(f) || IsBlank(t) || t < f || DateDiff(f, t, TimeUnit.Days) > 44 || !(typ in ["Holiday", "Break", "Closed", "Work Only", "Inclement Weather"]),
            Set(varCalDayAtt, {Key: key, N: 0}),
            Set(varCalDayAtt, {Key: key, N: Sum(ForAll(colCalTargets As c, With({c0: c.CampusId, f0: f, t0: t}, CountRows(Filter(Attendance, Campus.Campus = c0 && Date >= f0 && Date <= t0 && 'Is Deleted' <> true)))), Value)})
        )
    )
)
```

### E5 `btnCalCreateEngine.OnSelect` (Text "create") - called only by btnCalCreate when C-NEW is Ready
```
=With(
    {nm: Trim(txtCalNewName.Text), s: dpCalNewStart.SelectedDate, e: dpCalNewEnd.SelectedDate, allC: chkCalNewAll.Checked, y: LookUp(colCalYearOpts, YearId = varCalYearId), src: LookUp(colCalCampusOpts, CampusId = varCalCampusId)},
    Set(varCalSaving, true);
    Clear(colCalLog);
    With(
        {exY: With({q: nm}, LookUp('School Years', Name = q))},
        With(
            {yr: If(IsBlank(exY), IfError(Patch('School Years', Defaults('School Years'), {Name: nm, 'Start Date': s, 'End Date': e, 'Status (aaca_status)': 'Status (School Years)'.Planned}), Blank()), exY)},
            If(
                IsBlank(yr),
                Set(varCalReceipt, {Kind: "Failed", Title: "Not created · " & nm & " · " & Coalesce(First(Errors('School Years')).Message, "the school year could not be saved") & "."}); Clear(colCalReceiptLines),
                ClearCollect(colCalTargets, ForAll(Filter(colCalCampusOpts, allC || CampusId = varCalCampusId) As c, {CampusId: c.CampusId, CampusName: c.CampusName, Code: c.Code}));
                With(
                    {y1: Year(yr.'Start Date'), y2: Year(yr.'Start Date') + 1, ns: yr.'Start Date', ne: yr.'End Date'},
                    With(
                        {
                            lab: DateAdd(Date(y1, 9, 1), Mod(9 - Weekday(Date(y1, 9, 1)), 7), TimeUnit.Days),
                            vet: DateAdd(Date(y1, 11, 11), Switch(Weekday(Date(y1, 11, 11)), 7, -1, 1, 1, 0), TimeUnit.Days),
                            tg: DateAdd(Date(y1, 11, 1), Mod(12 - Weekday(Date(y1, 11, 1)), 7) + 21, TimeUnit.Days),
                            mlk: DateAdd(Date(y2, 1, 1), Mod(9 - Weekday(Date(y2, 1, 1)), 7) + 14, TimeUnit.Days),
                            pres: DateAdd(Date(y2, 2, 1), Mod(9 - Weekday(Date(y2, 2, 1)), 7) + 14, TimeUnit.Days),
                            mem: DateAdd(Date(y2, 5, 31), -Mod(Weekday(Date(y2, 5, 31)) + 5, 7), TimeUnit.Days),
                            jun: DateAdd(Date(y2, 6, 19), Switch(Weekday(Date(y2, 6, 19)), 7, -1, 1, 1, 0), TimeUnit.Days),
                            ind: DateAdd(Date(y2, 7, 4), Switch(Weekday(Date(y2, 7, 4)), 7, -1, 1, 1, 0), TimeUnit.Days)
                        },
                        ClearCollect(colCalFed, Filter(Table({D: lab, Label: "Labor Day"}, {D: vet, Label: "Veterans Day"}, {D: tg, Label: "Thanksgiving"}, {D: DateAdd(tg, 1, TimeUnit.Days), Label: "Thanksgiving"}, {D: mlk, Label: "Martin Luther King Jr. Day"}, {D: pres, Label: "Presidents Day"}, {D: mem, Label: "Memorial Day"}, {D: jun, Label: "Juneteenth"}, {D: ind, Label: "Independence Day"}), D >= ns && D <= ne))
                    )
                );
                ClearCollect(colCalTplTerms, ForAll(Filter(colCalTermsEff, Has) As tr, {TermText: tr.TermText, S: DateAdd(tr.S, 364, TimeUnit.Days), E: DateAdd(tr.E, 364, TimeUnit.Days)}));
                ClearCollect(colCalTplExc, Filter(ForAll(colCalExcEff As x, {D: DateAdd(x.D, 364, TimeUnit.Days), Label: x.Label, TypeText: x.TypeText, Fed: With({l: Lower(x.Label)}, "labor day" in l || "veteran" in l || "thanksgiving" in l || "martin luther" in l || "mlk" in l || "president" in l || "memorial" in l || "juneteenth" in l || "independence" in l)}), !Fed && D >= yr.'Start Date' && D <= yr.'End Date' && !(D in colCalFed.D)));
                ForAll(
                    colCalTargets As c,
                    With(
                        {
                            has: With({q: yr.'School Year', qc: c.CampusId}, CountRows(Filter(Terms, 'School Year'.'School Year' = q && Campus.Campus = qc))) + With({d0: yr.'Start Date', d1: yr.'End Date', qc: c.CampusId}, CountRows(Filter('Calendar Exceptions', Campus.Campus = qc && Date >= d0 && Date <= d1))),
                            cRec: With({q: c.CampusId}, LookUp(Campuses, ThisRecord.Campus = q))
                        },
                        If(
                            has > 0,
                            Collect(colCalLog, {Key: c.CampusName, Outcome: "skipped", Detail: "already has " & has & " calendar row(s) in " & yr.Name & "; use Copy to campus to replace them", Id: ZeroGuid}),
                            ForAll(colCalTplTerms As tp, With({wr: IfError(Patch(Terms, Defaults(Terms), {Name: yr.Name & " " & tp.TermText & " (" & c.Code & ")", 'School Year': yr, Campus: cRec, 'Term (aaca_term)': Switch(tp.TermText, "Q1", 'Term (Terms)'.Q1, "Q2", 'Term (Terms)'.Q2, "Q3", 'Term (Terms)'.Q3, "Q4", 'Term (Terms)'.Q4, "ESY", 'Term (Terms)'.ESY, "Testing", 'Term (Terms)'.Testing), 'Start Date': tp.S, 'End Date': tp.E}), Blank())}, Collect(colCalLog, {Key: c.CampusName & " · " & tp.TermText, Outcome: If(IsBlank(wr), "failed", "term"), Detail: If(IsBlank(wr), "period not created: " & Coalesce(First(Errors(Terms)).Message, "unknown error"), Text(wr.'Start Date', "m/d/yyyy") & " to " & Text(wr.'End Date', "m/d/yyyy") & " · " & wr.Name), Id: If(IsBlank(wr), ZeroGuid, wr.'Term (aaca_termid)')})));
                            ForAll(colCalTplExc As x, With({wr: IfError(Patch('Calendar Exceptions', Defaults('Calendar Exceptions'), {Description: x.Label, Date: x.D, Type: Switch(x.TypeText, "Holiday", 'Type (Calendar Exceptions)'.Holiday, "Break", 'Type (Calendar Exceptions)'.Break, "Closed", 'Type (Calendar Exceptions)'.Closed, "Work Only", 'Type (Calendar Exceptions)'.'Work Only', "Inclement Weather", 'Type (Calendar Exceptions)'.'Inclement Weather', "Make-up School Day", 'Type (Calendar Exceptions)'.'Make-up School Day'), Campus: cRec}), Blank())}, Collect(colCalLog, {Key: c.CampusName & " · " & Text(x.D, "m/d/yyyy"), Outcome: If(IsBlank(wr), "failed", "day"), Detail: If(IsBlank(wr), "day not created: " & Coalesce(First(Errors('Calendar Exceptions')).Message, "unknown error"), Text(wr.Type) & " · " & wr.Description), Id: If(IsBlank(wr), ZeroGuid, wr.'Calendar Exception')})));
                            ForAll(colCalFed As h, With({wr: IfError(Patch('Calendar Exceptions', Defaults('Calendar Exceptions'), {Description: h.Label, Date: h.D, Type: 'Type (Calendar Exceptions)'.Holiday, Campus: cRec}), Blank())}, Collect(colCalLog, {Key: c.CampusName & " · " & Text(h.D, "m/d/yyyy"), Outcome: If(IsBlank(wr), "failed", "holiday"), Detail: If(IsBlank(wr), "holiday not created: " & Coalesce(First(Errors('Calendar Exceptions')).Message, "unknown error"), wr.Description & " " & Text(wr.Date, "m/d/yyyy")), Id: If(IsBlank(wr), ZeroGuid, wr.'Calendar Exception')})))
                        )
                    )
                );
                With(
                    {
                        nT: CountRows(Filter(colCalLog, Outcome = "term")),
                        nD: CountRows(Filter(colCalLog, Outcome = "day")),
                        nH: CountRows(Filter(colCalLog, Outcome = "holiday")),
                        nS: CountRows(Filter(colCalLog, Outcome = "skipped")),
                        nF: CountRows(Filter(colCalLog, Outcome = "failed")),
                        notCopied: Concat(Distinct(Filter(ForAll(colCalExcEff As x, {L: x.Label, F: With({l: Lower(x.Label)}, "labor day" in l || "veteran" in l || "thanksgiving" in l || "martin luther" in l || "mlk" in l || "president" in l || "memorial" in l || "juneteenth" in l || "independence" in l)}), F), L), Value, ", ")
                    },
                    With(
                        {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("School year " & yr.Name & " calendar from " & src.Code & " " & y.YearName, 100), Action: 'Action (Audit Events)'.Rollover, Entity: "aaca_schoolyear", 'Entity ID': Text(yr.'School Year'), Before: "", After: JSON({Name: yr.Name, StartDate: Text(yr.'Start Date', "yyyy-mm-dd"), EndDate: Text(yr.'End Date', "yyyy-mm-dd"), Status: Text(yr.'Status (aaca_status)'), YearCreated: IsBlank(exY), TemplateYear: y.YearName, TemplateCampus: src.CampusName, Campuses: Concat(colCalTargets, CampusName, ", "), Periods: nT, Days: nD, Holidays: nH, Skipped: nS, Failed: nF}), Reason: "Created on the Calendar screen"}), Blank())},
                        Set(varCalReceipt, {Kind: If(nT + nD + nH = 0, If(nS > 0, "Blocked", "Failed"), nF > 0 || nS > 0, "Partial", "Created"), Title: "School year " & yr.Name & If(IsBlank(exY), " created", " already existed") & " · " & nT & " periods, " & nD & " days copied, " & nH & " holidays added" & If(nS > 0, " · " & nS & " campus(es) skipped", "") & If(nF > 0, " · " & nF & " failed", "")});
                        ClearCollect(
                            colCalReceiptLines,
                            {Label: "Operation", Value: "Create school year"},
                            {Label: "School year", Value: yr.Name & " · " & Text(yr.'Start Date', "m/d/yyyy") & " to " & Text(yr.'End Date', "m/d/yyyy") & " · " & Text(yr.'Status (aaca_status)') & If(IsBlank(exY), " · created", " · already existed")},
                            {Label: "Template", Value: src.CampusName & " " & y.YearName & ", dates moved 364 days (same weekday)"},
                            {Label: "Campuses", Value: Concat(colCalTargets, CampusName, ", ")},
                            {Label: "Periods / days / holidays", Value: nT & " / " & nD & " / " & nH},
                            {Label: "Federal holidays", Value: Concat(colCalFed, Label & " " & Text(D, "m/d/yyyy"), "; ")},
                            {Label: "Not copied (recalculated)", Value: If(notCopied = "", "None", notCopied)},
                            {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Rollover written")},
                            ForAll(Filter(colCalLog, Outcome in ["skipped", "failed"]) As g, {Label: g.Key, Value: If(g.Outcome = "skipped", "Skipped · ", "FAILED · ") & g.Detail})
                        );
                        ClearCollect(colCalYearOpts, ForAll(Sort('School Years', 'Start Date', SortOrder.Descending) As yy, {YearId: yy.'School Year', YearName: yy.Name, S: yy.'Start Date', E: yy.'End Date', StatusText: Text(yy.'Status (aaca_status)')}));
                        If(
                            nT + nD + nH > 0,
                            Set(varCalYearId, yr.'School Year');
                            Reset(ddCalYear);
                            Set(varCalFrom, Blank());
                            Set(varCalTo, Blank());
                            Set(varCalPickTo, false);
                            Set(varCalPanel, "Days");
                            Reset(tabCalPanel);
                            Select(btnCalLoadEngine)
                        )
                    )
                )
            )
        )
    );
    Set(varCalSaving, false)
)
```

### E6 `btnCalCopyEngine.OnSelect` (Text "copy") - called only by btnCalCopy when C-COPY is Ready
Add first, then remove the old rows only if every add succeeded; otherwise remove the new rows (rollback).
```
=With(
    {tg: LookUp(colCalCampusOpts, CampusId = varCalCopyTargetId), y: LookUp(colCalYearOpts, YearId = varCalYearId), src: LookUp(colCalCampusOpts, CampusId = varCalCampusId)},
    With(
        {lockedTg: Filter(colCalLocksAll, CampusId = tg.CampusId), y0: y.YearId, d0: y.S, d1: y.E, qc: tg.CampusId},
        With(
            {yrRec: With({q: y0}, LookUp('School Years', ThisRecord.'School Year' = q)), cRec: With({q: qc}, LookUp(Campuses, ThisRecord.Campus = q))},
            Set(varCalSaving, true);
            Clear(colCalLog);
            ClearCollect(
                colCalCopyOld,
                ForAll(Filter(Terms, 'School Year'.'School Year' = y0 && Campus.Campus = qc) As r, {Kind: "term", Id: r.'Term (aaca_termid)', Txt: Text(r.'Term (aaca_term)') & " " & Text(r.'Start Date', "m/d/yyyy") & " to " & Text(r.'End Date', "m/d/yyyy"), Ms: Date(1900, 1, 1)}),
                ForAll(Filter('Calendar Exceptions', Campus.Campus = qc && Date >= d0 && Date <= d1) As x, {Kind: "day", Id: x.'Calendar Exception', Txt: Text(x.Date, "m/d/yyyy") & " " & Text(x.Type) & " " & x.Description, Ms: Date(Year(x.Date), Month(x.Date), 1)})
            );
            ForAll(Filter(colCalTermsEff, Has) As tr, With({wr: IfError(Patch(Terms, Defaults(Terms), {Name: y.YearName & " " & tr.TermText & " (" & tg.Code & ")", 'School Year': yrRec, Campus: cRec, 'Term (aaca_term)': Switch(tr.TermText, "Q1", 'Term (Terms)'.Q1, "Q2", 'Term (Terms)'.Q2, "Q3", 'Term (Terms)'.Q3, "Q4", 'Term (Terms)'.Q4, "ESY", 'Term (Terms)'.ESY, "Testing", 'Term (Terms)'.Testing), 'Start Date': tr.S, 'End Date': tr.E}), Blank())}, Collect(colCalLog, {Key: tg.CampusName & " · " & tr.TermText, Outcome: If(IsBlank(wr), "failed", "term-added"), Detail: If(IsBlank(wr), "period not added: " & Coalesce(First(Errors(Terms)).Message, "unknown error"), Text(wr.'Start Date', "m/d/yyyy") & " to " & Text(wr.'End Date', "m/d/yyyy") & " · " & wr.Name), Id: If(IsBlank(wr), ZeroGuid, wr.'Term (aaca_termid)')})));
            ForAll(Filter(colCalExcEff, !(Date(Year(D), Month(D), 1) in lockedTg.MonthStart)) As x, With({wr: IfError(Patch('Calendar Exceptions', Defaults('Calendar Exceptions'), {Description: x.Label, Date: x.D, Type: Switch(x.TypeText, "Holiday", 'Type (Calendar Exceptions)'.Holiday, "Break", 'Type (Calendar Exceptions)'.Break, "Closed", 'Type (Calendar Exceptions)'.Closed, "Work Only", 'Type (Calendar Exceptions)'.'Work Only', "Inclement Weather", 'Type (Calendar Exceptions)'.'Inclement Weather', "Make-up School Day", 'Type (Calendar Exceptions)'.'Make-up School Day'), Campus: cRec}), Blank())}, Collect(colCalLog, {Key: tg.CampusName & " · " & Text(x.D, "m/d/yyyy"), Outcome: If(IsBlank(wr), "failed", "day-added"), Detail: If(IsBlank(wr), "day not added: " & Coalesce(First(Errors('Calendar Exceptions')).Message, "unknown error"), Text(wr.Type) & " · " & wr.Description), Id: If(IsBlank(wr), ZeroGuid, wr.'Calendar Exception')})));
            If(
                CountRows(Filter(colCalLog, Outcome = "failed")) = 0,
                ForAll(
                    Filter(colCalCopyOld, !(Ms in lockedTg.MonthStart)) As o,
                    If(
                        o.Kind = "term",
                        With({row: With({q: o.Id}, LookUp(Terms, ThisRecord.'Term (aaca_termid)' = q))}, With({ok: If(IsBlank(row), true, IfError(Remove(Terms, row); true, false))}, Collect(colCalLog, {Key: tg.CampusName & " · old period", Outcome: If(ok, "removed", "remove-failed"), Detail: o.Txt, Id: o.Id}))),
                        With({row: With({q: o.Id}, LookUp('Calendar Exceptions', ThisRecord.'Calendar Exception' = q))}, With({ok: If(IsBlank(row), true, IfError(Remove('Calendar Exceptions', row); true, false))}, Collect(colCalLog, {Key: tg.CampusName & " · old day", Outcome: If(ok, "removed", "remove-failed"), Detail: o.Txt, Id: o.Id})))
                    )
                ),
                ClearCollect(colCalCopyNew, Filter(colCalLog, Outcome in ["term-added", "day-added"]));
                ForAll(
                    colCalCopyNew As nw,
                    If(
                        nw.Outcome = "term-added",
                        With({row: With({q: nw.Id}, LookUp(Terms, ThisRecord.'Term (aaca_termid)' = q))}, With({ok: If(IsBlank(row), true, IfError(Remove(Terms, row); true, false))}, Collect(colCalLog, {Key: nw.Key, Outcome: If(ok, "rolled-back", "rollback-failed"), Detail: nw.Detail, Id: nw.Id}))),
                        With({row: With({q: nw.Id}, LookUp('Calendar Exceptions', ThisRecord.'Calendar Exception' = q))}, With({ok: If(IsBlank(row), true, IfError(Remove('Calendar Exceptions', row); true, false))}, Collect(colCalLog, {Key: nw.Key, Outcome: If(ok, "rolled-back", "rollback-failed"), Detail: nw.Detail, Id: nw.Id})))
                    )
                )
            );
            With(
                {
                    aT: CountRows(Filter(colCalLog, Outcome = "term-added")),
                    aD: CountRows(Filter(colCalLog, Outcome = "day-added")),
                    rm: CountRows(Filter(colCalLog, Outcome = "removed")),
                    rf: CountRows(Filter(colCalLog, Outcome = "remove-failed")),
                    fl: CountRows(Filter(colCalLog, Outcome = "failed")),
                    rb: CountRows(Filter(colCalLog, Outcome = "rolled-back")),
                    kept: CountRows(Filter(colCalCopyOld, Ms in lockedTg.MonthStart))
                },
                With(
                    {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Calendar copied " & src.Code & " to " & tg.Code & " " & y.YearName, 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_calendarexception", 'Entity ID': Text(tg.CampusId), Before: JSON({Rows: Left(Concat(colCalCopyOld, Txt, "; "), 3000)}), After: JSON({YearId: Text(y0), FromCampus: src.CampusName, ToCampus: tg.CampusName, PeriodsAdded: aT, DaysAdded: aD, OldRowsRemoved: rm, RemoveFailed: rf, Failed: fl, RolledBack: rb, KeptLockedRows: kept}), Reason: "Copy to campus on the Calendar screen"}), Blank())},
                    Set(varCalReceipt, {Kind: If(fl > 0, "Failed", rf > 0, "Partial", "Copied"), Title: If(fl > 0, "Not copied · " & fl & " row(s) could not be added; the new rows were removed and " & tg.CampusName & " keeps its calendar", "Copied · " & src.CampusName & " " & y.YearName & " to " & tg.CampusName & " · " & aT & " periods and " & aD & " days added, " & rm & " old rows removed" & If(rf > 0, ", " & rf & " old rows could not be removed", ""))});
                    ClearCollect(
                        colCalReceiptLines,
                        {Label: "Operation", Value: "Copy to campus"},
                        {Label: "School year", Value: y.YearName},
                        {Label: "From / to", Value: src.CampusName & " to " & tg.CampusName},
                        {Label: "Periods added", Value: Text(aT)},
                        {Label: "Days added", Value: Text(aD)},
                        {Label: "Old rows removed", Value: rm & If(rf > 0, " (" & rf & " could not be removed)", "")},
                        {Label: "Locked months kept", Value: If(kept = 0, "None", kept & " row(s) in locked months left as they were")},
                        {Label: "Failed / rolled back", Value: fl & " / " & rb},
                        {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Update written")},
                        ForAll(Filter(colCalLog, Outcome in ["term-added", "failed", "remove-failed", "rollback-failed"]) As g, {Label: g.Key, Value: Switch(g.Outcome, "term-added", "Period added", "failed", "FAILED", "remove-failed", "Old row NOT removed", "Rollback FAILED") & " · " & g.Detail})
                    );
                    Set(varCalCopyTargetId, Blank());
                    Reset(ddCalCopyTarget);
                    Reset(chkCalCopyConfirm);
                    Select(btnCalLoadEngine)
                )
            );
            Set(varCalSaving, false)
        )
    )
)
```

## Numeric layout budgets

- Nav: shared table (one row at root >= 800; two rows 96 at 640-799; three rows 148 on phone).
- Header bar: field groups 272 + 8 + 264 + 8 + View 140 = 692; + 32 padding = 724 <= 728 (one row, 60). 576-727:
  row 1 = 544 <= inner 544, row 2 = button: 8+44+8+44+8 = 112. Phone 343: three rows 8+44*3+8*2+8 = 164.
- Header heights: desktop 12+28+4+20+4+52+4+60 = 184 = 76+48+60; band 640-799 with bar 112: 12+28+4+20+4+104+4+112
  = 288 = 76+100+112; phone 12+28+4+36+4+156+4+164 = 408 = 92+152+164; office (bar hidden, PaddingBottom 12):
  12+28+4+20+4+44+12 = 124 = 76+48.
- View: body padding 8+8. Root 1366: view 1350 = main 962 + 8 + side 380. Main inner 938 / 4 = 234 per month ->
  shell 226 -> 218 / 7 = 31 px cells. 1280: 852 / 4 -> 28 px. 1024 (3/row): 596 / 3 -> 26 px. 640 (stacked,
  3/row): 600 / 3 -> 26 px. Phone 375 (1/row): 335 -> 45 px cells.
- Month template: 4 + 22 + 2 + 7 x 26 + 4 = 214 = 222 - 8 (desktop); 4 + 22 + 2 + 7 x 40 + 4 = 312 = 320 - 8 (phone).
  Months gallery: 3 rows x 222 = 666 (wide), 4 x 222 = 888 (3/row), 12 x 320 = 3840 (phone, scroll root).
- Legend chips: 234 / 149 / 167 px wide; longest "First / Last Day RSY" ~115 px at Size 11.
- Side inner: 380 - 32 = 348 desktop; phone 359 - 32 = 327. From/To and New dates: 156 + 8 + 156 = 320 <= 327.
  Periods row: 60 + 8 + 2 x 125 + 8 = 326 <= 327 (desktop dp 136). Actions 150 + 8 + 130 = 288.
- Panels: Days 596 + 36n (+56); Periods 518; New year 496; Copy 442 (arithmetic in each Height formula).
- Lower panels: Important 12+24+8+22n+12; Check 12+44+4+18+4+56*min(n,10)+12.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| cal-cell-date | galCalDays cell | day of month | colCalCells.D | btnCalDay | `Text: =ThisItem.Txt` | every in-month cell |
| cal-cell-kind | galCalDays cell | day type colour | colCalCells.Kind | btnCalDay | Fill / Color / BorderColor switches | every cell; legend above |
| cal-cell-label | galCalDays cell | exception name + type + date | colCalCells.Tip | btnCalDay | `Tooltip: =ThisItem.Tip` | hover / screen reader; names also listed in Important Dates |
| cal-month-title | conCalMonth | month + locked flag | colCalMonths.Title, Locked | lblCalMonthTitle | `=ThisItem.Title & If(ThisItem.Locked, " · locked", "")` | band above each month |
| cal-imp-line | galCalImp row | Important Dates / SDD / Qtr / Testing line | colCalImportant.Line | lblCalImpLine | `=ThisItem.Line` | lower-left panel, always |
| cal-check-line | galCalChk row | problem text | colCalChecks.Line, Sev | lblCalChkLine | `=ThisItem.Line` | lower-right panel |
| cal-period-row | galCalPer row | period name, start, end | colCalPerEdit | lblCalPerName, dpCalPerStart, dpCalPerEnd | see table | Periods tab |
| cal-receipt-line | galCalReceipt | per-row outcome | colCalReceiptLines | lblCalRcptLabel / lblCalRcptValue | `=ThisItem.Label` / `=ThisItem.Value` | receipt banner |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| cal-denied | conCalDenied | `=!IsAdminRole` | not System Admin |
| cal-body | conCalBody | `=IsAdminRole` | System Admin |
| cal-hdrbar | conCalHdrBar | `=IsAdminRole` | System Admin |
| cal-receipt | conCalReceipt | `=varCalReceipt.Kind <> ""` | after a write attempt until Close / revisit |
| cal-days | conCalDaysPanel | `=!(varCalPanel in ["Periods", "New year", "Copy"])` | Days tab (default) |
| cal-periods | conCalPerPanel | `=varCalPanel = "Periods"` | Periods tab |
| cal-new | conCalNewPanel | `=varCalPanel = "New year"` | New year tab |
| cal-copy | conCalCopyPanel | `=varCalPanel = "Copy"` | Copy tab |
| cal-confirm | chkCalConfirm | `=varCalDayAtt.N > 0` | attendance marks exist on the selected closure range |

## Required Actions

Copy of plan-index rows A-NAV-CAL (current button), A-CAL-YEAR, A-CAL-CAMPUS, A-CAL-SELECT, A-CAL-TAB,
A-CAL-DAYS-SET, A-CAL-DAYS-CLEAR, A-CAL-PER-SAVE, A-CAL-PER-UNDO, A-CAL-CHECK, A-CAL-NEWYEAR, A-CAL-COPY, A-CAL-VIEW.

| Action | Entry point and event | Source and stable ID | Mutation write set | Receipt proof set |
| --- | --- | --- | --- | --- |
| A-CAL-DAYS-SET | btnCalDay / dpCalFrom / dpCalTo -> rdoCalType (non-Clear) -> btnCalSaveDays.OnSelect | per (date, campus): live `ex` by Date + Campus; created `wr.'Calendar Exception'` | Calendar Exceptions: Description, Date, Type, Campus (create) or Description, Type (update); Audit Update | Type, Name, Dates, Campuses, counts, Attendance marks, Audit; per row `Text(wr.Type) · wr.Description · Text(wr.Date)` |
| A-CAL-DAYS-CLEAR | same with Type Clear | live `ex` | Remove row; Audit Update | Operation, Dates, Campuses, counts; per row "Removed (was type · name)" |
| A-CAL-PER-SAVE | Periods tab -> btnCalSavePer.OnSelect | live Terms row by School Year + Campus + Term; `wr.'Term (aaca_termid)'` | Terms: Name, Start Date, End Date (+ School Year, Campus, Term on create); Audit Update | per period `Text(wr.'Start Date') to Text(wr.'End Date') · wr.Name`, Audit |
| A-CAL-NEWYEAR | New year tab -> btnCalCreate -> btnCalCreateEngine | `yr.'School Year'` (created or existing); new Terms / Exceptions ids | School Years (Name, Start, End, Status Planned); Terms; Calendar Exceptions; Audit Rollover | School year (from `yr`), Template, Campuses, counts, Federal holidays, Not copied, skips/failures, Audit |
| A-CAL-COPY | Copy tab -> btnCalCopy -> btnCalCopyEngine | target campus `varCalCopyTargetId`; old ids `colCalCopyOld.Id`; new ids in `colCalLog.Id` | Terms + Calendar Exceptions at the target (add new, remove old, or roll back); Audit Update | From / to, counts, periods added (from `wr`), kept locked rows, failures, Audit |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| ddCalYear | lblCalYear `="School year"` | conCalYearField |
| ddCalCampus | lblCalCampus `="Campus"` | conCalCampusField |
| dpCalFrom | lblCalFrom `="From *"` | conCalFromField |
| dpCalTo | lblCalTo `="To *"` | conCalToField |
| rdoCalType | lblCalType `="Type *"` | conCalDaysPanel |
| txtCalName | lblCalName (mode text) | conCalDaysPanel |
| dpCalPerStart / dpCalPerEnd | lblCalPerName `=ThisItem.TermText` (+ column heads lblCalPerHStart / lblCalPerHEnd) | conCalPerRow |
| txtCalNewName | lblCalNewName | conCalNewPanel |
| dpCalNewStart | lblCalNewStart `="Start date *"` | conCalNewStartField |
| dpCalNewEnd | lblCalNewEnd `="End date *"` | conCalNewEndField |
| ddCalCopyTarget | lblCalCopyTarget `="Campus to replace *"` | conCalCopyPanel |

## Functional Test Scenarios

Owned: S-NAV-CAL (current button), S-CAL-DENIED, S-CAL-LOAD, S-CAL-YEAR, S-CAL-CAMPUS, S-CAL-SELECT, S-CAL-DAYS-SET,
S-CAL-DAYS-UPDATE, S-CAL-DAYS-CLEAR, S-CAL-DAYS-CLEAR-NONE, S-CAL-SET-CLEAR, S-CAL-DAYS-MULTI, S-CAL-DAYS-WEEKEND,
S-CAL-DAYS-LOCKED, S-CAL-DAYS-ATT, S-CAL-DAYS-INVALID, S-CAL-DAYS-FAIL, S-CAL-PER-SAVE, S-CAL-PER-GAP,
S-CAL-PER-INVALID, S-CAL-PER-UNDO, S-CAL-IMPORTANT, S-CAL-CHECK, S-CAL-CHECK-OLD, S-CAL-NEWYEAR, S-CAL-NEWYEAR-ALL,
S-CAL-NEWYEAR-INVALID, S-CAL-COPY, S-CAL-COPY-LOCKED, S-CAL-COPY-FAIL, S-CAL-VIEW - copy the rows (and the fixtures
above that table) from the plan index Functional Test Matrix.

## Relevant Data Source Schemas

- 'School Years': `'School Year'` (GUID), Name, 'Start Date', 'End Date', `'Status (aaca_status)'` (`'Status (School Years)'`).
- Terms: `'Term (aaca_termid)'` (GUID), Name, `'Term (aaca_term)'` (`'Term (Terms)'` Q1..Q4, ESY, Testing),
  'Start Date', 'End Date', 'School Year' (lookup), Campus (lookup; blank = all campuses).
- 'Calendar Exceptions': `'Calendar Exception'` (GUID), Description (the label), Date, Type
  (`'Type (Calendar Exceptions)'`), Campus (lookup; blank = all campuses). One row per day.
- Campuses: Campus (GUID), Name, Code. 'Month Locks': Campus, Month, `'Status (aaca_status)'`.
- Attendance: Campus, Date, 'Is Deleted' (count only). 'Audit Events': Summary, Action, Entity, 'Entity ID', Before,
  After, Reason.

## Required Variants

- GroupContainer -> `Variant: AutoLayout` (every container).
- Gallery -> `Variant: Vertical` (galCalReceipt, galCalLegend, galCalMonths, galCalDays, galCalImp, galCalChk,
  galCalAlso, galCalPer).

## Control Definitions

(From the discovery packets' `describe_control` results; property names valid for this screen. Copied header/help
controls keep exactly the properties they carry in StaffScreen.pa.yaml: Image, Spinner, HtmlViewer.)

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
- Classic/Button (`Control: Classic/Button`; NO AccessibleLabel - use Tooltip): Align [Align], AlignInContainer,
  AutoDisableOnSelect, BorderColor, BorderStyle, BorderThickness, Color, DisabledBorderColor, DisabledColor,
  DisabledFill, DisplayMode, Fill, FocusedBorderColor, FocusedBorderThickness, FontWeight [FontWeight], Height,
  HoverBorderColor, HoverColor, HoverFill, LayoutMinHeight, LayoutMinWidth, OnSelect, PaddingBottom/Left/Right/Top,
  PressedBorderColor, PressedColor, PressedFill, RadiusBottomLeft/Right, RadiusTopLeft/Right, Size, TabIndex, Text,
  Tooltip, VerticalAlign [VerticalAlign], Visible, Width, X, Y.
- Gallery (`Control: Gallery` + Variant): AccessibleLabel, BorderColor, BorderThickness, DelayItemLoading,
  FillPortions, Height, Items, LayoutMinHeight, LayoutMinWidth, LoadingSpinner [LoadingSpinner], Selectable,
  ShowScrollbar, TabIndex, TemplatePadding, TemplateSize, Visible, Width, WrapCount, AlignInContainer. Outputs
  TemplateWidth, TemplateHeight, AllItems.
- ModernDropdown (`Control: ModernDropdown`; Appearance enum `Appearance`): AccessibleLabel, AlignInContainer,
  Appearance, Color, Default, DisplayMode, Height, ItemDisplayText, Items, LayoutMinHeight, LayoutMinWidth, OnChange,
  Visible, Width. Output Selected.
- ModernTextInput (`Control: ModernTextInput`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  Default, DisplayMode, Height, LayoutMinHeight, LayoutMinWidth, MaxLength, Placeholder, TriggerOutput, Type
  [TextInputType], Visible, Width. Output Text.
- ModernDatePicker (`Control: ModernDatePicker`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  DefaultDate, DisplayMode, EndDate, FillPortions, Format [DatePickerFormat], Height, LayoutMinHeight, LayoutMinWidth,
  OnChange, StartDate, StartOfWeek [StartOfWeek], Visible, Width. Output SelectedDate.
- ModernRadio (`Control: ModernRadio`): AccessibleLabel, AlignInContainer, Color, Default, DisplayMode, Height,
  ItemDisplayText, Items, Layout [OptionLayout], LayoutMinHeight, LayoutMinWidth, OnChange, Visible. Output Selected.
- ModernCheckbox (`Control: ModernCheckbox`): AccessibleLabel, AlignInContainer, BasePaletteColor, CheckboxSize,
  Color, Default, DisplayMode, Height, Label, LayoutMinHeight, LayoutMinWidth, OnCheck, OnUncheck, Size, Tooltip,
  Visible, Width, X, Y. Output Checked.
- ModernTabList (`Control: ModernTabList`): AccessibleLabel, Align, Alignment, AlignInContainer, Appearance
  [TabListAppearance], BasePaletteColor, Color, Default, DisplayMode, FillPortions, Height, ItemDisplayText, Items,
  LayoutMinHeight, LayoutMinWidth, OnChange, OnSelect, Size, TabSize [TabSize], Visible, Width. Output Selected.

Compile-ready enum literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `Appearance.Outline`,
`DatePickerFormat.Short`, `OptionLayout.Vertical`, `TabSize.Small`, `TabListAppearance.Transparent`,
`LoadingSpinner.None`, `Align.Center`, `FontWeight.Bold`, `FontWeight.Semibold`, `FontWeight.Normal`,
`VerticalAlign.Top`, `VerticalAlign.Middle`, `DisplayMode.Edit`, `DisplayMode.Disabled`, `LayoutDirection.Horizontal`,
`LayoutDirection.Vertical`, `LayoutAlignItems.Stretch`, `LayoutAlignItems.Center`, `LayoutAlignItems.Start`,
`AlignInContainer.Stretch`, `AlignInContainer.Center`, `AlignInContainer.Start`, `LayoutOverflow.Scroll`,
`DropShadow.None`, `StartOfWeek.Monday`, `StartOfWeek.Sunday`, `TimeUnit.Days`, `TimeUnit.Months`, `TimeUnit.Years`,
`SortOrder.Ascending`, `SortOrder.Descending`.

YAML: every formula containing `: ` or ` #` is a `|-` block (all engines, S-DAYS, S-PER, C-* labels, record
literals such as `={Value: varCalPanel}`, texts with `"Ready: "`, `"Qtr.1: "`, `"SDD "...": "`, `"Could not load: "`,
lblCalPerHelp). Apostrophes inside Power Fx strings ("campus's") are fine in a `|-` block. No glyphs.
