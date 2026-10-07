"""Build 11: adds the NEXUS Help button + panel to every attendance screen (idempotent).

- Header: new button btn<P>Help after lbl<P>Identity (header Height + 36).
- Root: new panel con<P>Help right after con<P>Header (visible when varHelpOpen); shared state lives in App
  (varHelpOpen, varHelpBusy, varHelpConvId, colHelpMsgs {N, Q, A}) so the conversation follows the user across screens.
- Questions go to the "AACA - Ask NEXUS" flow (flows/build_help_flow.py), which asks the Resource Center agent.
Newest question/answer pair is shown first, so a new answer is always visible without scrolling.
"""
import re
import sys

APP = r"C:\src\aaca-attendance\app"
SCREENS = [("Att", "Screen1", "Attendance"), ("Stu", "StudentsScreen", "Students"), ("Abs", "AbsencesScreen", "Absences"),
           ("Trn", "TransportScreen", "Transportation"), ("Stf", "StaffScreen", "Staff")]
FLOW = sys.argv[1] if len(sys.argv) > 1 else "'AACA-AskNEXUS'"

ESC = 'Substitute(Substitute(Substitute(Substitute(Substitute({x}, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"), "**", ""), Char(10), "<br>")'
CHAT = ('Concat(Sort(colHelpMsgs, N, SortOrder.Descending), '
        '"<div style=\'margin:4px 0 4px 48px;padding:8px 12px;background:#2563EB;color:#FFFFFF;border-radius:12px 12px 2px 12px\'>" & '
        + ESC.format(x="Q") + ' & "</div>" & If(A = "", '
        '"<div style=\'margin:4px 48px 14px 0;padding:8px 12px;color:#4E5876\'><i>NEXUS is thinking...</i></div>", '
        '"<div style=\'margin:4px 48px 14px 0;padding:8px 12px;background:#FFFFFF;border:1px solid #D5DCEC;border-left:4px solid #7C3AED;color:#0F163A;border-radius:12px 12px 12px 2px\'><b style=\'color:#7C3AED\'>NEXUS</b><br>" & '
        + ESC.format(x="A") + ' & "</div>"))')
INTRO = ('"<div style=\'color:#4E5876;padding:4px\'>Hi, I am <b style=\'color:#7C3AED\'>NEXUS</b>. Ask me how to do something in the '
         'AACA Attendance app, or what a button, mark or color means. For example: <i>How do I classify an absence?</i> or '
         '<i>What does 1* mean?</i></div>"')


def button(p, ind):
    i = " " * ind
    return f"""{i}- btn{p}Help:
{i}    Control: ModernButton
{i}    Properties:
{i}      AccessibleLabel: =If(varHelpOpen, "Close NEXUS help", "Open NEXUS help")
{i}      AlignInContainer: =AlignInContainer.Start
{i}      BasePaletteColor: =ColorViolet
{i}      Color: =ColorWhite
{i}      Height: =32
{i}      Layout: =ButtonLayout.TextOnly
{i}      LayoutMinHeight: =0
{i}      LayoutMinWidth: =0
{i}      OnSelect: =Set(varHelpOpen, !varHelpOpen)
{i}      Size: =13
{i}      Text: =If(varHelpOpen, "Close help", "Ask NEXUS for help")
{i}      Width: =170
"""


def panel(p, screen, label, ind):
    i = " " * ind
    root = f"con{p}Root"
    ask = f"""=With({{q: Trim(txt{p}HelpQ.Text), n: CountRows(colHelpMsgs) + 1}},
    If(q <> "" && !varHelpBusy,
        Set(varHelpBusy, true);
        Collect(colHelpMsgs, {{N: n, Q: q, A: ""}});
        Reset(txt{p}HelpQ);
        With({{r: IfError({FLOW}.Run(q, {{ConversationId: Coalesce(varHelpConvId, ""), Context: HelpContextPrefix & " The user is on the {label} screen."}}), {{answer: "NEXUS could not answer right now. Please try again in a moment.", conversationid: Coalesce(varHelpConvId, ""), ok: "false"}})}},
            Patch(colHelpMsgs, LookUp(colHelpMsgs, N = n), {{A: Coalesce(r.answer, "NEXUS did not return an answer. Please try again.")}});
            If(r.ok = "true" && !IsBlank(r.conversationid), Set(varHelpConvId, r.conversationid))
        );
        Set(varHelpBusy, false)
    )
)"""
    ask = ask.replace("\n", "\n" + i + " " * 20)   # block scalar body sits 20 spaces in from the panel item
    return f"""{i}- con{p}Help:
{i}    Control: GroupContainer
{i}    Variant: AutoLayout
{i}    Properties:
{i}      BorderColor: =ColorViolet
{i}      BorderThickness: =1
{i}      DropShadow: =DropShadow.None
{i}      Fill: =ColorWhite
{i}      FillPortions: =0
{i}      Height: =If({root}.Width < 640, 460, 400)
{i}      LayoutAlignItems: =LayoutAlignItems.Stretch
{i}      LayoutDirection: =LayoutDirection.Vertical
{i}      LayoutGap: =8
{i}      LayoutMinHeight: =0
{i}      LayoutMinWidth: =0
{i}      PaddingBottom: =12
{i}      PaddingLeft: =12
{i}      PaddingRight: =12
{i}      PaddingTop: =12
{i}      RadiusBottomLeft: =6
{i}      RadiusBottomRight: =6
{i}      RadiusTopLeft: =6
{i}      RadiusTopRight: =6
{i}      Visible: =varHelpOpen
{i}    Children:
{i}      - con{p}HelpHead:
{i}          Control: GroupContainer
{i}          Variant: AutoLayout
{i}          Properties:
{i}            DropShadow: =DropShadow.None
{i}            FillPortions: =0
{i}            Height: =32
{i}            LayoutAlignItems: =LayoutAlignItems.Center
{i}            LayoutDirection: =LayoutDirection.Horizontal
{i}            LayoutGap: =8
{i}            LayoutMinHeight: =0
{i}            LayoutMinWidth: =0
{i}          Children:
{i}            - lbl{p}HelpTitle:
{i}                Control: ModernText
{i}                Properties:
{i}                  AccessibleLabel: =Self.Text
{i}                  AlignInContainer: =AlignInContainer.Center
{i}                  Color: =ColorViolet
{i}                  FillPortions: =1
{i}                  FontWeight: =FontWeight.Bold
{i}                  Height: =28
{i}                  LayoutMinHeight: =0
{i}                  LayoutMinWidth: =0
{i}                  PaddingBottom: =0
{i}                  PaddingLeft: =0
{i}                  PaddingRight: =0
{i}                  PaddingTop: =0
{i}                  Size: =16
{i}                  Text: ="NEXUS · AACA Attendance help"
{i}                  Wrap: =false
{i}            - btn{p}HelpNew:
{i}                Control: ModernButton
{i}                Properties:
{i}                  AccessibleLabel: ="Start a new conversation with NEXUS"
{i}                  AlignInContainer: =AlignInContainer.Center
{i}                  Appearance: =ButtonAppearance.Secondary
{i}                  Color: =ColorInk
{i}                  DisplayMode: =If(varHelpBusy, DisplayMode.Disabled, DisplayMode.Edit)
{i}                  Height: =32
{i}                  Layout: =ButtonLayout.TextOnly
{i}                  LayoutMinHeight: =0
{i}                  LayoutMinWidth: =0
{i}                  OnSelect: =Clear(colHelpMsgs); Set(varHelpConvId, "")
{i}                  Size: =13
{i}                  Text: ="New conversation"
{i}                  Width: =150
{i}            - btn{p}HelpClose:
{i}                Control: ModernButton
{i}                Properties:
{i}                  AccessibleLabel: ="Close NEXUS help"
{i}                  AlignInContainer: =AlignInContainer.Center
{i}                  Appearance: =ButtonAppearance.Secondary
{i}                  Color: =ColorInk
{i}                  Height: =32
{i}                  Layout: =ButtonLayout.TextOnly
{i}                  LayoutMinHeight: =0
{i}                  LayoutMinWidth: =0
{i}                  OnSelect: =Set(varHelpOpen, false)
{i}                  Size: =13
{i}                  Text: ="Close"
{i}                  Width: =80
{i}      - con{p}HelpChat:
{i}          Control: GroupContainer
{i}          Variant: AutoLayout
{i}          Properties:
{i}            DropShadow: =DropShadow.None
{i}            Fill: =ColorPaper
{i}            FillPortions: =1
{i}            LayoutAlignItems: =LayoutAlignItems.Stretch
{i}            LayoutDirection: =LayoutDirection.Vertical
{i}            LayoutMinHeight: =0
{i}            LayoutMinWidth: =0
{i}            LayoutOverflowY: =LayoutOverflow.Scroll
{i}            PaddingBottom: =8
{i}            PaddingLeft: =8
{i}            PaddingRight: =8
{i}            PaddingTop: =8
{i}            RadiusBottomLeft: =6
{i}            RadiusBottomRight: =6
{i}            RadiusTopLeft: =6
{i}            RadiusTopRight: =6
{i}          Children:
{i}            - htm{p}HelpChat:
{i}                Control: HtmlViewer
{i}                Properties:
{i}                  AlignInContainer: =AlignInContainer.Stretch
{i}                  AutoHeight: =true
{i}                  Color: =ColorInk
{i}                  HtmlText: |-
{i}                    =If(CountRows(colHelpMsgs) = 0, {INTRO}, {CHAT})
{i}                  LayoutMinHeight: =0
{i}                  LayoutMinWidth: =0
{i}                  PaddingBottom: =0
{i}                  PaddingLeft: =0
{i}                  PaddingRight: =0
{i}                  PaddingTop: =0
{i}                  Size: =13
{i}      - con{p}HelpAsk:
{i}          Control: GroupContainer
{i}          Variant: AutoLayout
{i}          Properties:
{i}            DropShadow: =DropShadow.None
{i}            FillPortions: =0
{i}            Height: =44
{i}            LayoutAlignItems: =LayoutAlignItems.Center
{i}            LayoutDirection: =LayoutDirection.Horizontal
{i}            LayoutGap: =8
{i}            LayoutMinHeight: =0
{i}            LayoutMinWidth: =0
{i}          Children:
{i}            - txt{p}HelpQ:
{i}                Control: ModernTextInput
{i}                Properties:
{i}                  AccessibleLabel: ="Your question for NEXUS"
{i}                  AlignInContainer: =AlignInContainer.Center
{i}                  Appearance: =Appearance.Outline
{i}                  Color: =ColorInk
{i}                  FillPortions: =1
{i}                  Height: =40
{i}                  LayoutMinHeight: =0
{i}                  LayoutMinWidth: =0
{i}                  MaxLength: =500
{i}                  Placeholder: ="Ask how to do something in the app..."
{i}            - btn{p}HelpAsk:
{i}                Control: ModernButton
{i}                Properties:
{i}                  AccessibleLabel: ="Send the question to NEXUS"
{i}                  AlignInContainer: =AlignInContainer.Center
{i}                  BasePaletteColor: =ColorViolet
{i}                  Color: =ColorWhite
{i}                  DisplayMode: =If(varHelpBusy || Trim(txt{p}HelpQ.Text) = "", DisplayMode.Disabled, DisplayMode.Edit)
{i}                  Height: =40
{i}                  Layout: =ButtonLayout.TextOnly
{i}                  LayoutMinHeight: =0
{i}                  LayoutMinWidth: =0
{i}                  OnSelect: |-
{i}                    {ask}
{i}                  Size: =14
{i}                  Text: =If(varHelpBusy, "Asking...", "Ask")
{i}                  Width: =100
"""


def block_end(lines, start):
    """Index of the line after the YAML list item that starts at lines[start]."""
    ind = len(lines[start]) - len(lines[start].lstrip())
    j = start + 1
    while j < len(lines):
        s = lines[j]
        if s.strip() and (len(s) - len(s.lstrip())) <= ind:
            break
        j += 1
    return j


for p, screen, label in SCREENS:
    path = f"{APP}\\{screen}.pa.yaml"
    lines = open(path, encoding="utf-8").read().split("\n")
    text = "\n".join(lines)
    if f"btn{p}Help:" in text:
        print(screen, "already has help"); continue
    hdr = next(k for k, s in enumerate(lines) if s.strip() == f"- con{p}Header:")
    # header height + 36 (32 button + 4 gap): first Height line inside the header's Properties
    hk = next(k for k in range(hdr, hdr + 20) if lines[k].strip().startswith("Height: ="))
    lines[hk] = lines[hk].replace("Height: =", "Height: =36 + ", 1)
    ident = next(k for k, s in enumerate(lines) if s.strip() == f"- lbl{p}Identity:")
    ind_btn = len(lines[ident]) - len(lines[ident].lstrip())
    e = block_end(lines, ident)
    lines[e:e] = button(p, ind_btn).rstrip("\n").split("\n")
    hdr = next(k for k, s in enumerate(lines) if s.strip() == f"- con{p}Header:")
    ind_panel = len(lines[hdr]) - len(lines[hdr].lstrip())
    e = block_end(lines, hdr)
    lines[e:e] = panel(p, screen, label, ind_panel).rstrip("\n").split("\n")
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
    print(screen, "help added")
