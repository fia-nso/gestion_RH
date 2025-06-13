import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @name_required.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get name_required;

  /// No description provided for @email_required.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get email_required;

  /// No description provided for @invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalid_email;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirm_logout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirm_logout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @no_employees.
  ///
  /// In en, this message translates to:
  /// **'No employees'**
  String get no_employees;

  /// No description provided for @no_name.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get no_name;

  /// No description provided for @no_contact.
  ///
  /// In en, this message translates to:
  /// **'No contact information'**
  String get no_contact;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @employee_details.
  ///
  /// In en, this message translates to:
  /// **'Employee Details'**
  String get employee_details;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete_employee.
  ///
  /// In en, this message translates to:
  /// **'Delete Employee'**
  String get delete_employee;

  /// No description provided for @confirm_delete_employee.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String confirm_delete_employee(Object name);

  /// No description provided for @create_employee.
  ///
  /// In en, this message translates to:
  /// **'Create Employee'**
  String get create_employee;

  /// No description provided for @edit_employee.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get edit_employee;

  /// No description provided for @password_required.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get password_required;

  /// No description provided for @password_too_short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get password_too_short;

  /// No description provided for @invalid_contact.
  ///
  /// In en, this message translates to:
  /// **'Invalid contact format'**
  String get invalid_contact;

  /// No description provided for @photo_selected.
  ///
  /// In en, this message translates to:
  /// **'Photo selected'**
  String get photo_selected;

  /// No description provided for @change_photo.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get change_photo;

  /// No description provided for @upload_photo.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get upload_photo;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get change_language;

  /// No description provided for @bienvenue.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get bienvenue;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contact;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @se_connecter.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get se_connecter;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @employer.
  ///
  /// In en, this message translates to:
  /// **'Employer'**
  String get employer;

  /// No description provided for @assistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistant;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @status_required.
  ///
  /// In en, this message translates to:
  /// **'Status is required'**
  String get status_required;

  /// No description provided for @start_date.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get start_date;

  /// No description provided for @start_date_required.
  ///
  /// In en, this message translates to:
  /// **'Start date is required'**
  String get start_date_required;

  /// No description provided for @leave_balance.
  ///
  /// In en, this message translates to:
  /// **'Leave Balance'**
  String get leave_balance;

  /// No description provided for @view_details.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get view_details;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @absence_summary.
  ///
  /// In en, this message translates to:
  /// **'Absence Summary'**
  String get absence_summary;

  /// No description provided for @absence_details.
  ///
  /// In en, this message translates to:
  /// **'Absence Details'**
  String get absence_details;

  /// No description provided for @total_absence_hours.
  ///
  /// In en, this message translates to:
  /// **'Total Absence Hours'**
  String get total_absence_hours;

  /// No description provided for @no_absences.
  ///
  /// In en, this message translates to:
  /// **'No absences recorded'**
  String get no_absences;

  /// No description provided for @record_absence.
  ///
  /// In en, this message translates to:
  /// **'Record Absence'**
  String get record_absence;

  /// No description provided for @absence_type.
  ///
  /// In en, this message translates to:
  /// **'Absence Type'**
  String get absence_type;

  /// No description provided for @absence_type_required.
  ///
  /// In en, this message translates to:
  /// **'Please select an absence type'**
  String get absence_type_required;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @date_required.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get date_required;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @duration_required.
  ///
  /// In en, this message translates to:
  /// **'Please select a duration'**
  String get duration_required;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @absence_recorded.
  ///
  /// In en, this message translates to:
  /// **'Absence recorded successfully'**
  String get absence_recorded;

  /// No description provided for @duration_exceeds_workday.
  ///
  /// In en, this message translates to:
  /// **'Duration cannot exceed 7 hours'**
  String get duration_exceeds_workday;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'record'**
  String get record;

  /// No description provided for @select_duration.
  ///
  /// In en, this message translates to:
  /// **'select duration'**
  String get select_duration;

  /// No description provided for @select_date.
  ///
  /// In en, this message translates to:
  /// **'select date'**
  String get select_date;

  /// No description provided for @sick_leave.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave'**
  String get sick_leave;

  /// No description provided for @vacation_leave.
  ///
  /// In en, this message translates to:
  /// **'Vacation Leave'**
  String get vacation_leave;

  /// No description provided for @off_leave.
  ///
  /// In en, this message translates to:
  /// **'Off Leave'**
  String get off_leave;

  /// No description provided for @no_leave_allocations.
  ///
  /// In en, this message translates to:
  /// **'No leave allocations recorded'**
  String get no_leave_allocations;

  /// No description provided for @leave_details.
  ///
  /// In en, this message translates to:
  /// **'Leave Details'**
  String get leave_details;

  /// No description provided for @allocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated'**
  String get allocated;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @times.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get times;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @absence_distribution.
  ///
  /// In en, this message translates to:
  /// **'Absence Type Distribution'**
  String get absence_distribution;

  /// No description provided for @work_hours_note.
  ///
  /// In en, this message translates to:
  /// **'Default work hours: 10:00 AM to 5:00 PM (7 hours per day)'**
  String get work_hours_note;

  /// No description provided for @reason_required.
  ///
  /// In en, this message translates to:
  /// **'Reason is required'**
  String get reason_required;

  /// No description provided for @custom_reason.
  ///
  /// In en, this message translates to:
  /// **'Custom Reason'**
  String get custom_reason;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get error;

  /// No description provided for @select_employee.
  ///
  /// In en, this message translates to:
  /// **'Select an Employee'**
  String get select_employee;

  /// No description provided for @select_employee_message.
  ///
  /// In en, this message translates to:
  /// **'Choose an employee from the list to view their leave and absence details'**
  String get select_employee_message;

  /// No description provided for @admin_actions.
  ///
  /// In en, this message translates to:
  /// **'Admin Actions'**
  String get admin_actions;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule: 10:00 AM - 5:00 PM'**
  String get schedule;

  /// No description provided for @start_date_label.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get start_date_label;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @on_leave.
  ///
  /// In en, this message translates to:
  /// **'On Leave'**
  String get on_leave;

  /// No description provided for @resigned.
  ///
  /// In en, this message translates to:
  /// **'Resigned'**
  String get resigned;

  /// No description provided for @add_employee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get add_employee;

  /// No description provided for @end_time_after_start.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get end_time_after_start;

  /// No description provided for @absence_recorded_success.
  ///
  /// In en, this message translates to:
  /// **'Absence recorded successfully'**
  String get absence_recorded_success;

  /// No description provided for @error_generic.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get error_generic;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @create_project.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get create_project;

  /// No description provided for @edit_project.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get edit_project;

  /// No description provided for @project_name.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get project_name;

  /// No description provided for @size_and_scope.
  ///
  /// In en, this message translates to:
  /// **'Size and Scope'**
  String get size_and_scope;

  /// No description provided for @assigned_employers.
  ///
  /// In en, this message translates to:
  /// **'Assigned Employers'**
  String get assigned_employers;

  /// No description provided for @add_employer.
  ///
  /// In en, this message translates to:
  /// **'Add Employer'**
  String get add_employer;

  /// No description provided for @select_employer.
  ///
  /// In en, this message translates to:
  /// **'Select Employer'**
  String get select_employer;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'description'**
  String get description;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'add'**
  String get add;

  /// No description provided for @absence_create_success.
  ///
  /// In en, this message translates to:
  /// **'Absence created successfully'**
  String get absence_create_success;

  /// No description provided for @end_date_label.
  ///
  /// In en, this message translates to:
  /// **'End Date (Optional)'**
  String get end_date_label;

  /// No description provided for @not_set.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get not_set;

  /// No description provided for @select_status.
  ///
  /// In en, this message translates to:
  /// **'Select status'**
  String get select_status;

  /// No description provided for @project_size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get project_size;

  /// No description provided for @project_scope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get project_scope;

  /// No description provided for @search_projects.
  ///
  /// In en, this message translates to:
  /// **'Search projects...'**
  String get search_projects;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sort_by_name.
  ///
  /// In en, this message translates to:
  /// **'Sort by Name'**
  String get sort_by_name;

  /// No description provided for @sort_by_date.
  ///
  /// In en, this message translates to:
  /// **'Sort by Date'**
  String get sort_by_date;

  /// No description provided for @sort_by_status.
  ///
  /// In en, this message translates to:
  /// **'Sort by Status'**
  String get sort_by_status;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @no_projects_found.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get no_projects_found;

  /// No description provided for @no_projects_yet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get no_projects_yet;

  /// No description provided for @try_different_filters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get try_different_filters;

  /// No description provided for @create_first_project.
  ///
  /// In en, this message translates to:
  /// **'Create your first project to get started'**
  String get create_first_project;

  /// No description provided for @project_details.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get project_details;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @days_elapsed.
  ///
  /// In en, this message translates to:
  /// **'Days elapsed'**
  String get days_elapsed;

  /// No description provided for @total_duration.
  ///
  /// In en, this message translates to:
  /// **'Total duration'**
  String get total_duration;

  /// No description provided for @assignment_info_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Assignment information will be displayed here'**
  String get assignment_info_placeholder;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
