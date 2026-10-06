# Screen Plan: Absences (build 9 - Add absence, Left early, Transportation nav)

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml`
- YAML key: AbsencesScreen
- Control name prefix: Abs (new controls `…AbsAdd…V`, `…AbsLe…V`, `btnAbsNavTransport`, `btnAbsAddLoadEngine`)

Read `canvas-app-shared.md` first. HARD RULES: do not rename, move or delete any existing control. Only the property
edits listed below change existing controls. Screen App Checker complexity is already 311: add nothing beyond this list.

## Current State

- Root `conAbsRoot` (scroll). Header `conAbsHeader` (Ink, no side padding) -> `lblAbsTitle`, `lblAbsIdentity`,
  `conAbsNav` (Attendance / Students / Absences), `conAbsHdrTabs` (Classify absences / Mapping Errors).
- Classify view `conAbsClassifyView` -> notice, spinner, receipt `conAbsReceiptV` (varAbsReceipt + colAbsReceiptLines
  via `galAbsReceiptV`), `conAbsCfPanel`, body `conAbsBodyV` = list `conAbsListPanelV` (FillPortions 2) + right-hand
  detail column `conAbsDecideV` (FillPortions 1; "Mark as Excused": `lblAbsDecideTitleV`, `lblAbsDecideEmptyV`,
  `lblAbsDecideWhoV`, `conAbsReasonFieldV`, `lblAbsDecideCheckV`, `conAbsDecideActionsV`).
- Engines at root: `btnAbsLoadEngine`, `btnAbsClassifyEngine`, `btnAbsMeEngine` (hidden Classic/Button).

## Changes

1. Nav: append `btnAbsNavTransport` to `conAbsNav`; make the nav wrap; grow header on phone.
2. Detail column `conAbsDecideV`: append NEW `conAbsAddBarV` (Add absence / Left early) and NEW `conAbsAddPanelV`
   (shared form, two modes) AFTER `conAbsDecideActionsV`; update the column's Title/Height/Visible.
3. Root: append NEW hidden engine `btnAbsAddLoadEngine` after `btnAbsMeEngine`.
4. Small property edits: `OnVisible`, `ddAbsCampusV.OnChange`, `conAbsListPanelV.Visible`,
   `lblAbsDecideEmptyV.Visible`.

## Properties to Update

| Control | Property | Exact new value |
| --- | --- | --- |
| AbsencesScreen | OnVisible | insert `Set(varAbsAddMode, "");` as a new line directly after `Set(varAbsReasonId, Blank());` (rest unchanged) |
| conAbsHeader | Height | `=If(conAbsRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conAbsRoot.Width < 640, 100, 48), 0) + If(CanClassify, 60, 0)` |
| conAbsNav | Height | `=If(conAbsRoot.Width < 640, 96, 44) + If(CanClassify, 8, 0)` |
| conAbsNav | LayoutWrap (new property) | `=true` |
| ddAbsCampusV | OnChange | `=Set(varAbsCampusId, Coalesce(Self.Selected.CampusId, ZeroGuid)); Set(varAbsTeacherId, ZeroGuid); Set(varAbsAddMode, ""); Reset(ddAbsTeacherV); Select(btnAbsLoadEngine)` |
| conAbsListPanelV | Visible | `=!(conAbsRoot.Width < 1024 && (!IsBlank(varAbsSelId) \|\| varAbsAddMode <> ""))` (write with a plain `\|\|`, not escaped) |
| conAbsDecideV | Visible | `=CanClassify` |
| conAbsDecideV | Height | `=16 + If(!IsBlank(varAbsSelId), 28 + 8 + 72 + 8 + 22 + Max(36, CountRows(colAbsReasons) * 32) + 8 + 36 + 8 + 44, 28 + If(varAbsAddMode = "", 8 + 60, 0) + 8 + 44 + If(varAbsAddMode = "leftearly", 8 + 368, varAbsAddMode = "absence", 8 + If(varAbsAddClass = "Excused", 492, 430), 0)) + 16` |
| lblAbsDecideTitleV | Text | `=If(!IsBlank(varAbsSelId), "Mark as Excused", varAbsAddMode = "absence", "Add absence", varAbsAddMode = "leftearly", "Left early", "Mark as Excused")` |
| lblAbsDecideTitleV | AccessibleLabel | `=Self.Text` |
| lblAbsDecideEmptyV | Visible | `=IsBlank(varAbsSelId) && varAbsAddMode = ""` |

Everything else on existing controls stays byte-identical.

## Controls to Add

### A. `btnAbsNavTransport` (ModernButton) - last child of `conAbsNav`

AccessibleLabel `="Go to Transportation"`, AlignInContainer `=AlignInContainer.Center`, Appearance
`=ButtonAppearance.Secondary`, Color `=ColorInk`, Height `=44`, Layout `=ButtonLayout.TextOnly`, LayoutMinHeight `=0`,
LayoutMinWidth `=0`, OnSelect `=Navigate(TransportScreen)`, Size `=14`, Text `="Transportation"`, Visible
`=CanClassify`, Width `=140`.

### B. `conAbsAddBarV` (GroupContainer AutoLayout) - child of `conAbsDecideV`, after `conAbsDecideActionsV`

DropShadow None, FillPortions `=0`, Height `=44`, LayoutAlignItems Center, LayoutDirection Horizontal, LayoutGap `=8`,
LayoutMinHeight/Width `=0`, Radius* `=0`, Visible `=CanClassify && IsBlank(varAbsSelId)`. Children:

- `btnAbsAddOpenV` (ModernButton): Text `="Add absence"`, Width `=130`, AccessibleLabel
  `="Add absence" & If(varAbsAddMode = "absence", " (open)", "")`, Appearance
  `=If(varAbsAddMode = "absence", ButtonAppearance.Primary, ButtonAppearance.Secondary)`, BasePaletteColor `=ColorTeal`,
  Color `=If(varAbsAddMode = "absence", ColorWhite, ColorInk)`, DisplayMode
  `=If(CanClassify && !varAbsSaving && !varAbsLoading && varAbsCampusId <> ZeroGuid, DisplayMode.Edit, DisplayMode.Disabled)`,
  OnSelect:
  ```
  =Set(varAbsSelId, Blank());
  Set(varAbsReasonId, Blank());
  Reset(rdoAbsReasonV);
  Set(varAbsAddMode, "absence");
  Set(varAbsAddClass, "");
  Set(varAbsAddReasonId, Blank());
  Reset(cboAbsAddStuV); Reset(dpAbsAddFromV); Reset(dpAbsAddToV); Reset(rdoAbsAddClassV); Reset(ddAbsAddReasonV); Reset(txtAbsAddNoteV); Reset(txtAbsLeTimeV);
  Select(btnAbsAddLoadEngine)
  ```
- `btnAbsLeOpenV` (ModernButton): same as above with `"leftearly"` / Text `="Left early"` / Width `=110` /
  AccessibleLabel `="Left early" & If(varAbsAddMode = "leftearly", " (open)", "")`.

Both: Height 44, Layout TextOnly, Size 14, LayoutMin* 0, AlignInContainer Center.

### C. `conAbsAddPanelV` (GroupContainer AutoLayout) - child of `conAbsDecideV`, after `conAbsAddBarV`

DropShadow None, FillPortions `=0`, Height `=If(varAbsAddMode = "leftearly", 368, varAbsAddClass = "Excused", 492, 430)`,
LayoutAlignItems Stretch, LayoutDirection Vertical, LayoutGap `=4`, LayoutMinHeight/Width `=0`, Radius* `=0`,
Visible `=CanClassify && IsBlank(varAbsSelId) && varAbsAddMode in ["absence", "leftearly"]`.

Children in this order (labels: ModernText Size 12 Semibold `ColorMuted`, Height 18, Wrap false, Padding* 0,
AlignInContainer Stretch, AccessibleLabel = their text; inputs: Height 36, Appearance `=Appearance.Outline`,
Color `=ColorInk`, AlignInContainer Stretch, LayoutMin* 0, DisplayMode
`=If(varAbsSaving, DisplayMode.Disabled, DisplayMode.Edit)`):

| # | Control | Type | Key properties | Visible |
| - | ------- | ---- | -------------- | ------- |
| 1 | lblAbsAddStuV | ModernText | Text `="Student *"` | (panel) |
| 2 | cboAbsAddStuV | ModernCombobox | AccessibleLabel `="Student"`, Items `=colAbsAddStu`, ItemDisplayText `=ThisItem.Label`, SelectMultiple `=false`, DefaultSelectedItems `=[]`, InputTextPlaceholder `="Type a name or student number"` | (panel) |
| 3 | lblAbsAddFromV | ModernText | Text `=If(varAbsAddMode = "leftearly", "Date *", "From date *")` | (panel) |
| 4 | dpAbsAddFromV | ModernDatePicker | AccessibleLabel `=If(varAbsAddMode = "leftearly", "Date", "From date")`, DefaultDate `=Today()`, StartDate `=Date(FirstSchoolYear, 1, 1)`, EndDate `=If(varAbsAddMode = "leftearly", Today(), DateAdd(Today(), 90, TimeUnit.Days))`, Format `=DatePickerFormat.Short` | (panel) |
| 5 | lblAbsAddToV | ModernText | Text `="To date (blank = same day)"` | `=varAbsAddMode = "absence"` |
| 6 | dpAbsAddToV | ModernDatePicker | AccessibleLabel `="To date"`, DefaultDate `=Blank()`, StartDate `=Date(FirstSchoolYear, 1, 1)`, EndDate `=DateAdd(Today(), 90, TimeUnit.Days)`, Format Short | `=varAbsAddMode = "absence"` |
| 7 | lblAbsAddClassV | ModernText | Text `="Classification *"` | `=varAbsAddMode = "absence"` |
| 8 | rdoAbsAddClassV | ModernRadio | AccessibleLabel `="Classification"`, Items `=["Excused", "Unexcused"]`, Default (block) `={Value: varAbsAddClass}`, Layout `=OptionLayout.Horizontal`, OnChange `=Set(varAbsAddClass, Self.Selected.Value); If(Self.Selected.Value <> "Excused", Set(varAbsAddReasonId, Blank()))` (no Appearance) | `=varAbsAddMode = "absence"` |
| 9 | lblAbsAddReasonV | ModernText | Text `="Absence reason *"` | `=varAbsAddMode = "absence" && varAbsAddClass = "Excused"` |
| 10 | ddAbsAddReasonV | ModernDropdown | AccessibleLabel `="Absence reason"`, Items `=colAbsReasons`, ItemDisplayText `=ThisItem.ReasonName`, Default `=LookUp(colAbsReasons, ReasonId = varAbsAddReasonId)`, OnChange `=Set(varAbsAddReasonId, Self.Selected.ReasonId)` | same as 9 |
| 11 | lblAbsLeTimeV | ModernText | Text `="Time left * (h:mm AM/PM)"` | `=varAbsAddMode = "leftearly"` |
| 12 | txtAbsLeTimeV | ModernTextInput | AccessibleLabel `="Time left, h:mm AM/PM"`, Placeholder `="1:30 PM"`, MaxLength `=8`, Default `=""` | `=varAbsAddMode = "leftearly"` |
| 13 | lblAbsAddNoteV | ModernText | Text `=If(varAbsAddMode = "leftearly", "Reason *", "Note (optional)")` | (panel) |
| 14 | txtAbsAddNoteV | ModernTextInput | AccessibleLabel `=If(varAbsAddMode = "leftearly", "Reason left early", "Note")`, Placeholder `=If(varAbsAddMode = "leftearly", "e.g. sick, picked up by parent", "e.g. no call from the family")`, MaxLength `=If(varAbsAddMode = "leftearly", 500, 2000)`, Default `=""` | (panel) |
| 15 | lblAbsAddCheckV | ModernText | Height `=72`, Size 12, FontWeight Normal, Color `=If(StartsWith(Self.Text, "Ready"), ColorExcused, ColorUnexcused)`, VerticalAlign Top, Wrap default (true), Text below | (panel) |
| 16 | conAbsAddActionsV | GroupContainer | horizontal, Height 44, gap 8, LayoutAlignItems Center, FillPortions 0, LayoutMin* 0, DropShadow None | (panel) |

`lblAbsAddCheckV.Text`:
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
        {n: CountRows(cboAbsAddStuV.SelectedItems), d0: dpAbsAddFromV.SelectedDate, d1: Coalesce(dpAbsAddToV.SelectedDate, dpAbsAddFromV.SelectedDate)},
        If(
            varAbsAddErr <> "", "Could not load students: " & varAbsAddErr,
            n <> 1, "Pick the student.",
            IsBlank(d0), "Choose the From date.",
            d1 < d0, "The To date must be on or after the From date.",
            d1 > DateAdd(Today(), 90, TimeUnit.Days), "The To date can be at most 90 days ahead.",
            DateDiff(d0, d1, TimeUnit.Days) > 60, "Choose at most 61 days at a time.",
            !(varAbsAddClass in ["Excused", "Unexcused"]), "Choose Excused or Unexcused.",
            varAbsAddClass = "Excused" && IsBlank(LookUp(colAbsReasons, ReasonId = varAbsAddReasonId)), "Excused needs an absence reason.",
            "Ready: Save absence adds a 0 (" & varAbsAddClass & ") for each school day from " & Text(d0, "mmm d") & " to " & Text(d1, "mmm d") & ". Days already marked are skipped and listed."
        )
    )
)
```

`conAbsAddActionsV` children (ModernButton, Height 44, TextOnly, Size 14, LayoutMin* 0, AlignInContainer Center):
- `btnAbsAddSaveV`: Text `="Save absence"`, Width `=150`, AccessibleLabel `="Save absence"`, BasePaletteColor
  `=ColorTeal`, Color `=ColorWhite`, Visible `=varAbsAddMode = "absence"`, DisplayMode
  `=If(CanClassify && varAbsAddMode = "absence" && !varAbsSaving && !varAbsLoading && StartsWith(lblAbsAddCheckV.Text, "Ready"), DisplayMode.Edit, DisplayMode.Disabled)`,
  OnSelect = formula F1 below.
- `btnAbsLeSaveV`: Text `="Save left early"`, Width `=150`, same styling, Visible `=varAbsAddMode = "leftearly"`,
  DisplayMode same with `"leftearly"`, OnSelect = formula F2 below.
- `btnAbsAddCancelV`: Text `="Cancel"`, Width `=100`, Appearance Secondary, Color `=ColorInk`, AccessibleLabel
  `="Cancel without saving"`, DisplayMode `=If(varAbsSaving, DisplayMode.Disabled, DisplayMode.Edit)`, OnSelect:
  ```
  =Set(varAbsReceipt, {Kind: "Cancelled", Title: If(varAbsAddMode = "leftearly", "Left early", "Add absence") & " cancelled · nothing was changed"});
  Clear(colAbsReceiptLines);
  Set(varAbsAddMode, ""); Set(varAbsAddClass, ""); Set(varAbsAddReasonId, Blank());
  Reset(cboAbsAddStuV); Reset(dpAbsAddFromV); Reset(dpAbsAddToV); Reset(rdoAbsAddClassV); Reset(ddAbsAddReasonV); Reset(txtAbsAddNoteV); Reset(txtAbsLeTimeV)
  ```

### D. `btnAbsAddLoadEngine` (Classic/Button) - root child of `conAbsRoot`, after `btnAbsMeEngine`

AlignInContainer Stretch, AutoDisableOnSelect `=false`, LayoutMinHeight/Width `=0`, Text `="add load"`, Visible `=false`,
OnSelect:
```
=Set(varAbsAddErr, "");
IfError(
    With(
        {c0: varAbsCampusId},
        ClearCollect(
            colAbsAddEnr,
            ForAll(
                Filter(Enrollments, Campus.Campus = c0) As e,
                {EnrId: e.Enrollment, StudentId: e.Student.Student, StudentName: Coalesce(e.Student.'Display Name', "Unnamed student"), StudentNumber: Coalesce(e.Student.'Student Number', ""), ServiceId: e.Service.Service, ServiceCode: Coalesce(e.Service.'Service Code', "SPED"), TeacherName: Coalesce(e.Teacher.Name, "No teacher"), StartDate: e.'Start Date', EndDate: e.'End Date', EnrRec: e}
            )
        )
    ); true,
    Set(varAbsAddErr, FirstError.Message)
);
ClearCollect(
    colAbsAddStu,
    Sort(
        ForAll(
            Distinct(Filter(colAbsAddEnr, IsBlank(EndDate) || EndDate >= DateAdd(Today(), -365, TimeUnit.Days)), StudentId) As g,
            With({en: First(Sort(Filter(colAbsAddEnr, StudentId = g.Value), StartDate, SortOrder.Descending))}, {StudentId: g.Value, StudentName: en.StudentName, StudentNumber: en.StudentNumber, Label: en.StudentName & " · " & en.StudentNumber})
        ),
        StudentName,
        SortOrder.Ascending
    )
)
```

### F1. `btnAbsAddSaveV.OnSelect` (Add absence)

```
=With(
    {
        stu: First(cboAbsAddStuV.SelectedItems),
        d0: dpAbsAddFromV.SelectedDate,
        d1: Coalesce(dpAbsAddToV.SelectedDate, dpAbsAddFromV.SelectedDate),
        cls: varAbsAddClass,
        rsn: With({qr: varAbsAddReasonId}, LookUp('Absence Reasons', ThisRecord.'Absence Reason' = qr && Active = true)),
        note: Left(Trim(txtAbsAddNoteV.Text), 2000),
        c0: varAbsCampusId
    },
    If(
        !CanClassify || varAbsSaving || varAbsLoading || varAbsAddMode <> "absence",
        Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved. Only the Attendance Office and System Admin can add absences, and not while saving or loading."}); Clear(colAbsReceiptLines),
        CountRows(cboAbsAddStuV.SelectedItems) <> 1 || IsBlank(d0) || d1 < d0 || d1 > DateAdd(Today(), 90, TimeUnit.Days) || DateDiff(d0, d1, TimeUnit.Days) > 60 || !(cls in ["Excused", "Unexcused"]) || (cls = "Excused" && IsBlank(rsn)),
        Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved. " & lblAbsAddCheckV.Text}); Clear(colAbsReceiptLines),
        Set(varAbsSaving, true);
        Clear(colAbsLog);
        IfError(
            Concurrent(
                ClearCollect(colAbsLocks, ForAll(Filter('Month Locks', 'Status (aaca_status)' = 'Status (Month Locks)'.Locked) As m, {CampusId: m.Campus.Campus, MonthStart: m.Month})),
                ClearCollect(colAbsAddTerms, Filter(Terms, 'Start Date' <= d1 && 'End Date' >= d0)),
                ClearCollect(colAbsAddExc, Filter('Calendar Exceptions', Date >= d0 && Date <= d1))
            ); true,
            Set(varAbsAddErr, FirstError.Message)
        );
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
                                                        'Notice Received On': Blank(),
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
                                        {au: If(!IsBlank(wr), IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Office absence " & wr.'Record Key', 100), Action: 'Action (Audit Events)'.Create, Entity: "aaca_attendance", 'Entity ID': Text(wr.Attendance), Before: If(IsBlank(live), "", JSON({IsDeleted: true, Present: live.Present})), After: JSON({Present: wr.Present, Source: Text(wr.Source), Classification: Text(wr.'Absence Classification'), Reason: Coalesce(wr.'Absence Reason'.Name, ""), Notes: Coalesce(wr.Notes, "")}), Reason: "Manual absence added in Absences (no parent notice)"}), Blank()))},
                                        Collect(colAbsLog, {AttId: Coalesce(wr.Attendance, live.Attendance, ZeroGuid), StudentName: stu.StudentName, AbsDate: d, TeacherName: Coalesce(seg.TeacherName, ""), CampusName: "", OldClass: If(IsBlank(live), "No record", "Deleted record (reused)"), NewClass: If(IsBlank(wr), "", Text(wr.'Absence Classification') & If(IsBlank(wr.'Absence Reason'), "", " (" & wr.'Absence Reason'.Name & ")")), ReasonName: If(IsBlank(wr), "", Coalesce(wr.Notes, "")), ByName: If(IsBlank(wr), "", Coalesce(wr.'Classified By'.'Full Name', "")), OnText: If(IsBlank(wr), "", Text(wr.'Classified On', "mmm d, yyyy h:mm AM/PM")), Outcome: If(!IsBlank(wr), "created", outcome = "ok", "failed", outcome), AuditOk: !IsBlank(au)})
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
                {sk: CountRows(colAbsLog) - cr - fl - ns},
                Set(varAbsReceipt, {Kind: If(cr = 0, "Failed", "Added"), Title: "Add absence · " & stu.StudentName & " · " & Text(d0, "mmm d") & If(d1 = d0, "", " – " & Text(d1, "mmm d")) & ", " & Text(d1, "yyyy") & " · " & cr & " created, " & sk & " skipped, " & fl & " failed" & If(ns > 0, " · " & ns & " non-school day(s) ignored", "")});
                ClearCollect(
                    colAbsReceiptLines,
                    {Label: "Operation", Value: "Add absence (Source Office, no parent notice)"},
                    {Label: "Student", Value: stu.StudentName & " · " & stu.StudentNumber},
                    {Label: "Dates", Value: Text(d0, "ddd mmm d, yyyy") & If(d1 = d0, "", " – " & Text(d1, "ddd mmm d, yyyy"))},
                    {Label: "Classification", Value: If(cr = 0, "Nothing written", g.NewClass)},
                    {Label: "Classified by", Value: If(cr = 0, "—", g.ByName & " · " & g.OnText)},
                    {Label: "Note", Value: If(cr = 0, "—", g.ReasonName = "", "None", g.ReasonName)},
                    {Label: "Created", Value: Text(cr)},
                    {Label: "Skipped", Value: Text(sk)},
                    {Label: "Failed", Value: Text(fl)},
                    ForAll(Filter(colAbsLog, Outcome <> "not a school day") As g2, {Label: Text(g2.AbsDate, "ddd mmm d"), Value: If(g2.Outcome = "created", "Created · " & g2.NewClass & " · teacher " & g2.TeacherName & If(g2.OldClass = "Deleted record (reused)", " · reused deleted row", "") & If(g2.AuditOk, " · audit Create written", " · audit NOT written"), g2.Outcome = "failed", "FAILED · not written", "Skipped · " & g2.Outcome)})
                );
                If(cr > 0, Set(varAbsAddMode, ""); Set(varAbsAddClass, ""); Set(varAbsAddReasonId, Blank()); Reset(cboAbsAddStuV); Reset(dpAbsAddFromV); Reset(dpAbsAddToV); Reset(rdoAbsAddClassV); Reset(ddAbsAddReasonV); Reset(txtAbsAddNoteV))
            )
        );
        Set(varAbsSaving, false);
        If(CountRows(Filter(colAbsLog, Outcome = "created")) > 0, Select(btnAbsLoadEngine))
    )
)
```

Notes: `colAbsLog.ReasonName` carries the written Notes for this flow (no schema change). Every Collect supplies all
12 colAbsLog fields. `colAbsAddTerms` / `colAbsAddExc` are new screen collections defined by these ClearCollects.

### F2. `btnAbsLeSaveV.OnSelect` (Left early)

```
=With(
    {
        stu: First(cboAbsAddStuV.SelectedItems),
        d: dpAbsAddFromV.SelectedDate,
        tt: Trim(txtAbsLeTimeV.Text),
        why: Left(Trim(txtAbsAddNoteV.Text), 500),
        c0: varAbsCampusId
    },
    With(
        {tm: If(EndsWith(Upper(tt), "AM") || EndsWith(Upper(tt), "PM"), IfError(TimeValue(tt, "en-US"), Blank()), Blank())},
        With(
            {
                at: If(IsBlank(tm) || IsBlank(d), Blank(), DateTime(Year(d), Month(d), Day(d), Hour(tm), Minute(tm), 0)),
                seg: First(Sort(Filter(colAbsAddEnr, StudentId = stu.StudentId && StartDate <= d && (IsBlank(EndDate) || EndDate >= d)), StartDate, SortOrder.Descending)),
                dt: Text(d, "ddd mmm d, yyyy")
            },
            If(
                !CanClassify || varAbsSaving || varAbsLoading || varAbsAddMode <> "leftearly",
                Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved. Only the Attendance Office and System Admin can record left early, and not while saving or loading."}); Clear(colAbsReceiptLines),
                CountRows(cboAbsAddStuV.SelectedItems) <> 1 || IsBlank(d) || d > Today() || IsBlank(at) || at > Now() || why = "",
                Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved. " & lblAbsAddCheckV.Text}); Clear(colAbsReceiptLines),
                IsBlank(seg),
                Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved · " & stu.StudentName & " · " & dt & " · not enrolled at this campus on that day"}); Clear(colAbsReceiptLines),
                Set(varAbsSaving, true);
                IfError(
                    Concurrent(
                        ClearCollect(colAbsAddTerms, Filter(Terms, 'Start Date' <= d && 'End Date' >= d)),
                        ClearCollect(colAbsAddExc, Filter('Calendar Exceptions', Date = d))
                    ); true,
                    Set(varAbsAddErr, FirstError.Message)
                );
                With(
                    {
                        t: First(Filter(colAbsAddTerms, IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = c0)),
                        x: LookUp(colAbsAddExc, (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = c0) && ThisRecord.Type <> 'Type (Calendar Exceptions)'.'Make-up School Day'),
                        mk: !IsBlank(LookUp(colAbsAddExc, (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = c0) && ThisRecord.Type = 'Type (Calendar Exceptions)'.'Make-up School Day')),
                        lk: With({ms: Date(Year(d), Month(d), 1)}, LookUp('Month Locks', Campus.Campus = c0 && Month = ms && 'Status (aaca_status)' = 'Status (Month Locks)'.Locked)),
                        live: With({qs: stu.StudentId, qv: seg.ServiceId, qd: d}, LookUp(Attendance, Student.Student = qs && Service.Service = qv && Date = qd))
                    },
                    With(
                        {
                            school: !IsBlank(t) && (mk || (Weekday(d, StartOfWeek.Monday) < 6 && IsBlank(x))),
                            active: !IsBlank(live) && live.'Is Deleted' <> true
                        },
                        If(
                            !school,
                            Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved · " & stu.StudentName & " · " & dt & " · not a school day at this campus"}); Clear(colAbsReceiptLines),
                            !IsBlank(lk),
                            Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved · " & stu.StudentName & " · " & dt & " · the month is locked for this campus"}); Clear(colAbsReceiptLines),
                            active && live.Present <> true,
                            Set(varAbsReceipt, {Kind: "Blocked", Title: "Not saved · " & stu.StudentName & " · " & dt & " · the day is marked absent; left early is only for present days"}); Clear(colAbsReceiptLines),
                            With(
                                {
                                    w: IfError(
                                        If(
                                            active,
                                            Patch(Attendance, live, {'Left Early': true, 'Left Early At': at, 'Left Early Reason': why}),
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
                                                    Present: true,
                                                    'Is Deleted': false,
                                                    Source: 'Source (Attendance)'.Office,
                                                    'Absence Classification': Blank(),
                                                    'Absence Reason': Blank(),
                                                    'Classified By': Blank(),
                                                    'Classified On': Blank(),
                                                    'Parent Reported Absent': false,
                                                    'Source Report ID': Blank(),
                                                    'Notice Received On': Blank(),
                                                    'Left Early': true,
                                                    'Left Early At': at,
                                                    'Left Early Reason': why
                                                }
                                            )
                                        ),
                                        Blank()
                                    )
                                },
                                If(
                                    IsBlank(w),
                                    Set(varAbsReceipt, {Kind: "Failed", Title: "Not saved · " & stu.StudentName & " · " & dt & " · the save failed; press Save left early to retry"}); Clear(colAbsReceiptLines),
                                    With(
                                        {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Left early " & w.'Record Key' & " " & Text(w.'Left Early At', "h:mm AM/PM"), 100), Action: If(active, 'Action (Audit Events)'.Update, 'Action (Audit Events)'.Create), Entity: "aaca_attendance", 'Entity ID': Text(w.Attendance), Before: If(active, JSON({Present: live.Present, LeftEarly: live.'Left Early' = true, Source: Text(live.Source)}), IsBlank(live), "", JSON({IsDeleted: true})), After: JSON({Present: w.Present, LeftEarly: w.'Left Early', LeftEarlyAt: Text(w.'Left Early At', "yyyy-mm-dd hh:mm"), Source: Text(w.Source)}), Reason: Left(why, 500)}), Blank())},
                                        Set(varAbsReceipt, {Kind: "Left early", Title: "Left early recorded · " & stu.StudentName & " · " & Text(w.Date, "ddd mmm d, yyyy") & " · " & Text(w.'Left Early At', "h:mm AM/PM")});
                                        ClearCollect(
                                            colAbsReceiptLines,
                                            {Label: "Student", Value: stu.StudentName & " · " & stu.StudentNumber},
                                            {Label: "Date", Value: Text(w.Date, "ddd mmm d, yyyy")},
                                            {Label: "Before", Value: If(active, "Present (marked by the " & If(live.Source = 'Source (Attendance)'.Office, "office", "teacher") & ")", IsBlank(live), "Not marked", "Deleted row (reused)")},
                                            {Label: "Present", Value: If(w.Present = true, "Yes (1)", "No")},
                                            {Label: "Left early", Value: If(w.'Left Early' = true, "Yes", "No")},
                                            {Label: "Left at", Value: Text(w.'Left Early At', "h:mm AM/PM")},
                                            {Label: "Reason", Value: w.'Left Early Reason'},
                                            {Label: "Source", Value: Text(w.Source)},
                                            {Label: "Teacher", Value: seg.TeacherName},
                                            {Label: "Record key", Value: w.'Record Key'},
                                            {Label: "Audit event", Value: If(IsBlank(au), "NOT written", If(active, "Update written", "Create written"))}
                                        );
                                        Set(varAbsAddMode, ""); Reset(cboAbsAddStuV); Reset(dpAbsAddFromV); Reset(txtAbsLeTimeV); Reset(txtAbsAddNoteV)
                                    )
                                )
                            )
                        )
                    )
                );
                Set(varAbsSaving, false)
            )
        )
    )
)
```

If the compiler rejects `'Classified By': Blank()` / `'Classified On': Blank()` on the create path, drop those two
lines only (they matter only when a deleted row is reused; report it).

## Layout and Visual Impact

- Breakpoint source: `conAbsRoot.Width` (existing). Detail column width at 1024 = (1024 - 8) / 3 = 339, inner 307;
  at 1366 inner 420; below 1024 it stacks full width under the list (the list hides while the panel is open).
- Bar: 130 + 8 + 110 = 248 <= 307. Actions: 150 + 8 + 100 = 258 <= 307.
- Panel heights (gap 4): absence 430 (Excused 492), leftearly 368 - see plan index Layout Budget. Column heights:
  idle 180, absence 550 / 612, leftearly 488; always below the list panel height on desktop (Max() keeps the body).
- `lblAbsAddCheckV` 72 px at Size 12 = 4 lines of ~50 chars at 307 px; longest "Ready" text ~150 chars = 3 lines.
- Nav: 4 buttons 494 + 32 padding; wraps to two rows below ~526 px (Height 96 + 8 on phone).
- Visual contract: shared toggle pattern for the bar; primary teal Save; Secondary Cancel; muted 12 Semibold labels.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| abs-rcpt-day | galAbsReceiptV line | per-day outcome | colAbsLog | lblAbsRcptLabelV / lblAbsRcptValueV (existing) | existing `ThisItem.Label` / `ThisItem.Value` | receipt at the top of the classify view |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| abs-add-bar | conAbsAddBarV | `=CanClassify && IsBlank(varAbsSelId)` | hidden while Excused… is open |
| abs-add-panel | conAbsAddPanelV | `=CanClassify && IsBlank(varAbsSelId) && varAbsAddMode in ["absence", "leftearly"]` | after Add absence / Left early; hidden after save success, Cancel, campus change, Excused… |

## Required Actions

Copy of plan-index contracts A-ABS-ADD-OPEN, A-LE-OPEN, A-ABS-ADD-SAVE, A-LE-SAVE, A-ABS-ADD-CANCEL, A-NAV-TRANSPORT
(Absences instance). Write sets, proof sets and receipts are exactly as in F1 / F2 above:

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-ABS-ADD-SAVE | gate in `lblAbsAddCheckV` "Ready" | `btnAbsAddSaveV.OnSelect` (F1) | Attendance by Student+Service+Date; `wr.Attendance` | per-day create/reuse/skip; audit Create; reload list | see plan Mutation Field Ledger | title + lines Classification, Classified by, Note, counts, per-day | `conAbsReceiptV` |
| A-LE-SAVE | gate "Ready" | `btnAbsLeSaveV.OnSelect` (F2) | same; `w.Attendance` | present -> update; none/deleted -> create present; absent -> refuse | see ledger | Before, Present, Left early, Left at, Reason, Source, Teacher, Record key, Audit | `conAbsReceiptV`; Screen1 1* |

## Data Entry Label Contracts

All seven pairs share the immediate parent `conAbsAddPanelV` (label directly above its input):
lblAbsAddStuV/cboAbsAddStuV, lblAbsAddFromV/dpAbsAddFromV, lblAbsAddToV/dpAbsAddToV, lblAbsAddClassV/rdoAbsAddClassV,
lblAbsAddReasonV/ddAbsAddReasonV, lblAbsLeTimeV/txtAbsLeTimeV, lblAbsAddNoteV/txtAbsAddNoteV. A label and its input
always share the same `Visible` predicate.

## Functional Test Scenarios

Owned: S-ABS-ADD-OPEN, S-ABS-ADD-RANGE, S-ABS-ADD-UNEXCUSED, S-ABS-ADD-LOCKED, S-ABS-ADD-INVALID, S-LE-OPEN,
S-LE-PRESENT, S-LE-NOROW, S-LE-ABSENT, S-LE-INVALID, S-ABS-CLASSIFY-REGRESSION, S-NAV-TRANSPORT (copy the rows from
the plan index Functional Test Matrix; fixtures are listed there). Key expectations:

- S-ABS-ADD-RANGE: Jane 9/4-9/10 Excused Illness -> 2 created (9/4 new, 9/10 reused deleted), 9/8 "Skipped · teacher
  marked present - use Needs a decision / ask the teacher", 9/9 "Skipped · already absent", 3 non-school ignored.
- S-LE-PRESENT: Jane 10/5 "1:30 PM" -> same row, Left Early true, Present stays true, Source Teacher, audit Update.
- S-LE-ABSENT: Jane 9/9 -> Blocked "the day is marked absent; left early is only for present days", no write.
- Regression: while Excused… is open the bar/panel are hidden; Excused save/cancel behave exactly as before.

## Relevant Data Source Schemas

- Attendance: Attendance (GUID), 'Record Key', Date, Present (Bool), 'Is Deleted' (Bool), Student, Service,
  Enrollment, Teacher, Campus, 'School Year', Term, 'IEP Ratio', Source ('Source (Attendance)'), 'Absence
  Classification', 'Absence Reason', 'Classified By' (Users), 'Classified On', Notes, 'Notice Received On',
  'Parent Reported Absent' (Bool), 'Source Report ID', NEW 'Left Early' (Bool), 'Left Early At' (DateTime),
  'Left Early Reason' (Text 500).
- Enrollments: Enrollment, Student (+'Display Name', 'Student Number'), Service (+Service, 'Service Code'), Teacher
  (+Name), Campus, 'School Year', 'IEP Ratio', 'Start Date', 'End Date'.
- Terms: 'Term (aaca_termid)', 'Start Date', 'End Date', Campus. 'Calendar Exceptions': Date, Campus, Type,
  Description. 'Month Locks': Campus, Month, 'Status (aaca_status)'. 'Absence Reasons': 'Absence Reason', Name, Active.
- 'Audit Events': Summary, Action, Entity, 'Entity ID', Before, After, Reason.

## Changed or Added Control Definitions

(From the discovery packet; only properties this edit sets.)

- GroupContainer (`Control: GroupContainer`, `Variant: AutoLayout` required): DropShadow [DropShadow], Fill,
  FillPortions, Height, LayoutAlignItems [LayoutAlignItems], LayoutDirection [LayoutDirection], LayoutGap,
  LayoutMinHeight, LayoutMinWidth, LayoutWrap, RadiusBottomLeft/RadiusBottomRight/RadiusTopLeft/RadiusTopRight,
  Visible, Width, AlignInContainer [AlignInContainer], PaddingTop/Bottom/Left/Right.
- ModernText (`Control: ModernText`): AccessibleLabel, AlignInContainer, Color, FillPortions, FontWeight
  [FontWeight], Height, LayoutMinHeight, LayoutMinWidth, PaddingBottom/Left/Right/Top, Size, Text, VerticalAlign
  [VerticalAlign], Visible, Wrap.
- ModernButton (`Control: ModernButton`; no Fill): AccessibleLabel, AlignInContainer, Appearance [ButtonAppearance],
  BasePaletteColor, Color, DisplayMode [DisplayMode], Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth,
  OnSelect, Size, Text, Tooltip, Visible, Width.
- Classic/Button (`Control: Classic/Button`): AlignInContainer, AutoDisableOnSelect, LayoutMinHeight, LayoutMinWidth,
  OnSelect, Text, Visible.
- ModernCombobox (`Control: ModernCombobox`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  DefaultSelectedItems, DisplayMode, Height, InputTextPlaceholder, IsSearchable, ItemDisplayText, Items,
  LayoutMinHeight, LayoutMinWidth, OnChange, SelectMultiple, Visible. Output SelectedItems.
- ModernDatePicker (`Control: ModernDatePicker`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  DefaultDate, DisplayMode, EndDate, Format [DatePickerFormat], Height, LayoutMinHeight, LayoutMinWidth, OnChange,
  Placeholder, StartDate, Visible. Output SelectedDate.
- ModernRadio (`Control: ModernRadio`): AccessibleLabel, AlignInContainer, Color, Default, DisplayMode, Height,
  ItemDisplayText, Items, Layout [OptionLayout], LayoutMinHeight, LayoutMinWidth, OnChange, Visible. Output Selected.
- ModernDropdown (`Control: ModernDropdown`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  Default, DisplayMode, Height, ItemDisplayText, Items, LayoutMinHeight, LayoutMinWidth, OnChange, Visible.
- ModernTextInput (`Control: ModernTextInput`): AccessibleLabel, AlignInContainer, Appearance [Appearance], Color,
  Default, DisplayMode, Height, LayoutMinHeight, LayoutMinWidth, MaxLength, Placeholder, Type [TextInputType],
  Visible. Output Text.

Compile-ready enum literals used: `ButtonAppearance.Primary`, `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`,
`Appearance.Outline`, `DatePickerFormat.Short`, `OptionLayout.Horizontal`, `DisplayMode.Edit`,
`DisplayMode.Disabled`, `LayoutDirection.Horizontal`, `LayoutDirection.Vertical`, `LayoutAlignItems.Center`,
`LayoutAlignItems.Stretch`, `AlignInContainer.Center`, `AlignInContainer.Stretch`, `FontWeight.Semibold`,
`VerticalAlign.Top`, `DropShadow.None`.

YAML: `Default: ={Value: varAbsAddClass}` contains `: ` -> write it as a `|-` block. Every multi-line formula above
is a `|-` block. Grep the new YAML for ` #` before returning (none expected).
