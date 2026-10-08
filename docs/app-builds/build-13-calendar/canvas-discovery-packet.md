# Discovery Packet - AACA Attendance build 13 (Calendar), captured 2026-10-08

EDIT mode. Live session synced 2026-10-08 = C:\src\aaca-attendance\app (commit 52cd602 + spinner fix + Testing
exclusion; Terms and Calendar Exceptions refreshed). Earlier packets (build-9/10/12) still apply.

## Calendar Exceptions (get_data_source_schema)
- aaca_name Display **"Description"** (the label, e.g. "Labor Day") - String
- aaca_date "Date" Date; aaca_campus "Campus" lookup (blank = all campuses)
- aaca_type "Type": `'Type (Calendar Exceptions)'` = Holiday | Break | 'Work Only' | Closed | 'Make-up School Day' |
  'Inclement Weather'

## Terms
- aaca_name "Name"; aaca_term **"Term (aaca_term)"**: `'Term (Terms)'` = Q1 | Q2 | Q3 | Q4 | ESY | Testing
- 'Start Date', 'End Date' (Date); 'School Year' lookup; Campus lookup (blank = all campuses)
- Existing code already excludes Testing wherever it picks "the term" for a day.

## School Years
- aaca_name "Name"; 'Start Date', 'End Date'; aaca_status **"Status (aaca_status)"**: `'Status (School Years)'` =
  Planned | Current | Closed (statecode is "Status (statecode)" - not used)

## Campuses: Name, Code (AV/CW/OX), Active. Month Locks: Campus + month (see build 3/5 packets for column names).

## Dev data (2026-27, all three campuses, matches the PDFs)
Q1 8/12-10/16, Q2 10/19-12/18, Q3 1/5-3/19, Q4 3/29-5/28, ESY 6/14-7/23, Testing 3/1-5/27 (2027).
Exceptions per campus: Post-ESY Break 8/3-8/10 (Closed), SDD 8/11, 10/23, 1/15, 4/9 (Work Only), Labor Day, Veterans
Day, Thanksgiving 11/23-27, Winter Recess 12/21-1/4, MLK, Presidents, Spring Recess 3/22-26, Memorial Day, Pre-ESY Break
5/31-6/11, Independence Day 7/5, Post-ESY Break 7/26-30.

## Existing shared state
IsAdminRole, CurrentSchoolYear, ZeroGuid, palette Color* (NEXUS), nav buttons per screen (btn<P>Nav*), NEXUS help panel
(con<P>Help + img<P>NavHelp) - see build-11 scripts. Nav row: buttons Attendance/Students/Absences/Transportation/Staff,
spacer, NEXUS logo.
