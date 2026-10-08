# Canvas App Plan

## Mode

EDIT (build 12, Phase 2 step C - Absence Notices on AbsencesScreen: Mapping Errors re-sourced to Absence Notices,
notice details on Classify, "How did we hear about it?" + Absence Notice creation in Add absence; App opens on
Absences from the Teams link)

## Requirements

Source of truth: `C:\src\aaca-attendance\docs\app-builds\build-12-billing-phase2\canvas-app-requirements.md`
(immutable). Approved overall plan: `plan.md` section 3. Summary:

- A. Mapping Errors tab lists Absence Notices (Status New and Match Status Unmatched/Ambiguous, or Error Detail not
  blank), grouped "Could not match (n)" / "Could not process (n)", campus filter as today. Detail panel: Map student
  (picker = students enrolled at the notice's campus on First Day Absent, pre-filtered by typed last name), Fix dates
  (Could not process rows), Dismiss (reason). Audit per write. Tab label counts these notices. SharePoint era
  engines retire (not shown).
- B. Classify absences and Needs a decision rows show the linked notice (Reference, Parent (Relationship), Reason
  Text, notified <Notice At>), loaded into colAbsList / colAbsCf via `Attendance.'Absence Notice'`.
- C. Add absence: required "How did we hear about it?" (Parent notified us + date/time, not future | No notice).
  Save creates an Absence Notice (Source Office, Status Accepted, Match Status Matched) first, links every
  created/reused day ('Absence Notice', Notice Received On), receipt shows the notice.
- D. `App.StartScreen` opens AbsencesScreen when launched with `screen=absences` (office/admin).

## Original Request Capability Inventory

The requirements file has no keyed inventory; keys are assigned here from its lettered clauses.

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Observer(s) | Scenario(s) |
| --- | --- | --- | --- | --- | --- | --- |
| R-ME-SOURCE | A: change the Mapping Errors SOURCE to Absence Notices; keep tab, list/detail layout, Open, receipts, campus picker, counts | Data exploration | `btnAbsMeEngine` reads 'Absence Notices' into `colAbsMe`; existing controls re-pointed in place | A-NT-LOAD | `galAbsMeA`, `galAbsMeB`, `lblAbsMeCount` | S-ME-LIST |
| R-ME-ROWS | A: rows = Status New and (Unmatched/Ambiguous or Error Detail not blank); campus filter as today (office locked, admins choose/all) | Data exploration | Kind rule (shared plan); `sc` campus scope | A-NT-LOAD, A-NT-CAMPUS | `lblAbsMeCount`, gallery Items | S-ME-LIST, S-ME-CAMPUS |
| R-ME-GROUPS | A: two groups "Could not match (n)" / "Could not process (n)" | Data exploration | Kind A / Kind B | A-NT-LOAD | `lblAbsMeAHead`, `lblAbsMeBHead` | S-ME-LIST |
| R-ME-ROWFIELDS | A: each row Reference, typed name, campus, absent First Day -> back Return Date, Reason Text, Parent Name + Relationship, Notice At local; A rows also Match Detail; B rows Error Detail | Data exploration | row name + meta labels | A-NT-LOAD | `lblAbsMeAName`, `lblAbsMeAMeta`, `lblAbsMeBName`, `lblAbsMeBMeta` | S-ME-LIST |
| R-ME-OPEN | A: keep Open + detail panel | Workflow and review | `btnAbsMeAOpen` / `btnAbsMeBOpen` set `varAbsNtSelId` | A-NT-OPEN, A-NT-CLOSE | `lblAbsMeFacts`, row highlight | S-ME-OPEN |
| R-ME-MAP | A: Map student: picker = students enrolled at notice campus covering First Day Absent, search name/Student Key, pre-filtered by typed last name; Save Patches {Student, Match Status Mapped by office, Match Detail "Mapped by <user> <date>", Error Detail ""}; status stays New; Audit Update aaca_absencenotice; receipt says days appear shortly; list reloads | Data lifecycle | `cboAbsMeStudent` + NEW `chkAbsNtAllStu`; `btnAbsMeMapSave` | A-NT-MAP | `conAbsMeReceipt`, `colAbsMe` reload, tab count | S-ME-MAP, S-ME-MAP-PREFILTER, S-ME-MAP-STALE |
| R-ME-DATES | A: Fix dates (Could not process): First Day / Return Date, Return > First, max 60 days; Patch Last Day = Return - 1, Error Detail "", Match Status Mapped by office; Audit | Data lifecycle | `txtAbsMeAbsDate`, `txtAbsMeRetDate`, `btnAbsMeDatesSave` | A-NT-DATES | `conAbsMeReceipt`, list reload | S-ME-DATES, S-ME-DATES-INVALID |
| R-ME-DISMISS | A: Dismiss: reason required -> Status Dismissed, Note, Processed On Now(), Processed By user; Audit | Workflow and review | `txtAbsMeDismissNote`, `btnAbsMeDismissSave` | A-NT-DISMISS | `conAbsMeReceipt`, row removed | S-ME-DISMISS, S-ME-DISMISS-INVALID |
| R-ME-COUNT | A: tab label "Mapping Errors (n)" counts these notices | Analytics and visualization | untouched `btnAbsHdrErrors.Text` over `colAbsMe` | A-NT-LOAD | `btnAbsHdrErrors.Text`, `lblAbsMeListTitle` | S-ME-LIST, S-ME-MAP |
| R-ME-RETIRE | A: SharePoint lists/engines stay in the file, no longer shown | Security, persistence, and resilience | no control deleted/renamed; SharePoint formulas replaced in place | N/A | file diff (no deletions) | S-ME-LIST |
| R-CLS-NOTICE | B: Classify absence rows and Needs a decision rows show Reference, Parent (Relationship), Reason Text, "notified <Notice At local>"; rows without a notice unchanged; fields loaded via the lookup in colAbs* | Data exploration | `btnAbsLoadEngine` adds Nt* fields | A-CLS-LOAD | `lblAbsRowSrcV`, `lblAbsCfRowMeta` | S-CLS-NOTICE, S-CLS-REGRESSION |
| R-ADD-HOW | C: required "How did we hear about it?" Parent notified us / No notice; date (default Today, not future) + time (h:mm AM/PM, default now); date-time not in the future | Data lifecycle | `rdoAbsNtHowV`, `dpAbsNtDateV`, `txtAbsNtTimeV`; gate `lblAbsAddCheckV` | A-ADD-OPEN, A-ADD-SAVE | `lblAbsAddCheckV.Text`, `btnAbsAddSaveV.DisplayMode` | S-ADD-HOW-INVALID, S-ADD-NOTIFIED |
| R-ADD-NOTICE | C: Save creates an Absence Notice first: Summary "<Last, First> - absent <m/d/yyyy>", Source Office, Status Accepted, Match Status Matched, Student, Campus, First/Last Day, Return = last + 1, Reason Text = note or reason name, Parent Name blank, Notice At (or blank), Processed On/By | Data lifecycle | Patch Defaults('Absence Notices') in `btnAbsAddSaveV` | A-ADD-SAVE | receipt Notice line | S-ADD-NOTIFIED, S-ADD-NONOTICE, S-ADD-NOTICE-FAIL |
| R-ADD-LINK | C: each created/reused Attendance row gets 'Absence Notice' and Notice Received On = Notice At (blank for No notice) | Data lifecycle | day Patch fields | A-ADD-SAVE | per-day receipt line "notice linked"; Classify row notice text | S-ADD-NOTIFIED, S-CLS-NOTICE |
| R-ADD-RECEIPT | C: receipt adds "Notice: <reference> · notified <time>" or "Notice: no notice (billable)" | Workflow and review | `colAbsReceiptLines` Notice line | A-ADD-SAVE | `galAbsReceiptV` | S-ADD-NOTIFIED, S-ADD-NONOTICE |
| R-START | D: StartScreen = AbsencesScreen when Param screen = absences and CanClassify, else Screen1 | App shell and navigation | App.StartScreen | A-START | first screen shown | S-START-PARAM |
| R-NF-LEAN | Non-functional: same look/patterns, IfError + Audit on every write, keep additions lean, no rename/re-parent, conAbsHdrTabs untouched | Security, persistence, and resilience | 7 new controls total; all other changes are in-place property edits | N/A | App Checker after build | N/A (risk report) |

## Requirement Coverage

| Requirement | Planned affordance | Fidelity |
| --- | --- | --- |
| Mapping Errors source = Absence Notices | `btnAbsMeEngine.OnSelect` rewritten: delegated Filter on Status New (+ Campus when scoped) -> `colAbsMe` notice rows; students/enrollments for the picker | Exact |
| Keep tab, list/detail, Open, receipts, campus picker, counts | all existing `AbsMe` controls kept, properties re-pointed; `conAbsHdrTabs` untouched (its label already counts `colAbsMe`) | Exact |
| Campus filter (office locked, admin choose / all) | existing `ddAbsMeCampus`; engine scope `sc` | Exact. Approximation: a New notice with blank Campus is visible only under "All campuses" (admins); the intake flow always sets Campus |
| Two groups with counts | `lblAbsMeAHead` "Could not match (n)", `lblAbsMeBHead` "Could not process (n)" | Exact |
| Row fields | `lblAbsMeAName`/`lblAbsMeBName` = Reference + typed name; `lblAbsMeAMeta`/`lblAbsMeBMeta` = campus (typed + record), absent/back dates, Match Status + Match Detail (A) or Error (B), Reason Text, Parent (Relationship), notified mm/dd/yyyy h:mm AM/PM | Exact (Reason/Match/Error text capped at 80-100 chars on rows; full text in the detail panel) |
| Map student picker | `cboAbsMeStudent` Items = `colAbsMeStudents` enrollment rows at the notice campus covering First Day Absent; only names containing the typed last name unless NEW `chkAbsNtAllStu` "Show all students enrolled at the notice's campus" is ticked or nothing matches; searchable by name/Student Key (Label) | Exact |
| Map save | `btnAbsMeMapSave` Patch notice {Student, Match Status Mapped by office, Match Detail, Error Detail ""}; audit Update; receipt; `Select(btnAbsMeEngine)` | Exact |
| Fix dates | `txtAbsMeAbsDate` / `txtAbsMeRetDate` (M/D/YYYY text, prefilled) + `btnAbsMeDatesSave`; needs a student on the notice | Exact; Approximation: Return Date is required here (Last Day = Return - 1 needs it) and Fix dates is refused when the notice has no student (use Map student, which also re-runs the flow) |
| Dismiss | `txtAbsMeDismissNote` + `btnAbsMeDismissSave` Patch Status Dismissed, Note, Processed On/By; audit | Exact |
| SharePoint engines retired, not shown | no control deleted/renamed/re-parented; the SharePoint/Report Decisions formulas inside the Mapping Errors controls are replaced in place (orchestrator: prefer in-place edits). No control stays SharePoint-only, so nothing needs hiding | Approximation: the old formulas live in git history (commit e957d43), not in hidden controls |
| Classify notice details | `btnAbsLoadEngine` adds NtRef/NtParent/NtRel/NtReason/NtAt to colAbsList and colAbsCf; `lblAbsRowSrcV`, `lblAbsCfRowMeta` show "Notice ABS-... · Parent (Rel) · reason · notified ..." | Exact |
| How did we hear about it? | NEW `lblAbsNtHowV` + `rdoAbsNtHowV` (vertical radio, no default = must choose); NEW `dpAbsNtDateV` (default Today, max Today) + `txtAbsNtTimeV` (default time the panel opened) shown for "Parent notified us" | Exact |
| Office notice creation + linking | `btnAbsAddSaveV.OnSelect` creates the notice before the day loop; each created/reused day gets `'Absence Notice'` + `'Notice Received On'`; notice create failure = no days written | Exact; Addition: if no day is created at all the new notice is set Cancelled (Note explains) so no orphan Accepted notice remains (the Teams alert has already posted) |
| Receipt Notice line | `colAbsReceiptLines` {Label "Notice"} | Exact |
| StartScreen Param | App.StartScreen formula (orchestrator) | Exact (fallback documented in shared plan) |

## Required Record Fields

| Field key | Screen | Record surface | Required field | Source field | Presentation requirement |
| --- | --- | --- | --- | --- | --- |
| me-identity | AbsencesScreen | galAbsMeA / galAbsMeB row | Reference + typed student name | colAbsMe.Ref, LastName, FirstName | `lblAbsMeAName` / `lblAbsMeBName` 14 Semibold, full text, 2 lines |
| me-campus | AbsencesScreen | same rows | typed campus (+ record campus when different) | TypedCampus, CampusName | meta line, first item |
| me-dates | AbsencesScreen | same rows | absent First Day Absent, back Return Date | FirstDay, ReturnDate | meta "absent m/d/yyyy · back m/d/yyyy" |
| me-reason | AbsencesScreen | same rows | Reason Text | ReasonText | meta "Reason ..." (80 chars) |
| me-parent | AbsencesScreen | same rows | Parent Name + Relationship | ParentName, Relationship | meta "Parent X (Mother)" |
| me-noticeat | AbsencesScreen | same rows | Notice At local | NoticeAt | meta "notified mm/dd/yyyy h:mm AM/PM" |
| me-match | AbsencesScreen | galAbsMeA row | Match Status + Match Detail | MatchText, MatchDetail | meta (80 chars) |
| me-error | AbsencesScreen | galAbsMeB row | Error Detail + student | ErrorDetail, StudentName | meta first item (100 chars) |
| me-facts | AbsencesScreen | conAbsMeDetail | all of the above in full + Campus/Student record values | colAbsMe row | `lblAbsMeFacts` multi-line |
| cls-notice | AbsencesScreen | galAbsListV row | Reference, Parent (Relationship), Reason Text, notified | colAbsList.NtRef, NtParent, NtRel, NtReason, NtAt | `lblAbsRowSrcV` |
| cf-notice | AbsencesScreen | galAbsCfList row | same | colAbsCf.Nt* | `lblAbsCfRowMeta` |
| add-rcpt-notice | AbsencesScreen | galAbsReceiptV line | Notice reference + notified time or "no notice (billable)" | returned notice `nt` | Label "Notice" |

## State-Driven Surface Visibility

| Surface key | Owner screen | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- | --- |
| me-list | AbsencesScreen | conAbsMeListPanel | `=!(conAbsRoot.Width < 1024 && !IsBlank(varAbsNtSelId))` | hidden on < 1024 while a notice is open |
| me-detail | AbsencesScreen | conAbsMeDetail | `=conAbsRoot.Width >= 1024 \|\| !IsBlank(varAbsNtSelId)` | always on desktop; on < 1024 only with a notice open |
| me-modebar | AbsencesScreen | conAbsMeModeBar | `=!IsBlank(varAbsNtSelId)` | notice open |
| me-map | AbsencesScreen | conAbsMeMapPanel | `=!IsBlank(varAbsNtSelId) && varAbsMeMode = "map"` | Map student mode |
| me-dates | AbsencesScreen | conAbsMeDatesPanel | `=!IsBlank(varAbsNtSelId) && varAbsMeMode = "dates" && LookUp(colAbsMe, NoticeId = varAbsNtSelId).Kind = "B"` | Fix dates on a Could not process notice |
| me-dismiss | AbsencesScreen | conAbsMeDismissPanel | `=!IsBlank(varAbsNtSelId) && varAbsMeMode = "dismiss"` | Dismiss mode |
| add-panel | AbsencesScreen | conAbsAddPanelV (unchanged) | `=CanClassify && IsBlank(varAbsSelId) && varAbsAddMode in ["absence", "leftearly"]` | unchanged |

(The notice date/time pair inside conAbsAddPanelV is child visibility: `=varAbsAddMode = "absence" && varAbsNtHow =
"Parent notified us"`.)

## Action Contracts

| Requested action | Preconditions | Entry point | Owner screen | Control and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-NT-LOAD | CanClassify | OnVisible, Mapping Errors tab (first time), Reload, campus change, after Map / Fix dates | AbsencesScreen | `btnAbsMeEngine.OnSelect` | 'Absence Notices' (`'Absence Notice'` GUID -> colAbsMe.NoticeId) | colAbsMe = New notices of Kind A/B in campus scope; colAbsMeStudents rebuilt; selection cleared | N/A | N/A | `lblAbsMeCount`, `lblAbsMeAHead`/`BHead`, galleries, tab label |
| A-NT-CAMPUS (existing) | admin (no campus lock), not loading/saving | `ddAbsMeCampus` | AbsencesScreen | `ddAbsMeCampus.OnChange` (unchanged) | Campuses | varAbsMeCampusId; reload | N/A | N/A | `lblAbsMeCount` campus name |
| A-NT-OPEN | row shown, not loading/saving | "Open" on a row | AbsencesScreen | `btnAbsMeAOpen.OnSelect` / `btnAbsMeBOpen.OnSelect` | colAbsMe.NoticeId | varAbsNtSelId = NoticeId; mode "map" (A) / "dates" (B); inputs reset; varAbsNtAllStu false | N/A | N/A | row Fill ColorInfoBg; `lblAbsMeFacts` |
| A-NT-CLOSE | notice open | "Close" | AbsencesScreen | `btnAbsMeClose.OnSelect` | N/A | varAbsNtSelId Blank, mode "", inputs reset; no write | N/A | N/A | `lblAbsMeFacts` guidance text |
| A-NT-MAP | CanClassify; notice open; exactly 1 student picked; not saving; live notice Status New | "Map student" -> "Save mapping" | AbsencesScreen | `btnAbsMeMapSave.OnSelect` | live `LookUp('Absence Notices', ThisRecord.'Absence Notice' = varAbsNtSelId)`; returned `w` | Patch notice; Status stays New; audit Update; colAbsMe row removed; `Select(btnAbsMeEngine)`; flow creates days ~1 min | Student, Match Status = Mapped by office, Match Detail = "Mapped by <user> <m/d/yyyy h:mm AM/PM>", Error Detail = "" | Title: Reference + student + "the days will appear shortly"; Body: Notice ref, typed name/campus, Student (`w.Student`), Match Status (`w`), Match Detail (`w`), Error Detail (`w`, "cleared"), Status (`w`), Audit | `conAbsMeReceipt` (`lblAbsMeReceiptTitle`, `lblAbsMeReceiptBody`); notice gone from list; tab count -1 |
| A-NT-DATES | CanClassify; Kind B notice open; notice has a student; First Day and Return parse (M/D/YYYY); Return > First; <= 60 days; live Status New | "Fix dates" -> "Save dates" | AbsencesScreen | `btnAbsMeDatesSave.OnSelect` | same live LookUp; `w` | Patch notice; audit Update; row removed; reload | First Day Absent, Last Day Absent = Return - 1, Return Date, Error Detail = "", Match Status = Mapped by office | Title: Reference + new range; Body: First Day (`w`, was live), Last Day (`w`, was), Return (`w`, was), Error Detail cleared (`w`), Match Status (`w`), Audit | `conAbsMeReceipt`; list reload |
| A-NT-DISMISS | CanClassify; notice open; reason non-blank; live Status New | "Dismiss" -> "Confirm dismiss" | AbsencesScreen | `btnAbsMeDismissSave.OnSelect` | same live LookUp; `w` | Patch Status Dismissed; audit Update; row removed | Status = Dismissed, Note = reason, Processed On = Now(), Processed By = CurrentUserRow | Title "Dismissed · notice <ref>"; Body: Status (`w`), Note (`w`), Processed on/by (`w`), Attendance not changed, Audit | `conAbsMeReceipt`; row gone; tab count -1 |
| A-CLS-LOAD (changed) | CanClassify, campus, dates | existing triggers | AbsencesScreen | `btnAbsLoadEngine.OnSelect` | Attendance (+ `'Absence Notice'` lookup) | colAbsList / colAbsCf gain Nt* fields | N/A | N/A | `lblAbsRowSrcV`, `lblAbsCfRowMeta` |
| A-ADD-OPEN (changed) | existing | "Add absence" / "Left early" | AbsencesScreen | `btnAbsAddOpenV.OnSelect`, `btnAbsLeOpenV.OnSelect` | N/A | + varAbsNtHow "", varAbsNtOpenAt Now(), reset rdoAbsNtHowV / dpAbsNtDateV / txtAbsNtTimeV | N/A | N/A | panel; How radio empty |
| A-ADD-SAVE (changed) | existing gate + How chosen; Parent notified => date+time parse and not after Now() | "Save absence" | AbsencesScreen | `btnAbsAddSaveV.OnSelect` | new 'Absence Notices' row `nt` (`nt.'Absence Notice'`); Attendance rows by Student+Service+Date (`wr.Attendance`) | 1) Patch Defaults('Absence Notices') (fail -> stop, nothing else written); audit Create (notice); 2) existing day loop, each created/reused day linked; audit Create per day; 3) if 0 days created -> notice Status Cancelled + Note, audit Update; reload list | Notice: Summary, Source Office, Status Accepted, Match Status Matched, Student, Campus, Absence Reason (Excused only), First Day Absent, Last Day Absent, Return Date, Reason Text, Notice At, Processed On, Processed By. Attendance (existing set) + 'Absence Notice' = nt, 'Notice Received On' = nt.'Notice At' | Title (existing); Lines: Operation, Student, Dates, Notice (`nt.Reference` + notified `nt.'Notice At'` or "no notice (billable)"), Notice audit, Classification, Classified by, Note, Created, Skipped, Failed, per-day lines incl. "notice linked" from `wr.'Absence Notice'` | `conAbsReceiptV`; classify list rows show the notice; Screen1 grid |
| A-ADD-CANCEL (changed) | panel open | "Cancel" | AbsencesScreen | `btnAbsAddCancelV.OnSelect` | N/A | + varAbsNtHow "", resets new inputs; no write | N/A | N/A | receipt "cancelled · nothing was changed" |
| A-START | app launch | Teams "Open in app" link (`?screen=absences`) | App | `App.StartScreen` | N/A | AbsencesScreen for office/admin; else Screen1 | N/A | N/A | first screen shown |

Opposing pairs: none. Continuation: none (the office notice is linked inside the same Save; Map / Fix dates hand off
to the processing flow, not to a later app action).

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-NT-MAP | `w` -> varAbsMeReceipt -> `lblAbsMeReceiptTitle` / `lblAbsMeReceiptBody` | Absence Notice (`w.Student`, `w.'Match Status'`) | Mapping Errors list (row disappears) and later Classify list (days via flow) | varAbsNtSelId = colAbsMe.NoticeId = live.'Absence Notice' = w.'Absence Notice' = audit Entity ID | `RemoveIf(colAbsMe, NoticeId = it.NoticeId)` then `Select(btnAbsMeEngine)` re-queries; Classify Reload after ~1 min | N/A - row leaves the list |
| A-NT-DATES | same | Absence Notice dates/status | same | same | same | N/A |
| A-NT-DISMISS | same | Absence Notice Status | Mapping Errors list (row removed) | same | `RemoveIf(colAbsMe, ...)` (next load excludes non-New) | N/A |
| A-ADD-SAVE | `nt` and per-day `wr` -> colAbsLog -> colAbsReceiptLines -> `galAbsReceiptV`; title `lblAbsReceiptTitleV` | Absence Notice `nt`; Attendance rows (`wr.'Absence Notice'`) | Classify list `galAbsListV` (`lblAbsRowSrcV` notice text) | nt.'Absence Notice' = each wr.'Absence Notice' = notice audit Entity ID | `Select(btnAbsLoadEngine)` when >= 1 day created (re-reads the lookup) | N/A - list sorted by date |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| A-NT-MAP | Student | Changed | `cboAbsMeStudent` selection -> `LookUp(Students, ThisRecord.Student = qs)` | Patch live | Body "Student: " & `w.Student.'Display Name'` | row leaves list; Classify rows after flow |
| A-NT-MAP | Match Status | Changed | Unmatched/Ambiguous/any | `'Match Status (Absence Notices)'.'Mapped by office'` | "Match Status: " & `Text(w.'Match Status')` | engine Kind rule (row excluded) |
| A-NT-MAP | Match Detail | Changed | live | "Mapped by <user> <m/d/yyyy h:mm AM/PM>" | "Match Detail: " & `w.'Match Detail'` | N/A |
| A-NT-MAP | Error Detail | Changed | live | `""` | "Error Detail: cleared" from `w.'Error Detail'` | Kind rule |
| A-NT-MAP | Status | Preserved | New | omitted | "Status: " & `Text(w.'Status (aaca_status)')` | flow sets Accepted later |
| A-NT-DATES | First Day Absent / Last Day Absent / Return Date | Changed | `txtAbsMeAbsDate`, `txtAbsMeRetDate` parsed | a, r - 1, r | three lines "now X (was Y)" from `w` / `live` | list reload |
| A-NT-DATES | Error Detail, Match Status | Changed | live | "", Mapped by office | lines from `w` | Kind rule |
| A-NT-DATES | Student | Preserved | live (required non-blank) | omitted | Facts panel before save | N/A |
| A-NT-DISMISS | Status, Note, Processed On, Processed By | Changed | Dismissed, `txtAbsMeDismissNote`, Now(), CurrentUserRow | Patch live | lines from `w` | row removed; next load excludes |
| A-NT-DISMISS | Student, dates, Match Status | Preserved | live | omitted | "Attendance: not changed" | N/A |
| A-ADD-SAVE | Notice: Summary, Source, Status, Match Status, Student, Campus, First/Last Day, Return Date, Reason Text, Notice At, Processed On/By, Absence Reason | Changed (create) | stu, c0, d0, d1, note/rsn, `varAbsNtHow` + `dpAbsNtDateV` + `txtAbsNtTimeV` | Patch Defaults | Notice line (ref + notified / no notice) + audit After JSON; Dates line | Classify row notice text |
| A-ADD-SAVE | Notice Parent Name, Typed names | Preserved (blank) | - | omitted | N/A | N/A |
| A-ADD-SAVE | Attendance 'Absence Notice' | Changed | nt | `'Absence Notice': nt` | per-day line "notice linked" from `wr.'Absence Notice'` | `lblAbsRowSrcV` "Notice ABS-..." |
| A-ADD-SAVE | Attendance 'Notice Received On' | Changed | nt.'Notice At' (blank = No notice) | was `Blank()`, now `nt.'Notice At'` | Notice line time | `lblAbsRowSrcV` notified time |
| A-ADD-SAVE | all other Attendance fields | Changed (unchanged rules from build 9) | seg, t, d, cls, rsn, note | existing Patch | existing lines | existing |
| A-ADD-SAVE | Notice Status (zero days) | Changed | Accepted | `'Status (Absence Notices)'.Cancelled` + Note | Notice line "cancelled (no days were created)" | N/A |

## Functional Test Matrix

Fixtures (Dev, today Wed 2026-10-07): office O (Attendance Office, Chatsworth = CW); admin M (System Admin, no
campus); teacher A. Notices: ABS-2026-001000 New, Unmatched, Campus CW, typed "Nobody Fakestudent", campus typed
"Chatsworth", First Day 10/6/2026, Return 10/7/2026. ABS-2026-001001..001004 Accepted for "McTestface, Testy"
(CW-TEST1, enrolled at CW from 2026-08-17, open) with Attendance days linked. For B rows the tester creates
ABS-T-B: a New notice for Testy (Student set, Match Status Matched) with Error Detail "Return Date before First Day"
and dates 10/9/2026 -> 10/8/2026 (set in Dev with the maker portal).

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-ME-LIST | fixtures; O on Absences | Mapping Errors tab | Could not match (1): ABS-2026-001000; Could not process (1): ABS-T-B; tab "Mapping Errors (2)" | `lblAbsMeAName` "ABS-2026-001000 · Fakestudent, Nobody (as typed)"; `lblAbsMeAMeta` "Campus Chatsworth · absent 10/6/2026 · back 10/7/2026 · Unmatched (...) · Reason ... · Parent ... · notified 10/06/2026 h:mm AM"; `lblAbsMeCount` "1 could not be matched · 1 could not be processed · your campus" | No notices -> "No mapping errors..." text; both galleries hidden |
| S-ME-CAMPUS | admin M | pick Oxnard, then All campuses | Oxnard: 0 rows; All: both rows | `lblAbsMeCount` | O: picker disabled showing Chatsworth |
| S-ME-OPEN | S-ME-LIST | Open on ABS-2026-001000 | row highlighted; Facts show all fields; Map student mode open | `lblAbsMeFacts`, `conAbsMeMapPanel` | < 1024: list hides, detail shows; Close returns |
| S-ME-MAP-PREFILTER | 001000 open (typed last "Fakestudent") | open picker | no name contains "Fakestudent" -> every student enrolled at CW on 10/6 (incl. McTestface, Testy) | `cboAbsMeStudent` items | typed last "McTestface" -> only Testy; tick `chkAbsNtAllStu` -> all CW students |
| S-ME-MAP | 001000 open | pick "McTestface, Testy" -> Save mapping | Notice: Student Testy, Match Status Mapped by office, Match Detail "Mapped by Ortiz, Olga 10/7/2026 9:05 AM", Error Detail blank, Status New; 1 Audit Update (Entity aaca_absencenotice); list reloads without it; tab (1) | `conAbsMeReceipt` title "Notice ABS-2026-001000 mapped to McTestface, Testy · the days will appear shortly"; body lines | ~1 min later Classify (Reload) shows Testy 10/6 with "Notice ABS-2026-001000"; if the flow fails it reappears under Could not process |
| S-ME-MAP-STALE | another user dismissed 001000 after load | Save mapping | no write; Blocked "is already Dismissed"; row removed | receipt | read failure -> Failed, nothing written |
| S-ME-DATES | ABS-T-B open (Fix dates mode) | First 10/8/2026, Return 10/12/2026 -> Save dates | First 10/8, Last 10/11, Return 10/12, Error Detail blank, Match Status Mapped by office; Audit Update; row leaves list | receipt "Notice ABS-... dates saved · 10/8/2026 to 10/11/2026 · the days will appear shortly" | N/A |
| S-ME-DATES-INVALID | ABS-T-B open | (a) Return = First; (b) Return 61+ days later; (c) "10/32/2026"; (d) notice without student | Save dates disabled; `lblAbsMeDatesCheck` explains | `btnAbsMeDatesSave.DisplayMode` | Fix dates button hidden on Kind A rows |
| S-ME-DISMISS | 001000 open | Dismiss -> "Not an AACA student" -> Confirm dismiss | Status Dismissed, Note, Processed On now, Processed By O; Audit Update; removed | receipt "Dismissed · notice ABS-2026-001000" | N/A |
| S-ME-DISMISS-INVALID | Dismiss mode | blank reason | Confirm dismiss disabled | DisplayMode | N/A |
| S-CLS-NOTICE | 001001 linked days for Testy | Classify, status All, dates covering them | Testy rows: "Website ... · Notice ABS-2026-001001 · <Parent> (<Relationship>) · <reason> · notified 10/0x/2026 h:mm AM" (or "· no notice") | `lblAbsRowSrcV` | Needs a decision row with a notice shows the same notice text in `lblAbsCfRowMeta` |
| S-CLS-REGRESSION | absence without notice (teacher-entered) | Classify | row text unchanged ("Teacher" / "Parent report #..." / Reported ...); Excused / Unexcused / Remove still work | `lblAbsRowSrcV`, `conAbsReceiptV` | N/A |
| S-ADD-HOW-INVALID | Add absence open, Testy, 10/12, Unexcused | (a) no How choice; (b) Parent notified, time "8:15"; (c) date today, time 1 hour from now | Save absence disabled; messages "Choose how we heard about it." / "Type the time ..." / "cannot be in the future" | `lblAbsAddCheckV`, DisplayMode | date picker max Today |
| S-ADD-NOTIFIED | Testy, From Mon 10/12 To Tue 10/13, Excused Illness, note "Mom called", Parent notified us, 10/7/2026, "7:45 AM" | Save absence | Notice: Summary "McTestface, Testy - absent 10/12/2026", Source Office, Status Accepted, Match Matched, Student Testy, Campus CW, First 10/12, Last 10/13, Return 10/14, Reason Text "Mom called", Notice At 10/7 7:45 AM, Processed On/By O; Audit Create (notice); 2 Attendance rows with 'Absence Notice' = it and Notice Received On 10/7 7:45 AM; 2 Audit Create | receipt line "Notice · ABS-2026-00xxxx · notified 10/07/2026 7:45 AM"; per-day "Created · Excused (Illness) · notice linked · ..."; Classify rows show the notice; Teams card posts (flow) | N/A |
| S-ADD-NONOTICE | Testy, 10/15, Unexcused, no note, No notice | Save absence | Notice At blank, Reason Text ""; day Notice Received On blank, linked | Notice line "no notice (billable) · ABS-..." | N/A |
| S-ADD-ALLSKIPPED | Testy 10/6 already absent | Save absence for 10/6 only, No notice | notice created then Status Cancelled, Note "No attendance days were created..."; audit Create + Update; receipt Kind Failed | Notice line "... · cancelled (no days were created)" | N/A |
| S-ADD-NOTICE-FAIL | user without notice create privilege (or Dev outage) | Save absence | no notice, no Attendance rows; receipt Failed "the absence notice could not be created, so no days were added" + Error line | `conAbsReceiptV` | N/A |
| S-LE-REGRESSION | Left early open | look at panel; save Jane left early | How / notice date / time controls hidden; save behaves as build 9 | panel, receipt | N/A |
| S-START-PARAM | O | launch app URL + `?screen=absences` / without / teacher A with param | AbsencesScreen / Screen1 / Screen1 (fallback form: Absences denied panel) | first screen | N/A |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| rdoAbsNtHowV | lblAbsNtHowV `="How did we hear about it? *"` | conAbsAddPanelV |
| dpAbsNtDateV | lblAbsNtDateV `="Date the parent told us *"` | conAbsAddPanelV |
| txtAbsNtTimeV | lblAbsNtTimeV `="Time the parent told us * (h:mm AM/PM)"` | conAbsAddPanelV |
| cboAbsMeStudent (existing) | lblAbsMeStudent `="Student *"` | conAbsMeMapField |
| txtAbsMeAbsDate (existing) | lblAbsMeAbsDate `="First Day Absent * (M/D/YYYY)"` | conAbsMeAbsField |
| txtAbsMeRetDate (existing) | lblAbsMeRetDate `="Return Date * (day back, M/D/YYYY)"` | conAbsMeRetField |
| txtAbsMeDismissNote (existing) | lblAbsMeDismissNote `="Why dismiss? *"` (unchanged) | conAbsMeDismissField |

## Layout Budget Contracts

| Screen / container | Branch / screen-width source | Horizontal total-width arithmetic | Vertical height arithmetic | Protected controls |
| --- | --- | --- | --- | --- |
| conAbsAddPanelV (gap 4) | conAbsRoot.Width; inner 307 at 1024 | inputs stretch; longest new label 39 chars x ~7 = 273 <= 307 | absence base 430 + How pair (18 + 64 + 2x4 = 90) = 520; + Excused 62; + Parent notified (18+36+18+36 + 4x4 = 124); max 706; leftearly 368 unchanged | Save absence, Cancel |
| conAbsDecideV | same | unchanged | absence branch `16 + 28 + 8 + 44 + 8 + panel + 16`; max 826 | same |
| galAbsMeA / galAbsMeB rows | conAbsRoot.Width < 640 | row inner 444 at 1024 (meta ~70 chars/line), 295 on phone (~47/line) | desktop 8 + 44 + 4 + 108 + 8 = 172 <= 176; phone 8 + 44 + 4 + 144 + 8 = 208 <= 212 | Open |
| conAbsMeMapPanel (gap 8) | < 640 | stretch | desktop 58 + 32 + 54 + 44 + 3x8 = 212; phone 58 + 32 + 72 + 44 + 24 = 230 | Save mapping |
| conAbsMeDatesPanel | < 640 | fields 2 x min 140 + 8 <= 476 | unchanged 172 / 256 | Save dates |
| lblAbsMeFacts | < 640 | 476 px at 1024 (~65 chars/line at 13) | <= 15 lines: 270 desktop; phone 400 | N/A |
| lblAbsRowSrcV | < 640 | 613 px at 1024 (~97 chars/line) | 2 lines desktop (36) / 4 phone (72): notice text <= ~190 chars (reason capped 80) | N/A |

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| --- | --- | --- | --- | --- | --- |
| AbsencesScreen | conAbsRoot (existing, sole top-level child) | AutoLayout | unchanged `=Parent.Width` | unchanged `=Parent.Height` | Scroll (unchanged) |

## Temporal Ordering Contracts

None. Mapping Errors rows sort by `Created` (typed DateTime); Notice At is a typed DateTime that is displayed, not
sorted; times typed by the office are parsed with `TimeValue(tt, "en-US")` and stored as DateTime.

## Working Directory

C:\src\aaca-attendance\app

Plan artifacts: C:\src\aaca-attendance\docs\app-builds\build-12-billing-phase2\

## Discovery Summary

- Existing screens: Screen1 (Att), StudentsScreen (Stu), AbsencesScreen (Abs), TransportScreen (Trn), StaffScreen
  (Stf). Layout: AutoLayout, one scroll root per screen.
- Data sources used by this edit: 'Absence Notices' (new; schema in canvas-discovery-packet.md), Attendance (+ new
  lookup 'Absence Notice'), Students, Enrollments, Campuses, 'Absence Reasons', Terms, 'Calendar Exceptions',
  'Month Locks', Users (CurrentUserRow), 'Audit Events'. 'Student Absence Log' stays referenced only by the Classify
  loader (colAbsCfRpt); 'Report Decisions' is no longer referenced by AbsencesScreen.
- Controls: all types already in AbsencesScreen (GroupContainer, ModernText, ModernButton, Classic/Button, Gallery,
  ModernCombobox, ModernDatePicker, ModernTextInput, ModernRadio, ModernCheckbox, ModernDropdown). No new types;
  no new enum types.

## Dispatch

| Action | Screen | Target File | YAML Key | Name Prefix | Screen Brief |
| --- | --- | --- | --- | --- | --- |
| Modify | Absences | `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml` | AbsencesScreen | Abs (new: AbsNt) | `C:\src\aaca-attendance\docs\app-builds\build-12-billing-phase2\AbsencesScreen.screen-plan.md` |

## App Changes

### Before builders

`App.OnStart` seeds and `App.StartScreen` exactly as in `canvas-app-shared.md` section "App.pa.yaml changes
(orchestrator)". OnStart: `Clear(colHelpMsgs)` -> `Clear(colHelpMsgs);` then append `Set(varAbsNtSelId, ZeroGuid);
Set(varAbsNtSelId, Blank()); Set(varAbsNtAllStu, false); Set(varAbsNtHow, ""); Set(varAbsNtOpenAt, Now());
Set(varAbsNtErr, "")` (one per line, last without semicolon). StartScreen:
`=If(Lower(Coalesce(Param("screen"), "")) = "absences" && CanClassify, AbsencesScreen, Screen1)`.

### After builders

None.

## Editor State Changes

None (no screen added or reordered).
