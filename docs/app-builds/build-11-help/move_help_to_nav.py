"""Build 11 follow-up (Adam): the Ask NEXUS button sits in the nav row, far right, instead of its own row above it.

Per screen: delete btn<P>Help (header row) and undo its +36 header height; the nav row becomes visible to every role
(teachers see only the NEXUS button; the screen buttons keep office/admin visibility); a spacer (desktop only) pushes the
new btn<P>NavHelp to the far right. Idempotent.
"""
APP = r"C:\src\aaca-attendance\app"
SCREENS = [("Att", "Screen1"), ("Stu", "StudentsScreen"), ("Abs", "AbsencesScreen"), ("Trn", "TransportScreen"), ("Stf", "StaffScreen")]


def block_end(lines, start):
    ind = len(lines[start]) - len(lines[start].lstrip())
    j = start + 1
    while j < len(lines) and not (lines[j].strip() and len(lines[j]) - len(lines[j].lstrip()) <= ind):
        j += 1
    return j


def find(lines, item):
    return next(k for k, s in enumerate(lines) if s.strip() == f"- {item}:")


def prop_line(lines, item, prop):
    """Index of `prop:` directly in item's Properties (searching only inside the item, before its Children)."""
    k = find(lines, item)
    e = block_end(lines, k)
    for j in range(k + 1, e):
        if lines[j].strip() == "Children:":
            break
        if lines[j].strip().startswith(prop + ":"):
            return j
    return None


for p, screen in SCREENS:
    path = f"{APP}\\{screen}.pa.yaml"
    lines = open(path, encoding="utf-8").read().split("\n")
    if any(s.strip() == f"- btn{p}NavHelp:" for s in lines):
        print(screen, "already moved"); continue
    root = f"con{p}Root"
    # 1. remove the header-row Help button
    k = find(lines, f"btn{p}Help")
    del lines[k:block_end(lines, k)]
    # 2. header height: drop the +36 row; nav row now always shown (48 = 44 + gap for non-managers)
    h = prop_line(lines, f"con{p}Header", "Height")
    lines[h] = lines[h].replace("Height: =36 + ", "Height: =", 1).replace(
        f"If(CanManageStudents, If({root}.Width < 640, 152, 48), 0)", f"If(CanManageStudents, If({root}.Width < 640, 152, 48), 48)", 1)
    assert f"152, 48), 48)" in lines[h], (screen, lines[h])
    # 3. nav visible to all; height for non-managers = one row
    v = prop_line(lines, f"con{p}Nav", "Visible")
    lines[v] = lines[v].split("Visible:")[0] + "Visible: =true"
    hn = prop_line(lines, f"con{p}Nav", "Height")
    pre, expr = lines[hn].split("Height: =", 1)
    lines[hn] = f"{pre}Height: =If(CanManageStudents, {expr}, 44)"
    # 4. screen buttons that had no Visible: office/admin only
    for b in ("Attendance", "Students", "Absences"):
        item = f"btn{p}Nav{b}"
        if prop_line(lines, item, "Visible") is None:
            hb = prop_line(lines, item, "Height")
            ind = lines[hb][: len(lines[hb]) - len(lines[hb].lstrip())]
            lines.insert(hb + 1, f"{ind}Visible: =CanManageStudents")
    # 5. spacer + NEXUS button as the last nav children
    last = find(lines, f"btn{p}NavStaff")
    i = lines[last][: len(lines[last]) - len(lines[last].lstrip())]
    add = f"""{i}- con{p}NavSpacer:
{i}    Control: GroupContainer
{i}    Variant: AutoLayout
{i}    Properties:
{i}      DropShadow: =DropShadow.None
{i}      FillPortions: =1
{i}      Height: =44
{i}      LayoutDirection: =LayoutDirection.Horizontal
{i}      LayoutMinHeight: =0
{i}      LayoutMinWidth: =0
{i}      Visible: ={root}.Width >= 640
{i}- btn{p}NavHelp:
{i}    Control: ModernButton
{i}    Properties:
{i}      AccessibleLabel: =If(varHelpOpen, "Close NEXUS help", "Open NEXUS help")
{i}      AlignInContainer: =AlignInContainer.Center
{i}      BasePaletteColor: =ColorViolet
{i}      Color: =ColorWhite
{i}      Height: =44
{i}      Layout: =ButtonLayout.TextOnly
{i}      LayoutMinHeight: =0
{i}      LayoutMinWidth: =0
{i}      OnSelect: =Set(varHelpOpen, !varHelpOpen)
{i}      Size: =14
{i}      Text: =If(varHelpOpen, "Close NEXUS", "Ask NEXUS")
{i}      Width: =124
"""
    e = block_end(lines, last)
    lines[e:e] = add.rstrip("\n").split("\n")
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
    print(screen, "moved")
