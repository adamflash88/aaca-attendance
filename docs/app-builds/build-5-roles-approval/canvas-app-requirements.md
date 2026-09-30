# Canvas App Original Request Contract

Contract version: 1
Target device: Responsive

## Original Request

Build 5 of the AACA Attendance canvas app: attendance roles + parent-report approval. Approved by the user on
2026-10-01 ("approve").

User's request (verbatim, 2026-10-01): "I want to restrict teachers use of this app strictly to being able to add
present data ("1") and viewing historical records only for their campus. All absences should be reported via our
absence reporting form on the school website that filters into the attendance log in sharepoint. We now have that
list integrated with our app. So in theory when the office manager is on the absences tab/screen they should be
seeing those absences and approving them which would update the teachers attendance grid. the rationale is to
eliminate as much human error as possible. This means that teachers should not have access to the students or
absences screen. office managers should have access to all three screens but only be able to view students at
their campuses and global admins should have access to everything."

Clarifications (user, 2026-10-01):
- "The office manager should not be editing the grid. its the teachers responsibility to update attendance."
- Unreported absences: "already has a system in place. Dont worry about that."
- "A teacher can undo a "1", yes a teacher can view other teachers grids as read only."
- "Teachers mark 1 and the office staff marks 0.. not directly on the grid though. the "0" is added when the office
  manager approves the absence in the absence screen. once approved the grid updates with a 0 and the correct color."
- "The office staff should hit excused or unexcused, provide a brief reason, and then hit approve."
- Pre-2026 unclassified absences: ignore. 2026 unclassified: office cross-references the SharePoint log.
  "for anything forward of today classification and entry of an absence will be strictly performed via the absence
  tab and integration we have with that sharepoint list."
- Parent submissions exist from 1/1/2026 → cut-over date 1/1/2026 (App Settings ParentReportCutoverDate = "2026-01-01").
- "Admins are view only as well ... accountability stops with the teacher."

Approved plan (verbatim decisions):

Roles:
| | Attendance grid | Students | Absences |
|---|---|---|---|
| Teacher | Own students: tap blank -> 1; tap a 1 -> undo (confirm). Other teachers' grids at their campus: view only. 0s never changeable. | hidden | hidden |
| Office manager | View only, any teacher at their campus | their campus | full: match, then approve / dismiss parent reports |
| System admin | View only, all campuses | everything | everything |
| Read-only | View only, all campuses (unchanged) | hidden | hidden |

Attendance screen (Screen1):
- Tap cycle becomes blank -> 1 -> (confirm) undo; the "A"/absent step is removed. Day view: Present and Undo only
  (no Absent button). "All" (day present) still fills blanks with 1 and skips days that already have any active row.
- Absences (0) are locked for everyone on the grid; tooltip/detail shows source, e.g. "Absent – Excused: Illness
  (parent report #515)" using Attendance 'Source Report ID', classification and Absence Reason.
- Editing allowed only when the signed-in user is a Teacher and the grid's selected teacher is that user's own Staff
  row (and month not locked, date not in the future, school day, enrolled). Otherwise a "View only" banner and all
  cells read-only. Teachers may pick other teachers at their own campus (campus picker fixed); office: own campus;
  admin/read-only: any campus.
- Undo of a 1 = soft delete (Is Deleted = Yes + Audit Event), as today; the teacher can re-mark it later.

Absences screen, Parent reports view — two queues (toggle or sub-tabs):
1. Needs review (existing matching queue, unchanged).
2. Ready to approve: Student Absence Log items with Match_Status in {"Exact","Approved Variation","Manually
   Resolved"}, a parseable AbsenceDate >= ParentReportCutoverDate, and NO Report Decisions row for that item ID.
   Show parent names, matched Student_ID + app student name, campus, dates, reason, submitted by.
- Approve panel for the selected report: student (from Student_ID -> Dataverse Students 'External Client ID'),
  each school day in range (same days-of-absence rule as Needs Review: AbsenceDate up to but not including
  ReturnDate; weekends and all non-"Make-up School Day" Calendar Exceptions excluded; inside a Term) with its planned
  outcome from the live Attendance row for Student + Service + Date:
  - no active row (none, or Is Deleted = Yes) -> create/restore a 0
  - existing active 0 with blank classification -> classify it
  - existing active 0 already classified -> skip ("already classified")
  - existing active 1 -> skip + flag ("marked present by teacher")
  - student not enrolled that day (no enrollment covering it) -> skip; month locked for that campus -> skip
- Office picks Excused or Unexcused (required), Absence Reason from Absence Reasons (required for both), optional
  brief Note pre-filled with the parent's Reason text (max ~200 chars), then Approve. Dismiss (with required note)
  records a Dismissed decision and writes no attendance.
- Approve writes, per eligible day: Attendance upsert on the Student+Service+Date key (Present false, Is Deleted
  false, classification, Absence Reason, Classified By = current Users row, Classified On = Now(), Notes = note,
  'Source Report ID' = SharePoint item ID, plus snapshots for new rows exactly as the grid save engine does:
  Record Key, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio). Then one Report Decisions row (Report
  Item ID, Decision Approved, Classification, Absence Reason, Note, Days Created, Days Classified, Days Skipped,
  Student, Student Key, Campus, Summary) and one Audit Events row. Receipt lists each day and its outcome.
  The Report Decisions alternate key on Report Item ID prevents double-approval (re-check before writing).
- Only Office (own campus) and Admin see/approve. Office sees only reports whose matched student is at their campus
  (campus from the student's current/latest enrollment) or whose SchoolSite is their campus.

Classify absences view (existing): default date range starts 2026-01-01; nothing before 2026 shown by default.

## Capability Inventory

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Scenario(s) | Specialized contract mappings |
| --------------- | ----------------------- | ----------------- | ------------------------ | ------------------ | ----------- | ----------------------------- |
| R-ROLE-NAV | Teachers can't access Students/Absences; office all three (own campus); admin everything | Security, persistence, and resilience | Nav hidden for Teacher/Read-only; screens show not-authorised panel; unchanged for Office/Admin | A-NAV | S-NAV-TEACHER, S-NAV-OFFICE | N/A |
| R-TEACHER-MARK | Teacher marks 1 only, own students | Data lifecycle | blank -> 1 upsert (existing engine), no path to 0 | A-MARK-PRESENT | S-MARK-1 | N/A |
| R-TEACHER-UNDO | Teacher can undo a 1 | Data lifecycle | 1 -> confirm -> soft delete + audit | A-UNDO-PRESENT | S-UNDO-1, S-UNDO-CANCEL | N/A |
| R-VIEW-ONLY | Teachers view other teachers' grids at their campus read-only; office and admin view-only | Security, persistence, and resilience | Editable only for own-teacher grid by a Teacher; View only banner otherwise; 0 cells never editable | A-VIEW-OTHER | S-VIEW-OTHER-TEACHER, S-VIEW-OFFICE, S-ZERO-LOCKED | N/A |
| R-READY-QUEUE | Office sees matched parent reports to approve | Workflow and review | Ready to approve list (matched, >= cutover, undecided), campus-scoped | A-LOAD-READY | S-READY-LIST, S-READY-EMPTY | N/A |
| R-APPROVE | Office hits Excused/Unexcused, brief reason, Approve; grid updates with 0 and colour | Workflow and review | Per-day outcomes; create/restore/classify 0s with Source Report ID; decision + audit; receipt | A-APPROVE-EXCUSED, A-APPROVE-UNEXCUSED | S-APPROVE-NEW-DAYS, S-APPROVE-CLASSIFY-EXISTING, S-APPROVE-SKIP-PRESENT, S-APPROVE-NO-REASON, S-APPROVE-ALREADY-DECIDED | N/A |
| R-DISMISS | (approved plan) dismiss duplicates/errors | Workflow and review | Decision Dismissed with note; no attendance writes | A-DISMISS | S-DISMISS | N/A |
| R-BACKLOG | Classify view for 2026 backlog; hide pre-2026 | Data exploration | Default From = 2026-01-01 | A-FILTER-ABSENCES | S-BACKLOG-DEFAULT | N/A |
| R-REGRESSION | Needs Review matching, Students screen unchanged | App shell and navigation | No behaviour change outside the listed items | A-NAV | S-REGRESSION | N/A |
