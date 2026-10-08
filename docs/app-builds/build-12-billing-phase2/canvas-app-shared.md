# Canvas App Shared Plan - AACA Attendance (build 12 edit, Phase 2 step C: Absence Notices)

Screens touched: AbsencesScreen only (prefix `Abs`; new names `AbsNt...`). App.pa.yaml changes are made by the
orchestrator (section at the end). Every builder reads this file plus its own brief.

## Aesthetic Direction (unchanged NEXUS palette - App.Formulas named colours; never write a new RGBA)

- Page `ColorPaper`; panels `ColorWhite`; rules/borders `ColorRule`
- Text primary `ColorInk`; secondary/labels `ColorMuted`; on-navy text `ColorWhite` / `ColorInkSoft`
- Accent / primary action `ColorTeal`; Excused `ColorExcused`; Unexcused / destructive `ColorUnexcused`
- Status surfaces (always `ColorInk` text): `ColorInfoBg` (success, selected rows), `ColorWarnBg` (warning,
  dismissed), `ColorErrorBg` (failed/blocked)

## Visual Contract

- Type roles (ModernText `Size`/`FontWeight`): panel heading 18-20 Bold ink; section heading 16 Semibold ink; row
  identity 14 Semibold ink; body 13 ink; field label 12 Semibold `ColorMuted`; caption/meta 12 ink.
- Every NEW ModernText: all four `Padding*` `=0`, `AccessibleLabel`, `AlignInContainer`, `LayoutMinWidth: =0`,
  `LayoutMinHeight: =0`, explicit `Height`, `FillPortions: =0` (vertical parents); single-line labels `Wrap: =false`;
  multi-line text `VerticalAlign: =VerticalAlign.Top`.
- Field label + input pairs: label Height 18 directly above an input of Height 36 (radio: 32 per option), both
  children of the same form container and gated by the same `Visible` predicate.
- Actions: ModernButton Height 44, `Layout: =ButtonLayout.TextOnly`, Size 14. Primary `BasePaletteColor: =ColorTeal`
  + `Color: =ColorWhite`; destructive `BasePaletteColor: =ColorUnexcused` + `Color: =ColorWhite`; secondary
  `Appearance: =ButtonAppearance.Secondary` + `Color: =ColorInk`; disabled via `DisplayMode.Disabled`.
- No symbol glyphs (arrows, ellipsis character, check marks) in NEW text: use plain words, "-", "·" and "...".
  ("·" is already used across the app and is allowed.)

## Layout Strategy

- Responsive, desktop-first 1366x768, usable at 1024 and on a 375 phone. The screen keeps its single scroll root
  `conAbsRoot` (sole top-level child, `Width: =Parent.Width`, `Height: =Parent.Height`, vertical,
  `LayoutOverflowY: =LayoutOverflow.Scroll`) - unchanged.
- Breakpoints read `conAbsRoot.Width` directly: phone `< 640`, tablet `< 1024`, desktop `>= 1024`. No layout
  variables, nothing set in `OnVisible`.
- Two-panel bodies (list + right-hand detail): horizontal at `>= 1024`, stacked below; on `< 1024` the list hides
  while a record/panel is open (existing pattern, unchanged).
- Detail column inner width: classify `conAbsDecideV` 307 px at 1024 (420 at 1366); mapping `conAbsMeDetail`
  476 px at 1024 (643 at 1366); phone about 311 px.
- Height formulas use literal numbers only (never bare `PaddingTop`/`LayoutGap` names).
- **HARD RULES:** never rename, re-parent or delete an existing control; `conAbsHdrTabs` and its two buttons are not
  touched at all. Edit properties in place; insert NEW controls only where the brief says (parent + previous
  sibling). Nothing is deleted in this build.

## Named State

App formulas used (existing, unchanged): `CurrentUserRow` (Users row), `CurrentStaff`, `CanClassify`,
`StudentCampusLock` (office campus GUID or `ZeroGuid`), `ZeroGuid`, `FirstSchoolYear`, palette `Color*`.

Existing AbsencesScreen state reused (types unchanged): `varAbsView`, `varAbsCampusId`, `varAbsSaving`,
`varAbsLoading`, `varAbsSelId`, `varAbsAddMode`, `varAbsAddClass`, `varAbsAddReasonId`, `varAbsAddErr`,
`varAbsReceipt` `{Kind, Title}`, `colAbsReceiptLines` `{Label, Value}`, `colAbsLog` (12 fields, every Collect
supplies all 12), `varAbsMeLoading`, `varAbsMeLoaded`, `varAbsMeSaving`, `varAbsMeLoadError`, `varAbsMeErr`,
`varAbsMeCampusId`, `varAbsMeMode` ("" | "map" | "dates" | "dismiss"), `varAbsMeReceipt` `{Kind, Title, Body}`.

NEW App.OnStart seeds (orchestrator adds them before the builder):

| Name | Type | Meaning |
| --- | --- | --- |
| `varAbsNtSelId` | GUID, nullable (starts Blank) | Absence Notice open in the Mapping Errors detail panel. REPLACES every screen use of the numeric `varAbsMeSelId` (that variable stays in OnStart, unused) |
| `varAbsNtAllStu` | Boolean | Map student: show every student enrolled at the notice's campus instead of only typed-last-name hits |
| `varAbsNtHow` | Text | Add absence: "" \| "Parent notified us" \| "No notice" |
| `varAbsNtOpenAt` | DateTime | moment Add absence was opened; default for the "time the parent told us" input |
| `varAbsNtErr` | Text | last Absence Notice create error in Add absence |

Collections whose schema CHANGES (only AbsencesScreen reads/writes them; App.OnStart does not seed them):

- `colAbsMe` (Mapping Errors list) becomes one row per Absence Notice:
  `{Kind ("A" could not match | "B" could not process), NoticeId (GUID), Ref, FirstName, LastName, TypedCampus,
  CampusId (GUID, ZeroGuid if none), CampusName, StudentId (GUID, ZeroGuid if none), StudentName, FirstDay (Date),
  ReturnDate (Date), ReasonText, ParentName, Relationship, NoticeAt (DateTime), MatchText, MatchDetail, ErrorDetail,
  Created (DateTime), Status (Text, always "")}`.
  The tab label `"Mapping Errors (" & CountRows(colAbsMe) & ")"` in the untouched `conAbsHdrTabs` therefore counts
  notices with no change to the tab.
- `colAbsMeStudents` (Map student picker) becomes one row per enrollment: `{StudentId, DisplayName, StudentKey,
  StatusText, CampusId, StartDate, EndDate, Label}`.
- `colAbsList` and `colAbsCf` (Classify) GAIN `NtRef` (Text), `NtParent` (Text), `NtRel` (Text), `NtReason` (Text),
  `NtAt` (DateTime) read through `Attendance.'Absence Notice'` in the existing load engine.
- `colAbsMeSrc`, `colAbsMeErrDec`, `colAbsMeDecIds` (SharePoint era) are no longer filled; nothing reads them after
  this build.

### Field semantics (one meaning everywhere)

- Absence Notice `'First Day Absent'` = first school day absent; `'Last Day Absent'` = last day absent;
  `'Return Date'` = day the child is back (exclusive) = Last Day Absent + 1 calendar day.
- `'Notice At'` = official notice time for billing (UTC in Dataverse, shown in the user's local time with
  `Text(x, "mm/dd/yyyy h:mm AM/PM")`). Blank = no notice. Attendance `'Notice Received On'` copies it.
- Mapping Errors rows = notices with `'Status (aaca_status)' = New` AND (`'Error Detail'` not blank -> Kind "B",
  else `'Match Status'` Unmatched or Ambiguous -> Kind "A"). Every other New notice (Matched / Mapped by office
  without error) is waiting for the processing flow and is not listed.

## Control Naming

Standard abbreviations (`con`, `lbl`, `btn`, `rdo`, `dp`, `txt`, `chk`, `cbo`, `gal`) + screen namespace `Abs`.
NEW controls in this build: `chkAbsNtAllStu`, `lblAbsNtHowV`, `rdoAbsNtHowV`, `lblAbsNtDateV`, `dpAbsNtDateV`,
`lblAbsNtTimeV`, `txtAbsNtTimeV`. Names are app-unique (no other screen uses `AbsNt`).

## Cross-Screen Contracts

- Teams "ABSENCE ALERT" card "Open in app" opens the app with `screen=absences`; `App.StartScreen` routes office and
  admin users to AbsencesScreen (see App changes). AbsencesScreen `OnVisible` already loads both views.
- Screen1 reloads attendance on visit, so days created by Add absence (and by the processing flow after Map student
  / Fix dates) appear on the grid at the next visit. No other screen changes.

## YAML Conventions

- Every property value starts with `=`; multi-line formulas are `|-` blocks with `=` on the first content line.
- Any value containing `: ` (caption text such as `"Notice: "`, record literals `{Value: x}`, `{Kind: "", ...}`) or
  ` #` MUST be a `|-` block. Unquoted ` #` starts a YAML comment and silently truncates the formula.
- Dataverse predicates: wrap scalars with `With()` (`With({q: id}, LookUp('Absence Notices', ThisRecord.'Absence
  Notice' = q))`); disambiguate primary keys with `ThisRecord.`; choice filters compare with `=` (use `= Blank()`,
  never `IsBlank`, for a blank choice in a delegated filter).
- `IfError(A, B)`: both branches the same type. Verified record pattern:
  `IfError(Patch(...), Set(varX, FirstError.Message); Blank())`. Table-returning success branches end with `; true`.
- Yes/No columns are Booleans (`Present = false`, `'Is Deleted': false`).
- Choice literals (exact):
  - `'Status (Absence Notices)'.New` / `.Accepted` / `.Dismissed` / `.Cancelled` (column `'Status (aaca_status)'`)
  - `'Match Status (Absence Notices)'.Matched` / `.Unmatched` / `.Ambiguous` / `.'Mapped by office'` (column
    `'Match Status'`)
  - `'Source (Absence Notices)'.Office` (column `Source`)
  - `'Source (Attendance)'.Office`, `'Absence Classification (Attendance)'.Excused` / `.Unexcused`
  - `'Action (Audit Events)'.Create` / `.Update`
- Audit Events rows: `Summary` (Left(..., 100)), `Action`, `Entity` (logical name: `"aaca_absencenotice"` or
  `"aaca_attendance"`), `'Entity ID'` (`Text(<guid>)`), `Before` / `After` (`JSON({...})` or ""), `Reason`
  (Left(..., 500)). Every write is wrapped in IfError and the receipt reports "written" / "NOT written".
- `Select(engine)` calls queue after the current formula finishes.

## App.pa.yaml changes (orchestrator)

Apply BEFORE the builder runs (the screen binds to the new variables). No screen is referenced by the OnStart edit.

1. `App.OnStart`: the current last line is `Clear(colHelpMsgs)`. Change it to `Clear(colHelpMsgs);` and append
   exactly these lines (6-space indent, inside the existing `|-` block). The new last line keeps NO trailing
   semicolon:

```
      Set(varAbsNtSelId, ZeroGuid);
      Set(varAbsNtSelId, Blank());
      Set(varAbsNtAllStu, false);
      Set(varAbsNtHow, "");
      Set(varAbsNtOpenAt, Now());
      Set(varAbsNtErr, "")
```

2. `App.StartScreen` (replace `=Screen1`; AbsencesScreen already exists):

```
    StartScreen: =If(Lower(Coalesce(Param("screen"), "")) = "absences" && CanClassify, AbsencesScreen, Screen1)
```

   If compile rejects a named formula in StartScreen, use the supported fallback
   `=If(Lower(Coalesce(Param("screen"), "")) = "absences", AbsencesScreen, Screen1)` - AbsencesScreen already shows
   its "not available for your role" panel (`conAbsDenied`, Back to Attendance) to teachers / read-only users.
   Report which form was kept.

Nothing else in App.pa.yaml changes (Formulas untouched).
