"""AACA Attendance importer — CHECK / PLAN stage.

Reads a filled copy of templates/AACA-Import-Template.xlsx, validates it, transforms it into the exact
rows that will be written to Dataverse, and writes two files NEXT TO THE WORKBOOK (OneDrive, never the repo):

  <workbook>.report.md   human-readable check report (errors, warnings, counts)
  <workbook>.plan.json   normalised load plan consumed by Import-AacaData.ps1

Nothing is written to Dataverse here. Usage:
  python import/aaca_import.py "C:\\...\\AACA-Import-2026-09-29.xlsx" [--today 2026-09-29]

Transformation rules (see docs/architecture.md, AACA rules confirmed 2026-09-29):
- School years and terms come from the Quarters sheet (per campus; Q1-Q4 and ESY). ESY is only a calendar period.
- One Enrollments (roster) row = one continuous enrollment. No splitting at quarters, ESY or school-year boundaries.
  A new row exists only for a transfer or IEP ratio change. End reasons: next row with a different teacher/campus =
  Transfer; different ratio only = Ratio Change; End Date with no following row = Archived (student archived).
- Student status is derived: an open enrollment = Active, otherwise Archived. RC- (Regional Center Only) students have
  no enrollment; their status comes from the sheet (blank = Active).
- Attendance keeps the teacher from the sheet as the historical snapshot and links to the enrollment covering the date.
  Rows on weekends or Closed / Work Only days are skipped as clerical errors and listed in the report.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

import pandas as pd

ROLE_VALUES = {"Teacher": 582100000, "Attendance Office": 582100001, "Read-only": 582100002, "System Admin": 582100003}
RATIO_VALUES = {"No Aide": 582100000, "1:1": 582100001, "2:1": 582100002, "3:1": 582100003, "4:1": 582100004}
GRADE_VALUES = {g: 582100000 + i for i, g in enumerate(["K", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "12+"])}
STUDENT_STATUS = {"Active": 582100000, "Inactive": 582100001, "Archived": 582100002}
TYPE_SCHOOL, TYPE_RC_ONLY = 582100000, 582100001  # Student Type
TERM_VALUES = {"Q1": 582100000, "Q2": 582100001, "Q3": 582100002, "Q4": 582100003, "ESY": 582100004}
# Calendar Exception Type: Closed -> Closure, Work Only -> Staff Development (labels to be renamed to match), Make-up
DAYTYPE_VALUES = {"Closed": 582100003, "Work Only": 582100002, "Make-up School Day": 582100004}
PROGRAM_REGULAR, PROGRAM_ESY = 582100000, 582100001
ENR_PLANNED, ENR_ACTIVE, ENR_ENDED = 582100000, 582100001, 582100002
# End Reason 582100002 is labelled "Archived" (was "Discharge"): an end date with no following enrollment.
END_TRANSFER, END_RATIO, END_ARCHIVED, END_YEAR, END_CORRECTION = 582100000, 582100001, 582100002, 582100003, 582100004
END_NAMES = {END_TRANSFER: "Transfer", END_RATIO: "Ratio Change", END_ARCHIVED: "Archived", END_YEAR: "Year End", END_CORRECTION: "Correction"}
SERVICE_CODE = "SPED"


class Report:
    def __init__(self):
        self.errors: list[str] = []
        self.warnings: dict[str, list[str]] = defaultdict(list)
        self.counts: dict[str, object] = {}

    def error(self, msg):
        self.errors.append(msg)

    def warn(self, group, msg):
        self.warnings[group].append(msg)


def as_date(v):
    if v is None or (isinstance(v, float) and pd.isna(v)) or v is pd.NaT or (isinstance(v, str) and not v.strip()):
        return None
    if isinstance(v, (dt.datetime, pd.Timestamp)):
        return v.date() if hasattr(v, "date") else v
    if isinstance(v, dt.date):
        return v
    return pd.to_datetime(str(v).strip()).date()


def text(v):
    if v is None or (isinstance(v, float) and pd.isna(v)):
        return ""
    return " ".join(str(v).split())


def load_sheets(path: Path):
    raw = pd.read_excel(path, sheet_name=None, dtype=object)
    out = {}
    for name, df in raw.items():
        if name in ("README", "Lists"):
            continue
        df = df.dropna(how="all")
        first = df.columns[0]
        mask = df.apply(lambda r: any(text(v).upper().startswith("EXAMPLE") for v in r.values[:3]), axis=1)
        out[name] = df[~mask].reset_index(drop=True)
    return out


def build(path: Path, today: dt.date):
    rep = Report()
    s = load_sheets(path)

    # ---------------- Campuses ----------------
    campuses = {}
    for i, r in s["Campuses"].iterrows():
        code, name = text(r["Campus Code"]).upper(), text(r["Campus Name"])
        if not code or not name:
            rep.error(f"Campuses row {i + 2}: name and code are required")
            continue
        if code in campuses:
            rep.error(f"Campuses row {i + 2}: duplicate code {code}")
        campuses[code] = {"code": code, "name": name}

    def campus_ok(code, where):
        if code == "ALL" or code in campuses:
            return True
        rep.error(f"{where}: unknown campus code '{code}'")
        return False

    # ---------------- Staff ----------------
    staff = {}
    for i, r in s["Staff"].iterrows():
        name, role, code = text(r["Staff Name"]), text(r["Role"]), text(r.get("Campus Code")).upper()
        where = f"Staff row {i + 2} ({name})"
        if not name:
            rep.error(f"Staff row {i + 2}: name required")
            continue
        if role not in ROLE_VALUES:
            rep.error(f"{where}: unknown role '{role}'")
            continue
        if code and not campus_ok(code, where):
            continue
        if "," not in name:
            rep.warn("Staff names not in 'Last, First' form (kept as typed)", name)
        if name in staff:
            rep.error(f"{where}: duplicate staff name")
        staff[name] = {"name": name, "email": text(r.get("Email")).lower(), "role": ROLE_VALUES[role], "roleName": role, "campus": code or None}

    def teacher_ok(name, where):
        if name in staff:
            return True
        rep.error(f"{where}: teacher '{name}' is not on the Staff sheet")
        return False

    # ---------------- Students ----------------
    students = {}
    name_seen = {}
    for i, r in s["Students"].iterrows():
        key, last, first = text(r["Student Key"]), text(r["Last Name"]), text(r["First Name"])
        where = f"Students row {i + 2}"
        if not key or not last or not first:
            rep.error(f"{where}: key, last and first name are required")
            continue
        if key in students:
            rep.error(f"{where}: duplicate Student Key {key}")
            continue
        grade, status = text(r.get("Grade")), text(r.get("Status"))
        if grade and grade not in GRADE_VALUES:
            rep.error(f"{where}: unknown grade '{grade}'")
        if status and status not in STUDENT_STATUS:
            rep.error(f"{where}: unknown status '{status}'")
        nm = (last.lower(), first.lower())
        if nm in name_seen:
            rep.warn("Students sharing a name (kept separate by key)", f"{last}, {first}: keys {name_seen[nm]} and {key}")
        name_seen[nm] = key
        students[key] = {"key": key, "last": last, "first": first, "display": f"{last}, {first}",
                         "dob": as_date(r.get("Date of Birth")), "grade": GRADE_VALUES.get(grade), "statusGiven": status or None,
                         # RC- keys = Regional Center Only students: services outside school, no enrollment or attendance.
                         "type": TYPE_RC_ONLY if key.upper().startswith("RC-") else TYPE_SCHOOL}

    # ---------------- Quarters -> Terms, School Years, periods ----------------
    terms = []
    by_campus_year = defaultdict(dict)   # (campus, year) -> {term: (start, end)}
    for i, r in s["Quarters"].iterrows():
        code, year, term = text(r["Campus Code"]).upper(), text(r["School Year"]), text(r["Term"])
        start, end = as_date(r["Start Date"]), as_date(r["End Date"])
        where = f"Quarters row {i + 2}"
        if not campus_ok(code, where):
            continue
        if term not in TERM_VALUES:
            rep.error(f"{where}: unknown term '{term}'")
            continue
        if not start or not end or end < start:
            rep.error(f"{where}: invalid dates")
            continue
        parts = year.split("-")
        if len(parts) != 2 or not all(p.isdigit() for p in parts) or int(parts[1]) != int(parts[0]) + 1:
            rep.error(f"{where}: school year '{year}' must look like 2025-2026")
            continue
        if term in by_campus_year[(code, year)]:
            rep.error(f"{where}: duplicate {term} for {code} {year}")
        by_campus_year[(code, year)][term] = (start, end)
        terms.append({"campus": None if code == "ALL" else code, "year": year, "term": term, "termValue": TERM_VALUES[term],
                      "start": start, "end": end, "name": f"{year} {term} ({'All' if code == 'ALL' else code})"})

    years = sorted({t["year"] for t in terms})
    school_years = {}
    for y in years:
        ts = [t for t in terms if t["year"] == y]
        school_years[y] = {"name": y, "start": min(t["start"] for t in ts), "end": max(t["end"] for t in ts)}
        if not any(t["term"] == "ESY" for t in ts):
            rep.warn("School years without an ESY term", y)
    for code in campuses:
        for y in years:
            have = set(by_campus_year.get((code, y), {})) | set(by_campus_year.get(("ALL", y), {}))
            missing = [t for t in TERM_VALUES if t not in have]
            if missing:
                rep.warn("Campus/year missing quarters (attendance on those dates will be treated as non-school)",
                         f"{campuses[code]['name']} {y}: missing {', '.join(missing)}")
    for (code, y), tmap in by_campus_year.items():
        ordered = sorted(tmap.items(), key=lambda kv: kv[1][0])
        for (t1, (s1, e1)), (t2, (s2, e2)) in zip(ordered, ordered[1:]):
            if s2 <= e1:
                rep.error(f"Quarters: {code} {y} {t1} and {t2} overlap")

    def campus_terms(code):
        return [t for t in terms if t["campus"] in (code, None)]

    def term_for(code, d):
        for t in campus_terms(code):
            if t["start"] <= d <= t["end"]:
                return t
        return None

    def year_for(code, d):
        """School year an enrollment belongs to: the campus year whose terms span the date, else the latest year
        starting on/before it, else the first year."""
        spans = {}
        for t in campus_terms(code):
            lo, hi = spans.get(t["year"], (t["start"], t["end"]))
            spans[t["year"]] = (min(lo, t["start"]), max(hi, t["end"]))
        for y, (lo, hi) in sorted(spans.items()):
            if lo <= d <= hi:
                return y
        started = [y for y, (lo, _) in sorted(spans.items()) if lo <= d]
        return started[-1] if started else (min(spans) if spans else None)

    def periods(code):
        """Ordered (year, program, start, end) periods for a campus; None bounds are open."""
        ys = sorted({t["year"] for t in campus_terms(code)})
        q1 = {y: min((t["start"] for t in campus_terms(code) if t["year"] == y and t["term"] == "Q1"), default=None) for y in ys}
        esy = {y: min((t["start"] for t in campus_terms(code) if t["year"] == y and t["term"] == "ESY"), default=None) for y in ys}
        out = []
        for idx, y in enumerate(ys):
            start = None if idx == 0 else q1[y]
            nxt = q1[ys[idx + 1]] if idx + 1 < len(ys) else None
            if esy[y]:
                out.append((y, PROGRAM_REGULAR, start, esy[y] - dt.timedelta(days=1)))
                out.append((y, PROGRAM_ESY, esy[y], None if nxt is None else nxt - dt.timedelta(days=1)))
            else:
                out.append((y, PROGRAM_REGULAR, start, None if nxt is None else nxt - dt.timedelta(days=1)))
        return out

    # ---------------- Calendar ----------------
    exceptions, nonschool, makeup = [], set(), set()
    for i, r in s["Calendar"].iterrows():
        code, d, desc, typ = text(r["Campus Code"]).upper(), as_date(r["Date"]), text(r["Description"]), text(r["Type"])
        where = f"Calendar row {i + 2}"
        if not campus_ok(code, where):
            continue
        if not d or typ not in DAYTYPE_VALUES:
            rep.error(f"{where}: date and a valid type are required")
            continue
        exceptions.append({"campus": None if code == "ALL" else code, "date": d, "name": desc or typ, "type": DAYTYPE_VALUES[typ], "typeName": typ})
        targets = list(campuses) if code == "ALL" else [code]
        for c in targets:
            (makeup if typ == "Make-up School Day" else nonschool).add((c, d))

    def school_day(code, d):
        if (code, d) in makeup:
            return term_for(code, d) is not None
        if d.weekday() >= 5 or (code, d) in nonschool:
            return False
        return term_for(code, d) is not None

    # ---------------- Attendance (parsed first: ESY evidence) ----------------
    att_rows = []
    for i, r in s["Attendance"].iterrows():
        d, key, teacher = as_date(r["Date"]), text(r["Student Key"]), text(r["Teacher Name"])
        present, status = text(r["Present"]), text(r.get("Absence Status"))
        where = f"Attendance row {i + 2}"
        if not d or key not in students or not teacher_ok(teacher, where):
            if key not in students:
                rep.error(f"{where}: unknown Student Key '{key}'")
            if not d:
                rep.error(f"{where}: bad date")
            continue
        if present in ("1", "1.0"):
            present = True
        elif present in ("0", "0.0"):
            present = False
        else:
            rep.error(f"{where}: Present must be 1 or 0 (got '{present}')")
            continue
        if status and status not in ("Excused", "Unexcused"):
            rep.error(f"{where}: Absence Status must be Excused, Unexcused or blank")
            continue
        if status and present:
            rep.error(f"{where}: Absence Status given on a present day")
            continue
        att_rows.append({"row": i + 2, "date": d, "key": key, "teacher": teacher, "present": present,
                         "classification": {"Excused": 582100000, "Unexcused": 582100001}.get(status),
                         "reason": text(r.get("Absence Reason")) or None, "notes": text(r.get("Notes")) or None})
    att_dates = defaultdict(set)
    for a in att_rows:
        att_dates[a["key"]].add(a["date"])

    # ---------------- Enrollments -> segments ----------------
    roster = []
    for i, r in s["Enrollments"].iterrows():
        key, teacher, code = text(r["Student Key"]), text(r["Teacher Name"]), text(r["Campus Code"]).upper()
        program, ratio = text(r["Program"]), text(r["IEP Ratio"])
        start, end = as_date(r["Start Date"]), as_date(r.get("End Date"))
        where = f"Enrollments row {i + 2}"
        ok = True
        if key not in students:
            rep.error(f"{where}: unknown Student Key '{key}'"); ok = False
        if not teacher_ok(teacher, where) or not campus_ok(code, where) or code == "ALL":
            ok = False
        if ratio not in RATIO_VALUES:
            rep.error(f"{where}: unknown IEP ratio '{ratio}'"); ok = False
        if not start or (end and end < start):
            rep.error(f"{where}: invalid start/end dates"); ok = False
        if ok and teacher in staff and staff[teacher]["role"] != ROLE_VALUES["Teacher"]:
            rep.warn("Enrollments assigned to staff whose role is not Teacher", f"{where}: {teacher} ({staff[teacher]['roleName']})")
        if ok:
            roster.append({"row": i + 2, "key": key, "teacher": teacher, "campus": code, "ratio": RATIO_VALUES[ratio],
                           "ratioName": ratio, "program": program, "start": start, "end": end})

    by_student = defaultdict(list)
    for rr in roster:
        by_student[rr["key"]].append(rr)
    segments = []
    for key, rows in by_student.items():
        rows.sort(key=lambda x: x["start"])
        for a, b in zip(rows, rows[1:]):
            if a["end"] is None or b["start"] <= a["end"]:
                rep.error(f"Enrollments rows {a['row']} and {b['row']}: overlapping dates for student {key} "
                          f"({a['start']}–{a['end'] or 'open'} vs {b['start']}–{b['end'] or 'open'})")
        # One roster row = one continuous enrollment (AACA rule 2026-09-29): no splitting at quarters, ESY or
        # school-year boundaries. A new row exists only for a transfer or IEP ratio change; an End Date with no
        # following row means the student is archived.
        prev_seg = None
        for idx, rr in enumerate(rows):
            nxt = rows[idx + 1] if idx + 1 < len(rows) else None
            if rr["end"] is None:
                reason = None
            elif nxt is None:
                reason = END_ARCHIVED
            elif nxt["teacher"] != rr["teacher"] or nxt["campus"] != rr["campus"]:
                reason = END_TRANSFER
            elif nxt["ratio"] != rr["ratio"]:
                reason = END_RATIO
            else:
                reason = END_CORRECTION
            status = ENR_PLANNED if rr["start"] > today else (ENR_ENDED if rr["end"] and rr["end"] < today else ENR_ACTIVE)
            seg = {"id": len(segments), "key": key, "teacher": rr["teacher"], "campus": rr["campus"], "ratio": rr["ratio"],
                   "year": year_for(rr["campus"], rr["start"]), "program": PROGRAM_REGULAR, "start": rr["start"], "end": rr["end"],
                   "endReason": reason, "status": status, "prev": prev_seg["id"] if prev_seg else None, "sourceRow": rr["row"]}
            segments.append(seg)
            prev_seg = seg

    def segment_for(key, d):
        for seg in segments:
            if seg["key"] == key and seg["start"] <= d and (seg["end"] is None or d <= seg["end"]):
                return seg
        return None

    # ---------------- Attendance checks + links ----------------
    attendance = []
    for a in att_rows:
        seg = segment_for(a["key"], a["date"])
        term = None
        if seg is None:
            rep.warn("Attendance outside any enrollment (imported without enrollment link)", f"row {a['row']}: {a['key']} {a['date']}")
            campus = staff[a["teacher"]]["campus"]
        else:
            campus = seg["campus"]
            if seg["teacher"] != a["teacher"]:
                rep.warn("Attendance teacher differs from the enrolled teacher (sheet teacher kept as history)", f"row {a['row']}: {a['key']} {a['date']} sheet={a['teacher']} enrolled={seg['teacher']}")
        if campus:
            term = term_for(campus, a["date"])
            if not school_day(campus, a["date"]):
                weekend, closed = a["date"].weekday() >= 5 and (campus, a["date"]) not in makeup, (campus, a["date"]) in nonschool
                if weekend or closed:
                    # Decision 2026-09-29: attendance on weekends / Closed / Work Only days is treated as clerical error.
                    why = "weekend" if weekend else "Closed / Work Only day"
                    rep.warn("Attendance on weekends or Closed/Work Only days (SKIPPED, not imported)", f"row {a['row']}: {a['key']} {a['date']} {campuses[campus]['name']} — {why}")
                    continue
                rep.warn("Attendance outside every quarter (imported as recorded — check the Quarters sheet)", f"row {a['row']}: {a['key']} {a['date']} {campuses[campus]['name']}")
        year = seg["year"] if seg else next((t["year"] for t in terms if t["start"] <= a["date"] <= t["end"]), None)
        attendance.append({**a, "segment": seg["id"] if seg else None, "campus": campus, "year": year,
                           "term": f"{term['year']}|{term['term']}|{term['campus'] or 'ALL'}" if term else None,
                           "ratio": seg["ratio"] if seg else None,
                           "recordKey": f"{a['date']:%Y%m%d}|{a['key']}|{SERVICE_CODE}"})

    # ---------------- Student status ----------------
    for key, st in students.items():
        if st["type"] == TYPE_RC_ONLY:
            if any(seg["key"] == key for seg in segments):
                rep.error(f"{key} {st['display']}: Regional Center Only (RC-) students cannot have roster rows")
            # No enrollment by design: status comes from the sheet (blank = Active).
            st["status"] = STUDENT_STATUS[st["statusGiven"] or "Active"]
            continue
        open_now = any(seg["key"] == key and (seg["end"] is None or seg["end"] >= today) for seg in segments)
        # AACA rule: an enrollment end date with no following enrollment means the student is archived.
        derived = "Active" if open_now else "Archived"
        if st["statusGiven"] and st["statusGiven"] != derived:
            rep.warn("Student status on the sheet differs from enrollments (status from enrollments used)", f"{key} {st['display']}: sheet={st['statusGiven']} enrollments={derived}")
        st["status"] = STUDENT_STATUS[derived]
        if not any(seg["key"] == key for seg in segments):
            rep.warn("Students with no enrollment", f"{key} {st['display']}")

    rep.counts = {
        "Campuses": len(campuses), "Staff": len(staff), "Students": len(students), "Roster rows": len(roster),
        "Enrollments to create (after splitting)": len(segments),
        "  of which ESY": sum(1 for x in segments if x["program"] == PROGRAM_ESY),
        "  open (no end date)": sum(1 for x in segments if x["end"] is None),
        "School years": len(school_years), "Terms": len(terms), "Calendar exceptions": len(exceptions),
        "Attendance rows": len(attendance), "  present": sum(1 for a in attendance if a["present"]),
        "  absent": sum(1 for a in attendance if not a["present"]),
        "  absent, not classified": sum(1 for a in attendance if not a["present"] and a["classification"] is None),
        "End reasons": dict(Counter(END_NAMES.get(x["endReason"], "(open)") for x in segments)),
    }
    plan = {"generated": dt.datetime.now().isoformat(timespec="seconds"), "today": today.isoformat(), "serviceCode": SERVICE_CODE,
            "campuses": list(campuses.values()), "staff": list(staff.values()),
            "students": list(students.values()), "schoolYears": list(school_years.values()), "terms": terms,
            "exceptions": exceptions, "enrollments": segments, "attendance": attendance}
    return rep, plan


def write_report(rep: Report, path: Path, source: Path):
    lines = [f"# Import check report — {source.name}", "", f"Generated {dt.datetime.now():%Y-%m-%d %H:%M}", ""]
    lines += ["## Result", "", ("**BLOCKING ERRORS: fix these in the workbook and re-run.**" if rep.errors else "No blocking errors — ready to load once the warnings below are reviewed."), ""]
    lines += ["## What would be created", ""]
    for k, v in rep.counts.items():
        lines.append(f"- {k}: {v}")
    lines.append("")
    if rep.errors:
        lines += [f"## Errors ({len(rep.errors)})", ""] + [f"- {e}" for e in rep.errors] + [""]
    lines += [f"## Warnings ({sum(len(v) for v in rep.warnings.values())})", ""]
    for group, items in rep.warnings.items():
        lines += [f"### {group} ({len(items)})", ""] + [f"- {x}" for x in items[:200]]
        if len(items) > 200:
            lines.append(f"- … and {len(items) - 200} more")
        lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("workbook")
    ap.add_argument("--today", default=dt.date.today().isoformat())
    args = ap.parse_args()
    src = Path(args.workbook).resolve()
    repo = Path(__file__).resolve().parents[1]
    if repo in src.parents:
        sys.exit("Refusing to read a filled workbook from inside the repository — move it to OneDrive first.")
    rep, plan = build(src, dt.date.fromisoformat(args.today))
    report_path = src.with_suffix(".report.md")
    plan_path = src.with_suffix(".plan.json")
    write_report(rep, report_path, src)
    plan_path.write_text(json.dumps(plan, default=str, indent=1), encoding="utf-8")
    print(f"Report: {report_path}\nPlan:   {plan_path}")
    print(f"Errors: {len(rep.errors)}  Warnings: {sum(len(v) for v in rep.warnings.values())}")
    for k, v in rep.counts.items():
        print(f"  {k}: {v}")
    for g, items in rep.warnings.items():
        print(f"  [warn] {g}: {len(items)}")
    for e in rep.errors[:25]:
        print(f"  [ERROR] {e}")


if __name__ == "__main__":
    main()
