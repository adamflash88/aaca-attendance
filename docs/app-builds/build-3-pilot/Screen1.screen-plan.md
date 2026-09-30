# Screen Plan: Attendance

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\Screen1.pa.yaml`
- YAML key: Screen1
- Control name prefix: Att

## Current State

`conAttRoot` (sole root, AutoLayout, scroll) -> `conAttHeader` (ink band, Height
`=If(conAttRoot.Width < 640, 92, 76) + If(CanManageStudents, 48, 0)`) -> `lblAttTitle`, `lblAttIdentity`,
`conAttNav` (horizontal, h44, gap 8, `Visible: =CanManageStudents`) with `btnAttNavAttendance` (current, teal,
Width 120) and `btnAttNavStudents` (Secondary, Width 120). Everything else (toolbar, grid, day view, engines) is out
of scope and must not change.

## Changes

1. Add a third nav button `btnAttNavAbsences` as the LAST child of `conAttNav` (after `btnAttNavStudents`).
2. Change `Width` of `btnAttNavAttendance` and `btnAttNavStudents` from `=120` to `=110`.
3. Nothing else in the file changes (no toolbar, grid, OnVisible, engine or root edits).

## Layout and Visual Impact

- Responsive bounds: header inner width at 390 = 390 - 16 - 16 = 358; nav row 110 + 8 + 110 + 8 + 110 = 346 <= 358
  (one row at every width). Desktop/tablet: 346 px at left of the band.
- Breakpoint source: unchanged (conAttRoot.Width); nav row has no breakpoint.
- Numeric layout budgets: conAttNav height 44 = button height 44; header height formula unchanged (already adds 48
  for the nav row).
- Text fit: "Attendance" (10 chars, Size 14 ≈ 75 px + ~24 px button padding ≈ 99) fits 110; "Students", "Absences"
  shorter. Single line.
- Visual contract: shared header navigation pattern (canvas-app-shared.md). Current = teal Primary; others Secondary
  ink text.
- Record presentation: N/A.

## Controls to Add

`btnAttNavAbsences` — ModernButton, last child of `conAttNav`:

```yaml
- btnAttNavAbsences:
    Control: ModernButton
    Properties:
      AccessibleLabel: ="Go to Absences"
      AlignInContainer: =AlignInContainer.Center
      Appearance: =ButtonAppearance.Secondary
      Color: =ColorInk
      Height: =44
      Layout: =ButtonLayout.TextOnly
      LayoutMinHeight: =0
      LayoutMinWidth: =0
      OnSelect: =Navigate(AbsencesScreen)
      Size: =14
      Text: ="Absences"
      Width: =110
```

(Existing nav buttons omit `FillPortions`; ModernButton's AutoLayout default is 0 — add `FillPortions: =0` to all
three nav buttons for explicitness.)

## Controls to Remove

None.

## Properties to Update

- `btnAttNavAttendance` -> `Width` -> `=110`; add `FillPortions: =0`
- `btnAttNavStudents` -> `Width` -> `=110`; add `FillPortions: =0`

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| ------ | ------------- | --------------------- | -------------------- | ---------------------------- | ------------------ | ----------------- | --------------------- |
| A-NAV-ATTENDANCE | CanManageStudents | btnAttNavAttendance.OnSelect `=Navigate(Screen1)` (existing) | N/A | stays on Screen1 | N/A | N/A | teal current button |
| A-NAV-STUDENTS | CanManageStudents | btnAttNavStudents.OnSelect `=Navigate(StudentsScreen)` (existing) | N/A | StudentsScreen shown | N/A | N/A | Students button teal there |
| A-NAV-ABSENCES | CanManageStudents | btnAttNavAbsences.OnSelect `=Navigate(AbsencesScreen)` (new) | N/A | AbsencesScreen shown and loads | N/A | N/A | Absences button teal there |

Cross-screen observer (no change here): after classifying on AbsencesScreen, returning to Screen1 runs the existing
OnVisible -> `Select(btnAttLoadEngine)`, which reloads `colMonthAtt` with `Letter` "E" / "U" from
`'Absence Classification'`, so the grid shows the excused/unexcused colour for that day.

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| -------- | ----- | ---- | ---- | ---------------- | ------------------------- |
| S-NAV3-OFFICE | Office user on Screen1 | Tap Absences | AbsencesScreen opens | its Absences button teal | Row fits at 390 (346 <= 358) |
| S-NAV3-TEACHER-HIDDEN | Teacher user | Open app | conAttNav hidden (Visible = CanManageStudents false) | no nav row | Read-only same |
| S-REGRESSION | Any user | Record P/A, All present, month/teacher pickers | Identical to build 2 | varLastAction receipt, grid | No other property changed |

## Changed or Added Control Definitions

ModernButton (React) — `Control: ModernButton`. Valid inputs: AccessibleLabel, Align, Appearance, BasePaletteColor,
BorderColor, BorderStyle, BorderThickness, Color, ContentLanguage, DisplayMode, Font, FontWeight, Height, Icon,
IconRotation, IconStyle, Italic, Layout, OnSelect, PaddingBottom/Left/Right/Top, RadiusBottomLeft/BottomRight/
TopLeft/TopRight, Size, Strikethrough, Text, Tooltip, Underline, VerticalAlign, Visible, Width, X, Y; as AutoLayout
child AlignInContainer, FillPortions, LayoutMinHeight, LayoutMinWidth, LayoutMaxHeight, LayoutMaxWidth. No `Fill`.

- Appearance — Enum name `ButtonAppearance` -> `=ButtonAppearance.Secondary`
- Layout — Enum name `ButtonLayout` -> `=ButtonLayout.TextOnly`
- AlignInContainer — Enum name `AlignInContainer` -> `=AlignInContainer.Center`
