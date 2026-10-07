"""Generates the "AACA - Ask NEXUS" cloud flow (clientdata JSON): the attendance app's Help panel calls it with a
question, the flow asks the Resource Center agent (NEXUS, Copilot Studio, environment "Resource Center Copilot") and
returns the answer. In a canvas app the connector's "Execute Agent and wait" returns only a Boolean, so the answer has
to come back through a flow.

    python flows/build_help_flow.py   -> writes flows/generated/help/*.json   (deploy: flows/Deploy-HelpFlow.ps1)

Inputs (Power Apps V2 trigger): Question (required), ConversationId (blank = new conversation), Context (screen/role
hint written by the app). Outputs: answer, conversationid, ok ("true"/"false").
Set the flow's run-only users to use the caller's own Copilot Studio connection so NEXUS answers as the signed-in user
(its SharePoint knowledge is permission-trimmed per user).
"""
import json
import os
import uuid

FLOW_ID = "6b1f2a40-5c2e-4d7a-9e11-0a1b2c3d4e81"
AGENT = "cr15b_ResourceCenterCopilot"
AGENT_ENV = "34bb0920-5056-eb04-b0b0-26ec19c6e711"
REF = "aaca_sharedmicrosoftcopilotstudio_nexus"
MCS = {"connectionName": "shared_microsoftcopilotstudio", "apiId": "/providers/Microsoft.PowerApps/apis/shared_microsoftcopilotstudio"}


def mid():
    return {"operationMetadataId": str(uuid.uuid4())}


def text_input(title, desc):
    return {"title": title, "type": "string", "x-ms-dynamically-added": True, "description": desc, "x-ms-content-hint": "TEXT"}


OUT_SCHEMA = {"type": "object", "properties": {
    "answer": {"title": "answer", "type": "string", "x-ms-dynamically-added": True},
    "conversationid": {"title": "conversationid", "type": "string", "x-ms-dynamically-added": True},
    "ok": {"title": "ok", "type": "string", "x-ms-dynamically-added": True}}}


def respond(answer, conv, ok, after):
    return {"runAfter": after, "metadata": mid(), "type": "Response", "kind": "PowerApp",
            "inputs": {"statusCode": 200, "body": {"answer": answer, "conversationid": conv, "ok": ok}, "schema": OUT_SCHEMA}}


flow = {"properties": {"connectionReferences": {"shared_microsoftcopilotstudio": {
    "runtimeSource": "invoker", "connection": {"connectionReferenceLogicalName": REF}, "api": {"name": "shared_microsoftcopilotstudio"}}},
    "definition": {
        "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {"$connections": {"defaultValue": {}, "type": "Object"}, "$authentication": {"defaultValue": {}, "type": "SecureObject"}},
        "triggers": {"manual": {"metadata": mid(), "type": "Request", "kind": "PowerAppV2", "inputs": {"schema": {
            "type": "object", "properties": {
                "text": text_input("Question", "The user's question"),
                "text_1": text_input("ConversationId", "Blank to start a new conversation"),
                "text_2": text_input("Context", "Which screen and role the question comes from")},
            "required": ["text"]}}}},
        "actions": {
            "Ask_NEXUS": {"runAfter": {}, "metadata": mid(), "type": "OpenApiConnectionWebhook",
                          "inputs": {"host": {**MCS, "operationId": "ExecuteCopilotAsyncV2"},
                                     "parameters": {"Copilot": AGENT, "environmentId": AGENT_ENV,
                                                    "body/message": "@{if(empty(triggerBody()?['text_2']), '', concat(triggerBody()?['text_2'], decodeUriComponent('%0A%0A')))}@{triggerBody()?['text']}",
                                                    "x-ms-conversation-id": "@{triggerBody()?['text_1']}"},
                                     "authentication": "@parameters('$authentication')"},
                          "limit": {"timeout": "PT100S"}},
            "Answer": respond("@{body('Ask_NEXUS')?['lastResponse']}", "@{body('Ask_NEXUS')?['conversationId']}", "true", {"Ask_NEXUS": ["Succeeded"]}),
            "No_answer": respond("NEXUS could not answer right now. Please try again in a moment.", "@{triggerBody()?['text_1']}", "false",
                                 {"Ask_NEXUS": ["Failed", "TimedOut"]}),
        },
        "outputs": {}}, "templateName": None}, "schemaVersion": "1.0.0.0"}

out = os.path.join(os.path.dirname(__file__), "generated", "help")
os.makedirs(out, exist_ok=True)
with open(os.path.join(out, f"{FLOW_ID}.json"), "w", encoding="utf-8", newline="\n") as f:
    json.dump({"workflowid": FLOW_ID, "name": "AACA - Ask NEXUS", "clientdata": flow}, f, indent=1)
print("written to", out)
