# Screen Plan: Staff - Calendar nav button

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\StaffScreen.pa.yaml`
- YAML key: StaffScreen
- Control name prefix: Stf (new control: `btnStfNavCalendar`)
- Build after CalendarScreen exists in the session (`Navigate(CalendarScreen)`).

## Current State

`conStfHeader` (Ink band, no side padding, PaddingBottom `=If(CanManageStudents, 0, 12)`) holds `lblStfTitle`,
`lblStfIdentity`, `conStfNav`, `conStfHdrBar`. `conStfNav` (horizontal, LayoutWrap true, PaddingLeft/Right 16)
children in order (lines 109-219): `btnStfNavAttendance`, `btnStfNavStudents`, `btnStfNavAbsences`,
`btnStfNavTransport`, `btnStfNavStaff` (CURRENT, teal), `conStfNavSpacer`, `imgStfNavHelp`.

## Changes

1. Insert `btnStfNavCalendar` into `conStfNav` immediately AFTER `btnStfNavStaff` (ends at line 188) and BEFORE
   `conStfNavSpacer` (same 24-space list indent as `- btnStfNavStaff:`):

```yaml
                        - btnStfNavCalendar:
                            Control: ModernButton
                            Properties:
                              AccessibleLabel: ="Go to Calendar"
                              AlignInContainer: =AlignInContainer.Center
                              Appearance: =ButtonAppearance.Secondary
                              Color: =ColorInk
                              Height: =44
                              Layout: =ButtonLayout.TextOnly
                              LayoutMinHeight: =0
                              LayoutMinWidth: =0
                              OnSelect: =Navigate(CalendarScreen)
                              Size: =14
                              Text: ="Calendar"
                              Visible: =IsAdminRole
                              Width: =100
```

2. Replace two Height values in place:
   - `conStfNav.Height` (line 95)
     from `=If(CanManageStudents, If(conStfRoot.Width < 640, 148, 44) + 8, 44)`
     to `=If(CanManageStudents, If(conStfRoot.Width < 640, 148, conStfRoot.Width < 800, 96, 44) + 8, 44)`
   - `conStfHeader.Height` (line 43)
     from `=If(conStfRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conStfRoot.Width < 640, 152, 48), 48) + If(CanManageStudents, 60, 0)`
     to `=If(conStfRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conStfRoot.Width < 640, 152, conStfRoot.Width < 800, 100, 48), 48) + If(CanManageStudents, 60, 0)`

## Layout and Visual Impact

Nav inner = root - 32. One row >= 800; two rows 96 at 640-799; phone three rows 148. Header (office/admin):
desktop 12+28+4+20+4+52+4+60 = 184 = 76+48+60; band 12+28+4+20+4+104+4+60 = 236 = 76+100+60; phone
12+28+4+36+4+156+4+60 = 304 = 92+152+60. `conStfHdrBar` unchanged. Never re-parent or rename.

## Controls to Add

`btnStfNavCalendar` (above).

## Controls to Remove

None.

## Properties to Update

`conStfNav.Height`, `conStfHeader.Height` (above).

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-NAV-CAL | IsAdminRole | `btnStfNavCalendar.OnSelect: =Navigate(CalendarScreen)` | N/A | CalendarScreen shown | N/A | N/A | `btnCalNavCalendar` teal (current) |

## Functional Test Scenarios

S-NAV-CAL, S-NAV-ROLE, S-NAV-LAYOUT, S-REG-STF - copy from the plan index.

## Changed or Added Control Definitions

ModernButton (already used here; no new property or enum): AccessibleLabel, AlignInContainer, Appearance
[ButtonAppearance], Color, Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth, OnSelect, Size, Text,
Visible, Width. Literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `AlignInContainer.Center`.
