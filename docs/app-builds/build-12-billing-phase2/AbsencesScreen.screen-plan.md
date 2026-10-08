# Screen Plan: Absences (build 12 - Absence Notices: Mapping Errors, Classify notice text, Add absence notice)

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml`
- YAML key: AbsencesScreen
- Control name prefix: Abs (NEW controls use `AbsNt`: `chkAbsNtAllStu`, `lblAbsNtHowV`, `rdoAbsNtHowV`,
  `lblAbsNtDateV`, `dpAbsNtDateV`, `lblAbsNtTimeV`, `txtAbsNtTimeV`)

Read `canvas-app-shared.md` first (palette, field semantics, choice literals, new variables, YAML rules).

HARD RULES: do not rename, move (re-parent) or delete any existing control. Do not touch `conAbsHdrTabs` or its
children. Only the properties listed below change; every other property stays byte-identical. Exactly 7 new
controls. The orchestrator has already added `varAbsNtSelId`, `varAbsNtAllStu`, `varAbsNtHow`, `varAbsNtOpenAt`,
`varAbsNtErr` to App.OnStart.

Self-check before returning (text search of the saved file):
- zero occurrences of `varAbsMeSelId`, `ItemId`, `'Report Decisions'`, `colAbsMeSrc`, `colAbsMeErrDec`,
  `colAbsMeDecIds`, `SchoolSite`, `AbsText`, `RetText`, `DecCreated`, `SpFound`;
- `'Student Absence Log'` appears only inside `btnAbsLoadEngine` (colAbsCfRpt, unchanged);
- no ` #` outside `|-` blocks; every value containing `: ` is a `|-` block.

## Current State

- Root `conAbsRoot` (scroll) -> `conAbsHeader` (nav + `conAbsHdrTabs`: Classify absences / Mapping Errors (n) =
  `CountRows(colAbsMe)`), `conAbsHelp`, `conAbsDenied`, `conAbsMeView` (Mapping Errors), engines `btnAbsLoadEngine`,
  `btnAbsClassifyEngine`, `btnAbsMeEngine`, `btnAbsAddLoadEngine`, then `conAbsClassifyView`.
- `conAbsMeView` -> `conAbsMeReceipt` (varAbsMeReceipt {Kind, Title, Body}) and `conAbsMeBody` = list panel
  `conAbsMeListPanel` (head, `conAbsMeCampusField`/`ddAbsMeCampus`, `lblAbsMeCount`, `lblAbsMeAHead`, `galAbsMeA`,
  `lblAbsMeBHead`, `galAbsMeB`) + detail `conAbsMeDetail` (`lblAbsMeDetailTitle`, `lblAbsMeFacts`,
  `conAbsMeModeBar` [Map student / Fix dates / Dismiss / Close], `conAbsMeMapPanel`, `conAbsMeDatesPanel`,
  `conAbsMeDismissPanel`). Today every formula reads SharePoint 'Student Absence Log' + 'Report Decisions' rows keyed
  by the numeric `varAbsMeSelId` / `ItemId`.
- Classify: `btnAbsLoadEngine` builds `colAbsList` + `colAbsCf`; rows show `lblAbsRowSrcV`, `lblAbsCfRowMeta`.
- Add absence panel `conAbsAddPanelV` in `conAbsDecideV` (build 9), saved by `btnAbsAddSaveV`.

## Changes (summary)

1. Mapping Errors engine reads Absence Notices (`btnAbsMeEngine.OnSelect`).
2. Mapping Errors list + detail controls re-pointed from `ItemId`/`varAbsMeSelId` to `NoticeId`/`varAbsNtSelId`.
3. Map student: picker filtered to the notice campus + First Day Absent, typed-last-name filter, NEW `chkAbsNtAllStu`;
   Save writes the notice. Fix dates and Dismiss write the notice.
4. Classify loader adds notice fields; two row labels show them.
5. Add absence: NEW "How did we hear about it?" + date/time; Save creates and links an Absence Notice.

## Properties to Update - Mapping Errors list

| Control | Property | Exact new value |
| --- | --- | --- |
| conAbsMeListPanel | Visible | `=!(conAbsRoot.Width < 1024 && !IsBlank(varAbsNtSelId))` |
| lblAbsMeAHead | Text | `="Could not match (" & CountRows(Filter(colAbsMe, Kind = "A")) & ")" & If(CountRows(Filter(colAbsMe, Kind = "A")) = 0, " · none", "")` |
| galAbsMeA | AccessibleLabel | `="Notices that could not be matched to a student"` |
| galAbsMeA | Height | `=Min(3, CountRows(Filter(colAbsMe, Kind = "A"))) * If(conAbsRoot.Width < 640, 212, 176)` |
| galAbsMeA | TemplateSize | `=If(conAbsRoot.Width < 640, 212, 176)` |
| conAbsMeARow | Fill | `=If(ThisItem.NoticeId = varAbsNtSelId, ColorInfoBg, ColorWhite)` |
| lblAbsMeAName | Text | F1 below |
| btnAbsMeAOpen | AccessibleLabel | `="Open notice " & ThisItem.Ref` |
| btnAbsMeAOpen | OnSelect | F2 below |
| lblAbsMeAMeta | Height | `=If(conAbsRoot.Width < 640, 144, 108)` |
| lblAbsMeAMeta | Text | F3 below |
| galAbsMeB | AccessibleLabel | `="Notices the processing flow could not process"` |
| galAbsMeB | Height | `=Min(3, CountRows(Filter(colAbsMe, Kind = "B"))) * If(conAbsRoot.Width < 640, 212, 176)` |
| galAbsMeB | Items | `=SortByColumns(Filter(colAbsMe, Kind = "B"), "Created", SortOrder.Descending)` |
| galAbsMeB | TemplateSize | `=If(conAbsRoot.Width < 640, 212, 176)` |
| conAbsMeBRow | Fill | `=If(ThisItem.NoticeId = varAbsNtSelId, ColorInfoBg, ColorWhite)` |
| lblAbsMeBName | Text | F1 below (same formula) |
| btnAbsMeBOpen | AccessibleLabel | `="Open notice " & ThisItem.Ref` |
| btnAbsMeBOpen | OnSelect | F2 below (same formula) |
| lblAbsMeBMeta | Height | `=If(conAbsRoot.Width < 640, 144, 108)` |
| lblAbsMeBMeta | Text | F4 below |
| lblAbsMeCount | Text | F5 below |

`galAbsMeA.Items` (`"Created"` sort), `lblAbsMeBHead`, `lblAbsMeListTitle`, `btnAbsMeReload`, `ddAbsMeCampus`,
`conAbsMeListPanel.Height` stay unchanged (they read `Kind` / `CountRows(colAbsMe)` / gallery heights).

F1 `lblAbsMeAName.Text` / `lblAbsMeBName.Text`:
```
=ThisItem.Ref & " · " & If(Trim(ThisItem.LastName & ThisItem.FirstName) = "", "(no name typed)", ThisItem.LastName & ", " & ThisItem.FirstName) & " (as typed)"
```

F2 `btnAbsMeAOpen.OnSelect` / `btnAbsMeBOpen.OnSelect`:
```
=Set(varAbsNtSelId, ThisItem.NoticeId);
Set(varAbsMeMode, If(ThisItem.Kind = "A", "map", "dates"));
Set(varAbsNtAllStu, false);
Reset(cboAbsMeStudent);
Reset(chkAbsNtAllStu);
Reset(txtAbsMeAbsDate);
Reset(txtAbsMeRetDate);
Reset(txtAbsMeDismissNote)
```

F3 `lblAbsMeAMeta.Text` (`|-` block):
```
="Campus " & If(ThisItem.TypedCampus = "", "(not typed)", ThisItem.TypedCampus) & If(ThisItem.CampusName = "" || ThisItem.CampusName = ThisItem.TypedCampus, "", " (" & ThisItem.CampusName & ")") & " · absent " & If(IsBlank(ThisItem.FirstDay), "-", Text(ThisItem.FirstDay, "m/d/yyyy")) & " · back " & If(IsBlank(ThisItem.ReturnDate), "-", Text(ThisItem.ReturnDate, "m/d/yyyy")) & " · " & ThisItem.MatchText & If(ThisItem.MatchDetail = "", "", " (" & If(Len(ThisItem.MatchDetail) > 80, Left(ThisItem.MatchDetail, 80) & "...", ThisItem.MatchDetail) & ")") & " · Reason " & If(ThisItem.ReasonText = "", "-", If(Len(ThisItem.ReasonText) > 80, Left(ThisItem.ReasonText, 80) & "...", ThisItem.ReasonText)) & " · Parent " & If(ThisItem.ParentName = "", "-", ThisItem.ParentName) & If(ThisItem.Relationship = "", "", " (" & ThisItem.Relationship & ")") & " · notified " & If(IsBlank(ThisItem.NoticeAt), "-", Text(ThisItem.NoticeAt, "mm/dd/yyyy h:mm AM/PM"))
```

F4 `lblAbsMeBMeta.Text` (`|-` block):
```
="Error " & If(ThisItem.ErrorDetail = "", "-", If(Len(ThisItem.ErrorDetail) > 100, Left(ThisItem.ErrorDetail, 100) & "...", ThisItem.ErrorDetail)) & " · " & If(ThisItem.StudentName = "", "no student", ThisItem.StudentName) & " · Campus " & If(ThisItem.CampusName = "", If(ThisItem.TypedCampus = "", "-", ThisItem.TypedCampus), ThisItem.CampusName) & " · absent " & If(IsBlank(ThisItem.FirstDay), "-", Text(ThisItem.FirstDay, "m/d/yyyy")) & " · back " & If(IsBlank(ThisItem.ReturnDate), "-", Text(ThisItem.ReturnDate, "m/d/yyyy")) & " · Reason " & If(ThisItem.ReasonText = "", "-", If(Len(ThisItem.ReasonText) > 60, Left(ThisItem.ReasonText, 60) & "...", ThisItem.ReasonText)) & " · Parent " & If(ThisItem.ParentName = "", "-", ThisItem.ParentName) & If(ThisItem.Relationship = "", "", " (" & ThisItem.Relationship & ")") & " · notified " & If(IsBlank(ThisItem.NoticeAt), "-", Text(ThisItem.NoticeAt, "mm/dd/yyyy h:mm AM/PM"))
```

F5 `lblAbsMeCount.Text` (`|-` block):
```
=If(
    varAbsMeLoadError <> "", "Could not load absence notices: " & varAbsMeLoadError & ". Use Reload to try again.",
    varAbsMeLoading, "Loading absence notices...",
    CountRows(colAbsMe) = 0, "No mapping errors. Every new absence notice for " & If(StudentCampusLock <> ZeroGuid, "your campus", varAbsMeCampusId = ZeroGuid, "all campuses", LookUp(colAbsCampusOpts, CampusId = varAbsMeCampusId).CampusName) & " is matched and processed.",
    CountRows(Filter(colAbsMe, Kind = "A")) & " could not be matched · " & CountRows(Filter(colAbsMe, Kind = "B")) & " could not be processed · " & If(StudentCampusLock <> ZeroGuid, "your campus", varAbsMeCampusId = ZeroGuid, "all campuses", LookUp(colAbsCampusOpts, CampusId = varAbsMeCampusId).CampusName)
)
```

## Properties to Update - Mapping Errors detail

| Control | Property | Exact new value |
| --- | --- | --- |
| conAbsMeDetail | Visible | `=conAbsRoot.Width >= 1024 \|\| !IsBlank(varAbsNtSelId)` (write a plain `\|\|`) |
| lblAbsMeFacts | Height | `=If(IsBlank(LookUp(colAbsMe, NoticeId = varAbsNtSelId)), 60, If(conAbsRoot.Width < 640, 400, 270))` |
| lblAbsMeFacts | Text | D1 below |
| conAbsMeModeBar | Visible | `=!IsBlank(varAbsNtSelId)` |
| btnAbsMeModeDates | Visible | `=LookUp(colAbsMe, NoticeId = varAbsNtSelId).Kind = "B"` |
| btnAbsMeModeDismiss | AccessibleLabel | `=Self.Text & " this notice" & If(varAbsMeMode = "dismiss", " (open)", "")` |
| btnAbsMeClose | AccessibleLabel | `="Close this notice without changes"` |
| btnAbsMeClose | OnSelect | D2 below |
| conAbsMeMapPanel | Height | `=If(conAbsRoot.Width < 640, 230, 212)` |
| conAbsMeMapPanel | Visible | `=!IsBlank(varAbsNtSelId) && varAbsMeMode = "map"` |
| cboAbsMeStudent | Items | D3 below |
| lblAbsMeMapCheck | Text | D4 below |
| btnAbsMeMapSave | AccessibleLabel | `="Save mapping to the absence notice"` |
| btnAbsMeMapSave | DisplayMode | `=If(CanClassify && !varAbsMeSaving && !IsBlank(LookUp(colAbsMe, NoticeId = varAbsNtSelId)) && CountRows(cboAbsMeStudent.SelectedItems) = 1, DisplayMode.Edit, DisplayMode.Disabled)` |
| btnAbsMeMapSave | OnSelect | M1 below |
| conAbsMeDatesPanel | Visible | `=!IsBlank(varAbsNtSelId) && varAbsMeMode = "dates" && LookUp(colAbsMe, NoticeId = varAbsNtSelId).Kind = "B"` |
| lblAbsMeAbsDate | AccessibleLabel / Text | `="First Day Absent, required, M/D/YYYY"` / `="First Day Absent * (M/D/YYYY)"` |
| txtAbsMeAbsDate | AccessibleLabel | `="First Day Absent"` |
| txtAbsMeAbsDate | Default | `=With({it: LookUp(colAbsMe, NoticeId = varAbsNtSelId)}, If(IsBlank(it.FirstDay), "", Text(it.FirstDay, "m/d/yyyy")))` |
| txtAbsMeAbsDate | Placeholder | `="10/6/2026"` |
| lblAbsMeRetDate | AccessibleLabel / Text | `="Return Date, the day the child is back, required, M/D/YYYY"` / `="Return Date * (day back, M/D/YYYY)"` |
| txtAbsMeRetDate | Default | `=With({it: LookUp(colAbsMe, NoticeId = varAbsNtSelId)}, If(IsBlank(it.ReturnDate), "", Text(it.ReturnDate, "m/d/yyyy")))` |
| txtAbsMeRetDate | Placeholder | `="10/8/2026"` |
| lblAbsMeDatesCheck | Text | D5 below |
| btnAbsMeDatesSave | AccessibleLabel | `="Save dates to the absence notice"` |
| btnAbsMeDatesSave | OnSelect | M2 below (DisplayMode unchanged: Ready gate) |
| conAbsMeDismissPanel | Visible | `=!IsBlank(varAbsNtSelId) && varAbsMeMode = "dismiss"` |
| txtAbsMeDismissNote | Placeholder | `="e.g. duplicate of ABS-2026-001002, or not an AACA student"` |
| btnAbsMeDismissSave | DisplayMode | `=If(CanClassify && !varAbsMeSaving && !IsBlank(LookUp(colAbsMe, NoticeId = varAbsNtSelId)) && Trim(txtAbsMeDismissNote.Text) <> "", DisplayMode.Edit, DisplayMode.Disabled)` |
| btnAbsMeDismissSave | OnSelect | M3 below |

D1 `lblAbsMeFacts.Text` (`|-` block):
```
=With(
    {it: LookUp(colAbsMe, NoticeId = varAbsNtSelId)},
    If(
        IsBlank(it),
        "Choose Open on a notice to map it to a student, fix its dates, or dismiss it.",
        "Notice " & it.Ref & " · " & If(it.Kind = "A", "Could not match", "Could not process") & " · " & it.MatchText & Char(10) &
        "Student as typed: " & it.FirstName & " " & it.LastName & " · campus as typed: " & If(it.TypedCampus = "", "-", it.TypedCampus) & Char(10) &
        "Campus: " & If(it.CampusName = "", "not set", it.CampusName) & " · student: " & If(it.StudentName = "", "not set", it.StudentName) & Char(10) &
        "First Day Absent: " & If(IsBlank(it.FirstDay), "-", Text(it.FirstDay, "m/d/yyyy")) & " · Return Date: " & If(IsBlank(it.ReturnDate), "-", Text(it.ReturnDate, "m/d/yyyy")) & Char(10) &
        "Reason: " & If(it.ReasonText = "", "-", If(Len(it.ReasonText) > 120, Left(it.ReasonText, 120) & "...", it.ReasonText)) & Char(10) &
        "Parent: " & If(it.ParentName = "", "-", it.ParentName) & If(it.Relationship = "", "", " (" & it.Relationship & ")") & " · notified " & If(IsBlank(it.NoticeAt), "-", Text(it.NoticeAt, "mm/dd/yyyy h:mm AM/PM")) & Char(10) &
        "Match Detail: " & If(it.MatchDetail = "", "-", If(Len(it.MatchDetail) > 120, Left(it.MatchDetail, 120) & "...", it.MatchDetail)) &
        If(it.Kind = "B", Char(10) & "Error: " & If(it.ErrorDetail = "", "-", If(Len(it.ErrorDetail) > 160, Left(it.ErrorDetail, 160) & "...", it.ErrorDetail)), "")
    )
)
```

D2 `btnAbsMeClose.OnSelect`:
```
=Set(varAbsNtSelId, Blank());
Set(varAbsMeMode, "");
Set(varAbsNtAllStu, false);
Reset(cboAbsMeStudent);
Reset(chkAbsNtAllStu);
Reset(txtAbsMeAbsDate);
Reset(txtAbsMeRetDate);
Reset(txtAbsMeDismissNote)
```

D3 `cboAbsMeStudent.Items` (`|-` block; picker = enrollments at the notice campus covering First Day Absent; only
names containing the typed last name unless "show all" is ticked or nothing matches):
```
=With(
    {it: LookUp(colAbsMe, NoticeId = varAbsNtSelId)},
    With(
        {base: Filter(colAbsMeStudents, (it.CampusId = ZeroGuid || CampusId = it.CampusId) && (IsBlank(it.FirstDay) || (StartDate <= it.FirstDay && (IsBlank(EndDate) || EndDate >= it.FirstDay))))},
        With(
            {hit: Filter(base, Len(Trim(it.LastName)) > 0 && Trim(it.LastName) in DisplayName)},
            Sort(If(varAbsNtAllStu || CountRows(hit) = 0, base, hit), DisplayName, SortOrder.Ascending)
        )
    )
)
```
(`ItemDisplayText: =ThisItem.Label`, `InputTextPlaceholder`, `SelectMultiple`, `DefaultSelectedItems: =[]` unchanged.)

D4 `lblAbsMeMapCheck.Text` (`|-` block):
```
=With(
    {it: LookUp(colAbsMe, NoticeId = varAbsNtSelId), stu: First(cboAbsMeStudent.SelectedItems)},
    If(
        IsBlank(it), "Choose Open on a notice first.",
        CountRows(cboAbsMeStudent.SelectedItems) <> 1, If(CountRows(cboAbsMeStudent.Items) = 0, "No student is enrolled at this campus on the First Day Absent. Tick Show all students, or fix the dates.", "Pick the student this notice is about. Save mapping stays off until you do."),
        "Ready: Save mapping links notice " & it.Ref & " to " & stu.DisplayName & " (Mapped by office). The processing flow then adds the absences within a minute."
    )
)
```

D5 `lblAbsMeDatesCheck.Text` (`|-` block):
```
=With(
    {it: LookUp(colAbsMe, NoticeId = varAbsNtSelId), a: IfError(DateValue(Trim(txtAbsMeAbsDate.Text), "en-US"), Blank()), r: IfError(DateValue(Trim(txtAbsMeRetDate.Text), "en-US"), Blank())},
    If(
        IsBlank(it) || it.Kind <> "B", "Open a notice in Could not process first.",
        it.StudentId = ZeroGuid, "This notice has no student yet. Use Map student; it also asks the processing flow to run again.",
        IsBlank(a), "Type the First Day Absent as M/D/YYYY, for example 10/6/2026.",
        IsBlank(r), "Type the Return Date (the day the child is back) as M/D/YYYY.",
        r <= a, "The Return Date must be after the First Day Absent.",
        DateDiff(a, r, TimeUnit.Days) > 60, "Those dates cover more than 60 days. Check them.",
        "Ready: Save dates sets " & Text(a, "m/d/yyyy") & " to " & Text(DateAdd(r, -1, TimeUnit.Days), "m/d/yyyy") & " (back " & Text(r, "m/d/yyyy") & "), clears the error and asks the processing flow to run again."
    )
)
```

## Controls to Add

### N1. `chkAbsNtAllStu` (ModernCheckbox) - child of `conAbsMeMapPanel`, inserted directly AFTER `conAbsMeMapField`
(before `lblAbsMeMapCheck`)

AccessibleLabel `="Show all students enrolled at the notice's campus"`, AlignInContainer `=AlignInContainer.Stretch`,
Default `=varAbsNtAllStu`, DisplayMode `=If(varAbsMeSaving, DisplayMode.Disabled, DisplayMode.Edit)`, FillPortions
`=0`, Height `=32`, Label `="Show all students enrolled at the notice's campus"`, LayoutMinHeight `=0`,
LayoutMinWidth `=0`, OnCheck `=Set(varAbsNtAllStu, true)`, OnUncheck `=Set(varAbsNtAllStu, false)`.
(If the compiler rejects `FillPortions` on ModernCheckbox, drop that one property and report it.)

### N2-N7. Add absence notice fields - children of `conAbsAddPanelV`, inserted in this order directly AFTER
`ddAbsAddReasonV` (before `lblAbsLeTimeV`)

Labels: ModernText Size 12, FontWeight `=FontWeight.Semibold`, Color `=ColorMuted`, Height 18, Wrap `=false`,
Padding* `=0`, AlignInContainer `=AlignInContainer.Stretch`, FillPortions `=0`, LayoutMin* `=0`, AccessibleLabel
`=Self.Text`. Inputs: AlignInContainer Stretch, FillPortions `=0`, LayoutMin* `=0`, Color `=ColorInk`, DisplayMode
`=If(varAbsSaving, DisplayMode.Disabled, DisplayMode.Edit)`.

| # | Control | Type | Key properties | Visible |
| - | ------- | ---- | -------------- | ------- |
| N2 | lblAbsNtHowV | ModernText | Text `="How did we hear about it? *"` | `=varAbsAddMode = "absence"` |
| N3 | rdoAbsNtHowV | ModernRadio | AccessibleLabel `="How did we hear about it"`, Items `=["Parent notified us", "No notice"]`, Default (`\|-` block) `={Value: varAbsNtHow}`, Layout `=OptionLayout.Vertical`, Height `=64`, OnChange `=Set(varAbsNtHow, Self.Selected.Value)` (no Appearance) | `=varAbsAddMode = "absence"` |
| N4 | lblAbsNtDateV | ModernText | Text `="Date the parent told us *"` | `=varAbsAddMode = "absence" && varAbsNtHow = "Parent notified us"` |
| N5 | dpAbsNtDateV | ModernDatePicker | AccessibleLabel `="Date the parent told us"`, Appearance `=Appearance.Outline`, DefaultDate `=Today()`, StartDate `=Date(FirstSchoolYear, 1, 1)`, EndDate `=Today()`, Format `=DatePickerFormat.Short`, Height `=36` | same as N4 |
| N6 | lblAbsNtTimeV | ModernText | Text `="Time the parent told us * (h:mm AM/PM)"` | same as N4 |
| N7 | txtAbsNtTimeV | ModernTextInput | AccessibleLabel `="Time the parent told us, h:mm AM/PM"`, Appearance `=Appearance.Outline`, Default `=Text(varAbsNtOpenAt, "h:mm AM/PM")`, MaxLength `=8`, Placeholder `="8:15 AM"`, Height `=36` | same as N4 |

No default How choice (required explicit choice; "No notice" makes the days billable).

## Properties to Update - Add absence

| Control | Property | Exact new value |
| --- | --- | --- |
| conAbsAddPanelV | Height | `=If(varAbsAddMode = "leftearly", 368, 520 + If(varAbsAddClass = "Excused", 62, 0) + If(varAbsNtHow = "Parent notified us", 124, 0))` |
| conAbsDecideV | Height | `=16 + If(!IsBlank(varAbsSelId), 28 + 8 + 72 + 8 + 22 + Max(36, CountRows(colAbsReasons) * 32) + 8 + 36 + 8 + 44, 28 + If(varAbsAddMode = "", 8 + 60, 0) + 8 + 44 + If(varAbsAddMode = "leftearly", 8 + 368, varAbsAddMode = "absence", 8 + 520 + If(varAbsAddClass = "Excused", 62, 0) + If(varAbsNtHow = "Parent notified us", 124, 0), 0)) + 16` |
| btnAbsAddOpenV | OnSelect | A1 below |
| btnAbsLeOpenV | OnSelect | A1 with `"leftearly"` instead of `"absence"` in `Set(varAbsAddMode, ...)` |
| btnAbsAddCancelV | OnSelect | A2 below |
| lblAbsAddCheckV | Text | A3 below |
| btnAbsAddSaveV | OnSelect | A4 below |

A1 `btnAbsAddOpenV.OnSelect`:
```
=Set(varAbsSelId, Blank());
Set(varAbsReasonId, Blank());
Reset(rdoAbsReasonV);
Set(varAbsAddMode, "absence");
Set(varAbsAddClass, "");
Set(varAbsAddReasonId, Blank());
Set(varAbsNtHow, "");
Set(varAbsNtOpenAt, Now());
Reset(cboAbsAddStuV); Reset(dpAbsAddFromV); Reset(dpAbsAddToV); Reset(rdoAbsAddClassV); Reset(ddAbsAddReasonV); Reset(txtAbsAddNoteV); Reset(txtAbsLeTimeV);
Reset(rdoAbsNtHowV); Reset(dpAbsNtDateV); Reset(txtAbsNtTimeV);
Select(btnAbsAddLoadEngine)
```

A2 `btnAbsAddCancelV.OnSelect` (`|-` block):
```
=Set(varAbsReceipt, {Kind: "Cancelled", Title: If(varAbsAddMode = "leftearly", "Left early", "Add absence") & " cancelled · nothing was changed"});
Clear(colAbsReceiptLines);
Set(varAbsAddMode, ""); Set(varAbsAddClass, ""); Set(varAbsAddReasonId, Blank()); Set(varAbsNtHow, "");
Reset(cboAbsAddStuV); Reset(dpAbsAddFromV); Reset(dpAbsAddToV); Reset(rdoAbsAddClassV); Reset(ddAbsAddReasonV); Reset(txtAbsAddNoteV); Reset(txtAbsLeTimeV);
Reset(rdoAbsNtHowV); Reset(dpAbsNtDateV); Reset(txtAbsNtTimeV)
```

A3 `lblAbsAddCheckV.Text` (`|-` block; leftearly branch byte-identical to today, absence branch extended):
```
=If(
    varAbsAddMode = "leftearly",
    With(
        {n: CountRows(cboAbsAddStuV.SelectedItems), d: dpAbsAddFromV.SelectedDate, tt: Trim(txtAbsLeTimeV.Text)},
        With(
            {tm: If(EndsWith(Upper(tt), "AM") || EndsWith(Upper(tt), "PM"), IfError(TimeValue(tt, "en-US"), Blank()), Blank())},
            If(
                varAbsAddErr <> "", "Could not load students: " & varAbsAddErr,
                n <> 1, "Pick the student.",
                IsBlank(d), "Choose the date.",
                d > Today(), "Left early cannot be in the future.",
                IsBlank(tm), "Type the time as h:mm AM/PM, for example 1:30 PM.",
                d = Today() && DateTime(Year(d), Month(d), Day(d), Hour(tm), Minute(tm), 0) > Now(), "That time has not happened yet today.",
                Trim(txtAbsAddNoteV.Text) = "", "Type the reason (required).",
                "Ready: Save left early marks " & Text(d, "ddd mmm d") & " present with Left early at " & Text(tm, "h:mm AM/PM") & ". A day marked absent is refused."
            )
        )
    ),
    With(
        {n: CountRows(cboAbsAddStuV.SelectedItems), d0: dpAbsAddFromV.SelectedDate, d1: Coalesce(dpAbsAddToV.SelectedDate, dpAbsAddFromV.SelectedDate), nd: dpAbsNtDateV.SelectedDate, ntt: Trim(txtAbsNtTimeV.Text)},
        With(
            {ntm: If(EndsWith(Upper(ntt), "AM") || EndsWith(Upper(ntt), "PM"), IfError(TimeValue(ntt, "en-US"), Blank()), Blank())},
            If(
                varAbsAddErr <> "", "Could not load students: " & varAbsAddErr,
                n <> 1, "Pick the student.",
                IsBlank(d0), "Choose the From date.",
                d1 < d0, "The To date must be on or after the From date.",
                d1 > DateAdd(Today(), 90, TimeUnit.Days), "The To date can be at most 90 days ahead.",
                DateDiff(d0, d1, TimeUnit.Days) > 60, "Choose at most 61 days at a time.",
                !(varAbsAddClass in ["Excused", "Unexcused"]), "Choose Excused or Unexcused.",
                varAbsAddClass = "Excused" && IsBlank(LookUp(colAbsReasons, ReasonId = varAbsAddReasonId)), "Excused needs an absence reason.",
                !(varAbsNtHow in ["Parent notified us", "No notice"]), "Choose how we heard about it.",
                varAbsNtHow = "Parent notified us" && IsBlank(nd), "Choose the date the parent told us.",
                varAbsNtHow = "Parent notified us" && IsBlank(ntm), "Type the time the parent told us as h:mm AM/PM, for example 8:15 AM.",
                varAbsNtHow = "Parent notified us" && DateTime(Year(nd), Month(nd), Day(nd), Hour(ntm), Minute(ntm), 0) > Now(), "The time the parent told us cannot be in the future.",
                "Ready: Save absence records the notice (" & If(varAbsNtHow = "No notice", "no notice", "told " & Text(nd, "m/d") & " " & Text(ntm, "h:mm AM/PM")) & ") and a 0 (" & varAbsAddClass & ") for each school day from " & Text(d0, "mmm d") & " to " & Text(d1, "mmm d") & ". Days already marked are skipped."
            )
        )
    )
)
```

A4 `btnAbsAddSaveV.OnSelect` (`|-` block). Changes versus today: notice inputs in the gate, notice created first
(stop if it fails), each written day gets `'Absence Notice'` + `'Notice Received On'`, audit text, NewClass suffix,
receipt Notice lines, cancel-on-zero, resets. The day loop is otherwise identical:
```
=With(
    {
        stu: First(cboAbsAddStuV.SelectedItems),
        d0: dpAbsAddFromV.SelectedDate,
        d1: Coalesce(dpAbsAddToV.SelectedDate, dpAbsAddFromV.SelectedDate),
        cls: varAbsAddClass,
        rsn: With({qr: varAbsAddReasonId}, LookUp('Absence Reasons', ThisRecord.'Absence Reason' = qr && Active = true)),
        note: Left(Trim(txtAbsAddNoteV.Text), 2000),
        c0: varAbsCampusId,
        how: varAbsNtHow,
        nd: dpAbsNtDateV.SelectedDate,
        ntt: Trim(txtAbsNtTimeV.Text)
    },
    With(
        {ntm: If(EndsWith(Upper(ntt), "AM") || EndsWith(Upper(ntt), "PM"), IfError(TimeValue(ntt, "en-US"), Blank()), Blank())},
        With(
            {nat: If(how = "Parent notified us" && !IsBlank(nd) && !IsBlank(ntm), DateTime(Year(nd), Month(nd), Day(nd), Hour(ntm), Minute(ntm), 0), Blank())},
            If(
                !CanClassify || varAbsSaving || varAbsLoading || varAbsAddMode <> "absence",
                Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved. Only the Attendance Office and System Admin can add absences, and not while saving or loading."}); Clear(colAbsReceiptLines),
                CountRows(cboAbsAddStuV.SelectedItems) <> 1 || IsBlank(d0) || d1 < d0 || d1 > DateAdd(Today(), 90, TimeUnit.Days) || DateDiff(d0, d1, TimeUnit.Days) > 60 || !(cls in ["Excused", "Unexcused"]) || (cls = "Excused" && IsBlank(rsn)) || !(how in ["Parent notified us", "No notice"]) || (how = "Parent notified us" && (IsBlank(nat) || nat > Now())),
                Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved. " & lblAbsAddCheckV.Text}); Clear(colAbsReceiptLines),
                Set(varAbsSaving, true);
                Clear(colAbsLog);
                Set(varAbsNtErr, "");
                IfError(
                    Concurrent(
                        ClearCollect(colAbsLocks, ForAll(Filter('Month Locks', 'Status (aaca_status)' = 'Status (Month Locks)'.Locked) As m, {CampusId: m.Campus.Campus, MonthStart: m.Month})),
                        ClearCollect(colAbsAddTerms, Filter(Terms, 'Start Date' <= d1 && 'End Date' >= d0)),
                        ClearCollect(colAbsAddExc, Filter('Calendar Exceptions', Date >= d0 && Date <= d1))
                    ); true,
                    Set(varAbsAddErr, FirstError.Message)
                );
                With(
                    {
                        srec: With({qs: stu.StudentId}, LookUp(Students, ThisRecord.Student = qs)),
                        crec: With({qc: c0}, LookUp(Campuses, ThisRecord.Campus = qc))
                    },
                    With(
                        {
                            nt: If(
                                !IsBlank(srec) && !IsBlank(crec),
                                IfError(
                                    Patch(
                                        'Absence Notices',
                                        Defaults('Absence Notices'),
                                        {
                                            Summary: Left(stu.StudentName & " - absent " & Text(d0, "m/d/yyyy"), 100),
                                            Source: 'Source (Absence Notices)'.Office,
                                            'Status (aaca_status)': 'Status (Absence Notices)'.Accepted,
                                            'Match Status': 'Match Status (Absence Notices)'.Matched,
                                            Student: srec,
                                            Campus: crec,
                                            'Absence Reason': If(cls = "Excused", rsn, Blank()),
                                            'First Day Absent': d0,
                                            'Last Day Absent': d1,
                                            'Return Date': DateAdd(d1, 1, TimeUnit.Days),
                                            'Reason Text': If(note <> "", note, cls = "Excused", rsn.Name, ""),
                                            'Notice At': nat,
                                            'Processed On': Now(),
                                            'Processed By': CurrentUserRow
                                        }
                                    ),
                                    Set(varAbsNtErr, FirstError.Message); Blank()
                                )
                            )
                        },
                        If(
                            IsBlank(nt),
                            Set(varAbsReceipt, {Kind: "Failed", Title: "Not saved · " & stu.StudentName & " · the absence notice could not be created, so no days were added"});
                            ClearCollect(
                                colAbsReceiptLines,
                                {Label: "Error", Value: If(varAbsNtErr <> "", varAbsNtErr, IsBlank(srec), "The student could not be read.", "The campus could not be read.")},
                                {Label: "Attendance", Value: "Not changed"}
                            ),
                            With(
                                {
                                    ref: Coalesce(nt.Reference, "(reference pending)"),
                                    aun: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Absence notice " & Coalesce(nt.Reference, "") & " created (office) for " & stu.StudentName, 100), Action: 'Action (Audit Events)'.Create, Entity: "aaca_absencenotice", 'Entity ID': Text(nt.'Absence Notice'), Before: "", After: JSON({Reference: Coalesce(nt.Reference, ""), Source: Text(nt.Source), Status: Text(nt.'Status (aaca_status)'), MatchStatus: Text(nt.'Match Status'), FirstDay: Text(nt.'First Day Absent', "yyyy-mm-dd"), LastDay: Text(nt.'Last Day Absent', "yyyy-mm-dd"), ReturnDate: Text(nt.'Return Date', "yyyy-mm-dd"), NoticeAt: If(IsBlank(nt.'Notice At'), "", Text(nt.'Notice At', "yyyy-mm-dd hh:mm")), ReasonText: Coalesce(nt.'Reason Text', "")}), Reason: If(how = "Parent notified us", "Office recorded a parent notice", "Office absence with no notice")}), Blank())
                                },
                                ForAll(
                                    Sequence(DateDiff(d0, d1, TimeUnit.Days) + 1, 0) As n,
                                    With(
                                        {d: DateAdd(d0, n.Value, TimeUnit.Days)},
                                        With(
                                            {
                                                seg: First(Sort(Filter(colAbsAddEnr, StudentId = stu.StudentId && StartDate <= d && (IsBlank(EndDate) || EndDate >= d)), StartDate, SortOrder.Descending)),
                                                t: First(Filter(colAbsAddTerms, ThisRecord.'Start Date' <= d && ThisRecord.'End Date' >= d && (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = c0))),
                                                x: LookUp(colAbsAddExc, ThisRecord.Date = d && (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = c0) && ThisRecord.Type <> 'Type (Calendar Exceptions)'.'Make-up School Day'),
                                                mk: !IsBlank(LookUp(colAbsAddExc, ThisRecord.Date = d && (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = c0) && ThisRecord.Type = 'Type (Calendar Exceptions)'.'Make-up School Day'))
                                            },
                                            With(
                                                {school: !IsBlank(t) && (mk || (Weekday(d, StartOfWeek.Monday) < 6 && IsBlank(x)))},
                                                With(
                                                    {live: If(!school || IsBlank(seg), Blank(), With({qs: stu.StudentId, qv: seg.ServiceId, qd: d}, LookUp(Attendance, Student.Student = qs && Service.Service = qv && Date = qd)))},
                                                    With(
                                                        {
                                                            outcome: If(
                                                                !school, "not a school day",
                                                                IsBlank(seg), "not enrolled at this campus",
                                                                !IsBlank(LookUp(colAbsLocks, CampusId = c0 && MonthStart = Date(Year(d), Month(d), 1))), "month locked",
                                                                !IsBlank(live) && live.'Is Deleted' <> true && live.Present = true, "teacher marked present - use Needs a decision / ask the teacher",
                                                                !IsBlank(live) && live.'Is Deleted' <> true, "already absent",
                                                                "ok"
                                                            )
                                                        },
                                                        With(
                                                            {
                                                                wr: If(
                                                                    outcome = "ok",
                                                                    IfError(
                                                                        Patch(
                                                                            Attendance,
                                                                            Coalesce(live, Defaults(Attendance)),
                                                                            {
                                                                                'Record Key': Text(d, "yyyymmdd") & "|" & seg.StudentNumber & "|" & seg.ServiceCode,
                                                                                Date: d,
                                                                                Student: seg.EnrRec.Student,
                                                                                Service: seg.EnrRec.Service,
                                                                                Enrollment: seg.EnrRec,
                                                                                Teacher: seg.EnrRec.Teacher,
                                                                                Campus: seg.EnrRec.Campus,
                                                                                'School Year': seg.EnrRec.'School Year',
                                                                                Term: t,
                                                                                'IEP Ratio': Switch(
                                                                                    seg.EnrRec.'IEP Ratio',
                                                                                    'IEP Ratio (Enrollments)'.'No Aide', 'IEP Ratio (Attendance)'.'No Aide',
                                                                                    'IEP Ratio (Enrollments)'.'1:1', 'IEP Ratio (Attendance)'.'1:1',
                                                                                    'IEP Ratio (Enrollments)'.'2:1', 'IEP Ratio (Attendance)'.'2:1',
                                                                                    'IEP Ratio (Enrollments)'.'3:1', 'IEP Ratio (Attendance)'.'3:1',
                                                                                    'IEP Ratio (Enrollments)'.'4:1', 'IEP Ratio (Attendance)'.'4:1'
                                                                                ),
                                                                                Present: false,
                                                                                'Is Deleted': false,
                                                                                Source: 'Source (Attendance)'.Office,
                                                                                'Absence Classification': Switch(cls, "Excused", 'Absence Classification (Attendance)'.Excused, "Unexcused", 'Absence Classification (Attendance)'.Unexcused),
                                                                                'Absence Reason': If(cls = "Excused", rsn, Blank()),
                                                                                'Classified On': Now(),
                                                                                'Classified By': CurrentUserRow,
                                                                                Notes: note,
                                                                                'Absence Notice': nt,
                                                                                'Notice Received On': nt.'Notice At',
                                                                                'Parent Reported Absent': false,
                                                                                'Source Report ID': Blank(),
                                                                                'Left Early': false,
                                                                                'Left Early At': Blank(),
                                                                                'Left Early Reason': Blank()
                                                                            }
                                                                        ),
                                                                        Blank()
                                                                    )
                                                                )
                                                            },
                                                            With(
                                                                {au: If(!IsBlank(wr), IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Office absence " & wr.'Record Key', 100), Action: 'Action (Audit Events)'.Create, Entity: "aaca_attendance", 'Entity ID': Text(wr.Attendance), Before: If(IsBlank(live), "", JSON({IsDeleted: true, Present: live.Present})), After: JSON({Present: wr.Present, Source: Text(wr.Source), Classification: Text(wr.'Absence Classification'), Reason: Coalesce(wr.'Absence Reason'.Name, ""), Notes: Coalesce(wr.Notes, ""), Notice: Coalesce(nt.Reference, ""), NoticeReceivedOn: If(IsBlank(wr.'Notice Received On'), "", Text(wr.'Notice Received On', "yyyy-mm-dd hh:mm"))}), Reason: If(IsBlank(nt.'Notice At'), "Office absence, no notice (" & Coalesce(nt.Reference, "") & ")", "Office absence, parent notified " & Text(nt.'Notice At', "mm/dd/yyyy h:mm AM/PM") & " (" & Coalesce(nt.Reference, "") & ")")}), Blank()))},
                                                                Collect(colAbsLog, {AttId: Coalesce(wr.Attendance, live.Attendance, ZeroGuid), StudentName: stu.StudentName, AbsDate: d, TeacherName: Coalesce(seg.TeacherName, ""), CampusName: "", OldClass: If(IsBlank(live), "No record", "Deleted record (reused)"), NewClass: If(IsBlank(wr), "", Text(wr.'Absence Classification') & If(IsBlank(wr.'Absence Reason'), "", " (" & wr.'Absence Reason'.Name & ")") & If(IsBlank(wr.'Absence Notice'), " · notice NOT linked", " · notice linked")), ReasonName: If(IsBlank(wr), "", Coalesce(wr.Notes, "")), ByName: If(IsBlank(wr), "", Coalesce(wr.'Classified By'.'Full Name', "")), OnText: If(IsBlank(wr), "", Text(wr.'Classified On', "mmm d, yyyy h:mm AM/PM")), Outcome: If(!IsBlank(wr), "created", outcome = "ok", "failed", outcome), AuditOk: !IsBlank(au)})
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                );
                                With(
                                    {
                                        cr: CountRows(Filter(colAbsLog, Outcome = "created")),
                                        fl: CountRows(Filter(colAbsLog, Outcome = "failed")),
                                        ns: CountRows(Filter(colAbsLog, Outcome = "not a school day")),
                                        g: First(Filter(colAbsLog, Outcome = "created"))
                                    },
                                    With(
                                        {
                                            sk: CountRows(colAbsLog) - cr - fl - ns,
                                            nc: If(cr = 0, IfError(Patch('Absence Notices', nt, {'Status (aaca_status)': 'Status (Absence Notices)'.Cancelled, Note: "No attendance days were created (every day was skipped or failed)."}), Blank()))
                                        },
                                        If(!IsBlank(nc), IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Absence notice " & ref & " cancelled (no days created)", 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_absencenotice", 'Entity ID': Text(nc.'Absence Notice'), Before: JSON({Status: "Accepted"}), After: JSON({Status: Text(nc.'Status (aaca_status)'), Note: Coalesce(nc.Note, "")}), Reason: "Add absence created no attendance days"}), Blank()));
                                        Set(varAbsReceipt, {Kind: If(cr = 0, "Failed", "Added"), Title: "Add absence · " & stu.StudentName & " · " & Text(d0, "mmm d") & If(d1 = d0, "", " – " & Text(d1, "mmm d")) & ", " & Text(d1, "yyyy") & " · " & cr & " created, " & sk & " skipped, " & fl & " failed" & If(ns > 0, " · " & ns & " non-school day(s) ignored", "")});
                                        ClearCollect(
                                            colAbsReceiptLines,
                                            {Label: "Operation", Value: "Add absence (Source Office) with an Absence Notice"},
                                            {Label: "Student", Value: stu.StudentName & " · " & stu.StudentNumber},
                                            {Label: "Dates", Value: Text(d0, "ddd mmm d, yyyy") & If(d1 = d0, "", " – " & Text(d1, "ddd mmm d, yyyy"))},
                                            {Label: "Notice", Value: If(IsBlank(nt.'Notice At'), "no notice (billable) · " & ref, ref & " · notified " & Text(nt.'Notice At', "mm/dd/yyyy h:mm AM/PM")) & If(cr = 0, If(IsBlank(nc), " · could NOT be cancelled", " · cancelled (no days were created)"), "")},
                                            {Label: "Notice audit", Value: If(IsBlank(aun), "NOT written", "Create written")},
                                            {Label: "Classification", Value: If(cr = 0, "Nothing written", g.NewClass)},
                                            {Label: "Classified by", Value: If(cr = 0, "—", g.ByName & " · " & g.OnText)},
                                            {Label: "Note", Value: If(cr = 0, "—", g.ReasonName = "", "None", g.ReasonName)},
                                            {Label: "Created", Value: Text(cr)},
                                            {Label: "Skipped", Value: Text(sk)},
                                            {Label: "Failed", Value: Text(fl)},
                                            ForAll(Filter(colAbsLog, Outcome <> "not a school day") As g2, {Label: Text(g2.AbsDate, "ddd mmm d"), Value: If(g2.Outcome = "created", "Created · " & g2.NewClass & " · teacher " & g2.TeacherName & If(g2.OldClass = "Deleted record (reused)", " · reused deleted row", "") & If(g2.AuditOk, " · audit Create written", " · audit NOT written"), g2.Outcome = "failed", "FAILED · not written", "Skipped · " & g2.Outcome)})
                                        );
                                        If(cr > 0, Set(varAbsAddMode, ""); Set(varAbsAddClass, ""); Set(varAbsAddReasonId, Blank()); Set(varAbsNtHow, ""); Reset(cboAbsAddStuV); Reset(dpAbsAddFromV); Reset(dpAbsAddToV); Reset(rdoAbsAddClassV); Reset(ddAbsAddReasonV); Reset(txtAbsAddNoteV); Reset(rdoAbsNtHowV); Reset(dpAbsNtDateV); Reset(txtAbsNtTimeV))
                                    )
                                )
                            )
                        )
                    )
                );
                Set(varAbsSaving, false);
                If(CountRows(Filter(colAbsLog, Outcome = "created")) > 0, Select(btnAbsLoadEngine))
            )
        )
    )
)
```
Notes: the "–" and "—" characters inside the copied receipt strings already exist in today's formula; keep them as
they are (do not add new ones). If the compiler rejects `'Absence Notice': nt` (lookup type mismatch), report the
exact diagnostic; do not drop the link silently.

## Properties to Update - Mapping Errors engine and saves

E1 `btnAbsMeEngine.OnSelect` (`|-` block; replaces the whole SharePoint loader):
```
=Set(varAbsMeLoading, true);
Set(varAbsMeLoadError, "");
Set(varAbsNtSelId, Blank());
Set(varAbsMeMode, "");
Set(varAbsNtAllStu, false);
Reset(cboAbsMeStudent);
Reset(chkAbsNtAllStu);
Reset(txtAbsMeAbsDate);
Reset(txtAbsMeRetDate);
Reset(txtAbsMeDismissNote);
If(
    !CanClassify,
    Clear(colAbsMe),
    With(
        {sc: If(StudentCampusLock <> ZeroGuid, StudentCampusLock, varAbsMeCampusId)},
        IfError(
            Concurrent(
                ClearCollect(colAbsMeStuRaw, ForAll(Students As s, {StudentId: s.Student, DisplayName: Coalesce(s.'Display Name', "Unnamed student"), StudentKey: Trim(Coalesce(s.'External Client ID', "")), StatusText: Text(s.'Status (aaca_status)')})),
                ClearCollect(colAbsMeEnr, ForAll(Enrollments As e, {StudentId: e.Student.Student, CampusId: e.Campus.Campus, CampusName: Coalesce(e.Campus.Name, ""), StartDate: e.'Start Date', EndDate: e.'End Date'})),
                ClearCollect(
                    colAbsMe,
                    Filter(
                        ForAll(
                            If(
                                sc = ZeroGuid,
                                Filter('Absence Notices', 'Status (aaca_status)' = 'Status (Absence Notices)'.New),
                                Filter('Absence Notices', 'Status (aaca_status)' = 'Status (Absence Notices)'.New && Campus.Campus = sc)
                            ) As n,
                            {
                                Kind: If(
                                    Trim(Coalesce(n.'Error Detail', "")) <> "", "B",
                                    n.'Match Status' = 'Match Status (Absence Notices)'.Unmatched || n.'Match Status' = 'Match Status (Absence Notices)'.Ambiguous, "A",
                                    ""
                                ),
                                NoticeId: n.'Absence Notice',
                                Ref: Coalesce(n.Reference, "(no reference)"),
                                FirstName: Coalesce(n.'Typed First Name', ""),
                                LastName: Coalesce(n.'Typed Last Name', ""),
                                TypedCampus: Coalesce(n.'Typed Campus', ""),
                                CampusId: Coalesce(n.Campus.Campus, ZeroGuid),
                                CampusName: Coalesce(n.Campus.Name, ""),
                                StudentId: Coalesce(n.Student.Student, ZeroGuid),
                                StudentName: Coalesce(n.Student.'Display Name', ""),
                                FirstDay: n.'First Day Absent',
                                ReturnDate: n.'Return Date',
                                ReasonText: Coalesce(n.'Reason Text', ""),
                                ParentName: Coalesce(n.'Parent Name', ""),
                                Relationship: Coalesce(n.Relationship, ""),
                                NoticeAt: n.'Notice At',
                                MatchText: Coalesce(Text(n.'Match Status'), ""),
                                MatchDetail: Coalesce(n.'Match Detail', ""),
                                ErrorDetail: Coalesce(n.'Error Detail', ""),
                                Created: n.'Created On',
                                Status: ""
                            }
                        ),
                        Kind <> ""
                    )
                )
            ); true,
            Set(varAbsMeLoadError, FirstError.Message)
        )
    );
    If(varAbsMeLoadError <> "", Clear(colAbsMe));
    ClearCollect(
        colAbsMeStudents,
        ForAll(
            colAbsMeEnr As e,
            With(
                {s: LookUp(colAbsMeStuRaw, StudentId = e.StudentId)},
                {StudentId: e.StudentId, DisplayName: Coalesce(s.DisplayName, "Unnamed student"), StudentKey: Coalesce(s.StudentKey, ""), StatusText: Coalesce(s.StatusText, ""), CampusId: e.CampusId, StartDate: e.StartDate, EndDate: e.EndDate, Label: Coalesce(s.DisplayName, "Unnamed student") & " · " & If(Coalesce(s.StudentKey, "") = "", "no Student Key", s.StudentKey) & " · " & e.CampusName & " · " & Coalesce(s.StatusText, "")}
            )
        )
    )
);
Set(varAbsMeLoaded, true);
Set(varAbsMeLoading, false)
```

M1 `btnAbsMeMapSave.OnSelect` (`|-` block):
```
=With(
    {it: LookUp(colAbsMe, NoticeId = varAbsNtSelId), stu: First(cboAbsMeStudent.SelectedItems), n: CountRows(cboAbsMeStudent.SelectedItems)},
    If(
        !CanClassify || varAbsMeSaving || IsBlank(it),
        Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not saved · choose a notice with Open first", Body: ""}),
        n <> 1,
        Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not saved · pick one student", Body: "Notice " & it.Ref & " was not changed."}),
        Set(varAbsMeSaving, true);
        Set(varAbsMeErr, "");
        With(
            {
                live: With({q: it.NoticeId}, LookUp('Absence Notices', ThisRecord.'Absence Notice' = q)),
                srec: With({qs: stu.StudentId}, LookUp(Students, ThisRecord.Student = qs)),
                mdet: Left("Mapped by " & Coalesce(CurrentUserRow.'Full Name', User().FullName) & " " & Text(Now(), "m/d/yyyy h:mm AM/PM"), 1000)
            },
            If(
                IsBlank(live),
                Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not saved · notice " & it.Ref & " could not be read", Body: "Nothing was changed. It may have been deleted. Use Reload."}),
                live.'Status (aaca_status)' <> 'Status (Absence Notices)'.New,
                Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not saved · notice " & it.Ref & " is already " & Text(live.'Status (aaca_status)'), Body: "Another user or the processing flow handled it. Nothing was written, and it has been removed from this list."}); RemoveIf(colAbsMe, NoticeId = it.NoticeId); Set(varAbsNtSelId, Blank()); Set(varAbsMeMode, ""),
                IsBlank(srec),
                Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not saved · the student could not be read", Body: "Notice " & it.Ref & " was not changed. Use Reload."}),
                With(
                    {w: IfError(Patch('Absence Notices', live, {Student: srec, 'Match Status': 'Match Status (Absence Notices)'.'Mapped by office', 'Match Detail': mdet, 'Error Detail': ""}), Set(varAbsMeErr, FirstError.Message); Blank())},
                    If(
                        IsBlank(w),
                        Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not saved · notice " & it.Ref & " could not be updated", Body: "Error: " & Coalesce(varAbsMeErr, "unknown error") & Char(10) & "Nothing was changed. The notice and student are still selected; press Save mapping to retry."}),
                        With(
                            {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Absence notice " & w.Reference & " mapped to " & Coalesce(w.Student.'Display Name', stu.DisplayName), 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_absencenotice", 'Entity ID': Text(w.'Absence Notice'), Before: JSON({Student: Coalesce(live.Student.'Display Name', ""), MatchStatus: Text(live.'Match Status'), MatchDetail: Coalesce(live.'Match Detail', ""), ErrorDetail: Coalesce(live.'Error Detail', "")}), After: JSON({Student: Coalesce(w.Student.'Display Name', ""), MatchStatus: Text(w.'Match Status'), MatchDetail: Coalesce(w.'Match Detail', ""), ErrorDetail: Coalesce(w.'Error Detail', "")}), Reason: Left("Mapped in Absences, Mapping Errors: " & stu.DisplayName, 500)}), Blank())},
                            Set(
                                varAbsMeReceipt,
                                {
                                    Kind: "Mapped",
                                    Title: "Notice " & w.Reference & " mapped to " & Coalesce(w.Student.'Display Name', stu.DisplayName) & " · the days will appear shortly",
                                    Body: "Notice: " & w.Reference & " · was " & If(it.Kind = "A", "Could not match", "Could not process") & Char(10) &
                                        "Typed by parent: " & it.FirstName & " " & it.LastName & " · " & it.TypedCampus & Char(10) &
                                        "Student: " & Coalesce(w.Student.'Display Name', "") & " · " & If(stu.StudentKey = "", "no Student Key", stu.StudentKey) & Char(10) &
                                        "Match Status: " & Text(w.'Match Status') & Char(10) &
                                        "Match Detail: " & Coalesce(w.'Match Detail', "") & Char(10) &
                                        "Error Detail: " & If(Coalesce(w.'Error Detail', "") = "", "cleared", w.'Error Detail') & Char(10) &
                                        "Status: " & Text(w.'Status (aaca_status)') & Char(10) &
                                        "Audit event: " & If(IsBlank(au), "NOT written", "Update written") & Char(10) &
                                        "Next: the processing flow creates the absences (0s) within about a minute. Reload Classify absences to see them."
                                }
                            );
                            RemoveIf(colAbsMe, NoticeId = it.NoticeId);
                            Set(varAbsNtSelId, Blank());
                            Set(varAbsMeMode, "");
                            Reset(cboAbsMeStudent)
                        )
                    )
                )
            )
        );
        Set(varAbsMeSaving, false);
        If(varAbsMeReceipt.Kind = "Mapped", Select(btnAbsMeEngine))
    )
)
```

M2 `btnAbsMeDatesSave.OnSelect` (`|-` block):
```
=With(
    {it: LookUp(colAbsMe, NoticeId = varAbsNtSelId), a: IfError(DateValue(Trim(txtAbsMeAbsDate.Text), "en-US"), Blank()), r: IfError(DateValue(Trim(txtAbsMeRetDate.Text), "en-US"), Blank())},
    If(
        !CanClassify || varAbsMeSaving || IsBlank(it) || it.Kind <> "B",
        Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not saved · open a notice in Could not process first", Body: ""}),
        it.StudentId = ZeroGuid || IsBlank(a) || IsBlank(r) || r <= a || DateDiff(a, r, TimeUnit.Days) > 60,
        Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not saved · " & lblAbsMeDatesCheck.Text, Body: "Notice " & it.Ref & " was not changed."}),
        Set(varAbsMeSaving, true);
        Set(varAbsMeErr, "");
        With(
            {live: With({q: it.NoticeId}, LookUp('Absence Notices', ThisRecord.'Absence Notice' = q))},
            If(
                IsBlank(live),
                Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not saved · notice " & it.Ref & " could not be read", Body: "Nothing was changed. It may have been deleted. Use Reload."}),
                live.'Status (aaca_status)' <> 'Status (Absence Notices)'.New,
                Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not saved · notice " & it.Ref & " is already " & Text(live.'Status (aaca_status)'), Body: "Another user or the processing flow handled it. Nothing was written, and it has been removed from this list."}); RemoveIf(colAbsMe, NoticeId = it.NoticeId); Set(varAbsNtSelId, Blank()); Set(varAbsMeMode, ""),
                With(
                    {w: IfError(Patch('Absence Notices', live, {'First Day Absent': a, 'Last Day Absent': DateAdd(r, -1, TimeUnit.Days), 'Return Date': r, 'Error Detail': "", 'Match Status': 'Match Status (Absence Notices)'.'Mapped by office'}), Set(varAbsMeErr, FirstError.Message); Blank())},
                    If(
                        IsBlank(w),
                        Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not saved · notice " & it.Ref & " could not be updated", Body: "Error: " & Coalesce(varAbsMeErr, "unknown error") & Char(10) & "Nothing was changed. Press Save dates to retry."}),
                        With(
                            {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Absence notice " & w.Reference & " dates fixed", 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_absencenotice", 'Entity ID': Text(w.'Absence Notice'), Before: JSON({FirstDay: Text(live.'First Day Absent', "yyyy-mm-dd"), LastDay: Text(live.'Last Day Absent', "yyyy-mm-dd"), ReturnDate: Text(live.'Return Date', "yyyy-mm-dd"), MatchStatus: Text(live.'Match Status'), ErrorDetail: Coalesce(live.'Error Detail', "")}), After: JSON({FirstDay: Text(w.'First Day Absent', "yyyy-mm-dd"), LastDay: Text(w.'Last Day Absent', "yyyy-mm-dd"), ReturnDate: Text(w.'Return Date', "yyyy-mm-dd"), MatchStatus: Text(w.'Match Status'), ErrorDetail: Coalesce(w.'Error Detail', "")}), Reason: "Dates fixed in Absences, Mapping Errors"}), Blank())},
                            Set(
                                varAbsMeReceipt,
                                {
                                    Kind: "Dates fixed",
                                    Title: "Notice " & w.Reference & " dates saved · " & Text(w.'First Day Absent', "m/d/yyyy") & " to " & Text(w.'Last Day Absent', "m/d/yyyy") & " · the days will appear shortly",
                                    Body: "Notice: " & w.Reference & " · was Could not process" & Char(10) &
                                        "First Day Absent: " & Text(w.'First Day Absent', "m/d/yyyy") & " (was " & If(IsBlank(live.'First Day Absent'), "blank", Text(live.'First Day Absent', "m/d/yyyy")) & ")" & Char(10) &
                                        "Last Day Absent: " & Text(w.'Last Day Absent', "m/d/yyyy") & " (was " & If(IsBlank(live.'Last Day Absent'), "blank", Text(live.'Last Day Absent', "m/d/yyyy")) & ")" & Char(10) &
                                        "Return Date: " & Text(w.'Return Date', "m/d/yyyy") & " (was " & If(IsBlank(live.'Return Date'), "blank", Text(live.'Return Date', "m/d/yyyy")) & ")" & Char(10) &
                                        "Error Detail: " & If(Coalesce(w.'Error Detail', "") = "", "cleared", w.'Error Detail') & " · Match Status: " & Text(w.'Match Status') & Char(10) &
                                        "Audit event: " & If(IsBlank(au), "NOT written", "Update written") & Char(10) &
                                        "Next: the processing flow creates the absences (0s) within about a minute. Reload Classify absences to see them."
                                }
                            );
                            RemoveIf(colAbsMe, NoticeId = it.NoticeId);
                            Set(varAbsNtSelId, Blank());
                            Set(varAbsMeMode, "");
                            Reset(txtAbsMeAbsDate);
                            Reset(txtAbsMeRetDate)
                        )
                    )
                )
            )
        );
        Set(varAbsMeSaving, false);
        If(varAbsMeReceipt.Kind = "Dates fixed", Select(btnAbsMeEngine))
    )
)
```

M3 `btnAbsMeDismissSave.OnSelect` (`|-` block):
```
=With(
    {it: LookUp(colAbsMe, NoticeId = varAbsNtSelId), why: Left(Trim(txtAbsMeDismissNote.Text), 1000)},
    If(
        !CanClassify || varAbsMeSaving || IsBlank(it),
        Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not dismissed · choose a notice with Open first", Body: ""}),
        why = "",
        Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not dismissed · type why the notice is dismissed", Body: "Notice " & it.Ref & " was not changed."}),
        Set(varAbsMeSaving, true);
        Set(varAbsMeErr, "");
        With(
            {live: With({q: it.NoticeId}, LookUp('Absence Notices', ThisRecord.'Absence Notice' = q))},
            If(
                IsBlank(live),
                Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not dismissed · notice " & it.Ref & " could not be read", Body: "Nothing was changed. Use Reload."}),
                live.'Status (aaca_status)' <> 'Status (Absence Notices)'.New,
                Set(varAbsMeReceipt, {Kind: "Blocked", Title: "Not dismissed · notice " & it.Ref & " is already " & Text(live.'Status (aaca_status)'), Body: "Nothing was written, and it has been removed from this list."}); RemoveIf(colAbsMe, NoticeId = it.NoticeId); Set(varAbsNtSelId, Blank()); Set(varAbsMeMode, ""),
                With(
                    {w: IfError(Patch('Absence Notices', live, {'Status (aaca_status)': 'Status (Absence Notices)'.Dismissed, Note: why, 'Processed On': Now(), 'Processed By': CurrentUserRow}), Set(varAbsMeErr, FirstError.Message); Blank())},
                    If(
                        IsBlank(w),
                        Set(varAbsMeReceipt, {Kind: "Failed", Title: "Not dismissed · notice " & it.Ref & " could not be updated", Body: "Error: " & Coalesce(varAbsMeErr, "unknown error") & Char(10) & "Nothing was written. Press Confirm dismiss to retry."}),
                        With(
                            {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Absence notice " & w.Reference & " dismissed in Mapping Errors", 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_absencenotice", 'Entity ID': Text(w.'Absence Notice'), Before: JSON({Status: Text(live.'Status (aaca_status)'), Note: Coalesce(live.Note, ""), List: If(it.Kind = "A", "Could not match", "Could not process")}), After: JSON({Status: Text(w.'Status (aaca_status)'), Note: Coalesce(w.Note, ""), ProcessedOn: Text(w.'Processed On', "yyyy-mm-dd hh:mm"), ProcessedBy: Coalesce(w.'Processed By'.'Full Name', "")}), Reason: Left(why, 500)}), Blank())},
                            Set(
                                varAbsMeReceipt,
                                {
                                    Kind: "Dismissed",
                                    Title: "Dismissed · notice " & w.Reference,
                                    Body: "Notice: " & w.Reference & " · was " & If(it.Kind = "A", "Could not match", "Could not process") & Char(10) &
                                        "Typed by parent: " & it.FirstName & " " & it.LastName & " · " & it.TypedCampus & Char(10) &
                                        "Status: " & Text(w.'Status (aaca_status)') & Char(10) &
                                        "Note: " & Coalesce(w.Note, "") & Char(10) &
                                        "Processed: " & Text(w.'Processed On', "mm/dd/yyyy h:mm AM/PM") & " by " & Coalesce(w.'Processed By'.'Full Name', "") & Char(10) &
                                        "Attendance: not changed" & Char(10) &
                                        "Audit event: " & If(IsBlank(au), "NOT written", "Update written") & Char(10) &
                                        "The processing flow will not process this notice."
                                }
                            );
                            RemoveIf(colAbsMe, NoticeId = it.NoticeId);
                            Set(varAbsNtSelId, Blank());
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
```

## Properties to Update - Classify

C1 `btnAbsLoadEngine.OnSelect`: two insertions only, rest byte-identical.
- In the `colAbsList` record, replace the last field line `NoticeOn: r.'Notice Received On'` with:
  `NoticeOn: r.'Notice Received On', NtRef: Coalesce(r.'Absence Notice'.Reference, ""), NtParent: Coalesce(r.'Absence Notice'.'Parent Name', ""), NtRel: Coalesce(r.'Absence Notice'.Relationship, ""), NtReason: Coalesce(r.'Absence Notice'.'Reason Text', ""), NtAt: r.'Absence Notice'.'Notice At'`
- In the `colAbsCf` record, replace `NoticeOn: r.'Notice Received On',` (the line before `Locked: ...`) with:
  `NoticeOn: r.'Notice Received On', NtRef: Coalesce(r.'Absence Notice'.Reference, ""), NtParent: Coalesce(r.'Absence Notice'.'Parent Name', ""), NtRel: Coalesce(r.'Absence Notice'.Relationship, ""), NtReason: Coalesce(r.'Absence Notice'.'Reason Text', ""), NtAt: r.'Absence Notice'.'Notice At',`

C2 `lblAbsRowSrcV.Visible`: `=ThisItem.SrcText <> "" || !IsBlank(ThisItem.NoticeOn) || ThisItem.ParentReason <> "" || ThisItem.NtRef <> ""`

C3 `lblAbsRowSrcV.Text` (`|-` block; second branch = today's formula unchanged):
```
=If(
    ThisItem.NtRef <> "",
    ThisItem.SrcText & If(ThisItem.SrcText = "", "", " · ") & "Notice " & ThisItem.NtRef & If(ThisItem.NtParent = "", "", " · " & ThisItem.NtParent & If(ThisItem.NtRel = "", "", " (" & ThisItem.NtRel & ")")) & If(ThisItem.NtReason = "", "", " · " & If(Len(ThisItem.NtReason) > 80, Left(ThisItem.NtReason, 80) & "...", ThisItem.NtReason)) & If(IsBlank(ThisItem.NtAt), " · no notice", " · notified " & Text(ThisItem.NtAt, "mm/dd/yyyy h:mm AM/PM")),
    ThisItem.SrcText & If(IsBlank(ThisItem.NoticeOn), "", If(ThisItem.SrcText = "", "", " · ") & "Reported " & Text(ThisItem.NoticeOn, "mmm d, yyyy h:mm AM/PM") & " (Pacific)") & If(ThisItem.ParentReason = "", "", " · Reason: " & If(Len(ThisItem.ParentReason) > 100, Left(ThisItem.ParentReason, 100) & "…", ThisItem.ParentReason))
)
```

C4 `lblAbsCfRowMeta.Text` (`|-` block; the Else branch is today's middle part unchanged):
```
=Text(ThisItem.AbsDate, "ddd mmm d, yyyy") & " · Teacher " & ThisItem.TeacherName & " · " & If(
    ThisItem.NtRef <> "",
    "Notice " & ThisItem.NtRef & If(ThisItem.NtParent = "", "", " · " & ThisItem.NtParent & If(ThisItem.NtRel = "", "", " (" & ThisItem.NtRel & ")")) & If(ThisItem.NtReason = "", "", " · " & If(Len(ThisItem.NtReason) > 80, Left(ThisItem.NtReason, 80) & "...", ThisItem.NtReason)) & If(IsBlank(ThisItem.NtAt), " · no notice", " · notified " & Text(ThisItem.NtAt, "mm/dd/yyyy h:mm AM/PM")),
    If(ThisItem.ReportId > 0, "Parent report #" & ThisItem.ReportId, "Parent report") & If(IsBlank(ThisItem.NoticeOn), "", " · Reported " & Text(ThisItem.NoticeOn, "mmm d, yyyy h:mm AM/PM") & " (Pacific)") & With({rs: Coalesce(LookUp(colAbsCfRpt, ReportId = ThisItem.ReportId).Reason, "")}, If(rs = "", "", " · Reason: " & If(Len(rs) > 100, Left(rs, 100) & "…", rs)))
) & If(ThisItem.Locked, " · Month locked", "")
```

## Controls to Remove / Hide

None. No Mapping Errors control stays SharePoint-only after the in-place edits, so nothing needs a `Visible: false`.

## Layout and Visual Impact

- Breakpoint source: `conAbsRoot.Width` (existing) everywhere.
- Mapping rows: desktop 8 + 44 + 4 + 108 + 8 = 172 <= TemplateSize 176; phone 8 + 44 + 4 + 144 + 8 = 208 <= 212.
  Meta at 1024 (row inner ~444 px, Size 12 ~70 chars/line) fits 6 lines = ~420 chars; longest A meta ~330 chars,
  B meta ~320 (error capped 100, reason 60). Phone ~47 chars/line x 9 lines = ~420.
- `lblAbsMeFacts` 270 desktop (15 lines of ~65 chars at Size 13) / 400 phone; `conAbsMeDetail.Height` already sums
  it. Map panel 212 / 230 (58 field + 32 checkbox + 54/72 check + 44 Save + 3 x 8).
- Add panel (gap 4): absence 520 (+62 Excused, +124 Parent notified) -> max 706; leftearly 368 unchanged; the new
  controls are hidden in leftearly mode so they take no space. Longest new label "Time the parent told us *
  (h:mm AM/PM)" ~273 px <= 307 px column at 1024. Vertical radio 2 x 32 = 64.
- `lblAbsAddCheckV` stays 72 px: longest new message ~170 chars = 4 lines at ~50 chars on 307 px.
- `lblAbsRowSrcV` 36/72: notice text <= ~190 chars (reason capped 80): 2 lines of ~97 chars at 1024, 4 on phone.
- Visual contract: new labels muted 12 Semibold; inputs Outline; checkbox plain; no new colours or glyphs.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| me-identity | galAbsMeA/B row | Reference + typed name | Ref, LastName, FirstName | lblAbsMeAName / lblAbsMeBName | F1 | row top line, beside Open |
| me-campus / me-dates / me-reason / me-parent / me-noticeat / me-match | galAbsMeA row | campus, absent/back, Match + detail, Reason, Parent (Rel), notified | colAbsMe fields | lblAbsMeAMeta | F3 | under the name, always visible |
| me-error (+ same fields) | galAbsMeB row | Error, student, campus, dates, reason, parent, notified | colAbsMe fields | lblAbsMeBMeta | F4 | same |
| me-facts | conAbsMeDetail | everything in full | colAbsMe row | lblAbsMeFacts | D1 | top of detail panel |
| cls-notice | galAbsListV row | Reference, Parent (Rel), Reason, notified | colAbsList.Nt* | lblAbsRowSrcV | C3 | third line of the row |
| cf-notice | galAbsCfList row | same | colAbsCf.Nt* | lblAbsCfRowMeta | C4 | second line of the row |
| add-rcpt-notice | galAbsReceiptV line | notice ref + notified / no notice | `nt` | lblAbsRcptLabelV / lblAbsRcptValueV (existing) | "Notice" line in A4 | receipt at the top of Classify view |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| me-list | conAbsMeListPanel | `=!(conAbsRoot.Width < 1024 && !IsBlank(varAbsNtSelId))` | hidden on < 1024 while a notice is open |
| me-detail | conAbsMeDetail | `=conAbsRoot.Width >= 1024 \|\| !IsBlank(varAbsNtSelId)` | always on desktop |
| me-modebar | conAbsMeModeBar | `=!IsBlank(varAbsNtSelId)` | notice open |
| me-map | conAbsMeMapPanel | `=!IsBlank(varAbsNtSelId) && varAbsMeMode = "map"` | Map student mode |
| me-dates | conAbsMeDatesPanel | `=!IsBlank(varAbsNtSelId) && varAbsMeMode = "dates" && LookUp(colAbsMe, NoticeId = varAbsNtSelId).Kind = "B"` | Fix dates on Kind B |
| me-dismiss | conAbsMeDismissPanel | `=!IsBlank(varAbsNtSelId) && varAbsMeMode = "dismiss"` | Dismiss mode |

## Required Actions

Copied from the plan index (A-NT-LOAD, A-NT-OPEN, A-NT-CLOSE, A-NT-MAP, A-NT-DATES, A-NT-DISMISS, A-CLS-LOAD,
A-ADD-OPEN, A-ADD-SAVE, A-ADD-CANCEL). Formulas: E1, F2, D2, M1, M2, M3, C1, A1, A4, A2.

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-NT-MAP | 1 student picked; live Status New | `btnAbsMeMapSave.OnSelect` (M1) | `varAbsNtSelId` -> live notice -> `w.'Absence Notice'` | Patch; audit Update; RemoveIf + reload | Student, Match Status, Match Detail, Error Detail | Title + Body (Student, Match Status, Match Detail, Error Detail, Status, Audit) from `w` | `conAbsMeReceipt`; row gone; tab count |
| A-NT-DATES | Kind B; student set; Ready gate; live New | `btnAbsMeDatesSave.OnSelect` (M2) | same | Patch; audit; RemoveIf + reload | First/Last Day, Return Date, Error Detail, Match Status | Body lines from `w` with "was" values from `live` | `conAbsMeReceipt` |
| A-NT-DISMISS | reason; live New | `btnAbsMeDismissSave.OnSelect` (M3) | same | Patch; audit; RemoveIf | Status, Note, Processed On, Processed By | Body from `w` | `conAbsMeReceipt` |
| A-ADD-SAVE | Ready gate incl. How + notice time not future | `btnAbsAddSaveV.OnSelect` (A4) | new notice `nt`; days `wr.Attendance` | notice create (stop on failure) -> days linked -> cancel notice if 0 days | see plan Mutation Field Ledger | Notice line, Notice audit, per-day "notice linked" | `conAbsReceiptV`; classify rows |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| rdoAbsNtHowV | lblAbsNtHowV `="How did we hear about it? *"` (same Visible) | conAbsAddPanelV |
| dpAbsNtDateV | lblAbsNtDateV `="Date the parent told us *"` (same Visible) | conAbsAddPanelV |
| txtAbsNtTimeV | lblAbsNtTimeV `="Time the parent told us * (h:mm AM/PM)"` (same Visible) | conAbsAddPanelV |
| txtAbsMeAbsDate | lblAbsMeAbsDate `="First Day Absent * (M/D/YYYY)"` | conAbsMeAbsField |
| txtAbsMeRetDate | lblAbsMeRetDate `="Return Date * (day back, M/D/YYYY)"` | conAbsMeRetField |
| cboAbsMeStudent / txtAbsMeDismissNote | unchanged labels | unchanged |

## Mutation Lifecycle Evidence / Field Ledger

As in the plan index (rows A-NT-MAP, A-NT-DATES, A-NT-DISMISS, A-ADD-SAVE). Key traces: `varAbsNtSelId` =
colAbsMe.NoticeId = `live.'Absence Notice'` = `w.'Absence Notice'` = audit `'Entity ID'`; Add absence:
`nt.'Absence Notice'` = notice audit Entity ID, and every created day `wr.'Absence Notice'` = `nt`.

## Functional Test Scenarios

Owned: S-ME-LIST, S-ME-CAMPUS, S-ME-OPEN, S-ME-MAP-PREFILTER, S-ME-MAP, S-ME-MAP-STALE, S-ME-DATES,
S-ME-DATES-INVALID, S-ME-DISMISS, S-ME-DISMISS-INVALID, S-CLS-NOTICE, S-CLS-REGRESSION, S-ADD-HOW-INVALID,
S-ADD-NOTIFIED, S-ADD-NONOTICE, S-ADD-ALLSKIPPED, S-ADD-NOTICE-FAIL, S-LE-REGRESSION (rows and fixtures in the plan
index). Key expectations:
- S-ME-LIST: ABS-2026-001000 under "Could not match (1)"; tab reads "Mapping Errors (n)" without touching the tab.
- S-ME-MAP: notice Student = McTestface, Testy, Match Status Mapped by office, Match Detail "Mapped by <name>
  <m/d/yyyy h:mm AM/PM>", Error Detail blank, Status New; audit Update; list reloads without it.
- S-ADD-NOTIFIED: one Accepted Office notice + linked days with Notice Received On = Notice At; receipt line
  "Notice · ABS-... · notified 10/07/2026 7:45 AM".
- S-ADD-NONOTICE: receipt "no notice (billable) · ABS-...".
- S-LE-REGRESSION: in Left early mode none of N2-N7 shows; Left early save unchanged.

## Relevant Data Source Schemas

- 'Absence Notices': `'Absence Notice'` (GUID PK), Summary, Reference (read-only autonumber), Source
  ('Source (Absence Notices)'), `'Status (aaca_status)'` ('Status (Absence Notices)'), 'Match Status' ('Match Status
  (Absence Notices)'), 'Match Detail', 'Error Detail', 'First Day Absent' (Date), 'Last Day Absent' (Date), 'Return
  Date' (Date), 'Notice At' (DateTime), 'Typed First Name', 'Typed Last Name', 'Typed Campus', 'Parent Name',
  Relationship, 'Reason Text', Note, 'Processed On' (DateTime), 'Processed By' (Users), Student (Students), Campus
  (Campuses), 'Absence Reason' ('Absence Reasons'), 'Created On'.
- Attendance: existing columns + 'Absence Notice' (lookup to Absence Notices), 'Notice Received On' (DateTime).
- Students: Student (PK), 'Display Name', 'External Client ID' (Student Key), 'Status (aaca_status)'.
- Enrollments: Student, Campus (+Name), 'Start Date', 'End Date' (plus build 9 fields used by the day loop).
- Campuses: Campus (PK), Name. Users: 'Full Name' (CurrentUserRow).
- 'Audit Events': Summary, Action, Entity, 'Entity ID', Before, After, Reason.

## Changed or Added Control Definitions

(Only properties this edit sets; all types already exist on this screen.)

- ModernCheckbox (`Control: ModernCheckbox`): AccessibleLabel, AlignInContainer [AlignInContainer], Default,
  DisplayMode [DisplayMode], FillPortions, Height, Label, LayoutMinHeight, LayoutMinWidth, OnCheck, OnUncheck.
- ModernRadio (`Control: ModernRadio`): AccessibleLabel, AlignInContainer, Color, Default, DisplayMode, FillPortions,
  Height, Items, Layout [OptionLayout], LayoutMinHeight, LayoutMinWidth, OnChange, Visible. Output `Selected`.
- ModernDatePicker (`Control: ModernDatePicker`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  DefaultDate, DisplayMode, EndDate, FillPortions, Format [DatePickerFormat], Height, LayoutMinHeight,
  LayoutMinWidth, StartDate, Visible. Output `SelectedDate`.
- ModernTextInput (`Control: ModernTextInput`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  Default, DisplayMode, FillPortions, Height, LayoutMinHeight, LayoutMinWidth, MaxLength, Placeholder, Visible.
  Output `Text`.
- ModernText (`Control: ModernText`): AccessibleLabel, AlignInContainer, Color, FillPortions, FontWeight
  [FontWeight], Height, LayoutMinHeight, LayoutMinWidth, PaddingBottom/Left/Right/Top, Size, Text, VerticalAlign,
  Visible, Wrap.
- ModernCombobox / ModernButton / Gallery / GroupContainer / Classic/Button: only existing properties are edited
  (Items, Text, AccessibleLabel, DisplayMode, OnSelect, Height, TemplateSize, Fill, Visible).

Compile-ready enum literals used by new/changed properties: `OptionLayout.Vertical`, `Appearance.Outline`,
`DatePickerFormat.Short`, `DisplayMode.Edit`, `DisplayMode.Disabled`, `AlignInContainer.Stretch`,
`FontWeight.Semibold`, `SortOrder.Descending`, `SortOrder.Ascending`, `TimeUnit.Days`.

YAML: `rdoAbsNtHowV.Default` (`={Value: varAbsNtHow}`) and every formula above containing `: ` are `|-` blocks.
Formulas F1, F2, D2, A1 contain no `: ` but may be written as `|-` blocks too.
