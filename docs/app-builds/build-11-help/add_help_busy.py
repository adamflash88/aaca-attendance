"""Build 11 follow-up (Adam): show progress while NEXUS answers, and set expectations about the delay.

Per screen, inside con<P>Help: a spinner row (spn<P>HelpBusy, visible while varHelpBusy) after the panel header, and a
small always-on note (lbl<P>HelpNote) after the question row. Idempotent.
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


for p, screen in SCREENS:
    path = f"{APP}\\{screen}.pa.yaml"
    lines = open(path, encoding="utf-8").read().split("\n")
    if any(s.strip() == f"- spn{p}HelpBusy:" for s in lines):
        print(screen, "already has it"); continue
    root = f"con{p}Root"
    # note after the question row
    k = find(lines, f"con{p}HelpAsk")
    i = lines[k][: len(lines[k]) - len(lines[k].lstrip())]
    note = f"""{i}- lbl{p}HelpNote:
{i}    Control: ModernText
{i}    Properties:
{i}      AccessibleLabel: =Self.Text
{i}      AlignInContainer: =AlignInContainer.Stretch
{i}      Color: =ColorMuted
{i}      FillPortions: =0
{i}      Height: =If({root}.Width < 640, 52, 20)
{i}      LayoutMinHeight: =0
{i}      LayoutMinWidth: =0
{i}      PaddingBottom: =0
{i}      PaddingLeft: =0
{i}      PaddingRight: =0
{i}      PaddingTop: =0
{i}      Size: =12
{i}      Text: ="NEXUS answers from the AACA Resource Center and the Attendance user guide. Answers usually take 10-30 seconds. Check important details with your office."
{i}      VerticalAlign: =VerticalAlign.Top
{i}      Wrap: =true"""
    e = block_end(lines, k)
    lines[e:e] = note.split("\n")
    # spinner after the panel header
    k = find(lines, f"con{p}HelpHead")
    spin = f"""{i}- spn{p}HelpBusy:
{i}    Control: Spinner
{i}    Properties:
{i}      AccessibleLabel: ="NEXUS is looking up your answer"
{i}      AlignInContainer: =AlignInContainer.Stretch
{i}      FillPortions: =0
{i}      FontColor: =ColorInk
{i}      FontSize: =13
{i}      Height: =32
{i}      Label: ="NEXUS is looking that up... answers usually take 10-30 seconds."
{i}      LabelPosition: ='Spinner.LabelPosition'.After
{i}      LayoutMinHeight: =0
{i}      LayoutMinWidth: =0
{i}      SpinnerColor: =ColorViolet
{i}      SpinnerSize: ='Spinner.SpinnerSize'.Small
{i}      TrackColor: =ColorInfoBg
{i}      Visible: =varHelpBusy"""
    e = block_end(lines, k)
    lines[e:e] = spin.split("\n")
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
    print(screen, "busy indicator added")
