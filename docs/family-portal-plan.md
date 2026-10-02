# AACA Family Portal (Power Pages) - plan, 2026-10-02

Status: approved 2026-10-02 (see "Decisions"). Phase 1 schema + roles deployed to Dev 2026-10-02; campus flow
(`flows/Absence-Notice-Campus.md`) to be built by Adam; web role + table permissions move to Phase 2 (need the site). Build in **Dev** first
(env https://org42baa05f.crm.dynamics.com, same Dataverse as the attendance and billing apps).
Tooling: Microsoft `power-pages` Claude Code plugin (installed 2026-10-02): create-site (code site / SPA),
setup-datamodel, setup-auth, create-webroles, integrate-webapi, audit-permissions, security-review,
activate-site, deploy-site.

## Why

Parents report absences on the website form today -> SharePoint "Student Absence Log". They type the child's
name, which causes mismatches ("Needs review"), and every office user with list access can read every campus's
reports. Goal: parents never type who the child is, only see their own children, and reports land in Dataverse
under the student's campus (existing campus security applies), with a server timestamp for the 24-hour
billable-notice rule (notice < 24h before 9:00am PT school start, or none = billable).

## Design

- **Site:** "AACA Family Portal", Power Pages code site, English (+ Spanish TBD).
- **Sign-in:** Microsoft Entra External ID (email one-time passcode; optional Google/Microsoft) with
  **invitation-only registration**: an office-issued invitation links the guardian (Contact) to their student(s).
- **Data (new):**
  - Guardian = built-in `contact`.
  - `aaca_guardianlink`: contact <-> aaca_student, relationship, can report absences, active.
  - `aaca_absencenotice`: student, submitted by (contact), first/last day absent (full days only in v1), reason
    (aaca_absencereason), note, status (New / Accepted / Dismissed / Cancelled), campus, processed on/by;
    submitted-on = createdon (server). A flow on create checks the guardian link, sets campus + owner = campus
    default team (same model as Set-CampusOwnership.ps1) and the summary name.
  - Portal shows students by first name only (no last-initial column needed).
- **Web role "Guardian"; table permissions:** contact (self); guardian link (contact scope, read);
  student (parental via guardian link, read, minimal columns: first name + last initial / key not shown);
  absence notice (contact scope: create, read, cancel own future-dated). Web API field allow-lists.
- **Parent pages (v1, confirmed 2026-10-02):** sign in; parent dashboard (card/tile layout built to take
  more features later, e.g. my reports, attendance, documents); report an absence. Deferred: my reports
  list/cancel, help page, attendance view.
- **Office side:** notices appear in the attendance app's Absences tab for that campus, already matched
  (part of the planned Absences/Transportation rebuild).

## Phases

1. Data model + security (guardians, links, notices, web role, table permissions).
2. Site: auth, my children, report absence, my reports, help.
3. Office processing in the attendance app Absences tab.
4. Guardian onboarding: import guardian contacts, send invitations.
5. Cutover from the website form; Spanish; custom domain; production authenticated-user capacity licence.

## Decisions (Adam, 2026-10-02)

1. Sign-in: **Entra External ID** external tenant (email one-time passcode).
2. Guardian data: no formal repository; Adam's **student enrollment web app** holds most/all parent emails
   and is the likely source for the Phase 4 import.
3. **English first**; Spanish in Phase 5.
4. v1 scope: **login, parent dashboard (extensible), absence reporting** only.

## Open questions (Adam)

1. Branding (logo, colours from autismacademy.org) and site name.
2. Enrollment web app: where it stores parent emails (Dataverse table? SharePoint? other) for the import.

## Related decisions already made (attendance app, same discussion)

- Absences tab + new Transportation tab (daily: both ways / to only / from only / none; pre-filled from
  attendance; unconfirmed blocks month lock); office "Add absence" (no notice) and "Left early" (partial day).
- Classifications are neutral; billing rules per classification (and funder) live in the Billing app later.
- Daily reminders: teachers (unmarked attendance, ~10am), office managers (open items, ~3:30pm), weekly
  escalation to site admins; month cannot be locked with open items.
