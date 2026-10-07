# Screen Plan: Transportation (TransportScreen) - Modify

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\TransportScreen.pa.yaml`
- YAML key: TransportScreen
- Control name prefix: Trn (new control: `btnTrnNavStaff`)

Read `canvas-app-shared.md` first. Edit properties IN PLACE. Never rename, move or delete an existing control.
TransportScreen has no teacher picker, so only the nav changes.

## Exact edit list

### 1. `conTrnHeader.Height` (line 46)
`=If(conTrnRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conTrnRoot.Width < 640, 152, 48), 0) + If(CanClassify, If(conTrnRoot.Width < 640, 112, 60), 0)`

### 2. `conTrnNav.Height` (line 98)
`=If(conTrnRoot.Width < 640, 148, 44) + If(CanClassify, 8, 0)`

### 3. NEW `btnTrnNavStaff` - last child of `conTrnNav` (after `btnTrnNavTransport`)
```
- btnTrnNavStaff:
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
(indent to match `btnTrnNavTransport`). Requires StaffScreen to exist in the session.

Nothing else changes.

## Layout budget

Nav 16+582+16 = 614 <= 640, one row; phone three rows 148 (+8). Header phone 92 + 152 + 112 = 356.

## Required Actions

| Action | Entry point and event | Source and stable ID | Mutation write set | Receipt proof set |
| --- | --- | --- | --- | --- |
| A-NAV-STAFF | btnTrnNavStaff.OnSelect | N/A | N/A | StaffScreen opens |

## Functional Test Scenarios

Owned: S-NAV-STAFF (Transportation entry), S-TRN-REGRESSION - copy rows from the plan index Functional Test Matrix.

## Control Definitions

- ModernButton (`Control: ModernButton`; NO Fill): AccessibleLabel, AlignInContainer, Appearance [ButtonAppearance],
  BasePaletteColor, Color, DisplayMode, Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth, OnSelect,
  Size, Text, Visible, Width.

Enum literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `AlignInContainer.Center`.
