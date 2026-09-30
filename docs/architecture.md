# AACA Attendance & Student Services Tracker — Architecture Proposal

Status: **APPROVED** 2026-09-28 — see §10 for the decision log
Owner / pilot: Adam Bernstein

This document is the Milestone 0 deliverable: platform decision, data model, security model,
environment/ALM approach, and the changes to the original brief caused by the answers to the
open questions. Nothing is built until this is approved.

---

## 1. Decisions from the open-question answers

| # | Answer | Design consequence |
|---|---|---|
| 1 | Desktop-first, responsive to any screen; offline nice-to-have | Responsive AutoLayout screens with a phone breakpoint for single-day entry. Offline: see §9 — possible only in the Power Apps mobile/Windows app, not the browser; deferred to Milestone 7. |
| 2 | Only the attendance office staff classify absences | Teachers record Present/Absent only. Classification columns are protected by **column-level security**, so teachers cannot write them even outside the app. |
| 3 | Only one service: Special Education Attendance | A `Service` table is kept (single row) so nothing is hard-coded and a second service can be added later. The app hides the service picker while only one is active. |
| 4 | No aide tracking; only the IEP-mandated ratio | Aide / DefaultAide columns are dropped. `IEP Ratio` choice on the enrollment (No Aide, 1:1, 2:1, 3:1, 4:1), snapshotted on each attendance row. |
| 5 | Year runs Aug–May plus a ~29-day summer program in Jun–Jul; calendars and quarters change yearly | No date rule is hard-coded. `School Year`, `Term` (Q1–Q4, Summer) and `Calendar Exception` tables are maintained each year by the admin. |
| 6 | FERPA applies; data is low-sensitivity | Minimal student fields; teacher isolation is still enforced by Dataverse security, not only in the app. |
| 7 | Dataverse is acceptable | **Platform = Dataverse.** Every SharePoint work-around in the brief (RecordKey text uniqueness, 5,000-item threshold, list archiving, item-level permissions) is replaced by a native feature. |
| 8 | No deadline; Adam is pilot user and developer | Milestones proceed at your pace; sign-off at each. |
| 9 | 3 campuses, 12–15 teachers, 5–15 students each | ≈ 225 students, ≈ 45,000 attendance rows per year. Every in-app query stays well under the 2,000-row delegation limit (§6). |

### What Dataverse changes versus the original brief

| Brief item (SharePoint) | Dataverse replacement |
|---|---|
| `RecordKey` text column with "enforce unique" | Real **alternate key** on (Student, Service, Date). Dataverse rejects duplicates; the app upserts against it. A readable key is still stored as the row name for exports. |
| Stable `StudentID` string used as the join key | Relationships use lookups (GUIDs, never reused). A human-readable **autonumber** Student Number (e.g. `STU-000123`) is kept for display and exports. |
| Item-level permission breaking | **Record ownership + business units + security roles** (§4). This scales natively. |
| Custom AuditLog for every write | **Built-in Dataverse auditing** (before/after, user, time — tamper-proof) plus a small `Audit Event` table for business actions that need a *reason* and must be visible in the app (§3.12). |
| 5,000-item threshold / index management | Not applicable. Dataverse indexes lookups and keys automatically; filters used by the app are all delegable. |
| Annual archive flow to keep the list fast | **Dropped.** At ~45k rows/year, ten years is ~450k rows, which Dataverse handles comfortably. Revisit only if storage costs require it. |
| `StudentPeriodSummary` pre-computed list | **Deferred.** Teacher/student-scoped aggregates fit in-app (≤ ~1,000 rows). Campus/org-wide reports use Dataverse views, Excel export or Power BI. Re-evaluated at Milestone 5. |

---

## 2. Environments, solution and ALM

| Item | Proposal |
|---|---|
| Dev environment | New **Developer** environment with Dataverse (free for the developer), e.g. `AACA Attendance – Dev`. The existing app (`1c7270fe…`) lives in the **Default** environment and holds no content; I recommend leaving it and creating the real app inside the solution in Dev. |
| Test / Prod | Sandbox (Test) and Production environments added before UAT (Milestone 7). Deployed as a **managed solution**. |
| Solution | `AACAAttendance` (unmanaged in Dev). Publisher `AACA`, prefix **`aaca_`**. Contains tables, choices, security roles, column-security profile, canvas app, flows, connection references and environment variables. |
| Source control | Git repository **outside OneDrive** (OneDrive sync and `.git` folders conflict) at `C:\src\aaca-attendance`, with a private **GitHub** remote. Solution exported and unpacked with `pac solution clone` / `pac solution sync`; canvas app source kept as `.pa.yaml`. |
| Tooling | Installed: git, .NET 10, PnP.PowerShell. Needed: **Power Platform CLI** (`dotnet tool install --global Microsoft.PowerApps.CLI.Tool`). |
| Licensing | Dataverse from a canvas app is a **premium** capability: every user (teachers, office, read-only) needs Power Apps Premium or a per-app licence in Test/Prod. The Developer environment is free for you. |

Proposed repository layout:

```
aaca-attendance/
  docs/            architecture, test plan, admin & user guides, known limitations
  schema/          tables.json — single source of truth for tables/columns/choices/keys
  provisioning/    Deploy-Schema.ps1 (creates schema from schema/tables.json via Dataverse Web API)
  seed/            New-SeedData.ps1 — fake campuses/staff/students/full-year attendance
  solution/        unpacked AACAAttendance solution (pac solution sync output)
  app/             canvas app .pa.yaml sources (coauthoring sync folder)
  flows/           flow definitions + build notes
  tests/           test cases and UAT scripts
```

---

## 3. Data model (Dataverse)

Conventions: logical names `aaca_<name>`; Date-only columns use **Date Only / Time-zone independent**
behaviour (avoids UTC day-shift bugs); every table has built-in Created/Modified By/On and Owner;
auditing enabled on every table.

### 3.1 Campus — `aaca_campus`
| Column | Type | Notes |
|---|---|---|
| Name (primary) | Text 100 | |
| Code | Text 10 | Alternate key |
| Active | Yes/No | |

Each campus maps to a business unit (§4) configured by the admin.

### 3.2 Staff — `aaca_staff`
| Column | Type | Notes |
|---|---|---|
| Name (primary) | Text 100 | Display name |
| User | Lookup → User (systemuser) | Alternate key; links to M365 SSO identity |
| App Role | Choice: Teacher, Attendance Office, Read-only, System Admin | Drives UI only; **security comes from security roles** |
| Campus | Lookup → Campus | Blank = all campuses |
| Active | Yes/No | |

The nightly integrity check flags any Staff row whose App Role disagrees with the user's assigned security role.

### 3.3 Student — `aaca_student`
| Column | Type | Notes |
|---|---|---|
| Display Name (primary) | Text 200 | "Last, First" — set by app on save; verified by integrity check |
| Student Number | **Autonumber** `STU-{SEQNUM:6}` | System-generated, never reused; alternate key |
| First Name / Last Name | Text 100 | Trimmed and normalized on save |
| Date of Birth | Date only | |
| Grade | Choice: K, 1–12, 12+ | 12+ = post-12 / transition |
| External Client ID | Text 50 | Optional |
| Status | Choice: Active, Inactive, Archived | |
| Archived On / Archived By | Date only / Lookup → User | |

Duplicate detection on save: same normalized First + Last + DOB → warning with link to the existing record.

### 3.4 Service — `aaca_service`
Name, Service Code (alternate key), Billing Code, Active. One seeded row: *Special Education Attendance* (`SPED`).

### 3.5 School Year — `aaca_schoolyear`
| Column | Type | Notes |
|---|---|---|
| Name (primary) | Text | "2026-2027" |
| Start Date / End Date | Date only | Whole year **including** the summer program, e.g. Aug 12 2026 – Jul 30 2027 |
| Status | Choice: Planned, Current, Closed | |

**Assumption A1 (unconfirmed — defaulted):** the Jun–Jul summer program belongs to the school year that ends in May (summer 2027 is part of 2026-2027). This only affects which year's totals and reports summer days fall under; it is a data rule, so it can be changed later without schema changes.

**Summer program enrollments:** summer (29 days, Mon–Fri) is its own Term, and students get **separate summer enrollments** so a student can have a different teacher or ratio in summer, and non-attending students simply have none. Because most students attend, the Admin "Summer roster" tool pre-selects every student active at the end of Q4. Office staff untick the students who aren't attending, preview, and commit.

### 3.6 Term — `aaca_term`
School Year (lookup), Campus (lookup, **blank = all campuses**), Term (Choice: Q1, Q2, Q3, Q4, Summer), Start Date, End Date.
Validation: terms in one year/campus must not overlap and must fall inside the school year.

### 3.7 Calendar Exception — `aaca_calendarexception`
| Column | Type | Notes |
|---|---|---|
| Date | Date only | |
| Campus | Lookup → Campus | Blank = all campuses |
| Type | Choice: Holiday, Break, Staff Development, Closure, **Make-up School Day** | A make-up day turns a weekend into a school day |
| Description | Text | |

**School-day rule:** a date is a school day for a campus when it falls inside a Term **and** (it is Mon–Fri with no non-school exception **or** it has a Make-up School Day exception). Days between terms (for example between May and the summer program) are automatically non-school days.

### 3.8 Enrollment — `aaca_enrollment` (historical backbone)
| Column | Type | Notes |
|---|---|---|
| Name (primary) | Text | Generated: `STU-000123 · 2026-2027 · Smith` |
| Student | Lookup → Student | |
| Campus | Lookup → Campus | |
| Teacher | Lookup → Staff | **Owner = teacher's user** (drives security, §4) |
| Service | Lookup → Service | |
| IEP Ratio | Choice: No Aide, 1:1, 2:1, 3:1, 4:1 | |
| School Year | Lookup → School Year | |
| Start Date / End Date | Date only | End blank = open-ended within the school year |
| Status | Choice: Planned (future-dated), Active, Ended | |
| End Reason | Choice: Transfer, Ratio Change, Discharge, Year End, Correction | |
| Previous Enrollment | Lookup → Enrollment | Chains transfer history |

Rules: enrollments never cross a school-year boundary (the rollover tool closes and reopens them). No two enrollments for the same Student + Service may overlap in dates; the app validates this before saving and the integrity check re-verifies it. A change of teacher, campus or ratio closes the row (End Date = effective date − 1) and opens a new one. Enrollment rows are never deleted.

### 3.9 Attendance — `aaca_attendance`
| Column | Type | Notes |
|---|---|---|
| Record Key (primary) | Text | `yyyymmdd\|STU-000123\|SPED` (readable; exports) |
| Date | Date only | |
| Student | Lookup → Student | |
| Service | Lookup → Service | |
| **Alternate key** | Student + Service + Date | Enforced uniqueness; target for upsert |
| Enrollment | Lookup → Enrollment | Enrollment in force that day |
| Snapshots | Teacher (Lookup → Staff), Campus, School Year, Term, IEP Ratio | Copied at save; later roster changes never rewrite the past |
| Present | Yes/No | Yes = 1, No = 0 |
| Absence Classification | Choice: Excused, Unexcused (blank = Not classified) | **Column-secured**: office staff only |
| Absence Reason | Lookup → Absence Reason | Column-secured. **Required when Excused** (enforced by the app and a Dataverse business rule) |
| Classified By / On | Lookup → User / Date+time | Column-secured |
| Notes | Multiline text 2,000 | |
| Is Deleted | Yes/No | Soft delete; re-entering the day restores the same row |
| Owner | User | = snapshot teacher's user |

Derived label (app): Present → *N/A*; Absent + blank → *Unclassified*; otherwise the classification.
When a teacher changes an absence to Present, the teacher cannot clear the secured column, so an automated flow clears it and writes an audit event (§7).
Billing columns (BA flag, additional billable codes) are **deferred** until you provide the billing template.

### 3.9a Absence Reason — `aaca_absencereason`
Name, Active, Sort Order. A table (not a fixed choice list) so office staff/admin can maintain reasons without a solution change. Seeded with **placeholder** reasons (Illness, Medical/Therapy Appointment, Family Emergency, Religious Observance, Bereavement, Other) for you to replace.

### 3.10 Month Lock — `aaca_monthlock`
Campus, Month (Date only, first of month), Status (Locked/Unlocked), Locked By / On, Reason. Alternate key Campus + Month.

### 3.11 Setting — `aaca_setting`
Key (alternate key), Value (text), Description. Initial keys: `AllowFutureDates` (**false** — no future-dated attendance), `AbsenceAlertPerTerm` (e.g. 5), `ConsecutiveAbsenceAlert` (e.g. 3), `UnclassifiedAgingDays` (e.g. 5). A reason for Excused is always required, so it is a fixed rule, not a setting.

### 3.12 Audit Event — `aaca_auditevent`
Timestamp, User, Action (Choice: Create, Update, SoftDelete, Restore, Transfer, Discharge, Archive, Unarchive, Reclassify, Lock, Unlock, Override, Rollover), Entity, Entity ID, Before (JSON), After (JSON), Reason.
Why both this table and built-in auditing: canvas apps cannot read the built-in audit log, and business actions need a *reason*. Built-in auditing is the tamper-proof backstop; this table powers the in-app audit viewer. Teachers may **create** audit events but never edit or delete them.

---

## 4. Security model

**Business units:** `AACA` (root) → one child business unit per campus. Each teacher's user sits in their campus's business unit.

**Ownership:** Enrollment and Attendance rows are owned by the teacher; a Student row is owned by the student's *current* teacher (reassigned when a transfer takes effect).

| Security role | Student | Enrollment | Attendance | Reference tables | Audit Event | Classification columns |
|---|---|---|---|---|---|---|
| AACA Teacher | Read (own) | Read (own) | Create/Read/Write (own); no delete | Read (all) | Create (own) | Read only |
| AACA Attendance Office | Create/Read/Write/Assign (**own campus business unit**) | Create/Read/Write/Assign (campus) | Read/Write (campus) | Read; write Absence Reason, Calendar Exception, Month Lock | Create/Read (campus) | **Read/Write** |
| AACA Read-only | Read (all) | Read (all) | Read (all) | Read | Read | Read |
| AACA System Admin | Full | Full | Full | Full | Read | Read/Write |

Office staff are **per campus**. They add and retire students, change IEP ratios and classroom (teacher) assignments, and classify absences for their own campus only.

**Cross-campus transfers:** after the transfer, the sending campus's office loses access to the student's *current* record, but keeps the history it owned (past attendance and ended enrollments). The transfer tool assigns the new enrollment and the student to the receiving teacher. Milestone 3 will verify that a campus-level Assign privilege is enough for this. If it isn't, the receiving campus's office completes a "transfer in" step instead.

Outcome: a teacher browsing Dataverse directly (Excel add-in, API, model-driven app) sees only their own current students, enrollments and attendance. Past attendance stays with the teacher who recorded it. Hard delete is granted to no role except System Admin.

---

## 5. App structure (canvas, responsive)

Screens:
- **Home** — role-aware tiles and counts
- **Attendance Matrix**
- **Student Profile**
- **Student Management** — add, transfer, discharge, archive
- **Absence Classification** queue (office staff)
- **Reports**
- **Admin** — reference data, calendar, month lock, rollover
- **Audit Viewer**

Shared components: header with role/campus context, month picker, student card, confirmation dialog, status badge (colour + letter: **P**, **A?** unclassified, **E** excused, **U** unexcused).

**Attendance matrix design:**
- **Loading.** Filter the month for one teacher, e.g. `Filter(Attendance, Teacher = t, Date >= first, Date <= last)`. That's at most about 15 students × 31 days ≈ 465 rows. The month's enrollments, calendar exceptions and lock are loaded at the same time with `Concurrent()`.
- **Layout.** One gallery row per enrollment segment active in the month; the day cells come from `Sequence(days)`. A student who transfers mid-month appears only on their enrolled days under each teacher.
- **Saving a cell.** Tapping a cell upserts **one row** using the alternate key. Before writing, the app checks the row's Modified On timestamp to detect conflicts. The cell shows saving / saved / failed with a retry, and the UI updates immediately and rolls back if the save fails.
- **Clearing a cell** asks for confirmation, then soft-deletes the row and writes an audit event.
- **Validation** runs before every write: school day, student enrolled that day, month not locked, and not a future date (per the Settings value).

---

## 6. Delegation and performance

- Every data query filters on lookups, dates, choices or Yes/No columns. These are delegable in Dataverse.
- The app avoids `Search`, `GroupBy` and `AddColumns` on the server tables. Aggregates run on small collections that have already been filtered.
- The largest in-app query is about 1,000 rows (a teacher's full-year quarter report), below the 2,000-row limit.
- Campus- and organisation-wide reports use Dataverse views, flow exports to Excel, or Power BI (a DirectQuery/import dataset later).
- Targets: the matrix loads in under 2 seconds (≈ 500 rows); a cell save is acknowledged in under 1 second (single row with an optimistic update).

## 7. Power Automate flows (solution-aware, connection references)

| Flow | Trigger | Purpose |
|---|---|---|
| Absence reset | Attendance updated, Present → Yes | Clear the classification columns; write an audit event |
| Transfer activation | Daily, 1 am | Activate future-dated enrollments; reassign Student owner |
| Nightly integrity check | Daily | Overlapping enrollments; attendance outside an enrollment or on a non-school day; students with no active enrollment; Staff role mismatches; unclassified absences older than N days → email to Adam / office |
| Absence alerts | Daily | N absences in a term, or N consecutive absences → email/Teams to office staff |
| Month-lock reminder | Monthly | Remind office staff to lock the previous month |
| Exports | On demand (button in the app) | Excel/PDF reports to a SharePoint document library (Milestone 5) |

Dropped from the brief: the audit-logging flow (built-in auditing plus app writes cover it), the annual archive flow (§1) and the summary rollups flow (deferred).

## 8. Milestones (revised)

1. **Foundation:**
   - Dev environment, solution and publisher
   - Schema file + provisioning script
   - Security roles, business units and column security
   - Seed data generator
   - Repository and pac CLI setup
2. **Attendance matrix:** entry, soft delete, validation, conflict handling.
3. **Student lifecycle:** add (with duplicate check), transfer, discharge, archive/unarchive, corrections, profile.
4. **Absence classification:** queue, bulk classify, absence reset flow, alerts.
5. **Reports and exports.**
6. **Admin tools:** reference data, calendar, month lock, year rollover.
7. **Hardening:**
   - Offline evaluation
   - Test/Prod environments and managed deployment
   - Full test plan and UAT per role
   - Guides and known-limitations list

## 9. Known limitations (initial)

- **Offline:** canvas offline with Dataverse works only in the Power Apps mobile/Windows app with an offline profile, not in a web browser. Desktop-browser users will not have offline mode.
- **Absence reset lag:** the Present → reset flow is asynchronous. The classification clears a few seconds after the change, though the app shows *N/A* immediately.
- **Teacher security testing** needs at least two extra licensed test accounts in Dev (seeded "teachers" without real accounts can't own records).
- **Built-in audit history** is viewable by System Admins in the Power Platform admin experience, not inside the canvas app.

## 10. Decision log (2026-09-28)

| Item | Decision |
|---|---|
| Office staff scope (Q-A) | Per campus. Office staff add and retire students, change IEP ratios and classroom assignments, and classify absences for their campus (§4). |
| Summer program (Q-B) | Most students attend. It runs 29 days, Mon–Fri, and uses separate summer enrollments with the pre-selected Summer roster tool (§3.5). A1 is defaulted. |
| Absences (Q-C) | Three states: Not classified, Excused, Unexcused. A reason is **required** for Excused. The reason list is a maintainable table seeded with placeholders (§3.9a). |
| Grades (Q-D) | K, 1–12, 12+. |
| Environment (Q-E) | Developer environment `AACA Attendance – Dev`. The real app is built there inside the solution, and the Default-environment app is abandoned. |
| Source control (Q-F) | Private GitHub repository; local clone at `C:\src\aaca-attendance`. |
| Testing (Q-G) | Licensed test accounts or licensed colleagues will test role isolation. |
| Future dates (Q-H) | Not allowed (`AllowFutureDates` = false). |

Still open (they don't block Milestone 1): the real absence-reason list, confirmation of A1, and the billing template (Milestone 5).
