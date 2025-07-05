// // screens/dashboard/dashboard_wrapper.dart
// import 'package:flutter/material.dart';
// import 'package:frontend/controller_provider/update_provider.dart';
// import 'package:frontend/l10n/generated/app_localizations.dart';
// import 'package:provider/provider.dart';
// import '../controller_provider/auth_provider.dart';
// import '../controller_provider/employee_management_controller.dart';
// import '../controller_provider/leave_management_controller.dart';
// import '../controller_provider/locale_provider.dart';
// import '../controller_provider/skill_management_controller.dart';
// import '../employees/employee_management_page.dart';
// import '../projects/project_management_page.dart';
// import '../profile/profile_page.dart';
// import '../shared/widgets/custom_app_bar.dart';
// import '../shared/widgets/bottom_navigation.dart';
// import '../shared/widgets/logout_dialog.dart';

// class DashboardWrapper extends StatelessWidget {
//   const DashboardWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(
//             create: (_) => EmployerUpdateController(context)),
//         ChangeNotifierProvider(create: (_) => LeaveManagementController()),
//         ChangeNotifierProvider<SkillManagementController>(
//           create: (_) => SkillManagementController(),
//         ),
//       ],
//       child: const _DashboardBody(),
//     );
//   }
// }

// class _DashboardBody extends StatefulWidget {
//   const _DashboardBody();

//   @override
//   State<_DashboardBody> createState() => _DashboardBodyState();
// }

// class _DashboardBodyState extends State<_DashboardBody> {
//   int _selectedIndex = 0;

//   @override
//   Widget build(BuildContext context) {
//     final localeController = Provider.of<LocaleProvider>(context);
//     final authController = context.watch<AuthController>();
//     final userRole = authController.user.currentRole.id;
//     final appLocalizations = AppLocalizations.of(context)!;

//     final pages = _buildPages(userRole);
//     final navItems = _buildNavItems(context, userRole);

//     return Scaffold(
//       appBar: CustomAppBar(
//         title: _getRoleTitle(context, userRole),
//         onLanguageToggle: () {
//           final newLocale = localeController.locale.languageCode == 'en'
//               ? const Locale('ar')
//               : const Locale('en');
//           localeController.changeLocale(newLocale);
//         },
//         onLogout: () => showLogoutDialog(context),
//       ),
//       body: IndexedStack(
//         index: _selectedIndex,
//         children: pages,
//       ),
//       bottomNavigationBar: CustomBottomNavigation(
//         selectedIndex: _selectedIndex,
//         items: navItems,
//         onTap: (index) => setState(() => _selectedIndex = index),
//       ),
//     );
//   }

//   List<Widget> _buildPages(String userRole) {
//     List<Widget> pages = [];

//     if (userRole == 'admin') {
//       pages.add(const EmployeeManagementPage());
//     }
    
//     if (userRole == 'admin' || userRole == 'employer') {
//       pages.add(const ProjectManagementPage());
//     }

//     pages.add(const ProfilePage());
//     return pages;
//   }

//   List<BottomNavItem> _buildNavItems(BuildContext context, String userRole) {
//     final appLocalizations = AppLocalizations.of(context)!;
//     List<BottomNavItem> items = [];

//     if (userRole == 'admin') {
//       items.add(BottomNavItem(
//         icon: Icons.people,
//         label: appLocalizations.employees,
//       ));
//     }

//     if (userRole == 'admin' || userRole == 'employer') {
//       items.add(BottomNavItem(
//         icon: Icons.folder,
//         label: appLocalizations.projects,
//       ));
//     }

//     items.add(BottomNavItem(
//       icon: Icons.person,
//       label: appLocalizations.profile,
//     ));

//     return items;
//   }

//   String _getRoleTitle(BuildContext context, String role) {
//     final appLocalizations = AppLocalizations.of(context)!;
//     switch (role) {
//       case 'admin':
//         return appLocalizations.admin;
//       case 'employer':
//         return appLocalizations.employer;
//       case 'assistant':
//         return appLocalizations.assistant;
//       default:
//         return 'Dashboard';
//     }
//   }
// }