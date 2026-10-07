"""Generates the Staff Access Sync cloud flow (clientdata JSON) for the AACA Attendance solution (build 10).

    python flows/build_staff_access_flow.py   -> writes flows/generated/staff/*.json

Every 15 minutes: Staff rows that are active, have an Email and no linked User are matched to an enabled user account
with that email. The Staff row is linked; then, ONLY when the row is a Teacher with a campus AND the account has no
security roles yet (a brand-new user), the account is moved to the campus business unit and given AACA Teacher +
Basic User and the "AACA Absence Viewers" column profile (same as Grant-AacaAccess.ps1 -Role Teacher). Existing
users' access is never changed; office/admin/finance access stays with Grant-AacaAccess.ps1.
Deploy: flows/Deploy-StaffAccessFlow.ps1. Design: docs/app-builds/build-10-staff/canvas-app-requirements.md.
"""
import json
import os
import uuid

FLOW_ID = "6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e61"
TEACHER = 582100000      # Staff App Role
ACT_UPDATE = 582100001   # Audit Event action

DV = {"connectionName": "shared_commondataserviceforapps", "apiId": "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps"}
AUTH = "@parameters('$authentication')"
CONN_REFS = {"shared_commondataserviceforapps": {"runtimeSource": "embedded", "connection": {"connectionReferenceLogicalName": "aaca_sharedcommondataserviceforapps_2b783"}, "api": {"name": "shared_commondataserviceforapps"}}}


def mid():
    return {"operationMetadataId": str(uuid.uuid4())}


def op(operation, params, after=None):
    return {"runAfter": after or {}, "metadata": mid(), "type": "OpenApiConnection",
            "inputs": {"host": {**DV, "operationId": operation}, "parameters": params, "authentication": AUTH}}


def ok(*names):
    return {n: ["Succeeded"] for n in names}


S = "items('Each_staff')"
USER = "first(body('Find_user')?['value'])"
UID = f"{USER}?['systemuserid']"
BU = "first(body('Find_bu')?['value'])?['businessunitid']"
# Absolute Web API base ("https://<org>/api/data/v9.x/") for Relate rows, taken from a List rows response.
BASE = "first(split(body('Find_roles')?['@odata.context'], '$metadata'))"

provision = {
    "Campus": op("GetItem", {"entityName": "aaca_campuses", "recordId": f"@{S}?['_aaca_campus_value']", "$select": "aaca_name"}),
    "Find_bu": op("ListRecords", {"entityName": "businessunits", "$select": "businessunitid",
                                  "$filter": "name eq '@{replace(body('Campus')?['aaca_name'], '''', '''''')}'", "$top": 1}, ok("Campus")),
    "Has_bu": {"runAfter": ok("Find_bu"), "metadata": mid(), "type": "If",
               "expression": {"greater": ["@length(body('Find_bu')?['value'])", 0]},
               "actions": {
                   "Move_user": {"runAfter": {}, "metadata": mid(), "type": "If",
                                 "expression": {"not": {"equals": [f"@{USER}?['_businessunitid_value']", f"@{BU}"]}},
                                 "actions": {"Set_business_unit": op("UpdateRecord", {"entityName": "systemusers", "recordId": f"@{UID}",
                                                                                      "item/businessunitid@odata.bind": f"@{{concat('/businessunits(', {BU}, ')')}}"})},
                                 "else": {"actions": {}}},
                   "Find_roles": op("ListRecords", {"entityName": "roles", "$select": "roleid,name",
                                                    "$filter": f"_businessunitid_value eq @{{{BU}}} and (name eq 'AACA Teacher' or name eq 'Basic User')"},
                                    ok("Move_user")),
                   "Each_role": {"runAfter": ok("Find_roles"), "metadata": mid(), "type": "Foreach", "foreach": "@body('Find_roles')?['value']",
                                 "actions": {"Assign_role": op("AssociateEntities", {
                                     "entityName": "systemusers", "recordId": f"@{UID}", "associationEntityRelationship": "systemuserroles_association",
                                     "item/@odata.id": f"@{{concat({BASE}, 'roles(', items('Each_role')?['roleid'], ')')}}"})},
                                 "runtimeConfiguration": {"concurrency": {"repetitions": 1}}},
                   "Find_profile": op("ListRecords", {"entityName": "fieldsecurityprofiles", "$select": "fieldsecurityprofileid",
                                                      "$filter": "name eq 'AACA Absence Viewers'", "$top": 1}, ok("Each_role")),
                   "Add_profile": {"runAfter": ok("Find_profile"), "metadata": mid(), "type": "If",
                                   "expression": {"greater": ["@length(body('Find_profile')?['value'])", 0]},
                                   "actions": {"Assign_profile": op("AssociateEntities", {
                                       "entityName": "systemusers", "recordId": f"@{UID}", "associationEntityRelationship": "systemuserprofiles_association",
                                       "item/@odata.id": f"@{{concat({BASE}, 'fieldsecurityprofiles(', first(body('Find_profile')?['value'])?['fieldsecurityprofileid'], ')')}}"})},
                                   "else": {"actions": {}}},
                   "Audit_access": op("CreateRecord", {"entityName": "aaca_auditevents",
                                                       "item/aaca_name": f"Access set up: @{{{S}?['aaca_name']}} (Teacher, @{{body('Campus')?['aaca_name']}})",
                                                       "item/aaca_action": ACT_UPDATE, "item/aaca_entity": "systemuser", "item/aaca_entityid": f"@{UID}",
                                                       "item/aaca_after": f"{{\"StaffId\":\"@{{{S}?['aaca_staffid']}}\",\"Roles\":\"AACA Teacher, Basic User\",\"Profile\":\"AACA Absence Viewers\",\"BusinessUnit\":\"@{{body('Campus')?['aaca_name']}}\"}}",
                                                       "item/aaca_reason": "Staff Access Sync flow (new teacher)"}, ok("Add_profile")),
               },
               "else": {"actions": {}}},
}

per_staff = {
    "Find_user": op("ListRecords", {"entityName": "systemusers", "$select": "systemuserid,_businessunitid_value",
                                    "$filter": f"isdisabled eq false and internalemailaddress eq '@{{replace({S}?['aaca_email'], '''', '''''')}}'", "$top": 1}),
    "User_found": {"runAfter": ok("Find_user"), "metadata": mid(), "type": "If",
                   "expression": {"greater": ["@length(body('Find_user')?['value'])", 0]},
                   "actions": {
                       "Link_staff": op("UpdateRecord", {"entityName": "aaca_staffs", "recordId": f"@{S}?['aaca_staffid']",
                                                         "item/aaca_user@odata.bind": f"@{{concat('/systemusers(', {UID}, ')')}}"}),
                       "Existing_roles": op("ListRecords", {"entityName": "systemuserrolescollection", "$select": "roleid",
                                                            "$filter": f"systemuserid eq @{{{UID}}}", "$top": 1}, ok("Link_staff")),
                       "New_teacher": {"runAfter": ok("Existing_roles"), "metadata": mid(), "type": "If",
                                       "expression": {"and": [{"equals": ["@length(body('Existing_roles')?['value'])", 0]},
                                                              {"equals": [f"@{S}?['aaca_approle']", TEACHER]},
                                                              {"not": {"equals": [f"@{S}?['_aaca_campus_value']", "@null"]}}]},
                                       "actions": provision, "else": {"actions": {}}},
                   },
                   "else": {"actions": {}}},
}

flow = {"properties": {"connectionReferences": CONN_REFS, "definition": {
    "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {"$connections": {"defaultValue": {}, "type": "Object"}, "$authentication": {"defaultValue": {}, "type": "SecureObject"}},
    "triggers": {"Every_15_minutes": {"metadata": mid(), "type": "Recurrence", "recurrence": {"frequency": "Minute", "interval": 15}}},
    "actions": {
        "Unlinked_staff": op("ListRecords", {"entityName": "aaca_staffs", "$select": "aaca_staffid,aaca_name,aaca_email,aaca_approle,_aaca_campus_value",
                                             "$filter": "_aaca_user_value eq null and aaca_email ne null and aaca_active eq true"}),
        "Each_staff": {"runAfter": ok("Unlinked_staff"), "metadata": mid(), "type": "Foreach", "foreach": "@body('Unlinked_staff')?['value']",
                       "actions": per_staff, "runtimeConfiguration": {"concurrency": {"repetitions": 1}}},
    },
    "outputs": {}}, "templateName": None}, "schemaVersion": "1.0.0.0"}

out = os.path.join(os.path.dirname(__file__), "generated", "staff")
os.makedirs(out, exist_ok=True)
with open(os.path.join(out, f"{FLOW_ID}.json"), "w", encoding="utf-8", newline="\n") as f:
    json.dump({"workflowid": FLOW_ID, "name": "AACA - Staff Access Sync", "clientdata": flow}, f, indent=1)
print("written to", out)
