# Canvas App Plan — AACA Billing (build 6, Phase 1 foundations)

## Mode

CREATE (new app "AACA Billing", app id 1d5dc650-cc68-4a25-8f71-a7cb591ed3c7, Dev environment
a4c9f4ce-b971-edf2-beba-e3c29552a316). Source folder `C:\src\aaca-attendance\billing-app`.

## Requirements

Authoritative: `C:\src\aaca-attendance\docs\app-builds\build-6-billing-foundations\canvas-app-requirements.md`
(not modified). Four screens: Home, Funders, Services, Student billing setup. Finance-only gate; QuickBooks mapping
fields; funder and service aliases (normalised UPPER/trimmed/collapsed); districts of record; student services;
every write audited; no rates or dollars anywhere; no delete of funders or services.

Deliberate deviation from the generic CREATE template: the user named the screens, so the first screen is
`HomeScreen` (new file), not `Screen1`. The orchestrator deletes `Screen1.pa.yaml` and sets `StartScreen` after
builders (see App Changes).

## Original Request Capability Inventory

The requirements contract is prose (no keyed table), so the planner assigns the stable keys below.

| Requirement key | Original request clause | Capability family | Required outcome / scope | Required action(s) | Observer(s) | Scenario(s) |
| --- | --- | --- | --- | --- | --- | --- |
| R01 | Shared only with finance; not-authorised panel unless Staff Finance Access = Yes | 10 Security | Every screen shows only the access panel and no data/nav for non-finance | A-GATE | `con<P>Gate.Visible = !IsFinance`; body Visible includes IsFinance | S-GATE-DENY, S-GATE-ALLOW |
| R02 | Header band "AACA Billing" with nav Home/Funders/Services/Students on every screen | 1 Shell | Same four buttons on all screens, current highlighted | A-NAV | `btn<P>Nav*` Appearance | S-NAV |
| R03 | Needs-attention card: funders with no QuickBooks customer, navigates pre-filtered | 7 Analytics + 1 | Count = active funders with blank QBO; opens Funders with Missing-QBO chip | A-HOME-LOAD, A-HOME-FUNQBO | `lblHomeFunQboCount`; `lblFunCount` | S-HOME-LOAD, S-HOME-FUNQBO |
| R04 | Card: active services with no QuickBooks item | 7 + 1 | Count = active services with blank QBO item; opens Services pre-filtered | A-HOME-LOAD, A-HOME-SVCQBO | `lblHomeSvcQboCount`; `lblSvcCount` | S-HOME-LOAD, S-HOME-SVCQBO |
| R05 | Card: active School students with no current district of record (no row covering Today()) | 7 + 1 | Count from colStudents x colDor; opens Students with No-DoR chip, status Active | A-HOME-LOAD, A-HOME-STUDOR | `lblHomeStuDorCount`; `lblStuCount` | S-HOME-LOAD, S-HOME-STUDOR |
| R06 | Card: Private Pay funders created from CodeMetro (Private Pay and QBO customer blank) | 7 + 1 | Count; opens Funders with Private Pay + Missing-QBO + show inactive | A-HOME-LOAD, A-HOME-PRIVPAY | `lblHomePrivPayCount`; `lblFunCount` | S-HOME-LOAD, S-HOME-PRIVPAY |
| R07 | "Coming next" note listing later phases as plain text, not buttons | 1 Shell | Static text panel | A-HOME-LOAD (render) | `lblHomeNextBody` | S-HOME-LOAD |
| R08 | Funders list search (abbreviation, full name or alias text) | 3 Exploration | Live filter incl. alias match | A-FUN-SEARCH | `galFunList.Items`, `lblFunCount` | S-FUN-SEARCH |
| R09 | Funder filter chips All / District / Regional Center / Private Pay / Missing QuickBooks customer | 3 | Type chips exclusive; Missing chip combinable | A-FUN-TYPE, A-FUN-MISSQBO, A-FUN-CLEAR | chip Appearance, `lblFunCount` | S-FUN-TYPE, S-FUN-MISSQBO, S-FUN-CLEAR |
| R10 | Funders "Show inactive" toggle default off | 3 | Inactive hidden unless on | A-FUN-INACTIVE | `tglFunInactive`, list | S-FUN-INACTIVE |
| R11 | Funder row: abbreviation, full name, type, QBO customer or "No QuickBooks customer" warning, alias count | 2 Read | Visible row fields | A-FUN-LOAD | row labels | S-FUN-LOAD |
| R12 | Funder detail edit: Abbreviation (required, unique case-insensitive), Full Name, Funder Type (required), QuickBooks Customer, Active; Save/Cancel; New funder | 2 Lifecycle | Create + update + cancel with validation | A-FUN-SELECT, A-FUN-NEW, A-FUN-CREATE, A-FUN-UPDATE, A-FUN-CANCEL | `lblFunReceipt`, list row | S-FUN-CREATE, S-FUN-CREATE-REQ, S-FUN-CREATE-DUP, S-FUN-UPDATE, S-FUN-CANCEL, S-FUN-FAIL |
| R13 | No delete of funders (deactivate instead) | 2 / 4 | Deactivate/Reactivate via Active; no delete control | A-FUN-DEACT, A-FUN-REACT | receipt Active line; list Inactive tag | S-FUN-DEACT, S-FUN-REACT, S-FUN-COMPOUND |
| R14 | Funder aliases: add (normalised); clash "Already mapped to X" + "Move it here"; same-funder notice; remove (confirm); one caption line | 5 Relationships | Alias rows map CodeMetro names to one funder | A-FUN-ALIAS-ADD, A-FUN-ALIAS-MOVE, A-FUN-ALIAS-DEL, A-FUN-ALIAS-DELCANCEL | `galFunAliases`, `lblFunAliasNotice`, `lblFunAliasReceipt` | S-FUN-ALIAS-ADD, S-FUN-ALIAS-SAME, S-FUN-ALIAS-MOVE, S-FUN-ALIAS-DEL, S-FUN-ALIAS-DELCANCEL |
| R15 | Services list sorted by Kind then Sort Order; filters All / School Day / Clinical / Missing QuickBooks item; Show inactive | 3 | Sorted, filtered list | A-SVC-LOAD, A-SVC-KIND, A-SVC-MISSQBO, A-SVC-INACTIVE, A-SVC-CLEAR | `galSvcList.Items`, `lblSvcCount` | S-SVC-LOAD, S-SVC-KIND, S-SVC-MISSQBO, S-SVC-INACTIVE, S-SVC-CLEAR |
| R16 | Service row: code, name, kind, unit, QBO item or warning, flags "Non-school days", "Not billable" | 2 Read | Visible row fields | A-SVC-LOAD | row labels | S-SVC-LOAD |
| R17 | Service detail: Code (required, unique), Name, Kind, Billing Unit, QBO Item, Billable, Billable on Non-School Days, Sort Order, Active; Save/Cancel/New; no delete | 2 | Create + update + cancel; deactivate | A-SVC-SELECT, A-SVC-NEW, A-SVC-CREATE, A-SVC-UPDATE, A-SVC-CANCEL, A-SVC-DEACT, A-SVC-REACT | `lblSvcReceipt`, list row | S-SVC-CREATE, S-SVC-CREATE-DUP, S-SVC-SORT-INVALID, S-SVC-UPDATE, S-SVC-CANCEL, S-SVC-DEACT, S-SVC-REACT, S-SVC-COMPOUND |
| R18 | SPED service: Code and Kind read-only | 10 / 2 | Inputs View; save never writes code/kind for SPED | A-SVC-SPED | `txtSvcCode.DisplayMode`, receipt | S-SVC-SPED |
| R19 | Service aliases: CPT Codes and Service Names groups; add by group (normalised); duplicate same text + same type elsewhere -> Move it here; remove (confirm) | 5 | Alias rows by type | A-SVC-CPT-ADD, A-SVC-SNM-ADD, A-SVC-ALIAS-MOVE, A-SVC-ALIAS-DEL, A-SVC-ALIAS-DELCANCEL | `galSvcCpt`, `galSvcSnm`, notices, receipt | S-SVC-CPT-ADD, S-SVC-SNM-ADD, S-SVC-ALIAS-TYPES, S-SVC-ALIAS-SAME, S-SVC-ALIAS-MOVE, S-SVC-ALIAS-DEL, S-SVC-ALIAS-DELCANCEL |
| R20 | Students list search by name or Student Key; filters All / School / Regional Center Only / No district of record; status Active (default) / All | 3 | Filtered list | A-STU-SEARCH, A-STU-TYPE, A-STU-NODOR, A-STU-STATUS, A-STU-CLEAR | `galStuList.Items`, `lblStuCount` | S-STU-SEARCH, S-STU-TYPE, S-STU-NODOR, S-STU-STATUS, S-STU-CLEAR |
| R21 | Student row: key, "Last, First", type, current DoR abbreviation or "No district of record" warning (School), count of active day-service rows | 2 Read | Visible row fields | A-STU-LOAD | row labels | S-STU-LOAD |
| R22 | Student detail header: key, name, type, status (read-only) | 2 Read | No student edits | A-STU-SELECT | `lblStuHeadName`, `lblStuHeadMeta` | S-STU-SELECT |
| R23 | Districts of Record rows sorted by Start desc: funder, start, end ("ongoing"), source, note | 6 Time + 5 | Visible rows | A-STU-SELECT | `galStuDor` | S-STU-SELECT |
| R24 | DoR Add/Edit: funder picker active District funders, start required, end optional, note; end >= start; no overlap (show clashing row) | 2 + 6 | Validated create/update | A-DOR-NEW, A-DOR-CREATE, A-DOR-EDIT, A-DOR-CANCEL | `lblStuDorValidation`, receipt, `galStuDor` | S-DOR-CREATE, S-DOR-REQ, S-DOR-ENDBEFORE, S-DOR-OVERLAP, S-DOR-CANCEL |
| R25 | CodeMetro DoR rows may be edited (become Source = Manual) or ended | 2 | Source flips to Manual on save; End date set | A-DOR-EDIT, A-DOR-END | receipt Source/End, row | S-DOR-EDIT-CM, S-DOR-END |
| R26 | DoR delete only Manual rows (confirm) | 2 | Delete with confirm; no delete on CodeMetro | A-DOR-DEL, A-DOR-DELCANCEL | `btnStuDorRowDelete.Visible`, receipt | S-DOR-DEL, S-DOR-DEL-CM, S-DOR-DELCANCEL |
| R27 | DoR hidden for Regional Center Only students (caption instead) | 1 / 4 | Section replaced by caption | A-STU-SELECT | `lblStuDorCaption`, `galStuDor.Visible` | S-DOR-RC |
| R28 | Student Services rows sorted by service sort order then start: service, funder, start, end, frequency, minutes, ESY, source, Excluded, note; Excluded muted + badge; caption "Each row is one line on the RDS grid; a 2:1 aide is two rows." | 2 Read | Visible rows | A-STU-SELECT | `galStuSs`, `badStuSsExcluded` | S-STU-SELECT, S-SS-EXCL |
| R29 | CodeMetro SS rows: only Excluded (toggle) and Note editable | 2 / 10 | Other inputs View; save writes only those two | A-SS-CMEDIT, A-SS-EXCL, A-SS-INCL | receipt, row | S-SS-CMEDIT, S-SS-EXCL, S-SS-INCL, S-SS-COMPOUND |
| R30 | Manual SS rows Add / Edit (service picker active School Day except SPED; funder picker active funders; start required; end optional) / Delete (confirm) | 2 | Create/update/delete manual rows | A-SS-NEW, A-SS-CREATE, A-SS-EDIT, A-SS-CANCEL, A-SS-DEL, A-SS-DELCANCEL | receipt, `galStuSs` | S-SS-CREATE, S-SS-CREATE-2, S-SS-REQ, S-SS-MIN-INVALID, S-SS-EDIT, S-SS-CANCEL, S-SS-DEL, S-SS-DEL-CM, S-SS-DELCANCEL |
| R31 | Every write writes an Audit Events row (entity, id, before/after JSON, reason) | 10 / 9 | Audit row after every successful mutation; receipt states audit result | all mutation contracts | receipt "Audit written"; Audit Events table | every mutation scenario (Then clause) |
| R32 | Every Patch wrapped in IfError with visible error notice; success notice after each save | 10 | Failed receipt on error; success receipt | all mutation contracts | section receipts | S-FUN-FAIL, S-LOAD-FAIL |
| R33 | Load into collections on visible / refresh; filter locally | 9 | OnVisible + Reload | A-HOME-LOAD, A-FUN-LOAD, A-SVC-LOAD, A-STU-LOAD | load engines, count labels | S-HOME-LOAD, S-FUN-LOAD, S-SVC-LOAD, S-STU-LOAD, S-LOAD-FAIL |
| R34 | Never store or show rates or dollars | 10 | No currency fields anywhere | A-GATE (scope rule) | absence of rate fields in all briefs | S-NAV (inspection) |

## Requirement Coverage

| Requirement | Planned affordance | Fidelity |
| --- | --- | --- |
| Not-authorised panel | `con<P>Gate` on every screen, body/nav hidden, collections cleared | Exact |
| Header nav | Four ModernButtons Home/Funders/Services/Students, current = teal Primary | Exact |
| Needs-attention cards with counts + pre-filtered navigation | Four `conHomeCard*` panels: count, title, "Review ..." button setting filter globals then Navigate | Exact |
| Coming next note | `lblHomeNextBody` plain text, no buttons | Exact |
| Funder filter chips | Four mutually exclusive type chips + one independent "Missing QuickBooks customer" chip (so Private Pay + Missing can combine for the Home card) | Exact (chip set as listed; Missing chip is combinable) |
| Show inactive | ModernToggle bound to `varFunShowInactive` / `varSvcShowInactive` | Exact |
| Detail edit forms | Row "Edit" button opens a prepopulated form panel; "New funder"/"New service" opens a blank form | Exact |
| Deactivate instead of delete | Active toggle in form; Save shows "Yes -> No (Deactivated)"; no delete control for funders/services | Exact |
| Service Name required | Validation requires Name because it is the Services primary-name column | Approximation: requirement lists Name without "required"; Dataverse primary name is required |
| Alias normalisation | `NormAlias()` UDF (Trim collapses internal runs; Upper) applied to input before compare and save; preview "Will be saved as ..." | Exact |
| "Move it here" | Visible only when the normalised text (same type for services) is mapped to another record | Exact |
| Alias remove confirm | Inline confirm row "Remove alias X from Y?" with Remove / Keep | Exact |
| Service flags "Non-school days", "Not billable" | Text tags in the row meta line | Exact |
| Student status filter Active/All | Two chips "Active" / "All statuses" | Exact |
| DoR overlap shows clashing row | Validation label names the clashing row's district and dates | Exact |
| CodeMetro DoR edit -> Manual | Save always writes `Source: Manual`; receipt shows "Source Manual" | Exact |
| DoR / SS end date optional | "Ongoing (no end date)" checkbox; unchecked requires an end date | Exact |
| Excluded rows muted + badge | Row Fill `ColorNotEnrolled`, muted text, Badge "Excluded" | Exact |
| CodeMetro SS only Excluded + Note | Other inputs `DisplayMode.View`; save Patch writes only `Excluded`, `Note` | Exact |
| Audit trail | Audit Events row after every successful write; receipt reports audit result | Exact |
| Delete of alias logged | Action 'Soft Delete' (option set has no hard-delete value), Reason "... removed (row deleted)" | Approximation: no Delete option exists |

## Required Record Fields

| Field key | Screen | Record surface | Required field | Source field | Presentation requirement |
| --- | --- | --- | --- | --- | --- |
| RF-FUN-ABBR | Funders | list row | Abbreviation (identity) | colFunders.Abbr | Full text, 14 Semibold |
| RF-FUN-NAME | Funders | list row | Full name | colFunders.FullName | meta line, wraps |
| RF-FUN-TYPE | Funders | list row | Funder type | colFunders.TypeText | meta line |
| RF-FUN-QBO | Funders | list row | QBO customer or "No QuickBooks customer" warning | colFunders.QboCustomer | own line, warning in ColorWarnInk |
| RF-FUN-ALIASES | Funders | list row | Alias count | CountIf(colFunderAliases, FunderId) | meta line "N aliases" |
| RF-FUN-ALIASTEXT | Funders | alias row | CodeMetro name | colFunderAliases.AliasText | full text |
| RF-SVC-CODE | Services | list row | Service code (identity) + name | colServices.Code, Name | "CODE - Name" 14 Semibold, wraps 2 lines |
| RF-SVC-KIND | Services | list row | Kind, billing unit, flags | KindText, UnitText, NonSchool, IsBillable, IsActive | meta line |
| RF-SVC-QBO | Services | list row | QBO item or warning | colServices.QboItem | own line, warning ColorWarnInk |
| RF-SVC-ALIASTEXT | Services | CPT / name alias rows | alias text | colServiceAliases.AliasText | full text |
| RF-STU-ID | Students | list row | Student key + "Last, First" | StudentKey, DisplayName | "KEY - Last, First" 14 Semibold |
| RF-STU-META | Students | list row | type, current DoR abbr or warning, active day-service count | TypeText, colDor, colStuSvc | meta line, warning ColorWarnInk |
| RF-STU-HEAD | Students | detail header | key, name, type, status | StudentKey, DisplayName, TypeText, StatusText | 18 Bold + meta line |
| RF-DOR-ROW | Students | DoR row | funder, start, end/ongoing, source, note | colDor fields + colFunders.Abbr | main line + meta line |
| RF-SS-ROW | Students | SS row | service, funder, start, end, frequency, minutes, ESY, source, Excluded, note | colStuSvc + lookups | main line, dates line, meta line, badge |

## State-Driven Surface Visibility

| Surface key | Owner screen | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- | --- |
| SV-GATE | all | `con<P>Gate` | `=!IsFinance` | visible for non-finance; hidden for finance |
| SV-BODY | all | `conHomeBody`, `conFunBody`, `conSvcBody`, `conStuBody`, `con<P>Nav` | `=IsFinance` | hidden for non-finance |
| SV-FUN-FORM | Funders | `conFunForm` | `=IsFinance && varFunMode <> ""` | open for new/edit; hidden otherwise |
| SV-FUN-ALIAS | Funders | `conFunAliasPanel` | `=IsFinance && varFunMode = "edit"` | only for a saved funder |
| SV-FUN-CONFIRM | Funders | `conFunAliasConfirm` | `=!IsBlank(varFunAliasDelId)` | during remove confirm |
| SV-SVC-FORM / SV-SVC-ALIAS / SV-SVC-CONFIRM | Services | `conSvcForm`, `conSvcAliasPanel`, `conSvcAliasConfirm` | same shapes with Svc vars | as Funders |
| SV-STU-DETAIL | Students | `conStuHead`, `conStuDor`, `conStuSs` | `=IsFinance && !IsBlank(varStuSelId)` | student selected |
| SV-DOR-FORM | Students | `conStuDorForm` | `=IsFinance && !IsBlank(varStuSelId) && varStuDorMode <> "" && LookUp(colStudents, StudentId = varStuSelId).TypeText <> "Regional Center Only"` | add/edit DoR |
| SV-SS-FORM | Students | `conStuSsForm` | `=IsFinance && !IsBlank(varStuSelId) && varStuSsMode <> ""` | add/edit SS |
| SV-DOR-CONFIRM / SV-SS-CONFIRM | Students | `conStuDorConfirm`, `conStuSsConfirm` | `=!IsBlank(varStuDorDelId)` / `=!IsBlank(varStuSsDelId)` | during delete confirm |
| SV-RECEIPTS | all mutating | `con<X>Receipt` | `=var<X>Receipt.Kind <> ""` | after a mutation until dismissed / next action / screen re-entry |

## Action Contracts

Abbreviations: "skeleton" = shared Mutation skeleton; "audit" = shared Audit Events row; all GUIDs are With() scalars.

| Requested action | Preconditions | Entry point | Owner screen | Control and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-GATE | any user | app open / any screen | all | `con<P>Gate.Visible`, engines' `!IsFinance` branch | Staff via CurrentStaff | non-finance: collections cleared, only gate shown | N/A | N/A | `con<P>Gate.Visible = !IsFinance`; body/nav `Visible` include IsFinance |
| A-NAV | IsFinance | header nav | all | `btn<P>Nav*.OnSelect = Navigate(...)` | N/A | screen changes | N/A | N/A | destination nav button Primary teal |
| A-HOME-LOAD | IsFinance | HomeScreen.OnVisible, `btnHomeRefresh` | Home | `btnHomeLoadEngine.OnSelect` | Funders, Services, Students, Districts of Record | colFunders/colServices/colStudents/colDor reloaded; `varHomeLoadedAt = Now()` | N/A | N/A | four `lblHome*Count` labels; `lblHomeStatus` "Counts as of ..." or error |
| A-HOME-FUNQBO | IsFinance | `btnHomeFunQbo` "Review funders" | Home | OnSelect | filter globals | varFunType "All", varFunMissingQbo true, varFunShowInactive false; Navigate(FundersScreen) | N/A | N/A | `btnFunChipMissing` Primary; `lblFunCount` n = Home count |
| A-HOME-SVCQBO | IsFinance | `btnHomeSvcQbo` "Review services" | Home | OnSelect | filter globals | varSvcKind "All", varSvcMissingQbo true, varSvcShowInactive false; Navigate(ServicesScreen) | N/A | N/A | `btnSvcChipMissing` Primary; `lblSvcCount` n = Home count |
| A-HOME-STUDOR | IsFinance | `btnHomeStuDor` "Review students" | Home | OnSelect | filter globals | varStuType "All", varStuNoDor true, varStuStatus "Active"; Navigate(StudentsScreen) | N/A | N/A | `btnStuChipNoDor` Primary; `lblStuCount` n = Home count |
| A-HOME-PRIVPAY | IsFinance | `btnHomePrivPay` "Review Private Pay" | Home | OnSelect | filter globals | varFunType "Private Pay", varFunMissingQbo true, varFunShowInactive true; Navigate(FundersScreen) | N/A | N/A | Private Pay + Missing chips Primary; `lblFunCount` n = Home count |
| A-FUN-LOAD | IsFinance | FundersScreen.OnVisible, `btnFunReload` | Funders | `btnFunLoadEngine.OnSelect` | Funders, Funder Aliases | colFunders, colFunderAliases reloaded | N/A | N/A | `galFunList`, `lblFunCount` |
| A-FUN-SEARCH | loaded | `txtFunSearch` | Funders | Text (Delayed) consumed by `galFunList.Items` | colFunders + colFunderAliases | rows where abbr/full name/any alias contains the text (case-insensitive) | N/A | N/A | `galFunList`, `lblFunCount` "Showing n of m" |
| A-FUN-TYPE | loaded | chips All/District/Regional Center/Private Pay | Funders | `btnFunChip*.OnSelect = Set(varFunType, "<value>")` | varFunType | exclusive type filter | N/A | N/A | active chip Primary; list |
| A-FUN-MISSQBO | loaded | `btnFunChipMissing` | Funders | `OnSelect = Set(varFunMissingQbo, !varFunMissingQbo)` | varFunMissingQbo | adds `Trim(QboCustomer) = ""` | N/A | N/A | chip Primary when on; list |
| A-FUN-INACTIVE | loaded | `tglFunInactive` | Funders | OnCheck/OnUncheck set varFunShowInactive | varFunShowInactive | inactive funders shown/hidden | N/A | N/A | list rows tagged "Inactive" |
| A-FUN-CLEAR | any filter set | `btnFunClear` | Funders | OnSelect resets all four filter states | filter state | All, false, false, search "" | N/A | N/A | all chips reset, `lblFunCount` n = m active |
| A-FUN-SELECT | row visible | `btnFunRowEdit` "Edit" | Funders | OnSelect | colFunders.FunderId | varFunSelId = ThisItem.FunderId, varFunMode "edit", receipts cleared, inputs reset via `btnFunFormResetEngine` | N/A | N/A | `conFunForm` visible, inputs prepopulated, row Fill ColorInfoBg |
| A-FUN-NEW | IsFinance | `btnFunNew` "New funder" | Funders | OnSelect | none (new) | varFunSelId Blank, varFunMode "new", inputs reset to blank/District/Active | N/A | N/A | `lblFunFormTitle` "New funder" |
| A-FUN-CREATE | mode "new", validation "Ready to save." | `btnFunSave` | Funders | OnSelect (skeleton) | Funders; returned `varFunLastRec.Funder` | new Funders row; varFunSelId = returned GUID, mode "edit"; audit Create | Abbreviation, Full Name, Funder Type, QuickBooks Customer, Active | identity GUID (RecordId) + Abbreviation, Full name, Funder type, QuickBooks customer, Active, audit | `lblFunReceipt` "Created funder ..."; row in `galFunList` highlighted |
| A-FUN-UPDATE | mode "edit", valid | `btnFunSave` | Funders | OnSelect (skeleton) | Funders by `varFunSelId` | row updated; audit Update with Before/After JSON | Abbreviation, Full Name, Funder Type, QuickBooks Customer, Active | as create + "Active before -> after (status change)" | `lblFunReceipt` "Updated funder ..."; row fields |
| A-FUN-DEACT | mode "edit", saved Active = true | `tglFunActive` off then `btnFunSave` | Funders | toggle = selection-only; Save = mutation | Funders by varFunSelId | Active true -> false (literal guard `old.IsActive && !act`) | Active (+ any other edited fields) | "Active Yes -> No (Deactivated)" | receipt; row tagged Inactive / hidden when Show inactive off |
| A-FUN-REACT | mode "edit", saved Active = false | `tglFunActive` on then Save | Funders | same | same | Active false -> true (guard `!old.IsActive && act`) | Active | "Active No -> Yes (Reactivated)" | receipt; row no longer tagged |
| A-FUN-CANCEL | mode <> "" | `btnFunCancel` | Funders | OnSelect | none | no Patch; varFunSelId Blank, varFunMode "" | N/A | N/A | form hidden; list row unchanged |
| A-FUN-ALIAS-ADD | mode "edit"; normalised text non-empty and not mapped anywhere | `btnFunAliasAdd` "Add alias" | Funders | OnSelect (skeleton, server re-check) | Funder Aliases; returned `varFunLastAlias.'Funder Alias'` | new alias (CodeMetro Name = NormAlias(input), Funder = selected funder); audit Create | CodeMetro Name, Funder | alias text, funder abbreviation, audit | `lblFunAliasReceipt` "Added alias ..."; `galFunAliases`; row alias count |
| A-FUN-ALIAS-MOVE | normalised text mapped to another funder | `btnFunAliasMove` "Move it here" | Funders | OnSelect (skeleton) | Funder Aliases by clash AliasId | alias Funder changes to selected funder; audit Update Before {Funder: old} After {Funder: new} | Funder | alias text, from funder, to funder, audit | receipt "Moved alias ..."; alias appears in this funder's list, gone from the other |
| A-FUN-ALIAS-DEL | confirm row open | `btnFunAliasRowRemove` then `btnFunAliasConfirmYes` "Remove" | Funders | Yes.OnSelect (skeleton with Remove) | Funder Aliases by varFunAliasDelId (snapshot from colFunderAliases) | row deleted; audit Soft Delete with Before JSON | existence | removed alias text, funder, audit | receipt "Removed alias ..."; alias gone from `galFunAliases` |
| A-FUN-ALIAS-DELCANCEL | confirm row open | `btnFunAliasConfirmNo` "Keep" | Funders | OnSelect | none | varFunAliasDelId Blank; no change | N/A | N/A | confirm hidden; alias still listed |
| A-SVC-LOAD | IsFinance | ServicesScreen.OnVisible, `btnSvcReload` | Services | `btnSvcLoadEngine` | Services, Service Aliases | collections reloaded | N/A | N/A | `galSvcList` sorted KindRank then SortOrder |
| A-SVC-KIND / A-SVC-MISSQBO / A-SVC-INACTIVE / A-SVC-CLEAR | loaded | chips, toggle, Clear | Services | as Funders with varSvcKind / varSvcMissingQbo / varSvcShowInactive | colServices | filtered list | N/A | N/A | chips, `lblSvcCount` |
| A-SVC-SELECT / A-SVC-NEW / A-SVC-CANCEL | as Funders | `btnSvcRowEdit`, `btnSvcNew`, `btnSvcCancel` | Services | as Funders | colServices.ServiceId | form state | N/A | N/A | `conSvcForm` |
| A-SVC-CREATE | mode "new", valid | `btnSvcSave` | Services | skeleton | Services; returned `varSvcLastRec.Service` | new service; audit Create | Service Code, Name, Kind, Billing Unit, QuickBooks Item, Sort Order, Billable, Billable on Non-School Days, Active | code, name, kind, unit, QBO item, sort order, billable, non-school, active, audit | `lblSvcReceipt`; list row |
| A-SVC-UPDATE | mode "edit", valid | `btnSvcSave` | Services | skeleton | Services by varSvcSelId | updated; audit Update | same as create (minus Code, Kind for SPED) | same + Active before -> after | receipt; row |
| A-SVC-SPED | selected Code = "SPED" | form | Services | `txtSvcCode.DisplayMode`, `rdoSvcKind.DisplayMode` = View; save branch without code/kind | Services | code/kind never written for SPED | Name, Billing Unit, QBO Item, Sort Order, Billable, Non-School, Active | receipt shows Code SPED, Kind School Day unchanged | `lblSvcHelp` "SPED is the attendance service..." |
| A-SVC-DEACT / A-SVC-REACT | as Funders | `tglSvcActive` + Save | Services | as Funders | Services by varSvcSelId | Active true->false / false->true with literal guards | Active | "Active Yes -> No (Deactivated)" / "No -> Yes (Reactivated)" | receipt; row "Inactive" tag |
| A-SVC-CPT-ADD | mode "edit"; normalised CPT text not mapped as CPT Code | `btnSvcCptAdd` | Services | skeleton | Service Aliases; returned `varSvcLastAlias.'Service Alias'` | alias Type CPT Code; audit Create | Alias, Alias Type, Service | alias text, type, service code, audit | `lblSvcAliasReceipt`; `galSvcCpt` |
| A-SVC-SNM-ADD | same for Service Name | `btnSvcSnmAdd` | Services | skeleton | same | alias Type Service Name | Alias, Alias Type, Service | same | receipt; `galSvcSnm` |
| A-SVC-ALIAS-MOVE | same text + same type mapped to another service | `btnSvcCptMove` / `btnSvcSnmMove` | Services | skeleton | Service Aliases by clash AliasId | Service changes; audit Update | Service | alias, type, from code, to code, audit | receipt; alias in this service's group |
| A-SVC-ALIAS-DEL / -DELCANCEL | confirm open | row "Remove" -> `btnSvcAliasConfirmYes` / `btnSvcAliasConfirmNo` | Services | skeleton with Remove / clear | Service Aliases by varSvcAliasDelId | deleted (audit Soft Delete) / unchanged | existence / N/A | removed alias, type, service, audit / N/A | receipt; alias gone / still listed |
| A-STU-LOAD | IsFinance | StudentsScreen.OnVisible, `btnStuReload` | Students | `btnStuLoadEngine` | Students, Districts of Record, Student Services, Funders, Services | five collections reloaded | N/A | N/A | `galStuList`, `lblStuCount` |
| A-STU-SEARCH / -TYPE / -NODOR / -STATUS / -CLEAR | loaded | `txtStuSearch`, chips, Clear | Students | consumed by `galStuList.Items` | colStudents (+ colDor) | filtered list | N/A | N/A | chips, `lblStuCount` |
| A-STU-SELECT | row visible | `btnStuRowOpen` "Open" | Students | OnSelect | colStudents.StudentId | varStuSelId = ThisItem.StudentId; DoR/SS modes, delete ids, receipts cleared | N/A | N/A | `conStuHead`, `galStuDor`, `galStuSs` for that student |
| A-DOR-NEW | student School type | `btnStuDorAdd` "Add district" | Students | OnSelect | none | varStuDorMode "new", varStuDorEditId Blank, form reset | N/A | N/A | `conStuDorForm` "Add district of record" |
| A-DOR-CREATE | mode "new", valid (funder, start, end rule, no overlap) | `btnStuDorSave` | Students | skeleton | Districts of Record; returned `varStuLastDor.'District of Record'` | new row Source Manual, Summary "<Key> - <Abbr>"; audit Create | Summary, Student, Funder, Start Date, End Date, Source, Note | student key, district, start, end/ongoing, source, note, audit | `lblStuDorReceipt`; `galStuDor`; list row warning cleared |
| A-DOR-EDIT | mode "edit" on any row, valid | row "Edit" -> `btnStuDorSave` | Students | skeleton | Districts of Record by varStuDorEditId | row updated; Source set to Manual (CodeMetro -> Manual); audit Update | Summary, Funder, Start Date, End Date, Source, Note | district, start, end, source (before -> Manual), note, audit | receipt; row |
| A-DOR-END | edit of an ongoing row; untick Ongoing, pick end >= start | same as A-DOR-EDIT | Students | skeleton | same | End Date set (row ended) | End Date, Source (+ unchanged others rewritten with same values) | "End <date>" | receipt; row shows end date |
| A-DOR-CANCEL | form open | `btnStuDorCancel` | Students | OnSelect | none | mode "", edit id Blank; no Patch | N/A | N/A | form hidden |
| A-DOR-DEL | row SourceText = "Manual"; confirm open | `btnStuDorRowDelete` -> `btnStuDorConfirmYes` | Students | skeleton with Remove | Districts of Record by varStuDorDelId (snapshot) | row deleted; audit Soft Delete | existence | district, start, end, audit | receipt "Deleted district of record ..."; row gone |
| A-DOR-DELCANCEL | confirm open | `btnStuDorConfirmNo` | Students | OnSelect | none | varStuDorDelId Blank | N/A | N/A | row still listed |
| A-SS-NEW | student selected | `btnStuSsAdd` "Add service row" | Students | OnSelect | none | varStuSsMode "new", form reset | N/A | N/A | `conStuSsForm` |
| A-SS-CREATE | mode "new", valid | `btnStuSsSave` | Students | skeleton | Student Services; returned `varStuLastSs.'Student Service'` | new Manual row; Summary "<Key> - <Code>[ #n] - <Abbr>"; audit Create | Summary, Student, Service, Funder, Start Date, End Date, Frequency, Minutes per Frequency, ESY, Excluded, Source, Note | service code, funder, start, end, frequency, minutes, ESY, excluded, source, note, summary, audit | `lblStuSsReceipt`; `galStuSs`; list row count |
| A-SS-EDIT | Manual row, mode "edit", valid | row "Edit" -> Save | Students | skeleton | Student Services by varStuSsEditId | updated; audit Update | as create minus Student, Source | same + Excluded before -> after | receipt; row |
| A-SS-CMEDIT | CodeMetro row in edit | row "Edit" -> Save | Students | skeleton (CodeMetro branch) | same | only Excluded, Note written; Source Key etc untouched | Excluded, Note | excluded before -> after, note, audit | receipt; row |
| A-SS-EXCL | saved Excluded = false | `tglStuSsExcluded` on + Save | Students | toggle selection-only; Save mutates | same | Excluded false -> true (guard `!old.IsExcluded && ex`) | Excluded | "Excluded No -> Yes (Excluded)" | row muted + Excluded badge; count drops |
| A-SS-INCL | saved Excluded = true | toggle off + Save | Students | same | same | Excluded true -> false (guard `old.IsExcluded && !ex`) | Excluded | "Excluded Yes -> No (Included)" | badge gone |
| A-SS-CANCEL | form open | `btnStuSsCancel` | Students | OnSelect | none | no Patch | N/A | N/A | form hidden |
| A-SS-DEL | Manual row, confirm open | `btnStuSsRowDelete` -> `btnStuSsConfirmYes` | Students | skeleton with Remove | Student Services by varStuSsDelId (snapshot) | deleted; audit Soft Delete | existence | summary, service, funder, start, audit | receipt; row gone |
| A-SS-DELCANCEL | confirm open | `btnStuSsConfirmNo` | Students | OnSelect | none | id Blank | N/A | N/A | row still listed |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization when sources differ | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-FUN-CREATE / UPDATE / DEACT / REACT | `varFunLastRec` -> `varFunReceipt` -> `lblFunReceipt` | Funders; `LookUp(colFunders, FunderId = varFunSelId)` after reload | `galFunList` row + `conFunForm` | `varFunLastRec.Funder` -> `varFunReceipt.RecordId` -> `varFunSelId` | success path `Select(btnFunLoadEngine)` (Refresh + ClearCollect) | `varFunSelId` = returned GUID: row Fill ColorInfoBg, form shows it |
| A-FUN-ALIAS-ADD / MOVE | `varFunLastAlias` -> `varFunAliasReceipt` | Funder Aliases; `Filter(colFunderAliases, FunderId = varFunSelId)` | `galFunAliases` | returned alias GUID in RecordId | `Select(btnFunLoadEngine)` | aliases filtered to selected funder |
| A-FUN-ALIAS-DEL | snapshot `LookUp(colFunderAliases, AliasId = varFunAliasDelId)` | absence in colFunderAliases | `galFunAliases` | snapshot AliasId | `Select(btnFunLoadEngine)` | N/A (row removed) |
| A-SVC-CREATE / UPDATE / SPED / DEACT / REACT | `varSvcLastRec` -> `lblSvcReceipt` | Services; `LookUp(colServices, ServiceId = varSvcSelId)` | `galSvcList`, `conSvcForm` | `varSvcLastRec.Service` -> RecordId -> `varSvcSelId` | `Select(btnSvcLoadEngine)` | row highlighted by varSvcSelId |
| A-SVC-CPT-ADD / SNM-ADD / MOVE / DEL | `varSvcLastAlias` or snapshot -> `lblSvcAliasReceipt` | Service Aliases; colServiceAliases | `galSvcCpt` / `galSvcSnm` | alias GUID | `Select(btnSvcLoadEngine)` | filtered to varSvcSelId + type |
| A-DOR-CREATE / EDIT / END / DEL | `varStuLastDor` or snapshot -> `lblStuDorReceipt` | Districts of Record; `Filter(colDor, StudentId = varStuSelId)` | `galStuDor`; list row meta; Home card on next visit | returned DoR GUID; student id unchanged in varStuSelId | `Select(btnStuLoadEngine)` | student stays selected (varStuSelId) |
| A-SS-CREATE / EDIT / CMEDIT / EXCL / INCL / DEL | `varStuLastSs` or snapshot -> `lblStuSsReceipt` | Student Services; `Filter(colStuSvc, StudentId = varStuSelId)` | `galStuSs`; list row count | returned SS GUID | `Select(btnStuLoadEngine)` | student stays selected |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| A-FUN-CREATE/UPDATE | Abbreviation | Changed | `Trim(txtFunAbbr.Text)` | Patch `Abbreviation` | "Abbreviation " & varFunLastRec.Abbreviation | `lblFunRowAbbr` |
| A-FUN-CREATE/UPDATE | Full Name | Changed | `Trim(txtFunFull.Text)` | `'Full Name'` | "Full name " & varFunLastRec.'Full Name' | `lblFunRowName` |
| A-FUN-CREATE/UPDATE | Funder Type | Changed | `rdoFunType.Selected.Value` | `'Funder Type'` via Switch | "Funder type " & Text(varFunLastRec.'Funder Type') | `lblFunRowName` |
| A-FUN-CREATE/UPDATE | QuickBooks Customer | Changed | `Trim(txtFunQbo.Text)` | `'QuickBooks Customer'` | "QuickBooks customer " & Coalesce(...,"none") | `lblFunRowQbo` |
| A-FUN-CREATE/UPDATE/DEACT/REACT | Active | Changed | `tglFunActive.Checked`; pre-state `LookUp(colFunders, FunderId = varFunSelId).IsActive` | `Active` | "Active " & before & " -> " & after & " (" & op & ")" | `lblFunRowName` "Inactive" tag |
| A-FUN-UPDATE | aliases | Preserved | colFunderAliases for FunderId | not part of Patch | alias count unchanged | `lblFunRowName` "N aliases" |
| A-FUN-ALIAS-ADD | CodeMetro Name, Funder | Changed | `NormAlias(txtFunAliasNew.Text)`, varFunSelId | Patch Defaults | "Added alias X to ABBR" | `galFunAliases` |
| A-FUN-ALIAS-MOVE | Funder | Changed | clash row FunderId | Patch `Funder` only | "from X to Y" | `galFunAliases` |
| A-FUN-ALIAS-MOVE | CodeMetro Name | Preserved | clash row AliasText | omitted from Patch | alias text in receipt | `galFunAliases` |
| A-FUN-ALIAS-DEL | existence | Changed | snapshot | Remove | "Removed alias X from ABBR" | absent from `galFunAliases` |
| A-SVC-CREATE/UPDATE | Service Code, Name, Kind, Billing Unit, QuickBooks Item, Sort Order, Billable, Non-School, Active | Changed (one row each in brief) | `txtSvcCode`, `txtSvcName`, `rdoSvcKind`, `rdoSvcUnit`, `txtSvcQbo`, `txtSvcSort`, `tglSvcBillable`, `tglSvcNonSchool`, `tglSvcActive` | Patch | one labeled receipt segment each | `lblSvcRowCode`, `lblSvcRowMeta`, `lblSvcRowQbo` |
| A-SVC-SPED | Service Code, Kind | Preserved | colServices row | omitted from Patch (SPED branch) | "Code SPED", "Kind School Day" read from varSvcLastRec | `lblSvcRowCode`, `lblSvcRowMeta` |
| A-SVC-*-ADD | Alias, Alias Type, Service | Changed | NormAlias(input), group type, varSvcSelId | Patch Defaults | "Added CPT code X to CODE" | `galSvcCpt` / `galSvcSnm` |
| A-SVC-ALIAS-MOVE | Service | Changed; Alias + Alias Type Preserved | clash row | Patch `Service` only | "from A to B" | group gallery |
| A-DOR-CREATE/EDIT/END | Funder, Start Date, End Date, Note, Source, Summary | Changed | `ddStuDorFunder.Selected`, `dpStuDorStart`, `chkStuDorOngoing`/`dpStuDorEnd`, `txtStuDorNote`, Manual, "<Key> - <Abbr>" | Patch | one labeled segment each | `lblStuDorRowMain`, `lblStuDorRowMeta` |
| A-DOR-EDIT | Student | Preserved | row StudentId | omitted on edit | student key in receipt | row stays under student |
| A-DOR-DEL | existence | Changed | snapshot | Remove | "Deleted district of record ..." | absent from `galStuDor` |
| A-SS-CREATE/EDIT | Service, Funder, Start, End, Frequency, Minutes, ESY, Excluded, Note, Summary (+ Student, Source on create) | Changed | `ddStuSsService`, `ddStuSsFunder`, `dpStuSsStart`, `chkStuSsOngoing`/`dpStuSsEnd`, `txtStuSsFreq`, `txtStuSsMin`, `tglStuSsEsy`, `tglStuSsExcluded`, `txtStuSsNote` | Patch | one labeled segment each | `lblStuSsRowMain`, `lblStuSsRowDates`, `lblStuSsRowMeta`, `badStuSsExcluded` |
| A-SS-CMEDIT/EXCL/INCL | Excluded, Note | Changed | `tglStuSsExcluded.Checked`, `txtStuSsNote` | Patch with only these two fields | "Excluded before -> after (op)", "Note ..." | row badge, meta |
| A-SS-CMEDIT | Service, Funder, Dates, Frequency, Minutes, ESY, Source, Source Key, Summary | Preserved | colStuSvc row | omitted from Patch | receipt "Other fields unchanged (CodeMetro row)" | row values unchanged |
| A-SS-DEL | existence | Changed | snapshot | Remove | "Deleted service row SUMMARY" | absent from `galStuSs` |

## Functional Test Matrix

Test data: scenarios create their own records with the prefix ZZTEST so the 31 real funders / 33 services / 146
students are not disturbed (packet volumes are the Given for counts). "Receipt" = the section receipt label.

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-GATE-DENY | Signed-in user's Staff row has Finance Access = No (or no Staff row) | Open the app | Only header title/identity and `conHomeGate` show; collections empty | `conHomeGate` visible, `conHomeBody`/`conHomeNav` hidden; same on every screen | no Staff row -> "not linked to an active Staff record" text |
| S-GATE-ALLOW | Finance Access = Yes, Staff Active | Open the app | Home body, nav and counts show | `conHomeBody` visible | N/A |
| S-NAV | IsFinance | Select Funders, Services, Students, Home in turn | Each screen opens; its own nav button is teal Primary; no rate/dollar field appears anywhere | `btn<P>Nav*` | N/A |
| S-HOME-LOAD | Dev data (31 funders, 4 Private Pay, 14 active School students without DoR) | Open Home | Counts equal the shared predicates over loaded collections (StuDor card = 14 at capture time); status "Counts as of <time>"; Coming next text visible | `lblHome*Count`, `lblHomeStatus`, `lblHomeNextBody` | Refresh button reloads |
| S-LOAD-FAIL | Data source unavailable (e.g. remove read privilege) | Reload | Error text shown, no crash | `lblHomeStatus` / `lbl<P>Count` "Could not load ..." | N/A |
| S-HOME-FUNQBO | Home shows N1 on the funders card | Select "Review funders" | FundersScreen; Missing chip on, type All, inactive off; `lblFunCount` shows N1 | `lblFunCount`, chips | N/A |
| S-HOME-SVCQBO | Card N2 | "Review services" | Services Missing chip on; count N2 | `lblSvcCount` | N/A |
| S-HOME-STUDOR | Card N3 (14) | "Review students" | Students No-DoR chip on, status Active; count N3 | `lblStuCount` | N/A |
| S-HOME-PRIVPAY | Card N4 | "Review Private Pay" | Private Pay + Missing chips on, Show inactive on; count N4 | `lblFunCount` | N/A |
| S-FUN-LOAD | Funders exist | Open Funders | Each row shows abbreviation, full name, type, QBO customer or warning, alias count | `galFunList` rows | funder with blank QBO shows "No QuickBooks customer" in warning colour |
| S-FUN-CREATE | No funder ZZTEST1 | New funder; Abbreviation " ZZTEST1 ", Full name "ZZ Test District", type District, QBO blank, Active on; Save | Funders row ZZTEST1 (trimmed) exists; Audit Events Create, Entity "Funders", Entity ID = GUID | Receipt "Created funder ZZTEST1. Abbreviation ZZTEST1 / Full name ZZ Test District / Funder type District / QuickBooks customer none / Active Yes / Audit written"; row highlighted | Home funders card +1 on next visit |
| S-FUN-CREATE-REQ | New funder form | Leave Abbreviation blank | Save disabled; no Patch | `lblFunValidation` "Abbreviation is required." | type cannot be blank (radio default District) |
| S-FUN-CREATE-DUP | ZZTEST1 exists | New funder with Abbreviation "zztest1" | Save disabled | `lblFunValidation` "Abbreviation zztest1 is already used by ZZ Test District." | server re-check in Save blocks a stale-list duplicate with a Blocked receipt |
| S-FUN-UPDATE | ZZTEST1, QBO blank | Edit; QBO "ZZ Test Customer"; Save | QuickBooks Customer saved; audit Update with Before/After JSON | Receipt "Updated funder ZZTEST1 ... QuickBooks customer ZZ Test Customer"; row line 3 | N/A |
| S-FUN-DEACT | ZZTEST1 Active | Edit; Active off; Save | Active = false | Receipt "Active Yes -> No (Deactivated)"; row hidden with Show inactive off, tagged "Inactive" with it on | N/A |
| S-FUN-REACT | ZZTEST1 inactive, Show inactive on | Edit; Active on; Save | Active = true | Receipt "Active No -> Yes (Reactivated)" | N/A |
| S-FUN-COMPOUND | ZZTEST1 Active | Deactivate + Save, then (same record still selected) Reactivate + Save | Second receipt reads "No -> Yes": old value comes from reloaded colFunders | two receipts | N/A |
| S-FUN-CANCEL | ZZTEST1 open | Change full name, select Cancel | No change in Funders; form closed | row still "ZZ Test District" | N/A |
| S-FUN-FAIL | ZZTEST1 open | Enter a Full Name longer than the column max length; Save | Patch fails; nothing saved | Receipt Kind Failed "Funder not saved. <error>" on ColorErrorBg | form stays open |
| S-FUN-SEARCH | ZZTEST1, ZZTEST2 exist; ZZTEST1 alias "ZZ TEST DISTRICT" | Type "zztest" then "zz test dis" | First: ZZTEST1 and ZZTEST2 shown, real funders hidden; second: ZZTEST1 (alias match) shown | `galFunList`, `lblFunCount` | clearing search restores all |
| S-FUN-TYPE | ZZTEST1, ZZTEST2 District; ZZTESTPP Private Pay | District chip | both District test funders shown, ZZTESTPP hidden | list | All chip restores |
| S-FUN-MISSQBO | ZZTEST2 QBO blank, ZZTEST1 QBO set | Missing chip | ZZTEST2 shown, ZZTEST1 hidden | list | chip off restores |
| S-FUN-INACTIVE | ZZTEST2 inactive | Toggle Show inactive on/off | shown with "Inactive" tag / hidden | list | default off |
| S-FUN-CLEAR | District + Missing + search set | Clear filters | All filters default, search empty | chips, `lblFunCount` | N/A |
| S-FUN-ALIAS-ADD | ZZTEST1 open, no aliases | Type "  zz   test  district "; preview shows "Will be saved as ZZ TEST DISTRICT"; Add alias | Funder Aliases row "ZZ TEST DISTRICT" -> ZZTEST1; audit Create | Receipt "Added alias ZZ TEST DISTRICT to ZZTEST1"; `galFunAliases`; row "1 alias" | blank input -> Add disabled |
| S-FUN-ALIAS-SAME | alias exists on ZZTEST1 | Type "zz test district" on ZZTEST1 | Add disabled; nothing written | `lblFunAliasNotice` "Already mapped to this funder." | N/A |
| S-FUN-ALIAS-MOVE | alias on ZZTEST1; ZZTEST2 open | Type "ZZ Test District" | Notice "Already mapped to ZZTEST1 ..."; Move it here -> alias Funder = ZZTEST2; audit Update | Receipt "Moved alias ZZ TEST DISTRICT from ZZTEST1 to ZZTEST2"; alias listed under ZZTEST2 | Add disabled while clash |
| S-FUN-ALIAS-DEL | alias on ZZTEST2 | Remove -> confirm "Remove alias ... from ZZTEST2?" -> Remove | row deleted; audit Soft Delete | Receipt "Removed alias ..."; gone | N/A |
| S-FUN-ALIAS-DELCANCEL | confirm open | Keep | nothing deleted | alias still listed | N/A |
| S-SVC-LOAD | services loaded | Open Services | rows sorted School Day first then by Sort Order; each row code, name, kind, unit, QBO item or warning, flags | `galSvcList` | N/A |
| S-SVC-KIND / S-SVC-MISSQBO / S-SVC-INACTIVE / S-SVC-CLEAR | ZZSVC1, ZZSVC2 School Day, ZZSVC3 Clinical | chip/toggle/clear | 2 matching shown, 1 hidden; clear restores | list, `lblSvcCount` | N/A |
| S-SVC-CREATE | none | New service "ZZSVC1", name "ZZ Test Aide", School Day, Days, QBO blank, Billable on, Non-school off, Sort 90, Active; Save | Services row; audit Create | Receipt with all nine labeled fields | N/A |
| S-SVC-CREATE-DUP | ZZSVC1 exists | New service code "zzsvc1" | Save disabled | `lblSvcValidation` "Service code zzsvc1 is already used ..." | N/A |
| S-SVC-SORT-INVALID | form open | Sort order "abc" | Save disabled | "Sort order must be a whole number." | blank sort order allowed |
| S-SVC-UPDATE | ZZSVC1 | QBO item "ZZ Item"; Save | saved | Receipt; row line 3 | N/A |
| S-SVC-SPED | SPED service | Edit SPED | Code and Kind inputs read-only; Save changes Name/QBO only | `lblSvcHelp`; receipt shows Code SPED, Kind School Day | N/A |
| S-SVC-DEACT / S-SVC-REACT / S-SVC-COMPOUND | ZZSVC1 Active | Active off Save; then on Save | false then true | receipts "Yes -> No (Deactivated)", "No -> Yes (Reactivated)" | N/A |
| S-SVC-CANCEL | ZZSVC1 open | edit name, Cancel | unchanged | row | N/A |
| S-SVC-CPT-ADD | ZZSVC1 open | CPT "  zz97153 " -> Add | Service Aliases ZZ97153, CPT Code, ZZSVC1 | receipt; `galSvcCpt` | N/A |
| S-SVC-SNM-ADD | ZZSVC1 open | Service name "zz test   aide" -> Add | alias "ZZ TEST AIDE", Service Name | receipt; `galSvcSnm` | N/A |
| S-SVC-ALIAS-TYPES | ZZ97153 exists as CPT Code | Add "ZZ97153" as a Service Name on ZZSVC1 | allowed (unique key is text + type) | `galSvcSnm` | N/A |
| S-SVC-ALIAS-SAME | ZZ97153 CPT on ZZSVC1 | type it again in CPT group | Add disabled, "Already mapped to this service." | `lblSvcCptNotice` | N/A |
| S-SVC-ALIAS-MOVE | ZZ97153 CPT on ZZSVC1; ZZSVC2 open | type ZZ97153 in CPT group; Move it here | alias Service = ZZSVC2 | receipt "Moved CPT code ZZ97153 from ZZSVC1 to ZZSVC2" | N/A |
| S-SVC-ALIAS-DEL / -DELCANCEL | alias listed | Remove -> confirm / Keep | deleted / unchanged | receipt / list | N/A |
| S-STU-LOAD | students loaded | Open Students | rows "KEY - Last, First"; meta type, DoR abbr or "No district of record", "N active day services" | `galStuList` | RC Only students never show the DoR warning |
| S-STU-SEARCH | students CW-1083 etc | type "cw-108", then a last name | matching rows only | list, count | N/A |
| S-STU-TYPE | 12 Regional Center Only students | Regional Center Only chip | only RC- keys | list | N/A |
| S-STU-NODOR | 14 active School students without current DoR | No district of record chip | exactly those 14 | `lblStuCount` 14 | adding a DoR (S-DOR-CREATE) drops the count to 13 |
| S-STU-STATUS | inactive students exist | All statuses chip | inactive/archived included | list | Active chip default |
| S-STU-CLEAR | filters set | Clear filters | defaults (All, off, Active, search empty) | chips | N/A |
| S-STU-SELECT | a School student | Open | header key/name/type/status read-only; DoR rows sorted start desc; SS rows sorted by service sort order then start; caption shown | `conStuHead`, `galStuDor`, `galStuSs`, `lblStuSsCaption` | N/A |
| S-DOR-RC | RC Only student | Open | DoR caption "Regional Center Only students have no district of record."; no Add, no rows | `lblStuDorCaption`, `btnStuDorAdd` hidden | N/A |
| S-DOR-CREATE | School student S1 with no DoR (from No-DoR list); active District funder ZZTEST1 | Add district: ZZTEST1, start 2026-07-01, Ongoing ticked, note "ZZ test"; Save | DoR row Manual, Summary "<S1 key> - ZZTEST1"; audit Create | Receipt "Created district of record. Student <key> / District ZZTEST1 / Start Jul 1, 2026 / End ongoing / Source Manual / Note ZZ test"; row; list warning gone | Home StuDor card -1 |
| S-DOR-REQ | add form | no district / no start | Save disabled with "Choose a district." / "Start date is required." | `lblStuDorValidation` | Ongoing unticked + no end -> "Pick an end date or tick Ongoing." |
| S-DOR-ENDBEFORE | add form | start 2026-09-01, end 2026-08-01 | Save disabled | "End date must be on or after the start date." | end = start allowed |
| S-DOR-OVERLAP | S1 has ZZTEST1 from 2026-07-01 ongoing | add ZZTEST2 from 2026-09-01 | Save disabled | "Overlaps ZZTEST1 Jul 1, 2026 to ongoing. ..." | adjacent (end 2026-08-31 then start 2026-09-01) allowed |
| S-DOR-EDIT-CM | a CodeMetro DoR row | Edit, change note; Save | Source = Manual | Receipt "Source CodeMetro -> Manual" | N/A |
| S-DOR-END | S1 row ongoing | Edit, untick Ongoing, end 2026-12-31; Save | End Date set | Receipt "End Dec 31, 2026"; row "Jul 1, 2026 to Dec 31, 2026" | N/A |
| S-DOR-CANCEL | form open | Cancel | unchanged | row | N/A |
| S-DOR-DEL | Manual row | Delete -> confirm -> Delete | removed; audit Soft Delete | receipt "Deleted district of record ZZTEST1 ..."; row gone | N/A |
| S-DOR-DEL-CM | CodeMetro row | look at row | no Delete button | `btnStuDorRowDelete.Visible = false` | N/A |
| S-DOR-DELCANCEL | confirm open | Keep | unchanged | row | N/A |
| S-SS-CREATE | S1 selected; active School Day service ZZSVC1; funder ZZTEST1 | Add service row: ZZSVC1, ZZTEST1, start 2026-07-01, Ongoing, frequency "Daily", minutes 360, ESY off, Excluded off, note "ZZ"; Save | Manual row Summary "<key> - ZZSVC1 - ZZTEST1"; audit Create | Receipt with all labeled fields | service picker excludes SPED and Clinical/inactive services |
| S-SS-CREATE-2 | one ZZSVC1 row exists for S1 | add a second ZZSVC1 row | Summary "<key> - ZZSVC1 #2 - ZZTEST1" | receipt Summary | N/A |
| S-SS-REQ | add form | no service / funder / start | Save disabled with message | `lblStuSsValidation` | N/A |
| S-SS-MIN-INVALID | add form | minutes "abc" or -5 | Save disabled "Minutes must be a number 0 or more." | validation | blank minutes allowed |
| S-SS-EDIT | Manual row | change frequency "3x week"; Save | saved | receipt | N/A |
| S-SS-CMEDIT | CodeMetro row | Edit: service/funder/dates/frequency/minutes/ESY read-only; change note; Save | only Note (and Excluded) written; Source Key untouched | receipt "Other fields unchanged (CodeMetro row)" | N/A |
| S-SS-EXCL | CodeMetro row Excluded off | Excluded on; Save | Excluded = true | receipt "Excluded No -> Yes (Excluded)"; row muted with badge; list count -1 | N/A |
| S-SS-INCL | same row excluded | Excluded off; Save | false | "Excluded Yes -> No (Included)" | N/A |
| S-SS-COMPOUND | same row | exclude then include in sequence | second op reads true from reloaded colStuSvc | two receipts | N/A |
| S-SS-CANCEL | form open | Cancel | unchanged | row | N/A |
| S-SS-DEL | Manual row | Delete -> confirm | removed; audit Soft Delete | receipt; row gone | N/A |
| S-SS-DEL-CM | CodeMetro row | look | no Delete button | `btnStuSsRowDelete.Visible = false` | N/A |
| S-SS-DELCANCEL | confirm open | Keep | unchanged | row | N/A |

## Directional Mutation Evidence

State pairs (no amount). Each direction is proved by a literal guard on the canonical pre-state and the toggle's
explicit target state; amount = N/A.

| Pair | Selected-record expression | Operation-state reset binding | Invalid-submit gate | Receive/increase mutation | Issue/decrease mutation | Canonical-source observer | Receipt bindings |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Funder Reactivate/Deactivate | `varFunSelId` (Blank on OnVisible/Cancel, set by `btnFunRowEdit`) | `btnFunFormResetEngine.OnSelect: =...; Reset(tglFunActive)` (Default = saved IsActive) on Edit/after save | `btnFunSave.DisplayMode: =If(varFunSaving \|\| lblFunValidation.Text <> "Ready to save.", DisplayMode.Disabled, DisplayMode.Edit)` | `btnFunSave.OnSelect` Patch `Active: act` with op `If(!old.IsActive && act, "Reactivated", ...)` | same Patch with op `old.IsActive && !act, "Deactivated"` | `lblFunRowName.Text` reads `ThisItem.IsActive` from colFunders | operation=op segment<br>old=If(old.IsActive,"Yes","No")<br>amount=N/A<br>expected=If(act,"Yes","No")<br>actual=If(varFunLastRec.Active,"Yes","No") |
| Service Reactivate/Deactivate | `varSvcSelId` | `Reset(tglSvcActive)` in `btnSvcFormResetEngine` | `btnSvcSave.DisplayMode` same shape with `lblSvcValidation` | `btnSvcSave.OnSelect` op `!old.IsActive && act` | op `old.IsActive && !act` | `lblSvcRowMeta` reads IsActive | same five segments from `varSvcLastRec.Active` |
| Student service Include/Exclude | `varStuSsEditId` (Blank on Open/Cancel/save) | `Reset(tglStuSsExcluded)` in `btnStuSsResetEngine` | `btnStuSsSave.DisplayMode` with `lblStuSsValidation` | op `old.IsExcluded && !ex` -> "Included" | op `!old.IsExcluded && ex` -> "Excluded" | `badStuSsExcluded.Visible: =ThisItem.IsExcluded` | old/expected/actual from `old.IsExcluded`, `ex`, `varStuLastSs.Excluded` |

## Compound Sequence Evidence

| Pair | Same-record ID expression | Sequence (start -> op1 amount -> mid -> op2 amount -> end) | Second-op old-value binding (reads mutated canonical source) |
| --- | --- | --- | --- |
| Funder Deactivate/Reactivate | `varFunSelId` | Active Yes -> Deactivate -> No -> Reactivate -> Yes | `btnFunSave.OnSelect: =With({..., old: LookUp(colFunders, FunderId = varFunSelId), ...}` after `Select(btnFunLoadEngine)` reloaded colFunders |
| Service Deactivate/Reactivate | `varSvcSelId` | Yes -> No -> Yes | `btnSvcSave.OnSelect: =With({..., old: LookUp(colServices, ServiceId = varSvcSelId), ...}` |
| SS Exclude/Include | `varStuSsEditId` (re-opened by Edit on the same row) | No -> Exclude -> Yes -> Include -> No | `btnStuSsSave.OnSelect: =With({..., old: LookUp(colStuSvc, SsId = varStuSsEditId), ...}` |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| `txtFunSearch` | `lblFunSearch` "Search abbreviation, name or alias" | `conFunListPanel` |
| `txtFunAbbr`, `txtFunFull`, `rdoFunType`, `txtFunQbo` | `lblFunAbbr` "Abbreviation (required)", `lblFunFull` "Full name", `lblFunType` "Funder type (required)", `lblFunQbo` "QuickBooks customer" | `conFunForm` |
| `txtFunAliasNew` | `lblFunAliasNew` "CodeMetro name" | `conFunAliasAddRow` |
| `txtSvcCode`, `txtSvcName`, `rdoSvcKind`, `rdoSvcUnit`, `txtSvcQbo`, `txtSvcSort` | `lblSvcCode` "Service code (required)", `lblSvcName` "Name (required)", `lblSvcKind` "Kind", `lblSvcUnit` "Billing unit", `lblSvcQbo` "QuickBooks item", `lblSvcSort` "Sort order" | `conSvcForm` |
| `txtSvcCptNew` / `txtSvcSnmNew` | `lblSvcCptNew` "CPT code" / `lblSvcSnmNew` "Service name" | `conSvcCptAddRow` / `conSvcSnmAddRow` |
| `txtStuSearch` | `lblStuSearch` "Search name or student key" | `conStuListPanel` |
| `ddStuDorFunder`, `txtStuDorNote` (+ date pickers) | `lblStuDorFunder` "District (required)", `lblStuDorNote` "Note", `lblStuDorStart`, `lblStuDorEnd` | `conStuDorForm` |
| `ddStuSsService`, `ddStuSsFunder`, `txtStuSsFreq`, `txtStuSsMin`, `txtStuSsNote` (+ date pickers) | `lblStuSsService` "Service (required)", `lblStuSsFunder` "Funder (required)", `lblStuSsFreq` "Frequency", `lblStuSsMin` "Minutes per frequency", `lblStuSsNote` "Note", `lblStuSsStart`, `lblStuSsEnd` | `conStuSsForm` |

## Layout Budget Contracts

Narrowest supported width 1024 (two-panel: list and right column each (1024 - 32 - 12) / 2 = 490, inner 458); stacked
below 1024 (full width; 640 -> inner 576; 390 -> 326).

| Screen / container | Branch / screen-width source | Horizontal total-width arithmetic | Vertical height arithmetic | Protected controls |
| --- | --- | --- | --- | --- |
| all / `con<P>Nav` | root width | 4 x 110 + 3 x 8 = 464 <= 608 (640 inner) | 44 | nav buttons |
| all / `con<P>Header` | root width | N/A | 24 + 28 + 4 + 20 + (4 + 44) = 124 finance; phone identity 36 -> 140 | title, nav |
| Home / `conHomeCards` (wrap, card 232) | root width | cols = Max(1, RoundDown((W - 32 + 12) / 244, 0)); 1024 -> 4 cols (4 x 232 + 36 = 964 <= 992) | rows x 196 + (rows - 1) x 12 | four Review buttons |
| Funders / `conFunChips` (wrap) | list panel inner width w | 64 + 96 + 150 + 120 + 240 + 32 = 702 | If(w >= 702, 44, w >= 454, 96, 148) | chips |
| Funders / `conFunAliasAddRow` | panel inner 458 | 120 + 8 + input + 8 + 110 -> input 212 (>= 120 at 368) | 44 | Add alias |
| Services / `conSvcChips` | inner w | 64 + 110 + 90 + 210 + 24 = 498 | If(w >= 498, 44, w >= 280, 96, 148) | chips |
| Students / `conStuChips` | inner w | 64 + 84 + 180 + 190 + 24 = 542 | If(w >= 542, 44, w >= 344, 96, 148) | chips |
| Students / `conStuStatusRow` (wrap) | inner w | 52 + 80 + 120 + 120 + 24 = 396 | If(w >= 396, 44, 96) | Clear filters |
| all forms (vertical) | panel width | Stretch | per brief: sum of 18/36 pairs + gaps 6 + padding 32 | Save, Cancel |
| all gallery rows | template width | identity label FillPortions 1 + fixed buttons (Edit 72, Delete 80, badge 84) | per brief TemplateSize budget | row actions |

## Viewport Containment Contracts

| Screen | Root control | Layout variant | Width binding | Height binding | Overflow policy |
| --- | --- | --- | --- | --- | --- |
| HomeScreen | `conHomeRoot` | AutoLayout | `conHomeRoot.Width: =Parent.Width` | `conHomeRoot.Height: =Parent.Height` | vertical scroll |
| FundersScreen | `conFunRoot` | AutoLayout | `=Parent.Width` | `=Parent.Height` | vertical scroll |
| ServicesScreen | `conSvcRoot` | AutoLayout | `=Parent.Width` | `=Parent.Height` | vertical scroll |
| StudentsScreen | `conStuRoot` | AutoLayout | `=Parent.Width` | `=Parent.Height` | vertical scroll |

## Working Directory

Plans: `C:\src\aaca-attendance\docs\app-builds\build-6-billing-foundations`
App source (screen targets): `C:\src\aaca-attendance\billing-app`

## Discovery Summary

- Controls: GroupContainer (AutoLayout), ModernText, ModernButton, Classic/Button (hidden engines), Gallery
  (Vertical), ModernTextInput, ModernRadio, ModernToggle, ModernCheckbox, ModernDropdown, ModernDatePicker, Badge.
  Not used: ModernTabList (cross-screen nav uses buttons), ModernSpinner, ModernIcon, ModernCard (not described).
- Data sources (Dataverse): Funders, Funder Aliases, Services, Service Aliases, Districts of Record, Student
  Services, Students, Staff, Users, Audit Events. (Campuses, Enrollments present but unused.)
- Verified Power Fx: named formulas under App.Properties.Formulas; UDFs compile; Yes/No columns are Booleans;
  lookup traversal `.Funder.Abbreviation`, `.Service.'Service Code'`.
- Connectors: none.

## Dispatch

| Action | Screen | Target File | YAML Key | Name Prefix | Screen Brief |
| --- | --- | --- | --- | --- | --- |
| Create | Home | `C:\src\aaca-attendance\billing-app\HomeScreen.pa.yaml` | HomeScreen | Home | `C:\src\aaca-attendance\docs\app-builds\build-6-billing-foundations\HomeScreen.screen-plan.md` |
| Create | Funders | `C:\src\aaca-attendance\billing-app\FundersScreen.pa.yaml` | FundersScreen | Fun | `C:\src\aaca-attendance\docs\app-builds\build-6-billing-foundations\FundersScreen.screen-plan.md` |
| Create | Services | `C:\src\aaca-attendance\billing-app\ServicesScreen.pa.yaml` | ServicesScreen | Svc | `C:\src\aaca-attendance\docs\app-builds\build-6-billing-foundations\ServicesScreen.screen-plan.md` |
| Create | Student billing setup | `C:\src\aaca-attendance\billing-app\StudentsScreen.pa.yaml` | StudentsScreen | Stu | `C:\src\aaca-attendance\docs\app-builds\build-6-billing-foundations\StudentsScreen.screen-plan.md` |

Every screen's header nav references all four screen names, so per-screen compiles report
`Name isn't recognized: <OtherScreen>` until all four files exist. Compile the app as a whole after the last builder.
Estimated control counts: Home ~40, Funders ~95, Services ~110, Students ~125 (largest; see its brief).

## App Changes

### Before builders

Done by the planner: `C:\src\aaca-attendance\billing-app\App.pa.yaml` (Formulas: identity/gate, ZeroGuid,
FarFuture, NormAlias UDF, palette; OnStart: typed seeds for every global in the shared plan; Theme). The user must add
Users, Audit Events (and Enrollments) to the app before the first compile. No `StartScreen` is set yet so App compiles
while only Screen1 exists.

### After builders

1. Delete `C:\src\aaca-attendance\billing-app\Screen1.pa.yaml`.
2. Add `StartScreen: =HomeScreen` under `App: Properties:` in App.pa.yaml.
3. Apply the Editor State change below. Then compile the whole app.

## Editor State Changes

`_EditorState.pa.yaml` final content (orchestrator applies after builders; the planner does not edit it):

```yaml
EditorState:
  ScreensOrder:
    - HomeScreen
    - FundersScreen
    - ServicesScreen
    - StudentsScreen
  ComponentDefinitionsOrder: []
```

(If the server rejects an empty `ComponentDefinitionsOrder`, omit that key.)
