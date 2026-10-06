# Canvas App Original Request Contract

Contract version: 1
Target device: Responsive (desktop-first 1366x768, usable at 1024)
Mode: EDIT (AACA Attendance, app fb649976-33fb-4419-8ee6-132c204df470, Dev env a4c9f4ce-b971-edf2-beba-e3c29552a316).
Source folder: `C:\src\aaca-attendance\app` (synced 2026-10-07 = Adam's saved build 8).

## Original Request (Adam, 2026-10-07, "approve")

- "The office is the only one that should be marking the left early entry." Office can record left early even when
  the teacher has not marked the day.
- Manual absences: "the ability within the absences section to create a manual absence entry in the event a parent
  fails to notify us".
- Transportation: "manage which kids have transportation services and how each day was handled (round trip, drop off
  only, pick up only, no transportation)"; "each day must be confirmed by end of day". Initial list loaded from
  CodeMetro (done: 28 Student Transportation rows in Dev); "moving forward ... managed in that transportation section".
  No aides/staff tracking. Billing does not need to know who transported.

## Scope

### A. AbsencesScreen (office/admin = CanClassify; teachers never see this screen)
Add to the existing **Classify absences** view (do NOT re-parent or rename existing controls; add NEW controls; the
view tabs live in the header strip `conAbsHdrTabs` - do not touch them):
1. **Add absence** panel (button opens it in the right-hand detail column, which today shows "Mark as Excused"
   guidance): student picker (students enrolled at the selected campus, search), From / To date (To optional =
   same day; future dates allowed up to Today()+90), Classification (Excused requires an Absence Reason; Unexcused),
   optional note. Save creates one Attendance row per **school day** in the range on which the student has an
   enrollment (school-day rule = the attendance app's: inside a term for the enrollment's campus, weekday or make-up day,
   no closing Calendar Exception; skip locked months - Month Locks). Each row: Present = false, Source = Office,
   Absence Classification + Absence Reason (Excused) / Unexcused, Classified On = Now(), Classified By = current user,
   Notes = the note, Enrollment/Teacher/Campus/School Year/Term/IEP Ratio from the enrollment, Service = the SPED service,
   Record Key = Text(date,"yyyymmdd") & "|" & StudentNumber & "|SPED", Is Deleted = false. Notice Received On stays
   blank (no parent notice). If a non-deleted row already exists that day: present -> set Parent Reported Absent?
   NO - instead skip it and list it in the receipt as "teacher marked present - use Needs a decision / ask the teacher";
   already absent -> skip ("already absent"); deleted row -> reuse it as the absence. Audit Event (Create) per row.
   Receipt lists created / skipped days.
2. **Left early** panel (button): student picker (campus), date (today default, past allowed, no future), time left
   (hour/minute picker or time text h:mm AM/PM), reason (required). Save: if a non-deleted row exists for the day and is
   present -> set Left Early = true, Left Early At (date+time), Left Early Reason; if it is absent -> refuse ("marked
   absent"); if no row -> create the day as present (Present = true, Source = Office, same enrollment fields as above)
   with the left-early fields. Audit Event (Update/Create).
3. Absence rows in the classify list already show source text; add "Left early h:mm AM - reason" display is NOT needed
   here (left-early days are present days, not absences).

### B. Screen1 (Attendance grid) - minimal
- Grid cell for a present day with Left Early = true shows "1" with a distinct small marker (e.g. text "1*" or a
  different fill from the legend palette) and the legend line gains "1* left early (office)". Teachers cannot change it
  (only their own undo of plain 1s as today; a left-early day is office-owned: block undo on it).
- Add a NEW nav button "Transportation" (CanClassify only) in the header nav next to Absences.

### C. StudentsScreen - minimal
- Add a NEW nav button "Transportation" (CanClassify only) in the header nav.

### D. AbsencesScreen nav
- Add a NEW nav button "Transportation" (CanClassify only) in `conAbsNav`.

### E. NEW screen TransportScreen (CanClassify; same header/nav/look; campus picker like Absences: office locked to
their campus via StudentCampusLock, admins choose)
Two views via tabs in the header strip (same pattern as Absences `conAbsHdrTabs`): **Daily** (default) and **Students**.
1. **Daily**: date picker (default Today(); school days; no future), campus. List = students with an active Student
   Transportation row covering the date AND enrolled at the campus that day. Each row: student, usual pattern,
   attendance that day (present / absent / left early h:mm / not marked), and four toggle buttons
   **Round trip / Drop off only / Pick up only / No transportation**. Pre-fill when no Daily Transport row exists:
   absent -> No transportation; left early -> Drop off only; otherwise blank = "Not confirmed" (no default).
   Row shows the saved status and "Confirmed by X at h:mm" once saved. **Confirm day** saves every row of the list
   (all must have a status; button disabled until then) as Daily Transport rows (Log Key = StudentKey|yyyy-mm-dd,
   upsert: update the existing row for that key), Confirmed On = Now(), Confirmed By = current user, Campus, Student,
   Student Transportation link; owner stays the creating user (campus BU). Single-row change after confirmation
   updates that row (re-confirm). Banner at top: "N school days not confirmed" for the last 10 school days at the campus
   (a day is unconfirmed when any listed student lacks a Daily Transport row); click a day to open it.
   Deadline rule shown: "Confirm each school day by the end of the day."
2. **Students**: list of Student Transportation rows at the campus (active by default; toggle "Show ended"): student,
   key, pattern, start-end, source. Actions: **Add** (student picker - campus students without an active row; start
   date default today; pattern), **Change pattern** (edit pattern + note), **End transportation** (end date, default
   today). Audit Event per write.

## Data sources (add to app: Student Transportation, Daily Transport; others present)
- Student Transportation (`aaca_studenttransport`): Summary, Student, Campus, Start Date, End Date, Usual Pattern
  choice 'Usual Pattern (Student Transportation)' = 'Round trip' | 'Drop off only' | 'Pick up only', Source
  (CodeMetro | Manual), Note.
- Daily Transport (`aaca_transportlog`): Summary, Student, Campus, Student Transportation, Date, Transport Status
  choice = 'Round trip' | 'Drop off only' | 'Pick up only' | 'No transportation', Confirmed On, Confirmed By (Users),
  Note, Log Key (unique).
- Attendance new: Left Early (Yes/No), Left Early At (DateTime), Left Early Reason (Text).
- Staff new: Site Administrator (Yes/No) - not used by the app in this build.

## Non-functional
Same look and patterns as the existing screens (header band, nav, notices/receipts, engines via Select, campus scoping).
AbsencesScreen complexity is 311 (>300 guideline): keep additions lean; consider putting Add absence / Left early into
the existing right-hand detail column. Known traps (canvas-yaml-gotchas memory) incl.: never re-parent or rename
existing controls; Studio may reorder root children on compile - anything that must stay on top belongs inside the
header container; quote ` #` and `: ` values; Yes/No columns are Booleans; `= Blank()` for choices in delegated filters.
All writes IfError + Audit Events.
