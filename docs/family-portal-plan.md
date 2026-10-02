# AACA Family Portal (Power Pages) - plan, 2026-10-02

Status: proposed, awaiting Adam's answers (see "Open questions"). Build in **Dev** first
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
  - `aaca_absencenotice`: student, submitting contact, absence start/end, return date, reason (aaca_absencereason),
    note, status (New / Accepted / Dismissed / Cancelled), campus; submitted-on = createdon (server).
    A flow on create sets campus + owner = campus default team (same model as Set-CampusOwnership.ps1).
- **Web role "Guardian"; table permissions:** contact (self); guardian link (contact scope, read);
  student (parental via guardian link, read, minimal columns: first name + last initial / key not shown);
  absence notice (contact scope: create, read, cancel own future-dated). Web API field allow-lists.
- **Parent pages (v1):** sign in; my children; report an absence; my reports (status, cancel future);
  help (office phone numbers per campus).
- **Office side:** notices appear in the attendance app's Absences tab for that campus, already matched
  (part of the planned Absences/Transportation rebuild).

## Phases

1. Data model + security (guardians, links, notices, web role, table permissions).
2. Site: auth, my children, report absence, my reports, help.
3. Office processing in the attendance app Absences tab.
4. Guardian onboarding: import guardian contacts, send invitations.
5. Cutover from the website form; Spanish; custom domain; production authenticated-user capacity licence.

## Open questions (Adam)

1. Entra External ID external tenant (free up to 50k MAU) OK, or plain local email/password accounts?
2. Where guardian names/emails live today (CodeMetro / SIS / spreadsheet)? Sample export for the import.
3. English + Spanish from day one?
4. Branding (logo, colours from autismacademy.org) and site name.
5. v1 scope confirmed (no attendance view for parents in v1)?

## Related decisions already made (attendance app, same discussion)

- Absences tab + new Transportation tab (daily: both ways / to only / from only / none; pre-filled from
  attendance; unconfirmed blocks month lock); office "Add absence" (no notice) and "Left early" (partial day).
- Classifications are neutral; billing rules per classification (and funder) live in the Billing app later.
- Daily reminders: teachers (unmarked attendance, ~10am), office managers (open items, ~3:30pm), weekly
  escalation to site admins; month cannot be locked with open items.
