"""Phase 2 step B: generates the three Absence Notice flows (clientdata JSON) for the AACA Attendance solution.

    python flows/build_notice_flows.py   -> writes flows/generated/notices/*.json   (deploy: flows/Deploy-NoticeFlows.ps1)

1. AACA - Website Absence Intake (HTTP, anyone): the parent website form posts {"data": {FN, LN, DOA, RETURN, School,
   Reason, DN, PN, Relationship}}. Validates, matches the student (active enrollment at that campus on the absence date,
   first + last name ignoring case, extra spaces and hyphen/space differences), creates an Absence Notice
   (Notice At = time received) and answers 200 {ok, reference} or 400 {ok: false, error}.
2. AACA - Absence Notice Alert (Dataverse: notice added, not imported): the campus "ABSENCE ALERT" Teams card, with the
   match result and an Open in app button. Posts to Campus.Absence Teams Chat ID; when that is blank, to the
   AbsenceAlertFallbackEmail App Setting (Dev testing); otherwise nothing.
3. AACA - Absence Notice Processing (Dataverse: notice added/modified, New + Matched/Mapped + student set): one absence
   per school day from Absence Start up to (not incl.) Return Date where the student is enrolled; a teacher's present
   mark is never overwritten (flagged for Needs a decision); a deleted row is revived. Writes the result on the notice.
Plan: docs/app-builds/build-12-billing-phase2/plan.md
"""
import json
import os
import uuid

MAX_DAYS = 60
MAKEUP = 582100004                       # Calendar Exception type "Make-up School Day"
SRC_PARENT, SRC_OFFICE = 582100001, 582100002   # Attendance source
N_NEW, N_ACCEPTED = 582100000, 582100001        # Absence Notice status
M_MATCHED, M_UNMATCHED, M_AMBIG, M_MAPPED = 582100000, 582100001, 582100002, 582100003
S_WEBSITE, S_OFFICE, S_PORTAL, S_IMPORT = 582100000, 582100001, 582100002, 582100003
TZ = "Pacific Standard Time"

INTAKE_ID = "6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e91"
ALERT_ID = "6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e92"
PROCESS_ID = "6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e93"

DV = {"connectionName": "shared_commondataserviceforapps", "apiId": "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps"}
TEAMS = {"connectionName": "shared_teams", "apiId": "/providers/Microsoft.PowerApps/apis/shared_teams"}
REF = {
    "shared_commondataserviceforapps": {"runtimeSource": "embedded", "connection": {"connectionReferenceLogicalName": "aaca_sharedcommondataserviceforapps_2b783"}, "api": {"name": "shared_commondataserviceforapps"}},
    "shared_teams": {"runtimeSource": "embedded", "connection": {"connectionReferenceLogicalName": "aaca_sharedteams_reminders"}, "api": {"name": "shared_teams"}},
}
AUTH = "@parameters('$authentication')"


def mid():
    return {"operationMetadataId": str(uuid.uuid4())}


def ok(*names):
    return {n: ["Succeeded"] for n in names}


def op(api, operation, params, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "OpenApiConnection",
            "inputs": {"host": {**api, "operationId": operation}, "parameters": params, "authentication": AUTH}}


def dv_list(entity, select, flt, after=None, expand=None, top=None):
    p = {"entityName": entity, "$select": select, "$filter": flt}
    if expand:
        p["$expand"] = expand
    if top:
        p["$top"] = top
    return op(DV, "ListRecords", p, after)


def compose(expr, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "Compose", "inputs": expr}


def query(src, where, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "Query", "inputs": {"from": src, "where": where}}


def select(src, value, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "Select", "inputs": {"from": src, "select": value}}


def cond(expr, yes, after=None, no=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "If", "expression": expr, "actions": yes, "else": {"actions": no or {}}}


def initvar(name, typ, value, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "InitializeVariable", "inputs": {"variables": [{"name": name, "type": typ, "value": value}]}}


def incr(name, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "IncrementVariable", "inputs": {"name": name, "value": 1}}


def respond(status, body, after):
    return {"runAfter": after, "metadata": mid(), "type": "Response", "kind": "Http",
            "inputs": {"statusCode": status, "headers": {"Content-Type": "application/json"}, "body": body}}


def wrap(name, fid, triggers, actions, refs):
    d = {"properties": {"connectionReferences": {r: REF[r] for r in refs}, "definition": {
        "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {"$connections": {"defaultValue": {}, "type": "Object"}, "$authentication": {"defaultValue": {}, "type": "SecureObject"}},
        "triggers": triggers, "actions": actions, "outputs": {}}, "templateName": None}, "schemaVersion": "1.0.0.0"}
    return {"workflowid": fid, "name": name, "clientdata": d}


def dv_trigger(name, message, flt, attrs=None):
    p = {"subscriptionRequest/message": message, "subscriptionRequest/entityname": "aaca_absencenotice",
         "subscriptionRequest/scope": 4, "subscriptionRequest/filterexpression": flt}
    if attrs:
        p["subscriptionRequest/filteringattributes"] = attrs
    return {name: {"metadata": mid(), "type": "OpenApiConnectionWebhook",
                   "inputs": {"host": {**DV, "operationId": "SubscribeWebhookTrigger"}, "parameters": p, "authentication": AUTH}}}


def norm(x):
    """Name comparison: lower case, trimmed, hyphens as spaces, double spaces collapsed."""
    return f"toLower(trim(replace(replace(replace(coalesce({x}, ''), '-', ' '), '  ', ' '), '  ', ' ')))"


# ============================================================================================================
# 1. Website Absence Intake
# ============================================================================================================
D = "triggerBody()?['data']"
FN, LN, SCHOOL = f"{D}?['FN']", f"{D}?['LN']", f"{D}?['School']"
CAMPUS = "first(body('Campus')?['value'])"
ABS, RET = "outputs('Absence_date')", "outputs('Return_date')"
UNIQUE = "union(body('Match_ids'), body('Match_ids'))"
COUNT = f"length({UNIQUE})"
ITEM_FN = norm("item()?['aaca_student']?['aaca_firstname']")
ITEM_LN = norm("item()?['aaca_student']?['aaca_lastname']")

intake_valid = {
    "Enrollments_on_day": dv_list("aaca_enrollments", "_aaca_student_value",
                                  f"_aaca_campus_value eq @{{{CAMPUS}?['aaca_campusid']}} and aaca_startdate le @{{{ABS}}} and (aaca_enddate eq null or aaca_enddate ge @{{{ABS}}})",
                                  None, "aaca_student($select=aaca_studentid,aaca_firstname,aaca_lastname,aaca_status)"),
    "Name_matches": query("@body('Enrollments_on_day')?['value']",
                          f"@and(equals({ITEM_FN}, {norm(FN)}), equals({ITEM_LN}, {norm(LN)}), not(equals(item()?['aaca_student']?['aaca_status'], 582100002)))",
                          ok("Enrollments_on_day")),
    "Match_ids": select("@body('Name_matches')", "@item()?['_aaca_student_value']", ok("Name_matches")),
    "Create_notice": op(DV, "CreateRecord", {
        "entityName": "aaca_absencenotices",
        "item/aaca_name": f"@{{take(concat(trim({FN}), ' ', trim({LN}), ' - absent ', formatDateTime({ABS}, 'M/d/yyyy')), 200)}}",
        "item/aaca_source": S_WEBSITE,
        "item/aaca_status": N_NEW,
        "item/aaca_noticeat": "@{trigger()?['startTime']}",
        "item/aaca_websitesubmittedat": f"@if(empty(coalesce({D}?['DN'], '')), null, {D}?['DN'])",
        "item/aaca_absencestart": f"@{{{ABS}}}",
        "item/aaca_absenceend": f"@{{addDays({RET}, -1, 'yyyy-MM-dd')}}",
        "item/aaca_returndate": f"@{{{RET}}}",
        "item/aaca_typedfirstname": f"@{{take(trim({FN}), 100)}}",
        "item/aaca_typedlastname": f"@{{take(trim({LN}), 100)}}",
        "item/aaca_typedcampus": f"@{{take(trim({SCHOOL}), 100)}}",
        "item/aaca_parentname": f"@{{take(trim(coalesce({D}?['PN'], '')), 200)}}",
        "item/aaca_relationshiptext": f"@{{take(trim(coalesce({D}?['Relationship'], '')), 100)}}",
        "item/aaca_reasontext": f"@{{take(coalesce({D}?['Reason'], ''), 4000)}}",
        "item/aaca_matchstatus": f"@if(equals({COUNT}, 1), {M_MATCHED}, if(equals({COUNT}, 0), {M_UNMATCHED}, {M_AMBIG}))",
        "item/aaca_matchdetail": (f"@{{if(equals({COUNT}, 1), 'Matched on name and campus', if(equals({COUNT}, 0), "
                                  f"concat('No student enrolled at ', {CAMPUS}?['aaca_name'], ' on that date with this name'), "
                                  f"concat({COUNT}, ' students at ', {CAMPUS}?['aaca_name'], ' have this name')))}}"),
        "item/aaca_campus@odata.bind": f"@{{concat('/aaca_campuses(', {CAMPUS}?['aaca_campusid'], ')')}}",
        "item/aaca_student@odata.bind": f"@if(equals({COUNT}, 1), concat('/aaca_students(', first({UNIQUE}), ')'), null)",
        "item/ownerid@odata.bind": f"@if(empty({CAMPUS}?['aaca_ownerteamid']), null, concat('/teams(', {CAMPUS}?['aaca_ownerteamid'], ')'))",
    }, ok("Match_ids")),
    "Accepted": respond(200, {"ok": True, "reference": "@{body('Create_notice')?['aaca_reference']}"}, ok("Create_notice")),
    "Save_failed": respond(500, {"ok": False, "error": "The absence could not be saved. Please call the school office."}, {"Create_notice": ["Failed", "TimedOut"]}),
}
intake = wrap("AACA - Website Absence Intake", INTAKE_ID,
              {"manual": {"metadata": mid(), "type": "Request", "kind": "Http", "inputs": {"triggerAuthenticationType": "All", "schema": {
                  "type": "object", "properties": {"data": {"type": "object", "properties": {
                      k: {"type": "string"} for k in ("FN", "LN", "DOA", "RETURN", "School", "Reason", "DN", "PN", "Relationship")}}}}}}},
              {
                  "Campus": dv_list("aaca_campuses", "aaca_campusid,aaca_name,aaca_ownerteamid",
                                    f"aaca_active eq true and aaca_name eq '@{{replace(trim(coalesce({SCHOOL}, '')), '''', '''''')}}'", top=1),
                  "Check": {"runAfter": ok("Campus"), "metadata": mid(), "type": "Scope", "actions": {
                      "Absence_date": compose(f"@formatDateTime({D}?['DOA'], 'yyyy-MM-dd')"),
                      "Return_date": compose(f"@if(empty(trim(coalesce({D}?['RETURN'], ''))), addDays({ABS}, 1, 'yyyy-MM-dd'), formatDateTime({D}?['RETURN'], 'yyyy-MM-dd'))",
                                             ok("Absence_date")),
                      "Is_valid": compose(f"@and(not(empty(trim(coalesce({FN}, '')))), not(empty(trim(coalesce({LN}, '')))), "
                                          f"not(empty(body('Campus')?['value'])), greater({RET}, {ABS}), "
                                          f"lessOrEquals(div(sub(ticks({RET}), ticks({ABS})), 864000000000), {MAX_DAYS}))", ok("Return_date")),
                  }},
                  "Bad_request": respond(400, {"ok": False, "error": "Missing or invalid name, school or dates."}, {"Check": ["Failed", "TimedOut"]}),
                  "If_valid": cond({"and": [{"equals": ["@outputs('Is_valid')", True]}]}, intake_valid, ok("Check"),
                                   {"Invalid": respond(400, {"ok": False, "error": "Missing or invalid name, school or dates."}, {})}),
              }, ["shared_commondataserviceforapps"])

# ============================================================================================================
# 2. Absence Notice Alert (Teams card for every new notice except imported history)
# ============================================================================================================
B = "triggerOutputs()?['body']"
SET = "body('Settings')?['value']"


def setting(key):
    return f"coalesce(first(body('Setting_{key}'))?['aaca_value'], '')"


app_url = setting("AttendanceAppUrl")
open_url = f"@{{concat({app_url}, if(contains({app_url}, '?'), '&', '?'), 'screen=absences')}}"
# Matched: the student's name as the app has it; otherwise what the parent typed.
student_name = (f"coalesce(first(body('Matched_student')?['value'])?['aaca_displayname'], "
                f"concat({B}?['aaca_typedfirstname'], ' ', {B}?['aaca_typedlastname']))")
matched = f"or(equals({B}?['aaca_matchstatus'], {M_MATCHED}), equals({B}?['aaca_matchstatus'], {M_MAPPED}))"


def tb(text, tid, **kw):
    return {"type": "TextBlock", "text": text, "wrap": True, "id": tid, "weight": "Bolder", "color": "Accent", **kw}


card = {
    "type": "AdaptiveCard", "$schema": "https://adaptivecards.io/schemas/adaptive-card.json", "version": "1.5",
    "body": [{
        "type": "Container", "showBorder": True, "roundedCorners": True, "style": "warning", "bleed": True, "id": "con_Container", "rtl": False,
        "backgroundImage": {"url": "@{" + setting("AbsenceAlertImageUrl") + "}"},
        "items": [
            {"type": "Badge", "size": "ExtraLarge", "text": "ABSENCE ALERT", "horizontalAlignment": "Center", "id": "icn_Absence", "shape": "Rounded"},
            {"type": "ProgressBar", "id": "lbl_Progress", "spacing": "Small", "horizontalAlignment": "Center"},
            tb(f"Date Notified: @{{formatDateTime(convertFromUtc({B}?['aaca_noticeat'], '{TZ}'), 'MM/dd/yyyy - h:mm tt')}}", "txt_date"),
            tb(f"Student Name: @{{{student_name}}}", "txt_student"),
            {"type": "TextBlock", "wrap": True, "id": "txt_match", "weight": "Bolder",
             "color": f"@{{if({matched}, 'Good', 'Attention')}}",
             "text": f"@{{if({matched}, 'Matched to this student in the attendance app', 'Could not match this student - map it in the app (Absences > Mapping Errors)')}}"},
            tb(f"Submitted By: @{{if(equals({B}?['aaca_source'], {S_OFFICE}), concat('Office - ', coalesce({B}?['_createdby_value@OData.Community.Display.V1.FormattedValue'], 'staff')), {B}?['aaca_parentname'])}}", "txt_SubBy"),
            tb(f"Relationship to Student: @{{if(empty(coalesce({B}?['aaca_relationshiptext'], '')), '-', {B}?['aaca_relationshiptext'])}}", "txt_Relationship"),
            tb(f"Date of Absence: @{{formatDateTime({B}?['aaca_absencestart'], 'MM/dd/yyyy')}}", "txt_DOA"),
            tb(f"Expected Date of Return: @{{if(empty({B}?['aaca_returndate']), '-', formatDateTime({B}?['aaca_returndate'], 'MM/dd/yyyy'))}}", "txt_DOR"),
            tb(f"Reason: @{{coalesce({B}?['aaca_reasontext'], '')}}", "txt_Reason"),
            tb(f"Reference: @{{{B}?['aaca_reference']}}", "txt_Ref"),
            {"type": "TextBlock", "text": "This alert is for your own awareness, nothing further is required.", "wrap": True, "color": "Attention",
             "id": "txt_footer", "horizontalAlignment": "Center", "weight": "Lighter"},
        ]}],
    "actions": [{"type": "Action.OpenUrl", "title": "Open in app", "url": open_url}],
}
card_text = json.dumps(card, indent=2)
post_params = {"poster": "Flow bot", "body/messageBody": card_text}

alert = wrap("AACA - Absence Notice Alert", ALERT_ID,
             dv_trigger("When_a_notice_is_added", 1, f"aaca_source ne {S_IMPORT}"),
             {
                 "Campus": op(DV, "GetItem", {"entityName": "aaca_campuses", "recordId": f"@{B}?['_aaca_campus_value']", "$select": "aaca_name,aaca_absencechatid"}),
                 "Matched_student": dv_list("aaca_students", "aaca_displayname",
                                            f"aaca_studentid eq @{{coalesce({B}?['_aaca_student_value'], '00000000-0000-0000-0000-000000000000')}}", top=1),
                 "Settings": dv_list("aaca_settings", "aaca_key,aaca_value",
                                     "aaca_key eq 'AttendanceAppUrl' or aaca_key eq 'AbsenceAlertImageUrl' or aaca_key eq 'AbsenceAlertFallbackEmail'"),
                 **{f"Setting_{k}": query(f"@{SET}", f"@equals(item()?['aaca_key'], '{k}')", ok("Settings"))
                    for k in ("AttendanceAppUrl", "AbsenceAlertImageUrl", "AbsenceAlertFallbackEmail")},
                 "Where_to_post": {"runAfter": ok("Campus", "Matched_student", "Setting_AttendanceAppUrl", "Setting_AbsenceAlertImageUrl", "Setting_AbsenceAlertFallbackEmail"),
                                   "metadata": mid(), "type": "Switch",
                                   "expression": (f"@if(not(empty(coalesce(body('Campus')?['aaca_absencechatid'], ''))), 'chat', "
                                                  f"if(not(empty({setting('AbsenceAlertFallbackEmail')})), 'fallback', 'none'))"),
                                   "cases": {
                                       "Campus_chat": {"case": "chat", "actions": {"Post_to_campus_chat": op(TEAMS, "PostCardToConversation", {
                                           **post_params, "location": "Group chat", "body/recipient": "@{body('Campus')?['aaca_absencechatid']}"})}},
                                       "Fallback": {"case": "fallback", "actions": {"Post_to_fallback": op(TEAMS, "PostCardToConversation", {
                                           **post_params, "location": "Chat with Flow bot", "body/recipient": "@{" + setting("AbsenceAlertFallbackEmail") + "}"})}},
                                   },
                                   "default": {"actions": {}}},
             }, ["shared_commondataserviceforapps", "shared_teams"])

# ============================================================================================================
# 3. Absence Notice Processing (attendance days from a matched notice)
# ============================================================================================================
DAY = "outputs('Day')"
ENR = "outputs('Enrollment')"
START = "outputs('Start')"
day_loop = {
    "Day": compose(f"@addDays({START}, item(), 'yyyy-MM-dd')"),
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
EXIST = "first(body('Existing_on_day'))"
NOTICE_BIND = f"@{{concat('/aaca_absencenotices(', {B}?['aaca_absencenoticeid'], ')')}}"
NOTES = f"@{{take(concat('Parent report ', coalesce({B}?['aaca_reference'], ''), ': ', coalesce({B}?['aaca_reasontext'], '')), 2000)}}"
new_row = {
    "entityName": "aaca_attendances",
    "item/aaca_recordkey": f"@{{concat(replace({DAY}, '-', ''), '|', body('Student')?['aaca_studentnumber'], '|SPED')}}",
    "item/aaca_date": f"@{{{DAY}}}",
    "item/aaca_present": False,
    "item/aaca_isdeleted": False,
    "item/aaca_source": f"@if(equals({B}?['aaca_source'], {S_OFFICE}), {SRC_OFFICE}, {SRC_PARENT})",
    "item/aaca_noticereceivedon": f"@{{{B}?['aaca_noticeat']}}",
    "item/aaca_notes": NOTES,
    "item/aaca_absencenotice@odata.bind": NOTICE_BIND,
    "item/aaca_student@odata.bind": f"@{{concat('/aaca_students(', {B}?['_aaca_student_value'], ')')}}",
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
    "Existing_on_day": query("@body('Attendance_in_range')?['value']", f"@equals(item()?['aaca_date'], {DAY})"),
    "Which_case": {
        "runAfter": ok("Existing_on_day"), "metadata": mid(), "type": "Switch",
        "expression": f"@if(empty(body('Existing_on_day')), 'new', if(equals({EXIST}?['aaca_isdeleted'], true), 'deleted', if(equals({EXIST}?['aaca_present'], true), 'present', 'absent')))",
        "cases": {
            "New": {"case": "new", "actions": {"Create_absence": op(DV, "CreateRecord", new_row), "Count_created": incr("Created", ok("Create_absence"))}},
            "Deleted": {"case": "deleted", "actions": {
                "Revive_as_absence": op(DV, "UpdateRecord", {
                    "entityName": "aaca_attendances", "recordId": f"@{EXIST}?['aaca_attendanceid']",
                    "item/aaca_present": False, "item/aaca_isdeleted": False, "item/aaca_source": new_row["item/aaca_source"],
                    "item/aaca_noticereceivedon": new_row["item/aaca_noticereceivedon"], "item/aaca_notes": NOTES,
                    "item/aaca_absencenotice@odata.bind": NOTICE_BIND}),
                "Count_revived": incr("Created", ok("Revive_as_absence"))}},
            "Present": {"case": "present", "actions": {
                # The teacher already marked present: never overwrite; flag it for the office (Needs a decision).
                "Flag_conflict": op(DV, "UpdateRecord", {
                    "entityName": "aaca_attendances", "recordId": f"@{EXIST}?['aaca_attendanceid']",
                    "item/aaca_parentreportedabsent": True, "item/aaca_noticereceivedon": new_row["item/aaca_noticereceivedon"],
                    "item/aaca_absencenotice@odata.bind": NOTICE_BIND}),
                "Count_conflict": incr("Conflict", ok("Flag_conflict"))}},
        },
        "default": {"actions": {"Count_already_absent": incr("Skipped")}},
    },
}
day_loop["School_day_check"] = cond({"and": [{"equals": ["@outputs('Is_school_day')", True]}]}, school_day_yes, ok("Is_school_day"),
                                    {"Count_not_school_day": incr("Skipped")})
LAST = "outputs('LastDay')"
work = {
    "Start": compose(f"@formatDateTime({B}?['aaca_absencestart'], 'yyyy-MM-dd')"),
    "EndExclusive": compose(f"@if(or(empty({B}?['aaca_returndate']), lessOrEquals(formatDateTime({B}?['aaca_returndate'], 'yyyy-MM-dd'), {START})), "
                            f"addDays({START}, 1, 'yyyy-MM-dd'), formatDateTime({B}?['aaca_returndate'], 'yyyy-MM-dd'))", ok("Start")),
    "LastDay": compose("@addDays(outputs('EndExclusive'), -1, 'yyyy-MM-dd')", ok("EndExclusive")),
    "DayCount": compose(f"@min({MAX_DAYS}, div(sub(ticks(outputs('EndExclusive')), ticks({START})), 864000000000))", ok("LastDay")),
    "Student": op(DV, "GetItem", {"entityName": "aaca_students", "recordId": f"@{B}?['_aaca_student_value']", "$select": "aaca_studentnumber"}),
    "Enrollments": dv_list("aaca_enrollments", "aaca_enrollmentid,aaca_startdate,aaca_enddate,aaca_iepratio,_aaca_campus_value,_aaca_teacher_value,_aaca_schoolyear_value",
                           f"_aaca_student_value eq @{{{B}?['_aaca_student_value']}} and aaca_startdate le @{{{LAST}}} and (aaca_enddate eq null or aaca_enddate ge @{{{START}}})",
                           ok("DayCount"), "aaca_campus($select=aaca_ownerteamid)"),
    "Terms": dv_list("aaca_terms", "aaca_termid,aaca_startdate,aaca_enddate,_aaca_campus_value",
                     f"aaca_startdate le @{{{LAST}}} and aaca_enddate ge @{{{START}}}", ok("DayCount")),
    "Exceptions": dv_list("aaca_calendarexceptions", "aaca_date,aaca_type,_aaca_campus_value",
                          f"aaca_date ge @{{{START}}} and aaca_date le @{{{LAST}}}", ok("DayCount")),
    "SPED": dv_list("aaca_services", "aaca_serviceid", "aaca_servicecode eq 'SPED'", top=1),
    "Attendance_in_range": dv_list("aaca_attendances", "aaca_attendanceid,aaca_date,aaca_present,aaca_isdeleted",
                                   f"_aaca_student_value eq @{{{B}?['_aaca_student_value']}} and aaca_date ge @{{{START}}} and aaca_date le @{{{LAST}}}", ok("DayCount")),
    "Each_day": {"runAfter": ok("Student", "Enrollments", "Terms", "Exceptions", "SPED", "Attendance_in_range"), "metadata": mid(),
                 "type": "Foreach", "foreach": "@range(0, outputs('DayCount'))", "actions": day_loop,
                 "runtimeConfiguration": {"concurrency": {"repetitions": 1}}},
}
process = wrap("AACA - Absence Notice Processing", PROCESS_ID,
               dv_trigger("When_a_matched_notice_is_ready", 4,
                          f"aaca_status eq {N_NEW} and _aaca_student_value ne null and (aaca_matchstatus eq {M_MATCHED} or aaca_matchstatus eq {M_MAPPED})",
                          "aaca_matchstatus,aaca_student"),
               {
                   "Init_created": initvar("Created", "integer", 0),
                   "Init_skipped": initvar("Skipped", "integer", 0, ok("Init_created")),
                   "Init_conflict": initvar("Conflict", "integer", 0, ok("Init_skipped")),
                   "Process": {"runAfter": ok("Init_conflict"), "metadata": mid(), "type": "Scope", "actions": work},
                   "Mark_accepted": op(DV, "UpdateRecord", {
                       "entityName": "aaca_absencenotices", "recordId": f"@{B}?['aaca_absencenoticeid']",
                       "item/aaca_status": N_ACCEPTED, "item/aaca_processedon": "@{utcNow()}",
                       "item/aaca_dayscreated": "@variables('Created')", "item/aaca_daysskipped": "@variables('Skipped')",
                       "item/aaca_daysconflict": "@variables('Conflict')", "item/aaca_errordetail": ""}, ok("Process")),
                   "Record_error": op(DV, "UpdateRecord", {
                       "entityName": "aaca_absencenotices", "recordId": f"@{B}?['aaca_absencenoticeid']",
                       "item/aaca_errordetail": "@{take(concat('Could not create the absence days: ', coalesce(string(result('Process')), '')), 2000)}"},
                       {"Process": ["Failed", "TimedOut"]}),
               }, ["shared_commondataserviceforapps"])

out = os.path.join(os.path.dirname(__file__), "generated", "notices")
os.makedirs(out, exist_ok=True)
for f in (intake, alert, process):
    with open(os.path.join(out, f"{f['workflowid']}.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(f, fh, indent=1)
print("written to", out)
