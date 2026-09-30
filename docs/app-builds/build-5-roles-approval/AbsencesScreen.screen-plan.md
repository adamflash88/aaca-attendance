# Screen Plan: Absences (AbsencesScreen)

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml`
- YAML key: AbsencesScreen
- Control name prefix: Abs (existing); ALL new controls in this build use `AbsAp`

## Current State

`conAbsRoot` (sole top-level scroll root) children in order: `conAbsHeader` (nav), `conAbsViewBar`
(`btnAbsViewClassify`, `btnAbsViewNr`), `conAbsDenied` (!CanClassify), `conAbsClassifyView` (controls ending in `V`,
incl. `dpAbsFromV`, `btnAbsClearFiltersV`), `conAbsNrView` (Needs Review: `spnAbsNrBusy`, `conAbsNrReceipt`,
`conAbsNrBody` > `conAbsNrListPanel` / `conAbsNrDetail`), then hidden engines `btnAbsLoadEngine`,
`btnAbsClassifyEngine`, `btnAbsNrEngine`. `varAbsView` is "classify" or "nr". `colAbsReasons`
(`{ReasonId, ReasonName, SortOrder}`) is loaded in OnVisible.

**HARD LESSON: never move an existing control into another container** (Studio renders it black). Edit existing
properties in place; add the new view as NEW controls. Do not touch the Needs Review or Classify logic except the
two items listed.

## Changes

1. **OnVisible** (`AbsencesScreen.OnVisible`): insert `Set(varAbsApSaving, false);` as the first line, and change the
   final `Select(btnAbsNrEngine)` to `Select(btnAbsNrEngine);` followed by a new last line `Select(btnAbsApEngine)`.
2. **Classify default From** — `btnAbsClearFiltersV.OnSelect`: replace
   `Set(varAbsFrom, Coalesce(CurrentSchoolYear.'Start Date', Date(Year(Today()) - If(Month(Today()) < 7, 1, 0), 7, 1)));`
   with `Set(varAbsFrom, ParentReportCutover);` (App.OnStart gets the same change before builders run).
   `dpAbsFromV.DefaultDate` stays `=varAbsFrom`.
3. **View bar — third toggle, 1024 breakpoint** (properties in place + one NEW child appended):
   - `conAbsViewBar.Height: =If(conAbsRoot.Width < 1024, 148, 44)`;
     `LayoutAlignItems: =If(conAbsRoot.Width < 1024, LayoutAlignItems.Stretch, LayoutAlignItems.Center)`;
     `LayoutDirection: =If(conAbsRoot.Width < 1024, LayoutDirection.Vertical, LayoutDirection.Horizontal)`
   - `btnAbsViewClassify` and `btnAbsViewNr`: in `AlignInContainer` and `Width` change the `< 640` test to `< 1024`
     (widths stay 170 / 320 on desktop).
   - NEW last child `btnAbsApViewReady` (ModernButton): AccessibleLabel `=Self.Text & If(varAbsView = "ready", " (current view)", "")`;
     AlignInContainer `=If(conAbsRoot.Width < 1024, AlignInContainer.Stretch, AlignInContainer.Center)`;
     Appearance `=If(varAbsView = "ready", ButtonAppearance.Primary, ButtonAppearance.Secondary)`; BasePaletteColor `=ColorTeal`;
     Color `=If(varAbsView = "ready", ColorWhite, ColorInk)`; Height 44; Layout `=ButtonLayout.TextOnly`; LayoutMinHeight 0; LayoutMinWidth 0; Size 14;
     OnSelect `=Set(varAbsView, "ready"); If(!varAbsApLoaded && !varAbsApLoading, Select(btnAbsApEngine))`;
     Text `="Parent reports – Ready to approve (" & If(varAbsApLoaded, Text(CountRows(colAbsAp)), "…") & ")"`;
     Width `=If(conAbsRoot.Width < 1024, Parent.Width - 32, 310)`.
4. **NEW view `conAbsApView`** inserted in `conAbsRoot.Children` immediately AFTER `conAbsNrView` and BEFORE
   `btnAbsLoadEngine`. Tree, properties and formulas in "Controls to Add".
5. **NEW engines** `btnAbsApEngine` and `btnAbsApPlanEngine` appended at the END of `conAbsRoot.Children` (after
   `btnAbsNrEngine`), same pattern as the other engines: `Control: Classic/Button`, `AlignInContainer: =AlignInContainer.Stretch`,
   `AutoDisableOnSelect: =false`, `LayoutMinHeight: =0`, `LayoutMinWidth: =0`, `Visible: =false`, Text `="ap load"` / `="ap plan"`.
6. **Root containment** — `conAbsRoot`: add `LayoutMinWidth: =0` and `LayoutMinHeight: =0`.

## Layout and Visual Impact

- Breakpoint source: `conAbsRoot.Width` everywhere (phone < 640, two-panel >= 1024), exactly like `conAbsNrView`.
- View bar: desktop 16 + 170 + 8 + 320 + 8 + 310 + 16 = 848 ≤ 1024; below 1024 stacked 3×44 + 2×8 = 148.
- List row (TemplateSize `If(conAbsRoot.Width < 640, 200, 150)`): desktop 8+44+4+36+4+36+8 = 140; phone 8+44+4+54+4+54+8 = 176.
- Detail actions: 120 + 8 + 110 + 8 + 96 = 342 ≤ 358 (390 phone minus 16+16 panel padding). Dismiss actions 150 + 8 + 120 = 278.
- Detail panel Height: `16 + 28 + 8 + (60 | facts + 8 + daysHead [+ 8 + days] + 8 + 58 + 8 + 58 + 8 + 94 + 8 + check + 8 + 44 [+ 8 + 170]) + 16`.
- Receipt Height: `8 + top(44|84) [+ 4 + body] [+ 4 + days] [+ 4 + 44] + 8`; body 150 desktop / 180 tablet / 240 phone
  holds 7 labelled lines incl. a 200-char note wrapping to 4 lines at 342 px.
- Visual contract: panels white/rule/radius 6/padding 16 as in Needs Review; receipt fill by Kind; Approve teal primary,
  Confirm dismiss red primary, others Secondary ink. Texts on ColorWarnBg/ColorInfoBg/ColorErrorBg use `Color: =ColorInk`.
- Record presentation: row identity = `lblAbsApRowName` (app student full Display Name + Student_ID); Approve and Dismiss
  sit together in the same detail surface (`conAbsApActions`) at every width.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --- | --- | --- | --- | --- | --- | --- |
| ap-row-student | galAbsApList row | app student + Student_ID | StudentName, StudentKey | lblAbsApRowName | see Controls to Add | row top, FillPortions 1, Height 42, wraps 2 lines |
| ap-row-parent | galAbsApList row | report #, parent-typed names, campus, dates | ID, FirstName, LastName, CampusName/SchoolSite, AbsenceDateText, ReturnDateText | lblAbsApRowMeta | see below | second line, always visible |
| ap-row-reason | galAbsApList row | reason, submitted by, notified | Reason, SubmittedBy, DateNotified | lblAbsApRowSub | see below | third line, muted |
| ap-detail-facts | conAbsApDetail | full facts | colAbsAp | lblAbsApFacts | see below | visible when selected |
| ap-detail-days | galAbsApDays | day + planned outcome + teacher | colAbsApPlan | lblAbsApDayLine | see below | visible when plan loaded |

## Controls to Add

All GroupContainers: `Variant: AutoLayout`, `DropShadow: =DropShadow.None`, `LayoutMinWidth: =0`,
`LayoutMinHeight: =0`, `FillPortions` explicit, Radius 0 unless noted. All ModernText: Padding* = 0,
`AlignInContainer: =AlignInContainer.Stretch` (or Center where stated), `LayoutMinWidth: =0`, `LayoutMinHeight: =0`,
AccessibleLabel `=Self.Text` unless stated. Every formula containing `: ` or ` #` MUST be a `|-` block.

```
conAbsApView                      vertical, FillPortions 0, gap 8, LayoutAlignItems Stretch
  Visible: =CanClassify && varAbsView = "ready"
  Height:  =If(spnAbsApBusy.Visible, 48 + 8, 0) + If(conAbsApReceipt.Visible, conAbsApReceipt.Height + 8, 0) + conAbsApBody.Height
  - spnAbsApBusy                  ModernSpinner; AccessibleLabel =Self.Label; Color =ColorInk; SpinnerColor =ColorTeal;
                                  Height 48; FillPortions 0; Label =If(varAbsApSaving, "Saving decision…", "Loading parent reports…");
                                  Visible =varAbsApLoading || varAbsApSaving
  - conAbsApReceipt               vertical, gap 4, padding 8/12/12/8, radius 6, BorderColor ColorRule, BorderThickness 1
      Fill: =Switch(varAbsApReceipt.Kind, "Failed", ColorErrorBg, "Blocked", ColorErrorBg, "Dismissed", ColorWarnBg, ColorInfoBg)
      Visible: =varAbsApReceipt.Kind <> ""
      Height: =8 + conAbsApReceiptTop.Height + If(lblAbsApReceiptBody.Visible, 4 + lblAbsApReceiptBody.Height, 0) + If(galAbsApRcptDays.Visible, 4 + galAbsApRcptDays.Height, 0) + If(btnAbsApShowGrid.Visible, 4 + 44, 0) + 8
      - conAbsApReceiptTop        horizontal, gap 8, LayoutAlignItems Center, Height =If(conAbsRoot.Width < 640, 84, 44)
          - lblAbsApReceiptTitle  Text =varAbsApReceipt.Title; FontWeight Semibold; Size 13; Color ColorInk; FillPortions 1;
                                  Height =If(conAbsRoot.Width < 640, 84, 44); VerticalAlign Top; AlignInContainer Center
          - btnAbsApReceiptDismiss Secondary, Width 88, Text "Dismiss", AccessibleLabel "Dismiss approval result"
              OnSelect: =Set(varAbsApReceipt, {Kind: "", Title: "", Body: "", ItemId: 0}); Clear(colAbsApLog); Set(varAbsApGridLink, {StudentId: ZeroGuid, TeacherId: ZeroGuid, CampusId: ZeroGuid, FirstDay: Today()})   (|- block)
      - lblAbsApReceiptBody       Text =varAbsApReceipt.Body; Size 12; Color ColorInk; VerticalAlign Top;
                                  Height =If(conAbsRoot.Width < 640, 240, conAbsRoot.Width < 1024, 180, 150); Visible =varAbsApReceipt.Body <> ""
      - galAbsApRcptDays          Gallery Vertical; AccessibleLabel "Day-by-day result"; FillPortions 0; TemplatePadding 0; TabIndex 0; Selectable false
          Items: =SortByColumns(colAbsApLog, "DayDate", SortOrder.Ascending)
          TemplateSize: =If(conAbsRoot.Width < 640, 52, 36)
          Height: =Min(If(conAbsRoot.Width < 640, 260, 216), If(conAbsRoot.Width < 640, 52, 36) * CountRows(colAbsApLog))
          Visible: =CountRows(colAbsApLog) > 0
          - conAbsApRcptRow       shell vertical; Width =Parent.TemplateWidth - 16; Height =Parent.TemplateHeight; PaddingTop 2; PaddingBottom 2
              - lblAbsApRcptLine  Size 12; FillPortions 1; VerticalAlign Top;
                                  Color =If(ThisItem.Outcome = "failed" || ThisItem.Outcome = "skip-present", ColorUnexcused, StartsWith(ThisItem.Outcome, "skip"), ColorMuted, ColorInk)
                                  Text =Text(ThisItem.DayDate, "ddd m/d/yyyy") & " · " & ThisItem.Detail   (|- block)
      - btnAbsApShowGrid          ModernButton primary teal/white, Width 140, Height 44, AlignInContainer Start, Text "Show on grid",
                                  AccessibleLabel "Show the first changed day on the Attendance grid"
          Visible: =varAbsApReceipt.Kind = "Approved" && varAbsApGridLink.TeacherId <> ZeroGuid
          OnSelect: see Formula F5
  - conAbsApBody                  same as conAbsNrBody:
      Height: =If(conAbsRoot.Width >= 1024, Max(conAbsApListPanel.Height, conAbsApDetail.Height), If(conAbsApListPanel.Visible, conAbsApListPanel.Height, 0) + If(conAbsApListPanel.Visible && conAbsApDetail.Visible, 8, 0) + If(conAbsApDetail.Visible, conAbsApDetail.Height, 0))
      LayoutAlignItems: =If(conAbsRoot.Width >= 1024, LayoutAlignItems.Start, LayoutAlignItems.Stretch)
      LayoutDirection:  =If(conAbsRoot.Width >= 1024, LayoutDirection.Horizontal, LayoutDirection.Vertical); gap 8; FillPortions 0
      - conAbsApListPanel         vertical panel (white, rule border, radius 6, padding 16, gap 8)
          AlignInContainer: =If(conAbsRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)
          FillPortions: =If(conAbsRoot.Width >= 1024, 1, 0)
          Height: =16 + 44 + 8 + If(conAbsRoot.Width < 640, 54, 36) + If(CountRows(colAbsAp) > 0, 8 + 520, 0) + 16
          Visible: =!(conAbsRoot.Width < 1024 && !IsBlank(varAbsApSelId))
          - conAbsApListHead      horizontal, Height 44, gap 8, align Center
              - lblAbsApListTitle Text ="Ready to approve (" & CountRows(colAbsAp) & ")"; Size 20; Bold; Height 30; FillPortions 1; LayoutMinWidth 80; Wrap false; AlignInContainer Center
              - btnAbsApReload    Secondary, Width 80, Text "Reload", AccessibleLabel "Reload ready parent reports",
                                  DisplayMode =If(varAbsApLoading || varAbsApSaving, DisplayMode.Disabled, DisplayMode.Edit), OnSelect =Select(btnAbsApEngine)
          - lblAbsApCount         Size 13; Semibold; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 54, 36)
              Color: =If(varAbsApLoadError <> "", ColorUnexcused, ColorInk)
              Text (|-): =If(varAbsApLoadError <> "", "Could not load parent reports — " & varAbsApLoadError & ". Use Reload to try again.", varAbsApLoading, "Loading parent reports…", CountRows(colAbsAp) = 0, "No parent reports are ready to approve. Matched website reports dated " & Text(ParentReportCutover, "m/d/yyyy") & " or later appear here after Reload.", CountRows(colAbsAp) & If(CountRows(colAbsAp) = 1, " report is", " reports are") & " ready · oldest absence first · " & If(StudentCampusLock = ZeroGuid, "all campuses", "your campus") & If(CountRows(colAbsApR1) >= 2000 || CountRows(colAbsApR2) >= 2000 || CountRows(colAbsApR3) >= 2000, " · list may be incomplete (2,000-item limit)", ""))
          - galAbsApList          Gallery Vertical; AccessibleLabel "Parent reports ready to approve"; FillPortions 0; Height 520;
                                  TemplatePadding 0; TabIndex 0; Selectable false; Visible =CountRows(colAbsAp) > 0
              Items: =SortByColumns(colAbsAp, "AbsDate", SortOrder.Ascending, "ID", SortOrder.Ascending)
              TemplateSize: =If(conAbsRoot.Width < 640, 200, 150)
              - conAbsApRowShell  vertical, gap 4, padding 8, BorderColor ColorRule, BorderThickness 1, Width =Parent.TemplateWidth - 16, Height =Parent.TemplateHeight
                  Fill: =If(ThisItem.ID = varAbsApSelId, ColorInfoBg, ColorWhite)
                  - conAbsApRowTop       horizontal, Height 44, gap 8, align Center, FillPortions 0
                      - lblAbsApRowName  Size 14; Semibold; Color ColorInk; FillPortions 1; Height 42; VerticalAlign Top; AlignInContainer Center
                          Text: =If(ThisItem.StudentId = ZeroGuid, "No app student · Student_ID " & ThisItem.StudentKey, ThisItem.StudentName & " · " & ThisItem.StudentKey)
                      - btnAbsApRowOpen  Secondary, Width 90, Text "Open"; AccessibleLabel (|-) ="Open parent report #" & ThisItem.ID
                          DisplayMode: =If(varAbsApLoading || varAbsApSaving, DisplayMode.Disabled, DisplayMode.Edit)
                          OnSelect: see Formula F2
                  - lblAbsApRowMeta      Size 12; Color ColorInk; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 54, 36)
                      Text (|-): ="#" & ThisItem.ID & " · parent typed " & ThisItem.FirstName & " " & ThisItem.LastName & " · " & If(ThisItem.CampusName = "", ThisItem.SchoolSite, ThisItem.CampusName) & " · absent " & ThisItem.AbsenceDateText & If(Trim(ThisItem.ReturnDateText) = "", "", " · back " & ThisItem.ReturnDateText) & " · " & ThisItem.MatchStatus
                  - lblAbsApRowSub       Size 12; Color ColorMuted; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 54, 36)
                      Text: ="Reason " & If(ThisItem.Reason = "", "—", If(Len(ThisItem.Reason) > 80, Left(ThisItem.Reason, 80) & "…", ThisItem.Reason)) & " · submitted by " & ThisItem.SubmittedBy & " · notified " & ThisItem.DateNotified
      - conAbsApDetail            vertical panel (white, rule, radius 6, padding 16, gap 8)
          AlignInContainer: =If(conAbsRoot.Width >= 1024, AlignInContainer.Start, AlignInContainer.Stretch)
          FillPortions: =If(conAbsRoot.Width >= 1024, 1, 0)
          Visible: =conAbsRoot.Width >= 1024 || !IsBlank(varAbsApSelId)
          Height: =16 + 28 + 8 + If(IsBlank(varAbsApSelId), 60, lblAbsApFacts.Height + 8 + lblAbsApDaysHead.Height + If(galAbsApDays.Visible, 8 + galAbsApDays.Height, 0) + 8 + 58 + 8 + 58 + 8 + 94 + 8 + lblAbsApCheck.Height + 8 + 44 + If(conAbsApDismissPanel.Visible, 8 + 170, 0)) + 16
          - lblAbsApDetailTitle   Text "Approve a parent report"; Size 18; Bold; Height 28; Wrap false
          - lblAbsApDetailEmpty   Text "Choose Open on a report to see its school days, then pick Excused or Unexcused and a reason."; Size 13; Color ColorMuted; Height 60; VerticalAlign Top; Visible =IsBlank(varAbsApSelId)
          - lblAbsApFacts         Formula F3; Size 13; Color ColorInk; VerticalAlign Top; Visible =!IsBlank(varAbsApSelId)
                                  Height: =If(conAbsRoot.Width < 640, 220, conAbsRoot.Width < 1280, 190, 150)
          - lblAbsApDaysHead      Formula F4; Size 13; Semibold; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 60, 40); Visible =!IsBlank(varAbsApSelId)
                                  Color: =If(varAbsApPlanErr <> "" || CountRows(Filter(colAbsApPlan, Outcome = "skip-present")) > 0, ColorUnexcused, ColorInk)
          - galAbsApDays          Gallery Vertical; AccessibleLabel "School days in this report"; FillPortions 0; TemplatePadding 0; TabIndex 0; Selectable false
              Items: =SortByColumns(colAbsApPlan, "DayDate", SortOrder.Ascending)
              TemplateSize: =If(conAbsRoot.Width < 640, 52, 36)
              Height: =If(conAbsRoot.Width < 640, 260, 216)
              Visible: =!IsBlank(varAbsApSelId) && varAbsApPlanFor = varAbsApSelId && CountRows(colAbsApPlan) > 0
              - conAbsApDayRow    shell vertical; Width =Parent.TemplateWidth - 16; Height =Parent.TemplateHeight; PaddingTop 2; PaddingBottom 2
                  - lblAbsApDayLine  Size 12; FillPortions 1; VerticalAlign Top
                      Color: =If(ThisItem.Outcome = "skip-present", ColorUnexcused, StartsWith(ThisItem.Outcome, "skip"), ColorMuted, ColorInk)
                      Text: =Text(ThisItem.DayDate, "ddd m/d/yyyy") & " · " & ThisItem.OutcomeText & If(ThisItem.TeacherName = "", "", " · " & ThisItem.TeacherName)
          - conAbsApClassField    vertical, gap 4, Height 58, FillPortions 0, Visible =!IsBlank(varAbsApSelId)
              - lblAbsApClass     Text "Classification *"; Size 12; Semibold; Color ColorMuted; Height 18; Wrap false; AccessibleLabel "Classification, required"
              - rdoAbsApClass     ModernRadio; AccessibleLabel "Classification"; Color ColorInk; Height 36; Items =["Excused", "Unexcused"];
                                  Layout =OptionLayout.Horizontal; Default (|-) ={Value: varAbsApClass};
                                  DisplayMode =If(varAbsApSaving, DisplayMode.Disabled, DisplayMode.Edit); OnChange =Set(varAbsApClass, Self.Selected.Value)
          - conAbsApReasonField   vertical, gap 4, Height 58, FillPortions 0, Visible =!IsBlank(varAbsApSelId)
              - lblAbsApReason    Text "Absence reason *"; (label style); AccessibleLabel "Absence reason, required"
              - ddAbsApReason     ModernDropdown; AccessibleLabel "Absence reason"; Appearance =Appearance.Outline; Color ColorInk; Height 36;
                                  Items =colAbsReasons; ItemDisplayText =ThisItem.ReasonName; Default =LookUp(colAbsReasons, ReasonId = varAbsApReasonId);
                                  DisplayMode =If(varAbsApSaving, DisplayMode.Disabled, DisplayMode.Edit); OnChange =Set(varAbsApReasonId, Self.Selected.ReasonId)
          - conAbsApNoteField     vertical, gap 4, Height 94, FillPortions 0, Visible =!IsBlank(varAbsApSelId)
              - lblAbsApNote      Text "Note for the attendance record (optional, 200 max)"; (label style)
              - txtAbsApNote      ModernTextInput; AccessibleLabel "Note"; Appearance =Appearance.Outline; Color ColorInk; Height 72; MaxLength 200;
                                  Type =TextInputType.Multiline; Placeholder "Brief reason, pre-filled from the parent's reason";
                                  Default =Left(LookUp(colAbsAp, ID = varAbsApSelId).Reason, 200); DisplayMode =If(varAbsApSaving, DisplayMode.Disabled, DisplayMode.Edit)
          - lblAbsApCheck         Formula F6; Size 13; VerticalAlign Top; Height =If(conAbsRoot.Width < 640, 54, 36); Visible =!IsBlank(varAbsApSelId)
                                  Color: =If(StartsWith(Self.Text, "Ready"), ColorExcused, ColorUnexcused)
          - conAbsApActions       horizontal, Height 44, gap 8, align Center, FillPortions 0, Visible =!IsBlank(varAbsApSelId)
              - btnAbsApApprove   primary teal/white, Width 120, Text "Approve", AccessibleLabel "Approve parent report"; DisplayMode Formula F7; OnSelect Formula F8
              - btnAbsApDismiss   Secondary, Width 110, Text "Dismiss", AccessibleLabel "Dismiss parent report";
                                  DisplayMode =If(CanClassify && !varAbsApSaving && !IsBlank(LookUp(colAbsAp, ID = varAbsApSelId)), DisplayMode.Edit, DisplayMode.Disabled)
                                  OnSelect =Set(varAbsApDismissOpen, true); Reset(txtAbsApDismissNote)
              - btnAbsApCancel    Secondary, Width 96, Text "Cancel", AccessibleLabel "Cancel and return to the list";
                                  DisplayMode =If(varAbsApSaving, DisplayMode.Disabled, DisplayMode.Edit); OnSelect Formula F10
          - conAbsApDismissPanel  vertical, gap 8, padding 12, radius 6, Fill ColorWarnBg, BorderColor ColorRule, BorderThickness 1, Height 170, FillPortions 0
              Visible: =varAbsApDismissOpen && !IsBlank(varAbsApSelId)
              - conAbsApDismissField vertical, gap 4, Height 94
                  - lblAbsApDismissNote Text "Why dismiss? (required)"; (label style, Color ColorInk)
                  - txtAbsApDismissNote ModernTextInput; AccessibleLabel "Dismiss note"; Appearance Outline; Color ColorInk; Height 72; MaxLength 1000;
                                  Type Multiline; Default =""; Placeholder "e.g. duplicate submission or wrong student"; DisplayMode =If(varAbsApSaving, DisplayMode.Disabled, DisplayMode.Edit)
              - conAbsApDismissActions horizontal, Height 44, gap 8, align Center
                  - btnAbsApDismissConfirm BasePaletteColor ColorUnexcused, Color ColorWhite, Width 150, Text "Confirm dismiss", AccessibleLabel "Confirm dismiss";
                                  DisplayMode =If(CanClassify && !varAbsApSaving && !IsBlank(LookUp(colAbsAp, ID = varAbsApSelId)) && Trim(txtAbsApDismissNote.Text) <> "", DisplayMode.Edit, DisplayMode.Disabled)
                                  OnSelect Formula F9
                  - btnAbsApDismissCancel Secondary, Width 120, Text "Keep report", AccessibleLabel "Keep the report and close dismiss";
                                  OnSelect =Set(varAbsApDismissOpen, false); Reset(txtAbsApDismissNote)
```

Every ModernButton above: `Height: =44`, `Layout: =ButtonLayout.TextOnly`, `Size: =14`, `LayoutMinHeight: =0`,
`LayoutMinWidth: =0`, `AlignInContainer: =AlignInContainer.Center` (btnAbsApShowGrid `Start`). Secondary =
`Appearance: =ButtonAppearance.Secondary`, `Color: =ColorInk`; primary = `BasePaletteColor: =ColorTeal`, `Color: =ColorWhite`.
Label style = Size 12, Semibold, Color ColorMuted, Height 18, Wrap false.

### Formulas (copy verbatim as `|-` blocks)

**F1 — `btnAbsApEngine.OnSelect`** (queue load)
```
=Set(varAbsApLoading, true);
Set(varAbsApLoadError, "");
Set(varAbsApSelId, Blank());
Set(varAbsApPlanFor, Blank());
Set(varAbsApDismissOpen, false);
Clear(colAbsApPlan);
If(
    !CanClassify,
    Clear(colAbsAp),
    IfError(
        Concurrent(
            ClearCollect(colAbsApR1, ForAll(Filter('Student Absence Log', Match_Status.Value = "Exact") As r, {ID: r.ID, Title: Coalesce(r.Title, ""), Created: r.Created, MatchStatus: "Exact", StudentKey: Trim(Coalesce(r.Student_ID, "")), FirstName: Coalesce(r.'Student First Name', ""), LastName: Coalesce(r.'Student Last Name', ""), SchoolSite: Coalesce(r.'School Site', ""), AbsenceDateText: Coalesce(r.'Absence Date', ""), ReturnDateText: Coalesce(r.'Return Date', ""), Reason: Coalesce(r.Reason, ""), SubmittedBy: Coalesce(r.'Submitted By', ""), DateNotified: Coalesce(r.'Date Notified', "")})),
            ClearCollect(colAbsApR2, ForAll(Filter('Student Absence Log', Match_Status.Value = "Approved Variation") As r, {ID: r.ID, Title: Coalesce(r.Title, ""), Created: r.Created, MatchStatus: "Approved Variation", StudentKey: Trim(Coalesce(r.Student_ID, "")), FirstName: Coalesce(r.'Student First Name', ""), LastName: Coalesce(r.'Student Last Name', ""), SchoolSite: Coalesce(r.'School Site', ""), AbsenceDateText: Coalesce(r.'Absence Date', ""), ReturnDateText: Coalesce(r.'Return Date', ""), Reason: Coalesce(r.Reason, ""), SubmittedBy: Coalesce(r.'Submitted By', ""), DateNotified: Coalesce(r.'Date Notified', "")})),
            ClearCollect(colAbsApR3, ForAll(Filter('Student Absence Log', Match_Status.Value = "Manually Resolved") As r, {ID: r.ID, Title: Coalesce(r.Title, ""), Created: r.Created, MatchStatus: "Manually Resolved", StudentKey: Trim(Coalesce(r.Student_ID, "")), FirstName: Coalesce(r.'Student First Name', ""), LastName: Coalesce(r.'Student Last Name', ""), SchoolSite: Coalesce(r.'School Site', ""), AbsenceDateText: Coalesce(r.'Absence Date', ""), ReturnDateText: Coalesce(r.'Return Date', ""), Reason: Coalesce(r.Reason, ""), SubmittedBy: Coalesce(r.'Submitted By', ""), DateNotified: Coalesce(r.'Date Notified', "")})),
            ClearCollect(colAbsApCampuses, ForAll(Campuses As c, {CampusId: c.Campus, CampusName: c.Name, CampusCode: Coalesce(c.Code, "")})),
            ClearCollect(colAbsApStu, ForAll(Students As s, {StudentId: s.Student, DisplayName: Coalesce(s.'Display Name', "Unnamed student"), StudentKey: Trim(Coalesce(s.'External Client ID', "")), StudentNumber: Coalesce(s.'Student Number', "")})),
            ClearCollect(colAbsApEnr, ForAll(Enrollments As e, {EnrId: e.Enrollment, StudentId: e.Student.Student, CampusId: e.Campus.Campus, CampusName: Coalesce(e.Campus.Name, ""), TeacherId: e.Teacher.Staff, TeacherName: Coalesce(e.Teacher.Name, ""), ServiceId: e.Service.Service, ServiceCode: Coalesce(e.Service.'Service Code', ""), StudentNumber: Coalesce(e.Student.'Student Number', ""), StartDate: e.'Start Date', EndDate: e.'End Date', EnrRec: e}))
        ); true,
        Set(varAbsApLoadError, FirstError.Message)
    );
    ClearCollect(colAbsApSrc, colAbsApR1, colAbsApR2, colAbsApR3);
    IfError(
        With({minId: Coalesce(Min(colAbsApSrc, ID), 0)}, ClearCollect(colAbsApDecided, ForAll(Filter('Report Decisions', 'Report Item ID' >= minId) As d, {ItemId: d.'Report Item ID'}))); true,
        Set(varAbsApLoadError, "Report Decisions could not be read (" & FirstError.Message & ")")
    );
    If(
        varAbsApLoadError <> "",
        Clear(colAbsAp),
        ClearCollect(
            colAbsAp,
            Filter(
                ForAll(
                    colAbsApSrc As s,
                    With(
                        {
                            d0: IfError(DateValue(s.AbsenceDateText, "en-US"), Blank()),
                            stu: LookUp(colAbsApStu, s.StudentKey <> "" && StudentKey = s.StudentKey),
                            site: LookUp(colAbsApCampuses, CampusName = Trim(s.SchoolSite))
                        },
                        With(
                            {seg: First(Sort(Filter(colAbsApEnr, StudentId = stu.StudentId), StartDate, SortOrder.Descending))},
                            {
                                ID: s.ID, Title: s.Title, Created: s.Created, MatchStatus: s.MatchStatus, StudentKey: s.StudentKey,
                                FirstName: s.FirstName, LastName: s.LastName, SchoolSite: s.SchoolSite,
                                AbsenceDateText: s.AbsenceDateText, ReturnDateText: s.ReturnDateText, Reason: s.Reason,
                                SubmittedBy: s.SubmittedBy, DateNotified: s.DateNotified,
                                AbsDate: d0,
                                StudentId: Coalesce(stu.StudentId, ZeroGuid), StudentName: Coalesce(stu.DisplayName, ""), StudentNumber: Coalesce(stu.StudentNumber, ""),
                                CampusId: Coalesce(seg.CampusId, site.CampusId, ZeroGuid), CampusName: Coalesce(seg.CampusName, site.CampusName, ""),
                                SiteCampusId: Coalesce(site.CampusId, ZeroGuid),
                                Decided: s.ID in colAbsApDecided.ItemId
                            }
                        )
                    )
                ),
                !IsBlank(AbsDate) && AbsDate >= ParentReportCutover && !Decided && (StudentCampusLock = ZeroGuid || CampusId = StudentCampusLock || SiteCampusId = StudentCampusLock)
            )
        )
    )
);
Set(varAbsApLoaded, true);
Set(varAbsApLoading, false)
```

**F2 — `btnAbsApRowOpen.OnSelect`**
```
=Set(varAbsApSelId, ThisItem.ID);
Set(varAbsApClass, "");
Set(varAbsApReasonId, Blank());
Set(varAbsApDismissOpen, false);
Reset(rdoAbsApClass);
Reset(ddAbsApReason);
Reset(txtAbsApNote);
Reset(txtAbsApDismissNote);
Select(btnAbsApPlanEngine)
```

**F2b — `btnAbsApPlanEngine.OnSelect`** (per-day plan; same school-day rule as Needs Review)
```
=Set(varAbsApPlanFor, Blank());
Set(varAbsApPlanErr, "");
Clear(colAbsApPlan);
With(
    {it: LookUp(colAbsAp, ID = varAbsApSelId)},
    With(
        {d0: it.AbsDate, r0: IfError(DateValue(it.ReturnDateText, "en-US"), Blank())},
        With(
            {dEnd: If(IsBlank(r0) || r0 <= d0, d0, DateAdd(r0, -1, TimeUnit.Days))},
            If(
                IsBlank(it),
                Set(varAbsApPlanErr, "that report is no longer in the queue; use Reload"),
                it.StudentId = ZeroGuid,
                Set(varAbsApPlanErr, "no app student has Student Key " & it.StudentKey),
                Trim(it.ReturnDateText) <> "" && IsBlank(r0),
                Set(varAbsApPlanErr, "the Return Date """ & it.ReturnDateText & """ can't be read as M/D/YYYY"),
                DateDiff(d0, dEnd, TimeUnit.Days) > 180,
                Set(varAbsApPlanErr, "the span from " & it.AbsenceDateText & " to " & it.ReturnDateText & " is over 180 days"),
                IfError(
                    With(
                        {qs: it.StudentId, a: d0, b: dEnd},
                        Concurrent(
                            ClearCollect(colAbsApTerms, Filter(Terms, 'Start Date' <= b && 'End Date' >= a)),
                            ClearCollect(colAbsApExc, ForAll(Filter('Calendar Exceptions', Date >= a && Date <= b) As x, {XDate: x.Date, CampusId: x.Campus.Campus, IsClosed: x.Type <> 'Type (Calendar Exceptions)'.'Make-up School Day', IsMakeup: x.Type = 'Type (Calendar Exceptions)'.'Make-up School Day'})),
                            ClearCollect(colAbsApLocks, ForAll(Filter('Month Locks', 'Status (aaca_status)' = 'Status (Month Locks)'.Locked) As m, {CampusId: m.Campus.Campus, MonthStart: m.Month})),
                            ClearCollect(colAbsApAtt, ForAll(Filter(Attendance, Student.Student = qs && Date >= a && Date <= b) As r, {AttId: r.Attendance, ServiceId: r.Service.Service, AttDate: r.Date, Present: r.Present = true, IsDeleted: r.'Is Deleted' = true, Classified: !IsBlank(r.'Absence Classification')}))
                        )
                    ); true,
                    Set(varAbsApPlanErr, "the calendar or attendance could not be loaded (" & FirstError.Message & ")")
                );
                If(
                    varAbsApPlanErr = "",
                    ForAll(
                        Sequence(DateDiff(d0, dEnd, TimeUnit.Days) + 1, 0) As k,
                        With(
                            {D: DateAdd(d0, k.Value, TimeUnit.Days)},
                            With(
                                {seg: First(Sort(Filter(colAbsApEnr, StudentId = it.StudentId && StartDate <= D && (IsBlank(EndDate) || EndDate >= D)), StartDate, SortOrder.Descending))},
                                With(
                                    {cid: Coalesce(seg.CampusId, it.CampusId)},
                                    With(
                                        {
                                            t: First(Filter(colAbsApTerms, ThisRecord.'Start Date' <= D && ThisRecord.'End Date' >= D && (IsBlank(ThisRecord.Campus) || ThisRecord.Campus.Campus = cid))),
                                            closed: !IsBlank(LookUp(colAbsApExc, XDate = D && (IsBlank(CampusId) || CampusId = cid) && IsClosed)),
                                            mk: !IsBlank(LookUp(colAbsApExc, XDate = D && (IsBlank(CampusId) || CampusId = cid) && IsMakeup)),
                                            wk: Weekday(D, StartOfWeek.Monday) >= 6
                                        },
                                        If(
                                            !IsBlank(t) && !closed && (!wk || mk),
                                            With(
                                                {
                                                    att: LookUp(colAbsApAtt, AttDate = D && ServiceId = seg.ServiceId),
                                                    locked: !IsBlank(LookUp(colAbsApLocks, CampusId = cid && MonthStart = Date(Year(D), Month(D), 1)))
                                                },
                                                With(
                                                    {oc: If(IsBlank(seg), "skip-notenrolled", locked, "skip-locked", IsBlank(att), "create", att.IsDeleted, "restore", att.Present, "skip-present", !att.Classified, "classify", "skip-classified")},
                                                    Collect(colAbsApPlan, {DayDate: D, EnrId: Coalesce(seg.EnrId, ZeroGuid), TermId: t.'Term (aaca_termid)', CampusId: Coalesce(cid, ZeroGuid), ServiceId: Coalesce(seg.ServiceId, ZeroGuid), TeacherId: Coalesce(seg.TeacherId, ZeroGuid), TeacherName: Coalesce(seg.TeacherName, ""), Outcome: oc, OutcomeText: Switch(oc, "create", "New 0 will be created", "restore", "Deleted row will be restored as 0", "classify", "Existing 0 will be classified", "skip-classified", "Skip · already classified", "skip-present", "Skip · marked present by teacher", "skip-notenrolled", "Skip · not enrolled that day", "skip-locked", "Skip · month locked", oc)})
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    );
                    Set(varAbsApPlanFor, varAbsApSelId)
                )
            )
        )
    )
)
```

**F3 — `lblAbsApFacts.Text`**
```
=With(
    {it: LookUp(colAbsAp, ID = varAbsApSelId)},
    "Report #" & it.ID & If(it.Title = "", "", " · " & it.Title) & " · " & it.MatchStatus & Char(10) &
    "App student: " & If(it.StudentId = ZeroGuid, "none found for Student_ID " & it.StudentKey, it.StudentName & " · " & it.StudentKey & " · " & it.StudentNumber) & Char(10) &
    "Parent typed: " & it.FirstName & " " & it.LastName & " · school site " & it.SchoolSite & Char(10) &
    "Campus: " & If(it.CampusName = "", "—", it.CampusName) & Char(10) &
    "Absence date: " & it.AbsenceDateText & " · Return date: " & If(Trim(it.ReturnDateText) = "", "—", it.ReturnDateText) & Char(10) &
    "Reason: " & If(it.Reason = "", "—", If(Len(it.Reason) > 120, Left(it.Reason, 120) & "…", it.Reason)) & Char(10) &
    "Submitted by " & it.SubmittedBy & " · notified " & it.DateNotified
)
```

**F4 — `lblAbsApDaysHead.Text`**
```
=With(
    {n: CountRows(colAbsApPlan), w: CountRows(Filter(colAbsApPlan, Outcome in ["create", "restore", "classify"])), pr: CountRows(Filter(colAbsApPlan, Outcome = "skip-present"))},
    If(
        varAbsApPlanErr <> "", "Days can't be worked out — " & varAbsApPlanErr & ".",
        varAbsApPlanFor <> varAbsApSelId, "Working out the school days…",
        n = 0, "No school days in this range (weekends, holidays or outside a term). Approve records the decision only.",
        n & If(n = 1, " school day", " school days") & " · " & w & " will get a 0 · " & (n - w) & " skipped" & If(pr > 0, " · " & pr & " marked present by the teacher, check with them", "")
    )
)
```

**F5 — `btnAbsApShowGrid.OnSelect`**
```
=With(
    {g: varAbsApGridLink},
    Set(varCampus, With({c: g.CampusId}, LookUp(Campuses, ThisRecord.Campus = c)));
    Set(varTeacher, With({t: g.TeacherId}, LookUp(Staff, ThisRecord.Staff = t)));
    Set(varMonthStart, Date(Year(g.FirstDay), Month(g.FirstDay), 1));
    Set(varViewDate, g.FirstDay);
    Set(varLastAction, {Kind: "Report", Message: varAbsApReceipt.Title, StudentId: g.StudentId, DayNum: Day(g.FirstDay)});
    Navigate(Screen1)
)
```

**F6 — `lblAbsApCheck.Text`**
```
=With(
    {it: LookUp(colAbsAp, ID = varAbsApSelId), rs: LookUp(colAbsReasons, ReasonId = varAbsApReasonId)},
    If(
        IsBlank(it), "That report is no longer in the queue. Use Reload.",
        it.StudentId = ZeroGuid, "No app student has Student Key " & it.StudentKey & ". Fix the key on the Students screen and Reload, or Dismiss.",
        varAbsApPlanErr <> "", "Approve is off until the dates can be worked out. Dismiss if the report is wrong.",
        varAbsApPlanFor <> varAbsApSelId, "Working out the school days…",
        !(varAbsApClass in ["Excused", "Unexcused"]), "Choose Excused or Unexcused.",
        IsBlank(rs), "Choose an absence reason.",
        "Ready: Approve writes " & CountRows(Filter(colAbsApPlan, Outcome in ["create", "restore", "classify"])) & " day(s) as " & varAbsApClass & " (" & rs.ReasonName & ") and records the decision."
    )
)
```

**F7 — `btnAbsApApprove.DisplayMode`**
```
=If(CanClassify && !varAbsApSaving && !varAbsApLoading && !IsBlank(LookUp(colAbsAp, ID = varAbsApSelId)) && LookUp(colAbsAp, ID = varAbsApSelId).StudentId <> ZeroGuid && varAbsApPlanFor = varAbsApSelId && varAbsApPlanErr = "" && varAbsApClass in ["Excused", "Unexcused"] && !IsBlank(LookUp(colAbsReasons, ReasonId = varAbsApReasonId)), DisplayMode.Edit, DisplayMode.Disabled)
```

**F8 — `btnAbsApApprove.OnSelect`** (single guarded mutation; literal guards per classification)
```
=With(
    {
        qid: varAbsApSelId,
        it: LookUp(colAbsAp, ID = varAbsApSelId),
        cls: varAbsApClass,
        note: Left(Trim(txtAbsApNote.Text), 200),
        rsn: With({qr: varAbsApReasonId}, LookUp('Absence Reasons', ThisRecord.'Absence Reason' = qr && Active = true))
    },
    If(
        !CanClassify || varAbsApSaving || IsBlank(it),
        Set(varAbsApReceipt, {Kind: "Blocked", Title: "Not approved · choose a report in Ready to approve first", Body: "", ItemId: Coalesce(qid, 0)}),
        !(cls in ["Excused", "Unexcused"]),
        Set(varAbsApReceipt, {Kind: "Blocked", Title: "Not approved · choose Excused or Unexcused", Body: "Report #" & qid & " was not changed.", ItemId: qid}),
        IsBlank(rsn),
        Set(varAbsApReceipt, {Kind: "Blocked", Title: "Not approved · choose an absence reason", Body: "Report #" & qid & " was not changed.", ItemId: qid}),
        it.StudentId = ZeroGuid || varAbsApPlanFor <> qid || varAbsApPlanErr <> "",
        Set(varAbsApReceipt, {Kind: "Blocked", Title: "Not approved · report #" & qid & " has no app student or its days could not be worked out", Body: "", ItemId: qid}),
        Set(varAbsApSaving, true);
        Clear(colAbsApLog);
        With(
            {
                prior: With({q: qid}, LookUp('Report Decisions', 'Report Item ID' = q)),
                live: With({q: qid}, LookUp('Student Absence Log', ID = q))
            },
            If(
                !IsBlank(prior),
                Set(varAbsApReceipt, {Kind: "Blocked", Title: "Not approved · report #" & qid & " was already " & Lower(Text(prior.Decision)), Body: "Decided by " & Coalesce(prior.'Created By'.'Full Name', "another user") & " on " & Text(prior.'Created On', "mmm d, yyyy h:mm AM/PM") & ". Nothing was written, and the report has been removed from this queue.", ItemId: qid});
                RemoveIf(colAbsAp, ID = qid);
                Collect(colAbsApDecided, {ItemId: qid});
                Set(varAbsApSelId, Blank());
                Set(varAbsApPlanFor, Blank()),
                IsBlank(live) || !(live.Match_Status.Value in ["Exact", "Approved Variation", "Manually Resolved"]) || Trim(Coalesce(live.Student_ID, "")) <> it.StudentKey,
                Set(varAbsApReceipt, {Kind: "Blocked", Title: "Not approved · report #" & qid & " changed in SharePoint", Body: "The report was deleted, or its match status or Student_ID changed since the queue loaded. Nothing was written. Use Reload.", ItemId: qid}),
                ClearCollect(colAbsApLocks, ForAll(Filter('Month Locks', 'Status (aaca_status)' = 'Status (Month Locks)'.Locked) As m, {CampusId: m.Campus.Campus, MonthStart: m.Month}));
                ForAll(
                    colAbsApPlan As p,
                    With(
                        {
                            seg: LookUp(colAbsApEnr, EnrId = p.EnrId),
                            term: LookUp(colAbsApTerms, ThisRecord.'Term (aaca_termid)' = p.TermId),
                            srv: With({qs: it.StudentId, qv: p.ServiceId, qd: p.DayDate}, LookUp(Attendance, Student.Student = qs && Service.Service = qv && Date = qd))
                        },
                        With(
                            {
                                oc: If(
                                    p.EnrId = ZeroGuid, "skip-notenrolled",
                                    !IsBlank(LookUp(colAbsApLocks, CampusId = p.CampusId && MonthStart = Date(Year(p.DayDate), Month(p.DayDate), 1))), "skip-locked",
                                    IsError(srv), "failed",
                                    IsBlank(srv), "create",
                                    srv.'Is Deleted' = true, "restore",
                                    srv.Present = true, "skip-present",
                                    IsBlank(srv.'Absence Classification'), "classify",
                                    "skip-classified"
                                )
                            },
                            With(
                                {
                                    wr: If(
                                        oc = "create" || oc = "restore",
                                        IfError(
                                            Patch(
                                                Attendance,
                                                Coalesce(srv, Defaults(Attendance)),
                                                {
                                                    'Record Key': Text(p.DayDate, "yyyymmdd") & "|" & seg.StudentNumber & "|" & seg.ServiceCode,
                                                    Date: p.DayDate,
                                                    Student: seg.EnrRec.Student,
                                                    Service: seg.EnrRec.Service,
                                                    Enrollment: seg.EnrRec,
                                                    Teacher: seg.EnrRec.Teacher,
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
                                                    Present: false,
                                                    'Is Deleted': false,
                                                    'Absence Classification': If(cls = "Excused", 'Absence Classification (Attendance)'.Excused, cls = "Unexcused", 'Absence Classification (Attendance)'.Unexcused),
                                                    'Absence Reason': rsn,
                                                    'Classified By': CurrentUserRow,
                                                    'Classified On': Now(),
                                                    Notes: note,
                                                    'Source Report ID': qid
                                                }
                                            ),
                                            Blank()
                                        ),
                                        oc = "classify",
                                        IfError(
                                            Patch(
                                                Attendance,
                                                srv,
                                                {
                                                    'Absence Classification': If(cls = "Excused", 'Absence Classification (Attendance)'.Excused, cls = "Unexcused", 'Absence Classification (Attendance)'.Unexcused),
                                                    'Absence Reason': rsn,
                                                    'Classified By': CurrentUserRow,
                                                    'Classified On': Now(),
                                                    Notes: If(note = "", srv.Notes, note),
                                                    'Source Report ID': qid
                                                }
                                            ),
                                            Blank()
                                        )
                                    )
                                },
                                Collect(
                                    colAbsApLog,
                                    {
                                        DayDate: p.DayDate,
                                        Outcome: If((oc in ["create", "restore", "classify"]) && IsBlank(wr), "failed", oc),
                                        Detail: If(
                                            !IsBlank(wr),
                                            Switch(oc, "create", "New 0 created", "restore", "Deleted row restored as 0", "Existing 0 classified") & " · 0 · " & Text(wr.'Absence Classification') & " (" & wr.'Absence Reason'.Name & ") · parent report #" & wr.'Source Report ID' & " · by " & Coalesce(wr.'Classified By'.'Full Name', "") & " · Teacher " & Coalesce(wr.Teacher.Name, p.TeacherName) & " · Key " & wr.'Record Key',
                                            oc in ["create", "restore", "classify", "failed"], "FAILED · not changed, press Approve to retry",
                                            Switch(oc, "skip-classified", "Skipped · already classified", "skip-present", "Skipped · marked present by teacher", "skip-notenrolled", "Skipped · not enrolled that day", "skip-locked", "Skipped · month locked", oc)
                                        ),
                                        AttId: If(!IsBlank(wr), wr.Attendance, IsError(srv) || IsBlank(srv), ZeroGuid, srv.Attendance)
                                    }
                                )
                            )
                        )
                    )
                );
                With(
                    {
                        nC: CountRows(Filter(colAbsApLog, Outcome in ["create", "restore"])),
                        nK: CountRows(Filter(colAbsApLog, Outcome = "classify")),
                        nS: CountRows(Filter(colAbsApLog, StartsWith(Outcome, "skip"))),
                        nF: CountRows(Filter(colAbsApLog, Outcome = "failed"))
                    },
                    If(
                        nF > 0,
                        Set(varAbsApReceipt, {Kind: "Failed", Title: "Partly applied · report #" & qid & " · " & nF & " day(s) failed", Body: "Written: " & nC & " created or restored, " & nK & " classified · " & nS & " skipped · " & nF & " failed." & Char(10) & "No decision was recorded, so the report stays in Ready to approve. Press Approve to retry; days already written will show as already classified.", ItemId: qid}),
                        With(
                            {
                                dec: IfError(
                                    Patch(
                                        'Report Decisions',
                                        Defaults('Report Decisions'),
                                        {
                                            Summary: Left("Approved parent report #" & qid & " · " & it.StudentName & " · " & cls, 100),
                                            'Report Item ID': qid,
                                            Decision: 'Decision (Report Decisions)'.Approved,
                                            Classification: If(cls = "Excused", 'Classification (Report Decisions)'.Excused, cls = "Unexcused", 'Classification (Report Decisions)'.Unexcused),
                                            'Absence Reason': rsn,
                                            Student: With({qs: it.StudentId}, LookUp(Students, ThisRecord.Student = qs)),
                                            Campus: With({qc: it.CampusId}, LookUp(Campuses, ThisRecord.Campus = qc)),
                                            'Student Key': it.StudentKey,
                                            Note: note,
                                            'Days Created': nC,
                                            'Days Classified': nK,
                                            'Days Skipped': nS
                                        }
                                    ),
                                    Blank()
                                )
                            },
                            If(
                                IsBlank(dec),
                                Set(varAbsApReceipt, {Kind: "Failed", Title: "Attendance written but the decision was NOT recorded · report #" & qid, Body: "Written: " & nC & " created or restored, " & nK & " classified · " & nS & " skipped." & Char(10) & "The Report Decisions row could not be saved (someone may have decided this report at the same moment). The report stays in the queue; press Approve to retry recording the decision, or Reload.", ItemId: qid}),
                                With(
                                    {
                                        au: IfError(
                                            Patch(
                                                'Audit Events',
                                                Defaults('Audit Events'),
                                                {
                                                    Summary: Left("Parent report #" & qid & " approved " & cls & " · " & nC & " created, " & nK & " classified, " & nS & " skipped", 100),
                                                    Action: 'Action (Audit Events)'.Reclassify,
                                                    Entity: "aaca_reportdecision",
                                                    'Entity ID': Text(dec.'Report Decision'),
                                                    Before: JSON({ReportItemId: qid, StudentKey: it.StudentKey, AbsenceDate: it.AbsenceDateText, ReturnDate: it.ReturnDateText}),
                                                    After: Left(JSON(ForAll(colAbsApLog As g, {Date: Text(g.DayDate, "yyyy-mm-dd"), Outcome: g.Outcome, AttId: Text(g.AttId)})), 2000),
                                                    Reason: Left("Approved in Absences, Ready to approve: " & cls & " · " & rsn.Name & If(note = "", "", " · " & note), 500)
                                                }
                                            ),
                                            Blank()
                                        )
                                    },
                                    Set(
                                        varAbsApReceipt,
                                        {
                                            Kind: "Approved",
                                            Title: "Approved · parent report #" & dec.'Report Item ID' & " · " & it.StudentName & " · " & Text(dec.Classification),
                                            Body: "Report: #" & dec.'Report Item ID' & If(it.Title = "", "", " · " & it.Title) & Char(10) &
                                                "Student: " & it.StudentName & " · " & dec.'Student Key' & " · " & Coalesce(dec.Campus.Name, it.CampusName, "—") & Char(10) &
                                                "Decision: " & Text(dec.Decision) & " (Report Decisions row recorded)" & Char(10) &
                                                "Classification: " & Text(dec.Classification) & " · Reason: " & dec.'Absence Reason'.Name & Char(10) &
                                                "Note: " & If(Coalesce(dec.Note, "") = "", "—", dec.Note) & Char(10) &
                                                "Days: " & dec.'Days Created' & " created or restored as 0 · " & dec.'Days Classified' & " classified · " & dec.'Days Skipped' & " skipped" & Char(10) &
                                                "Audit event: " & If(IsBlank(au), "NOT written", "written"),
                                            ItemId: dec.'Report Item ID'
                                        }
                                    );
                                    With(
                                        {g: First(Sort(Filter(colAbsApLog, Outcome in ["create", "restore", "classify"]), DayDate, SortOrder.Ascending))},
                                        With(
                                            {pp: LookUp(colAbsApPlan, DayDate = g.DayDate)},
                                            Set(varAbsApGridLink, {StudentId: it.StudentId, TeacherId: If(IsBlank(g), ZeroGuid, Coalesce(pp.TeacherId, ZeroGuid)), CampusId: Coalesce(pp.CampusId, ZeroGuid), FirstDay: Coalesce(g.DayDate, it.AbsDate)})
                                        )
                                    );
                                    RemoveIf(colAbsAp, ID = qid);
                                    Collect(colAbsApDecided, {ItemId: qid});
                                    Set(varAbsApSelId, Blank());
                                    Set(varAbsApPlanFor, Blank());
                                    Set(varAbsApClass, "");
                                    Set(varAbsApReasonId, Blank());
                                    Set(varAbsApDismissOpen, false);
                                    Reset(rdoAbsApClass);
                                    Reset(ddAbsApReason);
                                    Reset(txtAbsApNote)
                                )
                            )
                        )
                    )
                )
            )
        );
        Set(varAbsApSaving, false)
    )
)
```

**F9 — `btnAbsApDismissConfirm.OnSelect`**
```
=With(
    {qid: varAbsApSelId, it: LookUp(colAbsAp, ID = varAbsApSelId), dnote: Left(Trim(txtAbsApDismissNote.Text), 1000)},
    If(
        !CanClassify || varAbsApSaving || IsBlank(it) || dnote = "",
        Set(varAbsApReceipt, {Kind: "Blocked", Title: "Not dismissed · choose a report and type why it is dismissed", Body: "", ItemId: Coalesce(qid, 0)}),
        Set(varAbsApSaving, true);
        With(
            {prior: With({q: qid}, LookUp('Report Decisions', 'Report Item ID' = q))},
            If(
                !IsBlank(prior),
                Set(varAbsApReceipt, {Kind: "Blocked", Title: "Not dismissed · report #" & qid & " was already " & Lower(Text(prior.Decision)), Body: "Nothing was written, and the report has been removed from this queue.", ItemId: qid});
                RemoveIf(colAbsAp, ID = qid);
                Collect(colAbsApDecided, {ItemId: qid});
                Set(varAbsApSelId, Blank());
                Set(varAbsApPlanFor, Blank());
                Set(varAbsApDismissOpen, false),
                With(
                    {
                        dec: IfError(
                            Patch(
                                'Report Decisions',
                                Defaults('Report Decisions'),
                                {
                                    Summary: Left("Dismissed parent report #" & qid & " · " & If(it.StudentName = "", it.StudentKey, it.StudentName), 100),
                                    'Report Item ID': qid,
                                    Decision: 'Decision (Report Decisions)'.Dismissed,
                                    Student: With({qs: it.StudentId}, LookUp(Students, ThisRecord.Student = qs)),
                                    Campus: With({qc: it.CampusId}, LookUp(Campuses, ThisRecord.Campus = qc)),
                                    'Student Key': it.StudentKey,
                                    Note: dnote,
                                    'Days Created': 0,
                                    'Days Classified': 0,
                                    'Days Skipped': 0
                                }
                            ),
                            Blank()
                        )
                    },
                    If(
                        IsBlank(dec),
                        Set(varAbsApReceipt, {Kind: "Failed", Title: "Not dismissed · the decision could not be saved for report #" & qid, Body: "Nothing was written. The report is still selected; press Confirm dismiss to retry.", ItemId: qid}),
                        With(
                            {au: IfError(Patch('Audit Events', Defaults('Audit Events'), {Summary: Left("Parent report #" & qid & " dismissed", 100), Action: 'Action (Audit Events)'.Update, Entity: "aaca_reportdecision", 'Entity ID': Text(dec.'Report Decision'), Before: JSON({ReportItemId: qid, StudentKey: it.StudentKey, AbsenceDate: it.AbsenceDateText}), After: JSON({Decision: "Dismissed"}), Reason: Left(dnote, 500)}), Blank())},
                            Set(varAbsApReceipt, {Kind: "Dismissed", Title: "Dismissed · parent report #" & dec.'Report Item ID' & If(it.StudentName = "", "", " · " & it.StudentName), Body: "Report: #" & dec.'Report Item ID' & If(it.Title = "", "", " · " & it.Title) & Char(10) & "Student: " & If(it.StudentName = "", "no app student", it.StudentName) & " · " & dec.'Student Key' & Char(10) & "Decision: " & Text(dec.Decision) & " (Report Decisions row recorded)" & Char(10) & "Note: " & dec.Note & Char(10) & "Attendance: not changed (no rows written)" & Char(10) & "Audit event: " & If(IsBlank(au), "NOT written", "written"), ItemId: dec.'Report Item ID'});
                            Clear(colAbsApLog);
                            Set(varAbsApGridLink, {StudentId: ZeroGuid, TeacherId: ZeroGuid, CampusId: ZeroGuid, FirstDay: Today()});
                            RemoveIf(colAbsAp, ID = qid);
                            Collect(colAbsApDecided, {ItemId: qid});
                            Set(varAbsApSelId, Blank());
                            Set(varAbsApPlanFor, Blank());
                            Set(varAbsApClass, "");
                            Set(varAbsApReasonId, Blank());
                            Set(varAbsApDismissOpen, false);
                            Clear(colAbsApPlan);
                            Reset(rdoAbsApClass);
                            Reset(ddAbsApReason);
                            Reset(txtAbsApNote);
                            Reset(txtAbsApDismissNote)
                        )
                    )
                )
            )
        );
        Set(varAbsApSaving, false)
    )
)
```

**F10 — `btnAbsApCancel.OnSelect`**
```
=Set(varAbsApSelId, Blank());
Set(varAbsApPlanFor, Blank());
Set(varAbsApClass, "");
Set(varAbsApReasonId, Blank());
Set(varAbsApDismissOpen, false);
Clear(colAbsApPlan);
Reset(rdoAbsApClass);
Reset(ddAbsApReason);
Reset(txtAbsApNote);
Reset(txtAbsApDismissNote)
```

Schema notes for the builder: `varAbsApReceipt` always gets all four fields `{Kind, Title, Body, ItemId}`;
`varAbsApGridLink` all four `{StudentId, TeacherId, CampusId, FirstDay}`; `colAbsApPlan` / `colAbsApLog` record
shapes above exactly match the App.OnStart seeds. `colAbsApR1/R2/R3` projections must be identical except the
filter literal and `MatchStatus` literal.

## Controls to Remove

None.

## Properties to Update

- `AbsencesScreen.OnVisible` — Change 1.
- `btnAbsClearFiltersV.OnSelect` — Change 2.
- `conAbsViewBar` Height / LayoutAlignItems / LayoutDirection; `btnAbsViewClassify`, `btnAbsViewNr` AlignInContainer / Width — Change 3.
- `conAbsRoot` LayoutMinWidth / LayoutMinHeight = 0 — Change 6.

## State-Driven Surface Visibility

| Surface key | Surface control | State predicate | Visible and hidden states |
| --- | --- | --- | --- |
| abs-ready-view | conAbsApView | `=CanClassify && varAbsView = "ready"` | ready toggle on / other views, teachers |
| abs-ready-dismiss | conAbsApDismissPanel | `=varAbsApDismissOpen && !IsBlank(varAbsApSelId)` | after Dismiss / after confirm, keep, cancel, open |
| abs-ready-receipt | conAbsApReceipt | `=varAbsApReceipt.Kind <> ""` | after approve/dismiss attempt / after receipt Dismiss |

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-LOAD-READY | CanClassify | `btnAbsApViewReady`, `btnAbsApReload`, OnVisible -> `btnAbsApEngine.OnSelect` (F1) | SP item ID | colAbsAp rebuilt | N/A | N/A | `galAbsApList`, `lblAbsApCount`, toggle count |
| A-OPEN-READY | row exists | `btnAbsApRowOpen.OnSelect` (F2) -> F2b | varAbsApSelId | colAbsApPlan for the report; varAbsApPlanFor = ID | N/A | N/A | `lblAbsApFacts`, `lblAbsApDaysHead`, `galAbsApDays` |
| A-APPROVE-EXCUSED | F7 true with `varAbsApClass = "Excused"` | `rdoAbsApClass.OnChange` (selection only) -> `btnAbsApApprove.OnSelect` (F8) | qid; Attendance Student+Service+Date; Report Decisions 'Report Item ID' | days -> active 0 Excused (+ reason, Source Report ID); decision Approved; audit; queue row removed | see plan index write set | Title + Body (report, student/key/campus, Decision, Classification, Reason, Note, day counts, audit) + one `galAbsApRcptDays` line per day ("New 0 created · 0 · Excused (Illness) · parent report #515 · by … · Teacher … · Key …") | `conAbsApReceipt`; Screen1 grid after `btnAbsApShowGrid` |
| A-APPROVE-UNEXCUSED | same with "Unexcused" | same | same | same with Unexcused (literal guard `cls = "Unexcused"`) | same | same | same |
| A-DISMISS | selected; `Trim(txtAbsApDismissNote.Text) <> ""` | `btnAbsApDismiss` -> `btnAbsApDismissConfirm.OnSelect` (F9) | qid | decision Dismissed; audit Update; no Attendance write; row removed | Report Decisions row + Audit row | Title + Body (report, student, Decision Dismissed, Note, "Attendance: not changed", audit) | `conAbsApReceipt`; `galAbsApList` |
| A-CANCEL-READY | selected | `btnAbsApCancel` (F10), `btnAbsApDismissCancel` | N/A | selection/panel cleared | N/A | N/A | `lblAbsApDetailEmpty` / panel hidden |
| A-SHOW-ON-GRID | receipt Approved with changed day | `btnAbsApShowGrid.OnSelect` (F5) | varAbsApGridLink | Screen1 globals set; Navigate(Screen1) | N/A | N/A | Screen1 teal-bordered 0 cell + `lblAttReceipt` |
| A-FILTER-ABSENCES | classify view | `btnAbsClearFiltersV.OnSelect`; App.OnStart | N/A | varAbsFrom = ParentReportCutover | N/A | N/A | `dpAbsFromV` 1/1/2026 |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| --- | --- | --- |
| rdoAbsApClass | lblAbsApClass `="Classification *"` | conAbsApClassField |
| ddAbsApReason | lblAbsApReason `="Absence reason *"` | conAbsApReasonField |
| txtAbsApNote | lblAbsApNote `="Note for the attendance record (optional, 200 max)"` | conAbsApNoteField |
| txtAbsApDismissNote | lblAbsApDismissNote `="Why dismiss? (required)"` | conAbsApDismissField |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization | Destination focus |
| --- | --- | --- | --- | --- | --- | --- |
| A-APPROVE-* | `dec` -> varAbsApReceipt (Title/Body); `wr` per day -> colAbsApLog.Detail -> `lblAbsApRcptLine` | Attendance (`wr`), Report Decisions (`dec`) | Screen1 grid (`btnAttCell`); Ready queue | qid = 'Source Report ID' = 'Report Item ID'; colAbsApLog.AttId | success-only RemoveIf(colAbsAp)/Collect(colAbsApDecided); Screen1.OnVisible reloads grid | F5 sets varTeacher/varCampus/varMonthStart + varLastAction {StudentId, DayNum} |
| A-DISMISS | `dec` -> varAbsApReceipt | Report Decisions | Ready queue | qid | success-only RemoveIf | N/A |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| --- | --- | --- | --- | --- | --- | --- |
| A-APPROVE-* | Present / Is Deleted | Changed (create/restore) | outcome | `Present: false`, `'Is Deleted': false` | Detail "0" | Screen1 "0" |
| A-APPROVE-* | Absence Classification | Changed | varAbsApClass | literal-guarded If | Detail `Text(wr.'Absence Classification')`; Body `Text(dec.Classification)` | cell colour |
| A-APPROVE-* | Absence Reason | Changed | rsn | `'Absence Reason': rsn` | Detail `wr.'Absence Reason'.Name`; Body `dec.'Absence Reason'.Name` | tooltip |
| A-APPROVE-* | Notes | Changed / Preserved (classify + blank note) | txtAbsApNote / srv.Notes | `Notes: note` / `If(note = "", srv.Notes, note)` | Body "Note: " & dec.Note | Screen1 Details |
| A-APPROVE-* | Source Report ID | Changed | qid | `'Source Report ID': qid` | Detail "parent report #" & wr.'Source Report ID' | tooltip |
| A-APPROVE-* | Classified By / On | Changed | CurrentUserRow / Now() | Patch | Detail "by " & wr.'Classified By'.'Full Name' | Classify view |
| A-APPROVE-* | Record Key, Date, Student, Service, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio | Changed (create/restore) / Preserved (classify) | seg, term | full snapshot / omitted | Detail "Teacher … · Key …" | Screen1 grid of that teacher |
| A-APPROVE-* | skipped days | Preserved | live row | no Patch | Detail "Skipped · …" | Screen1 unchanged |
| A-DISMISS | Report Decisions Decision/Note | Changed | txtAbsApDismissNote | Patch Defaults | Body | queue |
| A-DISMISS | Attendance | Preserved | — | no write | Body "Attendance: not changed" | Screen1 |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| --- | --- | --- | --- | --- | --- |
| S-READY-LIST | #515 Exact CW-1001 9/14–9/17/2026 undecided; #410 Needs Review; #300 Exact 12/15/2025 | office O opens Ready to approve | only #515 listed | `galAbsApList`; toggle "(1)" | #300, #410 excluded |
| S-READY-SCOPE-OFFICE | #600 student at OX | office O (CW) loads | #600 absent; admin sees it | `galAbsApList` | SchoolSite Chatsworth + OX student listed for O |
| S-READY-EMPTY | none eligible | open view | empty message | `lblAbsApCount` | load error -> red text, list cleared |
| S-APPROVE-NEW-DAYS | #515, no rows 9/14–9/16 | Open, Excused, Illness, note "Flu", Approve | 3 Attendance rows 0 Excused/Illness/515; decision Approved (3,0,0); audit | receipt Title/Body; 3 day lines "New 0 created …" | saving disables Approve |
| S-APPROVE-UNEXCUSED | #516 one day | Unexcused, Other, Approve | 0 Unexcused | receipt "Unexcused" | — |
| S-APPROVE-RESTORE-DELETED | 9/16 deleted row | Approve | restored 0 | "Deleted row restored as 0" | — |
| S-APPROVE-CLASSIFY-EXISTING | 9/15 active unclassified 0 | Approve Excused | classified, 515 | "Existing 0 classified" | already classified -> "Skipped · already classified" |
| S-APPROVE-SKIP-PRESENT | 9/16 active 1 | Open, Approve | 9/16 unchanged | plan line red "Skip · marked present by teacher"; receipt "Skipped · marked present by teacher" | locked month / not enrolled skips |
| S-APPROVE-NO-REASON | Excused, no reason | — | Approve disabled | `lblAbsApCheck` "Choose an absence reason." | no class -> "Choose Excused or Unexcused." |
| S-APPROVE-ALREADY-DECIDED | decision exists for #515 | Approve | nothing written; row removed | Blocked receipt "…was already approved" | alternate-key race -> Failed "decision was NOT recorded" |
| S-APPROVE-UNMAPPED | #700 CW-9999 | Open | Approve disabled | `lblAbsApCheck` "No app student has Student Key CW-9999…" | Dismiss allowed |
| S-APPROVE-CANCEL | #515 open | Cancel | no writes | `lblAbsApDetailEmpty` | — |
| S-DISMISS | #515 open | Dismiss, note "Duplicate", Confirm dismiss | decision Dismissed; audit; no attendance | receipt "Dismissed · parent report #515"; row gone | S-DISMISS-NO-NOTE: blank note -> Confirm disabled |
| S-SHOW-ON-GRID | after approve | Show on grid | Screen1 teacher A, Sep 2026 | teal-bordered green 0 on 9/14 | hidden when no day changed |
| S-BACKLOG-DEFAULT | fresh start | open Classify | From 1/1/2026 | `dpAbsFromV`, `lblAbsCountV` | Clear filters -> 1/1/2026 |
| S-NAV-TEACHER | teacher | visit screen | denied panel | `conAbsDenied` | — |
| S-REGRESSION | Needs Review #410 | Review, pick, Resolve Match | unchanged | `conAbsNrReceipt` | — |

## Relevant Data Source Schemas

- Student Absence Log (SharePoint): ID (Number), Title, Created, Match_Status (`.Value`: "Exact", "Approved Variation",
  "Needs Review", "Manually Resolved"), Student_ID (Text), 'Student First Name', 'Student Last Name', 'School Site',
  'Absence Date' (Text M/D/YYYY), 'Return Date' (Text), Reason, 'Submitted By', 'Date Notified'. Never write Finance
  columns; this build never writes to this list.
- Report Decisions (Dataverse): 'Report Decision' (GUID), Summary, 'Report Item ID' (Number, alternate key), Decision
  ('Decision (Report Decisions)'.Approved / .Dismissed), Classification ('Classification (Report Decisions)'.Excused /
  .Unexcused), 'Absence Reason' (lookup), Student (lookup Students), Campus (lookup Campuses), 'Student Key', Note
  (1000), 'Days Created', 'Days Classified', 'Days Skipped' (Number — display names assumed; the orchestrator
  verifies at compile), 'Created By' (Users), 'Created On'.
- Attendance: Attendance (GUID), 'Record Key', Date, Present, 'Is Deleted', Student, Service, Enrollment, Teacher,
  Campus, 'School Year', Term, 'IEP Ratio' ('IEP Ratio (Attendance)'), 'Absence Classification'
  ('Absence Classification (Attendance)'.Excused/.Unexcused), 'Absence Reason', 'Classified By', 'Classified On',
  Notes, 'Source Report ID' (Number), 'Modified On'.
- Enrollments: Enrollment, Student, Campus, Teacher, Service, 'School Year', 'IEP Ratio' ('IEP Ratio (Enrollments)'),
  'Start Date', 'End Date'. Students: Student, 'Display Name', 'Student Number', 'External Client ID'. Terms:
  'Term (aaca_termid)', 'Start Date', 'End Date', Campus. Calendar Exceptions: Date, Campus, Type
  ('Type (Calendar Exceptions)'.'Make-up School Day'). Month Locks: Campus, Month, 'Status (aaca_status)'
  ('Status (Month Locks)'.Locked). Absence Reasons: 'Absence Reason', Name, Active. Audit Events: Summary, Action
  ('Action (Audit Events)'.Reclassify / .Update), Entity, 'Entity ID', Before, After, Reason.

## Required Variants

- GroupContainer -> `Variant: AutoLayout` (every new container)
- Gallery -> `Variant: Vertical` (galAbsApRcptDays, galAbsApList, galAbsApDays)

## Changed or Added Control Definitions

- **GroupContainer** (`Control: GroupContainer`, `Variant: AutoLayout`): inputs BorderColor, BorderStyle, BorderThickness,
  DropShadow [Enum name: DropShadow → `=DropShadow.None`], Fill, Height, Width, Visible, Radius{TopLeft,TopRight,BottomLeft,BottomRight},
  LayoutAlignItems [Enum name: LayoutAlignItems → `=LayoutAlignItems.Stretch` / `.Center` / `.Start`],
  LayoutDirection [Enum name: LayoutDirection → `=LayoutDirection.Vertical` / `.Horizontal`], LayoutGap,
  LayoutJustifyContent [LayoutJustifyContent], LayoutOverflowX/Y [Enum name: LayoutOverflow], LayoutWrap,
  Padding{Top,Bottom,Left,Right}; as AutoLayout child: AlignInContainer [Enum name: AlignInContainer →
  `=AlignInContainer.Stretch` / `.Start` / `.Center`], FillPortions, LayoutMinWidth, LayoutMinHeight, LayoutMaxWidth, LayoutMaxHeight.
- **ModernText** (`Control: ModernText`): AccessibleLabel, Align [Align], AutoHeight, Color, FontWeight [Enum name: FontWeight →
  `=FontWeight.Semibold` / `.Bold`], Height, Padding{Top,Bottom,Left,Right}, Size, Text, VerticalAlign [Enum name: VerticalAlign →
  `=VerticalAlign.Top`], Visible, Width, Wrap; child: AlignInContainer, FillPortions, LayoutMinWidth, LayoutMinHeight.
- **ModernButton** (`Control: ModernButton`, no Fill property): AccessibleLabel, Appearance [Enum name: ButtonAppearance →
  `=ButtonAppearance.Secondary` / `.Primary`], BasePaletteColor, Color, DisplayMode [Enum name: DisplayMode → `=DisplayMode.Edit` /
  `.Disabled`], FontWeight, Height, Layout [Enum name: ButtonLayout → `=ButtonLayout.TextOnly`], OnSelect, Padding*, Size, Text,
  Tooltip, Visible, Width; child: AlignInContainer, FillPortions, LayoutMinWidth, LayoutMinHeight.
- **Classic/Button** (`Control: Classic/Button`, engines only): AutoDisableOnSelect, OnSelect, Text, Visible; child: AlignInContainer,
  LayoutMinWidth, LayoutMinHeight. No AccessibleLabel property.
- **Gallery** (`Control: Gallery`, `Variant: Vertical`): AccessibleLabel, Height, Items, Selectable, ShowScrollbar, TabIndex,
  TemplatePadding, TemplateSize, Visible, Width, WrapCount; child: FillPortions, LayoutMinWidth, LayoutMinHeight.
  Outputs TemplateWidth/TemplateHeight only on the direct shell child.
- **ModernRadio** (`Control: ModernRadio`): AccessibleLabel, Color, Default (Record), DisplayMode, Height, ItemDisplayText, Items,
  Layout [Enum name: OptionLayout → `=OptionLayout.Horizontal`], OnChange, Required, Size, Visible, Width; output Selected.
- **ModernDropdown** (`Control: ModernDropdown`): AccessibleLabel, Appearance [Enum name: Appearance → `=Appearance.Outline`], Color,
  Default (Record), DisplayMode, Height, ItemDisplayText, Items, OnChange, Required, Size, Visible; output Selected.
- **ModernTextInput** (`Control: ModernTextInput`): AccessibleLabel, Appearance [`=Appearance.Outline`], Color, Default, DisplayMode,
  Height, MaxLength, OnChange, Placeholder, Size, Type [Enum name: TextInputType → `=TextInputType.Multiline`], Visible; output Text.
- **ModernSpinner** (`Control: ModernSpinner`): AccessibleLabel, Color, Height, Label, SpinnerColor, Visible, Width.
