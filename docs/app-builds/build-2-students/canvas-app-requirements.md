# Canvas App Original Request Contract

Contract version: 1
Target device: Responsive

## Original Request

Build 2 of the AACA Attendance canvas app (Milestone 3 of docs/architecture.md): a Student Management screen
where an office manager can add students, archive students, transfer students, change IEP (aide) ratios, etc.
User request (2026-09-29): "a new management screen where an office manager can manage adding students,
archiving students, transferring students, aide ratios, etc." Approved plan on 2026-09-29 with clarifications:
"Teachers do not see this screen." "We do not have a need for campus transfers at this time, but we may as
well future proof things and incorporate that feature." Approve.

Original brief clauses (Section 6 "Student lifecycle", Section 2 roles, Section 11 UX) in scope:

- Add student: form with duplicate detection (name + date of birth), required fields, campus, teacher,
  program, IEP ratio and start date; creates the Student and Enrollment rows and writes an audit entry.
- Transfer student (teacher, campus and/or ratio change): guided flow with an effective date; closes the
  current Enrollment the day before, opens a new one, leaves past attendance with the old teacher and campus;
  supports future-dated transfers; prevents overlapping enrollments for the same student and service.
- Discharge / end services: set End Date and status; the student drops out of future matrices but remains in
  history and reports.
- Archive / Unarchive: archived students are hidden from all pickers and default views, never deleted;
  "Include archived" toggle for search; archiving requires all enrollments closed.
- Corrections: edits to name, DOB, grade and external ID are audited (before/after); retroactive
  (backdated) enrollment changes warn if attendance is already recorded on/after the effective date.
- Student profile: enrollment history timeline for the selected student.
- Roles: Attendance Office = own campus only; System Admin = any campus; Teachers and Read-only never see the
  screen (no nav button, and the screen shows a not-authorised panel if reached).
- Relationships use GUID lookups; never key on free-text names. Normalise and trim text inputs.
- Every write path produces an Audit Events row.

Approved design (verbatim decisions):

- New screen `Students` (file Students.pa.yaml) + modify Screen1 header to add an Attendance / Students
  switch visible only to Office and Admin (CanManageStudents). Students screen header has the same switch.
- Layout: list on the left, selected-student detail + action buttons on the right; stacks on narrow widths.
  Same header, palette and responsive root pattern as Screen1 (see Screen1.pa.yaml and App.pa.yaml).
- Data: load students for the campus scope and current + next school year enrollments into collections on
  entry/refresh (scale ~225 students, ~300 enrollments/yr); filter locally for search.
- Actions and transitions:
  - Add: Student (Status Active, Display Name "Last, First", trimmed names) + Enrollment (School Year from
    the start date, Status Active if start <= Today() else Planned, Service = the single active service) +
    Audit Event (Create). Owner of Student and Enrollment = the teacher's Users record when the teacher's
    Staff.User is not blank. Duplicate (same trimmed first + last name, case-insensitive, and DOB) shows a
    warning with the existing student and blocks save until the user ticks "This is a different person".
  - Change class (transfer, teacher and/or campus, cross-campus allowed): effective date E; current open
    enrollment End Date = E - 1, End Reason Transfer, Status Ended if E <= Today() else stays Active;
    new enrollment starts E, same program/ratio/service/school year, Previous Enrollment = old, Status Active
    if E <= Today() else Planned; Student Owner = new teacher's user when E <= Today(); Audit Event (Transfer).
  - Change IEP ratio: same close/open pattern, End Reason Ratio Change, same teacher/campus, new ratio;
    Audit Event (Update, reason "IEP ratio change").
  - Discharge: open enrollment End Date = chosen date, End Reason Discharge, Status Ended (or Active until the
    date if in the future); Student Status Inactive when no other open/planned enrollment; Audit Event
    (Discharge) with reason text.
  - Archive: allowed only when the student has no enrollment with blank End Date or End Date >= Today();
    Status Archived, Archived On = Today(), Archived By = current Users row; Audit Event (Archive).
    Unarchive: Status Inactive, clears Archived On/By; Audit Event (Unarchive).
  - Edit details: First/Last/Display Name, Date of Birth, Grade, External Client ID prefilled; saves only
    those fields; Audit Event (Update) with Before/After JSON.
- Validation for effective dates: inside a School Year; strictly after the current enrollment Start Date;
  new enrollment must not overlap another enrollment of the same student + service; backdated (E <= Today())
  shows count of existing non-deleted Attendance rows for the student with Date >= E and requires a confirm
  checkbox.
- Receipts: a status strip in the initial viewport bound to the captured returned record(s), showing the
  action, student name + number, and every written field.
- Deferred: year rollover, summer roster (Milestone 6); attendance totals on the profile.

Data model facts: see docs/app-builds/build-1-attendance/canvas-app-requirements.md and the discovery packet
(`C:\src\aaca-attendance\app\canvas-discovery-packet.md`). Choice values used here:
Students 'Status (aaca_status)' = 'Status (Students)'.Active/Inactive/Archived; Grade 'Grade (Students)'.K,
'1'..'12', '12+'; Enrollments 'Status (aaca_status)' = 'Status (Enrollments)'.Planned/Active/Ended;
'End Reason' = 'End Reason (Enrollments)'.Transfer/'Ratio Change'/Discharge/'Year End'/Correction;
Program = 'Program (Enrollments)'.'Regular Year'/Summer; 'IEP Ratio' = 'IEP Ratio (Enrollments)'.'No Aide',
'1:1','2:1','3:1','4:1'; Audit Events Action = 'Action (Audit Events)'.Create/Update/Transfer/Discharge/
Archive/Unarchive.

## Capability Inventory

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Scenario(s) | Specialized contract mappings |
| --------------- | ----------------------- | ----------------- | ------------------------ | ------------------ | ----------- | ----------------------------- |
| R-NAV | Office manager reaches a management screen; teachers never see it | App shell and navigation | Attendance/Students switch on both headers visible only when CanManageStudents; Students screen shows not-authorised panel otherwise | A-NAV-STUDENTS, A-NAV-ATTENDANCE | S-NAV-OFFICE, S-NAV-TEACHER-HIDDEN | N/A |
| R-LIST | Find students; archived hidden unless "Include archived" | Data exploration | Search by name or student number; status filter; campus scope (office fixed, admin picker); optional teacher filter; zero-result state | A-LOAD-STUDENTS, A-FILTER-STUDENTS | S-SEARCH, S-ARCHIVED-HIDDEN | N/A |
| R-ADD | Add student with duplicate detection, required fields, campus, teacher, program, ratio, start date; audit | Data lifecycle | Student + Enrollment + Audit Event created; receipt shows every entered value and the new Student Number | A-ADD-STUDENT | S-ADD-OK, S-ADD-DUPLICATE, S-ADD-MISSING | N/A |
| R-TRANSFER | Transfer teacher and/or campus with effective date; future-dated; no overlap; history kept | Relationships and hierarchy | Old enrollment closed E-1 (Transfer), new enrollment from E linked via Previous Enrollment; owner moves; audit | A-TRANSFER | S-TRANSFER-TODAY, S-TRANSFER-FUTURE, S-TRANSFER-CAMPUS, S-TRANSFER-BACKDATED, S-TRANSFER-INVALID-DATE | N/A |
| R-RATIO | Change IEP (aide) ratio with effective date | Data lifecycle | Close/open with End Reason Ratio Change; same teacher; audit | A-CHANGE-RATIO | S-RATIO-OK, S-RATIO-SAME | N/A |
| R-DISCHARGE | Discharge / end services | Workflow and review | Enrollment ended (Discharge); student Inactive when nothing else open; audit | A-DISCHARGE | S-DISCHARGE-OK, S-DISCHARGE-CANCEL | N/A |
| R-ARCHIVE | Archive / Unarchive; archiving requires all enrollments closed | Workflow and review | Status Archived with Archived On/By; blocked with reason while any enrollment is open/future; unarchive to Inactive; audit | A-ARCHIVE, A-UNARCHIVE | S-ARCHIVE-OK, S-ARCHIVE-BLOCKED, S-UNARCHIVE-OK | N/A |
| R-EDIT | Corrections to name, DOB, grade, external ID are audited | Data lifecycle | Prefilled edit; saves those fields only; Audit Event with Before/After | A-EDIT-STUDENT | S-EDIT-OK, S-EDIT-CANCEL | N/A |
| R-HISTORY | Student profile with enrollment history | Relationships and hierarchy | Timeline of all enrollments for the selected student (dates, teacher, campus, ratio, program, status, end reason) | A-SELECT-STUDENT | S-HISTORY | N/A |
| R-REGRESSION | Existing Attendance screen behaviour unchanged | App shell and navigation | Only the header gains the switch; all Screen1 formulas untouched | A-NAV-STUDENTS | S-NAV-OFFICE | N/A |
