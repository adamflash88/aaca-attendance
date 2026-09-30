# Screen Plan: Students

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml`
- YAML key: StudentsScreen
- Control name prefix: Stu

## Current State

`conStuRoot` -> `conStuHeader` (with `conStuNav`: btnStuNavAttendance, btnStuNavStudents, Width 120), `conStuDenied`,
`conStuNotice`, `spnStuLoading`, `conStuReceipt` (varStuReceipt + colStuReceiptLines), `conStuBody` (list panel +
`conStuRight` with `conStuForm` and `conStuDetail`), hidden engines `btnStuLoadEngine`, `btnStuHistoryEngine`,
`btnStuFormResetEngine`. `conStuForm` is driven by `varStuMode` with one guarded `btnStuFormSubmit.OnSelect`
(`Switch(md, "add", …, "edit", …, "transfer", …, "ratio", …, "discharge", …, "archive", …, "unarchive", …)`).
Detail actions in `conStuActions` (wrap): Edit details, Change class, Change ratio, Discharge, Archive, Unarchive.

Keep every control and formula not listed below exactly as it is (add / edit / transfer / ratio arms, list,
filters, history, engines, duplicate check, backdate acknowledgement).

## Changes

1. Header nav: add `btnStuNavAbsences`; nav buttons Width 110.
2. Replace modes "discharge", "archive", "unarchive" with "end" (End enrollment) and "reenroll" (Re-enroll) in every
   formula that lists modes; remove the three old buttons and add two new ones.
3. Replace the three old `Switch` arms in `btnStuFormSubmit.OnSelect` with the "end" and "reenroll" arms below.
4. Fix `conStuForm.Height`: drop the `+ If(m = "add", 58 + 8, 0)` term (it budgets the hidden Program picker and
   leaves 66 px of blank space).

## Layout and Visual Impact

- Responsive bounds: nav 3 x 110 + 2 x 8 = 346 <= 358 at phone. conStuActions (wrap, existing Height formula
  `If(conStuDetail.Width - 32 >= 600, 44, conStuDetail.Width - 32 >= 376, 96, 148)`): visible buttons are Edit 120,
  Change class 120, Change ratio 120 and exactly one of End enrollment 150 / Re-enroll 110. >= 600: 534 (1 line);
  376–599: 120+8+120+8+120 = 376 then 150 (2 lines, 96); < 376: 248 / 278 (2 lines <= 148).
- Form: re-enroll shows Place (120) + Ratio (58) + Date (58) + Reason (86) — all existing fields; end shows Date +
  Reason (+ Backdate when attendance exists after the end date). Height formula below.
- Text fit: lblStuFormContext (h 60 wide / 100 when form < 700): keep the new end/reenroll texts <= 200 chars
  (3 lines wide, 5 lines narrow). lblStuFormCheck messages <= 110 chars (2 lines in 40, 3 lines in 60).
  "End enrollment" 14 chars ≈ 129 px -> Width 150. "Re-enroll student" (submit) fits the existing 190.
- Visual contract: End enrollment submit is destructive (`BasePaletteColor: =ColorUnexcused`); Re-enroll submit
  teal. Detail buttons stay Secondary.
- Record presentation: detail identity `lblStuDetailName` + `badgeStuDetailStatus` unchanged.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --------- | -------------- | -------------- | ------------ | ------------- | ------------- | ------------------------ |
| stu/detail/status | conStuProfileHead | Student status | colStuList.StatusText | badgeStuDetailStatus | existing (unchanged) | shows Archived after End, Active after Re-enroll |
| stu/history/dates | galStuHistory row | dates + status + end reason + link | colStuHistory | lblStuHistDates, lblStuHistEnd | existing (unchanged) | gap and new start visible after Re-enroll |

## Controls to Add

1. `btnStuNavAbsences` — ModernButton, last child of `conStuNav`:
   AccessibleLabel `="Go to Absences"`, AlignInContainer `=AlignInContainer.Center`, Appearance
   `=ButtonAppearance.Secondary`, Color `=ColorInk`, FillPortions `=0`, Height `=44`, Layout `=ButtonLayout.TextOnly`,
   LayoutMinHeight `=0`, LayoutMinWidth `=0`, OnSelect `=Navigate(AbsencesScreen)`, Size `=14`, Text `="Absences"`,
   Width `=110`.

2. `btnStuActEnd` — ModernButton in `conStuActions`, placed where `btnStuActDischarge` was:
   - AccessibleLabel `="End enrollment"`, AlignInContainer `=AlignInContainer.Center`, Appearance
     `=ButtonAppearance.Secondary`, Color `=ColorInk`, FillPortions `=0`, Height `=44`, Layout `=ButtonLayout.TextOnly`,
     LayoutMinHeight `=0`, LayoutMinWidth `=0`, Size `=14`, Text `="End enrollment"`, Width `=150`
   - Visible: `=LookUp(colStuList, StudentId = varStuSelId).StatusText <> "Archived"`
   - DisplayMode (`|-`):
     `=With({sel: LookUp(colStuList, StudentId = varStuSelId), open: First(Sort(Filter(colStuHistory, IsBlank(EndDate)), StartDate, SortOrder.Descending))}, If(!IsBlank(sel) && (StudentCampusLock = ZeroGuid || sel.CampusId = StudentCampusLock) && !varStuSaving && !varStuLoading && sel.StatusText = "Active" && !IsBlank(open), DisplayMode.Edit, DisplayMode.Disabled))`
   - OnSelect (`|-`):
     `=Set(varStuMode, "end"); Set(varStuAttAfter, With({q: varStuSelId, d: Today()}, CountRows(Filter(Attendance, Student.Student = q && Date > d && 'Is Deleted' <> true)))); Select(btnStuFormResetEngine)`

3. `btnStuActReenroll` — ModernButton in `conStuActions`, after `btnStuActEnd`:
   - AccessibleLabel `="Re-enroll student"`, same styling keys as above, Text `="Re-enroll"`, Width `=110`
   - Visible: `=LookUp(colStuList, StudentId = varStuSelId).StatusText = "Archived"`
   - DisplayMode (`|-`):
     `=With({sel: LookUp(colStuList, StudentId = varStuSelId)}, If(!IsBlank(sel) && (StudentCampusLock = ZeroGuid || sel.CampusId = StudentCampusLock) && !varStuSaving && !varStuLoading && sel.StatusText = "Archived" && CountRows(Filter(colStuHistory, IsBlank(EndDate))) = 0, DisplayMode.Edit, DisplayMode.Disabled))`
   - OnSelect (`|-`):
     `=Set(varStuMode, "reenroll"); Set(varStuFormCampusId, If(StudentCampusLock <> ZeroGuid, StudentCampusLock, Coalesce(LookUp(colStuList, StudentId = varStuSelId).CampusId, varStuScopeCampusId))); Set(varStuAttAfter, 0); Select(btnStuFormResetEngine)`

## Controls to Remove

`btnStuActDischarge`, `btnStuActArchive`, `btnStuActUnarchive`.

## Properties to Update

- `btnStuNavAttendance.Width` -> `=110`; `btnStuNavStudents.Width` -> `=110`; add `FillPortions: =0` to both.
- `conStuForm.Height` (`|-`):
  ```
  =With(
      {m: varStuMode, n: Self.Width < 700},
      16 + If(n, 56, 28) + 8 + If(n, 100, 60) + 8
      + If(m in ["add", "edit"], 306 + 8, 0)
      + If(m in ["add", "transfer", "reenroll"], 120 + 8, 0)
      + If(m in ["add", "ratio", "reenroll"], 58 + 8, 0)
      + If(m in ["add", "transfer", "ratio", "end", "reenroll"], 58 + 8, 0)
      + If(m in ["transfer", "ratio", "end", "edit", "reenroll"], 86 + 8, 0)
      + If(conStuDup.Visible, If(n, 176, 156) + 8, 0)
      + If(conStuBackdate.Visible, If(n, 124, 104) + 8, 0)
      + If(n, 60, 40) + 8 + 44 + 16
  )
  ```
- `lblStuFormTitle.Text`:
  `=With({n: LookUp(colStuList, StudentId = varStuSelId).DisplayName}, Switch(varStuMode, "add", "Add student", "edit", "Edit details — " & n, "transfer", "Change class — " & n, "ratio", "Change IEP ratio — " & n, "end", "End enrollment — " & n, "reenroll", "Re-enroll — " & n, ""))`
- `lblStuFormContext.Text`: in the Switch replace the "discharge", "archive", "unarchive" arms with (add
  `lastEnd: First(Sort(Filter(colStuHistory, !IsBlank(EndDate)), EndDate, SortOrder.Descending))` to its With):
  - `"end", "Ends the open enrollment with " & open.TeacherName & " (since " & Text(open.StartDate, "mmm d, yyyy") & ") on the end date, reason Archived. No enrollment follows, so the student becomes Archived and leaves the grids after that day."`
  - `"reenroll", "Starts a new enrollment after the last end date" & If(IsBlank(lastEnd), "", " (" & Text(lastEnd.EndDate, "mmm d, yyyy") & ")") & ", linked to the last one. The student becomes Active and appears on the teacher's grid from the start date."`
- `conStuFormPlace.Visible` -> `=varStuMode in ["add", "transfer", "reenroll"]`
- `lblStuFormCampus.Text` / `ddStuFormCampus.AccessibleLabel` -> unchanged (transfer "New campus *", else "Campus *").
- `conStuFormRatio.Visible` -> `=varStuMode in ["add", "ratio", "reenroll"]`
- `conStuFormDate.Visible` -> `=varStuMode in ["add", "transfer", "ratio", "end", "reenroll"]`
- `lblStuFormDate.Text`:
  `=Switch(varStuMode, "add", "Start date *", "transfer", "Effective date (first day in the new class) *", "ratio", "Effective date (first day at the new ratio) *", "end", "End date (last day of service) *", "reenroll", "Start date (first day back, after the last end date) *", "Date")`
- `dpStuFormDate.OnChange` (`|-`):
  `=Reset(chkStuBackdateAck); With({q: varStuSelId, d: Self.SelectedDate}, Set(varStuAttAfter, If(IsBlank(q) || IsBlank(d) || !(varStuMode in ["transfer", "ratio", "end"]), 0, varStuMode = "end", CountRows(Filter(Attendance, Student.Student = q && Date > d && 'Is Deleted' <> true)), CountRows(Filter(Attendance, Student.Student = q && Date >= d && 'Is Deleted' <> true)))))`
- `conStuFormReason.Visible` -> `=varStuMode in ["transfer", "ratio", "end", "edit", "reenroll"]`
- `lblStuFormReason.Text` and `txtStuFormReason.AccessibleLabel` -> `=If(varStuMode = "end", "Note for the audit log *", "Note for the audit log (optional)")`
- `conStuBackdate.Visible` -> `=varStuMode in ["transfer", "ratio", "end"] && varStuAttAfter > 0`
- `lblStuBackdateText.Text`: replace both `varStuMode = "discharge"` tests with `varStuMode = "end"`.
- `lblStuFormCheck.Text`: add `lastEnd: First(Sort(Filter(colStuHistory, !IsBlank(EndDate)), EndDate, SortOrder.Descending))`
  to the outer With (next to `sel`, `open`); the `live` binding may be removed. Replace the `varStuMode = "discharge"`,
  `varStuMode = "archive"` and `varStuMode = "unarchive"` arms with:
  ```
  varStuMode = "end",
  If(
      sel.StatusText <> "Active", "Only Active students can end an enrollment.",
      IsBlank(open), "No open enrollment to end.",
      IsBlank(eff), "Choose the end date (last day of service).",
      eff < open.StartDate, "The end date cannot be before " & Text(open.StartDate, "mmm d, yyyy") & ", when the enrollment started.",
      CountRows(Filter(colStuHistory, EnrId <> open.EnrId && (IsBlank(EndDate) || EndDate > eff))) > 0, "Another enrollment continues after this date. Use Change class or Change ratio instead.",
      Trim(txtStuFormReason.Text) = "", "Enter a note for the audit log.",
      ackBad, "Tick the confirmation. " & varStuAttAfter & " attendance days after the end date stay recorded.",
      "Ready to save."
  ),
  varStuMode = "reenroll",
  If(
      sel.StatusText <> "Archived", "Only archived students can be re-enrolled.",
      CountRows(Filter(colStuHistory, IsBlank(EndDate))) > 0, "This student still has an open enrollment.",
      IsBlank(cmp), "Choose a campus.",
      StudentCampusLock <> ZeroGuid && cmp.Campus <> StudentCampusLock, "Office staff can re-enroll students only at their own campus.",
      IsBlank(tch) || tch.Campus.Campus <> cmp.Campus, "Choose a teacher at " & cmp.Name & ".",
      IsBlank(ddStuFormRatio.Selected), "Choose an IEP ratio.",
      IsBlank(eff), "Choose the start date.",
      !IsBlank(lastEnd) && eff <= lastEnd.EndDate, "The start date must be after " & Text(lastEnd.EndDate, "mmm d, yyyy") & ", the last end date.",
      IsBlank(yr), "The start date is not inside a school year.",
      IsBlank(ActiveService), "No active service is set up. Ask a System Admin.",
      "Ready to save."
  ),
  ```
  (`yr`, `ackBad`, `cmp`, `tch`, `eff` already exist in that formula.)
- `btnStuFormSubmit.BasePaletteColor` -> `=If(varStuMode = "end", ColorUnexcused, ColorTeal)`
- `btnStuFormSubmit.Text` -> `=Switch(varStuMode, "add", "Add student", "edit", "Save details", "transfer", "Save class change", "ratio", "Save ratio change", "end", "End enrollment", "reenroll", "Re-enroll student", "Save")`
- `btnStuFormSubmit.OnSelect`: keep the guard, the outer With (md, q, fn, … open) and the "add", "edit", "transfer",
  "ratio" arms verbatim. Delete the "discharge", "archive", "unarchive" arms and put the two arms in the next
  section after "ratio". Keep the final `Set(varStuSaving, false)`.
- `btnStuFormCancel.OnSelect`: in its Switch replace `"discharge", "Discharge", "archive", "Archive", "unarchive", "Unarchive"`
  with `"end", "End enrollment", "reenroll", "Re-enroll"`.
- `lblStuActionHint.Text` (`|-`):
  ```
  =With(
      {sel: LookUp(colStuList, StudentId = varStuSelId), open: First(Sort(Filter(colStuHistory, IsBlank(EndDate)), StartDate, SortOrder.Descending))},
      If(
          StudentCampusLock <> ZeroGuid && sel.CampusId <> StudentCampusLock, "View only. Office staff can change only students at their own campus.",
          sel.StatusText = "Archived", "Archived. Use Re-enroll to start a new enrollment after the last end date; Edit details still works.",
          IsBlank(open), "No open enrollment, so Change class, Change ratio and End enrollment are unavailable.",
          "End enrollment is for a student leaving AACA. Use Change class or Change ratio for moves."
      )
  )
  ```

## Submit arms (insert after the "ratio" arm, inside `Switch(md, …)`)

```
"end",
With(
    {old: With({qe: open.EnrId}, LookUp(Enrollments, ThisRecord.Enrollment = qe)), stu: LookUp(Students, ThisRecord.Student = q)},
    With(
        {later: With({qs: q, qe: open.EnrId, qd: eff}, CountRows(Filter(Enrollments, Student.Student = qs && ThisRecord.Enrollment <> qe && (IsBlank('End Date') || 'End Date' > qd))))},
        If(
            IsBlank(old) || IsBlank(stu) || !IsBlank(old.'End Date'),
            Set(varStuReceipt, {Kind: "Blocked", Title: "Not saved. This enrollment was changed by someone else. The list was reloaded; check the history and try again.", StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines); Set(varStuMode, ""); Select(btnStuLoadEngine),
            stu.'Status (aaca_status)' <> 'Status (Students)'.Active,
            Set(varStuReceipt, {Kind: "Blocked", Title: "Not saved. " & stu.'Display Name' & " is not Active.", StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines); Select(btnStuLoadEngine),
            later > 0,
            Set(varStuReceipt, {Kind: "Blocked", Title: "Not saved. Another enrollment continues after " & Text(eff, "mmm d, yyyy") & ". Use Change class or Change ratio instead.", StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines),
            With(
                {closed: IfError(Patch(Enrollments, old, {'End Date': eff, 'End Reason': 'End Reason (Enrollments)'.Archived, 'Status (aaca_status)': If(eff < Today(), 'Status (Enrollments)'.Ended, 'Status (Enrollments)'.Active)}), Blank())},
                If(
                    IsBlank(closed),
                    Set(varStuReceipt, {Kind: "Failed", Title: "Failed. Nothing was saved for " & stu.'Display Name' & ". Press End enrollment to retry.", StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines),
                    With(
                        {s2: IfError(Patch(Students, stu, {'Status (aaca_status)': 'Status (Students)'.Archived, 'Archived On': eff, 'Archived By': CurrentUserRow}), Blank())},
                        If(
                            IsBlank(s2),
                            With(
                                {rb: IfError(Patch(Enrollments, closed, {'End Date': Blank(), 'End Reason': Blank(), 'Status (aaca_status)': old.'Status (aaca_status)'}), Blank())},
                                Set(varStuReceipt, {Kind: "Failed", Title: "Failed. " & stu.'Display Name' & " was not archived. " & If(IsBlank(rb), "The enrollment is still ended on " & Text(closed.'End Date', "mmm d, yyyy") & "; ask a System Admin.", "The enrollment was reopened; nothing changed."), StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines); Select(btnStuLoadEngine)
                            ),
                            With(
                                {audit: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: "End enrollment " & stu.'Student Number' & " end " & Text(eff, "yyyy-mm-dd") & " (archived)", Action: 'Action (Audit Events)'.Archive, Entity: "aaca_student", 'Entity ID': Text(stu.Student), Before: JSON({EnrollmentId: Text(old.Enrollment), EndDate: "", EnrollmentStatus: Text(old.'Status (aaca_status)'), StudentStatus: Text(stu.'Status (aaca_status)'), ArchivedOn: ""}), After: JSON({EnrollmentId: Text(closed.Enrollment), EndDate: Text(closed.'End Date', "yyyy-mm-dd"), EndReason: Text(closed.'End Reason'), EnrollmentStatus: Text(closed.'Status (aaca_status)'), StudentStatus: Text(s2.'Status (aaca_status)'), ArchivedOn: Text(s2.'Archived On', "yyyy-mm-dd"), ArchivedBy: s2.'Archived By'.'Full Name', AttendanceDaysAfterEnd: attAfter}), Reason: note}), Blank())},
                                Set(varStuReceipt, {Kind: "Ended", Title: "Enrollment ended · " & s2.'Display Name' & " · " & s2.'Student Number' & " · archived from " & Text(closed.'End Date', "mmm d, yyyy"), StudentId: s2.Student});
                                ClearCollect(
                                    colStuReceiptLines,
                                    {Label: "Operation", Value: "End enrollment"},
                                    {Label: "Student number", Value: s2.'Student Number'},
                                    {Label: "Teacher", Value: closed.Teacher.Name},
                                    {Label: "Campus", Value: closed.Campus.Name},
                                    {Label: "Enrollment start", Value: Text(closed.'Start Date', "mmm d, yyyy")},
                                    {Label: "End date", Value: Text(closed.'End Date', "mmm d, yyyy")},
                                    {Label: "End reason", Value: Text(closed.'End Reason')},
                                    {Label: "Enrollment status", Value: Text(closed.'Status (aaca_status)') & If(closed.'Status (aaca_status)' = 'Status (Enrollments)'.Active, " (until the end date)", "")},
                                    {Label: "Previous student status", Value: Text(stu.'Status (aaca_status)')},
                                    {Label: "Student status", Value: Text(s2.'Status (aaca_status)')},
                                    {Label: "Archived on", Value: Text(s2.'Archived On', "mmm d, yyyy")},
                                    {Label: "Archived by", Value: s2.'Archived By'.'Full Name'},
                                    {Label: "Recorded days after end date", Value: Text(attAfter)},
                                    {Label: "Note", Value: noteShort},
                                    {Label: "Audit event", Value: If(IsBlank(audit), "NOT written", "Archive written")}
                                );
                                Set(varStuSelId, s2.Student); Set(varStuMode, ""); Select(btnStuLoadEngine)
                            )
                        )
                    )
                )
            )
        )
    )
),
"reenroll",
With(
    {stu: LookUp(Students, ThisRecord.Student = q), yr: LookUp('School Years', 'Start Date' <= eff && 'End Date' >= eff)},
    With(
        {
            liveOpen: With({qs: q}, CountRows(Filter(Enrollments, Student.Student = qs && IsBlank('End Date')))),
            liveLast: With({qs: q}, First(Sort(Filter(Enrollments, Student.Student = qs && !IsBlank('End Date')), 'End Date', SortOrder.Descending)))
        },
        If(
            IsBlank(stu),
            Set(varStuReceipt, {Kind: "Failed", Title: "Failed. The student could not be found. Reload and try again.", StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines),
            stu.'Status (aaca_status)' <> 'Status (Students)'.Archived,
            Set(varStuReceipt, {Kind: "Blocked", Title: "Not saved. " & stu.'Display Name' & " is not archived.", StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines); Select(btnStuLoadEngine),
            liveOpen > 0,
            Set(varStuReceipt, {Kind: "Blocked", Title: "Not saved. " & stu.'Display Name' & " still has an open enrollment.", StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines); Select(btnStuLoadEngine),
            !IsBlank(liveLast) && eff <= liveLast.'End Date',
            Set(varStuReceipt, {Kind: "Blocked", Title: "Not saved. The start date must be after " & Text(liveLast.'End Date', "mmm d, yyyy") & ", the last end date.", StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines),
            IsBlank(yr),
            Set(varStuReceipt, {Kind: "Blocked", Title: "Not saved. The start date is not inside a school year.", StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines),
            With(
                {ne: IfError(Patch(Enrollments, Defaults(Enrollments), {Name: stu.'Student Number' & " " & Text(eff, "yyyy-mm-dd"), Student: stu, Campus: cmp, Teacher: tch, Service: ActiveService, 'School Year': yr, Program: prg, 'IEP Ratio': rat, 'Start Date': eff, 'Status (aaca_status)': If(eff <= Today(), 'Status (Enrollments)'.Active, 'Status (Enrollments)'.Planned), 'Previous Enrollment': liveLast}), Blank())},
                If(
                    IsBlank(ne),
                    Set(varStuReceipt, {Kind: "Failed", Title: "Failed. Nothing was saved for " & stu.'Display Name' & ". Press Re-enroll student to retry.", StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines),
                    With(
                        {s2: IfError(Patch(Students, stu, {'Status (aaca_status)': 'Status (Students)'.Active, 'Archived On': Blank(), 'Archived By': Blank()}), Blank())},
                        If(
                            IsBlank(s2),
                            Set(varStuReceipt, {Kind: "Failed", Title: "Partly saved. The enrollment from " & Text(ne.'Start Date', "mmm d, yyyy") & " was created but " & stu.'Display Name' & " is still Archived. Ask a System Admin.", StudentId: stu.Student}); Clear(colStuReceiptLines); Set(varStuSelId, stu.Student); Set(varStuMode, ""); Select(btnStuLoadEngine),
                            With(
                                {
                                    own: If(IsBlank(tch.User), false, !IsBlank(IfError(Patch(Students, s2, {Owner: tch.User}), Blank())) && !IsBlank(IfError(Patch(Enrollments, ne, {Owner: tch.User}), Blank()))),
                                    audit: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: "Re-enroll " & s2.'Student Number' & " from " & Text(eff, "yyyy-mm-dd"), Action: 'Action (Audit Events)'.Unarchive, Entity: "aaca_student", 'Entity ID': Text(s2.Student), Before: JSON({Status: Text(stu.'Status (aaca_status)'), ArchivedOn: Text(stu.'Archived On', "yyyy-mm-dd"), ArchivedBy: stu.'Archived By'.'Full Name', LastEnrollmentId: If(IsBlank(liveLast), "", Text(liveLast.Enrollment)), LastEndDate: Text(liveLast.'End Date', "yyyy-mm-dd")}), After: JSON({Status: Text(s2.'Status (aaca_status)'), ArchivedOn: "", ArchivedBy: "", NewEnrollmentId: Text(ne.Enrollment), CampusId: Text(cmp.Campus), Campus: cmp.Name, TeacherId: Text(tch.Staff), Teacher: tch.Name, IepRatio: Text(ne.'IEP Ratio'), StartDate: Text(ne.'Start Date', "yyyy-mm-dd"), EnrollmentStatus: Text(ne.'Status (aaca_status)'), SchoolYear: ne.'School Year'.Name}), Reason: If(note = "", "Re-enrolled", note)}), Blank())
                                },
                                Set(varStuReceipt, {Kind: "Reenrolled", Title: "Re-enrolled · " & s2.'Display Name' & " · " & s2.'Student Number' & " · from " & Text(ne.'Start Date', "mmm d, yyyy"), StudentId: s2.Student});
                                ClearCollect(
                                    colStuReceiptLines,
                                    {Label: "Operation", Value: "Re-enroll"},
                                    {Label: "Student number", Value: s2.'Student Number'},
                                    {Label: "Previous status", Value: Text(stu.'Status (aaca_status)')},
                                    {Label: "Student status", Value: Text(s2.'Status (aaca_status)')},
                                    {Label: "Archived on", Value: If(IsBlank(s2.'Archived On'), "Cleared", Text(s2.'Archived On', "mmm d, yyyy"))},
                                    {Label: "Archived by", Value: If(IsBlank(s2.'Archived By'), "Cleared", s2.'Archived By'.'Full Name')},
                                    {Label: "Campus", Value: ne.Campus.Name},
                                    {Label: "Teacher", Value: ne.Teacher.Name},
                                    {Label: "IEP ratio", Value: Text(ne.'IEP Ratio')},
                                    {Label: "Start date", Value: Text(ne.'Start Date', "mmm d, yyyy")},
                                    {Label: "Enrollment status", Value: Text(ne.'Status (aaca_status)')},
                                    {Label: "School year", Value: ne.'School Year'.Name},
                                    {Label: "Service", Value: ne.Service.Name},
                                    {Label: "Previous enrollment", Value: If(IsBlank(liveLast), "None", "Linked · ended " & Text(liveLast.'End Date', "mmm d, yyyy") & If(ne.'Previous Enrollment'.Enrollment = liveLast.Enrollment, "", " (link NOT saved)"))},
                                    {Label: "Gap", Value: If(IsBlank(liveLast), "—", Text(DateDiff(liveLast.'End Date', ne.'Start Date', TimeUnit.Days) - 1) & " days without an enrollment")},
                                    {Label: "Record owner", Value: If(IsBlank(tch.User), "Unchanged (teacher has no linked user)", own, tch.User.'Full Name', "Owner update FAILED")},
                                    {Label: "Note", Value: noteShort},
                                    {Label: "Audit event", Value: If(IsBlank(audit), "NOT written", "Unarchive written")}
                                );
                                Set(varStuSelId, s2.Student); Set(varStuMode, ""); Select(btnStuLoadEngine)
                            )
                        )
                    )
                )
            )
        )
    )
)
```

All names used (`q`, `eff`, `note`, `noteShort`, `attAfter`, `open`, `cmp`, `tch`, `prg`, `rat`) already exist in the
submit formula's outer With blocks. The final "ratio" arm needs a trailing `,` before `"end"`, and the "reenroll"
arm is the last arm (no default arm follows, as today).

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| ------ | ------------- | --------------------- | -------------------- | ---------------------------- | ------------------ | ----------------- | --------------------- |
| A-END-ENROLLMENT | sel Active, open enrollment, campus lock ok, check "Ready to save." (note required, end >= start, nothing continues after, ack if days after) | btnStuActEnd -> form "end" -> btnStuFormSubmit.OnSelect | Enrollments by open.EnrId (re-read `old`); Students by q | End Date = eff; End Reason Archived; Status Ended if eff < Today() else Active; Student Archived, Archived On = eff, By = CurrentUserRow; Audit Archive | End Date, End Reason, Enrollment Status, Student Status, Archived On, Archived By, Audit | lines listed in the "end" arm (Operation … Audit event) + title | conStuReceipt Kind "Ended"; reload -> badgeStuDetailStatus "Archived"; galStuHistory |
| A-REENROLL | sel Archived, no open enrollment, campus lock ok, check "Ready to save." | btnStuActReenroll -> form "reenroll" -> btnStuFormSubmit.OnSelect | Students by q; new Enrollment `ne` | New enrollment after last end, linked; student Active, archive stamp cleared; owner; Audit Unarchive | all new Enrollment fields, Student Status/Archived On/Archived By/Owner, Enrollment Owner, Audit | lines listed in the "reenroll" arm | conStuReceipt Kind "Reenrolled"; badge "Active"; galStuHistory new row "continues from" |
| A-NAV-* | CanManageStudents | btnStuNavAttendance / Students / Absences | N/A | Navigate | N/A | N/A | teal current button |

Cancel for both modes: existing `btnStuFormCancel` (receipt "End enrollment cancelled · … · nothing was changed" /
"Re-enroll cancelled · …"), `varStuMode` cleared, no write.

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| -------------- | ------------------------ | ------------------- |
| ddStuFormCampus (reenroll) | lblStuFormCampus.Text `=If(varStuMode = "transfer", "New campus *", "Campus *")` | conStuFormPlace |
| ddStuFormTeacher (reenroll) | lblStuFormTeacher.Text (existing) | conStuFormPlace |
| ddStuFormRatio (reenroll) | lblStuFormRatio.Text `=If(varStuMode = "ratio", "New IEP ratio *", "IEP ratio *")` | conStuFormRatio |
| dpStuFormDate (end / reenroll) | lblStuFormDate.Text (updated above) | conStuFormDate |
| txtStuFormReason (end required) | lblStuFormReason.Text (updated above) | conStuFormReason |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| ------ | --------------- | ----------------------------- | ---------------------------------- | -------------------- | ----------------------------------- | ----------------- |
| A-END-ENROLLMENT | `closed`, `s2` -> varStuReceipt / colStuReceiptLines | Enrollments / Students | badgeStuDetailStatus, galStuHistory, archived list | open.EnrId = closed.Enrollment; s2.Student | `Select(btnStuLoadEngine)` after success | `Set(varStuSelId, s2.Student)` |
| A-REENROLL | `ne`, `s2` -> receipt | Enrollments / Students | badge, galStuHistory; Screen1 grid for the teacher | ne.Enrollment; s2.Student | `Select(btnStuLoadEngine)`; Screen1 OnVisible | `Set(varStuSelId, s2.Student)` |

## Mutation Field Ledger

Copy of the plan-index rows for A-END-ENROLLMENT and A-REENROLL: End Date / End Reason / Enrollment Status /
Student Status / Archived On / Archived By / Note (Changed, each with its receipt line); Start Date / Teacher / Campus /
IEP Ratio of the ended enrollment (Preserved, omitted from the partial Patch, shown as receipt lines). Re-enroll:
Campus / Teacher / IEP Ratio / Start Date (user input, receipt lines), Status / School Year / Service / Previous
Enrollment (derived, receipt lines), Student Status + Archived On/By cleared (receipt lines), Owner (receipt line),
previous enrollment End Date / End Reason (Preserved, shown in "Previous enrollment" line and history).

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| -------- | ----- | ---- | ---- | ---------------- | ------------------------- |
| S-END-OK | Active S1, open E1 started 2026-08-12 | End enrollment, end 2026-09-26, note "Moved out of state", submit | E1 ended 2026-09-26, reason Archived, Status Ended; S1 Archived, On 2026-09-26, By me; audit Archive | Receipt title + lines; badge Archived; history | If attendance exists after the date, the ack checkbox must be ticked first |
| S-END-FUTURE | Active S2 | End date Today()+10 | E Status Active; S2 Archived | Receipt "Enrollment status Active (until the end date)" | End date before start -> check message, submit disabled |
| S-END-NO-NOTE | Mode end, note blank | — | Submit disabled | lblStuFormCheck "Enter a note for the audit log." | — |
| S-END-CANCEL | Mode end | Cancel | No write | Receipt "End enrollment cancelled · S1 · nothing was changed" | — |
| S-REENROLL-OK | Archived S1, last end 2026-09-26 | Re-enroll: North, T1, 2:1, start 2026-10-05, submit | New E2 Planned from 2026-10-05, Previous Enrollment E1; S1 Active, Archived On/By cleared; owner T1 user; audit Unarchive | Receipt incl. "Gap 8 days without an enrollment"; history two rows | Office user sees campus locked to own campus |
| S-REENROLL-BAD-DATE | same | Start 2026-09-26 | Submit disabled | "The start date must be after Sep 26, 2026, the last end date." | Engine re-checks live last End Date |
| S-REENROLL-CANCEL | Mode reenroll | Cancel | No write | Receipt "Re-enroll cancelled · …" | — |
| S-NAV3-OFFICE | Office user | Tap Absences | AbsencesScreen | teal Absences | 346 <= 358 |
| S-REGRESSION | Existing students | Add / Edit details / Change class / Change ratio | Same as build 2 | existing receipts | Discharge / Archive / Unarchive buttons gone |

## Relevant Data Source Schemas

- Enrollments: Enrollment (Guid), Name, Student, Campus, Teacher, Service, 'School Year', Program ('Program (Enrollments)'.'Regular Year'), 'IEP Ratio', 'Start Date', 'End Date', 'Status (aaca_status)' (Planned/Active/Ended), 'End Reason' ('End Reason (Enrollments)'.Archived), 'Previous Enrollment', Owner.
- Students: Student (Guid), 'Display Name', 'Student Number', 'Status (aaca_status)' (Active/Inactive/Archived), 'Archived On' (Date), 'Archived By' (Users), Owner.
- Audit Events: Summary, Action ('Action (Audit Events)'.Archive / .Unarchive), Entity, 'Entity ID', Before, After, Reason.
- 'School Years': 'Start Date', 'End Date', Name. Users: 'Full Name'.

## Changed or Added Control Definitions

ModernButton (React) — `Control: ModernButton`. Inputs: AccessibleLabel, Align, Appearance, BasePaletteColor,
BorderColor, BorderStyle, BorderThickness, Color, ContentLanguage, DisplayMode, Font, FontWeight, Height, Icon,
IconRotation, IconStyle, Italic, Layout, OnSelect, PaddingBottom/Left/Right/Top, Radius*, Size, Strikethrough, Text,
Tooltip, Underline, VerticalAlign, Visible, Width, X, Y; AutoLayout child: AlignInContainer, FillPortions,
LayoutMinHeight, LayoutMinWidth, LayoutMaxHeight, LayoutMaxWidth. No `Fill`.
- Appearance: Enum `ButtonAppearance` -> `=ButtonAppearance.Secondary`
- Layout: Enum `ButtonLayout` -> `=ButtonLayout.TextOnly`
- DisplayMode: Enum `DisplayMode` -> `DisplayMode.Edit` / `DisplayMode.Disabled`
- AlignInContainer: Enum `AlignInContainer` -> `=AlignInContainer.Center`

No other control type gains a new property.
