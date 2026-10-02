# Screen Plan: Home

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\billing-app\HomeScreen.pa.yaml`
- YAML key: HomeScreen
- Control name prefix: Home
- Read with: `C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid\canvas-app-shared.md`

## Current State

`conHomeRoot > conHomeHeader > conHomeNav` holds four ModernButtons: btnHomeNavHome (current, teal Primary),
btnHomeNavFunders, btnHomeNavServices, btnHomeNavStudents (Secondary). `conHomeNext > lblHomeNextBody` still lists
the RDS grid as a later phase.

## Changes

1. Append ONE new child at the END of `conHomeNav.Children` (after btnHomeNavStudents). Do not move, rename,
   re-order or edit any existing control.
2. Update two properties of the existing `lblHomeNextBody` in place (text no longer says the RDS grid is coming).

## Controls to Add

```yaml
                        - btnHomeNavRds:
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

(Indentation must match the sibling `- btnHomeNavStudents:` entry exactly.)

## Controls to Remove

None.

## Properties to Update

- `lblHomeNextBody.Text` and `lblHomeNextBody.AccessibleLabel` (keep the `|-` form):
```
="Later phases, not in this version: CodeMetro upload and exceptions screens; month close and QuickBooks Online invoice export; RDS PDFs."
```
No other property changes (Height formula of conHomeNext stays; the text is shorter).

## Layout and Visual Impact

- `conHomeNav`: 5 x 110 + 4 x 8 = 582 <= 608 (narrowest supported 640 - 32); one line, Height 44 unchanged.
- Text fit: "RDS Grid" at Size 14 is ~65 px in 110.
- Visual contract: Secondary nav button, `Color: =ColorInk` (dark text on light Secondary surface).

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Observer and evidence |
| --- | --- | --- | --- | --- | --- |
| A-RDS-NAV | IsFinance (conHomeNav visible) | `btnHomeNavRds.OnSelect: =Navigate(RdsScreen)` | N/A | RdsScreen opens | `btnRdsNavRds` teal on RdsScreen |
| A-NAV-REG | IsFinance | existing nav buttons | N/A | unchanged | unchanged |
| A-HOME-NEXT | always | none | N/A | text updated | `lblHomeNextBody` |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-RDS-NAV | finance user on Home | select "RDS Grid" | RdsScreen opens | RdsScreen nav | non-finance: nav hidden |
| S-NAV-REG | finance user on Home | Funders / Services / Students | unchanged; Home cards and counts render normally (no black boxes) | existing controls | N/A |
| S-HOME-NEXT | Home | read Coming next | no mention of the RDS grid | `lblHomeNextBody` | N/A |

Compile note: `RdsScreen` resolves only once RdsScreen.pa.yaml exists; compile the whole app after all builders.

## Changed or Added Control Definitions

ModernButton (`Control: ModernButton`; no Fill): AccessibleLabel, AlignInContainer (`=AlignInContainer.Center`),
Appearance (Enum name ButtonAppearance -> `=ButtonAppearance.Secondary`), BasePaletteColor, Color, FillPortions,
Height, Layout (Enum name ButtonLayout -> `=ButtonLayout.TextOnly`), OnSelect, Size, Text, Width.
