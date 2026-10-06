# Canvas App Original Request Contract

Contract version: 1
Target device: Responsive (desktop-first 1366x768, usable at 1024)
Mode: EDIT (AACA Attendance, app fb649976-33fb-4419-8ee6-132c204df470, Dev env a4c9f4ce-b971-edf2-beba-e3c29552a316).
Source folder: `C:\src\aaca-attendance\app` (synced 2026-10-06, identical to repo).

## Original Request

Adam, 2026-10-05/06 (approved "for the dev build/rebuild"):

- "I believe that the parent reports tabs is just going to serve to confuse people. I want to get rid of them. We can
  just run with classify absences. And frankly what gets pulled in from sharepoint should automatically be input as a
  0 and the only thing the office staff should be doing is classifying it as excused or unexcused."
- Reports that cannot be matched to a student: "lets keep a seperate tab for that. We'll have one tab that classifies
  and one tab that called Mapping Errors."
- Future-dated reports become 0s immediately (option a). If the teacher already marked present, do not overwrite:
  flag for the office ("Parent reported absent, teacher marked present") - agreed. 2026 reports never approved are
  processed once (done in Dev: 298 processed, 230 days created, 42 conflicts).

Already built (Dev, NOT part of this canvas build): flows "AACA - Absence Report Intake" (+ SharePoint trigger, +
backfill) create the 0s. Each created absence: Attendance with Present = false, Source = 'Parent report', Notice
Received On (datetime), Source Report ID (SharePoint item ID), Notes = "Parent report #<id>: <parent reason>", no
Absence Classification. Conflicts: the teacher's present row gets 'Parent Reported Absent' = Yes (+ Source Report ID,
Notice Received On). Each processed report writes a Report Decisions row (Report Item ID, Processing Status Processed /
Error, Error Detail, Days Created / Skipped / Conflict, Student Key, Student, Campus; owned by the campus).

## Scope: AbsencesScreen only (plus App.Formulas/OnStart changes if needed)

1. **Remove completely**: the "Parent reports - Needs review" and "Parent reports - Ready to approve" views, their
   toggle buttons, panels, galleries, engines (nr load / ap load / ap plan / approve / dismiss / match), and any
   variables/collections used only by them. Deleting controls is allowed; never re-parent remaining controls.
2. **View toggle** becomes two buttons: **Classify absences** (default) and **Mapping Errors (n)**.
3. **Classify absences** (keep the existing classify view and its Mark Excused / Mark Unexcused flow) plus:
   - Each absence row shows, when present: the parent's reason (from Notes), "Reported <date time> (Pacific)" from
     Notice Received On, and the source ("Parent report #<id>" / "Teacher" / "Office"). Rows from earlier imports
     without these fields show as today.
   - **Remove absence** for selected rows (office/admin only): requires a reason; soft-deletes each absence
     (Is Deleted = Yes, like the grid's undo), writes an Audit Event (Soft Delete) per row; the 0 disappears from the
     grid. Use case: the child came to school after all, duplicate report.
   - **Needs a decision** section at the top of the view (only when non-empty): Attendance rows for the campus/period
     with Parent Reported Absent = Yes and Present = Yes. Row: student, date, teacher, parent reason / report #,
     reported time. Actions: **Keep present** (clear the flag; audit Update, reason "Teacher marked present") and
     **Mark absent** (Present = false, flag cleared, Source = 'Office', then it appears in the classify list; audit
     Update). Office/admin only.
4. **Mapping Errors** view (office/admin; campus-limited like the rest of the screen):
   - List A, "No Student ID": SharePoint 'Student Absence Log' items created on/after the cut-over (App formula
     ParentReportCutover, default 2026-01-01) with blank Student_ID, School Site = the user's campus (admins: all, with
     the existing campus picker), and no Report Decisions row (Report Item ID = item ID). Row: report #, typed
     student first/last name, school site, absence/return date text, reason, submitted by, date notified.
   - List B, "Could not process": Report Decisions with Processing Status = Error (Dataverse security limits them to
     the user's campus). Row: report #, error detail, student key, created on.
   - **Map** (List A and List B "unknown student"): pick the student from the campus's students (search box; existing
     student picker pattern from the old Needs review match UI may be reused by copying, with NEW control names),
     then Patch the SharePoint item: Student_ID = the student's Student Key (External Client ID), Match_Status =
     "Manually Resolved". Do not write any other SharePoint column (finance-owned columns must never be written).
     The intake flow picks the change up within a few minutes and creates the 0s; show a notice saying so.
   - **Fix dates** (List B "dates cannot be read" / "covers N days"): edit Absence Date and Return Date text (M/D/YYYY)
     and Patch only those two SharePoint columns; same notice.
   - **Dismiss** (both lists): reason required; creates (List A) or updates (List B) a Report Decisions row with
     Decision = Dismissed, Processing Status = Processed, Note = reason, Report Item ID, Student Key if known;
     audit event. The flow then never processes the report.
   - Count in the toggle = List A + List B.
5. Teachers continue to have no access to the Absences screen. Read-only role: view only (no action buttons).

## Non-functional

- Keep the existing look (paper/ink/teal palette, header, nav, receipts/notices, responsive root, engines pattern).
- AbsencesScreen was over the App Checker complexity limit (328 > 300); removing the parent-report views should reduce
  it - aim to end below 300 and keep control count reasonable.
- Known traps (memory canvas-yaml-gotchas): quote values with ` #` or `: `; no glyphs; IfError branch types; `= Blank()`
  for choices in delegated filters; never re-parent controls; Yes/No columns are Booleans.
- All writes: IfError with visible notice; Audit Events row per change.

## Data sources (in the app)

Attendance (new columns: Source choice 'Source (Attendance)' Teacher/'Parent report'/Office; Notice Received On
DateTime; Parent Reported Absent Yes/No), Report Decisions (new: Processing Status choice Processed/Error, Error Detail
text, Days Conflict number), Student Absence Log (SharePoint), Students, Enrollments, Campuses, Staff, Absence Reasons,
Audit Events, Users, Month Locks, Terms, Calendar Exceptions, Services, School Years, App Settings, Student Directory.
