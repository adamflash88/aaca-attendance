# Screen Plan: Students - Calendar nav button

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml`
- YAML key: StudentsScreen
- Control name prefix: Stu (new control: `btnStuNavCalendar`)
- Build after CalendarScreen exists in the session (`Navigate(CalendarScreen)`).

## Current State

`conStuHeader` (Ink band, header PaddingLeft/Right 16) holds `lblStuTitle`, `lblStuIdentity`, `conStuNav`.
`conStuNav` (horizontal, LayoutWrap true, no side padding) children in order: `btnStuNavAttendance`,
`btnStuNavStudents` (CURRENT, teal), `btnStuNavAbsences`, `btnStuNavTransport`, `btnStuNavStaff`, `conStuNavSpacer`,
`imgStuNavHelp`.

## Changes

1. Insert `btnStuNavCalendar` into `conStuNav` immediately AFTER `btnStuNavStaff` and BEFORE `conStuNavSpacer`
   (same 24-space list indent as `- btnStuNavStaff:`):

```yaml
                        - btnStuNavCalendar:
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
   - `conStuNav.Height`
     from `=If(CanManageStudents, If(conStuRoot.Width < 640, 148, 44), 44)`
     to `=If(CanManageStudents, If(conStuRoot.Width < 640, 148, conStuRoot.Width < 800, 96, 44), 44)`
   - `conStuHeader.Height`
     from `=If(conStuRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conStuRoot.Width < 640, 152, 48), 48)`
     to `=If(conStuRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conStuRoot.Width < 640, 152, conStuRoot.Width < 800, 100, 48), 48)`

## Layout and Visual Impact

Same arithmetic as Screen1 (nav inner = root - 32): one row >= 800 (750 <= inner), two rows 96 at 640-799, three
rows 148 on a phone (228 / 258 / 240). Header 124 / 176 / 244. Never re-parent or rename anything.

## Controls to Add

`btnStuNavCalendar` (above).

## Controls to Remove

None.

## Properties to Update

`conStuNav.Height`, `conStuHeader.Height` (above).

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-NAV-CAL | IsAdminRole | `btnStuNavCalendar.OnSelect: =Navigate(CalendarScreen)` | N/A | CalendarScreen shown | N/A | N/A | `btnCalNavCalendar` teal (current) |

## Functional Test Scenarios

S-NAV-CAL, S-NAV-ROLE, S-NAV-LAYOUT, S-REG-STU - copy from the plan index.

## Changed or Added Control Definitions

ModernButton (already used here; no new property or enum): AccessibleLabel, AlignInContainer, Appearance
[ButtonAppearance], Color, Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth, OnSelect, Size, Text,
Visible, Width. Literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `AlignInContainer.Center`.
