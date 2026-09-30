# Screen Plan: Attendance (Screen1)

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\Screen1.pa.yaml`
- YAML key: Screen1
- Control name prefix: Att
- Compile order: this file references `StudentsScreen` (Navigate). Compile it only after
  `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml` exists in the session, or together with it.

## Current State

Screen1 (86 controls) has one AutoLayout root `conAttRoot` (vertical, scrolls). Its first child is the
header `conAttHeader` (vertical, `Fill: =ColorInk`, `LayoutGap: =4`, padding 12/16/12/16,
`Height: =If(conAttRoot.Width < 640, 92, 76)`) containing `lblAttTitle` and `lblAttIdentity`.
Everything else (toolbar, notice, spinner, receipt, confirm, detail, month view, day view, engines) must
remain byte-for-byte identical, including `Screen1.OnVisible: =Select(btnAttLoadEngine)`.

## Changes

1. Change `conAttHeader.Height` (the only existing property that changes).
2. Append one child `conAttNav` to `conAttHeader.Children`, after `lblAttIdentity`, holding the two nav
   buttons from the shared Header + Navigation Pattern (Attendance = current screen).

Nothing else in the file changes: no other property, no reordering, no reformatting.

## Layout and Visual Impact

- Breakpoint source: `conAttRoot.Width` (as the existing header already uses).
- Vertical budget: 12 + 28 (title) + 4 + 20|36 (identity) + 4 + 44 (nav) + 12 = 124 desktop/tablet,
  140 phone; without nav (teachers, read-only, not set up) 76 / 92 as today.
- Horizontal budget (nav row): 120 + 8 + 120 = 248 <= 358 (390 phone - 32 padding) <= 1334 desktop.
- Text fit: "Attendance" at Size 14 is ~75 px + button padding < 120; "Students" < 120. Single line.
- Contrast: Primary teal button with white text (current); Secondary light surface with `ColorInk`
  text (other). Both sit on the ink header band.
- Record presentation: N/A (no record surface touched).

## Required Record Fields

None touched.

## Controls to Add

Under `conAttHeader.Children`, immediately after `lblAttIdentity`:

```yaml
- conAttNav:
    Control: GroupContainer
    Variant: AutoLayout
    Properties:
      AlignInContainer: =AlignInContainer.Stretch
      DropShadow: =DropShadow.None
      FillPortions: =0
      Height: =44
      LayoutAlignItems: =LayoutAlignItems.Center
      LayoutDirection: =LayoutDirection.Horizontal
      LayoutGap: =8
      LayoutMinHeight: =0
      LayoutMinWidth: =0
      RadiusBottomLeft: =0
      RadiusBottomRight: =0
      RadiusTopLeft: =0
      RadiusTopRight: =0
      Visible: =CanManageStudents
    Children:
      - btnAttNavAttendance:
          Control: ModernButton
          Properties:
            AccessibleLabel: ="Attendance (current screen)"
            AlignInContainer: =AlignInContainer.Center
            Appearance: =ButtonAppearance.Primary
            BasePaletteColor: =ColorTeal
            Color: =ColorWhite
            FillPortions: =0
            Height: =44
            Layout: =ButtonLayout.TextOnly
            LayoutMinHeight: =0
            LayoutMinWidth: =0
            OnSelect: =Navigate(Screen1)
            Size: =14
            Text: ="Attendance"
            Width: =120
      - btnAttNavStudents:
          Control: ModernButton
          Properties:
            AccessibleLabel: ="Go to Students"
            AlignInContainer: =AlignInContainer.Center
            Appearance: =ButtonAppearance.Secondary
            Color: =ColorInk
            FillPortions: =0
            Height: =44
            Layout: =ButtonLayout.TextOnly
            LayoutMinHeight: =0
            LayoutMinWidth: =0
            OnSelect: =Navigate(StudentsScreen)
            Size: =14
            Text: ="Students"
            Width: =120
```

## Controls to Remove

None.

## Properties to Update

- `conAttHeader` → `Height` → `=If(conAttRoot.Width < 640, 92, 76) + If(CanManageStudents, 48, 0)`

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| ----------- | --------------- | --------------- | ------------------------- |
| SURF-ATT-NAV | conAttNav | `=CanManageStudents` | Visible for Attendance Office and System Admin; hidden for Teacher, Read-only and not-set-up users |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| ------ | ------------- | --------------------- | -------------------- | ---------------------------- | ------------------ | ----------------- | --------------------- |
| A-NAV-STUDENTS | `CanManageStudents` true | `btnAttNavStudents.OnSelect: =Navigate(StudentsScreen)` in header, initial viewport | N/A | Active screen becomes StudentsScreen | N/A | N/A | StudentsScreen header shows `btnStuNavStudents` in Primary (current) state and the Students list panel |
| A-NAV-ATTENDANCE (current item) | `CanManageStudents` true | `btnAttNavAttendance.OnSelect: =Navigate(Screen1)` | N/A | Stays on Screen1 | N/A | N/A | `btnAttNavAttendance` Primary teal = current screen |

## Data Entry Label Contracts

None (no inputs added).

## Mutation Lifecycle Evidence

None (no mutation added or changed).

## Mutation Field Ledger

None.

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| -------- | ----- | ---- | ---- | ---------------- | ------------------------- |
| S-NAV-OFFICE | Signed in as Attendance Office or System Admin (Adam: System Admin, blank campus) | Open app; press **Students** in the header | StudentsScreen opens | `btnStuNavStudents` Primary; `lblStuListTitle` "Students" | Pressing **Attendance** there returns to Screen1 with the month grid (Screen1.OnVisible reloads) |
| S-NAV-TEACHER-HIDDEN | Signed in as a Teacher or Read-only user | Open app | `conAttNav` hidden; header height 76 (92 phone) exactly as build 1 | `conAttNav.Visible = false` | No other path to StudentsScreen exists for these roles |
| S-REGRESSION-ATTENDANCE | Any role, current month Sep 2026 | Use month nav, cells, Day view, details, clear confirm as in build 1 | Identical behaviour to build 1 | All existing Att controls unchanged | Diff of Screen1.pa.yaml shows only the Height line and the added `conAttNav` block |

## Changed or Added Control Definitions

GroupContainer — `Control: GroupContainer`, `Variant: AutoLayout` (required; Variants AutoLayout | GridLayout | ManualLayout).
Inputs: BorderColor, BorderStyle, BorderThickness, ContentLanguage, DropShadow, EnableChildFocus, Fill, Height,
RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft, RadiusTopRight, Visible, Width, X, Y, LayoutAlignItems,
LayoutDirection, LayoutGap, LayoutJustifyContent, LayoutOverflowX, LayoutOverflowY, LayoutWrap, PaddingBottom,
PaddingLeft, PaddingRight, PaddingTop; as AutoLayout child: AlignInContainer, FillPortions, LayoutMaxHeight,
LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth.
Enum literals used: `=DropShadow.None`, `=LayoutAlignItems.Center`, `=LayoutDirection.Horizontal`,
`=AlignInContainer.Stretch` (Enum names: DropShadow, LayoutAlignItems, LayoutDirection, AlignInContainer).

ModernButton — `Control: ModernButton` (no Variant; NO `Fill` property).
Inputs: AccessibleLabel, Align, Appearance, BasePaletteColor, BorderColor, BorderStyle, BorderThickness, Color,
ContentLanguage, DisplayMode, Font, FontWeight, Height, Icon, IconRotation, IconStyle, Italic, Layout, OnSelect,
PaddingBottom, PaddingLeft, PaddingRight, PaddingTop, RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft,
RadiusTopRight, Size, Strikethrough, Text, Tooltip, Underline, VerticalAlign, Visible, Width, X, Y; as AutoLayout
child: AlignInContainer, FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth.
Enum literals used: `Appearance: =ButtonAppearance.Primary` / `=ButtonAppearance.Secondary` (Enum name
ButtonAppearance); `Layout: =ButtonLayout.TextOnly` (Enum name ButtonLayout); `=AlignInContainer.Center`.
