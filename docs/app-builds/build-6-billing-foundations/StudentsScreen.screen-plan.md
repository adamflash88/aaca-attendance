# Screen Plan: Student billing setup

## Assignment

- Action: Create
- Target file: `C:\src\aaca-attendance\billing-app\StudentsScreen.pa.yaml`
- YAML key: StudentsScreen
- Control name prefix: Stu
- Read with: `canvas-app-shared.md` (palette, visual contract, header/gate/engine/receipt/mutation/audit patterns,
  collection formulas, derived predicates, YAML rules).

## Specification

- Purpose: per-student billing setup. Students are read-only here. Finance maintains Districts of Record (who pays
  school days) and Student Services (one RDS grid line per row). Largest screen (~126 controls); keep formulas exactly
  as given and put long logic in the Save/Confirm buttons themselves (each is called from one place only).
- Shorthand used below: `<stu>` = `LookUp(colStudents, StudentId = varStuSelId)`;
  `<isSchool>` = `LookUp(colStudents, StudentId = varStuSelId).TypeText <> "Regional Center Only"`;
  `<RH(v)>` = `16 + Max(44, 18 * RoundUp(Len(v.Msg) / 45, 0) + 8)`; `<curDor(id)>` =
  `StartDate <= Today() && (IsBlank(EndDate) || EndDate >= Today())` with `StudentId = id`.
  Write the expanded formulas, never the shorthand.
- Screen properties: `Fill: =ColorPaper`; `OnVisible` (|- block):
  `=Set(varStuSelId, Blank()); Set(varStuDorMode, ""); Set(varStuSsMode, ""); Set(varStuDorEditId, Blank()); Set(varStuSsEditId, Blank()); Set(varStuDorDelId, Blank()); Set(varStuSsDelId, Blank()); Set(varStuDorReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Set(varStuSsReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Reset(txtStuSearch); Select(btnStuLoadEngine)`
  (varStuType / varStuNoDor / varStuStatus are not reset — Home sets them).
- Layout. Screen `Children:` = only `conStuRoot`. Root children in order:
  1. `conStuHeader` (shared; `btnStuNavStudents` current).
  2. `conStuGate` (shared; `lblStuGateTitle`, `lblStuGateBody`).
  3. `conStuBody` — shared list+detail body, `Visible: =IsFinance`, `FillPortions: =0`,
     `Height: =If(conStuRoot.Width >= 1024, Max(conStuListPanel.Height, conStuRight.Height), If(IsBlank(varStuSelId), conStuListPanel.Height, conStuRight.Height))`.
     a. `conStuListPanel` — white panel, Vertical, Stretch, padding 16, gap 8, two-panel FillPortions/Align rule,
        `Visible: =!(conStuRoot.Width < 1024 && !IsBlank(varStuSelId))`,
        `Height: =694 + conStuChips.Height + conStuStatusRow.Height`. Children:
        - `conStuListHead` H44: `lblStuListTitle` "Student billing setup" (18 Bold, FillPortions 1, Wrap false);
          `btnStuReload` Secondary "Reload" W88 (`Select(btnStuLoadEngine)`, Disabled while varStuLoading).
        - `lblStuSearch` "Search name or student key" (field label H18) / `txtStuSearch` (H36, Outline, Search,
          Delayed, Placeholder "e.g. Garcia or CW-1083").
        - `conStuChips` Horizontal, LayoutWrap, gap 8,
          `Height: =If(conStuListPanel.Width - 32 >= 542, 44, conStuListPanel.Width - 32 >= 344, 96, 148)`:
          `btnStuChipAll` "All" W64 (`varStuType = "All"`); `btnStuChipSchool` "School" W84 (`"School"`);
          `btnStuChipRc` "Regional Center Only" W180 (`"Regional Center Only"`); `btnStuChipNoDor` "No district of record"
          W190 (active `varStuNoDor`; `OnSelect: =With({next: !varStuNoDor}, Set(varStuNoDor, next))`).
        - `conStuStatusRow` Horizontal, LayoutWrap, gap 8, Center, `Height: =If(conStuListPanel.Width - 32 >= 396, 44, 96)`:
          `lblStuStatus` "Status" (field label, W52, H18, Wrap false); `btnStuStatusActive` chip "Active" W80
          (active `varStuStatus = "Active"`, `Set(varStuStatus, "Active")`); `btnStuStatusAll` chip "All statuses" W120
          (`Set(varStuStatus, "All")`); `btnStuClear` Secondary "Clear filters" W120:
          `=Set(varStuType, "All"); Set(varStuNoDor, false); Set(varStuStatus, "Active"); Reset(txtStuSearch)`.
        - `lblStuCount` (12, H36, wraps): `With({n: CountRows(<Items Filter>), m: CountRows(colStudents)}, If(varStuLoading, "Loading students...", varStuLoadError <> "", "Could not load students - " & varStuLoadError, n = 0, "No students match these filters. Use Clear filters to see all.", "Showing " & n & " of " & m & " students"))`.
        - `galStuList` Height 480 (contract below).
     b. `conStuRight` — Vertical, gap 12, Stretch, two-panel FillPortions/Align rule,
        `Visible: =!IsBlank(varStuSelId) || conStuRoot.Width >= 1024`, Height (|- block):
        `=If(IsBlank(varStuSelId), If(conStuRoot.Width >= 1024, 72, 0), 96 + 12 + conStuDor.Height + If(varStuDorMode <> "" && <isSchool>, 12 + 450, 0) + 12 + conStuSs.Height + If(varStuSsMode <> "", 12 + 748, 0))`.
        Children in order:
        - `conStuPlaceholder` (white, H72, `Visible: =IsBlank(varStuSelId)`): `lblStuPlaceholder` "Select Open on a student to see their district of record and service rows."
        - `conStuHead` (white panel, padding 12/16, gap 8, Vertical, H96, `Visible: =!IsBlank(varStuSelId)`):
          `conStuHeadTop` H44: `lblStuHeadName` (18 Bold, FillPortions 1, Wrap false, `=<stu>.StudentKey & " - " & <stu>.DisplayName`),
          `btnStuBack` Secondary "Back to list" W120 (`Visible: =conStuRoot.Width < 1024`,
          `OnSelect: =Set(varStuSelId, Blank()); Set(varStuDorMode, ""); Set(varStuSsMode, "")`);
          `lblStuHeadMeta` (12 muted, H20, Wrap false): `="Type " & <stu>.TypeText & " · Status " & <stu>.StatusText & " · student details are read-only here"`.
        - `conStuDor` (white panel, padding 16, gap 6, Vertical, `Visible: =!IsBlank(varStuSelId)`), Height (|-):
          `=32 + 44 + 6 + 36 + If(<isSchool>, 6 + 20 + 6 + 300, 0) + If(varStuDorReceipt.Kind <> "", 6 + <RH(varStuDorReceipt)>, 0) + If(!IsBlank(varStuDorDelId), 6 + 56, 0)`.
          Children in order: `conStuDorReceipt` (shared strip: `lblStuDorReceipt`, `btnStuDorReceiptDismiss`);
          `conStuDorHead` H44: `lblStuDorTitle` "Districts of record" (16 Bold, FillPortions 1), `btnStuDorAdd` Primary
          "Add district" W130 (`Visible: =<isSchool>`; OnSelect (|-) `=Set(varStuDorMode, "new"); Set(varStuDorEditId, Blank()); Set(varStuDorDelId, Blank()); Set(varStuDorReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Select(btnStuDorResetEngine)`);
          `lblStuDorCaption` (12 muted, H36, wraps): `=If(<isSchool>, "The district of record pays for school days. Rows may not overlap; a blank end date means ongoing.", "Regional Center Only students have no district of record. Regional Center billing uses the funder on each service row.")`;
          `conStuDorConfirm` (H56, ColorWarnBg, `Visible: =!IsBlank(varStuDorDelId)`): `lblStuDorConfirm`
          `=With({r: LookUp(colDor, DorId = varStuDorDelId)}, "Delete district of record " & LookUp(colFunders, FunderId = r.FunderId).Abbr & " from " & Text(r.StartDate, "mmm d, yyyy") & "?")`,
          `btnStuDorConfirmYes` destructive "Delete" W96, `btnStuDorConfirmNo` Secondary "Keep" W80 (`Set(varStuDorDelId, Blank())`);
          `lblStuDorCount` (12 muted, H20, `Visible: =<isSchool>`): `=With({n: CountRows(Filter(colDor, StudentId = varStuSelId))}, If(n = 0, "No district of record yet.", n & If(n = 1, " row", " rows")))`;
          `galStuDor` (H300, `Visible: =<isSchool>`, contract below).
        - `conStuDorForm` (white panel, padding 16, gap 6, Vertical, H450,
          `Visible: =!IsBlank(varStuSelId) && varStuDorMode <> "" && <isSchool>`). Children: `lblStuDorFormTitle`
          (16 Bold, H24, Wrap false) `=If(varStuDorMode = "new", "Add district of record", "Edit district of record") & If(LookUp(colDor, DorId = varStuDorEditId).SourceText = "CodeMetro", " (CodeMetro row; saving makes it Manual)", "")`;
          `lblStuDorFunder` "District (required)" / `ddStuDorFunder` (H36, Outline,
          Items |- `=With({cur: LookUp(colDor, DorId = varStuDorEditId).FunderId}, Sort(Filter(colFunders, (IsActive && TypeText = "District") || FunderId = cur), Abbr))`,
          `ItemDisplayText: =ThisItem.Abbr & " - " & ThisItem.FullName`,
          `Default: =LookUp(colFunders, FunderId = LookUp(colDor, DorId = varStuDorEditId).FunderId)`);
          `lblStuDorStart` "Start date (required)" / `dpStuDorStart` (H36, Outline, `Format: =DatePickerFormat.Short`,
          `DefaultDate: =LookUp(colDor, DorId = varStuDorEditId).StartDate`);
          `lblStuDorEnd` "End date" / `dpStuDorEnd` (same, `DefaultDate: =LookUp(colDor, DorId = varStuDorEditId).EndDate`,
          `DisplayMode: =If(chkStuDorOngoing.Checked, DisplayMode.Disabled, DisplayMode.Edit)`);
          `chkStuDorOngoing` ModernCheckbox (H32, Label "Ongoing (no end date)",
          `Default: =If(IsBlank(varStuDorEditId), true, IsBlank(LookUp(colDor, DorId = varStuDorEditId).EndDate))`);
          `lblStuDorNote` "Note" / `txtStuDorNote` (H36, `Default: =LookUp(colDor, DorId = varStuDorEditId).Note`);
          `lblStuDorValidation` (13, H36, wraps; formula below; teal when ready else ColorUnexcused);
          `conStuDorActions` H44: `btnStuDorSave` Primary "Save" W100; `btnStuDorCancel` Secondary "Cancel" W100
          (`=Set(varStuDorMode, ""); Set(varStuDorEditId, Blank())`).
        - `conStuSs` (white panel, padding 16, gap 6, Vertical, `Visible: =!IsBlank(varStuSelId)`), Height (|-):
          `=32 + 44 + 6 + 36 + 6 + 20 + 6 + 432 + If(varStuSsReceipt.Kind <> "", 6 + <RH(varStuSsReceipt)>, 0) + If(!IsBlank(varStuSsDelId), 6 + 56, 0)`.
          Children in order: `conStuSsReceipt` (strip: `lblStuSsReceipt`, `btnStuSsReceiptDismiss`);
          `conStuSsHead` H44: `lblStuSsTitle` "Student services" (16 Bold, FillPortions 1), `btnStuSsAdd` Primary
          "Add service row" W150 (|- `=Set(varStuSsMode, "new"); Set(varStuSsEditId, Blank()); Set(varStuSsDelId, Blank()); Set(varStuSsReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Select(btnStuSsResetEngine)`);
          `lblStuSsCaption` (12 muted, H36, wraps) |- `="Each row is one line on the RDS grid; a 2:1 aide is two rows."`;
          `conStuSsConfirm` (H56, ColorWarnBg, `Visible: =!IsBlank(varStuSsDelId)`): `lblStuSsConfirm`
          `="Delete service row " & LookUp(colStuSvc, SsId = varStuSsDelId).Summary & "?"`, `btnStuSsConfirmYes`
          destructive "Delete" W96, `btnStuSsConfirmNo` Secondary "Keep" W80 (`Set(varStuSsDelId, Blank())`);
          `lblStuSsCount` (12 muted, H20): `=With({n: CountRows(Filter(colStuSvc, StudentId = varStuSelId))}, If(n = 0, "No service rows yet.", n & If(n = 1, " row", " rows")))`;
          `galStuSs` (H432, contract below).
        - `conStuSsForm` (white panel, padding 16, gap 6, Vertical, H748,
          `Visible: =!IsBlank(varStuSelId) && varStuSsMode <> ""`). `<isCm>` below =
          `varStuSsMode = "edit" && LookUp(colStuSvc, SsId = varStuSsEditId).SourceText = "CodeMetro"`;
          `<cur>` = `LookUp(colStuSvc, SsId = varStuSsEditId)`. Children:
          `lblStuSsFormTitle` (16 Bold, H24, Wrap false) `=If(varStuSsMode = "new", "Add service row", <isCm>, "Edit CodeMetro row (only Excluded and Note can change)", "Edit service row")`;
          `lblStuSsService` "Service (required)" / `ddStuSsService` (Items |-
          `=With({cur: LookUp(colStuSvc, SsId = varStuSsEditId).ServiceId}, Sort(Filter(colServices, (IsActive && KindText = "School Day" && Upper(Code) <> "SPED") || ServiceId = cur), Coalesce(SortNum, 9999)))`,
          `ItemDisplayText: =ThisItem.Code & " - " & ThisItem.Name`, `Default: =LookUp(colServices, ServiceId = <cur>.ServiceId)`,
          `DisplayMode: =If(<isCm>, DisplayMode.View, DisplayMode.Edit)`);
          `lblStuSsFunder` "Funder (required)" / `ddStuSsFunder` (Items |-
          `=With({cur: LookUp(colStuSvc, SsId = varStuSsEditId).FunderId}, Sort(Filter(colFunders, IsActive || FunderId = cur), Abbr))`,
          display `ThisItem.Abbr & " - " & ThisItem.FullName`, `Default: =LookUp(colFunders, FunderId = <cur>.FunderId)`, View when <isCm>);
          `lblStuSsStart` "Start date (required)" / `dpStuSsStart` (`DefaultDate: =<cur>.StartDate`, View when <isCm>);
          `lblStuSsEnd` "End date" / `dpStuSsEnd` (`DefaultDate: =<cur>.EndDate`, `DisplayMode: =If(<isCm>, DisplayMode.View, chkStuSsOngoing.Checked, DisplayMode.Disabled, DisplayMode.Edit)`);
          `chkStuSsOngoing` (Label "Ongoing (no end date)", `Default: =If(IsBlank(varStuSsEditId), true, IsBlank(<cur>.EndDate))`, View when <isCm>);
          `lblStuSsFreq` "Frequency" / `txtStuSsFreq` (`Default: =<cur>.Frequency`, Placeholder "e.g. Daily", View when <isCm>);
          `lblStuSsMin` "Minutes per frequency" / `txtStuSsMin` (`Default: =With({m: <cur>.Minutes}, If(IsBlank(m), "", Text(m)))`, View when <isCm>);
          `tglStuSsEsy` (Label "ESY (extended school year)", W260, H44, `Default: =If(IsBlank(varStuSsEditId), false, <cur>.IsEsy)`, View when <isCm>);
          `tglStuSsExcluded` (Label "Excluded from billing", W260, H44, `Default: =If(IsBlank(varStuSsEditId), false, <cur>.IsExcluded)`, always Edit);
          `lblStuSsNote` "Note" / `txtStuSsNote` (`Default: =<cur>.Note`, always Edit);
          `lblStuSsValidation` (13, H36, wraps; formula below);
          `conStuSsActions` H44: `btnStuSsSave` Primary "Save" W100; `btnStuSsCancel` Secondary "Cancel" W100
          (`=Set(varStuSsMode, ""); Set(varStuSsEditId, Blank())`).
  4. `btnStuLoadEngine` hidden: non-finance `Clear(colStudents); Clear(colDor); Clear(colStuSvc); Clear(colFunders); Clear(colServices)`;
     success `Refresh(Students); Refresh('Districts of Record'); Refresh('Student Services'); Refresh(Funders); Refresh(Services); Concurrent(<colStudents>, <colDor>, <colStuSvc>, <colFunders>, <colServices> — all verbatim); true`.
  5. `btnStuDorResetEngine` hidden: `=Reset(ddStuDorFunder); Reset(dpStuDorStart); Reset(dpStuDorEnd); Reset(chkStuDorOngoing); Reset(txtStuDorNote)`.
  6. `btnStuSsResetEngine` hidden: `=Reset(ddStuSsService); Reset(ddStuSsFunder); Reset(dpStuSsStart); Reset(dpStuSsEnd); Reset(chkStuSsOngoing); Reset(txtStuSsFreq); Reset(txtStuSsMin); Reset(tglStuSsEsy); Reset(tglStuSsExcluded); Reset(txtStuSsNote)`.

- Gallery `galStuList`: Vertical, H480, TemplateSize 100, TemplatePadding 0, TabIndex 0, Selectable false. Items (|-):

```
=Sort(
    Filter(
        colStudents As s,
        (varStuStatus = "All" || s.StatusText = "Active") &&
        (varStuType = "All" || s.TypeText = varStuType) &&
        (!varStuNoDor || (s.TypeText = "School" && CountIf(colDor, StudentId = s.StudentId && StartDate <= Today() && (IsBlank(EndDate) || EndDate >= Today())) = 0)) &&
        (Trim(txtStuSearch.Text) = "" || Lower(Trim(txtStuSearch.Text)) in Lower(s.DisplayName & " " & s.StudentKey))
    ),
    DisplayName,
    SortOrder.Ascending
)
```

  Row shell `conStuRow` (Vertical, padding 8, gap 2, border rule, `Fill: =If(ThisItem.StudentId = varStuSelId, ColorInfoBg, ColorWhite)`):
  - `conStuRowTop` H44: `lblStuRowName` (14 Semibold, FillPortions 1, H24, Wrap false, `=ThisItem.StudentKey & " - " & ThisItem.DisplayName`);
    `btnStuRowOpen` Secondary "Open" W72, OnSelect (|-)
    `=Set(varStuSelId, ThisItem.StudentId); Set(varStuDorMode, ""); Set(varStuSsMode, ""); Set(varStuDorEditId, Blank()); Set(varStuSsEditId, Blank()); Set(varStuDorDelId, Blank()); Set(varStuSsDelId, Blank()); Set(varStuDorReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Set(varStuSsReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid})`.
  - `lblStuRowMeta` (12, H36, wraps, Top). Text (|-):

```
=With(
    {
        d: First(Filter(colDor, StudentId = ThisItem.StudentId && StartDate <= Today() && (IsBlank(EndDate) || EndDate >= Today()))),
        k: CountIf(colStuSvc, StudentId = ThisItem.StudentId && !IsExcluded && StartDate <= Today() && (IsBlank(EndDate) || EndDate >= Today()))
    },
    ThisItem.TypeText & If(ThisItem.StatusText = "Active", "", " · " & ThisItem.StatusText) & " · " &
    If(ThisItem.TypeText = "Regional Center Only", "No district needed", IsBlank(d), "No district of record", "District " & LookUp(colFunders, FunderId = d.FunderId).Abbr) &
    " · " & k & If(k = 1, " active day service", " active day services")
)
```

    `Color: =If(ThisItem.TypeText = "School" && CountIf(colDor, StudentId = ThisItem.StudentId && StartDate <= Today() && (IsBlank(EndDate) || EndDate >= Today())) = 0, ColorWarnInk, ColorInk)`.
  Row budget: 8 + 44 + 2 + 36 + 8 = 98 <= 100.

- Gallery `galStuDor`: Vertical, H300, TemplateSize 100, Items `=Sort(Filter(colDor, StudentId = varStuSelId), StartDate, SortOrder.Descending)`.
  Shell `conStuDorRow` (Vertical, padding 8, gap 2, border rule,
  `Fill: =If(ThisItem.StartDate <= Today() && (IsBlank(ThisItem.EndDate) || ThisItem.EndDate >= Today()), ColorInfoBg, ColorWhite)`):
  - `conStuDorRowTop` H44: `lblStuDorRowMain` (14 Semibold, FillPortions 1, H40, wraps)
    `=LookUp(colFunders, FunderId = ThisItem.FunderId).Abbr & " · " & Text(ThisItem.StartDate, "mmm d, yyyy") & " to " & If(IsBlank(ThisItem.EndDate), "ongoing", Text(ThisItem.EndDate, "mmm d, yyyy"))`;
    `btnStuDorRowEdit` Secondary "Edit" W72 (|- `=Set(varStuDorMode, "edit"); Set(varStuDorEditId, ThisItem.DorId); Set(varStuDorDelId, Blank()); Set(varStuDorReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Select(btnStuDorResetEngine)`);
    `btnStuDorRowDelete` Secondary "Delete" W80 (`Visible: =ThisItem.SourceText = "Manual"`, `OnSelect: =Set(varStuDorDelId, ThisItem.DorId)`).
  - `lblStuDorRowMeta` (12 muted, H36, wraps): `="Source " & ThisItem.SourceText & If(ThisItem.Note = "", "", " · Note " & ThisItem.Note)`.
  Budget 8 + 44 + 2 + 36 + 8 = 98 <= 100.

- Gallery `galStuSs`: Vertical, H432, TemplateSize 144. Items (|-):
  `=Sort(Filter(colStuSvc, StudentId = varStuSelId), SvcSort * 100000 + DateDiff(Date(2000, 1, 1), StartDate, TimeUnit.Days), SortOrder.Ascending)`.
  Shell `conStuSsRow` (Vertical, padding 8, gap 2, border rule, `Fill: =If(ThisItem.IsExcluded, ColorNotEnrolled, ColorWhite)`):
  - `conStuSsRowTop` H44, Center: `lblStuSsRowMain` (14 Semibold, FillPortions 1, H40, wraps,
    `Color: =If(ThisItem.IsExcluded, ColorMuted, ColorInk)`,
    `=With({sv: LookUp(colServices, ServiceId = ThisItem.ServiceId)}, sv.Code & " - " & sv.Name)`);
    `badStuSsExcluded` Badge (`Content: ="Excluded"`, W84, H24, FillPortions 0, AlignInContainer Center,
    `Appearance: ='BadgeCanvas.Appearance'.Tint`, `ThemeColor: ='BadgeCanvas.ThemeColor'.Subtle`,
    `Shape: ='BadgeCanvas.Shape'.Rounded`, `FontColor: =ColorInk`, `Visible: =ThisItem.IsExcluded`,
    AccessibleLabel "Excluded from billing").
  - `lblStuSsRowDates` (12, H36, wraps; muted when excluded) (|-):
    `="Funder " & LookUp(colFunders, FunderId = ThisItem.FunderId).Abbr & " · " & Text(ThisItem.StartDate, "mmm d, yyyy") & " to " & If(IsBlank(ThisItem.EndDate), "ongoing", Text(ThisItem.EndDate, "mmm d, yyyy")) & " · Frequency " & If(ThisItem.Frequency = "", "not set", ThisItem.Frequency) & " · " & If(IsBlank(ThisItem.Minutes), "minutes not set", ThisItem.Minutes & " min per frequency") & " · ESY " & If(ThisItem.IsEsy, "Yes", "No")`
  - `conStuSsRowActions` H44, Center: `lblStuSsRowMeta` (12 muted, FillPortions 1, H40, wraps)
    `="Source " & ThisItem.SourceText & If(ThisItem.Note = "", "", " · Note " & ThisItem.Note)`;
    `btnStuSsRowEdit` Secondary "Edit" W72 (|- `=Set(varStuSsMode, "edit"); Set(varStuSsEditId, ThisItem.SsId); Set(varStuSsDelId, Blank()); Set(varStuSsReceipt, {Kind: "", Msg: "", RecordId: ZeroGuid}); Select(btnStuSsResetEngine)`);
    `btnStuSsRowDelete` Secondary "Delete" W80 (`Visible: =ThisItem.SourceText = "Manual"`, `OnSelect: =Set(varStuSsDelId, ThisItem.SsId)`).
  Budget 8 + 44 + 2 + 36 + 2 + 44 + 8 = 144.

- `lblStuDorValidation.Text` (|-):

```
=With(
    {
        s: dpStuDorStart.SelectedDate,
        e: If(chkStuDorOngoing.Checked, FarFuture, Coalesce(dpStuDorEnd.SelectedDate, FarFuture)),
        editId: Coalesce(varStuDorEditId, ZeroGuid)
    },
    With(
        {clash: First(Filter(colDor, StudentId = varStuSelId && DorId <> editId && StartDate <= e && Coalesce(EndDate, FarFuture) >= s))},
        If(
            IsBlank(ddStuDorFunder.Selected), "Choose a district.",
            IsBlank(s), "Start date is required.",
            !chkStuDorOngoing.Checked && IsBlank(dpStuDorEnd.SelectedDate), "Pick an end date or tick Ongoing.",
            e < s, "End date must be on or after the start date.",
            !IsBlank(clash), "Overlaps " & LookUp(colFunders, FunderId = clash.FunderId).Abbr & " " & Text(clash.StartDate, "mmm d, yyyy") & " to " & If(IsBlank(clash.EndDate), "ongoing", Text(clash.EndDate, "mmm d, yyyy")) & ". Change the dates or end that row first.",
            "Ready to save."
        )
    )
)
```

- `lblStuSsValidation.Text` (|-):

```
=With(
    {
        isCm: varStuSsMode = "edit" && LookUp(colStuSvc, SsId = varStuSsEditId).SourceText = "CodeMetro",
        s: dpStuSsStart.SelectedDate,
        inMin: Trim(txtStuSsMin.Text)
    },
    If(
        isCm, "Ready to save.",
        IsBlank(ddStuSsService.Selected), "Choose a service.",
        IsBlank(ddStuSsFunder.Selected), "Choose a funder.",
        IsBlank(s), "Start date is required.",
        !chkStuSsOngoing.Checked && IsBlank(dpStuSsEnd.SelectedDate), "Pick an end date or tick Ongoing.",
        !chkStuSsOngoing.Checked && dpStuSsEnd.SelectedDate < s, "End date must be on or after the start date.",
        inMin <> "" && (!IsNumeric(inMin) || Value(inMin) < 0), "Minutes must be a number 0 or more.",
        "Ready to save."
    )
)
```

### `btnStuDorSave.OnSelect` (|-) — `DisplayMode: =If(varStuSaving || lblStuDorValidation.Text <> "Ready to save.", DisplayMode.Disabled, DisplayMode.Edit)`

```
=If(
    lblStuDorValidation.Text = "Ready to save." && !varStuSaving && IsFinance,
    Set(varStuSaving, true);
    Set(varStuErr, "");
    With(
        {
            editId: varStuDorEditId,
            idx: Coalesce(varStuDorEditId, ZeroGuid),
            old: LookUp(colDor, DorId = varStuDorEditId),
            sid: varStuSelId,
            stu: LookUp(colStudents, StudentId = varStuSelId),
            fid: ddStuDorFunder.Selected.FunderId,
            fAbbr: ddStuDorFunder.Selected.Abbr,
            s: dpStuDorStart.SelectedDate,
            e: If(chkStuDorOngoing.Checked, Blank(), dpStuDorEnd.SelectedDate),
            note: Trim(txtStuDorNote.Text)
        },
        IfError(
            Set(varStuLastDor, If(
                IsBlank(editId),
                Patch('Districts of Record', Defaults('Districts of Record'), {Summary: stu.StudentKey & " - " & fAbbr, Student: LookUp(Students, Student = sid), Funder: LookUp(Funders, Funder = fid), 'Start Date': s, 'End Date': e, Source: 'Source (Districts of Record)'.Manual, Note: note}),
                Patch('Districts of Record', LookUp('Districts of Record', 'District of Record' = idx), {Summary: stu.StudentKey & " - " & fAbbr, Funder: LookUp(Funders, Funder = fid), 'Start Date': s, 'End Date': e, Source: 'Source (Districts of Record)'.Manual, Note: note})
            ));
            true,
            Set(varStuErr, FirstError.Message);
            false
        );
        If(
            varStuErr <> "",
            Set(varStuDorReceipt, {Kind: "Failed", Msg: "District of record not saved. " & varStuErr, RecordId: idx}),
            IfError(
                Patch('Audit Events', Defaults('Audit Events'), {Summary: Left(If(IsBlank(editId), "Create", "Update") & " Districts of Record " & stu.StudentKey & " - " & fAbbr, 100), Action: If(IsBlank(editId), 'Action (Audit Events)'.Create, 'Action (Audit Events)'.Update), Entity: "Districts of Record", 'Entity ID': Text(varStuLastDor.'District of Record'), Before: If(IsBlank(editId), "", JSON({Funder: LookUp(colFunders, FunderId = old.FunderId).Abbr, StartDate: old.StartDate, EndDate: old.EndDate, Source: old.SourceText, Note: old.Note})), After: JSON({Student: stu.StudentKey, Funder: fAbbr, StartDate: s, EndDate: e, Source: "Manual", Note: note}), Reason: "District of record saved in AACA Billing"});
                Set(varStuAuditOk, true),
                Set(varStuAuditOk, false)
            );
            Set(varStuDorReceipt, {Kind: If(IsBlank(editId), "Created", "Updated"), Msg: If(IsBlank(editId), "Created", "Updated") & " district of record. Student " & stu.StudentKey & " | District " & fAbbr & " | Start " & Text(varStuLastDor.'Start Date', "mmm d, yyyy") & " | End " & If(IsBlank(varStuLastDor.'End Date'), "ongoing", Text(varStuLastDor.'End Date', "mmm d, yyyy")) & " | Source " & If(IsBlank(editId), "", old.SourceText & " -> ") & Text(varStuLastDor.Source) & " | Note " & Coalesce(varStuLastDor.Note, "none") & " | Audit " & If(varStuAuditOk, "written", "FAILED - tell Adam"), RecordId: varStuLastDor.'District of Record'});
            Set(varStuDorMode, "");
            Set(varStuDorEditId, Blank());
            Select(btnStuLoadEngine)
        )
    );
    Set(varStuSaving, false)
)
```

### `btnStuDorConfirmYes.OnSelect` (|-)

`With({snap: LookUp(colDor, DorId = varStuDorDelId)}, With({hid: snap.DorId, fAbbr: LookUp(colFunders, FunderId = snap.FunderId).Abbr}, If(!IsBlank(hid) && snap.SourceText = "Manual" && !varStuSaving && IsFinance, <skeleton>)))`.
Mutation `IfError(Remove('Districts of Record', LookUp('Districts of Record', 'District of Record' = hid)); true, Set(varStuErr, FirstError.Message); false)`.
Audit `'Soft Delete'`, Entity "Districts of Record", 'Entity ID' `Text(hid)`, Before
`JSON({Student: <stu>.StudentKey, Funder: fAbbr, StartDate: snap.StartDate, EndDate: snap.EndDate, Source: snap.SourceText, Note: snap.Note})`,
After "", Reason "District of record removed (row deleted)". Receipt Kind "Deleted", Msg
`"Deleted district of record " & fAbbr & " " & Text(snap.StartDate, "mmm d, yyyy") & " to " & If(IsBlank(snap.EndDate), "ongoing", Text(snap.EndDate, "mmm d, yyyy")) & ". | Audit " & ...`.
Success: `Set(varStuDorDelId, Blank()); Select(btnStuLoadEngine)`. Failure Msg "District of record not deleted. " & varStuErr.

### `btnStuSsSave.OnSelect` (|-) — DisplayMode as DoR Save with `lblStuSsValidation`

```
=If(
    lblStuSsValidation.Text = "Ready to save." && !varStuSaving && IsFinance,
    Set(varStuSaving, true);
    Set(varStuErr, "");
    With(
        {
            editId: varStuSsEditId,
            idx: Coalesce(varStuSsEditId, ZeroGuid),
            old: LookUp(colStuSvc, SsId = varStuSsEditId),
            sid: varStuSelId,
            stu: LookUp(colStudents, StudentId = varStuSelId),
            svId: ddStuSsService.Selected.ServiceId,
            svCode: ddStuSsService.Selected.Code,
            fId: ddStuSsFunder.Selected.FunderId,
            fAbbr: ddStuSsFunder.Selected.Abbr,
            s: dpStuSsStart.SelectedDate,
            e: If(chkStuSsOngoing.Checked, Blank(), dpStuSsEnd.SelectedDate),
            freq: Trim(txtStuSsFreq.Text),
            inMin: Trim(txtStuSsMin.Text),
            esy: tglStuSsEsy.Checked,
            ex: tglStuSsExcluded.Checked,
            note: Trim(txtStuSsNote.Text)
        },
        With(
            {
                isCm: !IsBlank(editId) && old.SourceText = "CodeMetro",
                minVal: If(inMin = "", Blank(), Value(inMin)),
                n: CountIf(colStuSvc, StudentId = sid && ServiceId = svId && SsId <> idx) + 1,
                op: If(IsBlank(editId), If(ex, "New row, excluded", "New row"), !old.IsExcluded && ex, "Excluded", old.IsExcluded && !ex, "Included", "No change")
            },
            With(
                {summ: If(!IsBlank(editId) && svId = old.ServiceId && fId = old.FunderId, old.Summary, stu.StudentKey & " - " & svCode & If(n > 1, " #" & n, "") & " - " & fAbbr)},
                IfError(
                    Set(varStuLastSs, If(
                        IsBlank(editId),
                        Patch('Student Services', Defaults('Student Services'), {Summary: summ, Student: LookUp(Students, Student = sid), Service: LookUp(Services, Service = svId), Funder: LookUp(Funders, Funder = fId), 'Start Date': s, 'End Date': e, Frequency: freq, 'Minutes per Frequency': minVal, ESY: esy, Excluded: ex, Source: 'Source (Student Services)'.Manual, Note: note}),
                        isCm,
                        Patch('Student Services', LookUp('Student Services', 'Student Service' = idx), {Excluded: ex, Note: note}),
                        Patch('Student Services', LookUp('Student Services', 'Student Service' = idx), {Summary: summ, Service: LookUp(Services, Service = svId), Funder: LookUp(Funders, Funder = fId), 'Start Date': s, 'End Date': e, Frequency: freq, 'Minutes per Frequency': minVal, ESY: esy, Excluded: ex, Note: note})
                    ));
                    true,
                    Set(varStuErr, FirstError.Message);
                    false
                );
                If(
                    varStuErr <> "",
                    Set(varStuSsReceipt, {Kind: "Failed", Msg: "Service row not saved. " & varStuErr, RecordId: idx}),
                    IfError(
                        Patch('Audit Events', Defaults('Audit Events'), {Summary: Left(If(IsBlank(editId), "Create", "Update") & " Student Services " & varStuLastSs.Summary, 100), Action: If(IsBlank(editId), 'Action (Audit Events)'.Create, 'Action (Audit Events)'.Update), Entity: "Student Services", 'Entity ID': Text(varStuLastSs.'Student Service'), Before: If(IsBlank(editId), "", JSON({Summary: old.Summary, StartDate: old.StartDate, EndDate: old.EndDate, Frequency: old.Frequency, Minutes: old.Minutes, ESY: old.IsEsy, Excluded: old.IsExcluded, Note: old.Note})), After: If(isCm, JSON({Excluded: ex, Note: note}), JSON({Summary: summ, Service: svCode, Funder: fAbbr, StartDate: s, EndDate: e, Frequency: freq, Minutes: minVal, ESY: esy, Excluded: ex, Note: note})), Reason: "Student service saved in AACA Billing"});
                        Set(varStuAuditOk, true),
                        Set(varStuAuditOk, false)
                    );
                    Set(varStuSsReceipt, {Kind: If(IsBlank(editId), "Created", "Updated"), Msg: If(
                        isCm,
                        "Updated CodeMetro service row " & varStuLastSs.Summary & ". Excluded " & If(old.IsExcluded, "Yes", "No") & " -> " & If(varStuLastSs.Excluded, "Yes", "No") & " (" & op & ") | Note " & Coalesce(varStuLastSs.Note, "none") & " | Other fields unchanged (CodeMetro row)",
                        If(IsBlank(editId), "Created", "Updated") & " service row " & varStuLastSs.Summary & ". Service " & svCode & " | Funder " & fAbbr & " | Start " & Text(varStuLastSs.'Start Date', "mmm d, yyyy") & " | End " & If(IsBlank(varStuLastSs.'End Date'), "ongoing", Text(varStuLastSs.'End Date', "mmm d, yyyy")) & " | Frequency " & Coalesce(varStuLastSs.Frequency, "not set") & " | Minutes " & If(IsBlank(varStuLastSs.'Minutes per Frequency'), "not set", Text(varStuLastSs.'Minutes per Frequency')) & " | ESY " & If(varStuLastSs.ESY, "Yes", "No") & " | Excluded " & If(IsBlank(editId), "", If(old.IsExcluded, "Yes", "No") & " -> ") & If(varStuLastSs.Excluded, "Yes", "No") & " (" & op & ") | Source " & Text(varStuLastSs.Source) & " | Note " & Coalesce(varStuLastSs.Note, "none")
                    ) & " | Audit " & If(varStuAuditOk, "written", "FAILED - tell Adam"), RecordId: varStuLastSs.'Student Service'});
                    Set(varStuSsMode, "");
                    Set(varStuSsEditId, Blank());
                    Select(btnStuLoadEngine)
                )
            )
        )
    );
    Set(varStuSaving, false)
)
```

The literal `" #"` above is inside a `|-` block, so YAML does not treat it as a comment. Keep it there.

### `btnStuSsConfirmYes.OnSelect` (|-)

`With({snap: LookUp(colStuSvc, SsId = varStuSsDelId)}, With({hid: snap.SsId}, If(!IsBlank(hid) && snap.SourceText = "Manual" && !varStuSaving && IsFinance, <skeleton>)))`.
Mutation `Remove('Student Services', LookUp('Student Services', 'Student Service' = hid))`. Audit `'Soft Delete'`, Entity
"Student Services", Before `JSON({Summary: snap.Summary, Service: LookUp(colServices, ServiceId = snap.ServiceId).Code, Funder: LookUp(colFunders, FunderId = snap.FunderId).Abbr, StartDate: snap.StartDate, EndDate: snap.EndDate})`,
After "", Reason "Student service removed (row deleted)". Receipt Kind "Deleted", Msg
`"Deleted service row " & snap.Summary & " (start " & Text(snap.StartDate, "mmm d, yyyy") & "). | Audit " & ...`.
Success `Set(varStuSsDelId, Blank()); Select(btnStuLoadEngine)`. Failure Msg "Service row not deleted. " & varStuErr.

- Breakpoint source: `conStuRoot.Width` (two-panel >= 1024), `conStuListPanel.Width` for chip wrapping.
- Numeric layout budgets:
  - List panel: 32 + 44 + 18 + 36 + chips + status + 36 + 480 + 6 gaps x 8 = 694 + chips + status. At 1024 (inner 458):
    chips row 1 64+84+180+16 = 344, row 2 190 -> 96; status 52+80+120+120+24 = 396 <= 458 -> 44.
  - Head panel: 12 + 44 + 8 + 20 + 12 = 96.
  - DoR panel School: 32 + 44 + 6 + 36 + 6 + 20 + 6 + 300 = 450; RC: 118 (+ receipt + 62 confirm).
  - DoR form: 24 + 3 x 54 + 32 + 54 + 36 + 44 = 352; 11 gaps x 6 = 66; padding 32 -> 450.
  - SS panel: 32 + 44 + 6 + 36 + 6 + 20 + 6 + 432 = 582 (+ receipt + 62 confirm).
  - SS form: 24 + 7 x 54 + 32 + 44 + 44 + 36 + 44 = 602; 19 gaps x 6 = 114; padding 32 -> 748.
  - Row widths at inner 458 (gallery row ~426 after padding): DoR top 258 + 72 + 80 + 16; SS top 334 + 84 + 8;
    SS actions 258 + 72 + 80 + 16; Students top 346 + 72 + 8.
  - Receipt strips: longest SS Msg ~420 chars -> 10 lines -> 18 x 10 + 8 = 188 label, 204 strip.
- Text fit: `lblStuHeadName` keys like "CW-1083 - Garcia-Hernandez, Alexandra" ~40 chars at 18 Bold (~340 px) within 426;
  chips "Regional Center Only" (~150 px) W180, "No district of record" (~160 px) W190.
- Visual hierarchy: as shared; section titles 16 Bold; excluded rows muted with Badge.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| RF-STU-ID | list row | key + "Last, First" | StudentKey, DisplayName | `lblStuRowName` | `=ThisItem.StudentKey & " - " & ThisItem.DisplayName` | top line |
| RF-STU-META | list row | type, DoR abbr / warning, active day-service count | TypeText, colDor, colStuSvc | `lblStuRowMeta` | see gallery contract | second line; warning colour |
| RF-STU-HEAD | detail header | key, name, type, status | colStudents | `lblStuHeadName`, `lblStuHeadMeta` | see layout | top of detail |
| RF-DOR-ROW | DoR row | funder, start, end/ongoing, source, note | colDor + colFunders.Abbr | `lblStuDorRowMain`, `lblStuDorRowMeta` | see gallery contract | two lines |
| RF-SS-ROW | SS row | service, funder, start, end, frequency, minutes, ESY, source, Excluded, note | colStuSvc + lookups | `lblStuSsRowMain`, `lblStuSsRowDates`, `lblStuSsRowMeta`, `badStuSsExcluded` | see gallery contract | three lines + badge |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| SV-GATE | `conStuGate` | `=!IsFinance` | non-finance / finance |
| SV-BODY | `conStuBody`, `conStuNav` | `=IsFinance` | finance / non-finance |
| SV-STU-DETAIL | `conStuHead`, `conStuDor`, `conStuSs` | `=!IsBlank(varStuSelId)` | student open / none |
| SV-DOR-FORM | `conStuDorForm` | `=!IsBlank(varStuSelId) && varStuDorMode <> "" && LookUp(colStudents, StudentId = varStuSelId).TypeText <> "Regional Center Only"` | add/edit / closed |
| SV-SS-FORM | `conStuSsForm` | `=!IsBlank(varStuSelId) && varStuSsMode <> ""` | add/edit / closed |
| SV-DOR-CONFIRM / SV-SS-CONFIRM | `conStuDorConfirm` / `conStuSsConfirm` | `=!IsBlank(varStuDorDelId)` / `=!IsBlank(varStuSsDelId)` | delete pending |
| SV-RECEIPTS | `conStuDorReceipt`, `conStuSsReceipt` | `.Kind <> ""` | after mutation |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-STU-LOAD | IsFinance | OnVisible, `btnStuReload` | 5 tables | reload | N/A | N/A | `galStuList`, `lblStuCount` |
| A-STU-SEARCH / TYPE / NODOR / STATUS / CLEAR | loaded | `txtStuSearch`, chips, Clear | colStudents, colDor, globals | Items predicate | N/A | N/A | chips, count |
| A-STU-SELECT | row | `btnStuRowOpen` | StudentId | varStuSelId set; sub-states cleared | N/A | N/A | detail panels for that student |
| A-DOR-NEW / A-DOR-CANCEL | School student | `btnStuDorAdd` / `btnStuDorCancel` | none | form open / closed, no Patch | N/A | N/A | `conStuDorForm` |
| A-DOR-CREATE | valid | `btnStuDorSave` | Districts of Record; returned `.'District of Record'` | Manual row, Summary "<Key> - <Abbr>"; audit Create | Summary, Student, Funder, Start Date, End Date, Source, Note | student key, district, start, end, source, note, audit | `lblStuDorReceipt`; `galStuDor`; list meta |
| A-DOR-EDIT / A-DOR-END | valid; any source | row Edit -> Save | by varStuDorEditId | Source -> Manual; End set when ended; audit Update | Summary, Funder, Start Date, End Date, Source, Note | as create + "Source CodeMetro -> Manual" | receipt; row |
| A-DOR-DEL / DELCANCEL | Manual row | row Delete -> `btnStuDorConfirmYes` / `btnStuDorConfirmNo` | snapshot | Remove + audit Soft Delete / none | existence | district, dates, audit | receipt; row gone / kept |
| A-SS-NEW / A-SS-CANCEL | student open | `btnStuSsAdd` / `btnStuSsCancel` | none | form open/closed | N/A | N/A | `conStuSsForm` |
| A-SS-CREATE | valid | `btnStuSsSave` | Student Services; returned `.'Student Service'` | Manual row; Summary with " #n" when duplicate service | Summary, Student, Service, Funder, Start Date, End Date, Frequency, Minutes per Frequency, ESY, Excluded, Source, Note | summary, service, funder, start, end, frequency, minutes, ESY, excluded, source, note, audit | `lblStuSsReceipt`; `galStuSs` |
| A-SS-EDIT | Manual row | row Edit -> Save | by varStuSsEditId | updated (Student, Source preserved) | Summary, Service, Funder, Start Date, End Date, Frequency, Minutes per Frequency, ESY, Excluded, Note | same + Excluded before -> after | receipt; row |
| A-SS-CMEDIT / A-SS-EXCL / A-SS-INCL | CodeMetro (or any) row | row Edit -> `tglStuSsExcluded` / `txtStuSsNote` -> Save | by varStuSsEditId | CodeMetro: only Excluded + Note; op guards `!old.IsExcluded && ex` Excluded, `old.IsExcluded && !ex` Included | Excluded, Note | "Excluded No -> Yes (Excluded)", Note | badge, row muted, count |
| A-SS-DEL / DELCANCEL | Manual row | row Delete -> confirm Yes / No | snapshot | Remove + audit / none | existence | summary, start, audit | receipt; row |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| `txtStuSearch` | `lblStuSearch` "Search name or student key" | `conStuListPanel` |
| `ddStuDorFunder` | `lblStuDorFunder` "District (required)" | `conStuDorForm` |
| `dpStuDorStart` / `dpStuDorEnd` | `lblStuDorStart` "Start date (required)" / `lblStuDorEnd` "End date" | `conStuDorForm` |
| `txtStuDorNote` | `lblStuDorNote` "Note" | `conStuDorForm` |
| `ddStuSsService` | `lblStuSsService` "Service (required)" | `conStuSsForm` |
| `ddStuSsFunder` | `lblStuSsFunder` "Funder (required)" | `conStuSsForm` |
| `dpStuSsStart` / `dpStuSsEnd` | `lblStuSsStart` / `lblStuSsEnd` | `conStuSsForm` |
| `txtStuSsFreq` | `lblStuSsFreq` "Frequency" | `conStuSsForm` |
| `txtStuSsMin` | `lblStuSsMin` "Minutes per frequency" | `conStuSsForm` |
| `txtStuSsNote` | `lblStuSsNote` "Note" | `conStuSsForm` |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| DoR create/edit/end/delete | `varStuLastDor` / snapshot -> `lblStuDorReceipt` | Districts of Record; `Filter(colDor, StudentId = varStuSelId)` | `galStuDor`; `lblStuRowMeta`; Home StuDor card on next visit | returned DoR GUID in RecordId; varStuSelId unchanged | `Select(btnStuLoadEngine)` | student stays open; current row Fill ColorInfoBg |
| SS create/edit/cmedit/excl/incl/delete | `varStuLastSs` / snapshot -> `lblStuSsReceipt` | Student Services; `Filter(colStuSvc, StudentId = varStuSelId)` | `galStuSs`; list row count | returned SS GUID | `Select(btnStuLoadEngine)` | student stays open |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| DoR create/edit | Funder | Changed | `ddStuDorFunder.Selected` | `Funder` | "District ..." | `lblStuDorRowMain` |
| DoR create/edit/end | Start Date / End Date | Changed | `dpStuDorStart`, `chkStuDorOngoing` + `dpStuDorEnd` | `'Start Date'`, `'End Date'` (Blank = ongoing) | "Start ...", "End ..." | `lblStuDorRowMain` |
| DoR create/edit | Source | Changed (CodeMetro -> Manual on edit) | literal Manual | `Source` | "Source CodeMetro -> Manual" | `lblStuDorRowMeta` |
| DoR create/edit | Note, Summary | Changed | `txtStuDorNote`, "<Key> - <Abbr>" | `Note`, `Summary` | "Note ..." | `lblStuDorRowMeta` |
| DoR edit | Student | Preserved | row | omitted | student key | stays under student |
| DoR delete | existence | Changed | snapshot | Remove | receipt | absent |
| SS create/edit | Service, Funder, Start, End, Frequency, Minutes, ESY, Excluded, Note, Summary | Changed | form inputs | Patch fields | one labeled segment each | SS row labels + badge |
| SS edit | Student, Source, Source Key | Preserved | row | omitted | N/A | row |
| SS cmedit/excl/incl | Excluded, Note | Changed | `tglStuSsExcluded`, `txtStuSsNote` | Patch with only these | "Excluded ... (op)", "Note ..." | badge, meta |
| SS cmedit | Service, Funder, dates, Frequency, Minutes, ESY, Source, Source Key, Summary | Preserved | row | omitted | "Other fields unchanged (CodeMetro row)" | row unchanged |
| SS delete | existence | Changed | snapshot | Remove | receipt | absent |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-STU-LOAD | 146 students | open | rows "KEY - Last, First" + meta | `galStuList` | RC rows never warn |
| S-STU-SEARCH | students | "cw-108", then a last name | matching only | list, count | clear restores |
| S-STU-TYPE | 12 RC Only | RC chip | only RC- keys | list | All restores |
| S-STU-NODOR / S-HOME-STUDOR | 14 active School students without current DoR | No-DoR chip (or arrive from Home) | exactly those | `lblStuCount` 14 | after S-DOR-CREATE -> 13 |
| S-STU-STATUS | inactive/archived exist | All statuses | included | list | Active default |
| S-STU-CLEAR | filters set | Clear | defaults | chips | N/A |
| S-STU-SELECT | School student | Open | header read-only; DoR rows start desc; SS rows by service sort then start; caption | detail panels | N/A |
| S-DOR-RC | RC student | Open | RC caption; no Add, no gallery | `lblStuDorCaption` | N/A |
| S-DOR-CREATE | S1 School, no DoR; ZZTEST1 District active | Add district ZZTEST1, start 2026-07-01, Ongoing, note "ZZ test"; Save | Manual row "<key> - ZZTEST1"; audit Create | receipt (student, district, start, end ongoing, source Manual, note, audit); row; list warning gone | Home card -1 |
| S-DOR-REQ | form | no district / no start / no end and Ongoing off | Save disabled with message | `lblStuDorValidation` | N/A |
| S-DOR-ENDBEFORE | form | start 2026-09-01, end 2026-08-01 | disabled | "End date must be on or after the start date." | end = start allowed |
| S-DOR-OVERLAP | S1 has ZZTEST1 2026-07-01 ongoing | add ZZTEST2 from 2026-09-01 | disabled | "Overlaps ZZTEST1 Jul 1, 2026 to ongoing. ..." | adjacent ranges allowed |
| S-DOR-EDIT-CM | CodeMetro row | Edit, note; Save | Source Manual | receipt "Source CodeMetro -> Manual" | N/A |
| S-DOR-END | ongoing row | untick Ongoing, end 2026-12-31; Save | ended | receipt "End Dec 31, 2026"; row | N/A |
| S-DOR-CANCEL | form | Cancel | unchanged | row | N/A |
| S-DOR-DEL / S-DOR-DEL-CM / S-DOR-DELCANCEL | Manual row / CodeMetro row | Delete -> Delete / look / Keep | removed / no Delete button / kept | receipt / `btnStuDorRowDelete` hidden / row | N/A |
| S-SS-CREATE | S1; ZZSVC1 School Day active; ZZTEST1 | Add: ZZSVC1, ZZTEST1, 2026-07-01, Ongoing, "Daily", 360, ESY off, Excluded off, "ZZ"; Save | Manual row "<key> - ZZSVC1 - ZZTEST1"; audit Create | receipt all labeled fields | SPED, Clinical and inactive services absent from picker |
| S-SS-CREATE-2 | one ZZSVC1 row | add another ZZSVC1 | Summary "... ZZSVC1 #2 - ZZTEST1" | receipt | N/A |
| S-SS-REQ / S-SS-MIN-INVALID | form | missing service/funder/start; minutes "abc" or -5 | disabled with message | `lblStuSsValidation` | blank minutes allowed |
| S-SS-EDIT | Manual row | frequency "3x week"; Save | saved | receipt | N/A |
| S-SS-CMEDIT | CodeMetro row | Edit (others read-only); note; Save | only Excluded/Note written | receipt "Other fields unchanged (CodeMetro row)" | N/A |
| S-SS-EXCL / S-SS-INCL / S-SS-COMPOUND | CodeMetro row not excluded | Excluded on Save; then off Save | true then false | receipts "Excluded No -> Yes (Excluded)" / "Yes -> No (Included)"; badge; row muted; count | second op reads reloaded colStuSvc |
| S-SS-CANCEL | form | Cancel | unchanged | row | N/A |
| S-SS-DEL / S-SS-DEL-CM / S-SS-DELCANCEL | Manual / CodeMetro row | Delete -> Delete / look / Keep | removed / no Delete / kept | receipt / hidden button / row | N/A |

## Relevant Data Source Schemas

- Students (read-only): `Student` (GUID), `'External Client ID'` (Student Key), `'Display Name'`,
  `'Status (aaca_status)'` (`'Status (Students)'` Active | Inactive | Archived), `'Student Type'`
  (`'Student Type (Students)'` School | 'Regional Center Only'; blank = School).
- Districts of Record: `'District of Record'` (GUID), `Summary` (required: "<Student Key> - <Funder abbreviation>"),
  `Student`, `Funder` (lookups), `'Start Date'` (required), `'End Date'`, `Source` (`'Source (Districts of Record)'`
  CodeMetro | Manual), `Note`.
- Student Services: `'Student Service'` (GUID), `Summary` (required: "<Student Key> - <Service Code>[ #n] - <Funder abbreviation>"),
  `Student`, `Service`, `Funder` (lookups), `'Start Date'` (required), `'End Date'`, `Frequency` (Text),
  `'Minutes per Frequency'` (Number), `ESY` (Boolean), `Source` (`'Source (Student Services)'` CodeMetro | Manual),
  `'Source Key'` (never written), `Excluded` (Boolean), `Note`.
- Funders / Services: read via colFunders / colServices (shared plan). Audit Events: shared plan.

## Required Variants

- GroupContainer -> `Variant: AutoLayout`. Gallery -> `Variant: Vertical` (`galStuList`, `galStuDor`, `galStuSs`).

## Control Definitions

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
  `Appearance: =Appearance.Outline`, `Type: =TextInputType.Search|SingleLine`, `TriggerOutput: =TriggerOutput.Delayed|Keypress`.
- **ModernDropdown** (`Control: ModernDropdown`): AccessibleLabel, Appearance, BasePaletteColor, BorderColor,
  BorderStyle, BorderThickness, Color, ContentLanguage, Default, DisplayMode, Fill, Font, FontWeight, Height, Italic,
  ItemDisplayText, Items, OnChange, Padding*, Radius*, Required, Size, Strikethrough, Underline, ValidationState,
  Visible, Width, X, Y, AlignInContainer, FillPortions, LayoutMinHeight, LayoutMinWidth (default 320 — set 0).
  Output Selected. `Appearance: =Appearance.Outline` (Enum name Appearance), `DisplayMode: =DisplayMode.View`.
- **ModernDatePicker** (`Control: ModernDatePicker`): AccessibleLabel, Appearance, BasePaletteColor, BorderColor,
  BorderStyle, BorderThickness, Color, ContentLanguage, DateTimeZone, DefaultDate, DisplayMode, EndDate, Fill, Font,
  FontWeight, Format, Height, IsEditable, Italic, OnChange, Padding*, Placeholder, Radius*, Size, StartDate,
  StartOfWeek, Strikethrough, Underline, ValidationState, Visible, Width, X, Y, AlignInContainer, FillPortions,
  LayoutMinHeight, LayoutMinWidth (default 320 — set 0). Output SelectedDate. `Appearance: =Appearance.Outline`,
  `Format: =DatePickerFormat.Short`, `DisplayMode: =DisplayMode.Disabled|View`.
- **ModernCheckbox** (`Control: ModernCheckbox`): AccessibleLabel, BasePaletteColor, CheckboxSize, Color,
  ContentLanguage, Default, DisplayMode, Font, FontWeight, Height, Italic, Label, OnCheck, OnUncheck, Size,
  Strikethrough, Tooltip, Underline, Visible, Width, X, Y, AlignInContainer, FillPortions, LayoutMinHeight,
  LayoutMinWidth. Output Checked.
- **ModernToggle** (`Control: ModernToggle`): AccessibleLabel, BasePaletteColor, Color, ContentLanguage, Default,
  DisplayMode, Font, FontWeight, Height, Italic, Label, LabelPosition, OnCheck, OnUncheck, Size, Strikethrough,
  ToggleSize, Tooltip, Underline, Visible, Width, X, Y, AlignInContainer, FillPortions, LayoutMinHeight,
  LayoutMinWidth. Output Checked.
- **Badge** (`Control: Badge`): AccessibleLabel, Align, Appearance, BasePaletteColor, Content, ContentLanguage,
  DisplayMode, Font, FontColor, FontItalic, FontSize, FontStrikethrough, FontUnderline, FontWeight, Height, Shape,
  ThemeColor, VerticalAlign, Visible, Width, X, Y, AlignInContainer, FillPortions, LayoutMinHeight, LayoutMinWidth.
  Enums: `Appearance: ='BadgeCanvas.Appearance'.Tint`, `Shape: ='BadgeCanvas.Shape'.Rounded`,
  `ThemeColor: ='BadgeCanvas.ThemeColor'.Subtle`. Text colour is `FontColor`, size `FontSize` (not Color/Size).
