# Screen Plan: Students (StudentsScreen) - Modify

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml`
- YAML key: StudentsScreen
- Control name prefix: Stu (new control: `btnStuNavStaff`)

Read `canvas-app-shared.md` first. Edit properties IN PLACE. Never rename, move or delete an existing control. The
Change class engine (`btnStuFormSubmit`) is NOT changed - StaffScreen copies it.

## Exact edit list

### 1. `conStuHeader.Height` (line 32)
`=If(conStuRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conStuRoot.Width < 640, 152, 48), 0)`

### 2. `conStuNav.Height` (line 86)
`=If(conStuRoot.Width < 640, 148, 44)`

### 3. NEW `btnStuNavStaff` - last child of `conStuNav` (after `btnStuNavTransport`)
```
- btnStuNavStaff:
    Control: ModernButton
    Properties:
      AccessibleLabel: ="Go to Staff"
      AlignInContainer: =AlignInContainer.Center
      Appearance: =ButtonAppearance.Secondary
      Color: =ColorInk
      Height: =44
      Layout: =ButtonLayout.TextOnly
      LayoutMinHeight: =0
      LayoutMinWidth: =0
      OnSelect: =Navigate(StaffScreen)
      Size: =14
      Text: ="Staff"
      Visible: =CanManageStudents
      Width: =80
```
(indent to match `btnStuNavTransport`). Requires StaffScreen to exist in the session.

### 4. `ddStuFormTeacher.Items` (line 1266) - assignment picker: active teachers only
`=Sort(Filter(Staff, Campus.Campus = ddStuFormCampus.Selected.Campus && 'App Role' = 'App Role (Staff)'.Teacher && Active = true), Name, SortOrder.Ascending)`

### 5. `btnStuLoadEngine.OnSelect` - `colStuTeacherSrc` keeps every teacher (names stay resolvable) and gains `IsActive`

Line 2513 becomes:
```
                                ClearCollect(colStuTeacherSrc, ForAll(Sort(Filter(Staff, 'App Role' = 'App Role (Staff)'.Teacher), Name, SortOrder.Ascending) As t, {TeacherId: t.Staff, TeacherName: t.Name, CampusId: t.Campus.Campus, IsActive: t.Active <> false}))
```
Line 2518 (the seed record must carry the same columns) becomes:
```
                        ClearCollect(colStuTeacherOpts, {TeacherId: ZeroGuid, TeacherName: "All teachers", CampusId: ZeroGuid, IsActive: true}, colStuTeacherSrc);
```
Do NOT filter `colStuTeacherSrc` / `colStuTeacherOpts` (they also display names of retired teachers in the list
filter and history). Every other line of the engine is unchanged; keep the `|-` block and its indentation.

Nothing else changes.

## Layout budget

Same as Screen1: nav 582 <= 608 on one row at >= 640; phone 148 (three rows); header phone 244.

## Required Actions

| Action | Entry point and event | Source and stable ID | Mutation write set | Receipt proof set |
| --- | --- | --- | --- | --- |
| A-NAV-STAFF | btnStuNavStaff.OnSelect | N/A | N/A | StaffScreen opens |
| A-STU-ACTIVE-PICKER | ddStuFormTeacher.Items (add / change class / re-enroll forms) | Staff.Staff | N/A (read filter) | dropdown list |
| A-STU-TEACHER-SRC | btnStuLoadEngine (colStuTeacherSrc.IsActive) | Staff.Staff | N/A | list / history still show retired teacher names |

## Functional Test Scenarios

Owned: S-NAV-STAFF (Students entry), S-STU-PICKER, S-STU-HISTORY-NAMES, S-STU-CHANGE-CLASS-REGRESSION - copy rows from
the plan index Functional Test Matrix.

## Control Definitions

- ModernButton (`Control: ModernButton`; NO Fill): AccessibleLabel, AlignInContainer, Appearance [ButtonAppearance],
  BasePaletteColor, Color, DisplayMode, Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth, OnSelect,
  Size, Text, Visible, Width.
- Existing GroupContainer / ModernDropdown / Classic/Button: only Height / Items / OnSelect values change.

Enum literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `AlignInContainer.Center`.
