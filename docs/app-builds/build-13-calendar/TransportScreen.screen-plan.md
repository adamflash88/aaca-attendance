# Screen Plan: Transportation - Calendar nav button

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\TransportScreen.pa.yaml`
- YAML key: TransportScreen
- Control name prefix: Trn (new control: `btnTrnNavCalendar`)
- Build after CalendarScreen exists in the session (`Navigate(CalendarScreen)`).

## Current State

`conTrnHeader` (Ink band, no side padding, PaddingBottom `=If(CanClassify, 0, 12)`) holds `lblTrnTitle`,
`lblTrnIdentity`, `conTrnNav`, `conTrnHdrTabs`. `conTrnNav` (horizontal, LayoutWrap true, PaddingLeft/Right 16)
children in order: `btnTrnNavAttendance`, `btnTrnNavStudents`, `btnTrnNavAbsences`, `btnTrnNavTransport` (CURRENT,
teal), `btnTrnNavStaff`, `conTrnNavSpacer`, `imgTrnNavHelp`.

## Changes

1. Insert `btnTrnNavCalendar` into `conTrnNav` immediately AFTER `btnTrnNavStaff` and BEFORE `conTrnNavSpacer`
   (same 24-space list indent as `- btnTrnNavStaff:`):

```yaml
                        - btnTrnNavCalendar:
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
   - `conTrnNav.Height`
     from `=If(CanManageStudents, If(conTrnRoot.Width < 640, 148, 44) + If(CanClassify, 8, 0), 44)`
     to `=If(CanManageStudents, If(conTrnRoot.Width < 640, 148, conTrnRoot.Width < 800, 96, 44) + If(CanClassify, 8, 0), 44)`
   - `conTrnHeader.Height`
     from `=If(conTrnRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conTrnRoot.Width < 640, 152, 48), 48) + If(CanClassify, If(conTrnRoot.Width < 640, 112, 60), 0)`
     to `=If(conTrnRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conTrnRoot.Width < 640, 152, conTrnRoot.Width < 800, 100, 48), 48) + If(CanClassify, If(conTrnRoot.Width < 640, 112, 60), 0)`

## Layout and Visual Impact

Nav inner = root - 32. One row >= 800; two rows 96 at 640-799; phone three rows 148. Header (CanClassify): desktop
76+48+60 = 184; band 76+100+60 = 236; phone 92+152+112 = 356. The tabs strip `conTrnHdrTabs` is unchanged. Never
re-parent or rename.

## Controls to Add

`btnTrnNavCalendar` (above).

## Controls to Remove

None.

## Properties to Update

`conTrnNav.Height`, `conTrnHeader.Height` (above).

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-NAV-CAL | IsAdminRole | `btnTrnNavCalendar.OnSelect: =Navigate(CalendarScreen)` | N/A | CalendarScreen shown | N/A | N/A | `btnCalNavCalendar` teal (current) |

## Functional Test Scenarios

S-NAV-CAL, S-NAV-ROLE, S-NAV-LAYOUT, S-REG-TRN - copy from the plan index.

## Changed or Added Control Definitions

ModernButton (already used here; no new property or enum): AccessibleLabel, AlignInContainer, Appearance
[ButtonAppearance], Color, Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth, OnSelect, Size, Text,
Visible, Width. Literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `AlignInContainer.Center`.
