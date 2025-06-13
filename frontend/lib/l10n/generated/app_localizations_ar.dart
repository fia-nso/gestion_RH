// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get details => 'تفاصيل';

  @override
  String get name_required => 'الاسم مطلوب';

  @override
  String get email_required => 'البريد الإلكتروني مطلوب';

  @override
  String get invalid_email => 'تنسيق البريد الإلكتروني غير صالح';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get employees => 'الموظفون';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get confirm_logout => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'أعد المحاولة';

  @override
  String get no_employees => 'لا يوجد موظفون';

  @override
  String get no_name => 'بدون اسم';

  @override
  String get no_contact => 'بدون معلومات الاتصال';

  @override
  String get edit => 'تعديل';

  @override
  String get employee_details => 'تفاصيل الموظف';

  @override
  String get close => 'إغلاق';

  @override
  String get delete_employee => 'حذف الموظف';

  @override
  String confirm_delete_employee(Object name) {
    return 'هل تريد تأكيد حذف الموظف $name؟';
  }

  @override
  String get create_employee => 'إنشاء موظف';

  @override
  String get edit_employee => 'تعديل الموظف';

  @override
  String get password_required => 'كلمة المرور مطلوبة';

  @override
  String get password_too_short => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get invalid_contact => 'تنسيق الاتصال غير صالح';

  @override
  String get photo_selected => 'تم اختيار الصورة';

  @override
  String get change_photo => 'تغيير الصورة';

  @override
  String get upload_photo => 'رفع صورة';

  @override
  String get save => 'حفظ';

  @override
  String get update => 'تحديث';

  @override
  String get create => 'إنشاء';

  @override
  String get delete => 'حذف';

  @override
  String get change_language => 'تغيير اللغة';

  @override
  String get bienvenue => 'مرحبا';

  @override
  String get name => 'الاسم';

  @override
  String get contact => 'معلومات الاتصال';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get se_connecter => 'تسجيل الدخول';

  @override
  String get admin => 'مدير';

  @override
  String get employer => 'صاحب العمل';

  @override
  String get assistant => 'مساعد';

  @override
  String get status => 'الحالة';

  @override
  String get status_required => 'الحالة مطلوبة';

  @override
  String get start_date => 'تاريخ البدء';

  @override
  String get start_date_required => 'تاريخ البدء مطلوب';

  @override
  String get leave_balance => 'رصيد الإجازات';

  @override
  String get view_details => 'عرض التفاصيل';

  @override
  String get role => 'الدور';

  @override
  String get absence_summary => 'ملخص الغياب';

  @override
  String get absence_details => 'تفاصيل الغياب';

  @override
  String get total_absence_hours => 'إجمالي ساعات الغياب';

  @override
  String get no_absences => 'لا توجد غيابات مسجلة';

  @override
  String get record_absence => 'تسجيل غياب';

  @override
  String get absence_type => 'نوع الغياب';

  @override
  String get absence_type_required => 'يرجى اختيار نوع الغياب';

  @override
  String get date => 'التاريخ';

  @override
  String get date_required => 'يرجى اختيار التاريخ';

  @override
  String get duration => 'المدة';

  @override
  String get duration_required => 'يرجى اختيار المدة';

  @override
  String get reason => 'السبب';

  @override
  String get absence_recorded => 'تم تسجيل الغياب بنجاح';

  @override
  String get duration_exceeds_workday => 'لا يمكن أن تتجاوز المدة 7 ساعات';

  @override
  String get record => 'تسجيل';

  @override
  String get select_duration => 'حدد المدة';

  @override
  String get select_date => 'حدد التاريخ';

  @override
  String get sick_leave => 'إجازة مرضية';

  @override
  String get vacation_leave => 'إجازة سنوية';

  @override
  String get off_leave => 'إجازة شخصية';

  @override
  String get no_leave_allocations => 'لا توجد تخصيصات إجازات مسجلة';

  @override
  String get leave_details => 'تفاصيل الإجازة';

  @override
  String get allocated => 'المخصص';

  @override
  String get used => 'المستخدم';

  @override
  String get remaining => 'المتبقي';

  @override
  String get days => 'أيام';

  @override
  String get hours => 'ساعات';

  @override
  String get times => 'مرات';

  @override
  String get progress => 'التقدم';

  @override
  String get absence_distribution => 'توزيع أنواع الغياب';

  @override
  String get work_hours_note =>
      'ساعات العمل الافتراضية: 10:00 صباحًا إلى 5:00 مساءً (7 ساعات يوميًا)';

  @override
  String get reason_required => 'السبب مطلوب';

  @override
  String get custom_reason => 'سبب مخصص';

  @override
  String get error => 'حدث خطأ';

  @override
  String get select_employee => 'اختر موظفًا';

  @override
  String get select_employee_message =>
      'اختر موظفًا من القائمة لعرض تفاصيل إجازاته وغياباته';

  @override
  String get admin_actions => 'إجراءات المدير';

  @override
  String get schedule => 'الجدول: 10:00 صباحًا - 5:00 مساءً';

  @override
  String get start_date_label => 'تاريخ البدء';

  @override
  String get active => 'نشط';

  @override
  String get on_leave => 'في إجازة';

  @override
  String get resigned => 'مستقيل';

  @override
  String get add_employee => 'إضافة موظف';

  @override
  String get end_time_after_start => 'يجب أن يكون وقت النهاية بعد وقت البداية';

  @override
  String get absence_recorded_success => 'تم تسجيل الغياب بنجاح';

  @override
  String get error_generic => 'حدث خطأ';

  @override
  String get projects => 'المشاريع';

  @override
  String get create_project => 'إنشاء مشروع';

  @override
  String get edit_project => 'تعديل مشروع';

  @override
  String get project_name => 'اسم المشروع';

  @override
  String get size_and_scope => 'الحجم والنطاق';

  @override
  String get assigned_employers => 'أصحاب العمل المعينون';

  @override
  String get add_employer => 'إضافة صاحب عمل';

  @override
  String get select_employer => 'اختر صاحب عمل';

  @override
  String get description => ' التفاصيل';

  @override
  String get add => 'إضافة';

  @override
  String get absence_create_success => 'تم تسجيل الغياب بنجاح';

  @override
  String get end_date_label => 'تاريخ الانتهاء (اختياري)';

  @override
  String get not_set => 'غير محدد';

  @override
  String get select_status => 'اختر الحالة';

  @override
  String get project_size => 'الحجم';

  @override
  String get project_scope => 'النطاق';
}
