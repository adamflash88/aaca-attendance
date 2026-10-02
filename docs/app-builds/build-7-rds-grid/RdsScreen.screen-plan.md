# Screen Plan: RDS Grid (Register of Daily Services)

## Assignment

- Action: Create
- Target file: `C:\src\aaca-attendance\billing-app\RdsScreen.pa.yaml`
- YAML key: RdsScreen
- Control name prefix: Rds
- Read with: `C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid\canvas-app-shared.md`

## Specification

- Purpose: read-only Register of Daily Services for one student + funder + month. No Patch/Remove/Save anywhere.
- Screen properties: `Fill: =ColorPaper`; `OnVisible: =Select(btnRdsLoadEngine)`.
- Breakpoint source: `conRdsRoot.Width` only. `w` below means `conRdsRoot.Width - 66`.

### Control tree (order matters; indentation = nesting)

```
conRdsRoot (root, shared spec)
  conRdsHeader (shared header)  > lblRdsTitle, lblRdsIdentity, conRdsNav > btnRdsNavHome, btnRdsNavFunders,
                                  btnRdsNavServices, btnRdsNavStudents, btnRdsNavRds (current)
  conRdsGate (shared gate)      > lblRdsGateTitle, lblRdsGateBody
  conRdsPickers                 white panel, Vertical, gap 8, padding 16, radius 6, Visible =IsFinance
                                  Height =16 + If(w >= 1160, 66, w >= 828, 144, 222) + 8 + 36 + 16
    conRdsPickerRow             Horizontal, LayoutWrap true, gap 12, AlignItems Start, FillPortions 0,
                                  Height =If(w >= 1160, 66, w >= 828, 144, 222)
      conRdsMonthField          Vertical, gap 4, Width 356, Height 66, FillPortions 0, Stretch
        lblRdsMonthCap          "Month" caption (18)
        conRdsMonthRow          Horizontal, gap 8, Height 44, AlignItems Center
          btnRdsPrevMonth       Secondary "Previous" w96
          lblRdsMonth           w140 h44, Size 15 Semibold, Align Center, VerticalAlign Middle, Wrap false
          btnRdsNextMonth       Secondary "Next" w96
      conRdsFunderField         Vertical, gap 4, Width 460, Height 66 > lblRdsFunderCap "Funder", ddRdsFunder (h44)
      conRdsStudentField        Vertical, gap 4, Width 320, Height 66 > lblRdsStudentCap "Student", ddRdsStudent (h44)
    lblRdsStatus                Height 36, Size 12, Top, wraps
  conRdsEmpty                   white panel, padding 16, radius 6, Height 72, Visible (SV-RDS-EMPTY)
    lblRdsEmptyText             Height 40, Size 14 ink, Top
  conRdsDoc                     document panel: Fill ColorWhite, border ColorRule 1, radius 0, padding 16, gap 12,
                                  Vertical Stretch, Visible (SV-RDS-DOC), Height (see budget)
    conRdsDocHead               Vertical, gap 4, Height 144
      lblRdsDocTitle            "Register of Daily Services" 20 Bold ink, h28, Wrap false
      lblRdsDocStudent          16 Semibold ink, h24, Wrap false
      lblRdsDocMeta1            13 ink, h40, Top
      lblRdsDocMeta2            13 ink, h40, Top
    lblRdsNoRows                Height 40, Size 13, Top, Visible =CountRows(colRdsRows) = 0
    conRdsGridScroll            Horizontal, LayoutOverflowX Scroll, AlignItems Start, FillPortions 0,
                                  Height =56 + Min(880, 44 * Max(1, CountRows(colRdsRows))),
                                  Visible =CountRows(colRdsRows) > 0
      conRdsGridInner           Vertical, gap 0, AlignInContainer Start, FillPortions 0, Stretch items,
                                  Width =Max(Parent.Width, 330 + 30 * CountRows(colRdsDays)),
                                  Height =40 + Min(880, 44 * Max(1, CountRows(colRdsRows)))
        conRdsGridHead          Horizontal, Height 40, FillPortions 0, Fill ColorPaper, AlignItems Stretch
          lblRdsHeadLabel       "Service", Width 220, 11 Bold, VerticalAlign Bottom, PaddingLeft 6, PaddingBottom 4
          galRdsDayHead         Gallery Horizontal over colRdsDays (see Grid)
            conRdsDayHeadCell   shell, Vertical > lblRdsDayNum, lblRdsDayDow
          lblRdsHeadTotal       "Total", FillPortions 1, 11 Bold, Align Center, VerticalAlign Bottom, PaddingBottom 4
        galRdsRows              Gallery Vertical over colRdsRows
          conRdsRowShell        shell, Horizontal, AlignItems Stretch, Fill ColorWhite
            lblRdsRowLabel      Width 220
            galRdsCells         Gallery Horizontal over this row's cells
              lblRdsCell        single child (no shell)
            conRdsRowTotal      Vertical, FillPortions 1, padding 2/4/2/4, border ColorRule 1
              lblRdsRowTotalMain  h18, 11 Bold, Align Right
              lblRdsRowTotalSub   h16, 10 ColorMuted, Align Right
    conRdsFooter                Vertical, gap 6, Stretch, Height =legendH + 206
      conRdsLegend              Horizontal, LayoutWrap true, gap 8, Height legendH =If(w >= 1004, 28, w >= 560, 64, 100)
        lblRdsLegPresent, lblRdsLegExcused, lblRdsLegUnexcused, lblRdsLegUnclass, lblRdsLegNonSchool,
        lblRdsLegFlag, lblRdsLegOutside
      lblRdsNonSchool           h40, 12 ColorMuted, Top
      lblRdsTotals              h40, 13 Semibold ink, Top
      lblRdsAbsenceNote         h36, 12 ColorMuted, Top
      lblRdsDataNote            h40, 12, Top
      lblRdsExcNote             h20, 12, Wrap false
  btnRdsLoadEngine, btnRdsMonthEngine, btnRdsGridEngine   (hidden engines, shared spec)
```

Container rules: every GroupContainer sets `DropShadow: =DropShadow.None`, `LayoutMinWidth: =0`,
`LayoutMinHeight: =0`, `FillPortions: =0` (except `conRdsRowTotal` = 1) and `AlignInContainer` (Stretch unless stated).
Header/gate copy the shared pattern with prefix Rds; nav: `btnRdsNavRds` is current (teal Primary, AccessibleLabel
"RDS Grid (current screen)"), the other four Secondary.

`conRdsDoc.Height`:
```
=16 + 144 + 12 + If(CountRows(colRdsRows) = 0, 40, 56 + Min(880, 44 * CountRows(colRdsRows))) + 12 +
 If(conRdsRoot.Width - 66 >= 1004, 28, conRdsRoot.Width - 66 >= 560, 64, 100) + 206 + 16
```
`conRdsFooter.Height: =If(conRdsRoot.Width - 66 >= 1004, 28, conRdsRoot.Width - 66 >= 560, 64, 100) + 206`

### Pickers

- `lblRdsMonthCap` / `lblRdsFunderCap` / `lblRdsStudentCap`: "Month" / "Funder" / "Student", 12 Semibold ColorMuted,
  Height 18, Wrap false.
- `btnRdsPrevMonth.OnSelect: =Set(varRdsMonth, Date(Year(varRdsMonth), Month(varRdsMonth) - 1, 1)); Select(btnRdsMonthEngine)`
- `btnRdsNextMonth.OnSelect: =Set(varRdsMonth, Date(Year(varRdsMonth), Month(varRdsMonth) + 1, 1)); Select(btnRdsMonthEngine)`
- Both: `DisplayMode: =If(varRdsLoading || IsBlank(varRdsMonth), DisplayMode.Disabled, DisplayMode.Edit)`,
  AccessibleLabel "Previous month" / "Next month".
- `lblRdsMonth.Text: =If(IsBlank(varRdsMonth), "", Text(varRdsMonth, "mmmm yyyy"))`
- `ddRdsFunder`: `Appearance: =Appearance.Outline`, `Height: =44`, `AlignInContainer: =AlignInContainer.Stretch`,
  `Items: =colRdsFunderOpts`, `ItemDisplayText: =ThisItem.Abbr & " – " & ThisItem.FullName & " (" & ThisItem.TypeText & ")"`,
  `Default: =LookUp(colRdsFunderOpts, FunderId = varRdsFunderId)`, AccessibleLabel "Funder",
  `DisplayMode: =If(varRdsLoading, DisplayMode.Disabled, DisplayMode.Edit)`,
  `OnChange: =If(Coalesce(Self.Selected.FunderId, ZeroGuid) <> Coalesce(varRdsFunderId, ZeroGuid), Set(varRdsFunderId, Self.Selected.FunderId); Select(btnRdsGridEngine))`
- `ddRdsStudent`: same styling; `Items: =colRdsStudentOpts`,
  `ItemDisplayText: =ThisItem.DisplayName & " (" & ThisItem.StudentKey & ")"`,
  `Default: =LookUp(colRdsStudentOpts, StudentId = varRdsStudentId)`, AccessibleLabel "Student",
  `DisplayMode: =If(varRdsLoading || IsBlank(varRdsFunderId), DisplayMode.Disabled, DisplayMode.Edit)`,
  `OnChange: =If(Coalesce(Self.Selected.StudentId, ZeroGuid) <> Coalesce(varRdsStudentId, ZeroGuid), Set(varRdsStudentId, Self.Selected.StudentId); Select(btnRdsGridEngine))`
  (the guard stops a Default refresh from re-firing the engine in a loop).
- `lblRdsStatus` (`|-` block; Color `=If(varRdsLoadError <> "", ColorUnexcused, varRdsPageCapped, ColorWarnInk, ColorMuted)`):
```
=If(
    varRdsLoading, "Loading...",
    varRdsLoadError <> "", "Could not load - " & varRdsLoadError,
    varRdsPageCapped, "Warning: a day returned 500 or more deliveries, so the funder and student lists may be incomplete. Tell Adam.",
    Text(CountRows(colRdsFunderOpts)) & " funders · " & Text(CountRows(colRdsMonthPairs), "#,##0") & " deliveries in " & Text(varRdsMonth, "mmmm yyyy")
)
```

### Empty state

`lblRdsEmptyText.Text` (`|-`):
```
=With({mn: Text(varRdsMonth, "mmmm yyyy")},
    If(
        varRdsLoading, "Loading...",
        CountRows(colRdsFunderOpts) = 0, "No funders have deliveries, districts of record or student services in " & mn & ". Try another month.",
        IsBlank(varRdsFunderId), "Choose a funder to see its students for " & mn & ".",
        CountRows(colRdsStudentOpts) = 0, "No students have anything for this funder in " & mn & ".",
        "Choose a student to show the Register of Daily Services."
    )
)
```
`lblRdsNoRows.Text: =If(varRdsLoading, "Loading grid...", "No rows for this student, funder and month: no attendance or day-service rows apply and no services were delivered.")` (`|-` block: contains `: `).

### Document header (all `|-` blocks)

- `lblRdsDocStudent.Text: =With({s: LookUp(colStudents, StudentId = varRdsStudentId)}, s.DisplayName & " (" & s.StudentKey & ")")`
- `lblRdsDocMeta1.Text`:
```
=With({f: LookUp(colFunders, FunderId = varRdsFunderId)}, "Funder: " & f.Abbr & " – " & f.FullName & " (" & f.TypeText & ")   ·   Month: " & Text(varRdsMonth, "mmmm yyyy"))
```
- `lblRdsDocMeta2.Text`:
```
=With(
    {
        s: LookUp(colStudents, StudentId = varRdsStudentId),
        dors: SortByColumns(Filter(colDor, StudentId = varRdsStudentId && StartDate <= varRdsMonthEnd && Coalesce(EndDate, FarFuture) >= varRdsMonth), "StartDate", SortOrder.Ascending)
    },
    "Campus: " & varRdsCampusText & "   ·   District of record: " &
    If(
        s.TypeText = "Regional Center Only", "None (Regional Center Only)",
        CountRows(dors) = 0, "None on file for this month",
        Concat(dors As d, LookUp(colFunders, FunderId = d.FunderId).Abbr & " " & Text(d.StartDate, "m/d/yyyy") & " to " & If(IsBlank(d.EndDate), "ongoing", Text(d.EndDate, "m/d/yyyy")), "; ")
    )
)
```
AccessibleLabel of each header label: `=Self.Text`.

### Grid (core visualization)

- `galRdsDayHead`: `Variant: Horizontal`, `Items: =colRdsDays`, `FillPortions: =0`, `AlignInContainer: =AlignInContainer.Stretch`,
  `TemplateSize: =RoundDown((conRdsGridInner.Width - 330) / Max(1, CountRows(colRdsDays)), 0)`,
  `Width: =CountRows(colRdsDays) * RoundDown((conRdsGridInner.Width - 330) / Max(1, CountRows(colRdsDays)), 0)`,
  `TemplatePadding: =0`, `ShowScrollbar: =false`, `Selectable: =false`, `TabIndex: =-1`,
  `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, AccessibleLabel "Days of the month".
  - `conRdsDayHeadCell`: Vertical, `Width: =Parent.TemplateWidth`, `Height: =Parent.TemplateHeight`,
    `Fill: =If(ThisItem.IsSchoolDay, ColorPaper, ColorNonSchool)`, `BorderColor: =ColorRule`, `BorderThickness: =1`,
    padding 2/0/2/0, Stretch, radius 0.
  - `lblRdsDayNum`: `Text: =Text(ThisItem.DayNum)`, h18, 11 Bold ink, Align Center, Wrap false.
  - `lblRdsDayDow`: `Text: =ThisItem.DowLetter`, h14, Size 9 ColorMuted, Align Center, Wrap false.
  - Both AccessibleLabel: `=Text(ThisItem.CellDate, "dddd mmmm d") & If(ThisItem.IsSchoolDay, "", ", " & ThisItem.NonSchoolReason)`.
- `galRdsRows`: `Variant: Vertical`, `Items: =SortByColumns(colRdsRows, "SortKey", SortOrder.Ascending, "Label", SortOrder.Ascending)`,
  `Height: =Min(880, 44 * Max(1, CountRows(colRdsRows)))`, `TemplateSize: =44`, `TemplatePadding: =0`,
  `FillPortions: =0`, `Selectable: =false`, `ShowScrollbar: =true`, `TabIndex: =0`, `LayoutMinWidth: =0`,
  `LayoutMinHeight: =0`, AccessibleLabel `="Register rows for " & Text(varRdsMonth, "mmmm yyyy")`.
  - `conRdsRowShell`: Horizontal, `Width: =Parent.TemplateWidth`, `Height: =Parent.TemplateHeight`, gap 0, Stretch.
  - `lblRdsRowLabel`: `Width: =220`, FillPortions 0, Stretch, Size 11, padding L6/R4/T0/B0, VerticalAlign Middle,
    border ColorRule 1, `FontWeight: =If(ThisItem.Kind = "SAI", FontWeight.Semibold, FontWeight.Normal)`,
    `Color: =If(ThisItem.IsBillable, ColorInk, ColorMuted)`, wraps (2 lines),
    `Text: =ThisItem.Label & If(ThisItem.IsBillable, "", " · not billable")`, AccessibleLabel `=Self.Text`.
  - `galRdsCells`: `Variant: Horizontal`,
    `Items: =SortByColumns(Filter(colRdsCells, RowKey = ThisItem.RowKey), "DayNum", SortOrder.Ascending)`,
    TemplateSize and Width exactly as `galRdsDayHead`, `AlignInContainer: =AlignInContainer.Stretch`, FillPortions 0,
    TemplatePadding 0, ShowScrollbar false, Selectable false, `TabIndex: =-1`, LayoutMin* 0,
    AccessibleLabel `="Days for " & ThisItem.Label`.
    - `lblRdsCell`: `Width: =Parent.TemplateWidth`, `Height: =Parent.TemplateHeight`, `Text: =ThisItem.CellText`,
      Align Center, VerticalAlign Middle, Size 11, `FontWeight: =FontWeight.Semibold`, Wrap false, padding 0,
      `BorderColor: =ColorRule`, `BorderThickness: =1`,
      `Fill: =Switch(ThisItem.State, "excused", ColorExcused, "unexcused", ColorUnexcused, "nonschool", ColorNonSchool, "flag", ColorFlag, "outside", ColorNotEnrolled, ColorWhite)`,
      `Color: =If(ThisItem.State = "excused" || ThisItem.State = "unexcused", ColorWhite, ColorInk)`,
      `AccessibleLabel: =Text(ThisItem.DayNum) & " " & Switch(ThisItem.State, "excused", "absent excused", "unexcused", "absent unexcused", "nonschool", "non-school day", "flag", "review, minutes on a non-school day", "outside", "outside the row dates", "") & " " & ThisItem.CellText`
  - `lblRdsRowTotalMain.Text: =With({tot: Sum(Filter(colRdsCells, RowKey = ThisItem.RowKey), CellNum)}, If(ThisItem.Kind = "CLIN", Text(tot, "#,##0") & " min", Text(tot) & " days"))`
  - `lblRdsRowTotalSub.Text` (`|-`): `=Switch(ThisItem.Kind, "SAI", "absent " & CountIf(colRdsCells, RowKey = ThisItem.RowKey && IsAbsent), "DAY", "", Text(Sum(Filter(colRdsCells, RowKey = ThisItem.RowKey), CellNum) / 60, "0.00") & " h · " & ThisItem.UnitText)`
  - Total labels: Wrap false, padding 0, AccessibleLabel `="Total " & Self.Text`.

### Footer

Legend chips (ModernText, Height 28, FillPortions 0, AlignInContainer Center, Size 11, Align Center, VerticalAlign
Middle, Wrap false, padding L8/R8/T0/B0, border ColorRule 1, AccessibleLabel `="Legend " & Self.Text`):

| Control | Width | Text | Fill | Color |
| --- | --- | --- | --- | --- |
| lblRdsLegPresent | 90 | "1 present" | ColorWhite | ColorInk |
| lblRdsLegExcused | 96 | "0 excused" | ColorExcused | ColorWhite |
| lblRdsLegUnexcused | 110 | "0 unexcused" | ColorUnexcused | ColorWhite |
| lblRdsLegUnclass | 130 | "0 not classified" | ColorWhite | ColorInk |
| lblRdsLegNonSchool | 130 | "Non-school day" | ColorNonSchool | ColorInk |
| lblRdsLegFlag | 260 | "Review: minutes on a non-school day" (`|-` block) | ColorFlag | ColorInk |
| lblRdsLegOutside | 140 | "Outside row dates" | ColorNotEnrolled | ColorInk |

- `lblRdsNonSchool.Text` (`|-`):
```
=With(
    {hol: Filter(colRdsDays, !IsSchoolDay && NonSchoolReason <> "Weekend" && NonSchoolReason <> "Outside any term"), outN: CountIf(colRdsDays, NonSchoolReason = "Outside any term")},
    If(CountRows(hol) = 0, "No holidays or breaks this month.", "Holidays and breaks: " & Concat(hol, Text(CellDate, "mmm d") & " " & NonSchoolReason, "; ") & ".") &
    If(outN > 0, " " & outN & " day(s) fall outside any school term.", "")
)
```
- `lblRdsTotals.Text` (`|-`):
```
="Totals: " &
If(CountIf(colRdsRows, Kind = "SAI") > 0, "SAI " & Sum(Filter(colRdsCells, RowKey = "SAI"), CellNum) & " days · ", "") &
Concat(Filter(colRdsRows, Kind = "DAY") As r, r.ShortLabel & " " & Sum(Filter(colRdsCells, RowKey = r.RowKey), CellNum) & " days · ") &
With({m: Sum(Filter(colRdsCells, Left(RowKey, 2) = "CL"), CellNum)}, "clinical " & Text(m, "#,##0") & " min (" & Text(m / 60, "0.00") & " h)")
```
  Fallback only if the compiler rejects `Concat(... As r, ...)`:
  `Concat(ForAll(Filter(colRdsRows, Kind = "DAY") As r, {T: r.ShortLabel & " " & Sum(Filter(colRdsCells, RowKey = r.RowKey), CellNum) & " days · "}), T)`.
- `lblRdsAbsenceNote.Text: ="Absences show as excused (green), unexcused (red) or not classified (plain). Billable-absence flags (24-hour notice rule) are coming in Phase 2."`
- `lblRdsDataNote.Text` (`|-`; `Color: =With({u: First(SortByColumns(colRdsUploads, "UploadedOn", SortOrder.Descending))}, If(!IsBlank(u) && u.RowsIn <> u.RowsMatched + u.RowsExc, ColorWarnInk, ColorMuted))`):
```
=With(
    {u: First(SortByColumns(colRdsUploads, "UploadedOn", SortOrder.Descending))},
    If(
        IsBlank(u), "No completed CodeMetro upload covers " & Text(varRdsMonth, "mmmm yyyy") & ".",
        "Data: CodeMetro upload " & u.FileName & " (" & Text(u.DateFrom, "m/d/yyyy") & " to " & Text(u.DateTo, "m/d/yyyy") &
        ", uploaded " & Text(u.UploadedOn, "m/d/yyyy h:mm AM/PM") & ") · Rows in " & u.RowsIn & " = matched " & u.RowsMatched &
        " + exceptions " & u.RowsExc & If(u.RowsIn = u.RowsMatched + u.RowsExc, " (ties out)", " (DOES NOT TIE OUT)")
    )
)
```
- `lblRdsExcNote.Text`: `=With({n: CountRows(colRdsExc)}, If(n = 0, "No open upload exceptions dated in " & Text(varRdsMonth, "mmmm yyyy") & ".", n & " open upload exception(s) dated in " & Text(varRdsMonth, "mmmm yyyy") & "."))`,
  `Color: =If(CountRows(colRdsExc) > 0, ColorWarnInk, ColorMuted)`, `FontWeight: =If(CountRows(colRdsExc) > 0, FontWeight.Semibold, FontWeight.Normal)`.

## Engines (copy verbatim; each OnSelect is a `|-` block)

### btnRdsLoadEngine.OnSelect

```
=Set(varRdsLoading, true);
Set(varRdsLoadError, "");
If(
    !IsFinance,
    Clear(colFunders); Clear(colServices); Clear(colStudents); Clear(colDor); Clear(colStuSvc);
    Clear(colRdsMonthPairs); Clear(colRdsFunderOpts); Clear(colRdsStudentOpts); Clear(colRdsDays); Clear(colRdsRows); Clear(colRdsCells),
    IfError(
        Refresh(Funders); Refresh(Services); Refresh(Students); Refresh('Districts of Record'); Refresh('Student Services');
        Concurrent(
            ClearCollect(colFunders, ForAll(Funders As f, {FunderId: f.Funder, Abbr: Coalesce(f.Abbreviation, ""), FullName: Coalesce(f.'Full Name', ""), TypeText: Coalesce(Text(f.'Funder Type'), ""), QboCustomer: Coalesce(f.'QuickBooks Customer', ""), IsActive: Coalesce(f.Active, false)})),
            ClearCollect(colServices, ForAll(Services As s, {ServiceId: s.Service, Code: Coalesce(s.'Service Code', ""), Name: Coalesce(s.Name, ""), KindText: Coalesce(Text(s.Kind), ""), KindRank: If(Text(s.Kind) = "School Day", 1, 2), UnitText: Coalesce(Text(s.'Billing Unit'), ""), QboItem: Coalesce(s.'QuickBooks Item', ""), SortNum: s.'Sort Order', IsBillable: Coalesce(s.Billable, false), NonSchool: Coalesce(s.'Billable on Non-School Days', false), IsActive: Coalesce(s.Active, false)})),
            ClearCollect(colStudents, ForAll(Students As s, {StudentId: s.Student, StudentKey: Coalesce(s.'External Client ID', ""), DisplayName: Coalesce(s.'Display Name', ""), StatusText: Coalesce(Text(s.'Status (aaca_status)'), ""), TypeText: If(Text(s.'Student Type') = "Regional Center Only", "Regional Center Only", "School")})),
            ClearCollect(colDor, ForAll('Districts of Record' As d, {DorId: d.'District of Record', StudentId: d.Student.Student, FunderId: d.Funder.Funder, StartDate: d.'Start Date', EndDate: d.'End Date', SourceText: Coalesce(Text(d.Source), ""), Note: Coalesce(d.Note, "")})),
            ClearCollect(colStuSvc, ForAll('Student Services' As x, {SsId: x.'Student Service', StudentId: x.Student.Student, ServiceId: x.Service.Service, FunderId: x.Funder.Funder, SvcSort: Coalesce(x.Service.'Sort Order', 9999), StartDate: x.'Start Date', EndDate: x.'End Date', Frequency: Coalesce(x.Frequency, ""), Minutes: x.'Minutes per Frequency', IsEsy: Coalesce(x.ESY, false), SourceText: Coalesce(Text(x.Source), ""), IsExcluded: Coalesce(x.Excluded, false), Note: Coalesce(x.Note, ""), Summary: Coalesce(x.Summary, "")}))
        );
        If(
            IsBlank(varRdsMonth),
            With(
                {lastD: First(Sort('Service Deliveries', Date, SortOrder.Descending)).Date},
                Set(varRdsMonth, If(IsBlank(lastD), Date(Year(Today()), Month(Today()), 1), Date(Year(lastD), Month(lastD), 1)))
            )
        );
        true,
        Set(varRdsLoadError, FirstError.Message);
        false
    )
);
Set(varRdsLoading, false);
If(IsFinance && varRdsLoadError = "", Select(btnRdsMonthEngine))
```

### btnRdsMonthEngine.OnSelect

```
=Set(varRdsLoading, true);
Set(varRdsLoadError, "");
Set(varRdsMonthEnd, Date(Year(varRdsMonth), Month(varRdsMonth), Day(DateAdd(DateAdd(varRdsMonth, 1, TimeUnit.Months), -1, TimeUnit.Days))));
With(
    {ms: varRdsMonth, me: varRdsMonthEnd},
    Clear(colRdsMonthPairs);
    Clear(colRdsPageLog);
    IfError(
        ForAll(
            Sequence(Day(me)) As n,
            With(
                {d: Date(Year(ms), Month(ms), n.Value)},
                With(
                    {pg: ForAll(Filter('Service Deliveries', Date = d) As r, {StudentId: r.Student.Student, FunderId: r.Funder.Funder})},
                    Collect(colRdsMonthPairs, pg);
                    Collect(colRdsPageLog, {DayNum: n.Value, RowCount: CountRows(pg)})
                )
            )
        );
        Concurrent(
            ClearCollect(colRdsTerms, ForAll(Filter(Terms, 'Start Date' <= me && 'End Date' >= ms) As t, {CampusId: t.Campus.Campus, StartDate: t.'Start Date', EndDate: t.'End Date'})),
            ClearCollect(colRdsCalEx, ForAll(Filter('Calendar Exceptions', Date >= ms && Date <= me) As x, {ExDate: x.Date, CampusId: x.Campus.Campus, TypeText: Coalesce(Text(x.Type), ""), Descr: Coalesce(x.Description, "")})),
            ClearCollect(colRdsUploads, ForAll(Filter('CodeMetro Uploads', 'Date From' <= me && 'Date To' >= ms && 'Status (aaca_status)' = 'Status (CodeMetro Uploads)'.Complete) As u, {FileName: Coalesce(u.'File Name', ""), UploadedOn: u.'Uploaded On', DateFrom: u.'Date From', DateTo: u.'Date To', RowsIn: Coalesce(u.'Rows In', 0), RowsMatched: Coalesce(u.'Rows Matched', 0), RowsExc: Coalesce(u.'Rows in Exceptions', 0)})),
            ClearCollect(colRdsExc, ForAll(Filter('Upload Exceptions', 'Appt Date' >= ms && 'Appt Date' <= me && 'Status (aaca_status)' = 'Status (Upload Exceptions)'.Open) As e, {ExcId: e.'Upload Exception'}))
        );
        true,
        Set(varRdsLoadError, FirstError.Message);
        false
    );
    Set(varRdsPageCapped, CountIf(colRdsPageLog, RowCount >= 500) > 0);
    With(
        {pairFunders: colRdsMonthPairs.FunderId},
        ClearCollect(
            colRdsFunderOpts,
            SortByColumns(
                Filter(
                    colFunders As f,
                    f.IsActive && (
                        f.FunderId in pairFunders ||
                        CountIf(colDor, FunderId = f.FunderId && StartDate <= me && Coalesce(EndDate, FarFuture) >= ms) > 0 ||
                        CountIf(colStuSvc, FunderId = f.FunderId && StartDate <= me && Coalesce(EndDate, FarFuture) >= ms) > 0
                    )
                ),
                "Abbr", SortOrder.Ascending
            )
        )
    );
    If(IsBlank(LookUp(colRdsFunderOpts, FunderId = varRdsFunderId)), Set(varRdsFunderId, Blank()))
);
Set(varRdsLoading, false);
Select(btnRdsGridEngine)
```

### btnRdsGridEngine.OnSelect

```
=Set(varRdsLoading, true);
With(
    {ms: varRdsMonth, me: varRdsMonthEnd, fid: varRdsFunderId},
    With(
        {pairs: Filter(colRdsMonthPairs, FunderId = fid)},
        ClearCollect(
            colRdsStudentOpts,
            SortByColumns(
                Filter(
                    colStudents As s,
                    !IsBlank(fid) && (
                        s.StudentId in pairs.StudentId ||
                        CountIf(colDor, StudentId = s.StudentId && FunderId = fid && StartDate <= me && Coalesce(EndDate, FarFuture) >= ms) > 0 ||
                        CountIf(colStuSvc, StudentId = s.StudentId && FunderId = fid && StartDate <= me && Coalesce(EndDate, FarFuture) >= ms) > 0
                    )
                ),
                "DisplayName", SortOrder.Ascending
            )
        )
    );
    If(IsBlank(LookUp(colRdsStudentOpts, StudentId = varRdsStudentId)), Set(varRdsStudentId, Blank()));
    Clear(colRdsDel); Clear(colRdsAtt); Clear(colRdsEnr); Clear(colRdsDays); Clear(colRdsRows); Clear(colRdsCells);
    Set(varRdsCampusText, "");
    If(
        IsFinance && !IsBlank(fid) && !IsBlank(varRdsStudentId),
        With(
            {sid: varRdsStudentId},
            IfError(
                Concurrent(
                    ClearCollect(colRdsDel, ForAll(Filter('Service Deliveries', Student.Student = sid && Funder.Funder = fid && Date >= ms && Date <= me) As r, {ServiceId: r.Service.Service, DayNum: Day(r.Date), Minutes: Coalesce(r.Minutes, 0)})),
                    ClearCollect(colRdsAtt, ForAll(Filter(Attendance, Student.Student = sid && Date >= ms && Date <= me) As a, {DayNum: Day(a.Date), Present: a.Present = true, IsDeleted: a.'Is Deleted' = true, Letter: If(a.Present = true, "P", a.'Absence Classification' = 'Absence Classification (Attendance)'.Excused, "E", a.'Absence Classification' = 'Absence Classification (Attendance)'.Unexcused, "U", "A")})),
                    ClearCollect(colRdsEnr, ForAll(Filter(Enrollments, Student.Student = sid && 'Start Date' <= me && (IsBlank('End Date') || 'End Date' >= ms)) As e, {CampusId: e.Campus.Campus, CampusName: Coalesce(e.Campus.Name, ""), StartDate: e.'Start Date', EndDate: e.'End Date'}))
                );
                true,
                Set(varRdsLoadError, FirstError.Message);
                false
            );
            RemoveIf(colRdsAtt, IsDeleted);
            With(
                {
                    stu: LookUp(colStudents, StudentId = sid),
                    isRc: LookUp(colFunders, FunderId = fid).TypeText = "Regional Center",
                    fbCid: First(SortByColumns(colRdsEnr, "StartDate", SortOrder.Descending)).CampusId
                },
                With(
                    {noCampus: stu.TypeText = "Regional Center Only" || CountRows(colRdsEnr) = 0},
                    Set(varRdsCampusText, If(stu.TypeText = "Regional Center Only", "Regional Center Only", CountRows(colRdsEnr) = 0, "No enrollment in this month (weekends shaded only)", Concat(Distinct(SortByColumns(colRdsEnr, "StartDate", SortOrder.Ascending), CampusName), Value, ", ")));
                    // ---------- 1. Days with the per-campus school-day rule ----------
                    ForAll(
                        Sequence(Day(me)) As n,
                        With(
                            {d: Date(Year(ms), Month(ms), n.Value)},
                            With(
                                {
                                    cid: Coalesce(LookUp(colRdsEnr, StartDate <= d && (IsBlank(EndDate) || EndDate >= d)).CampusId, fbCid),
                                    wkend: Weekday(d, StartOfWeek.Monday) >= 6,
                                    inDor: CountIf(colDor, StudentId = sid && FunderId = fid && StartDate <= d && Coalesce(EndDate, FarFuture) >= d) > 0
                                },
                                With(
                                    {
                                        t: LookUp(colRdsTerms, StartDate <= d && EndDate >= d && (IsBlank(CampusId) || CampusId = cid)),
                                        x: LookUp(colRdsCalEx, ExDate = d && (IsBlank(CampusId) || CampusId = cid) && TypeText <> "Make-up School Day"),
                                        mk: CountIf(colRdsCalEx, ExDate = d && (IsBlank(CampusId) || CampusId = cid) && TypeText = "Make-up School Day") > 0
                                    },
                                    Collect(
                                        colRdsDays,
                                        {
                                            DayNum: n.Value,
                                            CellDate: d,
                                            DowLetter: Mid("SMTWTFS", Weekday(d), 1),
                                            InDor: inDor,
                                            IsSchoolDay: If(noCampus, !wkend, !IsBlank(t) && (mk || (!wkend && IsBlank(x)))),
                                            NonSchoolReason: If(noCampus, If(wkend, "Weekend", ""), IsBlank(t), "Outside any term", mk, "", !IsBlank(x), x.TypeText & " - " & x.Descr, wkend, "Weekend", "")
                                        }
                                    )
                                )
                            )
                        )
                    );
                    // ---------- 2a. SAI row (not RC, student's DoR for part of the month) ----------
                    If(
                        !isRc && CountIf(colRdsDays, InDor) > 0,
                        Collect(colRdsRows, {RowKey: "SAI", Kind: "SAI", SortKey: 0, Label: "SAI – Special Education", ShortLabel: "SAI", ServiceId: LookUp(colServices, Code = "SPED").ServiceId, NonSchool: false, IsBillable: true, UnitText: "Days", StartDate: ms, EndDate: me})
                    );
                    // ---------- 2b. Day-service rows (one per Student Services row) ----------
                    If(
                        !isRc,
                        With(
                            {
                                ss: SortByColumns(
                                    Filter(colStuSvc As q, q.StudentId = sid && q.FunderId = fid && !q.IsExcluded && q.StartDate <= me && Coalesce(q.EndDate, FarFuture) >= ms && LookUp(colServices, ServiceId = q.ServiceId).KindText = "School Day" && LookUp(colServices, ServiceId = q.ServiceId).Code <> "SPED"),
                                    "SvcSort", SortOrder.Ascending, "StartDate", SortOrder.Ascending
                                )
                            },
                            ForAll(
                                Sequence(CountRows(ss)) As i,
                                With(
                                    {row: Index(ss, i.Value)},
                                    With(
                                        {sv: LookUp(colServices, ServiceId = row.ServiceId), nTot: CountIf(ss, ServiceId = row.ServiceId), nIdx: CountIf(FirstN(ss, i.Value), ServiceId = row.ServiceId)},
                                        Collect(colRdsRows, {RowKey: "SS" & Text(row.SsId), Kind: "DAY", SortKey: 1000 + i.Value, Label: sv.Code & " – " & sv.Name & If(nTot > 1, " #" & nIdx, ""), ShortLabel: sv.Code & If(nTot > 1, " #" & nIdx, ""), ServiceId: row.ServiceId, NonSchool: sv.NonSchool, IsBillable: sv.IsBillable, UnitText: sv.UnitText, StartDate: row.StartDate, EndDate: Coalesce(row.EndDate, FarFuture)})
                                    )
                                )
                            )
                        )
                    );
                    // ---------- 2c. Delivered-service (clinical) rows ----------
                    ForAll(
                        Distinct(colRdsDel, ServiceId) As g,
                        With(
                            {sv: LookUp(colServices, ServiceId = g.Value)},
                            Collect(colRdsRows, {RowKey: "CL" & Text(g.Value), Kind: "CLIN", SortKey: 100000 + Coalesce(sv.SortNum, 9999), Label: sv.Code & " – " & sv.Name, ShortLabel: sv.Code, ServiceId: g.Value, NonSchool: sv.NonSchool, IsBillable: sv.IsBillable, UnitText: sv.UnitText, StartDate: ms, EndDate: me})
                        )
                    );
                    // ---------- 3. Cells (single source for fills, totals and footer) ----------
                    ForAll(
                        colRdsRows As rw,
                        Collect(
                            colRdsCells,
                            ForAll(
                                colRdsDays As dd,
                                With(
                                    {
                                        a: LookUp(colRdsAtt, DayNum = dd.DayNum),
                                        inRow: rw.StartDate <= dd.CellDate && rw.EndDate >= dd.CellDate,
                                        mins: Sum(Filter(colRdsDel, ServiceId = rw.ServiceId && DayNum = dd.DayNum), Minutes),
                                        shade: !dd.IsSchoolDay && !rw.NonSchool
                                    },
                                    Switch(
                                        rw.Kind,
                                        "SAI",
                                        {RowKey: rw.RowKey, DayNum: dd.DayNum, CellText: If(!dd.InDor || IsBlank(a), "", a.Present, "1", "0"), CellNum: If(dd.InDor && !IsBlank(a) && a.Present, 1, 0), IsAbsent: dd.InDor && !IsBlank(a) && !a.Present, State: If(!dd.InDor, "outside", !IsBlank(a) && !a.Present && a.Letter = "E", "excused", !IsBlank(a) && !a.Present && a.Letter = "U", "unexcused", shade, "nonschool", "plain")},
                                        "DAY",
                                        {RowKey: rw.RowKey, DayNum: dd.DayNum, CellText: If(inRow && !IsBlank(a) && a.Present, "1", ""), CellNum: If(inRow && !IsBlank(a) && a.Present, 1, 0), IsAbsent: false, State: If(!inRow, "outside", shade, "nonschool", "plain")},
                                        {RowKey: rw.RowKey, DayNum: dd.DayNum, CellText: If(mins > 0, Text(mins), ""), CellNum: mins, IsAbsent: false, State: If(shade && mins > 0, "flag", shade, "nonschool", "plain")}
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    )
);
Set(varRdsLoading, false)
```

The Switch default arm is the CLIN shape (Kind "CLIN" is the only remaining kind). Read-only: no direction semantics.

### Collection schemas (screen-owned)

| Collection | Fields |
| --- | --- |
| colRdsMonthPairs | StudentId GUID, FunderId GUID (one per delivery in the month) |
| colRdsPageLog | DayNum, RowCount |
| colRdsTerms | CampusId GUID (blank = all), StartDate, EndDate |
| colRdsCalEx | ExDate, CampusId (blank = all), TypeText, Descr |
| colRdsUploads | FileName, UploadedOn, DateFrom, DateTo, RowsIn, RowsMatched, RowsExc |
| colRdsExc | ExcId |
| colRdsFunderOpts / colRdsStudentOpts | same schema as colFunders / colStudents |
| colRdsDel | ServiceId, DayNum, Minutes |
| colRdsAtt | DayNum, Present, IsDeleted, Letter "P"/"E"/"U"/"A" |
| colRdsEnr | CampusId, CampusName, StartDate, EndDate |
| colRdsDays | DayNum, CellDate, DowLetter, InDor, IsSchoolDay, NonSchoolReason |
| colRdsRows | RowKey ("SAI" / "SS"+guid / "CL"+guid), Kind ("SAI"/"DAY"/"CLIN"), SortKey, Label, ShortLabel, ServiceId, NonSchool, IsBillable, UnitText, StartDate, EndDate |
| colRdsCells | RowKey, DayNum, CellText, CellNum, IsAbsent, State ("plain"/"excused"/"unexcused"/"nonschool"/"flag"/"outside") |

Assumption: at most one non-deleted Attendance row per student per day (the attendance app records the SPED service
only); the first match is used.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| RF-RDS-STUDENT | header | student + key | colStudents | lblRdsDocStudent | see header | 16 Semibold, 1 line |
| RF-RDS-FUNDER / RF-RDS-MONTH | header | funder abbr, name, type; month | colFunders, varRdsMonth | lblRdsDocMeta1 | see header | 2-line budget |
| RF-RDS-CAMPUS / RF-RDS-DOR | header | campus; DoR for month | varRdsCampusText, colDor | lblRdsDocMeta2 | see header | 2-line budget |
| RF-RDS-ROWLABEL | grid row | code + name (+ #n, not billable) | colRdsRows.Label | lblRdsRowLabel | `ThisItem.Label & ...` | 220 wide, 2 lines at Size 11 in 44 |
| RF-RDS-CELL | grid cell | value + state colour | colRdsCells | lblRdsCell | `ThisItem.CellText`, Fill Switch | every day column |
| RF-RDS-TOTAL | grid row | total + sub-line | colRdsCells.CellNum | lblRdsRowTotalMain/Sub | see Grid | 18 + 16 + 4 padding = 38 <= 44 |
| RF-RDS-DAYHEAD | grid header | day number + letter | colRdsDays | lblRdsDayNum, lblRdsDayDow | see Grid | 2 + 18 + 14 + 2 = 36 <= 40 |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| SV-RDS-GATE | conRdsGate | `=!IsFinance` | non-finance only |
| SV-RDS-PICKERS | conRdsPickers | `=IsFinance` | finance |
| SV-RDS-EMPTY | conRdsEmpty | `=IsFinance && (IsBlank(varRdsFunderId) \|\| IsBlank(varRdsStudentId))` | until both chosen |
| SV-RDS-DOC | conRdsDoc | `=IsFinance && !IsBlank(varRdsFunderId) && !IsBlank(varRdsStudentId)` | both chosen |
| SV-RDS-NOROWS | lblRdsNoRows | `=CountRows(colRdsRows) = 0` | no rows / loading |
| SV-RDS-GRID | conRdsGridScroll | `=CountRows(colRdsRows) > 0` | rows exist |

## Required Actions

All from the plan index; read-only, write/proof sets N/A.

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Observer and evidence |
| --- | --- | --- | --- | --- | --- |
| A-RDS-NAV | IsFinance | `btnRdsNav*.OnSelect` (Rds current) | N/A | navigation | current button teal |
| A-RDS-GATE | !IsFinance | load engine `!IsFinance` branch | IsFinance | collections cleared; gate only | conRdsGate |
| A-RDS-LOAD | IsFinance | `RdsScreen.OnVisible: =Select(btnRdsLoadEngine)` | 5 shared tables; default month | collections, varRdsMonth set once | lblRdsMonth, lblRdsStatus |
| A-RDS-MONTH-PREV / -NEXT | !varRdsLoading | btnRdsPrevMonth / btnRdsNextMonth | varRdsMonth | Date() month -1 / +1; month engine | lblRdsMonth |
| A-RDS-MONTH-OPTS | month set | btnRdsMonthEngine | day-paged deliveries + month tables | options, page log, footer sources; invalid funder cleared | ddRdsFunder, lblRdsStatus |
| A-RDS-FUNDER / A-RDS-STUDENT | options loaded | dd OnChange (guarded) | FunderId / StudentId | var set; grid engine | ddRdsStudent, conRdsDoc |
| A-RDS-KEEP | month/funder change | engines | var IDs | kept if in rebuilt options else Blank | dropdown Default |
| A-RDS-GRID | both set | btnRdsGridEngine | per-selection tables | days, rows, cells, campus text | grid, totals |
| A-RDS-EMPTY | incomplete / no rows | Visible predicates | state | empty texts | lblRdsEmptyText, lblRdsNoRows |

## Functional Test Scenarios

Copy of the plan-index matrix rows S-RDS-* (all are exercised on this screen): S-RDS-NAV, S-RDS-GATE,
S-RDS-MONTH-DEFAULT, S-RDS-MONTH-PREV, S-RDS-MONTH-NEXT, S-RDS-FUNDER-OPTS, S-RDS-STUDENT-OPTS, S-RDS-KEEP,
S-RDS-KEEP-INVALID, S-RDS-HEADER, S-RDS-GRID-COLS, S-RDS-SAI, S-RDS-SAI-ABSENT, S-RDS-SAI-DORPART, S-RDS-DAYSVC,
S-RDS-DAYSVC-MULTI, S-RDS-CLIN, S-RDS-CLIN-NOTBILL, S-RDS-RC, S-RDS-PRIVPAY, S-RDS-SHADE, S-RDS-SHADE-NS, S-RDS-FLAG,
S-RDS-RC-WEEKEND, S-RDS-FOOTER, S-RDS-NOUPLOAD, S-RDS-READONLY, S-RDS-EMPTY-SEL, S-RDS-EMPTY-NOFUNDERS,
S-RDS-EMPTY-ROWS, S-RDS-DELEG, S-RDS-LOAD-FAIL, S-RDS-FIT-1366, S-RDS-FIT-1024. Given/When/Then text:
`C:\src\aaca-attendance\docs\app-builds\build-7-rds-grid\canvas-app-plan.md` (Functional Test Matrix). Key traces:
SAI "1" = colRdsAtt Present on an InDor day; flag = CLIN mins > 0 on !IsSchoolDay for !NonSchool; totals =
Sum(colRdsCells.CellNum) per RowKey.

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| ddRdsFunder | lblRdsFunderCap `Text: ="Funder"` | conRdsFunderField |
| ddRdsStudent | lblRdsStudentCap `Text: ="Student"` | conRdsStudentField |

## Layout and Numeric Budgets

- Root inner 1366 -> 1334; panel inner w: 1366 -> 1300, 1024 -> 958, 640 -> 574.
- `conRdsNav`: 5 x 110 + 4 x 8 = 582 <= 608.
- `conRdsPickerRow`: 356 + 460 + 320 + 24 = 1160 (1 line at 1366); 356 + 12 + 460 = 828 (2 lines at 1024); 3 lines
  below (each field <= 460 <= 574). Field group 18 + 4 + 44 = 66. Month row 96 + 8 + 140 + 8 + 96 = 348 <= 356.
- `conRdsPickers`: 16 + rowH + 8 + 36 + 16 (1366: 142; 1024: 220).
- Grid at 1366: inner = Max(1300, 330 + 30 x 31 = 1260) = 1300; day = RoundDown(970 / 31) = 31; label 220 + 961 +
  total 119 = 1300, no horizontal scroll. At 1024: inner 1260 > 958, day 30, total 110, `conRdsGridScroll` scrolls.
  Rows: TemplateSize 44; label 2 lines x ~15 = 30 <= 44; cell 3-4 digits at Size 11 <= 30 px; total 38 <= 44.
- `conRdsDocHead` 144; legend 1004 wide -> 28 / 64 / 100; footer legendH + 206; doc height formula above.
- Text fit: month "September 2026" Size 15 in 140; status/meta/data note 2-line (36-40) budgets; chips sized to text.

## Relevant Data Source Schemas (read only)

- Service Deliveries: Date (Date), Minutes (Number), Student / Funder / Service lookups.
- Attendance: Date, Present (Boolean), 'Is Deleted' (Boolean), 'Absence Classification' (choice
  'Absence Classification (Attendance)': Excused, Unexcused), Student lookup.
- Enrollments: Student, Campus lookups; 'Start Date', 'End Date' (blank = open). Campuses: Campus (GUID), Name.
- Terms: Campus (blank = all), 'Start Date', 'End Date'. Calendar Exceptions: Date, Campus (blank = all),
  Type (Holiday, Break, Staff Development, Closure, Make-up School Day), Description (primary name).
- CodeMetro Uploads: 'File Name', 'Uploaded On', 'Date From', 'Date To', 'Rows In', 'Rows Matched',
  'Rows in Exceptions', 'Status (aaca_status)' ('Status (CodeMetro Uploads)'.Complete).
- Upload Exceptions: 'Upload Exception' (GUID), 'Appt Date', 'Status (aaca_status)' ('Status (Upload Exceptions)'.Open).
- Funders, Services, Students, Districts of Record, Student Services: via shared collections (fields above).

## Required Variants

- GroupContainer -> `Variant: AutoLayout` (every container)
- Gallery -> `Variant: Vertical` (galRdsRows), `Variant: Horizontal` (galRdsDayHead, galRdsCells)

## Control Definitions

- GroupContainer (`Control: GroupContainer`): BorderColor, BorderStyle, BorderThickness, DropShadow
  (`=DropShadow.None`), Fill, Height, Radius{BottomLeft,BottomRight,TopLeft,TopRight}, Visible, Width,
  LayoutAlignItems (`=LayoutAlignItems.Stretch|Center|Start`), LayoutDirection (`=LayoutDirection.Vertical|Horizontal`),
  LayoutGap, LayoutJustifyContent, LayoutOverflowX / LayoutOverflowY (`=LayoutOverflow.Scroll`), LayoutWrap,
  PaddingBottom/Left/Right/Top; as child: AlignInContainer (`=AlignInContainer.Stretch|Center|Start`), FillPortions,
  LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth.
- ModernText (`Control: ModernText`): AccessibleLabel, Align (`=Align.Center|Left|Right`), AutoHeight, BorderColor,
  BorderStyle, BorderThickness, Color, DisplayMode, Fill, Font, FontWeight (`=FontWeight.Bold|Semibold|Normal`), Height,
  Italic, PaddingBottom/Left/Right/Top, Radius*, Size, Text, VerticalAlign (`=VerticalAlign.Top|Middle|Bottom`), Visible,
  Width, Wrap; child: AlignInContainer, FillPortions, LayoutMinHeight, LayoutMinWidth.
- ModernButton (`Control: ModernButton`; no Fill): AccessibleLabel, Appearance (`=ButtonAppearance.Secondary`),
  BasePaletteColor, Color, DisplayMode (`=DisplayMode.Disabled|Edit`), FontWeight, Height, Layout
  (`=ButtonLayout.TextOnly`), OnSelect, Size, Text, Tooltip, Visible, Width; child: AlignInContainer, FillPortions,
  LayoutMinHeight, LayoutMinWidth.
- ModernDropdown (`Control: ModernDropdown`): AccessibleLabel, Appearance (`=Appearance.Outline`), BasePaletteColor,
  Color, Default, DisplayMode, Fill, FontWeight, Height, ItemDisplayText, Items, OnChange, Required, Size, Visible,
  Width; output Selected; child: AlignInContainer, FillPortions, LayoutMinHeight, LayoutMinWidth.
- Gallery (`Control: Gallery` + Variant): AccessibleLabel, BorderColor, BorderThickness, DelayItemLoading, Fill, Height,
  Items, LoadingSpinner, Selectable, ShowNavigation, ShowScrollbar, TabIndex, TemplatePadding, TemplateSize, Visible,
  Width, WrapCount; outputs TemplateWidth, TemplateHeight; child: AlignInContainer, FillPortions, LayoutMinHeight,
  LayoutMinWidth.
- Classic/Button (`Control: Classic/Button`; engines only; no AccessibleLabel): AutoDisableOnSelect, OnSelect, Text,
  Visible, Height, Width; child: AlignInContainer, FillPortions, LayoutMinHeight, LayoutMinWidth.

## Builder Notes

- Values containing `: ` or ` #`: lblRdsStatus, lblRdsNoRows, lblRdsDocMeta1/2, lblRdsLegFlag, lblRdsTotals,
  lblRdsDataNote, every engine and any record literal -> `|-` blocks. Grep the file for ` #` and `: ` in plain scalars.
- No Patch, Remove, Notify-as-proof, Print or export anywhere. No symbol glyphs in button text.
- Do not set `Variant` on ModernText/ModernButton/ModernDropdown/Classic/Button.
