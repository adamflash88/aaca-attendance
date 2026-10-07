# Canvas App Original Request Contract

Contract version: 1
Target device: Responsive (desktop-first 1366x768, usable at 1024)
Mode: EDIT (AACA Attendance, app fb649976-33fb-4419-8ee6-132c204df470, Dev env a4c9f4ce-b971-edf2-beba-e3c29552a316).
Source folder: `C:\src\aaca-attendance\app` (synced 2026-10-06 = Adam's saved build 9, committed e6b59f3).

## Original Request (Adam, 2026-10-06, "I approve")

- "build a staff tab within the app that will allow office managers to manage the teachers ... add teachers and
  retire teachers ... bulk transfer a class to a new teacher."
- "office managers should only be able to add students and teachers."
- "Bulk transfers would be in the context of a classroom getting a new teacher ... new enrollments for each student
  where the aide ratio is the same but the teacher name is new."
- No access-removal feature: terminated staff lose their Microsoft 365 account (and so group membership).
- Access to the environment/app comes from security groups (pilot group now; a dynamic "AACA Attendance Users" group
  later). Dataverse role + campus come from the Staff row: a scheduled flow (built outside the app) links new Staff
  rows to their user account by Email, moves them to the campus business unit and grants AACA Teacher only.

## Scope

### A. NEW screen StaffScreen (CanManageStudents = office + admin; same header/nav/look as TransportScreen)
Campus picker like Transportation: office locked to their campus (StudentCampusLock), admins choose any campus.
Toggle "Show retired" (default off). Search box (name or email).

**List** (gallery, left/main column): staff whose Campus = selected campus (admins: also an "All campuses" option is
NOT needed). Columns: Name, Email, Role (App Role text), Students now (count of open enrollments with this teacher
covering Today() or starting later: End Date blank or >= Today()), Account ("Linked" when User is set, else
"Waiting for account"), Status (Active / Retired since mmm d, yyyy). Sort by Name. Retired rows (Active = No) only
when the toggle is on, greyed. Selecting a row selects that person (varStfSelId).

**Right-hand panel** (same pattern as Students: guidance when idle, form when an action is open, receipt after save):
Action buttons for the selected person: Edit, Transfer class (teachers only), Retire (active only). "Add teacher"
button at the top of the list (always available).

1. **Add teacher**: Name ("Last, First" hint; required), Work email (required, must contain "@" and end with
   "@autismacademy.org"; must not match another Staff row's Email or a linked user's Primary Email - check against
   Staff, case-insensitive), Campus (office: locked to theirs; admin: picker, required), Start date (default
   Today()), Role: office = fixed "Teacher" (no picker); admin = picker of all four App Roles (default Teacher).
   Save: Patch(Staff, Defaults(Staff), {Name, Email: Lower(Trim()), Campus, 'Start Date', 'App Role', Active: Yes,
   'Finance Access': No, 'Site Administrator': No}). User stays blank (the access flow links it). Audit Event Create
   (Entity aaca_staff). Receipt: "Added. They can sign in once they are in the app's security group; their access is
   set up automatically within about 15 minutes of their first sign-in."
2. **Edit**: Name, Email (same validation, excluding self), Start date. Admins may also change Campus and App Role;
   office cannot (show as text). Audit Event Update with Before/After JSON.
3. **Transfer class** (selected person must be an active Teacher with >= 1 student): New teacher picker (active
   Teachers at the same campus, excluding the selected one; required), Effective date (default Today(); allowed range
   Today()-30 .. Today()+90; must not fall in a locked month - Month Locks, same rule as Students Change class),
   optional note. Preview list = the students who will move (each: name, student number, ratio, current start date)
   and those skipped with reason. Per student, using the selected teacher's enrollments that are open on the
   effective date (Start Date <= eff and (End Date blank or End Date >= eff)), same logic as Students "Change class"
   (StudentsScreen engine around line 1812):
   - close the old enrollment: End Date = eff - 1, End Reason = Transfer, Status = Ended if eff <= Today() (else
     unchanged);
   - new enrollment: Name = StudentNumber & " " & Text(eff,"yyyy-mm-dd"), Student, Campus, Teacher = new teacher,
     Service, School Year, Program, IEP Ratio (same as old), Start Date = eff, Status Active/Planned by date,
     Previous Enrollment = closed old one;
   - an enrollment that STARTS after eff with the old teacher (planned, no attendance yet): Patch its Teacher to the
     new teacher instead (no close/new) - listed as "future enrollment reassigned";
   - if eff = the enrollment's Start Date: also just Patch Teacher (avoid a zero-length enrollment);
   - Audit Event Transfer per student (Before/After JSON like Change class, Reason = note or "Class transfer to
     <new teacher>").
   Engine processes students one at a time (ForAll over a collection with IfError per student; one failure does not
   stop the rest) and writes colStfLog; receipt lists Moved / Reassigned / Failed (with error) per student plus totals.
   Attendance rows already recorded on/after eff stay with the old teacher (note this in the form help text).
4. **Retire**: End date (default Today(), not before Start Date). Blocked (button disabled + reason text) while the
   person has open or future enrollments as Teacher: "Transfer their class first (N students)." Save: Active = No,
   End Date. Audit Event Update. Receipt. Also offer **Reactivate** for a retired person (Active = Yes, clear End
   Date) - admin and office.

### B. Nav
Add NEW nav button "Staff" (CanManageStudents only) next to Transportation on Screen1, StudentsScreen,
AbsencesScreen and TransportScreen headers (do not re-parent or rename existing controls).

### C. Active-only teacher pickers (assignment)
- StudentsScreen form teacher dropdown (line ~1266) and colStuTeacherSrc (line ~2513): only Active <> No teachers,
  BUT keep the currently assigned teacher resolvable for display (colStuTeacherSrc is also used to show names:
  add an IsActive field to colStuTeacherSrc instead of filtering it; filter only the form dropdown Items).
- Screen1 teacher picker (line ~539), Screen1 campus OnChange (line ~501), Screen1 OnVisible (line ~22) and App
  OnStart default teacher: active teachers only (default = first ACTIVE teacher at the campus).
- AbsencesScreen teacher filter (colAbsTeacherSrc): unchanged (history).

### D. Sign-in states (App formulas + Screen1 not-set-up panel)
- CurrentStaff: unchanged (linked by User). New formula StaffPending = IsBlank(CurrentStaff) &&
  !IsBlank(LookUp(Staff, Lower(Email) = Lower(User().Email) && Active <> No)) (adapt to the Yes/No type).
- Screen1 lblAttNotSetUpTitle/Body: when StaffPending -> "Your access is being set up" / "Your Staff record was found.
  Access is set up automatically within about 15 minutes of your first sign-in. Close the app and open it again in a
  few minutes." Otherwise the existing text, but change "Ask a System Admin to add a Staff row linked to your Users
  record" to "Ask your office manager to add you on the Staff screen".

## Data sources
- Staff (refreshed 2026-10-06): Name, Email (Text), Start Date, End Date (Date), Active / Finance Access /
  Site Administrator (Yes/No; schema shows OptionSetValue 'Active (Staff)' Yes/No - existing formula uses
  `CurrentStaff.Active <> false`, so it behaves as Boolean; verify in compile), App Role 'App Role (Staff)', Campus,
  User (Users).
- Enrollments, Students, Month Locks, Audit Events, Campuses, Users: as in earlier builds.

## Security (done in Dev 2026-10-06)
Office role: Staff Create/Write/Append Local. Staff rows with a campus are owned by that campus team
(Set-CampusOwnership). Office Enrollment Create/Write Local already exists (Change class).

## Non-functional
Same look and patterns as TransportScreen (header band with tabs strip inside the header container, nav,
notices/receipts, engines via Select, campus scoping). Keep each screen's complexity reasonable (new screen, so fresh
budget). Known traps (canvas-yaml-gotchas memory): never re-parent or rename existing controls; anything that must
stay on top belongs inside the header container; quote ` #` and `: ` values; Yes/No columns; `= Blank()` for
choices in delegated filters. All writes IfError + Audit Events.
