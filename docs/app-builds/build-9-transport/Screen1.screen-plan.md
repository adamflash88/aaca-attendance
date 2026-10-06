# Screen Plan: Attendance (Screen1) - build 9 minimal edit

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\Screen1.pa.yaml`
- YAML key: Screen1
- Control name prefix: Att (one new control: `btnAttNavTransport`)

Read `canvas-app-shared.md` first. Do not rename, move or delete any control. Only the edits below.

## Current State

Header `conAttHeader` (Ink, padding 16) -> `lblAttTitle`, `lblAttIdentity`, `conAttNav` (Attendance current /
Students / Absences). Month grid: `galAttRows` -> `galAttCells` -> `btnAttCell` (text "1"/"0"); Day view `galAttDayList`
-> `lblAttDayStatus`, `btnAttDayClear` (Undo). Engines `btnAttLoadEngine`, `btnAttSaveEngine`, `btnAttBulkEngine`
build/patch `colMonthAtt` records `{AttId, StudentId, DayNum, AttDate, Present, IsDeleted, Letter, ClassText, IepText,
Notes, RecordKey, ModifiedOn, SourceReportId, ReasonName}`.

## Changes

1. Add `LeftEarly` and `LeftEarlyAt` to every `colMonthAtt` record (7 places).
2. Cell marker `1*`, status word with the time, detail facts, legend.
3. Left-early days are office-owned: not editable/actionable on the teacher grid; save-engine guard blocks undo.
4. Nav button Transportation (+ wrap on phone).

## Properties to Update

### 1. colMonthAtt fields (7 record literals)

In each record literal below, append `, LeftEarly: X.'Left Early' = true, LeftEarlyAt: X.'Left Early At'` right
after the existing `ReasonName: Coalesce(X.'Absence Reason'.Name, "")` field, where `X` is the record name used in
that literal:

| # | Control.Property | Literal | X |
| - | ---------------- | ------- | - |
| 1 | btnAttLoadEngine.OnSelect | `ClearCollect(colMonthAtt, ForAll(Filter(Attendance, ...) As r, {...}))` | `r` |
| 2 | btnAttDetailSave.OnSelect | conflict branch `Collect(colMonthAtt, {AttId: server.Attendance, ...})` | `server` |
| 3 | btnAttDetailSave.OnSelect | success branch `Collect(colMonthAtt, {AttId: written.Attendance, ...})` | `written` |
| 4 | btnAttSaveEngine.OnSelect | conflict branch `Collect(colMonthAtt, {AttId: server.Attendance, ...})` | `server` |
| 5 | btnAttSaveEngine.OnSelect | success branch `Collect(colMonthAtt, {AttId: written.Attendance, ...})` | `written` |
| 6 | btnAttBulkEngine.OnSelect | conflict branch (server) | `server` |
| 7 | btnAttBulkEngine.OnSelect | success branch (written) | `written` |

Example (#1): `..., ReasonName: Coalesce(r.'Absence Reason'.Name, ""), LeftEarly: r.'Left Early' = true, LeftEarlyAt: r.'Left Early At'}`

### 2. galAttCells.Items and galAttDayList.Items (same edit in both)

In the inner record:
- add fields `LeftEarly: !IsBlank(a) && a.LeftEarly,` and `LeftEarlyAt: a.LeftEarlyAt,` after `Letter: ...,`
- `Editable:` becomes `varCanEditMonth && c.State = "Open" && (IsBlank(a) || (a.Letter = "P" && !a.LeftEarly)),`
- `Actionable:` becomes `If(varDetailsMode, !IsBlank(a), varCanEditMonth && c.State = "Open" && (IsBlank(a) || (a.Letter = "P" && !a.LeftEarly))),`
- in `StatusWord`, replace `If(a.Letter = "P", "Present", ` with
  `If(a.Letter = "P", If(a.LeftEarly, "Present – left early " & Text(a.LeftEarlyAt, "h:mm AM/PM") & " (office)", "Present"), `

### 3. btnAttCell.Text

Replace the inner `If(ThisItem.Letter = "P", "1", "0")` (inside the `HasRecord` branch) with
`If(ThisItem.Letter = "P", If(ThisItem.LeftEarly, "1*", "1"), "0")`. Everything else (Fill, Tooltip, OnSelect) unchanged:
Tooltip already shows StatusWord (with the time); the cell is disabled for teachers because Actionable is false.

### 4. lblAttDetailFacts.Text

Replace `If(a.Letter = "P", "Status Present (1)", ` with
`If(a.Letter = "P", "Status Present (1)" & If(a.LeftEarly, " · left early " & Text(a.LeftEarlyAt, "h:mm AM/PM") & " (office)", ""), `

### 5. lblAttLegend.Text (replace whole value, keep the `|-` block)

```
="1 present (tap a blank cell on your own grid; tap a 1 to undo) · 1* left early (office) · 0 absent: uncoloured = not classified, green = excused, red = unexcused · grey = no school · – not enrolled · dashed = future · ! failed, tap to retry · Details mode shows notes and the absence source"
```
(Shorter than the current text by ~4 characters, so existing heights 104 / 44 / 24 still fit.)

### 6. btnAttSaveEngine.OnSelect - undo guard

In the first `If(` condition, append inside the big OR (after the existing
`(req.Target = "clear" && (IsBlank(local) || local.IsDeleted || !local.Present))` term):
`|| (req.Target = "clear" && !IsBlank(local) && local.LeftEarly)`.
In the Blocked message's inner `If(`, insert a branch right after the `!varCanEditMonth, "view only — ..."` branch:
`req.Target = "clear" && !IsBlank(local) && local.LeftEarly, "left early was recorded by the office and can't be undone here",`

### 7. Nav

| Control | Property | Value |
| --- | --- | --- |
| conAttHeader | Height | `=If(conAttRoot.Width < 640, 92, 76) + If(CanManageStudents, If(conAttRoot.Width < 640, 100, 48), 0)` |
| conAttNav | Height | `=If(conAttRoot.Width < 640, 96, 44)` |
| conAttNav | LayoutWrap (new) | `=true` |

## Controls to Add

`btnAttNavTransport` (ModernButton) - last child of `conAttNav`: AccessibleLabel `="Go to Transportation"`,
AlignInContainer `=AlignInContainer.Center`, Appearance `=ButtonAppearance.Secondary`, Color `=ColorInk`, Height `=44`,
Layout `=ButtonLayout.TextOnly`, LayoutMinHeight `=0`, LayoutMinWidth `=0`, OnSelect `=Navigate(TransportScreen)`,
Size `=14`, Text `="Transportation"`, Visible `=CanClassify`, Width `=140`.

## Controls to Remove

None.

## Layout and Visual Impact

- Nav: 110+8+110+8+110+8+140 = 494 <= 992 (1024 - 32); two rows (96) below ~526 px.
- Cell width at 1366 ≈ (1334 - 236) / 31 = 35 px; "1*" at Size 14 Bold ≈ 16 px fits (the existing "1" + check
  mark already does).
- No colour change; the marker is the asterisk plus the tooltip / Day-view status text.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| att-cell-left-early | grid cell / Day view row | 1* + left-early time | colMonthAtt.LeftEarly, LeftEarlyAt | btnAttCell.Text / Tooltip; lblAttDayStatus | edits 2-3 | every present cell with Left Early = Yes |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-GRID-LOAD | staff ready | OnVisible / Reload -> btnAttLoadEngine | Attendance.Attendance | colMonthAtt + LeftEarly/At | N/A | N/A | btnAttCell "1*" |
| A-GRID-UNDO-BLOCK | Letter P and LeftEarly | cell tap / Day Undo (both disabled); engine guard | colMonthAtt | no write | N/A | Blocked `varLastAction.Message` "Not saved · <student> · <date> · left early was recorded by the office and can't be undone here" | lblAttReceipt |
| A-NAV-TRANSPORT | CanClassify | btnAttNavTransport.OnSelect | N/A | TransportScreen | N/A | N/A | TransportScreen header |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-GRID-MARKER | Jane Mon 10/5 Present, Left Early 1:30 PM (office) | Teacher Smith opens Oct 2026 | cell "1*"; tooltip "Doe, Jane – Mon Oct 5 – Present – left early 1:30 PM (office)"; legend has "1* left early (office)"; Day view status same; Details facts "Status Present (1) · left early 1:30 PM (office)" | btnAttCell, lblAttLegend, lblAttDayStatus, lblAttDetailFacts | plain 1 still "1" |
| S-GRID-UNDO-BLOCK | same | tap the 1* cell; Day view | cell disabled; Undo disabled | DisplayMode | engine guard returns Blocked text if ever reached |
| S-GRID-UNDO-REGRESSION | Ida 10/5 plain 1 | tap -> Confirm undo | soft delete as before | lblAttReceipt "Undone · ..." | N/A |
| S-GRID-ABSENCE-VISIBLE | office added Jane 9/4 Excused | open Sep 2026 | 0 green | btnAttCell Fill | N/A |
| S-NAV-TRANSPORT | office user | Transportation | TransportScreen opens | header | teacher: nav row hidden (existing) |

## Relevant Data Source Schemas

Attendance: 'Left Early' (Yes/No -> Boolean), 'Left Early At' (DateTime) - new columns, already visible in the session.

## Changed or Added Control Definitions

- ModernButton (`Control: ModernButton`): AccessibleLabel, AlignInContainer [AlignInContainer], Appearance
  [ButtonAppearance], Color, Height, Layout [ButtonLayout], LayoutMinHeight, LayoutMinWidth, OnSelect, Size, Text,
  Visible, Width. Literals: `ButtonAppearance.Secondary`, `ButtonLayout.TextOnly`, `AlignInContainer.Center`.
- GroupContainer: `LayoutWrap` (Boolean) is a valid AutoLayout input (new on conAttNav).
