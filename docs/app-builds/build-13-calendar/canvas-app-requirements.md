# Canvas App Original Request Contract

Contract version: 1
Target device: Responsive (desktop-first 1366x768, usable at 1024; calendar editing is a desktop task - phone just
needs to not break)
Mode: EDIT (AACA Attendance, app fb649976-33fb-4419-8ee6-132c204df470, Dev env a4c9f4ce-b971-edf2-beba-e3c29552a316).
Source folder: `C:\src\aaca-attendance\app` (= live session, synced 2026-10-08).
Approved plan: `docs/app-builds/build-13-calendar/plan.md` (Adam, 2026-10-08, "approve"; all calendar functions are
System Admin only).

## Original Request (Adam)
"A tab within this app for calendar management. System admin feature only for now. The ability to modify the current
calendar at each campus but also to create future academic year calendars (holidays, staff development days, quarters,
etc.) ... use the app to populate the necessary tables but also a button that allows us to 'View calendar' in the
attached format that can be printed to pdf." Campuses have separate calendars (mostly shared). Print per campus.
Quarters never have gaps: a quarter ends on a Friday and the next starts on the next school day; absences count toward
the quarter whose range they fall in.

## Data (all present in the app; Terms + Calendar Exceptions refreshed 2026-10-08)
- **School Years**: Name ("2026-2027"), 'Start Date', 'End Date' (Aug-Jul incl. ESY), 'Status' (Planned/Current/Closed)
  - column name `'Status (aaca_status)'` style: verify via schema.
- **Terms**: Name ("2026-2027 Q1 (AV)"), `'Term (aaca_term)'` choice `'Term (Terms)'` = Q1 | Q2 | Q3 | Q4 | ESY |
  Testing (new; informational, never a quarter), 'Start Date', 'End Date', 'School Year' lookup, Campus lookup
  (blank = all campuses).
- **Calendar Exceptions**: Name (label shown on the calendar, e.g. "Labor Day"), Date, Type choice
  `'Type (Calendar Exceptions)'` (verify exact option set name) = Holiday | Break | 'Work Only' | Closed |
  'Make-up School Day' | 'Inclement Weather' (new), Campus lookup (blank = all campuses). One row per day.
  Holiday/Break/Closed/Inclement Weather = no school; Work Only = staff development (no students); Make-up = a school
  day on a normally closed day.
- **Campuses** (Name, Code AV/CW/OX), **Month Locks** (campus + month closed for billing), **Attendance** (Date,
  Campus, Is Deleted), **Audit Events**.
- Named formulas available: IsAdminRole, CurrentSchoolYear, palette Color*, ZeroGuid.
- Dev data: 2026-27 for AV/CW/OX matches the PDFs (Q2 start fixed to 10/19); testing periods 3/1/2027-5/27/2027 loaded.
  Reference PDFs (outside repo): OneDrive `AACA-Attendance\data\AACA <AV|CW|OX> Calendar_2026_2027*.pdf`.

## Scope

### A. NEW CalendarScreen (System Admin only; others see the "not available for your role" panel)
Same header/nav/NEXUS help as the other screens; nav gets a NEW "Calendar" button (IsAdminRole) on every screen.
1. **Pickers**: School Year (dropdown, newest first, default CurrentSchoolYear) and Campus (dropdown; per-campus).
   Load engine reads that year's Terms (campus + all-campus rows) and Calendar Exceptions (date in the year, campus or
   all-campus) and the campus Month Locks.
2. **Year view** (main column): 12 month grids, August..July of the school year, Sunday-first like the PDF
   (month title band, S M T W T F S header, 6x7 day cells). Day colours (calendar legend shown above):
   First/Last day RSY = Q1 start and Q4 end (green), First/Last day ESY (blue), No School/Work = Holiday, Break, Closed
   (black, white text), Staff Development = Work Only (purple), Testing start/end (orange), Inclement Weather (red),
   Make-up School Day (green outline), weekdays outside any quarter/ESY (grey), weekends plain muted text. Today
   outlined. Clicking a day selects it (sets the edit panel's From date; a second click on another day sets To).
3. **Edit panel** (right column): From, To (default = From), Type (No school: Holiday / Break / Closed; Staff
   Development; Inclement Weather; Make-up School Day; Clear), Name (required unless Clear), "Also apply to" campus
   checkboxes (other campuses). Save applies to every weekday in the range (Make-up also allows Saturday) for this campus
   and the ticked ones: existing exception for that date+campus -> Patch type/name; none -> create; Clear -> remove the
   row (no-op if none). Guards: no change in a locked month for that campus; for no-school/SDD/inclement types, count
   non-deleted Attendance rows on those dates/campuses and, if any, require a confirm tick ("12 attendance marks exist on
   these days; they will no longer count"). One Audit Event per save (summary JSON of dates/campuses/type/name and
   counts). Receipt.
4. **Periods panel**: Q1, Q2, Q3, Q4, ESY, Testing start/end (date pickers prefilled). Save Periods validates:
   inside the school year; Q1 < Q2 < Q3 < Q4 < ESY; **Q(n+1) starts on the next school day after Q(n) ends** (skip
   weekends and the campus's no-school days); Testing inside Q1 start..Q4 end. Then upserts the six Terms rows for this
   campus (Name "<Year> Q1 (<Code>)" etc., School Year, Campus, Term). Audit Event. Receipt.
5. **Important Dates** (read-only, like the PDF right column), built from the loaded data: First Day RSY, Last Day RSY,
   First Day ESY, Last Day ESY, each named exception group (same Name + consecutive days -> "Name - m/d/yyyy" or
   "Name - m/d/yyyy - m/d/yyyy"), in date order; **Staff Development Days** ("SDD 1: August 11th, 2026" numbered);
   **Quarterly Periods** ("Qtr.1: 08/12/2026 to 10/16/2026"); **Testing Period**.
6. **Check calendar** (button + result list): missing Q1-Q4/ESY; quarter gap (school days between quarters, listing the
   dates) or overlap; ESY not after Q4; testing outside quarters; no-school types on weekends; no-school days that
   already have attendance marks (count per date). "All good" when nothing found.
7. **Create school year** (dialog/mode): Name (default next "YYYY-YYYY"), Start/End (default previous + 1 year),
   template = the currently shown campus/year. Creates the School Year (Planned) if missing, then for the selected
   campus (and optionally all campuses) copies the template's Terms and Calendar Exceptions shifted by 364 days (same
   weekday) as a starting point, EXCEPT federal holidays which are computed for the new year instead: Labor Day (1st Mon
   Sep), Veterans Day (Nov 11; Sat->Fri, Sun->Mon), Thanksgiving (4th Thu Nov + Fri), MLK Day (3rd Mon Jan), Presidents
   Day (3rd Mon Feb), Memorial Day (last Mon May), Juneteenth (Jun 19 observed), Independence Day (Jul 4 observed).
   Template rows whose Name matches those holidays are not copied. Then opens the new year for review.
8. **Copy to campus**: for the shown year, replace another campus's Terms (Q1-Q4/ESY/Testing) and Calendar Exceptions
   with this campus's (confirm shows how many rows will be removed/added). Audit Event.
9. **View calendar** button -> CalendarPrintScreen for the shown campus/year.

### B. NEW CalendarPrintScreen
One landscape page laid out like the Excel/PDF: title "<Year> AACA <Campus Name>", legend row (First/Last day RSY,
First/Last Day ESY, No School / Work, Staff Development, Testing, Inclement Weather), 12 months in 3 rows x 4 (Aug..Jul),
right column with Important Dates, Staff Development Days, Quarterly Periods, Testing Period. White background, thin
rules, print-friendly sizes. A small toolbar with **Print** (Print() -> browser dialog: printer or Save as PDF) and
**Back**; the toolbar hides while printing (e.g. a variable set before Print() and cleared by a short Timer).

## Non-functional
Same look and patterns as the other screens (NEXUS palette named colours; add calendar legend colours as NEW named
formulas e.g. CalRsy, CalEsy, CalNoSchool, CalSdd, CalTesting, CalWeather, CalMonthBand), header/nav/help unchanged,
engines via Select, IfError on every write + Audit Events. Keep each new screen within a reasonable size; the 12-month
grid should be one gallery of months (WrapCount 4 or 3) with a nested day gallery (42 cells), LoadingSpinner none.
Known traps (canvas-yaml-gotchas memory): never rename/re-parent existing controls; quote ` #` and `: ` outside block
scalars; choice comparisons via the option set; `= Blank()` for choice filters in delegated queries; IfError branch
types match; collections seeded in OnStart if referenced before load.
