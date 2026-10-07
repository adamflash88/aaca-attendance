# Discovery Packet - AACA Attendance build 10 (Staff screen), captured 2026-10-06

EDIT mode. Live session synced 2026-10-06: identical to C:\src\aaca-attendance\app (= Adam's saved build 9,
committed e6b59f3): App, Screen1, StudentsScreen, AbsencesScreen, TransportScreen, _EditorState.
The build-9 and build-8 packets (docs/app-builds/build-9-transport/canvas-discovery-packet.md) still apply.

## Staff data source (get_data_source_schema after Adam's refresh)
- Name (aaca_name): Text, required. Convention "Last, First".
- Email (aaca_email): Text 100 - NEW. Blank on existing rows (backfilled from linked users by script).
- Start Date (aaca_startdate), End Date (aaca_enddate): Date - NEW.
- Active, Finance Access, Site Administrator: Yes/No. In formulas they behave as Booleans (existing app code:
  `CurrentStaff.Active <> false`, `Filter(Services, Active = true)`).
- App Role: `'App Role (Staff)'` = Teacher | 'Attendance Office' | 'Read-only' | 'System Admin' (required).
- Campus: lookup Campuses (blank = all campuses). User: lookup Users (blank until linked).
- Relationships: Enrollments (aaca_enrollment_aaca_teacher), Attendance, Students (case manager).

## Audit Events
`'Action (Audit Events)'` values used in the app: Create, Update, Transfer, Archive, Unarchive, Reclassify.
Columns as used in StudentsScreen: Summary, Action, Entity, 'Entity ID', Before, After (JSON text), Reason.

## Reference implementation to reuse
- StudentsScreen "Change class" engine (around line 1800-1850): close old enrollment + create new one with
  'Previous Enrollment', month-lock check, audit JSON, receipt lines (colStuReceiptLines).
- TransportScreen: newest screen; copy its header/nav/tabs-strip layout, campus picker (varTrnCampusId with
  StudentCampusLock), notice and receipt patterns.
- Enrollment status choice: `'Status (Enrollments)'`.Planned | Active | Ended, column `'Status (aaca_status)'`;
  End Reason `'End Reason (Enrollments)'`.Transfer.

## Security (Dev, 2026-10-06)
Office role: Staff Create/Write/Append Local; Staff rows owned by campus teams. Admin: Global.
