# Canvas App Original Request Contract

Contract version: 1
Target device: Responsive

## Original Request

Build 1 of the AACA Attendance canvas app (Milestone 2 of docs/architecture.md): the app shell and the
Attendance Matrix, backed by live Dataverse tables (no mock data). Approved by the user on 2026-09-28.

Original brief clauses in scope for this build (Section 4 "Attendance entry", Section 2 roles, Section 11 UX):

- Monthly matrix: rows = the selected teacher's students active during the selected month; columns = days of
  that month. Month/year picker on top; admins get a teacher/campus picker.
- Cell states: blank (not recorded), 1 (present), 0 (absent). Tap to set/cycle. Provide "mark all present for
  this day" (column bulk action), with individual overrides afterwards.
- Non-school days (weekends, campus closures from Calendar Exceptions, days outside any Term) are shaded and
  read-only. (Admin override with reason is deferred to a later build.)
- A student appears only on days within their Enrollment StartDate/EndDate; other days are greyed out and
  locked. A mid-month transfer shows the student under the right teacher on the right days.
- Each save writes ONE record (upsert by the Student + Service + Date key); never rewrite the whole grid.
  Show per-cell saved / saving / failed indicators, retry on failure, and warn on concurrent edit conflicts
  (compare Modified On before writing).
- Clearing a cell = soft delete: confirmation prompt, Is Deleted = Yes, plus an Audit Event row.
  Re-entering the same day restores/overwrites the same row.
- Row totals (days present) and column totals (students present per day) calculated from the loaded month.
- Validation: value must be present/absent; must be a school day; student enrolled that day; no future dates
  unless Setting AllowFutureDates = "true"; month must not be locked (Month Locks row with Status = Locked for
  the campus and month).
- Optional detail panel per cell: student, date, status, notes (editable), IEP ratio, absence classification
  and reason (read-only in this build).
- Absences: a new absence has blank classification (= "Not classified"); status shown by colour AND letter:
  P present, A absent not classified, E excused, U unexcused.
- Roles (from the Staff row matched to the signed-in user): Teacher = own students only, cannot pick another
  teacher; Attendance Office = own campus, may pick any teacher at that campus; System Admin = any campus and
  teacher; Read-only = any campus and teacher, view only (no edits). No Staff row = "not set up" state.
- Responsive: desktop-first but usable on tablet and phone; phone-friendly Day view for quick single-day entry.
- Keyboard/screen-reader labels, sufficient contrast, non-colour status cues; clear empty, loading and error
  states; unsaved/saving/saved indicators.
- Performance: never load full history; load only the selected teacher + month with delegable filters, using
  Concurrent(); single-row Patch per save; optimistic UI update with rollback on failure.

Approved design decisions (plan approved 2026-09-28):

- One screen (Screen1 = Attendance). No navigation to unbuilt screens.
- Month view: tap cycle blank -> P -> A -> (confirm) clear. Details mode toggle: tap opens the detail panel
  instead of cycling.
- Day view (default when the screen is narrow): list of students for one date with Present / Absent buttons,
  same save rules.
- Snapshots written on every save: Teacher, Campus, School Year, Term, IEP Ratio, Enrollment, Service.
- Record Key text = yyyymmdd|StudentNumber|ServiceCode.
- Aesthetic: "classroom register" — paper RGBA(247,245,240,1), ink navy header RGBA(27,42,65,1) with white
  text, teal primary RGBA(0,110,97,1); status P green RGBA(46,125,50,1), A amber RGBA(178,106,0,1),
  E blue RGBA(21,101,192,1), U red RGBA(183,28,28,1); non-school grey RGBA(222,219,212,1); not-enrolled pale
  RGBA(238,236,231,1). Grid in one horizontally scrolling region so the day header and rows stay aligned;
  student name column visible at the left of the grid.

Data model facts (Dataverse, publisher prefix aaca; see schema/tables.json in the repo):

- Staff: Name, App Role (Teacher / Attendance Office / Read-only / System Admin), Campus (lookup, blank = all),
  User (lookup to Users), Active.
- Enrollments: Student, Campus, Teacher (lookup Staff), Service, School Year, Program (Regular Year / Summer),
  IEP Ratio (No Aide, 1:1, 2:1, 3:1, 4:1), Start Date, End Date (blank = open), Status (Planned/Active/Ended).
- Attendance: Record Key, Date, Student, Service, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio,
  Present (Yes/No), Absence Classification (Excused/Unexcused, blank = not classified; column-secured),
  Absence Reason (lookup, secured), Classified By/On (secured), Notes, Is Deleted (Yes/No), Modified On.
  Unique key: Student + Service + Date.
- Terms: School Year, Campus (blank = all campuses), Term (Q1..Q4, Summer), Start Date, End Date.
  Summer-program enrollments (Program = Summer) only count on Summer-term days; Regular Year enrollments only
  on Q1-Q4 days.
- Calendar Exceptions: Date, Campus (blank = all), Type (Holiday, Break, Staff Development, Closure,
  Make-up School Day). A Make-up School Day makes a weekend date a school day.
- Month Locks: Campus, Month (first of month), Status (Locked/Unlocked), Reason.
- Settings: Key, Value (AllowFutureDates = "false").
- Services: one active row, Service Code "SPED".
- Students: Display Name ("Last, First"), Student Number (STU-000123), Status.
- Audit Events: Summary, Action (Soft Delete, Restore, ...), Entity, Entity ID, Before, After, Reason.

## Capability Inventory

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Scenario(s) | Specialized contract mappings |
| --------------- | ----------------------- | ----------------- | ------------------------ | ------------------ | ----------- | ----------------------------- |
| R-IDENTITY | Role determined from Staff row for the signed-in user; no Staff row = not-set-up state | Security, persistence, and resilience | Current staff record, role flags, campus scope; not-set-up panel when missing | A-LOAD-IDENTITY | S-IDENT-ROLE, S-IDENT-MISSING | N/A |
| R-SCOPE | Teacher sees only own students; office = own campus teachers; admin/read-only = any campus/teacher | Security, persistence, and resilience | Campus and teacher pickers visible/editable only per role; teacher fixed to self | A-PICK-CAMPUS, A-PICK-TEACHER | S-SCOPE-TEACHER, S-SCOPE-OFFICE | N/A |
| R-MONTH | Month/year picker on top | Time and scheduling | Previous/next month and "This month"; reloads data for the new month | A-NAV-MONTH | S-MONTH-NEXT | Temporal ordering=N/A (dates typed Date) |
| R-LOAD | Load only selected teacher + month with delegable filters and Concurrent() | Integration and automation | Enrollments overlapping month, attendance in month, calendar exceptions in month, terms overlapping month, month lock, settings | A-LOAD-MONTH | S-LOAD-MONTH | N/A |
| R-ROWS | Rows = teacher's students active during the month; mid-month transfer shows correct days | Relationships and hierarchy | One row per student with an enrollment for this teacher overlapping the month; per-day eligibility from that enrollment's dates and program | A-LOAD-MONTH | S-ROWS-TRANSFER | N/A |
| R-CELL-STATES | Cell states blank / present / absent, status by colour AND letter (P, A, E, U) | Data lifecycle | Cell text and fill derived from the attendance row (ignoring Is Deleted = Yes) | A-MARK-CELL | S-MARK-PRESENT, S-MARK-ABSENT | N/A |
| R-MARK | Tap to set/cycle; each save writes ONE record via upsert on Student+Service+Date | Data lifecycle | Blank -> Present (create or restore), Present -> Absent (update), with snapshots | A-MARK-CELL | S-MARK-PRESENT, S-MARK-ABSENT, S-MARK-RESTORE | N/A |
| R-CLEAR | Clearing a cell = confirm, soft delete, audit event | Data lifecycle | Absent -> confirm dialog -> Is Deleted = Yes + Audit Event (Soft Delete); cancel leaves row unchanged | A-CLEAR-CELL | S-CLEAR-CONFIRM, S-CLEAR-CANCEL | N/A |
| R-BULK | Mark all present for a day, overrides afterwards | Data lifecycle | For one date: every eligible student with no active record gets Present; existing records untouched; summary receipt | A-DAY-ALL-PRESENT | S-BULK-DAY | N/A |
| R-NONSCHOOL | Non-school days shaded and read-only | Time and scheduling | Weekend (unless Make-up day), outside any term, Holiday/Break/Staff Development/Closure exception for all or this campus | A-VALIDATE-SAVE | S-BLOCK-NONSCHOOL | N/A |
| R-ENROLLED | Days outside enrollment greyed and locked | Relationships and hierarchy | Not-enrolled cells show "–" and cannot be changed | A-VALIDATE-SAVE | S-BLOCK-NOTENROLLED | N/A |
| R-FUTURE | No future dates unless the setting allows | Time and scheduling | Dates after Today() read-only when AllowFutureDates <> "true" | A-VALIDATE-SAVE | S-BLOCK-FUTURE | N/A |
| R-LOCK | Month must not be locked | Workflow and review | Locked month banner (with reason) and all cells read-only | A-VALIDATE-SAVE | S-BLOCK-LOCKED | N/A |
| R-READONLY | Read-only role cannot edit | Security, persistence, and resilience | All save actions disabled for Read-only | A-VALIDATE-SAVE | S-BLOCK-READONLY | N/A |
| R-STATUS | Per-cell saving / saved / failed indicators, retry on failure | Security, persistence, and resilience | Cell save state keyed by student+date; failed save rolls back the optimistic value and shows "!"; tapping retries | A-MARK-CELL, A-RETRY-CELL | S-FAIL-RETRY | N/A |
| R-CONFLICT | Warn on concurrent edit (compare Modified On) | Security, persistence, and resilience | If the server row's Modified On differs from the loaded copy, skip the write, refresh that cell, show a conflict banner | A-MARK-CELL | S-CONFLICT | N/A |
| R-TOTALS | Row totals (days present) and column totals (students present) from the loaded month | Analytics and visualization | Row total = count of Present among the row's active records; column total = count of Present on that date | A-MARK-CELL (observer) | S-MARK-PRESENT, S-CLEAR-CONFIRM | N/A |
| R-DETAIL | Detail panel per cell with notes; classification read-only | Data lifecycle | Details mode: tap opens panel showing student, date, status, IEP ratio, classification + reason, notes input; Save notes patches Notes only | A-OPEN-DETAIL, A-SAVE-NOTES | S-DETAIL-NOTES | N/A |
| R-DAYVIEW | Phone-friendly view for quick single-day entry | App shell and navigation | Month/Day switch; Day view lists eligible students for a chosen date with Present and Absent buttons using the same save path | A-SWITCH-VIEW, A-DAY-MARK | S-DAYVIEW-MARK | N/A |
| R-STATES | Clear empty, loading and error states | App shell and navigation | Loading indicator during loads; "No students for this teacher in <month>" empty state; error banner on load failure | A-LOAD-MONTH | S-EMPTY | N/A |
| R-A11Y | Keyboard navigation, screen-reader labels, contrast, non-colour cues | App shell and navigation | AccessibleLabel on every cell ("Smith, Alex – Sep 14 – Present"), letters on every status, contrast >= 4.5:1 for text | All | All | N/A |
