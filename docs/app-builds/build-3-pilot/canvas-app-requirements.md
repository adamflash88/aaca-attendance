# Canvas App Original Request Contract

Contract version: 1
Target device: Responsive

## Original Request

Build 3 of the AACA Attendance canvas app ("Step 1" pilot readiness), approved by the user on 2026-09-30.
User: "okay lets move to step 1" then "approve" to the edit plan below.

Domain rules confirmed by the user (2026-09-29), which override earlier designs:
- An enrollment is one continuous record from Start Date until ended; it does not split at quarters, ESY or school
  years. A new enrollment is created only on a transfer (teacher/campus) or an IEP ratio change.
- An End Date with no following enrollment means the student is archived; they drop off every grid after it.
- ESY is only a calendar period; no separate ESY enrollment. The Program column is internal (always 'Regular Year').
- Start and end dates are strict at day level going forward.

Approved edit plan (verbatim):

Screens to modify:
- Attendance (Screen1.pa.yaml): header switch becomes Attendance / Students / Absences (Office and Admin only).
  Nothing else changes.
- Students (StudentsScreen.pa.yaml): Discharge and Archive become one **End enrollment** action; Unarchive
  becomes **Re-enroll**. Header gains the Absences button.

Screen to add:
- Absences (AbsencesScreen.pa.yaml): office classification queue — mark absences Excused (reason required) or
  Unexcused, one at a time or in bulk.

Functional changes:
- End enrollment (replaces Discharge + Archive): select an active student -> End enrollment: end date (default
  today), note (required), confirm. The open enrollment gets End Date, End Reason Archived, Status Ended (or Active
  until a future date). No enrollment follows, so the student becomes Archived (Archived On = end date, Archived By
  = me). Audit Event (Archive). Receipt shows student, end date, new status; student drops off every grid after that
  date and moves to the archived list.
- Re-enroll (replaces Unarchive): select an archived student -> Re-enroll: campus, teacher, IEP ratio, start date
  (after their last end date). New enrollment linked to their last one (Previous Enrollment); student Active,
  Archived On/By cleared. Audit Event (Unarchive). Receipt with the new enrollment; history shows the gap and the new
  start; the student appears on the teacher's grid from the start date.
- Absences queue: Absences button in the header. Filters: campus (office staff fixed to theirs), teacher, date
  range (default: this school year), status (Not classified [default] / Excused / Unexcused / All). List of
  absences: student, date, teacher, campus, current status; count ("247 not classified"); zero-result state.
- Classify one: Excused or Unexcused on a row (Excused asks for a reason from Absence Reasons). Row gets
  classification, reason (Excused only; cleared for Unexcused), Classified By, Classified On. Audit Event
  (Reclassify). Row updates, receipt, Attendance grid shows green/red 0 for that day.
- Classify in bulk: tick rows (or Select all shown) -> Mark Excused (one reason) / Mark Unexcused. Each ticked row
  updated as above, one Patch per row. Receipt "18 marked Excused (Illness), 0 failed"; ticked rows leave the queue
  (when the Not classified filter is active).
- Change a classification: status filter Excused/Unexcused -> reclassify a row; audit records old -> new.
- Rules: present days can't be classified (never in the queue); Excused always requires a reason; a campus/month
  locked in Month Locks can't be classified; Teachers and Read-only never see the Absences screen.

App changes: named formula CanClassify = Office or Admin; OnStart initial values for the new screen's filters,
ticked rows and receipt. (Data row limit 2000 is a Studio setting the user changes.)

Approach: same header, palette, register styling and responsive root as the other screens; loads matching
absences for the chosen filters (about 1,250 total now); every write audited. Not in this build: reports/exports,
month lock screen, calendar editor, audit viewer.

## Capability Inventory

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Scenario(s) | Specialized contract mappings |
| --------------- | ----------------------- | ----------------- | ------------------------ | ------------------ | ----------- | ----------------------------- |
| R-NAV3 | Header switch Attendance / Students / Absences for Office and Admin | App shell and navigation | Same 3-button nav on all three screens, current screen highlighted; hidden for Teacher/Read-only; Absences screen shows not-authorised panel otherwise | A-NAV-ATTENDANCE, A-NAV-STUDENTS, A-NAV-ABSENCES | S-NAV3-OFFICE, S-NAV3-TEACHER-HIDDEN | N/A |
| R-END | End enrollment replaces Discharge + Archive | Workflow and review | Open enrollment ended (Archived reason); student Archived with On/By; audit; receipt | A-END-ENROLLMENT | S-END-OK, S-END-FUTURE, S-END-NO-NOTE, S-END-CANCEL | N/A |
| R-REENROLL | Re-enroll replaces Unarchive | Workflow and review | New linked enrollment after last end date; student Active; archive stamp cleared; audit; receipt | A-REENROLL | S-REENROLL-OK, S-REENROLL-BAD-DATE, S-REENROLL-CANCEL | N/A |
| R-QUEUE | Absences queue with campus/teacher/date/status filters and count | Data exploration | Delegable filter on Attendance (Present = false, Is Deleted = false, classification per status filter, campus, teacher, date range); count and zero state | A-LOAD-ABSENCES, A-FILTER-ABSENCES | S-QUEUE-DEFAULT, S-QUEUE-FILTER, S-QUEUE-EMPTY | N/A |
| R-CLASSIFY-ONE | Classify one absence Excused (reason) / Unexcused | Workflow and review | Patch classification + reason + Classified By/On; audit Reclassify; receipt; grid colour | A-CLASSIFY-EXCUSED, A-CLASSIFY-UNEXCUSED | S-ONE-EXCUSED, S-ONE-EXCUSED-NO-REASON, S-ONE-UNEXCUSED | N/A |
| R-CLASSIFY-BULK | Tick rows / select all shown, then mark Excused (one reason) or Unexcused | Workflow and review | One Patch per ticked row; counts of marked/failed; ticked set cleared on success | A-BULK-EXCUSED, A-BULK-UNEXCUSED, A-TICK | S-BULK-EXCUSED, S-BULK-UNEXCUSED, S-BULK-NONE-TICKED | N/A |
| R-RECLASSIFY | Change an existing classification, audit old -> new | Workflow and review | Same write path; Before/After JSON in audit | A-CLASSIFY-EXCUSED, A-CLASSIFY-UNEXCUSED | S-RECLASSIFY | N/A |
| R-LOCK | Locked campus/month can't be classified | Security, persistence, and resilience | Rows in a locked month show a lock and their actions are disabled; engine re-checks | A-CLASSIFY-EXCUSED, A-BULK-EXCUSED | S-LOCKED | N/A |
| R-REGRESSION | Existing Attendance/Students behaviour unchanged except the listed changes | App shell and navigation | Only header nav (Screen1) and the End/Re-enroll actions (Students) change | A-NAV-ATTENDANCE | S-REGRESSION | N/A |
