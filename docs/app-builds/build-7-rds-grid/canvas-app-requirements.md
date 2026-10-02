# Canvas App Original Request Contract

Contract version: 1
Target device: Tablet layout, responsive (desktop-first 1366x768, usable at 1024)
Mode: EDIT (existing app "AACA Billing", app id 1d5dc650-cc68-4a25-8f71-a7cb591ed3c7, Dev environment
a4c9f4ce-b971-edf2-beba-e3c29552a316). Source folder: `C:\src\aaca-attendance\billing-app` (HomeScreen, FundersScreen,
ServicesScreen, StudentsScreen built in build 6; plans in docs/app-builds/build-6-billing-foundations).

## Original Request

"I want to see the RDS grid" (Adam, 2026-10-01). Approved design (verbatim from the project brief and decisions):

- Register of Daily Services (RDS) grid: "For a chosen student, funder and month, the app shows a grid similar in look
  and feel to our attendance grid. It has one row per service and one column per day of the month, with totals."
- "The first row(s) are attendance (days present/absent), shaded to distinguish excused from unexcused absences. For
  school-district-funded students, this includes the Special Education row and any aide/BII/TA/HNS rows that are
  authorized that month."
- "Beneath those, every clinical service rendered that month is a line item showing minutes per day and a monthly total."
- "Regional-center-funded grids show only regional-center-funded clinical services and no school-day attendance rows.
  District and private-pay grids show only the non-regional-center services."
- "Non-school days (weekends and holidays, which vary by campus location) are visually shaded, except for services such
  as FT that are billable on non-school days." (Services.'Billable on Non-School Days' = true: 605 BA/MA/AMA, FT, FTA.)
- "The grid is what districts see, so it must be clean, accurate, and printable."
- Decisions: SAI (Special Education) is paid by the student's District of Record. Day services (1:1 Aide, BII, TA,
  BII TA, HNS) bill as days "mirroring attendance": a day counts when the student was present and the Student Services
  row covers that date; each Student Services row is its own grid row (a 2:1 aide = two rows). Clinical minutes come from
  Service Deliveries (CodeMetro, summed per student + funder + service + day); hours = minutes / 60 (decimal).
- Billable absences (24-hour notice rule) arrive in Phase 2: this build shows absences as excused/unexcused/unclassified
  only, with a caption saying billable-absence flags are coming. Month close, QuickBooks export and PDFs are later
  phases: no buttons for them.

## Screen in scope

New screen `RdsScreen` (file RdsScreen.pa.yaml) + a NEW nav button "RDS Grid" in the header nav of all four existing
screens (add new controls only — never move/re-parent existing ones; renaming is not needed).

1. Pickers (top): Month (month + year, default = the latest month that has Service Deliveries, else this month; Prev /
   Next buttons), Funder (dropdown of active funders that have something in the month: Service Deliveries in the month,
   or Districts of Record / Student Services overlapping the month; label "ABBR – Full name (type)"), Student (dropdown of
   students who have something for that funder in the month; label "Last, First (KEY)"). Changing month or funder keeps
   the student if still valid.
2. Header block (looks like a document): "Register of Daily Services", student name + key, funder abbreviation + full name
   + type, month name + year, campus (from the student's enrollment overlapping the month; "Regional Center Only" for RC
   students), district of record for the month.
3. Grid: first column = row label (service code + name, "#n" when a service has several rows), then one column per day
   1..last day of month (header: day number + weekday letter), then Total column(s).
   - Row A, only when the funder is NOT a Regional Center and it is the student's District of Record for some part of
     the month: "SAI – Special Education" from Attendance (not Is Deleted). Cell: "1" present; "0" absent filled green
     (Excused) / red (Unexcused) / plain (not classified); blank when no record. Total: present days; also show
     "absent n" in the total cell's second line.
   - Day-service rows (funder not Regional Center): Student Services for the student + funder, Excluded = false, service
     Kind = School Day, overlapping the month. Cell "1" when the student is present that day and the date is inside the
     row's Start/End; blank otherwise. Total: days.
   - Clinical rows: Service Deliveries for student + funder in the month grouped by service (sorted by service Sort Order).
     Cell = minutes that day. Total = minutes, plus hours (2 decimals) and the service's billing unit. Services with
     Billable = false show "not billable" in muted text.
   - Non-school days: weekend or campus calendar non-school day (same rule as the attendance app: inside a term for the
     campus, not weekend unless a Make-up School Day, not a Holiday/Break/Closed/Work Only exception for that campus or
     all campuses) are shaded grey on all rows except rows whose service is Billable on Non-School Days. RC-only students
     (no campus): weekends only.
   - A clinical cell with minutes on a shaded non-school day for a service that is NOT billable on non-school days is
     flagged amber (review), with a legend entry.
4. Footer: legend; "Totals: SAI n days · <service> n days … · clinical n min (h.hh h)"; data note: latest CodeMetro
   upload name, date range, "Rows in = matched + exceptions" tie-out from CodeMetro Uploads; count of Open Upload
   Exceptions dated in the month (text only).
5. Empty states: no funder/student selected; no rows for the selection.
6. Same access gate as the other screens; read-only screen (no writes).

## Non-functional

- Same visual language and patterns as the build 6 screens (read docs/app-builds/build-6-billing-foundations/
  canvas-app-shared.md and an existing screen, e.g. StudentsScreen.pa.yaml). The attendance app's grid
  (`C:\src\aaca-attendance\app\Screen1.pa.yaml`, galleries of Classic/Button cells, colMonthDays / IsSchoolDay logic at
  the btnAttLoadEngine) is the reference for the day grid and school-day rule.
- Grid must fit 31 days at 1366 wide (narrow day columns ~30px, label column ~220px, totals ~110px); horizontal scroll
  inside the grid container below that; printable look (white panel, thin rules).
- Data volume per selection is small; load into collections when month/funder/student change (filters on date range and
  lookups must be delegable: use With() scalars and `= Blank()` for choices). Funder/student option lists are built from
  month-filtered collections (Service Deliveries for one month ~3,000 rows: raise/assume Data row limit 2000 is NOT
  enough — build the option lists with delegable Distinct-free patterns, e.g. ClearCollect of the month's deliveries
  selecting only Student and Funder ids in pages, or GroupBy on a month collection loaded with ForAll over funders).
  Planner: choose a delegation-safe approach and state it.
- Known traps (memory canvas-yaml-gotchas): quote values containing ` #` or `: `; no symbol glyphs; IfError branch types
  match; `= Blank()` for choice filters; never re-parent controls; Yes/No columns are Booleans.

## Data sources

Present: Funders, Funder Aliases, Services, Service Aliases, Districts of Record, Student Services, Students, Staff,
Campuses, Users, Audit Events, Enrollments. Being added by the user: Service Deliveries, Upload Exceptions, CodeMetro
Uploads, Attendance, Calendar Exceptions, School Years, Terms.

## Out of scope

Billable-absence flag, CodeMetro upload UI, exceptions screen, month close, QuickBooks export, PDF.
