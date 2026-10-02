# Screen Plan: Services

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\billing-app\ServicesScreen.pa.yaml`
- YAML key: ServicesScreen
- Control name prefix: Svc
- Read with: `C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid\canvas-app-shared.md`

## Current State

`conSvcRoot > conSvcHeader > conSvcNav` holds btnSvcNavHome, btnSvcNavFunders, btnSvcNavServices (current, teal
Primary), btnSvcNavStudents.

## Changes

1. Append ONE new child at the END of `conSvcNav.Children` (after btnSvcNavStudents). Change nothing else: no move,
   rename, re-order or property edit of any existing control.

## Controls to Add

```yaml
                        - btnSvcNavRds:
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

(Indentation must match the sibling `- btnSvcNavStudents:` entry exactly.)

## Controls to Remove

None.

## Properties to Update

None.

## Layout and Visual Impact

`conSvcNav`: 5 x 110 + 4 x 8 = 582 <= 608; one line, Height 44 unchanged. Secondary + ColorInk text.

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Observer and evidence |
| --- | --- | --- | --- | --- | --- |
| A-RDS-NAV | IsFinance | `btnSvcNavRds.OnSelect: =Navigate(RdsScreen)` | N/A | RdsScreen opens | `btnRdsNavRds` teal |
| A-NAV-REG | IsFinance | existing nav, list, form | N/A | unchanged | unchanged |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-RDS-NAV | finance user on Services | "RDS Grid" | RdsScreen opens | RdsScreen nav | N/A |
| S-NAV-REG | finance user on Services | use list, form, nav | unchanged behaviour; no black-box controls | existing controls | N/A |

Compile note: `RdsScreen` resolves only once RdsScreen.pa.yaml exists; compile the whole app after all builders.

## Changed or Added Control Definitions

ModernButton (`Control: ModernButton`; no Fill): AccessibleLabel, AlignInContainer (`=AlignInContainer.Center`),
Appearance (Enum name ButtonAppearance -> `=ButtonAppearance.Secondary`), Color, FillPortions, Height, Layout
(Enum name ButtonLayout -> `=ButtonLayout.TextOnly`), OnSelect, Size, Text, Width.
