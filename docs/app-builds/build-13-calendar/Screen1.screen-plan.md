# Screen Plan: Attendance (Screen1) - Calendar nav button

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\Screen1.pa.yaml`
- YAML key: Screen1
- Control name prefix: Att (new control: `btnAttNavCalendar`)
- Build after CalendarScreen exists in the session (`Navigate(CalendarScreen)`).

## Current State

`conAttHeader` (Ink band, header PaddingLeft/Right 16) holds `lblAttTitle`, `lblAttIdentity`, `conAttNav`.
`conAttNav` (horizontal, LayoutWrap true, no side padding) children in order: `btnAttNavAttendance` (CURRENT, teal),
`btnAttNavStudents`, `btnAttNavAbsences`, `btnAttNavTransport`, `btnAttNavStaff`, `conAttNavSpacer`,
`imgAttNavHelp`.

## Changes

1. Insert `btnAttNavCalendar` into `conAttNav` immediately AFTER `btnAttNavStaff` and BEFORE `conAttNavSpacer`
   (same 24-space list indent as `- btnAttNavStaff:`):

```yaml
                        - btnAttNavCalendar:
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

2. Replace two Height values in place (nothing else changes):
   - `conAttNav.Height`
     from `=If(CanManageStudents, If(conAttRoot.Width < 640, 148, 44), 44)`
     to `=If(CanManageStudents, If(conAttRoot.Width < 640, 148, conAttRoot.Width < 800, 96, 44), 44)`
   - `conAttHeader.Height`
     from `=If(conAttRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conAttRoot.Width < 640, 152, 48), 48)`
     to `=If(conAttRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conAttRoot.Width < 640, 152, conAttRoot.Width < 800, 100, 48), 48)`

## Layout and Visual Impact

- Nav inner width = root - 32 (header padding). Admin: 650 buttons + 56 gaps + 44 logo = 750 -> one row at root >= 782
  (>= 800 branch, 44); 640-799 two rows (582 | Calendar + spacer + logo) = 96; phone three rows 228 / 258 / 240 = 148
  (unchanged). Office (Calendar hidden): unchanged rows, extra 52 px only in the 640-799 band.
- Header: desktop 12+28+4+20+4+44+12 = 124 = 76+48; band 12+28+4+20+4+96+12 = 176 = 76+100; phone
  12+28+4+36+4+148+12 = 244 = 92+152.
- Visual contract: identical to the other nav buttons (Secondary, ink text; never re-parent or rename anything).

## Controls to Add

`btnAttNavCalendar` (above).

## Controls to Remove

None.

## Properties to Update

`conAttNav.Height`, `conAttHeader.Height` (above).

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-NAV-CAL | IsAdminRole | `btnAttNavCalendar.OnSelect: =Navigate(CalendarScreen)` | N/A | CalendarScreen shown | N/A | N/A | `btnCalNavCalendar` teal (current) |

## Functional Test Scenarios

S-NAV-CAL, S-NAV-ROLE, S-NAV-LAYOUT, S-REG-ATT - copy from the plan index.

## Changed or Added Control Definitions

ModernButton (already used here; no new property or enum): AccessibleLabel, AlignInContainer, Appearance
[ButtonAppearance], Color, Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth, OnSelect, Size, Text,
Visible, Width. Literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `AlignInContainer.Center`.
