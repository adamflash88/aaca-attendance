# Screen Plan: Absences (build 4 — parent-report matching)

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml`
- YAML key: AbsencesScreen
- Control name prefix: Abs. New parent-report controls use `AbsNr`

Read `C:\src\aaca-attendance\app\canvas-app-shared.md` first (palette, type roles, conventions).

## Current State

`conAbsRoot` is the sole top-level child: AutoLayout, vertical, scroll, `LayoutGap: =8`. Its children, in order:
`conAbsHeader`, `conAbsDenied` (Visible `!CanClassify`), `conAbsNotice`, `spnAbsLoading`, `conAbsReceipt`,
`conAbsBody` (list and decide panels), then the hidden engines `btnAbsLoadEngine` and `btnAbsClassifyEngine`.
`OnVisible` loads the filter sources, then runs `Select(btnAbsLoadEngine)`. There are 83 controls; this edit
adds 39.

## Changes

1. **Screen `OnVisible`**: prepend `Set(varAbsNrSaving, false);` as the first statement. Append
   `; Select(btnAbsNrEngine)` after the final `Select(btnAbsLoadEngine)`. Leave everything else unchanged.
   If `varAbsNrLoaded` is false, the toggle button also triggers the load, so the view is still reached if a
   second queued Select is ever dropped.
2. **Insert `conAbsViewBar`** under `conAbsRoot`, directly after `conAbsHeader` (before `conAbsDenied`).
3. **Wrap the classify view.** Insert a new container `conAbsClassifyView` under `conAbsRoot` after
   `conAbsDenied`. **Move** `conAbsNotice`, `spnAbsLoading`, `conAbsReceipt` and `conAbsBody` into its
   `Children` in that order. Move each block verbatim; do not change any property of the moved controls or
   their descendants.
4. **Insert `conAbsNrView`** under `conAbsRoot` after `conAbsClassifyView`. It holds the whole parent-report
   view (below).
5. **Insert the hidden engine `btnAbsNrEngine`** as the last child of `conAbsRoot` (after
   `btnAbsClassifyEngine`).
6. Do not modify `conAbsRoot`, `conAbsHeader`, `conAbsDenied`, `btnAbsLoadEngine` or `btnAbsClassifyEngine`.

Final `conAbsRoot.Children` order: conAbsHeader, conAbsViewBar, conAbsDenied, conAbsClassifyView,
conAbsNrView, btnAbsLoadEngine, btnAbsClassifyEngine, btnAbsNrEngine.

## Layout and Visual Impact

- Breakpoint source: `conAbsRoot.Width` everywhere (`< 640` phone, `< 1024` stacked, `>= 1024` side by side),
  the same as the existing screen.
- Numeric budgets:
  - conAbsViewBar at `>= 640`: 16 + 170 + 8 + 320 + 16 = 530 ≤ 640. At `< 640`: vertical, 44 + 8 + 44 = 96.
  - conAbsNrListPanel: 16 + 44 + 8 + (54 phone | 36) + (8 + 520 when rows) + 16.
  - galAbsNrList row: phone 8+44+4+54+4+54+8 = 176 ≤ TemplateSize 180. Wider: 8+44+4+36+4+36+8 = 140 ≤ 144.
  - conAbsNrDetail when selected: phone 16+28+8+200+8+80+8+98+8+44+8+54+8+44+16 = 628. At `>= 640`:
    16+28+8+130+8+40+8+98+8+44+8+36+8+44+16 = 500. Empty: 16+28+8+60+16 = 128.
  - conAbsNrPickField: 18 + 4 + 36 + 4 + 36 = 98.
  - conAbsNrReceipt: 8 + (84 | 44) + (4 + (220 | 148) when Body ≠ "") + 8.
  - Actions row: 150 + 8 + 100 = 258 ≤ 326 (the phone inner width of 390 − 2×16 panel padding − 32).
- Text fit: row name 14 Semibold, 2 lines within 42. The meta and sub labels wrap: 2 lines at 36, 3 lines
  at 54 on phone. Facts has 7 lines at 13 (≈18 each), so 130; about 11 lines on phone, so 200. Days is
  2 lines (40), or 4 lines on phone (80). The check label is 2 lines (36), or 3 on phone (54). The receipt
  title can wrap up to 2 lines (44) or 4 on phone (84). Titles are kept under about 70 characters; details
  go in Body.
- Visual contract: panels are ColorWhite with a ColorRule 1px border, radius 6 and padding 16. The view
  buttons use Primary (teal) for the current view and Secondary for the other. The receipt uses the existing
  conAbsReceipt styling.
- Record presentation: the canonical identity is the parent-typed name (`lblAbsNrRowName`) plus the report ID
  (`lblAbsNrRowMeta`). The only row action is **Review**. Resolve Match and Cancel sit together in the detail
  panel.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --------- | -------------- | -------------- | ------------ | ------------- | ------------- | ------------------------ |
| NR-ROW-NAME | galAbsNrList row | Typed name | FirstName, LastName | lblAbsNrRowName | `=If(Trim(ThisItem.LastName & ThisItem.FirstName) = "", "(no name typed)", ThisItem.LastName & ", " & ThisItem.FirstName) & " (as typed)"` | Top row, FillPortions 1, Height 42, Size 14 Semibold |
| NR-ROW-META | galAbsNrList row | ID, Title, site, dates | ID, Title, SchoolSite, AbsenceDateText, ReturnDateText | lblAbsNrRowMeta | `="#" & ThisItem.ID & If(ThisItem.Title = "", "", " · " & ThisItem.Title) & " · " & ThisItem.SchoolSite & " · absent " & ThisItem.AbsenceDateText & If(Trim(ThisItem.ReturnDateText) = "", "", " · back " & ThisItem.ReturnDateText)` | Height `=If(conAbsRoot.Width < 640, 54, 36)`, Size 12, ColorInk, VerticalAlign Top |
| NR-ROW-SUB | galAbsNrList row | Reason, submitted by, notified | Reason, SubmittedBy, DateNotified | lblAbsNrRowSub | `="Reason " & If(ThisItem.Reason = "", "—", If(Len(ThisItem.Reason) > 80, Left(ThisItem.Reason, 80) & "…", ThisItem.Reason)) & " · submitted by " & ThisItem.SubmittedBy & " · notified " & ThisItem.DateNotified` | Height `=If(conAbsRoot.Width < 640, 54, 36)`, Size 12, ColorMuted, VerticalAlign Top |
| NR-DET-FACTS | conAbsNrDetail | All submitted fields | see formula | lblAbsNrFacts | see Controls to Add | Visible when selected |
| NR-DET-DAYS | conAbsNrDetail | Days of absence | computed | lblAbsNrDays | see Controls to Add | Visible when selected |
| NR-PICK-OPTION | cboAbsNrStudent | Last, First · code · key · status | colAbsNrStudents.Label | cboAbsNrStudent | `ItemDisplayText: =ThisItem.Label` | Picker options |

## Controls to Add

Every GroupContainer below uses `Variant: AutoLayout` and sets `DropShadow: =DropShadow.None`,
`LayoutMinWidth: =0` and `LayoutMinHeight: =0`. If its parent is AutoLayout it also sets
`FillPortions: =0` (unless stated otherwise) and `AlignInContainer`. Every ModernText sets the four
`Padding*` to 0, `LayoutMinWidth: =0`, `LayoutMinHeight: =0`, `AlignInContainer: =AlignInContainer.Stretch`,
`AccessibleLabel: =Self.Text` (unless stated otherwise) and `VerticalAlign: =VerticalAlign.Top` for
wrapping text. Every ModernButton sets `Height: =44`, `Layout: =ButtonLayout.TextOnly`, `Size: =14`,
`LayoutMinWidth: =0` and `LayoutMinHeight: =0`.

### A. conAbsViewBar (after conAbsHeader)

- `conAbsViewBar`: GroupContainer. Properties:
  - Visible `=CanClassify`
  - Height `=If(conAbsRoot.Width < 640, 96, 44)`
  - LayoutDirection `=If(conAbsRoot.Width < 640, LayoutDirection.Vertical, LayoutDirection.Horizontal)`
  - LayoutAlignItems `=If(conAbsRoot.Width < 640, LayoutAlignItems.Stretch, LayoutAlignItems.Center)`
  - LayoutGap 8, PaddingLeft 16, PaddingRight 16, AlignInContainer Stretch, radii 0
  - `btnAbsViewClassify`:
    - Text `="Classify absences"`
    - Appearance `=If(varAbsView = "classify", ButtonAppearance.Primary, ButtonAppearance.Secondary)`
    - BasePaletteColor `=ColorTeal`
    - Color `=If(varAbsView = "classify", ColorWhite, ColorInk)`
    - AccessibleLabel `="Classify absences" & If(varAbsView = "classify", " (current view)", "")`
    - Width `=If(conAbsRoot.Width < 640, Parent.Width - 32, 170)`, FillPortions 0
    - AlignInContainer `=If(conAbsRoot.Width < 640, AlignInContainer.Stretch, AlignInContainer.Center)`
    - OnSelect `=Set(varAbsView, "classify")`
  - `btnAbsViewNr`: same styling pattern with `"nr"`. Properties:
    - Text `="Parent reports – Needs review (" & If(varAbsNrLoaded, Text(CountRows(colAbsNr)), "…") & ")"`
    - AccessibleLabel `=Self.Text & If(varAbsView = "nr", " (current view)", "")`
    - Width `=If(conAbsRoot.Width < 640, Parent.Width - 32, 320)`
    - OnSelect `=Set(varAbsView, "nr"); If(!varAbsNrLoaded && !varAbsNrLoading, Select(btnAbsNrEngine))`

### B. conAbsClassifyView (after conAbsDenied)

- GroupContainer. Properties:
  - Visible `=varAbsView = "classify"`
  - LayoutDirection Vertical, LayoutAlignItems Stretch, LayoutGap 8, AlignInContainer Stretch, radii 0, no Fill
  - Height:
    `=If(conAbsNotice.Visible, conAbsNotice.Height + 8, 0) + If(spnAbsLoading.Visible, 48 + 8, 0) + If(conAbsReceipt.Visible, conAbsReceipt.Height + 8, 0) + If(conAbsBody.Visible, conAbsBody.Height, 0)`
  - Children: the moved `conAbsNotice`, `spnAbsLoading`, `conAbsReceipt` and `conAbsBody`, unchanged.

### C. conAbsNrView (after conAbsClassifyView)

- GroupContainer. Properties:
  - Visible `=CanClassify && varAbsView = "nr"`
  - LayoutDirection Vertical, LayoutAlignItems Stretch, LayoutGap 8, AlignInContainer Stretch, radii 0
  - Height `=If(spnAbsNrBusy.Visible, 48 + 8, 0) + If(conAbsNrReceipt.Visible, conAbsNrReceipt.Height + 8, 0) + conAbsNrBody.Height`
- Children, in order:
  1. `spnAbsNrBusy`: ModernSpinner.
     - Visible `=varAbsNrLoading || varAbsNrSaving`
     - Height 48, FillPortions 0, AlignInContainer Stretch
     - Label `=If(varAbsNrSaving, "Saving match…", "Loading parent reports…")`
     - AccessibleLabel `=Self.Label`
     - SpinnerColor `=ColorTeal`, Color `=ColorInk`, LayoutMinWidth 0, LayoutMinHeight 0
  2. `conAbsNrReceipt`: GroupContainer.
     - Visible `=varAbsNrReceipt.Kind <> ""`
     - Fill `=Switch(varAbsNrReceipt.Kind, "Failed", ColorErrorBg, "Blocked", ColorErrorBg, ColorInfoBg)`
     - BorderColor ColorRule, BorderThickness 1, radii 6
     - PaddingTop 8, PaddingBottom 8, PaddingLeft 12, PaddingRight 12, Vertical, Stretch, LayoutGap 4
     - Height `=8 + If(conAbsRoot.Width < 640, 84, 44) + If(varAbsNrReceipt.Body = "", 0, 4 + If(conAbsRoot.Width < 640, 220, 148)) + 8`
     - `conAbsNrReceiptTop`: Horizontal, LayoutAlignItems Center, LayoutGap 8, Height `=If(conAbsRoot.Width < 640, 84, 44)`
       - `lblAbsNrReceiptTitle`: Text `=varAbsNrReceipt.Title`, FillPortions 1, Height the same as the parent,
         Size 13 Semibold, ColorInk, AlignInContainer Center
       - `btnAbsNrReceiptDismiss`: Secondary, Color ColorInk, Text `="Dismiss"`, Width 88, FillPortions 0,
         AlignInContainer Center, AccessibleLabel `="Dismiss match result"`
         - OnSelect `=Set(varAbsNrReceipt, {Kind: "", Title: "", Body: "", ItemId: 0})`. This value contains
           `: `, so write it in a `|-` block.
     - `lblAbsNrReceiptBody`: Text `=varAbsNrReceipt.Body`, Visible `=varAbsNrReceipt.Body <> ""`,
       Height `=If(conAbsRoot.Width < 640, 220, 148)`, Size 12, ColorInk, FillPortions 0
  3. `conAbsNrBody`: GroupContainer. Radii 0, LayoutGap 8. Properties:
     - LayoutDirection `=If(conAbsRoot.Width >= 1024, LayoutDirection.Horizontal, LayoutDirection.Vertical)`
     - LayoutAlignItems `=If(conAbsRoot.Width >= 1024, LayoutAlignItems.Start, LayoutAlignItems.Stretch)`
     - Height:
       `=If(conAbsRoot.Width >= 1024, Max(conAbsNrListPanel.Height, conAbsNrDetail.Height), If(conAbsNrListPanel.Visible, conAbsNrListPanel.Height, 0) + If(conAbsNrListPanel.Visible && conAbsNrDetail.Visible, 8, 0) + If(conAbsNrDetail.Visible, conAbsNrDetail.Height, 0))`

#### C1. conAbsNrListPanel (child of conAbsNrBody)

- GroupContainer panel (ColorWhite, ColorRule border 1, radii 6, padding 16, Vertical, Stretch, LayoutGap 8).
  Properties:
  - AlignInContainer `=If(conAbsRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)`
  - FillPortions `=If(conAbsRoot.Width >= 1024, 1, 0)`
  - Visible `=!(conAbsRoot.Width < 1024 && !IsBlank(varAbsNrSelId))`
  - Height `=16 + 44 + 8 + If(conAbsRoot.Width < 640, 54, 36) + If(CountRows(colAbsNr) > 0, 8 + 520, 0) + 16`
- `conAbsNrListHead`: Horizontal, LayoutAlignItems Center, LayoutGap 8, Height 44.
  - `lblAbsNrListTitle`: Text `="Needs review (" & CountRows(colAbsNr) & ")"`, Size 20 Bold, Height 30,
    FillPortions 1, LayoutMinWidth 80, Wrap false, AlignInContainer Center, ColorInk
  - `btnAbsNrReload`: Secondary, ColorInk, Text `="Reload"`, Width 80, FillPortions 0,
    AccessibleLabel `="Reload parent reports"`, AlignInContainer Center
    - DisplayMode `=If(varAbsNrLoading || varAbsNrSaving, DisplayMode.Disabled, DisplayMode.Edit)`
    - OnSelect `=Select(btnAbsNrEngine)`
- `lblAbsNrCount`: Size 13 Semibold. Properties:
  - Height `=If(conAbsRoot.Width < 640, 54, 36)`
  - Color `=If(varAbsNrLoadError <> "", ColorUnexcused, ColorInk)`
  - Text (in a `|-` block):
    `=If(varAbsNrLoadError <> "", "Could not load parent reports — " & varAbsNrLoadError & ". Use Reload to try again.", varAbsNrLoading, "Loading parent reports…", CountRows(colAbsNr) = 0, "No parent reports need review. Unmatched website submissions appear here after Reload.", CountRows(colAbsNr) & If(CountRows(colAbsNr) = 1, " parent report needs", " parent reports need") & " review · newest first · choose Review to match one")`
- `galAbsNrList`: Gallery `Variant: Vertical`. Properties:
  - AccessibleLabel `="Parent reports needing review"`
  - Items `=Sort(colAbsNr, Created, SortOrder.Descending)`
  - Height 520, FillPortions 0, LayoutMinWidth 0, LayoutMinHeight 0, Selectable false, TabIndex 0
  - TemplatePadding 0, TemplateSize `=If(conAbsRoot.Width < 640, 180, 144)`
  - Visible `=CountRows(colAbsNr) > 0`
  - `conAbsNrRowShell` (sole child): Vertical, Stretch, LayoutGap 4, padding 8 on all four sides, radii 0,
    BorderColor ColorRule, BorderThickness 1
    - Fill `=If(ThisItem.ID = varAbsNrSelId, ColorInfoBg, ColorWhite)`
    - Width `=Parent.TemplateWidth - 16`, Height `=Parent.TemplateHeight`
    - `conAbsNrRowTop`: Horizontal, LayoutAlignItems Center, LayoutGap 8, Height 44, FillPortions 0
      - `lblAbsNrRowName`: per NR-ROW-NAME; AccessibleLabel `="Reported student " & Self.Text`,
        AlignInContainer Center
      - `btnAbsNrRowReview`: Secondary, ColorInk, Text `="Review"`, Width 90, FillPortions 0,
        AlignInContainer Center
        - AccessibleLabel `="Review parent report #" & ThisItem.ID`
        - DisplayMode `=If(varAbsNrLoading || varAbsNrSaving, DisplayMode.Disabled, DisplayMode.Edit)`
        - OnSelect: see A-SELECT-NR below
    - `lblAbsNrRowMeta`: per NR-ROW-META
    - `lblAbsNrRowSub`: per NR-ROW-SUB

#### C2. conAbsNrDetail (child of conAbsNrBody)

- GroupContainer panel (as the list panel). Properties:
  - AlignInContainer `=If(conAbsRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)`
  - FillPortions `=If(conAbsRoot.Width >= 1024, 1, 0)`
  - Visible `=conAbsRoot.Width >= 1024 || !IsBlank(varAbsNrSelId)`
  - Height:
    `=16 + 28 + 8 + If(IsBlank(varAbsNrSelId), 60, If(conAbsRoot.Width < 640, 200, 130) + 8 + If(conAbsRoot.Width < 640, 80, 40) + 8 + 98 + 8 + 44 + 8 + If(conAbsRoot.Width < 640, 54, 36) + 8 + 44) + 16`
- `lblAbsNrDetailTitle`: Text `="Match a parent report"`, Size 18 Bold, Height 28, Wrap false, ColorInk
- `lblAbsNrDetailEmpty`: Visible `=IsBlank(varAbsNrSelId)`, Height 60, Size 13, ColorMuted.
  Text `="Choose Review on a parent report to see what the parent submitted and pick the student."`
- `lblAbsNrFacts`: Visible `=!IsBlank(varAbsNrSelId)`, Height `=If(conAbsRoot.Width < 640, 200, 130)`, Size 13,
  ColorInk. Text (`|-` block):
  ```
  =With(
      {it: LookUp(colAbsNr, ID = varAbsNrSelId)},
      With(
          {code: LookUp(colAbsNrCampuses, CampusName = Trim(it.SchoolSite)).CampusCode},
          "Report #" & it.ID & If(it.Title = "", "", " · " & it.Title) & Char(10) &
          "Student as typed: " & it.FirstName & " " & it.LastName & Char(10) &
          "School site: " & it.SchoolSite & If(IsBlank(code) || code = "", " (no matching campus)", " (" & code & ")") & Char(10) &
          "Absence date: " & it.AbsenceDateText & " · Return date: " & If(Trim(it.ReturnDateText) = "", "—", it.ReturnDateText) & Char(10) &
          "Reason: " & If(it.Reason = "", "—", If(Len(it.Reason) > 120, Left(it.Reason, 120) & "…", it.Reason)) & Char(10) &
          "Submitted by " & it.SubmittedBy & " · notified " & it.DateNotified
      )
  )
  ```
- `lblAbsNrDays`: Visible `=!IsBlank(varAbsNrSelId)`, Height `=If(conAbsRoot.Width < 640, 80, 40)`, Size 13
  Semibold. Color `=If(StartsWith(Self.Text, "Days of absence: check"), ColorUnexcused, ColorInk)`.
  Text (`|-` block):
  ```
  =With(
      {it: LookUp(colAbsNr, ID = varAbsNrSelId)},
      With(
          {
              d0: IfError(DateValue(it.AbsenceDateText, "en-US"), Blank()),
              r0: IfError(DateValue(it.ReturnDateText, "en-US"), Blank()),
              cid: LookUp(colAbsNrCampuses, CampusName = Trim(it.SchoolSite)).CampusId
          },
          With(
              {dEnd: If(IsBlank(r0) || r0 <= d0, d0, DateAdd(r0, -1, TimeUnit.Days))},
              If(
                  IsBlank(d0) || (Trim(it.ReturnDateText) <> "" && IsBlank(r0)),
                  "Days of absence: check dates — the parent typed Absence Date """ & it.AbsenceDateText & """ and Return Date """ & it.ReturnDateText & """, which can't be read as M/D/YYYY.",
                  DateDiff(d0, dEnd, TimeUnit.Days) > 180,
                  "Days of absence: check dates — the span from " & it.AbsenceDateText & " to " & it.ReturnDateText & " is over 180 days.",
                  varAbsNrCalFor <> varAbsNrSelId,
                  "Days of absence: calculating…",
                  With(
                      {
                          n: CountRows(
                              Filter(
                                  ForAll(Sequence(DateDiff(d0, dEnd, TimeUnit.Days) + 1, 0) As k, {D: DateAdd(d0, k.Value, TimeUnit.Days)}),
                                  !IsBlank(LookUp(colAbsNrTerms, (IsBlank(CampusId) || CampusId = cid) && TStart <= D && TEnd >= D)) &&
                                  IsBlank(LookUp(colAbsNrExc, (IsBlank(CampusId) || CampusId = cid) && XDate = D && IsClosed)) &&
                                  (Weekday(D, StartOfWeek.Monday) <= 5 || !IsBlank(LookUp(colAbsNrExc, (IsBlank(CampusId) || CampusId = cid) && XDate = D && IsMakeup)))
                              )
                          )
                      },
                      "Days of absence: " & n & If(n = 1, " school day", " school days") & " · " & Text(d0, "ddd m/d/yyyy") & If(dEnd = d0, "", " – " & Text(dEnd, "ddd m/d/yyyy")) & If(IsBlank(cid), " · campus not recognised, all-campus calendar only", "")
                  )
              )
          )
      )
  )
  ```
  Rule: count a day when it is in a campus or all-campus Term, has no Closed/Work Only exception (campus or
  all-campus), and is Monday–Friday or a Make-up School Day.
- `conAbsNrPickField`: Vertical, Stretch, LayoutGap 4, Height 98, Visible `=!IsBlank(varAbsNrSelId)`
  - `lblAbsNrPick`: Text `="Student *"`, Height 18, Size 12 Semibold, ColorMuted, Wrap false
  - `cboAbsNrStudent`: ModernCombobox. Properties:
    - AccessibleLabel `="Student"`, Appearance `=Appearance.Outline`, Color `=ColorInk`
    - Height 36, FillPortions 0, AlignInContainer Stretch, LayoutMinWidth 0, LayoutMinHeight 0
    - SelectMultiple `=false`, IsSearchable `=true`, DefaultSelectedItems `=[]`
    - InputTextPlaceholder `="Type a name or Student Key"`
    - ItemDisplayText `=ThisItem.Label`
    - DisplayMode `=If(varAbsNrSaving, DisplayMode.Disabled, DisplayMode.Edit)`
    - Items (`|-` block):
      `=With({site: Trim(LookUp(colAbsNr, ID = varAbsNrSelId).SchoolSite)}, With({code: LookUp(colAbsNrCampuses, CampusName = site).CampusCode}, Sort(Filter(colAbsNrStudents, varAbsNrAllCampuses || IsBlank(code) || code = "" || CampusCode = code), DisplayName, SortOrder.Ascending)))`
    - OnChange `=Set(varAbsNrPickId, If(CountRows(Self.SelectedItems) = 0, Blank(), First(Self.SelectedItems).StudentId))`
  - `lblAbsNrPickHint`: Height 36, Size 12, ColorMuted. Text (`|-` block):
    `=With({site: Trim(LookUp(colAbsNr, ID = varAbsNrSelId).SchoolSite)}, With({code: LookUp(colAbsNrCampuses, CampusName = site).CampusCode}, With({n: CountRows(Filter(colAbsNrStudents, varAbsNrAllCampuses || IsBlank(code) || code = "" || CampusCode = code))}, If(varAbsNrAllCampuses, "All campuses · " & n & " students, all statuses incl. archived.", IsBlank(code) || code = "", "School site """ & site & """ matches no campus, so all campuses are shown (" & n & ").", code & " students · " & n & ", all statuses incl. archived. Tick Search all campuses to widen."))))`
- `chkAbsNrAll`: ModernCheckbox. Properties:
  - Label `="Search all campuses"`, AccessibleLabel `="Search all campuses"`, Color `=ColorInk`
  - Height 44, FillPortions 0, AlignInContainer Stretch, LayoutMinWidth 0, LayoutMinHeight 0
  - Default `=varAbsNrAllCampuses`, Visible `=!IsBlank(varAbsNrSelId)`
  - DisplayMode `=If(varAbsNrSaving, DisplayMode.Disabled, DisplayMode.Edit)`
  - OnCheck `=Set(varAbsNrAllCampuses, true)`
  - OnUncheck `=Set(varAbsNrAllCampuses, false); Set(varAbsNrPickId, Blank()); Reset(cboAbsNrStudent)`
- `lblAbsNrCheck`: Visible `=!IsBlank(varAbsNrSelId)`, Height `=If(conAbsRoot.Width < 640, 54, 36)`, Size 13.
  Color `=If(StartsWith(Self.Text, "Ready"), ColorExcused, ColorUnexcused)`. Text (`|-` block):
  `=With({it: LookUp(colAbsNr, ID = varAbsNrSelId), stu: LookUp(colAbsNrStudents, StudentId = varAbsNrPickId)}, If(IsBlank(it), "That report is no longer in the queue. Use Reload.", IsBlank(varAbsNrPickId) || CountRows(cboAbsNrStudent.SelectedItems) <> 1, "Pick the student this report is about. Resolve Match stays off until you do.", stu.StudentKey = "", stu.DisplayName & " has no Student Key, so it can't be matched. Add the key on the Students screen first.", "Ready: Resolve Match sets Student_ID " & stu.StudentKey & " and Match_Status Manually Resolved on report #" & it.ID & "."))`
- `conAbsNrActions`: Horizontal, LayoutAlignItems Center, LayoutGap 8, Height 44,
  Visible `=!IsBlank(varAbsNrSelId)`
  - `btnAbsNrResolve`: Primary. Properties:
    - BasePaletteColor ColorTeal, Color ColorWhite, Text `="Resolve Match"`, Width 150, FillPortions 0
    - AccessibleLabel `="Resolve Match"`, AlignInContainer Center
    - DisplayMode (`|-` block):
      `=If(CanClassify && !varAbsNrSaving && !varAbsNrLoading && !IsBlank(LookUp(colAbsNr, ID = varAbsNrSelId)) && !IsBlank(varAbsNrPickId) && CountRows(cboAbsNrStudent.SelectedItems) = 1 && LookUp(colAbsNrStudents, StudentId = varAbsNrPickId).StudentKey <> "", DisplayMode.Edit, DisplayMode.Disabled)`
    - OnSelect: see A-RESOLVE below
  - `btnAbsNrCancel`: Secondary, ColorInk, Text `="Cancel"`, Width 100, FillPortions 0, AlignInContainer Center.
    - AccessibleLabel `="Cancel and return to the list"`
    - DisplayMode `=If(varAbsNrSaving, DisplayMode.Disabled, DisplayMode.Edit)`
    - OnSelect `=Set(varAbsNrSelId, Blank()); Set(varAbsNrPickId, Blank()); Set(varAbsNrAllCampuses, false); Reset(cboAbsNrStudent); Reset(chkAbsNrAll)`

### D. btnAbsNrEngine (last child of conAbsRoot)

- Classic/Button. Properties: Visible `=false`, Text `="nr load"`, AutoDisableOnSelect `=false`,
  AlignInContainer Stretch, LayoutMinWidth 0, LayoutMinHeight 0. OnSelect (`|-` block):

```
=Set(varAbsNrLoading, true);
Set(varAbsNrLoadError, "");
Set(varAbsNrSelId, Blank());
Set(varAbsNrPickId, Blank());
Set(varAbsNrAllCampuses, false);
Reset(cboAbsNrStudent);
Reset(chkAbsNrAll);
If(
    !CanClassify,
    Clear(colAbsNr),
    IfError(
        Concurrent(
            ClearCollect(
                colAbsNr,
                ForAll(
                    Sort(Filter('Student Absence Log', Match_Status.Value = "Needs Review"), Created, SortOrder.Descending) As r,
                    {
                        ID: r.ID, Title: Coalesce(r.Title, ""), Created: r.Created,
                        FirstName: Coalesce(r.'Student First Name', ""), LastName: Coalesce(r.'Student Last Name', ""),
                        SchoolSite: Coalesce(r.'School Site', ""),
                        AbsenceDateText: Coalesce(r.'Absence Date', ""), ReturnDateText: Coalesce(r.'Return Date', ""),
                        Reason: Coalesce(r.Reason, ""), SubmittedBy: Coalesce(r.'Submitted By', ""), DateNotified: Coalesce(r.'Date Notified', "")
                    }
                )
            ),
            ClearCollect(colAbsNrCampuses, ForAll(Campuses As c, {CampusId: c.Campus, CampusName: c.Name, CampusCode: Coalesce(c.Code, "")})),
            ClearCollect(colAbsNrStuRaw, ForAll(Students As s, {StudentId: s.Student, DisplayName: Coalesce(s.'Display Name', "Unnamed student"), StudentKey: Coalesce(s.'External Client ID', ""), StatusText: Text(s.'Status (aaca_status)')})),
            ClearCollect(colAbsNrEnr, ForAll(Enrollments As e, {StudentId: e.Student.Student, CampusCode: e.Campus.Code, StartDate: e.'Start Date', EndDate: e.'End Date'}))
        ); true,
        Set(varAbsNrLoadError, FirstError.Message)
    );
    ClearCollect(
        colAbsNrStudents,
        ForAll(
            colAbsNrStuRaw As s,
            With(
                {
                    cur: First(Sort(Filter(colAbsNrEnr, StudentId = s.StudentId && StartDate <= Today() && (IsBlank(EndDate) || EndDate >= Today())), StartDate, SortOrder.Descending)),
                    lst: First(Sort(Filter(colAbsNrEnr, StudentId = s.StudentId), StartDate, SortOrder.Descending))
                },
                With(
                    {code: Coalesce(If(IsBlank(cur), lst.CampusCode, cur.CampusCode), "")},
                    {StudentId: s.StudentId, DisplayName: s.DisplayName, StudentKey: s.StudentKey, StatusText: s.StatusText, CampusCode: code, Label: s.DisplayName & " · " & If(code = "", "—", code) & " · " & If(s.StudentKey = "", "no Student Key", s.StudentKey) & " · " & s.StatusText}
                )
            )
        )
    )
);
Set(varAbsNrLoaded, true);
Set(varAbsNrLoading, false)
```

SharePoint column names are display names ('Student First Name', 'Student Last Name', 'School Site',
'Absence Date', 'Return Date', 'Submitted By', 'Date Notified'). If a name is rejected, use the internal name
from the schema (StudentFirstName, StudentLastName, SchoolSite, AbsenceDate, ReturnDate, ParentName,
DateNotified) for that field only. Never read or write the finance columns.

## Properties to Update

- `AbsencesScreen.OnVisible`: prepend `Set(varAbsNrSaving, false);` and append `; Select(btnAbsNrEngine)`.
- No other existing property changes. The moved classify controls keep every property.

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| ----------- | --------------- | --------------- | ------------------------- |
| SURF-ABS-VIEWBAR | conAbsViewBar | `=CanClassify` | Office/Admin / other roles |
| SURF-ABS-CLASSIFY | conAbsClassifyView | `=varAbsView = "classify"` | Classify view / Parent reports view |
| SURF-ABS-NR | conAbsNrView | `=CanClassify && varAbsView = "nr"` | Parent reports view / otherwise |
| SURF-NR-RECEIPT | conAbsNrReceipt | `=varAbsNrReceipt.Kind <> ""` | After a Resolve attempt until Dismiss / initially |
| SURF-NR-LIST | conAbsNrListPanel | `=!(conAbsRoot.Width < 1024 && !IsBlank(varAbsNrSelId))` | Always except narrow + selected |
| SURF-NR-DETAIL | conAbsNrDetail | `=conAbsRoot.Width >= 1024 \|\| !IsBlank(varAbsNrSelId)` | Wide, or narrow + selected / narrow + none |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| ------ | ------------- | --------------------- | -------------------- | ---------------------------- | ------------------ | ----------------- | --------------------- |
| A-SWITCH-ABS-VIEW | CanClassify | btnAbsViewClassify / btnAbsViewNr `.OnSelect` | varAbsView | "classify" ⇄ "nr"; the first switch to nr loads the queue | N/A | N/A | View containers' Visible; current button Primary |
| A-LOAD-NR | CanClassify | OnVisible, btnAbsNrReload, btnAbsViewNr → `btnAbsNrEngine.OnSelect` | SP item ID | colAbsNr = Needs Review items, Created desc; students all statuses | N/A | N/A | galAbsNrList, lblAbsNrCount, toggle N |
| A-SELECT-NR | Row exists | `btnAbsNrRowReview.OnSelect` (below); `btnAbsNrCancel.OnSelect` clears | `ThisItem.ID` → varAbsNrSelId | Selection set, pick reset, calendar loaded for the span, varAbsNrCalFor = ID | N/A | N/A | lblAbsNrFacts, lblAbsNrDays; row fill |
| A-PICK-STUDENT | Selected | `cboAbsNrStudent.OnChange` | StudentId → varAbsNrPickId | varAbsNrPickId = picked ID or Blank | N/A | N/A | lblAbsNrCheck; btnAbsNrResolve enabled |
| A-SEARCH-ALL | Selected | `chkAbsNrAll.OnCheck/OnUncheck` | varAbsNrAllCampuses | All campuses on/off; unchecking clears the pick | N/A | N/A | cboAbsNrStudent.Items; lblAbsNrPickHint |
| A-RESOLVE | Resolve gate true | `btnAbsNrResolve.OnSelect` (below) | `qid = varAbsNrSelId`; live item by ID; directory by Student_ID | Guards → one 3-column Patch → audit → receipt → RemoveIf by ID → clear. Failure: Failed receipt, selection kept | Matched_Student, Student_ID, Match_Status | ID, Title, Student_ID, Matched_Student Value + Id, Match_Status, picked student, audit | lblAbsNrReceiptTitle / lblAbsNrReceiptBody bound to `w`; queue without qid; toggle N |

`btnAbsNrRowReview.OnSelect` (`|-` block):

```
=Set(varAbsNrSelId, ThisItem.ID);
Set(varAbsNrPickId, Blank());
Set(varAbsNrAllCampuses, false);
Reset(cboAbsNrStudent);
Reset(chkAbsNrAll);
Set(varAbsNrCalFor, Blank());
With(
    {d0: IfError(DateValue(ThisItem.AbsenceDateText, "en-US"), Blank()), r0: IfError(DateValue(ThisItem.ReturnDateText, "en-US"), Blank())},
    With(
        {dEnd: If(IsBlank(r0) || r0 <= d0, d0, DateAdd(r0, -1, TimeUnit.Days))},
        If(
            IsBlank(d0) || DateDiff(d0, dEnd, TimeUnit.Days) > 180,
            Clear(colAbsNrTerms); Clear(colAbsNrExc),
            IfError(
                Concurrent(
                    ClearCollect(colAbsNrTerms, ForAll(Filter(Terms, 'Start Date' <= dEnd && 'End Date' >= d0) As t, {TStart: t.'Start Date', TEnd: t.'End Date', CampusId: t.Campus.Campus})),
                    ClearCollect(colAbsNrExc, ForAll(Filter('Calendar Exceptions', Date >= d0 && Date <= dEnd) As x, {XDate: x.Date, CampusId: x.Campus.Campus, IsClosed: x.Type = 'Type (Calendar Exceptions)'.Closed || x.Type = 'Type (Calendar Exceptions)'.'Work Only', IsMakeup: x.Type = 'Type (Calendar Exceptions)'.'Make-up School Day'}))
                ); true,
                Set(varAbsNrLoadError, "Calendar: " & FirstError.Message)
            )
        )
    )
);
Set(varAbsNrCalFor, ThisItem.ID)
```

`btnAbsNrResolve.OnSelect` (`|-` block):

```
=If(
    !CanClassify || varAbsNrSaving || IsBlank(varAbsNrSelId) || IsBlank(varAbsNrPickId) || CountRows(cboAbsNrStudent.SelectedItems) <> 1,
    Set(varAbsNrReceipt, {Kind: "Blocked", Title: "Not saved · choose a parent report and a student first", Body: "", ItemId: Coalesce(varAbsNrSelId, 0)}),
    Set(varAbsNrSaving, true);
    Set(varAbsNrErr, "");
    With(
        {qid: varAbsNrSelId, it: LookUp(colAbsNr, ID = varAbsNrSelId), stu: LookUp(colAbsNrStudents, StudentId = varAbsNrPickId)},
        With(
            {key: Coalesce(stu.StudentKey, ""), live: LookUp('Student Absence Log', ID = qid)},
            With(
                {dir: If(key = "", Blank(), LookUp('Student Directory', Student_ID = key))},
                If(
                    IsBlank(stu) || key = "",
                    Set(varAbsNrReceipt, {Kind: "Blocked", Title: "Not saved · the picked student has no Student Key", Body: "Add the Student Key on the Students screen, use Reload here, then pick the student again. Report #" & qid & " was not changed.", ItemId: qid}),
                    IsBlank(live),
                    Set(varAbsNrReceipt, {Kind: "Failed", Title: "Not saved · report #" & qid & " could not be read", Body: "SharePoint did not return the item (it may have been deleted). Nothing was changed. Use Reload.", ItemId: qid}),
                    live.Match_Status.Value <> "Needs Review",
                    Set(varAbsNrReceipt, {Kind: "Blocked", Title: "Not saved · report #" & qid & " is now " & Coalesce(live.Match_Status.Value, "blank"), Body: "Someone else or the matching flow already handled this report, so nothing was written. Use Reload to refresh the queue.", ItemId: qid}),
                    IsBlank(dir),
                    Set(varAbsNrReceipt, {Kind: "Blocked", Title: "Not saved · no Student Directory item for " & key, Body: "The Student Directory list has no item with Student_ID " & key & ", so report #" & qid & " was not changed. Ask Finance to add " & stu.DisplayName & " to the Student Directory, then try again.", ItemId: qid}),
                    With(
                        {w: IfError(Patch('Student Absence Log', live, {Matched_Student: {Id: dir.ID, Value: dir.Match_Name}, Student_ID: dir.Student_ID, Match_Status: {Value: "Manually Resolved"}}), Set(varAbsNrErr, FirstError.Message); Blank())},
                        If(
                            IsBlank(w),
                            Set(varAbsNrReceipt, {Kind: "Failed", Title: "Not saved · report #" & qid & " could not be updated", Body: "Error: " & Coalesce(varAbsNrErr, "unknown error") & Char(10) & "Nothing was changed. The report and " & stu.DisplayName & " are still selected; press Resolve Match to retry.", ItemId: qid}),
                            With(
                                {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Parent report #" & w.ID & " matched to " & w.Student_ID, 100), Action: 'Action (Audit Events)'.Update, Entity: "sharepoint:Student Absence Log", 'Entity ID': Text(w.ID), Before: JSON({Matched_Student: Coalesce(live.Matched_Student.Value, ""), Student_ID: Coalesce(live.Student_ID, ""), Match_Status: live.Match_Status.Value}), After: JSON({Matched_Student: {Id: w.Matched_Student.Id, Value: w.Matched_Student.Value}, Student_ID: w.Student_ID, Match_Status: w.Match_Status.Value}), Reason: Left("Resolved in Absences, Parent reports: " & stu.DisplayName & " (" & key & ")", 500)}), Blank())},
                                Set(
                                    varAbsNrReceipt,
                                    {
                                        Kind: "Resolved",
                                        Title: "Parent report #" & w.ID & " matched · " & w.Student_ID & " · " & stu.DisplayName,
                                        Body: "Report: #" & w.ID & If(Coalesce(w.Title, "") = "", "", " · " & w.Title) & Char(10) &
                                            "Submitted as: " & it.FirstName & " " & it.LastName & " · " & it.SchoolSite & Char(10) &
                                            "Student picked: " & stu.DisplayName & " · " & stu.StatusText & Char(10) &
                                            "Student_ID: " & w.Student_ID & Char(10) &
                                            "Matched_Student: " & w.Matched_Student.Value & " (Student Directory item #" & w.Matched_Student.Id & ")" & Char(10) &
                                            "Match_Status: " & w.Match_Status.Value & Char(10) &
                                            "Other columns: not written (report and billing fields unchanged)" & Char(10) &
                                            "Audit event: " & If(IsBlank(au), "NOT written", "Update written"),
                                        ItemId: w.ID
                                    }
                                );
                                RemoveIf(colAbsNr, ID = qid);
                                Set(varAbsNrSelId, Blank());
                                Set(varAbsNrPickId, Blank());
                                Set(varAbsNrAllCampuses, false);
                                Reset(cboAbsNrStudent);
                                Reset(chkAbsNrAll)
                            )
                        )
                    )
                )
            )
        )
    );
    Set(varAbsNrSaving, false)
)
```

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| -------------- | ------------------------ | ------------------- |
| cboAbsNrStudent | `lblAbsNrPick.Text: ="Student *"` | conAbsNrPickField |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization | Destination focus |
| ------ | --------------- | ----------------------------- | ---------------------------------- | -------------------- | --------------- | ----------------- |
| A-RESOLVE | varAbsNrReceipt from `w` (ItemId w.ID) → lblAbsNrReceiptTitle / lblAbsNrReceiptBody | 'Student Absence Log' ID = qid; re-query in btnAbsNrEngine excludes it | galAbsNrList (colAbsNr), btnAbsViewNr.Text N | qid → live → w.ID → ItemId → RemoveIf ID = qid | Success-only `RemoveIf(colAbsNr, ID = qid)` | N/A (item leaves the queue) |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| ------ | ----- | -------------- | ---------------------------- | ------------------------------- | --------------------- | ------------------- |
| A-RESOLVE | Matched_Student | Changed | dir (Student Directory by key) | `{Id: dir.ID, Value: dir.Match_Name}` | Body "Matched_Student: …(item #Id)" | SP item; audit After |
| A-RESOLVE | Student_ID | Changed | dir.Student_ID | `Student_ID: dir.Student_ID` | Body "Student_ID: " & w.Student_ID | SP item; audit After |
| A-RESOLVE | Match_Status | Changed | live "Needs Review" | `{Value: "Manually Resolved"}` | Body "Match_Status: " & w.Match_Status.Value | Queue re-query |
| A-RESOLVE | All other columns incl. finance columns | Preserved | live item | Omitted from the Patch change record | Body "Other columns: not written" | SP item view |

## Functional Test Scenarios

The plan index Functional Test Matrix owns these rows. They are copied here in full meaning:

- S-TOGGLE: Office user, 3 Needs Review items. The label shows "(3)". Pressing each button swaps
  conAbsNrView / conAbsClassifyView. The classify view is unchanged. A teacher sees no bar.
- S-NR-LIST: #515 and #516 (Needs Review) plus #517 (Exact). The list shows #516 then #515; #517 is absent.
  Each row shows name, #ID · Title · site · dates, and reason · submitted by · notified.
- S-NR-EMPTY: No items. lblAbsNrCount shows the zero-state text, the gallery is hidden and the label reads
  "(0)". On a load error, lblAbsNrCount shows red error text.
- S-NR-DAYS: CW report, Fri 9/18/2026 → return 09/22/2026, all-campus Closed exception on 9/21, CW term in
  September. Result "1 school day · Fri 9/18/2026 – Mon 9/21/2026". Without the exception: 2. With a Make-up
  School Day on Sat 9/19: +1. With a blank return or return ≤ absence date: 1 day.
- S-NR-BADDATE: Absence Date "13/45/2026". Result: red "Days of absence: check dates — …" with the raw text.
- S-NR-CANCEL: Selected + picked, then Cancel. Selection and pick are Blank and nothing is written.
- S-PICK-CAMPUS: SchoolSite "Chatsworth" → CW students of every status only. The hint names CW and the
  count. An unmapped site shows all campuses with a note.
- S-PICK-ALL: Tick → all students. Untick → CW only and the pick is cleared.
- S-PICK-RESET: A pick on #515, then Review #516 → the picker is empty and Resolve is disabled.
- S-RESOLVE-OK: #515 + directory #88 CW-1083 → one Patch writes the 3 columns and an audit row is created.
  The receipt shows Title and the 8 body lines. #515 is removed from the queue, N drops by 1, and the
  selection is cleared.
- S-RESOLVE-FAIL: The Patch errors (for example, read-only permission). The receipt is Failed with the error
  in Body. Selection and pick are kept, the queue is unchanged and Resolve is re-enabled.
- S-RESOLVE-ALREADY: The live status is "Exact". The receipt is Blocked "report #515 is now Exact"; nothing
  is written and the selection is kept.
- S-RESOLVE-NO-DIR: Key OX-1130 has no directory item. The receipt is Blocked; nothing is written and the
  selection is kept. A student with no key → Resolve is disabled and lblAbsNrCheck explains.
- S-REGRESSION: The classify filters, ticks, bulk actions, row Excused…/Unexcused and the decide panel work
  exactly as in build 3.

## Relevant Data Source Schemas

- 'Student Absence Log' (SharePoint): ID Number; Title Text (may be blank); Created DateTime.
  Match_Status is a Choice with `.Value`: "Exact", "Approved Variation", "Needs Review" or "Manually
  Resolved". Matched_Student is a Lookup to the Student Directory, written as `{Id, Value}`. Student_ID Text.
  The remaining columns are Text: 'Student First Name', 'Student Last Name', 'School Site' (= Campuses.Name),
  'Absence Date' and 'Return Date' (M/D/YYYY, leading zeros optional), Reason, 'Submitted By', 'Date Notified'.
  **Never write** Absence_x0020_Month, Billable_x0020_Days, Billing_x0020_Status,
  First_x0020_Eligible_x0020_Date or Total_x0020_Absence_x0020_Days.
- 'Student Directory' (SharePoint): ID; Student_ID (e.g. "CW-1001"); Match_Name (lower-case "first last"); the
  other columns are not used.
- Dataverse:
  - Students: Student (GUID), 'Display Name', 'External Client ID', 'Status (aaca_status)'.
  - Enrollments: Student, Campus (.Code), 'Start Date', 'End Date'.
  - Campuses: Campus, Name, Code.
  - Terms: 'Start Date', 'End Date', Campus (blank = all).
  - 'Calendar Exceptions': Date, Campus (blank = all), Type ('Type (Calendar Exceptions)'.Closed /
    .'Work Only' / .'Make-up School Day').
  - 'Audit Events': Summary, Action ('Action (Audit Events)'.Update), Entity, 'Entity ID', Before, After,
    Reason.
- Delegation: the SP queue filter is verified delegable. The Terms and Calendar Exceptions filters use With
  scalars only. ForAll over Students (≈126 rows) and Enrollments (≈216) is below the row limit; this
  matches the Students screen.

## Required Variants

- GroupContainer → `Variant: AutoLayout` (every new container)
- Gallery → `Variant: Vertical` (galAbsNrList)

## Changed or Added Control Definitions

Property lists come from the discovery packet `describe_control` results. Use only these names.

- **GroupContainer** (`Control: GroupContainer`). Inputs:
  - BorderColor, BorderStyle, BorderThickness, ContentLanguage, DropShadow, EnableChildFocus, Fill, Height
  - RadiusBottomLeft, RadiusBottomRight, RadiusTopLeft, RadiusTopRight, Visible, Width, X, Y
  - LayoutAlignItems, LayoutDirection, LayoutGap, LayoutJustifyContent, LayoutOverflowX, LayoutOverflowY,
    LayoutWrap
  - PaddingBottom, PaddingLeft, PaddingRight, PaddingTop
  - As an AutoLayout child: AlignInContainer, FillPortions, LayoutMaxHeight, LayoutMaxWidth, LayoutMinHeight,
    LayoutMinWidth
  - Enum literals: `=DropShadow.None`; `=LayoutDirection.Vertical` / `.Horizontal`;
    `=LayoutAlignItems.Stretch` / `.Center` / `.Start`; `=AlignInContainer.Stretch` / `.Center` / `.Start`
- **ModernText** (`Control: ModernText`). Inputs:
  - AccessibleLabel, Align, AutoHeight, BorderColor, BorderStyle, BorderThickness, Color, ContentLanguage,
    DisplayMode, Fill, Font, FontWeight, Height, Italic, OnSelect
  - PaddingBottom, PaddingLeft, PaddingRight, PaddingTop, Radius*, Size, Strikethrough, Text, Underline,
    VerticalAlign, Visible, Width, Wrap, X, Y
  - AutoLayout child properties
  - Enum literals: `=FontWeight.Bold` / `.Semibold`; `=VerticalAlign.Top`
- **ModernButton** (`Control: ModernButton`, no Fill). Inputs:
  - AccessibleLabel, Align, Appearance, BasePaletteColor, BorderColor, BorderStyle, BorderThickness, Color,
    ContentLanguage, DisplayMode, Font, FontWeight, Height
  - Icon, IconRotation, IconStyle, Italic, Layout, OnSelect, Padding*, Radius*, Size, Strikethrough, Text,
    Tooltip, Underline, VerticalAlign, Visible, Width, X, Y
  - AutoLayout child properties
  - Enum literals: `=ButtonAppearance.Primary` / `=ButtonAppearance.Secondary`; `=ButtonLayout.TextOnly`;
    `=DisplayMode.Edit` / `=DisplayMode.Disabled`
- **ModernCombobox** (`Control: ModernCombobox`, new to the app). Inputs:
  - AccessibleLabel, AllowExternalSelectedItems, Appearance, BasePaletteColor, BorderColor, BorderStyle,
    BorderThickness, Color, ContentLanguage, DefaultSelectedItems, DelayOutput, DisplayMode, Fill, Font,
    FontWeight, Height
  - InputTextPlaceholder, IsSearchable, Italic, ItemDisplayText, Items, MultiValueDelimiter, OnChange,
    Padding*, Radius*, Required, SelectMultiple, Size, Strikethrough, Underline, ValidationState, Visible,
    Width, X, Y
  - AutoLayout child properties
  - Outputs: SearchText, Selected, SelectedItems
  - Enum literals: `Appearance: =Appearance.Outline`; `DisplayMode.Edit` / `.Disabled`
  - There is no AllowEmptySelection; empty = `DefaultSelectedItems: =[]` + `Reset`
- **ModernCheckbox** (`Control: ModernCheckbox`). Inputs:
  - AccessibleLabel, BasePaletteColor, CheckboxSize, Color, ContentLanguage, Default, DisplayMode, Font,
    FontWeight, Height, Italic, Label
  - OnCheck, OnUncheck, Size, Strikethrough, Tooltip, Underline, Visible, Width, X, Y
  - AutoLayout child properties
  - Output: Checked
- **ModernSpinner** (`Control: ModernSpinner`). Inputs:
  - AccessibleLabel, Appearance, BasePaletteColor, Color, ContentLanguage, DisplayMode, Font, FontWeight,
    Height, Italic, Label, LabelPosition
  - LineHeight, Padding*, Size, SpinnerColor, Strikethrough, Tooltip, TrackColor, Underline, Visible, Width,
    X, Y
  - AutoLayout child properties
- **Gallery** (`Control: Gallery`, `Variant: Vertical`). Inputs:
  - AccessibleLabel, BorderColor, BorderStyle, BorderThickness, ContentLanguage, Default, DelayItemLoading,
    DisplayMode, Fill, FocusedBorderColor, FocusedBorderThickness, Height, Items
  - LoadingSpinner, LoadingSpinnerColor, NavigationStep, Selectable, ShowNavigation, ShowScrollbar, TabIndex,
    TemplatePadding, TemplateSize, Transition, Visible, Width, WrapCount, X, Y
  - AutoLayout child properties
- **Classic/Button** (`Control: Classic/Button`, engine only). Inputs used: AutoDisableOnSelect, OnSelect,
  Text, Visible, AlignInContainer, LayoutMinHeight, LayoutMinWidth. It has no AccessibleLabel.
