"""Build 11 follow-up (Adam): the NEXUS logo replaces the violet "Ask NEXUS" button in the nav row.

App.Formulas gets NexusLogo (88 px PNG as a data URI, from nexus-logo-88.png next to this script); on every screen
btn<P>NavHelp is replaced by img<P>NavHelp: a 44 x 44 rounded image, violet ring while the help panel is open.
Idempotent.
"""
import base64
import os

HERE = os.path.dirname(os.path.abspath(__file__))
APP = r"C:\src\aaca-attendance\app"
SCREENS = [("Att", "Screen1"), ("Stu", "StudentsScreen"), ("Abs", "AbsencesScreen"), ("Trn", "TransportScreen"), ("Stf", "StaffScreen")]


def block_end(lines, start):
    ind = len(lines[start]) - len(lines[start].lstrip())
    j = start + 1
    while j < len(lines) and not (lines[j].strip() and len(lines[j]) - len(lines[j].lstrip()) <= ind):
        j += 1
    return j


# 1. App formula
app = os.path.join(APP, "App.pa.yaml")
s = open(app, encoding="utf-8").read()
if "NexusLogo =" not in s:
    uri = "data:image/png;base64," + base64.b64encode(open(os.path.join(HERE, "nexus-logo-88.png"), "rb").read()).decode()
    anchor = "      // ---------- NEXUS help panel (build 11) ----------\n"
    assert anchor in s
    s = s.replace(anchor, anchor + f'      NexusLogo = "{uri}";\n', 1)
    open(app, "w", encoding="utf-8", newline="\n").write(s)
    print("App: NexusLogo added")

# 2. screens
for p, screen in SCREENS:
    path = os.path.join(APP, f"{screen}.pa.yaml")
    lines = open(path, encoding="utf-8").read().split("\n")
    if any(x.strip() == f"- img{p}NavHelp:" for x in lines):
        print(screen, "already uses the logo"); continue
    k = next(n for n, x in enumerate(lines) if x.strip() == f"- btn{p}NavHelp:")
    i = lines[k][: len(lines[k]) - len(lines[k].lstrip())]
    img = f"""{i}- img{p}NavHelp:
{i}    Control: Image
{i}    Properties:
{i}      AccessibleLabel: =If(varHelpOpen, "Close NEXUS help", "Open NEXUS help")
{i}      AlignInContainer: =AlignInContainer.Center
{i}      BorderColor: =ColorViolet
{i}      BorderThickness: =If(varHelpOpen, 3, 0)
{i}      FocusedBorderThickness: =3
{i}      Height: =44
{i}      HoverBorderColor: =ColorCyan
{i}      Image: =NexusLogo
{i}      ImagePosition: =ImagePosition.Fit
{i}      LayoutMinHeight: =0
{i}      LayoutMinWidth: =0
{i}      OnSelect: =Set(varHelpOpen, !varHelpOpen)
{i}      RadiusBottomLeft: =10
{i}      RadiusBottomRight: =10
{i}      RadiusTopLeft: =10
{i}      RadiusTopRight: =10
{i}      TabIndex: =0
{i}      Tooltip: =If(varHelpOpen, "Close NEXUS help", "Ask NEXUS for help")
{i}      Width: =44"""
    lines[k:block_end(lines, k)] = img.split("\n")
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
    print(screen, "logo button")
