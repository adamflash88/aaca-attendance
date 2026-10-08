# Screen Plan: Absences - Calendar nav button

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml`
- YAML key: AbsencesScreen
- Control name prefix: Abs (new control: `btnAbsNavCalendar`)
- Build after CalendarScreen exists in the session (`Navigate(CalendarScreen)`).

## Current State

`conAbsHeader` (Ink band, no side padding, PaddingBottom `=If(CanClassify, 0, 12)`) holds `lblAbsTitle`,
`lblAbsIdentity`, `conAbsNav`, `conAbsHdrTabs`. `conAbsNav` (horizontal, LayoutWrap true, PaddingLeft/Right 16)
children in order: `btnAbsNavAttendance`, `btnAbsNavStudents`, `btnAbsNavAbsences` (CURRENT, teal),
`btnAbsNavTransport`, `btnAbsNavStaff`, `conAbsNavSpacer`, `imgAbsNavHelp`.

## Changes

1. Insert `btnAbsNavCalendar` into `conAbsNav` immediately AFTER `btnAbsNavStaff` and BEFORE `conAbsNavSpacer`
   (same 24-space list indent as `- btnAbsNavStaff:`):

```yaml
                        - btnAbsNavCalendar:
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
   - `conAbsNav.Height`
     from `=If(CanManageStudents, If(conAbsRoot.Width < 640, 148, 44) + If(CanClassify, 8, 0), 44)`
     to `=If(CanManageStudents, If(conAbsRoot.Width < 640, 148, conAbsRoot.Width < 800, 96, 44) + If(CanClassify, 8, 0), 44)`
   - `conAbsHeader.Height`
     from `=If(conAbsRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conAbsRoot.Width < 640, 152, 48), 48) + If(CanClassify, 60, 0)`
     to `=If(conAbsRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conAbsRoot.Width < 640, 152, conAbsRoot.Width < 800, 100, 48), 48) + If(CanClassify, 60, 0)`

## Layout and Visual Impact

Nav inner = root - 32 (nav padding 16+16). One row >= 800; two rows 96 at 640-799; phone three rows 148. Header
(CanClassify): desktop 12+28+4+20+4+52+4+60 = 184 = 76+48+60; band 12+28+4+20+4+104+4+60 = 236 = 76+100+60; phone
12+28+4+36+4+156+4+60 = 304 = 92+152+60. The tabs strip `conAbsHdrTabs` is unchanged. Never re-parent or rename.

## Controls to Add

`btnAbsNavCalendar` (above).

## Controls to Remove

None.

## Properties to Update

`conAbsNav.Height`, `conAbsHeader.Height` (above).

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-NAV-CAL | IsAdminRole | `btnAbsNavCalendar.OnSelect: =Navigate(CalendarScreen)` | N/A | CalendarScreen shown | N/A | N/A | `btnCalNavCalendar` teal (current) |

## Functional Test Scenarios

S-NAV-CAL, S-NAV-ROLE, S-NAV-LAYOUT, S-REG-ABS - copy from the plan index.

## Changed or Added Control Definitions

ModernButton (already used here; no new property or enum): AccessibleLabel, AlignInContainer, Appearance
[ButtonAppearance], Color, Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth, OnSelect, Size, Text,
Visible, Width. Literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `AlignInContainer.Center`.
