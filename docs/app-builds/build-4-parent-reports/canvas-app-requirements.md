# Canvas App Original Request Contract

Contract version: 1
Target device: Responsive

## Original Request

Build 4 of the AACA Attendance canvas app: parent-report matching + Student Key rule. Approved by the user on
2026-09-30 ("Approve"; "student key should be read only").

Context: parents report absences through a website form; a Power Automate flow (owned by the user, outside this
app) writes each submission to the SharePoint list **Student Absence Log** (site
https://autismacademy.sharepoint.com/sites/FinanceMain) and tries to match the student by name against the
SharePoint list **Student Directory**. Unmatched submissions get Match_Status = "Needs Review". Student_ID values
(e.g. CW-1083) are the same Student Keys stored in Dataverse Students.'External Client ID' (verified identical).

Base prompt the user asked us to review (kept where not overridden by the approved plan):
"Add a 'Needs Review' screen for absence matching. Use the existing Student Absence Log and Student Directory
SharePoint lists. Show absence records whose Match_Status choice equals 'Needs Review.' Selecting a record should
display its original submitted first name, last name, campus, and absence dates. Provide a searchable,
single-select student picker showing full name, campus, and Student_ID. Initially filter students to the
absence's campus, mapping Antelope Valley to AV, Chatsworth to CW, and Oxnard to OX. Include an option to search
all campuses. Do not filter out inactive students because historical absences may need resolving. Add a 'Resolve
Match' button, disabled until a student is selected. On click, update the selected existing absence record's
Matched_Student lookup, Student_ID text, and Match_Status choice to 'Manually Resolved' in one save. Preserve all
other fields. Show a success message and refresh the review queue only after a successful save; show an error
and retain the selection if saving fails. Reset the student selection when switching absence records. Inspect the
actual SharePoint column types before implementing the update. Do not create a name-variations list."

Approved changes to that prompt (user decisions 2026-09-30):
- Placement: a toggle inside the Absences screen — "Classify absences | Parent reports – Needs review (N)" — not a
  new screen or nav button. Queue shows Needs Review only.
- Student picker reads the app's Dataverse Students (all statuses incl. Archived), NOT the Student Directory list.
  Display "Last, First · <campus code> · <Student Key> · <status>".
- Campus mapping via the Campuses table (SchoolSite text = Campuses.Name -> Campuses.Code), never hard-coded.
- On Resolve: find the Student Directory item whose Student_ID = the picked Student Key and set Matched_Student to
  it ({Id, Value}); if no directory item exists, write nothing and say so. Also set Student_ID and
  Match_Status {Value: "Manually Resolved"} in the same Patch. Preserve every other column (billing columns are
  finance-owned; never write them).
- Re-check before saving: re-read the log item; if Match_Status is no longer "Needs Review", write nothing and
  explain. Write a Dataverse Audit Events row (Action Update, Entity "sharepoint:Student Absence Log", Entity ID =
  the item ID, Summary "Parent report #<ID> matched to <key>", After = JSON of the three written values).
- Show computed "Days of absence": from AbsenceDate up to but not including ReturnDate (if ReturnDate is blank or
  <= AbsenceDate, just AbsenceDate), excluding weekends and that campus's Closed / Work Only Calendar Exceptions
  (campus-specific or all-campus), within the campus Terms. Date text is M/D/YYYY with or without leading zeros —
  parse with DateValue(text, "en-US"); if unparseable show the raw text with a "check dates" note.
- Student Key rule on the Students screen: Add student requires a Student Key (External Client ID), pre-filled
  with the selected campus code + "-" + (highest numeric suffix across all existing keys + 1), editable, must
  match ^[A-Z]{2,3}-\d+$, must be unique (block with message if another student has it); Edit makes the key
  read-only (view mode, with a note "Student Key can't be changed").
- Access: Office and Admin only (CanClassify), same as the rest of the Absences screen.

## Capability Inventory

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Scenario(s) | Specialized contract mappings |
| --------------- | ----------------------- | ----------------- | ------------------------ | ------------------ | ----------- | ----------------------------- |
| R-TOGGLE | Toggle inside Absences between Classify and Parent reports – Needs review (N) | App shell and navigation | ModernTabList or two buttons; count of Needs Review items; existing classify view unchanged | A-SWITCH-ABS-VIEW | S-TOGGLE | N/A |
| R-NR-QUEUE | Show Absence Log records with Match_Status = Needs Review | Data exploration | Delegable filter Match_Status.Value = "Needs Review", newest first; parent-typed first/last, SchoolSite, AbsenceDate, ReturnDate, Reason, Submitted By, Date Notified, Title; zero state | A-LOAD-NR | S-NR-LIST, S-NR-EMPTY | N/A |
| R-NR-DETAIL | Selecting a record shows its submitted names, campus, dates (+ computed days) | Time and scheduling | Detail panel for the selected item; computed school days of absence | A-SELECT-NR | S-NR-DAYS, S-NR-BADDATE | N/A |
| R-PICKER | Searchable single-select picker, campus-filtered with search-all, includes inactive | Data exploration | ModernCombobox SelectMultiple false over Dataverse students (local collection), filter by mapped campus code unless "Search all campuses"; reset on record switch | A-PICK-STUDENT, A-SEARCH-ALL | S-PICK-CAMPUS, S-PICK-ALL, S-PICK-RESET | N/A |
| R-RESOLVE | Resolve Match: one save of Matched_Student, Student_ID, Match_Status; preserve other fields; success/error handling | Workflow and review | Disabled until picked; re-check status; directory item required; Patch 3 columns; audit; success -> refresh queue + clear; failure -> error, keep selection | A-RESOLVE | S-RESOLVE-OK, S-RESOLVE-FAIL, S-RESOLVE-ALREADY, S-RESOLVE-NO-DIR | N/A |
| R-KEY | Student Key required, unique, auto-suggested on Add; read-only on Edit | Data lifecycle | Add form field with suggestion + validation; Edit shows it read-only; Dataverse alternate key backs uniqueness | A-ADD-STUDENT, A-EDIT-STUDENT | S-KEY-SUGGEST, S-KEY-DUP, S-KEY-FORMAT, S-KEY-READONLY | N/A |
| R-REGRESSION | Existing classify queue and Students behaviour unchanged | App shell and navigation | Only the listed additions | A-SWITCH-ABS-VIEW | S-REGRESSION | N/A |
