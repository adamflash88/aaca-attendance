# Canvas App Original Request Contract

Contract version: 1
Target device: Tablet layout, responsive (desktop-first 1366x768, usable at 1024)
Mode: CREATE (new app "AACA Billing", app id 1d5dc650-cc68-4a25-8f71-a7cb591ed3c7, Dev environment
a4c9f4ce-b971-edf2-beba-e3c29552a316, in solution AACA Attendance). Source folder: `C:\src\aaca-attendance\billing-app`.

## Original Request

Billing Phase 1 ("Foundations") of the clinical services / RDS / QuickBooks project, approved by Adam Bernstein
2026-10-01. The long-term goal (later phases, NOT in this build): upload CodeMetro CSVs of delivered services, show a
Register of Daily Services (RDS) grid per student + funder + month, close a month, export a QuickBooks Online invoice
CSV and generate RDS PDFs. This build creates the app shell and the mapping/admin screens finance needs so that
"finance can maintain them without a developer".

Approved decisions (verbatim from the conversation):

- A separate canvas app, "AACA Billing", shared only with finance (Cesar, Jake) and Adam. "This section of the app must
  not be seen by anyone other then the finance team and myself." Data protection is the AACA Finance security role
  (only it can read billing tables); the app additionally shows a not-authorised panel unless the current user's
  Staff row has Finance Access = Yes.
- QuickBooks Online. QBO assigns invoice numbers. Rates live in QBO: the app never stores or shows rates or dollars.
  Mapping tables: service -> QuickBooks item + billing unit (Days or Hours); funder -> QuickBooks customer. A
  private-pay funder is the parent (QBO customer = parent).
- Funder type (District / Regional Center / Private Pay) decides district-style vs regional-center grids later.
- CodeMetro writes long Funding Source names and messy CPT codes: Funder Aliases and Service Aliases map them. Aliases
  are stored normalised: trimmed, internal runs of spaces collapsed to one, UPPER CASE.
- School days (SAI = Special Education) are paid by the student's "district of record" (Districts of Record table,
  dated). Day services (1:1 Aide, BII, TA = Transportation Aide, BII TA, HNS) bill as days mirroring attendance; each
  Student Services row is one RDS grid row ("if a kid has a 2:1 there would be two aide rows"). These rows are loaded
  from the CodeMetro student-services export (Source = CodeMetro); finance can add Manual rows and can exclude a row.
- Services billable on non-school days: in-home floortime / adaptive skills (605 BA, 605 MA, 605 AMA, FT, FTA).
  No-show codes are not billable.
- Students have a Student Type: School, or Regional Center Only (RC- keys, no attendance). Blank = School.
- Audit trail: every write in this app writes an Audit Events row (entity, entity id, before/after JSON, reason).

## Screens in scope (4)

1. **Home** (`HomeScreen`)
   - App header band "AACA Billing" with navigation buttons Home / Funders / Services / Students on every screen.
   - Access gate: when the current user is not Finance (no Staff row, inactive, or Finance Access <> Yes) every screen
     shows only a "You don't have access to AACA Billing" panel with a one-line explanation and no data.
   - "Needs attention" cards with counts, each navigating to the right screen pre-filtered:
     funders with no QuickBooks customer; active services with no QuickBooks item; active School students with no
     current district of record (no Districts of Record row covering Today()); Private Pay funders created
     automatically from CodeMetro (Funder Type Private Pay and QuickBooks Customer blank).
   - A "Coming next" note listing later phases (CodeMetro upload, RDS grid, month close and QuickBooks export, PDFs)
     as plain text, not buttons.
2. **Funders** (`FundersScreen`) — list + detail.
   - List: search (abbreviation, full name or alias text), filter chips All / District / Regional Center / Private Pay /
     Missing QuickBooks customer, "Show inactive" toggle (default off). Row shows abbreviation, full name, type,
     QBO customer (or "No QuickBooks customer" warning text), alias count.
   - Detail: edit Abbreviation (required, unique case-insensitive), Full Name, Funder Type (required), QuickBooks
     Customer, Active. Save / Cancel. New funder button. No delete (deactivate instead).
   - Aliases section: the CodeMetro names mapped to this funder; Add alias (text input, normalised before save;
     if the normalised text already exists for another funder show "Already mapped to X" and a "Move it here" button;
     if it exists for this funder show a notice); Remove alias (confirm). Aliases explained in one caption line.
3. **Services** (`ServicesScreen`) — list + detail.
   - List: sorted by Kind then Sort Order; filters All / School Day / Clinical / Missing QuickBooks item; Show inactive.
     Row: code, name, kind, unit, QBO item (or warning), small flags "Non-school days", "Not billable".
   - Detail: Service Code (required, unique), Name, Kind, Billing Unit, QuickBooks Item, Billable, Billable on
     Non-School Days, Sort Order, Active. Save / Cancel / New service. No delete.
     The SPED service (code "SPED") is the attendance service: its Code and Kind are read-only.
   - Aliases section: two groups, CPT Codes and Service Names; add (type chosen by which group's Add is used,
     normalised; duplicate handling as for funders: same text + same type mapped elsewhere -> "Move it here");
     remove (confirm).
4. **Student billing setup** (`StudentsScreen`) — list + detail.
   - List: search by name or Student Key (External Client ID); filters All / School / Regional Center Only /
     "No district of record"; status filter Active (default) / All. Row: key, "Last, First", type, current district of
     record abbreviation (or warning "No district of record" for School students), count of active day-service rows.
   - Detail header: key, name, type, status (read-only; this app does not edit students).
   - Districts of Record: rows sorted by Start Date desc: funder, start, end (blank = "ongoing"), source, note.
     Add / Edit (funder picker limited to active District funders, start required, end optional, note); validation:
     end >= start; no two rows for the student may overlap in dates (show the clashing row). Rows from CodeMetro may be
     edited (they become Source = Manual on save) or ended. Delete allowed only for Manual rows (confirm).
     Hidden for Regional Center Only students (show a caption instead).
   - Student Services: rows sorted by service sort order then start: service, funder, start, end, frequency,
     minutes/frequency, ESY, source, Excluded, note. Excluded rows shown muted with "Excluded" badge.
     CodeMetro rows: only Excluded (toggle) and Note editable. Manual rows: Add / Edit (service picker limited to active
     School Day services except SPED; funder picker active funders; start required; end optional) / Delete (confirm).
     A caption explains "Each row is one line on the RDS grid; a 2:1 aide is two rows."

## Non-functional

- Same visual language as the AACA Attendance app (read `C:\src\aaca-attendance\app\App.pa.yaml` and
  `docs/app-builds/build-5-roles-approval/canvas-app-shared.md`): paper page, ink-navy header band, teal accent, named
  colour constants in App.Formulas, ModernText/ModernButton/GroupContainer, responsive scroll root per screen.
- Small data: ~35 funders, ~150 aliases, ~35 services, ~150 students, ~250 student services, ~150 districts of record.
  Load into collections on screen visible / refresh; filter locally; Patch writes then refresh the affected collection.
- Every Patch wrapped in IfError with a visible error notice; success notice after each save.
- All writes produce an Audit Events row (Action Create/Update/Soft Delete as appropriate; Entity = table display name;
  Entity Id = GUID text; Before/After = JSON of the changed fields; Reason short text).
- Text inputs trimmed; alias text normalised with `Upper(Trim(Substitute(...)))` style collapse of double spaces.
- No delete of funders or services. Lookups by GUID, never by display text.
- Known traps (canvas-yaml-gotchas): quote any value containing ` #` or `: `; no symbol glyphs; IfError branches
  must return the same type (end success branch with `; true`); `= Blank()` not `IsBlank()` for choice filters in
  delegated queries; never re-parent controls between compiles.

## Data sources (present in the app)

Funders, Funder Aliases, Services, Service Aliases, Districts of Record, Student Services, Students, Staff, Campuses,
plus (being added by the user) Users, Audit Events, Enrollments.

## Out of scope (later phases)

CodeMetro upload and exceptions, RDS grid, billable-absence flag, month close, QuickBooks export, PDFs.
