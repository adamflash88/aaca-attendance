"""Phase 2 follow-up (Adam 2026-10-08): richer Classify rows on the Absences screen.

Each absence row gets: the parent's reason on its own bold line; a report summary ("absent Fri Nov 20 - back Mon Nov 30
- 1 school day missed (Nov 20)"); and "Select all days in this report" to tick every day of the same notice.
colAbsNtDays (built by btnAbsLoadEngine) holds per-notice school-day counts and dates. Idempotent.
"""
P = r"C:\src\aaca-attendance\app\AbsencesScreen.pa.yaml"
s = open(P, encoding="utf-8").read()
if "lblAbsNtReasonV:" in s:
    raise SystemExit("already applied")

# 1. loader: notice id + dates on colAbsList rows (the colAbsList block is the one followed by the record close)
old = ("NtReason: Coalesce(r.'Absence Notice'.'Reason Text', \"\"), NtAt: r.'Absence Notice'.'Notice At'\n"
       "                                        }")
assert s.count(old) == 1, s.count(old)
s = s.replace(old, ("NtReason: Coalesce(r.'Absence Notice'.'Reason Text', \"\"), NtAt: r.'Absence Notice'.'Notice At',\n"
                    "                                            NtId: If(IsBlank(r.'Absence Notice'), ZeroGuid, r.'Absence Notice'.'Absence Notice'), "
                    "NtFirst: r.'Absence Notice'.'First Day Absent', NtReturn: r.'Absence Notice'.'Return Date'\n"
                    "                                        }"), 1)

# 2. per-report school days
old2 = "                    );\n                    Set(varAbsLoading, false)\n                  Text: =\"load\""
assert s.count(old2) == 1, s.count(old2)
new2 = """                    );
                    IfError(
                        ClearCollect(
                            colAbsNtDays,
                            ForAll(
                                Distinct(Filter(colAbsList, NtId <> ZeroGuid), NtId) As g,
                                With(
                                    {days: Sort(Filter(Attendance, 'Absence Notice'.'Absence Notice' = g.Value && 'Is Deleted' = false && Present = false), Date, SortOrder.Ascending)},
                                    {NtId: g.Value, N: CountRows(days), Dates: Concat(days, Text(Date, "mmm d"), ", ")}
                                )
                            )
                        ); true,
                        Set(varAbsLoadError, "Report day counts could not be loaded (" & FirstError.Message & ")")
                    );
                    Set(varAbsLoading, false)
                  Text: ="load\""""
s = s.replace(old2, new2, 1)

# 3. row height (+18 reason line, +24 report line, +2 gaps)
old3 = "TemplateSize: =If(conAbsRoot.Width < 640, 268, 170)"
assert s.count(old3) == 1
s = s.replace(old3, "TemplateSize: =If(conAbsRoot.Width < 640, 376, 220)", 1)

# 4. source line no longer carries the reason (it has its own line)
i = s.index("- lblAbsRowSrcV:")
old4 = (' & If(ThisItem.NtReason = "", "", " · " & If(Len(ThisItem.NtReason) > 80, Left(ThisItem.NtReason, 80) & "...", ThisItem.NtReason))')
j = s.index(old4, i)
assert j - i < 3000
s = s[:j] + s[j + len(old4):]

# 5. reason line + report line (with select-all) after lblAbsRowSrcV
k = s.index("                                          - conAbsRowBottomV:", i)
ins = """                                          - lblAbsNtReasonV:
                                              Control: ModernText
                                              Properties:
                                                AccessibleLabel: =Self.Text
                                                AlignInContainer: =AlignInContainer.Stretch
                                                Color: =ColorInk
                                                FontWeight: =FontWeight.Semibold
                                                Height: =If(conAbsRoot.Width < 640, 36, 18)
                                                LayoutMinHeight: =0
                                                LayoutMinWidth: =0
                                                PaddingBottom: =0
                                                PaddingLeft: =0
                                                PaddingRight: =0
                                                PaddingTop: =0
                                                Size: =12
                                                Text: |-
                                                  =With({r: Coalesce(ThisItem.NtReason, ThisItem.ParentReason, "")}, If(r = "", "Reason: none given", "Reason: " & If(Len(r) > 160, Left(r, 160) & "...", r)))
                                                VerticalAlign: =VerticalAlign.Top
                                                Wrap: =conAbsRoot.Width < 640
                                          - conAbsNtSpanRowV:
                                              Control: GroupContainer
                                              Variant: AutoLayout
                                              Properties:
                                                DropShadow: =DropShadow.None
                                                FillPortions: =0
                                                Height: =If(conAbsRoot.Width < 640, 64, 24)
                                                LayoutAlignItems: =LayoutAlignItems.Center
                                                LayoutDirection: =If(conAbsRoot.Width < 640, LayoutDirection.Vertical, LayoutDirection.Horizontal)
                                                LayoutGap: =4
                                                LayoutMinHeight: =0
                                                LayoutMinWidth: =0
                                                Visible: =ThisItem.NtId <> ZeroGuid
                                              Children:
                                                - lblAbsNtSpanV:
                                                    Control: ModernText
                                                    Properties:
                                                      AccessibleLabel: =Self.Text
                                                      AlignInContainer: =AlignInContainer.Stretch
                                                      Color: =ColorMuted
                                                      FillPortions: =1
                                                      Height: =If(conAbsRoot.Width < 640, 36, 20)
                                                      LayoutMinHeight: =0
                                                      LayoutMinWidth: =0
                                                      PaddingBottom: =0
                                                      PaddingLeft: =0
                                                      PaddingRight: =0
                                                      PaddingTop: =0
                                                      Size: =12
                                                      Text: |-
                                                        =With(
                                                            {d: LookUp(colAbsNtDays, NtId = ThisItem.NtId)},
                                                            "Report: absent " & Text(ThisItem.NtFirst, "ddd mmm d") &
                                                            If(IsBlank(ThisItem.NtReturn), "", " - back " & Text(ThisItem.NtReturn, "ddd mmm d")) &
                                                            If(IsBlank(d), "", " · " & d.N & If(d.N = 1, " school day", " school days") & " missed (" & d.Dates & ")")
                                                        )
                                                      VerticalAlign: =VerticalAlign.Top
                                                      Wrap: =conAbsRoot.Width < 640
                                                - btnAbsNtSelAllV:
                                                    Control: ModernButton
                                                    Properties:
                                                      AccessibleLabel: ="Tick every day of this report"
                                                      AlignInContainer: =AlignInContainer.Center
                                                      Appearance: =ButtonAppearance.Subtle
                                                      Color: =ColorTeal
                                                      DisplayMode: =If(varAbsSaving || ThisItem.Locked, DisplayMode.Disabled, DisplayMode.Edit)
                                                      Height: =24
                                                      Layout: =ButtonLayout.TextOnly
                                                      LayoutMinHeight: =0
                                                      LayoutMinWidth: =0
                                                      OnSelect: |-
                                                        =ForAll(
                                                            Filter(colAbsList, NtId = ThisItem.NtId && !Locked) As d,
                                                            If(IsBlank(LookUp(colAbsTicked, AttId = d.AttId)), Collect(colAbsTicked, {AttId: d.AttId}))
                                                        )
                                                      Size: =12
                                                      Text: ="Select all days in this report"
                                                      Width: =210
"""
s = s[:k] + ins + s[k:]
open(P, "w", encoding="utf-8", newline="\n").write(s)
print("applied")
