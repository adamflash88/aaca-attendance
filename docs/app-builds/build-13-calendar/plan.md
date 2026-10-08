# Build 13 plan: Calendar management (System Admin)

Status: **draft for Adam's approval** (2026-10-08). Nothing below is built yet.

## Goal

Manage each campus's school-year calendar in the attendance app instead of Excel, for the current year (fix mistakes)
and future years (build them), and print each campus's calendar in the familiar one-page layout.

Decisions (Adam, 2026-10-08):
- System Admin only for now. Campuses have **separate calendars** (mostly shared, with variances).
- **Print per campus.**
- New day types: **CAA/CAASPP Testing period** (informational) and **Inclement Weather Day** (closed).
- **Quarters never have gaps**: a quarter ends on a Friday and the next starts on the next school day. So "inside a
  quarter or ESY, not a closed day" is exactly "school is in session", and absences count toward the quarter whose
  range they fall in. A gap is a calendar typo (fixed 2026-10-08: Q2 2026-27 started 10/26 instead of 10/19 at all
  three campuses, corrected in Test and Dev).
- Built **before** billing step D.

## Data (existing tables, two small additions)

| Calendar element | Stored in |
|---|---|
| School year (Aug-Jul) | School Years (name, start, end, status Planned/Current/Closed) |
| Q1-Q4, ESY | Terms (per campus) |
| Testing period (range) | Terms, **new Term value "Testing"** (per campus; informational) |
| Holiday / Break / Closed / Work Only (SDD) / Make-up School Day | Calendar Exceptions (per campus, one row per day, name = label) |
| Inclement weather closure | Calendar Exceptions, **new type "Inclement Weather"** (closes the day like Closed) |
| First/Last Day RSY, First/Last Day ESY | derived: Q1 start, Q4 end, ESY start/end |
| Important Dates list | derived: named exception days, consecutive same-name days grouped ("Nov 23 - 27: Thanksgiving Break") |

Code that picks "the term" for a day (attendance Term lookup in the grid save, Add absence, the notice processing flow)
is changed to **prefer Q1-Q4/ESY and ignore Testing**, so the testing period never displaces a quarter.

## Calendar screen (new, nav button "Calendar", System Admin only)

- **Pickers**: School year (incl. "+ New school year"), Campus.
- **Year view**: 12 month grids Aug-Jul (S-S like the Excel calendar), colour-coded with the same legend: First/Last day
  RSY (green), First/Last day ESY (blue), No School/Work (black: holiday, break, closed), Staff Development (purple),
  Testing (orange), Inclement Weather (red), Make-up school day. Non-term days show grey.
- **Edit a day or range**: click a day (or pick From-To) -> panel: type (No school: Holiday / Break / Closed; Staff
  Development; Inclement Weather; Make-up School Day; Clear), name, and apply to this campus or also to other campuses
  (checkboxes).
- **Periods panel**: Q1-Q4, ESY and Testing start/end. Validation: inside the school year; **quarters back-to-back with
  no school-day gap** (Q(n+1) starts the next school day after Q(n) ends); ESY after Q4; testing inside Q1-Q4.
- **Important Dates / Staff Development Days / Quarterly Periods** panels (auto, like the Excel right column).
- **Create next school year**: name + dates; copies the periods and named days from a chosen campus calendar as a
  starting point and pre-fills the rule-based holidays (Labor Day, Veterans Day, Thanksgiving Thu-Fri, MLK Day,
  Presidents Day, Memorial Day, Juneteenth, July 4 observed) - everything else is adjusted by hand.
- **Copy to campus**: replaces another campus's calendar for that school year with this one (confirm, shows what will
  change).
- **Check calendar** (always visible summary): flags quarter gaps/overlaps, missing quarters, holidays on weekends,
  closures on days that already have attendance marks.

Safety rails: locked (billing-closed) months are read-only; changing a day that already has attendance marks asks for
confirmation and shows the count; every change writes an Audit Event.

## View calendar (print)

A print screen laid out like the Excel calendar for one campus and school year: title "2026-2027 AACA Antelope Valley",
legend, 12 months, Important Dates, Staff Development Days, Quarterly Periods, Testing Period. **Print** opens the
browser print dialog (printer or **Save as PDF**, landscape). (A flow that saves/emails a PDF can come later if wanted.)

## Also in this build

- Load the **2026-27 testing period** (03/01/2027 - 05/27/2027, all three campuses) from the PDFs.
- Older years' missing breaks (AV 2025-26 winter/spring recess, CW/OX 2024-25 Dec 30 - Jan 3): left as is (closed
  years; those days are already non-school). The Check calendar panel will show them.

## Build order

A. Schema (Term "Testing", exception type "Inclement Weather") + term-preference fixes (app + processing flow)
B. Calendar screen (year view, day/range editing, periods, important dates, checks, create year, copy to campus)
C. Print screen
D. Load 2026-27 testing periods; test in Dev; promote with the next release.

## Answered (2026-10-08)

1. **All calendar functions are System Admin only** for now, including inclement weather closures.
