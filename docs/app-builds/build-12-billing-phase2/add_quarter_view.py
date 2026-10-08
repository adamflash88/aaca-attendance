"""Attendance screen: "Quarters" view (Adam 2026-10-08) - total days absent per student per quarter for report cards.

Decisions: total absences only (any 0 that is not removed: excused, unexcused or not classified; left early = present);
the student's whole quarter counts even if part of it was with another teacher; ESY is a fifth column; on screen only.
Quarter dates come from Terms (campus-specific row, else an all-campus row) for the chosen school year.
Edits Screen1.pa.yaml (view switch, month-view visibility, reload hook, new conAttQtrView + btnAttQtrEngine) and
App.pa.yaml (OnStart seeds). Idempotent.
"""
APP = r"C:\src\aaca-attendance\app"
p1 = APP + r"\Screen1.pa.yaml"
p0 = APP + r"\App.pa.yaml"
s = open(p1, encoding="utf-8").read()
if "conAttQtrView:" in s:
    raise SystemExit("already applied")


def rep(old, new, count=1):
    global s
    assert s.count(old) == count, (old[:80], s.count(old))
    s = s.replace(old, new)


# 1. view switch: Month / Day / Quarters
rep('                                    AccessibleLabel: ="Month or Day view"', '                                    AccessibleLabel: ="Month, Day or Quarters view"')
rep('                                    Items: =["Month", "Day"]\n', '                                    Items: =["Month", "Day", "Quarters"]\n')
i = s.index("- tabAttViewMode:")
j = s.index("                                    Width: =160", i)
s = s[:j] + ('                                    OnChange: =If(Self.Selected.Value = "Quarters", Select(btnAttQtrEngine))\n'
             '                                    TabSize: =TabSize.Small\n'
             '                                    Width: =250') + s[j + len("                                    Width: =160"):]
# the original TabSize line now sits just above the new OnChange: drop it (the new one follows OnChange)
s = s.replace("                                    TabSize: =TabSize.Small\n                                    OnChange:", "                                    OnChange:", 1)
i = s.index("- conAttViewBar:")
j = s.index("                              Width: =382", i)
s = s[:j] + "                              Width: =472" + s[j + len("                              Width: =382"):]

# 2. month view only in Month mode
rep('                  Visible: =StaffReady && tabAttViewMode.Selected.Value <> "Day"', '                  Visible: =StaffReady && tabAttViewMode.Selected.Value = "Month"')

# 3. teacher/campus change reloads the quarter counts too
rep('                    Set(varLoading, false)\n                  Text: ="load"',
    '                    Set(varLoading, false);\n                    If(tabAttViewMode.Selected.Value = "Quarters", Select(btnAttQtrEngine))\n                  Text: ="load"')

# 4. the Quarters view (after the Day view) and its engine (after the load engine)
COLS = ["Q1", "Q2", "Q3", "Q4", "ESY"]


def count_expr(t):
    return (f'With({{c: LookUp(colAttQtrCols, Term = "{t}")}}, If(c.Has, CountRows(Filter(colAttQtrAbs, StudentId = sid && D >= c.S && D <= c.E)), Blank()))')


def head_cell(t):
    return f"""                        - lblAttQtrH{t}:
                            Control: ModernText
                            Properties:
                              AccessibleLabel: =Self.Text
                              Align: =Align.Center
                              AlignInContainer: =AlignInContainer.Stretch
                              Color: =ColorMuted
                              FontWeight: =FontWeight.Semibold
                              Height: =40
                              LayoutMinHeight: =0
                              LayoutMinWidth: =0
                              PaddingBottom: =0
                              PaddingLeft: =0
                              PaddingRight: =0
                              PaddingTop: =0
                              Size: =12
                              Text: |-
                                =With({{c: LookUp(colAttQtrCols, Term = "{t}")}}, "{t}" & If(c.Has && Today() >= c.S && Today() <= c.E, " · so far", "") & Char(10) & If(c.Has, Text(c.S, "m/d/yy") & " - " & Text(c.E, "m/d/yy"), "not set"))
                              VerticalAlign: =VerticalAlign.Top
                              Width: =124
                              Wrap: =true
"""


def row_cell(t):
    return f"""                              - btnAttQtrC{t}:
                                  Control: ModernButton
                                  Properties:
                                    AccessibleLabel: ="{t} absences for " & ThisItem.Name
                                    AlignInContainer: =AlignInContainer.Center
                                    Appearance: =If(varAttQtrSel.StudentId = ThisItem.StudentId && varAttQtrSel.Term = "{t}", ButtonAppearance.Primary, ButtonAppearance.Subtle)
                                    BasePaletteColor: =ColorTeal
                                    Color: =If(varAttQtrSel.StudentId = ThisItem.StudentId && varAttQtrSel.Term = "{t}", ColorWhite, ColorInk)
                                    DisplayMode: =If(IsBlank(ThisItem.{t}), DisplayMode.Disabled, DisplayMode.Edit)
                                    Height: =36
                                    Layout: =ButtonLayout.TextOnly
                                    LayoutMinHeight: =0
                                    LayoutMinWidth: =0
                                    OnSelect: |-
                                      =Set(varAttQtrSel, {{StudentId: ThisItem.StudentId, Term: "{t}"}})
                                    Size: =14
                                    Text: =If(IsBlank(ThisItem.{t}), "-", Text(ThisItem.{t}))
                                    Width: =124
"""


view = f"""            - conAttQtrView:
                Control: GroupContainer
                Variant: AutoLayout
                Properties:
                  BorderColor: =ColorRule
                  BorderThickness: =1
                  DropShadow: =DropShadow.None
                  Fill: =ColorWhite
                  FillPortions: =0
                  Height: =16 + 44 + 8 + 36 + 8 + 40 + 8 + Min(528, Max(88, 48 * CountRows(colAttQtr))) + 8 + 40 + 16
                  LayoutAlignItems: =LayoutAlignItems.Stretch
                  LayoutDirection: =LayoutDirection.Vertical
                  LayoutGap: =8
                  LayoutMinHeight: =0
                  LayoutMinWidth: =0
                  PaddingBottom: =16
                  PaddingLeft: =16
                  PaddingRight: =16
                  PaddingTop: =16
                  RadiusBottomLeft: =6
                  RadiusBottomRight: =6
                  RadiusTopLeft: =6
                  RadiusTopRight: =6
                  Visible: =StaffReady && tabAttViewMode.Selected.Value = "Quarters"
                Children:
                  - conAttQtrHead:
                      Control: GroupContainer
                      Variant: AutoLayout
                      Properties:
                        DropShadow: =DropShadow.None
                        FillPortions: =0
                        Height: =44
                        LayoutAlignItems: =LayoutAlignItems.Center
                        LayoutDirection: =LayoutDirection.Horizontal
                        LayoutGap: =8
                        LayoutMinHeight: =0
                        LayoutMinWidth: =0
                      Children:
                        - lblAttQtrTitle:
                            Control: ModernText
                            Properties:
                              AccessibleLabel: =Self.Text
                              AlignInContainer: =AlignInContainer.Center
                              Color: =ColorInk
                              FillPortions: =1
                              FontWeight: =FontWeight.Bold
                              Height: =28
                              LayoutMinHeight: =0
                              LayoutMinWidth: =0
                              PaddingBottom: =0
                              PaddingLeft: =0
                              PaddingRight: =0
                              PaddingTop: =0
                              Size: =18
                              Text: ="Absences by quarter · " & Coalesce(varTeacher.Name, "no teacher") & " · " & Coalesce(varAttQtrYear.Name, "")
                              Wrap: =false
                        - ddAttQtrYear:
                            Control: ModernDropdown
                            Properties:
                              AccessibleLabel: ="School year"
                              AlignInContainer: =AlignInContainer.Center
                              Appearance: =Appearance.Outline
                              Color: =ColorInk
                              Default: =varAttQtrYear
                              DisplayMode: =If(varAttQtrLoading, DisplayMode.Disabled, DisplayMode.Edit)
                              Height: =36
                              ItemDisplayText: =ThisItem.Name
                              Items: =Sort('School Years', 'Start Date', SortOrder.Descending)
                              LayoutMinHeight: =0
                              LayoutMinWidth: =0
                              OnChange: =Set(varAttQtrYear, Self.Selected); Select(btnAttQtrEngine)
                              Width: =160
                        - btnAttQtrReload:
                            Control: ModernButton
                            Properties:
                              AccessibleLabel: ="Reload quarter counts"
                              AlignInContainer: =AlignInContainer.Center
                              Appearance: =ButtonAppearance.Secondary
                              Color: =ColorInk
                              DisplayMode: =If(varAttQtrLoading, DisplayMode.Disabled, DisplayMode.Edit)
                              Height: =44
                              Layout: =ButtonLayout.TextOnly
                              LayoutMinHeight: =0
                              LayoutMinWidth: =0
                              OnSelect: =Select(btnAttQtrEngine)
                              Size: =14
                              Text: =If(varAttQtrLoading, "Loading...", "Reload")
                              Width: =96
                  - lblAttQtrHelp:
                      Control: ModernText
                      Properties:
                        AccessibleLabel: =Self.Text
                        AlignInContainer: =AlignInContainer.Stretch
                        Color: =If(varAttQtrError <> "", ColorUnexcused, ColorMuted)
                        Height: =36
                        LayoutMinHeight: =0
                        LayoutMinWidth: =0
                        PaddingBottom: =0
                        PaddingLeft: =0
                        PaddingRight: =0
                        PaddingTop: =0
                        Size: =12
                        Text: |-
                          =If(varAttQtrError <> "", "Could not load the quarter counts: " & varAttQtrError, "Total days absent per quarter for report cards: excused, unexcused and not yet classified (left early counts as present). A student's whole quarter counts, including days with another teacher. Tap a number to see the dates.")
                        VerticalAlign: =VerticalAlign.Top
                        Wrap: =true
                  - conAttQtrColHead:
                      Control: GroupContainer
                      Variant: AutoLayout
                      Properties:
                        DropShadow: =DropShadow.None
                        Fill: =ColorPaper
                        FillPortions: =0
                        Height: =40
                        LayoutAlignItems: =LayoutAlignItems.Center
                        LayoutDirection: =LayoutDirection.Horizontal
                        LayoutGap: =8
                        LayoutMinHeight: =0
                        LayoutMinWidth: =0
                        PaddingLeft: =8
                        PaddingRight: =8
                      Children:
                        - lblAttQtrHName:
                            Control: ModernText
                            Properties:
                              AccessibleLabel: =Self.Text
                              AlignInContainer: =AlignInContainer.Center
                              Color: =ColorMuted
                              FillPortions: =1
                              FontWeight: =FontWeight.Semibold
                              Height: =20
                              LayoutMinHeight: =0
                              LayoutMinWidth: =0
                              PaddingBottom: =0
                              PaddingLeft: =0
                              PaddingRight: =0
                              PaddingTop: =0
                              Size: =12
                              Text: ="Student (" & CountRows(colAttQtr) & ")"
                              Wrap: =false
""" + "".join(head_cell(t) for t in COLS) + f"""                  - galAttQtr:
                      Control: Gallery
                      Variant: Vertical
                      Properties:
                        AccessibleLabel: ="Absences by quarter"
                        FillPortions: =0
                        Height: =Min(528, Max(88, 48 * CountRows(colAttQtr)))
                        Items: =Sort(colAttQtr, Name, SortOrder.Ascending)
                        LayoutMinHeight: =0
                        LayoutMinWidth: =0
                        Selectable: =false
                        TabIndex: =0
                        TemplatePadding: =0
                        TemplateSize: =48
                      Children:
                        - conAttQtrRow:
                            Control: GroupContainer
                            Variant: AutoLayout
                            Properties:
                              BorderColor: =ColorRule
                              BorderThickness: =1
                              DropShadow: =DropShadow.None
                              Fill: =If(varAttQtrSel.StudentId = ThisItem.StudentId, ColorInfoBg, ColorWhite)
                              Height: =Parent.TemplateHeight - 4
                              LayoutAlignItems: =LayoutAlignItems.Center
                              LayoutDirection: =LayoutDirection.Horizontal
                              LayoutGap: =8
                              LayoutMinHeight: =0
                              LayoutMinWidth: =0
                              PaddingLeft: =8
                              PaddingRight: =8
                              Width: =Parent.TemplateWidth - 16
                            Children:
                              - lblAttQtrName:
                                  Control: ModernText
                                  Properties:
                                    AccessibleLabel: =Self.Text
                                    AlignInContainer: =AlignInContainer.Center
                                    Color: =ColorInk
                                    FillPortions: =1
                                    FontWeight: =FontWeight.Semibold
                                    Height: =20
                                    LayoutMinHeight: =0
                                    LayoutMinWidth: =0
                                    PaddingBottom: =0
                                    PaddingLeft: =0
                                    PaddingRight: =0
                                    PaddingTop: =0
                                    Size: =14
                                    Text: =ThisItem.Name
                                    Wrap: =false
""" + "".join(row_cell(t) for t in COLS) + """                  - lblAttQtrDetail:
                      Control: ModernText
                      Properties:
                        AccessibleLabel: =Self.Text
                        AlignInContainer: =AlignInContainer.Stretch
                        Color: =ColorInk
                        Height: =40
                        LayoutMinHeight: =0
                        LayoutMinWidth: =0
                        PaddingBottom: =0
                        PaddingLeft: =0
                        PaddingRight: =0
                        PaddingTop: =0
                        Size: =13
                        Text: |-
                          =With(
                              {c: LookUp(colAttQtrCols, Term = varAttQtrSel.Term), st: LookUp(colAttQtr, StudentId = varAttQtrSel.StudentId)},
                              If(
                                  IsBlank(st) || IsBlank(c), If(CountRows(colAttQtr) = 0 && !varAttQtrLoading, "No students in this class for the chosen school year.", "Tap a number to see the dates."),
                                  With(
                                      {ds: Sort(Filter(colAttQtrAbs, StudentId = st.StudentId && D >= c.S && D <= c.E), D, SortOrder.Ascending)},
                                      st.Name & " · " & c.Term & ": " & CountRows(ds) & If(CountRows(ds) = 1, " day absent", " days absent") & If(CountRows(ds) = 0, "", " - " & Concat(ds, Text(D, "ddd mmm d"), ", "))
                                  )
                              )
                          )
                        VerticalAlign: =VerticalAlign.Top
                        Wrap: =true
"""
anchor = "            - btnAttSaveEngine:"
assert s.count(anchor) == 1
s = s.replace(anchor, view + anchor, 1)

engine = """            - btnAttQtrEngine:
                Control: Classic/Button
                Properties:
                  AlignInContainer: =AlignInContainer.Stretch
                  AutoDisableOnSelect: =false
                  LayoutMinHeight: =0
                  LayoutMinWidth: =0
                  OnSelect: |-
                    =Set(varAttQtrLoading, true);
                    Set(varAttQtrError, "");
                    Set(varAttQtrSel, {StudentId: ZeroGuid, Term: ""});
                    If(IsBlank(varAttQtrYear), Set(varAttQtrYear, CurrentSchoolYear));
                    Clear(colAttQtrAbs);
                    If(
                        !StaffReady || IsBlank(varTeacher) || IsBlank(varAttQtrYear),
                        Clear(colAttQtr); Clear(colAttQtrCols); Clear(colAttQtrEnr),
                        IfError(
                            With(
                                {yid: varAttQtrYear.'School Year', ys: varAttQtrYear.'Start Date', ye: varAttQtrYear.'End Date', cid: varCampus.Campus, tid: varTeacher.Staff},
                                ClearCollect(colAttQtrTerms, ForAll(Filter(Terms, 'School Year'.'School Year' = yid) As t, {TermText: Text(t.'Term (aaca_term)'), CampusId: If(IsBlank(t.Campus), ZeroGuid, t.Campus.Campus), S: t.'Start Date', E: t.'End Date'}));
                                ClearCollect(
                                    colAttQtrCols,
                                    ForAll(
                                        ["Q1", "Q2", "Q3", "Q4", "ESY"] As q,
                                        With(
                                            {tm: Coalesce(LookUp(colAttQtrTerms, TermText = q.Value && CampusId = cid), LookUp(colAttQtrTerms, TermText = q.Value && CampusId = ZeroGuid))},
                                            {Term: q.Value, S: tm.S, E: tm.E, Has: !IsBlank(tm)}
                                        )
                                    )
                                );
                                ClearCollect(colAttQtrEnr, ForAll(Filter(Enrollments, Teacher.Staff = tid && 'Start Date' <= ye && (IsBlank('End Date') || 'End Date' >= ys)) As e, {StudentId: e.Student.Student, Name: Coalesce(e.Student.'Display Name', "Unknown student")}));
                                ForAll(
                                    Distinct(colAttQtrEnr, StudentId) As g,
                                    Collect(colAttQtrAbs, ForAll(Filter(Attendance, Student.Student = g.Value && Present = false && 'Is Deleted' = false && Date >= ys && Date <= ye) As a, {StudentId: g.Value, D: a.Date}))
                                );
                                ClearCollect(
                                    colAttQtr,
                                    ForAll(
                                        Distinct(colAttQtrEnr, StudentId) As g,
                                        With(
                                            {sid: g.Value},
                                            {
                                                StudentId: sid,
                                                Name: LookUp(colAttQtrEnr, StudentId = sid).Name,
""" + "".join(f"                                                {t}: {count_expr(t)}{',' if t != 'ESY' else ''}\n" for t in COLS) + """                                            }
                                        )
                                    )
                                )
                            ); true,
                            Set(varAttQtrError, FirstError.Message)
                        )
                    );
                    Set(varAttQtrLoading, false)
                  Text: ="quarters"
                  Visible: =false
"""
anchor2 = "            - btnAttLoadEngine:"
assert s.count(anchor2) == 1
s = s.replace(anchor2, engine + anchor2, 1)
open(p1, "w", encoding="utf-8", newline="\n").write(s)

# 5. App OnStart seeds
a = open(p0, encoding="utf-8").read()
if "varAttQtrYear" not in a:
    old = '      Set(varAbsNtErr, "")\n'
    assert old in a
    a = a.replace(old, ('      Set(varAbsNtErr, "");\n'
                        '      Set(varAttQtrYear, CurrentSchoolYear);\n'
                        '      Set(varAttQtrSel, {StudentId: ZeroGuid, Term: ""});\n'
                        '      Set(varAttQtrLoading, false);\n'
                        '      Set(varAttQtrError, "")\n'), 1)
    open(p0, "w", encoding="utf-8", newline="\n").write(a)
print("quarters view added")
