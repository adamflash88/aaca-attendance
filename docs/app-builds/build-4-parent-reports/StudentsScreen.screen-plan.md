# Screen Plan: Students (build 4 — Student Key rule)

## Assignment

- Action: Modify
- Target file: `C:\src\aaca-attendance\app\StudentsScreen.pa.yaml`
- YAML key: StudentsScreen
- Control name prefix: Stu

Read `C:\src\aaca-attendance\app\canvas-app-shared.md` first.

## Current State

The add/edit form is `conStuForm` (inside `conStuRight`). Its `varStuMode` arms are "add", "edit", "transfer",
"ratio", "end" and "reenroll". `conStuFormIdentity` (Height 306, Visible in add/edit) holds five label/input
pairs. The last pair is `lblStuFormExt` / `txtStuFormExt`, the External Client ID input, which is currently
optional. `ddStuFormCampus` (in `conStuFormPlace`, Items `Sort(Campuses, Name, SortOrder.Ascending)`) supplies
the campus record, including `.Code`. `lblStuFormCheck` produces "Ready to save." or a blocking message, and
`btnStuFormSubmit` is gated on it. `colStuList` (built in `btnStuLoadEngine` from all Students) has an
`ExternalId` field.

Student Key = `Students.'External Client ID'`. Dataverse also enforces uniqueness through the alternate key
`aaca_student_key`.

## Changes

Only the controls and arms listed here change. Transfer, ratio, end, reenroll, list, detail and every other
control stay byte-for-byte unchanged.

1. `lblStuFormExt`: new label text (required on add, read-only on edit).
2. `txtStuFormExt`: suggested Default on add, read-only on edit, placeholder.
3. Add `lblStuFormExtNote` directly after `txtStuFormExt` inside `conStuFormIdentity`.
4. `conStuFormIdentity.Height` and `conStuForm.Height`: grow by the note height.
5. `lblStuFormCheck`: Student Key validation in the "add" arm.
6. `btnStuFormSubmit.OnSelect`:
   - "add" arm: live uniqueness guard, always write the key, receipt label.
   - "edit" arm: stop writing the key, receipt label.
7. `lblStuFormContext`: "add"/"edit" wording. `lblStuDetailFacts`: "External ID" becomes "Student Key".

## Layout and Visual Impact

- Breakpoint source: `conStuForm.Width < 700`. This is the existing form-level breakpoint (`n` in the
  conStuForm Height formula).
- Numeric budget: `conStuFormIdentity` = 5 labels × 18 + 5 inputs × 36 + note (36 | 54 narrow) + 10 gaps × 4.
  That is 346 wide or 364 narrow (was 306).
- Text fit: the note wraps to 2 lines (36) wide or 3 lines (54) narrow at Size 12. `lblStuFormCheck` keeps
  its existing heights (40 | 60). The longest new message is about 105 characters, which is 1 line wide and
  3 lines narrow.
- Visual contract: field label 12 Semibold ColorMuted; the note is 12 Normal ColorMuted.

## Required Record Fields

| Field key | Record surface | Required field | Source field | Bound control | Exact formula | Placement and visibility |
| --------- | -------------- | -------------- | ------------ | ------------- | ------------- | ------------------------ |
| STU-FORM-KEY | conStuForm (add/edit) | Student Key | Students.'External Client ID' | txtStuFormExt | Default below | 5th field in conStuFormIdentity; visible in add/edit |

## Controls to Add

- `lblStuFormExtNote`: ModernText, inserted immediately after `txtStuFormExt` in `conStuFormIdentity`.
  Properties:
  - AccessibleLabel `=Self.Text`, AlignInContainer `=AlignInContainer.Stretch`, Color `=ColorMuted`, Size 12
  - Height `=If(conStuForm.Width < 700, 54, 36)`, LayoutMinHeight 0, LayoutMinWidth 0
  - PaddingTop/Bottom/Left/Right 0, VerticalAlign `=VerticalAlign.Top`
  - Text:
    `=If(varStuMode = "edit", "Student Key can't be changed.", "Suggested from the campus code and the next number after the highest existing key. You can edit it; it must look like CW-1083 and be unique.")`

## Controls to Remove

None

## Properties to Update

- `lblStuFormExt.Text`: `=If(varStuMode = "edit", "Student Key (read-only)", "Student Key *")`
- `lblStuFormExt.AccessibleLabel`: `=Self.Text`
- `txtStuFormExt.AccessibleLabel`: `=lblStuFormExt.Text`
- `txtStuFormExt.Placeholder` (new): `="e.g. CW-1083"`
- `txtStuFormExt.DisplayMode` (new): `=If(varStuMode = "edit", DisplayMode.View, DisplayMode.Edit)`
- `txtStuFormExt.Default` (`|-` block):
  ```
  =If(
      varStuMode = "edit", Coalesce(varStuEditBase.'External Client ID', ""),
      varStuMode = "add" && !IsBlank(ddStuFormCampus.Selected) && Coalesce(ddStuFormCampus.Selected.Code, "") <> "",
      ddStuFormCampus.Selected.Code & "-" & Text(Coalesce(Max(Filter(colStuList, IsMatch(Coalesce(ExternalId, ""), "^[A-Z]{2,3}-\d+$")), Value(Last(Split(ExternalId, "-")).Value)), 0) + 1),
      ""
  )
  ```
  - The suggestion is the chosen campus's `Campuses.Code` + "-" + (the highest numeric suffix of any
    well-formed key across all loaded students + 1).
  - Changing the campus re-suggests the key, which replaces a typed key. This is intended: the key follows
    the campus until saved.
  - `btnStuFormResetEngine` already runs `Reset(txtStuFormExt)`, so opening Add or Edit shows the Default.
- `conStuFormIdentity.Height`: `=If(conStuForm.Width < 700, 364, 346)`
- `conStuForm.Height`: in the existing With formula, replace the line
  `+ If(m in ["add", "edit"], 306 + 8, 0)` with `+ If(m in ["add", "edit"], If(n, 364, 346) + 8, 0)`.
  All other lines stay unchanged.
- `lblStuFormCheck.Text`:
  - In the first With record, add `key: Trim(txtStuFormExt.Text)` after `cmp: ddStuFormCampus.Selected, tch: ddStuFormTeacher.Selected`.
  - In the second With record, add `keyUsed: If(key = "", Blank(), LookUp(colStuList, Lower(Coalesce(ExternalId, "")) = Lower(key)))`.
  - In the `varStuMode = "add"` arm, insert these three condition/result pairs immediately after the existing
    pair `StudentCampusLock <> ZeroGuid && cmp.Campus <> StudentCampusLock, "Office staff can add students only to their own campus.",`:
    ```
    key = "", "Enter a Student Key, for example " & cmp.Code & "-1001.",
    !IsMatch(key, "^[A-Z]{2,3}-\d+$"), "Student Key must be 2–3 capital letters, a dash and digits, like CW-1083.",
    !IsBlank(keyUsed), "Student Key " & key & " is already used by " & keyUsed.DisplayName & " (" & keyUsed.StudentNumber & "). Use a different key.",
    ```
  - The "edit" arm stays unchanged. Its no-change comparison still includes the read-only key, which
    compares equal.
- `btnStuFormSubmit.OnSelect`, "add" arm:
  - Change `{yr: LookUp('School Years', 'Start Date' <= eff && 'End Date' >= eff), liveDup: CountRows(Filter(Students, 'First Name' = fn && 'Last Name' = ln && 'Date of Birth' = dob))}`
    to `{yr: LookUp('School Years', 'Start Date' <= eff && 'End Date' >= eff), liveDup: CountRows(Filter(Students, 'First Name' = fn && 'Last Name' = ln && 'Date of Birth' = dob)), liveKey: With({k: ext}, CountRows(Filter(Students, 'External Client ID' = k)))}`.
  - Make this the first condition of the following `If(`, before `liveDup > 0 && !dupAck`:
    `liveKey > 0,`
    `Set(varStuReceipt, {Kind: "Blocked", Title: "Not saved. Student Key " & ext & " is already used by another student. Choose a different key.", StudentId: Coalesce(q, ZeroGuid)}); Clear(colStuReceiptLines),`
  - In the Students create Patch, change `'External Client ID': If(ext = "", Blank(), ext)` to
    `'External Client ID': ext`.
  - In the add receipt lines, change `{Label: "External client ID", Value: Coalesce(s.'External Client ID', "—")}`
    to `{Label: "Student Key", Value: Coalesce(s.'External Client ID', "—")}`.
  - A Dataverse alternate-key violation makes the existing `IfError(Patch(...), Blank())` blank, which already
    produces the existing "Failed … nothing was saved" receipt. Keep it.
- `btnStuFormSubmit.OnSelect`, "edit" arm:
  - In `Patch(Students, old, {...})`, delete `, 'External Client ID': If(ext = "", Blank(), ext)`. The key is
    preserved by omission.
  - In the edit receipt lines, change `{Label: "External client ID", Value: Coalesce(s.'External Client ID', "—")}`
    to `{Label: "Student Key", Value: Coalesce(s.'External Client ID', "—") & " (unchanged)"}`.
  - Leave the audit Before/After JSON unchanged. Both show the same ExternalClientId.
- `lblStuFormContext.Text`: change the two Switch results:
  - "add" → `"Creates the student (Active, new student number, Student Key), their enrollment and an audit entry. Fields marked * are required."`
  - "edit" → `"Corrects name, date of birth and grade only. The Student Key can't be changed. Enrollments are unchanged; the audit log keeps before and after values."`
- `lblStuDetailFacts.Text`: replace `" · External ID "` with `" · Student Key "`. The rest of the formula
  stays unchanged.

## Required Actions

| Action | Preconditions | Entry point and event | Source and stable ID | Transition and postcondition | Mutation write set | Receipt proof set | Observer and evidence |
| ------ | ------------- | --------------------- | -------------------- | ---------------------------- | ------------------ | ----------------- | --------------------- |
| A-ADD-STUDENT | CanManageStudents; varStuMode "add"; lblStuFormCheck "Ready to save." | btnStuAdd → form → `btnStuFormSubmit.OnSelect` | New Students row `s.Student` | Existing create + enrollment + audit. The key is required, well-formed, and unique in the cache and live | Existing fields + 'External Client ID' = ext | Existing lines incl. "Student Key" = s.'External Client ID' | galStuReceipt; colStuList reload; lblStuDetailFacts |
| A-EDIT-STUDENT | varStuMode "edit" | btnStuActEdit → `btnStuFormSubmit.OnSelect` | Students `q` | The key is read-only and not written; other fields as before | First/Last/Display/DOB/Grade | Existing lines; "Student Key … (unchanged)" | galStuReceipt; audit Before = After for the key |

## Data Entry Label Contracts

| Required input | Persistent visible label | Shared field region |
| -------------- | ------------------------ | ------------------- |
| txtStuFormExt | `lblStuFormExt.Text: =If(varStuMode = "edit", "Student Key (read-only)", "Student Key *")` | conStuFormIdentity |

## Mutation Lifecycle Evidence

| Action | Receipt binding | Canonical source and observer | Requested destination and observer | Stable ID continuity | Synchronization | Destination focus |
| ------ | --------------- | ----------------------------- | ---------------------------------- | -------------------- | --------------- | ----------------- |
| A-ADD-STUDENT | varStuReceipt + colStuReceiptLines from `s` | Students `s.Student` | galStuList / detail | s.Student | Existing `Select(btnStuLoadEngine)` | Existing `Set(varStuSelId, s.Student)` |
| A-EDIT-STUDENT | Same, from `s` | Students `q` | detail | q = s.Student | Existing | Existing |

## Mutation Field Ledger

| Action | Field | Classification | Canonical pre-state or input | Write or preservation mechanism | Receipt/proof binding | Post-state observer |
| ------ | ----- | -------------- | ---------------------------- | ------------------------------- | --------------------- | ------------------- |
| A-ADD-STUDENT | 'External Client ID' | Changed | `Trim(txtStuFormExt.Text)` | `'External Client ID': ext` | `{Label: "Student Key", Value: Coalesce(s.'External Client ID', "—")}` | colStuList.ExternalId; lblStuDetailFacts |
| A-EDIT-STUDENT | 'External Client ID' | Preserved | varStuEditBase.'External Client ID' | Omitted from the edit Patch; input DisplayMode View | `"Student Key" … " (unchanged)"` | Audit Before/After ExternalClientId equal |

## Functional Test Scenarios

| Scenario | Given | When | Then | Evidence surface | Boundary or negative case |
| -------- | ----- | ---- | ---- | ---------------- | ------------------------- |
| S-KEY-SUGGEST | The highest well-formed key suffix is 1126 (e.g. AV-1126) | + Add student, choose campus Oxnard (Code OX) | txtStuFormExt shows OX-1127; editable | Input; lblStuFormExtNote | No campus chosen → key empty; lblStuFormCheck says "Choose a campus." first |
| S-KEY-DUP | CW-1083 belongs to Garcia, Ana | Add with key CW-1083, everything else valid | Nothing saved | lblStuFormCheck "Student Key CW-1083 is already used by Garcia, Ana (STU-…)…"; submit disabled | Key taken by another user after the check → Blocked receipt from liveKey; alternate-key violation → existing Failed receipt |
| S-KEY-FORMAT | Otherwise valid Add form | Key "cw1083", then "" | Nothing saved | "Student Key must be 2–3 capital letters…" / "Enter a Student Key…" | N/A |
| S-KEY-READONLY | Student with key CW-1083 | Edit details, change First name, Save details | First name saved; key still CW-1083 and not written | txtStuFormExt View mode; note "Student Key can't be changed."; receipt "Student Key: CW-1083 (unchanged)" | Legacy student with blank key → shown blank, read-only |
| S-REGRESSION | Any student | Transfer / ratio / end / re-enroll / list filters | Identical to build 3 | Existing receipts | N/A |

## Relevant Data Source Schemas

- Students: Student (GUID); 'External Client ID' (Text; Dataverse alternate key `aaca_student_key`, unique);
  'Display Name'; 'Student Number'.
- Campuses: Campus; Name; Code (e.g. AV, CW, OX).
- colStuList (screen cache): StudentId, DisplayName, StudentNumber, ExternalId, …

## Changed or Added Control Definitions

- **ModernTextInput** (`Control: ModernTextInput`). Inputs:
  - AccessibleLabel, Align, Appearance, BasePaletteColor, BorderColor, BorderStyle, BorderThickness, Color,
    ContentLanguage, Default, DisplayMode, Fill, Font, FontWeight, Height
  - Italic, MaxLength, OnChange, Padding*, Placeholder, Radius*, Required, Size, Strikethrough,
    TriggerOutput, Type, Underline, ValidationState, Visible, Width, X, Y
  - AutoLayout child properties
  - Output: Text
  - Enum literals set by this edit: `DisplayMode.View`, `DisplayMode.Edit` (Enum name `DisplayMode`)
- **ModernText** (`Control: ModernText`). Inputs:
  - AccessibleLabel, Align, AutoHeight, BorderColor, BorderStyle, BorderThickness, Color, ContentLanguage,
    DisplayMode, Fill, Font, FontWeight, Height, Italic, OnSelect
  - PaddingBottom, PaddingLeft, PaddingRight, PaddingTop, Radius*, Size, Strikethrough, Text, Underline,
    VerticalAlign, Visible, Width, Wrap, X, Y
  - AutoLayout child properties
  - Enum literals: `=AlignInContainer.Stretch`, `=VerticalAlign.Top`
