# Screen Plan: Attendance (Screen1)

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\Screen1.pa.yaml`
- YAML key: Screen1
- Control name prefix: Att (no new controls on this screen)

## Current State

`conAttRoot` (scroll root) > header (`conAttNav` visible when CanManageStudents), `conAttNotSetUp`, `conAttToolbar`
(month bar, view bar, scope row `ddAttCampus`/`ddAttTeacher`), `conAttNotice` (`lblAttNotice`), `spnAttLoading`,
`conAttReceipt` (`lblAttReceipt`), `conAttConfirm` (clear confirm), `conAttDetail` (notes), `conAttMonthView`
(legend, `galAttRows` > `galAttCells` > `btnAttCell`), `conAttDayView` (`galAttDayList` rows with
`btnAttDayPresent`/`btnAttDayAbsent`/`btnAttDayClear`), hidden engines `btnAttSaveEngine`, `btnAttBulkEngine`,
`btnAttLoadEngine`. `colMonthAtt` rows: `{AttId, StudentId, DayNum, AttDate, Present, IsDeleted, Letter, ClassText,
IepText, Notes, RecordKey, ModifiedOn}`. Letters: P / E / U / A.

**Do not move any control. Do not rename controls. Edit properties in place only.**

## Changes

1. **Grid edit gate (teacher, own grid only).** In `btnAttLoadEngine.OnSelect` replace
   `Set(varCanEditMonth, CanEditRole && IsBlank(varMonthLock) && varLoadError = "");` with
   `Set(varCanEditMonth, IsTeacherRole && !IsBlank(varTeacher) && varTeacher.Staff = CurrentStaff.Staff && IsBlank(varMonthLock) && varLoadError = "");`
2. **colMonthAtt gets two new fields** `SourceReportId` (Number) and `ReasonName` (Text). Add them to ALL SEVEN
   record literals that build colMonthAtt rows (shapes must stay identical):
   - `btnAttLoadEngine` ForAll over `r`: `SourceReportId: r.'Source Report ID', ReasonName: Coalesce(r.'Absence Reason'.Name, "")`
   - `btnAttSaveEngine` conflict branch (`server`) and success branch (`written`)
   - `btnAttBulkEngine` conflict branch (`server`) and success branch (`written`)
   - `btnAttDetailSave` conflict branch (`server`) and success branch (`written`)
   using `SourceReportId: <x>.'Source Report ID', ReasonName: Coalesce(<x>.'Absence Reason'.Name, "")` with `<x>` =
   `server` or `written` respectively.
3. **Cell cycle without "A"** (`btnAttCell.OnSelect`, block scalar):
```
=If(
    varDetailsMode,
    If(ThisItem.HasRecord, Set(varDetailKey, {StudentId: ThisItem.StudentId, DayNum: ThisItem.DayNum}); Set(varConfirmOpen, false); Reset(txtAttDetailNotes); Set(varDetailOpen, true)),
    !ThisItem.Editable || ThisItem.SaveState = "saving",
    false,
    ThisItem.SaveState = "failed" && ThisItem.Target in ["P", "clear"],
    Set(varSaveReq, {StudentId: ThisItem.StudentId, DayNum: ThisItem.DayNum, Target: ThisItem.Target}); Select(btnAttSaveEngine),
    !ThisItem.HasRecord,
    Set(varSaveReq, {StudentId: ThisItem.StudentId, DayNum: ThisItem.DayNum, Target: "P"}); Select(btnAttSaveEngine),
    ThisItem.Letter = "P",
    Set(varClearKey, {StudentId: ThisItem.StudentId, DayNum: ThisItem.DayNum}); Set(varDetailOpen, false); Set(varConfirmOpen, true),
    false
)
```
4. **Items records of `galAttCells` and `galAttDayList`** (both identical `ForAll` blocks) — replace three fields:
   - `Editable: varCanEditMonth && c.State = "Open" && (IsBlank(a) || a.Letter = "P"),`
   - `Actionable: If(varDetailsMode, !IsBlank(a), varCanEditMonth && c.State = "Open" && (IsBlank(a) || a.Letter = "P")),`
   - the `!IsBlank(a), Switch(a.Letter, …)` arm of `StatusWord` becomes
     `!IsBlank(a), If(a.Letter = "P", "Present", "Absent – " & Switch(a.Letter, "E", "Excused", "U", "Unexcused", "not classified") & If(a.ReasonName <> "", ": " & a.ReasonName, "") & If(IsBlank(a.SourceReportId), "", " (parent report #" & a.SourceReportId & ")")),`
   (Items are already `|-` blocks, so ": " and " #" are safe.) Tooltip formula of `btnAttCell` is unchanged — it
   already appends `ThisItem.StatusWord`.
5. **Save engine guards** (`btnAttSaveEngine.OnSelect`). Replace the first `If(` condition
   `IsBlank(cell) || cell.State <> "Open" || !varCanEditMonth || IsBlank(req.Target) || (req.Target = "clear" && (IsBlank(local) || local.IsDeleted))`
   with
   `IsBlank(cell) || cell.State <> "Open" || !varCanEditMonth || !(req.Target in ["P", "clear"]) || (req.Target = "clear" && (IsBlank(local) || local.IsDeleted || !local.Present)) || (req.Target = "P" && !IsBlank(local) && !local.IsDeleted && !local.Present)`
   and its Blocked message reason
   `If(!varCanEditMonth, "month locked or view-only role", Coalesce(cell.Reason, "cell not editable"))` with
   `If(!varCanEditMonth, "view only — teachers mark only their own grid, and not in a locked month", !IsBlank(local) && !local.IsDeleted && !local.Present, "absences (0) come from approved parent reports and can't be changed here", Coalesce(cell.Reason, "cell not editable"))`.
   In both Failed messages change `Switch(req.Target, "P", "Present", "A", "Absent", "Clear")` to
   `Switch(req.Target, "P", "Present", "Undo")`. In the success message change the literal `"Cleared · "` to
   `"Undone · "` (Kind stays "Cleared"). Everything else in the engine is unchanged (it already writes the full
   snapshot and the Soft Delete audit).
6. **View-only banner** — `lblAttNotice.Text`:
```
=If(
    varLoadError <> "", "Could not load attendance — " & varLoadError & ". Use Reload to try again.",
    !(IsTeacherRole && !IsBlank(varTeacher) && varTeacher.Staff = CurrentStaff.Staff),
    "View only — " & If(IsTeacherRole, "this is " & varTeacher.Name & "'s grid. You can mark attendance only on your own grid.", IsOfficeRole, "teachers mark attendance. Absences (0) come from parent reports you approve on the Absences screen.", "attendance is marked by each teacher on their own grid."),
    !IsBlank(varMonthLock), Text(varMonthStart, "mmmm yyyy") & " is locked for " & varCampus.Name & " — " & Coalesce(varMonthLock.Reason, "no reason given") & ". Cells are read-only.",
    ""
)
```
   (`|-` block; contains `'s` and no ": ".) `conAttNotice` Visible/Height unchanged.
7. **Teacher picker for teachers** — `ddAttTeacher.DisplayMode`:
   `=If((CanPickTeacher || IsTeacherRole) && !varLoading, DisplayMode.Edit, DisplayMode.Disabled)`. Items unchanged
   (teachers at `varCampus`). `ddAttCampus` unchanged (disabled for teachers and office).
8. **Pin a teacher's campus** — in `Screen1.OnVisible`, insert immediately after `Set(varLoading, false);`:
   `If(IsTeacherRole && !IsBlank(CurrentStaff.Campus), Set(varCampus, CurrentStaff.Campus));`
   (the existing teacher line `IsTeacherRole, Set(varTeacher, CurrentStaff)` stays, so each visit opens the own grid).
9. **Day view** (`galAttDayList` row):
   - `btnAttDayPresent.DisplayMode`: `=If(ThisItem.Editable && ThisItem.SaveState <> "saving" && (!ThisItem.HasRecord || ThisItem.SaveState = "failed"), DisplayMode.Edit, DisplayMode.Disabled)`
   - `btnAttDayAbsent`: `Visible: =false`, `DisplayMode: =DisplayMode.Disabled`, `OnSelect: =false` (keep the control; do not delete or move it)
   - `btnAttDayClear`: `Text: ="Undo"`, `AccessibleLabel: ="Undo present for " & ThisItem.StudentName`, `Visible: =ThisItem.HasRecord && ThisItem.Letter = "P"` (DisplayMode/OnSelect unchanged — it opens the confirm)
   - `lblAttDayStatus`: `Height: =36`, `Wrap: =true`, `VerticalAlign: =VerticalAlign.Top`, Text failed arm
     `"Save failed – press the button again to retry"` (rest unchanged)
   - `galAttDayList.TemplateSize: =132`; `galAttDayList.Height: =Min(620, Max(140, 140 * CountRows(Filter(colMonthCells, DayNum = Day(varViewDate) && (State = "Open" || State = "Future")))))`
   - `conAttDayView.Height`: same formula as today but with `Min(620, Max(140, 140 * …))` replacing `Min(620, Max(124, 124 * …))`.
10. **Undo confirm wording**:
    - `lblAttConfirmText.Text` (`|-`): `=With({a: LookUp(colMonthAtt, StudentId = varClearKey.StudentId && DayNum = varClearKey.DayNum && !IsDeleted), c: LookUp(colMonthCells, StudentId = varClearKey.StudentId && DayNum = varClearKey.DayNum)}, "Undo the 1 (present) for " & c.StudentName & " on " & Text(c.CellDate, "dddd mmmm d") & "? The row is kept and marked deleted (audit logged); you can mark the day again later.")`
    - `btnAttConfirmClear`: `Text: ="Confirm undo"`, `AccessibleLabel: ="Confirm undo"`
    - `btnAttConfirmCancel.OnSelect`: same formula with message prefix `"Undo cancelled · "` instead of `"Clear cancelled · "`.
11. **Details panel for 0 cells**:
    - `lblAttDetailFacts.Text` (`|-`):
```
=With({a: LookUp(colMonthAtt, StudentId = varDetailKey.StudentId && DayNum = varDetailKey.DayNum && !IsDeleted)}, If(IsBlank(a), "No attendance record for this cell.", If(a.Letter = "P", "Status Present (1)", "Status Absent (0) – " & a.ClassText & If(a.ReasonName <> "", ": " & a.ReasonName, "") & If(IsBlank(a.SourceReportId), " · no parent report linked", " · from parent report #" & a.SourceReportId) & " · locked") & "  ·  IEP ratio " & Coalesce(a.IepText, "—") & "  ·  Key " & a.RecordKey))
```
    - `txtAttDetailNotes.DisplayMode`: `=If(varCanEditMonth && LookUp(colMonthAtt, StudentId = varDetailKey.StudentId && DayNum = varDetailKey.DayNum && !IsDeleted).Letter = "P", DisplayMode.Edit, DisplayMode.View)`
    - `btnAttDetailSave.DisplayMode`: `=If(varCanEditMonth && LookUp(colMonthAtt, StudentId = varDetailKey.StudentId && DayNum = varDetailKey.DayNum && !IsDeleted).Letter = "P", DisplayMode.Edit, DisplayMode.Disabled)`
    - `btnAttDetailSave.OnSelect`: in the guard change `IsBlank(a) || !varCanEditMonth` to `IsBlank(a) || !varCanEditMonth || a.Letter <> "P"` and its message tail to `" · only a teacher's own 1s can take notes here"`.
12. **Legend** — `lblAttLegend.Text` (`|-`):
    `="1 present (tap a blank cell on your own grid; tap a 1 to undo) · 0 absent, from approved parent reports: uncoloured = not classified, green = excused, red = unexcused · grey = no school · – not enrolled · dashed = future · ! failed, tap to retry · Details mode shows notes and the absence source"`
    `lblAttLegend.Height`: `=If(conAttRoot.Width < 640, 104, conAttRoot.Width < 1340, 44, 24)`; in
    `conAttMonthView.Height` change the legend term `If(conAttRoot.Width < 640, 84, conAttRoot.Width < 1340, 44, 24)` to `If(conAttRoot.Width < 640, 104, conAttRoot.Width < 1340, 44, 24)`.
13. **Root containment** — `conAttRoot`: add `LayoutMinWidth: =0` and `LayoutMinHeight: =0` (keep everything else).

Unchanged: header/nav, month/view bars, `btnAttBulkEngine` logic (already gated by `varCanEditMonth` and skipping
any active row), `btnAttDayAll`/`btnAttDayAllPresent` (DisplayMode already uses `varCanEditMonth`).

## Layout and Visual Impact

- Breakpoint source: `conAttRoot.Width` (640 / 1024 / 1340 as today).
- Day row: 8+24+4+36+4+44+8 = 128 ≤ TemplateSize 132; gallery per-row pitch 132 + 8 = 140. Action row Present 100 + 8 + Undo 88 = 196 ≤ 390-32-16-24.
- Notice: longest text ≈ 125 chars at Size 13 (~6.5 px/char): desktop 1366-24 → 1 line in 44; tablet 1024 → 2 lines (34) + 8 ≤ 56; phone 342 px → 3 lines (51) + 8 ≤ 68.
- Legend ≈ 265 chars: phone 358 px ≈ 55 chars/line → 5 lines ≈ 85 ≤ 104; 1024–1339 ≈ 147 chars/line → 2 lines ≤ 44.
- Day status ≈ 70 chars at Size 12 wraps to 2 lines (34) ≤ 36.
- Visual contract: unchanged roles; confirm stays ColorErrorBg with ColorUnexcused confirm button.
- Record presentation: identity `lblAttRowName` / `lblAttDayName` = StudentName (unchanged).

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| att-zero-source | grid cell / day row / details | classification + reason + parent report # | colMonthAtt.ClassText/Letter, ReasonName, SourceReportId | `btnAttCell.Tooltip` (via StatusWord), `lblAttDayStatus`, `lblAttDetailFacts` | Changes 4 and 11 | Tooltip on hover; day status always visible; details when Details mode tap |

## Controls to Add

None.

## Controls to Remove

None (btnAttDayAbsent is hidden and neutralised, not deleted).

## Properties to Update

See Changes 1–13.

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| att-viewonly-banner | conAttNotice | `=StaffReady && lblAttNotice.Text <> ""` (unchanged) | Visible for error / role view-only / lock; hidden for a teacher on own unlocked grid |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-MARK-PRESENT | varCanEditMonth; State Open; no active row | `btnAttCell.OnSelect` / `btnAttDayPresent.OnSelect` -> `btnAttSaveEngine` Target "P" | Attendance Student+Service+Date; written.Attendance | Present=Yes, Is Deleted=No, snapshots | Record Key, Date, Student, Service, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio, Present, Is Deleted | "Saved/Restored · name · date · Status Present · IEP · Teacher · Term · Key" | `lblAttReceipt`; cell "1✓" teal border |
| A-UNDO-PRESENT | varCanEditMonth; Letter P | tap 1 / `btnAttDayClear` -> `btnAttConfirmClear.OnSelect`; cancel `btnAttConfirmCancel` | AttId | Is Deleted=Yes + Audit Soft Delete | Is Deleted, Audit row | "Undone · name · date · Is Deleted = Yes · Key · audit event written" | `lblAttReceipt`; cell blank |
| A-BULK-PRESENT | varCanEditMonth | `btnAttDayAll` / `btnAttDayAllPresent` | per student | unchanged | unchanged | "All present · …" | `lblAttReceipt` |
| A-VIEW-OTHER | Teacher | `ddAttTeacher.OnChange` | Staff.Staff | varTeacher set; varCanEditMonth false | N/A | N/A | `lblAttNotice`; cells disabled |
| A-ZERO-SOURCE | any role, 0 cell | Details mode + tap `btnAttCell` | colMonthAtt AttId | panel opens, read-only | N/A | N/A | `lblAttDetailFacts` |
| A-SHOW-ON-GRID (destination) | set by AbsencesScreen | Screen1.OnVisible -> btnAttLoadEngine | varLastAction.StudentId/DayNum | colMonthAtt reloaded | N/A | N/A | `lblAttReceipt` + teal-bordered 0 cell (existing BorderColor formula) |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| ddAttTeacher | lblAttTeacher `="Teacher"` (existing) | conAttTeacherField |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-MARK-PRESENT / A-UNDO-PRESENT | `written` -> varLastAction -> `lblAttReceipt` | Attendance; colMonthAtt row replaced from `written` | `btnAttCell` | StudentId + DayNum, written.Attendance | engine RemoveIf/Collect colMonthAtt | varLastAction teal border |
| A-APPROVE-* (observed) | AbsencesScreen receipt | Attendance | `btnAttCell` Text "0", Fill ColorExcused/ColorUnexcused, Tooltip | Source Report ID | Screen1.OnVisible -> btnAttLoadEngine | varLastAction set by `btnAbsApShowGrid` |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| A-MARK-PRESENT | Present, Is Deleted + snapshots | Changed | Target "P" | existing Patch | varLastAction.Message | cell "1" |
| A-MARK-PRESENT | classification / reason / Source Report ID | Preserved | server row | omitted | N/A | N/A |
| A-UNDO-PRESENT | Is Deleted | Changed | local P | `Patch(Attendance, server, {'Is Deleted': true})` | "Is Deleted = Yes" | cell blank |
| any | active 0 rows | Preserved | server row | engine guard blocks P/clear | Blocked message | cell still "0" |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-NAV-TEACHER | teacher A | open app | nav hidden | `conAttNav` | — |
| S-NAV-OFFICE | office O | open app | nav visible | `conAttNav` | — |
| S-MARK-1 | teacher A own grid, Jane 9/17 blank | tap cell | row Present=Yes | cell "1✓", `lblAttReceipt` "Saved · Doe, Jane · Thu Sep 17 · Status Present …" | future cell disabled |
| S-UNDO-1 | Jane 9/17 = 1 | tap -> Confirm undo | Is Deleted=Yes, audit | "Undone · … audit event written"; cell blank | tapping a 0 cell does nothing |
| S-UNDO-CANCEL | Jane 9/17 = 1 | tap -> Cancel | unchanged | "Undo cancelled · … record unchanged" | — |
| S-BULK-GATED | teacher A views B | — | All buttons disabled | `btnAttDayAll.DisplayMode` | own grid enabled |
| S-VIEW-OTHER-TEACHER | teacher A | pick Lee, Ben | read-only grid | "View only — this is Lee, Ben's grid…" | campus picker disabled |
| S-VIEW-OFFICE | office O | open Screen1 | read-only | "View only — teachers mark attendance…" | admin: same banner, campus picker enabled |
| S-ZERO-LOCKED | Jane 9/14 active 0 Excused, Illness, report 515 | tap cell; Details mode tap | no action; details read-only | "Absent – Excused: Illness (parent report #515)" | engine blocks P/clear on active 0 |
| S-SHOW-ON-GRID | AbsencesScreen approved #515 | Show on grid | grid teacher A Sep 2026 | 9/14 "0" green, teal border | — |

## Changed or Added Control Definitions

No new properties beyond these already-present ones; for reference (valid inputs used):

- GroupContainer (`Control: GroupContainer`, `Variant: AutoLayout`): LayoutMinWidth, LayoutMinHeight (child-of-AutoLayout / root inputs), Height, Width, LayoutOverflowY [`LayoutOverflow.Scroll`].
- ModernText (`Control: ModernText`): Text, Height, Wrap, VerticalAlign [Enum name: VerticalAlign → `=VerticalAlign.Top`], AccessibleLabel, Color, Size, Padding*.
- ModernButton (`Control: ModernButton`): Text, AccessibleLabel, DisplayMode [Enum DisplayMode → `=DisplayMode.Disabled`], Visible, OnSelect.
- Classic/Button (`Control: Classic/Button`): OnSelect, Tooltip, DisplayMode (no AccessibleLabel property).
- ModernDropdown (`Control: ModernDropdown`): DisplayMode.
- ModernTextInput (`Control: ModernTextInput`): DisplayMode [`=DisplayMode.View`].
- Gallery (`Control: Gallery`, `Variant: Vertical` / `Horizontal` as existing): Items, TemplateSize, Height.

## Relevant Data Source Schemas

Attendance: 'Source Report ID' (Number, new), 'Absence Reason' (lookup Absence Reasons; `.Name`), 'Absence
Classification', Present, 'Is Deleted', 'Modified On', 'Record Key', Notes. Staff: Staff (GUID), Name, 'App Role', Campus.
