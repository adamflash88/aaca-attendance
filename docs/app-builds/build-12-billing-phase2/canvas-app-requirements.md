# Canvas App Original Request Contract

Contract version: 1
Target device: Responsive (desktop-first 1366x768, usable at 1024)
Mode: EDIT (AACA Attendance, app fb649976-33fb-4419-8ee6-132c204df470, Dev env a4c9f4ce-b971-edf2-beba-e3c29552a316).
Source folder: `C:\src\aaca-attendance\app` (= live session, synced 2026-10-07; build 11 committed e957d43).
Phase 2 plan (approved by Adam 2026-10-07): `docs/app-builds/build-12-billing-phase2/plan.md` section 3 (step C).

## Original Request (Adam, 2026-10-07, "APPROVE" / "Go")

Absence reports move from the SharePoint "Student Absence Log" to the Dataverse table **Absence Notices**. A new
website flow creates notices (Source = Website form), matches the student by name + campus, and a processing flow creates
the attendance 0s for matched notices (status New -> Accepted). Unmatched / Ambiguous notices wait for the office.
Office staff stop using the parent website form: they record calls/emails in the app (Add absence) with the time the
parent told them. Every new notice (website or office) posts a Teams "ABSENCE ALERT" card whose "Open in app" link opens
the app with `screen=absences`.

## Scope (AbsencesScreen + App only; other screens unchanged)

### A. Mapping Errors tab (view "mapping") -> Absence Notices
Today the tab lists SharePoint `Student Absence Log` items with Match_Status = "Needs Review" (colAbsMeSrc, kinds A/B)
plus Report Decisions errors. Change the SOURCE to Absence Notices (keep the existing tab, list/detail layout, Open,
receipts, campus picker and counts; do not rename/re-parent existing controls; add new controls where needed):
- Rows = Absence Notices with Status = New and (Match Status = Unmatched or Ambiguous, or Error Detail not blank),
  campus filter as today (office locked to their campus via Campus lookup; admins choose / all). Two groups:
  "Could not match (n)" (Unmatched/Ambiguous: show typed first/last name, typed campus, Match Detail) and
  "Could not process (n)" (Error Detail not blank). Each row: Reference, typed name, campus, absent First Day Absent ->
  back Return Date, Reason Text, Parent Name + Relationship, Notice At (local time "mm/dd/yyyy h:mm AM/PM").
- **Map student** (detail panel): student picker = students with an enrollment at the notice's campus covering First Day
  Absent (search by name / Student Key), pre-filtered by the typed last name. Save: Patch the notice {Student, Match
  Status = 'Mapped by office', Match Detail = "Mapped by <user> <date>", Error Detail = ""} (status stays New; the
  processing flow creates the days within ~1 minute). Audit Event (Update, Entity aaca_absencenotice). Receipt says the
  days will appear shortly; list reloads.
- **Fix dates** (for "Could not process" rows): edit First Day Absent / Return Date (Return > First Day, max 60 days),
  Patch the notice (Last Day Absent = Return - 1, Error Detail = "") + set Match Status to 'Mapped by office' so the
  flow re-runs. Audit Event.
- **Dismiss**: reason required -> Patch Status = Dismissed, Note = reason, Processed On = Now(), Processed By = current
  user. Audit Event.
- Tab label "Mapping Errors (n)" counts these notices. The SharePoint-based lists/engines stay in the file but are no
  longer shown (hide their containers with Visible false-y expressions; do not delete controls) - they retire at cutover.

### B. Classify absences tab
- Absence rows (and the Needs a decision rows) show the linked notice when 'Absence Notice' is set: Reference, Parent
  Name (Relationship), Reason Text, "notified <Notice At local>". Rows without a notice keep today's text.
  Load the notice fields into the existing colAbs* collection via the Attendance 'Absence Notice' lookup (no per-row
  LookUp in the gallery).

### C. Add absence panel (existing "Add absence" mode)
- New required choice **"How did we hear about it?"**: "Parent notified us" | "No notice" (radio or dropdown).
  When "Parent notified us": date (default Today(), not in the future) + time (h:mm AM/PM text or hour/minute pickers,
  default now) of when the parent told us; validation: the resulting date-time is not in the future.
- Save (existing engine) ALSO creates an Absence Notice first: Summary "<Last, First> - absent <m/d/yyyy>",
  Source = Office, Status = Accepted, Match Status = Matched, Student, Campus, First Day Absent, Last Day Absent,
  Return Date = last day + 1, Reason Text = the note (or the reason name), Parent Name blank, Notice At = the entered
  date-time (Parent notified) or Blank() (No notice), Processed On = Now(), Processed By = current user; owner stays the
  creating user. Then each created/reused Attendance row gets 'Absence Notice' = that notice and Notice Received On =
  Notice At (blank for No notice). Status Accepted means the processing flow does not touch it; the alert flow posts the
  Teams card (Source = Office).
- Receipt adds "Notice: <reference> · notified <time>" or "Notice: no notice (billable)".

### D. App: open on Absences from the Teams link
- `App.StartScreen` = `If(Lower(Param("screen")) = "absences" && CanClassify, AbsencesScreen, Screen1)` (or the
  equivalent supported pattern); everything else unchanged.

## Data sources
- **Absence Notices** (added 2026-10-07; see schema in canvas-discovery-packet.md): Summary (aaca_name), Reference,
  Source 'Source (Absence Notices)' (Website form, Office, Family portal, SharePoint import), Status
  'Status (Absence Notices)' (New, Accepted, Dismissed, Cancelled) column `'Status (aaca_status)'`, Match Status
  'Match Status (Absence Notices)' (Matched, Unmatched, Ambiguous, Mapped by office), Match Detail, Error Detail,
  First Day Absent (aaca_absencestart, Date), Last Day Absent (aaca_absenceend, Date), Return Date (Date), Notice At
  (DateTime UTC), Website Submitted At, Typed First Name / Typed Last Name / Typed Campus, Parent Name, Relationship,
  Reason Text, Note, Days Created / Skipped / Conflict, Processed On, Processed By (Users), Student, Campus,
  Absence Reason, Submitted By (Contact, unused here), Legacy Item ID.
- **Attendance**: new lookup 'Absence Notice' (refreshed 2026-10-07).

## Non-functional
Same look and patterns (NEXUS palette named colors, header nav + NEXUS help unchanged, notices/receipts, engines via
Select, IfError on every write + Audit Events). AbsencesScreen is already very large: keep additions lean, reuse the
existing mapping/detail panel and engines where possible. Known traps (canvas-yaml-gotchas memory): never rename or
re-parent existing controls; tabs strip conAbsHdrTabs untouched; quote ` #` and `: ` outside block scalars; Yes/No
columns are Booleans in formulas; `= Blank()` for choice filters in delegated queries; IfError branch types match.
