# Screen Plan: Staff (NEW)

## Assignment

- Action: Create
- Target file: `C:\src\aaca-attendance\app\StaffScreen.pa.yaml`
- YAML key: StaffScreen
- Control name prefix: Stf

Read `canvas-app-shared.md` first (palette, nav pattern, data semantics, YAML rules, App seeds). Copy property shapes
from `C:\src\aaca-attendance\app\TransportScreen.pa.yaml`: header `conTrnHeader` (lines 39-269), denied panel
`conTrnDenied`, receipt `conTrnReceipt`, and the Students view (`conTrnStuView`, `conTrnStuListPanel`, `galTrnStuList`,
`conTrnStuPanel`) - renamed to `Stf` and with the values below. Do not edit TransportScreen.pa.yaml.

## Specification

- Purpose: office managers and admins list staff at a campus, add teachers, edit them, retire / reactivate them,
  and bulk-transfer a teacher's class to another teacher. Teachers / Read-only / not-set-up users see a denied panel.
- Breakpoint source: `conStfRoot.Width` only (phone `< 640`, narrow `< 1024`). Screen `Fill: =ColorPaper`.
- Selected person: `p` = `LookUp(colStfAll, StaffId = varStfSelId)` (written inline wherever needed).

### Control tree (exact names and order)

```
StaffScreen
└ conStfRoot                       root (sole top-level child)
  ├ conStfHeader                   Ink band (no side padding)
  │ ├ lblStfTitle
  │ ├ lblStfIdentity
  │ ├ conStfNav                    btnStfNavAttendance, btnStfNavStudents, btnStfNavAbsences, btnStfNavTransport, btnStfNavStaff
  │ └ conStfHdrBar                 paper strip: lblStfCampus, ddStfCampus
  ├ conStfDenied                   lblStfDeniedTitle, lblStfDeniedBody, btnStfDeniedBack
  ├ conStfBody
  │ ├ conStfReceipt                conStfReceiptTop(lblStfReceiptTitle, btnStfReceiptClose), galStfReceipt(conStfRcptRow: lblStfRcptLabel, lblStfRcptValue)
  │ └ conStfView                   two-panel body
  │   ├ conStfListPanel
  │   │ ├ conStfListHead           lblStfListTitle, btnStfAdd
  │   │ ├ conStfListTools          txtStfSearch, tglStfRetired
  │   │ ├ lblStfListNote
  │   │ └ galStfList               conStfRow: conStfRowInfo(lblStfRowName, lblStfRowMeta, lblStfRowStatus), btnStfRowSelect
  │   └ conStfPanel                (children table below)
  ├ btnStfLoadEngine               hidden Classic/Button engines (Visible false)
  ├ btnStfFormResetEngine
  ├ btnStfXferLoadEngine
  ├ btnStfPlanEngine
  └ btnStfXferEngine
```

Control count: about 70 (comparable to TransportScreen). Do not add extra wrappers.

## Screen OnVisible

```
=Set(varStfSaving, false);
Set(varStfLoading, false);
Set(varStfMode, "");
Set(varStfSelId, Blank());
Set(varStfReceipt, {Kind: "", Title: ""});
Clear(colStfReceiptLines);
Clear(colStfPlan);
If(StudentCampusLock <> ZeroGuid, Set(varStfCampusId, StudentCampusLock));
ClearCollect(colStfCampusOpts, ForAll(Sort(Campuses, Name, SortOrder.Ascending) As c, {CampusId: c.Campus, CampusName: c.Name}));
If(varStfCampusId = ZeroGuid, Set(varStfCampusId, Coalesce(First(colStfCampusOpts).CampusId, ZeroGuid)));
Select(btnStfLoadEngine)
```

## Layout and properties by section

### Root `conStfRoot`
As `conTrnRoot`: DropShadow None, Fill `=ColorPaper`, Width `=Parent.Width`, Height `=Parent.Height`, LayoutMinWidth
`=0`, LayoutMinHeight `=0`, Vertical, Stretch, gap 8, LayoutOverflowY `=LayoutOverflow.Scroll`, PaddingBottom 16,
Radius* 0.

### Header `conStfHeader` (copy of `conTrnHeader`)
Fill `=ColorInk`, FillPortions 0, Vertical, Stretch, gap 4, PaddingTop 12, PaddingBottom
`=If(CanManageStudents, 0, 12)`, no side padding, Radius* 0, Height:
`=If(conStfRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conStfRoot.Width < 640, 152, 48), 0) + If(CanManageStudents, 60, 0)`
(desktop 12+28+4+20+4+52+4+60 = 184; phone 12+28+4+36+4+156+4+60 = 304).
- `lblStfTitle`, `lblStfIdentity`: exactly as `lblTrnTitle` / `lblTrnIdentity` (PaddingLeft/Right 16; identity Height
  `=If(conStfRoot.Width < 640, 36, 20)`).
- `conStfNav`: as `conTrnNav` but Height `=If(conStfRoot.Width < 640, 148, 44) + 8`, Visible `=CanManageStudents`.
  Five buttons per the shared nav table; `btnStfNavStaff` is CURRENT (BasePaletteColor ColorTeal, Color ColorWhite,
  AccessibleLabel `="Staff (current screen)"`, Visible `=CanManageStudents`, Width 80, OnSelect
  `=Navigate(StaffScreen)`); `btnStfNavTransport` Visible `=CanClassify`; the other four are Secondary.
- `conStfHdrBar`: Fill `=ColorPaper`, horizontal, LayoutAlignItems Center, gap 8, Padding 8 top/bottom 16 sides,
  Height 60, Visible `=CanManageStudents`, FillPortions 0, Radius* 0. Budget 16+56+8+220+16 = 316 <= 343 (phone).
  - `lblStfCampus`: as `lblTrnCampus` (Text `="Campus"`, Width 56, Height 20).
  - `ddStfCampus`: as `ddTrnCampus` with Items `=colStfCampusOpts`, ItemDisplayText `=ThisItem.CampusName`, Default
    `=LookUp(colStfCampusOpts, CampusId = varStfCampusId)`, Width 220, Height 36, DisplayMode
    `=If(StudentCampusLock = ZeroGuid && !varStfLoading && !varStfSaving, DisplayMode.Edit, DisplayMode.Disabled)`,
    OnChange:
    ```
    =Set(varStfCampusId, Coalesce(Self.Selected.CampusId, ZeroGuid));
    Set(varStfMode, "");
    Set(varStfSelId, Blank());
    Clear(colStfPlan);
    Select(btnStfLoadEngine)
    ```

### `conStfDenied` (copy of `conTrnDenied`)
Visible `=!CanManageStudents`. Title `="Staff is not available for your role"`; body
`=If(!StaffReady, "Your sign-in is not linked to an active Staff record. Ask your office manager to add you on the Staff screen.", "Only the Attendance Office and System Admin roles manage staff. Teachers and Read-only users record and view attendance on the Attendance screen.")`;
`btnStfDeniedBack` "Back to Attendance" `=Navigate(Screen1)`. Height formula as `conTrnDenied` with `conStfRoot`.

### `conStfBody`
Vertical, Stretch, gap 8, FillPortions 0, no fill, Visible `=CanManageStudents`, Height
`=If(conStfReceipt.Visible, conStfReceipt.Height + 8, 0) + conStfView.Height`.

### Receipt `conStfReceipt` (copy of `conTrnReceipt`, names `Stf`)
Fill `=Switch(varStfReceipt.Kind, "Failed", ColorErrorBg, "Blocked", ColorErrorBg, "Partial", ColorWarnBg, ColorInfoBg)`,
Visible `=varStfReceipt.Kind <> ""`, Height
`=8 + If(conStfRoot.Width < 640, 124, 64) + If(CountRows(colStfReceiptLines) > 0, 4 + galStfReceipt.Height, 0) + 8`.
- `conStfReceiptTop` and `lblStfReceiptTitle` Height `=If(conStfRoot.Width < 640, 124, 64)` (title up to 3 lines
  desktop / 6 phone); `lblStfReceiptTitle.Text: =varStfReceipt.Title`.
- `btnStfReceiptClose` Text "Close", Width 88, OnSelect (block) `=Set(varStfReceipt, {Kind: "", Title: ""}); Clear(colStfReceiptLines)`.
- `galStfReceipt`: Items `=colStfReceiptLines`, WrapCount `=If(conStfRoot.Width < 1024, 1, 2)`, TemplateSize
  `=If(conStfRoot.Width < 640, 88, 56)`, Height
  `=Min(560, RoundUp(CountRows(colStfReceiptLines) / If(conStfRoot.Width < 1024, 1, 2), 0) * If(conStfRoot.Width < 640, 88, 56))`,
  ShowScrollbar true, Visible `=CountRows(colStfReceiptLines) > 0`. Row `conStfRcptRow` as `conTrnRcptRow`;
  `lblStfRcptLabel` Width `=If(conStfRoot.Width < 640, 110, 160)`; `lblStfRcptValue` FillPortions 1.

### View `conStfView`
FillPortions 0, gap 8, Visible `=CanManageStudents`, LayoutDirection
`=If(conStfRoot.Width >= 1024, LayoutDirection.Horizontal, LayoutDirection.Vertical)`, LayoutAlignItems
`=If(conStfRoot.Width >= 1024, LayoutAlignItems.Start, LayoutAlignItems.Stretch)`, Height
`=If(conStfRoot.Width >= 1024, Max(conStfListPanel.Height, conStfPanel.Height), If(conStfListPanel.Visible, conStfListPanel.Height, 0) + If(conStfListPanel.Visible && conStfPanel.Visible, 8, 0) + If(conStfPanel.Visible, conStfPanel.Height, 0))`.

### List panel `conStfListPanel`
Panel style, vertical, Stretch, gap 8, padding 16, AlignInContainer
`=If(conStfRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)`, FillPortions
`=If(conStfRoot.Width >= 1024, 2, 0)`, Visible `=!(conStfRoot.Width < 1024 && varStfMode <> "")`, Height
`=16 + 44 + 8 + If(conStfRoot.Width < 640, 88, 44) + If(lblStfListNote.Visible, 8 + 36, 0) + If(galStfList.Visible, 8 + galStfList.Height, 0) + 16`.

Visible-rows filter `F` (write it out in each place it is used):
`Filter(colStfAll, (varStfShowRetired || IsActive) && (Trim(txtStfSearch.Text) = "" || Lower(Trim(txtStfSearch.Text)) in SearchKey))`

- `conStfListHead`: horizontal, Center, gap 8, Height 44, FillPortions 0.
  - `lblStfListTitle`: 18 Bold ink, FillPortions 1, LayoutMinWidth 150, Height 30, Wrap false, Text
    `="Staff at " & LookUp(colStfCampusOpts, CampusId = varStfCampusId).CampusName & " (" & CountRows(F) & ")"`.
  - `btnStfAdd`: Primary teal, Text `="Add teacher"`, Width 130, AccessibleLabel `="Add a teacher"`, DisplayMode
    `=If(CanManageStudents && !varStfSaving && !varStfLoading && varStfCampusId <> ZeroGuid, DisplayMode.Edit, DisplayMode.Disabled)`,
    OnSelect `=Set(varStfSelId, Blank()); Set(varStfMode, "add"); Select(btnStfFormResetEngine)`.
- `conStfListTools`: horizontal, LayoutWrap `=true`, Center, gap 8, FillPortions 0, Height
  `=If(conStfRoot.Width < 640, 88, 44)`:
  - `txtStfSearch`: ModernTextInput, Type `=TextInputType.Search`, Appearance Outline, Color ink, Width 240,
    Height 36, AlignInContainer Center, Placeholder `="Search name or email"`, AccessibleLabel
    `="Search staff by name or email"`, MaxLength 100, TriggerOutput `=TriggerOutput.Keypress`.
  - `tglStfRetired`: ModernToggle, Label `="Show retired"`, LabelPosition `=ToggleLabelPosition.After`,
    AccessibleLabel `="Show retired staff"`, Width 150, Height 44, AlignInContainer Center, Default
    `=varStfShowRetired`, OnCheck `=Set(varStfShowRetired, true)`, OnUncheck `=Set(varStfShowRetired, false)`.
  Budget: 240+8+150 = 398 <= 613 (list inner at 1024: 645 - 32); phone 311 -> wraps, 36+8+44 = 88.
- `lblStfListNote`: 13 ink, Height 36, VerticalAlign Top, Visible `=Self.Text <> ""`, Color
  `=If(varStfLoadError <> "", ColorUnexcused, ColorInk)`, Text (block):
  ```
  =If(
      varStfLoading, "Loading...",
      varStfLoadError <> "", "Could not load: " & varStfLoadError & ". Change campus or reopen the screen to try again.",
      CountRows(F) = 0, If(Trim(txtStfSearch.Text) <> "", "No staff match the search.", "No staff at this campus" & If(varStfShowRetired, "", " (retired staff are hidden)") & "."),
      ""
  )
  ```
- `galStfList`: Gallery `Variant: Vertical`, AccessibleLabel `="Staff list"`, Items
  `=SortByColumns(F, "StaffName", SortOrder.Ascending)`, FillPortions 0, Height
  `=Min(If(conStfRoot.Width < 640, 4, 7), CountRows(F)) * If(conStfRoot.Width < 640, 176, 88)`, TemplateSize
  `=If(conStfRoot.Width < 640, 176, 88)`, TemplatePadding 0, Selectable false, TabIndex 0, Visible `=CountRows(F) > 0`.
  - `conStfRow` shell: Width `=Parent.TemplateWidth - 16`, Height `=Parent.TemplateHeight`, padding 8, gap 8,
    BorderColor ColorRule, BorderThickness 1, Radius* 0, Fill
    `=If(ThisItem.StaffId = varStfSelId, ColorInfoBg, !ThisItem.IsActive, ColorNonSchool, ColorWhite)`,
    LayoutDirection `=If(conStfRoot.Width < 640, LayoutDirection.Vertical, LayoutDirection.Horizontal)`,
    LayoutAlignItems `=If(conStfRoot.Width < 640, LayoutAlignItems.Stretch, LayoutAlignItems.Center)`.
  - `conStfRowInfo`: vertical, Stretch, gap 4, FillPortions `=If(conStfRoot.Width < 640, 0, 1)`, Height
    `=If(conStfRoot.Width < 640, 102, 66)`, LayoutMinWidth `=If(conStfRoot.Width < 640, 0, 260)`.
    - `lblStfRowName`: 14 Semibold, Height `=If(conStfRoot.Width < 640, 40, 22)`, Wrap
      `=conStfRoot.Width < 640`, VerticalAlign Top, Color `=If(ThisItem.IsActive, ColorInk, ColorMuted)`, Text
      `=ThisItem.StaffName & " · " & If(ThisItem.Email = "", "no work email", ThisItem.Email)`.
    - `lblStfRowMeta`: 12, Height `=If(conStfRoot.Width < 640, 36, 18)`, VerticalAlign Top, Color as name, Text (block):
      `=ThisItem.RoleText & " · Students now: " & ThisItem.StudentsNow & " · Account: " & If(ThisItem.Linked, "Linked", "Waiting for account")`
    - `lblStfRowStatus`: 12 Semibold, Height 18, Wrap false, Color `=If(ThisItem.IsActive, ColorTeal, ColorMuted)`,
      Text `=If(ThisItem.IsActive, "Active", "Retired" & If(IsBlank(ThisItem.EndDate), "", " since " & Text(ThisItem.EndDate, "mmm d, yyyy")))`.
  - `btnStfRowSelect`: Width 100, AlignInContainer
    `=If(conStfRoot.Width < 640, AlignInContainer.Start, AlignInContainer.Center)`, Appearance
    `=If(ThisItem.StaffId = varStfSelId, ButtonAppearance.Primary, ButtonAppearance.Secondary)`, BasePaletteColor
    `=ColorTeal`, Color `=If(ThisItem.StaffId = varStfSelId, ColorWhite, ColorInk)`, Text
    `=If(ThisItem.StaffId = varStfSelId, "Selected", "Select")`, AccessibleLabel `="Select " & ThisItem.StaffName`,
    DisplayMode `=If(varStfSaving, DisplayMode.Disabled, DisplayMode.Edit)`, OnSelect
    `=Set(varStfSelId, ThisItem.StaffId); Set(varStfMode, ""); Clear(colStfPlan)`.

### Right panel `conStfPanel`
Panel style, vertical, Stretch, gap 4, padding 16, AlignInContainer as list panel, FillPortions
`=If(conStfRoot.Width >= 1024, 1, 0)`, Visible `=conStfRoot.Width >= 1024 || varStfMode <> "" || !IsBlank(varStfSelId)`,
Height:
```
=32 + Switch(
    varStfMode,
    "add", If(IsAdminRole, 512, 364),
    "edit", If(IsAdminRole, 588, 440),
    "transfer", 556 + If(galStfPlan.Visible, 4 + galStfPlan.Height, 0),
    "retire", 272,
    "reactivate", 210,
    If(IsBlank(varStfSelId), 104, 244)
)
```
Children in this order. Labels = field label style (12 Semibold `ColorMuted`, Height 18, Wrap false). Inputs:
Appearance Outline, Color ink, AlignInContainer Stretch, DisplayMode `=If(varStfSaving, DisplayMode.Disabled, DisplayMode.Edit)`.
"M" in Visible = `varStfMode`.

| # | Control | Key properties | Height | Visible |
| - | ------- | -------------- | ------ | ------- |
| 1 | lblStfPanelTitle | 18 Bold ink, Wrap false, Text `=Switch(varStfMode, "add", "Add teacher", "edit", "Edit staff member", "transfer", "Transfer class", "retire", "Retire", "reactivate", "Reactivate", "Staff details")` | 28 | always |
| 2 | lblStfFacts | 12 ink, VerticalAlign Top, Text F1 below | 72 | `=varStfMode <> "add"` |
| 3 | conStfSelActions | horizontal, LayoutWrap true, Center, gap 8, FillPortions 0: btnStfEdit, btnStfXfer, btnStfRetire, btnStfReactivate | 96 | `=varStfMode = "" && !IsBlank(varStfSelId)` |
| 4 | lblStfActionHint | 12 ink, VerticalAlign Top, Text F2 below | 36 | same as 3 |
| 5 | lblStfName | `="Name * (Last, First)"` | 18 | `=varStfMode in ["add", "edit"]` |
| 6 | txtStfName | AccessibleLabel `="Name, Last, First"`, Placeholder `="Last, First"`, MaxLength 100, Default `=If(varStfMode = "edit", LookUp(colStfAll, StaffId = varStfSelId).StaffName, "")` | 36 | add/edit |
| 7 | lblStfEmail | `="Work email *"` | 18 | add/edit |
| 8 | txtStfEmail | AccessibleLabel `="Work email"`, Placeholder `="name@autismacademy.org"`, MaxLength 100, Default `=If(varStfMode = "edit", LookUp(colStfAll, StaffId = varStfSelId).Email, "")` | 36 | add/edit |
| 9 | lblStfFormCampus | Text F3 below (Wrap false) | 18 | add/edit |
| 10 | ddStfFormCampus | AccessibleLabel `="Campus"`, Items `=colStfCampusOpts`, ItemDisplayText `=ThisItem.CampusName`, Default `=LookUp(colStfCampusOpts, CampusId = If(varStfMode = "edit", LookUp(colStfAll, StaffId = varStfSelId).CampusId, varStfCampusId))` | 36 | `=IsAdminRole && varStfMode in ["add", "edit"]` |
| 11 | lblStfRole | Text F4 below (Wrap false) | 18 | add/edit |
| 12 | rdoStfRole | ModernRadio AccessibleLabel `="App role"`, Items `=StaffRoleOptions`, Layout `=OptionLayout.Vertical`, Default (block) `={Value: If(varStfMode = "edit", LookUp(colStfAll, StaffId = varStfSelId).RoleText, "Teacher")}` | 104 | `=IsAdminRole && varStfMode in ["add", "edit"]` |
| 13 | lblStfXferTeacher | `="New teacher *"` | 18 | `=varStfMode = "transfer"` |
| 14 | ddStfXferTeacher | AccessibleLabel `="New teacher"`, Items `=SortByColumns(Filter(colStfAll, IsActive && RoleText = "Teacher" && StaffId <> varStfSelId), "StaffName", SortOrder.Ascending)`, ItemDisplayText `=ThisItem.StaffName` (no Default) | 36 | transfer |
| 15 | lblStfDate | Text `=Switch(varStfMode, "add", "Start date *", "edit", "Start date", "transfer", "Effective date (first day with the new teacher) *", "retire", "End date (last day) *", "Date")` | 18 | `=varStfMode in ["add", "edit", "transfer", "retire"]` |
| 16 | dpStfDate | ModernDatePicker, AccessibleLabel `=lblStfDate.Text`, Format `=DatePickerFormat.Short`, DefaultDate `=Switch(varStfMode, "edit", LookUp(colStfAll, StaffId = varStfSelId).StartDate, Today())`, StartDate `=Switch(varStfMode, "transfer", DateAdd(Today(), -30, TimeUnit.Days), "retire", Coalesce(LookUp(colStfAll, StaffId = varStfSelId).StartDate, Date(2000, 1, 1)), Date(2000, 1, 1))`, EndDate `=Switch(varStfMode, "transfer", DateAdd(Today(), 90, TimeUnit.Days), DateAdd(Today(), 365, TimeUnit.Days))`, OnChange `=If(varStfMode = "transfer", Set(varStfXferDate, Self.SelectedDate); Select(btnStfPlanEngine))` | 36 | same as 15 |
| 17 | lblStfNote | `="Note for the audit log (optional)"` | 18 | transfer |
| 18 | txtStfNote | AccessibleLabel `="Note for the audit log"`, Type `=TextInputType.Multiline`, MaxLength 500, Default `=""` | 64 | transfer |
| 19 | lblStfXferHelp | 12 ink, VerticalAlign Top, Text `="Each student's current enrollment ends the day before the effective date and a new one starts with the new teacher at the same IEP ratio. Attendance already recorded on or after that date stays with the old teacher."` | 88 | transfer |
| 20 | lblStfPlanSummary | 13 Semibold ink, VerticalAlign Top, Text F5 below | 36 | transfer |
| 21 | galStfPlan | preview gallery, spec below | `=Min(6, CountRows(colStfPlan)) * 72` | `=varStfMode = "transfer" && CountRows(colStfPlan) > 0` |
| 22 | lblStfCheck | 12, VerticalAlign Top, Color `=If(StartsWith(Self.Text, "Ready"), ColorExcused, ColorUnexcused)`, Text = C1 below | 54 | `=varStfMode <> ""` |
| 23 | conStfActions | horizontal, Center, gap 8, FillPortions 0: btnStfSave, btnStfCancel | 44 | `=varStfMode <> ""` |

Panel height arithmetic (gap 4, padding 32): idle none 28+72 +4 = 104; idle selected 28+72+96+36 + 12 = 244;
add admin 28 + 6 label/input pairs (54+54+54+122+54) + 54 + 44 = 464 + 12*4 = 512; add office drops ddStfFormCampus
(36) and rdoStfRole (104) and 2 gaps -> 364; edit adds facts 72+4 -> 588 / 440; transfer
28+72+54+54+82+88+36+54+44 = 512 + 11*4 = 556 (+4 + gallery); retire 28+72+54+54+44 = 252 + 5*4 = 272;
reactivate 28+72+54+44 = 198 + 3*4 = 210.

Selection actions (inside `conStfSelActions`; all Height 44; `p` = selected row):
- `btnStfEdit`: Secondary, Text "Edit", Width 80, AccessibleLabel `="Edit " & LookUp(colStfAll, StaffId = varStfSelId).StaffName`,
  DisplayMode `=With({p: LookUp(colStfAll, StaffId = varStfSelId)}, If(!IsBlank(p) && (IsAdminRole || p.RoleText = "Teacher") && !varStfSaving && !varStfLoading, DisplayMode.Edit, DisplayMode.Disabled))`,
  OnSelect `=Set(varStfMode, "edit"); Select(btnStfFormResetEngine)`.
- `btnStfXfer`: Secondary, Text "Transfer class", Width 140, Visible
  `=LookUp(colStfAll, StaffId = varStfSelId).RoleText = "Teacher"`, DisplayMode
  `=With({p: LookUp(colStfAll, StaffId = varStfSelId)}, If(p.IsActive && p.StudentsNow >= 1 && !varStfSaving && !varStfLoading, DisplayMode.Edit, DisplayMode.Disabled))`,
  OnSelect:
  ```
  =Set(varStfMode, "transfer");
  Set(varStfXferDate, Today());
  Clear(colStfPlan);
  Select(btnStfFormResetEngine);
  Select(btnStfXferLoadEngine);
  Select(btnStfPlanEngine)
  ```
- `btnStfRetire`: Secondary, Text "Retire", Width 90, Visible `=LookUp(colStfAll, StaffId = varStfSelId).IsActive`,
  DisplayMode
  `=With({p: LookUp(colStfAll, StaffId = varStfSelId)}, If(p.IsActive && p.StudentsNow = 0 && (IsAdminRole || p.RoleText = "Teacher") && p.StaffId <> CurrentStaff.Staff && !varStfSaving && !varStfLoading, DisplayMode.Edit, DisplayMode.Disabled))`,
  OnSelect `=Set(varStfMode, "retire"); Select(btnStfFormResetEngine)`.
- `btnStfReactivate`: Secondary, Text "Reactivate", Width 120, Visible `=!LookUp(colStfAll, StaffId = varStfSelId).IsActive`,
  DisplayMode `=With({p: LookUp(colStfAll, StaffId = varStfSelId)}, If(!IsBlank(p) && (IsAdminRole || p.RoleText = "Teacher") && !varStfSaving && !varStfLoading, DisplayMode.Edit, DisplayMode.Disabled))`,
  OnSelect `=Set(varStfMode, "reactivate")`.
  Budget: Edit + Transfer class = 228; + Retire = 326 > 307 (panel inner at 1024) -> wraps to row 2 (96 = 44+8+44).

F1 `lblStfFacts.Text`:
```
=With(
    {p: LookUp(colStfAll, StaffId = varStfSelId)},
    If(
        IsBlank(p), "Select a person in the list to see their details and actions, or press Add teacher.",
        p.StaffName & " · " & p.RoleText & Char(10) &
        If(p.Email = "", "No work email yet", p.Email) & Char(10) &
        p.CampusName & " · " & p.StudentsNow & If(p.StudentsNow = 1, " student", " students") & " now · " & If(p.Linked, "Account linked", "Waiting for account") & Char(10) &
        If(p.IsActive, "Active", "Retired") & If(IsBlank(p.StartDate), "", " · started " & Text(p.StartDate, "mmm d, yyyy")) & If(IsBlank(p.EndDate), "", " · ended " & Text(p.EndDate, "mmm d, yyyy"))
    )
)
```

F2 `lblStfActionHint.Text`:
```
=With(
    {p: LookUp(colStfAll, StaffId = varStfSelId)},
    If(
        IsBlank(p), "",
        !IsAdminRole && p.RoleText <> "Teacher", "Office staff can change teacher records only. Ask a System Admin.",
        p.IsActive && p.StudentsNow > 0, "Retire is not available. Transfer their class first (" & p.StudentsNow & If(p.StudentsNow = 1, " student", " students") & ").",
        p.IsActive && p.StaffId = CurrentStaff.Staff, "You cannot retire yourself.",
        p.IsActive && p.RoleText = "Teacher", "No students to transfer. Retire is available.",
        ""
    )
)
```

F3 `lblStfFormCampus.Text` (block):
`=If(IsAdminRole, "Campus *", "Campus: " & If(varStfMode = "edit", LookUp(colStfAll, StaffId = varStfSelId).CampusName, LookUp(colStfCampusOpts, CampusId = varStfCampusId).CampusName) & " (your campus)")`

F4 `lblStfRole.Text` (block):
`=If(IsAdminRole, "App role *", "App role: " & If(varStfMode = "edit", LookUp(colStfAll, StaffId = varStfSelId).RoleText, "Teacher"))`

F5 `lblStfPlanSummary.Text`:
```
=With(
    {mv: CountRows(Filter(colStfPlan, Action = "move")), ra: CountRows(Filter(colStfPlan, Action = "reassign")), sk: CountRows(Filter(colStfPlan, Action = "skip"))},
    If(
        varStfLoading, "Loading the class...",
        mv + ra + sk = 0, "No enrollments with this teacher are open on " & Text(varStfXferDate, "mmm d, yyyy") & ".",
        "Preview · " & mv & " will move, " & ra & " future enrollment(s) reassigned, " & sk & " skipped"
    )
)
```

`galStfPlan`: Gallery `Variant: Vertical`, AccessibleLabel `="Students who will move"`, Items
`=SortByColumns(colStfPlan, "StudentName", SortOrder.Ascending)`, TemplateSize 72, TemplatePadding 0, Selectable false,
TabIndex 0, FillPortions 0. Shell `conStfPlanRow` (vertical, Stretch, gap 4, PaddingTop/Bottom 4, PaddingLeft/Right 8,
Width `=Parent.TemplateWidth - 16`, Height `=Parent.TemplateHeight`, BorderColor ColorRule, BorderThickness 1, Fill
`=If(ThisItem.Action = "skip", ColorWarnBg, ColorWhite)`):
- `lblStfPlanName` 13 Semibold ink, Height 18, Wrap false: `=ThisItem.StudentName & " · " & ThisItem.StudentNumber`.
- `lblStfPlanMeta` 12 ink, Height 36, VerticalAlign Top, Text (block):
  `="IEP " & ThisItem.RatioText & " · since " & Text(ThisItem.StartDate, "mmm d, yyyy") & " · " & Switch(ThisItem.Action, "move", "Will move to the new teacher", "reassign", "Future enrollment reassigned: " & ThisItem.Reason, "Skipped: " & ThisItem.Reason)`
  Row 4+18+4+36+4 = 66 <= 72.

C1 `lblStfCheck.Text`:
```
=With(
    {
        p: LookUp(colStfAll, StaffId = varStfSelId),
        nm: Trim(txtStfName.Text),
        em: Lower(Trim(txtStfEmail.Text)),
        d: dpStfDate.SelectedDate,
        nt: ddStfXferTeacher.Selected,
        selfId: If(varStfMode = "edit", varStfSelId, ZeroGuid)
    },
    With(
        {
            cmpId: If(IsAdminRole, ddStfFormCampus.Selected.CampusId, varStfMode = "edit", p.CampusId, varStfCampusId),
            role: If(IsAdminRole, rdoStfRole.Selected.Value, varStfMode = "edit", p.RoleText, "Teacher"),
            dupRow: If(em = "", Blank(), LookUp(colStfEmails, StaffId <> selfId && (EmailL = em || UserEmailL = em))),
            mv: CountRows(Filter(colStfPlan, Action in ["move", "reassign"])),
            sk: CountRows(Filter(colStfPlan, Action = "skip"))
        },
        If(
            !CanManageStudents, "Not authorised to manage staff.",
            varStfMode in ["add", "edit"],
            If(
                varStfMode = "edit" && IsBlank(p), "Select a person first.",
                varStfMode = "edit" && !IsAdminRole && p.RoleText <> "Teacher", "Office staff can change teacher records only.",
                nm = "", "Enter the name as Last, First.",
                em = "", "Enter the work email.",
                " " in em || CountRows(Split(em, "@")) <> 2 || !EndsWith(em, "@autismacademy.org") || Len(em) <= 18, "The work email must look like name@autismacademy.org.",
                !IsBlank(dupRow), "That email already belongs to " & dupRow.StaffName & ".",
                IsBlank(cmpId) || cmpId = ZeroGuid, "Choose a campus.",
                !(role in StaffRoleOptions.Value), "Choose an app role.",
                varStfMode = "add" && IsBlank(d), "Choose the start date.",
                varStfMode = "edit" && !IsBlank(d) && !IsBlank(p.EndDate) && d > p.EndDate, "The start date cannot be after the end date (" & Text(p.EndDate, "mmm d, yyyy") & ").",
                varStfMode = "edit" && p.StudentsNow > 0 && (cmpId <> p.CampusId || role <> p.RoleText), "Transfer their class first (" & p.StudentsNow & " students) before changing campus or role.",
                varStfMode = "edit" && nm = p.StaffName && em = Lower(p.Email) && d = p.StartDate && cmpId = p.CampusId && role = p.RoleText, "No changes to save.",
                varStfMode = "add", "Ready: adds " & nm & " (" & em & ") as " & role & " from " & Text(d, "mmm d, yyyy") & ".",
                "Ready: saves the changes to " & p.StaffName & "."
            ),
            varStfMode = "transfer",
            If(
                IsBlank(p) || !p.IsActive || p.RoleText <> "Teacher", "Transfer class is only for an active teacher.",
                IsBlank(nt), "Choose the new teacher.",
                nt.StaffId = p.StaffId, "Choose a different teacher.",
                IsBlank(d), "Choose the effective date.",
                d < DateAdd(Today(), -30, TimeUnit.Days) || d > DateAdd(Today(), 90, TimeUnit.Days), "The effective date must be between " & Text(DateAdd(Today(), -30, TimeUnit.Days), "mmm d") & " and " & Text(DateAdd(Today(), 90, TimeUnit.Days), "mmm d, yyyy") & ".",
                Date(Year(d), Month(d), 1) in colStfLocks.MonthStart, Text(d, "mmmm yyyy") & " is locked at this campus. Choose a date in an open month.",
                varStfLoading || d <> varStfXferDate, "Updating the preview...",
                mv = 0, "Nothing to move on " & Text(d, "mmm d, yyyy") & If(sk > 0, " (" & sk & " skipped).", "."),
                "Ready: moves " & mv & " enrollment(s) from " & p.StaffName & " to " & nt.StaffName & " on " & Text(d, "mmm d, yyyy") & "."
            ),
            varStfMode = "retire",
            If(
                IsBlank(p) || !p.IsActive, "Choose Retire on an active person.",
                !IsAdminRole && p.RoleText <> "Teacher", "Office staff can retire teachers only.",
                p.StaffId = CurrentStaff.Staff, "You cannot retire yourself.",
                p.StudentsNow > 0, "Transfer their class first (" & p.StudentsNow & " students).",
                IsBlank(d), "Choose the end date.",
                !IsBlank(p.StartDate) && d < p.StartDate, "The end date cannot be before the start date (" & Text(p.StartDate, "mmm d, yyyy") & ").",
                "Ready: retires " & p.StaffName & " with end date " & Text(d, "mmm d, yyyy") & ". They will no longer be offered as a teacher."
            ),
            varStfMode = "reactivate",
            If(
                IsBlank(p) || p.IsActive, "Choose Reactivate on a retired person.",
                !IsAdminRole && p.RoleText <> "Teacher", "Office staff can reactivate teachers only.",
                "Ready: reactivates " & p.StaffName & " and clears the end date."
            ),
            ""
        )
    )
)
```

`btnStfSave`: Width 190, AccessibleLabel `=Self.Text`, Color ColorWhite, BasePaletteColor
`=If(varStfMode = "retire", ColorUnexcused, ColorTeal)`, Text
`=Switch(varStfMode, "add", "Add teacher", "edit", "Save changes", "transfer", "Transfer class (" & CountRows(Filter(colStfPlan, Action in ["move", "reassign"])) & ")", "retire", "Retire", "reactivate", "Reactivate", "Save")`,
DisplayMode `=If(CanManageStudents && !varStfSaving && !varStfLoading && StartsWith(lblStfCheck.Text, "Ready"), DisplayMode.Edit, DisplayMode.Disabled)`,
OnSelect = S1 below. `btnStfCancel`: Secondary "Cancel", Width 100, OnSelect
`=Set(varStfMode, ""); Clear(colStfPlan); Select(btnStfFormResetEngine)`. Budget 190+8+100 = 298 <= 307.

## Engines (Classic/Button: AlignInContainer Stretch, AutoDisableOnSelect `=false`, LayoutMinHeight/Width 0, Visible `=false`, Text = short name)

### E0 `btnStfFormResetEngine.OnSelect` (Text "reset")
`=Reset(txtStfName); Reset(txtStfEmail); Reset(ddStfFormCampus); Reset(rdoStfRole); Reset(ddStfXferTeacher); Reset(dpStfDate); Reset(txtStfNote)`

### E1 `btnStfLoadEngine.OnSelect` (Text "load")
```
=Set(varStfLoading, true);
Set(varStfLoadError, "");
If(
    !CanManageStudents || varStfCampusId = ZeroGuid,
    Clear(colStfAll); Clear(colStfEnr); Clear(colStfLocks),
    With(
        {c0: varStfCampusId, t0: Today()},
        IfError(
            Concurrent(
                ClearCollect(colStfEnr, ForAll(Filter(Enrollments, Campus.Campus = c0 && (IsBlank('End Date') || 'End Date' >= t0)) As e, {EnrId: e.Enrollment, TeacherId: e.Teacher.Staff})),
                ClearCollect(colStfEmails, ForAll(Staff As s, {StaffId: s.Staff, StaffName: s.Name, EmailL: Lower(Trim(Coalesce(s.Email, ""))), UserEmailL: Lower(Trim(Coalesce(s.User.'Primary Email', "")))})),
                ClearCollect(colStfLocks, ForAll(Filter('Month Locks', Campus.Campus = c0 && 'Status (aaca_status)' = 'Status (Month Locks)'.Locked) As m, {MonthStart: m.Month}))
            );
            ClearCollect(colStfAll, ForAll(Filter(Staff, Campus.Campus = c0) As s, {StaffId: s.Staff, StaffName: s.Name, Email: Coalesce(s.Email, ""), RoleText: Text(s.'App Role'), CampusId: s.Campus.Campus, CampusName: s.Campus.Name, StartDate: s.'Start Date', EndDate: s.'End Date', IsActive: s.Active <> false, Linked: !IsBlank(s.User), StudentsNow: CountRows(Filter(colStfEnr, TeacherId = s.Staff)), SearchKey: Lower(s.Name & " " & Coalesce(s.Email, ""))}));
            true,
            Set(varStfLoadError, FirstError.Message)
        )
    );
    If(!IsBlank(varStfSelId) && IsBlank(LookUp(colStfAll, StaffId = varStfSelId)), Set(varStfSelId, Blank()))
);
Set(varStfLoading, false)
```

### E2 `btnStfXferLoadEngine.OnSelect` (Text "class load") - the selected teacher's enrollments
```
=Set(varStfLoading, true);
Set(varStfLoadError, "");
If(
    IsBlank(varStfSelId),
    Clear(colStfXferEnr),
    With(
        {q: varStfSelId, w0: DateAdd(Today(), -31, TimeUnit.Days)},
        IfError(
            ClearCollect(colStfXferEnr, ForAll(Filter(Enrollments, Teacher.Staff = q && (IsBlank('End Date') || 'End Date' >= w0)) As e, {EnrId: e.Enrollment, StudentId: e.Student.Student, StudentName: Coalesce(e.Student.'Display Name', "Unnamed student"), StudentNumber: Coalesce(e.Student.'Student Number', ""), StudentStatus: Text(e.Student.'Status (aaca_status)'), ServiceId: e.Service.Service, RatioText: Text(e.'IEP Ratio'), StartDate: e.'Start Date', EndDate: e.'End Date', YearEnd: e.'School Year'.'End Date'})); true,
            Set(varStfLoadError, FirstError.Message)
        )
    )
);
Set(varStfLoading, false)
```

### E3 `btnStfPlanEngine.OnSelect` (Text "plan") - preview for `varStfXferDate`
```
=With(
    {d: varStfXferDate},
    ClearCollect(
        colStfPlan,
        ForAll(
            Filter(colStfXferEnr, IsBlank(EndDate) || EndDate >= d) As e,
            {
                EnrId: e.EnrId, StudentId: e.StudentId, StudentName: e.StudentName, StudentNumber: e.StudentNumber, RatioText: e.RatioText, StartDate: e.StartDate,
                Action: If(IsBlank(d), "skip", e.StartDate >= d, "reassign", !IsBlank(e.EndDate), "skip", e.StudentStatus <> "Active", "skip", !IsBlank(e.YearEnd) && d > e.YearEnd, "skip", "move"),
                Reason: If(
                    IsBlank(d), "no effective date",
                    e.StartDate > d, "planned enrollment starting " & Text(e.StartDate, "mmm d, yyyy") & " gets the new teacher",
                    e.StartDate = d, "starts on the effective date, so only the teacher changes",
                    !IsBlank(e.EndDate), "already ends " & Text(e.EndDate, "mmm d, yyyy") & " (a change is planned); use Change class on the Students screen",
                    e.StudentStatus <> "Active", "student is " & e.StudentStatus,
                    !IsBlank(e.YearEnd) && d > e.YearEnd, "the effective date is after the school year ends (" & Text(e.YearEnd, "mmm d, yyyy") & ")",
                    ""
                )
            }
        )
    )
)
```
Rules (from the requirement): open on eff and started before eff with no end date -> **move** (close + new, Change
class logic); starts on eff -> **reassign** (Patch Teacher only, no zero-length enrollment); starts after eff ->
**reassign** ("future enrollment reassigned"); everything else -> **skip** with the reason shown.

### S1 `btnStfSave.OnSelect` - one literal guard per mode
```
=With(
    {
        mode: varStfMode,
        p: LookUp(colStfAll, StaffId = varStfSelId),
        nm: Trim(txtStfName.Text),
        em: Lower(Trim(txtStfEmail.Text)),
        d: dpStfDate.SelectedDate
    },
    With(
        {
            cmpRec: With({q: If(IsAdminRole, ddStfFormCampus.Selected.CampusId, mode = "edit", p.CampusId, varStfCampusId)}, LookUp(Campuses, ThisRecord.Campus = q)),
            roleVal: With({r: If(IsAdminRole, rdoStfRole.Selected.Value, mode = "edit", p.RoleText, "Teacher")}, Switch(r, "Teacher", 'App Role (Staff)'.Teacher, "Attendance Office", 'App Role (Staff)'.'Attendance Office', "Read-only", 'App Role (Staff)'.'Read-only', "System Admin", 'App Role (Staff)'.'System Admin'))
        },
        If(
            !CanManageStudents || varStfSaving || !StartsWith(lblStfCheck.Text, "Ready"),
            Set(varStfReceipt, {Kind: "Blocked", Title: "Not saved. " & lblStfCheck.Text}); Clear(colStfReceiptLines),
            mode = "transfer",
            ClearCollect(colStfXferWork, Filter(colStfPlan, Action in ["move", "reassign"]));
            Select(btnStfXferEngine),
            mode = "add",
            Set(varStfSaving, true);
            With(
                {dup: With({q: em}, LookUp(Staff, Email = q))},
                If(
                    !IsBlank(dup),
                    Set(varStfReceipt, {Kind: "Blocked", Title: "Not saved · " & em & " already belongs to " & dup.Name & "."}); Clear(colStfReceiptLines),
                    With(
                        {wr: IfError(Patch(Staff, Defaults(Staff), {Name: nm, Email: em, Campus: cmpRec, 'Start Date': d, 'App Role': roleVal, Active: true, 'Finance Access': false, 'Site Administrator': false}), Blank())},
                        If(
                            IsBlank(wr),
                            Set(varStfReceipt, {Kind: "Failed", Title: "Not saved · " & nm & " · " & Coalesce(First(Errors(Staff)).Message, "the save failed") & ". Press Add teacher to retry."}); Clear(colStfReceiptLines),
                            With(
                                {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Staff added " & wr.Name & " " & wr.Email, 100), Action: 'Action (Audit Events)'.Create, Entity: "aaca_staff", 'Entity ID': Text(wr.Staff), Before: "", After: JSON({Name: wr.Name, Email: wr.Email, CampusId: Text(wr.Campus.Campus), Campus: wr.Campus.Name, StartDate: Text(wr.'Start Date', "yyyy-mm-dd"), AppRole: Text(wr.'App Role'), Active: wr.Active, FinanceAccess: wr.'Finance Access', SiteAdministrator: wr.'Site Administrator'}), Reason: "Added on the Staff screen"}), Blank())},
                                Set(varStfSelId, wr.Staff);
                                Set(varStfReceipt, {Kind: "Added", Title: "Added. They can sign in once they are in the app's security group; their access is set up automatically within about 15 minutes of their first sign-in."});
                                ClearCollect(
                                    colStfReceiptLines,
                                    {Label: "Name", Value: wr.Name},
                                    {Label: "Work email", Value: wr.Email},
                                    {Label: "Campus", Value: wr.Campus.Name},
                                    {Label: "App role", Value: Text(wr.'App Role')},
                                    {Label: "Start date", Value: Text(wr.'Start Date', "mmm d, yyyy")},
                                    {Label: "Status", Value: If(wr.Active, "Active", "Retired")},
                                    {Label: "Finance / Site admin", Value: If(wr.'Finance Access', "Yes", "No") & " / " & If(wr.'Site Administrator', "Yes", "No")},
                                    {Label: "Account", Value: If(IsBlank(wr.User), "Waiting for account (linked automatically)", "Linked")},
                                    {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Create written")}
                                );
                                Set(varStfMode, "");
                                Select(btnStfLoadEngine)
                            )
                        )
                    )
                )
            );
            Set(varStfSaving, false),
            mode = "edit",
            Set(varStfSaving, true);
            With(
                {
                    live: With({q: varStfSelId}, LookUp(Staff, ThisRecord.Staff = q)),
                    dup: With({q: em, s0: varStfSelId}, LookUp(Staff, Email = q && ThisRecord.Staff <> s0)),
                    n: With({q: varStfSelId, t0: Today()}, CountRows(Filter(Enrollments, Teacher.Staff = q && (IsBlank('End Date') || 'End Date' >= t0))))
                },
                If(
                    IsBlank(live),
                    Set(varStfReceipt, {Kind: "Blocked", Title: "Not saved · this staff record was not found. Change campus or reopen the screen."}); Clear(colStfReceiptLines),
                    !IsBlank(dup),
                    Set(varStfReceipt, {Kind: "Blocked", Title: "Not saved · " & em & " already belongs to " & dup.Name & "."}); Clear(colStfReceiptLines),
                    IsAdminRole && n > 0 && (cmpRec.Campus <> live.Campus.Campus || roleVal <> live.'App Role'),
                    Set(varStfReceipt, {Kind: "Blocked", Title: "Not saved · Transfer their class first (" & n & " students) before changing campus or role."}); Clear(colStfReceiptLines),
                    With(
                        {wr: IfError(Patch(Staff, live, {Name: nm, Email: em, 'Start Date': d, Campus: If(IsAdminRole, cmpRec, live.Campus), 'App Role': If(IsAdminRole, roleVal, live.'App Role')}), Blank())},
                        If(
                            IsBlank(wr),
                            Set(varStfReceipt, {Kind: "Failed", Title: "Not saved · " & live.Name & " · " & Coalesce(First(Errors(Staff)).Message, "the save failed") & ". Press Save changes to retry."}); Clear(colStfReceiptLines),
                            With(
                                {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Staff updated " & wr.Name, 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_staff", 'Entity ID': Text(wr.Staff), Before: JSON({Name: live.Name, Email: Coalesce(live.Email, ""), CampusId: Text(live.Campus.Campus), Campus: live.Campus.Name, StartDate: If(IsBlank(live.'Start Date'), "", Text(live.'Start Date', "yyyy-mm-dd")), AppRole: Text(live.'App Role')}), After: JSON({Name: wr.Name, Email: wr.Email, CampusId: Text(wr.Campus.Campus), Campus: wr.Campus.Name, StartDate: If(IsBlank(wr.'Start Date'), "", Text(wr.'Start Date', "yyyy-mm-dd")), AppRole: Text(wr.'App Role')}), Reason: "Edited on the Staff screen"}), Blank())},
                                Set(varStfReceipt, {Kind: "Edited", Title: "Saved · " & wr.Name & " · " & wr.Email});
                                ClearCollect(
                                    colStfReceiptLines,
                                    {Label: "Name", Value: wr.Name},
                                    {Label: "Work email", Value: wr.Email},
                                    {Label: "Campus", Value: wr.Campus.Name & If(wr.Campus.Campus <> varStfCampusId, " (no longer listed under this campus)", "")},
                                    {Label: "App role", Value: Text(wr.'App Role')},
                                    {Label: "Start date", Value: If(IsBlank(wr.'Start Date'), "Not set", Text(wr.'Start Date', "mmm d, yyyy"))},
                                    {Label: "Before", Value: live.Name & " · " & Coalesce(live.Email, "no email") & " · " & live.Campus.Name & " · " & Text(live.'App Role')},
                                    {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Update written with before/after")}
                                );
                                Set(varStfMode, "");
                                Select(btnStfLoadEngine)
                            )
                        )
                    )
                )
            );
            Set(varStfSaving, false),
            mode = "retire",
            Set(varStfSaving, true);
            With(
                {
                    live: With({q: varStfSelId}, LookUp(Staff, ThisRecord.Staff = q)),
                    n: With({q: varStfSelId, t0: Today()}, CountRows(Filter(Enrollments, Teacher.Staff = q && (IsBlank('End Date') || 'End Date' >= t0))))
                },
                If(
                    IsBlank(live) || live.Active = false,
                    Set(varStfReceipt, {Kind: "Blocked", Title: "Not saved · this person is already retired or was removed."}); Clear(colStfReceiptLines); Select(btnStfLoadEngine),
                    n > 0,
                    Set(varStfReceipt, {Kind: "Blocked", Title: "Not saved · Transfer their class first (" & n & " students)."}); Clear(colStfReceiptLines); Select(btnStfLoadEngine),
                    With(
                        {wr: IfError(Patch(Staff, live, {Active: false, 'End Date': d}), Blank())},
                        If(
                            IsBlank(wr),
                            Set(varStfReceipt, {Kind: "Failed", Title: "Not saved · " & live.Name & " · " & Coalesce(First(Errors(Staff)).Message, "the save failed") & ". Press Retire to retry."}); Clear(colStfReceiptLines),
                            With(
                                {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Staff retired " & wr.Name, 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_staff", 'Entity ID': Text(wr.Staff), Before: JSON({Active: live.Active, EndDate: If(IsBlank(live.'End Date'), "", Text(live.'End Date', "yyyy-mm-dd"))}), After: JSON({Active: wr.Active, EndDate: Text(wr.'End Date', "yyyy-mm-dd")}), Reason: "Retired on the Staff screen"}), Blank())},
                                Set(varStfReceipt, {Kind: "Retired", Title: "Retired · " & wr.Name & " · end date " & Text(wr.'End Date', "mmm d, yyyy")});
                                ClearCollect(
                                    colStfReceiptLines,
                                    {Label: "Name", Value: wr.Name},
                                    {Label: "Status", Value: If(wr.Active, "Active", "Retired")},
                                    {Label: "End date", Value: Text(wr.'End Date', "mmm d, yyyy")},
                                    {Label: "Students now", Value: Text(n)},
                                    {Label: "Teacher pickers", Value: "No longer offered"},
                                    {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Update written")}
                                );
                                Set(varStfMode, "");
                                Select(btnStfLoadEngine)
                            )
                        )
                    )
                )
            );
            Set(varStfSaving, false),
            mode = "reactivate",
            Set(varStfSaving, true);
            With(
                {live: With({q: varStfSelId}, LookUp(Staff, ThisRecord.Staff = q))},
                If(
                    IsBlank(live) || live.Active = true,
                    Set(varStfReceipt, {Kind: "Blocked", Title: "Not saved · this person is already active or was removed."}); Clear(colStfReceiptLines); Select(btnStfLoadEngine),
                    With(
                        {wr: IfError(Patch(Staff, live, {Active: true, 'End Date': Blank()}), Blank())},
                        If(
                            IsBlank(wr),
                            Set(varStfReceipt, {Kind: "Failed", Title: "Not saved · " & live.Name & " · " & Coalesce(First(Errors(Staff)).Message, "the save failed") & ". Press Reactivate to retry."}); Clear(colStfReceiptLines),
                            With(
                                {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Staff reactivated " & wr.Name, 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_staff", 'Entity ID': Text(wr.Staff), Before: JSON({Active: live.Active, EndDate: If(IsBlank(live.'End Date'), "", Text(live.'End Date', "yyyy-mm-dd"))}), After: JSON({Active: wr.Active, EndDate: ""}), Reason: "Reactivated on the Staff screen"}), Blank())},
                                Set(varStfReceipt, {Kind: "Reactivated", Title: "Reactivated · " & wr.Name});
                                ClearCollect(
                                    colStfReceiptLines,
                                    {Label: "Name", Value: wr.Name},
                                    {Label: "Status", Value: If(wr.Active, "Active", "Retired")},
                                    {Label: "End date", Value: If(IsBlank(wr.'End Date'), "Cleared", Text(wr.'End Date', "mmm d, yyyy"))},
                                    {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Update written")}
                                );
                                Set(varStfMode, "");
                                Select(btnStfLoadEngine)
                            )
                        )
                    )
                )
            );
            Set(varStfSaving, false)
        )
    )
)
```

### E4 `btnStfXferEngine.OnSelect` (Text "transfer") - one student at a time, per-student IfError, log
Close + create logic is copied from StudentsScreen `btnStuFormSubmit` branch `"transfer"` (lines 1801-1860):
same close Patch, same new-enrollment Patch with `'Previous Enrollment': closed`, same rollback when the new
enrollment fails, same owner patches, same Transfer audit JSON.
```
=With(
    {
        d: dpStfDate.SelectedDate,
        fromId: varStfSelId,
        p: LookUp(colStfAll, StaffId = varStfSelId),
        toId: ddStfXferTeacher.Selected.StaffId,
        note: Trim(txtStfNote.Text),
        n: CountRows(colStfXferWork)
    },
    With(
        {tch: With({q: toId}, LookUp(Staff, ThisRecord.Staff = q))},
        If(
            !CanManageStudents || varStfSaving || varStfMode <> "transfer" || n = 0 || IsBlank(d) || IsBlank(tch) || tch.Active = false || !StartsWith(lblStfCheck.Text, "Ready"),
            Set(varStfReceipt, {Kind: "Blocked", Title: "Not saved. " & lblStfCheck.Text}); Clear(colStfReceiptLines),
            Set(varStfSaving, true);
            Clear(colStfLog);
            ForAll(
                colStfXferWork As w,
                With(
                    {
                        old: With({qe: w.EnrId}, LookUp(Enrollments, ThisRecord.Enrollment = qe)),
                        stu: With({qs: w.StudentId}, LookUp(Students, ThisRecord.Student = qs))
                    },
                    If(
                        IsBlank(old) || IsBlank(stu) || old.Teacher.Staff <> fromId || (!IsBlank(old.'End Date') && old.'End Date' < d),
                        Collect(colStfLog, {EnrId: w.EnrId, StudentName: w.StudentName, StudentNumber: w.StudentNumber, Action: w.Action, Outcome: "skipped", Detail: "changed by someone else since the preview", NewEnrId: ZeroGuid, AuditOk: false}),
                        w.Action = "reassign",
                        With(
                            {up: IfError(Patch(Enrollments, old, {Teacher: tch}), Blank())},
                            If(
                                IsBlank(up),
                                Collect(colStfLog, {EnrId: w.EnrId, StudentName: w.StudentName, StudentNumber: w.StudentNumber, Action: "reassign", Outcome: "failed", Detail: "teacher not changed: " & Coalesce(First(Errors(Enrollments)).Message, "unknown error"), NewEnrId: ZeroGuid, AuditOk: false}),
                                With(
                                    {
                                        enrOwn: If(IsBlank(tch.User), false, !IsBlank(IfError(Patch(Enrollments, up, {Owner: tch.User}), Blank()))),
                                        stuOwn: If(old.'Start Date' <= Today() && !IsBlank(tch.User), !IsBlank(IfError(Patch(Students, stu, {Owner: tch.User}), Blank())), false),
                                        au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Transfer " & stu.'Student Number' & " to " & tch.Name & " (enrollment from " & Text(old.'Start Date', "yyyy-mm-dd") & ")", 100), Action: 'Action (Audit Events)'.Transfer, Entity: "aaca_student", 'Entity ID': Text(stu.Student), Before: JSON({EnrollmentId: Text(old.Enrollment), TeacherId: Text(old.Teacher.Staff), Teacher: old.Teacher.Name, CampusId: Text(old.Campus.Campus), Campus: old.Campus.Name, StartDate: Text(old.'Start Date', "yyyy-mm-dd"), EndDate: If(IsBlank(old.'End Date'), "", Text(old.'End Date', "yyyy-mm-dd")), Status: Text(old.'Status (aaca_status)')}), After: JSON({EnrollmentId: Text(up.Enrollment), TeacherId: Text(tch.Staff), Teacher: tch.Name, CampusId: Text(up.Campus.Campus), Campus: up.Campus.Name, StartDate: Text(up.'Start Date', "yyyy-mm-dd"), Status: Text(up.'Status (aaca_status)'), Reassigned: true, BulkTransfer: true}), Reason: If(note = "", "Class transfer to " & tch.Name, note)}), Blank())
                                    },
                                    Collect(colStfLog, {EnrId: w.EnrId, StudentName: w.StudentName, StudentNumber: w.StudentNumber, Action: "reassign", Outcome: "reassigned", Detail: "enrollment from " & Text(up.'Start Date', "mmm d, yyyy") & " now with " & up.Teacher.Name & If(IsBlank(tch.User), " · owner unchanged (teacher has no linked user)", enrOwn, "", " · owner update FAILED"), NewEnrId: up.Enrollment, AuditOk: !IsBlank(au)})
                                )
                            )
                        ),
                        w.Action = "move",
                        With(
                            {
                                liveOverlap: With({qs: w.StudentId, qsv: old.Service.Service, qe: w.EnrId, qd: d}, CountRows(Filter(Enrollments, Student.Student = qs && Service.Service = qsv && ThisRecord.Enrollment <> qe && (IsBlank('End Date') || 'End Date' >= qd)))),
                                attAfter: With({qs: w.StudentId, qd: d}, CountRows(Filter(Attendance, Student.Student = qs && Date >= qd && 'Is Deleted' <> true)))
                            },
                            If(
                                !IsBlank(old.'End Date') || old.'Start Date' >= d,
                                Collect(colStfLog, {EnrId: w.EnrId, StudentName: w.StudentName, StudentNumber: w.StudentNumber, Action: "move", Outcome: "skipped", Detail: "the enrollment changed since the preview", NewEnrId: ZeroGuid, AuditOk: false}),
                                liveOverlap > 0,
                                Collect(colStfLog, {EnrId: w.EnrId, StudentName: w.StudentName, StudentNumber: w.StudentNumber, Action: "move", Outcome: "skipped", Detail: "the new enrollment would overlap another enrollment for this student and service", NewEnrId: ZeroGuid, AuditOk: false}),
                                With(
                                    {closed: IfError(Patch(Enrollments, old, {'End Date': DateAdd(d, -1, TimeUnit.Days), 'End Reason': 'End Reason (Enrollments)'.Transfer, 'Status (aaca_status)': If(d <= Today(), 'Status (Enrollments)'.Ended, old.'Status (aaca_status)')}), Blank())},
                                    If(
                                        IsBlank(closed),
                                        Collect(colStfLog, {EnrId: w.EnrId, StudentName: w.StudentName, StudentNumber: w.StudentNumber, Action: "move", Outcome: "failed", Detail: "nothing saved: " & Coalesce(First(Errors(Enrollments)).Message, "unknown error"), NewEnrId: ZeroGuid, AuditOk: false}),
                                        With(
                                            {ne: IfError(Patch(Enrollments, Defaults(Enrollments), {Name: stu.'Student Number' & " " & Text(d, "yyyy-mm-dd"), Student: stu, Campus: old.Campus, Teacher: tch, Service: old.Service, 'School Year': old.'School Year', Program: old.Program, 'IEP Ratio': old.'IEP Ratio', 'Start Date': d, 'Status (aaca_status)': If(d <= Today(), 'Status (Enrollments)'.Active, 'Status (Enrollments)'.Planned), 'Previous Enrollment': closed}), Blank())},
                                            If(
                                                IsBlank(ne),
                                                With(
                                                    {err: Coalesce(First(Errors(Enrollments)).Message, "unknown error")},
                                                    With(
                                                        {rb: IfError(Patch(Enrollments, closed, {'End Date': Blank(), 'End Reason': Blank(), 'Status (aaca_status)': old.'Status (aaca_status)'}), Blank())},
                                                        Collect(colStfLog, {EnrId: w.EnrId, StudentName: w.StudentName, StudentNumber: w.StudentNumber, Action: "move", Outcome: "failed", Detail: "new enrollment not created (" & err & "); " & If(IsBlank(rb), "the old enrollment is still ended on " & Text(closed.'End Date', "mmm d, yyyy") & " - ask a System Admin to reopen it", "the old enrollment was reopened, nothing changed"), NewEnrId: ZeroGuid, AuditOk: false})
                                                    )
                                                ),
                                                With(
                                                    {
                                                        stuOwn: If(d <= Today() && !IsBlank(tch.User), !IsBlank(IfError(Patch(Students, stu, {Owner: tch.User}), Blank())), false),
                                                        enrOwn: If(IsBlank(tch.User), false, !IsBlank(IfError(Patch(Enrollments, ne, {Owner: tch.User}), Blank()))),
                                                        audit: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Transfer " & stu.'Student Number' & " to " & tch.Name & " from " & Text(d, "yyyy-mm-dd"), 100), Action: 'Action (Audit Events)'.Transfer, Entity: "aaca_student", 'Entity ID': Text(stu.Student), Before: JSON({EnrollmentId: Text(old.Enrollment), TeacherId: Text(old.Teacher.Staff), Teacher: old.Teacher.Name, CampusId: Text(old.Campus.Campus), Campus: old.Campus.Name, StartDate: Text(old.'Start Date', "yyyy-mm-dd"), EndDate: "", Status: Text(old.'Status (aaca_status)')}), After: JSON({ClosedEnrollmentId: Text(closed.Enrollment), ClosedEndDate: Text(closed.'End Date', "yyyy-mm-dd"), ClosedStatus: Text(closed.'Status (aaca_status)'), NewEnrollmentId: Text(ne.Enrollment), TeacherId: Text(tch.Staff), Teacher: tch.Name, CampusId: Text(ne.Campus.Campus), Campus: ne.Campus.Name, StartDate: Text(ne.'Start Date', "yyyy-mm-dd"), Status: Text(ne.'Status (aaca_status)'), IepRatio: Text(ne.'IEP Ratio'), AttendanceDaysKeptWithOldClass: attAfter, BulkTransfer: true}), Reason: If(note = "", "Class transfer to " & tch.Name, note)}), Blank())
                                                    },
                                                    Collect(colStfLog, {EnrId: w.EnrId, StudentName: w.StudentName, StudentNumber: w.StudentNumber, Action: "move", Outcome: "moved", Detail: "old ends " & Text(closed.'End Date', "mmm d, yyyy") & " (" & Text(closed.'Status (aaca_status)') & "); new from " & Text(ne.'Start Date', "mmm d, yyyy") & " with " & ne.Teacher.Name & " · IEP " & Text(ne.'IEP Ratio') & " · " & Text(ne.'Status (aaca_status)') & If(attAfter > 0, " · " & attAfter & " recorded day(s) stay with the old teacher", "") & If(IsBlank(tch.User), " · owner unchanged (teacher has no linked user)", enrOwn, "", " · owner update FAILED"), NewEnrId: ne.Enrollment, AuditOk: !IsBlank(audit)})
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        ),
                        Collect(colStfLog, {EnrId: w.EnrId, StudentName: w.StudentName, StudentNumber: w.StudentNumber, Action: w.Action, Outcome: "skipped", Detail: "not part of the transfer", NewEnrId: ZeroGuid, AuditOk: false})
                    )
                )
            );
            With(
                {
                    mv: CountRows(Filter(colStfLog, Outcome = "moved")),
                    ra: CountRows(Filter(colStfLog, Outcome = "reassigned")),
                    fl: CountRows(Filter(colStfLog, Outcome = "failed")),
                    sk: CountRows(Filter(colStfLog, Outcome = "skipped")) + CountRows(Filter(colStfPlan, Action = "skip"))
                },
                Set(varStfReceipt, {Kind: If(mv + ra = 0, "Failed", fl + sk > 0, "Partial", "Transferred"), Title: "Class transfer · " & p.StaffName & " to " & tch.Name & " · " & Text(d, "mmm d, yyyy") & " · " & mv & " moved, " & ra & " reassigned, " & fl & " failed" & If(sk > 0, ", " & sk & " skipped", "")});
                ClearCollect(
                    colStfReceiptLines,
                    {Label: "Operation", Value: "Transfer class"},
                    {Label: "From teacher", Value: p.StaffName},
                    {Label: "To teacher", Value: tch.Name},
                    {Label: "Effective date", Value: Text(d, "mmm d, yyyy")},
                    {Label: "Moved", Value: Text(mv)},
                    {Label: "Reassigned", Value: Text(ra)},
                    {Label: "Failed", Value: Text(fl)},
                    {Label: "Skipped", Value: Text(sk)},
                    ForAll(colStfLog As g, {Label: g.StudentName & " · " & g.StudentNumber, Value: Switch(g.Outcome, "moved", "Moved", "reassigned", "Future enrollment reassigned", "failed", "FAILED", "Skipped") & " · " & g.Detail & If(g.Outcome in ["moved", "reassigned"], If(g.AuditOk, " · audit Transfer written", " · audit NOT written"), "")}),
                    ForAll(Filter(colStfPlan, Action = "skip") As k, {Label: k.StudentName & " · " & k.StudentNumber, Value: "Skipped · " & k.Reason})
                )
            );
            Clear(colStfXferWork);
            Clear(colStfPlan);
            Set(varStfMode, "");
            Set(varStfSaving, false);
            Select(btnStfLoadEngine)
        )
    )
)
```

## Numeric layout budgets

- Nav: 16+582+16 = 614 <= 640 (one row); phone three rows 44*3+8*2 = 148 (+8).
- Header strip: 316 (one row everywhere).
- List head: 150 min + 8 + 130 = 288 <= 311 (phone list inner 375-32-32); tools phone 88.
- List row desktop: inner at 1024 = 645-32 (panel padding) - 16 (shell inset) - 16 (row padding) = 581 >= info 260
  + 8 + 100; height 8+66+8 = 82 <= 88. Phone: 8 + (40+4+36+4+18 = 102) + 8 + 44 + 8 = 170 <= 176.
- Panel inner at 1024: (1024-8)/3 - 32 = 306; actions 298; selection actions wrap to 96.
- Plan row 66 <= 72; receipt row: 160 label + value, 3 lines (56) desktop, 5 lines (88) phone.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| stf-identity | galStfList row | Name + Email | StaffName, Email | lblStfRowName | `=ThisItem.StaffName & " · " & If(ThisItem.Email = "", "no work email", ThisItem.Email)` | first line, always |
| stf-role-count-account | galStfList row | Role, Students now, Account | RoleText, StudentsNow, Linked | lblStfRowMeta | see above | second line |
| stf-status | galStfList row | Active / Retired since mmm d, yyyy | IsActive, EndDate | lblStfRowStatus | see above | third line |
| stf-detail | conStfPanel | all of the above + campus, start/end | colStfAll row | lblStfFacts | F1 | panel, when selected |
| stf-plan-row | galStfPlan row | student name, number, ratio, current start, outcome | colStfPlan | lblStfPlanName, lblStfPlanMeta | see above | transfer mode |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| stf-denied | conStfDenied | `=!CanManageStudents` | Teachers, Read-only, not set up |
| stf-body | conStfBody / conStfView | `=CanManageStudents` | office/admin |
| stf-receipt | conStfReceipt | `=varStfReceipt.Kind <> ""` | after a save attempt until Close / revisit |
| stf-list | conStfListPanel | `=!(conStfRoot.Width < 1024 && varStfMode <> "")` | hidden on narrow while a form is open |
| stf-panel | conStfPanel | `=conStfRoot.Width >= 1024 \|\| varStfMode <> "" \|\| !IsBlank(varStfSelId)` | desktop always |
| stf-sel-actions | conStfSelActions, lblStfActionHint | `=varStfMode = "" && !IsBlank(varStfSelId)` | person selected, no form open |
| stf-form | rows 5-12 | `varStfMode in ["add", "edit"]` (+ IsAdminRole for picker/radio) | add/edit |
| stf-xfer | rows 13-14, 17-21 | `varStfMode = "transfer"` | transfer |

## Required Actions

Copy of plan-index rows A-NAV-STAFF, A-STF-CAMPUS, A-STF-SEARCH, A-STF-SHOW-RETIRED, A-STF-SELECT, A-STF-ADD,
A-STF-EDIT, A-STF-XFER-OPEN, A-STF-XFER-PREVIEW, A-STF-XFER, A-STF-RETIRE, A-STF-REACTIVATE, A-STF-CANCEL.

| Action | Entry point and event | Source and stable ID | Mutation write set | Receipt proof set |
| --- | --- | --- | --- | --- |
| A-STF-ADD | btnStfAdd -> btnStfSave (mode "add") | new `wr.Staff` -> varStfSelId | Staff: Name, Email, Campus, Start Date, App Role, Active=true, Finance Access=false, Site Administrator=false; Audit Create | title (exact requested sentence); Name, Work email, Campus, App role, Start date, Status, Finance / Site admin, Account, Audit |
| A-STF-EDIT | btnStfEdit -> btnStfSave ("edit") | varStfSelId -> live | Name, Email, Start Date (+ Campus, App Role for admin); Audit Update Before/After | Name, Work email, Campus, App role, Start date, Before, Audit |
| A-STF-XFER | btnStfXfer -> btnStfSave ("transfer") -> btnStfXferEngine | per student `w.EnrId`; `closed.Enrollment`, `ne.Enrollment`, `up.Enrollment` | move: old End Date, End Reason, Status; new enrollment (Name, Student, Campus, Teacher, Service, School Year, Program, IEP Ratio, Start Date, Status, Previous Enrollment), Owners; reassign: Teacher (+Owner); Audit Transfer per student | title totals; Operation, From, To, Effective date, Moved, Reassigned, Failed, Skipped; one line per student (outcome + detail + audit) |
| A-STF-RETIRE | btnStfRetire -> btnStfSave ("retire") | varStfSelId -> live | Active=false, End Date; Audit Update | Name, Status, End date, Students now, Teacher pickers, Audit |
| A-STF-REACTIVATE | btnStfReactivate -> btnStfSave ("reactivate") | varStfSelId -> live | Active=true, End Date=blank; Audit Update | Name, Status, End date "Cleared", Audit |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| ddStfCampus | lblStfCampus `="Campus"` | conStfHdrBar |
| txtStfName | lblStfName `="Name * (Last, First)"` | conStfPanel |
| txtStfEmail | lblStfEmail `="Work email *"` | conStfPanel |
| ddStfFormCampus | lblStfFormCampus (F3) | conStfPanel |
| rdoStfRole | lblStfRole (F4) | conStfPanel |
| ddStfXferTeacher | lblStfXferTeacher `="New teacher *"` | conStfPanel |
| dpStfDate | lblStfDate (mode text) | conStfPanel |
| txtStfNote | lblStfNote `="Note for the audit log (optional)"` | conStfPanel |

## Functional Test Scenarios

Owned: S-NAV-STAFF (current button), S-NAV-ROLE, S-STF-LIST, S-STF-RETIRED-TOGGLE, S-STF-SEARCH, S-STF-CAMPUS,
S-STF-ADD, S-STF-ADD-ADMIN, S-STF-ADD-INVALID, S-STF-EDIT, S-STF-EDIT-OFFICE, S-STF-EDIT-BLOCK, S-STF-XFER-PREVIEW,
S-STF-XFER, S-STF-XFER-TODAY, S-STF-XFER-SAMEDAY, S-STF-XFER-PARTIAL, S-STF-XFER-INVALID, S-STF-XFER-DISABLED,
S-STF-RETIRE-BLOCK, S-STF-RETIRE, S-STF-RETIRE-INVALID, S-STF-REACTIVATE, S-STF-RETIRE-REACTIVATE - copy the rows
from the plan index Functional Test Matrix (fixtures listed above that table).

## Relevant Data Source Schemas

- Staff: Staff (GUID), Name (Text, required), Email (Text 100), 'Start Date' / 'End Date' (Date), Active /
  'Finance Access' / 'Site Administrator' (Yes/No = Boolean), 'App Role' ('App Role (Staff)': Teacher |
  'Attendance Office' | 'Read-only' | 'System Admin', required), Campus (lookup Campuses), User (lookup Users;
  'Primary Email', 'Full Name').
- Enrollments: Enrollment (GUID), Name, Student, Campus, Teacher (lookup Staff), Service, 'School Year' (has
  'End Date'), Program, 'IEP Ratio', 'Start Date', 'End Date', 'Status (aaca_status)' ('Status (Enrollments)'),
  'End Reason' ('End Reason (Enrollments)'), 'Previous Enrollment' (lookup Enrollments), Owner.
- Students: Student, 'Display Name', 'Student Number', 'Status (aaca_status)', Owner. Attendance: Student, Date,
  'Is Deleted'. 'Month Locks': Campus, Month, 'Status (aaca_status)'. Campuses: Campus, Name.
- 'Audit Events': Summary, Action, Entity, 'Entity ID', Before, After, Reason.

## Required Variants

- GroupContainer -> `Variant: AutoLayout` (every container).
- Gallery -> `Variant: Vertical` (galStfReceipt, galStfList, galStfPlan).

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
  LayoutMinWidth, OnSelect, Size, Text, Tooltip, Visible, Width.
- Classic/Button (`Control: Classic/Button`; NO AccessibleLabel): AlignInContainer, AutoDisableOnSelect,
  LayoutMinHeight, LayoutMinWidth, OnSelect, Text, Visible.
- Gallery (`Control: Gallery` + Variant): AccessibleLabel, FillPortions, Height, Items, LayoutMinHeight,
  LayoutMinWidth, Selectable, ShowScrollbar, TabIndex, TemplatePadding, TemplateSize, Visible, Width, WrapCount.
  Outputs TemplateWidth, TemplateHeight.
- ModernDropdown (`Control: ModernDropdown`; Appearance enum name `Appearance`): AccessibleLabel, AlignInContainer,
  Appearance, Color, Default, DisplayMode, Height, ItemDisplayText, Items, LayoutMinHeight, LayoutMinWidth, OnChange,
  Visible, Width. Output Selected.
- ModernTextInput (`Control: ModernTextInput`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  Default, DisplayMode, Height, LayoutMinHeight, LayoutMinWidth, MaxLength, Placeholder, TriggerOutput
  [TriggerOutput], Type [TextInputType], Visible, Width. Output Text.
- ModernDatePicker (`Control: ModernDatePicker`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  DefaultDate, DisplayMode, EndDate, Format [DatePickerFormat], Height, LayoutMinHeight, LayoutMinWidth, OnChange,
  StartDate, Visible. Output SelectedDate.
- ModernRadio (`Control: ModernRadio`): AccessibleLabel, AlignInContainer, Color, Default, DisplayMode, Height,
  ItemDisplayText, Items, Layout [OptionLayout], LayoutMinHeight, LayoutMinWidth, OnChange, Visible. Output Selected.
- ModernToggle (`Control: ModernToggle`): AccessibleLabel, AlignInContainer, BasePaletteColor, Color, Default,
  DisplayMode, Height, Label, LabelPosition [ToggleLabelPosition], LayoutMinHeight, LayoutMinWidth, OnCheck,
  OnUncheck, Size, Tooltip, Visible, Width. Output Checked.

Compile-ready enum literals: `ButtonAppearance.Primary`, `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`,
`Appearance.Outline`, `DatePickerFormat.Short`, `OptionLayout.Vertical`, `TextInputType.Search`,
`TextInputType.Multiline`, `TriggerOutput.Keypress`, `ToggleLabelPosition.After`, `DisplayMode.Edit`,
`DisplayMode.Disabled`, `LayoutDirection.Horizontal`, `LayoutDirection.Vertical`, `LayoutAlignItems.Stretch`,
`LayoutAlignItems.Center`, `LayoutAlignItems.Start`, `AlignInContainer.Stretch`, `AlignInContainer.Center`,
`AlignInContainer.Start`, `LayoutOverflow.Scroll`, `FontWeight.Bold`, `FontWeight.Semibold`, `VerticalAlign.Top`,
`DropShadow.None`.

YAML: every formula containing `: ` or ` #` is a `|-` block (record literals, `"Campus: "`, `"Ready: "`,
`"Students now: "`, `"Account: "`, `"Skipped: "`, `"Future enrollment reassigned: "`). The apostrophes in "app's",
"student's", "You're" are inside Power Fx strings and are fine in a `|-` block. No glyphs.
