# Screen Plan: Funders

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\billing-app\FundersScreen.pa.yaml`
- YAML key: FundersScreen
- Control name prefix: Fun
- Read with: `C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid\canvas-app-shared.md`

## Current State

`conFunRoot > conFunHeader > conFunNav` holds btnFunNavHome, btnFunNavFunders (current, teal Primary),
btnFunNavServices, btnFunNavStudents.

## Changes

1. Append ONE new child at the END of `conFunNav.Children` (after btnFunNavStudents). Change nothing else: no move,
   rename, re-order or property edit of any existing control.

## Controls to Add

```yaml
                        - btnFunNavRds:
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

(Indentation must match the sibling `- btnFunNavStudents:` entry exactly.)

## Controls to Remove

None.

## Properties to Update

None.

## Layout and Visual Impact

`conFunNav`: 5 x 110 + 4 x 8 = 582 <= 608; one line, Height 44 unchanged. Secondary + ColorInk text.

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Observer and evidence |
| --- | --- | --- | --- | --- | --- |
| A-RDS-NAV | IsFinance | `btnFunNavRds.OnSelect: =Navigate(RdsScreen)` | N/A | RdsScreen opens | `btnRdsNavRds` teal |
| A-NAV-REG | IsFinance | existing nav, list, form | N/A | unchanged | unchanged |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-RDS-NAV | finance user on Funders | "RDS Grid" | RdsScreen opens | RdsScreen nav | N/A |
| S-NAV-REG | finance user on Funders | use list, form, nav | unchanged behaviour; no black-box controls | existing controls | N/A |

Compile note: `RdsScreen` resolves only once RdsScreen.pa.yaml exists; compile the whole app after all builders.

## Changed or Added Control Definitions

ModernButton (`Control: ModernButton`; no Fill): AccessibleLabel, AlignInContainer (`=AlignInContainer.Center`),
Appearance (Enum name ButtonAppearance -> `=ButtonAppearance.Secondary`), Color, FillPortions, Height, Layout
(Enum name ButtonLayout -> `=ButtonLayout.TextOnly`), OnSelect, Size, Text, Width.
