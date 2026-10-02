# Screen Plan: Funders

## Assignment

- Action: Create
- Target file: `C:\src\aaca-attendance\billing-app\FundersScreen.pa.yaml`
- YAML key: FundersScreen
- Control name prefix: Fun
- Read with: `canvas-app-shared.md` (palette, visual contract, header/gate/engine/receipt/mutation/audit patterns,
  collection formulas, YAML rules).

## Specification

- Purpose: maintain funders (QuickBooks customer mapping, type, active) and their CodeMetro aliases. No delete of
  funders (deactivate instead). Never shows rates or dollars.
- Screen properties: `Fill: =ColorPaper`; `OnVisible` (|- block):
  `=Set(varFunSelId, Blank()); Set(varFunMode, ""); Set(varFunAliasDelId, Blank()); Set(varFunReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Set(varFunAliasReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Reset(txtFunSearch); Reset(tglFunInactive); Select(btnFunLoadEngine)`
  (filter globals varFunType / varFunMissingQbo / varFunShowInactive are NOT reset — Home sets them).
- Layout. Screen `Children:` = only `conFunRoot` (shared root). Root children in order:
  1. `conFunHeader` (shared; `btnFunNavFunders` current/Primary).
  2. `conFunGate` (shared; `lblFunGateTitle`, `lblFunGateBody`).
  3. `conFunBody` — shared list+detail body; `Visible: =IsFinance`; `FillPortions: =0`;
     `Height: =If(conFunRoot.Width >= 1024, Max(conFunListPanel.Height, conFunRight.Height), If(varFunMode = "", conFunListPanel.Height, conFunRight.Height))`.
     a. `conFunListPanel` — white panel, Vertical, Stretch, padding 16, gap 8, `FillPortions: =If(conFunRoot.Width >= 1024, 1, 0)`,
        `AlignInContainer: =If(conFunRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)`,
        `Visible: =!(conFunRoot.Width < 1024 && varFunMode <> "")`, `Height: =738 + conFunChips.Height`. Children:
        - `conFunListHead` Horizontal, Height 44, gap 8, Center: `lblFunListTitle` "Funders" (18 Bold, FillPortions 1,
          LayoutMinWidth 80, Height 28, Wrap false); `btnFunReload` Secondary "Reload" Width 88
          (`OnSelect: =Select(btnFunLoadEngine)`, Disabled while varFunLoading); `btnFunNew` Primary "New funder" Width 120.
        - `lblFunSearch` "Search abbreviation, name or alias" (field label, Height 18, Wrap false).
        - `txtFunSearch` ModernTextInput, Height 36, `Appearance: =Appearance.Outline`, `Type: =TextInputType.Search`,
          `TriggerOutput: =TriggerOutput.Delayed`, `Placeholder: ="e.g. LAUSD or Los Angeles"`, Color ink, Default "".
        - `conFunChips` Horizontal, `LayoutWrap: =true`, gap 8, `FillPortions: =0`,
          `Height: =If(conFunListPanel.Width - 32 >= 702, 44, conFunListPanel.Width - 32 >= 454, 96, 148)`. Chips
          (ModernButton chip style, Height 44, FillPortions 0): `btnFunChipAll` "All" W64 (active `varFunType = "All"`,
          OnSelect `Set(varFunType, "All")`); `btnFunChipDistrict` "District" W96 (`"District"`); `btnFunChipRc`
          "Regional Center" W150 (`"Regional Center"`); `btnFunChipPp` "Private Pay" W120 (`"Private Pay"`);
          `btnFunChipMissing` "Missing QuickBooks customer" W240 (active `varFunMissingQbo`,
          OnSelect `=With({next: !varFunMissingQbo}, Set(varFunMissingQbo, next))`).
        - `conFunFilterRow` Horizontal, Height 44, gap 8, Center: `tglFunInactive` ModernToggle (Label "Show inactive",
          Width 160, Height 44, `Default: =varFunShowInactive`, `OnCheck: =Set(varFunShowInactive, true)`,
          `OnUncheck: =Set(varFunShowInactive, false)`, Color ink); `btnFunClear` Secondary "Clear filters" W120,
          OnSelect `=Set(varFunType, "All"); Set(varFunMissingQbo, false); Set(varFunShowInactive, false); Reset(txtFunSearch); Reset(tglFunInactive)`.
        - `lblFunCount` caption, Height 36, wraps (formula below).
        - `galFunList` (see Gallery contract), Height 480.
     b. `conFunRight` — Vertical, gap 12, no fill, Stretch, `FillPortions: =If(conFunRoot.Width >= 1024, 1, 0)`,
        `AlignInContainer` as list panel, `Visible: =varFunMode <> "" || conFunRoot.Width >= 1024`,
        `Height: =If(varFunMode = "", If(conFunRoot.Width >= 1024, 72, 0), conFunForm.Height + If(varFunMode = "edit", 12 + conFunAliasPanel.Height, 0))`. Children:
        - `conFunPlaceholder` white panel, padding 16, Height 72, `Visible: =varFunMode = ""`:
          `lblFunPlaceholder` "Select Edit on a funder, or New funder to add one." (13 muted, Height 40, wraps).
        - `conFunForm` white panel, Vertical, Stretch, padding 16, gap 6, `Visible: =varFunMode <> ""`,
          `Height: =488 + If(varFunReceipt.Kind <> "", 6 + 16 + Max(44, 18 * RoundUp(Len(varFunReceipt.Msg) / 45, 0) + 8), 0)`. Children in order:
          `conFunReceipt` (shared receipt strip: `lblFunReceipt`, `btnFunReceiptDismiss`; var `varFunReceipt`);
          `conFunFormHead` Horizontal H44: `lblFunFormTitle` (18 Bold, FillPortions 1, Wrap false,
          `Text: =If(varFunMode = "new", "New funder", "Edit funder " & LookUp(colFunders, FunderId = varFunSelId).Abbr)`),
          `btnFunBack` Secondary "Back to list" W120 (`Visible: =conFunRoot.Width < 1024`, same OnSelect as Cancel);
          `lblFunAbbr` "Abbreviation (required)"; `txtFunAbbr` (H36, Outline, SingleLine, Keypress,
          `Default: =LookUp(colFunders, FunderId = varFunSelId).Abbr`, MaxLength 100);
          `lblFunFull` "Full name"; `txtFunFull` (`Default: =LookUp(colFunders, FunderId = varFunSelId).FullName`);
          `lblFunType` "Funder type (required)"; `rdoFunType` ModernRadio (H36, `Layout: =OptionLayout.Horizontal`,
          `Items: =["District", "Regional Center", "Private Pay"]`, `Default` (|- block)
          `={Value: Coalesce(LookUp(colFunders, FunderId = varFunSelId).TypeText, "District")}`);
          `lblFunQbo` "QuickBooks customer"; `txtFunQbo` (`Default: =LookUp(colFunders, FunderId = varFunSelId).QboCustomer`,
          Placeholder "Exact customer name in QuickBooks Online");
          `tglFunActive` ModernToggle (Label "Active", H44, W160,
          `Default: =If(IsBlank(varFunSelId), true, LookUp(colFunders, FunderId = varFunSelId).IsActive)`);
          `lblFunValidation` (H36, 13, wraps, formula below, `Color: =If(Self.Text = "Ready to save.", ColorTeal, ColorUnexcused)`);
          `conFunActions` Horizontal H44 gap 8: `btnFunSave` Primary "Save" W100; `btnFunCancel` Secondary "Cancel" W100.
        - `conFunAliasPanel` white panel, Vertical, Stretch, padding 16, gap 6, `Visible: =varFunMode = "edit"`,
          `Height: =486 + If(varFunAliasReceipt.Kind <> "", 6 + 16 + Max(44, 18 * RoundUp(Len(varFunAliasReceipt.Msg) / 45, 0) + 8), 0) + If(!IsBlank(varFunAliasDelId), 62, 0)`. Children in order:
          `conFunAliasReceipt` (shared receipt strip: `lblFunAliasReceipt`, `btnFunAliasReceiptDismiss`; var `varFunAliasReceipt`);
          `lblFunAliasTitle` "CodeMetro names (aliases)" (14 Semibold, H20, Wrap false);
          `lblFunAliasCaption` "Aliases are the Funding Source names CodeMetro writes. Each one maps to exactly one funder." (12 muted, H36, wraps);
          `conFunAliasAddRow` Horizontal H44 gap 8 Center: `lblFunAliasNew` "CodeMetro name" (field label, W120, H36, Wrap false, VerticalAlign Middle),
          `txtFunAliasNew` (FillPortions 1, H36, Outline, `TriggerOutput: =TriggerOutput.Keypress`, Placeholder "Funding Source name"),
          `btnFunAliasAdd` Primary "Add alias" W110;
          `conFunAliasNotice` Horizontal H44 gap 8 Center, padding 4/8, radius 6, `Fill` = ColorWarnBg when the typed name
          is already mapped (anywhere), else ColorWhite: `lblFunAliasNotice` (13 ink, FillPortions 1, H40, wraps),
          `btnFunAliasMove` Primary "Move it here" W120 (Visible only on a clash with another funder);
          `conFunAliasConfirm` Horizontal H56, Fill ColorWarnBg, padding 6/8, gap 8, Center, radius 6,
          `Visible: =!IsBlank(varFunAliasDelId)`: `lblFunAliasConfirm` (13 ink, FillPortions 1, H40, wraps,
          `="Remove alias " & LookUp(colFunderAliases, AliasId = varFunAliasDelId).AliasText & " from " & LookUp(colFunders, FunderId = varFunSelId).Abbr & "?"`),
          `btnFunAliasConfirmYes` destructive "Remove" W96, `btnFunAliasConfirmNo` Secondary "Keep" W80
          (`OnSelect: =Set(varFunAliasDelId, Blank())`);
          `lblFunAliasCount` (12 muted, H20, Wrap false):
          `=With({n: CountRows(Filter(colFunderAliases, FunderId = varFunSelId))}, If(n = 0, "No aliases yet.", n & If(n = 1, " alias", " aliases")))`;
          `galFunAliases` Height 260, TemplateSize 52, Items `=Sort(Filter(colFunderAliases, FunderId = varFunSelId), AliasText)`;
          row shell `conFunAliasRow` Horizontal, padding 4/8, gap 8, Center, border rule 1, Fill ColorWhite:
          `lblFunAliasRowText` (13 ink, FillPortions 1, H40, wraps, `=ThisItem.AliasText`), `btnFunAliasRowRemove`
          Secondary "Remove" W88 (`OnSelect: =Set(varFunAliasDelId, ThisItem.AliasId)`, AccessibleLabel
          `="Remove alias " & ThisItem.AliasText`).
  4. `btnFunLoadEngine` hidden Classic/Button: shared engine shape; non-finance branch `Clear(colFunders); Clear(colFunderAliases)`;
     success branch `Refresh(Funders); Refresh('Funder Aliases'); Concurrent(<colFunders verbatim>, <colFunderAliases verbatim>); true`.
  5. `btnFunFormResetEngine` hidden Classic/Button: `OnSelect: =Reset(txtFunAbbr); Reset(txtFunFull); Reset(rdoFunType); Reset(txtFunQbo); Reset(tglFunActive); Reset(txtFunAliasNew)`.

- Gallery contract `galFunList`: Variant Vertical, Height 480, TemplateSize 120, TemplatePadding 0, TabIndex 0,
  Selectable false, AccessibleLabel "Funders list". Items (|- block):

```
=Sort(
    Filter(
        colFunders As f,
        (varFunShowInactive || f.IsActive) &&
        (varFunType = "All" || f.TypeText = varFunType) &&
        (!varFunMissingQbo || Trim(f.QboCustomer) = "") &&
        (Trim(txtFunSearch.Text) = "" ||
            Lower(Trim(txtFunSearch.Text)) in Lower(f.Abbr & " " & f.FullName) ||
            CountIf(colFunderAliases, FunderId = f.FunderId && Lower(Trim(txtFunSearch.Text)) in Lower(AliasText)) > 0)
    ),
    Abbr,
    SortOrder.Ascending
)
```

  Row shell `conFunRow` Vertical, Stretch, padding 8, gap 2, border rule 1,
  `Fill: =If(ThisItem.FunderId = varFunSelId, ColorInfoBg, ColorWhite)`, Width `Parent.TemplateWidth - 16`,
  Height `Parent.TemplateHeight`:
  - `conFunRowTop` Horizontal H44 gap 8 Center: `lblFunRowAbbr` (14 Semibold ink, FillPortions 1, H24, Wrap false,
    `=ThisItem.Abbr`); `btnFunRowEdit` Secondary "Edit" W72 (AccessibleLabel `="Edit funder " & ThisItem.Abbr`).
  - `lblFunRowName` (12 ink, H36, wraps, Top):
    `=ThisItem.FullName & " · " & ThisItem.TypeText & If(ThisItem.IsActive, "", " · Inactive") & " · " & CountIf(colFunderAliases, FunderId = ThisItem.FunderId) & " aliases"`
  - `lblFunRowQbo` (12, H20, Wrap false, `FontWeight: =If(Trim(ThisItem.QboCustomer) = "", FontWeight.Semibold, FontWeight.Normal)`,
    `Color: =If(Trim(ThisItem.QboCustomer) = "", ColorWarnInk, ColorInk)`,
    `Text: =If(Trim(ThisItem.QboCustomer) = "", "No QuickBooks customer", "QuickBooks customer " & ThisItem.QboCustomer)`).
  Row budget: 8 + 44 + 2 + 36 + 2 + 20 + 8 = 120 = TemplateSize.

- `lblFunCount.Text` (|- block): `=With({n: CountRows(<the Filter(...) expression from Items, without Sort>),
  m: CountRows(Filter(colFunders, varFunShowInactive || IsActive))}, ...)` (never read `galFunList.AllItems`), body:
  `If(varFunLoading, "Loading funders...", varFunLoadError <> "", "Could not load funders - " & varFunLoadError, n = 0, "No funders match these filters. Use Clear filters to see all.", "Showing " & n & " of " & m & " funders")`.
  `Color: =If(varFunLoadError <> "", ColorUnexcused, ColorMuted)`.

- `lblFunValidation.Text` (|- block):

```
=With(
    {inAbbr: Trim(txtFunAbbr.Text), inType: Coalesce(rdoFunType.Selected.Value, "")},
    With(
        {dup: LookUp(colFunders, Lower(Abbr) = Lower(inAbbr) && FunderId <> Coalesce(varFunSelId, ZeroGuid))},
        If(
            inAbbr = "", "Abbreviation is required.",
            !IsBlank(dup), "Abbreviation " & inAbbr & " is already used by " & Coalesce(dup.FullName, dup.Abbr) & ".",
            inType = "", "Choose a funder type.",
            "Ready to save."
        )
    )
)
```

- `lblFunAliasNotice.Text` (|- block) and `conFunAliasNotice.Fill`, `btnFunAliasMove.Visible`, `btnFunAliasAdd.DisplayMode`
  all derive from `With({n: NormAlias(txtFunAliasNew.Text)}, With({hit: LookUp(colFunderAliases, AliasText = n)}, ...))`:
  - Notice: `If(n = "", "Type the CodeMetro Funding Source name, then select Add alias.", IsBlank(hit), "Will be saved as " & n, hit.FunderId = varFunSelId, "Already mapped to this funder.", "Already mapped to " & LookUp(colFunders, FunderId = hit.FunderId).Abbr & ". Select Move it here to map it to this funder instead.")`
  - Fill: `If(IsBlank(hit) || n = "", ColorWhite, ColorWarnBg)`
  - Move Visible: `!IsBlank(hit) && hit.FunderId <> varFunSelId`
  - Add DisplayMode: `If(varFunSaving || n = "" || !IsBlank(hit), DisplayMode.Disabled, DisplayMode.Edit)`

- Breakpoint source: `conFunRoot.Width` (>= 1024 two-panel) and `conFunListPanel.Width` for chip wrapping.
- Numeric layout budgets:
  - List panel: 32 + 44 + 18 + 36 + chips + 44 + 36 + 480 + 6 gaps x 8 = 738 + chips. Chips at 1024 (inner 458):
    row 1 64+96+150+120+3x8 = 454, row 2 240 -> 96; at 1366 (inner 629) -> 96; stacked 576 -> 96; 326 -> 148.
  - Filter row: 160 + 8 + 120 = 288 <= 326.
  - Form panel: 44 + 4 x (18 + 36) + 44 + 36 + 44 = 384; 12 gaps x 6 = 72; padding 32 -> 488 (+ receipt).
    Radio row: 3 options ~330 px <= 458 (wraps internally below that; stacked branch has >= 326 inner, acceptable).
  - Alias panel: 20 + 36 + 44 + 44 + 20 + 260 = 424; 5 gaps x 6 = 30; padding 32 -> 486 (+ receipt + 62 confirm).
  - Alias add row at inner 458: 120 + 8 + input (212) + 8 + 110 = 458. Notice row: label + 8 + 120 Move.
  - Confirm row at inner 458: label (458 - 16 - 96 - 80 - 16 = 250, 2 lines x 20) + buttons -> H56.
  - Receipt: Msg length ~250 chars -> RoundUp(250 / 45) = 6 lines -> 18 x 6 + 8 = 116; strip 132 (fits phone widths).
- Text fit: `lblFunRowAbbr` abbreviations <= 20 chars at 14 Semibold (~160 px) in >= 300 px; full name wraps 2 lines;
  chip "Missing QuickBooks customer" (27 chars at 14 ~ 210 px) in W240.
- Visual hierarchy: list title 18 Bold; row identity 14 Semibold; warning QBO text ColorWarnInk Semibold; form title
  18 Bold; field labels 12 Semibold muted; Save teal Primary.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| RF-FUN-ABBR | list row | Abbreviation | colFunders.Abbr | `lblFunRowAbbr` | `=ThisItem.Abbr` | top line, always |
| RF-FUN-NAME / RF-FUN-TYPE / RF-FUN-ALIASES | list row | full name, type, alias count (+ Inactive tag) | FullName, TypeText, CountIf(colFunderAliases) | `lblFunRowName` | see Gallery contract | second line, 2 lines |
| RF-FUN-QBO | list row | QBO customer or warning | QboCustomer | `lblFunRowQbo` | see Gallery contract | third line |
| RF-FUN-ALIASTEXT | alias row | CodeMetro name | AliasText | `lblFunAliasRowText` | `=ThisItem.AliasText` | wraps 2 lines |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| SV-GATE | `conFunGate` | `=!IsFinance` | non-finance / finance |
| SV-BODY | `conFunBody`, `conFunNav` | `=IsFinance` | finance / non-finance |
| SV-FUN-FORM | `conFunForm` | `=varFunMode <> ""` (inside IsFinance body) | new/edit open / closed |
| SV-FUN-ALIAS | `conFunAliasPanel` | `=varFunMode = "edit"` | saved funder / new or closed |
| SV-FUN-CONFIRM | `conFunAliasConfirm` | `=!IsBlank(varFunAliasDelId)` | remove pending / none |
| SV-RECEIPTS | `conFunReceipt`, `conFunAliasReceipt` | `=varFunReceipt.Kind <> ""`, `=varFunAliasReceipt.Kind <> ""` | after mutation until dismissed / next Edit, New or screen entry |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-FUN-LOAD | IsFinance | `OnVisible`, `btnFunReload` -> `btnFunLoadEngine` | Funders, Funder Aliases | collections reloaded | N/A | N/A | `galFunList`, `lblFunCount` |
| A-FUN-SEARCH / TYPE / MISSQBO / INACTIVE / CLEAR | loaded | `txtFunSearch`, chips, `tglFunInactive`, `btnFunClear` | colFunders, colFunderAliases, filter globals | Items predicate above | N/A | N/A | chips Appearance, `lblFunCount` |
| A-FUN-SELECT | row visible | `btnFunRowEdit.OnSelect` (|-): `=Set(varFunSelId, ThisItem.FunderId); Set(varFunMode, "edit"); Set(varFunAliasDelId, Blank()); Set(varFunReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Set(varFunAliasReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Select(btnFunFormResetEngine)` | FunderId | edit mode, inputs prepopulated from colFunders by ID | N/A | N/A | form + highlighted row |
| A-FUN-NEW | IsFinance | `btnFunNew.OnSelect`: same as Select but `Set(varFunSelId, Blank()); Set(varFunMode, "new")` | none | blank form (type District, Active on) | N/A | N/A | `lblFunFormTitle` "New funder" |
| A-FUN-CREATE / A-FUN-UPDATE / A-FUN-DEACT / A-FUN-REACT | `lblFunValidation` = "Ready to save." | `btnFunSave.OnSelect` (formula below); `btnFunSave.DisplayMode: =If(varFunSaving \|\| lblFunValidation.Text <> "Ready to save.", DisplayMode.Disabled, DisplayMode.Edit)` | Funders; create -> returned `varFunLastRec.Funder`; update -> `varFunSelId` | create/update; op guards `!old.IsActive && act` = Reactivated, `old.IsActive && !act` = Deactivated; audit Create/Update; selection = returned ID; reload | Abbreviation, Full Name, Funder Type, QuickBooks Customer, Active | RecordId + "Abbreviation", "Full name", "Funder type", "QuickBooks customer", "Active before -> after (op)", "Audit" | `lblFunReceipt`; `galFunList` row (highlight by varFunSelId) |
| A-FUN-CANCEL | form open | `btnFunCancel.OnSelect` / `btnFunBack.OnSelect`: `=Set(varFunSelId, Blank()); Set(varFunMode, ""); Set(varFunAliasDelId, Blank())` | none | no Patch, form closed | N/A | N/A | placeholder/list |
| A-FUN-ALIAS-ADD | mode "edit", Add enabled | `btnFunAliasAdd.OnSelect` (formula below) | Funder Aliases; returned `varFunLastAlias.'Funder Alias'` | new alias for varFunSelId; audit Create | CodeMetro Name, Funder | alias text, funder abbreviation, audit | `lblFunAliasReceipt`; `galFunAliases`; row alias count |
| A-FUN-ALIAS-MOVE | clash with another funder | `btnFunAliasMove.OnSelect` | Funder Aliases by clash AliasId | Funder -> varFunSelId; audit Update | Funder | alias, from, to, audit | receipt; `galFunAliases` |
| A-FUN-ALIAS-DEL | confirm open | `btnFunAliasRowRemove` -> `btnFunAliasConfirmYes.OnSelect` | snapshot by varFunAliasDelId | Remove; audit Soft Delete | existence | alias, funder, audit | receipt; alias gone |
| A-FUN-ALIAS-DELCANCEL | confirm open | `btnFunAliasConfirmNo` | none | varFunAliasDelId Blank | N/A | N/A | alias still listed |

### `btnFunSave.OnSelect` (|- block)

```
=If(
    lblFunValidation.Text = "Ready to save." && !varFunSaving && IsFinance,
    Set(varFunSaving, true);
    Set(varFunErr, "");
    With(
        {
            id: varFunSelId,
            idx: Coalesce(varFunSelId, ZeroGuid),
            old: LookUp(colFunders, FunderId = varFunSelId),
            inAbbr: Trim(txtFunAbbr.Text),
            inFull: Trim(txtFunFull.Text),
            inType: rdoFunType.Selected.Value,
            inQbo: Trim(txtFunQbo.Text),
            act: tglFunActive.Checked
        },
        With(
            {
                dup: LookUp(Funders, Abbreviation = inAbbr && Funder <> idx),
                typeOpt: Switch(inType, "District", 'Funder Type (Funders)'.District, "Regional Center", 'Funder Type (Funders)'.'Regional Center', "Private Pay", 'Funder Type (Funders)'.'Private Pay'),
                op: If(IsBlank(id), "New funder", !old.IsActive && act, "Reactivated", old.IsActive && !act, "Deactivated", "No status change")
            },
            If(
                !IsBlank(dup),
                Set(varFunReceipt, {Kind: "Blocked", Msg: "Not saved. Abbreviation " & inAbbr & " is already used by another funder (" & dup.'Full Name' & ").", RecordId: idx}),
                IfError(
                    Set(varFunLastRec, If(IsBlank(id),
                        Patch(Funders, Defaults(Funders), {Abbreviation: inAbbr, 'Full Name': inFull, 'Funder Type': typeOpt, 'QuickBooks Customer': inQbo, Active: act}),
                        Patch(Funders, LookUp(Funders, Funder = idx), {Abbreviation: inAbbr, 'Full Name': inFull, 'Funder Type': typeOpt, 'QuickBooks Customer': inQbo, Active: act})));
                    true,
                    Set(varFunErr, FirstError.Message);
                    false
                );
                If(
                    varFunErr <> "",
                    Set(varFunReceipt, {Kind: "Failed", Msg: "Funder not saved. " & varFunErr, RecordId: idx}),
                    IfError(
                        Patch('Audit Events', Defaults('Audit Events'), {Summary: Left(If(IsBlank(id), "Create", "Update") & " Funders " & varFunLastRec.Abbreviation, 100), Action: If(IsBlank(id), 'Action (Audit Events)'.Create, 'Action (Audit Events)'.Update), Entity: "Funders", 'Entity ID': Text(varFunLastRec.Funder), Before: If(IsBlank(id), "", JSON({Abbreviation: old.Abbr, FullName: old.FullName, FunderType: old.TypeText, QuickBooksCustomer: old.QboCustomer, Active: old.IsActive})), After: JSON({Abbreviation: inAbbr, FullName: inFull, FunderType: inType, QuickBooksCustomer: inQbo, Active: act}), Reason: "Funder saved in AACA Billing"});
                        Set(varFunAuditOk, true),
                        Set(varFunAuditOk, false)
                    );
                    Set(varFunReceipt, {Kind: If(IsBlank(id), "Created", "Updated"), Msg: If(IsBlank(id), "Created", "Updated") & " funder " & varFunLastRec.Abbreviation & ". Abbreviation " & varFunLastRec.Abbreviation & " | Full name " & Coalesce(varFunLastRec.'Full Name', "(blank)") & " | Funder type " & Text(varFunLastRec.'Funder Type') & " | QuickBooks customer " & Coalesce(varFunLastRec.'QuickBooks Customer', "none") & " | Active " & If(IsBlank(id), "", If(old.IsActive, "Yes", "No") & " -> ") & If(varFunLastRec.Active, "Yes", "No") & " (" & op & ") | Audit " & If(varFunAuditOk, "written", "FAILED - tell Adam"), RecordId: varFunLastRec.Funder});
                    Set(varFunSelId, varFunLastRec.Funder);
                    Set(varFunMode, "edit");
                    Select(btnFunLoadEngine);
                    Select(btnFunFormResetEngine)
                )
            )
        )
    );
    Set(varFunSaving, false)
)
```

### `btnFunAliasAdd.OnSelect` (|- block)

```
=With(
    {n: NormAlias(txtFunAliasNew.Text), fid: varFunSelId},
    With(
        {hit: LookUp('Funder Aliases', 'CodeMetro Name' = n)},
        If(
            !IsBlank(hit),
            Set(varFunAliasReceipt, {Kind: "Blocked", Msg: "Not added. " & n & " is already mapped to " & hit.Funder.Abbreviation & ".", RecordId: hit.'Funder Alias'}),
            n <> "" && !IsBlank(fid) && !varFunSaving && IsFinance,
            Set(varFunSaving, true);
            Set(varFunErr, "");
            IfError(Set(varFunLastAlias, Patch('Funder Aliases', Defaults('Funder Aliases'), {'CodeMetro Name': n, Funder: LookUp(Funders, Funder = fid)})); true, Set(varFunErr, FirstError.Message); false);
            If(
                varFunErr <> "",
                Set(varFunAliasReceipt, {Kind: "Failed", Msg: "Alias not added. " & varFunErr, RecordId: ZeroGuid}),
                IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Create Funder Aliases " & n, 100), Action: 'Action (Audit Events)'.Create, Entity: "Funder Aliases", 'Entity ID': Text(varFunLastAlias.'Funder Alias'), Before: "", After: JSON({CodeMetroName: n, Funder: LookUp(colFunders, FunderId = fid).Abbr}), Reason: "Funder alias added in AACA Billing"}); Set(varFunAuditOk, true), Set(varFunAuditOk, false));
                Set(varFunAliasReceipt, {Kind: "Added", Msg: "Added alias " & n & " to " & LookUp(colFunders, FunderId = fid).Abbr & ". | Audit " & If(varFunAuditOk, "written", "FAILED - tell Adam"), RecordId: varFunLastAlias.'Funder Alias'});
                Reset(txtFunAliasNew);
                Select(btnFunLoadEngine)
            );
            Set(varFunSaving, false)
        )
    )
)
```

### `btnFunAliasMove.OnSelect` (|- block)

Same skeleton. `With({n: NormAlias(txtFunAliasNew.Text), fid: varFunSelId}, With({hit: LookUp(colFunderAliases, AliasText = n && FunderId <> fid)}, With({hid: hit.AliasId, fromAbbr: LookUp(colFunders, FunderId = hit.FunderId).Abbr, toAbbr: LookUp(colFunders, FunderId = fid).Abbr}, If(!IsBlank(hid) && !IsBlank(fid) && !varFunSaving && IsFinance, ...))))`.
Mutation: `Set(varFunLastAlias, Patch('Funder Aliases', LookUp('Funder Aliases', 'Funder Alias' = hid), {Funder: LookUp(Funders, Funder = fid)}))`.
Audit: Action Update, Entity "Funder Aliases", 'Entity ID' `Text(hid)`, Before `JSON({CodeMetroName: n, Funder: fromAbbr})`,
After `JSON({CodeMetroName: n, Funder: toAbbr})`, Reason "Funder alias moved in AACA Billing".
Receipt Kind "Moved", Msg `"Moved alias " & n & " from " & fromAbbr & " to " & toAbbr & ". | Audit " & ...`, RecordId hid.
Success also `Reset(txtFunAliasNew); Select(btnFunLoadEngine)`. Failure Msg "Alias not moved. " & varFunErr.

### `btnFunAliasConfirmYes.OnSelect` (|- block)

`With({snap: LookUp(colFunderAliases, AliasId = varFunAliasDelId)}, With({hid: snap.AliasId, fAbbr: LookUp(colFunders, FunderId = snap.FunderId).Abbr}, If(!IsBlank(hid) && !varFunSaving && IsFinance, ...)))`.
Mutation: `IfError(Remove('Funder Aliases', LookUp('Funder Aliases', 'Funder Alias' = hid)); true, Set(varFunErr, FirstError.Message); false)`.
Audit: Action `'Action (Audit Events)'.'Soft Delete'`, Entity "Funder Aliases", Before `JSON({CodeMetroName: snap.AliasText, Funder: fAbbr})`,
After "", Reason "Funder alias removed (row deleted)". Receipt Kind "Removed", Msg `"Removed alias " & snap.AliasText & " from " & fAbbr & ". | Audit " & ...`.
Success also `Set(varFunAliasDelId, Blank()); Select(btnFunLoadEngine)`. Failure Msg "Alias not removed. " & varFunErr.

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| `txtFunSearch` | `lblFunSearch` "Search abbreviation, name or alias" | `conFunListPanel` |
| `txtFunAbbr` | `lblFunAbbr` "Abbreviation (required)" | `conFunForm` |
| `txtFunFull` | `lblFunFull` "Full name" | `conFunForm` |
| `rdoFunType` | `lblFunType` "Funder type (required)" | `conFunForm` |
| `txtFunQbo` | `lblFunQbo` "QuickBooks customer" | `conFunForm` |
| `txtFunAliasNew` | `lblFunAliasNew` "CodeMetro name" | `conFunAliasAddRow` |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-FUN-CREATE/UPDATE/DEACT/REACT | `varFunLastRec` -> `varFunReceipt` -> `lblFunReceipt` | Funders; `LookUp(colFunders, FunderId = varFunSelId)` | `galFunList` row, form | returned `.Funder` -> RecordId -> varFunSelId | `Select(btnFunLoadEngine)` | row Fill ColorInfoBg by varFunSelId |
| A-FUN-ALIAS-ADD/MOVE/DEL | `varFunLastAlias` or snapshot -> `lblFunAliasReceipt` | Funder Aliases; colFunderAliases | `galFunAliases` | alias GUID | `Select(btnFunLoadEngine)` | gallery filtered to varFunSelId |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| create/update | Abbreviation | Changed | `Trim(txtFunAbbr.Text)` | `Abbreviation` | "Abbreviation " & varFunLastRec.Abbreviation | `lblFunRowAbbr` |
| create/update | Full Name | Changed | `Trim(txtFunFull.Text)` | `'Full Name'` | "Full name ..." | `lblFunRowName` |
| create/update | Funder Type | Changed | `rdoFunType.Selected.Value` | `'Funder Type'` (Switch) | "Funder type ..." | `lblFunRowName` |
| create/update | QuickBooks Customer | Changed | `Trim(txtFunQbo.Text)` | `'QuickBooks Customer'` | "QuickBooks customer ..." | `lblFunRowQbo` |
| create/update/deact/react | Active | Changed | `tglFunActive.Checked`; old = colFunders row | `Active` | "Active Yes -> No (Deactivated)" | `lblFunRowName` Inactive tag |
| update | aliases of the funder | Preserved | colFunderAliases | not in Patch | alias count | `lblFunRowName` |
| alias add | CodeMetro Name, Funder | Changed | NormAlias(input), varFunSelId | Patch Defaults | "Added alias N to ABBR" | `galFunAliases` |
| alias move | Funder | Changed; CodeMetro Name Preserved | clash row | Patch `Funder` only | "from X to Y" | `galFunAliases` |
| alias remove | existence | Changed | snapshot | Remove | "Removed alias ..." | absent |

## Functional Test Scenarios

Copied from the plan index (keys identical): S-FUN-LOAD, S-FUN-CREATE, S-FUN-CREATE-REQ, S-FUN-CREATE-DUP,
S-FUN-UPDATE, S-FUN-DEACT, S-FUN-REACT, S-FUN-COMPOUND, S-FUN-CANCEL, S-FUN-FAIL, S-FUN-SEARCH, S-FUN-TYPE,
S-FUN-MISSQBO, S-FUN-INACTIVE, S-FUN-CLEAR, S-FUN-ALIAS-ADD, S-FUN-ALIAS-SAME, S-FUN-ALIAS-MOVE, S-FUN-ALIAS-DEL,
S-FUN-ALIAS-DELCANCEL, plus arrival checks S-HOME-FUNQBO and S-HOME-PRIVPAY.

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-FUN-CREATE | no ZZTEST1 | New funder " ZZTEST1 " / "ZZ Test District" / District / QBO blank / Active; Save | row created trimmed; audit Create | `lblFunReceipt` all five fields + Audit written; row highlighted | N/A |
| S-FUN-CREATE-REQ | new form | blank abbreviation | Save disabled | `lblFunValidation` "Abbreviation is required." | N/A |
| S-FUN-CREATE-DUP | ZZTEST1 exists | abbreviation "zztest1" | Save disabled | "Abbreviation zztest1 is already used by ZZ Test District." | server re-check -> Blocked receipt |
| S-FUN-UPDATE | ZZTEST1 QBO blank | QBO "ZZ Test Customer"; Save | saved | receipt; `lblFunRowQbo` | N/A |
| S-FUN-DEACT / S-FUN-REACT / S-FUN-COMPOUND | ZZTEST1 active | Active off, Save; Active on, Save | false then true | receipts "Active Yes -> No (Deactivated)" then "No -> Yes (Reactivated)" | second old value read from reloaded colFunders |
| S-FUN-CANCEL | form open with edits | Cancel | unchanged | row text | N/A |
| S-FUN-FAIL | form open | Full name longer than column max; Save | not saved | Failed receipt on ColorErrorBg | N/A |
| S-FUN-SEARCH / TYPE / MISSQBO / INACTIVE / CLEAR | ZZTEST1, ZZTEST2 (District), ZZTESTPP (Private Pay) | search "zztest" / District chip / Missing chip / toggle / Clear | 2 matching shown, 1 hidden each; Clear restores | `galFunList`, `lblFunCount` | alias text matches in search |
| S-FUN-ALIAS-ADD | ZZTEST1 edit | "  zz   test  district " -> Add alias | alias ZZ TEST DISTRICT | receipt; `galFunAliases`; row "1 aliases" | blank -> Add disabled |
| S-FUN-ALIAS-SAME | alias on ZZTEST1 | type it again | Add disabled | notice "Already mapped to this funder." | N/A |
| S-FUN-ALIAS-MOVE | alias on ZZTEST1; ZZTEST2 open | type it; Move it here | alias now under ZZTEST2 | receipt "Moved alias ... from ZZTEST1 to ZZTEST2" | N/A |
| S-FUN-ALIAS-DEL / DELCANCEL | alias listed | Remove -> Remove / Keep | deleted / kept | receipt / list | N/A |
| S-HOME-FUNQBO / S-HOME-PRIVPAY | arrive from Home | screen opens | chips reflect globals; `lblFunCount` n = Home count | chips, count | N/A |

## Relevant Data Source Schemas

- Funders: `Funder` (GUID PK), `Abbreviation` (Text, primary name, unique), `'Full Name'` (Text),
  `'QuickBooks Customer'` (Text), `'Funder Type'` choice `'Funder Type (Funders)'` = District | 'Regional Center' |
  'Private Pay', `Active` (Boolean).
- Funder Aliases: `'Funder Alias'` (GUID PK), `'CodeMetro Name'` (Text, normalised UPPER, unique), `Funder` (lookup Funders).
- Audit Events: `Summary`, `Action` (`'Action (Audit Events)'`), `Entity`, `'Entity ID'`, `Before`, `After`, `Reason`.

## Required Variants

- GroupContainer -> `Variant: AutoLayout` (all). Gallery -> `Variant: Vertical` (`galFunList`, `galFunAliases`).

## Control Definitions

- **GroupContainer** (`Control: GroupContainer`, `Variant: AutoLayout`): BorderColor, BorderStyle, BorderThickness,
  ContentLanguage, DropShadow, EnableChildFocus, Fill, Height, RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft,
  RadiusTopRight, Visible, Width, X, Y, LayoutAlignItems, LayoutDirection, LayoutGap, LayoutJustifyContent,
  LayoutOverflowX, LayoutOverflowY, LayoutWrap, PaddingBottom, PaddingLeft, PaddingRight, PaddingTop, AlignInContainer,
  FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth. Enums: `=DropShadow.None`,
  `=LayoutDirection.Vertical|Horizontal`, `=LayoutAlignItems.Stretch|Center|Start`, `=LayoutOverflow.Scroll`,
  `=AlignInContainer.Stretch|Center|Start`.
- **ModernText** (`Control: ModernText`): AccessibleLabel, Align, AutoHeight, BorderColor, BorderStyle, BorderThickness,
  Color, ContentLanguage, DisplayMode, Fill, Font, FontWeight, Height, Italic, OnSelect, PaddingBottom, PaddingLeft,
  PaddingRight, PaddingTop, Radius*, Size, Strikethrough, Text, Underline, VerticalAlign, Visible, Width, Wrap, X, Y,
  AlignInContainer, FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth. Enums:
  `=FontWeight.Bold|Semibold|Normal`, `=VerticalAlign.Top|Middle`.
- **ModernButton** (`Control: ModernButton`): AccessibleLabel, Align, Appearance, BasePaletteColor, BorderColor,
  BorderStyle, BorderThickness, Color, ContentLanguage, DisplayMode, Font, FontWeight, Height, Icon, IconRotation,
  IconStyle, Italic, Layout, OnSelect, Padding*, Radius*, Size, Strikethrough, Text, Tooltip, Underline, VerticalAlign,
  Visible, Width, X, Y, AlignInContainer, FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight,
  LayoutMinWidth. NO Fill. Enums: `Appearance: =ButtonAppearance.Primary|Secondary` (Enum name ButtonAppearance),
  `Layout: =ButtonLayout.TextOnly`, `DisplayMode: =DisplayMode.Edit|Disabled`.
- **Classic/Button** (`Control: Classic/Button`, hidden engines): AutoDisableOnSelect, OnSelect, Text, Visible,
  AlignInContainer, LayoutMinHeight, LayoutMinWidth. No AccessibleLabel.
- **Gallery** (`Control: Gallery`, `Variant: Vertical`): AccessibleLabel, BorderColor, BorderStyle, BorderThickness,
  ContentLanguage, Default, DelayItemLoading, DisplayMode, Fill, FocusedBorderColor, FocusedBorderThickness, Height,
  Items, LoadingSpinner, LoadingSpinnerColor, NavigationStep, Selectable, ShowNavigation, ShowScrollbar, TabIndex,
  TemplatePadding, TemplateSize, Transition, Visible, Width, WrapCount, X, Y, AlignInContainer, FillPortions,
  LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth. Outputs: TemplateWidth, TemplateHeight.
- **ModernTextInput** (`Control: ModernTextInput`): AccessibleLabel, Align, Appearance, BasePaletteColor, BorderColor,
  BorderStyle, BorderThickness, Color, ContentLanguage, Default, DisplayMode, Fill, Font, FontWeight, Height, Italic,
  MaxLength, OnChange, Padding*, Placeholder, Radius*, Required, Size, Strikethrough, TriggerOutput, Type, Underline,
  ValidationState, Visible, Width, X, Y, AlignInContainer, FillPortions, LayoutMinHeight, LayoutMinWidth. Output Text.
  Enums: `Appearance: =Appearance.Outline`, `Type: =TextInputType.Search|SingleLine`,
  `TriggerOutput: =TriggerOutput.Delayed|Keypress`.
- **ModernRadio** (`Control: ModernRadio`): AccessibleLabel, BasePaletteColor, BorderColor, BorderStyle,
  BorderThickness, Color, ContentLanguage, Default, DisabledColor, DisplayMode, Fill, Font, FontWeight, Height,
  Italic, ItemDisplayText, Items, Layout, LineHeight, OnChange, Padding*, RadioBackgroundFill, RadioBorderColor,
  RadioSelectionFill, RadioSize, Radius*, Required, Size, Strikethrough, Underline, Visible, Width, X, Y,
  AlignInContainer, FillPortions, LayoutMinHeight, LayoutMinWidth. Output Selected (`.Value` for a text list).
  Enum: `Layout: =OptionLayout.Horizontal`.
- **ModernToggle** (`Control: ModernToggle`): AccessibleLabel, BasePaletteColor, Color, ContentLanguage, Default,
  DisplayMode, Font, FontWeight, Height, Italic, Label, LabelPosition, OnCheck, OnUncheck, Size, Strikethrough,
  ToggleSize, Tooltip, Underline, Visible, Width, X, Y, AlignInContainer, FillPortions, LayoutMinHeight,
  LayoutMinWidth. Output Checked.
