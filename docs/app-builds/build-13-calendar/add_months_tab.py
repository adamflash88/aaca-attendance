"""Calendar screen: "Months" tab (Adam 2026-10-08) - student days per month, RSY and ESY totals vs targets.

Student day = colCalYearDays.Open (weekday not Holiday/Break/Closed/Inclement Weather/Work Only, or a Make-up day)
inside Q1-Q4 (RSY) or ESY. Counts use colCalPerEdit, so they follow the Periods tab as it is edited (before saving);
day edits count once saved. Targets: App Settings CalRsyTargetDays / CalEsyTargetDays (default 180 / 29).
Also adds the totals to Check calendar (using the saved periods). Idempotent.
"""
APP = r"C:\src\aaca-attendance\app"
p = APP + r"\CalendarScreen.pa.yaml"
s = open(p, encoding="utf-8").read()
if "conCalMonthsPanel:" in s:
    raise SystemExit("already applied")


def rep(old, new):
    global s
    assert s.count(old) == 1, (old[:80], s.count(old))
    s = s.replace(old, new)


rep('Visible: =!(varCalPanel in ["Periods", "New year", "Copy"])', 'Visible: =!(varCalPanel in ["Periods", "New year", "Copy", "Months"])')
rep('Items: =["Days", "Periods", "New year", "Copy"]', 'Items: =["Days", "Periods", "New year", "Copy", "Months"]')
rep('Switch(varCalPanel, "Periods", conCalPerPanel.Height, "New year", conCalNewPanel.Height, "Copy", conCalCopyPanel.Height, conCalDaysPanel.Height)',
    'Switch(varCalPanel, "Periods", conCalPerPanel.Height, "New year", conCalNewPanel.Height, "Copy", conCalCopyPanel.Height, "Months", conCalMonthsPanel.Height, conCalDaysPanel.Height)')

ITEMS = """=With(
                                              {rs: Filter(colCalPerEdit, TermText in ["Q1", "Q2", "Q3", "Q4"] && !IsBlank(S) && !IsBlank(E)), es: Filter(colCalPerEdit, TermText = "ESY" && !IsBlank(S) && !IsBlank(E))},
                                              ForAll(
                                                  colCalMonths As m,
                                                  With(
                                                      {days: Filter(colCalYearDays, Open && D >= m.MonthStart && D <= DateAdd(DateAdd(m.MonthStart, 1, TimeUnit.Months), -1, TimeUnit.Days))},
                                                      {
                                                          Title: m.Title,
                                                          MonthStart: m.MonthStart,
                                                          Rsy: CountRows(Filter(days As dd, CountRows(Filter(rs As r, dd.D >= r.S && dd.D <= r.E)) > 0)),
                                                          Esy: CountRows(Filter(days As dd, CountRows(Filter(es As r, dd.D >= r.S && dd.D <= r.E)) > 0))
                                                      }
                                                  )
                                              )
                                          )"""


def txt(name, text, h, size=12, bold=False, color="ColorInk", fill=None, fillp=1, align=None, wrap=False, extra=""):
    lines = [f"- {name}:", "    Control: ModernText", "    Properties:", "      AccessibleLabel: =Self.Text"]
    if align:
        lines.append(f"      Align: =Align.{align}")
    lines += ["      AlignInContainer: =AlignInContainer.Stretch", f"      Color: ={color}"]
    if fill:
        lines.append(f"      Fill: ={fill}")
    lines.append(f"      FillPortions: ={fillp}")
    if bold:
        lines.append("      FontWeight: =FontWeight.Bold")
    lines += [f"      Height: ={h}", "      LayoutMinHeight: =0", "      LayoutMinWidth: =0",
              "      PaddingBottom: =0", f"      PaddingLeft: ={'8' if fill else '0'}", "      PaddingRight: =0", "      PaddingTop: =0",
              f"      Size: ={size}"]
    if "\n" in text:
        lines.append("      Text: |-")
        lines += ["        " + t for t in text.split("\n")]
    else:
        lines.append(f"      Text: ={text}")
    if extra:
        lines += ["      " + e for e in extra.split("\n")]
    lines += ["      VerticalAlign: =VerticalAlign.Middle", f"      Wrap: ={'true' if wrap else 'false'}"]
    return lines


def row(name, h, children, fill=None, width=None):
    lines = [f"- {name}:", "    Control: GroupContainer", "    Variant: AutoLayout", "    Properties:", "      DropShadow: =DropShadow.None"]
    if fill:
        lines.append(f"      Fill: ={fill}")
    lines += ["      FillPortions: =0", f"      Height: ={h}", "      LayoutAlignItems: =LayoutAlignItems.Center",
              "      LayoutDirection: =LayoutDirection.Horizontal", "      LayoutGap: =8", "      LayoutMinHeight: =0", "      LayoutMinWidth: =0",
              ] + ([f"      Width: ={width}"] if width else []) + ["    Children:"]
    for c in children:
        lines += ["      " + x for x in c]
    return lines


def flag(name, label, total, target):
    t = (f'With({{n: {total}, g: {target}}}, "{label}: " & n & " student days - " & '
         f'If(n = g, "on target (" & g & ").", n < g, (g - n) & " under the " & g & "-day target.", (n - g) & " over the " & g & "-day target."))')
    return txt(name, t, 36, 13, True, color=f"With({{n: {total}, g: {target}}}, If(n = g, ColorExcused, ColorUnexcused))",
               fill=f"With({{n: {total}, g: {target}}}, If(n = g, ColorInfoBg, ColorErrorBg))", wrap=True)


RSY = "Sum(galCalMoCount.AllItems, Rsy)"
ESY = "Sum(galCalMoCount.AllItems, Esy)"
gallery = ["- galCalMoCount:", "    Control: Gallery", "    Variant: Vertical", "    Properties:",
           '      AccessibleLabel: ="Student days by month"', "      FillPortions: =0",
           "      Height: =CountRows(colCalMonths) * 26", "      Items: |-", "        " + ITEMS.replace("\n", "\n" + " " * 8 if False else "\n"),
           "      LayoutMinHeight: =0", "      LayoutMinWidth: =0", "      LoadingSpinner: =LoadingSpinner.None",
           "      Selectable: =false", "      ShowScrollbar: =false", "      TemplatePadding: =0", "      TemplateSize: =26",
           "    Children:"]
cell_row = row("conCalMoRow", "Parent.TemplateHeight", width="Parent.TemplateWidth", children=[
    txt("lblCalMoName", "ThisItem.Title", 24, 12),
    txt("lblCalMoRsy", 'If(ThisItem.Rsy = 0, "-", Text(ThisItem.Rsy))', 24, 12, align="Center", fillp=0, extra="Width: =64"),
    txt("lblCalMoEsy", 'If(ThisItem.Esy = 0, "-", Text(ThisItem.Esy))', 24, 12, align="Center", fillp=0, extra="Width: =64"),
])
gallery += ["      " + x for x in cell_row]

children = []
children.append(txt("lblCalMoTitle", '"School days by month"', 24, 16, True))
children.append(txt("lblCalMoHelp",
                    '"Student days: weekdays inside Q1-Q4 (RSY) or ESY, minus holidays, breaks, closures, inclement weather and staff development; make-up days count. Follows the Periods tab as you edit; day changes count once saved."',
                    48, 11, color="ColorMuted", wrap=True))
children.append(row("conCalMoHead", 24, [
    txt("lblCalMoHMonth", '"Month"', 20, 12, True, color="ColorMuted"),
    txt("lblCalMoHRsy", '"RSY"', 20, 12, True, color="ColorMuted", align="Center", fillp=0, extra="Width: =64"),
    txt("lblCalMoHEsy", '"ESY"', 20, 12, True, color="ColorMuted", align="Center", fillp=0, extra="Width: =64"),
], fill="ColorPaper"))
children.append(gallery)
children.append(row("conCalMoTot", 28, [
    txt("lblCalMoTotLabel", '"Total"', 24, 13, True),
    txt("lblCalMoTotRsy", f"Text({RSY})", 24, 13, True, align="Center", fillp=0, extra="Width: =64"),
    txt("lblCalMoTotEsy", f"Text({ESY})", 24, 13, True, align="Center", fillp=0, extra="Width: =64"),
], fill="ColorPaper"))
children.append(flag("lblCalMoRsyFlag", "RSY", RSY, "CalRsyTarget"))
children.append(flag("lblCalMoEsyFlag", "ESY", ESY, "CalEsyTarget"))

panel = ["- conCalMonthsPanel:", "    Control: GroupContainer", "    Variant: AutoLayout", "    Properties:",
         "      BorderColor: =ColorRule", "      BorderThickness: =1", "      DropShadow: =DropShadow.None", "      Fill: =ColorWhite",
         "      FillPortions: =0",
         "      Height: =32 + 24 + 4 + 48 + 4 + 24 + 4 + CountRows(colCalMonths) * 26 + 4 + 28 + 4 + 36 + 4 + 36",
         "      LayoutAlignItems: =LayoutAlignItems.Stretch", "      LayoutDirection: =LayoutDirection.Vertical", "      LayoutGap: =4",
         "      LayoutMinHeight: =0", "      LayoutMinWidth: =0",
         "      PaddingBottom: =16", "      PaddingLeft: =16", "      PaddingRight: =16", "      PaddingTop: =16",
         "      RadiusBottomLeft: =6", "      RadiusBottomRight: =6", "      RadiusTopLeft: =6", "      RadiusTopRight: =6",
         '      Visible: =varCalPanel = "Months"', "    Children:"]
for c in children:
    panel += ["      " + x for x in c]

# insert after the Copy panel (last child of conCalSide)
L = s.split("\n")
k = next(i for i, x in enumerate(L) if x.strip() == "- conCalCopyPanel:")
ind = len(L[k]) - len(L[k].lstrip())
j = k + 1
while j < len(L) and not (L[j].strip() and len(L[j]) - len(L[j].lstrip()) <= ind):
    j += 1
L[j:j] = [" " * ind + x if x else x for x in panel]
s = "\n".join(L)

# Check calendar: RSY / ESY totals against the targets (saved periods)
anchor = '                        If(CountRows(colCalChecks) = 0, Collect(colCalChecks, {Sev: "ok"'
assert s.count(anchor) == 1
chk = """                        With(
                            {rs: Filter(colCalTermsEff, Has && TermText in ["Q1", "Q2", "Q3", "Q4"]), es: Filter(colCalTermsEff, Has && TermText = "ESY")},
                            With(
                                {nR: CountRows(Filter(colCalYearDays As dd, dd.Open && CountRows(Filter(rs As r, dd.D >= r.S && dd.D <= r.E)) > 0)), nE: CountRows(Filter(colCalYearDays As dd, dd.Open && CountRows(Filter(es As r, dd.D >= r.S && dd.D <= r.E)) > 0))},
                                If(nR <> CalRsyTarget, Collect(colCalChecks, {Sev: "warn", Line: "RSY has " & nR & " student days; the target is " & CalRsyTarget & " (" & If(nR < CalRsyTarget, (CalRsyTarget - nR) & " under", (nR - CalRsyTarget) & " over") & ")."}));
                                If(nE <> CalEsyTarget, Collect(colCalChecks, {Sev: "warn", Line: "ESY has " & nE & " student days; the target is " & CalEsyTarget & " (" & If(nE < CalEsyTarget, (CalEsyTarget - nE) & " under", (nE - CalEsyTarget) & " over") & ")."}))
                            )
                        );
"""
s = s.replace(anchor, chk + anchor, 1)
open(p, "w", encoding="utf-8", newline="\n").write(s)

# App: targets from App Settings (defaults 180 / 29)
ap = APP + r"\App.pa.yaml"
a = open(ap, encoding="utf-8").read()
if "CalRsyTarget" not in a:
    anchor = "      CalLegend = "
    i = a.index(anchor)
    a = a[:i] + ('      CalRsyTarget = Coalesce(IfError(Value(LookUp(\'App Settings\', Key = "CalRsyTargetDays").Value), Blank()), 180);   // RSY student days required\n'
                 '      CalEsyTarget = Coalesce(IfError(Value(LookUp(\'App Settings\', Key = "CalEsyTargetDays").Value), Blank()), 29);    // ESY student days required\n') + a[i:]
    open(ap, "w", encoding="utf-8", newline="\n").write(a)
print("months tab added")
