# Screen Plan: Students

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\billing-app\StudentsScreen.pa.yaml`
- YAML key: StudentsScreen
- Control name prefix: Stu
- Read with: `C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid\canvas-app-shared.md`

## Current State

`conStuRoot > conStuHeader > conStuNav` holds btnStuNavHome, btnStuNavFunders, btnStuNavServices,
btnStuNavStudents (current, teal Primary).

## Changes

1. Append ONE new child at the END of `conStuNav.Children` (after btnStuNavStudents). Change nothing else: no move,
   rename, re-order or property edit of any existing control.

## Controls to Add

```yaml
                        - btnStuNavRds:
                            Control: ModernButton
                            Properties:
                              AccessibleLabel: ="Go to RDS Grid"
                              AlignInContainer: =AlignInContainer.Center
                              Appearance: =ButtonAppearance.Secondary
                              Color: =ColorInk
                              FillPortions: =0
                              Height: =44
                              Layout: =ButtonLayout.TextOnly
                              OnSelect: =Navigate(RdsScreen)
                              Size: =14
                              Text: ="RDS Grid"
                              Width: =110
```

(Indentation must match the sibling `- btnStuNavStudents:` entry exactly.)

## Controls to Remove

None.

## Properties to Update

None.

## Layout and Visual Impact

`conStuNav`: 5 x 110 + 4 x 8 = 582 <= 608; one line, Height 44 unchanged. Secondary + ColorInk text.

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Observer and evidence |
| --- | --- | --- | --- | --- | --- |
| A-RDS-NAV | IsFinance | `btnStuNavRds.OnSelect: =Navigate(RdsScreen)` | N/A | RdsScreen opens | `btnRdsNavRds` teal |
| A-NAV-REG | IsFinance | existing nav, list, DoR / service-row forms | N/A | unchanged | unchanged |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-RDS-NAV | finance user on Students | "RDS Grid" | RdsScreen opens | RdsScreen nav | N/A |
| S-NAV-REG | finance user on Students | use list, detail, forms, nav | unchanged behaviour; no black-box controls | existing controls | N/A |

Compile note: `RdsScreen` resolves only once RdsScreen.pa.yaml exists; compile the whole app after all builders.

## Changed or Added Control Definitions

ModernButton (`Control: ModernButton`; no Fill): AccessibleLabel, AlignInContainer (`=AlignInContainer.Center`),
Appearance (Enum name ButtonAppearance -> `=ButtonAppearance.Secondary`), Color, FillPortions, Height, Layout
(Enum name ButtonLayout -> `=ButtonLayout.TextOnly`), OnSelect, Size, Text, Width.
