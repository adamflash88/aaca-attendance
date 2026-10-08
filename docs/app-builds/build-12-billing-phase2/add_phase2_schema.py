"""Phase 2 (step A): adds the absence-notice, billing-rule and billing-day schema to schema/tables.json. Idempotent.
Apply with provisioning/Deploy-Schema.ps1. Plan: docs/app-builds/build-12-billing-phase2/plan.md
"""
import json
import os

P = os.path.join(os.path.dirname(__file__), "..", "..", "..", "schema", "tables.json")
t = json.load(open(P, encoding="utf-8"))
T = {x["logicalName"]: x for x in t["tables"]}


def addcols(table, cols):
    have = {c["logicalName"] for c in T[table]["columns"]}
    T[table]["columns"] += [c for c in cols if c["logicalName"] not in have]


def addlookups(ls):
    have = {(l["table"], l["logicalName"]) for l in t["lookups"]}
    t["lookups"] += [l for l in ls if (l["table"], l["logicalName"]) not in have]


# Absence Notice: one record per absence report from any source
an = T["aaca_absencenotice"]
an["description"] = ("An absence report from any source (website form, office entry, family portal, SharePoint import). "
                     "Notice At is the official notice time for billing. A flow matches the student and creates the attendance days.")
addcols("aaca_absencenotice", [
    {"logicalName": "aaca_reference", "type": "autonumber", "displayName": "Reference", "format": "ABS-{DATETIMEUTC:yyyy}-{SEQNUM:6}", "maxLength": 30},
    {"logicalName": "aaca_source", "type": "choice", "displayName": "Source",
     "options": [[582100000, "Website form"], [582100001, "Office"], [582100002, "Family portal"], [582100003, "SharePoint import"]]},
    {"logicalName": "aaca_noticeat", "type": "datetime", "displayName": "Notice At",
     "description": "Official notice time for the billing rules: time received (website), time the parent told the office (office), submitted (portal), Date Notified (import)."},
    {"logicalName": "aaca_websitesubmittedat", "type": "datetime", "displayName": "Website Submitted At",
     "description": "The website's own submission stamp (DN), for reference."},
    {"logicalName": "aaca_returndate", "type": "date", "displayName": "Return Date",
     "description": "Expected date of return as given (the student is back that day)."},
    {"logicalName": "aaca_typedfirstname", "type": "text", "displayName": "Typed First Name", "maxLength": 100},
    {"logicalName": "aaca_typedlastname", "type": "text", "displayName": "Typed Last Name", "maxLength": 100},
    {"logicalName": "aaca_typedcampus", "type": "text", "displayName": "Typed Campus", "maxLength": 100},
    {"logicalName": "aaca_parentname", "type": "text", "displayName": "Parent Name", "maxLength": 200},
    {"logicalName": "aaca_relationshiptext", "type": "text", "displayName": "Relationship", "maxLength": 100},
    {"logicalName": "aaca_reasontext", "type": "memo", "displayName": "Reason Text", "maxLength": 4000},
    {"logicalName": "aaca_matchstatus", "type": "choice", "displayName": "Match Status",
     "options": [[582100000, "Matched"], [582100001, "Unmatched"], [582100002, "Ambiguous"], [582100003, "Mapped by office"]]},
    {"logicalName": "aaca_matchdetail", "type": "text", "displayName": "Match Detail", "maxLength": 500},
    {"logicalName": "aaca_dayscreated", "type": "int", "displayName": "Days Created"},
    {"logicalName": "aaca_daysskipped", "type": "int", "displayName": "Days Skipped"},
    {"logicalName": "aaca_daysconflict", "type": "int", "displayName": "Days Conflict"},
    {"logicalName": "aaca_errordetail", "type": "text", "displayName": "Error Detail", "maxLength": 2000},
    {"logicalName": "aaca_legacyitemid", "type": "int", "displayName": "Legacy Item ID",
     "description": "SharePoint Student Absence Log item ID (imported history)."},
])
an.setdefault("keys", [])
if not any(k["logicalName"] == "aaca_absencenotice_legacy" for k in an["keys"]):
    an["keys"].append({"logicalName": "aaca_absencenotice_legacy", "displayName": "Legacy Item", "columns": ["aaca_legacyitemid"]})

addcols("aaca_campus", [{"logicalName": "aaca_absencechatid", "type": "text", "displayName": "Absence Teams Chat ID", "maxLength": 200,
                         "description": "Teams group chat that receives the campus ABSENCE ALERT cards (set per environment)."}])
addlookups([{"table": "aaca_attendance", "logicalName": "aaca_absencenotice", "displayName": "Absence Notice", "target": "aaca_absencenotice",
             "onDelete": "RemoveLink", "description": "The absence report that created this day."}])

# Billing rules (finance-managed) and per-day billing results
UNITS = [[582100000, "Full day"], [582100001, "Half day"]]
NEW = [
    {"logicalName": "aaca_billingrule", "displayName": "Billing Rule", "pluralName": "Billing Rules", "billing": True,
     "description": "A finance-managed rule that decides whether an absence (later: transportation) day is billable, for which services, from when.",
     "primaryName": {"logicalName": "aaca_name", "displayName": "Name", "maxLength": 200},
     "columns": [
         {"logicalName": "aaca_appliesto", "type": "choice", "displayName": "Applies To", "required": True,
          "options": [[582100000, "Absence"], [582100001, "Transportation"]]},
         {"logicalName": "aaca_ruletype", "type": "choice", "displayName": "Rule Type", "required": True,
          "options": [[582100000, "Late notice"], [582100001, "No notice"], [582100002, "Transportation status"]]},
         {"logicalName": "aaca_noticehours", "type": "int", "displayName": "Notice Hours",
          "description": "Late notice: billable when notice arrived fewer than this many hours before the school start time."},
         {"logicalName": "aaca_schoolstarttime", "type": "text", "displayName": "School Start Time", "maxLength": 5,
          "description": "HH:mm, Pacific (e.g. 09:00)."},
         {"logicalName": "aaca_result", "type": "choice", "displayName": "Result", "required": True,
          "options": [[582100000, "Billable"], [582100001, "Not billable"], [582100002, "Needs review"]]},
         {"logicalName": "aaca_units", "type": "choice", "displayName": "Units", "options": UNITS, "default": 582100000},
         {"logicalName": "aaca_fundertype", "type": "choice", "displayName": "Funder Type", "description": "Blank = all funder types.",
          "options": [[582100000, "District"], [582100001, "Regional Center"], [582100002, "Private Pay"]]},
         {"logicalName": "aaca_effectivefrom", "type": "date", "displayName": "Effective From", "required": True},
         {"logicalName": "aaca_effectiveto", "type": "date", "displayName": "Effective To", "description": "Blank = still in effect."},
         {"logicalName": "aaca_priority", "type": "int", "displayName": "Priority", "description": "Lower runs first; the first matching rule decides."},
         {"logicalName": "aaca_active", "type": "bool", "displayName": "Active", "default": True},
         {"logicalName": "aaca_note", "type": "memo", "displayName": "Note", "maxLength": 2000}]},
    {"logicalName": "aaca_billingruleservice", "displayName": "Billing Rule Service", "pluralName": "Billing Rule Services", "billing": True,
     "description": "A service a billing rule applies to (one row per rule + service).",
     "primaryName": {"logicalName": "aaca_name", "displayName": "Name", "maxLength": 200},
     "columns": [{"logicalName": "aaca_pairkey", "type": "text", "displayName": "Pair Key", "maxLength": 100, "description": "RuleId|ServiceId"}],
     "keys": [{"logicalName": "aaca_billingruleservice_pair", "displayName": "Pair Key", "columns": ["aaca_pairkey"]}]},
    {"logicalName": "aaca_billingday", "displayName": "Billing Day", "pluralName": "Billing Days", "billing": True,
     "description": "The billing result for one student, service and school day, written by the billing rules engine (never in locked months).",
     "primaryName": {"logicalName": "aaca_name", "displayName": "Summary", "maxLength": 200},
     "columns": [
         {"logicalName": "aaca_daykey", "type": "text", "displayName": "Day Key", "maxLength": 150, "description": "StudentNumber|ServiceCode|yyyy-mm-dd"},
         {"logicalName": "aaca_date", "type": "date", "displayName": "Date", "required": True},
         {"logicalName": "aaca_status", "type": "choice", "displayName": "Billing Status", "required": True,
          "options": [[582100000, "Billable absence"], [582100001, "Not billable absence"], [582100002, "Present"], [582100003, "Needs review"]]},
         {"logicalName": "aaca_units", "type": "choice", "displayName": "Units", "options": UNITS},
         {"logicalName": "aaca_reason", "type": "text", "displayName": "Reason", "maxLength": 1000},
         {"logicalName": "aaca_computedon", "type": "datetime", "displayName": "Computed On"}],
     "keys": [{"logicalName": "aaca_billingday_key", "displayName": "Day Key", "columns": ["aaca_daykey"]}]},
]
for nt in NEW:
    if nt["logicalName"] not in T:
        t["tables"].append(nt)
addlookups([
    {"table": "aaca_billingruleservice", "logicalName": "aaca_billingrule", "displayName": "Billing Rule", "target": "aaca_billingrule", "required": True},
    {"table": "aaca_billingruleservice", "logicalName": "aaca_service", "displayName": "Service", "target": "aaca_service", "required": True},
    {"table": "aaca_billingday", "logicalName": "aaca_student", "displayName": "Student", "target": "aaca_student", "required": True},
    {"table": "aaca_billingday", "logicalName": "aaca_service", "displayName": "Service", "target": "aaca_service", "required": True},
    {"table": "aaca_billingday", "logicalName": "aaca_funder", "displayName": "Funder", "target": "aaca_funder"},
    {"table": "aaca_billingday", "logicalName": "aaca_attendance", "displayName": "Attendance", "target": "aaca_attendance", "onDelete": "RemoveLink"},
    {"table": "aaca_billingday", "logicalName": "aaca_billingrule", "displayName": "Billing Rule", "target": "aaca_billingrule", "onDelete": "RemoveLink"},
])
json.dump(t, open(P, "w", encoding="utf-8", newline="\n"), indent=2, ensure_ascii=False)
print("schema updated")
