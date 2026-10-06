# Screen Plan: Absences (AbsencesScreen)

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml`
- YAML key: AbsencesScreen
- Control name prefix: Abs (existing). NEW controls use `AbsCf` (Needs a decision), `AbsRm` (Remove absence),
  `AbsMe` (Mapping Errors) and the single row label `lblAbsRowSrcV`.
- Read with: `C:\src\aaca-attendance\docs\app-builds\build-8-absences\canvas-app-shared.md`

## Current State

`conAbsRoot` (sole top-level scroll root) children in order: `conAbsHeader`, `conAbsViewBar`
(`btnAbsViewClassify`, `btnAbsViewNr`, `btnAbsApViewReady`), `conAbsDenied`, `conAbsClassifyView`
(`conAbsNoticeV`, `spnAbsLoadingV`, `conAbsReceiptV`, `conAbsBodyV` > `conAbsListPanelV` / `conAbsDecideV`),
`conAbsNrView`, `btnAbsLoadEngine`, `btnAbsClassifyEngine`, `conAbsApView`, `btnAbsNrEngine`, `btnAbsApEngine`,
`btnAbsApPlanEngine`. The classify view (controls ending in `V`) and its engines stay; the Needs review (`AbsNr`) and
Ready to approve (`AbsAp`) parts go.

**HARD RULES:** never move a surviving control into a different parent and never rename one (Studio renders them as
black boxes). Delete removed controls outright (not `Visible: =false`). New siblings may be inserted into existing
containers at the positions given below. Every value containing `: ` or ` #` must be a `|-` block.

## Controls to Remove

Delete each of these together with ALL of its descendants:

1. `btnAbsViewNr` and `btnAbsApViewReady` (children of `conAbsViewBar`).
2. `conAbsNrView` (whole Needs review view: spnAbsNrBusy, conAbsNrReceipt…, conAbsNrBody…, cboAbsNrStudent, chkAbsNrAll,
   btnAbsNrResolve, btnAbsNrCancel, …).
3. `conAbsApView` (whole Ready to approve view: spnAbsApBusy, conAbsApReceipt…, galAbsApRcptDays, btnAbsApShowGrid,
   conAbsApBody…, galAbsApList, conAbsApDetail…, btnAbsApApprove, conAbsApDismissPanel…).
4. `btnAbsNrEngine`, `btnAbsApEngine`, `btnAbsApPlanEngine`.

After deletion no formula on the screen may reference `varAbsNr*`, `varAbsAp*`, `colAbsNr*`, `colAbsAp*`.

Resulting `conAbsRoot` children order: `conAbsHeader`, `conAbsViewBar`, `conAbsDenied`, `conAbsClassifyView`,
NEW `conAbsMeView`, `btnAbsLoadEngine`, `btnAbsClassifyEngine`, NEW `btnAbsMeEngine`.

## Properties to Update

1. `AbsencesScreen.OnVisible` - replace entirely (`|-`):
```
=Set(varAbsSaving, false);
Set(varAbsMeSaving, false);
Set(varAbsSelId, Blank());
Set(varAbsReasonId, Blank());
Set(varAbsReceipt, {Kind: "", Title: ""});
Clear(colAbsReceiptLines);
If(varAbsView <> "errors", Set(varAbsView, "classify"));
If(StudentCampusLock <> ZeroGuid, Set(varAbsCampusId, StudentCampusLock));
IfError(
    Concurrent(
        ClearCollect(colAbsCampusOpts, ForAll(Sort(Campuses, Name, SortOrder.Ascending) As c, {CampusId: c.Campus, CampusName: c.Name})),
        ClearCollect(colAbsTeacherSrc, ForAll(Sort(Filter(Staff, 'App Role' = 'App Role (Staff)'.Teacher), Name, SortOrder.Ascending) As t, {TeacherId: t.Staff, TeacherName: t.Name, CampusId: t.Campus.Campus})),
        ClearCollect(colAbsReasons, ForAll(Sort(Filter('Absence Reasons', Active = true), 'Sort Order', SortOrder.Ascending) As a, {ReasonId: a.'Absence Reason', ReasonName: a.Name, SortOrder: a.'Sort Order'}))
    ); true,
    Set(varAbsLoadError, FirstError.Message)
);
ClearCollect(colAbsTeacherOpts, {TeacherId: ZeroGuid, TeacherName: "All teachers", CampusId: ZeroGuid}, colAbsTeacherSrc);
ClearCollect(colAbsMeCampusOpts, {CampusId: ZeroGuid, CampusName: "All campuses"}, colAbsCampusOpts);
Select(btnAbsLoadEngine);
Select(btnAbsMeEngine)
```
2. `conAbsRoot`: add `LayoutMinWidth: =0` and `LayoutMinHeight: =0` (keep everything else).
3. `conAbsViewBar`: `Height: =If(conAbsRoot.Width < 640, 96, 44)`;
   `LayoutAlignItems: =If(conAbsRoot.Width < 640, LayoutAlignItems.Stretch, LayoutAlignItems.Center)`;
   `LayoutDirection: =If(conAbsRoot.Width < 640, LayoutDirection.Vertical, LayoutDirection.Horizontal)`.
4. `btnAbsViewClassify`: `AlignInContainer: =If(conAbsRoot.Width < 640, AlignInContainer.Stretch, AlignInContainer.Center)`;
   `Width: =If(conAbsRoot.Width < 640, Parent.Width - 32, 170)`. Everything else unchanged.
5. `conAbsClassifyView.Height`:
   `=If(conAbsNoticeV.Visible, conAbsNoticeV.Height + 8, 0) + If(spnAbsLoadingV.Visible, 48 + 8, 0) + If(conAbsReceiptV.Visible, conAbsReceiptV.Height + 8, 0) + If(conAbsCfPanel.Visible, conAbsCfPanel.Height + 8, 0) + If(conAbsBodyV.Visible, conAbsBodyV.Height, 0)`
6. `conAbsListPanelV.Height` (`|-`) - adds the Remove row (`8 + If(n, 110, 58)`) after the bulk row:
```
=With(
    {n: conAbsRoot.Width < 640, k: CountRows(Filter(colAbsList, (varAbsTeacherId = ZeroGuid || TeacherId = varAbsTeacherId) && (varAbsStatus = "All" || ClassText = varAbsStatus))) > 0},
    16 + 44 + 8 + 58 + 8 + 58 + 8 + If(n, 138, 58) + 8 + 44 + 8 + If(n, 110, 58) + 8 + If(n, 110, 58) + 8 + If(n, 36, 18) + 8 + If(n, 60, 40) + If(k, 8 + 520, 0) + 16
)
```
7. `galAbsListV.TemplateSize: =If(conAbsRoot.Width < 640, 268, 170)`.
8. `btnAbsLoadEngine.OnSelect` - replace entirely (`|-`). Same as today plus the new colAbsList fields, colAbsCf and
   colAbsCfRpt:
```
=Set(varAbsLoading, true);
Set(varAbsLoadError, "");
Clear(colAbsTicked);
Set(varAbsSelId, Blank());
If(
    !CanClassify || varAbsCampusId = ZeroGuid || IsBlank(varAbsFrom) || IsBlank(varAbsTo) || varAbsFrom > varAbsTo,
    Clear(colAbsList); Clear(colAbsCf); Clear(colAbsCfRpt),
    IfError(
        ClearCollect(colAbsLocks, ForAll(Filter('Month Locks', 'Status (aaca_status)' = 'Status (Month Locks)'.Locked) As m, {CampusId: m.Campus.Campus, MonthStart: m.Month})); true,
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
                        ModifiedOn: r.'Modified On',
                        SrcText: If(
                            r.Source = 'Source (Attendance)'.'Parent report' || (IsBlank(r.Source) && !IsBlank(r.'Source Report ID')), If(IsBlank(r.'Source Report ID'), "Parent report", "Parent report #" & r.'Source Report ID'),
                            r.Source = 'Source (Attendance)'.Office, "Office" & If(IsBlank(r.'Source Report ID'), "", " (parent report #" & r.'Source Report ID' & ")"),
                            r.Source = 'Source (Attendance)'.Teacher, "Teacher",
                            ""
                        ),
                        ParentReason: With(
                            {n: Coalesce(r.Notes, ""), p: Find(": ", Coalesce(r.Notes, ""))},
                            If(
                                n = "" || (IsBlank(r.'Source Report ID') && r.Source <> 'Source (Attendance)'.'Parent report'), "",
                                StartsWith(n, "Parent report #") && !IsBlank(p), Mid(n, p + 2),
                                n
                            )
                        ),
                        NoticeOn: r.'Notice Received On'
                    }
                )
            );
            ClearCollect(
                colAbsCf,
                ForAll(
                    Filter(Attendance, 'Parent Reported Absent' = true && Present = true && 'Is Deleted' = false && Campus.Campus = c0 && Date >= d0 && Date <= d1) As r,
                    {
                        AttId: r.Attendance,
                        StudentName: Coalesce(r.Student.'Display Name', "Unknown student"), StudentNumber: Coalesce(r.Student.'Student Number', "—"),
                        AbsDate: r.Date,
                        TeacherName: Coalesce(r.Teacher.Name, "No teacher"),
                        ReportId: Coalesce(r.'Source Report ID', 0),
                        NoticeOn: r.'Notice Received On',
                        Locked: !IsBlank(LookUp(colAbsLocks, CampusId = r.Campus.Campus && MonthStart = Date(Year(r.Date), Month(r.Date), 1)))
                    }
                )
            )
        ); true,
        Set(varAbsLoadError, FirstError.Message)
    );
    IfError(
        ClearCollect(colAbsCfRpt, ForAll(Distinct(Filter(colAbsCf, ReportId > 0), ReportId) As k, With({q: k.Value}, {ReportId: q, Reason: Coalesce(LookUp('Student Absence Log', ID = q).Reason, "")}))); true,
        Set(varAbsLoadError, "Parent reasons could not be read from SharePoint (" & FirstError.Message & ")")
    )
);
Set(varAbsLoading, false)
```

`btnAbsClassifyEngine`, `conAbsDecideV`, the filters, ticks, bulk Mark Excused / Mark Unexcused and the row
Excused… / Unexcused buttons are NOT changed.

## Controls to Add

Conventions for every new control (do not repeat per item): GroupContainer = `Variant: AutoLayout`,
`DropShadow: =DropShadow.None`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, explicit `FillPortions`, explicit
`AlignInContainer` (Stretch unless stated), radius 0 unless stated. ModernText = Padding* 0, `LayoutMinWidth: =0`,
`LayoutMinHeight: =0`, `AlignInContainer: =AlignInContainer.Stretch`, `AccessibleLabel: =Self.Text` unless stated,
`FillPortions: =0` with the given `Height`. ModernButton = `Height: =44`, `Layout: =ButtonLayout.TextOnly`,
`Size: =14`, `LayoutMinHeight: =0`, `LayoutMinWidth: =0`, `FillPortions: =0`, `AlignInContainer: =AlignInContainer.Center`
unless stated; "Secondary" = `Appearance: =ButtonAppearance.Secondary` + `Color: =ColorInk`; "teal" =
`BasePaletteColor: =ColorTeal` + `Color: =ColorWhite`; "red" = `BasePaletteColor: =ColorUnexcused` + `Color: =ColorWhite`.
Label style = Size 12, Semibold, `Color: =ColorMuted`, Height 18, `Wrap: =false`. Inputs = `Appearance: =Appearance.Outline`,
`Color: =ColorInk`, `Height: =36`, `AlignInContainer: =AlignInContainer.Stretch`, `FillPortions: =0`.
Galleries = `Variant: Vertical`, `FillPortions: =0`, `TemplatePadding: =0`, `TabIndex: =0`, `Selectable: =false`,
`LayoutMinHeight: =0`, `LayoutMinWidth: =0`; the single shell child = vertical, `Width: =Parent.TemplateWidth - 16`,
`Height: =Parent.TemplateHeight`, `BorderColor: =ColorRule`, `BorderThickness: =1`, padding 8, gap 4,
`LayoutAlignItems: =LayoutAlignItems.Stretch`.

### A. View bar - append after `btnAbsViewClassify` inside `conAbsViewBar`

```
btnAbsMeViewErrors   ModernButton
  AccessibleLabel: =Self.Text & If(varAbsView = "errors", " (current view)", "")
  AlignInContainer: =If(conAbsRoot.Width < 640, AlignInContainer.Stretch, AlignInContainer.Center)
  Appearance: =If(varAbsView = "errors", ButtonAppearance.Primary, ButtonAppearance.Secondary)
  BasePaletteColor: =ColorTeal;  Color: =If(varAbsView = "errors", ColorWhite, ColorInk)
  OnSelect: =Set(varAbsView, "errors"); If(!varAbsMeLoaded && !varAbsMeLoading, Select(btnAbsMeEngine))
  Text: ="Mapping Errors (" & If(varAbsMeLoaded, Text(CountRows(colAbsMe)), "…") & ")"
  Width: =If(conAbsRoot.Width < 640, Parent.Width - 32, 220)
```

### B. Row line - insert in `conAbsRowShellV` between `lblAbsRowMetaV` and `conAbsRowBottomV`

```
lblAbsRowSrcV   ModernText; Size 12; Color =ColorInk; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 72, 36)
  Visible: =ThisItem.SrcText <> "" || !IsBlank(ThisItem.NoticeOn) || ThisItem.ParentReason <> ""
  Text (|-):
    =ThisItem.SrcText & If(IsBlank(ThisItem.NoticeOn), "", If(ThisItem.SrcText = "", "", " · ") & "Reported " & Text(ThisItem.NoticeOn, "mmm d, yyyy h:mm AM/PM") & " (Pacific)") & If(ThisItem.ParentReason = "", "", " · Reason: " & If(Len(ThisItem.ParentReason) > 100, Left(ThisItem.ParentReason, 100) & "…", ThisItem.ParentReason))
```

### C. Remove row - insert in `conAbsListPanelV` between `conAbsBulkRowV` and `lblAbsBulkHintV`

```
conAbsRmRowV   horizontal/vertical, FillPortions 0, gap 8
  Height: =If(conAbsRoot.Width < 640, 110, 58)
  LayoutDirection: =If(conAbsRoot.Width < 640, LayoutDirection.Vertical, LayoutDirection.Horizontal)
  LayoutAlignItems: =LayoutAlignItems.End
  - conAbsRmField   vertical, gap 4, Height 58, LayoutMinWidth 140, LayoutAlignItems Stretch,
                    FillPortions: =If(conAbsRoot.Width < 640, 0, 1)
      - lblAbsRmReason  (label style) Text ="Reason to remove ticked absences *"; AccessibleLabel ="Reason to remove ticked absences, required"
      - txtAbsRmReason  ModernTextInput (input style); AccessibleLabel ="Reason to remove ticked absences"; Default =""; MaxLength 500;
                        Type =TextInputType.SingleLine; Placeholder ="e.g. child came to school after all, or duplicate report";
                        DisplayMode =If(varAbsSaving, DisplayMode.Disabled, DisplayMode.Edit)
  - btnAbsRmRemove  ModernButton red; Width 200
      AlignInContainer: =If(conAbsRoot.Width < 640, AlignInContainer.Start, AlignInContainer.End)
      AccessibleLabel: ="Remove the ticked absences (soft delete)"
      Text: ="Remove ticked (" & CountRows(Filter(colAbsList, AttId in colAbsTicked.AttId && !Locked && (varAbsTeacherId = ZeroGuid || TeacherId = varAbsTeacherId) && (varAbsStatus = "All" || ClassText = varAbsStatus))) & ")"
      DisplayMode: =If(CanClassify && !varAbsSaving && !varAbsLoading && Trim(txtAbsRmReason.Text) <> "" && CountRows(Filter(colAbsList, AttId in colAbsTicked.AttId && !Locked && (varAbsTeacherId = ZeroGuid || TeacherId = varAbsTeacherId) && (varAbsStatus = "All" || ClassText = varAbsStatus))) > 0, DisplayMode.Edit, DisplayMode.Disabled)
      OnSelect: Formula R1
```

### D. Needs a decision - insert in `conAbsClassifyView` between `conAbsReceiptV` and `conAbsBodyV`

```
conAbsCfPanel   vertical, FillPortions 0, gap 8, padding 12 (all sides), radius 6, Fill =ColorWarnBg,
                BorderColor =ColorRule, BorderThickness 1, LayoutAlignItems Stretch
  Visible: =CanClassify && CountRows(colAbsCf) > 0
  Height: =12 + lblAbsCfTitle.Height + 8 + lblAbsCfHint.Height + 8 + galAbsCfList.Height + 12
  - lblAbsCfTitle   Size 16; Semibold; Color =ColorInk; VerticalAlign Top; Height =If(conAbsRoot.Width < 1024, 44, 24)
      Text: ="Needs a decision (" & CountRows(colAbsCf) & ") · Parent reported absent, teacher marked present"
  - lblAbsCfHint    Size 12; Color =ColorInk; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 54, conAbsRoot.Width < 1024, 36, 18)
      Text: ="Keep present clears the flag. Mark absent makes the day a 0 (Source Office) so you can classify it in the list below."
  - galAbsCfList    Gallery; AccessibleLabel ="Parent-report conflicts needing a decision"
      Items: =SortByColumns(colAbsCf, "AbsDate", SortOrder.Ascending, "StudentName", SortOrder.Ascending)
      TemplateSize: =If(conAbsRoot.Width < 640, 184, 130)
      Height: =Min(If(conAbsRoot.Width < 640, 3, 4), CountRows(colAbsCf)) * If(conAbsRoot.Width < 640, 184, 130)
      - conAbsCfRow   shell (see conventions); Fill =ColorWhite
          - lblAbsCfRowName   Size 14; Semibold; Color =ColorInk; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 40, 22)
              Text: =ThisItem.StudentName & " · " & ThisItem.StudentNumber
          - lblAbsCfRowMeta   Size 12; Color =ColorInk; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 72, 36)
              Text (|-): see Formula C1
          - conAbsCfRowActions  horizontal, Height 44, gap 8, FillPortions 0, LayoutAlignItems Center
              - btnAbsCfKeep    ModernButton teal; Width 130; Text ="Keep present"
                  AccessibleLabel: ="Keep " & ThisItem.StudentName & " present on " & Text(ThisItem.AbsDate, "mmm d")
                  DisplayMode: =If(CanClassify && !varAbsSaving && !varAbsLoading, DisplayMode.Edit, DisplayMode.Disabled)
                  OnSelect: Formula C2
              - btnAbsCfAbsent  ModernButton Secondary; Width 130; Text ="Mark absent"
                  AccessibleLabel: ="Mark " & ThisItem.StudentName & " absent on " & Text(ThisItem.AbsDate, "mmm d")
                  DisplayMode: =If(CanClassify && !ThisItem.Locked && !varAbsSaving && !varAbsLoading, DisplayMode.Edit, DisplayMode.Disabled)
                  OnSelect: Formula C3
```

### E. Mapping Errors view - insert in `conAbsRoot` right after `conAbsClassifyView`

```
conAbsMeView   vertical, FillPortions 0, gap 8, LayoutAlignItems Stretch
  Visible: =CanClassify && varAbsView = "errors"
  Height: =If(conAbsMeReceipt.Visible, conAbsMeReceipt.Height + 8, 0) + conAbsMeBody.Height
  - conAbsMeReceipt   vertical, gap 4, PaddingTop 8, PaddingBottom 8, PaddingLeft 12, PaddingRight 12, radius 6,
                      BorderColor =ColorRule, BorderThickness 1, FillPortions 0
      Fill: =Switch(varAbsMeReceipt.Kind, "Failed", ColorErrorBg, "Blocked", ColorErrorBg, "Dismissed", ColorWarnBg, ColorInfoBg)
      Visible: =varAbsMeReceipt.Kind <> ""
      Height: =8 + If(conAbsRoot.Width < 640, 84, 44) + If(varAbsMeReceipt.Body = "", 0, 4 + If(conAbsRoot.Width < 640, 300, 190)) + 8
      - conAbsMeReceiptTop   horizontal, gap 8, LayoutAlignItems Center, FillPortions 0, Height =If(conAbsRoot.Width < 640, 84, 44)
          - lblAbsMeReceiptTitle  Size 13; Semibold; Color =ColorInk; FillPortions 1; VerticalAlign Top;
                                  AlignInContainer Center; Height =If(conAbsRoot.Width < 640, 84, 44); Text =varAbsMeReceipt.Title
          - btnAbsMeReceiptClose  Secondary; Width 88; Text ="Close"; AccessibleLabel ="Close result"
              OnSelect (|-): =Set(varAbsMeReceipt, {Kind: "", Title: "", Body: ""})
      - lblAbsMeReceiptBody   Size 12; Color =ColorInk; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 300, 190);
                              Text =varAbsMeReceipt.Body; Visible =varAbsMeReceipt.Body <> ""
  - conAbsMeBody   FillPortions 0, gap 8
      Height: =If(conAbsRoot.Width >= 1024, Max(conAbsMeListPanel.Height, conAbsMeDetail.Height), If(conAbsMeListPanel.Visible, conAbsMeListPanel.Height, 0) + If(conAbsMeListPanel.Visible && conAbsMeDetail.Visible, 8, 0) + If(conAbsMeDetail.Visible, conAbsMeDetail.Height, 0))
      LayoutAlignItems: =If(conAbsRoot.Width >= 1024, LayoutAlignItems.Start, LayoutAlignItems.Stretch)
      LayoutDirection: =If(conAbsRoot.Width >= 1024, LayoutDirection.Horizontal, LayoutDirection.Vertical)
      - conAbsMeListPanel   vertical panel (white, rule, radius 6, padding 16, gap 8, LayoutAlignItems Stretch)
          AlignInContainer: =If(conAbsRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)
          FillPortions: =If(conAbsRoot.Width >= 1024, 1, 0)
          Visible: =!(conAbsRoot.Width < 1024 && !IsBlank(varAbsMeSelId))
          Height (|-): =With({nA: CountRows(Filter(colAbsMe, Kind = "A")), nB: CountRows(Filter(colAbsMe, Kind = "B"))}, 16 + 44 + 8 + 58 + 8 + If(conAbsRoot.Width < 640, 54, 36) + 8 + 24 + If(nA > 0, 8 + galAbsMeA.Height, 0) + 8 + 24 + If(nB > 0, 8 + galAbsMeB.Height, 0) + 16)
          - conAbsMeListHead   horizontal, Height 44, gap 8, LayoutAlignItems Center, FillPortions 0
              - lblAbsMeListTitle  Size 20; Bold; Color =ColorInk; FillPortions 1; Height 30; LayoutMinWidth 80; Wrap false;
                                   AlignInContainer Center; Text ="Mapping Errors (" & CountRows(colAbsMe) & ")"
              - btnAbsMeReload     Secondary; Width 80; Text ="Reload"; AccessibleLabel ="Reload mapping errors"
                  DisplayMode: =If(varAbsMeLoading || varAbsMeSaving, DisplayMode.Disabled, DisplayMode.Edit)
                  OnSelect: =Select(btnAbsMeEngine)
          - conAbsMeCampusField   vertical, gap 4, Height 58, FillPortions 0, LayoutAlignItems Stretch
              - lblAbsMeCampus   (label style) Text ="Campus"
              - ddAbsMeCampus    ModernDropdown (input style); AccessibleLabel ="Campus for mapping errors"
                  Items: =colAbsMeCampusOpts;  ItemDisplayText: =ThisItem.CampusName
                  Default: =LookUp(colAbsMeCampusOpts, CampusId = If(StudentCampusLock <> ZeroGuid, StudentCampusLock, varAbsMeCampusId))
                  DisplayMode: =If(StudentCampusLock = ZeroGuid && !varAbsMeLoading && !varAbsMeSaving, DisplayMode.Edit, DisplayMode.Disabled)
                  OnChange: =Set(varAbsMeCampusId, Coalesce(Self.Selected.CampusId, ZeroGuid)); Set(varAbsMeReceipt, {Kind: "", Title: "", Body: ""}); Select(btnAbsMeEngine)   (|-)
          - lblAbsMeCount   Size 13; Semibold; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 54, 36)
              Color: =If(varAbsMeLoadError <> "", ColorUnexcused, ColorInk)
              Text (|-): see Formula M2
          - lblAbsMeAHead   Size 16; Semibold; Color =ColorInk; Height 24; Wrap false
              Text: ="No Student ID (" & CountRows(Filter(colAbsMe, Kind = "A")) & ")" & If(CountRows(Filter(colAbsMe, Kind = "A")) = 0, " · none", "")
          - galAbsMeA   Gallery; AccessibleLabel ="Reports with no Student ID"
              Items: =SortByColumns(Filter(colAbsMe, Kind = "A"), "Created", SortOrder.Descending)
              TemplateSize: =If(conAbsRoot.Width < 640, 158, 140)
              Height: =Min(3, CountRows(Filter(colAbsMe, Kind = "A"))) * If(conAbsRoot.Width < 640, 158, 140)
              Visible: =CountRows(Filter(colAbsMe, Kind = "A")) > 0
              - conAbsMeARow   shell; Fill =If(ThisItem.ItemId = varAbsMeSelId, ColorInfoBg, ColorWhite)
                  - conAbsMeATop   horizontal, Height 44, gap 8, LayoutAlignItems Center, FillPortions 0
                      - lblAbsMeAName   Size 14; Semibold; Color =ColorInk; FillPortions 1; Height 42; VerticalAlign Top; AlignInContainer Center
                          Text (|-): ="#" & ThisItem.ItemId & " · " & If(Trim(ThisItem.LastName & ThisItem.FirstName) = "", "(no name typed)", ThisItem.LastName & ", " & ThisItem.FirstName) & " (as typed)"
                      - btnAbsMeAOpen   Secondary; Width 90; Text ="Open"; AccessibleLabel (|-) ="Open report #" & ThisItem.ItemId
                          DisplayMode: =If(varAbsMeLoading || varAbsMeSaving, DisplayMode.Disabled, DisplayMode.Edit)
                          OnSelect: Formula M3
                  - lblAbsMeAMeta   Size 12; Color =ColorInk; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 90, 72)
                      Text (|-): =If(ThisItem.SchoolSite = "", "No school site", ThisItem.SchoolSite) & " · absent " & If(ThisItem.AbsText = "", "—", ThisItem.AbsText) & If(ThisItem.RetText = "", "", " · back " & ThisItem.RetText) & " · Reason " & If(ThisItem.Reason = "", "—", If(Len(ThisItem.Reason) > 80, Left(ThisItem.Reason, 80) & "…", ThisItem.Reason)) & " · submitted by " & If(ThisItem.SubmittedBy = "", "—", ThisItem.SubmittedBy) & " · notified " & If(ThisItem.Notified = "", "—", ThisItem.Notified)
          - lblAbsMeBHead   Size 16; Semibold; Color =ColorInk; Height 24; Wrap false
              Text: ="Could not process (" & CountRows(Filter(colAbsMe, Kind = "B")) & ")" & If(CountRows(Filter(colAbsMe, Kind = "B")) = 0, " · none", "")
          - galAbsMeB   Gallery; AccessibleLabel ="Reports the intake flow could not process"
              Items: =SortByColumns(Filter(colAbsMe, Kind = "B"), "DecCreated", SortOrder.Descending)
              TemplateSize: =If(conAbsRoot.Width < 640, 158, 140)
              Height: =Min(3, CountRows(Filter(colAbsMe, Kind = "B"))) * If(conAbsRoot.Width < 640, 158, 140)
              Visible: =CountRows(Filter(colAbsMe, Kind = "B")) > 0
              - conAbsMeBRow   shell; Fill =If(ThisItem.ItemId = varAbsMeSelId, ColorInfoBg, ColorWhite)
                  - conAbsMeBTop   horizontal, Height 44, gap 8, LayoutAlignItems Center, FillPortions 0
                      - lblAbsMeBName   (same style as lblAbsMeAName)
                          Text (|-): ="#" & ThisItem.ItemId & " · Student key " & If(ThisItem.StudentKey = "", "—", ThisItem.StudentKey) & If(ThisItem.Status = "", "", " · " & ThisItem.Status)
                      - btnAbsMeBOpen   (same as btnAbsMeAOpen) OnSelect: Formula M3
                  - lblAbsMeBMeta   Size 12; Color =ColorInk; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 90, 72)
                      Text (|-): ="Error: " & If(ThisItem.ErrorDetail = "", "—", If(Len(ThisItem.ErrorDetail) > 160, Left(ThisItem.ErrorDetail, 160) & "…", ThisItem.ErrorDetail)) & " · created " & Text(ThisItem.DecCreated, "mmm d, yyyy h:mm AM/PM")
      - conAbsMeDetail   vertical panel (white, rule, radius 6, padding 16, gap 8, LayoutAlignItems Stretch)
          AlignInContainer: =If(conAbsRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)
          FillPortions: =If(conAbsRoot.Width >= 1024, 1, 0)
          Visible: =conAbsRoot.Width >= 1024 || !IsBlank(varAbsMeSelId)
          Height: =16 + 28 + 8 + lblAbsMeFacts.Height + If(conAbsMeModeBar.Visible, 8 + conAbsMeModeBar.Height, 0) + If(conAbsMeMapPanel.Visible, 8 + conAbsMeMapPanel.Height, 0) + If(conAbsMeDatesPanel.Visible, 8 + conAbsMeDatesPanel.Height, 0) + If(conAbsMeDismissPanel.Visible, 8 + conAbsMeDismissPanel.Height, 0) + 16
          - lblAbsMeDetailTitle  Size 18; Bold; Color =ColorInk; Height 28; Wrap false; Text ="Fix a mapping error"
          - lblAbsMeFacts   Size 13; Color =ColorInk; VerticalAlign Top
              Height: =If(IsBlank(LookUp(colAbsMe, ItemId = varAbsMeSelId)), 60, If(conAbsRoot.Width < 640, 320, 210))
              Text (|-): see Formula M4
          - conAbsMeModeBar   horizontal, LayoutWrap =true, gap 8, LayoutAlignItems Center, FillPortions 0
              Height: =If(conAbsRoot.Width < 640, 96, 44)
              Visible: =!IsBlank(varAbsMeSelId)
              - btnAbsMeModeMap      Width 130; Text ="Map student"; toggle style with active =varAbsMeMode = "map";
                                     AccessibleLabel =Self.Text & If(varAbsMeMode = "map", " (open)", "");
                                     DisplayMode =If(varAbsMeSaving, DisplayMode.Disabled, DisplayMode.Edit); OnSelect =Set(varAbsMeMode, "map")
              - btnAbsMeModeDates    Width 110; Text ="Fix dates"; active =varAbsMeMode = "dates"; same DisplayMode;
                                     Visible =LookUp(colAbsMe, ItemId = varAbsMeSelId).Kind = "B"; OnSelect =Set(varAbsMeMode, "dates")
              - btnAbsMeModeDismiss  Width 100; Text ="Dismiss"; active =varAbsMeMode = "dismiss"; same DisplayMode;
                                     AccessibleLabel =Self.Text & " this report" & If(varAbsMeMode = "dismiss", " (open)", ""); OnSelect =Set(varAbsMeMode, "dismiss")
              - btnAbsMeClose        Secondary; Width 90; Text ="Close"; AccessibleLabel ="Close this report without changes"
                                     DisplayMode =If(varAbsMeSaving, DisplayMode.Disabled, DisplayMode.Edit); OnSelect: Formula M5
          - conAbsMeMapPanel   vertical, gap 8, FillPortions 0, LayoutAlignItems Stretch
              Visible: =!IsBlank(varAbsMeSelId) && varAbsMeMode = "map"
              Height: =If(conAbsRoot.Width < 640, 190, 172)
              - conAbsMeMapField   vertical, gap 4, Height 58, FillPortions 0
                  - lblAbsMeStudent   (label style) Text ="Student *"; AccessibleLabel ="Student, required"
                  - cboAbsMeStudent   ModernCombobox (input style); AccessibleLabel ="Student"; SelectMultiple =false; IsSearchable =true;
                                      DefaultSelectedItems =[]; InputTextPlaceholder ="Type a name or Student Key"; ItemDisplayText =ThisItem.Label
                      Items (|-): =With({cid: LookUp(colAbsMe, ItemId = varAbsMeSelId).CampusId}, Sort(Filter(colAbsMeStudents, IsBlank(cid) || cid = ZeroGuid || CampusId = cid), DisplayName, SortOrder.Ascending))
                      DisplayMode: =If(varAbsMeSaving, DisplayMode.Disabled, DisplayMode.Edit)
              - lblAbsMeMapCheck   Size 13; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 72, 54)
                  Color: =If(StartsWith(Self.Text, "Ready"), ColorExcused, ColorUnexcused)
                  Text (|-): see Formula M6
              - btnAbsMeMapSave   teal; Width 160; AlignInContainer Start; Text ="Save mapping"; AccessibleLabel ="Save mapping to SharePoint"
                  DisplayMode: =If(CanClassify && !varAbsMeSaving && !IsBlank(LookUp(colAbsMe, ItemId = varAbsMeSelId)) && CountRows(cboAbsMeStudent.SelectedItems) = 1 && Trim(Coalesce(First(cboAbsMeStudent.SelectedItems).StudentKey, "")) <> "", DisplayMode.Edit, DisplayMode.Disabled)
                  OnSelect: Formula M7
          - conAbsMeDatesPanel   vertical, gap 8, FillPortions 0, LayoutAlignItems Stretch
              Visible: =!IsBlank(varAbsMeSelId) && varAbsMeMode = "dates" && LookUp(colAbsMe, ItemId = varAbsMeSelId).Kind = "B"
              Height: =If(conAbsRoot.Width < 640, 256, 172)
              - conAbsMeDatesRow   gap 8, FillPortions 0, LayoutAlignItems Stretch
                  Height: =If(conAbsRoot.Width < 640, 124, 58)
                  LayoutDirection: =If(conAbsRoot.Width < 640, LayoutDirection.Vertical, LayoutDirection.Horizontal)
                  - conAbsMeAbsField   vertical, gap 4, Height 58, LayoutMinWidth 140, FillPortions =If(conAbsRoot.Width < 640, 0, 1)
                      - lblAbsMeAbsDate   (label style) Text ="Absence Date * (M/D/YYYY)"
                      - txtAbsMeAbsDate   ModernTextInput (input style); AccessibleLabel ="Absence Date"; Type =TextInputType.SingleLine; MaxLength 10;
                                          Placeholder ="9/14/2026"; Default =LookUp(colAbsMe, ItemId = varAbsMeSelId).AbsText;
                                          DisplayMode =If(varAbsMeSaving, DisplayMode.Disabled, DisplayMode.Edit)
                  - conAbsMeRetField   same as conAbsMeAbsField
                      - lblAbsMeRetDate   (label style) Text ="Return Date (M/D/YYYY, blank = one day)"
                      - txtAbsMeRetDate   same as txtAbsMeAbsDate but AccessibleLabel ="Return Date"; Placeholder ="9/16/2026";
                                          Default =LookUp(colAbsMe, ItemId = varAbsMeSelId).RetText
              - lblAbsMeDatesCheck   Size 13; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 72, 54)
                  Color: =If(StartsWith(Self.Text, "Ready"), ColorExcused, ColorUnexcused)
                  Text (|-): see Formula M8
              - btnAbsMeDatesSave   teal; Width 130; AlignInContainer Start; Text ="Save dates"; AccessibleLabel ="Save dates to SharePoint"
                  DisplayMode: =If(CanClassify && !varAbsMeSaving && StartsWith(lblAbsMeDatesCheck.Text, "Ready"), DisplayMode.Edit, DisplayMode.Disabled)
                  OnSelect: Formula M9
          - conAbsMeDismissPanel   vertical, gap 8, FillPortions 0, Height 146, LayoutAlignItems Stretch
              Visible: =!IsBlank(varAbsMeSelId) && varAbsMeMode = "dismiss"
              - conAbsMeDismissField   vertical, gap 4, Height 94, FillPortions 0
                  - lblAbsMeDismissNote   (label style) Text ="Why dismiss? *"; AccessibleLabel ="Why dismiss, required"
                  - txtAbsMeDismissNote   ModernTextInput; Appearance Outline; Color ColorInk; Height 72; AccessibleLabel ="Dismiss reason";
                                          Type =TextInputType.Multiline; MaxLength 1000; Default =""; Placeholder ="e.g. duplicate of report 699, or not an AACA student";
                                          DisplayMode =If(varAbsMeSaving, DisplayMode.Disabled, DisplayMode.Edit)
              - btnAbsMeDismissSave   red; Width 160; AlignInContainer Start; Text ="Confirm dismiss"; AccessibleLabel ="Confirm dismiss"
                  DisplayMode: =If(CanClassify && !varAbsMeSaving && !IsBlank(LookUp(colAbsMe, ItemId = varAbsMeSelId)) && Trim(txtAbsMeDismissNote.Text) <> "", DisplayMode.Edit, DisplayMode.Disabled)
                  OnSelect: Formula M10
```

### F. Engine - append as the LAST child of `conAbsRoot`

```
btnAbsMeEngine   Classic/Button; AlignInContainer =AlignInContainer.Stretch; AutoDisableOnSelect =false;
                 LayoutMinHeight 0; LayoutMinWidth 0; Text ="me load"; Visible =false; OnSelect: Formula M1
```

## Formulas (write each as a `|-` block)

**R1 - `btnAbsRmRemove.OnSelect`** (direct action; soft delete like the grid's undo)
```
=With(
    {
        why: Left(Trim(txtAbsRmReason.Text), 500),
        pick: Filter(colAbsList, AttId in colAbsTicked.AttId && !Locked && (varAbsTeacherId = ZeroGuid || TeacherId = varAbsTeacherId) && (varAbsStatus = "All" || ClassText = varAbsStatus))
    },
    If(
        !CanClassify || varAbsSaving || varAbsLoading,
        Set(varAbsReceipt, {Kind: "Blocked", Title: "Not removed. Only the Attendance Office and System Admin can remove absences, and not while saving or loading."}); Clear(colAbsReceiptLines),
        CountRows(pick) = 0,
        Set(varAbsReceipt, {Kind: "Blocked", Title: "Not removed. No absences ticked. Tick rows or use Select all shown."}); Clear(colAbsReceiptLines),
        why = "",
        Set(varAbsReceipt, {Kind: "Blocked", Title: "Not removed. Type why these absences are being removed."}); Clear(colAbsReceiptLines),
        Set(varAbsSaving, true);
        ClearCollect(colAbsWork, ForAll(pick As r, {AttId: r.AttId}));
        Clear(colAbsLog);
        ClearCollect(colAbsLocks, ForAll(Filter('Month Locks', 'Status (aaca_status)' = 'Status (Month Locks)'.Locked) As m, {CampusId: m.Campus.Campus, MonthStart: m.Month}));
        ForAll(
            colAbsWork As w,
            With(
                {c: LookUp(colAbsList, AttId = w.AttId), live: With({qid: w.AttId}, LookUp(Attendance, ThisRecord.Attendance = qid))},
                With(
                    {
                        outcome: If(
                            IsBlank(live), "failed",
                            live.Present = true || live.'Is Deleted' = true, "not an absence",
                            !IsBlank(LookUp(colAbsLocks, CampusId = live.Campus.Campus && MonthStart = Date(Year(live.Date), Month(live.Date), 1))), "locked",
                            !IsBlank(c) && live.'Modified On' <> c.ModifiedOn, "changed",
                            "ok"
                        )
                    },
                    With(
                        {wr: If(outcome = "ok", IfError(Patch(Attendance, live, {'Is Deleted': true}), Blank()))},
                        With(
                            {au: If(!IsBlank(wr), IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Soft delete " & wr.'Record Key' & " (absence removed in Absences)", 100), Action: 'Action (Audit Events)'.'Soft Delete', Entity: "aaca_attendance", 'Entity ID': Text(wr.Attendance), Before: JSON({Present: false, IsDeleted: false, Classification: Coalesce(c.ClassText, ""), Source: Coalesce(c.SrcText, "")}), After: JSON({IsDeleted: wr.'Is Deleted'}), Reason: why}), Blank()))},
                            Collect(colAbsLog, {AttId: w.AttId, StudentName: Coalesce(c.StudentName, live.Student.'Display Name', "Unknown student"), AbsDate: Coalesce(c.AbsDate, live.Date), TeacherName: Coalesce(c.TeacherName, ""), CampusName: Coalesce(c.CampusName, ""), OldClass: Coalesce(c.ClassText, ""), NewClass: If(IsBlank(wr), "", If(wr.'Is Deleted' = true, "Is Deleted = Yes", "Is Deleted = No")), ReasonName: "", ByName: "", OnText: "", Outcome: If(!IsBlank(wr) && wr.'Is Deleted' = true, "removed", outcome = "ok", "failed", outcome), AuditOk: !IsBlank(au)})
                        )
                    )
                )
            )
        );
        With(
            {
                rm: CountRows(Filter(colAbsLog, Outcome = "removed")),
                fl: CountRows(Filter(colAbsLog, Outcome = "failed")),
                sk: CountRows(Filter(colAbsLog, Outcome in ["locked", "changed", "not an absence"]))
            },
            Set(varAbsReceipt, {Kind: If(rm = 0, "Failed", "Removed"), Title: rm & " absence(s) removed (Is Deleted = Yes), " & fl & " failed" & If(sk > 0, ", " & sk & " skipped", "") & " · reason: " & why});
            ClearCollect(
                colAbsReceiptLines,
                {Label: "Operation", Value: "Remove absence (soft delete, like the grid's undo)"},
                {Label: "Reason", Value: why},
                {Label: "Ticked", Value: Text(CountRows(colAbsWork))},
                {Label: "Removed", Value: Text(rm)},
                {Label: "Failed", Value: Text(fl)},
                {Label: "Skipped", Value: Text(sk) & " (locked month, changed by someone else, or no longer an absence)"},
                ForAll(colAbsLog As g2, {Label: g2.StudentName & " · " & Text(g2.AbsDate, "mmm d"), Value: If(g2.Outcome = "removed", g2.NewClass & " · was " & g2.OldClass & If(g2.AuditOk, " · audit Soft Delete written", " · audit NOT written"), g2.Outcome = "failed", "FAILED · not changed", "Skipped · " & g2.Outcome)})
            );
            If(varAbsSelId in Filter(colAbsLog, Outcome = "removed").AttId, Set(varAbsSelId, Blank()); Set(varAbsReasonId, Blank()); Reset(rdoAbsReasonV));
            RemoveIf(colAbsList, AttId in Filter(colAbsLog, Outcome = "removed").AttId);
            RemoveIf(colAbsTicked, AttId in Filter(colAbsLog, Outcome = "removed").AttId);
            If(rm > 0, Reset(txtAbsRmReason))
        );
        Clear(colAbsWork);
        Set(varAbsSaving, false)
    )
)
```

**C1 - `lblAbsCfRowMeta.Text`**
```
=Text(ThisItem.AbsDate, "ddd mmm d, yyyy") & " · Teacher " & ThisItem.TeacherName & " · " & If(ThisItem.ReportId > 0, "Parent report #" & ThisItem.ReportId, "Parent report") & If(IsBlank(ThisItem.NoticeOn), "", " · Reported " & Text(ThisItem.NoticeOn, "mmm d, yyyy h:mm AM/PM") & " (Pacific)") & With({rs: Coalesce(LookUp(colAbsCfRpt, ReportId = ThisItem.ReportId).Reason, "")}, If(rs = "", "", " · Reason: " & If(Len(rs) > 100, Left(rs, 100) & "…", rs))) & If(ThisItem.Locked, " · Month locked", "")
```

**C2 - `btnAbsCfKeep.OnSelect`** (direct action; clear the flag only)
```
=With(
    {qid: ThisItem.AttId, c: ThisItem},
    If(
        !CanClassify || varAbsSaving || varAbsLoading,
        Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved. Only the Attendance Office and System Admin can decide these, and not while saving or loading."}); Clear(colAbsReceiptLines),
        Set(varAbsSaving, true);
        With(
            {live: With({q: qid}, LookUp(Attendance, ThisRecord.Attendance = q))},
            If(
                IsBlank(live) || live.'Is Deleted' = true || live.Present <> true || live.'Parent Reported Absent' <> true,
                Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved · " & c.StudentName & " · " & Text(c.AbsDate, "ddd mmm d, yyyy") & " · this day changed since the list loaded, so it was removed from Needs a decision"}); Clear(colAbsReceiptLines); RemoveIf(colAbsCf, AttId = qid),
                With(
                    {w: IfError(Patch(Attendance, live, {'Parent Reported Absent': false}), Blank())},
                    If(
                        IsBlank(w),
                        Set(varAbsReceipt, {Kind: "Failed", Title: "Not saved · " & c.StudentName & " · " & Text(c.AbsDate, "ddd mmm d, yyyy") & " · the save failed; try again"}); Clear(colAbsReceiptLines),
                        With(
                            {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Keep present " & w.'Record Key' & " (parent report #" & c.ReportId & ")", 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_attendance", 'Entity ID': Text(w.Attendance), Before: JSON({Present: true, ParentReportedAbsent: true, SourceReportId: c.ReportId}), After: JSON({Present: w.Present, ParentReportedAbsent: w.'Parent Reported Absent'}), Reason: "Teacher marked present"}), Blank())},
                            Set(varAbsReceipt, {Kind: "Kept present", Title: "Kept present · " & c.StudentName & " · " & Text(w.Date, "ddd mmm d, yyyy") & " · flag cleared"});
                            ClearCollect(
                                colAbsReceiptLines,
                                {Label: "Student", Value: c.StudentName & " · " & c.StudentNumber},
                                {Label: "Date", Value: Text(w.Date, "ddd mmm d, yyyy")},
                                {Label: "Teacher", Value: c.TeacherName},
                                {Label: "Parent report", Value: If(c.ReportId > 0, "#" & c.ReportId, "—")},
                                {Label: "Present", Value: If(w.Present = true, "Yes (1, unchanged)", "No")},
                                {Label: "Parent Reported Absent", Value: If(w.'Parent Reported Absent' = true, "Yes", "No (cleared)")},
                                {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Update written · Teacher marked present")}
                            );
                            RemoveIf(colAbsCf, AttId = qid)
                        )
                    )
                )
            )
        );
        Set(varAbsSaving, false)
    )
)
```

**C3 - `btnAbsCfAbsent.OnSelect`** (direct action; Present false, flag cleared, Source Office; then reload)
```
=With(
    {qid: ThisItem.AttId, c: ThisItem},
    If(
        !CanClassify || varAbsSaving || varAbsLoading,
        Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved. Only the Attendance Office and System Admin can decide these, and not while saving or loading."}); Clear(colAbsReceiptLines),
        Set(varAbsSaving, true);
        With(
            {live: With({q: qid}, LookUp(Attendance, ThisRecord.Attendance = q))},
            If(
                IsBlank(live) || live.'Is Deleted' = true || live.Present <> true || live.'Parent Reported Absent' <> true,
                Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved · " & c.StudentName & " · " & Text(c.AbsDate, "ddd mmm d, yyyy") & " · this day changed since the list loaded, so it was removed from Needs a decision"}); Clear(colAbsReceiptLines); RemoveIf(colAbsCf, AttId = qid),
                With(
                    {lk: With({cid: live.Campus.Campus, ms: Date(Year(live.Date), Month(live.Date), 1)}, LookUp('Month Locks', Campus.Campus = cid && Month = ms && 'Status (aaca_status)' = 'Status (Month Locks)'.Locked))},
                    If(
                        !IsBlank(lk),
                        Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved · " & c.StudentName & " · " & Text(c.AbsDate, "ddd mmm d, yyyy") & " · the month is locked for this campus"}); Clear(colAbsReceiptLines),
                        With(
                            {w: IfError(Patch(Attendance, live, {Present: false, 'Parent Reported Absent': false, Source: 'Source (Attendance)'.Office}), Blank())},
                            If(
                                IsBlank(w),
                                Set(varAbsReceipt, {Kind: "Failed", Title: "Not saved · " & c.StudentName & " · " & Text(c.AbsDate, "ddd mmm d, yyyy") & " · the save failed; try again"}); Clear(colAbsReceiptLines),
                                With(
                                    {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Mark absent " & w.'Record Key' & " (parent report #" & c.ReportId & ")", 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_attendance", 'Entity ID': Text(w.Attendance), Before: JSON({Present: true, ParentReportedAbsent: true, Source: Text(live.Source)}), After: JSON({Present: w.Present, ParentReportedAbsent: w.'Parent Reported Absent', Source: Text(w.Source)}), Reason: "Parent reported absent; office marked absent"}), Blank())},
                                    Set(varAbsReceipt, {Kind: "Marked absent", Title: "Marked absent · " & c.StudentName & " · " & Text(w.Date, "ddd mmm d, yyyy") & " · now a 0 to classify"});
                                    ClearCollect(
                                        colAbsReceiptLines,
                                        {Label: "Student", Value: c.StudentName & " · " & c.StudentNumber},
                                        {Label: "Date", Value: Text(w.Date, "ddd mmm d, yyyy")},
                                        {Label: "Teacher", Value: c.TeacherName},
                                        {Label: "Parent report", Value: If(c.ReportId > 0, "#" & c.ReportId, "—")},
                                        {Label: "Present", Value: If(w.Present = true, "Yes", "No (0)")},
                                        {Label: "Parent Reported Absent", Value: If(w.'Parent Reported Absent' = true, "Yes", "No (cleared)")},
                                        {Label: "Source", Value: Text(w.Source)},
                                        {Label: "Classification", Value: "Not classified (classify it in the list below)"},
                                        {Label: "Audit event", Value: If(IsBlank(au), "NOT written", "Update written")}
                                    );
                                    RemoveIf(colAbsCf, AttId = qid);
                                    Select(btnAbsLoadEngine)
                                )
                            )
                        )
                    )
                )
            )
        );
        Set(varAbsSaving, false)
    )
)
```

**M1 - `btnAbsMeEngine.OnSelect`** (load both lists, campus-scoped)
```
=Set(varAbsMeLoading, true);
Set(varAbsMeLoadError, "");
Set(varAbsMeSelId, Blank());
Set(varAbsMeMode, "");
Reset(cboAbsMeStudent);
Reset(txtAbsMeAbsDate);
Reset(txtAbsMeRetDate);
Reset(txtAbsMeDismissNote);
If(
    !CanClassify,
    Clear(colAbsMe),
    IfError(
        With(
            {cut: ParentReportCutover},
            Concurrent(
                ClearCollect(colAbsMeSrc, ForAll(Filter('Student Absence Log', Created >= cut) As r, {ItemId: r.ID, Created: r.Created, StudentKey: Trim(Coalesce(r.Student_ID, "")), FirstName: Coalesce(r.'Student First Name', ""), LastName: Coalesce(r.'Student Last Name', ""), SchoolSite: Trim(Coalesce(r.'School Site', "")), AbsText: Coalesce(r.'Absence Date', ""), RetText: Coalesce(r.'Return Date', ""), Reason: Coalesce(r.Reason, ""), SubmittedBy: Coalesce(r.'Submitted By', ""), Notified: Coalesce(r.'Date Notified', "")})),
                ClearCollect(colAbsMeErrDec, ForAll(Filter('Report Decisions', 'Processing Status' = 'Processing Status (Report Decisions)'.Error) As d, {ItemId: d.'Report Item ID', DecId: d.'Report Decision', ErrorDetail: Coalesce(d.'Error Detail', ""), StudentKey: Trim(Coalesce(d.'Student Key', "")), CampusId: Coalesce(d.Campus.Campus, ZeroGuid), DecCreated: d.'Created On'})),
                ClearCollect(colAbsMeStuRaw, ForAll(Students As s, {StudentId: s.Student, DisplayName: Coalesce(s.'Display Name', "Unnamed student"), StudentKey: Trim(Coalesce(s.'External Client ID', "")), StatusText: Text(s.'Status (aaca_status)')})),
                ClearCollect(colAbsMeEnr, ForAll(Enrollments As e, {StudentId: e.Student.Student, CampusId: e.Campus.Campus, CampusName: Coalesce(e.Campus.Name, ""), StartDate: e.'Start Date', EndDate: e.'End Date'}))
            )
        ); true,
        Set(varAbsMeLoadError, FirstError.Message)
    );
    IfError(
        With({minId: Coalesce(Min(colAbsMeSrc, ItemId), 0)}, ClearCollect(colAbsMeDecIds, ForAll(Filter('Report Decisions', 'Report Item ID' >= minId) As d, {ItemId: d.'Report Item ID'}))); true,
        Set(varAbsMeLoadError, "Report Decisions could not be read (" & FirstError.Message & ")")
    );
    ClearCollect(
        colAbsMeStudents,
        ForAll(
            colAbsMeStuRaw As s,
            With(
                {
                    cur: First(Sort(Filter(colAbsMeEnr, StudentId = s.StudentId && StartDate <= Today() && (IsBlank(EndDate) || EndDate >= Today())), StartDate, SortOrder.Descending)),
                    lst: First(Sort(Filter(colAbsMeEnr, StudentId = s.StudentId), StartDate, SortOrder.Descending))
                },
                With(
                    {cid: If(IsBlank(cur), lst.CampusId, cur.CampusId), cn: If(IsBlank(cur), lst.CampusName, cur.CampusName)},
                    {StudentId: s.StudentId, DisplayName: s.DisplayName, StudentKey: s.StudentKey, StatusText: s.StatusText, CampusId: Coalesce(cid, ZeroGuid), Label: s.DisplayName & " · " & Coalesce(cn, "no campus") & " · " & If(s.StudentKey = "", "no Student Key", s.StudentKey) & " · " & s.StatusText}
                )
            )
        )
    );
    If(
        varAbsMeLoadError <> "",
        Clear(colAbsMe),
        With(
            {sc: If(StudentCampusLock <> ZeroGuid, StudentCampusLock, varAbsMeCampusId)},
            ClearCollect(
                colAbsMe,
                Filter(
                    ForAll(
                        Filter(colAbsMeSrc, StudentKey = "" && !(ItemId in colAbsMeDecIds.ItemId)) As s,
                        With(
                            {site: LookUp(colAbsCampusOpts, CampusName = s.SchoolSite)},
                            {Kind: "A", ItemId: s.ItemId, DecId: ZeroGuid, Created: s.Created, StudentKey: "", FirstName: s.FirstName, LastName: s.LastName, SchoolSite: s.SchoolSite, CampusId: Coalesce(site.CampusId, ZeroGuid), AbsText: s.AbsText, RetText: s.RetText, Reason: s.Reason, SubmittedBy: s.SubmittedBy, Notified: s.Notified, ErrorDetail: "", DecCreated: s.Created, Status: "", SpFound: true}
                        )
                    ),
                    sc = ZeroGuid || CampusId = sc
                ),
                Filter(
                    ForAll(
                        colAbsMeErrDec As d,
                        With(
                            {sp: With({q: d.ItemId}, LookUp('Student Absence Log', ID = q))},
                            With(
                                {site: LookUp(colAbsCampusOpts, CampusName = Trim(Coalesce(sp.'School Site', "")))},
                                {Kind: "B", ItemId: d.ItemId, DecId: d.DecId, Created: Coalesce(sp.Created, d.DecCreated), StudentKey: Coalesce(Trim(sp.Student_ID), d.StudentKey, ""), FirstName: Coalesce(sp.'Student First Name', ""), LastName: Coalesce(sp.'Student Last Name', ""), SchoolSite: Trim(Coalesce(sp.'School Site', "")), CampusId: If(d.CampusId <> ZeroGuid, d.CampusId, Coalesce(site.CampusId, ZeroGuid)), AbsText: Coalesce(sp.'Absence Date', ""), RetText: Coalesce(sp.'Return Date', ""), Reason: Coalesce(sp.Reason, ""), SubmittedBy: Coalesce(sp.'Submitted By', ""), Notified: Coalesce(sp.'Date Notified', ""), ErrorDetail: d.ErrorDetail, DecCreated: d.DecCreated, Status: "", SpFound: !IsBlank(sp)}
                            )
                        )
                    ),
                    StudentCampusLock <> ZeroGuid || sc = ZeroGuid || CampusId = sc
                )
            )
        )
    )
);
Set(varAbsMeLoaded, true);
Set(varAbsMeLoading, false)
```

**M2 - `lblAbsMeCount.Text`**
```
=If(
    varAbsMeLoadError <> "", "Could not load mapping errors: " & varAbsMeLoadError & ". Use Reload to try again.",
    varAbsMeLoading, "Loading mapping errors…",
    CountRows(colAbsMe) = 0, "No mapping errors. Website reports since " & Text(ParentReportCutover, "m/d/yyyy") & " all have a Student ID or a decision.",
    CountRows(Filter(colAbsMe, Kind = "A")) & " with no Student ID · " & CountRows(Filter(colAbsMe, Kind = "B")) & " could not be processed · " & If(StudentCampusLock <> ZeroGuid, "your campus", varAbsMeCampusId = ZeroGuid, "all campuses", LookUp(colAbsCampusOpts, CampusId = varAbsMeCampusId).CampusName) & If(CountRows(colAbsMeSrc) >= 2000, " · list may be incomplete (2,000-item limit)", "")
)
```

**M3 - `btnAbsMeAOpen.OnSelect` and `btnAbsMeBOpen.OnSelect`**
```
=Set(varAbsMeSelId, ThisItem.ItemId);
Set(varAbsMeMode, If(ThisItem.Kind = "A", "map", ""));
Reset(cboAbsMeStudent);
Reset(txtAbsMeAbsDate);
Reset(txtAbsMeRetDate);
Reset(txtAbsMeDismissNote)
```

**M4 - `lblAbsMeFacts.Text`**
```
=With(
    {it: LookUp(colAbsMe, ItemId = varAbsMeSelId)},
    If(
        IsBlank(it),
        "Choose Open on a report to map it to a student, fix its dates, or dismiss it.",
        "Report #" & it.ItemId & " · " & If(it.Kind = "A", "No Student ID", "Could not process") & If(it.Status = "", "", " · " & it.Status) & Char(10) &
        "Student as typed: " & it.FirstName & " " & it.LastName & Char(10) &
        "School site: " & If(it.SchoolSite = "", "—", it.SchoolSite) & Char(10) &
        "Absence date: " & If(it.AbsText = "", "—", it.AbsText) & " · Return date: " & If(it.RetText = "", "—", it.RetText) & Char(10) &
        "Reason: " & If(it.Reason = "", "—", If(Len(it.Reason) > 160, Left(it.Reason, 160) & "…", it.Reason)) & Char(10) &
        "Submitted by " & If(it.SubmittedBy = "", "—", it.SubmittedBy) & " · notified " & If(it.Notified = "", "—", it.Notified) & Char(10) &
        "Student_ID: " & If(it.StudentKey = "", "blank", it.StudentKey) &
        If(it.Kind = "B", Char(10) & "Error: " & If(it.ErrorDetail = "", "—", If(Len(it.ErrorDetail) > 200, Left(it.ErrorDetail, 200) & "…", it.ErrorDetail)) & If(it.SpFound, "", " · SharePoint item not found"), "")
    )
)
```

**M5 - `btnAbsMeClose.OnSelect`**
```
=Set(varAbsMeSelId, Blank());
Set(varAbsMeMode, "");
Reset(cboAbsMeStudent);
Reset(txtAbsMeAbsDate);
Reset(txtAbsMeRetDate);
Reset(txtAbsMeDismissNote)
```

**M6 - `lblAbsMeMapCheck.Text`**
```
=With(
    {it: LookUp(colAbsMe, ItemId = varAbsMeSelId), stu: First(cboAbsMeStudent.SelectedItems)},
    If(
        CountRows(cboAbsMeStudent.SelectedItems) <> 1, "Pick the student this report is about. Save mapping stays off until you do.",
        Trim(Coalesce(stu.StudentKey, "")) = "", stu.DisplayName & " has no Student Key (External Client ID). Add it on the Students screen first.",
        "Ready: Save mapping writes Student_ID " & stu.StudentKey & " and Match_Status Manually Resolved on report #" & it.ItemId & ". Nothing else in SharePoint changes."
    )
)
```

**M7 - `btnAbsMeMapSave.OnSelect`** (writes ONLY Student_ID and Match_Status)
```
=With(
    {it: LookUp(colAbsMe, ItemId = varAbsMeSelId), stu: First(cboAbsMeStudent.SelectedItems), n: CountRows(cboAbsMeStudent.SelectedItems)},
    With(
        {qid: it.ItemId, key: Trim(Coalesce(stu.StudentKey, ""))},
        If(
            !CanClassify || varAbsMeSaving || IsBlank(it),
            Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not saved · choose a report with Open first", Body: ""}),
            n <> 1 || key = "",
            Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not saved · pick one student who has a Student Key", Body: "Report #" & qid & " was not changed."}),
            Set(varAbsMeSaving, true);
            Set(varAbsMeErr, "");
            With(
                {live: With({q: qid}, LookUp('Student Absence Log', ID = q)), prior: With({q: qid}, LookUp('Report Decisions', 'Report Item ID' = q))},
                If(
                    IsBlank(live),
                    Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not saved · report #" & qid & " could not be read from SharePoint", Body: "Nothing was changed. The item may have been deleted. Use Reload."}),
                    it.Kind = "A" && (Trim(Coalesce(live.Student_ID, "")) <> "" || !IsBlank(prior)),
                    Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not saved · report #" & qid & " was already handled", Body: "It now has Student_ID " & Coalesce(live.Student_ID, "(blank)") & If(IsBlank(prior), "", " and a Report Decisions row") & ". Nothing was written. Use Reload."}),
                    it.Kind = "B" && (IsBlank(prior) || prior.'Processing Status' <> 'Processing Status (Report Decisions)'.Error),
                    Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not saved · report #" & qid & " is no longer in Could not process", Body: "The intake flow or another user already handled it. Nothing was written. Use Reload."}),
                    With(
                        {w: IfError(Patch('Student Absence Log', live, {Student_ID: key, Match_Status: {Value: "Manually Resolved"}}), Set(varAbsMeErr, FirstError.Message); Blank())},
                        If(
                            IsBlank(w),
                            Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not saved · report #" & qid & " could not be updated", Body: "Error: " & Coalesce(varAbsMeErr, "unknown error") & Char(10) & "Nothing was changed. The report and student are still selected; press Save mapping to retry."}),
                            With(
                                {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Parent report #" & w.ID & " mapped to " & w.Student_ID, 100), Action: 'Action (Audit Events)'.Update, Entity: "sharepoint:Student Absence Log", 'Entity ID': Text(w.ID), Before: JSON({Student_ID: Coalesce(live.Student_ID, ""), Match_Status: Coalesce(live.Match_Status.Value, "")}), After: JSON({Student_ID: w.Student_ID, Match_Status: w.Match_Status.Value}), Reason: Left("Mapped in Absences, Mapping Errors: " & stu.DisplayName & " (" & key & ")", 500)}), Blank())},
                                Set(
                                    varAbsMeReceipt,
                                    {
                                        Kind: "Mapped",
                                        Title: "Report #" & w.ID & " mapped · Student_ID " & w.Student_ID & " · " & stu.DisplayName,
                                        Body: "Report: #" & w.ID & " · was " & If(it.Kind = "A", "No Student ID", "Could not process") & Char(10) &
                                            "Typed by parent: " & it.FirstName & " " & it.LastName & " · " & it.SchoolSite & Char(10) &
                                            "Student picked: " & stu.DisplayName & " · " & stu.StatusText & Char(10) &
                                            "Student_ID: " & w.Student_ID & Char(10) &
                                            "Match_Status: " & w.Match_Status.Value & Char(10) &
                                            "Other SharePoint columns: not written" & Char(10) &
                                            "Audit event: " & If(IsBlank(au), "NOT written", "Update written") & Char(10) &
                                            "Next: the intake flow picks this up within a few minutes and creates the absences (0s). Reload later to confirm."
                                    }
                                );
                                If(it.Kind = "A", RemoveIf(colAbsMe, ItemId = qid));
                                If(it.Kind = "B", Patch(colAbsMe, it, {StudentKey: w.Student_ID, Status: "Mapped to " & w.Student_ID & ", waiting for the intake flow"}));
                                Set(varAbsMeSelId, Blank());
                                Set(varAbsMeMode, "");
                                Reset(cboAbsMeStudent)
                            )
                        )
                    )
                )
            );
            Set(varAbsMeSaving, false)
        )
    )
)
```

**M8 - `lblAbsMeDatesCheck.Text`**
```
=With(
    {a: IfError(DateValue(Trim(txtAbsMeAbsDate.Text), "en-US"), Blank()), rt: Trim(txtAbsMeRetDate.Text)},
    With(
        {r: If(rt = "", Blank(), IfError(DateValue(rt, "en-US"), Blank()))},
        If(
            IsBlank(a), "Type the Absence Date as M/D/YYYY, for example 9/14/2026.",
            rt <> "" && IsBlank(r), "Type the Return Date as M/D/YYYY, or leave it blank for a one-day absence.",
            !IsBlank(r) && r <= a, "The Return Date must be after the Absence Date (it is the day the child is back).",
            !IsBlank(r) && DateDiff(a, r, TimeUnit.Days) > 180, "Those dates cover more than 180 days. Check them.",
            "Ready: Save dates writes Absence Date " & Text(a, "m/d/yyyy") & If(IsBlank(r), " and a blank Return Date", " and Return Date " & Text(r, "m/d/yyyy")) & ". Nothing else in SharePoint changes."
        )
    )
)
```

**M9 - `btnAbsMeDatesSave.OnSelect`** (writes ONLY 'Absence Date' and 'Return Date')
```
=With(
    {it: LookUp(colAbsMe, ItemId = varAbsMeSelId), a: IfError(DateValue(Trim(txtAbsMeAbsDate.Text), "en-US"), Blank()), rt: Trim(txtAbsMeRetDate.Text)},
    With(
        {qid: it.ItemId, r: If(rt = "", Blank(), IfError(DateValue(rt, "en-US"), Blank()))},
        If(
            !CanClassify || varAbsMeSaving || IsBlank(it) || it.Kind <> "B",
            Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not saved · open a report in Could not process first", Body: ""}),
            IsBlank(a) || (rt <> "" && IsBlank(r)) || (!IsBlank(r) && (r <= a || DateDiff(a, r, TimeUnit.Days) > 180)),
            Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not saved · check the dates", Body: "Type dates as M/D/YYYY. The Return Date is the day the child is back: after the Absence Date and at most 180 days later. Report #" & qid & " was not changed."}),
            Set(varAbsMeSaving, true);
            Set(varAbsMeErr, "");
            With(
                {live: With({q: qid}, LookUp('Student Absence Log', ID = q)), aTxt: Text(a, "m/d/yyyy"), rTxt: If(IsBlank(r), "", Text(r, "m/d/yyyy"))},
                If(
                    IsBlank(live),
                    Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not saved · report #" & qid & " could not be read from SharePoint", Body: "Nothing was changed. The item may have been deleted. Use Reload."}),
                    With(
                        {w: IfError(Patch('Student Absence Log', live, {'Absence Date': aTxt, 'Return Date': rTxt}), Set(varAbsMeErr, FirstError.Message); Blank())},
                        If(
                            IsBlank(w),
                            Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not saved · report #" & qid & " could not be updated", Body: "Error: " & Coalesce(varAbsMeErr, "unknown error") & Char(10) & "Nothing was changed. Press Save dates to retry."}),
                            With(
                                {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Parent report #" & w.ID & " dates fixed", 100), Action: 'Action (Audit Events)'.Update, Entity: "sharepoint:Student Absence Log", 'Entity ID': Text(w.ID), Before: JSON({AbsenceDate: Coalesce(live.'Absence Date', ""), ReturnDate: Coalesce(live.'Return Date', "")}), After: JSON({AbsenceDate: Coalesce(w.'Absence Date', ""), ReturnDate: Coalesce(w.'Return Date', "")}), Reason: "Dates fixed in Absences, Mapping Errors"}), Blank())},
                                Set(
                                    varAbsMeReceipt,
                                    {
                                        Kind: "Dates fixed",
                                        Title: "Report #" & w.ID & " dates saved · " & w.'Absence Date' & If(Coalesce(w.'Return Date', "") = "", " (one day)", " to " & w.'Return Date'),
                                        Body: "Report: #" & w.ID & " · Could not process" & Char(10) &
                                            "Absence Date: " & Coalesce(live.'Absence Date', "(blank)") & " -> " & Coalesce(w.'Absence Date', "(blank)") & Char(10) &
                                            "Return Date: " & Coalesce(live.'Return Date', "(blank)") & " -> " & Coalesce(w.'Return Date', "(blank)") & Char(10) &
                                            "Other SharePoint columns: not written" & Char(10) &
                                            "Audit event: " & If(IsBlank(au), "NOT written", "Update written") & Char(10) &
                                            "Next: the intake flow picks this up within a few minutes and creates the absences (0s). Reload later to confirm."
                                    }
                                );
                                Patch(colAbsMe, it, {AbsText: Coalesce(w.'Absence Date', ""), RetText: Coalesce(w.'Return Date', ""), Status: "Dates fixed, waiting for the intake flow"});
                                Set(varAbsMeSelId, Blank());
                                Set(varAbsMeMode, "");
                                Reset(txtAbsMeAbsDate);
                                Reset(txtAbsMeRetDate)
                            )
                        )
                    )
                )
            );
            Set(varAbsMeSaving, false)
        )
    )
)
```

**M10 - `btnAbsMeDismissSave.OnSelect`** (A creates, B updates the Report Decisions row)
```
=With(
    {it: LookUp(colAbsMe, ItemId = varAbsMeSelId), why: Left(Trim(txtAbsMeDismissNote.Text), 1000)},
    With(
        {qid: it.ItemId},
        If(
            !CanClassify || varAbsMeSaving || IsBlank(it),
            Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not dismissed · choose a report with Open first", Body: ""}),
            why = "",
            Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not dismissed · type why the report is dismissed", Body: "Report #" & qid & " was not changed."}),
            Set(varAbsMeSaving, true);
            Set(varAbsMeErr, "");
            With(
                {prior: With({q: qid}, LookUp('Report Decisions', 'Report Item ID' = q))},
                If(
                    it.Kind = "A" && !IsBlank(prior),
                    Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not dismissed · report #" & qid & " already has a decision", Body: "Nothing was written, and the report has been removed from this list."}); RemoveIf(colAbsMe, ItemId = qid); Set(varAbsMeSelId, Blank()); Set(varAbsMeMode, ""),
                    it.Kind = "B" && IsBlank(prior),
                    Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not dismissed · the Report Decisions row for report #" & qid & " was not found", Body: "Nothing was written. Use Reload."}),
                    With(
                        {
                            dec: IfError(
                                If(
                                    it.Kind = "A",
                                    Patch('Report Decisions', Defaults('Report Decisions'), {Summary: Left("Dismissed parent report #" & qid & " (no Student ID) · " & it.FirstName & " " & it.LastName, 100), 'Report Item ID': qid, Decision: 'Decision (Report Decisions)'.Dismissed, 'Processing Status': 'Processing Status (Report Decisions)'.Processed, Note: why, Campus: With({qc: it.CampusId}, LookUp(Campuses, ThisRecord.Campus = qc))}),
                                    it.Kind = "B",
                                    Patch('Report Decisions', prior, {Decision: 'Decision (Report Decisions)'.Dismissed, 'Processing Status': 'Processing Status (Report Decisions)'.Processed, Note: why})
                                ),
                                Set(varAbsMeErr, FirstError.Message); Blank()
                            )
                        },
                        If(
                            IsBlank(dec),
                            Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not dismissed · the decision could not be saved for report #" & qid, Body: "Error: " & Coalesce(varAbsMeErr, "unknown error") & Char(10) & "Nothing was written. Press Confirm dismiss to retry."}),
                            With(
                                {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Parent report #" & qid & " dismissed in Mapping Errors", 100), Action: If(it.Kind = "A", 'Action (Audit Events)'.Create, 'Action (Audit Events)'.Update), Entity: "aaca_reportdecision", 'Entity ID': Text(dec.'Report Decision'), Before: JSON({ReportItemId: qid, List: If(it.Kind = "A", "No Student ID", "Could not process"), ErrorDetail: it.ErrorDetail}), After: JSON({Decision: Text(dec.Decision), ProcessingStatus: Text(dec.'Processing Status'), Note: dec.Note}), Reason: Left(why, 500)}), Blank())},
                                Set(
                                    varAbsMeReceipt,
                                    {
                                        Kind: "Dismissed",
                                        Title: "Dismissed · report #" & dec.'Report Item ID',
                                        Body: "Report: #" & dec.'Report Item ID' & " · was " & If(it.Kind = "A", "No Student ID", "Could not process") & Char(10) &
                                            "Typed by parent: " & it.FirstName & " " & it.LastName & " · " & it.SchoolSite & Char(10) &
                                            "Decision: " & Text(dec.Decision) & Char(10) &
                                            "Processing Status: " & Text(dec.'Processing Status') & Char(10) &
                                            "Note: " & dec.Note & Char(10) &
                                            "Report Decisions row: " & If(it.Kind = "A", "created", "updated") & Char(10) &
                                            "Attendance and SharePoint: not changed" & Char(10) &
                                            "Audit event: " & If(IsBlank(au), "NOT written", "written") & Char(10) &
                                            "The intake flow will not process this report."
                                    }
                                );
                                RemoveIf(colAbsMe, ItemId = qid);
                                Set(varAbsMeSelId, Blank());
                                Set(varAbsMeMode, "");
                                Reset(txtAbsMeDismissNote)
                            )
                        )
                    )
                )
            );
            Set(varAbsMeSaving, false)
        )
    )
)
```

## Layout and Visual Impact

- Breakpoint source: `conAbsRoot.Width` everywhere (phone < 640, tablet < 1024, two-panel >= 1024).
- View bar: desktop 16 + 170 + 8 + 220 + 16 = 430; phone stacked 44 + 8 + 44 = 96.
- Classify row: desktop 8+44+4+18+4+36+4+44+8 = 170 = TemplateSize; phone 8+44+4+36+4+72+4+88+8 = 268. `lblAbsRowSrcV`
  longest value ~175 chars (100-char reason cap): >= 576 px wide at size 12 is <= 2 lines (36); 326 px phone <= 4 lines (72).
- Remove row: horizontal field (min 140) + 8 + 200 <= 576 (narrowest horizontal list width); phone 58 + 8 + 44 = 110.
- Needs a decision: row desktop 8+22+4+36+4+44+8 = 126 <= 130; phone 8+40+4+72+4+44+8 = 180 <= 184; actions
  130 + 8 + 130 = 268 <= 334. Panel = 12 + title + 8 + hint + 8 + gallery + 12 (formula above).
- Mapping list rows: desktop 8+44+4+72+8 = 136 <= 140; phone 8+44+4+90+8 = 154 <= 158. Name row: name FillPortions 1 +
  8 + Open 90 (phone name width 326 - 98 = 228, wraps to 2 lines in 42).
- Mode bar: 130+8+110+8+100+8+90 = 454 <= 472 (1024 two-panel detail inner width); < 640 wraps to two rows (96).
- Map panel 58+8+54+8+44 = 172 (phone 58+8+72+8+44 = 190); Dates panel 58+8+54+8+44 = 172 (phone 124+8+72+8+44 = 256);
  Dismiss panel 94+8+44 = 146. Dates row 140+8+140 = 288 <= 358.
- Receipt: 8 + (44|84) + 4 + (190|300) + 8 holds the 10-line Map/Dismiss body (desktop <= 10 lines x 17; phone <= 17 lines).
- Facts: 210 desktop (<= 12 lines incl. wrapped reason/error), 320 phone.
- Visual: Needs a decision panel `ColorWarnBg` with white row shells; Keep present teal primary, Mark absent Secondary;
  Remove ticked and Confirm dismiss red; Save mapping / Save dates teal; mode buttons toggle style; all text ink.
- Record presentation: classify identity unchanged (`lblAbsRowNameV`); conflict identity `lblAbsCfRowName`; Keep present
  and Mark absent sit together on every conflict row at every width. Mapping identity `lblAbsMeAName` / `lblAbsMeBName`;
  Map, Fix dates (B), Dismiss are together in the same detail surface.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| cls-row-source | galAbsListV row | source, reported time, parent reason | SrcText, NoticeOn, ParentReason | lblAbsRowSrcV | section B | below the date line; hidden only when all three empty |
| cf-row-student | galAbsCfList row | student | StudentName, StudentNumber | lblAbsCfRowName | `=ThisItem.StudentName & " · " & ThisItem.StudentNumber` | row top |
| cf-row-facts | galAbsCfList row | date, teacher, report #, reported, reason | AbsDate, TeacherName, ReportId, NoticeOn, colAbsCfRpt.Reason | lblAbsCfRowMeta | C1 | second line |
| me-a-identity | galAbsMeA row | report #, typed names | ItemId, FirstName, LastName | lblAbsMeAName | section E | row top beside Open |
| me-a-facts | galAbsMeA row | site, dates, reason, submitted by, notified | SchoolSite, AbsText, RetText, Reason, SubmittedBy, Notified | lblAbsMeAMeta | section E | below |
| me-b-identity | galAbsMeB row | report #, student key, status | ItemId, StudentKey, Status | lblAbsMeBName | section E | row top beside Open |
| me-b-facts | galAbsMeB row | error detail, created on | ErrorDetail, DecCreated | lblAbsMeBMeta | section E | below |
| me-detail-facts | conAbsMeDetail | all facts | colAbsMe row | lblAbsMeFacts | M4 | top of detail |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| abs-errors-view | conAbsMeView | `=CanClassify && varAbsView = "errors"` | Mapping Errors toggle / otherwise hidden |
| abs-conflicts | conAbsCfPanel | `=CanClassify && CountRows(colAbsCf) > 0` | conflicts in scope / none |
| abs-me-receipt | conAbsMeReceipt | `=varAbsMeReceipt.Kind <> ""` | after Map / Fix dates / Dismiss attempt / after Close |
| abs-me-map | conAbsMeMapPanel | `=!IsBlank(varAbsMeSelId) && varAbsMeMode = "map"` | Map student pressed / otherwise |
| abs-me-dates | conAbsMeDatesPanel | `=!IsBlank(varAbsMeSelId) && varAbsMeMode = "dates" && LookUp(colAbsMe, ItemId = varAbsMeSelId).Kind = "B"` | Fix dates on a List B report / otherwise |
| abs-me-dismiss | conAbsMeDismissPanel | `=!IsBlank(varAbsMeSelId) && varAbsMeMode = "dismiss"` | Dismiss pressed / otherwise |

## Required Actions

Copied from the plan index (`C:\src\aaca-attendance\docs\app-builds\build-8-absences\canvas-app-plan.md`, Action
Contracts); formulas above implement them.

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-TOGGLE-ERRORS | CanClassify | `btnAbsMeViewErrors.OnSelect` | N/A | varAbsView "errors"; first-time load | N/A | N/A | `conAbsMeView.Visible` |
| A-LOAD-ABSENCES | CanClassify, campus, valid dates | `btnAbsLoadEngine.OnSelect` | Attendance.Attendance | colAbsList (+3 fields), colAbsCf, colAbsCfRpt | N/A | N/A | `galAbsListV`, `lblAbsRowSrcV`, `galAbsCfList` |
| A-REMOVE-ABSENCE | ticked visible unlocked >= 1; reason | `btnAbsRmRemove.OnSelect` (R1) | AttId per ticked row | Is Deleted = true; audit Soft Delete; leaves list | Is Deleted; Audit row | title counts + reason; per-row "Is Deleted = Yes" from wr; audit outcome | `conAbsReceiptV`; `galAbsListV` |
| A-KEEP-PRESENT | conflict row | `btnAbsCfKeep.OnSelect` (C2) | ThisItem.AttId | flag false; audit Update "Teacher marked present" | Parent Reported Absent; Audit row | Student, Date, Teacher, Parent report, Present, Parent Reported Absent, Audit | `conAbsReceiptV`; row gone |
| A-MARK-ABSENT | conflict row, unlocked | `btnAbsCfAbsent.OnSelect` (C3) | ThisItem.AttId | Present false, flag false, Source Office; audit Update; reload | Present, Parent Reported Absent, Source; Audit row | + Source, Classification | `conAbsReceiptV`; `galAbsListV` after reload |
| A-ME-LOAD | CanClassify | `btnAbsMeEngine.OnSelect` (M1) | SP item ID | colAbsMe A + B in scope | N/A | N/A | galleries, `lblAbsMeCount`, toggle |
| A-ME-CAMPUS | admin | `ddAbsMeCampus.OnChange` | Campus GUID | varAbsMeCampusId; reload | N/A | N/A | `lblAbsMeCount` |
| A-ME-OPEN / CLOSE | row | M3 / M5 | ItemId | select / clear | N/A | N/A | `lblAbsMeFacts`, row fill |
| A-ME-MAP | one keyed student | `btnAbsMeMapSave.OnSelect` (M7) | qid | SP Student_ID + Match_Status; audit | Student_ID, Match_Status; Audit row | Report, list, typed, picked, Student_ID (w), Match_Status (w), other columns not written, audit, next | `conAbsMeReceipt`; list row gone / pending |
| A-ME-FIXDATES | valid dates, List B | `btnAbsMeDatesSave.OnSelect` (M9) | qid | SP Absence Date + Return Date; audit | Absence Date, Return Date; Audit row | before -> after for both (live / w), other columns not written, audit, next | `conAbsMeReceipt`; B row pending |
| A-ME-DISMISS | reason | `btnAbsMeDismissSave.OnSelect` (M10) | Report Item ID qid | create (A) / update (B) Report Decisions; audit | Decision, Processing Status, Note (+ Summary, Report Item ID, Campus for A); Audit row | Decision, Processing Status, Note (dec), created/updated, not changed, audit | `conAbsMeReceipt`; row gone |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| txtAbsRmReason | lblAbsRmReason `="Reason to remove ticked absences *"` | conAbsRmField |
| ddAbsMeCampus | lblAbsMeCampus `="Campus"` | conAbsMeCampusField |
| cboAbsMeStudent | lblAbsMeStudent `="Student *"` | conAbsMeMapField |
| txtAbsMeAbsDate | lblAbsMeAbsDate `="Absence Date * (M/D/YYYY)"` | conAbsMeAbsField |
| txtAbsMeRetDate | lblAbsMeRetDate `="Return Date (M/D/YYYY, blank = one day)"` | conAbsMeRetField |
| txtAbsMeDismissNote | lblAbsMeDismissNote `="Why dismiss? *"` | conAbsMeDismissField |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization | Focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-REMOVE-ABSENCE | wr -> colAbsLog -> colAbsReceiptLines -> galAbsReceiptV | Attendance Is Deleted | galAbsListV; Screen1 grid | AttId | RemoveIf colAbsList / colAbsTicked on success | N/A |
| A-KEEP-PRESENT | w -> varAbsReceipt / colAbsReceiptLines | Attendance flag | galAbsCfList | AttId | RemoveIf(colAbsCf) on success | N/A |
| A-MARK-ABSENT | w -> receipt | Attendance Present / flag / Source | galAbsListV | AttId | Select(btnAbsLoadEngine) on success | N/A |
| A-ME-MAP | w -> varAbsMeReceipt | SP Student_ID / Match_Status | galAbsMeA / galAbsMeB | ItemId = w.ID | RemoveIf (A) / Patch Status (B) | N/A |
| A-ME-FIXDATES | w -> varAbsMeReceipt | SP dates | galAbsMeB | ItemId = w.ID | Patch(colAbsMe) | N/A |
| A-ME-DISMISS | dec -> varAbsMeReceipt | Report Decisions | galAbsMeA / galAbsMeB, toggle count | ItemId = dec.'Report Item ID' | RemoveIf(colAbsMe) | N/A |

## Mutation Field Ledger

See the plan index ledger; in short: Remove writes only Is Deleted; Keep present only Parent Reported Absent; Mark
absent only Present, Parent Reported Absent, Source; Map only Student_ID, Match_Status; Fix dates only Absence Date,
Return Date; Dismiss only Decision, Processing Status, Note (+ Summary, Report Item ID, Campus when creating). Every
other column is omitted from the Patch (preserved). Every mutation also writes one Audit Events row.

## Functional Test Scenarios

All rows of the plan index Functional Test Matrix are exercised on this screen: S-VIEWS-GONE, S-TOGGLE, S-ROW-PARENT,
S-ROW-OFFICE, S-ROW-LEGACY, S-REMOVE-OK, S-REMOVE-NO-REASON, S-REMOVE-LOCKED, S-CF-LIST, S-CF-HIDDEN-EMPTY,
S-KEEP-PRESENT, S-MARK-ABSENT, S-MARK-ABSENT-LOCKED, S-CF-STALE, S-ME-A-LIST, S-ME-A-SCOPE, S-ME-B-LIST, S-ME-COUNT,
S-ME-MAP-A, S-ME-MAP-B, S-ME-MAP-NOKEY, S-ME-MAP-RACE, S-ME-DATES-OK, S-ME-DATES-INVALID, S-ME-DISMISS-A,
S-ME-DISMISS-B, S-ME-DISMISS-NO-NOTE, S-ROLE-TEACHER, S-ROLE-READONLY, S-CLASSIFY-REGRESSION. Key expectations:

| Scenario | When | Then (evidence) |
| --- | --- | --- |
| S-ROW-PARENT | Load Not classified CW | `lblAbsRowSrcV` "Parent report #515 · Reported Sep 13, 2026 10:56 PM (Pacific) · Reason: Flu" |
| S-REMOVE-OK | tick 2, reason, Remove ticked (2) | receipt "2 absence(s) removed (Is Deleted = Yes), 0 failed · reason: …"; lines "Is Deleted = Yes · was Not classified · audit Soft Delete written"; rows gone |
| S-KEEP-PRESENT | Keep present on #516 conflict | receipt "Kept present · Doe, Jane · Wed Sep 16, 2026 · flag cleared"; Present "Yes (1, unchanged)"; Parent Reported Absent "No (cleared)"; row gone |
| S-MARK-ABSENT | Mark absent | receipt "Marked absent · …"; Present "No (0)"; Source "Office"; list reloads, row shows "Office (parent report #516) · Reported …" |
| S-ME-MAP-A | Map #700 to Doe, Jane | receipt Student_ID CW-1001, Match_Status Manually Resolved, "Other SharePoint columns: not written", flow notice; #700 leaves List A; toggle count -1 |
| S-ME-DATES-OK | #711: 9/30/2026, 10/2/2026 | receipt "Absence Date: 9/31/2026 -> 9/30/2026"; B row "Dates fixed, waiting for the intake flow" |
| S-ME-DISMISS-A / -B | Confirm dismiss with note | receipt Decision Dismissed, Processing Status Processed, Note, "created" / "updated"; row gone |

## Relevant Data Source Schemas

- Attendance: Attendance (GUID), 'Record Key', Date, Present (Bool), 'Is Deleted' (Bool), Student, Teacher, Campus,
  'Absence Classification', 'Absence Reason', 'Classified By', 'Classified On', Notes, 'Source Report ID' (Number),
  'Modified On', NEW Source (choice 'Source (Attendance)': Teacher, 'Parent report', Office), NEW 'Notice Received On'
  (DateTime), NEW 'Parent Reported Absent' (Bool).
- Report Decisions: 'Report Decision' (GUID), Summary, 'Report Item ID' (Number), Decision ('Decision (Report
  Decisions)': Approved, Dismissed; required), Note, 'Student Key', Campus (lookup), 'Created On', NEW 'Processing
  Status' ('Processing Status (Report Decisions)': Processed, Error), NEW 'Error Detail' (Text).
- Student Absence Log (SharePoint): ID, Created, Student_ID, Match_Status (choice record `{Value}`), 'Student First Name',
  'Student Last Name', 'School Site', 'Absence Date', 'Return Date' (text M/D/YYYY), Reason, 'Submitted By',
  'Date Notified'. WRITE ONLY Student_ID, Match_Status, 'Absence Date', 'Return Date'.
- Students: Student, 'Display Name', 'External Client ID' (= Student Key), 'Status (aaca_status)'.
- Enrollments: Student, Campus, 'Start Date', 'End Date'. Campuses: Campus, Name. Month Locks: Campus, Month,
  'Status (aaca_status)'. Audit Events: Summary, Action, Entity, 'Entity ID', Before, After, Reason.

## Required Variants

- GroupContainer -> `Variant: AutoLayout` (every new container)
- Gallery -> `Variant: Vertical` (galAbsCfList, galAbsMeA, galAbsMeB)

## Changed or Added Control Definitions

Creation keywords (verbatim from describe_control): `Control: GroupContainer` (+ Variant), `Control: Gallery`
(+ Variant), `Control: ModernText`, `Control: ModernButton`, `Control: Classic/Button`, `Control: ModernTextInput`,
`Control: ModernDropdown`, `Control: ModernCombobox`. No `@version` suffixes.

- GroupContainer (AutoLayout): AlignInContainer, BorderColor, BorderStyle, BorderThickness, DropShadow, Fill,
  FillPortions, Height, LayoutAlignItems, LayoutDirection, LayoutGap, LayoutJustifyContent, LayoutMaxHeight,
  LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth, LayoutOverflowX, LayoutOverflowY, LayoutWrap, PaddingBottom,
  PaddingLeft, PaddingRight, PaddingTop, RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft, RadiusTopRight, Visible,
  Width. Enums: `LayoutDirection.Vertical|Horizontal`, `LayoutAlignItems.Stretch|Center|Start|End`,
  `AlignInContainer.Stretch|Center|Start|End`, `DropShadow.None`, `LayoutOverflow.Scroll`.
- Gallery (Vertical): AccessibleLabel, AlignInContainer, BorderColor, BorderThickness, DisplayMode, Fill, FillPortions,
  Height, Items, LayoutMinHeight, LayoutMinWidth, Selectable, ShowScrollbar, TabIndex, TemplatePadding, TemplateSize,
  Visible, Width, WrapCount.
- ModernText: AccessibleLabel, Align, AlignInContainer, AutoHeight, Color, Fill, FillPortions, FontWeight, Height,
  LayoutMinHeight, LayoutMinWidth, PaddingBottom, PaddingLeft, PaddingRight, PaddingTop, Size, Text, VerticalAlign,
  Visible, Width, Wrap. Enums: `FontWeight.Semibold|Bold`, `VerticalAlign.Top`.
- ModernButton: AccessibleLabel, AlignInContainer, Appearance, BasePaletteColor, Color, DisplayMode, FillPortions,
  Height, Layout, LayoutMinHeight, LayoutMinWidth, OnSelect, Size, Text, Tooltip, Visible, Width (NO Fill). Enums:
  `Appearance: =ButtonAppearance.Primary|Secondary` (Enum name ButtonAppearance), `Layout: =ButtonLayout.TextOnly`,
  `DisplayMode.Edit|Disabled`.
- Classic/Button (engine): AlignInContainer, AutoDisableOnSelect, LayoutMinHeight, LayoutMinWidth, OnSelect, Text,
  Visible (NO AccessibleLabel).
- ModernTextInput: AccessibleLabel, AlignInContainer, Appearance, Color, Default, DisplayMode, FillPortions, Height,
  LayoutMinHeight, LayoutMinWidth, MaxLength, OnChange, Placeholder, Required, Type, Visible, Width. Enums:
  `Appearance: =Appearance.Outline` (Enum name Appearance), `Type: =TextInputType.SingleLine|Multiline` (Enum name
  TextInputType). Output `.Text`.
- ModernDropdown: AccessibleLabel, AlignInContainer, Appearance, Color, Default, DisplayMode, FillPortions, Height,
  ItemDisplayText, Items, LayoutMinHeight, LayoutMinWidth, OnChange, Visible, Width. `Appearance: =Appearance.Outline`.
  Output `.Selected`.
- ModernCombobox: AccessibleLabel, AlignInContainer, Appearance, Color, DefaultSelectedItems, DisplayMode,
  FillPortions, Height, InputTextPlaceholder, IsSearchable, ItemDisplayText, Items, LayoutMinHeight, LayoutMinWidth,
  OnChange, SelectMultiple, Visible, Width. `Appearance: =Appearance.Outline`. Empty selection:
  `DefaultSelectedItems: =[]`. Outputs `.SelectedItems`, `.Selected`.

## Builder Notes

- Scan every plain scalar for ` #` and `: ` before saving; make those values `|-` blocks (all formulas above are blocks).
- No glyphs other than the "·" and "…" already used on this screen.
- If compile reports `Source`, `'Notice Received On'`, `'Parent Reported Absent'`, `'Processing Status'` or
  `'Error Detail'` as unknown, stop and report the exact message (the orchestrator checks the display name with
  `get_data_source_schema`); do not guess alternatives.
- If `k.Value` in the colAbsCfRpt `Distinct` is rejected, use `k.Result` (older Power Fx column name) and report it.
