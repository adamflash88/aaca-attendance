// AACA Attendance app user guide (.docx), written for staff AND as a knowledge source for the Resource Center agent:
// one heading per screen/task, short self-contained sections, FAQ and glossary at the end.
const fs = require('fs');
const path = require('path');
const { Document, Packer, Paragraph, TextRun, HeadingLevel, LevelFormat, AlignmentType, Table, TableRow, TableCell,
  WidthType, ShadingType, BorderStyle } = require('docx');

const OUT = 'C:\\Users\\AdamBernstein\\OneDrive - AACA\\06 - Information Technology\\03 - App Projects\\PowerApps\\AACA-Attendance\\user-guide';
fs.mkdirSync(OUT, { recursive: true });

const kids = [];
const H1 = (t) => kids.push(new Paragraph({ heading: HeadingLevel.HEADING_1, spacing: { before: 360, after: 120 }, children: [new TextRun(t)] }));
const H2 = (t) => kids.push(new Paragraph({ heading: HeadingLevel.HEADING_2, spacing: { before: 240, after: 80 }, children: [new TextRun(t)] }));
const P = (...runs) => kids.push(new Paragraph({ spacing: { after: 120 }, children: runs.map((r) => (typeof r === 'string' ? new TextRun(r) : r)) }));
const B = (t) => new TextRun({ text: t, bold: true });
const UL = (items) => items.forEach((t) => kids.push(new Paragraph({ numbering: { reference: 'bul', level: 0 }, spacing: { after: 60 },
  children: (Array.isArray(t) ? t : [t]).map((r) => (typeof r === 'string' ? new TextRun(r) : r)) })));
let listNo = 0;
const OL = (items) => { listNo += 1; const ref = `num${listNo}`; numberingRefs.push(ref);
  items.forEach((t) => kids.push(new Paragraph({ numbering: { reference: ref, level: 0 }, spacing: { after: 60 },
    children: (Array.isArray(t) ? t : [t]).map((r) => (typeof r === 'string' ? new TextRun(r) : r)) }))); };
const numberingRefs = [];
const FAQ = (q, a) => { kids.push(new Paragraph({ spacing: { before: 160, after: 40 }, children: [B(q)] })); P(a); };

const border = { style: BorderStyle.SINGLE, size: 4, color: 'BFBFBF' };
function table(widths, rows) {
  const total = widths.reduce((a, b) => a + b, 0);
  kids.push(new Table({ width: { size: total, type: WidthType.DXA }, columnWidths: widths,
    rows: rows.map((r, i) => new TableRow({ tableHeader: i === 0, children: r.map((c, j) => new TableCell({
      width: { size: widths[j], type: WidthType.DXA }, borders: { top: border, bottom: border, left: border, right: border },
      margins: { top: 60, bottom: 60, left: 100, right: 100 },
      shading: i === 0 ? { type: ShadingType.CLEAR, color: 'auto', fill: 'E0F0ED' } : undefined,
      children: [new Paragraph({ children: [i === 0 ? B(c) : new TextRun(c)] })] })) })) }));
  kids.push(new Paragraph({ spacing: { after: 120 }, children: [] }));
}

// ------------------------------------------------------------------------------------------------ Title
kids.push(new Paragraph({ heading: HeadingLevel.TITLE, children: [new TextRun('AACA Attendance App: User Guide')] }));
P('This guide explains how to use the AACA Attendance app: what each screen is for, how to do each task, and what the marks and colors mean. It covers teachers, campus office managers, site administrators and business office staff.');

// ------------------------------------------------------------------------------------------------ Overview
H1('What the AACA Attendance app is');
P('The AACA Attendance app is where AACA records daily student attendance for each campus (Antelope Valley, Chatsworth and Oxnard). Teachers mark students present. Absences reported by parents through the Student Absence form are added to the app automatically. The campus office classifies absences, records students who left early, manages students and teachers, and confirms transportation each day.');
H2('Who can do what (roles)');
table([2200, 7520], [
  ['Role', 'What they can do'],
  ['Teacher', 'Sees their own class grid and marks students present (1). Can undo their own 1s. Can view (not change) other teachers\' grids at their campus. Cannot change absences (0) or left-early days (1*). Does not see the Students, Absences, Transportation or Staff screens.'],
  ['Attendance Office (office managers and site administrators)', 'Works with their own campus only. Classifies absences (Excused or Unexcused), adds absences, records left early, resolves parent/teacher conflicts and Mapping Errors, manages students and enrollments, confirms transportation, and adds, transfers and retires teachers on the Staff screen. The attendance grid is view-only for this role.'],
  ['System Admin (business office)', 'Everything the office can do, for all campuses, chosen with the Campus picker.'],
  ['Read-only', 'Can view all campuses but cannot change anything.'],
]);
P('Your role and campus appear at the top of every screen, next to your name (for example: "Jane Smith · Teacher · Chatsworth").');

// ------------------------------------------------------------------------------------------------ Getting started
H1('Getting started');
H2('Opening the app');
P('Open AACA Attendance from the link you were given or from Power Apps (apps.powerapps.com). Sign in with your AACA Microsoft 365 account. The first time you open it you may be asked to allow the app to use its connections; choose Allow.');
H2('"You\'re not set up yet"');
P('This message means your sign-in is not linked to a Staff record in the app. Ask your campus office manager to add you on the Staff screen (teachers) or ask the business office (all other roles).');
H2('"Your access is being set up"');
P('This message means the office has added you on the Staff screen and the app found your record, but your access is still being set up. This happens automatically within about 15 minutes of your first sign-in. Close the app and open it again in a few minutes.');
H2('Moving between screens');
P('The buttons at the top of the screen move between the screens your role can use: Attendance, Students, Absences, Transportation and Staff. Teachers only see the Attendance screen.');

// ------------------------------------------------------------------------------------------------ Attendance
H1('Attendance screen (the grid)');
P('The Attendance screen shows one teacher\'s class for one month: a row per student and a column per day. Teachers see their own class when the app opens. Office and admin users pick a campus and a teacher.');
H2('What the marks and colors mean');
table([2000, 7720], [
  ['Mark', 'Meaning'],
  ['1', 'Present. Teachers add 1s by tapping a blank square on their own grid.'],
  ['1*', 'Present but left early. Recorded by the office (Absences > Left early). Teachers cannot undo it.'],
  ['0 (no color)', 'Absent, not classified yet. Usually reported by a parent; the office still has to classify it.'],
  ['0 (green)', 'Absent - Excused.'],
  ['0 (red)', 'Absent - Unexcused.'],
  ['Grey square', 'No school that day (weekend, holiday, break, or outside the school term).'],
  ['-', 'Student not enrolled with this teacher on that day.'],
  ['Dashed square', 'A future date. Attendance cannot be taken for future dates.'],
  ['!', 'A save failed. Tap the square to try again.'],
]);
H2('Marking a student present (teachers)');
OL(['Find today\'s column on your grid.', 'Tap the blank square for the student. It changes to 1 and saves.', 'To mark everyone at once, use All present for that day. It fills in blank squares only and leaves absences and existing marks alone.']);
H2('Undoing a 1 (teachers)');
P('Tap the 1, then choose Confirm undo. The square goes back to blank. You can only undo your own 1s. A 0 (absence) or a 1* (left early) cannot be changed by teachers; contact the campus office if one of them is wrong.');
H2('Moving around the grid');
UL(['Month and year pickers, the Prev and Next buttons, and This month change the month shown.', 'The Month / Day switch changes between the whole month and a single day\'s list.', 'Details mode shows notes and where each absence came from (parent report, office, teacher).', 'Office, admin and read-only users choose the Campus and Teacher at the top. Teachers can pick another teacher at their campus to view that grid; it is view-only.']);
H2('Why can\'t I change a square?');
UL(['It is a 0 (absence) or 1* (left early): these belong to the office.', 'It is another teacher\'s grid: other grids are view-only.', 'It is a future date or a non-school (grey) day.', 'The month has been locked for billing.', 'You are signed in as Attendance Office, System Admin or Read-only: the grid is view-only for those roles.']);

// ------------------------------------------------------------------------------------------------ Absences
H1('Absences screen (office and admin)');
P('The Absences screen is where the office handles absences. It has two tabs at the top: Classify absences and Mapping Errors.');
H2('Where absences come from');
P('When a parent submits the Student Absence form, the app automatically adds a 0 for each school day in the reported range, within about 5 minutes. The office then classifies it. The office can also add absences directly (see Add absence).');
H2('Classifying absences (Excused or Unexcused)');
OL(['Open Absences. The Classify absences tab lists absences that still need a classification, with the parent\'s reason and when they reported it.', 'Tick one or more absences (or use Select all shown).', 'Choose Mark Excused (a reason is required) or Mark Unexcused.', 'The day turns green (Excused) or red (Unexcused) on the attendance grid.']);
P('Use the Campus, Teacher, Status and date filters to narrow the list, and Clear filters to reset them.');
H2('Removing an absence that should not be there');
P('If a parent reported an absence but the child came to school, tick the absence, enter a reason and choose Remove ticked. The 0 is removed from the grid. Every removal is recorded in the audit log.');
H2('Needs a decision (parent said absent, teacher marked present)');
P('If a parent reported an absence for a day the teacher already marked present, the app does not overwrite the teacher\'s mark. The day appears under Needs a decision at the top of the Absences screen. Choose Keep present (the child was at school) or Mark absent (the parent is right).');
H2('Add absence (parent did not notify us)');
OL(['Choose Add absence.', 'Pick the student, the From date and (optionally) the To date. Leave To date blank for a single day.', 'Choose the classification: Excused (pick a reason) or Unexcused. Add a note if useful.', 'Choose Save absence. The app adds an absence for each school day in the range on which the student is enrolled. Days the teacher already marked present are skipped and listed in the receipt.']);
H2('Left early');
OL(['Choose Left early.', 'Pick the student and the date (today by default; future dates are not allowed).', 'Enter the time the student left (h:mm AM/PM) and the reason.', 'Choose Save left early. The day shows 1* on the grid. If the teacher had not marked the day yet, the app marks the student present and left early.']);
P('Only the office records left early. A day marked absent cannot be recorded as left early.');
H2('Mapping Errors');
P('Mapping Errors lists parent reports the app could not match to a student, usually because the Student ID was missing or mistyped, or the dates could not be read. The number on the tab is how many are waiting.');
UL([[B('No Student ID / could not match: '), 'open the report and choose Map student to pick the correct student. Only map a report when you are sure which student it is, because mapping updates the real parent report. About 5 minutes later the absence appears in Classify absences.'],
    [B('Could not process (for example, bad dates): '), 'choose Fix dates to correct the absence and return dates.'],
    [B('Duplicate or test reports: '), 'choose Dismiss and give a reason. The report leaves the list.']]);

// ------------------------------------------------------------------------------------------------ Students
H1('Students screen (office and admin)');
P('The Students screen lists students at your campus. Search by name, student number or external ID, and filter by status and teacher. Select a student to see their details, enrollment history and actions.');
H2('Add a student');
P('Choose + Add student and fill in first name, last name, date of birth, grade, program, campus, teacher, IEP ratio and start date. The app assigns the Student ID automatically. The student then appears on the teacher\'s grid from the start date.');
H2('Student actions');
table([2200, 7520], [
  ['Action', 'When to use it'],
  ['Edit details', 'Fix the student\'s name, date of birth, grade or other details.'],
  ['Change class', 'The student moves to another teacher from a chosen date. Past days stay with the old teacher; new days go to the new teacher.'],
  ['Change ratio', 'The student\'s IEP aide ratio changes (No Aide, 1:1, 2:1, 3:1, 4:1) from a chosen date.'],
  ['End enrollment', 'The student is leaving AACA. Do not use it for moves between teachers; use Change class instead.'],
  ['Re-enroll', 'A student who left comes back.'],
]);
P('Each change ends the current enrollment and starts a new one, so the history is kept. Enrollment history shows every past class, teacher and ratio.');

// ------------------------------------------------------------------------------------------------ Transportation
H1('Transportation screen (office and admin)');
P('Transportation tracks which students receive transportation and how each school day was handled. It has two tabs: Daily and Students.');
H2('Daily confirmation (every school day)');
OL(['Open Transportation. The Daily tab shows today\'s students at your campus who have transportation, with their usual pattern and today\'s attendance.', 'For each student choose Round trip, Drop off only, Pick up only or No transportation. Absent students are pre-set to No transportation and students who left early to Drop off only.', 'Choose Confirm day. Every student needs a choice before you can confirm. The list then shows who confirmed it and when.']);
P('Confirm each school day by the end of the day. A banner lists recent school days that are not confirmed yet; select a day to open it. You can change a single student after confirming; the change is saved for that day.');
H2('Managing who gets transportation (Students tab)');
UL(['Add student: give a student transportation from a start date with their usual pattern.', 'Change pattern: change the usual pattern (Round trip, Drop off only, Pick up only) or the note.', 'End transportation: the student no longer receives transportation from the end date.', 'Show ended lists students whose transportation has ended.']);

// ------------------------------------------------------------------------------------------------ Staff
H1('Staff screen (office and admin)');
P('The Staff screen is where the office manages its teachers. It lists everyone at the campus with their email, role, number of current students and account status: Linked (they have signed in and are set up) or Waiting for account (added, but not signed in yet). Turn on Show retired to include former staff. Office managers see their own campus; admins choose any campus.');
H2('Add a teacher (new hire)');
OL(['Choose Add teacher.', 'Enter the name as "Last, First", their AACA work email, the campus and the start date.', 'Choose Save. They appear as Waiting for account.', 'Once the new teacher is in the attendance app\'s security group and opens the app, their access is set up automatically within about 15 minutes. You can assign students to them on the Students screen straight away.']);
P('Office managers can only add teachers. Other roles (office staff, administrators) are set up by the business office.');
H2('Edit');
P('Fix a name or email typo. Admins can also change a person\'s campus or role (only when they have no students).');
H2('Transfer class (a class gets a new teacher)');
OL(['Select the current teacher and choose Transfer class.', 'Choose the new teacher (active teachers at the same campus) and the effective date (the first day with the new teacher).', 'Check the preview: it lists every student who will move and anyone who will be skipped, with the reason.', 'Choose Save. Each student\'s enrollment with the old teacher ends the day before the effective date, and a new enrollment starts with the new teacher, keeping the same IEP ratio, program and campus. A receipt lists each student.']);
P('Attendance already recorded on or after the effective date stays with the old teacher. Students whose enrollment already has an end date are skipped; use Change class on the Students screen for them.');
H2('Retire and Reactivate');
P('Retire marks a teacher as no longer working at AACA, with an end date. It is only available once they have no students, so transfer their class first. Retired teachers no longer appear when assigning students. You cannot retire yourself. Reactivate brings a retired teacher back. Removing someone\'s Microsoft 365 account is handled by IT when they leave; the app does not need to do it.');

// ------------------------------------------------------------------------------------------------ Reminders
H1('Teams reminders');
P('The app sends reminders as Microsoft Teams chat messages from the Flow bot, only on school days:');
table([2400, 2200, 5120], [
  ['Reminder', 'When', 'What it says'],
  ['Teacher reminder', 'School days, 10:00 AM', 'Sent to a teacher who still has students not marked today, with their names.'],
  ['Office reminder', 'School days, 3:30 PM', 'Sent to the campus office when anything is still open: attendance not marked (and by which teachers), absences to classify, parent/teacher conflicts, transportation not confirmed, and Mapping Errors. No message if everything is done.'],
  ['Weekly summary', 'Fridays, 3:00 PM', 'Sent to each campus site administrator: the week\'s unmarked attendance, unconfirmed transportation days and open absence items.'],
]);

// ------------------------------------------------------------------------------------------------ FAQ
H1('Frequently asked questions');
FAQ('A parent reported an absence but the child came to school. What do I do?', 'If the teacher already marked the child present, the day is under Needs a decision: choose Keep present. If the day shows 0, tick it on the Classify absences tab, give a reason and choose Remove ticked.');
FAQ('A parent\'s report is not showing in the app.', 'Reports appear within about 5 minutes. If it is still missing, check the Mapping Errors tab: the Student ID may have been missing or mistyped.');
FAQ('Why is a day grey on the grid?', 'It is not a school day for that campus: a weekend, holiday, break, or a date outside the school term.');
FAQ('What does 1* mean?', 'The student was present but left early. The office records it on the Absences screen with the time and reason.');
FAQ('As a teacher, how do I fix an absence (0) that is wrong?', 'Teachers cannot change absences. Ask your campus office; they can remove it or resolve it under Needs a decision.');
FAQ('What is the difference between Excused and Unexcused?', 'The office decides. Excused absences need a reason (for example illness or appointment). Excused days show green on the grid; Unexcused days show red.');
FAQ('A student is moving to a different teacher. How do I move them?', 'Students screen: select the student and choose Change class, with the date of the move. To move a whole class, use Transfer class on the Staff screen.');
FAQ('A teacher is leaving. What do I do?', 'Transfer their class to the new teacher on the Staff screen, then Retire them.');
FAQ('A new teacher cannot see their students.', 'Check the Staff screen: if they show Waiting for account, they have not opened the app yet or their access is still being set up (up to 15 minutes after first sign-in). Also check that their students are assigned to them on the Students screen.');
FAQ('I did not get a Teams reminder.', 'Reminders only go out on school days and only when something is still open. Teachers only get one if a student is unmarked at 10:00. Your Staff record must have your email.');
FAQ('Can I take attendance for tomorrow?', 'No. Attendance can only be taken for today and past dates.');
FAQ('Who do I contact for help?', 'Teachers: your campus office manager. Office managers and site administrators: the business office.');

// ------------------------------------------------------------------------------------------------ Glossary
H1('Glossary');
table([2600, 7120], [
  ['Term', 'Meaning'],
  ['Enrollment', 'A student\'s assignment to one teacher, campus and IEP ratio for a period of time. A change of class or ratio ends one enrollment and starts the next.'],
  ['IEP ratio', 'The student\'s aide ratio from their IEP: No Aide, 1:1, 2:1, 3:1 or 4:1.'],
  ['Classification', 'Whether an absence is Excused or Unexcused, decided by the office.'],
  ['Parent report', 'An absence submitted by a parent through the Student Absence form.'],
  ['Mapping Errors', 'Parent reports the app could not match to a student.'],
  ['Needs a decision', 'Days where a parent reported an absence but the teacher marked the student present.'],
  ['Student ID / Student Key', 'The student\'s ID used on the parent absence form and in CodeMetro.'],
  ['Usual pattern', 'How a student normally travels: Round trip, Drop off only or Pick up only.'],
  ['Retired', 'A staff member who no longer works at AACA. Their history is kept.'],
  ['Month lock', 'A month closed for billing. Its attendance can no longer be changed.'],
]);

const doc = new Document({
  styles: { default: { document: { run: { font: 'Calibri', size: 22 } } } },
  numbering: { config: [
    { reference: 'bul', levels: [{ level: 0, format: LevelFormat.BULLET, text: '\u2022', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    ...numberingRefs.map((ref) => ({ reference: ref, levels: [{ level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] })),
  ] },
  sections: [{ properties: { page: { size: { width: 12240, height: 15840 }, margin: { top: 1080, bottom: 1080, left: 1260, right: 1260 } } }, children: kids }],
});
Packer.toBuffer(doc).then((b) => { const f = path.join(OUT, 'AACA Attendance App - User Guide.docx'); fs.writeFileSync(f, b); console.log('written', f); });
