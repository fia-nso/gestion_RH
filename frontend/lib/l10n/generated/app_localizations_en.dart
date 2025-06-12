import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get details => 'Details';

  @override
  String get name_required => 'Name is required';

  @override
  String get email_required => 'Email is required';

  @override
  String get invalid_email => 'Invalid email format';

  @override
  String get profile => 'Profile';

  @override
  String get employees => 'Employees';

  @override
  String get logout => 'Logout';

  @override
  String get confirm_logout => 'Are you sure you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get no_employees => 'No employees';

  @override
  String get no_name => 'No name';

  @override
  String get no_contact => 'No contact information';

  @override
  String get edit => 'Edit';

  @override
  String get employee_details => 'Employee Details';

  @override
  String get close => 'Close';

  @override
  String get delete_employee => 'Delete Employee';

  @override
  String confirm_delete_employee(Object name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get create_employee => 'Create Employee';

  @override
  String get edit_employee => 'Edit Employee';

  @override
  String get password_required => 'Password is required';

  @override
  String get password_too_short => 'Password must be at least 6 characters';

  @override
  String get invalid_contact => 'Invalid contact format';

  @override
  String get photo_selected => 'Photo selected';

  @override
  String get change_photo => 'Change Photo';

  @override
  String get upload_photo => 'Upload Photo';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get change_language => 'Change Language';

  @override
  String get bienvenue => 'Welcome';

  @override
  String get name => 'Name';

  @override
  String get contact => 'Contact Information';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get se_connecter => 'Log in';

  @override
  String get admin => 'Admin';

  @override
  String get employer => 'Employer';

  @override
  String get assistant => 'Assistant';

  @override
  String get status => 'Status';

  @override
  String get status_required => 'Status is required';

  @override
  String get start_date => 'Start Date';

  @override
  String get start_date_required => 'Start date is required';

  @override
  String get leave_balance => 'Leave Balance';

  @override
  String get view_details => 'View Details';

  @override
  String get role => 'Role';

  @override
  String get absence_summary => 'Absence Summary';

  @override
  String get absence_details => 'Absence Details';

  @override
  String get total_absence_hours => 'Total Absence Hours';

  @override
  String get no_absences => 'No absences recorded';

  @override
  String get record_absence => 'Record Absence';

  @override
  String get absence_type => 'Absence Type';

  @override
  String get absence_type_required => 'Please select an absence type';

  @override
  String get date => 'Date';

  @override
  String get date_required => 'Please select a date';

  @override
  String get duration => 'Duration';

  @override
  String get duration_required => 'Please select a duration';

  @override
  String get reason => 'Reason';

  @override
  String get absence_recorded => 'Absence recorded successfully';

  @override
  String get duration_exceeds_workday => 'Duration cannot exceed 7 hours';

  @override
  String get record => 'record';

  @override
  String get select_duration => 'select duration';

  @override
  String get select_date => 'select date';

  @override
  String get sick_leave => 'Sick Leave';

  @override
  String get vacation_leave => 'Vacation Leave';

  @override
  String get off_leave => 'Off Leave';

  @override
  String get no_leave_allocations => 'No leave allocations recorded';

  @override
  String get leave_details => 'Leave Details';

  @override
  String get allocated => 'Allocated';

  @override
  String get used => 'Used';

  @override
  String get remaining => 'Remaining';

  @override
  String get days => 'Days';

  @override
  String get hours => 'Hours';

  @override
  String get times => 'Times';

  @override
  String get progress => 'Progress';

  @override
  String get absence_distribution => 'Absence Type Distribution';

  @override
  String get work_hours_note => 'Default work hours: 10:00 AM to 5:00 PM (7 hours per day)';

  @override
  String get reason_required => 'Reason is required';

  @override
  String get custom_reason => 'Custom Reason';

  @override
  String get error => 'An error occurred';

  @override
  String get select_employee => 'Select an Employee';

  @override
  String get select_employee_message => 'Choose an employee from the list to view their leave and absence details';

  @override
  String get admin_actions => 'Admin Actions';

  @override
  String get schedule => 'Schedule: 10:00 AM - 5:00 PM';

  @override
  String get start_date_label => 'Start Date';

  @override
  String get active => 'Active';

  @override
  String get on_leave => 'On Leave';

  @override
  String get resigned => 'Resigned';

  @override
  String get add_employee => 'Add Employee';

  @override
  String get end_time_after_start => 'End time must be after start time';

  @override
  String get absence_recorded_success => 'Absence recorded successfully';

  @override
  String get error_generic => 'An error occurred';

  @override
  String get projects => 'Projects';

  @override
  String get create_project => 'Create Project';

  @override
  String get edit_project => 'Edit Project';

  @override
  String get project_name => 'Project Name';

  @override
  String get size_and_scope => 'Size and Scope';

  @override
  String get assigned_employers => 'Assigned Employers';

  @override
  String get add_employer => 'Add Employer';

  @override
  String get select_employer => 'Select Employer';

  @override
  String get description => 'description';

  @override
  String get add => 'add';

  @override
  String get absence_create_success => 'Absence created successfully';

  @override
  String get end_date_label => 'End Date (Optional)';

  @override
  String get not_set => 'Not set';

  @override
  String get select_status => 'Select status';

  @override
  String get project_size => 'Size';

  @override
  String get project_scope => 'Scope';
}
