# Screen Plan: Transportation (NEW)

## Assignment

- Action: Create
- Target file: `C:\src\aaca-attendance\app\TransportScreen.pa.yaml`
- YAML key: TransportScreen
- Control name prefix: Trn

Read `canvas-app-shared.md` first (palette, header nav pattern, YAML rules, school-day rule). The header block copies
AbsencesScreen's header (`conAbsHeader` / `conAbsNav` / `conAbsHdrTabs`) under the `Trn` prefix; open
`C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml` lines 27-213 and its receipt `conAbsReceiptV` (lines 1883-2016) as
the property templates.

## Specification

- Purpose: office/admin confirm each school day's transportation per student (Daily) and maintain who has
  transportation (Students). Teachers / Read-only see a denied panel.
- Breakpoint source: `conTrnRoot.Width` only (phone `< 640`, narrow `< 1024`).
- Screen `Fill: =ColorPaper`.

### Control tree (exact names and order)

```
TransportScreen
└ conTrnRoot                      root (sole top-level child)
  ├ conTrnHeader                  Ink band (no side padding)
  │ ├ lblTrnTitle
  │ ├ lblTrnIdentity
  │ ├ conTrnNav                   btnTrnNavAttendance, btnTrnNavStudents, btnTrnNavAbsences, btnTrnNavTransport
  │ └ conTrnHdrTabs               paper strip: btnTrnHdrDaily, btnTrnHdrStudents, lblTrnCampus, ddTrnCampus
  ├ conTrnDenied                  lblTrnDeniedTitle, lblTrnDeniedBody, btnTrnDeniedBack
  ├ conTrnBody
  │ ├ conTrnReceipt               conTrnReceiptTop(lblTrnReceiptTitle, btnTrnReceiptClose), galTrnReceipt(conTrnRcptRow: lblTrnRcptLabel, lblTrnRcptValue)
  │ ├ conTrnDailyView
  │ │ ├ conTrnBanner              lblTrnBannerTitle, lblTrnDeadline, galTrnBannerDays(btnTrnBannerDay)
  │ │ └ conTrnDayPanel
  │ │   ├ conTrnDayHead           lblTrnDayTitle, btnTrnReload
  │ │   ├ conTrnDateField         lblTrnDate, dpTrnDate
  │ │   ├ lblTrnDayCount
  │ │   ├ conTrnConfirmRow        btnTrnConfirm, lblTrnConfirmHint
  │ │   └ galTrnDayList           conTrnDayRow: conTrnDayInfo(lblTrnDayName, lblTrnDayMeta, lblTrnDayStatus), conTrnDayOpts(btnTrnOptRound, btnTrnOptDrop, btnTrnOptPick, btnTrnOptNone)
  │ └ conTrnStuView               (two-panel body)
  │   ├ conTrnStuListPanel        conTrnStuListHead(lblTrnStuListTitle, chkTrnShowEnded, btnTrnStuAdd), galTrnStuList(conTrnStuRow: lblTrnStuRowName, lblTrnStuRowMeta, conTrnStuRowActions(btnTrnStuRowChange, btnTrnStuRowEnd))
  │   └ conTrnStuPanel            lblTrnStuPanelTitle, lblTrnStuFacts, lblTrnStuPick, cboTrnStuPick, lblTrnStuStart, dpTrnStuStart, lblTrnStuPattern, rdoTrnStuPattern, lblTrnStuNote, txtTrnStuNote, lblTrnStuEnd, dpTrnStuEnd, lblTrnStuCheck, conTrnStuActions(btnTrnStuSave, btnTrnStuCancel)
  ├ btnTrnStuLoadEngine           hidden Classic/Button engines (Visible false)
  ├ btnTrnLoadEngine
  ├ btnTrnBannerEngine
  └ btnTrnSaveEngine
```

## Screen OnVisible

```
=Set(varTrnSaving, false);
Set(varTrnLoading, false);
Set(varTrnStuMode, "");
Set(varTrnSelStId, Blank());
Set(varTrnReceipt, {Kind: "", Title: ""});
Clear(colTrnReceiptLines);
If(varTrnView <> "students", Set(varTrnView, "daily"));
If(StudentCampusLock <> ZeroGuid, Set(varTrnCampusId, StudentCampusLock));
Set(varTrnDate, Today());
ClearCollect(colTrnCampusOpts, ForAll(Sort(Campuses, Name, SortOrder.Ascending) As c, {CampusId: c.Campus, CampusName: c.Name}));
If(varTrnCampusId = ZeroGuid, Set(varTrnCampusId, Coalesce(First(colTrnCampusOpts).CampusId, ZeroGuid)));
Select(btnTrnStuLoadEngine);
Select(btnTrnLoadEngine);
Select(btnTrnBannerEngine)
```

## Layout and properties by section

### Root `conTrnRoot`
GroupContainer AutoLayout: DropShadow None, Fill `=ColorPaper`, Width `=Parent.Width`, Height `=Parent.Height`,
LayoutMinWidth `=0`, LayoutMinHeight `=0`, LayoutDirection Vertical, LayoutAlignItems Stretch, LayoutGap `=8`,
LayoutOverflowY `=LayoutOverflow.Scroll`, PaddingBottom `=16`, Radius* `=0`.

### Header `conTrnHeader` (copy of `conAbsHeader`)
Fill `=ColorInk`, FillPortions 0, Height
`=If(conTrnRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conTrnRoot.Width < 640, 100, 48), 0) + If(CanClassify, If(conTrnRoot.Width < 640, 112, 60), 0)`,
Vertical, Stretch, gap 4, PaddingTop 12, PaddingBottom `=If(CanClassify, 0, 12)`, no side padding, Radius* 0.
- `lblTrnTitle`: as `lblAbsTitle` (Text `="AACA Attendance"`, Size 20 Bold, `ColorWhite`, Height 28, PaddingLeft/Right 16).
- `lblTrnIdentity`: as `lblAbsIdentity` (identity formula from shared plan, `ColorInkSoft`, Size 12, Height
  `=If(conTrnRoot.Width < 640, 36, 20)`, PaddingLeft/Right 16, VerticalAlign Top).
- `conTrnNav`: horizontal, LayoutWrap `=true`, LayoutAlignItems Center, gap 8, PaddingLeft/Right 16, Height
  `=If(conTrnRoot.Width < 640, 96, 44) + If(CanClassify, 8, 0)`, Visible `=CanManageStudents`, FillPortions 0.
  Four buttons per the shared nav table; `btnTrnNavTransport` is the CURRENT one (BasePaletteColor ColorTeal,
  Color ColorWhite, AccessibleLabel "Transportation (current screen)", Visible `=CanClassify`, Width 140,
  OnSelect `=Navigate(TransportScreen)`); the other three are Secondary.
- `conTrnHdrTabs`: Fill `=ColorPaper`, horizontal, LayoutWrap `=true`, LayoutAlignItems Center, gap 8, Padding 8
  top/bottom 16 left/right, Height `=If(conTrnRoot.Width < 640, 112, 60)`, Visible `=CanClassify`, FillPortions 0,
  Radius* 0. Children:
  - `btnTrnHdrDaily`: toggle pattern active when `varTrnView = "daily"`, Text `="Daily"`, Width 130,
    AccessibleLabel `="Daily confirmation" & If(varTrnView = "daily", " (current view)", "")`,
    OnSelect `=Set(varTrnView, "daily"); Select(btnTrnLoadEngine); Select(btnTrnBannerEngine)`.
  - `btnTrnHdrStudents`: toggle pattern active when `varTrnView = "students"`, Text `="Students"`, Width 130,
    AccessibleLabel `="Students with transportation" & If(varTrnView = "students", " (current view)", "")`,
    OnSelect `=Set(varTrnView, "students")`.
  - `lblTrnCampus`: ModernText Text `="Campus"`, Size 12 Semibold `ColorMuted`, Width 56, Height 20, Wrap false,
    AlignInContainer Center, Padding* 0.
  - `ddTrnCampus`: ModernDropdown AccessibleLabel `="Campus"`, Appearance Outline, Color ColorInk, Width 220,
    Height 36, AlignInContainer Center, Items `=colTrnCampusOpts`, ItemDisplayText `=ThisItem.CampusName`, Default
    `=LookUp(colTrnCampusOpts, CampusId = varTrnCampusId)`, DisplayMode
    `=If(StudentCampusLock = ZeroGuid && !varTrnLoading && !varTrnSaving, DisplayMode.Edit, DisplayMode.Disabled)`,
    OnChange:
    ```
    =Set(varTrnCampusId, Coalesce(Self.Selected.CampusId, ZeroGuid));
    Set(varTrnStuMode, "");
    Set(varTrnSelStId, Blank());
    Select(btnTrnStuLoadEngine);
    Select(btnTrnLoadEngine);
    Select(btnTrnBannerEngine)
    ```
  Budget: 16+130+8+130+8+56+8+220+16 = 592 <= 640 (one row); below 592 it wraps: 8+44+8+36+8 = 104 <= 112.

### `conTrnDenied` (copy of `conAbsDenied`)
Visible `=!CanClassify`. Title `="Transportation is not available for your role"`; body
`=If(!StaffReady, "Your sign-in is not linked to an active Staff record. Ask a System Admin to set you up.", "Only the Attendance Office and System Admin roles manage transportation. Teachers and Read-only users record and view attendance on the Attendance screen.")`;
`btnTrnDeniedBack` "Back to Attendance" `=Navigate(Screen1)`. Height formula as Absences with `conTrnRoot`.

### `conTrnBody`
Vertical, Stretch, gap 8, FillPortions 0, no fill, Visible `=CanClassify`, Height
`=If(conTrnReceipt.Visible, conTrnReceipt.Height + 8, 0) + If(conTrnDailyView.Visible, conTrnDailyView.Height, 0) + If(conTrnStuView.Visible, conTrnStuView.Height, 0)`.

### Receipt `conTrnReceipt` (copy of `conAbsReceiptV`, names `Trn`)
Fill `=Switch(varTrnReceipt.Kind, "Failed", ColorErrorBg, "Blocked", ColorErrorBg, ColorInfoBg)`, Visible
`=varTrnReceipt.Kind <> ""`, Height `=8 + If(conTrnRoot.Width < 640, 84, 44) + If(CountRows(colTrnReceiptLines) > 0, 4 + galTrnReceipt.Height, 0) + 8`.
`lblTrnReceiptTitle.Text: =varTrnReceipt.Title`; `btnTrnReceiptClose` Text "Close", Width 88, OnSelect
`=Set(varTrnReceipt, {Kind: "", Title: ""}); Clear(colTrnReceiptLines)` (block scalar). `galTrnReceipt`: Items
`=colTrnReceiptLines`, TemplateSize 40, WrapCount `=If(conTrnRoot.Width < 640, 1, conTrnRoot.Width < 1024, 2, 3)`,
Height `=Min(400, RoundUp(CountRows(colTrnReceiptLines) / If(conTrnRoot.Width < 640, 1, conTrnRoot.Width < 1024, 2, 3), 0) * 40)`,
row `conTrnRcptRow` with `lblTrnRcptLabel` (`ThisItem.Label`, muted Semibold 12) and `lblTrnRcptValue`
(`ThisItem.Value`, ink 12, FillPortions 1), exactly like `conAbsRcptRowV`.

### Daily view `conTrnDailyView`
Vertical, Stretch, gap 8, FillPortions 0, Visible `=CanClassify && varTrnView = "daily"`, Height
`=conTrnBanner.Height + 8 + conTrnDayPanel.Height`.

`conTrnBanner`: panel border, Fill `=If(CountRows(Filter(colTrnDays, Missing > 0)) > 0, ColorWarnBg, ColorInfoBg)`,
vertical, Stretch, gap 4, padding 12, radius 6, FillPortions 0, Height
`=12 + If(conTrnRoot.Width < 640, 44, 24) + 4 + 18 + If(CountRows(Filter(colTrnDays, Missing > 0)) > 0, 4 + 44, 0) + 12`.
- `lblTrnBannerTitle` (16 Semibold ink, Height `=If(conTrnRoot.Width < 640, 44, 24)`, VerticalAlign Top) Text:
  ```
  =With(
      {k: CountRows(Filter(colTrnDays, Missing > 0)), t: CountRows(colTrnDays), cn: LookUp(colTrnCampusOpts, CampusId = varTrnCampusId).CampusName},
      If(
          t = 0, "No school days in the last 4 weeks at " & cn & ".",
          k = 0, "All of the last " & t & " school days are confirmed at " & cn & ".",
          k & " school day" & If(k = 1, "", "s") & " not confirmed · last " & t & " school days at " & cn
      )
  )
  ```
- `lblTrnDeadline` (12 ink, Height 18, Wrap false) Text `="Confirm each school day by the end of the day."`
- `galTrnBannerDays`: Gallery `Variant: Horizontal`, AccessibleLabel `="School days not confirmed"`, Items
  `=Filter(colTrnDays, Missing > 0)`, Height 44, TemplateSize 148, TemplatePadding 0, FillPortions 0, Selectable
  false, TabIndex 0, Visible `=CountRows(Filter(colTrnDays, Missing > 0)) > 0`. Single child (no shell):
  `btnTrnBannerDay` ModernButton Secondary ink, Height 44, Width `=Parent.TemplateWidth - 8`, Text
  `=Text(ThisItem.D, "ddd m/d") & " (" & ThisItem.Missing & ")"`, AccessibleLabel
  `="Open " & Text(ThisItem.D, "dddd mmmm d") & ", " & ThisItem.Missing & " not confirmed"`, DisplayMode
  `=If(varTrnLoading || varTrnSaving, DisplayMode.Disabled, DisplayMode.Edit)`, OnSelect
  `=Set(varTrnDate, ThisItem.D); Reset(dpTrnDate); Select(btnTrnLoadEngine)`.

`conTrnDayPanel`: panel (white, border, radius 6), vertical, Stretch, gap 8, padding 16, FillPortions 0, Height
`=16 + 44 + 8 + 58 + 8 + If(conTrnRoot.Width < 640, 54, 36) + 8 + If(conTrnRoot.Width < 640, 88, 44) + If(CountRows(colTrnDaily) > 0, 8 + galTrnDayList.Height, 0) + 16`.
- `conTrnDayHead` (horizontal, Height 44, Center, gap 8): `lblTrnDayTitle` Text `="Daily confirmation"` 20 Bold,
  FillPortions 1, Height 30, LayoutMinWidth 120, Wrap false; `btnTrnReload` Secondary "Reload" Width 80, DisplayMode
  `=If(varTrnLoading || varTrnSaving, DisplayMode.Disabled, DisplayMode.Edit)`, OnSelect
  `=Select(btnTrnStuLoadEngine); Select(btnTrnLoadEngine); Select(btnTrnBannerEngine)`.
- `conTrnDateField` (vertical, gap 4, Height 58, Width 240, AlignInContainer Start, FillPortions 0): `lblTrnDate`
  `="Date"` (label style); `dpTrnDate` ModernDatePicker AccessibleLabel `="Date to confirm"`, Appearance Outline,
  Height 36, DefaultDate `=varTrnDate`, StartDate `=Date(FirstSchoolYear, 1, 1)`, EndDate `=Today()`, Format
  `=DatePickerFormat.Short`, DisplayMode `=If(varTrnLoading || varTrnSaving, DisplayMode.Disabled, DisplayMode.Edit)`,
  OnChange `=Set(varTrnDate, Self.SelectedDate); Select(btnTrnLoadEngine)`.
- `lblTrnDayCount` (13 Semibold, Height `=If(conTrnRoot.Width < 640, 54, 36)`, VerticalAlign Top, Color
  `=If(varTrnLoadError <> "", ColorUnexcused, ColorInk)`) Text (block):
  ```
  =With(
      {n: CountRows(colTrnDaily), ok: CountRows(Filter(colTrnDaily, LogId <> ZeroGuid)), cn: LookUp(colTrnCampusOpts, CampusId = varTrnCampusId).CampusName},
      If(
          varTrnLoading, "Loading...",
          varTrnLoadError <> "", "Could not load: " & varTrnLoadError & ". Use Reload to try again.",
          !varTrnIsSchoolDay, "Not a school day at " & cn & " – " & varTrnDayReason & ". Nothing to confirm.",
          n = 0, "No students with transportation at " & cn & " on " & Text(varTrnDate, "ddd mmm d, yyyy") & ".",
          n & " students with transportation · " & cn & " · " & Text(varTrnDate, "ddd mmm d, yyyy") & " · " & ok & " confirmed, " & (n - ok) & " not confirmed"
      )
  )
  ```
- `conTrnConfirmRow` (FillPortions 0, gap 8, Height `=If(conTrnRoot.Width < 640, 88, 44)`, LayoutDirection
  `=If(conTrnRoot.Width < 640, LayoutDirection.Vertical, LayoutDirection.Horizontal)`, LayoutAlignItems
  `=If(conTrnRoot.Width < 640, LayoutAlignItems.Stretch, LayoutAlignItems.Center)`):
  - `btnTrnConfirm` primary teal, Width 190, AlignInContainer `=If(conTrnRoot.Width < 640, AlignInContainer.Start, AlignInContainer.Center)`,
    Text `=With({k: CountRows(Filter(colTrnDaily, LogId = ZeroGuid || Pick <> SavedStatus))}, If(CountRows(colTrnDaily) > 0 && k = 0, "All confirmed", "Confirm day (" & k & ")"))`,
    AccessibleLabel `="Confirm transportation for " & Text(varTrnDate, "dddd mmmm d")`, DisplayMode:
    ```
    =If(CanClassify && !varTrnSaving && !varTrnLoading && varTrnIsSchoolDay && varTrnDate <= Today() && CountRows(colTrnDaily) > 0 && CountRows(Filter(colTrnDaily, Pick = "")) = 0 && CountRows(Filter(colTrnDaily, LogId = ZeroGuid || Pick <> SavedStatus)) > 0, DisplayMode.Edit, DisplayMode.Disabled)
    ```
    OnSelect:
    ```
    =ClearCollect(colTrnWork, ForAll(Filter(colTrnDaily, Pick <> "" && (LogId = ZeroGuid || Pick <> SavedStatus)) As r, {StudentId: r.StudentId, Status: r.Pick}));
    Set(varTrnReq, {Scope: "day"});
    Select(btnTrnSaveEngine);
    Select(btnTrnBannerEngine)
    ```
  - `lblTrnConfirmHint` (12 ink, Height 36, FillPortions `=If(conTrnRoot.Width < 640, 0, 1)`, AlignInContainer
    `=If(conTrnRoot.Width < 640, AlignInContainer.Stretch, AlignInContainer.Center)`, VerticalAlign Top) Text:
    ```
    =With(
        {n: CountRows(colTrnDaily), b: CountRows(Filter(colTrnDaily, Pick = "")), k: CountRows(Filter(colTrnDaily, LogId = ZeroGuid || Pick <> SavedStatus))},
        If(
            varTrnLoading, "",
            !varTrnIsSchoolDay, "Not a school day. Nothing to confirm.",
            n = 0, "No students to confirm.",
            b > 0, b & " row(s) still need a status: Round trip, Drop off only, Pick up only or No transportation.",
            k = 0, "Every row is confirmed. Changing a status on a row saves it straight away.",
            "Ready: " & k & " row(s) will be saved for " & Text(varTrnDate, "ddd mmm d") & "."
        )
    )
    ```
- `galTrnDayList`: Gallery `Variant: Vertical`, AccessibleLabel `="Students with transportation on " & Text(varTrnDate, "dddd mmmm d")`,
  Items `=colTrnDaily` (already sorted by name), FillPortions 0, Height
  `=Min(If(conTrnRoot.Width < 1024, 3, 7), CountRows(colTrnDaily)) * If(conTrnRoot.Width < 1024, 224, 88)`,
  TemplateSize `=If(conTrnRoot.Width < 1024, 224, 88)`, TemplatePadding 0, Selectable false, TabIndex 0, Visible
  `=CountRows(colTrnDaily) > 0`.
  - `conTrnDayRow` shell: Width `=Parent.TemplateWidth - 16`, Height `=Parent.TemplateHeight`, Fill `=ColorWhite`,
    BorderColor ColorRule, BorderThickness 1, padding 8, gap 8, Radius* 0, LayoutDirection
    `=If(conTrnRoot.Width < 1024, LayoutDirection.Vertical, LayoutDirection.Horizontal)`, LayoutAlignItems
    `=If(conTrnRoot.Width < 1024, LayoutAlignItems.Stretch, LayoutAlignItems.Center)`.
  - `conTrnDayInfo`: vertical, Stretch, gap 4, FillPortions `=If(conTrnRoot.Width < 1024, 0, 1)`, Height
    `=If(conTrnRoot.Width < 1024, 102, 66)`, LayoutMinWidth `=If(conTrnRoot.Width < 1024, 0, 300)`, LayoutMinHeight 0.
    - `lblTrnDayName` 14 Semibold ink, Height 22, Wrap false: `=ThisItem.StudentName & " · " & ThisItem.KeyBase`.
    - `lblTrnDayMeta` 12 ink, Height `=If(conTrnRoot.Width < 1024, 36, 18)`, VerticalAlign Top (block):
      `="Usual: " & ThisItem.Pattern & " · Attendance: " & ThisItem.AttText`.
    - `lblTrnDayStatus` 12 Semibold, Height `=If(conTrnRoot.Width < 1024, 36, 18)`, VerticalAlign Top, Color
      `=If(ThisItem.LogId <> ZeroGuid, ColorTeal, ThisItem.Pick = "", ColorUnexcused, ColorMuted)`, Text (block):
      ```
      =If(
          ThisItem.LogId <> ZeroGuid,
          "Confirmed by " & If(ThisItem.ByName = "", "unknown", ThisItem.ByName) & " at " & Text(ThisItem.OnTime, "h:mm AM/PM") & If(Date(Year(ThisItem.OnTime), Month(ThisItem.OnTime), Day(ThisItem.OnTime)) <> varTrnDate, " on " & Text(ThisItem.OnTime, "m/d"), "") & " · " & ThisItem.SavedStatus,
          ThisItem.Pick = "", "Not confirmed · choose a status",
          "Not confirmed · " & ThisItem.Pick & If(ThisItem.Pick = ThisItem.Prefill, If(ThisItem.AttKind = "absent", " (pre-filled: absent)", " (pre-filled: left early)"), " (chosen, not saved)")
      )
      ```
  - `conTrnDayOpts`: horizontal, LayoutWrap `=true`, LayoutAlignItems Center, gap 8, FillPortions 0, Width `=544`,
    Height `=If(conTrnRoot.Width < 1024, 96, 44)`, AlignInContainer
    `=If(conTrnRoot.Width < 1024, AlignInContainer.Stretch, AlignInContainer.Center)`. Four buttons (toggle pattern,
    Height 44, AlignInContainer Center):

    | Control | Text | Width | Literal `S` |
    | --- | --- | --- | --- |
    | btnTrnOptRound | "Round trip" | 110 | "Round trip" |
    | btnTrnOptDrop | "Drop off only" | 130 | "Drop off only" |
    | btnTrnOptPick | "Pick up only" | 120 | "Pick up only" |
    | btnTrnOptNone | "No transportation" | 160 | "No transportation" |

    Each, with its own literal `S` written out (no shared variable):
    - Appearance `=If(ThisItem.Pick = S, ButtonAppearance.Primary, ButtonAppearance.Secondary)`, BasePaletteColor
      `=ColorTeal`, Color `=If(ThisItem.Pick = S, ColorWhite, ColorInk)`.
    - AccessibleLabel `=S & " for " & ThisItem.StudentName & If(ThisItem.Pick = S, " (selected)", "")`.
    - DisplayMode `=If(CanClassify && !varTrnSaving && !varTrnLoading && varTrnIsSchoolDay && varTrnDate <= Today(), DisplayMode.Edit, DisplayMode.Disabled)`.
    - OnSelect (block), e.g. for Round trip:
      ```
      =If(
          ThisItem.LogId = ZeroGuid,
          Patch(colTrnDaily, LookUp(colTrnDaily, StudentId = ThisItem.StudentId), {Pick: "Round trip"}),
          ThisItem.SavedStatus <> "Round trip",
          ClearCollect(colTrnWork, {StudentId: ThisItem.StudentId, Status: "Round trip"});
          Set(varTrnReq, {Scope: "row"});
          Select(btnTrnSaveEngine)
      )
      ```

### Students view `conTrnStuView`
GroupContainer: FillPortions 0, gap 8, Visible `=CanClassify && varTrnView = "students"`, LayoutDirection
`=If(conTrnRoot.Width >= 1024, LayoutDirection.Horizontal, LayoutDirection.Vertical)`, LayoutAlignItems
`=If(conTrnRoot.Width >= 1024, LayoutAlignItems.Start, LayoutAlignItems.Stretch)`, Height
`=If(conTrnRoot.Width >= 1024, Max(conTrnStuListPanel.Height, conTrnStuPanel.Height), If(conTrnStuListPanel.Visible, conTrnStuListPanel.Height, 0) + If(conTrnStuListPanel.Visible && conTrnStuPanel.Visible, 8, 0) + If(conTrnStuPanel.Visible, conTrnStuPanel.Height, 0))`.

`conTrnStuListPanel` (panel, vertical, Stretch, gap 8, padding 16, AlignInContainer
`=If(conTrnRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)`, FillPortions
`=If(conTrnRoot.Width >= 1024, 2, 0)`, Visible `=!(conTrnRoot.Width < 1024 && varTrnStuMode <> "")`), Height
`=16 + If(conTrnRoot.Width < 640, 96, 44) + If(CountRows(Filter(colTrnStAll, varTrnShowEnded || Active)) > 0, 8 + galTrnStuList.Height, 0) + 16`.
- `conTrnStuListHead`: horizontal, LayoutWrap true, Center, gap 8, Height `=If(conTrnRoot.Width < 640, 96, 44)`:
  - `lblTrnStuListTitle` 18 Bold, FillPortions 1, LayoutMinWidth 200, Height 30, Wrap false, Text
    `="Students with transportation (" & CountRows(Filter(colTrnStAll, varTrnShowEnded || Active)) & ")"`.
  - `chkTrnShowEnded` ModernCheckbox Label `="Show ended"`, AccessibleLabel `="Show ended transportation"`, Width 140,
    Height 44, Default `=varTrnShowEnded`, OnCheck `=Set(varTrnShowEnded, true)`, OnUncheck
    `=Set(varTrnShowEnded, false)`, AlignInContainer Center.
  - `btnTrnStuAdd` primary teal "Add student" Width 130, AccessibleLabel `="Add a student to transportation"`,
    DisplayMode `=If(CanClassify && !varTrnSaving && !varTrnLoading, DisplayMode.Edit, DisplayMode.Disabled)`,
    OnSelect `=Set(varTrnSelStId, Blank()); Set(varTrnStuMode, "add"); Reset(cboTrnStuPick); Reset(dpTrnStuStart); Reset(rdoTrnStuPattern); Reset(txtTrnStuNote)`.
- `galTrnStuList`: Gallery Vertical, AccessibleLabel `="Students with transportation"`, Items
  `=SortByColumns(Filter(colTrnStAll, varTrnShowEnded || Active), "StudentName", SortOrder.Ascending)`, Height
  `=Min(If(conTrnRoot.Width < 640, 3, 5), CountRows(Filter(colTrnStAll, varTrnShowEnded || Active))) * If(conTrnRoot.Width < 640, 216, 130)`,
  TemplateSize `=If(conTrnRoot.Width < 640, 216, 130)`, TemplatePadding 0, Selectable false, TabIndex 0, Visible
  `=CountRows(Filter(colTrnStAll, varTrnShowEnded || Active)) > 0`.
  - `conTrnStuRow` shell (Width `Parent.TemplateWidth - 16`, Height `Parent.TemplateHeight`, vertical, Stretch, gap 4,
    padding 8, border, Fill `=If(ThisItem.StId = varTrnSelStId, ColorInfoBg, !ThisItem.Active, ColorNonSchool, ColorWhite)`):
    - `lblTrnStuRowName` 14 Semibold, Height `=If(conTrnRoot.Width < 640, 40, 22)`, VerticalAlign Top, Text
      `=ThisItem.StudentName & " · " & ThisItem.KeyBase & If(ThisItem.Active, "", " · ended")`.
    - `lblTrnStuRowMeta` 12 ink, Height `=If(conTrnRoot.Width < 640, 54, 36)`, VerticalAlign Top, Text (block):
      `=ThisItem.Pattern & " · " & Text(ThisItem.StartDate, "mmm d, yyyy") & " - " & If(IsBlank(ThisItem.EndDate), "ongoing", Text(ThisItem.EndDate, "mmm d, yyyy")) & " · " & If(ThisItem.SourceText = "", "no source", ThisItem.SourceText) & If(ThisItem.Note = "", "", " · Note: " & Left(ThisItem.Note, 120))`
    - `conTrnStuRowActions`: horizontal, LayoutWrap true, Center, gap 8, FillPortions 0, Height
      `=If(conTrnRoot.Width < 640, 96, 44)`:
      - `btnTrnStuRowChange` Secondary "Change pattern" Width 150, AccessibleLabel
        `="Change pattern for " & ThisItem.StudentName`, DisplayMode
        `=If(CanClassify && ThisItem.Active && !varTrnSaving, DisplayMode.Edit, DisplayMode.Disabled)`, OnSelect
        `=Set(varTrnSelStId, ThisItem.StId); Set(varTrnStuMode, "change"); Reset(rdoTrnStuPattern); Reset(txtTrnStuNote)`.
      - `btnTrnStuRowEnd` Secondary "End transportation" Width 170, AccessibleLabel
        `="End transportation for " & ThisItem.StudentName`, same DisplayMode, OnSelect
        `=Set(varTrnSelStId, ThisItem.StId); Set(varTrnStuMode, "end"); Reset(dpTrnStuEnd)`.

`conTrnStuPanel` (panel, vertical, Stretch, gap 4, padding 16, AlignInContainer as list panel, FillPortions
`=If(conTrnRoot.Width >= 1024, 1, 0)`, Visible `=conTrnRoot.Width >= 1024 || varTrnStuMode <> ""`), Height
`=32 + Switch(varTrnStuMode, "add", 442, "change", 376, "end", 254, 86)`. Children (labels = field label style,
inputs Height 36 unless noted, Appearance Outline, Color ink, DisplayMode `=If(varTrnSaving, DisplayMode.Disabled, DisplayMode.Edit)`):

| # | Control | Key properties | Visible |
| - | ------- | -------------- | ------- |
| 1 | lblTrnStuPanelTitle | 18 Bold, Height 28, Wrap false, Text `=Switch(varTrnStuMode, "add", "Add transportation", "change", "Change pattern", "end", "End transportation", "Transportation details")` | always |
| 2 | lblTrnStuFacts | 13 ink, Height 54, VerticalAlign Top, Text below | `=varTrnStuMode <> "add"` |
| 3 | lblTrnStuPick | `="Student *"` | `=varTrnStuMode = "add"` |
| 4 | cboTrnStuPick | ModernCombobox AccessibleLabel `="Student"`, Items `=Filter(colTrnCampStu, !(StudentId in Filter(colTrnStAll, Active).StudentId))`, ItemDisplayText `=ThisItem.Label`, SelectMultiple `=false`, DefaultSelectedItems `=[]`, InputTextPlaceholder `="Type a name or Student Key"` | add |
| 5 | lblTrnStuStart | `="Start date *"` | add |
| 6 | dpTrnStuStart | AccessibleLabel `="Start date"`, DefaultDate `=Today()`, StartDate `=Date(FirstSchoolYear, 1, 1)`, EndDate `=DateAdd(Today(), 365, TimeUnit.Days)`, Format Short | add |
| 7 | lblTrnStuPattern | `="Usual pattern *"` | `=varTrnStuMode in ["add", "change"]` |
| 8 | rdoTrnStuPattern | ModernRadio AccessibleLabel `="Usual pattern"`, Items `=TransportPatternOptions`, Default (block) `=If(varTrnStuMode = "change", {Value: LookUp(colTrnStAll, StId = varTrnSelStId).Pattern}, {Value: "Round trip"})`, Layout `=OptionLayout.Vertical`, Height 96 | add/change |
| 9 | lblTrnStuNote | `="Note (optional)"` | add/change |
| 10 | txtTrnStuNote | AccessibleLabel `="Note"`, Default `=If(varTrnStuMode = "change", LookUp(colTrnStAll, StId = varTrnSelStId).Note, "")`, MaxLength 2000, Placeholder `="e.g. grandparent drops off on Fridays"` | add/change |
| 11 | lblTrnStuEnd | `="End date *"` | `=varTrnStuMode = "end"` |
| 12 | dpTrnStuEnd | AccessibleLabel `="End date"`, DefaultDate `=Today()`, StartDate `=Date(FirstSchoolYear, 1, 1)`, EndDate `=DateAdd(Today(), 365, TimeUnit.Days)`, Format Short | end |
| 13 | lblTrnStuCheck | 12, Height 54, VerticalAlign Top, Color `=If(StartsWith(Self.Text, "Ready"), ColorExcused, ColorUnexcused)`, Text below | `=varTrnStuMode <> ""` |
| 14 | conTrnStuActions | horizontal, Height 44, Center, gap 8: `btnTrnStuSave`, `btnTrnStuCancel` | `=varTrnStuMode <> ""` |

`lblTrnStuFacts.Text`:
```
=With({s: LookUp(colTrnStAll, StId = varTrnSelStId)}, If(IsBlank(s), "Choose Add student, or Change pattern / End transportation on a row.", s.StudentName & " · " & s.KeyBase & Char(10) & "Now " & s.Pattern & " · " & Text(s.StartDate, "mmm d, yyyy") & " - " & If(IsBlank(s.EndDate), "ongoing", Text(s.EndDate, "mmm d, yyyy")) & " · " & s.SourceText))
```

`lblTrnStuCheck.Text`:
```
=With(
    {s: LookUp(colTrnStAll, StId = varTrnSelStId), p: rdoTrnStuPattern.Selected.Value},
    Switch(
        varTrnStuMode,
        "add", If(
            CountRows(cboTrnStuPick.SelectedItems) <> 1, "Pick a student (only students without active transportation are listed).",
            IsBlank(dpTrnStuStart.SelectedDate), "Choose the start date.",
            !(p in TransportPatternOptions.Value), "Choose the usual pattern.",
            "Ready: adds " & First(cboTrnStuPick.SelectedItems).StudentName & " from " & Text(dpTrnStuStart.SelectedDate, "mmm d, yyyy") & " as " & p & " (Source Manual)."
        ),
        "change", If(
            IsBlank(s) || !s.Active, "Choose Change pattern on an active row.",
            !(p in TransportPatternOptions.Value), "Choose the usual pattern.",
            p = s.Pattern && Trim(txtTrnStuNote.Text) = s.Note, "Nothing changed yet.",
            "Ready: saves " & p & " for " & s.StudentName & " (was " & s.Pattern & ")."
        ),
        "end", If(
            IsBlank(s) || !s.Active, "Choose End transportation on an active row.",
            IsBlank(dpTrnStuEnd.SelectedDate), "Choose the end date.",
            dpTrnStuEnd.SelectedDate < s.StartDate, "The end date cannot be before the start date (" & Text(s.StartDate, "mmm d, yyyy") & ").",
            "Ready: ends transportation for " & s.StudentName & " on " & Text(dpTrnStuEnd.SelectedDate, "mmm d, yyyy") & "."
        ),
        ""
    )
)
```

`btnTrnStuSave`: Width 170, Text `=Switch(varTrnStuMode, "add", "Add transportation", "change", "Save pattern", "end", "End transportation", "Save")`,
AccessibleLabel `=Self.Text`, BasePaletteColor `=If(varTrnStuMode = "end", ColorUnexcused, ColorTeal)`, Color ColorWhite,
DisplayMode `=If(CanClassify && !varTrnSaving && !varTrnLoading && StartsWith(lblTrnStuCheck.Text, "Ready"), DisplayMode.Edit, DisplayMode.Disabled)`,
OnSelect = formula S3 below. `btnTrnStuCancel`: Secondary "Cancel" Width 100, OnSelect
`=Set(varTrnStuMode, ""); Set(varTrnSelStId, Blank()); Reset(cboTrnStuPick); Reset(txtTrnStuNote)`.

## Engines (Classic/Button: AlignInContainer Stretch, AutoDisableOnSelect `=false`, LayoutMinHeight/Width 0, Visible `=false`, Text = short name)

### E1 `btnTrnStuLoadEngine.OnSelect` (Text "stu load")
```
=Set(varTrnLoading, true);
Set(varTrnLoadError, "");
If(
    !CanClassify || varTrnCampusId = ZeroGuid,
    Clear(colTrnStAll); Clear(colTrnCampEnr); Clear(colTrnCampStu),
    IfError(
        With(
            {c0: varTrnCampusId},
            Concurrent(
                ClearCollect(colTrnStAll, ForAll(Filter('Student Transportation', Campus.Campus = c0) As t, {StId: t.'Student Transportation', StRec: t, StudentId: t.Student.Student, StudentName: Coalesce(t.Student.'Display Name', "Unknown student"), KeyBase: With({k: Trim(Coalesce(t.Student.'External Client ID', ""))}, If(k = "", Coalesce(t.Student.'Student Number', ""), k)), Pattern: Text(t.'Usual Pattern'), StartDate: t.'Start Date', EndDate: t.'End Date', SourceText: Text(t.Source), Note: Coalesce(t.Note, ""), Active: IsBlank(t.'End Date') || t.'End Date' >= Today()})),
                ClearCollect(colTrnCampEnr, ForAll(Filter(Enrollments, Campus.Campus = c0 && (IsBlank('End Date') || 'End Date' >= Today())) As e, {StudentId: e.Student.Student, StudentName: Coalesce(e.Student.'Display Name', "Unnamed student"), KeyBase: With({k: Trim(Coalesce(e.Student.'External Client ID', ""))}, If(k = "", Coalesce(e.Student.'Student Number', ""), k)), StuRec: e.Student, CampRec: e.Campus}))
            )
        ); true,
        Set(varTrnLoadError, FirstError.Message)
    );
    ClearCollect(colTrnCampStu, Sort(ForAll(Distinct(colTrnCampEnr, StudentId) As g, With({en: LookUp(colTrnCampEnr, StudentId = g.Value)}, {StudentId: g.Value, StudentName: en.StudentName, KeyBase: en.KeyBase, StuRec: en.StuRec, CampRec: en.CampRec, Label: en.StudentName & " · " & en.KeyBase})), StudentName, SortOrder.Ascending))
);
Set(varTrnLoading, false)
```

### E2 `btnTrnLoadEngine.OnSelect` (Text "day load") - Daily list, school-day flag, pre-fill
```
=Set(varTrnLoading, true);
Set(varTrnLoadError, "");
If(
    !CanClassify || varTrnCampusId = ZeroGuid || IsBlank(varTrnDate),
    Clear(colTrnDaily); Set(varTrnIsSchoolDay, false); Set(varTrnDayReason, "no campus or date"),
    With(
        {c0: varTrnCampusId, d: varTrnDate},
        IfError(
            Concurrent(
                ClearCollect(colTrnDayTerms, Filter(Terms, 'Start Date' <= d && 'End Date' >= d)),
                ClearCollect(colTrnDayExc, Filter('Calendar Exceptions', Date = d)),
                ClearCollect(colTrnDayEnr, ForAll(Filter(Enrollments, Campus.Campus = c0 && 'Start Date' <= d && (IsBlank('End Date') || 'End Date' >= d)) As e, {EStudentId: e.Student.Student})),
                ClearCollect(colTrnDayAtt, ForAll(Filter(Attendance, Campus.Campus = c0 && Date = d && 'Is Deleted' = false) As r, {AStudentId: r.Student.Student, APresent: r.Present = true, ALeft: r.'Left Early' = true, AAt: r.'Left Early At'})),
                ClearCollect(colTrnDayLogs, ForAll(Filter('Daily Transport', Date = d) As g, {LStudentId: g.Student.Student, LogId: g.'Daily Transport', LStatus: Text(g.'Transport Status'), LBy: Coalesce(g.'Confirmed By'.'Full Name', ""), LOn: g.'Confirmed On'}))
            ); true,
            Set(varTrnLoadError, FirstError.Message)
        );
        With(
            {
                t: First(Filter(colTrnDayTerms, IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = c0)),
                x: LookUp(colTrnDayExc, (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = c0) && ThisRecord.Type <> 'Type (Calendar Exceptions)'.'Make-up School Day'),
                mk: !IsBlank(LookUp(colTrnDayExc, (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = c0) && ThisRecord.Type = 'Type (Calendar Exceptions)'.'Make-up School Day')),
                wk: Weekday(d, StartOfWeek.Monday) >= 6
            },
            Set(varTrnIsSchoolDay, !IsBlank(t) && (mk || (!wk && IsBlank(x))));
            Set(varTrnDayReason, If(IsBlank(t), "outside any term", mk, "", !IsBlank(x), Text(x.Type) & " – " & x.Description, wk, "weekend", ""))
        );
        ClearCollect(
            colTrnDaily,
            Sort(
                ForAll(
                    Filter(colTrnStAll, StartDate <= d && (IsBlank(EndDate) || EndDate >= d) && StudentId in colTrnDayEnr.EStudentId) As s,
                    With(
                        {a: LookUp(colTrnDayAtt, AStudentId = s.StudentId), lg: LookUp(colTrnDayLogs, LStudentId = s.StudentId)},
                        With(
                            {ak: If(IsBlank(a), "none", a.APresent && a.ALeft, "leftearly", a.APresent, "present", "absent")},
                            With(
                                {pf: Switch(ak, "absent", "No transportation", "leftearly", "Drop off only", "")},
                                {
                                    StudentId: s.StudentId, StId: s.StId, StRec: s.StRec, StudentName: s.StudentName, KeyBase: s.KeyBase, Pattern: s.Pattern,
                                    AttKind: ak,
                                    AttText: Switch(ak, "present", "Present", "leftearly", "Left early " & Text(a.AAt, "h:mm AM/PM"), "absent", "Absent", "Not marked"),
                                    LogId: Coalesce(lg.LogId, ZeroGuid),
                                    SavedStatus: Coalesce(lg.LStatus, ""),
                                    ByName: Coalesce(lg.LBy, ""),
                                    OnTime: lg.LOn,
                                    Prefill: pf,
                                    Pick: If(IsBlank(lg), pf, lg.LStatus)
                                }
                            )
                        )
                    )
                ),
                StudentName,
                SortOrder.Ascending
            )
        )
    )
);
Set(varTrnLoading, false)
```

### E3 `btnTrnBannerEngine.OnSelect` (Text "banner") - last 10 school days, Missing per day
```
=If(
    !CanClassify || varTrnCampusId = ZeroGuid,
    Clear(colTrnDays),
    With(
        {c0: varTrnCampusId, w0: DateAdd(Today(), -27, TimeUnit.Days), w1: Today()},
        IfError(
            Concurrent(
                ClearCollect(colTrnWinTerms, Filter(Terms, 'Start Date' <= w1 && 'End Date' >= w0)),
                ClearCollect(colTrnWinExc, Filter('Calendar Exceptions', Date >= w0 && Date <= w1)),
                ClearCollect(colTrnWinEnr, ForAll(Filter(Enrollments, Campus.Campus = c0 && 'Start Date' <= w1 && (IsBlank('End Date') || 'End Date' >= w0)) As e, {EStudentId: e.Student.Student, EStart: e.'Start Date', EEnd: e.'End Date'})),
                ClearCollect(colTrnWinLogs, ForAll(Filter('Daily Transport', Campus.Campus = c0 && Date >= w0 && Date <= w1) As g, {LStudentId: g.Student.Student, LDate: g.Date}))
            ); true,
            Set(varTrnLoadError, FirstError.Message)
        );
        ClearCollect(
            colTrnWinDays,
            ForAll(
                Sequence(28, 0) As n,
                With(
                    {d: DateAdd(w1, -n.Value, TimeUnit.Days)},
                    With(
                        {
                            t: First(Filter(colTrnWinTerms, ThisRecord.'Start Date' <= d && ThisRecord.'End Date' >= d && (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = c0))),
                            x: LookUp(colTrnWinExc, ThisRecord.Date = d && (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = c0) && ThisRecord.Type <> 'Type (Calendar Exceptions)'.'Make-up School Day'),
                            mk: !IsBlank(LookUp(colTrnWinExc, ThisRecord.Date = d && (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = c0) && ThisRecord.Type = 'Type (Calendar Exceptions)'.'Make-up School Day'))
                        },
                        {D: d, IsSchool: !IsBlank(t) && (mk || (Weekday(d, StartOfWeek.Monday) < 6 && IsBlank(x)))}
                    )
                )
            )
        );
        ClearCollect(
            colTrnDays,
            ForAll(
                FirstN(Sort(Filter(colTrnWinDays, IsSchool), D, SortOrder.Descending), 10) As dd,
                With(
                    {exp: Filter(colTrnStAll, StartDate <= dd.D && (IsBlank(EndDate) || EndDate >= dd.D) && StudentId in Filter(colTrnWinEnr, EStart <= dd.D && (IsBlank(EEnd) || EEnd >= dd.D)).EStudentId)},
                    {D: dd.D, Expected: CountRows(exp), Missing: CountRows(Filter(exp, !(StudentId in Filter(colTrnWinLogs, LDate = dd.D).LStudentId)))}
                )
            )
        )
    )
)
```

### E4 `btnTrnSaveEngine.OnSelect` (Text "save") - Confirm day (scope "day") and single-row change (scope "row")
```
=With(
    {d: varTrnDate, me: CurrentUserRow, n: CountRows(colTrnWork), scope: varTrnReq.Scope, cn: LookUp(colTrnCampusOpts, CampusId = varTrnCampusId).CampusName},
    If(
        !CanClassify || varTrnSaving || n = 0 || !varTrnIsSchoolDay || d > Today() || !(scope in ["day", "row"]),
        Set(varTrnReceipt, {Kind: "Blocked", Title: "Not saved. Choose a school day on or before today and a status for each student."}); Clear(colTrnReceiptLines),
        Set(varTrnSaving, true);
        Clear(colTrnLog);
        ForAll(
            colTrnWork As w,
            With(
                {r: LookUp(colTrnDaily, StudentId = w.StudentId)},
                With(
                    {
                        k: r.KeyBase & "|" & Text(d, "yyyy-mm-dd"),
                        st: Switch(w.Status, "Round trip", 'Transport Status (Daily Transport)'.'Round trip', "Drop off only", 'Transport Status (Daily Transport)'.'Drop off only', "Pick up only", 'Transport Status (Daily Transport)'.'Pick up only', "No transportation", 'Transport Status (Daily Transport)'.'No transportation')
                    },
                    With(
                        {live: If(IsBlank(r) || r.KeyBase = "", Blank(), LookUp('Daily Transport', 'Log Key' = k))},
                        With(
                            {
                                wr: If(
                                    IsBlank(r) || r.KeyBase = "" || IsBlank(st),
                                    Blank(),
                                    IfError(
                                        Patch(
                                            'Daily Transport',
                                            Coalesce(live, Defaults('Daily Transport')),
                                            {Summary: Left(r.KeyBase & " " & Text(d, "m/d") & " transport", 100), Student: r.StRec.Student, Campus: r.StRec.Campus, Date: d, 'Transport Status': st, 'Confirmed On': Now(), 'Confirmed By': me, 'Log Key': k}
                                        ),
                                        Blank()
                                    )
                                )
                            },
                            With(
                                {au: If(!IsBlank(wr), IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Transport " & k & " " & Text(wr.'Transport Status'), 100), Action: If(IsBlank(live), 'Action (Audit Events)'.Create, 'Action (Audit Events)'.Update), Entity: "aaca_transportlog", 'Entity ID': Text(wr.'Daily Transport'), Before: If(IsBlank(live), "", JSON({Status: Text(live.'Transport Status'), ConfirmedBy: Coalesce(live.'Confirmed By'.'Full Name', ""), ConfirmedOn: Text(live.'Confirmed On', "yyyy-mm-dd hh:mm")})), After: JSON({Status: Text(wr.'Transport Status'), ConfirmedBy: Coalesce(wr.'Confirmed By'.'Full Name', ""), ConfirmedOn: Text(wr.'Confirmed On', "yyyy-mm-dd hh:mm")}), Reason: If(scope = "row", "Changed after confirmation", "Daily transport confirmed")}), Blank()))},
                                If(!IsBlank(wr), Patch(colTrnDaily, r, {LogId: wr.'Daily Transport', SavedStatus: Text(wr.'Transport Status'), Pick: Text(wr.'Transport Status'), ByName: Coalesce(wr.'Confirmed By'.'Full Name', ""), OnTime: wr.'Confirmed On'}));
                                Collect(colTrnLog, {StudentName: Coalesce(r.StudentName, "Unknown student"), Before: If(IsBlank(live), "", Text(live.'Transport Status')), Status: If(IsBlank(wr), w.Status, Text(wr.'Transport Status')), ByName: If(IsBlank(wr), "", Coalesce(wr.'Confirmed By'.'Full Name', "")), OnText: If(IsBlank(wr), "", Text(wr.'Confirmed On', "h:mm AM/PM")), LogKey: k, Outcome: If(IsBlank(wr), "failed", IsBlank(live), "created", "updated"), AuditOk: !IsBlank(au)})
                            )
                        )
                    )
                )
            )
        );
        With(
            {cr: CountRows(Filter(colTrnLog, Outcome = "created")), up: CountRows(Filter(colTrnLog, Outcome = "updated")), fl: CountRows(Filter(colTrnLog, Outcome = "failed")), g: First(colTrnLog)},
            If(
                scope = "row",
                Set(varTrnReceipt, {Kind: If(fl > 0, "Failed", "Updated"), Title: If(fl > 0, "Not saved · " & g.StudentName & " · " & Text(d, "ddd mmm d") & " · the save failed; click the status again to retry", "Updated · " & g.StudentName & " · " & Text(d, "ddd mmm d") & " · " & g.Status & If(g.Before = "", "", " (was " & g.Before & ")"))});
                ClearCollect(
                    colTrnReceiptLines,
                    {Label: "Student", Value: g.StudentName},
                    {Label: "Date", Value: Text(d, "ddd mmm d, yyyy")},
                    {Label: "Before", Value: If(g.Before = "", "No row", g.Before)},
                    {Label: "Now", Value: If(fl > 0, "Not saved", g.Status)},
                    {Label: "Confirmed by", Value: If(fl > 0, "—", g.ByName)},
                    {Label: "Confirmed at", Value: If(fl > 0, "—", g.OnText)},
                    {Label: "Log key", Value: g.LogKey},
                    {Label: "Audit event", Value: If(g.AuditOk, If(g.Outcome = "created", "Create written", "Update written"), "NOT written")}
                ),
                Set(varTrnReceipt, {Kind: If(cr + up = 0, "Failed", "Confirmed"), Title: "Day confirmed · " & Text(d, "ddd mmm d, yyyy") & " · " & (cr + up) & " saved (" & cr & " created, " & up & " updated), " & fl & " failed"});
                ClearCollect(
                    colTrnReceiptLines,
                    {Label: "Operation", Value: "Confirm day"},
                    {Label: "Date", Value: Text(d, "ddd mmm d, yyyy")},
                    {Label: "Campus", Value: cn},
                    {Label: "Confirmed by", Value: Coalesce(LookUp(colTrnLog, ByName <> "").ByName, "—")},
                    ForAll(colTrnLog As g2, {Label: g2.StudentName, Value: If(g2.Outcome = "failed", "FAILED · not saved", g2.Status & " · " & g2.Outcome & If(g2.AuditOk, " · audit written", " · audit NOT written"))})
                )
            )
        );
        Clear(colTrnWork);
        Set(varTrnSaving, false)
    )
)
```

### S3 `btnTrnStuSave.OnSelect` - Add / Change pattern / End (one literal guard per mode)
```
=With(
    {
        mode: varTrnStuMode,
        s: LookUp(colTrnStAll, StId = varTrnSelStId),
        p: rdoTrnStuPattern.Selected.Value,
        note: Left(Trim(txtTrnStuNote.Text), 2000),
        stu: First(cboTrnStuPick.SelectedItems),
        sd: dpTrnStuStart.SelectedDate,
        ed: dpTrnStuEnd.SelectedDate
    },
    With(
        {pat: Switch(p, "Round trip", 'Usual Pattern (Student Transportation)'.'Round trip', "Drop off only", 'Usual Pattern (Student Transportation)'.'Drop off only', "Pick up only", 'Usual Pattern (Student Transportation)'.'Pick up only')},
        If(
            !CanClassify || varTrnSaving || !StartsWith(lblTrnStuCheck.Text, "Ready"),
            Set(varTrnReceipt, {Kind: "Blocked", Title: "Not saved. " & lblTrnStuCheck.Text}); Clear(colTrnReceiptLines),
            mode = "add",
            Set(varTrnSaving, true);
            With(
                {dup: With({q: stu.StudentId, c0: varTrnCampusId}, LookUp('Student Transportation', Student.Student = q && Campus.Campus = c0 && (IsBlank('End Date') || 'End Date' >= Today())))},
                If(
                    !IsBlank(dup),
                    Set(varTrnReceipt, {Kind: "Blocked", Title: "Not saved · " & stu.StudentName & " already has active transportation (added by someone else). Use Reload."}); Clear(colTrnReceiptLines),
                    With(
                        {wr: IfError(Patch('Student Transportation', Defaults('Student Transportation'), {Summary: Left(stu.KeyBase & " - transportation", 100), Student: stu.StuRec, Campus: stu.CampRec, 'Start Date': sd, 'Usual Pattern': pat, Source: 'Source (Student Transportation)'.Manual, Note: note}), Blank())},
                        If(
                            IsBlank(wr),
                            Set(varTrnReceipt, {Kind: "Failed", Title: "Not saved · " & stu.StudentName & " · the save failed; press Add transportation to retry"}); Clear(colTrnReceiptLines),
                            With(
                                {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Transportation added " & wr.Summary, 100), Action: 'Action (Audit Events)'.Create, Entity: "aaca_studenttransport", 'Entity ID': Text(wr.'Student Transportation'), Before: "", After: JSON({Pattern: Text(wr.'Usual Pattern'), Start: Text(wr.'Start Date', "yyyy-mm-dd"), Source: Text(wr.Source), Note: Coalesce(wr.Note, "")}), Reason: "Added in Transportation, Students"}), Blank())},
                                Collect(colTrnStAll, {StId: wr.'Student Transportation', StRec: wr, StudentId: stu.StudentId, StudentName: stu.StudentName, KeyBase: stu.KeyBase, Pattern: Text(wr.'Usual Pattern'), StartDate: wr.'Start Date', EndDate: wr.'End Date', SourceText: Text(wr.Source), Note: Coalesce(wr.Note, ""), Active: true});
                                Set(varTrnSelStId, wr.'Student Transportation');
                                Set(varTrnReceipt, {Kind: "Added", Title: "Transportation added · " & stu.StudentName & " · " & Text(wr.'Usual Pattern') & " from " & Text(wr.'Start Date', "mmm d, yyyy")});
                                ClearCollect(
                                    colTrnReceiptLines,
                                    {Label: "Student", Value: stu.StudentName},
                                    {Label: "Student key", Value: stu.KeyBase},
                                    {Label: "Pattern", Value: Text(wr.'Usual Pattern')},
                                    {Label: "Start", Value: Text(wr.'Start Date', "mmm d, yyyy")},
                                    {Label: "End", Value: If(IsBlank(wr.'End Date'), "ongoing", Text(wr.'End Date', "mmm d, yyyy"))},
                                    {Label: "Source", Value: Text(wr.Source)},
                                    {Label: "Note", Value: If(Coalesce(wr.Note, "") = "", "None", wr.Note)},
                                    {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Create written")}
                                );
                                Set(varTrnStuMode, ""); Reset(cboTrnStuPick); Reset(txtTrnStuNote)
                            )
                        )
                    )
                )
            );
            Set(varTrnSaving, false),
            mode = "change",
            Set(varTrnSaving, true);
            With(
                {live: With({q: s.StId}, LookUp('Student Transportation', ThisRecord.'Student Transportation' = q))},
                If(
                    IsBlank(live) || (!IsBlank(live.'End Date') && live.'End Date' < Today()),
                    Set(varTrnReceipt, {Kind: "Blocked", Title: "Not saved · " & s.StudentName & " · this transportation row was removed or has ended. Use Reload."}); Clear(colTrnReceiptLines),
                    With(
                        {wr: IfError(Patch('Student Transportation', live, {'Usual Pattern': pat, Note: note}), Blank())},
                        If(
                            IsBlank(wr),
                            Set(varTrnReceipt, {Kind: "Failed", Title: "Not saved · " & s.StudentName & " · the save failed; press Save pattern to retry"}); Clear(colTrnReceiptLines),
                            With(
                                {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Transportation pattern " & wr.Summary, 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_studenttransport", 'Entity ID': Text(wr.'Student Transportation'), Before: JSON({Pattern: Text(live.'Usual Pattern'), Note: Coalesce(live.Note, "")}), After: JSON({Pattern: Text(wr.'Usual Pattern'), Note: Coalesce(wr.Note, "")}), Reason: "Pattern changed in Transportation, Students"}), Blank())},
                                Patch(colTrnStAll, s, {Pattern: Text(wr.'Usual Pattern'), Note: Coalesce(wr.Note, ""), StRec: wr});
                                Set(varTrnReceipt, {Kind: "Changed", Title: "Pattern saved · " & s.StudentName & " · " & Text(wr.'Usual Pattern') & " (was " & Text(live.'Usual Pattern') & ")"});
                                ClearCollect(
                                    colTrnReceiptLines,
                                    {Label: "Student", Value: s.StudentName & " · " & s.KeyBase},
                                    {Label: "Pattern before", Value: Text(live.'Usual Pattern')},
                                    {Label: "Pattern now", Value: Text(wr.'Usual Pattern')},
                                    {Label: "Note", Value: If(Coalesce(wr.Note, "") = "", "None", wr.Note)},
                                    {Label: "Start", Value: Text(wr.'Start Date', "mmm d, yyyy")},
                                    {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Update written")}
                                );
                                Set(varTrnStuMode, "")
                            )
                        )
                    )
                )
            );
            Set(varTrnSaving, false),
            mode = "end",
            Set(varTrnSaving, true);
            With(
                {live: With({q: s.StId}, LookUp('Student Transportation', ThisRecord.'Student Transportation' = q))},
                If(
                    IsBlank(live) || (!IsBlank(live.'End Date') && live.'End Date' < Today()) || ed < live.'Start Date',
                    Set(varTrnReceipt, {Kind: "Blocked", Title: "Not saved · " & s.StudentName & " · the row was removed or ended, or the end date is before the start date. Use Reload."}); Clear(colTrnReceiptLines),
                    With(
                        {wr: IfError(Patch('Student Transportation', live, {'End Date': ed}), Blank())},
                        If(
                            IsBlank(wr),
                            Set(varTrnReceipt, {Kind: "Failed", Title: "Not saved · " & s.StudentName & " · the save failed; press End transportation to retry"}); Clear(colTrnReceiptLines),
                            With(
                                {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Transportation ended " & wr.Summary, 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_studenttransport", 'Entity ID': Text(wr.'Student Transportation'), Before: JSON({EndDate: If(IsBlank(live.'End Date'), "", Text(live.'End Date', "yyyy-mm-dd"))}), After: JSON({EndDate: Text(wr.'End Date', "yyyy-mm-dd")}), Reason: "Ended in Transportation, Students"}), Blank())},
                                Patch(colTrnStAll, s, {EndDate: wr.'End Date', Active: IsBlank(wr.'End Date') || wr.'End Date' >= Today(), StRec: wr});
                                Set(varTrnReceipt, {Kind: "Ended", Title: "Transportation ended · " & s.StudentName & " · " & Text(wr.'End Date', "mmm d, yyyy")});
                                ClearCollect(
                                    colTrnReceiptLines,
                                    {Label: "Student", Value: s.StudentName & " · " & s.KeyBase},
                                    {Label: "Pattern", Value: Text(wr.'Usual Pattern')},
                                    {Label: "Start", Value: Text(wr.'Start Date', "mmm d, yyyy")},
                                    {Label: "End", Value: Text(wr.'End Date', "mmm d, yyyy")},
                                    {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Update written")}
                                );
                                Set(varTrnStuMode, "")
                            )
                        )
                    )
                )
            );
            Set(varTrnSaving, false)
        )
    )
)
```

## Numeric layout budgets

- Nav: 16+110+8+110+8+110+8+140+16 = 526; wraps below that (Height 96+8 on phone).
- Tabs strip: 592 <= 640 one row; phone 104 <= 112.
- Banner (gap 4, padding 12): desktop 12+24+4+18+4+44+12 = 118; phone 138; no chips 70 / 90.
- Day panel (desktop, 3 rows): 16+44+8+58+8+36+8+44+8+(3*88 = 264)+16 = 510.
- Day row desktop: row inner at 1024 = 1024 - 32 (panel padding) - 16 (shell inset) - 16 (row padding) = 960 >=
  info min 300 + 8 + opts 544 = 852. Height 8 + max(22+4+18+4+18 = 66, 44) + 8 = 82 <= 88.
- Day row narrow (< 1024): 8 + info 102 + 8 + opts 96 + 8 = 222 <= 224. Phone options: row 1 Round trip + Drop off
  only = 248, row 2 Pick up only + No transportation = 288, both <= 311 (375 - 32 - 16 - 16).
- Confirm row: 190 + 8 + hint (FillPortions) on >= 640; phone 44 + 8 + 36 = 88.
- Students list head: 200 + 8 + 140 + 8 + 130 = 486 <= 645 (list inner at 1024); phone wraps to 96.
- Students row: desktop 8+22+4+36+4+44+8 = 126 <= 130; phone 8+40+4+54+4+96+8 = 214 <= 216; actions 150+8+170 = 328.
- Student panel (gap 4, padding 32): idle 28+4+54 = 86; add 28 + (18+36+18+36+18+96+18+36+54+44 = 374) + 10*4 = 442;
  change 28+54+(18+96+18+36+54+44 = 266) + 7*4 = 376; end 28+54+(18+36+54+44 = 152) + 5*4 = 254.
  Actions 170 + 8 + 100 = 278 <= 307 (detail inner at 1024).

## Text fit

- Status buttons: "No transportation" ≈ 128 + 24 padding = 152 <= 160; "Drop off only" ≈ 122 <= 130.
- `lblTrnDayMeta` / `lblTrnDayStatus` single line at >= 1024 (≈ 400 px available, ≤ 65 chars at Size 12); two lines
  (36) below 1024.
- `lblTrnStuCheck` 54 px = 3 lines; longest Ready text ≈ 110 chars fits at 307 px.

## Visual hierarchy

Header and tabs exactly like Absences. Banner warn/info band; panels white; panel titles 20/18 Bold; row identity 14
Semibold; meta 12; confirmed status teal Semibold; not-confirmed red when blank.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| trn-day-identity | galTrnDayList row | student + key | StudentName, KeyBase | lblTrnDayName | `=ThisItem.StudentName & " · " & ThisItem.KeyBase` | first line, always |
| trn-day-pattern-att | galTrnDayList row | usual pattern, attendance | Pattern, AttText | lblTrnDayMeta | see above | second line |
| trn-day-status | galTrnDayList row | saved status / confirmed by + time / not confirmed | SavedStatus, ByName, OnTime, Pick, Prefill, AttKind | lblTrnDayStatus | see above | third line |
| trn-day-choice | galTrnDayList row | current choice | Pick | btnTrnOpt* Appearance | `ThisItem.Pick = S` | buttons beside / below |
| trn-stu-identity | galTrnStuList row | student + key | StudentName, KeyBase, Active | lblTrnStuRowName | see above | first line |
| trn-stu-meta | galTrnStuList row | pattern, start - end, source, note | Pattern, StartDate, EndDate, SourceText, Note | lblTrnStuRowMeta | see above | second line |
| trn-banner-day | galTrnBannerDays | date + missing | D, Missing | btnTrnBannerDay.Text | see above | banner |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| trn-daily | conTrnDailyView | `=CanClassify && varTrnView = "daily"` | Daily tab / Students tab |
| trn-students | conTrnStuView | `=CanClassify && varTrnView = "students"` | Students tab / Daily tab |
| trn-denied | conTrnDenied | `=!CanClassify` | non-office roles |
| trn-receipt | conTrnReceipt | `=varTrnReceipt.Kind <> ""` (inside `conTrnBody`, Visible `=CanClassify`) | after a save attempt until Close |
| trn-stu-panel | conTrnStuPanel | `=conTrnRoot.Width >= 1024 \|\| varTrnStuMode <> ""` | desktop always; narrow only in a mode |

## Required Actions

Copy of the plan-index rows A-NAV-TRANSPORT, A-TRN-CAMPUS, A-TRN-TAB-DAILY, A-TRN-TAB-STUDENTS, A-TRN-STU-LOAD,
A-TRN-LOAD-DAY, A-TRN-PICK, A-TRN-CONFIRM-DAY, A-TRN-ROW-CHANGE, A-TRN-BANNER, A-TRN-BANNER-OPEN, A-TRN-SHOW-ENDED,
A-TRN-STU-ADD, A-TRN-STU-CHANGE, A-TRN-STU-END, A-TRN-STU-CANCEL. Implementation = the formulas above:

| Action | Entry point and event | Source and stable ID | Mutation write set | Receipt proof set |
| --- | --- | --- | --- | --- |
| A-TRN-PICK | btnTrnOpt*.OnSelect branch 1 | colTrnDaily by StudentId | colTrnDaily.Pick (local staging) | N/A (button + status line) |
| A-TRN-CONFIRM-DAY | btnTrnConfirm.OnSelect -> E4 scope "day" | 'Daily Transport' by Log Key; `wr.'Daily Transport'` | Summary, Student, Campus, Date, Transport Status, Confirmed On, Confirmed By, Log Key; Audit row | title counts; Operation, Date, Campus, Confirmed by, one line per student (`Text(wr.'Transport Status')` + created/updated + audit) |
| A-TRN-ROW-CHANGE | btnTrnOpt*.OnSelect branch 2 -> E4 scope "row" | same Log Key / LogId | Transport Status, Confirmed On, Confirmed By; Audit Update | Student, Date, Before (live), Now (wr), Confirmed by, Confirmed at, Log key, Audit |
| A-TRN-STU-ADD | btnTrnStuSave (mode "add") | new `wr.'Student Transportation'` | Summary, Student, Campus, Start Date, Usual Pattern, Source Manual, Note; Audit Create | Student, Student key, Pattern, Start, End, Source, Note, Audit |
| A-TRN-STU-CHANGE | btnTrnStuSave (mode "change") | varTrnSelStId -> live | Usual Pattern, Note; Audit Update | Student, Pattern before, Pattern now, Note, Start, Audit |
| A-TRN-STU-END | btnTrnStuSave (mode "end") | varTrnSelStId -> live | End Date; Audit Update | Student, Pattern, Start, End, Audit |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| ddTrnCampus | lblTrnCampus `="Campus"` | conTrnHdrTabs |
| dpTrnDate | lblTrnDate `="Date"` | conTrnDateField |
| cboTrnStuPick | lblTrnStuPick `="Student *"` | conTrnStuPanel |
| dpTrnStuStart | lblTrnStuStart `="Start date *"` | conTrnStuPanel |
| rdoTrnStuPattern | lblTrnStuPattern `="Usual pattern *"` | conTrnStuPanel |
| txtTrnStuNote | lblTrnStuNote `="Note (optional)"` | conTrnStuPanel |
| dpTrnStuEnd | lblTrnStuEnd `="End date *"` | conTrnStuPanel |

## Mutation Lifecycle Evidence

See plan index rows A-TRN-CONFIRM-DAY, A-TRN-ROW-CHANGE, A-TRN-STU-ADD, A-TRN-STU-CHANGE, A-TRN-STU-END: receipt from
`wr`; colTrnDaily / colTrnStAll patched from `wr` on success only; banner re-queried after Confirm day; new ST row
focused by `varTrnSelStId`.

## Functional Test Scenarios

Owned: S-NAV-TRANSPORT (current button), S-NAV-ROLE, S-TRN-TABS, S-TRN-CAMPUS, S-TRN-DAILY-LIST,
S-TRN-CONFIRM-DISABLED, S-TRN-CONFIRM, S-TRN-UPSERT, S-TRN-ROW-CHANGE, S-TRN-BANNER, S-TRN-NONSCHOOL, S-TRN-STU-LIST,
S-TRN-STU-ADD, S-TRN-STU-ADD-INVALID, S-TRN-STU-CHANGE, S-TRN-STU-END, S-TRN-ROLE - copy the rows (Given / When /
Then / Evidence / Boundary) from the plan index Functional Test Matrix; fixtures are listed above that table.
Key traces:
- S-TRN-DAILY-LIST 10/5: Jane AttText "Left early 1:30 PM" Pick "Drop off only" (pre-filled), Max "Absent" -> "No
  transportation" (pre-filled), Ida "Present" -> blank; Ann excluded by enrollment end 9/30; Lee excluded by ST end.
- S-TRN-CONFIRM: Log Keys `CW-1001|2026-10-05`, `CW-1002|2026-10-05`, `CW-1003|2026-10-05`; rows then read
  "Confirmed by Ortiz, Olga at h:mm PM · <status>"; Confirm button "All confirmed" (disabled).
- S-TRN-ROW-CHANGE: same LogId, receipt "Updated · Doe, Jane · Mon Oct 5 · Round trip (was Drop off only)".
- S-TRN-BANNER: "4 school days not confirmed · last 10 school days at Chatsworth"; chips Tue 10/6 (3), Mon 10/5 (3),
  Fri 10/2 (1), Thu 10/1 (1).

## Relevant Data Source Schemas

- 'Student Transportation': 'Student Transportation' (GUID), Summary (required), Student (lookup Students), Campus
  (lookup Campuses), 'Start Date' (required Date), 'End Date' (Date, blank = ongoing), 'Usual Pattern'
  ('Usual Pattern (Student Transportation)': 'Round trip' | 'Drop off only' | 'Pick up only', required), Source
  ('Source (Student Transportation)': CodeMetro | Manual), Note (Text).
- 'Daily Transport': 'Daily Transport' (GUID), Summary (required), Student, Campus, Date (required), 'Transport Status'
  ('Transport Status (Daily Transport)': 'Round trip' | 'Drop off only' | 'Pick up only' | 'No transportation',
  required), 'Confirmed On' (DateTime), 'Confirmed By' (lookup Users), Note, 'Log Key' (unique Text). Its Student
  Transportation lookup is NOT exposed - never reference it.
- Attendance: Student, Campus, Date, Present, 'Is Deleted', 'Left Early', 'Left Early At'.
- Enrollments: Student (+'Display Name', 'Student Number', 'External Client ID'), Campus, 'Start Date', 'End Date'.
- Students: Student, 'Display Name', 'Student Number', 'External Client ID'. Users: 'Full Name'.
- Terms: 'Start Date', 'End Date', Campus. 'Calendar Exceptions': Date, Campus, Type, Description. Campuses: Campus, Name.
- 'Audit Events': Summary, Action, Entity, 'Entity ID', Before, After, Reason.

## Required Variants

- GroupContainer -> `Variant: AutoLayout` (every container).
- Gallery -> `Variant: Vertical` (galTrnReceipt, galTrnDayList, galTrnStuList); `Variant: Horizontal` (galTrnBannerDays).

## Control Definitions

(From the discovery packet `describe_control` results; property names valid for this screen.)

- GroupContainer (`Control: GroupContainer` + Variant): BorderColor, BorderStyle [BorderStyle], BorderThickness,
  DropShadow [DropShadow], Fill, Height, RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft, RadiusTopRight, Visible,
  Width; AutoLayout: LayoutAlignItems [LayoutAlignItems], LayoutDirection [LayoutDirection] (required), LayoutGap,
  LayoutJustifyContent [LayoutJustifyContent], LayoutOverflowX/LayoutOverflowY [LayoutOverflow], LayoutWrap,
  PaddingBottom/Left/Right/Top; as child: AlignInContainer [AlignInContainer], FillPortions, LayoutMaxHeight,
  LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth.
- ModernText (`Control: ModernText`): AccessibleLabel, Align [Align], AlignInContainer, AutoHeight, Color, FillPortions,
  FontWeight [FontWeight], Height, LayoutMinHeight, LayoutMinWidth, PaddingBottom/Left/Right/Top, Size, Text,
  VerticalAlign [VerticalAlign], Visible, Width, Wrap.
- ModernButton (`Control: ModernButton`; NO Fill): AccessibleLabel, AlignInContainer, Appearance [ButtonAppearance],
  BasePaletteColor, Color, DisplayMode [DisplayMode], FillPortions, Height, Layout [ButtonLayout], LayoutMinHeight,
  LayoutMinWidth, OnSelect, PaddingLeft, PaddingRight, Size, Text, Tooltip, Visible, Width.
- Classic/Button (`Control: Classic/Button`; NO AccessibleLabel): AlignInContainer, AutoDisableOnSelect,
  LayoutMinHeight, LayoutMinWidth, OnSelect, Text, Visible.
- Gallery (`Control: Gallery` + Variant): AccessibleLabel, FillPortions, Height, Items, LayoutMinHeight,
  LayoutMinWidth, Selectable, ShowScrollbar, TabIndex, TemplatePadding, TemplateSize, Visible, Width, WrapCount.
  Outputs TemplateWidth, TemplateHeight.
- ModernDropdown (`Control: ModernDropdown`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  Default, DisplayMode, Height, ItemDisplayText, Items, LayoutMinHeight, LayoutMinWidth, OnChange, Visible, Width.
- ModernCombobox (`Control: ModernCombobox`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  DefaultSelectedItems, DisplayMode, Height, InputTextPlaceholder, IsSearchable, ItemDisplayText, Items,
  LayoutMinHeight, LayoutMinWidth, SelectMultiple, Visible. Output SelectedItems.
- ModernDatePicker (`Control: ModernDatePicker`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  DefaultDate, DisplayMode, EndDate, Format [DatePickerFormat], Height, LayoutMinHeight, LayoutMinWidth, OnChange,
  StartDate, Visible. Output SelectedDate.
- ModernTextInput (`Control: ModernTextInput`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  Default, DisplayMode, Height, LayoutMinHeight, LayoutMinWidth, MaxLength, Placeholder, Type [TextInputType], Visible.
  Output Text.
- ModernRadio (`Control: ModernRadio`): AccessibleLabel, AlignInContainer, Color, Default, DisplayMode, Height,
  ItemDisplayText, Items, Layout [OptionLayout], LayoutMinHeight, LayoutMinWidth, OnChange, Visible. Output Selected.
- ModernCheckbox (`Control: ModernCheckbox`): AccessibleLabel, AlignInContainer, Color, Default, DisplayMode, Height,
  Label, LayoutMinHeight, LayoutMinWidth, OnCheck, OnUncheck, Visible, Width. Output Checked.

Compile-ready enum literals: `ButtonAppearance.Primary`, `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`,
`Appearance.Outline`, `DatePickerFormat.Short`, `OptionLayout.Vertical`, `DisplayMode.Edit`, `DisplayMode.Disabled`,
`LayoutDirection.Horizontal`, `LayoutDirection.Vertical`, `LayoutAlignItems.Stretch`, `LayoutAlignItems.Center`,
`LayoutAlignItems.Start`, `AlignInContainer.Stretch`, `AlignInContainer.Center`, `AlignInContainer.Start`,
`LayoutOverflow.Scroll`, `FontWeight.Bold`, `FontWeight.Semibold`, `VerticalAlign.Top`, `DropShadow.None`.

YAML: every formula containing `: ` or ` #` is a `|-` block (record literals `{Scope: "day"}`, `{Value: ...}`,
`{Pick: ...}`, captions like `"Usual: "`, `"Ready: "`, `"Note: "`). No glyphs. The en dash "–" used in
`varTrnDayReason` and the count label matches Screen1's existing text; replace with "-" if the compiler complains.
