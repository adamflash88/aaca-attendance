# Screen Plan: Absences

## Assignment

- Action: Create
- Target file: `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml`
- YAML key: AbsencesScreen
- Control name prefix: Abs

## Specification

- Purpose: Attendance-office classification queue. Load absences for a campus, date range and status; classify one
  (Excused with a required reason, or Unexcused) or many (tick / Select all shown, one Patch per row); every write
  audited; locked months blocked.
- Visual: same header band, palette, panel surfaces and receipt as StudentsScreen (copy its header/denied/notice/
  receipt structures under the `Abs` prefix). Page focal region: the queue list; side panel: reason prompt.
- Breakpoint source everywhere: `conAbsRoot.Width` (`< 640` phone, `>= 1024` desktop). Written below as `ph` =
  `conAbsRoot.Width < 640`, `dk` = `conAbsRoot.Width >= 1024`; write the full expression in YAML.
- Shorthand formulas used below (write them out in full in YAML):
  - `SHOWN` = `Filter(colAbsList, (varAbsTeacherId = ZeroGuid || TeacherId = varAbsTeacherId) && (varAbsStatus = "All" || ClassText = varAbsStatus))`
  - `TICKED` = `Filter(colAbsList, AttId in colAbsTicked.AttId && !Locked && (varAbsTeacherId = ZeroGuid || TeacherId = varAbsTeacherId) && (varAbsStatus = "All" || ClassText = varAbsStatus))`
  - `REASONOK(x)` = `!IsBlank(LookUp(colAbsReasons, ReasonId = x))`

### Screen properties

- `Fill: =ColorPaper`
- `OnVisible` (`|-`):
  ```
  =Set(varAbsSaving, false);
  Set(varAbsSelId, Blank());
  Set(varAbsReasonId, Blank());
  Set(varAbsReceipt, {Kind: "", Title: ""});
  Clear(colAbsReceiptLines);
  If(StudentCampusLock <> ZeroGuid, Set(varAbsCampusId, StudentCampusLock));
  IfError(
      Concurrent(
          ClearCollect(colAbsCampusOpts, ForAll(Sort(Campuses, Name, SortOrder.Ascending) As c, {CampusId: c.Campus, CampusName: c.Name})),
          ClearCollect(colAbsTeacherSrc, ForAll(Sort(Filter(Staff, 'App Role' = 'App Role (Staff)'.Teacher), Name, SortOrder.Ascending) As t, {TeacherId: t.Staff, TeacherName: t.Name, CampusId: t.Campus.Campus})),
          ClearCollect(colAbsReasons, ForAll(Sort(Filter('Absence Reasons', Active = true), 'Sort Order', SortOrder.Ascending) As a, {ReasonId: a.'Absence Reason', ReasonName: a.Name, SortOrder: a.'Sort Order'}))
      ),
      Set(varAbsLoadError, FirstError.Message)
  );
  ClearCollect(colAbsTeacherOpts, {TeacherId: ZeroGuid, TeacherName: "All teachers", CampusId: ZeroGuid}, colAbsTeacherSrc);
  Select(btnAbsLoadEngine)
  ```

### Control tree (order matters; every GroupContainer is `Variant: AutoLayout`, `DropShadow: =DropShadow.None`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`)

```
conAbsRoot                       vertical, Width =Parent.Width, Height =Parent.Height, LayoutMinWidth =0, LayoutMinHeight =0,
                                 LayoutOverflowY =LayoutOverflow.Scroll, gap 8, PaddingBottom 16, Fill ColorPaper, radius 0, Stretch
├─ conAbsHeader                  copy of conStuHeader (Height =If(conAbsRoot.Width < 640, 92, 76) + If(CanManageStudents, 48, 0))
│  ├─ lblAbsTitle                "AACA Attendance" (20 Bold white, h28, wrap false)
│  ├─ lblAbsIdentity             same formula as lblStuIdentity, Height =If(conAbsRoot.Width < 640, 36, 20)
│  └─ conAbsNav                  shared nav pattern, Visible =CanManageStudents
│     ├─ btnAbsNavAttendance     Secondary -> Navigate(Screen1)
│     ├─ btnAbsNavStudents       Secondary -> Navigate(StudentsScreen)
│     └─ btnAbsNavAbsences       CURRENT (teal) -> Navigate(AbsencesScreen), AccessibleLabel "Absences (current screen)"
├─ conAbsDenied                  copy of conStuDenied; Visible =!CanClassify
│  ├─ lblAbsDeniedTitle          "Absences is not available for your role"
│  ├─ lblAbsDeniedBody           If(!StaffReady, "Your sign-in is not linked to an active Staff record. Ask a System Admin to set you up.", "Only the Attendance Office and System Admin roles classify absences. Teachers and Read-only users record and view attendance on the Attendance screen.")
│  └─ btnAbsDeniedBack           "Back to Attendance" -> Navigate(Screen1), Width 190
├─ conAbsNotice                  copy of conStuNotice; Visible =CanClassify && varAbsLoadError <> ""
│  └─ lblAbsNotice               ="Could not load absences — " & varAbsLoadError & ". Use ↻ to try again."
├─ spnAbsLoading                 ModernSpinner, Height 48, FillPortions 0, Visible =varAbsLoading || varAbsSaving,
│                                Label =If(varAbsSaving, "Saving classifications…", "Loading absences…"), SpinnerColor ColorTeal, Color ColorInk
├─ conAbsReceipt                 copy of conStuReceipt with Abs names (see Receipt)
│  ├─ conAbsReceiptTop           ├─ lblAbsReceiptTitle  └─ btnAbsReceiptDismiss
│  └─ galAbsReceipt              └─ conAbsRcptRow ├─ lblAbsRcptLabel └─ lblAbsRcptValue
├─ conAbsBody                    Visible =CanClassify (see Body)
│  ├─ conAbsListPanel
│  │  ├─ conAbsListHead          ├─ lblAbsListTitle ├─ btnAbsReload └─ btnAbsClearFilters
│  │  ├─ conAbsScopeRow          ├─ conAbsCampusField (lblAbsCampus, ddAbsCampus) └─ conAbsTeacherField (lblAbsTeacher, ddAbsTeacher)
│  │  ├─ conAbsDateRow           ├─ conAbsFromField (lblAbsFrom, dpAbsFrom) └─ conAbsToField (lblAbsTo, dpAbsTo)
│  │  ├─ conAbsStatusField       ├─ lblAbsStatus └─ rdoAbsStatus
│  │  ├─ conAbsTickRow           ├─ btnAbsSelectAll └─ btnAbsClearTicks
│  │  ├─ conAbsBulkRow           ├─ conAbsBulkReasonField (lblAbsBulkReason, ddAbsBulkReason) └─ conAbsBulkBtns (btnAbsBulkExcused, btnAbsBulkUnexcused)
│  │  ├─ lblAbsBulkHint
│  │  ├─ lblAbsCount
│  │  └─ galAbsList              └─ conAbsRowShell ├─ conAbsRowTop (chkAbsRowTick, lblAbsRowName, badgeAbsRowStatus)
│  │                                               ├─ lblAbsRowMeta
│  │                                               └─ conAbsRowBottom (lblAbsRowNote, btnAbsRowExcused, btnAbsRowUnexcused)
│  └─ conAbsDecide
│     ├─ lblAbsDecideTitle
│     ├─ lblAbsDecideEmpty
│     ├─ lblAbsDecideWho
│     ├─ conAbsReasonField       ├─ lblAbsReason └─ rdoAbsReason
│     ├─ lblAbsDecideCheck
│     └─ conAbsDecideActions     ├─ btnAbsDecideSave └─ btnAbsDecideCancel
├─ btnAbsLoadEngine              Classic/Button, Visible false
└─ btnAbsClassifyEngine          Classic/Button, Visible false
```

Every direct child of `conAbsRoot`: `FillPortions: =0`, `AlignInContainer: =AlignInContainer.Stretch`.
Every ModernText: four `Padding*: =0`, explicit `Height`, `AccessibleLabel`, `AlignInContainer`.

### Body

- `conAbsBody`: `LayoutDirection: =If(conAbsRoot.Width >= 1024, LayoutDirection.Horizontal, LayoutDirection.Vertical)`,
  `LayoutAlignItems: =If(conAbsRoot.Width >= 1024, LayoutAlignItems.Start, LayoutAlignItems.Stretch)`, gap 8,
  `Height: =If(conAbsRoot.Width >= 1024, Max(conAbsListPanel.Height, conAbsDecide.Height), If(conAbsListPanel.Visible, conAbsListPanel.Height, 0) + If(conAbsListPanel.Visible && conAbsDecide.Visible, 8, 0) + If(conAbsDecide.Visible, conAbsDecide.Height, 0))`
  (panel heights are literal sums below, never parent-derived, so no loop).
- `conAbsListPanel`: panel surface (white, border, radius 6, padding 16, gap 8, vertical, Stretch);
  `FillPortions: =If(conAbsRoot.Width >= 1024, 2, 0)`; `AlignInContainer: =If(conAbsRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)`;
  `Visible: =!(conAbsRoot.Width < 1024 && !IsBlank(varAbsSelId))`;
  `Height` (`|-`):
  ```
  =With(
      {n: conAbsRoot.Width < 640, k: CountRows(Filter(colAbsList, (varAbsTeacherId = ZeroGuid || TeacherId = varAbsTeacherId) && (varAbsStatus = "All" || ClassText = varAbsStatus))) > 0},
      16 + 44 + 8 + 58 + 8 + 58 + 8 + If(n, 138, 58) + 8 + 44 + 8 + If(n, 110, 58) + 8 + If(n, 36, 18) + 8 + If(n, 54, 36) + If(k, 8 + 520, 0) + 16
  )
  ```
  (wide 990 / phone 1158 with rows; the gallery is hidden when SHOWN is empty.)
- `conAbsDecide`: panel surface; `FillPortions: =If(conAbsRoot.Width >= 1024, 1, 0)`; same AlignInContainer formula;
  `Visible: =conAbsRoot.Width >= 1024 || !IsBlank(varAbsSelId)`;
  `Height: =16 + If(IsBlank(varAbsSelId), 28 + 8 + 60, 28 + 8 + 72 + 8 + 22 + Max(36, CountRows(colAbsReasons) * 32) + 8 + 36 + 8 + 44) + 16`
  (6 reasons -> 458; nothing picked -> 128).

### List panel children

| Control | Type | Key properties |
| ------- | ---- | -------------- |
| conAbsListHead | GroupContainer | horizontal, h44, gap 8, LayoutAlignItems Center, FillPortions 0 |
| lblAbsListTitle | ModernText | "Absences", Size 20 Bold, FillPortions 1, LayoutMinWidth 80, h30, wrap false |
| btnAbsReload | ModernButton | "↻", Secondary, Width 44, Tooltip "Reload absences", DisplayMode disabled while varAbsLoading \|\| varAbsSaving, OnSelect `=Select(btnAbsLoadEngine)` |
| btnAbsClearFilters | ModernButton | "Clear filters", Secondary, Width 120, OnSelect below |
| conAbsScopeRow | GroupContainer | horizontal, h58, gap 8, Stretch, FillPortions 0 |
| conAbsCampusField / conAbsTeacherField | GroupContainer | vertical, gap 4, Stretch, FillPortions 1, LayoutMinWidth 140 |
| lblAbsCampus / lblAbsTeacher | ModernText | "Campus" / "Teacher", 12 Semibold ColorMuted, h18, wrap false |
| ddAbsCampus | ModernDropdown | Items `=colAbsCampusOpts`; ItemDisplayText `=ThisItem.CampusName`; Default `=LookUp(colAbsCampusOpts, CampusId = varAbsCampusId)`; DisplayMode `=If(StudentCampusLock = ZeroGuid && !varAbsLoading && !varAbsSaving, DisplayMode.Edit, DisplayMode.Disabled)`; OnChange `=Set(varAbsCampusId, Coalesce(Self.Selected.CampusId, ZeroGuid)); Set(varAbsTeacherId, ZeroGuid); Reset(ddAbsTeacher); Select(btnAbsLoadEngine)`; h36, Appearance Outline, LayoutMinWidth 0 |
| ddAbsTeacher | ModernDropdown | Items `=Filter(colAbsTeacherOpts, TeacherId = ZeroGuid \|\| CampusId = varAbsCampusId)`; ItemDisplayText `=ThisItem.TeacherName`; Default `=LookUp(colAbsTeacherOpts, TeacherId = varAbsTeacherId)`; OnChange `=Set(varAbsTeacherId, Coalesce(Self.Selected.TeacherId, ZeroGuid)); Set(varAbsSelId, Blank())` (local filter, no reload) |
| conAbsDateRow, conAbsFromField, conAbsToField | GroupContainer | same shapes as the scope row |
| lblAbsFrom / lblAbsTo | ModernText | "From date" / "To date" |
| dpAbsFrom | ModernDatePicker | DefaultDate `=varAbsFrom`; StartDate `=Date(FirstSchoolYear, 1, 1)`; EndDate `=Today()`; Format `=DatePickerFormat.Short`; OnChange `=Set(varAbsFrom, Self.SelectedDate); Select(btnAbsLoadEngine)`; h36, Appearance Outline, LayoutMinWidth 0 |
| dpAbsTo | ModernDatePicker | DefaultDate `=varAbsTo`; same bounds; OnChange `=Set(varAbsTo, Self.SelectedDate); Select(btnAbsLoadEngine)` |
| conAbsStatusField | GroupContainer | vertical, gap 4, `Height: =If(conAbsRoot.Width < 640, 138, 58)` |
| lblAbsStatus | ModernText | "Status" |
| rdoAbsStatus | ModernRadio | Items `=["Not classified", "Excused", "Unexcused", "All"]`; Default `'={Value: varAbsStatus}'`; Layout `=If(conAbsRoot.Width < 640, OptionLayout.Vertical, OptionLayout.Horizontal)`; Height `=If(conAbsRoot.Width < 640, 116, 36)`; OnChange `=Set(varAbsStatus, Self.Selected.Value); Select(btnAbsLoadEngine)`; Color ColorInk; LayoutMinWidth 0 |
| conAbsTickRow | GroupContainer | horizontal, h44, gap 8, Center |
| btnAbsSelectAll | ModernButton | "Select all shown", Secondary, Width 150; DisplayMode Edit only when `!varAbsSaving && !varAbsLoading && CountRows(SHOWN) > 0`; OnSelect below |
| btnAbsClearTicks | ModernButton | "Clear ticks", Secondary, Width 110; DisplayMode Edit only when `CountRows(colAbsTicked) > 0 && !varAbsSaving`; OnSelect `=Clear(colAbsTicked)` |
| conAbsBulkRow | GroupContainer | `LayoutDirection: =If(conAbsRoot.Width < 640, LayoutDirection.Vertical, LayoutDirection.Horizontal)`, gap 8, `LayoutAlignItems: =LayoutAlignItems.End`, `Height: =If(conAbsRoot.Width < 640, 110, 58)` |
| conAbsBulkReasonField | GroupContainer | vertical, gap 4, Height 58, `FillPortions: =If(conAbsRoot.Width < 640, 0, 1)`, LayoutMinWidth 140, AlignInContainer Stretch |
| lblAbsBulkReason | ModernText | "Reason for Mark Excused" |
| ddAbsBulkReason | ModernDropdown | Items `=colAbsReasons`; ItemDisplayText `=ThisItem.ReasonName`; Default `=LookUp(colAbsReasons, ReasonId = varAbsBulkReasonId)`; OnChange `=Set(varAbsBulkReasonId, Self.Selected.ReasonId)` |
| conAbsBulkBtns | GroupContainer | horizontal, gap 8, FillPortions 0, Width 288, Height 44, AlignInContainer End |
| btnAbsBulkExcused | ModernButton | "Mark Excused", Width 130, BasePaletteColor ColorExcused, Color white; DisplayMode Edit only when `CanClassify && !varAbsSaving && !varAbsLoading && CountRows(TICKED) > 0 && REASONOK(varAbsBulkReasonId)` |
| btnAbsBulkUnexcused | ModernButton | "Mark Unexcused", Width 150, BasePaletteColor ColorUnexcused, Color white; DisplayMode Edit only when `CanClassify && !varAbsSaving && !varAbsLoading && CountRows(TICKED) > 0` |
| lblAbsBulkHint | ModernText | Size 12 ColorMuted; `Height: =If(conAbsRoot.Width < 640, 36, 18)`; `Wrap: =conAbsRoot.Width < 640`; Text below |
| lblAbsCount | ModernText | Size 13 ColorInk Semibold; `Height: =If(conAbsRoot.Width < 640, 54, 36)`; VerticalAlign Top; Text below |
| galAbsList | Gallery Vertical | see Rows |

`btnAbsClearFilters.OnSelect` (`|-`):
```
=Set(varAbsCampusId, If(StudentCampusLock <> ZeroGuid, StudentCampusLock, !IsBlank(CurrentStaff.Campus), CurrentStaff.Campus.Campus, Coalesce(First(colAbsCampusOpts).CampusId, ZeroGuid)));
Set(varAbsTeacherId, ZeroGuid);
Set(varAbsStatus, "Not classified");
Set(varAbsFrom, Coalesce(CurrentSchoolYear.'Start Date', Date(Year(Today()) - If(Month(Today()) < 7, 1, 0), 7, 1)));
Set(varAbsTo, Today());
Reset(ddAbsCampus); Reset(ddAbsTeacher); Reset(dpAbsFrom); Reset(dpAbsTo); Reset(rdoAbsStatus);
Select(btnAbsLoadEngine)
```

`btnAbsSelectAll.OnSelect` (`|-`):
```
=ClearCollect(colAbsTicked, ForAll(Filter(colAbsList, !Locked && (varAbsTeacherId = ZeroGuid || TeacherId = varAbsTeacherId) && (varAbsStatus = "All" || ClassText = varAbsStatus)) As r, {AttId: r.AttId}))
```

`btnAbsBulkExcused.OnSelect` (`|-`):
```
=ClearCollect(colAbsWork, ForAll(Filter(colAbsList, AttId in colAbsTicked.AttId && !Locked && (varAbsTeacherId = ZeroGuid || TeacherId = varAbsTeacherId) && (varAbsStatus = "All" || ClassText = varAbsStatus)) As r, {AttId: r.AttId}));
Set(varAbsReq, {Kind: "Excused", Scope: "bulk", ReasonId: varAbsBulkReasonId});
Select(btnAbsClassifyEngine)
```
`btnAbsBulkUnexcused.OnSelect`: identical, with `{Kind: "Unexcused", Scope: "bulk", ReasonId: ZeroGuid}`.

`lblAbsBulkHint.Text` (`|-`):
```
=With({t: CountRows(Filter(colAbsList, AttId in colAbsTicked.AttId && !Locked && (varAbsTeacherId = ZeroGuid || TeacherId = varAbsTeacherId) && (varAbsStatus = "All" || ClassText = varAbsStatus)))},
    If(t = 0, "No absences ticked. Tick rows or use Select all shown.", t & " ticked" & If(IsBlank(LookUp(colAbsReasons, ReasonId = varAbsBulkReasonId)), " · choose a reason to use Mark Excused", " · ready")))
```

`lblAbsCount.Text` (`|-`):
```
=With(
    {n: CountRows(Filter(colAbsList, (varAbsTeacherId = ZeroGuid || TeacherId = varAbsTeacherId) && (varAbsStatus = "All" || ClassText = varAbsStatus))), word: Switch(varAbsStatus, "Not classified", "not classified", "Excused", "excused", "Unexcused", "unexcused", "absences")},
    If(
        varAbsLoading, "Loading absences…",
        varAbsCampusId = ZeroGuid, "Choose a campus to load absences.",
        IsBlank(varAbsFrom) || IsBlank(varAbsTo) || varAbsFrom > varAbsTo, "Choose a From date on or before the To date.",
        n = 0, "0 " & word & ". Nothing matches these filters. Change the dates, teacher or status, or use Clear filters.",
        n & " " & word & " · " & LookUp(colAbsCampusOpts, CampusId = varAbsCampusId).CampusName & " · " & LookUp(colAbsTeacherOpts, TeacherId = varAbsTeacherId).TeacherName & " · " & Text(varAbsFrom, "mmm d, yyyy") & " – " & Text(varAbsTo, "mmm d, yyyy") & If(CountRows(colAbsList) >= 2000, " · Only the first 2,000 were loaded; narrow the dates.", "")
    )
)
```

### Rows (galAbsList)

- `galAbsList`: `Variant: Vertical`; `Items: =SortByColumns(Filter(colAbsList, (varAbsTeacherId = ZeroGuid || TeacherId = varAbsTeacherId) && (varAbsStatus = "All" || ClassText = varAbsStatus)), "AbsDate", SortOrder.Ascending, "StudentName", SortOrder.Ascending)`;
  `Height: =520`; `TemplateSize: =If(conAbsRoot.Width < 640, 148, 130)`; `TemplatePadding: =0`; `Selectable: =false`;
  `ShowScrollbar: =true`; `TabIndex: =0`; `FillPortions: =0`; `LayoutMinHeight: =0`; `LayoutMinWidth: =0`;
  `AccessibleLabel: ="Absences queue"`; `Visible: =CountRows(<SHOWN>) > 0` (same filter as Items).
- `conAbsRowShell` (only direct child): vertical, `Width: =Parent.TemplateWidth`, `Height: =Parent.TemplateHeight`,
  padding 8 all sides, gap 4, Stretch, border ColorRule 1, radius 0,
  `Fill: =If(ThisItem.AttId = varAbsSelId, ColorInfoBg, ThisItem.Locked, ColorNonSchool, ColorWhite)`.
  - `conAbsRowTop`: horizontal, h44, gap 8, Center, FillPortions 0.
    - `chkAbsRowTick` (ModernCheckbox): Width 44, Height 44, FillPortions 0, `Label: =""`,
      `AccessibleLabel: ="Tick " & ThisItem.StudentName & " " & Text(ThisItem.AbsDate, "mmm d")`,
      `Default: =!IsBlank(LookUp(colAbsTicked, AttId = ThisItem.AttId))`,
      `OnCheck` (`|-`): `=If(IsBlank(LookUp(colAbsTicked, AttId = ThisItem.AttId)), Collect(colAbsTicked, {AttId: ThisItem.AttId}))`,
      `OnUncheck: =RemoveIf(colAbsTicked, AttId = ThisItem.AttId)`,
      `DisplayMode: =If(ThisItem.Locked || varAbsSaving, DisplayMode.Disabled, DisplayMode.Edit)`.
    - `lblAbsRowName`: `Text: =ThisItem.StudentName & " · " & ThisItem.StudentNumber`, Size 14 Semibold ColorInk,
      FillPortions 1, LayoutMinWidth 0, Height 42 (2 lines), VerticalAlign Middle, wraps.
    - `badgeAbsRowStatus`: `Content: =ThisItem.ClassText`, Width 110, Height 24, FillPortions 0,
      `ThemeColor: =Switch(ThisItem.ClassText, "Excused", 'BadgeCanvas.ThemeColor'.Success, "Unexcused", 'BadgeCanvas.ThemeColor'.Danger, 'BadgeCanvas.ThemeColor'.Warning)`,
      shared badge styling, `AccessibleLabel: ="Status " & ThisItem.ClassText`.
  - `lblAbsRowMeta`: `Text: =Text(ThisItem.AbsDate, "ddd mmm d, yyyy") & " · " & ThisItem.TeacherName & " · " & ThisItem.CampusName`,
    Size 12 ColorInk, `Height: =If(conAbsRoot.Width < 640, 36, 18)`, `Wrap: =conAbsRoot.Width < 640`, VerticalAlign Top.
  - `conAbsRowBottom`: horizontal, h44, gap 8, Center, FillPortions 0.
    - `lblAbsRowNote`: FillPortions 1, LayoutMinWidth 0, Height 40, Size 12, wraps, VerticalAlign Middle,
      `Color: =If(ThisItem.Locked, ColorUnexcused, ColorMuted)`,
      `Text: =If(ThisItem.Locked, "Month locked · cannot classify", ThisItem.ClassText = "Not classified", "Not classified yet", ThisItem.ClassText & If(ThisItem.ReasonName = "", "", " · " & ThisItem.ReasonName) & If(ThisItem.ClassifiedByName = "", "", " · " & ThisItem.ClassifiedByName & " " & Text(ThisItem.ClassifiedOn, "mmm d")))`.
    - `btnAbsRowExcused`: "Excused…", Width 100, BasePaletteColor ColorExcused, Color white,
      `AccessibleLabel: ="Mark " & ThisItem.StudentName & " " & Text(ThisItem.AbsDate, "mmm d") & " excused"`,
      `DisplayMode: =If(CanClassify && !ThisItem.Locked && !varAbsSaving && !varAbsLoading, DisplayMode.Edit, DisplayMode.Disabled)`,
      `OnSelect: =Set(varAbsSelId, ThisItem.AttId); Set(varAbsReasonId, ThisItem.ReasonId); Reset(rdoAbsReason)`.
    - `btnAbsRowUnexcused`: "Unexcused", Width 110, BasePaletteColor ColorUnexcused, Color white,
      `DisplayMode: =If(CanClassify && !ThisItem.Locked && ThisItem.ClassText <> "Unexcused" && !varAbsSaving && !varAbsLoading, DisplayMode.Edit, DisplayMode.Disabled)`,
      `OnSelect` (`|-`): `=ClearCollect(colAbsWork, {AttId: ThisItem.AttId}); Set(varAbsReq, {Kind: "Unexcused", Scope: "one", ReasonId: ZeroGuid}); Select(btnAbsClassifyEngine)`.

### Reason prompt (conAbsDecide children)

- `lblAbsDecideTitle`: "Mark as Excused", Size 18 Bold, h28, wrap false.
- `lblAbsDecideEmpty`: Visible `=IsBlank(varAbsSelId)`, h60, Size 13 ColorMuted, text
  "Choose Excused… on an absence to pick its reason here. Unexcused on a row saves straight away."
- `lblAbsDecideWho`: Visible `=!IsBlank(varAbsSelId)`, h72, Size 13 ColorInk, VerticalAlign Top,
  `Text: =With({a: LookUp(colAbsList, AttId = varAbsSelId)}, a.StudentName & " · " & a.StudentNumber & " · " & Text(a.AbsDate, "ddd mmm d, yyyy") & " · " & a.TeacherName & " · " & a.CampusName & " · now " & a.ClassText & If(a.ReasonName = "", "", " (" & a.ReasonName & ")"))`.
- `conAbsReasonField`: vertical, gap 4, Visible `=!IsBlank(varAbsSelId)`, `Height: =22 + Max(36, CountRows(colAbsReasons) * 32)`.
  - `lblAbsReason`: "Reason *".
  - `rdoAbsReason` (ModernRadio): Items `=colAbsReasons`; ItemDisplayText `=ThisItem.ReasonName`;
    Default `=LookUp(colAbsReasons, ReasonId = varAbsReasonId)`; Layout `=OptionLayout.Vertical`;
    `Height: =Max(36, CountRows(colAbsReasons) * 32)`; OnChange `=Set(varAbsReasonId, Self.Selected.ReasonId)`;
    AccessibleLabel "Reason for excused absence"; LayoutMinWidth 0.
- `lblAbsDecideCheck`: Visible `=!IsBlank(varAbsSelId)`, h36, Size 13,
  `Color: =If(Self.Text = "Ready to save.", ColorExcused, ColorUnexcused)`,
  `Text: =With({a: LookUp(colAbsList, AttId = varAbsSelId)}, If(IsBlank(a), "That absence is no longer in the list. Cancel and reload.", a.Locked, "This month is locked for " & a.CampusName & ". It cannot be classified.", IsBlank(LookUp(colAbsReasons, ReasonId = varAbsReasonId)), "Choose a reason. Excused always needs one.", "Ready to save."))`.
- `conAbsDecideActions`: horizontal, h44, gap 8, Visible `=!IsBlank(varAbsSelId)`.
  - `btnAbsDecideSave`: "Save as Excused", Width 160, BasePaletteColor ColorExcused, Color white,
    `DisplayMode: =If(CanClassify && lblAbsDecideCheck.Text = "Ready to save." && !varAbsSaving && !varAbsLoading, DisplayMode.Edit, DisplayMode.Disabled)`,
    `OnSelect` (`|-`): `=ClearCollect(colAbsWork, {AttId: varAbsSelId}); Set(varAbsReq, {Kind: "Excused", Scope: "one", ReasonId: varAbsReasonId}); Select(btnAbsClassifyEngine)`.
  - `btnAbsDecideCancel`: "Cancel", Secondary, Width 100, `OnSelect` (`|-`):
    `=With({a: LookUp(colAbsList, AttId = varAbsSelId)}, Set(varAbsReceipt, {Kind: "Cancelled", Title: "Excused cancelled · " & Coalesce(a.StudentName, "no absence") & " · " & Text(a.AbsDate, "mmm d, yyyy") & " · nothing was changed"})); Clear(colAbsReceiptLines); Set(varAbsSelId, Blank()); Set(varAbsReasonId, Blank()); Reset(rdoAbsReason)`.

### Receipt (copy conStuReceipt, rename Stu -> Abs)

- `conAbsReceipt`: `Visible: =varAbsReceipt.Kind <> ""`; `Fill: =Switch(varAbsReceipt.Kind, "Failed", ColorErrorBg, "Blocked", ColorErrorBg, "Cancelled", ColorWarnBg, ColorInfoBg)`;
  `Height: =8 + If(conAbsRoot.Width < 640, 84, 44) + If(CountRows(colAbsReceiptLines) > 0, 4 + galAbsReceipt.Height, 0) + 8`; padding 8/12/12/8, gap 4, border, radius 6.
- `conAbsReceiptTop`: horizontal, `Height: =If(conAbsRoot.Width < 640, 84, 44)`; `lblAbsReceiptTitle` (`Text: =varAbsReceipt.Title`, 13 Semibold, FillPortions 1, same height, wraps) + `btnAbsReceiptDismiss` ("Dismiss", Secondary, Width 88, `OnSelect` `|-` `=Set(varAbsReceipt, {Kind: "", Title: ""}); Clear(colAbsReceiptLines)`).
- `galAbsReceipt`: Items `=colAbsReceiptLines`; `WrapCount: =If(conAbsRoot.Width < 640, 1, conAbsRoot.Width < 1024, 2, 3)`; `TemplateSize: =40`; `TemplatePadding: =0`;
  `Height: =Min(400, RoundUp(CountRows(colAbsReceiptLines) / If(conAbsRoot.Width < 640, 1, conAbsRoot.Width < 1024, 2, 3), 0) * 40)`; Visible `=CountRows(colAbsReceiptLines) > 0`; Selectable false; TabIndex 0.
  Row shell `conAbsRcptRow` (horizontal, Parent.TemplateWidth/Height, padding 2/8/2, gap 8): `lblAbsRcptLabel` (`=ThisItem.Label`, 12 Semibold ColorMuted, FillPortions 0, Width 150) and `lblAbsRcptValue` (`=ThisItem.Value`, 12 ColorInk, FillPortions 1, LayoutMinWidth 0, wraps, VerticalAlign Top).

### Engines (Classic/Button: `Visible: =false`, `AutoDisableOnSelect: =false`, `AlignInContainer: =AlignInContainer.Stretch`, `LayoutMinHeight: =0`, `LayoutMinWidth: =0`, `FillPortions: =0`, Text "load" / "classify")

`btnAbsLoadEngine.OnSelect` (`|-`):
```
=Set(varAbsLoading, true);
Set(varAbsLoadError, "");
Clear(colAbsTicked);
Set(varAbsSelId, Blank());
If(
    !CanClassify || varAbsCampusId = ZeroGuid || IsBlank(varAbsFrom) || IsBlank(varAbsTo) || varAbsFrom > varAbsTo,
    Clear(colAbsList),
    IfError(
        ClearCollect(colAbsLocks, ForAll(Filter('Month Locks', 'Status (aaca_status)' = 'Status (Month Locks)'.Locked) As m, {CampusId: m.Campus.Campus, MonthStart: m.Month})),
        Set(varAbsLoadError, FirstError.Message)
    );
    IfError(
        With(
            {c0: varAbsCampusId, d0: varAbsFrom, d1: varAbsTo},
            ClearCollect(
                colAbsList,
                ForAll(
                    Switch(
                        varAbsStatus,
                        "Not classified", Filter(Attendance, Present = false && 'Is Deleted' = false && 'Absence Classification' = Blank() && Campus.Campus = c0 && Date >= d0 && Date <= d1),
                        "Excused", Filter(Attendance, Present = false && 'Is Deleted' = false && 'Absence Classification' = 'Absence Classification (Attendance)'.Excused && Campus.Campus = c0 && Date >= d0 && Date <= d1),
                        "Unexcused", Filter(Attendance, Present = false && 'Is Deleted' = false && 'Absence Classification' = 'Absence Classification (Attendance)'.Unexcused && Campus.Campus = c0 && Date >= d0 && Date <= d1),
                        Filter(Attendance, Present = false && 'Is Deleted' = false && Campus.Campus = c0 && Date >= d0 && Date <= d1)
                    ) As r,
                    {
                        AttId: r.Attendance, RecordKey: r.'Record Key',
                        StudentId: r.Student.Student, StudentName: Coalesce(r.Student.'Display Name', "Unknown student"), StudentNumber: Coalesce(r.Student.'Student Number', "—"),
                        AbsDate: r.Date,
                        TeacherId: r.Teacher.Staff, TeacherName: Coalesce(r.Teacher.Name, "No teacher"),
                        CampusId: r.Campus.Campus, CampusName: Coalesce(r.Campus.Name, "No campus"),
                        ClassText: If(r.'Absence Classification' = 'Absence Classification (Attendance)'.Excused, "Excused", r.'Absence Classification' = 'Absence Classification (Attendance)'.Unexcused, "Unexcused", "Not classified"),
                        ReasonId: r.'Absence Reason'.'Absence Reason', ReasonName: Coalesce(r.'Absence Reason'.Name, ""),
                        ClassifiedByName: Coalesce(r.'Classified By'.'Full Name', ""), ClassifiedOn: r.'Classified On',
                        Locked: !IsBlank(LookUp(colAbsLocks, CampusId = r.Campus.Campus && MonthStart = Date(Year(r.Date), Month(r.Date), 1))),
                        ModifiedOn: r.'Modified On'
                    }
                )
            )
        ),
        Set(varAbsLoadError, FirstError.Message)
    )
);
Set(varAbsLoading, false)
```

`btnAbsClassifyEngine.OnSelect` (`|-`) — one Patch per row, literal guard per decision:
```
=With(
    {req: varAbsReq, rsn: With({qr: varAbsReq.ReasonId}, LookUp('Absence Reasons', ThisRecord.'Absence Reason' = qr && Active = true)), n: CountRows(colAbsWork)},
    If(
        !CanClassify,
        Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved. Only the Attendance Office and System Admin can classify absences."}); Clear(colAbsReceiptLines),
        !(req.Kind in ["Excused", "Unexcused"]),
        Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved. Choose Excused or Unexcused."}); Clear(colAbsReceiptLines),
        n = 0,
        Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved. No absences ticked. Tick rows or use Select all shown."}); Clear(colAbsReceiptLines),
        req.Kind = "Excused" && IsBlank(rsn),
        Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved. Excused needs a reason from Absence Reasons."}); Clear(colAbsReceiptLines),
        Set(varAbsSaving, true);
        Clear(colAbsLog);
        ClearCollect(colAbsLocks, ForAll(Filter('Month Locks', 'Status (aaca_status)' = 'Status (Month Locks)'.Locked) As m, {CampusId: m.Campus.Campus, MonthStart: m.Month}));
        ForAll(
            colAbsWork As w,
            With(
                {c: LookUp(colAbsList, AttId = w.AttId), live: With({qid: w.AttId}, LookUp(Attendance, ThisRecord.Attendance = qid))},
                With(
                    {
                        oldText: If(live.'Absence Classification' = 'Absence Classification (Attendance)'.Excused, "Excused", live.'Absence Classification' = 'Absence Classification (Attendance)'.Unexcused, "Unexcused", "Not classified") & If(IsBlank(live.'Absence Reason'), "", " (" & live.'Absence Reason'.Name & ")"),
                        outcome: If(
                            IsBlank(live), "failed",
                            live.Present = true || live.'Is Deleted' = true, "not an absence",
                            !IsBlank(LookUp(colAbsLocks, CampusId = live.Campus.Campus && MonthStart = Date(Year(live.Date), Month(live.Date), 1))), "locked",
                            !IsBlank(c) && live.'Modified On' <> c.ModifiedOn, "changed",
                            "ok"
                        )
                    },
                    With(
                        {
                            wr: If(
                                outcome = "ok",
                                IfError(
                                    Switch(
                                        req.Kind,
                                        "Excused", Patch(Attendance, live, {'Absence Classification': 'Absence Classification (Attendance)'.Excused, 'Absence Reason': rsn, 'Classified By': CurrentUserRow, 'Classified On': Now()}),
                                        "Unexcused", Patch(Attendance, live, {'Absence Classification': 'Absence Classification (Attendance)'.Unexcused, 'Absence Reason': Blank(), 'Classified By': CurrentUserRow, 'Classified On': Now()})
                                    ),
                                    Blank()
                                )
                            )
                        },
                        With(
                            {newText: If(IsBlank(wr), "", If(wr.'Absence Classification' = 'Absence Classification (Attendance)'.Excused, "Excused", wr.'Absence Classification' = 'Absence Classification (Attendance)'.Unexcused, "Unexcused", "Not classified") & If(IsBlank(wr.'Absence Reason'), "", " (" & wr.'Absence Reason'.Name & ")"))},
                            With(
                                {au: If(!IsBlank(wr), IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Reclassify " & wr.'Record Key' & " " & oldText & " to " & newText, 100), Action: 'Action (Audit Events)'.Reclassify, Entity: "aaca_attendance", 'Entity ID': Text(wr.Attendance), Before: JSON({Classification: oldText, ClassifiedBy: Coalesce(live.'Classified By'.'Full Name', ""), ClassifiedOn: Text(live.'Classified On', "yyyy-mm-dd hh:mm")}), After: JSON({Classification: newText, ClassifiedBy: Coalesce(wr.'Classified By'.'Full Name', ""), ClassifiedOn: Text(wr.'Classified On', "yyyy-mm-dd hh:mm")}), Reason: If(req.Scope = "bulk", "Bulk classification in Absences queue", "Classified in Absences queue")}), Blank()))},
                                If(!IsBlank(wr) && !IsBlank(c), Patch(colAbsList, c, {ClassText: If(wr.'Absence Classification' = 'Absence Classification (Attendance)'.Excused, "Excused", "Unexcused"), ReasonId: wr.'Absence Reason'.'Absence Reason', ReasonName: Coalesce(wr.'Absence Reason'.Name, ""), ClassifiedByName: Coalesce(wr.'Classified By'.'Full Name', ""), ClassifiedOn: wr.'Classified On', ModifiedOn: wr.'Modified On'}));
                                If(outcome = "locked" && !IsBlank(c), Patch(colAbsList, c, {Locked: true}));
                                If(outcome = "changed" && !IsBlank(c), Patch(colAbsList, c, {ClassText: If(live.'Absence Classification' = 'Absence Classification (Attendance)'.Excused, "Excused", live.'Absence Classification' = 'Absence Classification (Attendance)'.Unexcused, "Unexcused", "Not classified"), ReasonId: live.'Absence Reason'.'Absence Reason', ReasonName: Coalesce(live.'Absence Reason'.Name, ""), ClassifiedByName: Coalesce(live.'Classified By'.'Full Name', ""), ClassifiedOn: live.'Classified On', ModifiedOn: live.'Modified On'}));
                                Collect(colAbsLog, {AttId: w.AttId, StudentName: Coalesce(c.StudentName, live.Student.'Display Name', "Unknown student"), AbsDate: Coalesce(c.AbsDate, live.Date), TeacherName: Coalesce(c.TeacherName, ""), CampusName: Coalesce(c.CampusName, ""), OldClass: oldText, NewClass: newText, ReasonName: If(IsBlank(wr), "", Coalesce(wr.'Absence Reason'.Name, "")), ByName: If(IsBlank(wr), "", Coalesce(wr.'Classified By'.'Full Name', "")), OnText: If(IsBlank(wr), "", Text(wr.'Classified On', "mmm d, yyyy h:mm AM/PM")), Outcome: If(!IsBlank(wr), "marked", outcome = "ok", "failed", outcome), AuditOk: !IsBlank(au)})
                            )
                        )
                    )
                )
            )
        );
        With(
            {
                mk: CountRows(Filter(colAbsLog, Outcome = "marked")),
                fl: CountRows(Filter(colAbsLog, Outcome = "failed")),
                sk: CountRows(Filter(colAbsLog, Outcome in ["locked", "changed", "not an absence"])),
                g: First(colAbsLog)
            },
            If(
                req.Scope = "one",
                Set(varAbsReceipt, {Kind: If(mk = 1, "Classified", g.Outcome = "failed", "Failed", "Blocked"), Title: If(mk = 1, "Marked " & g.NewClass & " · " & g.StudentName & " · " & Text(g.AbsDate, "ddd mmm d, yyyy"), "Not saved · " & g.StudentName & " · " & Text(g.AbsDate, "ddd mmm d, yyyy") & " · " & Switch(g.Outcome, "locked", "the month is locked for this campus", "changed", "someone else changed this absence; the row was refreshed", "not an absence", "this day is no longer an absence", "the save failed; try again"))});
                ClearCollect(
                    colAbsReceiptLines,
                    {Label: "Student", Value: g.StudentName},
                    {Label: "Date", Value: Text(g.AbsDate, "ddd mmm d, yyyy")},
                    {Label: "Teacher", Value: g.TeacherName},
                    {Label: "Campus", Value: g.CampusName},
                    {Label: "Before", Value: g.OldClass},
                    {Label: "Classification", Value: If(mk = 1, g.NewClass, "Unchanged")},
                    {Label: "Reason", Value: If(mk = 1, If(g.ReasonName = "", "None (cleared)", g.ReasonName), "Unchanged")},
                    {Label: "Classified by", Value: If(mk = 1, g.ByName, "—")},
                    {Label: "Classified on", Value: If(mk = 1, g.OnText, "—")},
                    {Label: "Audit event", Value: If(g.AuditOk, "Reclassify written", mk = 1, "NOT written", "Not needed")}
                );
                If(mk = 1, Set(varAbsSelId, Blank()); Set(varAbsReasonId, Blank()); Reset(rdoAbsReason)),
                Set(varAbsReceipt, {Kind: If(mk = 0, "Failed", "Classified"), Title: mk & " marked " & req.Kind & If(req.Kind = "Excused", " (" & rsn.Name & ")", "") & ", " & fl & " failed" & If(sk > 0, ", " & sk & " skipped", "")});
                ClearCollect(
                    colAbsReceiptLines,
                    {Label: "Operation", Value: "Mark " & req.Kind},
                    {Label: "Reason", Value: If(req.Kind = "Excused", rsn.Name, "None (cleared)")},
                    {Label: "Ticked", Value: Text(n)},
                    {Label: "Marked", Value: Text(mk)},
                    {Label: "Failed", Value: Text(fl)},
                    {Label: "Skipped", Value: Text(sk) & " (locked month, changed by someone else, or no longer an absence)"},
                    ForAll(colAbsLog As g2, {Label: g2.StudentName & " · " & Text(g2.AbsDate, "mmm d"), Value: If(g2.Outcome = "marked", g2.NewClass & " · " & g2.ByName & If(g2.AuditOk, "", " · audit NOT written"), g2.Outcome = "failed", "FAILED · not changed", "Skipped · " & g2.Outcome)})
                )
            );
            RemoveIf(colAbsTicked, AttId in Filter(colAbsLog, Outcome = "marked").AttId)
        );
        Clear(colAbsWork);
        Set(varAbsSaving, false)
    )
)
```

## Layout budgets (numeric)

- Nav: 3 x 110 + 2 x 8 = 346 <= 358 (header inner at 390).
- List head: title min 80 + 44 + 120 + 2 x 8 = 260 <= 358.
- Scope/date rows: 140 + 8 + 140 = 288 <= 358; height 58 = 18 + 4 + 36.
- Status field: wide 18 + 4 + 36 = 58 (radio ~400 px <= 608 list inner at 640); phone 18 + 4 + 116 = 138 (4 options x ~29).
- Tick row: 150 + 8 + 110 = 268 <= 358.
- Bulk row: wide 140 + 8 + 288 = 436 <= 608, height 58; phone vertical 58 + 8 + 44 = 110, buttons 130 + 8 + 150 = 288 <= 358.
- List panel: wide 16+44+8+58+8+58+8+58+8+44+8+58+8+18+8+36+8+520+16 = 990; phone 16+44+8+58+8+58+8+138+8+44+8+110+8+36+8+54+8+520+16 = 1158.
- Row: width at phone ≈ 358 - 2 (border) - 16 (shell padding) = 340. Top 44+8+110+8 = 170 + name >= 170. Bottom 100+8+110+8 = 226 + note >= 114.
  Height 8 + 44 + 4 + (18 | 36) + 4 + 44 + 8 = 130 wide / 148 phone = TemplateSize (same `conAbsRoot.Width < 640` source).
- Desktop row width at 1024: list panel (1024 - 8) x 2/3 = 677 -> inner 645 -> row inner ≈ 627; 626 - 396 fixed = 230 for text.
- Decide panel: side inner at 1024 = (1016 / 3) - 32 = 307; actions 160 + 8 + 100 = 268 <= 307; height 458 (6 reasons).
- Text fit: "Select all shown" ≈ 124 px in 150; "Mark Unexcused" ≈ 129 in 150; "Mark Excused" ≈ 114 in 130;
  "Save as Excused" ≈ 136 in 160; "Excused…" ≈ 84 in 100; "Unexcused" ≈ 94 in 110; badge "Not classified" (12 px) ≈ 90 in 110.
- Receipt title: 44 wide (2 lines at 13) / 84 phone (4 lines); longest bulk title ≈ 75 chars.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --------- | -------------- | -------------- | ------------ | ------------- | ------------- | ------------------------ |
| abs/row/student | galAbsList row | Student | StudentName, StudentNumber | lblAbsRowName | `=ThisItem.StudentName & " · " & ThisItem.StudentNumber` | top row, fill, 2 lines |
| abs/row/date | galAbsList row | Date | AbsDate | lblAbsRowMeta | see Rows | second line |
| abs/row/teacher | galAbsList row | Teacher | TeacherName | lblAbsRowMeta | see Rows | second line |
| abs/row/campus | galAbsList row | Campus | CampusName | lblAbsRowMeta | see Rows | second line |
| abs/row/status | galAbsList row | Current status | ClassText | badgeAbsRowStatus.Content | `=ThisItem.ClassText` | top row right, 110 wide |
| abs/row/reason | galAbsList row | Reason / by / lock | ReasonName, ClassifiedByName, ClassifiedOn, Locked | lblAbsRowNote | see Rows | bottom row, left of actions |
| abs/decide/identity | conAbsDecide | Student, date, teacher, campus, status | colAbsList by varAbsSelId | lblAbsDecideWho | see Reason prompt | visible when an absence is picked |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| ----------- | --------------- | --------------- | ------------------------- |
| abs-denied | conAbsDenied | `=!CanClassify` | Teacher / Read-only / not set up vs Office / Admin |
| abs-body | conAbsBody | `=CanClassify` | Office / Admin vs others |
| abs-decide | conAbsDecide | `=conAbsRoot.Width >= 1024 \|\| !IsBlank(varAbsSelId)` | desktop always; narrow only while picking |
| abs-list-narrow | conAbsListPanel | `=!(conAbsRoot.Width < 1024 && !IsBlank(varAbsSelId))` | hidden on narrow while picking |
| abs-receipt | conAbsReceipt | `=varAbsReceipt.Kind <> ""` | after classify/cancel until Dismiss or re-entry |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| ------ | ------------- | --------------------- | -------------------- | ---------------------------- | ------------------ | ----------------- | --------------------- |
| A-NAV-ATTENDANCE / STUDENTS / ABSENCES | CanManageStudents | btnAbsNav*.OnSelect Navigate(...) | N/A | screen change | N/A | N/A | current button teal |
| A-LOAD-ABSENCES | CanClassify, campus, From <= To | OnVisible / filters / btnAbsReload -> btnAbsLoadEngine.OnSelect | Attendance.Attendance -> colAbsList.AttId | colAbsList = server filter | N/A | N/A | galAbsList, lblAbsCount |
| A-FILTER-ABSENCES | CanClassify | ddAbsCampus / dpAbsFrom / dpAbsTo / rdoAbsStatus OnChange (reload); ddAbsTeacher OnChange (local); btnAbsClearFilters | filter variables | Items + count follow every filter; Clear restores defaults | N/A | N/A | lblAbsCount lists status word, campus, teacher, dates |
| A-TICK | row not Locked | chkAbsRowTick OnCheck/OnUncheck; btnAbsSelectAll; btnAbsClearTicks | colAbsTicked.AttId | ticked set | N/A | N/A | lblAbsBulkHint "N ticked" |
| A-CLASSIFY-EXCUSED | not Locked; reason chosen | btnAbsRowExcused -> btnAbsDecideSave.OnSelect -> btnAbsClassifyEngine | Attendance by varAbsSelId | Excused + reason + by/on; audit; cache row updated; prompt closed | Absence Classification, Absence Reason, Classified By, Classified On (+ audit row) | Student, Date, Teacher, Campus, Before, Classification, Reason, Classified by, Classified on, Audit event | conAbsReceipt; row badge / row leaves queue; Screen1 E |
| A-CLASSIFY-UNEXCUSED | not Locked; not already Unexcused | btnAbsRowUnexcused.OnSelect -> engine | Attendance by ThisItem.AttId | Unexcused, reason cleared | same | same (Reason "None (cleared)") | conAbsReceipt; Screen1 U |
| A-BULK-EXCUSED | TICKED > 0, bulk reason | btnAbsBulkExcused.OnSelect -> engine | each colAbsWork.AttId | one Patch per row | same per row | Operation, Reason, Ticked, Marked, Failed, Skipped + per-row lines | title "N marked Excused (Reason), F failed" |
| A-BULK-UNEXCUSED | TICKED > 0 | btnAbsBulkUnexcused.OnSelect -> engine | same | same, reason cleared | same | same | title "N marked Unexcused, F failed" |

Cancel (prompt): btnAbsDecideCancel — receipt Kind "Cancelled", no write, varAbsSelId / varAbsReasonId cleared.

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| -------------- | ------------------------ | ------------------- |
| ddAbsCampus | lblAbsCampus `="Campus"` | conAbsCampusField |
| ddAbsTeacher | lblAbsTeacher `="Teacher"` | conAbsTeacherField |
| dpAbsFrom | lblAbsFrom `="From date"` | conAbsFromField |
| dpAbsTo | lblAbsTo `="To date"` | conAbsToField |
| rdoAbsStatus | lblAbsStatus `="Status"` | conAbsStatusField |
| ddAbsBulkReason | lblAbsBulkReason `="Reason for Mark Excused"` | conAbsBulkReasonField |
| rdoAbsReason | lblAbsReason `="Reason *"` | conAbsReasonField |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| ------ | --------------- | ----------------------------- | ---------------------------------- | -------------------- | ----------------------------------- | ----------------- |
| A-CLASSIFY-* | `wr` -> colAbsLog -> varAbsReceipt / colAbsReceiptLines | Attendance by AttId | galAbsList row (colAbsList); Screen1 colMonthAtt | w.AttId = wr.Attendance = colAbsLog.AttId = colAbsList.AttId | engine `Patch(colAbsList, c, {...wr})` on success only; Screen1 OnVisible reload | row matched by AttId; leaves list when status filter no longer matches |
| A-BULK-* | per-row `wr` -> colAbsLog -> title + per-row lines | Attendance | galAbsList; lblAbsBulkHint | per AttId | same per row; `RemoveIf(colAbsTicked, AttId in marked)` | per-row receipt line student · date |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| ------ | ----- | -------------- | ---------------------------- | ------------------------------- | --------------------- | ------------------- |
| A-CLASSIFY-* / A-BULK-* | Absence Classification | Changed | req.Kind | literal Switch arm | "Classification" / per-row value from wr | badgeAbsRowStatus |
| A-CLASSIFY-* / A-BULK-* | Absence Reason | Changed | rsn (varAbsReasonId / varAbsBulkReasonId) or Blank() | Patch | "Reason" from wr | lblAbsRowNote |
| A-CLASSIFY-* / A-BULK-* | Classified By / On | Changed | CurrentUserRow / Now() | Patch | "Classified by" / "Classified on" from wr | lblAbsRowNote |
| A-CLASSIFY-* / A-BULK-* | Present, Is Deleted, Date, Student, Teacher, Campus | Preserved | live row | omitted from Patch | "Student", "Date", "Teacher", "Campus" lines | lblAbsRowName / lblAbsRowMeta |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| -------- | ----- | ---- | ---- | ---------------- | ------------------------- |
| S-QUEUE-DEFAULT | Office (North), unclassified absences this school year | Open screen | North, school-year start .. today, Not classified | lblAbsCount "N not classified · North · All teachers · …" | campus dropdown disabled for Office |
| S-QUEUE-FILTER | Admin, T1 has >= 2 rows, T2 >= 1 | Pick T1; then Clear filters | Only T1 rows; then all | galAbsList, lblAbsCount | Status Excused reloads with Excused predicate |
| S-QUEUE-EMPTY | Range with no absences | Set dates | empty | lblAbsCount "0 not classified. Nothing matches…" | From > To message |
| S-ONE-EXCUSED | Unclassified A1 | Excused… -> Illness -> Save as Excused | A1 Excused (Illness), by me, now; audit | Receipt title + 10 lines; row leaves queue | Cancel -> "Excused cancelled … nothing was changed" |
| S-ONE-EXCUSED-NO-REASON | A1 picked, no reason | — | Save disabled | lblAbsDecideCheck "Choose a reason…" | engine blocks with "Excused needs a reason" |
| S-ONE-UNEXCUSED | Unclassified A2 | Unexcused | A2 Unexcused, reason blank | Receipt Reason "None (cleared)" | disabled when already Unexcused |
| S-RECLASSIFY | A1 Excused (Illness) | Status Excused; A1 Unexcused | A1 Unexcused; audit Before "Excused (Illness)" | Receipt Before / Classification | Excused… preselects Illness |
| S-BULK-EXCUSED | A3, A4, A5 ticked | Illness + Mark Excused | 3 rows Excused | "3 marked Excused (Illness), 0 failed" + 3 lines | ticks hidden by a filter are not sent |
| S-BULK-UNEXCUSED | Select all shown (2 rows) | Mark Unexcused | 2 rows Unexcused | "2 marked Unexcused, 0 failed" | — |
| S-BULK-NONE-TICKED | nothing ticked | — | bulk buttons disabled | lblAbsBulkHint "No absences ticked…" | Mark Excused also needs a reason |
| S-LOCKED | Month Locks North 2026-08-01 Locked | Load August | rows show "Month locked · cannot classify", actions disabled, excluded from Select all | lblAbsRowNote | locked after load -> engine "Skipped · locked" |

## Relevant Data Source Schemas

- Attendance: Attendance (Guid), 'Record Key', Date, Present (Boolean), 'Is Deleted' (Boolean), Student (-> 'Display Name',
  'Student Number', Student), Teacher (-> Name, Staff), Campus (-> Name, Campus), 'Absence Classification'
  ('Absence Classification (Attendance)'.Excused / .Unexcused; blank = not classified; filter with `= Blank()`),
  'Absence Reason' (-> Name, 'Absence Reason'), 'Classified By' (Users -> 'Full Name'), 'Classified On' (DateTime), 'Modified On'.
- 'Absence Reasons': 'Absence Reason' (Guid), Name, Active (Boolean), 'Sort Order' (Number).
- 'Month Locks': Campus (-> Campus), Month (Date, first of month), 'Status (aaca_status)' ('Status (Month Locks)'.Locked).
- Campuses: Campus, Name. Staff: Staff, Name, 'App Role' ('App Role (Staff)'.Teacher), Campus.
- 'Audit Events': Summary, Action ('Action (Audit Events)'.Reclassify), Entity, 'Entity ID', Before, After, Reason.

## Required Variants

- GroupContainer -> `Variant: AutoLayout` (every container on this screen)
- Gallery -> `Variant: Vertical` (galAbsList, galAbsReceipt)

## Control Definitions

- **GroupContainer** (`Control: GroupContainer`, Variant required). Inputs: BorderColor, BorderStyle, BorderThickness,
  ContentLanguage, DropShadow, EnableChildFocus, Fill, Height, RadiusBottomLeft/BottomRight/TopLeft/TopRight, Visible,
  Width, X, Y; AutoLayout: LayoutAlignItems, LayoutDirection (required), LayoutGap, LayoutJustifyContent, LayoutOverflowX,
  LayoutOverflowY, LayoutWrap, PaddingBottom/Left/Right/Top; as child: AlignInContainer, FillPortions, LayoutMaxHeight,
  LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth.
  Enums: `DropShadow.None`; `LayoutDirection.Vertical` / `.Horizontal`; `LayoutAlignItems.Stretch` / `.Center` / `.Start` / `.End`;
  `LayoutOverflow.Scroll`; `AlignInContainer.Stretch` / `.Center` / `.Start` / `.End`.
- **ModernText** (`Control: ModernText`). Inputs: AccessibleLabel, Align, AutoHeight, BorderColor, BorderStyle,
  BorderThickness, Color, ContentLanguage, DisplayMode, Fill, Font, FontWeight, Height, Italic, OnSelect,
  PaddingBottom/Left/Right/Top, Radius*, Size, Strikethrough, Text, Underline, VerticalAlign, Visible, Width, Wrap, X, Y;
  child: AlignInContainer, FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth.
  Enums: `FontWeight.Bold` / `.Semibold` / `.Normal`; `VerticalAlign.Top` / `.Middle`.
- **ModernButton** (`Control: ModernButton`). Inputs: AccessibleLabel, Align, Appearance, BasePaletteColor, BorderColor,
  BorderStyle, BorderThickness, Color, ContentLanguage, DisplayMode, Font, FontWeight, Height, Icon, IconRotation,
  IconStyle, Italic, Layout, OnSelect, Padding*, Radius*, Size, Strikethrough, Text, Tooltip, Underline, VerticalAlign,
  Visible, Width, X, Y; child keys as above. No Fill.
  Enums: `ButtonAppearance.Secondary`; `ButtonLayout.TextOnly`; `DisplayMode.Edit` / `.Disabled`.
- **Classic/Button** (`Control: Classic/Button`). Inputs used: AutoDisableOnSelect, OnSelect, Text, Visible; child keys.
  Full list: Align, AutoDisableOnSelect, BorderColor, BorderStyle, BorderThickness, Color, ContentLanguage,
  DisabledBorderColor, DisabledColor, DisabledFill, DisplayMode, Fill, FocusedBorderColor, FocusedBorderThickness, Font,
  FontWeight, Height, HoverBorderColor, HoverColor, HoverFill, Italic, OnSelect, Padding*, PressedBorderColor,
  PressedColor, PressedFill, Radius*, Size, Strikethrough, TabIndex, Text, Tooltip, Underline, VerticalAlign, Visible,
  Width, X, Y. No AccessibleLabel.
- **Gallery** (`Control: Gallery`, `Variant: Vertical`). Inputs: AccessibleLabel, BorderColor, BorderStyle,
  BorderThickness, ContentLanguage, Default, DelayItemLoading, DisplayMode, Fill, FocusedBorderColor,
  FocusedBorderThickness, Height, Items, LoadingSpinner, LoadingSpinnerColor, NavigationStep, Selectable,
  ShowNavigation, ShowScrollbar, TabIndex, TemplatePadding, TemplateSize, Transition, Visible, Width, WrapCount, X, Y;
  child keys. Outputs TemplateWidth, TemplateHeight.
- **ModernDropdown** (`Control: ModernDropdown`). Inputs: AccessibleLabel, Appearance, BasePaletteColor, BorderColor,
  BorderStyle, BorderThickness, Color, ContentLanguage, Default, DisplayMode, Fill, Font, FontWeight, Height, Italic,
  ItemDisplayText, Items, OnChange, Padding*, Radius*, Required, Size, Strikethrough, Underline, ValidationState,
  Visible, Width, X, Y; child keys. Output Selected. Enum: `Appearance.Outline`.
- **ModernDatePicker** (`Control: ModernDatePicker`). Inputs: AccessibleLabel, Appearance, BasePaletteColor, BorderColor,
  BorderStyle, BorderThickness, Color, ContentLanguage, DateTimeZone, DefaultDate, DisplayMode, EndDate, Fill, Font,
  FontWeight, Format, Height, IsEditable, Italic, OnChange, Padding*, Placeholder, Radius*, Size, StartDate, StartOfWeek,
  Strikethrough, Underline, ValidationState, Visible, Width, X, Y; child keys. Output SelectedDate.
  Enums: `Appearance.Outline`; `DatePickerFormat.Short`.
- **ModernRadio** (`Control: ModernRadio`). Inputs: AccessibleLabel, BasePaletteColor, BorderColor, BorderStyle,
  BorderThickness, Color, ContentLanguage, Default, DisabledColor, DisplayMode, Fill, Font, FontWeight, Height, Italic,
  ItemDisplayText, Items, Layout, LineHeight, OnChange, Padding*, RadioBackgroundFill, RadioBorderColor,
  RadioSelectionFill, RadioSize, Radius*, Required, Size, Strikethrough, Underline, Visible, Width, X, Y; child keys.
  Output Selected. Enum: `OptionLayout.Vertical` / `OptionLayout.Horizontal`.
- **ModernCheckbox** (`Control: ModernCheckbox`). Inputs: AccessibleLabel, BasePaletteColor, CheckboxSize, Color,
  ContentLanguage, Default, DisplayMode, Font, FontWeight, Height, Italic, Label, OnCheck, OnUncheck, Size,
  Strikethrough, Tooltip, Underline, Visible, Width, X, Y; child keys. Output Checked.
- **ModernSpinner** (`Control: ModernSpinner`). Inputs: AccessibleLabel, Appearance, BasePaletteColor, Color,
  ContentLanguage, DisplayMode, Font, FontWeight, Height, Italic, Label, LabelPosition, LineHeight, Padding*, Size,
  SpinnerColor, Strikethrough, Tooltip, TrackColor, Underline, Visible, Width, X, Y; child keys.
- **Badge** (`Control: Badge`). Inputs: AccessibleLabel, Align, Appearance, BasePaletteColor, Content, ContentLanguage,
  DisplayMode, Font, FontColor, FontItalic, FontSize, FontStrikethrough, FontUnderline, FontWeight, Height, Shape,
  ThemeColor, VerticalAlign, Visible, Width, X, Y; child keys.
  Enums: `'BadgeCanvas.Appearance'.Tint`; `'BadgeCanvas.Shape'.Rounded`; `'BadgeCanvas.ThemeColor'.Success` / `.Danger` / `.Warning`.
