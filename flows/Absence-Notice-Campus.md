# Flow spec - Family portal absence notice: campus, owner, name

When a parent reports an absence in the family portal (Power Pages), the notice is created by the portal's
application user, so it starts with no campus and an owner nobody at the campus can see. This flow:

1. checks the submitting guardian is actually linked to the student and allowed to report absences;
2. sets **Campus** from the student's active enrollment;
3. makes that campus business unit's **default team** the owner (same model as `provisioning/Set-CampusOwnership.ps1`),
   so the campus office sees it at Local depth;
4. fills the **Summary** (`aaca_name`), e.g. `Sam - 2026-10-05` or `Sam - 2026-10-05 to 2026-10-07`.

Submitted on = the row's **Created On** (server time). The flow never changes it.

## Build it inside the solution

**make.powerapps.com -> AACA Attendance - Dev -> Solutions -> AACA Attendance -> New -> Automation -> Cloud flow ->
Automated**. Name: `AACA - Absence Notice Campus`. Reuse the `AACA Dataverse` connection reference
(see `Student-Directory-Sync.md`). Premium licence note there applies here too. The flow owner needs to be able to
assign records to teams (System Administrator, or the AACA System Admin role).

## Trigger

**Dataverse > When a row is added, modified or deleted**
- Change type: **Added**
- Table name: **Absence Notices**
- Scope: **Organization**

## Steps

**1 - Dataverse > Get a row by ID** (rename `Get student`)
- Table: **Students**; Row ID: `triggerOutputs()?['body/_aaca_student_value']`
- Select columns: `aaca_firstname`

**2 - Dataverse > List rows** (rename `Guardian link`)
- Table: **Guardian Links**
- Filter rows:
  `_aaca_contact_value eq @{triggerOutputs()?['body/_aaca_submittedby_value']} and _aaca_student_value eq @{triggerOutputs()?['body/_aaca_student_value']} and aaca_active eq true and aaca_canreportabsences eq true`
- Row count: `1`

**3 - Condition** (rename `Linked guardian`): `length(outputs('Guardian_link')?['body/value'])` **is greater than** `0`
- **If no:** *Dataverse > Update a row* on the notice (Absence Notices, Row ID = trigger `aaca_absencenoticeid`):
  Status = **Dismissed**, Summary = `Not linked - check guardian`. Then **Terminate** (Succeeded).
  (The portal's table permissions should make this impossible; this is a second line of defence.)

**4 - Dataverse > List rows** (rename `Enrollment`)
- Table: **Enrollments**
- Filter rows: `_aaca_student_value eq @{triggerOutputs()?['body/_aaca_student_value']}`
- Sort by: `aaca_startdate desc`
- Expand query: `aaca_campus($select=aaca_name)`
- Row count: `20`

**5 - Filter array** (rename `Active enrollment`): From `outputs('Enrollment')?['body/value']`,
  `item()?['aaca_status']` is equal to `582100001`.

**6 - Compose** (rename `Campus`):
```
if(greater(length(body('Active_enrollment')), 0),
   first(body('Active_enrollment')),
   first(outputs('Enrollment')?['body/value']))
```
(No active enrollment -> most recent enrollment. No enrollment at all -> `null`; see step 9.)

**7 - Dataverse > List rows** (rename `Business unit`)
- Table: **Business Units**; Filter rows: `name eq '@{replace(outputs('Campus')?['aaca_campus/aaca_name'], '''', '''''')}'`
- Row count: `1`

**8 - Dataverse > List rows** (rename `Campus team`)
- Table: **Teams**; Filter rows:
  `isdefault eq true and _businessunitid_value eq @{first(outputs('Business_unit')?['body/value'])?['businessunitid']}`
- Row count: `1`

**9 - Dataverse > Update a row** (rename `Set campus and owner`) - put steps 7-9 inside a **Condition**
`outputs('Campus')` **is not equal to** `null`; in the **If no** branch only set the Summary (the notice stays with the
portal user; System Admins see it and fix the student's enrollment).
- Table: **Absence Notices**; Row ID: `triggerOutputs()?['body/aaca_absencenoticeid']`
- Campus: `aaca_campuses(@{outputs('Campus')?['_aaca_campus_value']})`
- Owner: `teams(@{first(outputs('Campus_team')?['body/value'])?['teamid']})`
- Summary:
```
concat(outputs('Get_student')?['body/aaca_firstname'], ' - ', triggerOutputs()?['body/aaca_absencestart'],
       if(equals(triggerOutputs()?['body/aaca_absencestart'], triggerOutputs()?['body/aaca_absenceend']), '',
          concat(' to ', triggerOutputs()?['body/aaca_absenceend'])))
```

## Test (Dev)

1. Create a test Contact and a Guardian Link to one student (Active, Can Report Absences = Yes).
2. Create an Absence Notice for that student with Submitted By = the contact. Within a minute: Campus is set, Owner =
   the campus team, Summary filled.
3. Repeat with a contact that has no link: Status becomes Dismissed.
4. Sign in as an Attendance Office user of that campus (or query with the `MSCRMCallerID` header) and confirm the
   notice is visible; an office user of another campus must not see it.
