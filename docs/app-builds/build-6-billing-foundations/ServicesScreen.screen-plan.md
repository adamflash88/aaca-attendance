# Screen Plan: Services

## Assignment

- Action: Create
- Target file: `C:\src\aaca-attendance\billing-app\ServicesScreen.pa.yaml`
- YAML key: ServicesScreen
- Control name prefix: Svc
- Read with: `canvas-app-shared.md` (palette, visual contract, header/gate/engine/receipt/mutation/audit patterns,
  collection formulas, YAML rules).

## Specification

- Purpose: maintain services (QuickBooks item, billing unit, billable flags, sort order, active) and their CodeMetro
  aliases in two groups (CPT codes, service names). No delete of services. SPED code/kind read-only. No rates/dollars.
- Screen properties: `Fill: =ColorPaper`; `OnVisible` (|- block):
  `=Set(varSvcSelId, Blank()); Set(varSvcMode, ""); Set(varSvcAliasDelId, Blank()); Set(varSvcReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Set(varSvcAliasReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Reset(tglSvcInactive); Select(btnSvcLoadEngine)`
  (varSvcKind / varSvcMissingQbo / varSvcShowInactive are not reset — Home sets them).
- Layout. Screen `Children:` = only `conSvcRoot`. Root children in order:
  1. `conSvcHeader` (shared; `btnSvcNavServices` current).
  2. `conSvcGate` (shared; `lblSvcGateTitle`, `lblSvcGateBody`).
  3. `conSvcBody` — shared list+detail body, `Visible: =IsFinance`, `FillPortions: =0`,
     `Height: =If(conSvcRoot.Width >= 1024, Max(conSvcListPanel.Height, conSvcRight.Height), If(varSvcMode = "", conSvcListPanel.Height, conSvcRight.Height))`.
     a. `conSvcListPanel` — white panel, Vertical, Stretch, padding 16, gap 8, FillPortions/AlignInContainer as shared
        two-panel rule, `Visible: =!(conSvcRoot.Width < 1024 && varSvcMode <> "")`, `Height: =668 + conSvcChips.Height`:
        - `conSvcListHead` H44: `lblSvcListTitle` "Services" (18 Bold, FillPortions 1); `btnSvcReload` Secondary
          "Reload" W88 (`Select(btnSvcLoadEngine)`); `btnSvcNew` Primary "New service" W120.
        - `conSvcChips` Horizontal, `LayoutWrap: =true`, gap 8,
          `Height: =If(conSvcListPanel.Width - 32 >= 498, 44, conSvcListPanel.Width - 32 >= 280, 96, 148)`:
          `btnSvcChipAll` "All" W64 (`varSvcKind = "All"`); `btnSvcChipSchool` "School Day" W110 (`"School Day"`);
          `btnSvcChipClinical` "Clinical" W90 (`"Clinical"`); `btnSvcChipMissing` "Missing QuickBooks item" W210
          (active `varSvcMissingQbo`; `OnSelect: =With({next: !varSvcMissingQbo}, Set(varSvcMissingQbo, next))`).
        - `conSvcFilterRow` H44: `tglSvcInactive` (Label "Show inactive", W160, `Default: =varSvcShowInactive`,
          OnCheck/OnUncheck set varSvcShowInactive true/false); `btnSvcClear` Secondary "Clear filters" W120:
          `=Set(varSvcKind, "All"); Set(varSvcMissingQbo, false); Set(varSvcShowInactive, false); Reset(tglSvcInactive)`.
        - `lblSvcCount` (12, H36, wraps): `With({n: CountRows(<Items Filter>), m: CountRows(Filter(colServices, varSvcShowInactive || IsActive))}, If(varSvcLoading, "Loading services...", varSvcLoadError <> "", "Could not load services - " & varSvcLoadError, n = 0, "No services match these filters. Use Clear filters to see all.", "Showing " & n & " of " & m & " services"))`.
        - `galSvcList` Height 480 (contract below).
     b. `conSvcRight` — Vertical, gap 12, `Visible: =varSvcMode <> "" || conSvcRoot.Width >= 1024`,
        `Height: =If(varSvcMode = "", If(conSvcRoot.Width >= 1024, 72, 0), conSvcForm.Height + If(varSvcMode = "edit", 12 + conSvcAliasPanel.Height, 0))`:
        - `conSvcPlaceholder` (H72, `Visible: =varSvcMode = ""`): `lblSvcPlaceholder` "Select Edit on a service, or New service to add one."
        - `conSvcForm` white panel, Vertical, Stretch, padding 16, gap 6, `Visible: =varSvcMode <> ""`,
          `Height: =756 + If(varSvcReceipt.Kind <> "", 6 + 16 + Max(44, 18 * RoundUp(Len(varSvcReceipt.Msg) / 45, 0) + 8), 0)`.
          Children in order: `conSvcReceipt` (shared strip: `lblSvcReceipt`, `btnSvcReceiptDismiss`);
          `conSvcFormHead` H44: `lblSvcFormTitle` (`=If(varSvcMode = "new", "New service", "Edit service " & LookUp(colServices, ServiceId = varSvcSelId).Code)`),
          `btnSvcBack` "Back to list" W120 (`Visible: =conSvcRoot.Width < 1024`, OnSelect = Cancel);
          `lblSvcCode` "Service code (required)" / `txtSvcCode` (Default `LookUp(colServices, ServiceId = varSvcSelId).Code`,
          `DisplayMode: =If(<isSpedSel>, DisplayMode.View, DisplayMode.Edit)`, MaxLength 100);
          `lblSvcName` "Name (required)" / `txtSvcName` (Default `.Name`);
          `lblSvcKind` "Kind" / `rdoSvcKind` (Horizontal, `Items: =["School Day", "Clinical"]`,
          Default |- `={Value: Coalesce(LookUp(colServices, ServiceId = varSvcSelId).KindText, "School Day")}`,
          `DisplayMode: =If(<isSpedSel>, DisplayMode.View, DisplayMode.Edit)`);
          `lblSvcUnit` "Billing unit" / `rdoSvcUnit` (`Items: =["Days", "Hours"]`, Default |-
          `={Value: Coalesce(LookUp(colServices, ServiceId = varSvcSelId).UnitText, "Days")}`);
          `lblSvcQbo` "QuickBooks item" / `txtSvcQbo` (Default `.QboItem`, Placeholder "Exact item name in QuickBooks Online");
          `lblSvcSort` "Sort order" / `txtSvcSort` (Default `=With({v: LookUp(colServices, ServiceId = varSvcSelId).SortNum}, If(IsBlank(v), "", Text(v)))`, Placeholder "e.g. 10");
          `tglSvcBillable` (Label "Billable", W160, H44, `Default: =If(IsBlank(varSvcSelId), true, LookUp(colServices, ServiceId = varSvcSelId).IsBillable)`);
          `tglSvcNonSchool` (Label "Billable on non-school days", W260, `Default: =If(IsBlank(varSvcSelId), false, LookUp(...).NonSchool)`);
          `tglSvcActive` (Label "Active", W160, `Default: =If(IsBlank(varSvcSelId), true, LookUp(...).IsActive)`);
          `lblSvcHelp` (12 muted, H36, wraps) |- `=If(<isSpedSel>, "SPED is the attendance service: its code and kind are fixed.", "Service codes must be unique (upper or lower case does not matter).")`;
          `lblSvcValidation` (13, H36, wraps; formula below; Color teal when "Ready to save." else ColorUnexcused);
          `conSvcActions` H44: `btnSvcSave` Primary "Save" W100; `btnSvcCancel` Secondary "Cancel" W100.
          `<isSpedSel>` = `!IsBlank(varSvcSelId) && Upper(LookUp(colServices, ServiceId = varSvcSelId).Code) = "SPED"`.
        - `conSvcAliasPanel` white panel, Vertical, Stretch, padding 16, gap 6, `Visible: =varSvcMode = "edit"`,
          `Height: =710 + If(varSvcAliasReceipt.Kind <> "", 6 + 16 + Max(44, 18 * RoundUp(Len(varSvcAliasReceipt.Msg) / 45, 0) + 8), 0) + If(!IsBlank(varSvcAliasDelId), 62, 0)`.
          Children in order: `conSvcAliasReceipt` (strip: `lblSvcAliasReceipt`, `btnSvcAliasReceiptDismiss`);
          `lblSvcAliasTitle` "CodeMetro codes and names (aliases)" (14 Semibold, H20);
          `lblSvcAliasCaption` "Aliases are the CPT codes and service names CodeMetro writes. Each one maps to exactly one service." (12 muted, H36);
          `conSvcAliasConfirm` (H56, ColorWarnBg, `Visible: =!IsBlank(varSvcAliasDelId)`): `lblSvcAliasConfirm`
          `=With({a: LookUp(colServiceAliases, AliasId = varSvcAliasDelId)}, "Remove " & Lower(a.AliasTypeText) & " " & a.AliasText & " from " & LookUp(colServices, ServiceId = varSvcSelId).Code & "?")`,
          `btnSvcAliasConfirmYes` destructive "Remove" W96, `btnSvcAliasConfirmNo` Secondary "Keep" W80 (`Set(varSvcAliasDelId, Blank())`);
          then group CPT, then group Snm (structure below).
  4. `btnSvcLoadEngine` hidden: non-finance `Clear(colServices); Clear(colServiceAliases)`; success
     `Refresh(Services); Refresh('Service Aliases'); Concurrent(<colServices verbatim>, <colServiceAliases verbatim>); true`.
  5. `btnSvcFormResetEngine` hidden: `=Reset(txtSvcCode); Reset(txtSvcName); Reset(rdoSvcKind); Reset(rdoSvcUnit); Reset(txtSvcQbo); Reset(txtSvcSort); Reset(tglSvcBillable); Reset(tglSvcNonSchool); Reset(tglSvcActive); Reset(txtSvcCptNew); Reset(txtSvcSnmNew)`.

- Alias groups (G / type text T / choice literal / labels):
  - G = `Cpt`, T = "CPT Code", choice `'Alias Type (Service Aliases)'.'CPT Code'`, title "CPT codes", field label "CPT code", noun "CPT code".
  - G = `Snm`, T = "Service Name", choice `'Alias Type (Service Aliases)'.'Service Name'`, title "Service names", field label "Service name", noun "service name".
  Each group, as direct children of `conSvcAliasPanel`:
  - `lblSvc<G>Title` (14 Semibold, H20): `="<title> (" & CountRows(Filter(colServiceAliases, ServiceId = varSvcSelId && AliasTypeText = "<T>")) & ")"`.
  - `conSvc<G>AddRow` Horizontal H44 gap 8 Center: `lblSvc<G>New` "<field label>" (W110, H36, Wrap false),
    `txtSvc<G>New` (FillPortions 1, H36, Outline, Keypress), `btnSvc<G>Add` Primary "Add" W88.
  - `conSvc<G>Notice` Horizontal H44, padding 4/8, radius 6: `lblSvc<G>Notice` (13, FillPortions 1, H40, wraps),
    `btnSvc<G>Move` Primary "Move it here" W120. All four bindings derive from
    `With({n: NormAlias(txtSvc<G>New.Text)}, With({hit: LookUp(colServiceAliases, AliasText = n && AliasTypeText = "<T>")}, ...))`:
    notice `If(n = "", "Type a <noun>, then select Add.", IsBlank(hit), "Will be saved as " & n, hit.ServiceId = varSvcSelId, "Already mapped to this service.", "Already mapped to " & LookUp(colServices, ServiceId = hit.ServiceId).Code & ". Select Move it here to map it to this service instead.")`;
    row Fill `If(n = "" || IsBlank(hit), ColorWhite, ColorWarnBg)`; Move Visible `!IsBlank(hit) && hit.ServiceId <> varSvcSelId`;
    Add DisplayMode `If(varSvcSaving || n = "" || !IsBlank(hit), DisplayMode.Disabled, DisplayMode.Edit)`.
  - `galSvc<G>` Vertical, Height 176, TemplateSize 52, Items `=Sort(Filter(colServiceAliases, ServiceId = varSvcSelId && AliasTypeText = "<T>"), AliasText)`;
    shell `conSvc<G>Row` (Horizontal, padding 4/8, gap 8, Center, border rule): `lblSvc<G>RowText` (13, FillPortions 1, H40, wraps,
    `=ThisItem.AliasText`), `btnSvc<G>RowRemove` Secondary "Remove" W88 (`Set(varSvcAliasDelId, ThisItem.AliasId)`).

- Gallery contract `galSvcList`: Vertical, Height 480, TemplateSize 120, TemplatePadding 0, TabIndex 0, Selectable false.
  Items (|- block):

```
=Sort(
    Filter(
        colServices,
        (varSvcShowInactive || IsActive) &&
        (varSvcKind = "All" || KindText = varSvcKind) &&
        (!varSvcMissingQbo || Trim(QboItem) = "")
    ),
    KindRank * 100000 + Coalesce(SortNum, 9999),
    SortOrder.Ascending
)
```

  Row shell `conSvcRow` (Vertical, padding 8, gap 2, border rule, `Fill: =If(ThisItem.ServiceId = varSvcSelId, ColorInfoBg, ColorWhite)`):
  - `conSvcRowTop` H44: `lblSvcRowCode` (14 Semibold, FillPortions 1, H40, wraps, `=ThisItem.Code & " - " & ThisItem.Name`);
    `btnSvcRowEdit` Secondary "Edit" W72 (Select pattern below).
  - `lblSvcRowMeta` (12 ink, H36, wraps):
    `=ThisItem.KindText & " · " & ThisItem.UnitText & If(ThisItem.NonSchool, " · Non-school days", "") & If(ThisItem.IsBillable, "", " · Not billable") & If(ThisItem.IsActive, "", " · Inactive") & If(IsBlank(ThisItem.SortNum), "", " · Sort " & ThisItem.SortNum)`
  - `lblSvcRowQbo` (12, H20, Wrap false; warning style when blank): `=If(Trim(ThisItem.QboItem) = "", "No QuickBooks item", "QuickBooks item " & ThisItem.QboItem)`.
  Row budget 8 + 44 + 2 + 36 + 2 + 20 + 8 = 120.

- `lblSvcValidation.Text` (|- block):

```
=With(
    {inCode: Trim(txtSvcCode.Text), inName: Trim(txtSvcName.Text), inSort: Trim(txtSvcSort.Text)},
    With(
        {dup: LookUp(colServices, Lower(Code) = Lower(inCode) && ServiceId <> Coalesce(varSvcSelId, ZeroGuid))},
        If(
            inCode = "", "Service code is required.",
            !IsBlank(dup), "Service code " & inCode & " is already used by " & dup.Name & ".",
            inName = "", "Name is required.",
            inSort <> "" && (!IsNumeric(inSort) || Value(inSort) <> RoundDown(Value(inSort), 0)), "Sort order must be a whole number.",
            IsBlank(rdoSvcKind.Selected) || IsBlank(rdoSvcUnit.Selected), "Choose a kind and a billing unit.",
            "Ready to save."
        )
    )
)
```

- Breakpoints/budgets: list panel 32 + 44 + chips + 44 + 36 + 480 + 4 gaps x 8 = 668 + chips (chips 96 at inner 458:
  row 1 64+110+90+16 = 280, row 2 210). Form: 44 + 6 x 54 + 3 x 44 + 36 + 36 + 44 = 616; 18 gaps x 6 = 108;
  padding 32 -> 756 (+ receipt). Alias panel: 20 + 36 + 2 x (20 + 44 + 44 + 176) = 624; 9 gaps x 6 = 54; padding 32
  -> 710 (+ receipt + 62 confirm). Add row at inner 458: 110 + 8 + 244 + 8 + 88. Toggle "Billable on non-school days"
  label ~200 px + switch 40 in W260.
- Text fit: chip "Missing QuickBooks item" (23 chars ~180 px) in W210; row code line wraps 2 lines at 14.
- Visual hierarchy: as Funders.

### Select / New / Cancel

- `btnSvcRowEdit.OnSelect` (|-): `=Set(varSvcSelId, ThisItem.ServiceId); Set(varSvcMode, "edit"); Set(varSvcAliasDelId, Blank()); Set(varSvcReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Set(varSvcAliasReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Select(btnSvcFormResetEngine)`.
- `btnSvcNew.OnSelect`: same with `Set(varSvcSelId, Blank()); Set(varSvcMode, "new")`.
- `btnSvcCancel.OnSelect` / `btnSvcBack.OnSelect`: `=Set(varSvcSelId, Blank()); Set(varSvcMode, ""); Set(varSvcAliasDelId, Blank())`.

### `btnSvcSave.OnSelect` (|- block) — shared skeleton

`DisplayMode: =If(varSvcSaving || lblSvcValidation.Text <> "Ready to save.", DisplayMode.Disabled, DisplayMode.Edit)`.

```
=If(
    lblSvcValidation.Text = "Ready to save." && !varSvcSaving && IsFinance,
    Set(varSvcSaving, true);
    Set(varSvcErr, "");
    With(
        {
            id: varSvcSelId,
            idx: Coalesce(varSvcSelId, ZeroGuid),
            old: LookUp(colServices, ServiceId = varSvcSelId),
            inCode: Trim(txtSvcCode.Text),
            inName: Trim(txtSvcName.Text),
            inKind: rdoSvcKind.Selected.Value,
            inUnit: rdoSvcUnit.Selected.Value,
            inQbo: Trim(txtSvcQbo.Text),
            inSort: Trim(txtSvcSort.Text),
            bil: tglSvcBillable.Checked,
            ns: tglSvcNonSchool.Checked,
            act: tglSvcActive.Checked
        },
        With(
            {
                isSped: !IsBlank(id) && Upper(old.Code) = "SPED",
                dup: LookUp(Services, 'Service Code' = inCode && Service <> idx),
                kindOpt: Switch(inKind, "School Day", 'Kind (Services)'.'School Day', "Clinical", 'Kind (Services)'.Clinical),
                unitOpt: Switch(inUnit, "Days", 'Billing Unit (Services)'.Days, "Hours", 'Billing Unit (Services)'.Hours),
                sortVal: If(inSort = "", Blank(), Value(inSort)),
                op: If(IsBlank(id), "New service", !old.IsActive && act, "Reactivated", old.IsActive && !act, "Deactivated", "No status change")
            },
            If(
                !IsBlank(dup),
                Set(varSvcReceipt, {Kind: "Blocked", Msg: "Not saved. Service code " & inCode & " is already used by " & dup.Name & ".", RecordId: idx}),
                IfError(
                    Set(varSvcLastRec, If(
                        IsBlank(id),
                        Patch(Services, Defaults(Services), {'Service Code': inCode, Name: inName, Kind: kindOpt, 'Billing Unit': unitOpt, 'QuickBooks Item': inQbo, 'Sort Order': sortVal, Billable: bil, 'Billable on Non-School Days': ns, Active: act}),
                        isSped,
                        Patch(Services, LookUp(Services, Service = idx), {Name: inName, 'Billing Unit': unitOpt, 'QuickBooks Item': inQbo, 'Sort Order': sortVal, Billable: bil, 'Billable on Non-School Days': ns, Active: act}),
                        Patch(Services, LookUp(Services, Service = idx), {'Service Code': inCode, Name: inName, Kind: kindOpt, 'Billing Unit': unitOpt, 'QuickBooks Item': inQbo, 'Sort Order': sortVal, Billable: bil, 'Billable on Non-School Days': ns, Active: act})
                    ));
                    true,
                    Set(varSvcErr, FirstError.Message);
                    false
                );
                If(
                    varSvcErr <> "",
                    Set(varSvcReceipt, {Kind: "Failed", Msg: "Service not saved. " & varSvcErr, RecordId: idx}),
                    IfError(
                        Patch('Audit Events', Defaults('Audit Events'), {Summary: Left(If(IsBlank(id), "Create", "Update") & " Services " & varSvcLastRec.'Service Code', 100), Action: If(IsBlank(id), 'Action (Audit Events)'.Create, 'Action (Audit Events)'.Update), Entity: "Services", 'Entity ID': Text(varSvcLastRec.Service), Before: If(IsBlank(id), "", JSON({ServiceCode: old.Code, Name: old.Name, Kind: old.KindText, BillingUnit: old.UnitText, QuickBooksItem: old.QboItem, SortNumber: old.SortNum, Billable: old.IsBillable, NonSchoolDays: old.NonSchool, Active: old.IsActive})), After: JSON({ServiceCode: varSvcLastRec.'Service Code', Name: inName, Kind: Text(varSvcLastRec.Kind), BillingUnit: inUnit, QuickBooksItem: inQbo, SortNumber: sortVal, Billable: bil, NonSchoolDays: ns, Active: act}), Reason: "Service saved in AACA Billing"});
                        Set(varSvcAuditOk, true),
                        Set(varSvcAuditOk, false)
                    );
                    Set(varSvcReceipt, {Kind: If(IsBlank(id), "Created", "Updated"), Msg: If(IsBlank(id), "Created", "Updated") & " service " & varSvcLastRec.'Service Code' & If(isSped, " (code and kind are fixed for SPED)", "") & ". Code " & varSvcLastRec.'Service Code' & " | Name " & varSvcLastRec.Name & " | Kind " & Text(varSvcLastRec.Kind) & " | Billing unit " & Text(varSvcLastRec.'Billing Unit') & " | QuickBooks item " & Coalesce(varSvcLastRec.'QuickBooks Item', "none") & " | Sort order " & If(IsBlank(varSvcLastRec.'Sort Order'), "none", Text(varSvcLastRec.'Sort Order')) & " | Billable " & If(varSvcLastRec.Billable, "Yes", "No") & " | Non-school days " & If(varSvcLastRec.'Billable on Non-School Days', "Yes", "No") & " | Active " & If(IsBlank(id), "", If(old.IsActive, "Yes", "No") & " -> ") & If(varSvcLastRec.Active, "Yes", "No") & " (" & op & ") | Audit " & If(varSvcAuditOk, "written", "FAILED - tell Adam"), RecordId: varSvcLastRec.Service});
                    Set(varSvcSelId, varSvcLastRec.Service);
                    Set(varSvcMode, "edit");
                    Select(btnSvcLoadEngine);
                    Select(btnSvcFormResetEngine)
                )
            )
        )
    );
    Set(varSvcSaving, false)
)
```

### Alias add / move / remove (per group G; same skeleton as Funders)

- `btnSvc<G>Add.OnSelect`: `With({n: NormAlias(txtSvc<G>New.Text), sid: varSvcSelId}, With({hit: LookUp('Service Aliases', Alias = n && 'Alias Type' = <choice>)}, If(!IsBlank(hit), Set(varSvcAliasReceipt, {Kind: "Blocked", Msg: "Not added. " & n & " is already mapped to " & hit.Service.'Service Code' & ".", RecordId: hit.'Service Alias'}), n <> "" && !IsBlank(sid) && !varSvcSaving && IsFinance, <skeleton>)))`.
  Mutation `Set(varSvcLastAlias, Patch('Service Aliases', Defaults('Service Aliases'), {Alias: n, 'Alias Type': <choice>, Service: LookUp(Services, Service = sid)}))`.
  Audit Create, Entity "Service Aliases", 'Entity ID' `Text(varSvcLastAlias.'Service Alias')`, After
  `JSON({Alias: n, AliasType: "<T>", Service: LookUp(colServices, ServiceId = sid).Code})`, Reason "Service alias added in AACA Billing".
  Receipt Kind "Added", Msg `"Added <noun> " & n & " to " & LookUp(colServices, ServiceId = sid).Code & ". | Audit " & ...`.
  Success: `Reset(txtSvc<G>New); Select(btnSvcLoadEngine)`.
- `btnSvc<G>Move.OnSelect`: `hit: LookUp(colServiceAliases, AliasText = n && AliasTypeText = "<T>" && ServiceId <> sid)`, `hid: hit.AliasId`,
  `fromCode`, `toCode` from colServices; mutation `Patch('Service Aliases', LookUp('Service Aliases', 'Service Alias' = hid), {Service: LookUp(Services, Service = sid)})`;
  audit Update Before `JSON({Alias: n, AliasType: "<T>", Service: fromCode})` After `JSON({Alias: n, AliasType: "<T>", Service: toCode})`;
  receipt Kind "Moved", Msg `"Moved <noun> " & n & " from " & fromCode & " to " & toCode & ". | Audit " & ...`.
- `btnSvcAliasConfirmYes.OnSelect`: `snap: LookUp(colServiceAliases, AliasId = varSvcAliasDelId)`, `hid: snap.AliasId`,
  `sCode: LookUp(colServices, ServiceId = snap.ServiceId).Code`; `Remove('Service Aliases', LookUp('Service Aliases', 'Service Alias' = hid))`;
  audit `'Soft Delete'`, Before `JSON({Alias: snap.AliasText, AliasType: snap.AliasTypeText, Service: sCode})`, After "",
  Reason "Service alias removed (row deleted)"; receipt Kind "Removed", Msg `"Removed " & Lower(snap.AliasTypeText) & " " & snap.AliasText & " from " & sCode & ". | Audit " & ...`;
  success `Set(varSvcAliasDelId, Blank()); Select(btnSvcLoadEngine)`.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| RF-SVC-CODE | list row | code + name | Code, Name | `lblSvcRowCode` | `=ThisItem.Code & " - " & ThisItem.Name` | top line, 2 lines |
| RF-SVC-KIND | list row | kind, unit, flags | KindText, UnitText, NonSchool, IsBillable, IsActive | `lblSvcRowMeta` | see gallery contract | second line |
| RF-SVC-QBO | list row | QBO item or warning | QboItem | `lblSvcRowQbo` | see gallery contract | third line |
| RF-SVC-ALIASTEXT | CPT / name rows | alias | AliasText | `lblSvcCptRowText`, `lblSvcSnmRowText` | `=ThisItem.AliasText` | wraps |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| SV-GATE | `conSvcGate` | `=!IsFinance` | non-finance / finance |
| SV-BODY | `conSvcBody`, `conSvcNav` | `=IsFinance` | finance / non-finance |
| SV-SVC-FORM | `conSvcForm` | `=varSvcMode <> ""` | open / closed |
| SV-SVC-ALIAS | `conSvcAliasPanel` | `=varSvcMode = "edit"` | saved service / otherwise |
| SV-SVC-CONFIRM | `conSvcAliasConfirm` | `=!IsBlank(varSvcAliasDelId)` | remove pending |
| SV-RECEIPTS | `conSvcReceipt`, `conSvcAliasReceipt` | `.Kind <> ""` | after mutation |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-SVC-LOAD | IsFinance | OnVisible, `btnSvcReload` | Services, Service Aliases | reload | N/A | N/A | `galSvcList`, `lblSvcCount` |
| A-SVC-KIND / MISSQBO / INACTIVE / CLEAR | loaded | chips, toggle, Clear | colServices + globals | Items predicate | N/A | N/A | chips, count |
| A-SVC-SELECT / NEW / CANCEL | as above | `btnSvcRowEdit`, `btnSvcNew`, `btnSvcCancel` | ServiceId | form state, prepopulated by ID | N/A | N/A | `conSvcForm` |
| A-SVC-CREATE / UPDATE / DEACT / REACT | valid | `btnSvcSave.OnSelect` | Services; returned `.Service` / varSvcSelId | create/update; op guards; audit | Service Code, Name, Kind, Billing Unit, QuickBooks Item, Sort Order, Billable, Billable on Non-School Days, Active | RecordId + all nine labeled values + op + audit | `lblSvcReceipt`; row highlight |
| A-SVC-SPED | selected code SPED | form | Services by varSvcSelId | code/kind View; SPED Patch branch omits them | as update minus Service Code, Kind | receipt Code SPED, Kind unchanged | `lblSvcHelp` |
| A-SVC-CPT-ADD / A-SVC-SNM-ADD | edit mode, Add enabled | `btnSvcCptAdd` / `btnSvcSnmAdd` | Service Aliases; returned `.'Service Alias'` | alias created with type | Alias, Alias Type, Service | alias, type noun, service code, audit | `lblSvcAliasReceipt`; group gallery |
| A-SVC-ALIAS-MOVE | clash same type | `btnSvcCptMove` / `btnSvcSnmMove` | clash AliasId | Service -> this service | Service | alias, from, to, audit | receipt; gallery |
| A-SVC-ALIAS-DEL / DELCANCEL | confirm open | row Remove -> `btnSvcAliasConfirmYes` / `btnSvcAliasConfirmNo` | snapshot | Remove / none | existence / N/A | alias, type, service, audit | receipt; gallery |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| `txtSvcCode` | `lblSvcCode` "Service code (required)" | `conSvcForm` |
| `txtSvcName` | `lblSvcName` "Name (required)" | `conSvcForm` |
| `rdoSvcKind` | `lblSvcKind` "Kind" | `conSvcForm` |
| `rdoSvcUnit` | `lblSvcUnit` "Billing unit" | `conSvcForm` |
| `txtSvcQbo` | `lblSvcQbo` "QuickBooks item" | `conSvcForm` |
| `txtSvcSort` | `lblSvcSort` "Sort order" | `conSvcForm` |
| `txtSvcCptNew` | `lblSvcCptNew` "CPT code" | `conSvcCptAddRow` |
| `txtSvcSnmNew` | `lblSvcSnmNew` "Service name" | `conSvcSnmAddRow` |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| service save | `varSvcLastRec` -> `lblSvcReceipt` | Services; `LookUp(colServices, ServiceId = varSvcSelId)` | `galSvcList`, form | `.Service` -> RecordId -> varSvcSelId | `Select(btnSvcLoadEngine)` | row highlight |
| alias add/move/remove | `varSvcLastAlias` / snapshot -> `lblSvcAliasReceipt` | Service Aliases; colServiceAliases | `galSvcCpt` / `galSvcSnm` | alias GUID | `Select(btnSvcLoadEngine)` | filtered by varSvcSelId + type |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| save | Service Code | Changed (Preserved for SPED) | `Trim(txtSvcCode.Text)` | `'Service Code'` (omitted in SPED branch) | "Code ..." | `lblSvcRowCode` |
| save | Name | Changed | `Trim(txtSvcName.Text)` | `Name` | "Name ..." | `lblSvcRowCode` |
| save | Kind | Changed (Preserved for SPED) | `rdoSvcKind.Selected.Value` | `Kind` | "Kind ..." | `lblSvcRowMeta` |
| save | Billing Unit | Changed | `rdoSvcUnit.Selected.Value` | `'Billing Unit'` | "Billing unit ..." | `lblSvcRowMeta` |
| save | QuickBooks Item | Changed | `Trim(txtSvcQbo.Text)` | `'QuickBooks Item'` | "QuickBooks item ..." | `lblSvcRowQbo` |
| save | Sort Order | Changed | `Trim(txtSvcSort.Text)` | `'Sort Order'` (Blank when empty) | "Sort order ..." | `lblSvcRowMeta`, list order |
| save | Billable | Changed | `tglSvcBillable.Checked` | `Billable` | "Billable ..." | "Not billable" tag |
| save | Billable on Non-School Days | Changed | `tglSvcNonSchool.Checked` | field | "Non-school days ..." | "Non-school days" tag |
| save / deact / react | Active | Changed | `tglSvcActive.Checked`; old from colServices | `Active` | "Active Yes -> No (Deactivated)" | "Inactive" tag |
| save | Billing Code (legacy) | Preserved | Services row | never written, never shown | N/A | N/A |
| alias add | Alias, Alias Type, Service | Changed | NormAlias(input), group, varSvcSelId | Patch Defaults | receipt | group gallery |
| alias move | Service (Alias, Alias Type Preserved) | Changed | clash row | Patch `Service` only | receipt | gallery |
| alias remove | existence | Changed | snapshot | Remove | receipt | absent |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-SVC-LOAD | services loaded | open | School Day rows first, then Clinical, each by sort order; rows show all fields | `galSvcList` | N/A |
| S-SVC-KIND / MISSQBO / INACTIVE / CLEAR | ZZSVC1, ZZSVC2 School Day; ZZSVC3 Clinical | chip / toggle / Clear | 2 matching shown, 1 hidden; Clear restores | list, `lblSvcCount` | N/A |
| S-HOME-SVCQBO | from Home | open | Missing chip on, count = Home | chips, count | N/A |
| S-SVC-CREATE | none | New: ZZSVC1, "ZZ Test Aide", School Day, Days, QBO blank, Billable on, Non-school off, Sort 90, Active; Save | created; audit Create | receipt nine labeled fields; row | N/A |
| S-SVC-CREATE-DUP | ZZSVC1 | New code "zzsvc1" | Save disabled | validation text | server Blocked receipt if stale |
| S-SVC-SORT-INVALID | form | sort "abc" or "2.5" | Save disabled | "Sort order must be a whole number." | blank allowed |
| S-SVC-UPDATE | ZZSVC1 | QBO item "ZZ Item"; Save | saved | receipt; `lblSvcRowQbo` | N/A |
| S-SVC-SPED | SPED exists | Edit SPED | code/kind read-only; save changes others only | `lblSvcHelp`; receipt "(code and kind are fixed for SPED)" | N/A |
| S-SVC-DEACT / REACT / COMPOUND | ZZSVC1 active | Active off Save, then on Save | false then true | receipts with op | old read from reloaded colServices |
| S-SVC-CANCEL | edits pending | Cancel | unchanged | row | N/A |
| S-SVC-CPT-ADD | ZZSVC1 edit | CPT "  zz97153 " Add | alias ZZ97153 CPT Code | receipt; `galSvcCpt` | blank -> Add disabled |
| S-SVC-SNM-ADD | ZZSVC1 edit | name "zz test   aide" Add | alias ZZ TEST AIDE Service Name | receipt; `galSvcSnm` | N/A |
| S-SVC-ALIAS-TYPES | ZZ97153 is CPT | add ZZ97153 as service name | allowed | `galSvcSnm` | N/A |
| S-SVC-ALIAS-SAME | ZZ97153 CPT on ZZSVC1 | retype in CPT group | Add disabled | "Already mapped to this service." | N/A |
| S-SVC-ALIAS-MOVE | ZZ97153 CPT on ZZSVC1; ZZSVC2 open | type it in CPT; Move it here | moved | receipt "Moved CPT code ZZ97153 from ZZSVC1 to ZZSVC2" | N/A |
| S-SVC-ALIAS-DEL / DELCANCEL | alias listed | Remove -> Remove / Keep | deleted / kept | receipt / list | N/A |

## Relevant Data Source Schemas

- Services: `Service` (GUID PK), `Name` (primary name), `'Service Code'` (unique), `Kind` `'Kind (Services)'` =
  'School Day' | Clinical, `'Billing Unit'` `'Billing Unit (Services)'` = Days | Hours, `'QuickBooks Item'`,
  `'Sort Order'` (Number), `Billable`, `'Billable on Non-School Days'`, `Active` (Booleans). `'Billing Code'` legacy —
  never read or shown.
- Service Aliases: `'Service Alias'` (GUID PK), `Alias` (Text, normalised), `'Alias Type'`
  `'Alias Type (Service Aliases)'` = 'CPT Code' | 'Service Name' (unique key Alias + Alias Type), `Service` (lookup).
- Audit Events: as shared plan.

## Required Variants

- GroupContainer -> `Variant: AutoLayout`. Gallery -> `Variant: Vertical` (`galSvcList`, `galSvcCpt`, `galSvcSnm`).

## Control Definitions

Same definitions as listed in `FundersScreen.screen-plan.md` "Control Definitions" (copied here):

- **GroupContainer** (`Control: GroupContainer`, `Variant: AutoLayout`): BorderColor, BorderStyle, BorderThickness,
  ContentLanguage, DropShadow, EnableChildFocus, Fill, Height, RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft,
  RadiusTopRight, Visible, Width, X, Y, LayoutAlignItems, LayoutDirection, LayoutGap, LayoutJustifyContent,
  LayoutOverflowX, LayoutOverflowY, LayoutWrap, PaddingBottom, PaddingLeft, PaddingRight, PaddingTop, AlignInContainer,
  FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth. Enums `=DropShadow.None`,
  `=LayoutDirection.Vertical|Horizontal`, `=LayoutAlignItems.Stretch|Center|Start`, `=LayoutOverflow.Scroll`,
  `=AlignInContainer.Stretch|Center|Start`.
- **ModernText** (`Control: ModernText`): AccessibleLabel, Align, AutoHeight, BorderColor, BorderStyle, BorderThickness,
  Color, ContentLanguage, DisplayMode, Fill, Font, FontWeight, Height, Italic, OnSelect, PaddingBottom, PaddingLeft,
  PaddingRight, PaddingTop, Radius*, Size, Strikethrough, Text, Underline, VerticalAlign, Visible, Width, Wrap, X, Y,
  AlignInContainer, FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth.
  Enums `=FontWeight.Bold|Semibold|Normal`, `=VerticalAlign.Top|Middle`.
- **ModernButton** (`Control: ModernButton`): AccessibleLabel, Align, Appearance, BasePaletteColor, BorderColor,
  BorderStyle, BorderThickness, Color, ContentLanguage, DisplayMode, Font, FontWeight, Height, Icon, IconRotation,
  IconStyle, Italic, Layout, OnSelect, Padding*, Radius*, Size, Strikethrough, Text, Tooltip, Underline, VerticalAlign,
  Visible, Width, X, Y, AlignInContainer, FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight,
  LayoutMinWidth. NO Fill. `Appearance: =ButtonAppearance.Primary|Secondary`, `Layout: =ButtonLayout.TextOnly`.
- **Classic/Button** (`Control: Classic/Button`): AutoDisableOnSelect, OnSelect, Text, Visible, AlignInContainer,
  LayoutMinHeight, LayoutMinWidth.
- **Gallery** (`Control: Gallery`, `Variant: Vertical`): AccessibleLabel, BorderColor, BorderStyle, BorderThickness,
  ContentLanguage, Default, DelayItemLoading, DisplayMode, Fill, FocusedBorderColor, FocusedBorderThickness, Height,
  Items, LoadingSpinner, LoadingSpinnerColor, NavigationStep, Selectable, ShowNavigation, ShowScrollbar, TabIndex,
  TemplatePadding, TemplateSize, Transition, Visible, Width, WrapCount, X, Y, AlignInContainer, FillPortions,
  LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth.
- **ModernTextInput** (`Control: ModernTextInput`): AccessibleLabel, Align, Appearance, BasePaletteColor, BorderColor,
  BorderStyle, BorderThickness, Color, ContentLanguage, Default, DisplayMode, Fill, Font, FontWeight, Height, Italic,
  MaxLength, OnChange, Padding*, Placeholder, Radius*, Required, Size, Strikethrough, TriggerOutput, Type, Underline,
  ValidationState, Visible, Width, X, Y, AlignInContainer, FillPortions, LayoutMinHeight, LayoutMinWidth. Output Text.
  `Appearance: =Appearance.Outline`, `Type: =TextInputType.SingleLine`, `TriggerOutput: =TriggerOutput.Keypress`,
  `DisplayMode: =DisplayMode.View`.
- **ModernRadio** (`Control: ModernRadio`): AccessibleLabel, BasePaletteColor, BorderColor, BorderStyle,
  BorderThickness, Color, ContentLanguage, Default, DisabledColor, DisplayMode, Fill, Font, FontWeight, Height, Italic,
  ItemDisplayText, Items, Layout, LineHeight, OnChange, Padding*, RadioBackgroundFill, RadioBorderColor,
  RadioSelectionFill, RadioSize, Radius*, Required, Size, Strikethrough, Underline, Visible, Width, X, Y,
  AlignInContainer, FillPortions, LayoutMinHeight, LayoutMinWidth. Output Selected. `Layout: =OptionLayout.Horizontal`.
- **ModernToggle** (`Control: ModernToggle`): AccessibleLabel, BasePaletteColor, Color, ContentLanguage, Default,
  DisplayMode, Font, FontWeight, Height, Italic, Label, LabelPosition, OnCheck, OnUncheck, Size, Strikethrough,
  ToggleSize, Tooltip, Underline, Visible, Width, X, Y, AlignInContainer, FillPortions, LayoutMinHeight,
  LayoutMinWidth. Output Checked.
