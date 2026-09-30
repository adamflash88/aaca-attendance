# Screen Plan: Attendance (Screen1)

## Assignment

- Action: Create
- Target file: `C:\src\aaca-attendance\app\Screen1.pa.yaml` (replace the empty screen wholesale)
- YAML key: `Screen1`
- Control name prefix: `Att`
- Read with: `C:\src\aaca-attendance\app\canvas-app-shared.md` (palette names, type roles,
  named state, YAML conventions). `App.pa.yaml` already defines every `Color*`, role and
  settings named formula and initialises all variables listed in the shared plan.

This screen is ~85 controls (above the usual 40) because the approved plan is a single
screen. Most controls are small; the complexity lives in five formulas given verbatim below
(ATT_ROW, the three engines, the cell view-model). Copy them exactly.

## Specification

- Purpose: monthly attendance register (student x day grid) with per-cell upsert, soft
  delete, day bulk "All present", totals, detail panel, and a phone Day view.
- Screen properties: `Fill: =ColorPaper`; `OnVisible: =Select(btnAttLoadEngine)`.
- Breakpoint source: `conAttRoot.Width` everywhere (written as `W` below). Phone `W < 640`,
  tablet `W < 1024`, wide toolbar `W >= 1240`. Narrowest section inner width 358.
- All engines are invisible Classic/Buttons inside the root; other controls call
  `Select(btnAtt…Engine)` after setting the request variable.

### Control tree (order = render order; every GroupContainer is `Variant: AutoLayout` with `LayoutMinWidth: =0`, `LayoutMinHeight: =0`)

Notation: `H`=Height, `Wd`=Width, `FP`=FillPortions, `AIC`=AlignInContainer, `pad`=PaddingTop/Bottom/Left/Right,
`gap`=LayoutGap, `dir`=LayoutDirection. Every AutoLayout child sets `AIC` and `FP` explicitly and the
`LayoutMinWidth`/`LayoutMinHeight` shown (default `=0`). Every ModernText sets all four Padding* (0 unless stated).

```
Screen1
└─ conAttRoot  dir V · Wd =Parent.Width · H =Parent.Height · LayoutOverflowY Scroll · LayoutAlignItems Stretch
   │           gap 8 · PaddingBottom 16 · Fill =ColorPaper · radii 0
   ├─ conAttHeader  dir V · FP 0 · H =If(W<640,92,76) · Fill =ColorInk · pad 12/12/16/16 · gap 4 · Stretch · radii 0
   │   ├─ lblAttTitle     H 28 · Text "AACA Attendance" · Size 20 Bold · Color =ColorWhite · Wrap false
   │   └─ lblAttIdentity  H =If(W<640,36,20) · Size 12 · Color =ColorInkSoft · Wrap true
   ├─ conAttNotSetUp  dir V · FP 0 · H =If(W<640,156,112) · Visible =!StaffReady · white card · pad 16 · gap 8 · Stretch
   │   ├─ lblAttNotSetUpTitle  H 24 · "You're not set up yet" · Size 16 Semibold · Color =ColorInk
   │   └─ lblAttNotSetUpBody   H =If(W<640,92,48) · Size 14 · Color =ColorInk · Wrap true
   ├─ conAttToolbar  dir =If(W>=1240,Horizontal,Vertical) · FP 0 · H =If(W>=1240,74,206) · Visible =StaffReady
   │   │             white card · pad 8/8/16/16 · gap 8 · LayoutAlignItems Stretch
   │   ├─ conAttMonthNav  dir H · FP 0 · Wd 380 · H 58 · AIC Stretch · gap 8 · LayoutAlignItems Center
   │   │   ├─ btnAttPrevMonth  ModernButton · Wd 44 · H 44 · Text "◀" · Secondary · AccessibleLabel "Previous month"
   │   │   ├─ lblAttMonth      FP 1 · LayoutMinWidth 100 · H 28 · Text =Text(varMonthStart,"mmmm yyyy") · Size 16 Bold · Wrap false
   │   │   ├─ btnAttNextMonth  ModernButton · Wd 44 · H 44 · Text "▶" · Secondary · AccessibleLabel "Next month"
   │   │   └─ btnAttThisMonth  ModernButton · Wd 88 · H 44 · Text "This month" · Secondary
   │   ├─ conAttScope  dir H · FP =If(W>=1240,1,0) · LayoutMinWidth 300 · H 58 · AIC Stretch · gap 8
   │   │   ├─ conAttCampusField   dir V · FP 1 · LayoutMinWidth 146 · gap 4 · Stretch
   │   │   │   ├─ lblAttCampus    H 18 · Text "Campus" · Size 12 · Color =ColorMuted
   │   │   │   └─ ddAttCampus     H 36 · AIC Stretch · FP 0
   │   │   └─ conAttTeacherField  dir V · FP 1 · LayoutMinWidth 146 · gap 4 · Stretch
   │   │       ├─ lblAttTeacher   H 18 · Text "Teacher" · Size 12 · Color =ColorMuted
   │   │       └─ ddAttTeacher    H 36 · AIC Stretch · FP 0
   │   └─ conAttViewGroup  dir H · FP 0 · Wd 350 · H 58 · AIC Stretch · gap 8 · LayoutAlignItems Center
   │       ├─ tabAttView         Wd 160 · H 44
   │       ├─ btnAttDetailsMode  ModernButton · Wd 130 · H 44
   │       └─ btnAttReload       ModernButton · Wd 44 · H 44 · Text "↻" · Secondary · AccessibleLabel "Reload month"
   ├─ conAttNotice  dir H · FP 0 · H =If(W<640,68,W<1024,56,44) · Visible =StaffReady && lblAttNotice.Text <> ""
   │   │            pad 4/4/12/12 · LayoutAlignItems Center · Fill =If(varLoadError<>"",ColorErrorBg,ColorWarnBg) · border ColorRule 1
   │   └─ lblAttNotice  FP 1 · AIC Stretch · Size 13 · Color =ColorInk · Wrap true · VerticalAlign Middle
   ├─ spnAttLoading  ModernSpinner · FP 0 · H 48 · AIC Stretch · Visible =varLoading
   ├─ conAttReceipt  dir H · FP 0 · H =If(W<640,124,W<1024,64,56) · Visible =varLastAction.Kind <> ""
   │   │             pad 6/6/12/12 · gap 8 · LayoutAlignItems Center · border ColorRule 1 · Fill (see Receipt)
   │   ├─ lblAttReceipt         FP 1 · AIC Stretch · Size 13 · Color =ColorInk · Wrap true · VerticalAlign Middle
   │   └─ btnAttReceiptDismiss  ModernButton · FP 0 · Wd 88 · H 44 · Text "Dismiss" · Secondary
   ├─ conAttConfirm  dir V · FP 0 · H =If(W<640,140,116) · Visible =varConfirmOpen · Fill =ColorErrorBg · border ColorUnexcused 1
   │   │             pad 12 · gap 8 · Stretch
   │   ├─ lblAttConfirmText  H =If(W<640,64,40) · Size 14 · Color =ColorInk · Wrap true
   │   └─ conAttConfirmActions  dir H · FP 0 · H 44 · gap 8 · Stretch
   │       ├─ btnAttConfirmClear   Wd 132 · H 44 · Text "Confirm clear" · Destructive
   │       └─ btnAttConfirmCancel  Wd 96 · H 44 · Text "Cancel" · Secondary
   ├─ conAttDetail  dir V · FP 0 · H =If(W<640,308,264) · Visible =varDetailOpen · white card · pad 16 · gap 8 · Stretch
   │   ├─ lblAttDetailTitle  H =If(W<640,44,24) · Size 16 Semibold · Color =ColorInk · Wrap true
   │   ├─ lblAttDetailFacts  H =If(W<640,68,44) · Size 13 · Color =ColorInk · Wrap true
   │   ├─ conAttDetailNotesField  dir V · FP 0 · H 96 · gap 4 · Stretch
   │   │   ├─ lblAttDetailNotesLabel  H 20 · Text "Notes" · Size 12 Semibold · Color =ColorMuted
   │   │   └─ txtAttDetailNotes       H 72 · FP 0 · AIC Stretch
   │   └─ conAttDetailActions  dir H · FP 0 · H 44 · gap 8 · Stretch
   │       ├─ btnAttDetailSave   Wd 120 · H 44 · Text "Save notes" · Primary
   │       └─ btnAttDetailClose  Wd 88 · H 44 · Text "Close" · Secondary
   ├─ conAttMonthView  dir V · FP 0 · H =MonthViewH · Visible =StaffReady && tabAttView.Selected.Value <> "Day"
   │   │               white card · pad 16 · gap 8 · Stretch
   │   ├─ lblAttLegend  H =LegendH · Size 12 · Color =ColorMuted · Wrap true
   │   ├─ lblAttEmpty   H 48 · Size 14 · Color =ColorInk · Wrap true · Visible =CountRows(colMonthStudents) = 0 && !varLoading
   │   └─ conAttGridScroll  dir H · FP 0 · H =GridScrollH · LayoutOverflowX Scroll · Stretch · gap 0 · radii 0
   │       │                Visible =CountRows(colMonthStudents) > 0
   │       └─ conAttGridInner  dir V · FP 0 · Wd =Max(Parent.Width, 236 + 34 * Max(28, CountRows(colMonthDays)))
   │           │               AIC Stretch · gap 0 · LayoutAlignItems Stretch · radii 0
   │           ├─ conAttGridHeader  dir H · FP 0 · H 64 · gap 0 · Fill =ColorPaper
   │           │   ├─ lblAttHeadName   FP 0 · Wd 180 · AIC Stretch · "Student" · Size 12 Bold · PaddingLeft 8 · VerticalAlign Bottom
   │           │   ├─ galAttDayHead    Gallery Horizontal · FP 0 · Wd =CountRows(colMonthDays) * CellW · AIC Stretch
   │           │   │   └─ conAttDayHeadCell  dir V · Wd =Parent.TemplateWidth · H =Parent.TemplateHeight · pad 2/2/1/1 · gap 0
   │           │   │       ├─ lblAttDayHeadDow  H 16 · Size 9 · Align Center · Color =ColorMuted · Wrap false
   │           │   │       ├─ lblAttDayHeadNum  H 18 · Size 12 Bold · Align Center · Wrap false
   │           │   │       └─ btnAttDayAll      Classic/Button · H 26 · FP 0 · AIC Stretch · "All"
   │           │   └─ lblAttHeadTotal  FP 1 · AIC Stretch · "Present" · Size 11 Bold · Align Center · VerticalAlign Bottom
   │           ├─ galAttRows  Gallery Vertical · FP 0 · H =RowsH · AIC Stretch
   │           │   └─ conAttRowShell  dir H · Wd =Parent.TemplateWidth · H =Parent.TemplateHeight · gap 0 · Fill =ColorWhite · radii 0
   │           │       ├─ lblAttRowName   FP 0 · Wd 180 · AIC Stretch · Size 12 · Wrap true · PaddingLeft 8 · VerticalAlign Middle
   │           │       ├─ galAttCells     Gallery Horizontal · FP 0 · Wd =CountRows(colMonthDays) * CellW · AIC Stretch
   │           │       │   └─ btnAttCell  Classic/Button (single child, no X/Y)
   │           │       └─ lblAttRowTotal  FP 1 · AIC Stretch · Size 12 Semibold · Align Center
   │           └─ conAttGridFooter  dir H · FP 0 · H 36 · gap 0 · Fill =ColorPaper
   │               ├─ lblAttFootName   FP 0 · Wd 180 · AIC Stretch · "Present per day" · Size 12 Semibold · PaddingLeft 8
   │               ├─ galAttDayTotals  Gallery Horizontal · FP 0 · Wd =CountRows(colMonthDays) * CellW · AIC Stretch
   │               │   └─ lblAttDayTotal  ModernText single child · Wd =Parent.TemplateWidth · H =Parent.TemplateHeight
   │               └─ lblAttFootTotal  FP 1 · AIC Stretch · Size 12 Bold · Align Center
   ├─ conAttDayView  dir V · FP 0 · H =DayViewH · Visible =StaffReady && tabAttView.Selected.Value = "Day"
   │   │             white card · pad 16 · gap 8 · Stretch
   │   ├─ conAttDayNav  dir H · FP 0 · H 44 · gap 8 · LayoutAlignItems Center · Stretch
   │   │   ├─ btnAttPrevDay        Wd 44 · H 44 · "◀" · Secondary · AccessibleLabel "Previous day"
   │   │   ├─ lblAttDayDate        FP 1 · LayoutMinWidth 100 · H 28 · Text =Text(varViewDate,"ddd mmm d") · Size 14 Bold · Wrap false
   │   │   ├─ btnAttNextDay        Wd 44 · H 44 · "▶" · Secondary · AccessibleLabel "Next day"
   │   │   └─ btnAttDayAllPresent  Wd 120 · H 44 · "All present" · Primary
   │   ├─ lblAttDayNotice  H 48 · Size 13 · Color =ColorInk · Wrap true · Visible =Self.Text <> ""
   │   └─ galAttDayList  Gallery Vertical · FP 0 · H =DayListH · AIC Stretch · Visible =DayCount > 0
   │       └─ conAttDayRow  dir V · Wd =Parent.TemplateWidth · H =Parent.TemplateHeight · pad 8/8/12/12 · gap 4
   │           │            Fill =ColorWhite · BorderColor =ColorRule · BorderThickness 1 · radii 6 · LayoutAlignItems Stretch
   │           ├─ lblAttDayName    H 24 · Size 14 Semibold · Color =ColorInk · Wrap false
   │           ├─ lblAttDayStatus  H 20 · Size 12 · Wrap false
   │           └─ conAttDayActions  dir H · FP 0 · H 44 · gap 8
   │               ├─ btnAttDayPresent  Wd 100 · H 44 · "Present" · Primary · BasePaletteColor =ColorPresent · Color =ColorWhite
   │               ├─ btnAttDayAbsent   Wd 100 · H 44 · "Absent"  · Primary · BasePaletteColor =ColorAbsent  · Color =ColorWhite
   │               └─ btnAttDayClear    Wd 88  · H 44 · "Clear"   · Secondary · Visible =ThisItem.HasRecord
   ├─ btnAttSaveEngine  Classic/Button · Visible false · AutoDisableOnSelect false · Text "save"
   ├─ btnAttBulkEngine  Classic/Button · Visible false · AutoDisableOnSelect false · Text "bulk"
   └─ btnAttLoadEngine  Classic/Button · Visible false · AutoDisableOnSelect false · Text "load"
```

"white card" = `Fill: =ColorWhite`, `BorderColor: =ColorRule`, `BorderThickness: =1`, four radii 6,
`DropShadow: =DropShadow.None`. Children of vertical containers: `AIC Stretch` unless stated; children
of horizontal containers with `LayoutAlignItems Center`: `AIC Center` for fixed-height buttons/labels.
For every ModernButton in a horizontal row set `FillPortions: =0`, `Width`, `Height`,
`LayoutMinWidth: =0`, `LayoutMinHeight: =0`. Secondary buttons use `Color: =ColorInk`; Primary use
`BasePaletteColor: =ColorTeal`, `Color: =ColorWhite` unless stated. Destructive (`btnAttConfirmClear`) =
Primary with `BasePaletteColor: =ColorUnexcused`, `Color: =ColorWhite`. All ModernButtons are
`Layout: =ButtonLayout.TextOnly`, `Size: =14`.

### Size expressions (write the expression inline wherever the name appears; never read descendant `.Height`)

- `W` = `conAttRoot.Width`
- `CellW` = `RoundDown((conAttGridInner.Width - 236) / Max(1, CountRows(colMonthDays)), 0)`
- `RowsH` = `Min(528, Max(132, 44 * CountRows(colMonthStudents)))`
- `GridScrollH` = `64 + Min(528, Max(132, 44 * CountRows(colMonthStudents))) + 36 + 14`
- `LegendH` = `If(conAttRoot.Width < 640, 84, conAttRoot.Width < 1024, 44, 24)`
- `MonthViewH` = `16 + LegendH + 8 + If(CountRows(colMonthStudents) = 0, 48, GridScrollH) + 16`
- `DayCount` = `CountRows(Filter(colMonthCells, DayNum = Day(varViewDate) && (State = "Open" || State = "Future")))`
- `DayListH` = `Min(620, Max(124, 124 * DayCount))`
- `DayViewH` = `16 + 44 + 8 + If(lblAttDayNotice.Text <> "", 56, 0) + If(DayCount = 0, 0, DayListH) + 16`

### Numeric layout budgets

| Container / branch | Horizontal arithmetic | Vertical arithmetic |
| --- | --- | --- |
| conAttHeader | N/A (vertical) | 12+28+4+20+12 = 76; phone 12+28+4+36+12 = 92 |
| conAttToolbar W>=1240 (H) | 16+380+8+B(min 300)+8+350+16 = 1078 ≤ 1240 → B = 462 at threshold | 8+58+8 = 74 |
| conAttToolbar W<1240 (V) | each group stretches to W−32; phone 358 | 8+58+8+58+8+58+8 = 206 |
| conAttMonthNav | 44+8+label+8+44+8+88 = 200+label; label min 100 → 300 ≤ 358 (phone), 380 (wide) → label 158–180 fits "September 2026" at 16 | 58 ≥ 44 button |
| conAttScope | 146+8+146 = 300 ≤ 358 | label 18 + 4 + dropdown 36 = 58 |
| conAttViewGroup | 160+8+130+8+44 = 350 ≤ 358 | 58 ≥ 44 |
| conAttNotice | 12+text+12 | phone 3 lines×20+8 = 68; tablet 2 lines 48 ≤ 56; desktop 1 line ≤ 44 |
| conAttReceipt | 12+text+8+88+12; phone text 238 px | phone 6 lines×18+12 = 120 ≤ 124; tablet 2 lines 48 ≤ 64; desktop 1 line + 44 button ≤ 56 |
| conAttConfirm | 132+8+96 = 236 ≤ 334 | phone 12+64+8+44+12 = 140; desktop 12+40+8+44+12 = 116 |
| conAttDetail | 120+8+88 = 216 ≤ 326 | desktop 16+24+8+44+8+96+8+44+16 = 264; phone 16+44+8+68+8+96+8+44+16 = 308 |
| conAttDetailNotesField | N/A | 20+4+72 = 96 |
| conAttGridInner | 180 + days×CellW + total(FP1) = Wd; Wd ≥ 236+34×days; 1366 desktop → scroll width 1334 ≥ 1290 (31 days) → no scroll, CellW 35; 1024 → Wd 1290, CellW 34, horizontal scroll | 64 + RowsH + 36 |
| conAttDayHeadCell | CellW (34–40) | 2+16+18+26+2 = 64 |
| conAttRowShell | same columns as header | TemplateSize 44; name 2 lines at Size 12 ≈ 36 ≤ 44 |
| conAttDayNav | 44+8+label+8+44+8+120 = 232+label; phone label 126 ≥ "Mon Sep 28" at 14 (~90) | 44 |
| conAttDayRow | actions 100+8+100+8+88 = 304 ≤ 358−24−scrollbar(≤12) = 322 | 8+24+4+20+4+44+8 = 112 ≤ TemplateSize 116 |

Cell touch target: 34–40 px wide × 40 px high (desktop mouse density, approved dense
register). Approximation: phone users get the Day view with 44 px buttons (default below 640).

## Galleries

| Gallery | Variant | Items | TemplateSize | TemplatePadding | Height | Other |
| --- | --- | --- | --- | --- | --- | --- |
| galAttDayHead | Horizontal | `=colMonthDays` | `=CellW` | 0 | stretch (64) | ShowScrollbar false, ShowNavigation false, Selectable false, LayoutMinWidth 0, LayoutMinHeight 0, AccessibleLabel "Day columns" |
| galAttRows | Vertical | `=colMonthStudents` | 44 | 0 | `=RowsH` | ShowScrollbar true, Selectable false, LayoutMinWidth 0, LayoutMinHeight 0, AccessibleLabel "Students in " & month |
| galAttCells | Horizontal | CELL_ITEMS (below) | `=CellW` | 0 | stretch (44) | ShowScrollbar false, ShowNavigation false, Selectable false, LayoutMinWidth 0, LayoutMinHeight 0, AccessibleLabel ="Days for " & ThisItem.StudentName |
| galAttDayTotals | Horizontal | `=colMonthDays` | `=CellW` | 0 | stretch (36) | as galAttDayHead; AccessibleLabel "Students present per day" |
| galAttDayList | Vertical | DAY_ITEMS (below) | 116 | 4 | `=DayListH` | ShowScrollbar true, Selectable false, LayoutMinWidth 0, LayoutMinHeight 0, AccessibleLabel "Students for " & date |

All galleries keep `DisplayMode` at default Edit (no read-only ancestors).

## Exact formulas

`ATT_ROW(…)` and `WORD(…)` below are textual macros, not Power Fx functions. Wherever a
formula says `ATT_ROW(r)`, `ATT_ROW(server)`, `ATT_ROW(written)` or `WORD(written)`, paste the
macro body with `x` replaced by that name. Do not create a user-defined function.

### ATT_ROW(x) — projection of an Attendance record `x` into `colMonthAtt` (paste with `x` replaced)

```
{
    AttId: x.Attendance,
    StudentId: x.Student.Student,
    DayNum: Day(x.Date),
    AttDate: x.Date,
    Present: x.Present = true,
    IsDeleted: x.'Is Deleted' = true,
    Letter: If(x.Present = true, "P", x.'Absence Classification' = 'Absence Classification (Attendance)'.Excused, "E", x.'Absence Classification' = 'Absence Classification (Attendance)'.Unexcused, "U", "A"),
    ClassText: If(x.Present = true, "—", IsBlank(x.'Absence Classification'), "Not classified", Text(x.'Absence Classification')),
    IepText: Text(x.'IEP Ratio'),
    Notes: x.Notes,
    RecordKey: x.'Record Key',
    ModifiedOn: x.'Modified On'
}
```

WORD(x) = `If(x.Present = true, "Present", x.'Absence Classification' = 'Absence Classification (Attendance)'.Excused, "Absent (excused)", x.'Absence Classification' = 'Absence Classification (Attendance)'.Unexcused, "Absent (unexcused)", "Absent (not classified)")`

### btnAttLoadEngine.OnSelect (A-LOAD-MONTH)

```
=Set(varLoading, true);
Set(varLoadError, "");
Set(varMonthEnd, DateAdd(DateAdd(varMonthStart, 1, TimeUnit.Months), -1, TimeUnit.Days));
Set(varDetailOpen, false);
Set(varConfirmOpen, false);
Clear(colCellState);
If(
    !StaffReady || IsBlank(varTeacher),
    Clear(colMonthEnr); Clear(colMonthAtt); Clear(colMonthExceptions); Clear(colMonthTerms);
    Clear(colMonthDays); Clear(colMonthStudents); Clear(colMonthCells),
    IfError(
        Concurrent(
            ClearCollect(
                colMonthEnr,
                ForAll(
                    Filter(Enrollments, Teacher.Staff = varTeacher.Staff && 'Start Date' <= varMonthEnd && (IsBlank('End Date') || 'End Date' >= varMonthStart)) As e,
                    {
                        EnrId: e.Enrollment,
                        StudentId: e.Student.Student,
                        StudentName: e.Student.'Display Name',
                        StudentNumber: e.Student.'Student Number',
                        ServiceId: e.Service.Service,
                        ServiceCode: e.Service.'Service Code',
                        StartDate: e.'Start Date',
                        EndDate: e.'End Date',
                        IsSummer: e.Program = 'Program (Enrollments)'.Summer,
                        IepText: Text(e.'IEP Ratio'),
                        EnrRec: e
                    }
                )
            ),
            ClearCollect(
                colMonthAtt,
                ForAll(
                    Filter(Attendance, Teacher.Staff = varTeacher.Staff && Date >= varMonthStart && Date <= varMonthEnd) As r,
                    ATT_ROW(r)
                )
            ),
            ClearCollect(colMonthExceptions, Filter('Calendar Exceptions', Date >= varMonthStart && Date <= varMonthEnd)),
            ClearCollect(colMonthTerms, Filter(Terms, 'Start Date' <= varMonthEnd && 'End Date' >= varMonthStart)),
            Set(varMonthLock, LookUp('Month Locks', Campus.Campus = varCampus.Campus && Month = varMonthStart && 'Status (aaca_status)' = 'Status (Month Locks)'.Locked))
        ),
        Set(varLoadError, FirstError.Message)
    );
    Clear(colMonthDays);
    ForAll(
        Sequence(Day(varMonthEnd)) As n,
        With(
            {d: Date(Year(varMonthStart), Month(varMonthStart), n.Value)},
            With(
                {
                    t: First(Filter(colMonthTerms, ThisRecord.'Start Date' <= d && ThisRecord.'End Date' >= d && (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = varCampus.Campus))),
                    x: LookUp(colMonthExceptions, ThisRecord.Date = d && (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = varCampus.Campus) && ThisRecord.Type <> 'Type (Calendar Exceptions)'.'Make-up School Day'),
                    mk: !IsBlank(LookUp(colMonthExceptions, ThisRecord.Date = d && (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = varCampus.Campus) && ThisRecord.Type = 'Type (Calendar Exceptions)'.'Make-up School Day')),
                    wkend: Weekday(d, StartOfWeek.Monday) >= 6
                },
                Collect(
                    colMonthDays,
                    {
                        DayNum: n.Value,
                        CellDate: d,
                        DowLabel: Text(d, "ddd"),
                        TermId: t.'Term (aaca_termid)',
                        TermKind: If(IsBlank(t), "", t.'Term (aaca_term)' = 'Term (Terms)'.Summer, "Summer", "Regular"),
                        IsSchoolDay: !IsBlank(t) && (mk || (!wkend && IsBlank(x))),
                        NonSchoolReason: If(IsBlank(t), "Outside any term", mk, "", !IsBlank(x), Text(x.Type) & " – " & x.Description, wkend, "Weekend", "")
                    }
                )
            )
        )
    );
    ClearCollect(
        colMonthStudents,
        Sort(
            ForAll(
                Distinct(colMonthEnr, StudentId) As g,
                With({en: LookUp(colMonthEnr, StudentId = g.Value)}, {StudentId: g.Value, StudentName: en.StudentName, StudentNumber: en.StudentNumber})
            ),
            StudentName,
            SortOrder.Ascending
        )
    );
    Clear(colMonthCells);
    ForAll(
        colMonthStudents As s,
        Collect(
            colMonthCells,
            ForAll(
                colMonthDays As dd,
                With(
                    {seg: LookUp(colMonthEnr, StudentId = s.StudentId && StartDate <= dd.CellDate && (IsBlank(EndDate) || EndDate >= dd.CellDate) && IsSummer = (dd.TermKind = "Summer"))},
                    {
                        StudentId: s.StudentId,
                        StudentName: s.StudentName,
                        DayNum: dd.DayNum,
                        CellDate: dd.CellDate,
                        EnrId: seg.EnrId,
                        State: If(!dd.IsSchoolDay, "NonSchool", IsBlank(seg), "NotEnrolled", dd.CellDate > Today() && !AllowFutureDates, "Future", "Open"),
                        Reason: If(!dd.IsSchoolDay, dd.NonSchoolReason, IsBlank(seg), "Not enrolled with this teacher on this day", dd.CellDate > Today() && !AllowFutureDates, "Future date", "")
                    }
                )
            )
        )
    )
);
Set(varCanEditMonth, CanEditRole && IsBlank(varMonthLock) && varLoadError = "");
If(
    varViewDate < varMonthStart || varViewDate > varMonthEnd,
    Set(varViewDate, If(Today() >= varMonthStart && Today() <= varMonthEnd, Today(), varMonthStart))
);
Set(varLoading, false)
```

### btnAttSaveEngine.OnSelect (A-MARK-CELL, A-CLEAR-CELL, A-RETRY-CELL, A-DAY-MARK, A-VALIDATE-SAVE)

Reads `varSaveReq` = `{StudentId, DayNum, Target}` with Target "P", "A" or "clear".

```
=With(
    {
        req: varSaveReq,
        cell: LookUp(colMonthCells, StudentId = varSaveReq.StudentId && DayNum = varSaveReq.DayNum)
    },
    With(
        {
            seg: LookUp(colMonthEnr, EnrId = cell.EnrId),
            local: LookUp(colMonthAtt, StudentId = req.StudentId && DayNum = req.DayNum),
            term: LookUp(colMonthTerms, ThisRecord.'Term (aaca_termid)' = LookUp(colMonthDays, DayNum = req.DayNum).TermId),
            dateText: Text(cell.CellDate, "ddd mmm d")
        },
        If(
            IsBlank(cell) || cell.State <> "Open" || !varCanEditMonth || IsBlank(req.Target) || (req.Target = "clear" && (IsBlank(local) || local.IsDeleted)),
            Set(varLastAction, {Kind: "Blocked", Message: "Not saved · " & cell.StudentName & " · " & dateText & " · " & If(!varCanEditMonth, "month locked or view-only role", Coalesce(cell.Reason, "cell not editable")), StudentId: req.StudentId, DayNum: req.DayNum}),
            RemoveIf(colCellState, StudentId = req.StudentId && DayNum = req.DayNum);
            Collect(colCellState, {StudentId: req.StudentId, DayNum: req.DayNum, SaveState: "saving", Target: req.Target});
            With(
                {server: LookUp(Attendance, Student.Student = req.StudentId && Service.Service = seg.ServiceId && Date = cell.CellDate)},
                If(
                    IsError(server),
                    RemoveIf(colCellState, StudentId = req.StudentId && DayNum = req.DayNum);
                    Collect(colCellState, {StudentId: req.StudentId, DayNum: req.DayNum, SaveState: "failed", Target: req.Target});
                    Set(varLastAction, {Kind: "Failed", Message: "Failed · " & cell.StudentName & " · " & dateText & " · " & Switch(req.Target, "P", "Present", "A", "Absent", "Clear") & " was not saved — tap the cell (or the Day view button) to retry", StudentId: req.StudentId, DayNum: req.DayNum}),
                    (!IsBlank(local) && local.ModifiedOn <> server.'Modified On') || (IsBlank(local) && !IsBlank(server) && server.'Is Deleted' <> true),
                    RemoveIf(colMonthAtt, StudentId = req.StudentId && DayNum = req.DayNum);
                    If(!IsBlank(server), Collect(colMonthAtt, ATT_ROW(server)));
                    RemoveIf(colCellState, StudentId = req.StudentId && DayNum = req.DayNum);
                    Set(varLastAction, {Kind: "Conflict", Message: "Changed by someone else — reloaded · " & cell.StudentName & " · " & dateText & " · now " & If(IsBlank(server) || server.'Is Deleted' = true, "Not recorded", WORD(server)) & " · your change was not saved", StudentId: req.StudentId, DayNum: req.DayNum}),
                    With(
                        {
                            wasDeleted: !IsBlank(server) && server.'Is Deleted' = true,
                            written: IfError(
                                If(
                                    req.Target = "clear",
                                    Patch(Attendance, server, {'Is Deleted': true}),
                                    Patch(
                                        Attendance,
                                        Coalesce(server, Defaults(Attendance)),
                                        {
                                            'Record Key': Text(cell.CellDate, "yyyymmdd") & "|" & seg.StudentNumber & "|" & seg.ServiceCode,
                                            Date: cell.CellDate,
                                            Student: seg.EnrRec.Student,
                                            Service: seg.EnrRec.Service,
                                            Enrollment: seg.EnrRec,
                                            Teacher: varTeacher,
                                            Campus: seg.EnrRec.Campus,
                                            'School Year': seg.EnrRec.'School Year',
                                            Term: term,
                                            'IEP Ratio': Switch(
                                                seg.EnrRec.'IEP Ratio',
                                                'IEP Ratio (Enrollments)'.'No Aide', 'IEP Ratio (Attendance)'.'No Aide',
                                                'IEP Ratio (Enrollments)'.'1:1', 'IEP Ratio (Attendance)'.'1:1',
                                                'IEP Ratio (Enrollments)'.'2:1', 'IEP Ratio (Attendance)'.'2:1',
                                                'IEP Ratio (Enrollments)'.'3:1', 'IEP Ratio (Attendance)'.'3:1',
                                                'IEP Ratio (Enrollments)'.'4:1', 'IEP Ratio (Attendance)'.'4:1'
                                            ),
                                            Present: req.Target = "P",
                                            'Is Deleted': false
                                        }
                                    )
                                ),
                                Blank()
                            )
                        },
                        If(
                            IsBlank(written),
                            RemoveIf(colCellState, StudentId = req.StudentId && DayNum = req.DayNum);
                            Collect(colCellState, {StudentId: req.StudentId, DayNum: req.DayNum, SaveState: "failed", Target: req.Target});
                            Set(varLastAction, {Kind: "Failed", Message: "Failed · " & cell.StudentName & " · " & dateText & " · " & Switch(req.Target, "P", "Present", "A", "Absent", "Clear") & " was not saved — tap the cell (or the Day view button) to retry", StudentId: req.StudentId, DayNum: req.DayNum}),
                            With(
                                {
                                    audit: If(
                                        req.Target = "clear",
                                        IfError(
                                            Patch(
                                                'Audit Events',
                                                Defaults('Audit Events'),
                                                {
                                                    Summary: "Attendance soft-deleted " & written.'Record Key',
                                                    Action: 'Action (Audit Events)'.'Soft Delete',
                                                    Entity: "aaca_attendance",
                                                    'Entity ID': Text(written.Attendance),
                                                    Before: "Is Deleted=No; Present=" & If(local.Present, "Yes", "No"),
                                                    After: "Is Deleted=Yes",
                                                    Reason: "Cleared in Attendance Matrix"
                                                }
                                            ),
                                            Blank()
                                        ),
                                        Blank()
                                    )
                                },
                                RemoveIf(colMonthAtt, StudentId = req.StudentId && DayNum = req.DayNum);
                                Collect(colMonthAtt, ATT_ROW(written));
                                RemoveIf(colCellState, StudentId = req.StudentId && DayNum = req.DayNum);
                                Collect(colCellState, {StudentId: req.StudentId, DayNum: req.DayNum, SaveState: "saved", Target: req.Target});
                                Set(
                                    varLastAction,
                                    {
                                        Kind: If(req.Target = "clear", "Cleared", wasDeleted, "Restored", "Saved"),
                                        Message: If(
                                            req.Target = "clear",
                                            "Cleared · " & cell.StudentName & " · " & dateText & " · Is Deleted = Yes · Key " & written.'Record Key' & If(IsBlank(audit), " · audit event NOT written", " · audit event written"),
                                            If(wasDeleted, "Restored · ", "Saved · ") & cell.StudentName & " · " & dateText & " · Status " & WORD(written) & " · IEP " & Text(written.'IEP Ratio') & " · Teacher " & varTeacher.Name & " · Term " & term.Name & " · Key " & written.'Record Key'
                                        ),
                                        StudentId: req.StudentId,
                                        DayNum: req.DayNum
                                    }
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)
```

### btnAttBulkEngine.OnSelect (A-DAY-ALL-PRESENT)

Reads `varBulkDay`. For each Open cell of that day: skip if an active local row exists; else
server upsert with `Present = true` using the same conflict rule and write set as the save
engine (record literal identical to the save engine's with `c.CellDate` for `cell.CellDate`
and `Present: true`).

```
=With(
    {
        dn: varBulkDay,
        cd: Date(Year(varMonthStart), Month(varMonthStart), varBulkDay),
        term: LookUp(colMonthTerms, ThisRecord.'Term (aaca_termid)' = LookUp(colMonthDays, DayNum = varBulkDay).TermId)
    },
    If(
        !varCanEditMonth || CountRows(Filter(colMonthCells, DayNum = dn && State = "Open")) = 0,
        Set(varLastAction, {Kind: "Blocked", Message: "All present not available · " & Text(cd, "ddd mmm d") & " · no editable cells (non-school, future, locked or view-only)", StudentId: ZeroGuid, DayNum: dn}),
        Clear(colBulkLog);
        ForAll(
            Filter(colMonthCells, DayNum = dn && State = "Open") As c,
            With(
                {
                    seg: LookUp(colMonthEnr, EnrId = c.EnrId),
                    local: LookUp(colMonthAtt, StudentId = c.StudentId && DayNum = dn)
                },
                If(
                    !IsBlank(local) && !local.IsDeleted,
                    Collect(colBulkLog, {StudentId: c.StudentId, Outcome: "skipped"}),
                    With(
                        {server: LookUp(Attendance, Student.Student = c.StudentId && Service.Service = seg.ServiceId && Date = cd)},
                        If(
                            IsError(server),
                            RemoveIf(colCellState, StudentId = c.StudentId && DayNum = dn);
                            Collect(colCellState, {StudentId: c.StudentId, DayNum: dn, SaveState: "failed", Target: "P"});
                            Collect(colBulkLog, {StudentId: c.StudentId, Outcome: "failed"}),
                            (!IsBlank(local) && local.ModifiedOn <> server.'Modified On') || (IsBlank(local) && !IsBlank(server) && server.'Is Deleted' <> true),
                            RemoveIf(colMonthAtt, StudentId = c.StudentId && DayNum = dn);
                            If(!IsBlank(server), Collect(colMonthAtt, ATT_ROW(server)));
                            Collect(colBulkLog, {StudentId: c.StudentId, Outcome: "skipped"}),
                            With(
                                {
                                    written: IfError(
                                        Patch(
                                            Attendance,
                                            Coalesce(server, Defaults(Attendance)),
                                            {
                                                'Record Key': Text(c.CellDate, "yyyymmdd") & "|" & seg.StudentNumber & "|" & seg.ServiceCode,
                                                Date: c.CellDate,
                                                Student: seg.EnrRec.Student,
                                                Service: seg.EnrRec.Service,
                                                Enrollment: seg.EnrRec,
                                                Teacher: varTeacher,
                                                Campus: seg.EnrRec.Campus,
                                                'School Year': seg.EnrRec.'School Year',
                                                Term: term,
                                                'IEP Ratio': Switch(
                                                    seg.EnrRec.'IEP Ratio',
                                                    'IEP Ratio (Enrollments)'.'No Aide', 'IEP Ratio (Attendance)'.'No Aide',
                                                    'IEP Ratio (Enrollments)'.'1:1', 'IEP Ratio (Attendance)'.'1:1',
                                                    'IEP Ratio (Enrollments)'.'2:1', 'IEP Ratio (Attendance)'.'2:1',
                                                    'IEP Ratio (Enrollments)'.'3:1', 'IEP Ratio (Attendance)'.'3:1',
                                                    'IEP Ratio (Enrollments)'.'4:1', 'IEP Ratio (Attendance)'.'4:1'
                                                ),
                                                Present: true,
                                                'Is Deleted': false
                                            }
                                        ),
                                        Blank()
                                    )
                                },
                                If(
                                    IsBlank(written),
                                    RemoveIf(colCellState, StudentId = c.StudentId && DayNum = dn);
                                    Collect(colCellState, {StudentId: c.StudentId, DayNum: dn, SaveState: "failed", Target: "P"});
                                    Collect(colBulkLog, {StudentId: c.StudentId, Outcome: "failed"}),
                                    RemoveIf(colMonthAtt, StudentId = c.StudentId && DayNum = dn);
                                    Collect(colMonthAtt, ATT_ROW(written));
                                    RemoveIf(colCellState, StudentId = c.StudentId && DayNum = dn);
                                    Collect(colCellState, {StudentId: c.StudentId, DayNum: dn, SaveState: "saved", Target: "P"});
                                    Collect(colBulkLog, {StudentId: c.StudentId, Outcome: "marked"})
                                )
                            )
                        )
                    )
                )
            )
        );
        Set(varLastAction, {Kind: "Bulk", Message: "All present · " & Text(cd, "ddd mmm d") & " · " & CountRows(Filter(colBulkLog, Outcome = "marked")) & " marked, " & CountRows(Filter(colBulkLog, Outcome = "skipped")) & " skipped (already recorded or changed by someone else), " & CountRows(Filter(colBulkLog, Outcome = "failed")) & " failed", StudentId: ZeroGuid, DayNum: dn})
    )
)
```

### CELL_ITEMS — `galAttCells.Items` (outer `ThisItem` = student row)

```
=ForAll(
    Filter(colMonthCells, StudentId = ThisItem.StudentId) As c,
    With(
        {
            a: LookUp(colMonthAtt, StudentId = c.StudentId && DayNum = c.DayNum && !IsDeleted),
            s: LookUp(colCellState, StudentId = c.StudentId && DayNum = c.DayNum)
        },
        {
            StudentId: c.StudentId,
            StudentName: c.StudentName,
            DayNum: c.DayNum,
            CellDate: c.CellDate,
            State: c.State,
            Reason: c.Reason,
            HasRecord: !IsBlank(a),
            Letter: Coalesce(a.Letter, ""),
            SaveState: Coalesce(s.SaveState, ""),
            Target: Coalesce(s.Target, ""),
            Editable: varCanEditMonth && c.State = "Open",
            Actionable: If(varDetailsMode, !IsBlank(a), varCanEditMonth && c.State = "Open"),
            StatusWord: If(
                Coalesce(s.SaveState, "") = "failed", "Save failed – tap to retry",
                Coalesce(s.SaveState, "") = "saving", "Saving",
                !IsBlank(a), Switch(a.Letter, "P", "Present", "E", "Absent, excused", "U", "Absent, unexcused", "Absent, not classified"),
                c.State = "NotEnrolled", "Not enrolled",
                c.State = "NonSchool", "Not a school day",
                c.State = "Future", "Future date",
                "Not recorded"
            )
        }
    )
)
```

DAY_ITEMS — `galAttDayList.Items`: identical to CELL_ITEMS except the first argument is
`Filter(colMonthCells, DayNum = Day(varViewDate) && (State = "Open" || State = "Future")) As c`.

### btnAttCell (Classic/Button, sole child of galAttCells)

- `Width: =Parent.TemplateWidth - 3` · `Height: =Parent.TemplateHeight - 4` (no X/Y)
- `Text:` `=Switch(ThisItem.SaveState, "failed", "!", "saving", If(ThisItem.Target = "clear", "…", ThisItem.Target & "…"), If(ThisItem.HasRecord, ThisItem.Letter & If(ThisItem.SaveState = "saved", "✓", ""), ThisItem.State = "NotEnrolled", "–", ""))`
- `Fill:` `=If(ThisItem.SaveState = "failed", ColorWhite, ThisItem.SaveState = "saving", ColorSaving, ThisItem.HasRecord, Switch(ThisItem.Letter, "P", ColorPresent, "E", ColorExcused, "U", ColorUnexcused, ColorAbsent), ThisItem.State = "NonSchool", ColorNonSchool, ThisItem.State = "NotEnrolled", ColorNotEnrolled, ColorWhite)`
- `Color:` `=If(ThisItem.SaveState = "failed", ColorUnexcused, ThisItem.SaveState = "saving", ColorInk, ThisItem.HasRecord, ColorWhite, ColorMuted)`
- `BorderColor:` `=If(varLastAction.Kind <> "" && varLastAction.StudentId = ThisItem.StudentId && varLastAction.DayNum = ThisItem.DayNum, ColorTeal, ThisItem.SaveState = "failed", ColorUnexcused, ColorRule)`
- `BorderThickness:` `=If(varLastAction.Kind <> "" && varLastAction.StudentId = ThisItem.StudentId && varLastAction.DayNum = ThisItem.DayNum, 3, 1)`
- `BorderStyle: =If(ThisItem.State = "Future", BorderStyle.Dashed, BorderStyle.Solid)`
- `DisplayMode: =If(ThisItem.Actionable, DisplayMode.Edit, DisplayMode.Disabled)`;
  `DisabledFill: =Self.Fill`, `DisabledColor: =Self.Color`, `DisabledBorderColor: =Self.BorderColor`;
  `HoverFill: =Self.Fill`, `PressedFill: =Self.Fill`, `HoverBorderColor: =ColorTeal`, `HoverColor: =Self.Color`
- `Size: =14`, `FontWeight: =FontWeight.Bold`, `Align: =Align.Center`, `VerticalAlign: =VerticalAlign.Middle`,
  PaddingLeft/Right `=1`, PaddingTop/Bottom `=0`, four radii `=3`, `FocusedBorderColor: =ColorTeal`,
  `FocusedBorderThickness: =3`, `AutoDisableOnSelect: =false`, `TabIndex: =0`
- `Tooltip:` `=ThisItem.StudentName & " – " & Text(ThisItem.CellDate, "ddd mmm d") & " – " & ThisItem.StatusWord & If(ThisItem.State <> "Open" && ThisItem.Reason <> "", " (" & ThisItem.Reason & ")", "") & If(!varCanEditMonth && ThisItem.State = "Open", " (read-only)", "")`
- `OnSelect:`
```
=If(
    varDetailsMode,
    If(ThisItem.HasRecord, Set(varDetailKey, {StudentId: ThisItem.StudentId, DayNum: ThisItem.DayNum}); Set(varConfirmOpen, false); Reset(txtAttDetailNotes); Set(varDetailOpen, true)),
    !ThisItem.Editable || ThisItem.SaveState = "saving",
    false,
    ThisItem.SaveState = "failed",
    Set(varSaveReq, {StudentId: ThisItem.StudentId, DayNum: ThisItem.DayNum, Target: ThisItem.Target}); Select(btnAttSaveEngine),
    !ThisItem.HasRecord,
    Set(varSaveReq, {StudentId: ThisItem.StudentId, DayNum: ThisItem.DayNum, Target: "P"}); Select(btnAttSaveEngine),
    ThisItem.Letter = "P",
    Set(varSaveReq, {StudentId: ThisItem.StudentId, DayNum: ThisItem.DayNum, Target: "A"}); Select(btnAttSaveEngine),
    Set(varClearKey, {StudentId: ThisItem.StudentId, DayNum: ThisItem.DayNum}); Set(varDetailOpen, false); Set(varConfirmOpen, true)
)
```

### Other bindings

| Control.Property | Formula |
| --- | --- |
| lblAttIdentity.Text | `=Coalesce(CurrentUserRow.'Full Name', User().FullName) & " · " & RoleLabel & " · " & If(!StaffReady, "no campus", IsBlank(CurrentStaff.Campus), "All campuses", CurrentStaff.Campus.Name)` |
| lblAttNotSetUpBody.Text | `="Your sign-in (" & User().Email & ") is not linked to an active Staff record. Ask a System Admin to add a Staff row linked to your Users record, then reopen the app."` |
| btnAttPrevMonth.OnSelect | `=Set(varMonthStart, DateAdd(varMonthStart, -1, TimeUnit.Months)); Select(btnAttLoadEngine)` |
| btnAttNextMonth.OnSelect | `=Set(varMonthStart, DateAdd(varMonthStart, 1, TimeUnit.Months)); Select(btnAttLoadEngine)` |
| btnAttThisMonth.OnSelect | `=Set(varMonthStart, Date(Year(Today()), Month(Today()), 1)); Set(varViewDate, Today()); Select(btnAttLoadEngine)` |
| month nav, pickers, reload `.DisplayMode` | `=If(varLoading, DisplayMode.Disabled, DisplayMode.Edit)` (pickers: see below) |
| ddAttCampus.Items / ItemDisplayText / Default | `=Sort(Campuses, Name, SortOrder.Ascending)` / `=ThisItem.Name` / `=varCampus` |
| ddAttCampus.DisplayMode | `=If(CanPickCampus && !varLoading, DisplayMode.Edit, DisplayMode.Disabled)` |
| ddAttCampus.OnChange | `=Set(varCampus, Self.Selected); Set(varTeacher, First(Sort(Filter(Staff, Campus.Campus = varCampus.Campus && 'App Role' = 'App Role (Staff)'.Teacher), Name, SortOrder.Ascending))); Select(btnAttLoadEngine)` |
| ddAttTeacher.Items / ItemDisplayText / Default | `=Sort(Filter(Staff, Campus.Campus = varCampus.Campus && 'App Role' = 'App Role (Staff)'.Teacher), Name, SortOrder.Ascending)` / `=ThisItem.Name` / `=varTeacher` |
| ddAttTeacher.DisplayMode | `=If(CanPickTeacher && !varLoading, DisplayMode.Edit, DisplayMode.Disabled)` |
| ddAttTeacher.OnChange | `=Set(varTeacher, Self.Selected); Select(btnAttLoadEngine)` |
| ddAtt*.AccessibleLabel / Appearance | "Campus" / "Teacher"; `=Appearance.Outline`; `Color: =ColorInk`; `LayoutMinWidth: =0` |
| tabAttView | `Items: =["Month", "Day"]`; `ItemDisplayText: =ThisItem.Value`; `Default: '=If(conAttRoot.Width < 640, {Value: "Day"}, {Value: "Month"})'`; `Appearance: =TabListAppearance.Subtle`; `TabSize: =TabSize.Small`; `BasePaletteColor: =ColorTeal`; `Color: =ColorInk`; `AccessibleLabel: ="Month or Day view"`; `LayoutMinWidth: =0`; `LayoutMinHeight: =0` |
| btnAttDetailsMode | `Text: =If(varDetailsMode, "Details on", "Details mode")`; `Appearance: =If(varDetailsMode, ButtonAppearance.Primary, ButtonAppearance.Secondary)`; `BasePaletteColor: =ColorTeal`; `Color: =If(varDetailsMode, ColorWhite, ColorInk)`; `OnSelect: =Set(varDetailsMode, !varDetailsMode); Set(varDetailOpen, false)`; `AccessibleLabel: ="Details mode – tap a marked cell to open its details"` |
| btnAttReload.OnSelect | `=Select(btnAttLoadEngine)` |
| lblAttNotice.Text | `=If(varLoadError <> "", "Could not load attendance — " & varLoadError & ". Use ↻ to try again.", !IsBlank(varMonthLock), Text(varMonthStart, "mmmm yyyy") & " is locked for " & varCampus.Name & " — " & Coalesce(varMonthLock.Reason, "no reason given") & ". Cells are read-only.", IsReadOnlyRole, "View only — the Read-only role cannot change attendance.", "")` |
| spnAttLoading | `Label: ="Loading " & Text(varMonthStart, "mmmm yyyy") & "…"`; `LabelPosition: =SpinnerLabelPosition.After`; `AccessibleLabel: ="Loading attendance"`; `SpinnerColor: =ColorTeal`; `Color: =ColorInk`; `LayoutMinWidth: =0`; `LayoutMinHeight: =0` |
| conAttReceipt.Fill | `=Switch(varLastAction.Kind, "Conflict", ColorWarnBg, "Failed", ColorErrorBg, "Blocked", ColorErrorBg, ColorInfoBg)` |
| lblAttReceipt.Text | `=varLastAction.Message` (AccessibleLabel `="Last action " & varLastAction.Message`) |
| btnAttReceiptDismiss.OnSelect | `=Set(varLastAction, {Kind: "", Message: "", StudentId: ZeroGuid, DayNum: 0})` |
| lblAttConfirmText.Text | `=With({a: LookUp(colMonthAtt, StudentId = varClearKey.StudentId && DayNum = varClearKey.DayNum && !IsDeleted), c: LookUp(colMonthCells, StudentId = varClearKey.StudentId && DayNum = varClearKey.DayNum)}, "Clear " & Switch(a.Letter, "P", "Present", "E", "Absent (excused)", "U", "Absent (unexcused)", "Absent") & " for " & c.StudentName & " on " & Text(c.CellDate, "dddd mmmm d") & "? The row is kept and marked deleted (audit logged); marking the day again restores it.")` |
| btnAttConfirmClear.OnSelect | `=Set(varConfirmOpen, false); Set(varSaveReq, {StudentId: varClearKey.StudentId, DayNum: varClearKey.DayNum, Target: "clear"}); Select(btnAttSaveEngine)` |
| btnAttConfirmCancel.OnSelect | `=Set(varConfirmOpen, false); Set(varLastAction, {Kind: "Cancelled", Message: "Clear cancelled · " & LookUp(colMonthCells, StudentId = varClearKey.StudentId && DayNum = varClearKey.DayNum).StudentName & " · " & Text(Date(Year(varMonthStart), Month(varMonthStart), varClearKey.DayNum), "ddd mmm d") & " · record unchanged", StudentId: varClearKey.StudentId, DayNum: varClearKey.DayNum})` |
| lblAttDetailTitle.Text | `=LookUp(colMonthStudents, StudentId = varDetailKey.StudentId).StudentName & " · " & Text(Date(Year(varMonthStart), Month(varMonthStart), varDetailKey.DayNum), "dddd mmmm d, yyyy")` |
| lblAttDetailFacts.Text | `=With({a: LookUp(colMonthAtt, StudentId = varDetailKey.StudentId && DayNum = varDetailKey.DayNum && !IsDeleted)}, If(IsBlank(a), "No attendance record for this cell.", "Status " & Switch(a.Letter, "P", "Present", "E", "Absent (excused)", "U", "Absent (unexcused)", "Absent (not classified)") & "  ·  IEP ratio " & Coalesce(a.IepText, "—") & "  ·  Classification " & a.ClassText & " (read-only)  ·  Reason " & Coalesce(LookUp(Attendance, ThisRecord.Attendance = a.AttId).'Absence Reason'.Name, "—") & "  ·  Key " & a.RecordKey))` |
| txtAttDetailNotes | `Default: =LookUp(colMonthAtt, StudentId = varDetailKey.StudentId && DayNum = varDetailKey.DayNum && !IsDeleted).Notes`; `Type: =TextInputType.Multiline`; `MaxLength: =2000`; `Appearance: =Appearance.Outline`; `Placeholder: ="Add a note for this day"`; `AccessibleLabel: ="Notes"`; `DisplayMode: =If(varCanEditMonth, DisplayMode.Edit, DisplayMode.View)`; `LayoutMinWidth: =0`; `LayoutMinHeight: =0` |
| btnAttDetailSave.DisplayMode | `=If(varCanEditMonth && !IsBlank(LookUp(colMonthAtt, StudentId = varDetailKey.StudentId && DayNum = varDetailKey.DayNum && !IsDeleted)), DisplayMode.Edit, DisplayMode.Disabled)` |
| btnAttDetailClose.OnSelect | `=Set(varDetailOpen, false)` |
| lblAttLegend.Text | `="P present · A absent, not classified · E excused · U unexcused · – not enrolled · grey = no school · dashed = future · … saving · ✓ saved · ! save failed, tap to retry · Details mode: tap a marked cell for notes"` (block scalar — contains `: `) |
| lblAttEmpty.Text | `=If(IsBlank(varTeacher), "No teacher selected — choose a teacher above.", "No students for " & varTeacher.Name & " in " & Text(varMonthStart, "mmmm yyyy") & ".")` |
| conAttDayHeadCell.Fill | `=If(ThisItem.IsSchoolDay, ColorWhite, ColorNonSchool)` |
| lblAttDayHeadDow.Text / lblAttDayHeadNum.Text | `=ThisItem.DowLabel` / `=Text(ThisItem.DayNum)`; Num `Color: =If(ThisItem.CellDate = Today(), ColorTeal, ColorInk)`; AccessibleLabel `=Text(ThisItem.CellDate, "dddd mmmm d") & If(ThisItem.IsSchoolDay, "", " – " & ThisItem.NonSchoolReason)` |
| btnAttDayAll | `Text: ="All"`; `Size: =9`; `Fill: =ColorTeal`; `Color: =ColorWhite`; `DisabledFill: =ColorNotEnrolled`; `DisabledColor: =ColorMuted`; `BorderThickness: =0`; radii 3; Padding* 0; `AutoDisableOnSelect: =false`; `Tooltip: ="All present – " & Text(ThisItem.CellDate, "ddd mmm d")`; `DisplayMode: =If(varCanEditMonth && !varLoading && CountRows(Filter(colMonthCells, DayNum = ThisItem.DayNum && State = "Open")) > 0, DisplayMode.Edit, DisplayMode.Disabled)`; `OnSelect: =Set(varBulkDay, ThisItem.DayNum); Select(btnAttBulkEngine)`; `LayoutMinWidth: =0`; `LayoutMinHeight: =0` |
| lblAttRowName.Text | `=ThisItem.StudentName` (AccessibleLabel `=ThisItem.StudentName`) |
| lblAttRowTotal.Text | `=Text(CountRows(Filter(colMonthAtt, StudentId = ThisItem.StudentId && Present && !IsDeleted)))`; AccessibleLabel `="Days present " & Self.Text` |
| lblAttDayTotal.Text | `=With({n: CountRows(Filter(colMonthAtt, DayNum = ThisItem.DayNum && Present && !IsDeleted))}, If(n = 0 && !ThisItem.IsSchoolDay, "", Text(n)))`; Size 12 Semibold, Align Center, Wrap false |
| lblAttFootTotal.Text | `=Text(CountRows(Filter(colMonthAtt, Present && !IsDeleted)))` |
| btnAttPrevDay.OnSelect | `=With({nd: DateAdd(varViewDate, -1, TimeUnit.Days)}, Set(varViewDate, nd); If(nd < varMonthStart, Set(varMonthStart, Date(Year(nd), Month(nd), 1)); Select(btnAttLoadEngine)))` |
| btnAttNextDay.OnSelect | `=With({nd: DateAdd(varViewDate, 1, TimeUnit.Days)}, Set(varViewDate, nd); If(nd > varMonthEnd, Set(varMonthStart, Date(Year(nd), Month(nd), 1)); Select(btnAttLoadEngine)))` |
| btnAttDayAllPresent | `DisplayMode: =If(varCanEditMonth && !varLoading && CountRows(Filter(colMonthCells, DayNum = Day(varViewDate) && State = "Open")) > 0, DisplayMode.Edit, DisplayMode.Disabled)`; `OnSelect: =Set(varBulkDay, Day(varViewDate)); Select(btnAttBulkEngine)` |
| lblAttDayNotice.Text | `=With({dd: LookUp(colMonthDays, DayNum = Day(varViewDate))}, If(varLoading, "", CountRows(colMonthStudents) = 0, "No students for this teacher in " & Text(varMonthStart, "mmmm yyyy") & ".", !dd.IsSchoolDay, "Not a school day — " & dd.NonSchoolReason & ".", DayCount = 0, "No students are enrolled with this teacher on this day.", ""))` |
| lblAttDayName.Text | `=ThisItem.StudentName` |
| lblAttDayStatus | `Text: =Switch(ThisItem.SaveState, "failed", "Save failed – press Present or Absent to retry", "saving", "Saving…", If(ThisItem.HasRecord, ThisItem.StatusWord & If(ThisItem.SaveState = "saved", " ✓ saved", ""), ThisItem.State = "Future", "Future date – locked", "Not recorded"))`; `Color: =If(ThisItem.SaveState = "failed", ColorUnexcused, ColorMuted)` |
| btnAttDayPresent | `DisplayMode: =If(ThisItem.Editable && ThisItem.SaveState <> "saving" && (ThisItem.Letter <> "P" \|\| ThisItem.SaveState = "failed"), DisplayMode.Edit, DisplayMode.Disabled)`; `OnSelect: =Set(varSaveReq, {StudentId: ThisItem.StudentId, DayNum: ThisItem.DayNum, Target: "P"}); Select(btnAttSaveEngine)`; AccessibleLabel `="Mark " & ThisItem.StudentName & " present"` |
| btnAttDayAbsent | `DisplayMode: =If(ThisItem.Editable && ThisItem.SaveState <> "saving" && (!(ThisItem.Letter in ["A", "E", "U"]) \|\| ThisItem.SaveState = "failed"), DisplayMode.Edit, DisplayMode.Disabled)`; `OnSelect: =Set(varSaveReq, {StudentId: ThisItem.StudentId, DayNum: ThisItem.DayNum, Target: "A"}); Select(btnAttSaveEngine)`; AccessibleLabel `="Mark " & ThisItem.StudentName & " absent"` |
| btnAttDayClear | `DisplayMode: =If(ThisItem.Editable && ThisItem.SaveState <> "saving", DisplayMode.Edit, DisplayMode.Disabled)`; `OnSelect: =Set(varClearKey, {StudentId: ThisItem.StudentId, DayNum: ThisItem.DayNum}); Set(varDetailOpen, false); Set(varConfirmOpen, true)`; AccessibleLabel `="Clear the record for " & ThisItem.StudentName` |

`\|\|` in the table above is the Power Fx `||` operator (escaped for Markdown).

### btnAttDetailSave.OnSelect (A-SAVE-NOTES)

```
=With(
    {
        a: LookUp(colMonthAtt, StudentId = varDetailKey.StudentId && DayNum = varDetailKey.DayNum && !IsDeleted),
        nm: LookUp(colMonthStudents, StudentId = varDetailKey.StudentId).StudentName,
        dt: Text(Date(Year(varMonthStart), Month(varMonthStart), varDetailKey.DayNum), "ddd mmm d"),
        newNotes: txtAttDetailNotes.Text
    },
    If(
        IsBlank(a) || !varCanEditMonth,
        Set(varLastAction, {Kind: "Blocked", Message: "Notes not saved · " & nm & " · " & dt & " · no record, month locked or view-only role", StudentId: varDetailKey.StudentId, DayNum: varDetailKey.DayNum}),
        With(
            {server: LookUp(Attendance, ThisRecord.Attendance = a.AttId)},
            If(
                IsError(server),
                Set(varLastAction, {Kind: "Failed", Message: "Failed · " & nm & " · " & dt & " · notes were not saved — press Save notes to retry", StudentId: varDetailKey.StudentId, DayNum: varDetailKey.DayNum}),
                IsBlank(server) || server.'Modified On' <> a.ModifiedOn,
                RemoveIf(colMonthAtt, AttId = a.AttId);
                If(!IsBlank(server), Collect(colMonthAtt, ATT_ROW(server)));
                Reset(txtAttDetailNotes);
                Set(varLastAction, {Kind: "Conflict", Message: "Changed by someone else — reloaded · " & nm & " · " & dt & " · your notes were not saved", StudentId: varDetailKey.StudentId, DayNum: varDetailKey.DayNum}),
                With(
                    {written: IfError(Patch(Attendance, server, {Notes: newNotes}), Blank())},
                    If(
                        IsBlank(written),
                        Set(varLastAction, {Kind: "Failed", Message: "Failed · " & nm & " · " & dt & " · notes were not saved — press Save notes to retry", StudentId: varDetailKey.StudentId, DayNum: varDetailKey.DayNum}),
                        RemoveIf(colMonthAtt, AttId = a.AttId);
                        Collect(colMonthAtt, ATT_ROW(written));
                        Set(varLastAction, {Kind: "Notes", Message: "Notes saved · " & nm & " · " & dt & " · Notes """ & Left(written.Notes, 80) & If(Len(written.Notes) > 80, "…", "") & """ · Key " & written.'Record Key', StudentId: varDetailKey.StudentId, DayNum: varDetailKey.DayNum})
                    )
                )
            )
        )
    )
)
```

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| ATT-ROW-NAME | Grid row | Student full name | Students.'Display Name' via colMonthStudents.StudentName | lblAttRowName | `=ThisItem.StudentName` | First 180 px column of every row; 2 lines at Size 12 |
| ATT-CELL-STATUS | Grid cell | Status letter P/A/E/U, "–" not enrolled | colMonthAtt.Letter / colMonthCells.State | btnAttCell | Text formula above | Every cell; letter + colour |
| ATT-CELL-SAVE | Grid cell | saving / saved / failed | colCellState.SaveState | btnAttCell | "…" / "✓" / "!" in Text | Same cell |
| ATT-CELL-REASON | Grid cell | Non-school / not-enrolled / future reason | colMonthCells.Reason | btnAttCell.Tooltip | Tooltip formula above | Hover/long-press |
| ATT-ROW-TOTAL | Grid row | Days present | colMonthAtt (Present, !IsDeleted) | lblAttRowTotal | table above | Last column |
| ATT-COL-TOTAL | Grid footer | Students present per day | colMonthAtt | lblAttDayTotal | table above | Footer under each day |
| ATT-HEAD-DAY | Grid header | Weekday + day number | colMonthDays | lblAttDayHeadDow, lblAttDayHeadNum | table above | Header above each day |
| ATT-DAY-NAME | Day view row | Student full name | colMonthCells.StudentName | lblAttDayName | `=ThisItem.StudentName` | Row line 1 |
| ATT-DAY-STATUS | Day view row | Status word + save state | colMonthAtt / colCellState | lblAttDayStatus | table above | Row line 2 |
| ATT-DETAIL-ID | Detail panel | Student + date | colMonthStudents, varDetailKey | lblAttDetailTitle | table above | Panel line 1 |
| ATT-DETAIL-FACTS | Detail panel | Status, IEP ratio, classification (read-only), reason, key | colMonthAtt + live Attendance.'Absence Reason' | lblAttDetailFacts | table above | Panel line 2 |
| ATT-DETAIL-NOTES | Detail panel | Notes (editable) | Attendance.Notes | txtAttDetailNotes | Default above | Panel field |
| ATT-HEADER-ID | Header | User, role, campus | Users.'Full Name', Staff.'App Role', Staff.Campus | lblAttIdentity | table above | Always |

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| SV-NOTSETUP | conAttNotSetUp | `=!StaffReady` | No/inactive Staff row → visible; otherwise hidden |
| SV-TOOLBAR | conAttToolbar | `=StaffReady` | Hidden when not set up |
| SV-NOTICE | conAttNotice | `=StaffReady && lblAttNotice.Text <> ""` | Lock, read-only or load error → visible |
| SV-LOADING | spnAttLoading | `=varLoading` | During load engine only |
| SV-RECEIPT | conAttReceipt | `=varLastAction.Kind <> ""` | After any mutation/cancel/block until Dismiss |
| SV-CONFIRM | conAttConfirm | `=varConfirmOpen` | After tapping an absent cell / Day view Clear; hidden after Confirm/Cancel/reload |
| SV-DETAIL | conAttDetail | `=varDetailOpen` | Details mode tap on a recorded cell; hidden on Close/reload/mode toggle |
| SV-MONTH | conAttMonthView | `=StaffReady && tabAttView.Selected.Value <> "Day"` | Month tab (default ≥ 640) |
| SV-DAY | conAttDayView | `=StaffReady && tabAttView.Selected.Value = "Day"` | Day tab (default < 640) |
| SV-EMPTY | lblAttEmpty | `=CountRows(colMonthStudents) = 0 && !varLoading` | No students in month |
| SV-GRID | conAttGridScroll | `=CountRows(colMonthStudents) > 0` | Students exist |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-LOAD-IDENTITY | App start | App.Formulas `CurrentStaff`; App.OnStart defaults | Users.'Primary Email' = User().Email → Staff.User | Role flags, varCampus, varTeacher | N/A | N/A | lblAttIdentity; SV-NOTSETUP |
| A-PICK-CAMPUS | `CanPickCampus` | ddAttCampus.OnChange | Campuses.Campus | varCampus, varTeacher = first teacher there; reload | N/A | N/A | ddAttTeacher Items; galAttRows; lblAttNotice (lock for new campus) |
| A-PICK-TEACHER | `CanPickTeacher` | ddAttTeacher.OnChange | Staff.Staff | varTeacher; reload | N/A | N/A | galAttRows Items (colMonthStudents) |
| A-NAV-MONTH | StaffReady, !varLoading | btnAttPrevMonth / btnAttNextMonth / btnAttThisMonth .OnSelect | varMonthStart | month ±1 / current; reload | N/A | N/A | lblAttMonth; galAttDayHead day count |
| A-LOAD-MONTH | any | btnAttLoadEngine.OnSelect via OnVisible, pickers, month/day nav, btnAttReload | Enrollments/Attendance by Teacher.Staff + month; Calendar Exceptions, Terms, Month Locks | collections rebuilt; varCanEditMonth | N/A | N/A | galAttRows, lblAttEmpty, spnAttLoading, lblAttNotice |
| A-MARK-CELL (blank→P) | cell Open, varCanEditMonth, !varDetailsMode, no active row, not saving | btnAttCell.OnSelect → varSaveReq Target "P" → btnAttSaveEngine | Attendance by Student+Service+Date; row GUID `Attendance` | Patch(Coalesce(server, Defaults)) Present=Yes, Is Deleted=No + snapshots; colMonthAtt row replaced by ATT_ROW(written) | Present, Is Deleted, Record Key, Date, Student, Service, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio | student, date, Status, IEP, Teacher, Term, Key (from `written`) | btnAttCell "P✓" green + teal focus border; lblAttRowTotal; lblAttDayTotal; lblAttReceipt |
| A-MARK-CELL (P→A) | active row Letter "P" | btnAttCell.OnSelect → Target "A" | same GUID | Present=No; classification untouched (blank = not classified) | same as above | same; Status "Absent (not classified)" | "A✓" amber; totals −1; receipt |
| A-MARK-CELL (restore) | server row Is Deleted=Yes | blank cell tap (Target "P") | same GUID as the soft-deleted row | same Patch on existing row → Is Deleted=No | same | receipt Kind "Restored" | cell letter; receipt "Restored · …" |
| A-CLEAR-CELL | active row A/E/U (Month) or any (Day view), Editable | btnAttCell.OnSelect (absent) or btnAttDayClear → conAttConfirm → btnAttConfirmClear.OnSelect → Target "clear" | same GUID | Patch(server, {'Is Deleted': true}) + Audit Events row (Soft Delete, Entity ID = GUID) | Is Deleted; Audit Events: Summary, Action, Entity, Entity ID, Before, After, Reason | student, date, "Is Deleted = Yes", Key, audit written / NOT written | cell blank; totals; lblAttReceipt |
| A-CLEAR-CELL (cancel) | conAttConfirm visible | btnAttConfirmCancel.OnSelect | N/A | no write; varConfirmOpen false | N/A | "Clear cancelled · name · date · record unchanged" | cell unchanged; receipt |
| A-DAY-ALL-PRESENT | varCanEditMonth, ≥1 Open cell that day | btnAttDayAll.OnSelect (header) or btnAttDayAllPresent.OnSelect → varBulkDay → btnAttBulkEngine | per student: Attendance by Student+Service+Date | each Open cell without active row → Present=Yes (create/restore); active rows skipped | per written row: same as blank→P | date, marked / skipped / failed counts | column cells "P✓"; lblAttDayTotal; receipt |
| A-VALIDATE-SAVE | cell State ≠ Open, locked month, read-only role, future | btnAttCell / Day buttons disabled; engines re-check | colMonthCells.State, varCanEditMonth | no write | N/A | Blocked receipt only if the engine is reached | disabled cell + Tooltip reason; conAttNotice; dashed future border |
| A-RETRY-CELL | colCellState SaveState "failed" | btnAttCell.OnSelect (shows "!") or Day view button | same key | engine re-run with stored Target | as the retried action | as the retried action | "!" → "P✓"/"A✓"/blank; receipt |
| A-OPEN-DETAIL | varDetailsMode, cell has active row | btnAttDetailsMode.OnSelect then btnAttCell.OnSelect | colMonthAtt by StudentId+DayNum | varDetailKey; conAttDetail visible | N/A | N/A | lblAttDetailTitle / Facts / txtAttDetailNotes |
| A-SAVE-NOTES | panel open, active row, varCanEditMonth | btnAttDetailSave.OnSelect | Attendance GUID a.AttId | Modified On check; Patch(server, {Notes}) | Notes | student, date, Notes text, Key | txtAttDetailNotes Default; lblAttReceipt |
| A-SWITCH-VIEW | StaffReady | tabAttView (select Month/Day) | N/A | Selected.Value drives SV-MONTH / SV-DAY | N/A | N/A | panel visibility |
| A-DAY-MARK | Day view row Editable | btnAttDayPresent / btnAttDayAbsent .OnSelect → btnAttSaveEngine | same as A-MARK-CELL | same | same | same | lblAttDayStatus; receipt; month grid shows same value |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| ddAttCampus | lblAttCampus `Text: ="Campus"` | conAttCampusField |
| ddAttTeacher | lblAttTeacher `Text: ="Teacher"` | conAttTeacherField |
| txtAttDetailNotes | lblAttDetailNotesLabel `Text: ="Notes"` | conAttDetailNotesField |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-MARK-CELL / A-DAY-MARK / restore | `written` Patch result → varLastAction.Message → lblAttReceipt | Dataverse Attendance row (GUID); `LookUp(Attendance, Student.Student = sid && Service.Service = svc && Date = d)` | Grid cell / Day row / totals via colMonthAtt | Same row found by alternate key; GUID from `written.Attendance` stored as AttId | `RemoveIf` + `Collect(colMonthAtt, ATT_ROW(written))` only on success | btnAttCell border teal when varLastAction StudentId+DayNum match |
| A-CLEAR-CELL | `written` + `audit` → lblAttReceipt | Attendance.'Is Deleted' = Yes; Audit Events row Entity ID = Text(GUID) | Cell blank (CELL_ITEMS filters `!IsDeleted`) | same GUID | same as above | same focus border |
| A-DAY-ALL-PRESENT | colBulkLog counts → lblAttReceipt | per-row Attendance | column cells + lblAttDayTotal | per student key | per-row ATT_ROW(written) on success | column: each written cell shows "✓" |
| A-SAVE-NOTES | `written` → lblAttReceipt | Attendance.Notes by GUID | txtAttDetailNotes Default reads colMonthAtt | a.AttId | ATT_ROW(written) on success | panel stays on varDetailKey |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| Mark P/A | Present | Changed | varSaveReq.Target | `Present: req.Target = "P"` | "Status " & WORD(written) | btnAttCell.Text / Fill |
| Mark P/A | Is Deleted | Changed (→ No) | server row or new | `'Is Deleted': false` | Kind "Restored" vs "Saved" | cell shows letter (filter `!IsDeleted`) |
| Mark P/A | Record Key, Date, Student, Service | Changed (identity) | cell/seg | as write set | "Key " & written.'Record Key' + name + date | lblAttDetailFacts Key |
| Mark P/A | IEP Ratio | Changed (snapshot) | seg.EnrRec.'IEP Ratio' mapped | Switch mapping | "IEP " & Text(written.'IEP Ratio') | lblAttDetailFacts IEP |
| Mark P/A | Teacher, Term | Changed (snapshot) | varTeacher, term | as write set | "Teacher " & varTeacher.Name, "Term " & term.Name | receipt |
| Mark P/A | Enrollment, Campus, School Year | Changed (system snapshot, not user-visible) | seg.EnrRec | as write set | none in UI — verify on the Dataverse row | Dataverse |
| Mark P/A | Absence Classification, Absence Reason, Notes | Preserved | existing row | omitted from Patch | classification shown in lblAttDetailFacts | lblAttDetailFacts |
| Clear | Is Deleted | Changed (→ Yes) | local active row | `Patch(Attendance, server, {'Is Deleted': true})` | "Is Deleted = Yes" | cell blank |
| Clear | Present, Notes, snapshots | Preserved | server row | omitted from Patch | restored letter after re-mark | colMonthAtt row kept with IsDeleted true |
| Clear | Audit Events row | Changed (created) | — | Patch('Audit Events', Defaults(...)) | "audit event written" / "NOT written" | Dataverse Audit Events |
| Notes | Notes | Changed | txtAttDetailNotes.Text | `{Notes: newNotes}` | "Notes \"…\"" | txtAttDetailNotes Default |
| Notes | all other fields | Preserved | server row | omitted | — | lblAttDetailFacts |

## Functional Test Scenarios

Seed: Seed Campus Alpha, its first teacher alphabetically (T1), its first students S1..S4
alphabetically; September 2026; today = Mon Sep 28 2026 (no records yet; Sep 26–27 weekend;
Sep 29–30 future); AllowFutureDates = "false"; Adam = System Admin.

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-IDENT-ROLE | Adam signs in | Screen opens | Admin flags; campus = Seed Campus Alpha, teacher = T1 | lblAttIdentity "Adam Bernstein · System Admin · All campuses"; ddAttCampus/ddAttTeacher enabled | N/A |
| S-IDENT-MISSING | User without Staff row | Screen opens | StaffReady false; no loads | conAttNotSetUp visible; toolbar/grid hidden | Inactive Staff row behaves the same |
| S-SCOPE-TEACHER | Staff App Role Teacher at Alpha | Screen opens | varTeacher = self | both dropdowns Disabled; grid shows own students | cannot pick another teacher |
| S-SCOPE-OFFICE | App Role Attendance Office, Campus Beta | open; pick 2nd Beta teacher | reload for that teacher | ddAttCampus Disabled = Beta; ddAttTeacher lists only Beta teachers | N/A |
| S-PICK-CAMPUS-ADMIN | Adam | pick Seed Campus Gamma | varTeacher = first Gamma teacher; reload | ddAttTeacher, galAttRows, lblAttNotice | N/A |
| S-MONTH-NEXT | Sep 2026 loaded | ▶ then This month | Oct 2026 (31 days, all future cells dashed/disabled) then Sep 2026 | lblAttMonth; header count | N/A |
| S-LOAD-MONTH | Adam, T1, Sep 2026 | open | colMonthAtt = T1 rows dated Sep 1–30 | letters on Sep 1–25 school days; spinner hides | load error → conAttNotice red |
| S-ROWS-TRANSFER | Student X: enrollment T1 Sep 1–14, T2 Sep 15–open (create if absent) | view T1, then T2 | T1 row open Sep 1–14, "–" Sep 15–30; T2 opposite | btnAttCell text/tooltip | N/A |
| S-MARK-PRESENT | S1 Sep 28 no row | tap S1/Sep 28 cell | Attendance row key 20260928\|STU…\|SPED Present=Yes, Is Deleted=No, snapshots | cell "P✓" green; row total +1; Sep 28 total +1; receipt "Saved · S1 · Mon Sep 28 · Status Present · IEP … · Key …" | N/A |
| S-MARK-ABSENT | S1 Sep 28 = P | tap again | same GUID Present=No, classification blank | "A✓" amber; totals −1; receipt "Status Absent (not classified)" | N/A |
| S-CLEAR-CONFIRM | S1 Sep 28 = A | tap → Confirm clear | Is Deleted=Yes same GUID; Audit Events Soft Delete, Entity ID = GUID | cell blank; receipt "Cleared · … Is Deleted = Yes · … audit event written" | audit failure → "NOT written" |
| S-CLEAR-CANCEL | S1 Sep 28 = A | tap → Cancel | no write | cell still "A"; receipt "Clear cancelled" | N/A |
| S-MARK-RESTORE | S1 Sep 28 soft-deleted | tap blank cell | same GUID Is Deleted=No, Present=Yes; still one row for the key | receipt "Restored · … Status Present" | N/A |
| S-BULK-DAY | Sep 28: S1 = P, others blank | header "All" on 28 | every other Open student gets Present; S1 untouched | column "P✓"; footer total = Open count; receipt "All present · Mon Sep 28 · n marked, 1 skipped, 0 failed" | no Open cells → button disabled |
| S-BLOCK-NONSCHOOL | Sat Sep 26 | hover/tap | no write | grey cells Disabled; tooltip "(Weekend)"; header shell grey; "All" disabled | holiday exception shows its type + description |
| S-BLOCK-NOTENROLLED | Student X in T1 view, Sep 21 | tap | no write | "–" pale Disabled; tooltip "Not enrolled" | N/A |
| S-BLOCK-FUTURE | Tue Sep 29 | tap / Day view Sep 29 | no write | dashed blank Disabled; Day row "Future date – locked", buttons Disabled | AllowFutureDates "true" → Open |
| S-BLOCK-LOCKED | Month Locks: Alpha, 2026-08-01, Locked, Reason "Audit close" | ◀ to Aug 2026 | varCanEditMonth false | lblAttNotice "August 2026 is locked for Seed Campus Alpha — Audit close. Cells are read-only."; all cells/All/Save notes Disabled | N/A |
| S-BLOCK-READONLY | App Role Read-only | open | varCanEditMonth false | notice "View only …"; cells Disabled; Details mode opens panel, notes View | N/A |
| S-FAIL-RETRY | Browser offline | tap S2 Sep 28 | no row; colMonthAtt unchanged | cell "!" red border; receipt "Failed · S2 · Mon Sep 28 · Present was not saved …" | online → tap "!" → "P✓", receipt Saved |
| S-CONFLICT | Grid loaded; 2nd session marks S3 Sep 28 Present | 1st session taps S3 Sep 28 | no write; local refreshed from server | cell "P"; receipt "Changed by someone else — reloaded · S3 · Mon Sep 28 · now Present · your change was not saved" | Modified On mismatch on an existing row behaves the same |
| S-DETAIL-NOTES | Details mode on; S1 Sep 25 recorded | tap cell; type "Left early 1pm"; Save notes | Notes updated on same GUID | panel facts; receipt "Notes saved · … · Notes \"Left early 1pm\" · Key …"; reopen shows notes | conflict → reloaded, notes not saved |
| S-DAYVIEW-MARK | Width < 640 (Day tab default) or Day tab selected; Mon Sep 28 | Present on S4, then Absent | same engine writes as A-MARK-CELL | lblAttDayStatus "Present ✓ saved" → "Absent, not classified ✓ saved"; receipt; Month tab cell matches | non-school day → lblAttDayNotice, list hidden |
| S-EMPTY | Teacher with no enrollments in month (e.g. Jul 2026) | load | colMonthStudents empty | lblAttEmpty "No students for T1 in July 2026."; grid hidden; Day notice | N/A |

## Relevant Data Source Schemas (display names used in formulas)

- Attendance: `Attendance` (GUID), `'Record Key'`, `Date`, `Present` (Boolean), `'Is Deleted'` (Boolean),
  `Student`→Students, `Service`→Services, `Enrollment`→Enrollments, `Teacher`→Staff, `Campus`→Campuses,
  `'School Year'`→School Years, `Term`→Terms, `'IEP Ratio'` ('IEP Ratio (Attendance)': 'No Aide','1:1','2:1','3:1','4:1'),
  `'Absence Classification'` ('Absence Classification (Attendance)': Excused, Unexcused; read-only),
  `'Absence Reason'`→Absence Reasons (read-only), `Notes`, `'Modified On'`.
- Enrollments: `Enrollment` (GUID), `Student`, `Campus`, `Teacher`, `Service`, `'School Year'`,
  `Program` ('Program (Enrollments)': 'Regular Year', Summer), `'IEP Ratio'` ('IEP Ratio (Enrollments)'), `'Start Date'`, `'End Date'`.
- Students: `Student` (GUID), `'Display Name'`, `'Student Number'`. Services: `Service` (GUID), `'Service Code'`.
- Staff: `Staff` (GUID), `Name`, `'App Role'`, `Campus`, `User`, `Active`. Campuses: `Campus` (GUID), `Name`.
- Terms: `'Term (aaca_termid)'` (GUID), `Name`, `Campus`, `'Term (aaca_term)'` ('Term (Terms)': Q1–Q4, Summer), `'Start Date'`, `'End Date'`.
- Calendar Exceptions: `Date`, `Campus`, `Type` ('Type (Calendar Exceptions)': Holiday, Break, 'Staff Development', Closure, 'Make-up School Day'), `Description`.
- Month Locks: `Campus`, `Month`, `'Status (aaca_status)'` ('Status (Month Locks)'.Locked), `Reason`.
- Audit Events: `Summary`, `Action` ('Action (Audit Events)'.'Soft Delete'), `Entity`, `'Entity ID'`, `Before`, `After`, `Reason`.
- Absence Reasons: primary-name column NOT in the discovery packet; the brief assumes `Name`
  (`'Absence Reason'.Name`, used only in lblAttDetailFacts). If the compile rejects it, replace
  that one reference with the correct primary column.

## Required Variants

- GroupContainer → `Variant: AutoLayout` (every container on this screen)
- Gallery → `Variant: Horizontal` for galAttDayHead, galAttCells, galAttDayTotals;
  `Variant: Vertical` for galAttRows, galAttDayList

## Control Definitions

Creation keywords (verbatim from describe_control): `Control: GroupContainer` (+Variant),
`Control: ModernText`, `Control: ModernButton`, `Control: Classic/Button`, `Control: Gallery`
(+Variant), `Control: ModernDropdown`, `Control: ModernTabList`, `Control: ModernTextInput`,
`Control: ModernSpinner`. No `@version` suffix.

- **GroupContainer** — BorderColor, BorderStyle, BorderThickness, ContentLanguage, DropShadow,
  EnableChildFocus, Fill, Height, RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft,
  RadiusTopRight, Visible, Width, X, Y; AutoLayout: LayoutAlignItems, LayoutDirection,
  LayoutGap, LayoutJustifyContent, LayoutOverflowX, LayoutOverflowY, LayoutWrap,
  PaddingBottom, PaddingLeft, PaddingRight, PaddingTop; as child: AlignInContainer,
  FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight, LayoutMinWidth.
  Literals: `=LayoutDirection.Vertical` / `=LayoutDirection.Horizontal`,
  `=LayoutAlignItems.Stretch` / `.Center`, `=LayoutOverflow.Scroll` / `.Hide`,
  `=AlignInContainer.Stretch` / `.Center`, `=DropShadow.None`, `=BorderStyle.Solid`.
- **ModernText** — AccessibleLabel, Align, AutoHeight, BorderColor, BorderStyle,
  BorderThickness, Color, ContentLanguage, DisplayMode, Fill, Font, FontWeight, Height,
  Italic, OnSelect, PaddingBottom, PaddingLeft, PaddingRight, PaddingTop, Radius*, Size,
  Strikethrough, Text, Underline, VerticalAlign, Visible, Width, Wrap, X, Y; child props as
  above. Literals: `=Align.Left` / `.Center`, `=FontWeight.Bold` / `.Semibold` / `.Normal`,
  `=VerticalAlign.Middle` / `.Bottom`.
- **ModernButton** (no Fill) — AccessibleLabel, Align, Appearance, BasePaletteColor,
  BorderColor, BorderStyle, BorderThickness, Color, ContentLanguage, DisplayMode, Font,
  FontWeight, Height, Icon, IconRotation, IconStyle, Italic, Layout, OnSelect, Padding*,
  Radius*, Size, Strikethrough, Text, Tooltip, Underline, VerticalAlign, Visible, Width, X, Y.
  Literals: `=ButtonAppearance.Primary` / `.Secondary`, `=ButtonLayout.TextOnly`,
  `=DisplayMode.Edit` / `.Disabled`.
- **Classic/Button** (no AccessibleLabel) — Align, AutoDisableOnSelect, BorderColor,
  BorderStyle, BorderThickness, Color, ContentLanguage, DisabledBorderColor, DisabledColor,
  DisabledFill, DisplayMode, Fill, FocusedBorderColor, FocusedBorderThickness, Font,
  FontWeight, Height, HoverBorderColor, HoverColor, HoverFill, Italic, OnSelect,
  PaddingBottom, PaddingLeft, PaddingRight, PaddingTop, PressedBorderColor, PressedColor,
  PressedFill, RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft, RadiusTopRight, Size,
  Strikethrough, TabIndex, Text, Tooltip, Underline, VerticalAlign, Visible, Width, X, Y.
  Literals: `=Align.Center`, `=FontWeight.Bold`, `=VerticalAlign.Middle`,
  `=BorderStyle.Solid` / `.Dashed`, `=DisplayMode.Edit` / `.Disabled`.
- **Gallery** — BorderStyle, ContentLanguage, Default, DisplayMode, Fill, FocusedBorderColor,
  FocusedBorderThickness, LoadingSpinnerColor, NavigationStep, Selectable, ShowNavigation,
  TabIndex, Transition, Visible; Vertical/Horizontal: AccessibleLabel, BorderColor,
  BorderThickness, DelayItemLoading, Height, Items, LoadingSpinner, ShowScrollbar,
  TemplatePadding, TemplateSize, Width, WrapCount, X, Y; child props as above.
- **ModernDropdown** — AccessibleLabel, Appearance, BasePaletteColor, BorderColor, BorderStyle,
  BorderThickness, Color, ContentLanguage, Default, DisplayMode, Fill, Font, FontWeight,
  Height, Italic, ItemDisplayText, Items, OnChange, Padding*, Radius*, Required, Size,
  Strikethrough, Underline, ValidationState, Visible, Width, X, Y. Output `Selected`.
  Literal: `=Appearance.Outline`.
- **ModernTabList** — AccessibleLabel, Align, Alignment, Appearance, BasePaletteColor, Color,
  ContentLanguage, Default, DisplayMode, Font, FontWeight, Height, Italic, ItemDisplayText,
  Items, OnChange, OnSelect, Padding*, Size, Strikethrough, TabSize, Underline, Visible,
  Width, X, Y. Output `Selected`. Literals: `=TabListAppearance.Subtle`, `=TabSize.Small`.
- **ModernTextInput** — AccessibleLabel, Align, Appearance, BasePaletteColor, BorderColor,
  BorderStyle, BorderThickness, Color, ContentLanguage, Default, DisplayMode, Fill, Font,
  FontWeight, Height, Italic, MaxLength, OnChange, Padding*, Placeholder, Radius*, Required,
  Size, Strikethrough, TriggerOutput, Type, Underline, ValidationState, Visible, Width, X, Y.
  Output `Text`. Literals: `=Appearance.Outline`, `=TextInputType.Multiline`,
  `=DisplayMode.Edit` / `.View`.
- **ModernSpinner** — AccessibleLabel, Appearance, BasePaletteColor, Color, ContentLanguage,
  DisplayMode, Font, FontWeight, Height, Italic, Label, LabelPosition, LineHeight, Padding*,
  Size, SpinnerColor, Strikethrough, Tooltip, TrackColor, Underline, Visible, Width, X, Y.
  Literals: `=SpinnerAppearance.Primary`, `=SpinnerLabelPosition.After`.

## Builder notes

- Accessibility approximation (approved): Classic/Button cells have no AccessibleLabel; the
  Tooltip carries "Name – Day – Status (reason)" and the visible letter is the non-colour cue.
- `Select()` of the engines is used from OnVisible, galleries and buttons; engines must stay
  `DisplayMode.Edit` and `AutoDisableOnSelect: =false`.
- Keep the engines as the only writers to `Attendance`/`Audit Events` besides
  btnAttDetailSave.OnSelect.
