"""Generates the three absence-intake cloud flow definitions (clientdata JSON) for the AACA Attendance solution.

    python flows/build_absence_intake_flows.py   -> writes flows/generated/*.json

flows/Deploy-AbsenceIntakeFlows.ps1 creates/updates them in Dataverse (solution-aware, connection references).
Design: docs/app-builds/build-8-absences/ and flows/Absence-Report-Intake.md.
"""
import json
import os
import uuid

SITE = "https://autismacademy.sharepoint.com/sites/FinanceMain"
ABSENCE_LOG = "1058d183-30d4-4fe8-83f6-1c5120edf24f"   # SharePoint list "Student Absence Log"
CUTOVER = "2026-01-01"                                  # parent reports before this are ignored
MAX_DAYS = 60
MAKEUP = 582100004                                      # Calendar Exception type "Make-up School Day"
SRC_PARENT = 582100001                                  # Attendance source "Parent report"
PROCESSED, ERROR = 582100000, 582100001                 # Report Decision processing status
APPROVED, DISMISSED = 582100000, 582100001              # Report Decision decision (required column)

CHILD_ID = "6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e51"
TRIGGER_ID = "6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e52"
BACKFILL_ID = "6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e53"

DV = {"connectionName": "shared_commondataserviceforapps", "apiId": "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps"}
SP = {"connectionName": "shared_sharepointonline", "apiId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"}
AUTH = {"type": "Raw", "value": "@json(decodeBase64(triggerOutputs().headers['X-MS-APIM-Tokens']))['$ConnectionKey']"}
CONN_REFS = {
    "shared_commondataserviceforapps": {"runtimeSource": "embedded", "connection": {"connectionReferenceLogicalName": "aaca_sharedcommondataserviceforapps_2b783"}, "api": {"name": "shared_commondataserviceforapps"}},
    "shared_sharepointonline": {"runtimeSource": "embedded", "connection": {"connectionReferenceLogicalName": "aaca_sharedsharepointonline_4204c"}, "api": {"name": "shared_sharepointonline"}},
}


def mid():
    return {"operationMetadataId": str(uuid.uuid4())}


def op(api, operation, params, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "OpenApiConnection",
            "inputs": {"host": {**api, "operationId": operation}, "parameters": params, "authentication": AUTH}}


def ok(*names):
    return {n: ["Succeeded"] for n in names}


def compose(expr, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "Compose", "inputs": expr}


def setvar(name, value, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "SetVariable", "inputs": {"name": name, "value": value}}


def incr(name, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "IncrementVariable", "inputs": {"name": name, "value": 1}}


def cond(expr, yes, no=None, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "If", "expression": expr,
            "actions": yes, "else": {"actions": no or {}}}


def query(src, where, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "Query", "inputs": {"from": src, "where": where}}


def wrap(definition, refs):
    return {"properties": {"connectionReferences": refs, "definition": {
        "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {"$connections": {"defaultValue": {}, "type": "Object"}, "$authentication": {"defaultValue": {}, "type": "SecureObject"}},
        **definition}, "templateName": None}, "schemaVersion": "1.0.0.0"}


# ------------------------------------------------------------------------------------------------------------
# Child flow: process one report (input = SharePoint item ID as text)
# ------------------------------------------------------------------------------------------------------------
R = "body('Get_report')"
DAY = "outputs('Day')"
ENR = "outputs('Enrollment')"


def decision_body(status, decision, error_expr):
    """Report Decision fields shared by the processed and error paths (create or update)."""
    return {
        "item/aaca_name": f"@{{concat('Report ', triggerBody()['text'], ' - ', if(equals({status}, {PROCESSED}), 'processed', 'error'))}}",
        "item/aaca_reportitemid": "@int(triggerBody()['text'])",
        "item/aaca_decision": decision,
        "item/aaca_processingstatus": status,
        "item/aaca_errordetail": error_expr,
        "item/aaca_studentkey": "@outputs('Key')",
        "item/aaca_dayscreated": "@variables('Created')",
        "item/aaca_daysskipped": "@variables('Skipped')",
        "item/aaca_daysconflict": "@variables('Conflict')",
        "item/aaca_note": f"@{{take(coalesce({R}?['Reason'], ''), 1000)}}",
    }


def write_decision(name, status, decision, error_expr, extra_binds, after):
    """Create the decision, or update an earlier error decision for this report (re-processing after a fix)."""
    body = {**decision_body(status, decision, error_expr), **extra_binds}
    create = op(DV, "CreateRecord", {"entityName": "aaca_reportdecisions", **body})
    update = op(DV, "UpdateRecord", {"entityName": "aaca_reportdecisions",
                                     "recordId": "@first(body('Existing_decision')?['value'])?['aaca_reportdecisionid']", **body})
    return {name: cond({"and": [{"equals": ["@empty(body('Existing_decision')?['value'])", True]}]},
                       {f"{name}_create": create}, {f"{name}_update": update}, after=after)}


site_campus_bind = {
    # Error rows belong to the campus named in the report so that campus's office sees them in Mapping Errors.
    "item/aaca_campus@odata.bind": "@if(empty(body('Site_campus')?['value']), null, concat('/aaca_campuses(', first(body('Site_campus')?['value'])?['aaca_campusid'], ')'))",
    "item/ownerid@odata.bind": "@if(or(empty(body('Site_campus')?['value']), empty(first(body('Site_campus')?['value'])?['aaca_ownerteamid'])), null, concat('/teams(', first(body('Site_campus')?['value'])?['aaca_ownerteamid'], ')'))",
}


def error_path(prefix, message_expr):
    """Set the error variables and write an Error decision."""
    acts = {f"{prefix}_status": setvar("Status", "error"),
            f"{prefix}_text": setvar("ErrorText", message_expr, ok(f"{prefix}_status"))}
    acts.update(write_decision(f"{prefix}_decision", ERROR, DISMISSED, "@variables('ErrorText')", site_campus_bind, ok(f"{prefix}_text")))
    return acts


# Day loop -------------------------------------------------------------------------------------------------
day_loop_actions = {
    "Day": compose(f"@addDays(outputs('Start'), item(), 'yyyy-MM-dd')"),
    "Enrollment_on_day": query("@body('Enrollments')?['value']",
                               f"@and(lessOrEquals(item()?['aaca_startdate'], {DAY}), or(equals(item()?['aaca_enddate'], null), greaterOrEquals(item()?['aaca_enddate'], {DAY})))",
                               ok("Day")),
    "Enrollment": compose("@first(body('Enrollment_on_day'))", ok("Enrollment_on_day")),
    "Term_on_day": query("@body('Terms')?['value']",
                         f"@and(equals(item()?['_aaca_campus_value'], {ENR}?['_aaca_campus_value']), lessOrEquals(item()?['aaca_startdate'], {DAY}), greaterOrEquals(item()?['aaca_enddate'], {DAY}))",
                         ok("Enrollment")),
    "Makeup_on_day": query("@body('Exceptions')?['value']",
                           f"@and(equals(item()?['aaca_date'], {DAY}), equals(item()?['aaca_type'], {MAKEUP}), or(equals(item()?['_aaca_campus_value'], null), equals(item()?['_aaca_campus_value'], {ENR}?['_aaca_campus_value'])))",
                           ok("Enrollment")),
    "Closed_on_day": query("@body('Exceptions')?['value']",
                           f"@and(equals(item()?['aaca_date'], {DAY}), not(equals(item()?['aaca_type'], {MAKEUP})), or(equals(item()?['_aaca_campus_value'], null), equals(item()?['_aaca_campus_value'], {ENR}?['_aaca_campus_value'])))",
                           ok("Enrollment")),
    "Is_school_day": compose(
        f"@and(not(equals({ENR}, null)), not(empty(body('Term_on_day'))), or(not(empty(body('Makeup_on_day'))), and(not(or(equals(dayOfWeek({DAY}), 0), equals(dayOfWeek({DAY}), 6))), empty(body('Closed_on_day')))))",
        ok("Term_on_day", "Makeup_on_day", "Closed_on_day")),
}
existing_q = query("@body('Attendance_in_range')?['value']", f"@equals(item()?['aaca_date'], {DAY})")
EXIST = "first(body('Existing_on_day'))"
new_row = {
    "entityName": "aaca_attendances",
    "item/aaca_recordkey": f"@{{concat(replace({DAY}, '-', ''), '|', outputs('Student')?['aaca_studentnumber'], '|SPED')}}",
    "item/aaca_date": f"@{{{DAY}}}",
    "item/aaca_present": False,
    "item/aaca_isdeleted": False,
    "item/aaca_source": SRC_PARENT,
    "item/aaca_noticereceivedon": f"@{{{R}?['Created']}}",
    "item/aaca_sourcereportid": "@int(triggerBody()['text'])",
    "item/aaca_notes": f"@{{take(concat('Parent report #', triggerBody()['text'], ': ', coalesce({R}?['Reason'], '')), 2000)}}",
    "item/aaca_student@odata.bind": "@{concat('/aaca_students(', outputs('Student')?['aaca_studentid'], ')')}",
    "item/aaca_service@odata.bind": "@{concat('/aaca_services(', first(body('SPED')?['value'])?['aaca_serviceid'], ')')}",
    "item/aaca_enrollment@odata.bind": f"@{{concat('/aaca_enrollments(', {ENR}?['aaca_enrollmentid'], ')')}}",
    "item/aaca_teacher@odata.bind": f"@if(equals({ENR}?['_aaca_teacher_value'], null), null, concat('/aaca_staffs(', {ENR}?['_aaca_teacher_value'], ')'))",
    "item/aaca_campus@odata.bind": f"@{{concat('/aaca_campuses(', {ENR}?['_aaca_campus_value'], ')')}}",
    "item/aaca_schoolyear@odata.bind": f"@if(equals({ENR}?['_aaca_schoolyear_value'], null), null, concat('/aaca_schoolyears(', {ENR}?['_aaca_schoolyear_value'], ')'))",
    "item/aaca_term@odata.bind": "@{concat('/aaca_terms(', first(body('Term_on_day'))?['aaca_termid'], ')')}",
    "item/aaca_iepratio": f"@{ENR}?['aaca_iepratio']",
    "item/ownerid@odata.bind": f"@if(empty({ENR}?['aaca_campus']?['aaca_ownerteamid']), null, concat('/teams(', {ENR}?['aaca_campus']?['aaca_ownerteamid'], ')'))",
}
school_day_yes = {
    "Existing_on_day": existing_q,
    "Which_case": {
        "runAfter": ok("Existing_on_day"), "metadata": mid(), "type": "Switch",
        "expression": f"@if(empty(body('Existing_on_day')), 'new', if(equals({EXIST}?['aaca_isdeleted'], true), 'deleted', if(equals({EXIST}?['aaca_present'], true), 'present', 'absent')))",
        "cases": {
            "New": {"case": "new", "actions": {
                "Create_absence": op(DV, "CreateRecord", new_row),
                "Count_created": incr("Created", ok("Create_absence"))}},
            "Deleted": {"case": "deleted", "actions": {
                # An undone (soft-deleted) row already holds the key for this day: reuse it as the absence.
                "Revive_as_absence": op(DV, "UpdateRecord", {
                    "entityName": "aaca_attendances", "recordId": f"@{EXIST}?['aaca_attendanceid']",
                    "item/aaca_present": False, "item/aaca_isdeleted": False, "item/aaca_source": SRC_PARENT,
                    "item/aaca_noticereceivedon": new_row["item/aaca_noticereceivedon"],
                    "item/aaca_sourcereportid": new_row["item/aaca_sourcereportid"], "item/aaca_notes": new_row["item/aaca_notes"]}),
                "Count_revived": incr("Created", ok("Revive_as_absence"))}},
            "Present": {"case": "present", "actions": {
                # Teacher already marked present: never overwrite; flag it for the office to decide.
                "Flag_conflict": op(DV, "UpdateRecord", {
                    "entityName": "aaca_attendances", "recordId": f"@{EXIST}?['aaca_attendanceid']",
                    "item/aaca_parentreportedabsent": True,
                    "item/aaca_noticereceivedon": new_row["item/aaca_noticereceivedon"],
                    "item/aaca_sourcereportid": new_row["item/aaca_sourcereportid"]}),
                "Count_conflict": incr("Conflict", ok("Flag_conflict"))}},
        },
        "default": {"actions": {"Count_already_absent": incr("Skipped")}},
    },
}
day_loop_actions["School_day_check"] = cond({"and": [{"equals": ["@outputs('Is_school_day')", True]}]},
                                            school_day_yes, {"Count_not_school_day": incr("Skipped")}, ok("Is_school_day"))

work = {
    "Student": compose("@first(body('Find_student')?['value'])"),
    "Enrollments": op(DV, "ListRecords", {
        "entityName": "aaca_enrollments",
        "$select": "aaca_enrollmentid,aaca_startdate,aaca_enddate,aaca_iepratio,_aaca_campus_value,_aaca_teacher_value,_aaca_schoolyear_value",
        "$filter": "_aaca_student_value eq @{outputs('Student')?['aaca_studentid']} and aaca_startdate le @{outputs('LastDay')} and (aaca_enddate eq null or aaca_enddate ge @{outputs('Start')})",
        "$expand": "aaca_campus($select=aaca_ownerteamid)"}, ok("Student")),
    "Terms": op(DV, "ListRecords", {
        "entityName": "aaca_terms", "$select": "aaca_termid,aaca_startdate,aaca_enddate,_aaca_campus_value",
        "$filter": "aaca_startdate le @{outputs('LastDay')} and aaca_enddate ge @{outputs('Start')}"}, ok("Student")),
    "Exceptions": op(DV, "ListRecords", {
        "entityName": "aaca_calendarexceptions", "$select": "aaca_date,aaca_type,_aaca_campus_value",
        "$filter": "aaca_date ge @{outputs('Start')} and aaca_date le @{outputs('LastDay')}"}, ok("Student")),
    "SPED": op(DV, "ListRecords", {"entityName": "aaca_services", "$select": "aaca_serviceid", "$filter": "aaca_servicecode eq 'SPED'", "$top": 1}, ok("Student")),
    "Attendance_in_range": op(DV, "ListRecords", {
        "entityName": "aaca_attendances", "$select": "aaca_attendanceid,aaca_date,aaca_present,aaca_isdeleted",
        "$filter": "_aaca_student_value eq @{outputs('Student')?['aaca_studentid']} and aaca_date ge @{outputs('Start')} and aaca_date le @{outputs('LastDay')}"}, ok("Student")),
    "Each_day": {"runAfter": ok("Enrollments", "Terms", "Exceptions", "SPED", "Attendance_in_range"), "metadata": mid(),
                 "type": "Foreach", "foreach": "@range(0, outputs('DayCount'))", "actions": day_loop_actions,
                 "runtimeConfiguration": {"concurrency": {"repetitions": 1}}},
    "Processed_status": setvar("Status", "processed", ok("Each_day")),
}
work.update(write_decision("Processed_decision", PROCESSED, APPROVED, "",
                           {"item/aaca_student@odata.bind": "@{concat('/aaca_students(', outputs('Student')?['aaca_studentid'], ')')}",
                            "item/aaca_campus@odata.bind": "@if(empty(body('Enrollments')?['value']), null, concat('/aaca_campuses(', first(body('Enrollments')?['value'])?['_aaca_campus_value'], ')'))",
                            "item/ownerid@odata.bind": "@if(or(empty(body('Enrollments')?['value']), empty(first(body('Enrollments')?['value'])?['aaca_campus']?['aaca_ownerteamid'])), null, concat('/teams(', first(body('Enrollments')?['value'])?['aaca_campus']?['aaca_ownerteamid'], ')'))"},
                           ok("Processed_status")))

# Date parsing (M/D/YYYY with or without leading zeros); a failure goes to the error path.
DATE_ISO = "concat(split({t}, '/')[2], '-', formatNumber(int(split({t}, '/')[0]), '00'), '-', formatNumber(int(split({t}, '/')[1]), '00'))"
abs_t = f"trim(coalesce({R}?['AbsenceDate'], ''))"
ret_t = f"trim(coalesce({R}?['ReturnDate'], ''))"
dates_scope = {
    "Start": compose("@" + DATE_ISO.format(t=abs_t)),
    "ReturnParsed": compose(f"@if(empty({ret_t}), '', {DATE_ISO.format(t=ret_t)})", ok("Start")),
    # Days absent = absence date up to (not including) the return date; no or bad return date = one day.
    "EndExclusive": compose("@if(or(empty(outputs('ReturnParsed')), lessOrEquals(outputs('ReturnParsed'), outputs('Start'))), addDays(outputs('Start'), 1, 'yyyy-MM-dd'), formatDateTime(outputs('ReturnParsed'), 'yyyy-MM-dd'))", ok("ReturnParsed")),
    "LastDay": compose("@addDays(outputs('EndExclusive'), -1, 'yyyy-MM-dd')", ok("EndExclusive")),
    "DayCount": compose("@div(sub(ticks(outputs('EndExclusive')), ticks(outputs('Start'))), 864000000000)", ok("LastDay")),
}

# Flat routing (Power Automate allows at most 8 nesting levels): read everything first, compute which case the
# report is in, then one Switch handles each case side by side.
EXISTING = "body('Existing_decision')?['value']"
gate1 = (f"@if(and(not(empty({EXISTING})), not(equals(first({EXISTING})?['aaca_processingstatus'], {ERROR}))), 'done', "
         "if(empty(outputs('Key')), 'unmapped', "
         "if(empty(body('Find_student')?['value']), 'unknown', "
         "if(not(variables('DatesOK')), 'baddates', 'check'))))")
gate2 = f"@if(less(outputs('Start'), '{CUTOVER}'), 'before', if(greater(outputs('DayCount'), {MAX_DAYS}), 'toolong', 'work'))"

top = {
    "Get_report": op(SP, "GetItem", {"dataset": SITE, "table": ABSENCE_LOG, "id": "@int(triggerBody()['text'])"}, ok("Init_dates")),
    "Key": compose(f"@toUpper(trim(coalesce({R}?['Student_ID'], '')))", ok("Get_report")),
    "Existing_decision": op(DV, "ListRecords", {"entityName": "aaca_reportdecisions",
                                                "$select": "aaca_reportdecisionid,aaca_processingstatus",
                                                "$filter": "aaca_reportitemid eq @{int(triggerBody()['text'])}", "$top": 1}, ok("Key")),
    "Site_campus": op(DV, "ListRecords", {"entityName": "aaca_campuses", "$select": "aaca_campusid,aaca_ownerteamid",
                                          "$filter": f"aaca_name eq '@{{trim(coalesce({R}?['SchoolSite'], ''))}}'", "$top": 1}, ok("Key")),
    "Find_student": op(DV, "ListRecords", {"entityName": "aaca_students", "$select": "aaca_studentid,aaca_studentnumber",
                                           "$filter": "aaca_externalclientid eq '@{outputs('Key')}'", "$top": 1}, ok("Key")),
    "Dates": {"runAfter": ok("Key"), "metadata": mid(), "type": "Scope", "actions": dates_scope},
    "Dates_ok": setvar("DatesOK", True, ok("Dates")),
    "Gate": {"runAfter": {"Dates_ok": ["Succeeded", "Skipped"], "Existing_decision": ["Succeeded"],
                          "Site_campus": ["Succeeded"], "Find_student": ["Succeeded"]},
             "metadata": mid(), "type": "Compose", "inputs": gate1},
    "Route": {"runAfter": ok("Gate"), "metadata": mid(), "type": "Switch", "expression": "@outputs('Gate')",
              "cases": {
                  "Done": {"case": "done", "actions": {"Skip_done": setvar("Status", "skipped: already processed")}},
                  "Unmapped": {"case": "unmapped", "actions": {"Skip_unmapped": setvar("Status", "unmapped: no Student ID (Mapping Errors tab)")}},
                  "Unknown": {"case": "unknown", "actions": error_path("Unknown_student", "@{concat('Student ID ', outputs('Key'), ' is not in the app')}")},
                  "BadDates": {"case": "baddates", "actions": error_path("Bad_dates", f"@{{concat('Absence or return date cannot be read (expected M/D/YYYY): ', {abs_t}, ' / ', {ret_t})}}")},
                  "Check": {"case": "check", "actions": {
                      "Gate2": compose(gate2),
                      "Route2": {"runAfter": ok("Gate2"), "metadata": mid(), "type": "Switch", "expression": "@outputs('Gate2')",
                                 "cases": {
                                     "Before": {"case": "before", "actions": {"Skip_before": setvar("Status", "skipped: before 2026 cut-over")}},
                                     "TooLong": {"case": "toolong", "actions": error_path("Too_long", f"@{{concat('Absence covers ', string(outputs('DayCount')), ' days (more than {MAX_DAYS}); check the dates')}}")},
                                     "Work": {"case": "work", "actions": work}},
                                 "default": {"actions": {}}}}}},
              "default": {"actions": {}}},
}

def initvar(name, typ, value, after):
    return {"runAfter": after, "metadata": mid(), "type": "InitializeVariable", "inputs": {"variables": [{"name": name, "type": typ, "value": value}]}}

child = wrap({
    "triggers": {"manual": {"metadata": mid(), "type": "Request", "kind": "Button", "inputs": {"schema": {
        "type": "object", "properties": {"text": {"title": "ReportItemId", "type": "string", "x-ms-dynamically-added": True,
                                                  "description": "SharePoint Student Absence Log item ID", "x-ms-content-hint": "TEXT"}},
        "required": ["text"]}}}},
    "actions": {
        "Init_status": {"runAfter": {}, "metadata": mid(), "type": "InitializeVariable", "inputs": {"variables": [{"name": "Status", "type": "string", "value": "started"}]}},
        "Init_error": {"runAfter": ok("Init_status"), "metadata": mid(), "type": "InitializeVariable", "inputs": {"variables": [{"name": "ErrorText", "type": "string", "value": ""}]}},
        "Init_created": {"runAfter": ok("Init_error"), "metadata": mid(), "type": "InitializeVariable", "inputs": {"variables": [{"name": "Created", "type": "integer", "value": 0}]}},
        "Init_skipped": {"runAfter": ok("Init_created"), "metadata": mid(), "type": "InitializeVariable", "inputs": {"variables": [{"name": "Skipped", "type": "integer", "value": 0}]}},
        "Init_conflict": {"runAfter": ok("Init_skipped"), "metadata": mid(), "type": "InitializeVariable", "inputs": {"variables": [{"name": "Conflict", "type": "integer", "value": 0}]}},
        "Init_dates": initvar("DatesOK", "boolean", False, ok("Init_conflict")),
        **top,
        "Respond": {"runAfter": {"Route": ["Succeeded", "Failed", "Skipped", "TimedOut"]}, "metadata": mid(), "type": "Response", "kind": "PowerApp",
                    "inputs": {"statusCode": 200,
                               "body": {"status": "@{if(equals(variables('Status'), 'started'), 'failed', variables('Status'))}",
                                        "created": "@{variables('Created')}", "conflicts": "@{variables('Conflict')}", "error": "@{variables('ErrorText')}"},
                               "schema": {"type": "object", "properties": {"status": {"title": "status", "type": "string", "x-ms-dynamically-added": True},
                                                                           "created": {"title": "created", "type": "string", "x-ms-dynamically-added": True},
                                                                           "conflicts": {"title": "conflicts", "type": "string", "x-ms-dynamically-added": True},
                                                                           "error": {"title": "error", "type": "string", "x-ms-dynamically-added": True}}}}},
    },
    "outputs": {}}, CONN_REFS)

# ------------------------------------------------------------------------------------------------------------
# SharePoint trigger flow: every created/modified report -> child flow
# ------------------------------------------------------------------------------------------------------------
trigger = wrap({
    "triggers": {"When_a_report_is_created_or_modified": {
        "recurrence": {"frequency": "Minute", "interval": 1}, "splitOn": "@triggerOutputs()?['body/value']",
        "metadata": mid(), "type": "OpenApiConnection",
        "inputs": {"host": {**SP, "operationId": "GetOnUpdatedItems"}, "parameters": {"dataset": SITE, "table": ABSENCE_LOG},
                   "authentication": "@parameters('$authentication')"}}},
    "actions": {"Process_report": {"runAfter": {}, "metadata": mid(), "type": "Workflow",
                                   "inputs": {"host": {"workflowReferenceName": CHILD_ID}, "body": {"text": "@{triggerOutputs()?['body/ID']}"}}}},
    "outputs": {}}, {"shared_sharepointonline": CONN_REFS["shared_sharepointonline"]})

# ------------------------------------------------------------------------------------------------------------
# Backfill flow (run once): every report since the cut-over -> child flow (already-decided reports are skipped)
# ------------------------------------------------------------------------------------------------------------
backfill = wrap({
    "triggers": {"manual": {"metadata": mid(), "type": "Request", "kind": "Button", "inputs": {"schema": {"type": "object", "properties": {}, "required": []}}}},
    "actions": {
        "All_reports": {"runAfter": {}, "metadata": mid(), "type": "OpenApiConnection",
                        "inputs": {"host": {**SP, "operationId": "GetItems"},
                                   "parameters": {"dataset": SITE, "table": ABSENCE_LOG, "$top": 5000},
                                   "authentication": AUTH},
                        "runtimeConfiguration": {"paginationPolicy": {"minimumItemCount": 20000}}},
        "Each_report": {"runAfter": ok("All_reports"), "metadata": mid(), "type": "Foreach", "foreach": "@body('All_reports')?['value']",
                        "actions": {"Process_one": {"runAfter": {}, "metadata": mid(), "type": "Workflow",
                                                    "inputs": {"host": {"workflowReferenceName": CHILD_ID}, "body": {"text": "@{items('Each_report')?['ID']}"}}}},
                        "runtimeConfiguration": {"concurrency": {"repetitions": 1}}},
    },
    "outputs": {}}, {"shared_sharepointonline": CONN_REFS["shared_sharepointonline"]})

out = os.path.join(os.path.dirname(__file__), "generated")
os.makedirs(out, exist_ok=True)
for fid, name, d in [(CHILD_ID, "AACA - Absence Report Intake", child),
                     (TRIGGER_ID, "AACA - Absence Report Intake (SharePoint)", trigger),
                     (BACKFILL_ID, "AACA - Absence Report Backfill", backfill)]:
    with open(os.path.join(out, f"{fid}.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"workflowid": fid, "name": name, "clientdata": d}, f, indent=1)
print("written to", out)
