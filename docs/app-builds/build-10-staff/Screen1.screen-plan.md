# Screen Plan: Attendance (Screen1) - Modify

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\Screen1.pa.yaml`
- YAML key: Screen1
- Control name prefix: Att (new control: `btnAttNavStaff`)

Read `canvas-app-shared.md` first. Edit properties IN PLACE. Never rename, move or delete an existing control. The only
new control is `btnAttNavStaff`, appended as the last child of the existing `conAttNav`.

## Exact edit list

### 1. Screen `OnVisible` (lines 17-24) - remembered / default teacher must be active

Replace the inner `With({tid: varTeacher.Staff, cid: varCampus.Campus}, ...)` block with:
```
        With(
            {tid: varTeacher.Staff, cid: varCampus.Campus},
            If(
                IsTeacherRole, Set(varTeacher, CurrentStaff),
                IsBlank(tid) || IsBlank(LookUp(Staff, ThisRecord.Staff = tid && Campus.Campus = cid && Active = true)),
                Set(varTeacher, First(Sort(Filter(Staff, Campus.Campus = cid && 'App Role' = 'App Role (Staff)'.Teacher && Active = true), Name, SortOrder.Ascending)))
            )
        );
```
Everything else in OnVisible (comments, varLoading, campus self-heal, colAttYears, `Select(btnAttLoadEngine)`) is
unchanged. Keep the existing `|-` block form.

### 2. `conAttHeader.Height` (line 52)
`=If(conAttRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conAttRoot.Width < 640, 152, 48), 0)`

### 3. `conAttNav.Height` (line 105)
`=If(conAttRoot.Width < 640, 148, 44)`

### 4. NEW `btnAttNavStaff` - last child of `conAttNav` (after `btnAttNavTransport`)
```
- btnAttNavStaff:
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
(indent to match the sibling `btnAttNavTransport`). Requires StaffScreen to exist in the session.

### 5. `lblAttNotSetUpTitle` (lines 204-220)
- `AccessibleLabel: =Self.Text`
- `Text: =If(StaffPending, "Your access is being set up", "You're not set up yet")`

### 6. `lblAttNotSetUpBody.Text` (line 235) - write as a `|-` block
```
=If(
    StaffPending,
    "Your Staff record was found. Access is set up automatically within about 15 minutes of your first sign-in. Close the app and open it again in a few minutes.",
    "Your sign-in (" & User().Email & ") is not linked to an active Staff record. Ask your office manager to add you on the Staff screen, then reopen the app."
)
```
Heights unchanged: body 104 / 64 / 48 holds the longer pending text (about 160 characters: 4 lines at 343 px, 2 lines
at >= 640 px wide).

### 7. `ddAttCampus.OnChange` (line 501)
`=Set(varCampus, Self.Selected); Set(varTeacher, First(Sort(Filter(Staff, Campus.Campus = varCampus.Campus && 'App Role' = 'App Role (Staff)'.Teacher && Active = true), Name, SortOrder.Ascending))); Select(btnAttLoadEngine)`

### 8. `ddAttTeacher.Items` (line 539)
`=Sort(Filter(Staff, Campus.Campus = varCampus.Campus && 'App Role' = 'App Role (Staff)'.Teacher && Active = true), Name, SortOrder.Ascending)`

Nothing else changes (grid, load/save engines, legend, toolbar).

## Layout budget

Nav one row at >= 640: 110+8+110+8+110+8+140+8+80 = 582 <= 608 (640 - 32 header padding). Phone (343 inner): rows
228 / 258 / 80 -> 148. Header phone 92 + 152 = 244 = 12+28+4+36+4+148+12.

## Required Actions

| Action | Entry point and event | Source and stable ID | Mutation write set | Receipt proof set |
| --- | --- | --- | --- | --- |
| A-NAV-STAFF | btnAttNavStaff.OnSelect `=Navigate(StaffScreen)` | N/A | N/A | StaffScreen header current button |
| A-ATT-ACTIVE-PICKER | ddAttTeacher.Items, ddAttCampus.OnChange, OnVisible | Staff.Staff | N/A (read filter) | teacher dropdown list |
| A-SIGNIN-STATE | conAttNotSetUp (Visible `=!StaffReady`, unchanged) | StaffPending, CurrentStaff | N/A | lblAttNotSetUpTitle / Body text |

## Functional Test Scenarios

Owned: S-NAV-STAFF (Screen1 entry), S-NAV-ROLE (teacher sees no nav), S-ATT-PICKER, S-ATT-REMEMBERED,
S-SIGNIN-PENDING, S-SIGNIN-NOTSETUP, S-ATT-REGRESSION - copy rows from the plan index Functional Test Matrix.

## Control Definitions

- ModernButton (`Control: ModernButton`; NO Fill): AccessibleLabel, AlignInContainer, Appearance [ButtonAppearance],
  BasePaletteColor, Color, DisplayMode, Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth, OnSelect,
  Size, Text, Visible, Width.
- ModernText (existing labels): AccessibleLabel, Text (already present).
- GroupContainer / ModernDropdown: only Height / Items / OnChange values change (properties already present).

Enum literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `AlignInContainer.Center`.
