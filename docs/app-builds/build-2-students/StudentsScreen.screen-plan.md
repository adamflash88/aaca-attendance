# Screen Plan: Students (StudentsScreen)

## Assignment

- Action: Create
- Target file: `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml`
- YAML key: StudentsScreen (not `Students` — that is a Dataverse table name and a screen of the same
  name would shadow `Students` in every formula)
- Control name prefix: Stu
- Read with `C:\src\aaca-attendance\app\canvas-app-shared.md` (palette, type roles, header/nav pattern,
  YAML conventions). App.Formulas/OnStart additions listed in the plan index are applied before you build.
- Size note: ~125 controls (~2,500 YAML lines). This exceeds the usual 40-control dispatch budget by
  orchestrator decision (one approved screen). Build it section by section in the order below.

## Specification

- Purpose: Attendance Office (own campus) and System Admin (any campus) find a student, see profile and
  enrollment history, and add / edit / change class / change IEP ratio / discharge / archive / unarchive.
  Teachers, Read-only and not-set-up users see only a not-authorised panel.
- Breakpoint source: `conStuRoot.Width` for phone (`< 640`) and stacked (`< 1024`) layout; inside the right
  column, text-wrap budgets branch on `conStuDetail.Width < 700` and `conStuForm.Width < 700`
  (those widths never depend on heights). Body split `>= 1024`: list FillPortions 2, right column 3.
- Screen properties: `Fill: =ColorPaper`; `OnVisible: =Set(varStuMode, ""); Set(varStuAttAfter, 0); Select(btnStuLoadEngine)`

### Control tree (order is significant; every container is `Variant: AutoLayout`)

```
StudentsScreen
└ conStuRoot                         root (shared Layout Strategy values)
  ├ conStuHeader                     shared header pattern; btnStuNavStudents = current (Primary)
  │  ├ lblStuTitle · lblStuIdentity
  │  └ conStuNav → btnStuNavAttendance (Secondary) · btnStuNavStudents (Primary)
  ├ conStuDenied                     Visible !CanManageStudents
  │  └ lblStuDeniedTitle · lblStuDeniedBody · btnStuDeniedBack
  ├ conStuNotice → lblStuNotice      Visible CanManageStudents && varStuLoadError <> ""
  ├ spnStuLoading                    Visible varStuLoading
  ├ conStuReceipt                    Visible varStuReceipt.Kind <> ""
  │  ├ conStuReceiptTop → lblStuReceiptTitle · btnStuReceiptDismiss
  │  └ galStuReceipt → conStuRcptRow → lblStuRcptLabel · lblStuRcptValue
  ├ conStuBody                       Visible CanManageStudents; horizontal >= 1024 else vertical
  │  ├ conStuListPanel
  │  │  ├ conStuListHead → lblStuListTitle · btnStuReload · btnStuAdd
  │  │  ├ conStuSearchField → lblStuSearch · txtStuSearch
  │  │  ├ conStuScopeRow → conStuCampusField (lblStuCampus · ddStuCampus) · conStuTeacherField (lblStuTeacher · ddStuTeacher)
  │  │  ├ conStuStatusField → lblStuStatus · rdoStuStatus
  │  │  ├ conStuFilterActions → tglStuArchived · btnStuClearFilters
  │  │  ├ lblStuCount
  │  │  └ galStuList → conStuRowShell → conStuRowTop (lblStuRowName · badgeStuRowStatus · btnStuRowView) · lblStuRowMeta · lblStuRowPlacement
  │  └ conStuRight
  │     ├ conStuForm                 Visible varStuMode <> ""
  │     │  ├ lblStuFormTitle · lblStuFormContext
  │     │  ├ conStuFormIdentity → lblStuFormFirst · txtStuFormFirst · lblStuFormLast · txtStuFormLast · lblStuFormDob · dpStuFormDob · lblStuFormGrade · ddStuFormGrade · lblStuFormExt · txtStuFormExt
  │     │  ├ conStuFormPlace → lblStuFormCampus · ddStuFormCampus · lblStuFormTeacher · ddStuFormTeacher
  │     │  ├ conStuFormProgram → lblStuFormProgram · rdoStuFormProgram
  │     │  ├ conStuFormRatio → lblStuFormRatio · ddStuFormRatio
  │     │  ├ conStuFormDate → lblStuFormDate · dpStuFormDate
  │     │  ├ conStuFormReason → lblStuFormReason · txtStuFormReason
  │     │  ├ conStuDup → lblStuDupText · btnStuDupView · chkStuDupAck
  │     │  ├ conStuBackdate → lblStuBackdateText · chkStuBackdateAck
  │     │  ├ lblStuFormCheck
  │     │  └ conStuFormActions → btnStuFormSubmit · btnStuFormCancel
  │     └ conStuDetail
  │        ├ lblStuDetailEmpty          Visible IsBlank(varStuSelId)
  │        └ conStuProfile              Visible !IsBlank(varStuSelId)
  │           ├ btnStuBackToList        Visible conStuRoot.Width < 1024
  │           ├ conStuProfileHead → lblStuDetailName · badgeStuDetailStatus
  │           ├ lblStuDetailFacts · lblStuDetailPlacement
  │           ├ conStuActions → btnStuActEdit · btnStuActTransfer · btnStuActRatio · btnStuActDischarge · btnStuActArchive · btnStuActUnarchive
  │           ├ lblStuActionHint · lblStuHistoryTitle · lblStuHistoryEmpty
  │           └ galStuHistory → conStuHistRow → conStuHistBar · conStuHistText (lblStuHistDates · lblStuHistPlacement · lblStuHistEnd)
  ├ btnStuLoadEngine · btnStuHistoryEngine · btnStuFormResetEngine   Classic/Button, Visible false
```

### Sizes and styling (all GroupContainers: `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, `DropShadow: =DropShadow.None`)

Panels (`conStuDenied`, `conStuListPanel`, `conStuForm`, `conStuDetail`): `Fill: =ColorWhite`, `BorderColor: =ColorRule`,
`BorderThickness: =1` (conStuForm: `BorderColor: =ColorTeal`, `BorderThickness: =2`), radius 6, padding 16, gap 8,
vertical, `LayoutAlignItems: =LayoutAlignItems.Stretch`. Field groups (`conStuSearchField`, `conStuCampusField`,
`conStuTeacherField`, `conStuStatusField`, `conStuForm*` groups): vertical, gap 4, no padding, Stretch; each label
ModernText Size 12 `ColorMuted` Semibold Height 18 `Wrap: =false`; each input Height 36 (multiline 64).

| Control | Key properties |
| ------- | -------------- |
| conStuRoot | shared root values; children below with `FillPortions: =0`, `AlignInContainer: =AlignInContainer.Stretch` |
| conStuHeader | shared pattern with `<root>` = `conStuRoot` |
| conStuDenied | `Height: =16 + 24 + 8 + If(conStuRoot.Width < 640, 88, 48) + 8 + 44 + 16`; title Size 16 Semibold H 24 "Students is not available for your role"; body Size 14 H `If(conStuRoot.Width < 640, 88, 48)`, Text `=If(!StaffReady, "Your sign-in is not linked to an active Staff record. Ask a System Admin to set you up.", "Only the Attendance Office and System Admin roles can manage students. Teachers and Read-only users record and view attendance on the Attendance screen.")`; btnStuDeniedBack Secondary W 190 "Back to Attendance", `OnSelect: =Navigate(Screen1)`, `AlignInContainer: =AlignInContainer.Start` |
| conStuNotice | horizontal, `Fill: =ColorErrorBg`, border ColorRule 1, padding 4/12, `Height: =If(conStuRoot.Width < 640, 68, 44)`; lblStuNotice FillPortions 1, Size 13, `Color: =ColorInk`, Text `="Could not load students — " & varStuLoadError & ". Use ↻ to try again."` |
| spnStuLoading | ModernSpinner H 48, `Label: ="Loading students…"`, `SpinnerColor: =ColorTeal`, `Color: =ColorInk` |
| conStuReceipt | vertical, padding 8/12/8/12, gap 4, border ColorRule 1, radius 6, `Fill: =Switch(varStuReceipt.Kind, "Failed", ColorErrorBg, "Blocked", ColorErrorBg, "Cancelled", ColorWarnBg, ColorInfoBg)`; `Height: =8 + If(conStuRoot.Width < 640, 84, 44) + If(CountRows(colStuReceiptLines) > 0, 4 + galStuReceipt.Height, 0) + 8` |
| conStuReceiptTop | horizontal, gap 8, `LayoutAlignItems: =LayoutAlignItems.Center`, `Height: =If(conStuRoot.Width < 640, 84, 44)`; lblStuReceiptTitle FillPortions 1, Size 13 Semibold, `Color: =ColorInk`, Wrap true, Height = same as row, `Text: =varStuReceipt.Title`; btnStuReceiptDismiss Secondary W 88 "Dismiss", `OnSelect: =Set(varStuReceipt, {Kind: "", Title: "", StudentId: ZeroGuid}); Clear(colStuReceiptLines)` (quote the record literal / use `|-`) |
| galStuReceipt | Vertical; `Items: =colStuReceiptLines`; `WrapCount: =If(conStuRoot.Width < 640, 1, conStuRoot.Width < 1024, 2, 3)`; `TemplateSize: =40`; `TemplatePadding: =0`; `Height: =Min(400, RoundUp(CountRows(colStuReceiptLines) / If(conStuRoot.Width < 640, 1, conStuRoot.Width < 1024, 2, 3), 0) * 40)`; `Visible: =CountRows(colStuReceiptLines) > 0`; `Selectable: =false`; `TabIndex: =0`; `ShowScrollbar: =true`; AccessibleLabel "Saved values" |
| conStuRcptRow | horizontal, Width/Height = Parent.TemplateWidth/TemplateHeight, padding 2/8/2/0, gap 8, Stretch; lblStuRcptLabel W 150 FillPortions 0 Size 12 Semibold `ColorMuted` Wrap `Text: =ThisItem.Label`; lblStuRcptValue FillPortions 1 Size 12 `ColorInk` Wrap `Text: =ThisItem.Value`; AccessibleLabel `=ThisItem.Label & " " & ThisItem.Value` |
| conStuBody | `LayoutDirection: =If(conStuRoot.Width >= 1024, LayoutDirection.Horizontal, LayoutDirection.Vertical)`, `LayoutAlignItems: =If(conStuRoot.Width >= 1024, LayoutAlignItems.Start, LayoutAlignItems.Stretch)`, gap 8, no fill; `Height: =If(conStuRoot.Width >= 1024, Max(844, conStuRight.Height), If(conStuListPanel.Visible, 844 + 8, 0) + conStuRight.Height)` |
| conStuListPanel | `FillPortions: =If(conStuRoot.Width >= 1024, 2, 0)`, `AlignInContainer: =If(conStuRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)`, `Height: =844`, `Visible: =!(conStuRoot.Width < 1024 && (!IsBlank(varStuSelId) \|\| varStuMode <> ""))` |
| conStuListHead | horizontal H 44, gap 8, Center; lblStuListTitle "Students" Size 20 Bold FillPortions 1 LayoutMinWidth 80 H 30 Wrap false; btnStuReload Secondary W 44 "↻" AccessibleLabel "Reload students" `OnSelect: =Select(btnStuLoadEngine)`, DisplayMode disabled while `varStuLoading`; btnStuAdd Primary W 140 "+ Add student" (entry event below), disabled while `varStuLoading \|\| varStuSaving` |
| conStuSearchField | H 58; lblStuSearch "Search name, student number or external ID"; txtStuSearch `Type: =TextInputType.Search`, `TriggerOutput: =TriggerOutput.Delayed`, `Placeholder: ="e.g. Garcia, STU-000123 or SEED-0001"`, `Default: =""` |
| conStuScopeRow | horizontal H 58, gap 8, Stretch; conStuCampusField / conStuTeacherField `FillPortions: =1`, `LayoutMinWidth: =140` |
| ddStuCampus | `Items: =colStuCampusOpts`; `ItemDisplayText: =ThisItem.CampusName`; `Default: =LookUp(colStuCampusOpts, CampusId = varStuScopeCampusId)`; `DisplayMode: =If(StudentCampusLock = ZeroGuid && !varStuLoading, DisplayMode.Edit, DisplayMode.Disabled)`; `OnChange: =Set(varStuScopeCampusId, Coalesce(Self.Selected.CampusId, ZeroGuid)); Set(varStuTeacherFilterId, ZeroGuid); Reset(ddStuTeacher)` |
| ddStuTeacher | `Items: =Filter(colStuTeacherOpts, TeacherId = ZeroGuid \|\| varStuScopeCampusId = ZeroGuid \|\| CampusId = varStuScopeCampusId)`; `ItemDisplayText: =ThisItem.TeacherName`; `Default: =LookUp(colStuTeacherOpts, TeacherId = varStuTeacherFilterId)`; `OnChange: =Set(varStuTeacherFilterId, Coalesce(Self.Selected.TeacherId, ZeroGuid))` |
| conStuStatusField | H 58; lblStuStatus "Status"; rdoStuStatus `Items: =["Active", "Inactive", "Archived", "All"]`, `Default: '={Value: "Active"}'`, `Layout: =OptionLayout.Horizontal`, H 36 |
| conStuFilterActions | horizontal H 44, gap 8, Center; tglStuArchived `Label: ="Include archived"`, `LabelPosition: =ToggleLabelPosition.After`, `Default: =false`, W 180 H 44; btnStuClearFilters Secondary W 120 "Clear filters" `OnSelect: =Set(varStuScopeCampusId, StudentDefaultScope); Set(varStuTeacherFilterId, ZeroGuid); Reset(txtStuSearch); Reset(rdoStuStatus); Reset(tglStuArchived); Reset(ddStuCampus); Reset(ddStuTeacher)` |
| lblStuCount | H 54, Size 12, `ColorMuted`, Wrap true — formula F-COUNT below (active filters + zero-result state) |
| galStuList | Vertical; `Items:` formula F-LIST; `Height: =448`; `TemplateSize: =116`; `TemplatePadding: =0`; `Selectable: =false`; `TabIndex: =0`; `ShowScrollbar: =true`; AccessibleLabel "Students list" |
| conStuRowShell | vertical, Width/Height = Parent.TemplateWidth/TemplateHeight, padding 6/8/6/8, gap 2, Stretch, `Fill: =If(ThisItem.StudentId = varStuSelId, ColorInfoBg, ColorWhite)`, `BorderColor: =ColorRule`, `BorderThickness: =1`, radii 0 |
| conStuRowTop | horizontal H 44, gap 8, Center: lblStuRowName FillPortions 1 Size 14 Semibold `ColorInk` Wrap H 42 `Text: =ThisItem.DisplayName`; badgeStuRowStatus W 84 H 24 `Content: =ThisItem.StatusText` (Badge rules below); btnStuRowView Secondary W 64 "View", AccessibleLabel `="View " & ThisItem.DisplayName`, `OnSelect: =Set(varStuSelId, ThisItem.StudentId); Set(varStuMode, ""); Select(btnStuHistoryEngine)` |
| lblStuRowMeta | H 18 Size 12 `ColorInk` Wrap false `Text: =ThisItem.StudentNumber & " · Grade " & ThisItem.GradeText & " · IEP " & ThisItem.RatioText` |
| lblStuRowPlacement | H 36 Size 12 `ColorMuted` Wrap `Text: =If(ThisItem.PlacementKind = "Current", "", ThisItem.PlacementKind & " · ") & ThisItem.TeacherName & " · " & ThisItem.CampusName` |
| conStuRight | vertical, gap 8, no fill/padding, Stretch; `FillPortions: =If(conStuRoot.Width >= 1024, 3, 0)`; `AlignInContainer` as list panel; `Height: =If(conStuForm.Visible, conStuForm.Height + 8, 0) + conStuDetail.Height` |
| conStuForm | `Visible: =varStuMode <> ""`; `Height:` formula F-FORMH |
| lblStuFormTitle | Size 18 Bold, Wrap, `Height: =If(conStuForm.Width < 700, 56, 28)`, formula F-TITLE |
| lblStuFormContext | Size 13, Wrap, `Height: =If(conStuForm.Width < 700, 100, 60)`, formula F-CONTEXT |
| conStuFormIdentity | `Visible: =varStuMode in ["add", "edit"]`, `Height: =306` (5×18 + 5×36 + 9×4) |
| conStuFormPlace | `Visible: =varStuMode in ["add", "transfer"]`, `Height: =120` |
| conStuFormProgram | `Visible: =varStuMode = "add"`, `Height: =58` |
| conStuFormRatio | `Visible: =varStuMode in ["add", "ratio"]`, `Height: =58` |
| conStuFormDate | `Visible: =varStuMode in ["add", "transfer", "ratio", "discharge"]`, `Height: =58` |
| conStuFormReason | `Visible: =varStuMode in ["transfer", "ratio", "discharge", "edit", "archive", "unarchive"]`, `Height: =86` |
| conStuDup | `Fill: =ColorWarnBg`, border ColorRule 1, radius 6, padding 12, gap 8, `Visible:` F-DUPVIS, `Height: =If(conStuForm.Width < 700, 176, 156)`; lblStuDupText Size 13 Wrap H `If(conStuForm.Width < 700, 60, 40)` F-DUPTEXT; btnStuDupView Secondary W 190 H 44 `AlignInContainer: =AlignInContainer.Start` "Open existing student" F-DUPVIEW; chkStuDupAck `Label: ="This is a different person"`, H 32, `Default: =false` |
| conStuBackdate | same surface, `Visible: =varStuMode in ["transfer", "ratio", "discharge"] && varStuAttAfter > 0`, `Height: =If(conStuForm.Width < 700, 124, 104)`; lblStuBackdateText Size 13 Wrap H `If(conStuForm.Width < 700, 60, 40)` F-BACKTEXT; chkStuBackdateAck `Label: ="I understand. Keep those days as recorded."`, H 32, `Default: =false` |
| lblStuFormCheck | Size 13, Wrap, `Height: =If(conStuForm.Width < 700, 60, 40)`, `Color: =If(Self.Text = "Ready to save.", ColorExcused, ColorUnexcused)`, formula F-CHECK |
| conStuFormActions | horizontal H 44, gap 8, Center; btnStuFormSubmit Primary W 190 `BasePaletteColor: =If(varStuMode in ["discharge", "archive"], ColorUnexcused, ColorTeal)`, `Color: =ColorWhite`, `Text: =Switch(varStuMode, "add", "Add student", "edit", "Save details", "transfer", "Save class change", "ratio", "Save ratio change", "discharge", "Discharge student", "archive", "Archive student", "unarchive", "Unarchive student", "Save")`, `DisplayMode: =If(varStuMode <> "" && lblStuFormCheck.Text = "Ready to save." && !varStuSaving && !varStuLoading, DisplayMode.Edit, DisplayMode.Disabled)`, OnSelect F-SUBMIT; btnStuFormCancel Secondary W 96 "Cancel" F-CANCEL |
| conStuDetail | `Height: =16 + If(IsBlank(varStuSelId), 40, conStuProfile.Height) + 16`; lblStuDetailEmpty H 40 Size 14 Wrap `Text: ="Select a student with View to see their profile, enrollment history and actions, or use + Add student."` |
| conStuProfile | vertical, gap 8, no padding, Stretch, `Height:` F-PROFH |
| btnStuBackToList | Secondary W 150 "← Back to list", `AlignInContainer: =AlignInContainer.Start`, `OnSelect: =Set(varStuSelId, Blank()); Set(varStuMode, ""); Clear(colStuHistory)` |
| conStuProfileHead | horizontal, gap 8, Center, `Height: =If(conStuDetail.Width < 700, 60, 30)`; lblStuDetailName FillPortions 1 Size 20 Bold Wrap `Text: =LookUp(colStuList, StudentId = varStuSelId).DisplayName`; badgeStuDetailStatus W 96 H 28 `Content: =LookUp(colStuList, StudentId = varStuSelId).StatusText` |
| lblStuDetailFacts | Size 13 Wrap `Height: =If(conStuDetail.Width < 700, 60, 40)` F-FACTS |
| lblStuDetailPlacement | Size 13 Wrap `Height: =If(conStuDetail.Width < 700, 80, 60)` F-PLACE |
| conStuActions | horizontal, `LayoutWrap: =true`, gap 8, `Height: =If(conStuDetail.Width - 32 >= 600, 44, conStuDetail.Width - 32 >= 376, 96, 148)`; buttons all Secondary H 44 FillPortions 0: btnStuActEdit W 120 "Edit details", btnStuActTransfer W 120 "Change class", btnStuActRatio W 120 "Change ratio", btnStuActDischarge W 104 "Discharge", btnStuActArchive W 104 "Archive", btnStuActUnarchive W 104 "Unarchive" (entry events + gates below) |
| lblStuActionHint | Size 13 `ColorMuted` Wrap `Height: =If(conStuDetail.Width < 700, 60, 40)` F-HINT |
| lblStuHistoryTitle | Size 16 Semibold H 24 `Text: ="Enrollment history (" & CountRows(colStuHistory) & ")"` |
| lblStuHistoryEmpty | H 40 Size 13 `Visible: =CountRows(colStuHistory) = 0` `Text: ="No enrollments on record for this student."` |
| galStuHistory | Vertical; `Items: =Sort(colStuHistory, StartDate, SortOrder.Descending)`; `Height: =348`; `TemplateSize: =116`; `TemplatePadding: =0`; `Visible: =CountRows(colStuHistory) > 0`; `Selectable: =false`; `TabIndex: =0`; AccessibleLabel "Enrollment history" |
| conStuHistRow | horizontal, Width/Height = Parent.TemplateWidth/TemplateHeight, padding 8/8/8/8, gap 8, Stretch, `BorderColor: =ColorRule`, `BorderThickness: =1`, `Fill: =If(ThisItem.StartDate <= Today() && (IsBlank(ThisItem.EndDate) \|\| ThisItem.EndDate >= Today()), ColorInfoBg, ColorWhite)`; conStuHistBar W 6 FillPortions 0 `Fill: =Switch(ThisItem.StatusText, "Active", ColorTeal, "Planned", ColorInkSoft, ColorRule)`; conStuHistText vertical FillPortions 1 gap 2 Stretch |
| lblStuHistDates | Size 13 Semibold H 20 Wrap false `Text: =Text(ThisItem.StartDate, "mmm d, yyyy") & " – " & If(IsBlank(ThisItem.EndDate), "open", Text(ThisItem.EndDate, "mmm d, yyyy")) & " · " & ThisItem.StatusText` |
| lblStuHistPlacement | Size 12 Wrap H 36 `Text: =ThisItem.TeacherName & " · " & ThisItem.CampusName & " · IEP " & ThisItem.RatioText & " · " & ThisItem.ProgramText & " · " & ThisItem.YearName` |
| lblStuHistEnd | Size 12 `ColorMuted` Wrap H 36 F-HISTEND |
| Engines | `btnStuLoadEngine` F-LOAD; `btnStuHistoryEngine` F-HISTORY; `btnStuFormResetEngine` F-RESET. Each: `Control: Classic/Button`, `Visible: =false`, `AutoDisableOnSelect: =false`, `Text:` "load"/"history"/"reset", `AlignInContainer: =AlignInContainer.Stretch`, `LayoutMinHeight: =0`, `LayoutMinWidth: =0` |

Badges (both): `Appearance: ='BadgeCanvas.Appearance'.Tint`, `Shape: ='BadgeCanvas.Shape'.Rounded`,
`FontColor: =ColorInk`, `FontSize: =12`, `ThemeColor: =Switch(<status>, "Active", 'BadgeCanvas.ThemeColor'.Success, "Archived", 'BadgeCanvas.ThemeColor'.Warning, 'BadgeCanvas.ThemeColor'.Subtle)`,
AccessibleLabel `="Status " & <status>`.

### Data binding and collections (built only by the engines; same shape wherever a name repeats)

ENR record shape (used for `colStuEnr` and `colStuHistory`, alias `e`):
`{EnrId: e.Enrollment, StudentId: e.Student.Student, CampusId: e.Campus.Campus, CampusName: e.Campus.Name, CampusCode: e.Campus.Code, TeacherId: e.Teacher.Staff, TeacherName: e.Teacher.Name, ServiceId: e.Service.Service, YearId: e.'School Year'.'School Year', YearName: e.'School Year'.Name, ProgramText: Text(e.Program), RatioText: Text(e.'IEP Ratio'), StartDate: e.'Start Date', EndDate: e.'End Date', StatusText: Text(e.'Status (aaca_status)'), EndReasonText: Text(e.'End Reason'), PrevEnrId: e.'Previous Enrollment'.Enrollment}`

Field semantics: an enrollment is **open** when `IsBlank(EndDate)`; **current** when `StartDate <= Today()` and
(`IsBlank(EndDate)` or `EndDate >= Today()`); **open-or-future** when `IsBlank(EndDate) || EndDate >= Today()`.
The actions act on OPEN = `First(Sort(Filter(colStuHistory, IsBlank(EndDate)), StartDate, SortOrder.Descending))`.
The list shows the current placement, else the next planned one, else the last one (`PlacementKind`).

F-LOAD (`btnStuLoadEngine.OnSelect`):
```
=Set(varStuLoading, true);
Set(varStuLoadError, "");
If(
    !CanManageStudents,
    Clear(colStuList); Clear(colStuEnr); Clear(colStuHistory),
    IfError(
        Concurrent(
            ClearCollect(colStuEnr, ForAll(Filter(Enrollments, IsBlank('End Date') || 'End Date' >= Date(Year(Today()) - 1, 7, 1)) As e, <ENR>)),
            ClearCollect(colStuRaw, ForAll(Students As s, {StudentId: s.Student, DisplayName: s.'Display Name', FirstName: s.'First Name', LastName: s.'Last Name', StudentNumber: s.'Student Number', Dob: s.'Date of Birth', GradeText: Text(s.Grade), ExternalId: s.'External Client ID', StatusText: Text(s.'Status (aaca_status)'), ArchivedOn: s.'Archived On'})),
            ClearCollect(colStuYears, ForAll('School Years' As y, {YearId: y.'School Year', YearName: y.Name, YStart: y.'Start Date', YEnd: y.'End Date', YStatus: Text(y.'Status (aaca_status)')})),
            ClearCollect(colStuCampusSrc, ForAll(Sort(Campuses, Name, SortOrder.Ascending) As c, {CampusId: c.Campus, CampusName: c.Name})),
            ClearCollect(colStuTeacherSrc, ForAll(Sort(Filter(Staff, 'App Role' = 'App Role (Staff)'.Teacher), Name, SortOrder.Ascending) As t, {TeacherId: t.Staff, TeacherName: t.Name, CampusId: t.Campus.Campus}))
        ),
        Set(varStuLoadError, FirstError.Message)
    );
    ClearCollect(colStuCampusOpts, {CampusId: ZeroGuid, CampusName: "All campuses"}, colStuCampusSrc);
    ClearCollect(colStuTeacherOpts, {TeacherId: ZeroGuid, TeacherName: "All teachers", CampusId: ZeroGuid}, colStuTeacherSrc);
    ClearCollect(
        colStuList,
        ForAll(
            colStuRaw As r,
            With(
                {
                    cur: First(Sort(Filter(colStuEnr, StudentId = r.StudentId && StartDate <= Today() && (IsBlank(EndDate) || EndDate >= Today())), StartDate, SortOrder.Descending)),
                    nxt: First(Sort(Filter(colStuEnr, StudentId = r.StudentId && StartDate > Today()), StartDate, SortOrder.Ascending)),
                    lst: First(Sort(Filter(colStuEnr, StudentId = r.StudentId), StartDate, SortOrder.Descending))
                },
                With(
                    {p: If(!IsBlank(cur), cur, !IsBlank(nxt), nxt, lst)},
                    {
                        StudentId: r.StudentId, DisplayName: r.DisplayName, FirstName: r.FirstName, LastName: r.LastName,
                        StudentNumber: r.StudentNumber, Dob: r.Dob, GradeText: r.GradeText, ExternalId: r.ExternalId,
                        StatusText: r.StatusText, ArchivedOn: r.ArchivedOn,
                        CampusId: p.CampusId, CampusName: Coalesce(p.CampusName, "No campus"),
                        TeacherId: p.TeacherId, TeacherName: Coalesce(p.TeacherName, "No teacher"),
                        RatioText: Coalesce(p.RatioText, "—"), ProgramText: Coalesce(p.ProgramText, "—"),
                        PlacementKind: If(!IsBlank(cur), "Current", !IsBlank(nxt), "Planned", !IsBlank(lst), "Last", "None"),
                        SearchKey: Lower(r.DisplayName & " " & r.StudentNumber & " " & r.ExternalId)
                    }
                )
            )
        )
    );
    If(IsBlank(varStuSelId), Clear(colStuHistory), ClearCollect(colStuHistory, ForAll(With({q: varStuSelId}, Filter(Enrollments, Student.Student = q)) As e, <ENR>)))
);
Set(varStuLoading, false)
```
(Replace `<ENR>` with the ENR shape. `ForAll(Students ...)` returns up to the app's data-row limit — 112 seed
rows, ~225 in production; raise the limit to 2000 if it ever exceeds 500.)

F-HISTORY (`btnStuHistoryEngine.OnSelect`):
`=If(IsBlank(varStuSelId), Clear(colStuHistory), ClearCollect(colStuHistory, ForAll(With({q: varStuSelId}, Filter(Enrollments, Student.Student = q)) As e, <ENR>)))`

F-RESET (`btnStuFormResetEngine.OnSelect`):
`=Reset(txtStuFormFirst); Reset(txtStuFormLast); Reset(dpStuFormDob); Reset(ddStuFormGrade); Reset(txtStuFormExt); Reset(ddStuFormCampus); Reset(ddStuFormTeacher); Reset(rdoStuFormProgram); Reset(ddStuFormRatio); Reset(dpStuFormDate); Reset(txtStuFormReason); Reset(chkStuDupAck); Reset(chkStuBackdateAck)`

PRED (list predicate, used verbatim in F-LIST and F-COUNT):
```
(StudentCampusLock = ZeroGuid || CampusId = StudentCampusLock) &&
(varStuScopeCampusId = ZeroGuid || CampusId = varStuScopeCampusId) &&
(varStuTeacherFilterId = ZeroGuid || TeacherId = varStuTeacherFilterId) &&
(Coalesce(rdoStuStatus.Selected.Value, "Active") = "All" || StatusText = Coalesce(rdoStuStatus.Selected.Value, "Active")) &&
(tglStuArchived.Checked || StatusText <> "Archived") &&
(Trim(txtStuSearch.Text) = "" || Lower(Trim(txtStuSearch.Text)) in SearchKey)
```
F-LIST (`galStuList.Items`): `=Sort(Filter(colStuList, PRED), DisplayName, SortOrder.Ascending)`

F-COUNT (`lblStuCount.Text`):
```
=With(
    {
        n: CountRows(Filter(colStuList, PRED)),
        m: CountRows(Filter(colStuList, (StudentCampusLock = ZeroGuid || CampusId = StudentCampusLock) && (varStuScopeCampusId = ZeroGuid || CampusId = varStuScopeCampusId)))
    },
    If(
        varStuLoading, "Loading students…",
        n = 0, If(!tglStuArchived.Checked && Coalesce(rdoStuStatus.Selected.Value, "Active") = "Archived", "Archived students are hidden. Turn on Include archived to see them.", "No students match these filters. Use Clear filters to see everyone in scope."),
        "Showing " & n & " of " & m & " students · Status " & Coalesce(rdoStuStatus.Selected.Value, "Active") & If(tglStuArchived.Checked, " (archived included)", "") & " · " & LookUp(colStuCampusOpts, CampusId = varStuScopeCampusId).CampusName & " · " & LookUp(colStuTeacherOpts, TeacherId = varStuTeacherFilterId).TeacherName & If(Trim(txtStuSearch.Text) = "", "", " · search """ & Trim(txtStuSearch.Text) & """")
    )
)
```

F-FACTS: `="Student number " & s.StudentNumber & " · Grade " & s.GradeText & " · Born " & Text(s.Dob, "mmm d, yyyy") & " · External ID " & Coalesce(s.ExternalId, "—") & If(s.StatusText = "Archived", " · Archived " & Text(s.ArchivedOn, "mmm d, yyyy"), "")` wrapped in `With({s: LookUp(colStuList, StudentId = varStuSelId)}, ...)`.

F-PLACE:
```
=With(
    {
        cur: LookUp(colStuHistory, StartDate <= Today() && (IsBlank(EndDate) || EndDate >= Today())),
        nxt: First(Sort(Filter(colStuHistory, StartDate > Today()), StartDate, SortOrder.Ascending))
    },
    If(IsBlank(cur), "No current enrollment", "Now — " & cur.TeacherName & " · " & cur.CampusName & " · IEP " & cur.RatioText & " · " & cur.ProgramText & " · since " & Text(cur.StartDate, "mmm d, yyyy") & If(IsBlank(cur.EndDate), "", " · ends " & Text(cur.EndDate, "mmm d, yyyy")))
    & If(IsBlank(nxt), "", " | Planned from " & Text(nxt.StartDate, "mmm d, yyyy") & " — " & nxt.TeacherName & " · " & nxt.CampusName & " · IEP " & nxt.RatioText)
)
```

F-HISTEND: `=If(ThisItem.EndReasonText = "", If(IsBlank(ThisItem.EndDate), "Open — no end reason", "No end reason recorded"), "End reason " & ThisItem.EndReasonText) & If(IsBlank(ThisItem.PrevEnrId), "", " · continues from the " & Text(LookUp(colStuHistory, EnrId = ThisItem.PrevEnrId).StartDate, "mmm d, yyyy") & " enrollment")`

### Action entry points (selection-only: they set mode/state and reset the form, never mutate)

Common gate `OK` = `!IsBlank(sel) && (StudentCampusLock = ZeroGuid || sel.CampusId = StudentCampusLock) && !varStuSaving && !varStuLoading`
with `sel: LookUp(colStuList, StudentId = varStuSelId)` and `open:` OPEN (write each DisplayMode as `=With({sel: ..., open: ...}, If(<gate>, DisplayMode.Edit, DisplayMode.Disabled))`).
ATT(op, d) = `With({q: varStuSelId, d: <date>}, CountRows(Filter(Attendance, Student.Student = q && Date <op> d && 'Is Deleted' <> true)))`.

| Control | DisplayMode gate | Visible | OnSelect |
| ------- | ---------------- | ------- | -------- |
| btnStuAdd | `!varStuLoading && !varStuSaving` | true | `=Set(varStuMode, "add"); Set(varStuFormCampusId, If(StudentCampusLock <> ZeroGuid, StudentCampusLock, varStuScopeCampusId)); Set(varStuAttAfter, 0); Select(btnStuFormResetEngine)` |
| btnStuActEdit | OK | true | `=Set(varStuEditBase, With({q: varStuSelId}, LookUp(Students, ThisRecord.Student = q))); Set(varStuMode, "edit"); Set(varStuAttAfter, 0); Select(btnStuFormResetEngine)` |
| btnStuActTransfer | OK `&& sel.StatusText = "Active" && !IsBlank(open)` | true | `=Set(varStuMode, "transfer"); Set(varStuFormCampusId, First(Sort(Filter(colStuHistory, IsBlank(EndDate)), StartDate, SortOrder.Descending)).CampusId); Set(varStuAttAfter, ATT(>=, Today())); Select(btnStuFormResetEngine)` |
| btnStuActRatio | same as Transfer | true | `=Set(varStuMode, "ratio"); Set(varStuAttAfter, ATT(>=, Today())); Select(btnStuFormResetEngine)` |
| btnStuActDischarge | same as Transfer | true | `=Set(varStuMode, "discharge"); Set(varStuAttAfter, ATT(>, Today())); Select(btnStuFormResetEngine)` |
| btnStuActArchive | OK `&& CountRows(Filter(colStuHistory, IsBlank(EndDate) \|\| EndDate >= Today())) = 0` | `=LookUp(colStuList, StudentId = varStuSelId).StatusText <> "Archived"` | `=Set(varStuMode, "archive"); Set(varStuAttAfter, 0); Select(btnStuFormResetEngine)` |
| btnStuActUnarchive | OK | `=LookUp(colStuList, StudentId = varStuSelId).StatusText = "Archived"` | `=Set(varStuMode, "unarchive"); Set(varStuAttAfter, 0); Select(btnStuFormResetEngine)` |

F-HINT (`lblStuActionHint.Text`):
```
=With(
    {sel: LookUp(colStuList, StudentId = varStuSelId), open: First(Sort(Filter(colStuHistory, IsBlank(EndDate)), StartDate, SortOrder.Descending)), live: CountRows(Filter(colStuHistory, IsBlank(EndDate) || EndDate >= Today()))},
    If(
        StudentCampusLock <> ZeroGuid && sel.CampusId <> StudentCampusLock, "View only. Office staff can change only students at their own campus.",
        sel.StatusText = "Archived", "Archived. Use Unarchive to return the student to Inactive; Edit details still works.",
        IsBlank(open), "No open enrollment, so Change class, Change ratio and Discharge are unavailable." & If(live = 0, " Archive is available.", ""),
        live > 0, "Archive needs every enrollment closed: " & live & " open or future enrollment" & If(live = 1, "", "s") & ".",
        "All actions available."
    )
)
```

### Form inputs (every input: AccessibleLabel = its label text, `Appearance: =Appearance.Outline`, `Color: =ColorInk`, Stretch)

| Input | Label control / Text | Items / Default / other |
| ----- | -------------------- | ----------------------- |
| txtStuFormFirst | lblStuFormFirst "First name *" | `Default: =If(varStuMode = "edit", varStuEditBase.'First Name', "")`, MaxLength 100 |
| txtStuFormLast | lblStuFormLast "Last name *" | `Default: =If(varStuMode = "edit", varStuEditBase.'Last Name', "")`, MaxLength 100 |
| dpStuFormDob | lblStuFormDob "Date of birth *" | `DefaultDate: =If(varStuMode = "edit", varStuEditBase.'Date of Birth', Blank())`, `StartDate: =Date(1990, 1, 1)`, `EndDate: =Today()`, `Format: =DatePickerFormat.Short` |
| ddStuFormGrade | lblStuFormGrade "Grade *" | `Items: =['Grade (Students)'.K, 'Grade (Students)'.'1', 'Grade (Students)'.'2', 'Grade (Students)'.'3', 'Grade (Students)'.'4', 'Grade (Students)'.'5', 'Grade (Students)'.'6', 'Grade (Students)'.'7', 'Grade (Students)'.'8', 'Grade (Students)'.'9', 'Grade (Students)'.'10', 'Grade (Students)'.'11', 'Grade (Students)'.'12', 'Grade (Students)'.'12+']`; `ItemDisplayText: =Text(ThisItem.Value)`; `Default:` (`|-`) `=If(varStuMode = "edit", {Value: varStuEditBase.Grade}, Blank())` |
| txtStuFormExt | lblStuFormExt "External client ID (optional)" | `Default: =If(varStuMode = "edit", Coalesce(varStuEditBase.'External Client ID', ""), "")`, MaxLength 100 |
| ddStuFormCampus | lblStuFormCampus `=If(varStuMode = "transfer", "New campus *", "Campus *")` | `Items: =Sort(Campuses, Name, SortOrder.Ascending)`; `ItemDisplayText: =ThisItem.Name`; `Default: =LookUp(Campuses, ThisRecord.Campus = varStuFormCampusId)`; `DisplayMode: =If(StudentCampusLock = ZeroGuid, DisplayMode.Edit, DisplayMode.Disabled)`; `OnChange: =Reset(ddStuFormTeacher)` |
| ddStuFormTeacher | lblStuFormTeacher `=If(varStuMode = "transfer", "New teacher *", "Teacher *")` | `Items: =Sort(Filter(Staff, Campus.Campus = ddStuFormCampus.Selected.Campus && 'App Role' = 'App Role (Staff)'.Teacher), Name, SortOrder.Ascending)`; `ItemDisplayText: =ThisItem.Name`; no Default (explicit choice) |
| rdoStuFormProgram | lblStuFormProgram "Program *" | `Items: =['Program (Enrollments)'.'Regular Year', 'Program (Enrollments)'.Summer]`; `ItemDisplayText: =Text(ThisItem.Value)`; `Default:` (`|-`) `={Value: 'Program (Enrollments)'.'Regular Year'}`; `Layout: =OptionLayout.Horizontal`; H 36 |
| ddStuFormRatio | lblStuFormRatio `=If(varStuMode = "ratio", "New IEP ratio *", "IEP ratio *")` | `Items:` (`|-`) `=['IEP Ratio (Enrollments)'.'No Aide', 'IEP Ratio (Enrollments)'.'1:1', 'IEP Ratio (Enrollments)'.'2:1', 'IEP Ratio (Enrollments)'.'3:1', 'IEP Ratio (Enrollments)'.'4:1']`; `ItemDisplayText: =Text(ThisItem.Value)`; no Default |
| dpStuFormDate | lblStuFormDate `=Switch(varStuMode, "add", "Start date *", "transfer", "Effective date (first day in the new class) *", "ratio", "Effective date (first day at the new ratio) *", "discharge", "End date (last day of service) *", "Date")` | `DefaultDate: =Today()`, `StartDate: =Date(Year(Today()) - 1, 7, 1)`, `EndDate: =Date(Year(Today()) + 2, 12, 31)`, `Format: =DatePickerFormat.Short`, `OnChange:` (`|-`) `=Reset(chkStuBackdateAck); With({q: varStuSelId, d: Self.SelectedDate}, Set(varStuAttAfter, If(IsBlank(q) \|\| IsBlank(d) \|\| !(varStuMode in ["transfer", "ratio", "discharge"]), 0, varStuMode = "discharge", CountRows(Filter(Attendance, Student.Student = q && Date > d && 'Is Deleted' <> true)), CountRows(Filter(Attendance, Student.Student = q && Date >= d && 'Is Deleted' <> true)))))` |
| txtStuFormReason | lblStuFormReason `=If(varStuMode = "discharge", "Reason for discharge *", "Note for the audit log (optional)")` | `Type: =TextInputType.Multiline`, H 64, MaxLength 500, `Default: =""` |

F-TITLE: `=With({n: LookUp(colStuList, StudentId = varStuSelId).DisplayName}, Switch(varStuMode, "add", "Add student", "edit", "Edit details — " & n, "transfer", "Change class — " & n, "ratio", "Change IEP ratio — " & n, "discharge", "Discharge — " & n, "archive", "Archive — " & n, "unarchive", "Unarchive — " & n, ""))`

F-CONTEXT:
```
=With(
    {sel: LookUp(colStuList, StudentId = varStuSelId), open: First(Sort(Filter(colStuHistory, IsBlank(EndDate)), StartDate, SortOrder.Descending))},
    Switch(
        varStuMode,
        "add", "Creates the student (Active, new student number), their enrollment and an audit entry. Fields marked * are required.",
        "edit", "Corrects name, date of birth, grade and external ID only. Enrollments are unchanged; the audit log keeps before and after values.",
        "transfer", "Now " & open.TeacherName & " · " & open.CampusName & " · IEP " & open.RatioText & " · since " & Text(open.StartDate, "mmm d, yyyy") & ". The current enrollment ends the day before the effective date; attendance before it stays with the old class.",
        "ratio", "Now IEP " & open.RatioText & " with " & open.TeacherName & " since " & Text(open.StartDate, "mmm d, yyyy") & ". The current enrollment ends the day before the effective date and a new one starts at the new ratio.",
        "discharge", "Ends the open enrollment with " & open.TeacherName & " (since " & Text(open.StartDate, "mmm d, yyyy") & ") on the end date. The student becomes Inactive when nothing else is open; history is kept.",
        "archive", "Hides " & sel.DisplayName & " from lists unless Include archived is on. Nothing is deleted.",
        "unarchive", "Returns " & sel.DisplayName & " to Inactive and clears Archived On and Archived By.",
        ""
    )
)
```

DUP = `LookUp(colStuList, Lower(FirstName) = Lower(Trim(txtStuFormFirst.Text)) && Lower(LastName) = Lower(Trim(txtStuFormLast.Text)) && Dob = dpStuFormDob.SelectedDate)` (colStuList holds every student, all campuses).
- F-DUPVIS: `=varStuMode = "add" && Trim(txtStuFormFirst.Text) <> "" && Trim(txtStuFormLast.Text) <> "" && !IsBlank(dpStuFormDob.SelectedDate) && !IsBlank(DUP)`
- F-DUPTEXT: `=With({d: DUP}, "Possible duplicate: " & d.DisplayName & " · " & d.StudentNumber & " · born " & Text(d.Dob, "mmm d, yyyy") & " · " & d.StatusText & " · " & d.TeacherName)`
- F-DUPVIEW: `=With({d: DUP}, Set(varStuSelId, d.StudentId); Set(varStuMode, ""); Select(btnStuHistoryEngine))`
- F-BACKTEXT: `=varStuAttAfter & If(varStuAttAfter = 1, " attendance day", " attendance days") & If(varStuMode = "discharge", " after ", " on or after ") & Text(dpStuFormDate.SelectedDate, "mmm d, yyyy") & If(varStuMode = "discharge", " are already recorded and will stay recorded.", " will stay recorded under the old class.")`

F-CHECK (`lblStuFormCheck.Text`; the submit gate compares with the literal `"Ready to save."`):
```
=With(
    {
        sel: LookUp(colStuList, StudentId = varStuSelId),
        open: First(Sort(Filter(colStuHistory, IsBlank(EndDate)), StartDate, SortOrder.Descending)),
        fn: Trim(txtStuFormFirst.Text), ln: Trim(txtStuFormLast.Text),
        dob: dpStuFormDob.SelectedDate, eff: dpStuFormDate.SelectedDate,
        cmp: ddStuFormCampus.Selected, tch: ddStuFormTeacher.Selected
    },
    With(
        {
            yr: LookUp(colStuYears, YStart <= eff && YEnd >= eff),
            oyr: LookUp(colStuYears, YearId = open.YearId),
            dup: LookUp(colStuList, Lower(FirstName) = Lower(fn) && Lower(LastName) = Lower(ln) && Dob = dob),
            overlap: CountRows(Filter(colStuHistory, EnrId <> open.EnrId && ServiceId = open.ServiceId && (IsBlank(EndDate) || EndDate >= eff))) > 0,
            live: CountRows(Filter(colStuHistory, IsBlank(EndDate) || EndDate >= Today())),
            ackBad: varStuAttAfter > 0 && !chkStuBackdateAck.Checked
        },
        If(
            !CanManageStudents, "Not authorised to manage students.",
            varStuMode = "add",
            If(
                fn = "" || ln = "", "Enter first and last name.",
                IsBlank(dob), "Choose the date of birth.",
                dob > Today(), "Date of birth cannot be in the future.",
                IsBlank(ddStuFormGrade.Selected), "Choose a grade.",
                IsBlank(cmp), "Choose a campus.",
                StudentCampusLock <> ZeroGuid && cmp.Campus <> StudentCampusLock, "Office staff can add students only to their own campus.",
                IsBlank(tch) || tch.Campus.Campus <> cmp.Campus, "Choose a teacher at " & cmp.Name & ".",
                IsBlank(rdoStuFormProgram.Selected), "Choose a program.",
                IsBlank(ddStuFormRatio.Selected), "Choose an IEP ratio.",
                IsBlank(eff), "Choose a start date.",
                IsBlank(yr), "The start date is not inside a school year.",
                IsBlank(ActiveService), "No active service is set up. Ask a System Admin.",
                !IsBlank(dup) && !chkStuDupAck.Checked, "Possible duplicate. Open the existing student, or tick This is a different person.",
                "Ready to save."
            ),
            IsBlank(sel), "Select a student first.",
            StudentCampusLock <> ZeroGuid && sel.CampusId <> StudentCampusLock, "Office staff can change only students at their own campus.",
            varStuMode = "edit",
            If(
                fn = "" || ln = "", "Enter first and last name.",
                IsBlank(dob), "Choose the date of birth.",
                dob > Today(), "Date of birth cannot be in the future.",
                IsBlank(ddStuFormGrade.Selected), "Choose a grade.",
                fn = varStuEditBase.'First Name' && ln = varStuEditBase.'Last Name' && dob = varStuEditBase.'Date of Birth' && ddStuFormGrade.Selected.Value = varStuEditBase.Grade && Trim(txtStuFormExt.Text) = Coalesce(varStuEditBase.'External Client ID', ""), "No changes to save.",
                "Ready to save."
            ),
            varStuMode in ["transfer", "ratio"],
            If(
                IsBlank(open), "No open enrollment to change.",
                sel.StatusText <> "Active", "Only Active students can change class or ratio.",
                IsBlank(eff), "Choose the effective date.",
                eff <= open.StartDate, "The effective date must be after " & Text(open.StartDate, "mmm d, yyyy") & ", when the current enrollment started.",
                IsBlank(oyr) || eff > oyr.YEnd, "The effective date must be inside the " & oyr.YearName & " school year (ends " & Text(oyr.YEnd, "mmm d, yyyy") & ").",
                overlap, "That date overlaps another enrollment for this student and service.",
                varStuMode = "transfer" && IsBlank(cmp), "Choose the new campus.",
                varStuMode = "transfer" && StudentCampusLock <> ZeroGuid && cmp.Campus <> StudentCampusLock, "Office staff can move students only within their own campus.",
                varStuMode = "transfer" && (IsBlank(tch) || tch.Campus.Campus <> cmp.Campus), "Choose a teacher at " & cmp.Name & ".",
                varStuMode = "transfer" && tch.Staff = open.TeacherId && cmp.Campus = open.CampusId, "Choose a different teacher or campus.",
                varStuMode = "ratio" && IsBlank(ddStuFormRatio.Selected), "Choose the new IEP ratio.",
                varStuMode = "ratio" && Text(ddStuFormRatio.Selected.Value) = open.RatioText, "The new ratio must differ from the current " & open.RatioText & ".",
                ackBad, "Tick the confirmation. " & varStuAttAfter & " recorded attendance days stay with the old class.",
                "Ready to save."
            ),
            varStuMode = "discharge",
            If(
                IsBlank(open), "No open enrollment to end.",
                IsBlank(eff), "Choose the last day of service.",
                eff < open.StartDate, "The end date cannot be before " & Text(open.StartDate, "mmm d, yyyy") & ", when the enrollment started.",
                !IsBlank(oyr) && eff > oyr.YEnd, "The end date must be inside the " & oyr.YearName & " school year.",
                Trim(txtStuFormReason.Text) = "", "Enter the reason for discharge.",
                ackBad, "Tick the confirmation. " & varStuAttAfter & " attendance days after the end date stay recorded.",
                "Ready to save."
            ),
            varStuMode = "archive",
            If(sel.StatusText = "Archived", "Already archived.", live > 0, "Archive needs every enrollment closed. " & live & " open or future enrollment(s) remain.", "Ready to save."),
            varStuMode = "unarchive",
            If(sel.StatusText <> "Archived", "Only archived students can be unarchived.", "Ready to save."),
            ""
        )
    )
)
```

F-CANCEL (`btnStuFormCancel.OnSelect`, non-mutating):
`=Set(varStuReceipt, {Kind: "Cancelled", Title: Switch(varStuMode, "add", "Add student", "edit", "Edit details", "transfer", "Change class", "ratio", "Change ratio", "discharge", "Discharge", "archive", "Archive", "unarchive", "Unarchive", "Form") & " cancelled · " & Coalesce(LookUp(colStuList, StudentId = varStuSelId).DisplayName, "no student selected") & " · nothing was changed", StudentId: Coalesce(varStuSelId, ZeroGuid)}); Clear(colStuReceiptLines); Set(varStuMode, ""); Select(btnStuFormResetEngine)`

F-SUBMIT (`btnStuFormSubmit.OnSelect`) — one guarded mutation event; each mode is a literal `Switch` arm
(no default arm). Write it in a `|-` block. Shell:
```
=If(
    varStuMode = "" || lblStuFormCheck.Text <> "Ready to save." || varStuSaving,
    Set(varStuReceipt, {Kind: "Blocked", Title: "Not saved. " & lblStuFormCheck.Text, StudentId: Coalesce(varStuSelId, ZeroGuid)});
    Clear(colStuReceiptLines),
    Set(varStuSaving, true);
    With(
        {
            md: varStuMode, q: varStuSelId,
            fn: Trim(txtStuFormFirst.Text), ln: Trim(txtStuFormLast.Text), dob: dpStuFormDob.SelectedDate,
            gr: ddStuFormGrade.Selected.Value, ext: Trim(txtStuFormExt.Text),
            cmp: ddStuFormCampus.Selected, tch: ddStuFormTeacher.Selected,
            prg: rdoStuFormProgram.Selected.Value, rat: ddStuFormRatio.Selected.Value,
            eff: dpStuFormDate.SelectedDate, note: Trim(txtStuFormReason.Text),
            dupAck: chkStuDupAck.Checked, attAfter: varStuAttAfter,
            open: First(Sort(Filter(colStuHistory, IsBlank(EndDate)), StartDate, SortOrder.Descending))
        },
        With(
            {noteShort: If(note = "", "—", Len(note) > 60, Left(note, 60) & "…", note)},
            Switch(md, "add", ARM-ADD, "edit", ARM-EDIT, "transfer", ARM-TRANSFER, "ratio", ARM-RATIO, "discharge", ARM-DISCHARGE, "archive", ARM-ARCHIVE, "unarchive", ARM-UNARCHIVE)
        )
    );
    Set(varStuSaving, false)
)
```
FAIL(kind, title) below means `Set(varStuReceipt, {Kind: kind, Title: title, StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines)`.
SUCCESS(id) means `Set(varStuSelId, id); Set(varStuMode, ""); Select(btnStuLoadEngine)` (last statement of the arm).
L(a, b) means the record `{Label: a, Value: b}` inside `ClearCollect(colStuReceiptLines, ...)`.
AUDIT(action, id, summary, before, after, reason) means
`IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: summary, Action: 'Action (Audit Events)'.<action>, Entity: "aaca_student", 'Entity ID': Text(id), Before: before, After: after, Reason: reason}), Blank())`.

ARM-ADD:
```
With(
    {yr: LookUp('School Years', 'Start Date' <= eff && 'End Date' >= eff), liveDup: CountRows(Filter(Students, 'First Name' = fn && 'Last Name' = ln && 'Date of Birth' = dob))},
    If(
        liveDup > 0 && !dupAck,
        FAIL("Blocked", "Not saved. " & ln & ", " & fn & " born " & Text(dob, "mmm d, yyyy") & " already exists. Open it, or tick This is a different person."),
        With(
            {s: IfError(Patch(Students, Defaults(Students), {'First Name': fn, 'Last Name': ln, 'Display Name': ln & ", " & fn, 'Date of Birth': dob, Grade: gr, 'External Client ID': If(ext = "", Blank(), ext), 'Status (aaca_status)': 'Status (Students)'.Active}), Blank())},
            If(
                IsBlank(s),
                FAIL("Failed", "Failed. " & ln & ", " & fn & " was not created and nothing was saved. Press Add student to retry."),
                With(
                    {e: IfError(Patch(Enrollments, Defaults(Enrollments), {Name: s.'Student Number' & " " & Text(eff, "yyyy-mm-dd"), Student: s, Campus: cmp, Teacher: tch, Service: ActiveService, 'School Year': yr, Program: prg, 'IEP Ratio': rat, 'Start Date': eff, 'Status (aaca_status)': If(eff <= Today(), 'Status (Enrollments)'.Active, 'Status (Enrollments)'.Planned)}), Blank())},
                    With(
                        {
                            own: If(IsBlank(e) || IsBlank(tch.User), false, !IsBlank(IfError(Patch(Students, s, {Owner: tch.User}), Blank())) && !IsBlank(IfError(Patch(Enrollments, e, {Owner: tch.User}), Blank()))),
                            audit: AUDIT(Create, s.Student, "Student created " & s.'Student Number' & " " & s.'Display Name', "", JSON({StudentNumber: s.'Student Number', FirstName: s.'First Name', LastName: s.'Last Name', DateOfBirth: Text(s.'Date of Birth', "yyyy-mm-dd"), Grade: Text(s.Grade), ExternalClientId: Coalesce(s.'External Client ID', ""), Status: Text(s.'Status (aaca_status)'), EnrollmentId: If(IsBlank(e), "", Text(e.Enrollment)), CampusId: Text(cmp.Campus), TeacherId: Text(tch.Staff), Program: Text(prg), IepRatio: Text(rat), StartDate: Text(eff, "yyyy-mm-dd"), DuplicateAcknowledged: dupAck}), If(dupAck, "Created; duplicate warning confirmed as a different person", "Created in Students screen"))
                        },
                        Set(varStuReceipt, {Kind: If(IsBlank(e), "Failed", "Added"), Title: If(IsBlank(e), "Partly saved. " & s.'Display Name' & " " & s.'Student Number' & " was created but the enrollment was NOT. Ask a System Admin to add it.", "Student added · " & s.'Display Name' & " · " & s.'Student Number'), StudentId: s.Student});
                        ClearCollect(colStuReceiptLines,
                            L("Student number", s.'Student Number'), L("Display name", s.'Display Name'), L("First name", s.'First Name'), L("Last name", s.'Last Name'),
                            L("Date of birth", Text(s.'Date of Birth', "mmm d, yyyy")), L("Grade", Text(s.Grade)), L("External client ID", Coalesce(s.'External Client ID', "—")),
                            L("Student status", Text(s.'Status (aaca_status)')), L("Campus", Coalesce(e.Campus.Name, "NOT saved")), L("Teacher", Coalesce(e.Teacher.Name, "NOT saved")),
                            L("Program", Coalesce(Text(e.Program), "NOT saved")), L("IEP ratio", Coalesce(Text(e.'IEP Ratio'), "NOT saved")), L("Start date", Coalesce(Text(e.'Start Date', "mmm d, yyyy"), "NOT saved")),
                            L("School year", Coalesce(e.'School Year'.Name, "NOT saved")), L("Enrollment status", Coalesce(Text(e.'Status (aaca_status)'), "NOT saved")), L("Service", Coalesce(e.Service.Name, "NOT saved")),
                            L("Record owner", If(IsBlank(tch.User), "Unchanged (teacher has no linked user)", own, tch.User.'Full Name', "Owner update FAILED")),
                            L("Duplicate check", If(dupAck, "Confirmed different person", "No match")), L("Audit event", If(IsBlank(audit), "NOT written", "Create written")));
                        SUCCESS(s.Student)
                    )
                )
            )
        )
    )
)
```

ARM-EDIT (patch only the six identity fields; status, number, archive fields and enrollments are omitted → preserved):
```
With(
    {old: LookUp(Students, ThisRecord.Student = q)},
    If(
        IsBlank(old), FAIL("Failed", "Failed. The student could not be found. Reload and try again."),
        With(
            {s: IfError(Patch(Students, old, {'First Name': fn, 'Last Name': ln, 'Display Name': ln & ", " & fn, 'Date of Birth': dob, Grade: gr, 'External Client ID': If(ext = "", Blank(), ext)}), Blank())},
            If(
                IsBlank(s), FAIL("Failed", "Failed. Details for " & old.'Display Name' & " were not saved. Press Save details to retry."),
                With(
                    {audit: AUDIT(Update, s.Student, "Student details corrected " & s.'Student Number', JSON({FirstName: old.'First Name', LastName: old.'Last Name', DisplayName: old.'Display Name', DateOfBirth: Text(old.'Date of Birth', "yyyy-mm-dd"), Grade: Text(old.Grade), ExternalClientId: Coalesce(old.'External Client ID', "")}), JSON({FirstName: s.'First Name', LastName: s.'Last Name', DisplayName: s.'Display Name', DateOfBirth: Text(s.'Date of Birth', "yyyy-mm-dd"), Grade: Text(s.Grade), ExternalClientId: Coalesce(s.'External Client ID', "")}), If(note = "", "Details corrected", note))},
                    Set(varStuReceipt, {Kind: "Edited", Title: "Details saved · " & s.'Display Name' & " · " & s.'Student Number', StudentId: s.Student});
                    ClearCollect(colStuReceiptLines,
                        L("Student number", s.'Student Number'), L("First name", s.'First Name'), L("Last name", s.'Last Name'), L("Display name", s.'Display Name'),
                        L("Date of birth", Text(s.'Date of Birth', "mmm d, yyyy")), L("Grade", Text(s.Grade)), L("External client ID", Coalesce(s.'External Client ID', "—")),
                        L("Before", old.'Display Name' & " · " & Text(old.'Date of Birth', "mmm d, yyyy") & " · Grade " & Text(old.Grade) & " · ID " & Coalesce(old.'External Client ID', "—")),
                        L("Student status", Text(s.'Status (aaca_status)') & " (unchanged)"), L("Note", noteShort), L("Audit event", If(IsBlank(audit), "NOT written", "Update written with before/after")));
                    SUCCESS(s.Student)
                )
            )
        )
    )
)
```

ARM-TRANSFER:
```
With(
    {old: With({qe: open.EnrId}, LookUp(Enrollments, ThisRecord.Enrollment = qe)), stu: LookUp(Students, ThisRecord.Student = q)},
    With(
        {liveOverlap: With({qs: q, qsv: open.ServiceId, qe: open.EnrId, qd: eff}, CountRows(Filter(Enrollments, Student.Student = qs && Service.Service = qsv && ThisRecord.Enrollment <> qe && (IsBlank('End Date') || 'End Date' >= qd))))},
        If(
            IsBlank(old) || IsBlank(stu) || !IsBlank(old.'End Date'),
            FAIL("Blocked", "Not saved. This enrollment was changed by someone else. The list was reloaded; check the history and try again."); Set(varStuMode, ""); Select(btnStuLoadEngine),
            liveOverlap > 0,
            FAIL("Blocked", "Not saved. The new enrollment would overlap another enrollment for this student and service."),
            With(
                {closed: IfError(Patch(Enrollments, old, {'End Date': DateAdd(eff, -1, TimeUnit.Days), 'End Reason': 'End Reason (Enrollments)'.Transfer, 'Status (aaca_status)': If(eff <= Today(), 'Status (Enrollments)'.Ended, old.'Status (aaca_status)')}), Blank())},
                If(
                    IsBlank(closed),
                    FAIL("Failed", "Failed. Nothing was saved for " & stu.'Display Name' & ". Press Save class change to retry."),
                    With(
                        {ne: IfError(Patch(Enrollments, Defaults(Enrollments), {Name: stu.'Student Number' & " " & Text(eff, "yyyy-mm-dd"), Student: stu, Campus: cmp, Teacher: tch, Service: old.Service, 'School Year': old.'School Year', Program: old.Program, 'IEP Ratio': old.'IEP Ratio', 'Start Date': eff, 'Status (aaca_status)': If(eff <= Today(), 'Status (Enrollments)'.Active, 'Status (Enrollments)'.Planned), 'Previous Enrollment': closed}), Blank())},
                        If(
                            IsBlank(ne),
                            With(
                                {rb: IfError(Patch(Enrollments, closed, {'End Date': Blank(), 'End Reason': Blank(), 'Status (aaca_status)': old.'Status (aaca_status)'}), Blank())},
                                FAIL("Failed", "Failed. The new enrollment was not created. " & If(IsBlank(rb), "The old enrollment is still ended on " & Text(closed.'End Date', "mmm d, yyyy") & "; ask a System Admin to reopen it.", "The old enrollment was reopened; nothing changed.")); Select(btnStuLoadEngine)
                            ),
                            With(
                                {
                                    stuOwn: If(eff <= Today() && !IsBlank(tch.User), !IsBlank(IfError(Patch(Students, stu, {Owner: tch.User}), Blank())), false),
                                    enrOwn: If(IsBlank(tch.User), false, !IsBlank(IfError(Patch(Enrollments, ne, {Owner: tch.User}), Blank()))),
                                    audit: AUDIT(Transfer, stu.Student, "Transfer " & stu.'Student Number' & " to " & tch.Name & " from " & Text(eff, "yyyy-mm-dd"), JSON({EnrollmentId: Text(old.Enrollment), TeacherId: Text(open.TeacherId), Teacher: open.TeacherName, CampusId: Text(open.CampusId), Campus: open.CampusName, StartDate: Text(old.'Start Date', "yyyy-mm-dd"), EndDate: "", Status: Text(old.'Status (aaca_status)')}), JSON({ClosedEnrollmentId: Text(closed.Enrollment), ClosedEndDate: Text(closed.'End Date', "yyyy-mm-dd"), ClosedStatus: Text(closed.'Status (aaca_status)'), NewEnrollmentId: Text(ne.Enrollment), TeacherId: Text(tch.Staff), Teacher: tch.Name, CampusId: Text(cmp.Campus), Campus: cmp.Name, StartDate: Text(ne.'Start Date', "yyyy-mm-dd"), Status: Text(ne.'Status (aaca_status)'), AttendanceDaysKeptWithOldClass: attAfter}), If(note = "", "Class change", note))
                                },
                                Set(varStuReceipt, {Kind: "Transferred", Title: "Class change saved · " & stu.'Display Name' & " · " & stu.'Student Number', StudentId: stu.Student});
                                ClearCollect(colStuReceiptLines,
                                    L("Student number", stu.'Student Number'), L("Effective date", Text(ne.'Start Date', "mmm d, yyyy")),
                                    L("Old teacher", closed.Teacher.Name), L("Old campus", closed.Campus.Name), L("Old enrollment ends", Text(closed.'End Date', "mmm d, yyyy")),
                                    L("Old end reason", Text(closed.'End Reason')), L("Old enrollment status", Text(closed.'Status (aaca_status)')),
                                    L("New teacher", ne.Teacher.Name), L("New campus", ne.Campus.Name), L("New enrollment status", Text(ne.'Status (aaca_status)')),
                                    L("IEP ratio (carried)", Text(ne.'IEP Ratio')), L("Program (carried)", Text(ne.Program)), L("School year", ne.'School Year'.Name),
                                    L("Linked to previous", If(ne.'Previous Enrollment'.Enrollment = closed.Enrollment, "Yes", "No")),
                                    L("Student owner", If(stuOwn, tch.User.'Full Name', eff > Today(), "Unchanged (effective date is in the future)", IsBlank(tch.User), "Unchanged (teacher has no linked user)", "Owner update FAILED")),
                                    L("Enrollment owner", If(enrOwn, tch.User.'Full Name', IsBlank(tch.User), "Default (teacher has no linked user)", "Owner update FAILED")),
                                    L("Recorded days kept with old class", Text(attAfter)), L("Note", noteShort), L("Audit event", If(IsBlank(audit), "NOT written", "Transfer written")));
                                SUCCESS(stu.Student)
                            )
                        )
                    )
                )
            )
        )
    )
)
```

ARM-RATIO: identical structure to ARM-TRANSFER with these differences only — `'End Reason': 'End Reason (Enrollments)'.'Ratio Change'`;
new enrollment `Campus: old.Campus, Teacher: old.Teacher, 'IEP Ratio': rat` (Service, School Year, Program, Previous Enrollment as transfer);
no Student owner patch; `enrOwn: If(IsBlank(old.Teacher.User), false, !IsBlank(IfError(Patch(Enrollments, ne, {Owner: old.Teacher.User}), Blank())))`;
failure titles say "Save ratio change"; audit `AUDIT(Update, stu.Student, "IEP ratio change " & stu.'Student Number' & " " & Text(old.'IEP Ratio') & " to " & Text(rat) & " from " & Text(eff, "yyyy-mm-dd"), JSON({EnrollmentId: Text(old.Enrollment), IepRatio: Text(old.'IEP Ratio'), StartDate: Text(old.'Start Date', "yyyy-mm-dd"), EndDate: ""}), JSON({ClosedEnrollmentId: Text(closed.Enrollment), ClosedEndDate: Text(closed.'End Date', "yyyy-mm-dd"), NewEnrollmentId: Text(ne.Enrollment), IepRatio: Text(ne.'IEP Ratio'), StartDate: Text(ne.'Start Date', "yyyy-mm-dd"), Status: Text(ne.'Status (aaca_status)'), AttendanceDaysKeptWithOldClass: attAfter}), "IEP ratio change" & If(note = "", "", ". " & note))`;
Kind `"RatioChanged"`, Title `"Ratio change saved · " & stu.'Display Name' & " · " & stu.'Student Number'`; lines:
`L("Student number", ...)`, `L("Effective date", Text(ne.'Start Date', "mmm d, yyyy"))`, `L("Old ratio", Text(closed.'IEP Ratio'))`, `L("New ratio", Text(ne.'IEP Ratio'))`,
`L("Old enrollment ends", Text(closed.'End Date', "mmm d, yyyy"))`, `L("Old end reason", Text(closed.'End Reason'))`, `L("Old enrollment status", Text(closed.'Status (aaca_status)'))`,
`L("New enrollment status", Text(ne.'Status (aaca_status)'))`, `L("Teacher (unchanged)", ne.Teacher.Name)`, `L("Campus (unchanged)", ne.Campus.Name)`, `L("Program (carried)", Text(ne.Program))`,
`L("Linked to previous", ...)`, `L("Enrollment owner", If(enrOwn, old.Teacher.User.'Full Name', IsBlank(old.Teacher.User), "Default (teacher has no linked user)", "Owner update FAILED"))`,
`L("Recorded days kept with old class", Text(attAfter))`, `L("Note", noteShort)`, `L("Audit event", If(IsBlank(audit), "NOT written", "Update written"))`.

ARM-DISCHARGE:
```
With(
    {old: With({qe: open.EnrId}, LookUp(Enrollments, ThisRecord.Enrollment = qe)), stu: LookUp(Students, ThisRecord.Student = q)},
    If(
        IsBlank(old) || IsBlank(stu) || !IsBlank(old.'End Date'),
        FAIL("Blocked", "Not saved. This enrollment was changed by someone else. The list was reloaded; check the history and try again."); Set(varStuMode, ""); Select(btnStuLoadEngine),
        With(
            {closed: IfError(Patch(Enrollments, old, {'End Date': eff, 'End Reason': 'End Reason (Enrollments)'.Discharge, 'Status (aaca_status)': If(eff <= Today(), 'Status (Enrollments)'.Ended, old.'Status (aaca_status)')}), Blank())},
            If(
                IsBlank(closed), FAIL("Failed", "Failed. Nothing was saved for " & stu.'Display Name' & ". Press Discharge student to retry."),
                With(
                    {others: With({qs: q, qe: closed.Enrollment}, CountRows(Filter(Enrollments, Student.Student = qs && ThisRecord.Enrollment <> qe && (IsBlank('End Date') || 'End Date' >= Today()))))},
                    With(
                        {s2: If(others = 0, IfError(Patch(Students, stu, {'Status (aaca_status)': 'Status (Students)'.Inactive}), Blank()), stu)},
                        With(
                            {audit: AUDIT(Discharge, stu.Student, "Discharge " & stu.'Student Number' & " end " & Text(eff, "yyyy-mm-dd"), JSON({EnrollmentId: Text(old.Enrollment), EndDate: "", EnrollmentStatus: Text(old.'Status (aaca_status)'), StudentStatus: Text(stu.'Status (aaca_status)')}), JSON({EnrollmentId: Text(closed.Enrollment), EndDate: Text(closed.'End Date', "yyyy-mm-dd"), EndReason: Text(closed.'End Reason'), EnrollmentStatus: Text(closed.'Status (aaca_status)'), StudentStatus: If(IsBlank(s2), "update failed", Text(s2.'Status (aaca_status)')), AttendanceDaysAfterEnd: attAfter}), note)},
                            Set(varStuReceipt, {Kind: "Discharged", Title: "Discharged · " & stu.'Display Name' & " · " & stu.'Student Number', StudentId: stu.Student});
                            ClearCollect(colStuReceiptLines,
                                L("Student number", stu.'Student Number'), L("Teacher", closed.Teacher.Name), L("Campus", closed.Campus.Name),
                                L("Enrollment start", Text(closed.'Start Date', "mmm d, yyyy")), L("End date", Text(closed.'End Date', "mmm d, yyyy")),
                                L("End reason", Text(closed.'End Reason')), L("Enrollment status", Text(closed.'Status (aaca_status)')),
                                L("Student status", If(IsBlank(s2), "Status update FAILED", Text(s2.'Status (aaca_status)'))),
                                L("Other open or planned enrollments", Text(others)), L("Recorded days after end date", Text(attAfter)),
                                L("Reason", noteShort), L("Audit event", If(IsBlank(audit), "NOT written", "Discharge written")));
                            SUCCESS(stu.Student)
                        )
                    )
                )
            )
        )
    )
)
```

ARM-ARCHIVE:
```
With(
    {stu: LookUp(Students, ThisRecord.Student = q), liveOpen: With({qs: q}, CountRows(Filter(Enrollments, Student.Student = qs && (IsBlank('End Date') || 'End Date' >= Today()))))},
    If(
        IsBlank(stu), FAIL("Failed", "Failed. The student could not be found. Reload and try again."),
        stu.'Status (aaca_status)' = 'Status (Students)'.Archived, FAIL("Blocked", "Not saved. " & stu.'Display Name' & " is already archived."); Select(btnStuLoadEngine),
        liveOpen > 0, FAIL("Blocked", "Not saved. Archive needs every enrollment closed. " & liveOpen & " open or future enrollment(s) remain."),
        With(
            {s: IfError(Patch(Students, stu, {'Status (aaca_status)': 'Status (Students)'.Archived, 'Archived On': Today(), 'Archived By': CurrentUserRow}), Blank())},
            If(
                IsBlank(s), FAIL("Failed", "Failed. " & stu.'Display Name' & " was not archived. Press Archive student to retry."),
                With(
                    {audit: AUDIT(Archive, s.Student, "Archived " & s.'Student Number' & " " & s.'Display Name', JSON({Status: Text(stu.'Status (aaca_status)'), ArchivedOn: "", ArchivedBy: ""}), JSON({Status: Text(s.'Status (aaca_status)'), ArchivedOn: Text(s.'Archived On', "yyyy-mm-dd"), ArchivedBy: s.'Archived By'.'Full Name'}), If(note = "", "Archived", note))},
                    Set(varStuReceipt, {Kind: "Archived", Title: "Archived · " & s.'Display Name' & " · " & s.'Student Number', StudentId: s.Student});
                    ClearCollect(colStuReceiptLines,
                        L("Operation", "Archive"), L("Student number", s.'Student Number'), L("Previous status", Text(stu.'Status (aaca_status)')),
                        L("Expected status", "Archived"), L("Status", Text(s.'Status (aaca_status)')),
                        L("Archived on", Text(s.'Archived On', "mmm d, yyyy")), L("Archived by", s.'Archived By'.'Full Name'),
                        L("Note", noteShort), L("Audit event", If(IsBlank(audit), "NOT written", "Archive written")));
                    SUCCESS(s.Student)
                )
            )
        )
    )
)
```

ARM-UNARCHIVE: guard `stu.'Status (aaca_status)' <> 'Status (Students)'.Archived` → FAIL("Blocked", "Not saved. " & stu.'Display Name' & " is not archived."); Select(btnStuLoadEngine);
patch `Patch(Students, stu, {'Status (aaca_status)': 'Status (Students)'.Inactive, 'Archived On': Blank(), 'Archived By': Blank()})`;
audit `AUDIT(Unarchive, s.Student, "Unarchived " & s.'Student Number' & " " & s.'Display Name', JSON({Status: Text(stu.'Status (aaca_status)'), ArchivedOn: Text(stu.'Archived On', "yyyy-mm-dd"), ArchivedBy: stu.'Archived By'.'Full Name'}), JSON({Status: Text(s.'Status (aaca_status)'), ArchivedOn: "", ArchivedBy: ""}), If(note = "", "Unarchived", note))`;
Kind `"Unarchived"`, Title `"Unarchived · " & s.'Display Name' & " · " & s.'Student Number'`; lines `L("Operation", "Unarchive")`,
`L("Student number", s.'Student Number')`, `L("Previous status", Text(stu.'Status (aaca_status)'))`, `L("Expected status", "Inactive")`,
`L("Status", Text(s.'Status (aaca_status)'))`, `L("Archived on", If(IsBlank(s.'Archived On'), "Cleared", Text(s.'Archived On', "mmm d, yyyy")))`,
`L("Archived by", If(IsBlank(s.'Archived By'), "Cleared", s.'Archived By'.'Full Name'))`, `L("Note", noteShort)`,
`L("Audit event", If(IsBlank(audit), "NOT written", "Unarchive written"))`; then SUCCESS(s.Student).

## Numeric Layout Budgets

- Root/header: header 124 (140 phone). Denied panel 164 (204 phone).
- List panel (vertical, fixed 844): 16 + head 44 + 8 + search 58 + 8 + scope 58 + 8 + status 58 + 8 + filter actions 44 + 8 + count 54 + 8 + gallery 448 + 16 = 844.
  Horizontal rows at phone inner width 358 (390 − 32): head 80 + 44 + 140 + 16 = 280; scope 140 + 8 + 140 = 288;
  status radio 4 options ≈ 300; filter actions 180 + 8 + 120 = 308. At 1024 side-by-side list inner = (1024 − 8) × 2/5 − 32 = 374: all rows fit (max 308).
- List row (TemplateSize 116): 6 + top 44 + 2 + meta 18 + 2 + placement 36 + 6 = 114. Row top at phone: 358 − 16 = 342 = name (≥ 178, 2 lines × 21 = 42) + 8 + badge 84 + 8 + View 64 → fits; at 1024: name 194.
- Body: side-by-side height = Max(844, right column); stacked = 852 (when list visible) + right column.
- Detail (conStuDetail width DW): profile = [52 if root < 1024] + name 30|60 + 8 + facts 40|60 + 8 + placement 60|80 + 8 + actions A + 8 + hint 40|60 + 8 + 24 + 8 + (history 348 or empty 40); A = 44 when DW − 32 ≥ 600 (120+120+120+104+104+4×8 = 600), 96 when ≥ 376 (rows 376 + 216), else 148 (rows 248 + 232 + 104). Desktop 1366: DW = 815 → profile 634, detail 666. Phone: profile 880, detail 912.
- History row (TemplateSize 116): 8 + dates 20 + 2 + placement 36 + 2 + end 36 + 8 = 112; phone text width ≈ 314 → placement ≈ 85 chars = 2 lines at Size 12.
- Form (conStuForm width FW; n = FW < 700): 16 + title 28|56 + 8 + context 60|100 + 8 + [identity 306+8 add/edit] + [place 120+8 add/transfer] + [program 58+8 add] + [ratio 58+8 add/ratio] + [date 58+8 add/transfer/ratio/discharge] + [reason 86+8 non-add] + [dup 156|176 + 8 when visible] + [backdate 104|124 + 8 when visible] + check 40|60 + 8 + actions 44 + 16. Desktop add (no dup) = 868. Actions row: 190 + 8 + 96 = 294 ≤ 326 (phone inner).
- Receipt: 8 + top 44|84 + [4 + Min(400, RoundUp(lines/wrap) × 40)] + 8; row: label 150 + 8 + value (fill) with 2 × 18 lines + 4 padding = 40. Longest title ≈ 110 chars → 3 lines × 20 at 270 px phone = 60 ≤ 84.

F-FORMH (`conStuForm.Height`):
```
=With(
    {m: varStuMode, n: Self.Width < 700},
    16 + If(n, 56, 28) + 8 + If(n, 100, 60) + 8
    + If(m in ["add", "edit"], 306 + 8, 0)
    + If(m in ["add", "transfer"], 120 + 8, 0)
    + If(m = "add", 58 + 8, 0)
    + If(m in ["add", "ratio"], 58 + 8, 0)
    + If(m in ["add", "transfer", "ratio", "discharge"], 58 + 8, 0)
    + If(m in ["transfer", "ratio", "discharge", "edit", "archive", "unarchive"], 86 + 8, 0)
    + If(conStuDup.Visible, If(n, 176, 156) + 8, 0)
    + If(conStuBackdate.Visible, If(n, 124, 104) + 8, 0)
    + If(n, 60, 40) + 8 + 44 + 16
)
```
F-PROFH (`conStuProfile.Height`):
`=If(conStuRoot.Width < 1024, 52, 0) + If(conStuDetail.Width < 700, 60, 30) + 8 + If(conStuDetail.Width < 700, 60, 40) + 8 + If(conStuDetail.Width < 700, 80, 60) + 8 + If(conStuDetail.Width - 32 >= 600, 44, conStuDetail.Width - 32 >= 376, 96, 148) + 8 + If(conStuDetail.Width < 700, 60, 40) + 8 + 24 + 8 + If(CountRows(colStuHistory) = 0, 40, 348)`

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| ------ | ------------ | -------------- | ------------- | -------------- | --------------- |
| StudentsScreen | conStuRoot (sole top-level child) | AutoLayout | `conStuRoot.Width: =Parent.Width` | `conStuRoot.Height: =Parent.Height` | `LayoutOverflowY: =LayoutOverflow.Scroll`; galleries scroll internally with fixed heights |

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --------- | -------------- | -------------- | ------------ | ------------- | ------------- | ------------------------ |
| STU/list/name | galStuList row | Canonical identity | Students.'Display Name' | lblStuRowName | `=ThisItem.DisplayName` | Row top line, 2-line wrap, always visible |
| STU/list/number | galStuList row | Student number | Students.'Student Number' | lblStuRowMeta | `ThisItem.StudentNumber & ...` | Line 2 |
| STU/list/grade | galStuList row | Grade | Students.Grade | lblStuRowMeta | `... " · Grade " & ThisItem.GradeText ...` | Line 2 |
| STU/list/ratio | galStuList row | IEP ratio | placement Enrollment.'IEP Ratio' | lblStuRowMeta | `... " · IEP " & ThisItem.RatioText` | Line 2 |
| STU/list/teacher | galStuList row | Current teacher | placement Enrollment.Teacher.Name | lblStuRowPlacement | `... ThisItem.TeacherName & ...` | Line 3, 2-line wrap |
| STU/list/campus | galStuList row | Campus | placement Enrollment.Campus.Name | lblStuRowPlacement | `... " · " & ThisItem.CampusName` | Line 3 |
| STU/list/status | galStuList row | Status | Students.'Status (aaca_status)' | badgeStuRowStatus | `Content: =ThisItem.StatusText` | Row top line, W 84 |
| STU/detail/name | conStuProfile | Canonical identity | Students.'Display Name' | lblStuDetailName | `=LookUp(colStuList, StudentId = varStuSelId).DisplayName` | Profile head, Size 20 |
| STU/detail/status | conStuProfile | Status | Students status | badgeStuDetailStatus | `Content: =LookUp(colStuList, StudentId = varStuSelId).StatusText` | Profile head |
| STU/detail/facts | conStuProfile | Number, grade, DOB, external ID, archived on | Students fields | lblStuDetailFacts | F-FACTS | Under head |
| STU/detail/placement | conStuProfile | Current + planned teacher, campus, ratio, program, dates | colStuHistory (live Enrollments) | lblStuDetailPlacement | F-PLACE | Under facts |
| STU/history/dates | galStuHistory row | Start – end dates, status | Enrollment Start/End Date, Status | lblStuHistDates | see table | Row line 1 |
| STU/history/placement | galStuHistory row | Teacher, campus, ratio, program, school year | Enrollment lookups/choices | lblStuHistPlacement | see table | Row line 2 |
| STU/history/end | galStuHistory row | End reason, previous-enrollment link | Enrollment 'End Reason', 'Previous Enrollment' | lblStuHistEnd | F-HISTEND | Row line 3 |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| ----------- | --------------- | --------------- | ------------------------- |
| SURF-STU-NAV | conStuNav | `=CanManageStudents` | Office/Admin; hidden otherwise |
| SURF-STU-DENIED | conStuDenied | `=!CanManageStudents` | Teacher / Read-only / not set up; hidden for Office/Admin |
| SURF-STU-BODY | conStuBody | `=CanManageStudents` | Office/Admin; hidden otherwise |
| SURF-STU-RECEIPT | conStuReceipt | `=varStuReceipt.Kind <> ""` | After any submit/cancel until Dismiss or next action |
| SURF-STU-LIST | conStuListPanel | `=!(conStuRoot.Width < 1024 && (!IsBlank(varStuSelId) \|\| varStuMode <> ""))` | Always side-by-side; stacked only when nothing is selected/open |
| SURF-STU-FORM | conStuForm | `=varStuMode <> ""` | While an action form is open |
| SURF-STU-F-IDENTITY | conStuFormIdentity | `=varStuMode in ["add", "edit"]` | Add, Edit |
| SURF-STU-F-PLACE | conStuFormPlace | `=varStuMode in ["add", "transfer"]` | Add, Change class |
| SURF-STU-F-PROGRAM | conStuFormProgram | `=varStuMode = "add"` | Add |
| SURF-STU-F-RATIO | conStuFormRatio | `=varStuMode in ["add", "ratio"]` | Add, Change ratio |
| SURF-STU-F-DATE | conStuFormDate | `=varStuMode in ["add", "transfer", "ratio", "discharge"]` | Dated actions |
| SURF-STU-F-REASON | conStuFormReason | `=varStuMode in ["transfer", "ratio", "discharge", "edit", "archive", "unarchive"]` | All but Add |
| SURF-STU-DUP | conStuDup | F-DUPVIS | Add with a name + DOB match |
| SURF-STU-BACKDATE | conStuBackdate | `=varStuMode in ["transfer", "ratio", "discharge"] && varStuAttAfter > 0` | Dated change over recorded attendance |
| SURF-STU-PROFILE | conStuProfile | `=!IsBlank(varStuSelId)` | A student is selected |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| ------ | ------------- | --------------------- | -------------------- | ---------------------------- | ------------------ | ----------------- | --------------------- |
| A-NAV-ATTENDANCE | CanManageStudents | `btnStuNavAttendance.OnSelect: =Navigate(Screen1)` | N/A | Screen1 shown | N/A | N/A | `btnAttNavAttendance` Primary; month grid |
| A-NAV-STUDENTS (current item) | CanManageStudents | `btnStuNavStudents.OnSelect: =Navigate(StudentsScreen)` | N/A | Stays | N/A | N/A | Primary = current |
| A-LOAD-STUDENTS | CanManageStudents | `StudentsScreen.OnVisible`, `btnStuReload.OnSelect` → `Select(btnStuLoadEngine)` | Students, Enrollments (window from Jul 1 prior year), School Years, Campuses, Staff | Caches rebuilt; history re-queried for `varStuSelId` | N/A | N/A | galStuList rows; lblStuCount "Showing n of m"; lblStuNotice on error |
| A-FILTER-STUDENTS | Loaded | txtStuSearch, rdoStuStatus, tglStuArchived, ddStuCampus (Admin), ddStuTeacher, btnStuClearFilters | colStuList | Items = F-LIST (PRED) | N/A | N/A | galStuList; lblStuCount names every active criterion and the zero-result message |
| A-SELECT-STUDENT | Row visible | `btnStuRowView.OnSelect` (and `btnStuDupView`) sets `varStuSelId` + `Select(btnStuHistoryEngine)` | Students.Student GUID | Profile + history for that ID | N/A | N/A | lblStuDetailName, badgeStuDetailStatus, galStuHistory (live Enrollments of that student), row highlight |
| A-ADD-STUDENT | CanManageStudents; F-CHECK = "Ready to save." | `btnStuAdd` → form → `btnStuFormSubmit.OnSelect` arm "add" | New Students.Student (returned `s`), new Enrollments.Enrollment (`e`) | Student Active + Enrollment (Active if start ≤ today else Planned) + owner (if teacher has user) + Audit Create | Students: First Name, Last Name, Display Name, Date of Birth, Grade, External Client ID, Status, Owner*; Enrollments: Name, Student, Campus, Teacher, Service, School Year, Program, IEP Ratio, Start Date, Status, Owner*; Audit Event | Student number, display/first/last name, DOB, grade, external ID, student status, campus, teacher, program, IEP ratio, start date, school year, enrollment status, service, record owner, duplicate check, audit | galStuReceipt lines from `s`/`e`; then `varStuSelId = s.Student` + reload → highlighted row + profile + history |
| A-EDIT-STUDENT | Selected; campus OK; changed values | `btnStuActEdit` (prefill from live `varStuEditBase`) → submit arm "edit" | Students.Student = `varStuSelId` | Six identity fields updated; everything else preserved; Audit Update with Before/After JSON | First Name, Last Name, Display Name, Date of Birth, Grade, External Client ID; Audit Event | Number, first, last, display, DOB, grade, external ID, before summary, status (unchanged), note, audit | receipt; profile/list after reload |
| A-EDIT-CANCEL / any cancel | Form open | `btnStuFormCancel.OnSelect` F-CANCEL | none | No write; mode cleared | N/A | Title "… cancelled · name · nothing was changed" | conStuReceipt (Kind Cancelled); profile unchanged |
| A-TRANSFER | Selected Active; OPEN exists; campus OK; F-CHECK ready | `btnStuActTransfer` → submit arm "transfer" | OPEN.EnrId → Enrollments; new returned `ne`; Students.Student | Old End Date = E−1, End Reason Transfer, Status Ended if E ≤ today; new enrollment from E (Active/Planned) linked via Previous Enrollment; Student owner → new teacher user when E ≤ today; Audit Transfer | Old: End Date, End Reason, Status; New: Name, Student, Campus, Teacher, Service, School Year, Program, IEP Ratio, Start Date, Status, Previous Enrollment, Owner*; Student Owner*; Audit | Number, effective date, old teacher/campus/end/end reason/status, new teacher/campus/status, ratio, program, school year, linked, student owner, enrollment owner, kept days, note, audit | receipt; galStuHistory shows both rows (old ended, new with "continues from") |
| A-CHANGE-RATIO | as transfer | `btnStuActRatio` → arm "ratio" | as transfer | Same close/open, End Reason Ratio Change, same teacher/campus, new ratio; Audit Update "IEP ratio change" | Old: End Date, End Reason, Status; New: same set with IEP Ratio = new, Owner*; Audit | Number, effective date, old ratio, new ratio, old end/end reason/status, new status, teacher, campus, program, linked, enrollment owner, kept days, note, audit | receipt; history rows |
| A-DISCHARGE | Selected Active; OPEN exists; reason entered | `btnStuActDischarge` → arm "discharge" | OPEN.EnrId; Students.Student | End Date = D, End Reason Discharge, Status Ended if D ≤ today; Student Inactive when no other open/future enrollment; Audit Discharge | Enrollment: End Date, End Reason, Status; Student: Status (conditional); Audit | Number, teacher, campus, start, end date, end reason, enrollment status, student status, other open count, days after end, reason, audit | receipt; badge; history |
| A-ARCHIVE | Status ≠ Archived; no enrollment with blank End Date or End Date ≥ today | `btnStuActArchive` (selector, sets `varStuMode = "archive"`) → arm "archive" | Students.Student | Status Archived, Archived On today, Archived By current user; Audit Archive | Status, Archived On, Archived By; Audit | Operation, number, previous status, expected status, status, archived on, archived by, note, audit | receipt; profile badge "Archived"; row leaves default list |
| A-UNARCHIVE | Status = Archived | `btnStuActUnarchive` (selector `"unarchive"`) → arm "unarchive" | Students.Student | Status Inactive; Archived On/By cleared; Audit Unarchive | Status, Archived On, Archived By; Audit | Operation, number, previous status, expected status, status, archived on (Cleared), archived by (Cleared), note, audit | receipt; badge "Inactive" |

`*` Owner fields are written only when the teacher's `Staff.User` is not blank (seed teachers have none).

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| -------------- | ------------------------ | ------------------- |
| txtStuSearch | lblStuSearch | conStuSearchField |
| ddStuCampus | lblStuCampus | conStuCampusField |
| ddStuTeacher | lblStuTeacher | conStuTeacherField |
| rdoStuStatus | lblStuStatus | conStuStatusField |
| txtStuFormFirst / txtStuFormLast / dpStuFormDob / ddStuFormGrade / txtStuFormExt | lblStuFormFirst / lblStuFormLast / lblStuFormDob / lblStuFormGrade / lblStuFormExt | conStuFormIdentity |
| ddStuFormCampus / ddStuFormTeacher | lblStuFormCampus / lblStuFormTeacher | conStuFormPlace |
| rdoStuFormProgram | lblStuFormProgram | conStuFormProgram |
| ddStuFormRatio | lblStuFormRatio | conStuFormRatio |
| dpStuFormDate | lblStuFormDate | conStuFormDate |
| txtStuFormReason | lblStuFormReason | conStuFormReason |

Labels never carry their own `Visible`; only the declared field-group surfaces are conditional.

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization | Destination focus |
| ------ | --------------- | ----------------------------- | ---------------------------------- | -------------------- | --------------- | ----------------- |
| A-ADD-STUDENT | `s`, `e` Patch results → varStuReceipt + colStuReceiptLines | Students / Enrollments (Dataverse) | galStuList row + conStuProfile + galStuHistory | `s.Student` → `varStuSelId` → colStuList/colStuHistory rows | `Select(btnStuLoadEngine)` after success (requery) | row highlight + profile by `varStuSelId` |
| A-EDIT-STUDENT | `s`, `old` | Students | profile, list row | `varStuSelId` = q = `s.Student` | reload | same |
| A-TRANSFER / A-CHANGE-RATIO | `closed`, `ne` | Enrollments | galStuHistory, lblStuDetailPlacement, list placement | `open.EnrId` → `closed.Enrollment`; `ne.'Previous Enrollment'` = closed; student `q` | reload (incl. history) | profile stays on `q` |
| A-DISCHARGE | `closed`, `s2` | Enrollments, Students | history, badge, list | `open.EnrId`, `q` | reload | same |
| A-ARCHIVE / A-UNARCHIVE | `s` (+ pre-state `stu`) | Students | badge, list filter result | `q` = `s.Student` | reload | same |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| ------ | ----- | -------------- | ---------------------------- | ------------------------------- | --------------------- | ------------------- |
| ADD | First/Last/Display Name, DOB, Grade, External ID, Status | Changed | Trim(txt…), dpStuFormDob, ddStuFormGrade, "Active" | Patch(Students, Defaults) | lines First/Last/Display name, DOB, Grade, External client ID, Student status | lblStuDetailName, F-FACTS, badge |
| ADD | Enrollment Campus, Teacher, Program, IEP Ratio, Start Date, Status, School Year, Service | Changed | dd/rdo/dp inputs; yr lookup; ActiveService | Patch(Enrollments, Defaults) | lines Campus, Teacher, Program, IEP ratio, Start date, Enrollment status, School year, Service | F-PLACE, galStuHistory |
| ADD | Owner (student + enrollment) | Changed (conditional) | tch.User | Patch {Owner} | line Record owner | Dataverse owner |
| EDIT | six identity fields | Changed | inputs prefilled from varStuEditBase | Patch(Students, old, {6 fields}) | six lines | profile |
| EDIT | Status, Student Number, Archived On/By, enrollments | Preserved | live `old` | omitted from partial Patch | line Student status "(unchanged)" | badge, F-FACTS, history |
| TRANSFER | old End Date, End Reason, Status | Changed | eff; old status | Patch(Enrollments, old, …) | Old enrollment ends / Old end reason / Old enrollment status | galStuHistory row |
| TRANSFER | new Campus, Teacher, Start Date, Status, Previous Enrollment | Changed | cmp, tch, eff | Patch(Enrollments, Defaults) | New campus / New teacher / Effective date / New enrollment status / Linked | history row |
| TRANSFER | IEP Ratio, Program, Service, School Year | Preserved (carried) | `old` live record | copied from `old` | IEP ratio (carried), Program (carried), School year | history row |
| TRANSFER | Student Owner / Enrollment Owner | Changed (conditional) | tch.User, eff ≤ today | Patch {Owner} | Student owner / Enrollment owner | Dataverse owner |
| TRANSFER | Attendance rows | Preserved | Attendance (not written) | no write | Recorded days kept with old class | Screen1 old teacher grid |
| RATIO | new IEP Ratio; old End Date/Reason/Status; new Status/Start | Changed | rat, eff | as transfer | Old ratio / New ratio / Old enrollment ends / Old end reason / statuses / Effective date | history |
| RATIO | Teacher, Campus, Program, Service, School Year | Preserved (carried) | `old` | copied | Teacher (unchanged), Campus (unchanged), Program (carried) | history |
| DISCHARGE | End Date, End Reason, Status; Student Status | Changed | eff; others = 0 | Patch old; Patch stu | End date / End reason / Enrollment status / Student status | history, badge |
| ARCHIVE | Status, Archived On, Archived By | Changed | "Archived", Today(), CurrentUserRow | Patch(Students, stu, …) | Status / Archived on / Archived by (+ Previous/Expected status) | badge, F-FACTS |
| UNARCHIVE | Status, Archived On, Archived By | Changed | "Inactive", Blank(), Blank() | Patch(Students, stu, …) | Status / Archived on "Cleared" / Archived by "Cleared" | badge |
| ARCHIVE/UNARCHIVE | Name, DOB, grade, enrollments | Preserved | live `stu` | omitted | — | profile, history |

## Directional (state pair) evidence — Archive / Unarchive

Shared-operation flow: selectors `btnStuActArchive.OnSelect` / `btnStuActUnarchive.OnSelect` only set
`varStuMode` ("archive" / "unarchive") and reset the form; the single guarded mutation event is
`btnStuFormSubmit.OnSelect`, whose literal `Switch` arms `"archive"` and `"unarchive"` patch Status.
Operation state resets: `StudentsScreen.OnVisible: =Set(varStuMode, ""); …` and `Set(varStuMode, "")` in every
SUCCESS. Gate: `btnStuFormSubmit.DisplayMode` requires `varStuMode <> ""` and F-CHECK ready. Selected ID:
`varStuSelId` (OnStart Blank, assigned by btnStuRowView/btnStuDupView, consumed by gates, arms via `q`, receipt).
Compound: Inactive → Archive → Archived → Unarchive → Inactive; the unarchive arm reads
`stu: LookUp(Students, ThisRecord.Student = q)` live, so its "Previous status" is the persisted Archived value.

## Functional Test Scenarios

Seed: 3 campuses (ALP/BET/GAM), 12 "Seed …" teachers (no linked Users), 112 students "SEED-0001".."SEED-0112",
school years 2025-2026 (Closed) and 2026-2027 (Current, Aug 12 2026 – Jul 30 2027), one seed student with a
Planned future transfer; today 2026-09-29. S1 = an Active ALP student with one open enrollment since 2026-08-12
at IEP 1:1 (teacher T_A); T_B = another ALP teacher; T_C = a BET teacher.

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| -------- | ----- | ---- | ---- | ---------------- | ------------------------- |
| S-NAV-OFFICE | Office/Admin | Open StudentsScreen from header | Students list loads | btnStuNavStudents Primary; lblStuCount "Showing n of m" | Attendance button returns to Screen1 |
| S-NAV-TEACHER-HIDDEN | Teacher or Read-only reaches the screen | Screen visible | Only denied panel; body hidden | conStuDenied | No nav row in header |
| S-OFFICE-SCOPE | Office user at ALP | Open screen | ddStuCampus disabled on Seed Campus Alpha; only ALP placements listed | galStuList, lblStuCount | Actions on a non-ALP student (opened via duplicate link) disabled with hint |
| S-SEARCH | Admin, All campuses, status Active | Type `SEED-000` | SEED-0001..SEED-0009 listed, SEED-0100 excluded | galStuList, lblStuCount shows `search "SEED-000"` | Clear filters restores all; `zzz` shows zero-result text |
| S-ARCHIVED-HIDDEN | S3 archived (S-ARCHIVE-OK) | Default filters; then status Archived without toggle; then toggle on | Hidden; message "Archived students are hidden…"; then S3 listed | galStuList, lblStuCount | Status All + toggle off still hides S3 |
| S-ADD-OK | Admin; campus ALP | + Add student: Test / Pupil, DOB 2016-05-10, Grade 4, ext blank, ALP, T_A, Regular Year, 1:1, start 2026-09-29 → Add student | Student Active "Pupil, Test" with new STU number; enrollment Active 2026-2027 1:1 T_A; Audit Create | receipt lines (all 19); row highlighted; history 1 row | Owner line "Unchanged (teacher has no linked user)" |
| S-ADD-DUPLICATE | S1 exists | Add with S1's first/last (different case) + DOB | conStuDup shows S1 name/number; Save disabled until tick | lblStuFormCheck, conStuDup | "Open existing student" selects S1, closes form, no write |
| S-ADD-MISSING | Add form | Leave Grade blank | Check "Choose a grade."; Save disabled | lblStuFormCheck | Future DOB → "cannot be in the future" |
| S-EDIT-OK | S4 grade 3, ext SEED-0004 | Edit details → Grade 4, ext SEED-0004A → Save details | Students row updated; Audit Update Before/After | receipt Grade 4 / SEED-0004A / Before line | Unchanged values → "No changes to save." |
| S-EDIT-CANCEL | Edit form with a changed first name | Cancel | No write | receipt "Edit details cancelled · … nothing was changed"; profile name unchanged | — |
| S-TRANSFER-TODAY | S1 | Change class → ALP, T_B, effective 2026-09-29, tick confirm if shown | Old ends 2026-09-28 Transfer Ended; new from 2026-09-29 T_B Active linked | receipt; galStuHistory 2 rows ("continues from Aug 12, 2026") | Same teacher+campus → "Choose a different teacher or campus." |
| S-TRANSFER-FUTURE | S2 like S1 | Effective 2026-10-15 | Old ends 2026-10-14, stays Active; new Planned; student owner unchanged | receipt "New enrollment status Planned", "Student owner Unchanged (effective date is in the future)"; F-PLACE shows "Planned from Oct 15, 2026" | Student stays in T_A grid until Oct 14 |
| S-TRANSFER-CAMPUS | Admin; S5 at ALP | Change class → BET, T_C, 2026-10-01 | New enrollment campus BET | receipt New campus Seed Campus Beta | Office: ddStuFormCampus disabled (own campus) |
| S-TRANSFER-BACKDATED | S6 with 12 attendance rows since 2026-09-01 | Effective 2026-09-01 | Warning "12 attendance days on or after Sep 1, 2026 will stay recorded under the old class."; Save disabled until tick; after save Attendance unchanged | conStuBackdate; receipt "Recorded days kept with old class 12" | Changing the date resets the tick and recounts |
| S-TRANSFER-INVALID-DATE | S1 open since 2026-08-12 | Effective 2026-08-12, then 2027-08-02 | "must be after Aug 12, 2026…"; "must be inside the 2026-2027 school year…" | lblStuFormCheck; Save disabled | Planned-transfer seed student: effective before its planned start is rejected |
| S-RATIO-OK | S7 at 1:1 | Change ratio → 2:1, 2026-10-01 | Old ends 2026-09-30 Ratio Change (stays Active); new Planned 2:1 same teacher | receipt Old ratio 1:1 / New ratio 2:1 | — |
| S-RATIO-SAME | S7 at 1:1 | Choose 1:1 | "The new ratio must differ from the current 1:1." | lblStuFormCheck | Save disabled |
| S-DISCHARGE-OK | S3 open enrollment | Discharge, end 2026-09-28, reason "Moved out of district" | Enrollment End 2026-09-28 Discharge Ended; student Inactive; Audit Discharge | receipt; badge Inactive; history | Blank reason blocks |
| S-DISCHARGE-CANCEL | Discharge form open | Cancel | No write | receipt "Discharge cancelled …"; badge still Active | — |
| S-ARCHIVE-OK | S3 after discharge (no open/future enrollment) | Archive → Archive student | Status Archived, Archived On 2026-09-29, By current user | receipt Operation Archive / Previous Inactive / Expected Archived / Status Archived | — |
| S-ARCHIVE-BLOCKED | S1 (open enrollment) | View S1 | btnStuActArchive disabled; hint "Archive needs every enrollment closed: 1 open or future enrollment." | lblStuActionHint | Discharged today (end = today) still counts as open until tomorrow |
| S-UNARCHIVE-OK | S3 archived | Include archived → View → Unarchive → Unarchive student | Status Inactive; Archived On/By cleared | receipt Previous Archived / Expected Inactive / Status Inactive / Cleared | Compound Inactive → Archived → Inactive on same student |
| S-HISTORY | Seed student with the planned transfer | View | galStuHistory shows current (Active, ends day before) and Planned rows, newest first, with "continues from" | galStuHistory; F-PLACE "Planned from …" | Student with no enrollments → "No enrollments on record" |

## Relevant Data Source Schemas

- Students: Student (GUID), 'Display Name', 'Student Number' (autonumber, read from Patch result), 'First Name',
  'Last Name', 'Date of Birth' (Date), Grade ('Grade (Students)'.K, '1'..'12', '12+'), 'External Client ID',
  'Status (aaca_status)' ('Status (Students)'.Active/Inactive/Archived), 'Archived On' (Date), 'Archived By' (Users), Owner (polymorphic; accepts a Users record).
- Enrollments: Enrollment (GUID), Name, Student, Campus, Teacher (Staff), Service, 'School Year', Program
  ('Program (Enrollments)'.'Regular Year'/Summer), 'IEP Ratio' ('IEP Ratio (Enrollments)'.'No Aide'/'1:1'/'2:1'/'3:1'/'4:1'),
  'Start Date', 'End Date' (blank = open), 'Status (aaca_status)' ('Status (Enrollments)'.Planned/Active/Ended),
  'End Reason' ('End Reason (Enrollments)'.Transfer/'Ratio Change'/Discharge/'Year End'/Correction), 'Previous Enrollment' (Enrollments), Owner.
- Staff: Staff (GUID), Name, 'App Role' ('App Role (Staff)'.Teacher), Campus, User (Users). Campuses: Campus, Name, Code.
- 'School Years': 'School Year' (GUID), Name, 'Start Date', 'End Date', 'Status (aaca_status)'. Services: Service, Name, Active.
- Attendance (read only here): Student, Date, 'Is Deleted'. 'Audit Events': Summary, Action ('Action (Audit Events)'.Create/Update/Transfer/Discharge/Archive/Unarchive), Entity, 'Entity ID', Before, After, Reason.
- Users: 'Full Name'. `CurrentUserRow` (App.Formulas) is the signed-in Users row.

## Required Variants

- GroupContainer → `Variant: AutoLayout` (every container on this screen)
- Gallery → `Variant: Vertical` (galStuReceipt, galStuList, galStuHistory)

## Control Definitions

GroupContainer — `Control: GroupContainer` + `Variant: AutoLayout`. Inputs: BorderColor, BorderStyle, BorderThickness,
ContentLanguage, DropShadow, EnableChildFocus, Fill, Height, RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft,
RadiusTopRight, Visible, Width, X, Y, LayoutAlignItems, LayoutDirection, LayoutGap, LayoutJustifyContent,
LayoutOverflowX, LayoutOverflowY, LayoutWrap, PaddingBottom, PaddingLeft, PaddingRight, PaddingTop; child: AlignInContainer,
FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth. Literals: `=DropShadow.None`,
`=LayoutDirection.Vertical|Horizontal`, `=LayoutAlignItems.Stretch|Center|Start`, `=LayoutOverflow.Scroll`,
`=AlignInContainer.Stretch|Center|Start`.

ModernText — `Control: ModernText`. Inputs: AccessibleLabel, Align, AutoHeight, BorderColor, BorderStyle, BorderThickness,
Color, ContentLanguage, DisplayMode, Fill, Font, FontWeight, Height, Italic, OnSelect, PaddingBottom, PaddingLeft,
PaddingRight, PaddingTop, RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft, RadiusTopRight, Size, Strikethrough, Text,
Underline, VerticalAlign, Visible, Width, Wrap, X, Y; child: AlignInContainer, FillPortions, LayoutMaxHeight, LayoutMaxWidth,
LayoutMinHeight, LayoutMinWidth. Literals: `=FontWeight.Bold|Semibold|Normal`, `=VerticalAlign.Top`, `=Align.Left`.

ModernButton — `Control: ModernButton` (no `Fill`). Inputs: AccessibleLabel, Align, Appearance, BasePaletteColor,
BorderColor, BorderStyle, BorderThickness, Color, ContentLanguage, DisplayMode, Font, FontWeight, Height, Icon,
IconRotation, IconStyle, Italic, Layout, OnSelect, PaddingBottom, PaddingLeft, PaddingRight, PaddingTop, Radius*,
Size, Strikethrough, Text, Tooltip, Underline, VerticalAlign, Visible, Width, X, Y; child props as above.
Literals: `=ButtonAppearance.Primary|Secondary` (Enum ButtonAppearance), `=ButtonLayout.TextOnly` (Enum ButtonLayout),
`=DisplayMode.Edit|Disabled`.

Classic/Button (engines only) — `Control: Classic/Button`. Inputs used: AutoDisableOnSelect, OnSelect, Text, Visible,
AlignInContainer, LayoutMinHeight, LayoutMinWidth (no AccessibleLabel property).

Gallery — `Control: Gallery` + `Variant: Vertical`. Inputs: AccessibleLabel, BorderColor, BorderStyle, BorderThickness,
ContentLanguage, Default, DelayItemLoading, DisplayMode, Fill, FocusedBorderColor, FocusedBorderThickness, Height, Items,
LoadingSpinner, LoadingSpinnerColor, NavigationStep, Selectable, ShowNavigation, ShowScrollbar, TabIndex, TemplatePadding,
TemplateSize, Transition, Visible, Width, WrapCount, X, Y; child: AlignInContainer, FillPortions, LayoutMaxHeight,
LayoutMaxWidth, LayoutMinHeight (default 287 — set 0), LayoutMinWidth (default 320 — set 0). Outputs: TemplateWidth, TemplateHeight.

ModernDropdown — `Control: ModernDropdown`. Inputs: AccessibleLabel, Appearance, BasePaletteColor, BorderColor, BorderStyle,
BorderThickness, Color, ContentLanguage, Default, DisplayMode, Fill, Font, FontWeight, Height, Italic, ItemDisplayText,
Items, OnChange, Padding*, Radius*, Required, Size, Strikethrough, Underline, ValidationState, Visible, Width, X, Y;
child props (LayoutMinWidth default 320 — set 0). Output: Selected. Literal: `Appearance: =Appearance.Outline` (Enum Appearance).

ModernTextInput — `Control: ModernTextInput`. Inputs: AccessibleLabel, Align, Appearance, BasePaletteColor, BorderColor,
BorderStyle, BorderThickness, Color, ContentLanguage, Default, DisplayMode, Fill, Font, FontWeight, Height, Italic,
MaxLength, OnChange, Padding*, Placeholder, Radius*, Required, Size, Strikethrough, TriggerOutput, Type, Underline,
ValidationState, Visible, Width, X, Y; child props (LayoutMinWidth default 320 — set 0). Output: Text.
Literals: `=Appearance.Outline`, `=TextInputType.Search|Multiline|SingleLine` (Enum TextInputType),
`=TriggerOutput.Delayed` (Enum TriggerOutput).

ModernDatePicker — `Control: ModernDatePicker`. Inputs: AccessibleLabel, Appearance, BasePaletteColor, BorderColor,
BorderStyle, BorderThickness, Color, ContentLanguage, DateTimeZone, DefaultDate, DisplayMode, EndDate, Fill, Font,
FontWeight, Height, IsEditable, Italic, OnChange, Padding*, Placeholder, Radius*, Size, StartDate, StartOfWeek,
Strikethrough, Underline, ValidationState, Visible, Width, X, Y; child props (LayoutMinWidth default 320 — set 0).
Output: SelectedDate. Literals: `=Appearance.Outline`, `Format: =DatePickerFormat.Short` (Enum DatePickerFormat).

ModernRadio — `Control: ModernRadio`. Inputs: AccessibleLabel, BasePaletteColor, BorderColor, BorderStyle, BorderThickness,
Color, ContentLanguage, Default, DisabledColor, DisplayMode, Fill, Font, FontWeight, Height, Italic, ItemDisplayText,
Items, Layout, LineHeight, OnChange, Padding*, RadioBackgroundFill, RadioBorderColor, RadioSelectionFill, RadioSize,
Radius*, Required, Size, Strikethrough, Underline, Visible, Width, X, Y; child props (LayoutMinHeight default 100,
LayoutMinWidth default 320 — set both 0). Output: Selected. Literal: `Layout: =OptionLayout.Horizontal` (Enum OptionLayout).

ModernCheckbox — `Control: ModernCheckbox`. Inputs: AccessibleLabel, BasePaletteColor, CheckboxSize, Color, ContentLanguage,
Default, DisplayMode, Font, FontWeight, Height, Italic, Label, OnCheck, OnUncheck, Size, Strikethrough, Tooltip,
Underline, Visible, Width, X, Y; child props. Output: Checked.

ModernToggle — `Control: ModernToggle`. Inputs: AccessibleLabel, BasePaletteColor, Color, ContentLanguage, Default,
DisplayMode, Font, FontWeight, Height, Italic, Label, LabelPosition, OnCheck, OnUncheck, Size, Strikethrough,
ToggleSize, Tooltip, Underline, Visible, Width, X, Y; child props. Output: Checked.
Literal: `LabelPosition: =ToggleLabelPosition.After` (Enum ToggleLabelPosition).

ModernSpinner — `Control: ModernSpinner`. Inputs: AccessibleLabel, Appearance, BasePaletteColor, Color, ContentLanguage,
DisplayMode, Font, FontWeight, Height, Italic, Label, LabelPosition, LineHeight, Padding*, Size, SpinnerColor,
Strikethrough, Tooltip, TrackColor, Underline, Visible, Width, X, Y; child props.

Badge — `Control: Badge`. Inputs: AccessibleLabel, Align, Appearance, BasePaletteColor, Content, ContentLanguage,
DisplayMode, Font, FontColor, FontItalic, FontSize, FontStrikethrough, FontUnderline, FontWeight, Height, Shape,
ThemeColor, VerticalAlign, Visible, Width, X, Y; child props. Literals: `Appearance: ='BadgeCanvas.Appearance'.Tint`,
`Shape: ='BadgeCanvas.Shape'.Rounded`, `ThemeColor: ='BadgeCanvas.ThemeColor'.Success|Warning|Subtle`.
