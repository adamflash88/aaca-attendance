# Phase 2 plan: absences into Dataverse + billing rules

Status: **approved by Adam 2026-10-07** (with the answers under Open questions).

## Goal

One pipeline for absences, owned by AACA rather than SharePoint formulas:

**parent website form / office entry -> Absence Notice (Dataverse) -> attendance days -> billing rules (finance-managed)
-> Billing Day results -> RDS grid**

Decisions already made (Adam, 2026-10-07):
- Move the parent-report pipeline from SharePoint to Dataverse; finance works from the apps (no SharePoint writes).
- New website intake flow lives in the AACA Attendance solution (Test now, production at go-live); the website gets
  the new URL at cutover. The second absence list on the AutismAcademy site is retired too.
- Keep the campus "ABSENCE ALERT" Teams cards; add an "Open in app" link.
- Billability does not depend on Excused / Unexcused (that is about the merits of the absence only).
- Holidays and closures are never billable (campus calendar, not plain weekdays).
- Office staff stop using the parent form; they record parent calls/emails in the app with the time they were told.
- Return Date is required on the website form (blank is still treated as a one-day absence, defensively).
- Transportation rules: Adam will decide later; TA keeps billing on present days until then.

## Today's rule, as found (SharePoint calculated columns)

Billable Through Date = day notified (+1 day if notified after 9:00 AM). Billable Days = weekdays from Absence Date to
min(Return Date, Billable Through Date + 1). Equivalent per-day rule: **an absence day is billable when the notice
arrived less than 24 hours before its 9:00 AM start.** Known gaps fixed by this design: holidays counted as school days;
blank Return Date = 0 days; text-date parsing; multi-month absences booked to the start month; days the student actually
attended still counted; absences entered without a parent report never counted.

## 1. Data model (schema/tables.json)

**Absence Notice** (`aaca_absencenotice`, exists from the family-portal design; extended):
| New column | Purpose |
|---|---|
| Reference (autonumber `ABS-{yyyy}-{000000}`) | the serial the old flow wrote to Title |
| Source (choice) | Website form, Office, Family portal, SharePoint import |
| Notice At (date/time) | **official notice time for billing**: flow receive time (website), entered call time (office), Created (portal), Date Notified (import) |
| Website Submitted At (date/time) | the website's own `DN` stamp, for reference |
| Return Date (date) | as given (exclusive); Absence End stays = last day absent |
| Typed First / Last Name, Typed Campus (text) | what the parent typed (kept for Mapping Errors) |
| Parent Name, Relationship (text), Reason Text (memo) | from the form |
| Match Status (choice) | Matched, Unmatched, Ambiguous, Mapped by office |
| Match Detail (text) | why it did not match / who mapped it |
| Days Created / Skipped / Conflict (int), Error Detail (text) | processing result (replaces Report Decision for new notices) |
| Legacy Item ID (int, alternate key) | SharePoint item ID for imported history |

Existing Status (New / Accepted / Dismissed / Cancelled), Student, Campus, Absence Reason, Processed On/By are reused.

**Attendance**: new lookup **Absence Notice** (which notice produced the day). Notice Received On stays (copied from the
notice). Source Report ID stays for history.

**Campus**: new text **Absence Teams Chat ID** (the three group chats, set per environment).

**App Settings**: `AttendanceAppUrl` (per environment, used by "Open in app").

**Billing Rule** (`aaca_billingrule`, billing table, finance-owned):
Name, Applies To (Absence; Transportation reserved), Rule Type (Late notice, No notice), Notice Hours (24), School Start
Time (09:00), Time Zone (Pacific), Result (Billable, Not billable, Needs review), Units (1 / 0.5), Funder Type (optional),
Effective From / To, Priority, Active, Note. Services it applies to: **Billing Rule Service** rows (rule + service; seed rules start with SAI, finance adds more).

**Billing Day** (`aaca_billingday`, billing table, written by the engine):
Student, Date, Service, Funder (district of record that day), Attendance row, Billing Status (Billable absence, Not
billable absence, Present, Needs review), Units, Rule applied, Reason text, Computed On. Alternate key
student|service|date. Locked months are never rewritten.

Security: Office gets Absence Notice create/read/write (Local); Billing Rule / Billing Day only in AACA Finance; campus
teams own notices.

## 2. Flows (solution, Test then production)

1. **AACA - Website Absence Intake** (HTTP, anyone; replaces the Default-environment "AbsenceAlert" flow):
   validate (names, campus in the 3 known, dates parse, return >= absence; otherwise 400 and nothing saved) ->
   match student: active student, same campus, first + last name compared ignoring case, extra spaces and hyphen/space
   differences; exactly one = Matched, none = Unmatched, several = Ambiguous -> create Absence Notice (Notice At = time
   received) -> Teams card to the campus chat (same layout + "Matched to <student>" or "Could not match - needs mapping
   in the app" + **Open in app** button) -> 200 to the website.
2. **AACA - Absence Notice Processing** (Dataverse trigger on notices that are Matched/Mapped and New; replaces the
   SharePoint intake engine): one 0 per **school day** from Absence Date up to (not incl.) Return Date where enrolled;
   teacher already marked present -> conflict flag (Needs a decision), never overwritten; deleted row -> revived; sets
   Notice Received On + Absence Notice lookup on each day; writes the result back on the notice (Accepted or error).
3. **AACA - Billing Rules Engine** (child flow, called on attendance/notice changes, nightly for open months, and from
   the billing app's "Re-apply rules" button): for each absence day, the first active rule (by priority, effective on
   that date) that matches decides Billable / Not billable / Needs review for the rule's services; present days write
   Present. Upserts Billing Day rows; skips locked months.
4. **Retired at cutover**: SharePoint intake trigger + child + backfill flows, the Default-environment website flow, and
   (once nothing reads the Student Directory list) the two directory-sync flows.

## 3. Attendance app changes

- **Mapping Errors** reads Absence Notices (Unmatched / Ambiguous) instead of the SharePoint list; Map student sets the
  notice's student (Mapped by office) and processing runs; Dismiss sets Dismissed with a reason.
- **Classify absences** shows the notice details (reason, parent, relationship, notice time, reference).
- **Add absence** gains "How did we hear about it?": *Parent notified us* (date + time, default now, not future) or
  *No notice*. It creates an Absence Notice (Source Office) and the days, linked.
- **Open in app**: the app opens on Absences when launched with `?screen=absences` (StartScreen reads Param).
- User guide updated (NEXUS knowledge) for the new Add absence question and Mapping Errors.

## 4. Billing app changes

- **Billing Rules** screen: list, add/edit, effective dates, active toggle, services; "Re-apply rules" (open months).
- **RDS grid**: billable absences marked on the SAI row (legend: billable absence) with totals "absent n, billable n";
  tapping a cell shows the Billing Day reason (rule, notice time vs deadline).
- Seed rules: *Late notice* (24 h before 09:00, Billable, SAI) and *No notice* (Billable, SAI).

## 5. History import + comparison report

- Import every Student Absence Log item into Absence Notices (Source SharePoint import, Legacy Item ID, Notice At from
  Date Notified, student from the existing Report Decision / Matched_Student), and link the existing attendance days via
  Source Report ID.
- Run the engine for all open months.
- **Comparison report** (Excel in OneDrive `AACA-Attendance\data`, never the repo - it has student names): per notice,
  SharePoint Billable Days vs new Billable Days and the reason for each difference (holiday/closure, blank return date,
  student attended, multi-month split, no report).

## 6. Cutover (Test, then the same at production go-live)

1. Deploy schema, security, flows (off); import history; run the engine; Adam + finance review the comparison report.
2. Turn on Website Absence Intake; update the website form's URL to the new flow (whoever maintains the website).
3. Turn off: Default-environment AbsenceAlert flow, SharePoint intake flows. SharePoint list becomes read-only history.
4. Promote the app/solution version with the Absences and billing changes.

## Open questions (answered 2026-10-07)

1. Billable absences can bill services beyond SAI: **finance will supply the absence billing rules per service.** The
   rule's service list (Billing Rule Services) is therefore part of every rule; the seed rules start with SAI only and
   finance adds services as the rules are confirmed.
2. Teams card for office-entered notices too: **yes** (same campus chat, Source shown on the card).
3. Website URL change at cutover: **Adam.**
4. Student Directory list: **retires**, with its two directory-sync flows.

## Build order (each step approved/tested before the next)

A. Schema + security (Dev) -> B. Website intake + processing flows (Dev, tested with fake submissions) -> C. Attendance
app Absences changes -> D. Billing rules, engine, Billing Rules screen, RDS marks -> E. History import + comparison report
-> F. Promote to Test, cutover.
