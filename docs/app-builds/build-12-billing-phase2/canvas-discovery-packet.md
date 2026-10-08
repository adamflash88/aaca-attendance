# Discovery Packet - AACA Attendance build 12 / Phase 2 step C (Absence Notices), captured 2026-10-07

EDIT mode. Live session (env a4c9f4ce-b971-edf2-beba-e3c29552a316, app fb649976-33fb-4419-8ee6-132c204df470) synced
2026-10-07: identical to C:\src\aaca-attendance\app (build 11, commit e957d43). Earlier packets (build 8, 9, 10) still
apply for the other data sources and patterns.

## New data source: Absence Notices (get_data_source_schema 2026-10-07)
- aaca_name "Summary" String (primary); aaca_reference "Reference" String (autonumber ABS-yyyy-nnnnnn, read-only)
- aaca_source "Source": `'Source (Absence Notices)'` = 'Website form' | Office | 'Family portal' | 'SharePoint import'
- aaca_status "Status (aaca_status)": `'Status (Absence Notices)'` = New | Accepted | Dismissed | Cancelled
  (statecode is "Status (statecode)" Active/Inactive - not used)
- aaca_matchstatus "Match Status": `'Match Status (Absence Notices)'` = Matched | Unmatched | Ambiguous | 'Mapped by office'
- aaca_matchdetail "Match Detail" String; aaca_errordetail "Error Detail" String
- aaca_absencestart "First Day Absent" Date; aaca_absenceend "Last Day Absent" Date; aaca_returndate "Return Date" Date
- aaca_noticeat "Notice At" DateTime; aaca_websitesubmittedat "Website Submitted At" DateTime
- aaca_typedfirstname / aaca_typedlastname / aaca_typedcampus String; aaca_parentname "Parent Name";
  aaca_relationshiptext "Relationship"; aaca_reasontext "Reason Text"; aaca_note "Note"
- aaca_dayscreated / aaca_daysskipped / aaca_daysconflict Number; aaca_processedon DateTime; aaca_processedby -> Users
- lookups: aaca_student "Student", aaca_campus "Campus", aaca_absencereason "Absence Reason", aaca_submittedby (Contact)
- relationship: Attendance via aaca_attendance_aaca_absencenotice

## Attendance (refreshed): new lookup aaca_absencenotice "Absence Notice" (DataEntity)

## Dev test data
Absence Notices ABS-2026-001000 (Unmatched, Chatsworth, typed "Nobody Fakestudent", New) and ABS-2026-001001..001004
(test student "McTestface, Testy", key CW-TEST1, Accepted). Use these to test Mapping Errors and Classify.

## Flows that act on notices (already deployed in Dev; the app does not call them)
- Processing: fires when a notice is New + Student set + Match Status Matched/Mapped by office -> creates days, sets
  Accepted. Changing Match Status to 'Mapped by office' (with Student) re-triggers it.
- Alert: fires on every notice created (except SharePoint import) -> Teams card with "Open in app" = AttendanceAppUrl
  App Setting + "?screen=absences" (or "&screen=absences").
