"""Generates templates/AACA-Import-Template.xlsx — the blank workbook used to load real data.

Run: python templates/New-ImportTemplate.py
The filled-in copy contains student data: keep it in OneDrive, never in this repository.
"""
from pathlib import Path

from openpyxl import Workbook
from openpyxl.comments import Comment
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation
from openpyxl.worksheet.table import Table, TableStyleInfo

OUT = Path(__file__).with_name("AACA-Import-Template.xlsx")
FONT = "Arial"
HEADER_FILL = PatternFill("solid", fgColor="1B2A41")   # ink navy, matches the app
REQUIRED_FILL = PatternFill("solid", fgColor="FFF2CC")  # pale yellow = required input column
EXAMPLE_FONT = Font(name=FONT, italic=True, color="7F7F7F")
MAX_ROWS = 60000  # validation range; the attendance log can be long

# Choice lists (must match the Dataverse choice labels the importer maps to)
LISTS = {
    "Roles": ["Teacher", "Attendance Office", "Read-only", "System Admin"],
    "Grades": ["K", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "12+"],
    "StudentStatus": ["Active", "Inactive", "Archived"],
    "Programs": ["Regular Year", "ESY"],
    "Ratios": ["No Aide", "1:1", "2:1", "3:1", "4:1"],
    "Terms": ["Q1", "Q2", "Q3", "Q4", "ESY"],
    "DayTypes": ["Closed", "Work Only", "Make-up School Day"],
    "Present": ["1", "0"],
    "AbsenceStatus": ["Excused", "Unexcused"],
}

# sheet -> list of (header, width, required, kind, list name or None, note)
SHEETS = {
    "Campuses": [
        ("Campus Name", 26, True, "text", None, "Full campus name, e.g. Chatsworth."),
        ("Campus Code", 14, True, "text", None, "Short unique code (2-10 letters) used on every other sheet, e.g. CHT."),
    ],
    "Staff": [
        ("Staff Name", 30, True, "text", None, "Last, First — exactly as you want it shown in the app."),
        ("Email", 34, False, "text", None, "Work email. Optional now; needed later to give the person access."),
        ("Role", 20, True, "list", "Roles", "App role."),
        ("Campus Code", 14, False, "text", None, "Home campus code. Leave blank for all campuses (admins, read-only)."),
    ],
    "Students": [
        ("Student Key", 16, True, "text", None, "Any unique ID for this student (e.g. your current ID). Used to link the other sheets. Two students with the same name MUST have different keys."),
        ("Last Name", 22, True, "text", None, None),
        ("First Name", 22, True, "text", None, None),
        ("Date of Birth", 14, False, "date", None, "Optional. mm/dd/yyyy."),
        ("Grade", 9, False, "list", "Grades", "Optional."),
        ("Status", 12, False, "list", "StudentStatus", "Optional. Blank = worked out from enrollments (open enrollment = Active, otherwise Inactive)."),
    ],
    "Enrollments": [
        ("Student Key", 16, True, "text", None, "Must exist on the Students sheet."),
        ("Teacher Name", 30, True, "text", None, "Must match a Staff Name exactly."),
        ("Campus Code", 14, True, "text", None, None),
        ("Program", 14, True, "list", "Programs", "Regular Year or ESY."),
        ("IEP Ratio", 11, True, "list", "Ratios", None),
        ("Start Date", 13, True, "date", None, "First day with this teacher/campus/ratio."),
        ("End Date", 13, False, "date", None, "Last day. Blank = still current. A row that runs past the end of the school year or into ESY is split automatically."),
    ],
    "Quarters": [
        ("Campus Code", 14, True, "text", None, "Campus code, or ALL if the dates apply to every campus."),
        ("School Year", 13, True, "text", None, "Format 2025-2026."),
        ("Term", 8, True, "list", "Terms", "Q1-Q4 or ESY."),
        ("Start Date", 13, True, "date", None, None),
        ("End Date", 13, True, "date", None, None),
    ],
    "Calendar": [
        ("Campus Code", 14, True, "text", None, "Campus code, or ALL for every campus."),
        ("Date", 13, True, "date", None, "Weekends are automatic — list only weekdays students don't attend (or make-up days)."),
        ("Description", 30, True, "text", None, "e.g. Labor Day, Winter Recess."),
        ("Type", 20, True, "list", "DayTypes", "Closed = no school. Work Only = staff only, no students. Make-up School Day = turns a weekend into a school day."),
    ],
    "Attendance": [
        ("Date", 13, True, "date", None, None),
        ("Student Key", 16, True, "text", None, "Must exist on the Students sheet."),
        ("Teacher Name", 30, True, "text", None, "Teacher who recorded the day (kept as history)."),
        ("Present", 9, True, "list", "Present", "1 = present, 0 = absent."),
        ("Absence Status", 16, False, "list", "AbsenceStatus", "Only when Present = 0. Excused / Unexcused, or blank = not yet classified."),
        ("Absence Reason", 22, False, "text", None, "Optional. Recommended when Excused."),
        ("Notes", 30, False, "text", None, "Optional."),
    ],
}

EXAMPLES = {
    "Campuses": ["EXAMPLE Campus", "EXC"],
    "Staff": ["EXAMPLE, Teacher", "teacher@example.org", "Teacher", "EXC"],
    "Students": ["EXAMPLE-1", "Sample", "Student", "01/15/2014", "5", ""],
    "Enrollments": ["EXAMPLE-1", "EXAMPLE, Teacher", "EXC", "Regular Year", "1:1", "08/12/2026", ""],
    "Quarters": ["EXC", "2026-2027", "Q1", "08/12/2026", "10/16/2026"],
    "Calendar": ["EXC", "09/07/2026", "Labor Day", "Closed"],
    "Attendance": ["08/12/2026", "EXAMPLE-1", "EXAMPLE, Teacher", "0", "Excused", "Illness", ""],
}


def build():
    wb = Workbook()
    readme = wb.active
    readme.title = "README"
    lines = [
        ("AACA Attendance — data import template", Font(name=FONT, bold=True, size=16, color="1B2A41")),
        ("", None),
        ("How to fill this in", Font(name=FONT, bold=True, size=12)),
        ("1. Fill the sheets in tab order: Campuses, Staff, Students, Enrollments, Quarters, Calendar, Attendance.", None),
        ("2. Yellow header columns are required; the others are optional.", None),
        ("3. Grey italic row 2 on each sheet is an EXAMPLE. Delete it or leave it — rows starting with EXAMPLE are ignored.", None),
        ("4. Use the dropdowns where offered. Dates as mm/dd/yyyy (real Excel dates, not text).", None),
        ("5. Every sheet links by Student Key, Staff Name (exactly as on Staff) and Campus Code — spelling must match exactly.", None),
        ("6. School years are worked out from the Quarters sheet (Q1 start to ESY end).", None),
        ("", None),
        ("Privacy", Font(name=FONT, bold=True, size=12)),
        ("This workbook will contain student data. Save your filled copy in OneDrive — never in the code repository or email it.", None),
        ("", None),
        ("What happens next", Font(name=FONT, bold=True, size=12)),
        ("The import script first runs a CHECK pass and produces a report (counts, unmatched names, overlapping enrollments,", None),
        ("attendance on non-school days or outside an enrollment). Nothing is loaded until the report is clean and approved.", None),
    ]
    for i, (text, font) in enumerate(lines, start=1):
        c = readme.cell(row=i, column=1, value=text)
        c.font = font or Font(name=FONT, size=11)
    readme.column_dimensions["A"].width = 120

    lists_ws = wb.create_sheet("Lists")
    for col, (name, values) in enumerate(LISTS.items(), start=1):
        lists_ws.cell(row=1, column=col, value=name).font = Font(name=FONT, bold=True)
        for r, v in enumerate(values, start=2):
            lists_ws.cell(row=r, column=col, value=v).font = Font(name=FONT)
    list_refs = {
        name: f"Lists!${get_column_letter(col)}$2:${get_column_letter(col)}${len(values) + 1}"
        for col, (name, values) in enumerate(LISTS.items(), start=1)
    }

    for sheet_name, cols in SHEETS.items():
        ws = wb.create_sheet(sheet_name, index=len(wb.sheetnames) - 1)  # keep Lists last
        for ci, (header, width, required, kind, list_name, note) in enumerate(cols, start=1):
            letter = get_column_letter(ci)
            cell = ws.cell(row=1, column=ci, value=header)
            cell.font = Font(name=FONT, bold=True, color="1B2A41" if required else "FFFFFF")
            cell.fill = REQUIRED_FILL if required else HEADER_FILL
            cell.alignment = Alignment(vertical="center")
            if note:
                cell.comment = Comment(("Required. " if required else "Optional. ") + note, "AACA")
            ws.column_dimensions[letter].width = width
            rng = f"{letter}2:{letter}{MAX_ROWS}"
            if kind == "list":
                dv = DataValidation(type="list", formula1=f"={list_refs[list_name]}", allow_blank=not required)
                dv.error, dv.errorTitle = "Pick a value from the list.", "Not an allowed value"
                ws.add_data_validation(dv)
                dv.add(rng)
            elif kind == "date":
                dv = DataValidation(type="date", operator="between", formula1="DATE(2020,1,1)", formula2="DATE(2035,12,31)", allow_blank=True)
                dv.error, dv.errorTitle = "Enter a date between 2020 and 2035 (mm/dd/yyyy).", "Not a date"
                ws.add_data_validation(dv)
                dv.add(rng)
                for r in range(2, 500):
                    ws.cell(row=r, column=ci).number_format = "mm/dd/yyyy"
        # Example row (text values so the sample shows exactly what to type)
        for ci, value in enumerate(EXAMPLES[sheet_name], start=1):
            c = ws.cell(row=2, column=ci, value=value)
            c.font = EXAMPLE_FONT
        ws.freeze_panes = "A2"
        last = get_column_letter(len(cols))
        table = Table(displayName=f"tbl{sheet_name}", ref=f"A1:{last}2")
        table.tableStyleInfo = TableStyleInfo(name="TableStyleLight1", showRowStripes=True)
        ws.add_table(table)
        ws.row_dimensions[1].height = 22

    lists_ws.sheet_state = "hidden"
    wb.save(OUT)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    build()
