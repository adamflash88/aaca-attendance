// Builds three role questionnaires (.docx) laid out for Microsoft Forms "Quick import":
// numbered questions, each followed by its answer choices as a bulleted list; questions without choices become text.
const fs = require('fs');
const path = require('path');
const { Document, Packer, Paragraph, TextRun, HeadingLevel, LevelFormat, AlignmentType } = require('docx');

const OUT = 'C:\\Users\\AdamBernstein\\OneDrive - AACA\\06 - Information Technology\\03 - App Projects\\PowerApps\\AACA-Attendance\\pilot-questionnaires';
fs.mkdirSync(OUT, { recursive: true });

const RESULT = ['Worked as expected', 'Worked, but it was confusing', 'Did not work', 'I could not find it', 'I did not try this'];
const YESNO = ['Yes', 'No', 'Not sure'];
const CAMPUS = ['Antelope Valley', 'Chatsworth', 'Oxnard'];
const DEVICE = ['Windows computer', 'Mac', 'iPad or tablet', 'Phone'];
const BROWSER = ['Microsoft Edge', 'Google Chrome', 'Safari', 'Other'];
const REMINDER = ['Yes, and it was accurate', 'Yes, but the numbers or names were wrong', 'No, I did not get one', 'Not sure'];
const EASE = ['1 - Very hard', '2', '3', '4', '5 - Very easy'];

// q(text, choices?) ; note(text) adds a plain instruction line (not a question)
const q = (text, choices) => ({ text, choices });
const note = (text) => ({ note: text });

function build(file, title, intro, sections) {
  const children = [
    new Paragraph({ heading: HeadingLevel.TITLE, children: [new TextRun(title)] }),
    ...intro.map((t) => new Paragraph({ spacing: { after: 120 }, children: [new TextRun(t)] })),
  ];
  let n = 0;
  for (const s of sections) {
    children.push(new Paragraph({ heading: HeadingLevel.HEADING_1, spacing: { before: 280 }, children: [new TextRun(s.title)] }));
    for (const item of s.items) {
      if (item.note) {
        children.push(new Paragraph({ spacing: { after: 120 }, children: [new TextRun({ text: item.note, italics: true })] }));
        continue;
      }
      n += 1;
      // Forms Quick import: questions = Word numbered list (level 0), choices = lettered sub-list (level 1) under it.
      children.push(new Paragraph({ numbering: { reference: 'q', level: 0 }, spacing: { before: 160, after: 60 }, children: [new TextRun(item.text)] }));
      for (const c of item.choices || []) {
        children.push(new Paragraph({ numbering: { reference: 'q', level: 1 }, children: [new TextRun(c)] }));
      }
    }
  }
  const doc = new Document({
    styles: { default: { document: { run: { font: 'Calibri', size: 22 } } } },
    numbering: { config: [{ reference: 'q', levels: [
      { level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 360, hanging: 360 } } } },
      { level: 1, format: LevelFormat.LOWER_LETTER, text: '%2.', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 1080, hanging: 360 } } } },
    ] }] },
    sections: [{ properties: { page: { size: { width: 12240, height: 15840 }, margin: { top: 1080, bottom: 1080, left: 1260, right: 1260 } } }, children }],
  });
  return Packer.toBuffer(doc).then((b) => fs.writeFileSync(path.join(OUT, file), b));
}

const INTRO = (role) => [
  `Thank you for helping us pilot the AACA Attendance app. This form walks you through the tasks a ${role} does in the app. For each task, try it in the app, then tell us how it went.`,
  'Use the pilot (Test) version of the app from the link you were sent. It is a copy of our real data, so it is safe to try things. If something does not work, the "What happened?" boxes are the most useful part of this form: tell us what you did and what you saw.',
];
const ABOUT = (roles) => ({
  title: 'About you',
  items: [
    q('Your name'),
    ...(roles ? [q('Your role', roles)] : []),
    q('Your campus', roles ? [...CAMPUS, 'All campuses (business office)'] : CAMPUS),
    q('What did you use to test the app?', DEVICE),
    q('Which web browser did you use?', BROWSER),
  ],
});
const OVERALL = (taskName) => ({
  title: 'Overall',
  items: [
    q(`Overall, how easy was ${taskName}?`, EASE),
    q('Did anything not work, look wrong, or confuse you? Please describe it.'),
    q('Is there anything you wish the app did, or did differently? (feature requests and ideas)'),
    q('Any other feedback?'),
  ],
});

// ---------------------------------------------------------------- Teachers
const teacher = build('AACA Attendance Pilot - Teachers.docx', 'AACA Attendance Pilot: Teachers', INTRO('teacher'), [
  ABOUT(null),
  { title: 'Getting in', items: [
    q('Open the app and sign in. At the top, do you see your name and the word "Teacher"?', YESNO),
    q('Does your grid list all of your current students, with no one missing and no one extra?', ['Yes, the list is correct', 'Someone is missing', 'Someone is listed who should not be', 'Not sure']),
    q('If someone is missing or should not be listed, who? (first name and last initial is fine)'),
  ] },
  { title: 'Taking attendance', items: [
    note('Do these on a school day, using today\'s column.'),
    q('Tap the blank square for a student who is here today. Did it change to a 1 and stay that way?', RESULT),
    q('Tap a 1 you just added, then choose Confirm undo. Did the square go back to blank?', RESULT),
    q('Tap All present for today. Did it fill in the blank squares, and leave squares that already had a mark alone?', RESULT),
    q('Find a 0 on your grid (an absence reported by a parent or the office) and tap it. Were you prevented from changing it?', ['Yes, I could not change it', 'No, I was able to change it', 'There were no 0s on my grid']),
    q('If you see a 1* (a student the office recorded as leaving early), tap it. Were you prevented from undoing it?', ['Yes, I could not undo it', 'No, I was able to undo it', 'There were no 1* marks on my grid']),
    q('What happened? (anything about the tasks above that did not work as you expected)'),
  ] },
  { title: 'Looking around', items: [
    q('Use the month and year pickers, the Prev and Next buttons, and This month. Did the grid move to the right month each time?', RESULT),
    q('Pick another teacher at your campus from the Teacher list. Could you see their grid without being able to change it?', ['Yes, I could see it but not change it', 'I was able to change it', 'I could not see other teachers']),
    q('Grey squares are days with no school. Do the grey days this month match your campus calendar (weekends, holidays, breaks)?', YESNO),
    q('If any days are wrong, which dates?'),
  ] },
  { title: 'Teams reminder', items: [
    note('On school days at 10:00, the Flow bot sends you a Teams message if any of your students are not marked yet. To test it, leave a student unmarked until after 10:00 one day.'),
    q('Did you get the 10:00 Teams reminder on a day you had not finished attendance, and did it list the right students?', REMINDER),
    q('Did you get a reminder on a day you had already marked everyone?', ['No (correct)', 'Yes, I got one anyway', 'Not sure']),
    q('How do you feel about the reminder?', ['Helpful', 'Fine either way', 'Too much / annoying']),
  ] },
  { title: 'Your routine', items: [
    q('About how long does taking attendance in the app take you each day?', ['Less than 1 minute', '1 to 3 minutes', '3 to 5 minutes', 'More than 5 minutes']),
    q('When do you usually take attendance?', ['First thing in the morning', 'During the morning', 'After lunch', 'At the end of the day']),
  ] },
  OVERALL('taking attendance in the app'),
]);

// ------------------------------------------------- Office managers & site administrators
const officeSections = (allCampuses) => [
  { title: 'Getting in', items: [
    q('Open the app and sign in. At the top, do you see your name and your role?', YESNO),
    q(allCampuses ? 'Can you switch between all three campuses with the Campus picker?' : 'On the Students screen, do you see only students from your own campus?', YESNO),
    q('On the Attendance grid, tap a few squares. The grid is view-only for your role: did the squares stay unchanged?', ['Yes, nothing changed', 'No, I was able to change a square']),
  ] },
  { title: 'Absences: Classify absences', items: [
    note('Open Absences. The Classify absences tab lists absences that still need Excused or Unexcused. Absences reported by parents appear here automatically.'),
    q('Does each absence show the parent\'s reason and when they reported it?', RESULT),
    q('Tick an absence, choose a reason, and click Mark Excused. Does that day turn green on the student\'s attendance grid?', RESULT),
    q('Tick an absence and click Mark Unexcused. Does that day turn red on the grid?', RESULT),
    q('Remove absence: if a parent reported an absence but the child came to school, tick it, give a reason and remove it. Did the 0 disappear from the grid?', [...RESULT, 'I had no absence that needed removing']),
    q('Needs a decision (shown at the top when there are any): for a day where a parent reported an absence but the teacher marked the student present, choose Keep present or Mark absent. Did it do what you chose?', [...RESULT, 'Nothing was listed under Needs a decision']),
    q('What happened? (anything about the tasks above that did not work as you expected)'),
  ] },
  { title: 'Absences: adding them yourself', items: [
    q('Add absence: record an absence for a student whose parent did not notify us (pick the student, dates and Excused or Unexcused). Does it appear on the grid already classified?', RESULT),
    q('Left early: record a student who came to school and left early (time and reason). Does that day show 1* on the grid?', RESULT),
    q('What happened?'),
  ] },
  { title: 'Absences: Mapping Errors', items: [
    note('Mapping Errors lists parent reports the app could not match to a student, usually because of a name typo. Only map a report when you are sure which student it is: mapping updates the real parent report.'),
    q('Open the Mapping Errors tab. Does the number on the tab match the number of reports in the list?', RESULT),
    q('Open a report and map it to the correct student. About 5 minutes later, did the absence appear in Classify absences?', [...RESULT, 'There were no reports to map']),
    q('Dismiss a report that is a duplicate or a test entry (a reason is required). Did it leave the list?', [...RESULT, 'There was nothing to dismiss']),
    q('What happened?'),
  ] },
  { title: 'Students', items: [
    note('If you have no real changes to make, you can add a clearly named test student (for example "Test, Pilot") and end their enrollment afterwards.'),
    q('Add a student. Did the app give them a Student ID automatically, and do they appear on the right teacher\'s grid?', RESULT),
    q('Change class: move a student to another teacher from a chosen date. Did their past days stay with the old teacher and new days go to the new one?', RESULT),
    q('Change ratio: change a student\'s aide ratio from a chosen date. Did it save?', RESULT),
    q('End enrollment, then Re-enroll the same student. Did both work?', RESULT),
    q('What happened?'),
  ] },
  { title: 'Transportation', items: [
    q('Open Transportation. On the Daily tab, does the list show the students at your campus who get transportation?', ['Yes, the list is correct', 'Someone is missing', 'Someone is listed who should not be', 'I could not find the Transportation screen']),
    q('If someone is missing or should not be listed, who?'),
    q('Were absent students already set to "No transportation" (and students who left early to "Drop off only")?', YESNO),
    q('Choose Round trip, Drop off only, Pick up only or No transportation for each student, then click Confirm day. Did it save and show who confirmed it?', RESULT),
    q('On the Students tab, try Add, Change pattern and End transportation for a student. Did they work?', RESULT),
    q('What happened?'),
  ] },
  { title: 'Staff', items: [
    note('Open Staff. Use a clearly named test teacher (for example "Test, Pilot Teacher") for the add, transfer and retire steps, so real teachers are not changed.'),
    q(allCampuses ? 'Can you switch the Staff screen between all three campuses, and does each list the right people?' : "Does the Staff screen list your campus's teachers correctly (names, emails, number of students)?", [...RESULT.slice(0, 3), 'I could not find the Staff screen']),
    q('Add teacher: add the test teacher with a made-up work email. Did it save and appear in the list as "Waiting for account"?', RESULT),
    q("Edit: change the test teacher's name. Did it save?", RESULT),
    q('Transfer class: open it for a teacher with students and look at the preview (you can cancel instead of saving). Did the preview list the right students?', RESULT),
    q('Retire: retire the test teacher. Did it work, and did they disappear from the teacher list when adding a student?', RESULT),
    q('What happened?'),
  ] },
  { title: 'Teams reminders', items: [
    note('On school days at 3:30 PM, the Flow bot sends the campus office a Teams message listing anything still open (attendance not marked, absences to classify, conflicts, transportation not confirmed, Mapping Errors). Nothing open = no message.'),
    q('Did you get the 3:30 reminder on a day with open items, and did its numbers match what the app showed?', REMINDER),
    ...(allCampuses ? [] : [q('Site administrators only: did you get the Friday weekly summary, and was it useful?', ['Yes, and it was useful', 'Yes, but it was not useful or not accurate', 'No, I did not get one', 'I am not a site administrator'])]),
    q('Is anything missing from the reminders, or is there anything you would remove?'),
  ] },
  { title: 'Your routine', items: [
    q('How long did classifying today\'s absences and confirming transportation take you?', ['Less than 5 minutes', '5 to 15 minutes', '15 to 30 minutes', 'More than 30 minutes']),
  ] },
  OVERALL('the app for your daily office tasks'),
];

const office = build('AACA Attendance Pilot - Office and Site Administrators.docx', 'AACA Attendance Pilot: Office Managers and Site Administrators',
  INTRO('campus office manager or site administrator'), [ABOUT(['Office manager', 'Site administrator']), ...officeSections(false)]);

const admin = build('AACA Attendance Pilot - Business Office Admins.docx', 'AACA Attendance Pilot: Business Office Admins',
  [...INTRO('business-office admin'), 'You can see all campuses. Use the Campus picker to try each task at more than one campus. If you only have view access, answer the viewing questions and choose "I did not try this" for the rest.'],
  [ABOUT(['System admin', 'Read-only (view access)']), ...officeSections(true)]);

Promise.all([teacher, office, admin]).then(() => console.log('written to', OUT));
