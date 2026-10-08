"""Generates the three Teams reminder cloud flows (clientdata JSON) for the AACA Attendance solution.

    python flows/build_reminder_flows.py   -> writes flows/generated/reminders/*.json

1. Teacher Attendance Reminder - school days 10:00 PT: each teacher with students not marked today gets a Teams chat
   from the Flow bot listing them.
2. Office Daily Reminder - school days 15:30 PT: each campus's Attendance Office staff get today's open items
   (attendance not marked, absences to classify, parent/teacher conflicts, transportation not confirmed, Mapping
   Errors). Nothing open = no message.
3. Weekly Site Admin Summary - Fridays 15:00 PT: each campus's Site Administrators get the week's numbers.

School day = the app's rule: a term at the campus covers the date, and (a make-up day) or (a weekday with no closing
calendar exception for the campus or all campuses). Deploy: flows/Deploy-ReminderFlows.ps1. Spec: flows/Reminders.md.
"""
import json
import os
import uuid

SITE = "https://autismacademy.sharepoint.com/sites/FinanceMain"
ABSENCE_LOG = "1058d183-30d4-4fe8-83f6-1c5120edf24f"
CUTOVER = "2026-01-01"      # absences before this are not chased (App Settings ParentReportCutoverDate)
MAKEUP = 582100004          # Calendar Exception type "Make-up School Day"
OFFICE = 582100001          # Staff App Role "Attendance Office"
TZ = "Pacific Standard Time"

TEACHER_ID = "6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e71"
OFFICE_ID = "6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e72"
WEEKLY_ID = "6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e73"

DV = {"connectionName": "shared_commondataserviceforapps", "apiId": "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps"}
SP = {"connectionName": "shared_sharepointonline", "apiId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"}
TEAMS = {"connectionName": "shared_teams", "apiId": "/providers/Microsoft.PowerApps/apis/shared_teams"}
TEAMS_REF = "aaca_sharedteams_reminders"
REF = {
    "shared_commondataserviceforapps": {"runtimeSource": "embedded", "connection": {"connectionReferenceLogicalName": "aaca_sharedcommondataserviceforapps_2b783"}, "api": {"name": "shared_commondataserviceforapps"}},
    "shared_sharepointonline": {"runtimeSource": "embedded", "connection": {"connectionReferenceLogicalName": "aaca_sharedsharepointonline_4204c"}, "api": {"name": "shared_sharepointonline"}},
    "shared_teams": {"runtimeSource": "embedded", "connection": {"connectionReferenceLogicalName": TEAMS_REF}, "api": {"name": "shared_teams"}},
}
AUTH = "@parameters('$authentication')"


def mid():
    return {"operationMetadataId": str(uuid.uuid4())}


def ok(*names):
    return {n: ["Succeeded"] for n in names}


def op(api, operation, params, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "OpenApiConnection",
            "inputs": {"host": {**api, "operationId": operation}, "parameters": params, "authentication": AUTH}}


def dv_list(entity, select, flt, after=None, expand=None):
    p = {"entityName": entity, "$select": select, "$filter": flt}
    if expand:
        p["$expand"] = expand
    return op(DV, "ListRecords", p, after)


def compose(expr, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "Compose", "inputs": expr}


def query(src, where, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "Query", "inputs": {"from": src, "where": where}}


def select(src, value, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "Select", "inputs": {"from": src, "select": value}}


def cond(expr, yes, after=None, no=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "If", "expression": expr, "actions": yes, "else": {"actions": no or {}}}


def foreach(src, actions, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "Foreach", "foreach": src, "actions": actions,
            "runtimeConfiguration": {"concurrency": {"repetitions": 1}}}


def initvar(name, typ, value, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "InitializeVariable", "inputs": {"variables": [{"name": name, "type": typ, "value": value}]}}


def setvar(name, value, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "SetVariable", "inputs": {"name": name, "value": value}}


def addvar(name, value, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "IncrementVariable", "inputs": {"name": name, "value": value}}


def teams(to_expr, html_expr, after=None):
    return op(TEAMS, "PostMessageToConversation", {"poster": "Flow bot", "location": "Chat with Flow bot",
                                                   "body/recipient": to_expr, "body/messageBody": html_expr}, after)


def schedule(days, hour, minute):
    return {"Schedule": {"metadata": mid(), "type": "Recurrence", "recurrence": {
        "frequency": "Week", "interval": 1, "timeZone": TZ,
        "schedule": {"weekDays": days, "hours": [str(hour)], "minutes": [minute]}}}}


def wrap(name, fid, triggers, actions, refs):
    d = {"properties": {"connectionReferences": {r: REF[r] for r in refs}, "definition": {
        "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {"$connections": {"defaultValue": {}, "type": "Object"}, "$authentication": {"defaultValue": {}, "type": "SecureObject"}},
        "triggers": triggers, "actions": actions, "outputs": {}}, "templateName": None}, "schemaVersion": "1.0.0.0"}
    return {"workflowid": fid, "name": name, "clientdata": d}


WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
TODAY = "outputs('Today')"
C = "items('Each_campus')"
CID = f"{C}?['aaca_campusid']"
EMAIL = "coalesce(item()?['aaca_email'], item()?['aaca_user']?['internalemailaddress'])"

common_start = {
    "Today": compose(f"@convertFromUtc(utcNow(), '{TZ}', 'yyyy-MM-dd')"),
    "Campuses": dv_list("aaca_campuses", "aaca_campusid,aaca_name", "aaca_active eq true", ok("Today")),
}


def school_day_checks(day_expr, prefix, after):
    """Actions that decide whether day_expr is a school day at the current campus -> outputs('<prefix>School_day')."""
    return {
        f"{prefix}Term": dv_list("aaca_terms", "aaca_termid",
                                 f"aaca_term ne 582100005 and _aaca_campus_value eq @{{{CID}}} and aaca_startdate le @{{{day_expr}}} and aaca_enddate ge @{{{day_expr}}}", after),
        f"{prefix}Exceptions": dv_list("aaca_calendarexceptions", "aaca_type",
                                       f"aaca_date eq @{{{day_expr}}} and (_aaca_campus_value eq @{{{CID}}} or _aaca_campus_value eq null)", after),
        f"{prefix}Makeup": query(f"@body('{prefix}Exceptions')?['value']", f"@equals(item()?['aaca_type'], {MAKEUP})", ok(f"{prefix}Exceptions")),
        f"{prefix}School_day": compose(
            f"@and(not(empty(body('{prefix}Term')?['value'])), or(not(empty(body('{prefix}Makeup'))), "
            f"and(not(or(equals(dayOfWeek({day_expr}), 0), equals(dayOfWeek({day_expr}), 6))), "
            f"equals(length(body('{prefix}Makeup')), length(body('{prefix}Exceptions')?['value'])))))",
            ok(f"{prefix}Term", f"{prefix}Makeup")),
    }


def unmarked_today(after):
    """Students enrolled at the campus today with no attendance row today -> body('Unmarked') (enrollment rows)."""
    return {
        "Enrolled": dv_list("aaca_enrollments", "_aaca_student_value,_aaca_teacher_value",
                            f"_aaca_campus_value eq @{{{CID}}} and aaca_startdate le @{{{TODAY}}} and (aaca_enddate eq null or aaca_enddate ge @{{{TODAY}}})",
                            after, "aaca_student($select=aaca_displayname),aaca_teacher($select=aaca_name)"),
        "Marked": dv_list("aaca_attendances", "_aaca_student_value",
                          f"_aaca_campus_value eq @{{{CID}}} and aaca_date eq @{{{TODAY}}} and aaca_isdeleted eq false", after),
        "Marked_ids": select("@body('Marked')?['value']", "@item()?['_aaca_student_value']", ok("Marked")),
        "Unmarked": query("@body('Enrolled')?['value']", "@not(contains(body('Marked_ids'), item()?['_aaca_student_value']))", ok("Enrolled", "Marked_ids")),
    }


# ------------------------------------------------------------------------------------------------------------
# 1. Teacher Attendance Reminder (10:00)
# ------------------------------------------------------------------------------------------------------------
per_teacher = {
    "Teacher": dv_list("aaca_staffs", "aaca_name,aaca_email,aaca_active",
                       "aaca_staffid eq @{items('Each_teacher')} and aaca_active eq true", None, "aaca_user($select=internalemailaddress)"),
    "Teacher_email": select("@body('Teacher')?['value']", f"@{EMAIL}", ok("Teacher")),
    "Their_students": query("@body('Unmarked')", "@equals(item()?['_aaca_teacher_value'], items('Each_teacher'))"),
    "Their_names": select("@body('Their_students')", "@item()?['aaca_student']?['aaca_displayname']", ok("Their_students")),
    "Has_email": cond({"and": [{"not": {"equals": ["@empty(first(body('Teacher_email')))", True]}}]}, {
        "Send_teacher": teams("@{first(body('Teacher_email'))}",
                              "<p>Good morning. Attendance for today (@{formatDateTime(outputs('Today'), 'dddd, MMMM d')}) is not marked yet for "
                              "@{length(body('Their_students'))} student(s):</p><p><b>@{join(body('Their_names'), ', ')}</b></p>"
                              "<p>Please open the AACA Attendance app and mark them present. Absences reported by parents are already filled in.</p>")},
        ok("Teacher_email", "Their_names")),
}
teacher_campus = {
    **school_day_checks(TODAY, "", None),
    "If_school_day": cond({"and": [{"equals": ["@outputs('School_day')", True]}]}, {
        **unmarked_today(None),
        "Teacher_ids": select("@body('Unmarked')", "@item()?['_aaca_teacher_value']", ok("Unmarked")),
        "Each_teacher": foreach("@union(body('Teacher_ids'), body('Teacher_ids'))", per_teacher, ok("Teacher_ids")),
    }, ok("School_day")),
}
teacher_flow = wrap("AACA - Teacher Attendance Reminder", TEACHER_ID, schedule(WEEKDAYS, 10, 0), {
    **common_start,
    "Each_campus": foreach("@body('Campuses')?['value']", teacher_campus, ok("Campuses")),
}, ["shared_commondataserviceforapps", "shared_teams"])


# ------------------------------------------------------------------------------------------------------------
# Shared counts for the office and weekly flows (current campus)
# ------------------------------------------------------------------------------------------------------------
def open_items(after):
    return {
        "To_classify": dv_list("aaca_attendances", "aaca_attendanceid",
                               f"_aaca_campus_value eq @{{{CID}}} and aaca_present eq false and aaca_isdeleted eq false and aaca_classification eq null "
                               f"and aaca_date ge {CUTOVER} and aaca_date le @{{{TODAY}}}", after),
        "Conflicts": dv_list("aaca_attendances", "aaca_attendanceid",
                             f"_aaca_campus_value eq @{{{CID}}} and aaca_present eq true and aaca_parentreportedabsent eq true and aaca_isdeleted eq false "
                             f"and aaca_date ge {CUTOVER}", after),
        "Campus_errors": query("@body('Needs_review')?['value']",
                               f"@equals(toLower(trim(coalesce(item()?['SchoolSite'], ''))), toLower({C}?['aaca_name']))", after),
        "Recipients_office": dv_list("aaca_staffs", "aaca_name,aaca_email",
                                     f"_aaca_campus_value eq @{{{CID}}} and aaca_approle eq {OFFICE} and aaca_active eq true", after,
                                     "aaca_user($select=internalemailaddress)"),
        "Recipients_admin": dv_list("aaca_staffs", "aaca_name,aaca_email",
                                    f"_aaca_campus_value eq @{{{CID}}} and aaca_siteadministrator eq true and aaca_active eq true", after,
                                    "aaca_user($select=internalemailaddress)"),
    }


needs_review = {"Needs_review": op(SP, "GetItems", {"dataset": SITE, "table": ABSENCE_LOG, "$filter": "Match_Status eq 'Needs Review'", "$top": 5000},
                                   ok("Campuses"))}

# ------------------------------------------------------------------------------------------------------------
# 2. Office Daily Reminder (15:30)
# ------------------------------------------------------------------------------------------------------------
office_today = {
    **unmarked_today(None),
    **open_items(None),
    "Unmarked_teachers": select("@body('Unmarked')", "@item()?['aaca_teacher']?['aaca_name']", ok("Unmarked")),
    "Transport_active": dv_list("aaca_studenttransports", "_aaca_student_value",
                                f"_aaca_campus_value eq @{{{CID}}} and aaca_startdate le @{{{TODAY}}} and (aaca_enddate eq null or aaca_enddate ge @{{{TODAY}}})"),
    "Transport_logged": dv_list("aaca_transportlogs", "_aaca_student_value", f"_aaca_campus_value eq @{{{CID}}} and aaca_date eq @{{{TODAY}}}"),
    "Logged_ids": select("@body('Transport_logged')?['value']", "@item()?['_aaca_student_value']", ok("Transport_logged")),
    "Enrolled_ids": select("@body('Enrolled')?['value']", "@item()?['_aaca_student_value']", ok("Enrolled")),
    "Transport_open": query("@body('Transport_active')?['value']",
                            "@and(contains(body('Enrolled_ids'), item()?['_aaca_student_value']), not(contains(body('Logged_ids'), item()?['_aaca_student_value'])))",
                            ok("Transport_active", "Logged_ids", "Enrolled_ids")),
    "Total_open": compose("@add(add(add(length(body('Unmarked')), length(body('To_classify')?['value'])), add(length(body('Conflicts')?['value']), length(body('Transport_open')))), length(body('Campus_errors')))",
                          ok("Unmarked", "To_classify", "Conflicts", "Transport_open", "Campus_errors")),
    "Message": compose(
        f"<p>End-of-day check for <b>@{{{C}?['aaca_name']}}</b>, @{{formatDateTime(outputs('Today'), 'dddd, MMMM d')}}:</p><ul>"
        "@{if(greater(length(body('Unmarked')), 0), concat('<li>Attendance not marked: <b>', length(body('Unmarked')), '</b> student(s) (', join(union(body('Unmarked_teachers'), body('Unmarked_teachers')), ', '), ')</li>'), '')}"
        "@{if(greater(length(body('To_classify')?['value']), 0), concat('<li>Absences to classify: <b>', length(body('To_classify')?['value']), '</b></li>'), '')}"
        "@{if(greater(length(body('Conflicts')?['value']), 0), concat('<li>Parent reported absent but marked present (Needs a decision): <b>', length(body('Conflicts')?['value']), '</b></li>'), '')}"
        "@{if(greater(length(body('Transport_open')), 0), concat('<li>Transportation not confirmed today: <b>', length(body('Transport_open')), '</b> student(s)</li>'), '')}"
        "@{if(greater(length(body('Campus_errors')), 0), concat('<li>Parent reports in Mapping Errors: <b>', length(body('Campus_errors')), '</b></li>'), '')}"
        "</ul><p>Please finish these in the AACA Attendance app before the end of the day.</p>",
        ok("Total_open", "Unmarked_teachers")),
    "Anything_open": cond({"and": [{"greater": ["@outputs('Total_open')", 0]}]}, {
        "Office_emails": select("@body('Recipients_office')?['value']", f"@{EMAIL}"),
        "Each_office": foreach("@body('Office_emails')", {
            "Send_office": cond({"and": [{"not": {"equals": ["@empty(item())", True]}}]}, {"Post_office": teams("@{items('Each_office')}", "@{outputs('Message')}")})},
            ok("Office_emails")),
    }, ok("Message", "Recipients_office")),
}
office_campus = {
    **school_day_checks(TODAY, "", None),
    "If_school_day": cond({"and": [{"equals": ["@outputs('School_day')", True]}]}, office_today, ok("School_day")),
}
office_flow = wrap("AACA - Office Daily Reminder", OFFICE_ID, schedule(WEEKDAYS, 15, 30), {
    **common_start, **needs_review,
    "Each_campus": foreach("@body('Campuses')?['value']", office_campus, ok("Needs_review")),
}, ["shared_commondataserviceforapps", "shared_sharepointonline", "shared_teams"])

# ------------------------------------------------------------------------------------------------------------
# 3. Weekly Site Admin Summary (Friday 15:00): this week's Monday..today
# ------------------------------------------------------------------------------------------------------------
DAY = "outputs('Day')"
MONDAY = "outputs('Monday')"
week_day = {
    "Day": compose(f"@addDays({MONDAY}, item(), 'yyyy-MM-dd')"),
    "Day_term": query("@body('Week_terms')?['value']", f"@and(lessOrEquals(item()?['aaca_startdate'], {DAY}), greaterOrEquals(item()?['aaca_enddate'], {DAY}))", ok("Day")),
    "Day_makeup": query("@body('Week_exceptions')?['value']", f"@and(equals(item()?['aaca_date'], {DAY}), equals(item()?['aaca_type'], {MAKEUP}))", ok("Day")),
    "Day_closed": query("@body('Week_exceptions')?['value']", f"@and(equals(item()?['aaca_date'], {DAY}), not(equals(item()?['aaca_type'], {MAKEUP})))", ok("Day")),
    "Day_school": compose(f"@and(not(empty(body('Day_term'))), or(not(empty(body('Day_makeup'))), and(not(or(equals(dayOfWeek({DAY}), 0), equals(dayOfWeek({DAY}), 6))), empty(body('Day_closed')))))",
                          ok("Day_term", "Day_makeup", "Day_closed")),
    "If_school": cond({"and": [{"equals": ["@outputs('Day_school')", True]}]}, {
        "Count_day": addvar("SchoolDays", 1),
        "Day_enrolled": query("@body('Week_enrolled')?['value']",
                              f"@and(lessOrEquals(item()?['aaca_startdate'], {DAY}), or(equals(item()?['aaca_enddate'], null), greaterOrEquals(item()?['aaca_enddate'], {DAY})))"),
        "Day_enrolled_ids": select("@body('Day_enrolled')", "@item()?['_aaca_student_value']", ok("Day_enrolled")),
        "Day_marked": query("@body('Week_attendance')?['value']", f"@equals(item()?['aaca_date'], {DAY})"),
        "Day_marked_ids": select("@body('Day_marked')", "@item()?['_aaca_student_value']", ok("Day_marked")),
        "Day_unmarked": query("@body('Day_enrolled_ids')", "@not(contains(body('Day_marked_ids'), item()))", ok("Day_enrolled_ids", "Day_marked_ids")),
        "Add_unmarked": addvar("UnmarkedDays", "@length(body('Day_unmarked'))", ok("Day_unmarked")),
        "Day_transport": query("@body('Week_transport')?['value']",
                               f"@and(lessOrEquals(item()?['aaca_startdate'], {DAY}), or(equals(item()?['aaca_enddate'], null), greaterOrEquals(item()?['aaca_enddate'], {DAY})), contains(body('Day_enrolled_ids'), item()?['_aaca_student_value']))",
                               ok("Day_enrolled_ids")),
        "Day_logged": query("@body('Week_logs')?['value']", f"@equals(item()?['aaca_date'], {DAY})"),
        "Day_logged_ids": select("@body('Day_logged')", "@item()?['_aaca_student_value']", ok("Day_logged")),
        "Day_transport_open": query("@body('Day_transport')", "@not(contains(body('Day_logged_ids'), item()?['_aaca_student_value']))", ok("Day_transport", "Day_logged_ids")),
        "Add_transport": addvar("TransportOpen", "@length(body('Day_transport_open'))", ok("Day_transport_open", "Add_unmarked")),
    }, ok("Day_school")),
}
WEEK_RANGE = f"le @{{{TODAY}}} and aaca_enddate ge @{{{MONDAY}}}"
weekly_campus = {
    "Reset_days": setvar("SchoolDays", 0),
    "Reset_unmarked": setvar("UnmarkedDays", 0, ok("Reset_days")),
    "Reset_transport": setvar("TransportOpen", 0, ok("Reset_unmarked")),
    "Week_terms": dv_list("aaca_terms", "aaca_startdate,aaca_enddate", f"aaca_term ne 582100005 and _aaca_campus_value eq @{{{CID}}} and aaca_startdate {WEEK_RANGE}", ok("Reset_transport")),
    "Week_exceptions": dv_list("aaca_calendarexceptions", "aaca_date,aaca_type",
                               f"aaca_date ge @{{{MONDAY}}} and aaca_date le @{{{TODAY}}} and (_aaca_campus_value eq @{{{CID}}} or _aaca_campus_value eq null)", ok("Reset_transport")),
    "Week_enrolled": dv_list("aaca_enrollments", "_aaca_student_value,aaca_startdate,aaca_enddate",
                             f"_aaca_campus_value eq @{{{CID}}} and aaca_startdate le @{{{TODAY}}} and (aaca_enddate eq null or aaca_enddate ge @{{{MONDAY}}})", ok("Reset_transport")),
    "Week_attendance": dv_list("aaca_attendances", "_aaca_student_value,aaca_date",
                               f"_aaca_campus_value eq @{{{CID}}} and aaca_date ge @{{{MONDAY}}} and aaca_date le @{{{TODAY}}} and aaca_isdeleted eq false", ok("Reset_transport")),
    "Week_transport": dv_list("aaca_studenttransports", "_aaca_student_value,aaca_startdate,aaca_enddate",
                              f"_aaca_campus_value eq @{{{CID}}} and aaca_startdate le @{{{TODAY}}} and (aaca_enddate eq null or aaca_enddate ge @{{{MONDAY}}})", ok("Reset_transport")),
    "Week_logs": dv_list("aaca_transportlogs", "_aaca_student_value,aaca_date",
                         f"_aaca_campus_value eq @{{{CID}}} and aaca_date ge @{{{MONDAY}}} and aaca_date le @{{{TODAY}}}", ok("Reset_transport")),
    **open_items(ok("Reset_transport")),
    "Each_day": foreach("@range(0, add(dayOfWeek(outputs('Today')), 0))", week_day,
                        ok("Week_terms", "Week_exceptions", "Week_enrolled", "Week_attendance", "Week_transport", "Week_logs")),
    "Summary": compose(
        f"<p>Weekly summary for <b>@{{{C}?['aaca_name']}}</b>, week of @{{formatDateTime(outputs('Monday'), 'MMMM d')}} "
        "(@{variables('SchoolDays')} school day(s)):</p><ul>"
        "<li>Student-days with attendance not marked: <b>@{variables('UnmarkedDays')}</b></li>"
        "<li>Student-days with transportation not confirmed: <b>@{variables('TransportOpen')}</b></li>"
        "<li>Absences still to classify (all dates): <b>@{length(body('To_classify')?['value'])}</b></li>"
        "<li>Parent reported absent but marked present (Needs a decision): <b>@{length(body('Conflicts')?['value'])}</b></li>"
        "<li>Parent reports in Mapping Errors: <b>@{length(body('Campus_errors'))}</b></li>"
        "</ul><p>Details are in the AACA Attendance app (Absences and Transportation).</p>",
        ok("Each_day", "To_classify", "Conflicts", "Campus_errors")),
    "Admin_emails": select("@body('Recipients_admin')?['value']", f"@{EMAIL}", ok("Recipients_admin")),
    "Each_admin": foreach("@body('Admin_emails')", {
        "Send_admin": cond({"and": [{"not": {"equals": ["@empty(item())", True]}}]}, {"Post_admin": teams("@{items('Each_admin')}", "@{outputs('Summary')}")})},
        ok("Summary", "Admin_emails")),
}
weekly_flow = wrap("AACA - Weekly Site Admin Summary", WEEKLY_ID, schedule(["Friday"], 15, 0), {
    **common_start, **needs_review,
    # Monday of this week (the flow runs on Friday; dayOfWeek: Sunday = 0).
    "Monday": compose("@addDays(outputs('Today'), sub(1, dayOfWeek(outputs('Today'))), 'yyyy-MM-dd')", ok("Today")),
    "Init_days": initvar("SchoolDays", "integer", 0, ok("Monday")),
    "Init_unmarked": initvar("UnmarkedDays", "integer", 0, ok("Init_days")),
    "Init_transport": initvar("TransportOpen", "integer", 0, ok("Init_unmarked")),
    "Each_campus": foreach("@body('Campuses')?['value']", weekly_campus, ok("Needs_review", "Init_transport")),
}, ["shared_commondataserviceforapps", "shared_sharepointonline", "shared_teams"])

out = os.path.join(os.path.dirname(__file__), "generated", "reminders")
os.makedirs(out, exist_ok=True)
for f in (teacher_flow, office_flow, weekly_flow):
    with open(os.path.join(out, f"{f['workflowid']}.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(f, fh, indent=1)
print("written to", out)
