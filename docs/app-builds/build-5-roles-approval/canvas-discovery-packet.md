# Discovery Packet — AACA Attendance build 1 (captured 2026-09-28 by the orchestrator)

All results below come from the live coauthoring session (environment a4c9f4ce-b971-edf2-beba-e3c29552a316,
app fb649976-33fb-4419-8ee6-132c204df470). Control property lists are exact `describe_control` results,
condensed to one line per property ("Name: Type = Default [Enum name: X; values: ...]").

## list_apis

Available APIs: 1 — Users

## list_data_sources (13, all Kind CdsNative, Writable, Delegatable)

Absence Reasons, App Settings, Attendance, Audit Events, Calendar Exceptions, Campuses, Enrollments,
Month Locks, School Years, Services, Staff, Students, Terms, Users

## list_controls (relevant excerpt; full catalog also includes Classic, FluentV9 and AI controls)

ModernAvatar, ModernButton, ModernCard, ModernCheckbox, ModernCombobox, ModernDataGrid, ModernDataGridColumn,
ModernDatePicker, ModernDropdown, ModernIcon, ModernInformationButton, ModernLink, ModernNumberInput,
ModernProgressBar, ModernRadio, ModernRating, ModernSlider, ModernSpinner, ModernTabList, ModernText,
ModernTextInput, ModernToggle, Classic/Button, Classic/Icon, Gallery, GroupContainer, Rectangle, Label,
Badge, Progress, Spinner, TabList, Text, Button, Timer, ...

## Verified Power Fx (compiled PASSED against this app on 2026-09-28)

These formulas compiled with zero errors in App.Formulas and are the authoritative syntax:

```
LookUp(Users, 'Primary Email' = User().Email)                       // current Users row
LookUp(Staff, User.User = <usersRow>.User)                          // Staff row for that user (lookup id compare)
<staff>.'App Role' = 'App Role (Staff)'.Teacher                     // also 'Attendance Office', 'Read-only', 'System Admin'
Filter(Attendance, Teacher.Staff = <staff>.Staff && Date >= Date(2026,9,1) && Date <= Date(2026,9,30))
If(First(Attendance).Present, 1, 0)                                 // Present is Boolean (Yes/No two-option)
First(Attendance).'Is Deleted'                                      // Boolean
First(Attendance).'Absence Classification' = 'Absence Classification (Attendance)'.Excused   // also .Unexcused; blank = not classified
Filter(Enrollments, Teacher.Staff = <staff>.Staff && 'Start Date' <= <monthEnd> && (IsBlank('End Date') || 'End Date' >= <monthStart>))
First(Enrollments).Program = 'Program (Enrollments)'.Summer         // also 'Regular Year'
LookUp('App Settings', Key = "AllowFutureDates").Value              // Text "true"/"false"
LookUp('Month Locks', Campus.Campus = <campusId> && Month = Date(2026,9,1) && 'Status (aaca_status)' = 'Status (Month Locks)'.Locked)
First(Terms).'Term (aaca_term)' = 'Term (Terms)'.Summer             // Q1, Q2, Q3, Q4, Summer
First('Calendar Exceptions').Type = 'Type (Calendar Exceptions)'.'Make-up School Day'   // Holiday, Break, 'Staff Development', Closure
First(Attendance).'Modified On'                                     // DateTime, for concurrency check
First(Enrollments).'IEP Ratio' = 'IEP Ratio (Enrollments)'.'1:1'   // 'No Aide', '1:1', '2:1', '3:1', '4:1'
First(Enrollments).Student.'Student Number'                         // related-record field access
```

Dataverse writes: use `Patch(Attendance, <existing record or Defaults(Attendance)>, {...})` with lookup
columns set to records (e.g. `Student: <Students record>`, `Teacher: <Staff record>`). Lookup id fields are
`Students.Student`, `Staff.Staff`, `Campuses.Campus`, `Enrollments.Enrollment`, `Services.Service`,
`'School Years'.'School Year'`, `Terms.'Term (aaca_termid)'`, `Attendance.Attendance`.

## Data source schemas (relevant columns; logical name — Display: Type)

### Attendance (unique key: Student + Service + Date)
- aaca_attendanceid — "Attendance": Guid
- aaca_recordkey — "Record Key": String (primary name; set to Text(date,"yyyymmdd") & "|" & StudentNumber & "|" & ServiceCode)
- aaca_date — "Date": Date
- aaca_present — "Present": Boolean (option set "Present (Attendance)": Yes, No)
- aaca_isdeleted — "Is Deleted": Boolean (option set "Is Deleted (Attendance)": Yes, No)
- aaca_student — "Student": lookup Students
- aaca_service — "Service": lookup Services
- aaca_enrollment — "Enrollment": lookup Enrollments
- aaca_teacher — "Teacher": lookup Staff
- aaca_campus — "Campus": lookup Campuses
- aaca_schoolyear — "School Year": lookup School Years
- aaca_term — "Term": lookup Terms
- aaca_iepratio — "IEP Ratio": option set "IEP Ratio (Attendance)": No Aide, 1:1, 2:1, 3:1, 4:1
- aaca_classification — "Absence Classification": option set "Absence Classification (Attendance)": Excused, Unexcused (column-secured; read-only in this build)
- aaca_absencereason — "Absence Reason": lookup Absence Reasons (secured, read-only)
- aaca_classifiedby — "Classified By": lookup Users (secured, read-only)
- aaca_classifiedon — "Classified On": DateTime (secured, read-only)
- aaca_notes — "Notes": String (max 2000)
- modifiedon — "Modified On": DateTime

### Enrollments
- aaca_enrollmentid — "Enrollment": Guid; aaca_name — "Name": String
- aaca_student — "Student": lookup Students; aaca_campus — "Campus": lookup Campuses
- aaca_teacher — "Teacher": lookup Staff; aaca_service — "Service": lookup Services
- aaca_schoolyear — "School Year": lookup School Years
- aaca_program — "Program": option set "Program (Enrollments)": Regular Year, Summer
- aaca_iepratio — "IEP Ratio": option set "IEP Ratio (Enrollments)": No Aide, 1:1, 2:1, 3:1, 4:1
- aaca_startdate — "Start Date": Date; aaca_enddate — "End Date": Date (blank = open)
- aaca_status — "Status (aaca_status)": option set "Status (Enrollments)": Planned, Active, Ended

### Staff
- aaca_staffid — "Staff": Guid; aaca_name — "Name": String
- aaca_approle — "App Role": option set "App Role (Staff)": Teacher, Attendance Office, Read-only, System Admin
- aaca_campus — "Campus": lookup Campuses (blank = all campuses)
- aaca_user — "User": lookup Users
- aaca_active — "Active": Boolean (option set "Active (Staff)": Yes, No)

### Students
- aaca_studentid — "Student": Guid; aaca_displayname — "Display Name": String ("Last, First")
- aaca_studentnumber — "Student Number": String (STU-000123)
- aaca_status — "Status (aaca_status)": option set "Status (Students)": Active, Inactive, Archived

### Terms
- aaca_termid — "Term (aaca_termid)": Guid; aaca_name — "Name": String
- aaca_schoolyear — "School Year": lookup School Years; aaca_campus — "Campus": lookup Campuses (blank = all)
- aaca_term — "Term (aaca_term)": option set "Term (Terms)": Q1, Q2, Q3, Q4, Summer
- aaca_startdate — "Start Date": Date; aaca_enddate — "End Date": Date

### Calendar Exceptions
- aaca_calendarexceptionid — "Calendar Exception": Guid; aaca_name — "Description": String
- aaca_date — "Date": Date; aaca_campus — "Campus": lookup Campuses (blank = all)
- aaca_type — "Type": option set "Type (Calendar Exceptions)": Holiday, Break, Staff Development, Closure, Make-up School Day

### Month Locks
- aaca_monthlockid — "Month Lock": Guid; aaca_name — "Name": String
- aaca_campus — "Campus": lookup Campuses; aaca_month — "Month": Date (first of month)
- aaca_status — "Status (aaca_status)": option set "Status (Month Locks)": Locked, Unlocked
- aaca_reason — "Reason": String; aaca_lockedon — "Locked On": DateTime; aaca_lockedby — "Locked By": lookup Users

### App Settings
- aaca_settingid — "Setting": Guid; aaca_key — "Key": String; aaca_value — "Value": String; aaca_description — "Description": String
- Rows: AllowFutureDates = "false"; AbsenceAlertPerTerm; ConsecutiveAbsenceAlert; UnclassifiedAgingDays

### Services
- aaca_serviceid — "Service": Guid; aaca_name — "Name": String; aaca_servicecode — "Service Code": String ("SPED")
- aaca_active — "Active": Boolean

### Campuses
- aaca_campusid — "Campus": Guid; aaca_name — "Name": String; aaca_code — "Code": String; aaca_active — "Active": Boolean

### School Years
- aaca_schoolyearid — "School Year": Guid; aaca_name — "Name": String
- aaca_startdate — "Start Date": Date; aaca_enddate — "End Date": Date
- aaca_status — "Status (aaca_status)": option set "Status (School Years)": Planned, Current, Closed

### Audit Events
- aaca_auditeventid — "Audit Event": Guid; aaca_name — "Summary": String
- aaca_action — "Action": option set "Action (Audit Events)": Create, Update, Soft Delete, Restore, Transfer, Discharge, Archive, Unarchive, Reclassify, Lock, Unlock, Override, Rollover
- aaca_entity — "Entity": String; aaca_entityid — "Entity ID": String
- aaca_before — "Before": String; aaca_after — "After": String; aaca_reason — "Reason": String

### Users (systemuser; 2,591-line schema, relevant columns only)
- systemuserid — "User": Guid; internalemailaddress — "Primary Email": String
- fullname — "Full Name": String; domainname — "User Name": String; azureactivedirectoryobjectid — "Azure AD Object ID": Guid

## describe_control results

### GroupContainer — family Classic
Creation: `Control: GroupContainer` + `Variant:` (required) AutoLayout | GridLayout | ManualLayout
Common inputs: BorderColor: Color = RGBA(0,0,0,1); BorderStyle: Enum = BorderStyle.Solid [Enum name: BorderStyle; Dashed, Dotted, None, Solid]; BorderThickness: Number = 0; ContentLanguage: Text; DropShadow: Enum = DropShadow.Light [Enum name: DropShadow; Bold, ExtraBold, Light, None, Regular, Semibold, Semilight]; EnableChildFocus: Boolean = true; Fill: Color = RGBA(0,0,0,0); Height: Number = 200; RadiusBottomLeft/RadiusBottomRight/RadiusTopLeft/RadiusTopRight: Number = 4; Visible: Boolean = true; Width: Number = 500; X, Y: Number = 0
AutoLayout inputs: LayoutAlignItems: Enum = LayoutAlignItems.Start [Enum name: LayoutAlignItems; Center, End, Start, Stretch]; LayoutDirection: Enum (Required) [Enum name: LayoutDirection; Horizontal, Vertical]; LayoutGap: Number = 0; LayoutJustifyContent: Enum = LayoutJustifyContent.Start [Enum name: LayoutJustifyContent; Center, End, SpaceBetween, Start]; LayoutOverflowX: Enum = LayoutOverflow.Hide [Enum name: LayoutOverflow; Hide, Scroll]; LayoutOverflowY: Enum = LayoutOverflow.Hide [Enum name: LayoutOverflow; Hide, Scroll]; LayoutWrap: Boolean = false; PaddingBottom/PaddingLeft/PaddingRight/PaddingTop: Number = 0
ManualLayout inputs: ChildTabPriority: Boolean = true; Padding*: Number = 0
As child of AutoLayout: AlignInContainer: Enum = AlignInContainer.Stretch [Enum name: AlignInContainer; Center, End, SetByContainer, Start, Stretch]; FillPortions: Number = 1; LayoutMaxHeight: Number = 0; LayoutMaxWidth: Number = 0; LayoutMinHeight: Number = 100; LayoutMinWidth: Number = 250
Outputs include Height, Width, Visible, Fill.

### ModernText — family React
Creation: `Control: ModernText`
Inputs: AccessibleLabel: Text; Align: Enum = Align.Left [Enum name: Align; Center, Justify, Left, Right]; AutoHeight: Boolean = false; BorderColor: Color; BorderStyle: Enum [BorderStyle]; BorderThickness: Number; Color: Color; ContentLanguage: Text; DisplayMode: Enum = DisplayMode.Edit [Enum name: DisplayMode; Disabled, Edit, View]; Fill: Color; Font: Enum [Enum name: Font; Arial, Courier New, Dancing Script, Georgia, Great Vibes, Lato, Lato Black, Lato Hairline, Lato Light, Open Sans, Open Sans Condensed, Patrick Hand, Segoe UI, Verdana]; FontWeight: Enum = FontWeight.Normal [Enum name: FontWeight; Bold, Lighter, Normal, Semibold]; Height: Number = 32; Italic: Boolean; OnSelect: Boolean; PaddingBottom/Left/Right/Top: Number = 5; Radius*: Number; Size: Number = 15; Strikethrough: Boolean; Text: Text = "Text"; Underline: Boolean; VerticalAlign: Enum = VerticalAlign.Middle [Enum name: VerticalAlign; Bottom, Middle, Top]; Visible: Boolean = true; Width: Number = 150; Wrap: Boolean = true; X, Y
As AutoLayout child: AlignInContainer: Enum = AlignInContainer.SetByContainer; FillPortions: Number = 0; LayoutMaxHeight = 0; LayoutMaxWidth = 0; LayoutMinHeight = 32; LayoutMinWidth = 150

### ModernButton — family React
Creation: `Control: ModernButton`
Inputs: AccessibleLabel: Text; Align: Enum [Align]; Appearance: Enum = ButtonAppearance.Primary [Enum name: ButtonAppearance; Outline, Primary, Secondary, Subtle, Transparent]; BasePaletteColor: Color; BorderColor: Color; BorderStyle: Enum [BorderStyle]; BorderThickness: Number; Color: Color; ContentLanguage: Text; DisplayMode: Enum = DisplayMode.Edit [DisplayMode]; Font: Enum [Font]; FontWeight: Enum [FontWeight]; Height: Number = 32; Icon: Text = ""; IconRotation: Number = 0; IconStyle: Enum = IconStyle.Outline [Enum name: IconStyle; Filled, Outline]; Italic: Boolean; Layout: Enum = ButtonLayout.IconBefore [Enum name: ButtonLayout; IconAfter, IconBefore, IconOnly, TextOnly]; OnSelect: Boolean; Padding*: Number; Radius*: Number; Size: Number = 0; Strikethrough: Boolean; Text: Text = "Button"; Tooltip: Text; Underline: Boolean; VerticalAlign: Enum [VerticalAlign]; Visible: Boolean = true; Width: Number = 96; X, Y
NOTE: ModernButton has NO Fill property; surface colour comes from Appearance + BasePaletteColor.
As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 32; LayoutMinWidth = 96; LayoutMaxHeight/Width = 0

### Classic/Button — family Classic (use for grid cells: supports per-cell Fill)
Creation: `Control: Classic/Button`
Inputs: Align: Enum = Align.Center [Align]; AutoDisableOnSelect: Boolean = true; BorderColor: Color = App.Theme.Colors.Primary; BorderStyle: Enum = BorderStyle.Solid [BorderStyle]; BorderThickness: Number = 2; Color: Color; ContentLanguage: Text; DisabledBorderColor: Color = RGBA(244,244,244,1); DisabledColor: Color = RGBA(166,166,166,1); DisabledFill: Color = RGBA(244,244,244,1); DisplayMode: Enum = DisplayMode.Edit [DisplayMode]; Fill: Color = App.Theme.Colors.Primary; FocusedBorderColor: Color = Self.BorderColor; FocusedBorderThickness: Number = 4; Font: Enum = App.Theme.Font [Font]; FontWeight: Enum = FontWeight.Semibold [FontWeight]; Height: Number = 40; HoverBorderColor: Color; HoverColor: Color; HoverFill: Color; Italic: Boolean; OnSelect: Boolean; PaddingBottom/Left/Right/Top: Number = 5; PressedBorderColor: Color; PressedColor: Color = Self.Color; PressedFill: Color; RadiusBottomLeft/Right, RadiusTopLeft/Right: Number = 10; Size: Number = 15; Strikethrough: Boolean; TabIndex: Number = 0; Text: Text = "Button"; Tooltip: Text; Underline: Boolean; VerticalAlign: Enum = VerticalAlign.Middle [VerticalAlign]; Visible: Boolean = true; Width: Number = 160; X, Y
NOTE: Classic/Button has NO AccessibleLabel property; use Tooltip plus the visible Text letter for status cues.
As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 40; LayoutMinWidth = 160; LayoutMaxHeight/Width = 0

### Gallery — family Classic
Creation: `Control: Gallery` + `Variant:` (required) Horizontal | VariableHeight | Vertical
Common inputs: BorderStyle: Enum = BorderStyle.Solid [BorderStyle]; ContentLanguage: Text; Default: Record; DisplayMode: Enum = DisplayMode.Edit [DisplayMode]; Fill: Color = RGBA(0,0,0,0); FocusedBorderColor: Color; FocusedBorderThickness: Number = 4; LoadingSpinnerColor: Color; NavigationStep: Number = 1; Selectable: Boolean = true; ShowNavigation: Boolean = false; TabIndex: Number = -1; Transition: Enum = Transition.None [Enum name: Transition; None, Pop, Push]; Visible: Boolean = true
Vertical / Horizontal variant inputs: AccessibleLabel: Text; BorderColor: Color; BorderThickness: Number = 0; DelayItemLoading: Boolean = true; Height: Number = 575; Items: Table; LoadingSpinner: Enum = LoadingSpinner.Data [Enum name: LoadingSpinner; Controls, Data, None]; ShowScrollbar: Boolean = true; TemplatePadding: Number = 5; TemplateSize: Number; Width: Number = 640; WrapCount: Number = 1; X, Y
VariableHeight variant: same minus WrapCount, plus MaxTemplateSize: Number = 5000; TemplateSize = 280
As AutoLayout child: AlignInContainer = Stretch; FillPortions = 1; LayoutMinHeight = 287; LayoutMinWidth = 320; LayoutMaxHeight/Width = 0
Outputs: AllItems, AllItemsCount, Selected, TemplateHeight, TemplateWidth, TemplatePadding, VisibleIndex, Height, Width

### ModernDropdown — family React
Creation: `Control: ModernDropdown`
Inputs: AccessibleLabel: Text; Appearance: Enum = Appearance.FilledDarker [Enum name: Appearance; FilledDarker, FilledLighter, Outline]; BasePaletteColor: Color; BorderColor; BorderStyle [BorderStyle]; BorderThickness; Color; ContentLanguage; Default: Record; DisplayMode: Enum = DisplayMode.Edit [DisplayMode]; Fill: Color; Font [Font]; FontWeight = FontWeight.Normal [FontWeight]; Height: Number = 32; Italic; ItemDisplayText: Text = ThisItem.Value1; Items: Table; OnChange: Boolean; Padding*; Radius*; Required: Boolean = false; Size: Number = 14; Strikethrough; Underline; ValidationState: Enum = ValidationState.None [Enum name: ValidationState; Error, None]; Visible = true; Width: Number = 320; X, Y
Output: Selected: Record
As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 32; LayoutMinWidth = 320

### ModernTabList — family React
Creation: `Control: ModernTabList`
Inputs: AccessibleLabel: Text; Align: Enum = Align.Left [Align]; Alignment: Enum = LayoutDirection.Horizontal [Enum name: LayoutDirection; Horizontal, Vertical]; Appearance: Enum = TabListAppearance.Transparent [Enum name: TabListAppearance; FilledCircular, Subtle, SubtleCircular, Transparent]; BasePaletteColor: Color; Color: Color; ContentLanguage; Default: Record; DisplayMode [DisplayMode]; Font [Font]; FontWeight [FontWeight]; Height: Number = 60; Italic; ItemDisplayText: Text = ThisItem.Value; Items: Table = Table({Value:"Item 1"},...); OnChange: Boolean; OnSelect: Boolean; Padding*; Size: Number = 14; Strikethrough; TabSize: Enum = TabSize.Large [Enum name: TabSize; Large, Medium, Small]; Underline; Visible = true; Width: Number = 300; X, Y
Output: Selected: Record
As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 60; LayoutMinWidth = 300

### ModernTextInput — family React
Creation: `Control: ModernTextInput`
Inputs: AccessibleLabel: Text; Align = Align.Left [Align]; Appearance = Appearance.FilledDarker [Enum name: Appearance; FilledDarker, FilledLighter, Outline]; BasePaletteColor; BorderColor; BorderStyle [BorderStyle]; BorderThickness; Color; ContentLanguage; Default: Text = ""; DisplayMode = DisplayMode.Edit [DisplayMode]; Fill; Font [Font]; FontWeight = Normal [FontWeight]; Height: Number = 32; Italic; MaxLength: Number; OnChange: Boolean; Padding*; Placeholder: Text = "Enter text"; Radius*; Required: Boolean = false; Size: Number = 14; Strikethrough; TriggerOutput: Enum = TriggerOutput.Keypress [Enum name: TriggerOutput; Delayed, FocusOut, Keypress]; Type: Enum = TextInputType.SingleLine [Enum name: TextInputType; Multiline, Password, Search, SingleLine]; Underline; ValidationState = ValidationState.None [ValidationState]; Visible = true; Width: Number = 320; X, Y
Output: Text: Text
As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 32; LayoutMinWidth = 320

### ModernDatePicker — family React
Creation: `Control: ModernDatePicker`
Inputs: AccessibleLabel: Text; Appearance = Appearance.FilledDarker [Enum name: Appearance; FilledDarker, FilledLighter, Outline]; BasePaletteColor; BorderColor; BorderStyle [BorderStyle]; BorderThickness; Color; ContentLanguage; DateTimeZone: Enum = DateTimeZone.Local [Enum name: DateTimeZone; Local, UTC]; DefaultDate: Date; DisplayMode = DisplayMode.Edit [DisplayMode]; EndDate: Date = Date(Year(Today())+100,12,31); Fill; Font [Font]; FontWeight [FontWeight]; Format: Enum = DatePickerFormat.LongAbbreviated [Enum name: DatePickerFormat; LongAbbreviated, Short, YearMonth]; Height: Number = 32; IsEditable: Boolean = false; Italic; OnChange: Boolean; Padding*; Placeholder: Text = "Select a date"; Radius*; Size: Number = 14; StartDate: Date = Date(1900,1,1); StartOfWeek: Enum = StartOfWeek.Sunday [Enum name: StartOfWeek; Friday, Monday, MondayZero, Saturday, Sunday, Thursday, Tuesday, Wednesday]; Strikethrough; Underline; ValidationState [ValidationState]; Visible = true; Width: Number = 320; X, Y
Output: SelectedDate: Date
As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 32; LayoutMinWidth = 320

### ModernSpinner — family React
Creation: `Control: ModernSpinner`
Inputs: AccessibleLabel: Text; Appearance: Enum = SpinnerAppearance.Primary [Enum name: SpinnerAppearance; Inverted, Primary]; BasePaletteColor; Color; ContentLanguage; DisplayMode [DisplayMode]; Font [Font]; FontWeight [FontWeight]; Height: Number = 48; Italic; Label: Text = ""; LabelPosition: Enum = SpinnerLabelPosition.After [Enum name: SpinnerLabelPosition; Above, After, Before, Below]; LineHeight: Number; Padding*: Number = 8; Size: Number = 0; SpinnerColor: Color; Strikethrough; Tooltip: Text; TrackColor: Color; Underline; Visible = true; Width: Number = 48; X, Y
As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 48; LayoutMinWidth = 48

### Badge — family FluentV9
Creation: `Control: Badge`
Inputs: AccessibleLabel: Text; Align: Enum [Align]; Appearance: Enum = "Tint" [Enum name: BadgeCanvas.Appearance; Filled, Ghost, Outline, Tint]; BasePaletteColor: Color; Content: Text = "AB"; ContentLanguage; DisplayMode [DisplayMode]; Font [Font]; FontColor: Color; FontItalic: Boolean; FontSize: Number = 0; FontStrikethrough; FontUnderline; FontWeight [FontWeight]; Height: Number = 32; Shape: Enum = "Circular" [Enum name: BadgeCanvas.Shape; Circular, Rounded, Square]; ThemeColor: Enum = "Brand" [Enum name: BadgeCanvas.ThemeColor; Brand, Danger, Important, Informative, Severe, Subtle, Success, Warning]; VerticalAlign [VerticalAlign]; Visible = true; Width: Number = 32; X, Y
As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 32; LayoutMinWidth = 32

### ModernIcon — family React
Creation: `Control: ModernIcon`
Inputs: AccessibleLabel: Text; BasePaletteColor; BorderColor; BorderStyle [BorderStyle]; BorderThickness; ContentLanguage; DisplayMode = DisplayMode.Edit [DisplayMode]; Fill: Color; Height: Number = 32; Icon: Text = "Add"; IconColor: Color; IconStyle: Enum = IconStyle.Outline [Enum name: IconStyle; Filled, Outline]; OnSelect: Boolean; Padding*: Number = 0; Radius*; Rotation: Number = 0; Tooltip: Text; Visible = true; Width: Number = 32; X, Y
As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 32; LayoutMinWidth = 32

---

## Build 2 addendum (captured 2026-09-29)

Data sources unchanged (App Settings replaces the removed Power Pages "Settings"). Absence Reasons:
aaca_absencereasonid "Absence Reason": Guid; aaca_name "Name": String; aaca_active "Active": Boolean;
aaca_sortorder "Sort Order": Number.

Additional Students columns: aaca_firstname "First Name": String; aaca_lastname "Last Name": String;
aaca_dateofbirth "Date of Birth": Date; aaca_grade "Grade": option set "Grade (Students)": K, 1..12, 12+;
aaca_externalclientid "External Client ID": String; aaca_archivedon "Archived On": Date;
aaca_archivedby "Archived By": lookup Users; _ownerid_value "Owner": Polymorphic.
Enrollments also: aaca_previousenrollment "Previous Enrollment": lookup Enrollments;
aaca_endreason "End Reason": option set "End Reason (Enrollments)": Transfer, Ratio Change, Discharge, Year End, Correction.

### Verified behaviour formula (compiled PASSED in a Classic/Button OnSelect against this app, then removed)

```
With({t: First(Filter(Staff, 'App Role' = 'App Role (Staff)'.Teacher)), yr: LookUp('School Years', 'Start Date' <= Today() && 'End Date' >= Today())},
  With({s: Patch(Students, Defaults(Students), {'First Name': "Probe", 'Last Name': "Only", 'Display Name': "Only, Probe", 'Date of Birth': Date(2015,1,1), Grade: 'Grade (Students)'.'12+', 'Status (aaca_status)': 'Status (Students)'.Active})},
    Patch(Students, s, {Owner: t.User});                                   // polymorphic Owner accepts a Users record
    Patch(Enrollments, Defaults(Enrollments), {Name: "x", Student: s, Campus: t.Campus, Teacher: t, Service: First(Services), 'School Year': yr,
      Program: 'Program (Enrollments)'.'Regular Year', 'IEP Ratio': 'IEP Ratio (Enrollments)'.'No Aide', 'Start Date': Today(),
      'Status (aaca_status)': 'Status (Enrollments)'.Planned, 'End Reason': 'End Reason (Enrollments)'.Transfer, 'Previous Enrollment': First(Enrollments)});
    Patch(Students, s, {'Status (aaca_status)': 'Status (Students)'.Archived, 'Archived On': Today(), 'Archived By': LookUp(Users, 'Primary Email' = User().Email)});
    Patch('Audit Events', Defaults('Audit Events'), {Summary: "x", Action: 'Action (Audit Events)'.Transfer, Entity: "aaca_student", 'Entity ID': Text(s.Student)});
    Set(varProbeNum, s.'Student Number');                                  // autonumber readable from the Patch result
    Set(varProbeDup, CountRows(Filter(Students, 'First Name' = "Probe" && 'Last Name' = "Only" && 'Date of Birth' = Date(2015,1,1))))   // no delegation warning
  ))
```

### describe_control — new control types for build 2

ModernToggle (React) — `Control: ModernToggle`. Inputs: AccessibleLabel: Text; BasePaletteColor; Color; ContentLanguage; Default: Boolean = false; DisplayMode = DisplayMode.Edit [DisplayMode]; Font [Font]; FontWeight [FontWeight]; Height: Number = 35; Italic; Label: Text = "Label"; LabelPosition: Enum = ToggleLabelPosition.After [Enum name: ToggleLabelPosition; Above, After, Before]; OnCheck: Boolean; OnUncheck: Boolean; Size: Number = 0; Strikethrough; ToggleSize: Number = 40; Tooltip: Text; Underline; Visible = true; Width: Number = 113; X, Y. Output: Checked: Boolean. As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 35; LayoutMinWidth = 113.

ModernCheckbox (React) — `Control: ModernCheckbox`. Inputs: AccessibleLabel: Text; BasePaletteColor; CheckboxSize: Number = 16; Color; ContentLanguage; Default: Boolean = false; DisplayMode = DisplayMode.Edit [DisplayMode]; Font [Font]; FontWeight [FontWeight]; Height: Number = 32; Italic; Label: Text = "Checkbox"; OnCheck: Boolean; OnUncheck: Boolean; Size: Number = 0; Strikethrough; Tooltip: Text; Underline; Visible = true; Width: Number = 160; X, Y. Output: Checked: Boolean. As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 32; LayoutMinWidth = 160.

ModernRadio (React) — `Control: ModernRadio`. Inputs: AccessibleLabel: Text; BasePaletteColor; BorderColor; BorderStyle [BorderStyle]; BorderThickness; Color; ContentLanguage; Default: Record; DisabledColor: Color = RGBA(186,186,186,1); DisplayMode = DisplayMode.Edit [DisplayMode]; Fill: Color; Font [Font]; FontWeight = FontWeight.Normal [FontWeight]; Height: Number = 100; Italic; ItemDisplayText: Text = ThisItem.Value; Items: Table; Layout: Enum = OptionLayout.Vertical [Enum name: OptionLayout; Horizontal, HorizontalStacked, Vertical]; LineHeight: Number = 16; OnChange: Boolean; Padding*; RadioBackgroundFill: Color; RadioBorderColor: Color; RadioSelectionFill: Color; RadioSize: Number = 14; Radius*; Required: Boolean = false; Size: Number = 14; Strikethrough; Underline; Visible = true; Width: Number = 320; X, Y. Output: Selected: Record. As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 100; LayoutMinWidth = 320.

All other control types (GroupContainer, ModernText, ModernButton, Classic/Button, Gallery, ModernDropdown,
ModernTabList, ModernTextInput, ModernDatePicker, ModernSpinner, Badge, ModernIcon) are described above in
this packet and unchanged.

---

## Build 3 addendum (captured 2026-09-30)

Schema label changes now live (Power Fx choice spellings changed — use these):
- 'Term (Terms)'.ESY (was Summer); 'Program (Enrollments)'.ESY (was Summer; Program is internal, always 'Regular Year')
- 'End Reason (Enrollments)'.Archived (was Discharge) — meaning: end date with no following enrollment
- 'Type (Calendar Exceptions)'.Closed (was Closure), 'Type (Calendar Exceptions)'.'Work Only' (was 'Staff Development')
- Students 'Date of Birth' is optional.

App.Formulas now also has MonthOptions; FirstSchoolYear. Screen1 toolbar controls were renamed:
conAttMonthBar, btnAttMonthPrev, ddAttMonthPick, ddAttYearPick, btnAttMonthNext, btnAttMonthNow, conAttViewBar,
tabAttViewMode, btnAttDetailsToggle, btnAttRefresh; Screen1 OnVisible builds colAttYears. Real data is loaded
(126 students, 216 enrollments, 11,426 attendance rows, 1,252 absences all unclassified).

### Verified formulas (compiled PASSED against this app on 2026-09-30, then removed)

```
// Delegable absence queue (NO delegation warning). IMPORTANT: use = Blank(), NOT IsBlank(), on the choice column —
// IsBlank('Absence Classification') is NOT delegable.
With({c0: First(Campuses).Campus, d0: Date(2026,8,1), d1: Today()},
  Filter(Attendance, Present = false && 'Is Deleted' = false && 'Absence Classification' = Blank()
                     && Campus.Campus = c0 && Date >= d0 && Date <= d1))
Filter(Attendance, Present = false && 'Absence Classification' = 'Absence Classification (Attendance)'.Excused)

// Classification write (compiled in a Classic/Button OnSelect)
With({a: First(Filter(Attendance, Present = false)), rsn: First(Filter('Absence Reasons', Active = true)), me: LookUp(Users, 'Primary Email' = User().Email)},
  With({w: Patch(Attendance, a, {'Absence Classification': 'Absence Classification (Attendance)'.Excused, 'Absence Reason': rsn, 'Classified By': me, 'Classified On': Now()})},
    Set(varProbeTxt, Text(w.'Absence Classification') & " " & w.'Absence Reason'.Name & " " & w.'Classified By'.'Full Name');
    Patch(Attendance, a, {'Absence Classification': Blank(), 'Absence Reason': Blank()});
    Patch('Audit Events', Defaults('Audit Events'), {Summary: "x", Action: 'Action (Audit Events)'.Reclassify, Entity: "aaca_attendance", 'Entity ID': Text(a.Attendance)})))
```

Absence Reasons: 'Absence Reasons' — Name (Text), Active (Boolean), 'Sort Order' (Number). Seeded: Illness,
Medical/Therapy Appointment, Family Emergency, Religious Observance, Bereavement, Other.
Month Locks as before: LookUp('Month Locks', Campus.Campus = cid && Month = monthStart && 'Status (aaca_status)' = 'Status (Month Locks)'.Locked).
All controls needed (GroupContainer, Gallery, ModernText, ModernButton, Classic/Button, ModernDropdown,
ModernDatePicker, ModernTextInput, ModernCheckbox, ModernRadio, ModernToggle, ModernSpinner, Badge) are described
above in this packet and unchanged.

---

## Build 4 addendum (captured 2026-09-30)

list_data_sources now also returns: Student Absence Log (Kind: Connected, SharePoint, Writable, Delegatable) and
Student Directory (Kind: Connected, SharePoint, Writable, Delegatable).

### Student Absence Log (get_data_source_schema, relevant columns)
- ID: Number; Title: String (e.g. "ABS-2026-000515", may be blank); Created: DateTime; Modified: DateTime
- Match_Status: Record (SharePoint Choice). Choices: "Exact", "Approved Variation", "Needs Review", "Manually Resolved"
- Matched_Student: Record (SharePoint Lookup -> Student Directory). Projected: Matched_Student_x003a__x0020_Cam /Fir /Las
- Student_ID: String; StudentFirstName ("Student First Name"): String; StudentLastName ("Student Last Name"): String
- SchoolSite ("School Site"): String — always one of "Antelope Valley", "Chatsworth", "Oxnard" (= Campuses.Name)
- AbsenceDate ("Absence Date"): String, ReturnDate ("Return Date"): String — M/D/YYYY, with or without leading zeros
  (e.g. "7/1/2026", "09/14/2026"). Days absent = AbsenceDate up to but not including ReturnDate, school days only.
- Reason: String; ParentName ("Submitted By"): String; DateNotified ("Date Notified"): String (e.g. "09/13/2026 - 10:56 PM")
- Finance-owned, NEVER write: Absence_x0020_Month, Billable_x0020_Days, Billing_x0020_Status, First_x0020_Eligible_x0020_Date, Total_x0020_Absence_x0020_Days

### Student Directory (all text)
- ID: Number; Title (blank); Student_ID (e.g. "CW-1001"); First_Name; Last_Name; Campus (code: AV/CW/OX);
  Match_Name (lower-case "first last"); Active ("Yes"/"No"); FirstName (unused legacy column)

### Verified formulas (compiled against this app 2026-09-30, then removed)
```
// delegable (no warning)
Sort(Filter('Student Absence Log', Match_Status.Value = "Needs Review"), Created, SortOrder.Descending)
// one-save resolve (valid) — lookup as {Id, Value}, choice as {Value}
Patch('Student Absence Log', item, {Matched_Student: {Id: dir.ID, Value: dir.Match_Name}, Student_ID: dir.Student_ID, Match_Status: {Value: "Manually Resolved"}})
w.Match_Status.Value; w.Matched_Student.Id; w.Matched_Student.Value
LookUp('Student Directory', Student_ID = "CW-1001")        // use a scalar from With(), never item.Field, inside LookUp (delegation warning otherwise)
DateValue("7/1/2026", "en-US"); DateValue("09/14/2026", "en-US")
LookUp(Campuses, Name = <scalar SchoolSite>).Code
```

### describe_control — ModernCombobox (React)
Creation: `Control: ModernCombobox`. Inputs: AccessibleLabel: Text; AllowExternalSelectedItems: Boolean = true;
Appearance: Enum = Appearance.FilledDarker [Enum name: Appearance; FilledDarker, FilledLighter, Outline];
BasePaletteColor; BorderColor; BorderStyle [BorderStyle]; BorderThickness; Color; ContentLanguage;
DefaultSelectedItems: Table; DelayOutput: Boolean = false; DisplayMode = DisplayMode.Edit [DisplayMode]; Fill;
Font [Font]; FontWeight = FontWeight.Normal [FontWeight]; Height: Number = 32; InputTextPlaceholder: Text = "Find items";
IsSearchable: Boolean = true; Italic; ItemDisplayText: Text = ThisItem.Value1; Items: Table; MultiValueDelimiter: Text = ", ";
OnChange: Boolean; Padding*; Radius*; Required: Boolean = false; SelectMultiple: Boolean = true (set false);
Size: Number = 14; Strikethrough; Underline; ValidationState = ValidationState.None [ValidationState]; Visible = true;
Width: Number = 320; X, Y. Outputs: SearchText: Text; Selected: Record; SelectedItems: Table.
As AutoLayout child: AlignInContainer = SetByContainer; FillPortions = 0; LayoutMinHeight = 32; LayoutMinWidth = 320.
Reset/empty selection: DefaultSelectedItems: =[] (combobox has no AllowEmptySelection).

Dataverse: Students now has a unique alternate key aaca_student_key on 'External Client ID' (index building).

---

## Build 5 addendum (captured 2026-10-01)

New data source: **Report Decisions** (CdsNative, Writable, Delegatable) — table aaca_reportdecision
- aaca_reportdecisionid "Report Decision": Guid; aaca_name "Summary": String
- aaca_reportitemid "Report Item ID": Number (SharePoint Student Absence Log item ID; unique alternate key)
- aaca_decision "Decision": option set "Decision (Report Decisions)": Approved, Dismissed
- aaca_classification "Classification": option set "Classification (Report Decisions)": Excused, Unexcused
- aaca_absencereason "Absence Reason": lookup Absence Reasons; aaca_student "Student": lookup Students;
  aaca_campus "Campus": lookup Campuses; aaca_studentkey "Student Key": String; aaca_note "Note": String (1000)
- aaca_dayscreated / aaca_daysclassified / aaca_daysskipped: Number; createdby/createdon (who/when decided)

Attendance has a new column: aaca_sourcereportid "Source Report ID": Number (SharePoint item ID of the approving report).
Students has aaca_keysequence "Key Sequence" (autonumber text) — used only by the Students add flow.
App Settings has a new row: Key "ParentReportCutoverDate", Value "2026-01-01" (parse with DateValue(v, "en-US") or Date(Value(Left(v,4)), ...)).
Student Absence Log Match_Status choices: "Exact", "Approved Variation", "Needs Review", "Manually Resolved".

Existing Screen1 behaviour to reuse (read Screen1.pa.yaml): btnAttSaveEngine upserts one Attendance row by
Student + Service + Date with snapshots (Record Key, Enrollment, Teacher, Campus, School Year, Term, IEP Ratio) and a
Modified On conflict check; clear = soft delete + Audit Event; colMonthAtt/colMonthCells render the grid; cell text
shows 1/0 and colour by classification (ColorExcused green, ColorUnexcused red, unclassified uncoloured).

HARD LESSONS (must follow):
- NEVER re-parent (move) existing controls into a new container: Studio renders moved controls as solid black boxes.
  Add Visible conditions in place, or create NEW controls with new names.
- In an unquoted YAML value, " #" starts a comment — single-quote or use |- for any value containing " #".
- Values containing ": " must be quoted or use |-.
- Choice columns in Dataverse filters: use `= Blank()` not IsBlank(); use With() scalars inside every LookUp/Filter
  predicate (no record.Field inside predicates).
- IfError(A, B): both branches must be the same type (end table-returning success branches with `; true`).
- No symbol glyphs (◀ ▶ ↻) in button text.
