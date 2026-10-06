# Screen Plan: Students - build 9 minimal edit

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml`
- YAML key: StudentsScreen
- Control name prefix: Stu (one new control: `btnStuNavTransport`)

Read `canvas-app-shared.md` first. Do not rename, move or delete any control. Only the edits below.

## Current State

Header `conStuHeader` (Ink, padding 16, Height `=If(conStuRoot.Width < 640, 92, 76) + If(CanManageStudents, 48, 0)`)
-> `lblStuTitle`, `lblStuIdentity`, `conStuNav` (Height 44; Attendance / Students current / Absences).

## Changes / Properties to Update

| Control | Property | Value |
| --- | --- | --- |
| conStuHeader | Height | `=If(conStuRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conStuRoot.Width < 640, 100, 48), 0)` |
| conStuNav | Height | `=If(conStuRoot.Width < 640, 96, 44)` |
| conStuNav | LayoutWrap (new) | `=true` |

## Controls to Add

`btnStuNavTransport` (ModernButton) - last child of `conStuNav` (after `btnStuNavAbsences`): AccessibleLabel
`="Go to Transportation"`, AlignInContainer `=AlignInContainer.Center`, Appearance `=ButtonAppearance.Secondary`,
Color `=ColorInk`, Height `=44`, Layout `=ButtonLayout.TextOnly`, LayoutMinHeight `=0`, LayoutMinWidth `=0`,
OnSelect `=Navigate(TransportScreen)`, Size `=14`, Text `="Transportation"`, Visible `=CanClassify`, Width `=140`.

## Controls to Remove

None.

## Layout and Visual Impact

Nav 110+8+110+8+110+8+140 = 494 <= 992 at 1024; wraps to two rows (Height 96) below ~526 px; header grows 52 px on
phone only.

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-NAV-TRANSPORT | CanClassify | btnStuNavTransport.OnSelect `=Navigate(TransportScreen)` | N/A | TransportScreen shown | N/A | N/A | TransportScreen header, Transportation button teal |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-NAV-TRANSPORT | office user on Students | press Transportation | TransportScreen opens | `btnTrnNavTransport` current | Teacher: `conStuNav` hidden (existing) |

## Changed or Added Control Definitions

ModernButton (`Control: ModernButton`): AccessibleLabel, AlignInContainer [AlignInContainer], Appearance
[ButtonAppearance], Color, Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth, OnSelect, Size, Text,
Visible, Width. Literals `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `AlignInContainer.Center`.
GroupContainer `LayoutWrap` (Boolean) is a valid AutoLayout input.
