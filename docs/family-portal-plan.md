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

## Student profile (added 2026-10-05, PROPOSED - awaiting Adam's review)

Parents get a **read-only child profile** per linked child (staff maintain it). Reference: Adam's old model-driven
"Student" contact form (tabs: Student Information, Contact Information, Guardian Information, Medical,
Administrative). Decisions: parents see **everything** on it (incl. SPED qualifier, case manager, district rep,
aide ratio, CBI release); mask exemption dropped; co-guardians see each other's **name + relationship only**;
staff edit in a new model-driven app **"AACA Student Records"**; initial data via a **CSV template** Adam fills in.

### Schema

New columns on `aaca_student` (one row per student; teachers already read it, which is useful for allergies):

| Column | Type | Notes |
|---|---|---|
| `aaca_middlename` | text 100 | |
| `aaca_gender` | choice | Male, Female, Non-binary, Not specified |
| `aaca_ethnicity` | choice | CALPADS: Hispanic or Latino, American Indian or Alaska Native, Asian, Black or African American, Filipino, Native Hawaiian or Pacific Islander, White, Two or More Races, Declined to State |
| `aaca_preferredcontact` | choice | Any, Email, Phone, Text message |
| `aaca_addresstype` | choice | Home, Mailing, Other |
| `aaca_street`, `aaca_unit`, `aaca_city`, `aaca_state`, `aaca_zip` | text | home address |
| `aaca_allergies`, `aaca_dietaryrestrictions` | memo 2000 | |
| `aaca_medicalreleaseonfile` | bool | |
| `aaca_nextgrade` | choice | same values as Grade |
| `aaca_ieptype` | choice | Initial, Annual, Triennial, Amendment, 30-Day Interim |
| `aaca_iepdate` | date | Current active IEP date |
| `aaca_enrollmentformsonfile` | bool | Current year enrollment forms on file |
| `aaca_spedqualifier` | choice | Autism, Intellectual Disability, Speech or Language Impairment, Other Health Impairment, Emotional Disturbance, Specific Learning Disability, Multiple Disabilities, Orthopedic Impairment, Hard of Hearing, Deaf, Visual Impairment, Deaf-Blindness, Traumatic Brain Injury, Established Medical Disability |
| `aaca_casemanager` -> `aaca_staff` | lookup | |
| `aaca_districtrepname` | text 100 | |
| `aaca_enrollmentyear` -> `aaca_schoolyear` | lookup | |
| `aaca_cbirelease`, `aaca_mediarelease` | choice | Full, Limited, None |
| `aaca_transportation` | bool | Transportation services |
| `aaca_transportcompany`, `aaca_transportphone` | text | |

Already in the schema (not duplicated): first/last name, DOB (age computed in the portal), grade, campus + aide
ratio (active enrollment), school district (current District of Record).

New tables (owned by the campus team, like students):
- `aaca_emergencycontact`: student, name, relationship, phone, priority (1-3).
- `aaca_studentmedication`: student, medication, dosage, frequency/time, sort order.

Guardians: existing `aaca_guardianlink` + `contact`. The link's name holds the guardian's display name (e.g.
"Jose Lopez") so a co-guardian is shown from the link (name + relationship) without exposing their contact row;
the signed-in guardian's own details (email, phone, address) come from their own contact (self scope).

Deferred (later cards): student photo (image column), report cards & transcripts (documents), behavior services.

### Portal
Dashboard child chips become child cards -> `/children/:id` profile: sticky section links (Overview, Home &
emergency, Guardians, Health, School & services), stacked panels, "Something wrong? Contact your campus office".

### Permissions (Guardian web role, read only)
student, emergency contact, medication, enrollment (campus/ratio), District of Record: parental via guardian
link. Other guardians' links: parental via student (fields: name, relationship). Own contact: self.
Reference lookups (campus, staff name, school year, funder name): global read, name column only.

## Related decisions already made (attendance app, same discussion)

- Absences tab + new Transportation tab (daily: both ways / to only / from only / none; pre-filled from
  attendance; unconfirmed blocks month lock); office "Add absence" (no notice) and "Left early" (partial day).
- Classifications are neutral; billing rules per classification (and funder) live in the Billing app later.
- Daily reminders: teachers (unmarked attendance, ~10am), office managers (open items, ~3:30pm), weekly
  escalation to site admins; month cannot be locked with open items.
