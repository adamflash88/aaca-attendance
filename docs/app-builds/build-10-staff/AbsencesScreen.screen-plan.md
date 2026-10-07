# Screen Plan: Absences (AbsencesScreen) - Modify

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml`
- YAML key: AbsencesScreen
- Control name prefix: Abs (new control: `btnAbsNavStaff`)

Read `canvas-app-shared.md` first. Edit properties IN PLACE. Never rename, move or delete an existing control.
`colAbsTeacherSrc` / `colAbsTeacherOpts` are NOT changed (history filter keeps retired teachers).

## Exact edit list

### 1. `conAbsHeader.Height` (line 53)
`=If(conAbsRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conAbsRoot.Width < 640, 152, 48), 0) + If(CanClassify, 60, 0)`

### 2. `conAbsNav.Height` (line 105)
`=If(conAbsRoot.Width < 640, 148, 44) + If(CanClassify, 8, 0)`

### 3. NEW `btnAbsNavStaff` - last child of `conAbsNav` (after `btnAbsNavTransport`)
```
- btnAbsNavStaff:
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
(indent to match `btnAbsNavTransport`). Requires StaffScreen to exist in the session.

Nothing else changes.

## Layout budget

Nav (PaddingLeft/Right 16 inside the header): 16+582+16 = 614 <= 640, one row; phone three rows 148 (+8).

## Required Actions

| Action | Entry point and event | Source and stable ID | Mutation write set | Receipt proof set |
| --- | --- | --- | --- | --- |
| A-NAV-STAFF | btnAbsNavStaff.OnSelect | N/A | N/A | StaffScreen opens |

## Functional Test Scenarios

Owned: S-NAV-STAFF (Absences entry), S-ABS-REGRESSION - copy rows from the plan index Functional Test Matrix.

## Control Definitions

- ModernButton (`Control: ModernButton`; NO Fill): AccessibleLabel, AlignInContainer, Appearance [ButtonAppearance],
  BasePaletteColor, Color, DisplayMode, Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth, OnSelect,
  Size, Text, Visible, Width.

Enum literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `AlignInContainer.Center`.
