# Canvas App Shared Plan - AACA Attendance (build 10 edit: Staff screen)

Screens touched: StaffScreen (NEW, prefix `Stf`), Screen1 (`Att`), StudentsScreen (`Stu`), AbsencesScreen (`Abs`),
TransportScreen (`Trn`). Every builder reads this file plus its own brief. App.pa.yaml and _EditorState.pa.yaml are
edited by the orchestrator only (section "App.pa.yaml changes (orchestrator)" at the end).

## Aesthetic Direction (unchanged from build 9)

"Classroom register": warm paper page, ink-navy header band, teal accent. All colours are App.Formulas named
constants - always use the name, never a new RGBA:

- Page `ColorPaper`; panels `ColorWhite`; rules/borders `ColorRule`
- Text primary `ColorInk`; secondary `ColorMuted`; on-ink text `ColorWhite` / `ColorInkSoft`
- Accent / primary action `ColorTeal`; destructive (Retire) `ColorUnexcused` with white text; "Ready" check text
  `ColorExcused`, blocking check text `ColorUnexcused`
- Status surfaces (always `ColorInk` text on them): `ColorInfoBg` (success, selected row), `ColorWarnBg` (partial
  result, skipped preview rows), `ColorErrorBg` (failed/blocked), `ColorNonSchool` (retired rows, `ColorMuted` text)

## Visual Contract

- Type roles (ModernText `Size`/`FontWeight`): app title 20 Bold white; panel heading 18 Bold ink; row identity 14
  Semibold ink; body 13 ink; field label 12 Semibold `ColorMuted`; caption/meta 12.
- Every NEW ModernText: all four Padding* `=0` (unless stated), `AccessibleLabel`, `AlignInContainer`,
  `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, explicit `Height`; single-line labels `Wrap: =false`; multi-line text
  `VerticalAlign: =VerticalAlign.Top`.
- Spacing: container gap 8 (form panel 4); panel padding 16; receipt padding 8 top/bottom, 12 sides; radius 6 on
  panels, 0 on header/strip containers.
- Panels: `Fill: =ColorWhite`, `BorderColor: =ColorRule`, `BorderThickness: =1`, `DropShadow: =DropShadow.None`,
  all four Radius* `=6`.
- Every NEW GroupContainer: `Variant: AutoLayout`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`,
  `DropShadow: =DropShadow.None`, explicit `LayoutDirection`, `LayoutAlignItems`, `FillPortions`, and `Height`.
- Actions (ModernButton, `Height: =44`, `Layout: =ButtonLayout.TextOnly`, `Size: =14`, `LayoutMinHeight: =0`,
  `LayoutMinWidth: =0`, explicit `Width`, `AlignInContainer: =AlignInContainer.Center` in rows):
  - Primary: `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite` (Appearance default Primary)
  - Destructive (Retire save): `BasePaletteColor: =ColorUnexcused`, `Color: =ColorWhite`
  - Secondary: `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk` (never light text on Secondary)
  - Disabled via `DisplayMode: =DisplayMode.Disabled`.
- No symbol glyphs (arrows, check marks, refresh marks) in any NEW text. Use plain words, "-" or "·".

## Layout Strategy

- Responsive, desktop-first (1366x768), usable at 1024 and on a 375 phone. Each screen has ONE scroll root (sole
  top-level child): `Width: =Parent.Width`, `Height: =Parent.Height`, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`,
  vertical, `LayoutOverflowY: =LayoutOverflow.Scroll`, `LayoutAlignItems: =LayoutAlignItems.Stretch`,
  `PaddingBottom: =16`, `LayoutGap: =8`. Every section and every hidden engine button lives under it.
- Breakpoints read the screen root's `Width` directly (`conStfRoot.Width`, `conAttRoot.Width`, `conStuRoot.Width`,
  `conAbsRoot.Width`, `conTrnRoot.Width`): phone `< 640`, narrow `< 1024`. Never store breakpoints in variables.
- Two-panel body (list + right-hand panel): horizontal at `>= 1024` (list `FillPortions` 2, panel 1), vertical below;
  on `< 1024` the list hides while a form mode is open (TransportScreen Students pattern).
- Galleries: one AutoLayout shell child sized `Parent.TemplateWidth - 16` x `Parent.TemplateHeight`; numeric
  `Height` from `Min(k, rows) * TemplateSize` (never `Self.TemplateHeight`); explicit `TemplateSize`;
  `TemplatePadding: =0`; `TabIndex: =0`; `Selectable: =false`.
- **Root-order rule:** anything that must render at the top (title, nav, campus picker) lives INSIDE the header
  container. The view/campus strip is a full-width `ColorPaper` strip and the header's LAST child.
- **HARD LESSON: never move (re-parent) or rename an existing control.** Studio renders moved controls as black boxes.
  Edit properties in place and add NEW controls with NEW names. Inserting a new sibling into an existing container is
  allowed. Delete nothing in this build.

## Named State

App formulas (existing, unchanged): `CurrentUserRow`, `CurrentStaff`, `StaffReady`, `IsTeacherRole`, `IsOfficeRole`,
`IsAdminRole`, `CanClassify`, `CanManageStudents` (= Office || Admin), `StudentCampusLock` (office campus GUID or
`ZeroGuid`), `ZeroGuid`, `RoleLabel`, palette `Color*`.

App formulas NEW (orchestrator adds them before builders):
- `StaffPending` (Boolean): signed-in user has no linked Staff row but an active Staff row carries their email.
- `StaffRoleOptions = ["Teacher", "Attendance Office", "Read-only", "System Admin"]` (single column `Value`).

App.OnStart NEW seeds (StaffScreen only; every name starts with `Stf`):

| Name | Type / shape | Meaning |
| --- | --- | --- |
| `varStfCampusId` | GUID | campus shown (office: locked to `StudentCampusLock`) |
| `varStfSelId` | GUID, nullable (starts Blank) | selected person (`Staff.Staff`) |
| `varStfMode` | Text: `""` \| `"add"` \| `"edit"` \| `"transfer"` \| `"retire"` \| `"reactivate"` | right-panel mode |
| `varStfShowRetired` | Boolean | "Show retired" toggle |
| `varStfLoading`, `varStfSaving` | Boolean | busy flags |
| `varStfLoadError` | Text | last load error |
| `varStfXferDate` | Date | effective date the preview was built for |
| `varStfReceipt` | `{Kind: Text, Title: Text}` (always both fields) | receipt banner |
| `colStfCampusOpts` | `{CampusId, CampusName}` | campus picker |
| `colStfAll` | `{StaffId, StaffName, Email, RoleText, CampusId, CampusName, StartDate, EndDate, IsActive, Linked, StudentsNow, SearchKey}` | Staff rows at the campus |
| `colStfEmails` | `{StaffId, StaffName, EmailL, UserEmailL}` | ALL Staff rows, lower-cased emails for duplicate checks |
| `colStfEnr` | `{EnrId, TeacherId}` | campus enrollments with End blank or >= Today() |
| `colStfLocks` | `{MonthStart: Date}` | locked months at the campus |
| `colStfXferEnr` | `{EnrId, StudentId, StudentName, StudentNumber, StudentStatus, ServiceId, RatioText, StartDate, EndDate, YearEnd}` | selected teacher's enrollments |
| `colStfPlan` / `colStfXferWork` | `{EnrId, StudentId, StudentName, StudentNumber, RatioText, StartDate, Action, Reason}` | preview / work queue; Action `"move"` \| `"reassign"` \| `"skip"` |
| `colStfLog` | `{EnrId, StudentName, StudentNumber, Action, Outcome, Detail, NewEnrId, AuditOk}` | bulk-transfer log; Outcome `"moved"` \| `"reassigned"` \| `"failed"` \| `"skipped"`; every Collect supplies all 8 fields |
| `colStfReceiptLines` | `{Label, Value}` | receipt lines |

### Data semantics (one definition, used everywhere)

- **Active** (Staff Yes/No) is a Boolean. In Dataverse filters use `Active = true` (delegable; Yes/No columns are never
  blank). In memory use `s.Active <> false` (same as `StaffReady`). Writes: `Active: true` / `Active: false`.
- **Students now** for a staff member = number of Enrollments rows with `Teacher = that person` and
  (`'End Date'` blank or `'End Date' >= Today()`) - covers current and future (planned) enrollments. The same
  definition blocks Retire and enables Transfer class.
- **Open on the effective date d** = `'Start Date' <= d && (IsBlank('End Date') || 'End Date' >= d)`.
- **Account** = "Linked" when `Staff.User` is set, else "Waiting for account".
- **Email** is stored as `Lower(Trim(input))`; valid when it has no space, exactly one "@", ends with
  `@autismacademy.org` and is longer than 18 characters; unique against every other Staff row's `Email` and every
  other Staff row's linked user `'Primary Email'` (case-insensitive).
- Office (`IsOfficeRole`) may add Teachers only, and may edit / retire / reactivate only rows whose App Role is
  Teacher; campus and role are fixed for office. Admin (`IsAdminRole`) may do everything at any campus.

## Control Naming

Standard abbreviations (`con`, `lbl`, `btn`, `dd`, `txt`, `dp`, `rdo`, `tgl` toggle, `gal`) + screen namespace.
Names are app-unique. StaffScreen: `Stf` (`conStfRoot`, `galStfList`, `btnStfXferEngine`, ...).
New nav buttons on the other screens: `btnAttNavStaff`, `btnStuNavStaff`, `btnAbsNavStaff`, `btnTrnNavStaff`.

## Cross-Screen Contracts

### Header nav pattern (each screen instantiates it under its own prefix; values are fixed)

Every button: ModernButton, `Height: =44`, `Layout: =ButtonLayout.TextOnly`, `Size: =14`, `LayoutMinHeight: =0`,
`LayoutMinWidth: =0`, `AlignInContainer: =AlignInContainer.Center`.

| # | Text | Width | OnSelect | Visible | Non-current | Current screen |
| - | ---- | ----- | -------- | ------- | ----------- | -------------- |
| 1 | `"Attendance"` | 110 | `=Navigate(Screen1)` | always | `Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk`, AccessibleLabel `"Go to Attendance"` | `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite`, AccessibleLabel `"Attendance (current screen)"` |
| 2 | `"Students"` | 110 | `=Navigate(StudentsScreen)` | always | same, `"Go to Students"` | same, `"Students (current screen)"` |
| 3 | `"Absences"` | 110 | `=Navigate(AbsencesScreen)` | always | same, `"Go to Absences"` | same, `"Absences (current screen)"` |
| 4 | `"Transportation"` | 140 | `=Navigate(TransportScreen)` | `=CanClassify` | same, `"Go to Transportation"` | same, `"Transportation (current screen)"` |
| 5 NEW | `"Staff"` | 80 | `=Navigate(StaffScreen)` | `=CanManageStudents` | same, `"Go to Staff"` | same, `"Staff (current screen)"` |

- Button 5 is appended as the LAST child of the existing nav container on every screen.
- Width budget: 110+8+110+8+110+8+140+8+80 = 582 (+32 side padding = 614 <= 640): one row at `>= 640`. On a phone
  (343 px inside a 375 screen) it wraps to three rows (228 / 258 / 80), so every nav container's phone height grows
  from 96 to 148 (44*3 + 8*2) and every header's phone nav term grows from 100 to 152. Exact per-screen edits are in
  each brief.
- Wordmark `"AACA Attendance"` (Size 20 Bold white). Identity line: `Coalesce(CurrentUserRow.'Full Name',
  User().FullName) & " · " & RoleLabel & " · " & If(!StaffReady, "no campus", IsBlank(CurrentStaff.Campus),
  "All campuses", CurrentStaff.Campus.Name)` (Size 12, `ColorInkSoft`).

### Active-only teacher pickers (assignment) - one rule for every screen

Pickers that ASSIGN a teacher list only `Active = true` teachers (Screen1 teacher picker + its defaults, StudentsScreen
form teacher dropdown, StaffScreen new-teacher picker, App.OnStart default teacher). Lists that DISPLAY history keep
retired teachers resolvable (`colStuTeacherSrc` gains `IsActive` instead of being filtered; `colAbsTeacherSrc`
unchanged).

### Navigation and freshness

- StaffScreen `OnVisible` reloads its campus list; Screen1 / StudentsScreen re-query Staff and Enrollments on visit,
  so a retired teacher disappears from their pickers and transferred enrollments show the new teacher at the next
  visit.
- `Navigate(StaffScreen)` on the other four screens requires StaffScreen to exist in the session: the orchestrator
  compiles StaffScreen first.

## YAML Conventions

- Every property value starts with `=`; multi-line formulas use `|-` with `=` on the first content line.
- Any value containing `: ` (record literals `{Kind: "", Title: ""}`, `{Value: "Teacher"}`, captions like
  `"Campus: "`, `"Ready: "`, `"Students now: "`) or ` #` MUST be a `|-` block. Unquoted ` #` starts a YAML comment.
- Dataverse predicates: `With()` scalars inside every LookUp/Filter over a data source (never `record.Field` in the
  predicate); choice columns compare `= Blank()` in delegated filters; disambiguate primary-key columns with
  `ThisRecord.` (`LookUp(Staff, ThisRecord.Staff = q)`, `LookUp(Enrollments, ThisRecord.Enrollment = qe)`).
- `IfError(A, B)`: both branches same type; table-returning success branches end with `; true`;
  `IfError(Patch(...), Blank())` is the verified record pattern. The failure text of a Patch is read afterwards with
  `Coalesce(First(Errors(<source>)).Message, "<fallback>")` BEFORE any other write to that source.
- Yes/No columns are Booleans: `Active = true`, `{Active: false}`, `'Finance Access': false`,
  `'Site Administrator': false`, `'Is Deleted' <> true`.
- Choice literals (exact):
  - `'App Role (Staff)'.Teacher` / `.'Attendance Office'` / `.'Read-only'` / `.'System Admin'`
  - `'Status (Enrollments)'.Planned` / `.Active` / `.Ended` (column `'Status (aaca_status)'`)
  - `'End Reason (Enrollments)'.Transfer`
  - `'Status (Month Locks)'.Locked`
  - `'Action (Audit Events)'.Create` / `.Update` / `.Transfer`
  - Role text to choice: `Switch(r, "Teacher", 'App Role (Staff)'.Teacher, "Attendance Office", 'App Role (Staff)'.'Attendance Office', "Read-only", 'App Role (Staff)'.'Read-only', "System Admin", 'App Role (Staff)'.'System Admin')`
- Enum literals: `ButtonAppearance.Secondary`, `ButtonAppearance.Primary`, `ButtonLayout.TextOnly`,
  `Appearance.Outline`, `TextInputType.Multiline`, `TextInputType.SingleLine`, `TextInputType.Search`,
  `FontWeight.Semibold`, `FontWeight.Bold`, `LayoutDirection.Vertical`, `LayoutDirection.Horizontal`,
  `LayoutAlignItems.Stretch`, `LayoutAlignItems.Center`, `LayoutAlignItems.Start`, `AlignInContainer.Stretch`,
  `AlignInContainer.Center`, `AlignInContainer.Start`, `LayoutOverflow.Scroll`, `DisplayMode.Edit`,
  `DisplayMode.Disabled`, `VerticalAlign.Top`, `DropShadow.None`, `DatePickerFormat.Short`, `OptionLayout.Vertical`,
  `ToggleLabelPosition.After`.
- Audit Events rows: `Summary` (`Left(..., 100)`), `Action`, `Entity` (logical table name: `"aaca_staff"` for Staff
  writes, `"aaca_student"` for transfers as in Change class), `'Entity ID'` (`Text(<guid>)`), `Before` / `After`
  (`JSON({...})` or `""`), `Reason`. Every write is wrapped in IfError and the receipt reports "... written" /
  "NOT written".
- `Select(engine)` calls queue in order. Do not use `Set` inside `ForAll`.

## App.pa.yaml changes (orchestrator)

Apply BEFORE any builder runs; compile App first. No screen names are referenced, so App compiles on its own.

### 1. `App.Formulas` - append after the line `TransportPatternOptions = ["Round trip", "Drop off only", "Pick up only"];` (same 6-space indent)

```
      // ---------- Staff (build 10) ----------
      StaffPending = IsBlank(CurrentStaff) && !IsBlank(LookUp(Staff, Email = Lower(User().Email) && Active = true));
      StaffRoleOptions = ["Teacher", "Attendance Office", "Read-only", "System Admin"];
```

(`CurrentStaff` is unchanged. Dataverse text equality is case-insensitive, so `Email = Lower(User().Email)` is the
delegable form of `Lower(Email) = Lower(User().Email)`; `Active = true` is the Boolean form of "Active <> No".)

### 2. `App.OnStart` - default teacher becomes active-only

In the `Set(varTeacher, ...)` block replace the line

```
                      Filter(Staff, Campus.Campus = varCampus.Campus && 'App Role' = 'App Role (Staff)'.Teacher),
```

with

```
                      Filter(Staff, Campus.Campus = varCampus.Campus && 'App Role' = 'App Role (Staff)'.Teacher && Active = true),
```

### 3. `App.OnStart` - new seeds

Change the current final line `      Clear(colTrnLog)` to `      Clear(colTrnLog);` and append exactly (6-space indent;
the last line has NO trailing semicolon):

```
      Set(varStfCampusId, If(StudentCampusLock <> ZeroGuid, StudentCampusLock, !IsBlank(CurrentStaff.Campus), CurrentStaff.Campus.Campus, Coalesce(First(Sort(Campuses, Name, SortOrder.Ascending)).Campus, ZeroGuid)));
      Set(varStfSelId, ZeroGuid);
      Set(varStfSelId, Blank());
      Set(varStfMode, "");
      Set(varStfShowRetired, false);
      Set(varStfLoading, false);
      Set(varStfSaving, false);
      Set(varStfLoadError, "");
      Set(varStfXferDate, Today());
      Set(varStfReceipt, {Kind: "", Title: ""});
      ClearCollect(colStfCampusOpts, {CampusId: ZeroGuid, CampusName: ""});
      Clear(colStfCampusOpts);
      ClearCollect(colStfAll, {StaffId: ZeroGuid, StaffName: "", Email: "", RoleText: "", CampusId: ZeroGuid, CampusName: "", StartDate: Today(), EndDate: Today(), IsActive: false, Linked: false, StudentsNow: 0, SearchKey: ""});
      Clear(colStfAll);
      ClearCollect(colStfEmails, {StaffId: ZeroGuid, StaffName: "", EmailL: "", UserEmailL: ""});
      Clear(colStfEmails);
      ClearCollect(colStfEnr, {EnrId: ZeroGuid, TeacherId: ZeroGuid});
      Clear(colStfEnr);
      ClearCollect(colStfLocks, {MonthStart: Today()});
      Clear(colStfLocks);
      ClearCollect(colStfXferEnr, {EnrId: ZeroGuid, StudentId: ZeroGuid, StudentName: "", StudentNumber: "", StudentStatus: "", ServiceId: ZeroGuid, RatioText: "", StartDate: Today(), EndDate: Today(), YearEnd: Today()});
      Clear(colStfXferEnr);
      ClearCollect(colStfPlan, {EnrId: ZeroGuid, StudentId: ZeroGuid, StudentName: "", StudentNumber: "", RatioText: "", StartDate: Today(), Action: "", Reason: ""});
      Clear(colStfPlan);
      ClearCollect(colStfXferWork, {EnrId: ZeroGuid, StudentId: ZeroGuid, StudentName: "", StudentNumber: "", RatioText: "", StartDate: Today(), Action: "", Reason: ""});
      Clear(colStfXferWork);
      ClearCollect(colStfLog, {EnrId: ZeroGuid, StudentName: "", StudentNumber: "", Action: "", Outcome: "", Detail: "", NewEnrId: ZeroGuid, AuditOk: false});
      Clear(colStfLog);
      ClearCollect(colStfReceiptLines, {Label: "", Value: ""});
      Clear(colStfReceiptLines)
```

(OnStart is already a `|-` block, so the `: ` inside record literals is safe.)

### 4. `_EditorState.pa.yaml` (after StaffScreen exists)

`ScreensOrder` gets `StaffScreen` appended: Screen1, StudentsScreen, AbsencesScreen, TransportScreen, StaffScreen.
`StartScreen` stays `=Screen1`.
