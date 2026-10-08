"""Calendar print fix (Adam 2026-10-08): fill one landscape page, hide the toolbar via Screen.Printing.

Local to CalendarPrintScreen (+ removes the now-unused varCalPPrinting seed from App.OnStart):
- toolbar Visible = Not CalendarPrintScreen.Printing; Print button = Print(); timer + variable removed
- hint text: "Print in landscape and enable Background graphics to include calendar colors."
- at widths >= 1024 the months, day cells, important-dates list and text sizes are derived from the screen height
  available (the toolbar's space is reclaimed while printing); narrower layouts keep their previous fixed sizes.
Collections, calculations, classifications and colours are untouched. Idempotent-ish: asserts on the old values.
"""
APP = r"C:\src\aaca-attendance\app"
p = APP + r"\CalendarPrintScreen.pa.yaml"
s = open(p, encoding="utf-8").read()

W = "conCalPRoot.Width >= 1024"
# body height available on a desktop page (no reference to the galleries inside the body: avoids circular refs)
AV = ("(conCalPRoot.Height - 24 - lblCalPTitle.Height - galCalPLegend.Height - 12"
      " - If(CalendarPrintScreen.Printing, 0, conCalPToolbar.Height + 6)"
      " - If(CountRows(colCalCells) = 0, lblCalPEmpty.Height + 6, 0))")
MONTH = f"RoundDown(Max(300, {AV}) / 3, 0)"                      # month tile height (3 rows of 4)
CELL = "RoundDown((galCalPMonths.TemplateHeight - 6 - 4 - 2 - lblCalPMonthTitle.Height) / 7, 0)"
IMPROW = f"Max(14, Min(24, RoundDown(Max(300, {AV}) / Max(1, CountRows(colCalImportant)), 0)))"


def rep(old, new):
    global s
    assert s.count(old) == 1, (old[:70], s.count(old))
    s = s.replace(old, new)


# 1. toolbar / print button / timer / variable
rep("    Properties:\n      Fill: =ColorWhite\n      OnVisible: =Set(varCalPPrinting, false)\n",
    "    Properties:\n      Fill: =ColorWhite\n")
rep("                  Visible: =!varCalPPrinting\n", "                  Visible: =Not(CalendarPrintScreen.Printing)\n")
rep("                        OnSelect: =Set(varCalPPrinting, true); Print()\n", "                        OnSelect: =Print()\n")
i = s.index("            - tmrCalPPrint:")
j = s.index("            - lblCalPTitle:")
s = s[:i] + s[j:]
rep('Text: ="In the print dialog choose Landscape, then a printer or Save as PDF."',
    'Text: ="Print in landscape and enable Background graphics to include calendar colors."')

# 2. title and legend a little larger on desktop
rep("                  Height: =30\n", f"                  Height: =If({W}, 36, 30)\n")
rep("                  Size: =20\n                  Text: =LookUp(colCalYearOpts", f"                  Size: =If({W}, 24, 20)\n                  Text: =LookUp(colCalYearOpts")
rep("WrapCount: =If(conCalPRoot.Width >= 1024, 8, conCalPRoot.Width >= 640, 4, 2)\n",
    "WrapCount: =If(conCalPRoot.Width >= 1024, 8, conCalPRoot.Width >= 640, 4, 2)\n")
rep("* 22\n                  Items: =CalLegend", f"* If({W}, 26, 22)\n                  Items: =CalLegend")
rep("                  TemplateSize: =22\n", f"                  TemplateSize: =If({W}, 26, 22)\n")
rep("                        Size: =If(conCalPRoot.Width < 640, 11, 9)\n                        Text: =ThisItem.Txt",
    f"                        Size: =If({W}, 11, conCalPRoot.Width < 640, 11, 9)\n                        Text: =ThisItem.Txt")

# 3. body + months fill the page height on desktop
rep("Height: =If(conCalPRoot.Width >= 1024, Max(galCalPMonths.Height, galCalPImp.Height), galCalPMonths.Height + 8 + galCalPImp.Height)",
    f"Height: =If({W}, Max(300, {AV}), galCalPMonths.Height + 8 + galCalPImp.Height)")
rep("Height: =RoundUp(CountRows(colCalMonths) / If(conCalPRoot.Width >= 1024, 4, conCalPRoot.Width >= 640, 3, 1), 0) * If(conCalPRoot.Width < 640, 240, 156)",
    f"Height: =If({W}, 3 * {MONTH}, RoundUp(CountRows(colCalMonths) / If(conCalPRoot.Width >= 640, 3, 1), 0) * If(conCalPRoot.Width < 640, 240, 156))")
rep("TemplateSize: =If(conCalPRoot.Width < 640, 240, 156)",
    f"TemplateSize: =If({W}, {MONTH}, conCalPRoot.Width < 640, 240, 156)")
# month band scales with the tile
rep("                                    Height: =18\n", f"                                    Height: =If({W}, Max(18, RoundDown(galCalPMonths.TemplateHeight * 0.11, 0)), 18)\n")
rep("                                    Size: =If(conCalPRoot.Width < 640, 12, 10)\n",
    f"                                    Size: =If({W}, Max(10, Min(16, RoundDown(Self.Height * 0.55, 0))), conCalPRoot.Width < 640, 12, 10)\n")
# day cells fill the rest of the tile
rep("                                    Height: =7 * If(conCalPRoot.Width < 640, 30, 18)\n",
    f"                                    Height: =7 * If({W}, {CELL}, conCalPRoot.Width < 640, 30, 18)\n")
rep("                                    TemplateSize: =If(conCalPRoot.Width < 640, 30, 18)\n",
    f"                                    TemplateSize: =If({W}, {CELL}, conCalPRoot.Width < 640, 30, 18)\n")
rep("                                          Size: =If(conCalPRoot.Width < 640, 12, 9)\n",
    f"                                          Size: =If({W}, Max(9, Min(18, RoundDown(Min(Parent.TemplateHeight, Parent.TemplateWidth) * 0.45, 0))), conCalPRoot.Width < 640, 12, 9)\n")

# 4. important dates: taller rows, wider column, larger text on desktop
rep("Height: =CountRows(colCalImportant) * If(conCalPRoot.Width < 640, 22, 15)",
    f"Height: =CountRows(colCalImportant) * If({W}, {IMPROW}, conCalPRoot.Width < 640, 22, 15)")
rep("TemplateSize: =If(conCalPRoot.Width < 640, 22, 15)",
    f"TemplateSize: =If({W}, {IMPROW}, conCalPRoot.Width < 640, 22, 15)")
rep("                        Width: =300\n", f"                        Width: =If({W}, Max(280, RoundDown(conCalPRoot.Width * 0.24, 0)), 300)\n")
rep("Size: =If(ThisItem.IsHead, If(conCalPRoot.Width < 640, 13, 10), If(conCalPRoot.Width < 640, 12, 9))",
    f"Size: =If({W}, Max(9, Min(13, RoundDown(Parent.TemplateHeight * If(ThisItem.IsHead, 0.62, 0.55), 0))), If(ThisItem.IsHead, If(conCalPRoot.Width < 640, 13, 10), If(conCalPRoot.Width < 640, 12, 9)))")
open(p, "w", encoding="utf-8", newline="\n").write(s)

# 5. App: drop the unused seed
a = open(APP + r"\App.pa.yaml", encoding="utf-8").read()
seed = "      Set(varCalPPrinting, false);\n"
if seed in a:
    a = a.replace(seed, "", 1)
    open(APP + r"\App.pa.yaml", "w", encoding="utf-8", newline="\n").write(a)
print("print screen updated")

# Second pass (2026-10-08, after Adam's first print test): deriving sizes from the live screen height made Print()
# re-measure and shrink the calendar on every print. The desktop layout is now a fixed Letter-landscape frame:
# conCalPRoot Width =If(Parent.Width >= 1024, 1056, Parent.Width), Height =If(Parent.Width >= 1024,
# 816 + If(CalendarPrintScreen.Printing, 0, conCalPToolbar.Height + 6), Parent.Height); every AV expression above is
# replaced by the constant 718 (816 - 24 padding - 36 title - 26 legend - 12 gaps) and the side list is 260 wide.
