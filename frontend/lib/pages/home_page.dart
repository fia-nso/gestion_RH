import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/controller_provider/update_provider.dart';
import 'package:frontend/l10n/generated/app_localizations.dart';
import 'package:frontend/models/auth_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/uttils/navigator.dart';
import 'package:provider/provider.dart';
import '../controller_provider/auth_provider.dart';
import '../controller_provider/employee_management_controller.dart';
import '../controller_provider/leave_management_controller.dart';
import '../controller_provider/locale_provider.dart';
import '../controller_provider/project_management_controller.dart';
import '../models/absence_model.dart';
import '../models/leave_model.dart';
import '../models/project_model.dart';
import '../services/leave_service.dart';
import '../widgets/leave_display_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_nav_bar/google_nav_bar.dart'; // Ajout du package

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => EmployerUpdateController(context)),
        // ChangeNotifierProvider(create: (_) => EmployeeManagementController()),
        ChangeNotifierProvider(create: (_) => LeaveManagementController()),
      ],
      child: const _HomePageBody(),
    );
  }
}

class _HomePageBody extends StatefulWidget {
  const _HomePageBody();

  @override
  State<_HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<_HomePageBody> {
  int _selectedIndex = 0; // Index pour suivre la page active

  @override
  Widget build(BuildContext context) {
    final localeController = Provider.of<LocaleProvider>(context);
    final authController = context.watch<AuthController>();
    final userRole = authController.user.currentRole.id;

    // Définir les pages et les boutons de navigation
    List<Widget> pages = [];
    List<GButton> navButtons = [];

    // Ajouter la page "Employees" en premier si l'utilisateur est admin
    if (userRole == 'admin') {
      pages.add(const EmployeeManagementView()); // Employees page second
      navButtons.add(
        GButton(
          icon: Icons.people,
          text: AppLocalizations.of(context)!.employees,
          semanticLabel: AppLocalizations.of(context)!.employees,
        ),
      );
    }
    if (userRole == 'admin' || userRole == 'employer') {
      pages.add(const ProjectManagementView()); // Add Projects page first
      navButtons.add(
        GButton(
          icon: Icons.folder,
          text: AppLocalizations.of(context)!.projects,
          semanticLabel: AppLocalizations.of(context)!.projects,
        ),
      );
    }

    // Ajouter la page "Profile" en second pour tous les utilisateurs
    pages.add(
        _buildProfileTab(context, authController, userRole)); // Page Profile
    navButtons.add(
      GButton(
        icon: Icons.person,
        text: AppLocalizations.of(context)!.profile,
        semanticLabel: AppLocalizations.of(context)!.profile, // Accessibilité
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_getRoleTitle(context, userRole)),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              final newLocale = localeController.locale.languageCode == 'en'
                  ? const Locale('ar')
                  : const Locale('en');
              localeController.changeLocale(newLocale);
            },
            tooltip: AppLocalizations.of(context)!.change_language,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
            tooltip: AppLocalizations.of(context)!.logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: GNav(
            backgroundColor: Theme.of(context).colorScheme.surface,
            color: Theme.of(context).colorScheme.onSurface,
            activeColor: Theme.of(context).colorScheme.primary,
            tabBackgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
            gap: 8,
            padding: const EdgeInsets.all(16),
            tabs: navButtons,
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  String _getRoleTitle(BuildContext context, String role) {
    final appLocalizations = AppLocalizations.of(context)!;
    switch (role) {
      case 'admin':
        return appLocalizations.admin;
      case 'employer':
        return appLocalizations.employer;
      case 'assistant':
        return appLocalizations.assistant;
      default:
        return 'Dashboard';
    }
  }

  Widget _buildProfileTab(
      BuildContext context, AuthController authController, String userRole) {
    if (userRole == 'employer') {
      return _buildEmployerProfile(context, authController);
    } else {
      return _buildGenericProfile(context, authController, userRole);
    }
  }

  Widget _buildEmployerProfile(
      BuildContext context, AuthController authController) {
    final controller = context.watch<EmployerUpdateController>();
    final leaveController = context.watch<LeaveManagementController>();
    final employer = authController.employer;
    final isAdmin = authController.user.currentRole.id == 'admin';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!leaveController.hasLoadedAllocations(employer.id) ||
          !leaveController.hasLoadedAbsences(employer.id)) {
        leaveController.loadEmployeeLeaveAllocations(employer.id);
      }
    });

    return controller.loading
        ? const Center(child: CircularProgressIndicator())
        : controller.error != null
            ? Center(child: Text(controller.error!))
            : Column(
                children: [
                  // Header avec photo et nom
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 20, bottom: 40),
                    child: Column(
                      children: [
                        // Photo de profil
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: employer.photo != null &&
                                        employer.photo!.isNotEmpty
                                    ? NetworkImage(employer.photo!)
                                    : null,
                                onBackgroundImageError:
                                    (exception, stackTrace) {
                                  print(
                                      'Erreur de chargement de l\'image : $exception');
                                },
                                child: employer.photo == null ||
                                        employer.photo!.isEmpty
                                    ? const Icon(Icons.person,
                                        size: 50, color: Colors.grey)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Nom et titre
                        Text(
                          employer.name ?? "Utilisateur",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRoleTitle(
                              context, authController.user.currentRole.id),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenu principal avec sections
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Contact
                          _buildSection(
                            context,
                            title: AppLocalizations.of(context)!.contact ??
                                "CONTACT",
                            children: [
                              _buildContactItem(
                                icon: Icons.email,
                                title: "Email",
                                subtitle: employer.contact ?? "Non renseigné",
                                iconColor: Colors.blue,
                              ),
                              _buildContactItem(
                                icon: Icons.location_on,
                                title: "details",
                                subtitle: employer.details ?? "Non renseignée",
                                iconColor: Colors.purple,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Section Compte
                          _buildSection(
                            context,
                            title: "COMPTE",
                            children: [
                              _buildMenuTile(
                                icon: Icons.person,
                                title: "Données personnelles",
                                onTap: () => _showPersonalDataDialog(
                                    context, controller),
                                iconColor: Colors.blue,
                              ),
                              _buildMenuTile(
                                icon: Icons.work,
                                title: "Congés et absences",
                                onTap: () => _showAbsenceDetailsDialog(
                                  context,
                                  leaveController
                                      .getEmployeeAbsences(employer.id),
                                  employer.name ?? 'Employee',
                                ),
                                iconColor: Colors.blue,
                              ),
                              const SizedBox(height: 8),
                              if (leaveController.isLoading(employer.id))
                                const Center(child: CircularProgressIndicator())
                              else if (leaveController.getError(employer.id) !=
                                  null)
                                Text(
                                  leaveController.getError(employer.id)!,
                                  style: const TextStyle(color: Colors.red),
                                )
                              else
                                AbsenceSummary(
                                  absences: leaveController
                                      .getEmployeeAbsences(employer.id),
                                  totalAbsenceHours: leaveController
                                      .getTotalAbsenceHours(employer.id),
                                  showTitle: false,
                                ),
                              _buildMenuTile(
                                icon: Icons.payment,
                                title: "Paie & Fiscalité",
                                onTap: () {
                                  // Navigation vers paie et fiscalité
                                },
                                iconColor: Colors.blue,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Section Paramètres
                          _buildSection(
                            context,
                            title: "PARAMÈTRES",
                            children: [
                              _buildMenuTile(
                                icon: Icons.lock,
                                title: "Changer le mot de passe",
                                onTap: () {
                                  // Navigation vers changement de mot de passe
                                },
                                iconColor: Colors.blue,
                              ),
                              _buildMenuTile(
                                icon: Icons.info,
                                title: "Version",
                                onTap: () {
                                  // Afficher version
                                },
                                iconColor: Colors.blue,
                              ),
                              _buildMenuTile(
                                icon: Icons.help,
                                title: "FAQ et Aide",
                                onTap: () {
                                  // Navigation vers FAQ
                                },
                                iconColor: Colors.blue,
                              ),
                              _buildMenuTile(
                                icon: Icons.logout,
                                title: "Déconnexion",
                                onTap: () => _showLogoutDialog(context),
                                iconColor: Colors.red,
                                isDestructive: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color iconColor,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey, width: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonalDataDialog(
      BuildContext context, EmployerUpdateController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Données personnelles"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo upload section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person, size: 50),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () => controller.pickPhoto(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller.nameController,
                decoration: InputDecoration(
                  labelText: "Prénom",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.contactController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.detailsController,
                decoration: InputDecoration(
                  labelText: "details",
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              controller.save(context);
              Navigator.of(context).pop();
            },
            child: const Text("update"),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericProfile(
      BuildContext context, AuthController authController, String userRole) {
    final leaveController = context.watch<LeaveManagementController>();
    // final userName = authController.user.name;
    // final userStatus = authController.user.status;
    final userId = authController.user.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!leaveController.hasLoadedAllocations(userId) ||
          !leaveController.hasLoadedAbsences(userId)) {
        leaveController.loadEmployeeLeaveAllocations(userId);
      }
    });

    return const Center(
        // child: SingleChildScrollView(
        //   child: Column(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       CircleAvatar(
        //         radius: 50,
        //         backgroundColor: Colors.grey[200],
        //         child: const Icon(Icons.person, size: 50),
        //       ),
        //       const SizedBox(height: 20),
        //       Text(
        //         '${AppLocalizations.of(context)!.bienvenue}, ${userName ?? "Utilisateur"}',
        //         style: Theme.of(context).textTheme.titleLarge,
        //         textAlign: TextAlign.center,
        //       ),
        //       const SizedBox(height: 20),
        //       Text(
        //         '${AppLocalizations.of(context)!.role}: ${userRole.toUpperCase()}',
        //         style: Theme.of(context).textTheme.titleMedium,
        //       ),
        //       const SizedBox(height: 20),
        //       Text(
        //         '${AppLocalizations.of(context)!.status}: ${userStatus ?? 'N/A'}',
        //         style: Theme.of(context).textTheme.titleMedium,
        //       ),
        //       const SizedBox(height: 20),
        // Card(
        //   child: Padding(
        //     padding: const EdgeInsets.all(16.0),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Row(
        //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //           children: [
        //             Text(
        //               AppLocalizations.of(context)!.leave_balance,
        //               style: Theme.of(context)
        //                   .textTheme
        //                   .titleMedium
        //                   ?.copyWith(fontWeight: FontWeight.bold),
        //             ),
        //             IconButton(
        //               onPressed: () => _showLeaveDetailsDialog(
        //                 context,
        //                 leaveController.getEmployeeAllocations(userId),
        //                 userName ?? 'User',
        //               ),
        //               icon: const Icon(Icons.open_in_full),
        //               tooltip: AppLocalizations.of(context)!.view_details,
        //             ),
        //           ],
        //         ),
        //         const SizedBox(height: 8),
        //         if (leaveController.isLoading(userId))
        //           const Center(child: CircularProgressIndicator())
        //         else if (leaveController.getError(userId) != null)
        //           Text(
        //             leaveController.getError(userId)!,
        //             style: const TextStyle(color: Colors.red),
        //           )
        //         else
        //           LeaveAllocationSummary(
        //             allocations:
        //                 leaveController.getEmployeeAllocations(userId),
        //             showTitle: false,
        //           ),
        //       ],
        //     ),
        //   ),
        // ),
        // const SizedBox(height: 20),
        // Card(
        //   child: Padding(
        //     padding: const EdgeInsets.all(16.0),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Row(
        //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //           children: [
        //             Text(
        //               AppLocalizations.of(context)!.absence_summary,
        //               style: Theme.of(context)
        //                   .textTheme
        //                   .titleMedium
        //                   ?.copyWith(fontWeight: FontWeight.bold),
        //             ),
        //             IconButton(
        //               onPressed: () => _showAbsenceDetailsDialog(
        //                 context,
        //                 leaveController.getEmployeeAbsences(userId),
        //                 userName ?? 'User',
        //               ),
        //               icon: const Icon(Icons.open_in_full),
        //               tooltip: AppLocalizations.of(context)!.view_details,
        //             ),
        //           ],
        //         ),
        //         const SizedBox(height: 8),
        //         if (leaveController.isLoading(userId))
        //           const Center(child: CircularProgressIndicator())
        //         else if (leaveController.getError(userId) != null)
        //           Text(
        //             leaveController.getError(userId)!,
        //             style: const TextStyle(color: Colors.red),
        //           )
        //         else
        //           AbsenceSummary(
        //             absences: leaveController.getEmployeeAbsences(userId),
        //             totalAbsenceHours:
        //                 leaveController.getTotalAbsenceHours(userId),
        //             showTitle: false,
        //           ),
        //       ],
        //     ),
        //   ),
        // ),
        //     ],
        //   ),
        // ),
        );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.logout),
          content: Text(appLocalizations.confirm_logout),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(appLocalizations.logout),
              onPressed: () async {
                Navigator.of(context).pop();
                await EmployerService().signOut();
                if (context.mounted) {
                  AppNavigator.pushReplacement('/login');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showLeaveDetailsDialog(
      BuildContext context, List<LeaveAllocation> allocations, String name) {
    showDialog(
      context: context,
      builder: (context) =>
          LeaveAllocationDialog(allocations: allocations, employeeName: name),
    );
  }

  void _showAbsenceDetailsDialog(
      BuildContext context, List<Absence> absences, String name) {
    showDialog(
      context: context,
      builder: (context) =>
          AbsenceDialog(absences: absences, employeeName: name),
    );
  }

  void _showRecordAbsenceDialog(
      BuildContext context, String employeeId, String employeeName) {
    showDialog(
      context: context,
      builder: (context) => RecordAbsenceDialog(
        employeeId: employeeId,
        employeeName: employeeName,
        onAbsenceRecorded: () {
          context
              .read<LeaveManagementController>()
              .loadEmployeeLeaveAllocations(employeeId);
        },
      ),
    );
  }
}

class EmployeeManagementView extends StatefulWidget {
  const EmployeeManagementView({super.key});

  @override
  State<EmployeeManagementView> createState() => _EmployeeManagementViewState();
}

class _EmployeeManagementViewState extends State<EmployeeManagementView> {
  String? _selectedEmployeeId;
  Employer? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeManagementController>().loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmployeeManagementController>();
    final leaveController = context.watch<LeaveManagementController>();
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : controller.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(controller.error!),
                      ElevatedButton(
                        onPressed: controller.loadEmployees,
                        child: Text(appLocalizations.retry),
                      ),
                    ],
                  ),
                )
              : controller.employees.isEmpty
                  ? Center(child: Text(appLocalizations.no_employees))
                  : Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerLowest,
                      child: _buildEmployeeList(controller.employees),
                    ),
    );
  }

  Widget _buildEmployeeList(List<Employer> employees) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.people, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                appLocalizations.employees,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${employees.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _showCreateEmployeeDialog(context),
                tooltip: appLocalizations.add_employee,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              final isSelected = _selectedEmployeeId == employee.id;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Material(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _selectEmployee(employee),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            backgroundImage: employee.photo != null
                                ? NetworkImage(employee.photo!)
                                : null,
                            child: employee.photo == null
                                ? Text(
                                    employee.name
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        'E',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee.name ?? appLocalizations.no_name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.black87,
                                  ),
                                ),
                                if (employee.status != null)
                                  Text(
                                    _getLocalizedStatus(employee.status!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getStatusColor(employee.status!),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showEditEmployeeDialog(context, employee);
                                  break;
                                case 'delete':
                                  _showDeleteEmployeeDialog(context, employee);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  value: 'edit',
                                  child: Text(appLocalizations.edit)),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Text(appLocalizations.delete)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeMessage() {
    final appLocalizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            appLocalizations.select_employee,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appLocalizations.select_employee_message,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeLeaveDetails(LeaveManagementController controller) {
    final appLocalizations = AppLocalizations.of(context)!;
    final employeeId = _selectedEmployee!.id;
    final isLoading = controller.isLoading(employeeId);
    final error = controller.getError(employeeId);

    if (!controller.hasLoadedAllocations(employeeId) && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadEmployeeLeaveAllocations(employeeId);
      });
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmployeeHeader(),
          const SizedBox(height: 24),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (error != null)
            _buildErrorMessage(error)
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LeaveAllocationSummary(
                      allocations:
                          controller.getEmployeeAllocations(employeeId),
                      showTitle: true,
                    ),
                    const SizedBox(height: 32),
                    AbsenceSummary(
                      absences: controller.getEmployeeAbsences(employeeId),
                      totalAbsenceHours:
                          controller.getTotalAbsenceHours(employeeId),
                      showTitle: true,
                    ),
                    if (context.read<AuthController>().user.currentRole.id ==
                        'admin') ...[
                      const SizedBox(height: 32),
                      _buildAdminActions(controller),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeHeader() {
    final appLocalizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColorDark
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: _selectedEmployee!.photo != null
                ? NetworkImage(_selectedEmployee!.photo!)
                : null,
            child: _selectedEmployee!.photo == null
                ? Text(
                    _selectedEmployee!.name?.substring(0, 1).toUpperCase() ??
                        'E',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedEmployee!.name ?? appLocalizations.no_name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appLocalizations.schedule,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
                if (_selectedEmployee!.startDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${appLocalizations.start_date_label}: ${_formatDate(_selectedEmployee!.startDate!)}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getLocalizedStatus(_selectedEmployee!.status ?? 'active'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(LeaveManagementController controller) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text(
                appLocalizations.admin_actions,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showRecordAbsenceDialog(context,
                _selectedEmployee!.id, _selectedEmployee!.name ?? 'Employee'),
            icon: const Icon(Icons.add),
            label: Text(appLocalizations.record_absence),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
              child: Text(error,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        ],
      ),
    );
  }

  void _selectEmployee(Employer employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetails(
          employeeId: employee.id,
          employee: employee,
        ),
      ),
    );
    // setState(() {
    //   _selectedEmployeeId = employee.id;
    //   _selectedEmployee = employee;
    // });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'on leave':
        return Colors.orange;
      case 'resigned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLocalizedStatus(String status) {
    final appLocalizations = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'active':
        return appLocalizations.active;
      case 'on leave':
        return appLocalizations.on_leave;
      case 'resigned':
        return appLocalizations.resigned;
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMd(Localizations.localeOf(context).languageCode)
        .format(date);
  }

  void _showCreateEmployeeDialog(BuildContext context) {
    final controller = context.read<EmployeeManagementController>();
    showDialog(
      context: context,
      builder: (context) => CreateEmployeeDialog(controller: controller),
    );
  }

  void _showEditEmployeeDialog(BuildContext context, Employer employee) {
    final controller = context.read<EmployeeManagementController>();
    showDialog(
      context: context,
      builder: (context) =>
          EditEmployeeDialog(employee: employee, controller: controller),
    );
  }

  void _showDeleteEmployeeDialog(BuildContext context, Employer employee) {
    final appLocalizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.delete_employee),
        content: Text(
            '${appLocalizations.confirm_delete_employee} ${employee.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(appLocalizations.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context
                  .read<EmployeeManagementController>()
                  .deleteEmployee(employee.id);
            },
            child: Text(appLocalizations.delete),
          ),
        ],
      ),
    );
  }

  // Added _showRecordAbsenceDialog method
  void _showRecordAbsenceDialog(
      BuildContext context, String employeeId, String employeeName) {
    showDialog(
      context: context,
      builder: (context) => RecordAbsenceDialog(
        employeeId: employeeId,
        employeeName: employeeName,
        onAbsenceRecorded: () {
          context
              .read<LeaveManagementController>()
              .loadEmployeeLeaveAllocations(employeeId);
        },
      ),
    );
  }
}

class RecordAbsenceDialog extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final VoidCallback onAbsenceRecorded;

  const RecordAbsenceDialog({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.onAbsenceRecorded,
  });

  @override
  State<RecordAbsenceDialog> createState() => _RecordAbsenceDialogState();
}

class _RecordAbsenceDialogState extends State<RecordAbsenceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  AbsenceType _selectedType = AbsenceType.illness;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isPartialDay = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: appLocalizations.select_date,
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      helpText: isStartTime ? 'start_time' : 'end_time',
    );
    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  double _calculateDuration() {
    if (_isPartialDay) {
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = _endTime.hour * 60 + _endTime.minute;
      final duration = endMinutes - startMinutes;
      return duration > 0 ? duration / 60.0 : 0.0;
    } else {
      return 7.0; // Full day = 7 hours
    }
  }

  Future<void> _submitAbsence() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final duration = _calculateDuration();
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalizations.end_time_after_start),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final leaveController = context.read<LeaveManagementController>();
      await leaveController.recordAbsence(
        employeeId: widget.employeeId,
        type: _selectedType,
        date: _selectedDate,
        duration: Duration(minutes: (duration * 60).round()),
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      widget.onAbsenceRecorded();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appLocalizations.absence_recorded_success),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${appLocalizations.error_generic}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(8),
      child: AlertDialog(
        title:
            Text('${appLocalizations.record_absence} - ${widget.employeeName}'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AbsenceType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: appLocalizations.absence_type,
                    border: const OutlineInputBorder(),
                  ),
                  items: AbsenceType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(_getAbsenceTypeIcon(type), size: 16),
                                const SizedBox(width: 8),
                                Text(type.displayName),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                  validator: (value) => value == null
                      ? appLocalizations.absence_type_required
                      : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child:
                        Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('partial_day'),
                  subtitle: const Text('partial_day_hint'),
                  value: _isPartialDay,
                  onChanged: (value) => setState(() => _isPartialDay = value!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_isPartialDay) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'start_time',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_startTime.format(context)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'end_time',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_endTime.format(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.reason,
                    border: const OutlineInputBorder(),
                    hintText: 'reason_hint',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${appLocalizations.duration}: ${_calculateDuration().toStringAsFixed(1)} ${appLocalizations.hours}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: Text(appLocalizations.cancel),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAbsence,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(appLocalizations.record),
          ),
        ],
      ),
    );
  }

  IconData _getAbsenceTypeIcon(AbsenceType type) {
    switch (type) {
      case AbsenceType.illness:
        return Icons.sick;
      case AbsenceType.lateArrival:
        return Icons.schedule;
      case AbsenceType.approvedTimeOff:
        return Icons.event_available;
    }
  }
}

class CreateEmployeeDialog extends StatefulWidget {
  final EmployeeManagementController controller;

  const CreateEmployeeDialog({super.key, required this.controller});

  @override
  State<CreateEmployeeDialog> createState() => _CreateEmployeeDialogState();
}

class _CreateEmployeeDialogState extends State<CreateEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();
  final _detailsController = TextEditingController();
  XFile? _photo;
  DateTime? _startDate;
  Status? _status;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _contactController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _photo = pickedFile);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: appLocalizations.select_date,
    );
    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(appLocalizations.create_employee),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: appLocalizations.name),
                validator: (value) => value == null || value.trim().isEmpty
                    ? appLocalizations.name_required
                    : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: appLocalizations.email),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return appLocalizations.email_required;
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return appLocalizations.invalid_email;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration:
                    InputDecoration(labelText: appLocalizations.password),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return appLocalizations.password_required;
                  if (value.length < 6)
                    return appLocalizations.password_too_short;
                  return null;
                },
              ),
              TextFormField(
                controller: _contactController,
                decoration:
                    InputDecoration(labelText: appLocalizations.contact),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final phoneRegExp = RegExp(r'^\+?[1-9]\d{1,14}$');
                    final emailRegExp =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!phoneRegExp.hasMatch(value) &&
                        !emailRegExp.hasMatch(value)) {
                      return appLocalizations.invalid_contact;
                    }
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _detailsController,
                decoration:
                    InputDecoration(labelText: appLocalizations.details),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: appLocalizations.start_date,
                  hintText: _startDate == null
                      ? appLocalizations.select_date
                      : DateFormat.yMMMd().format(_startDate!),
                ),
                onTap: () => _selectDate(context),
                validator: (value) => _startDate == null
                    ? appLocalizations.start_date_required
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Status>(
                value: _status,
                decoration: InputDecoration(labelText: appLocalizations.status),
                items: Status.values
                    .map((status) => DropdownMenuItem(
                        value: status, child: Text(status.value)))
                    .toList(),
                onChanged: (value) => setState(() => _status = value),
                validator: (value) =>
                    value == null ? appLocalizations.status_required : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickPhoto,
                    child: Text(appLocalizations.upload_photo),
                  ),
                  const SizedBox(width: 8),
                  if (_photo != null) Text(appLocalizations.photo_selected),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocalizations.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await widget.controller.createEmployee(
                name: _nameController.text,
                email: _emailController.text,
                password: _passwordController.text,
                contact: _contactController.text.isEmpty
                    ? null
                    : _contactController.text,
                details: _detailsController.text.isEmpty
                    ? null
                    : _detailsController.text,
                startDate: _startDate,
                status: _status,
              );
              if (context.mounted) {
                await LeaveService()
                    .initializeEmployeeLeaveAllocations(_emailController.text);
                Navigator.of(context).pop();
              }
            }
          },
          child: Text(appLocalizations.create),
        ),
      ],
    );
  }
}

class EditEmployeeDialog extends StatefulWidget {
  final Employer employee;
  final EmployeeManagementController controller;

  const EditEmployeeDialog(
      {super.key, required this.employee, required this.controller});

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late TextEditingController _detailsController;
  XFile? _photo;
  DateTime? _startDate;
  Status? _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _contactController = TextEditingController(text: widget.employee.contact);
    _detailsController = TextEditingController(text: widget.employee.details);
    _startDate = widget.employee.startDate;
    _status = widget.employee.status != null
        ? Status.fromString(widget.employee.status!)
        : Status.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _photo = pickedFile);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: appLocalizations.select_date,
    );
    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(appLocalizations.edit_employee),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.employee.photo != null &&
                  widget.employee.photo!.isNotEmpty)
                CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(widget.employee.photo!)),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: appLocalizations.name),
                validator: (value) => value == null || value.trim().isEmpty
                    ? appLocalizations.name_required
                    : null,
              ),
              TextFormField(
                controller: _contactController,
                decoration:
                    InputDecoration(labelText: appLocalizations.contact),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    const phoneRegExp = r'^\+?[1-9]\d{1,14}$';
                    const emailRegExp = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                    if (!RegExp(phoneRegExp).hasMatch(value) &&
                        !RegExp(emailRegExp).hasMatch(value)) {
                      return appLocalizations.invalid_contact;
                    }
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _detailsController,
                decoration:
                    InputDecoration(labelText: appLocalizations.details),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: appLocalizations.start_date,
                  hintText: _startDate == null
                      ? appLocalizations.select_date
                      : DateFormat.yMMMd().format(_startDate!),
                ),
                onTap: () => _selectDate(context),
                validator: (value) => _startDate == null
                    ? appLocalizations.start_date_required
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Status>(
                value: _status,
                decoration: InputDecoration(labelText: appLocalizations.status),
                items: Status.values
                    .map((status) => DropdownMenuItem(
                        value: status, child: Text(status.value)))
                    .toList(),
                onChanged: (value) => setState(() => _status = value),
                validator: (value) =>
                    value == null ? appLocalizations.status_required : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickPhoto,
                    child: Text(appLocalizations.change_photo),
                  ),
                  const SizedBox(width: 8),
                  if (_photo != null) Text(appLocalizations.photo_selected),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocalizations.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await widget.controller.updateEmployee(
                id: widget.employee.id,
                name: _nameController.text,
                contact: _contactController.text.isEmpty
                    ? null
                    : _contactController.text,
                details: _detailsController.text.isEmpty
                    ? null
                    : _detailsController.text,
                photo: _photo,
                startDate: _startDate,
                status: _status,
              );
              if (context.mounted) Navigator.of(context).pop();
            }
          },
          child: Text(appLocalizations.update),
        ),
      ],
    );
  }
}

class EmployeeDetails extends StatelessWidget {
  final String employeeId;

  final Employer employee;
  const EmployeeDetails(
      {super.key, required this.employeeId, required this.employee});

  @override
  Widget build(BuildContext context) {
    Widget _buildErrorMessage(String error) {
      final appLocalizations = AppLocalizations.of(context)!;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Theme.of(context).colorScheme.error.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
                child: Text(error,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          ],
        ),
      );
    }

    final controller = context.watch<LeaveManagementController>();

    final isLoading = controller.isLoading(employeeId);
    final error = controller.getError(employeeId);

    if (!controller.hasLoadedAllocations(employeeId) && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadEmployeeLeaveAllocations(employeeId);
      });
    }

    String _formatDate(DateTime date) {
      return DateFormat.yMd(Localizations.localeOf(context).languageCode)
          .format(date);
    }

    Widget _buildEmployeeHeader() {
      final appLocalizations = AppLocalizations.of(context)!;
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColorDark
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage:
                  employee.photo != null ? NetworkImage(employee.photo!) : null,
              child: employee.photo == null
                  ? Text(employee.name?.substring(0, 1).toUpperCase() ?? 'E',
                      style: Theme.of(context).textTheme.bodySmall)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name ?? appLocalizations.no_name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appLocalizations.schedule,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (employee.startDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${appLocalizations.start_date_label}: ${_formatDate(employee.startDate!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'activee',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildAdminActions(LeaveManagementController controller) {
      final appLocalizations = AppLocalizations.of(context)!;
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).colorScheme.error.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.admin_actions,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showRecordAbsenceDialog(
                  context, employee.id, employee.name ?? 'Employee'),
              icon: const Icon(Icons.add),
              label: Text(appLocalizations.record_absence),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(employee.name!),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmployeeHeader(),
          const SizedBox(height: 24),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (error != null)
            _buildErrorMessage(error)
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LeaveAllocationSummary(
                      allocations:
                          controller.getEmployeeAllocations(employeeId),
                      showTitle: true,
                    ),
                    const SizedBox(height: 32),
                    AbsenceSummary(
                      absences: controller.getEmployeeAbsences(employeeId),
                      totalAbsenceHours:
                          controller.getTotalAbsenceHours(employeeId),
                      showTitle: true,
                    ),
                    if (context.read<AuthController>().user.currentRole.id ==
                        'admin') ...[
                      const SizedBox(height: 32),
                      _buildAdminActions(controller),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showRecordAbsenceDialog(
      BuildContext context, String employeeId, String employeeName) {
    showDialog(
      context: context,
      builder: (context) => RecordAbsenceDialog(
        employeeId: employeeId,
        employeeName: employeeName,
        onAbsenceRecorded: () {
          context
              .read<LeaveManagementController>()
              .loadEmployeeLeaveAllocations(employeeId);
        },
      ),
    );
  }
}

class ProjectManagementView extends StatefulWidget {
  const ProjectManagementView({super.key});

  @override
  State<ProjectManagementView> createState() => _ProjectManagementViewState();
}

class _ProjectManagementViewState extends State<ProjectManagementView> {
  String _searchQuery = '';
  ProjectStatus? _statusFilter;
  String _sortBy = 'name'; // name, startDate, status
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final userRole = authController.user.currentRole.id;
    final appLocalizations = AppLocalizations.of(context)!;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectManagementController()),
        ChangeNotifierProvider.value(
            value: context.read<EmployeeManagementController>()
              ..loadEmployees()),
      ],
      child: Scaffold(
        body: Consumer<ProjectManagementController>(
          builder: (context, controller, child) {
            if (controller.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(controller.error!),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.loadProjects,
                      child: Text(appLocalizations.retry),
                    ),
                  ],
                ),
              );
            }

            final filteredProjects =
                _filterAndSortProjects(controller.projects);

            return Column(
              children: [
                _buildSearchAndFilterBar(context, appLocalizations),
                Expanded(
                  child: filteredProjects.isEmpty
                      ? _buildEmptyState(context, appLocalizations)
                      : RefreshIndicator(
                          onRefresh: () async {
                            await controller.loadProjects();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredProjects.length,
                            itemBuilder: (context, index) {
                              final project = filteredProjects[index];
                              return ProjectCard(
                                project: project,
                                onTap: () =>
                                    _navigateToProjectDetails(context, project),
                                onEdit: userRole == 'admin'
                                    ? () => _showEditProjectDialog(
                                        context, project, controller)
                                    : null,
                              );
                            },
                          )),
                ),
              ],
            );
          },
        ),
        floatingActionButton: Consumer<AuthController>(
          builder: (context, authController, child) {
            if (authController.user.currentRole.id == 'admin') {
              return FloatingActionButton(
                onPressed: () => _showProjectDialog(context),
                child: const Icon(Icons.add),
                tooltip: appLocalizations.create_project,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(
      BuildContext context, AppLocalizations appLocalizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: appLocalizations.search_projects,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                tooltip: appLocalizations.sort,
                onSelected: (value) {
                  setState(() {
                    if (_sortBy == value) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortBy = value;
                      _sortAscending = true;
                    }
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha),
                        SizedBox(width: 8),
                        Text(appLocalizations.sort_by_name),
                        if (_sortBy == 'name') ...[
                          Spacer(),
                          Icon(_sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'startDate',
                    child: Row(
                      children: [
                        Icon(Icons.date_range),
                        SizedBox(width: 8),
                        Text(appLocalizations.sort_by_date),
                        if (_sortBy == 'startDate') ...[
                          Spacer(),
                          Icon(_sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(Icons.flag),
                        SizedBox(width: 8),
                        Text(appLocalizations.sort_by_status),
                        if (_sortBy == 'status') ...[
                          Spacer(),
                          Icon(_sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(appLocalizations.all),
                  selected: _statusFilter == null,
                  onSelected: (selected) {
                    setState(() {
                      _statusFilter = selected ? null : _statusFilter;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...ProjectStatus.values.map((status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status.value),
                        selected: _statusFilter == status,
                        onSelected: (selected) {
                          setState(() {
                            _statusFilter = selected ? status : null;
                          });
                        },
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, AppLocalizations appLocalizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != null
                ? appLocalizations.no_projects_found
                : appLocalizations.no_projects_yet,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != null
                ? appLocalizations.try_different_filters
                : appLocalizations.create_first_project,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  List<Project> _filterAndSortProjects(List<Project> projects) {
    var filtered = projects.where((project) {
      final matchesSearch = _searchQuery.isEmpty ||
          project.name.toLowerCase().contains(_searchQuery) ||
          project.description.toLowerCase().contains(_searchQuery);
      final matchesStatus =
          _statusFilter == null || project.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'startDate':
          comparison = a.startDate.compareTo(b.startDate);
          break;
        case 'status':
          comparison = a.status.value.compareTo(b.status.value);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  void _navigateToProjectDetails(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetails(project: project),
      ),
    );
  }

  void _showEditProjectDialog(BuildContext context, Project project,
      ProjectManagementController controller) {
    showDialog(
      context: context,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
              value: context.read<EmployeeManagementController>()
                ..loadEmployees()),
          ChangeNotifierProvider(create: (_) => ProjectFormController(project)),
        ],
        child: EditProjectPage(
          project: project,
          controller: controller,
        ),
      ),
    );
  }

  void _showProjectDialog(BuildContext context, [Project? project]) {
    showDialog(
      context: context,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
              value: context.read<EmployeeManagementController>()
                ..loadEmployees()),
          ChangeNotifierProvider(create: (_) => ProjectFormController(project)),
        ],
        child: const ProjectFormPage(),
      ),
    );
  }
}

// Enhanced ProjectCard with better visual design
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _calculateProgress();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusChip(project.status, context),
                      if (onEdit != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: onEdit,
                          tooltip: AppLocalizations.of(context)!.edit,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (progress != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(progress),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  _buildInfoItem(
                    icon: Icons.calendar_today,
                    label: DateFormat.yMMMd().format(project.startDate),
                    context: context,
                  ),
                  const SizedBox(width: 16),
                  if (project.endDate != null)
                    _buildInfoItem(
                      icon: Icons.event,
                      label: DateFormat.yMMMd().format(project.endDate!),
                      context: context,
                    ),
                  const Spacer(),
                  _buildInfoItem(
                    icon: Icons.info_outline,
                    label: '${project.size}',
                    context: context,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ProjectStatus status, BuildContext context) {
    Color chipColor;
    IconData icon;

    switch (status) {
      case ProjectStatus.planning:
        chipColor = Colors.orange;
        icon = Icons.schedule;
        break;
      case ProjectStatus.active:
        chipColor = Colors.blue;
        icon = Icons.play_arrow;
        break;
      case ProjectStatus.completed:
        chipColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case ProjectStatus.onHold:
        chipColor = Colors.grey;
        icon = Icons.pause;
        break;
      default:
        chipColor = Colors.red;
        icon = Icons.error;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        status.value,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required BuildContext context,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  double? _calculateProgress() {
    if (project.endDate == null) return null;

    final now = DateTime.now();
    final totalDuration = project.endDate!.difference(project.startDate).inDays;
    final elapsedDuration = now.difference(project.startDate).inDays;

    if (totalDuration <= 0) return 1.0;
    if (elapsedDuration <= 0) return 0.0;

    final progress = elapsedDuration / totalDuration;
    return progress.clamp(0.0, 1.0);
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }
}

// New ProjectDetailsView for detailed project information
class ProjectDetails extends StatelessWidget {
  final Project project;

  const ProjectDetails({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final authController = context.watch<AuthController>();
    final userRole = authController.user.currentRole.id;

    print('ProjectDetails: ${project.assignments}');

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context),
              tooltip: appLocalizations.edit,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(context, theme, appLocalizations),
            const SizedBox(height: 24),
            _buildDetailsSection(context, theme, appLocalizations),
            const SizedBox(height: 24),
            _buildTimelineSection(context, theme, appLocalizations),
            const SizedBox(height: 24),
            _buildAssignmentsSection(
              context,
              theme,
              appLocalizations,
              project.assignments ?? [],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, ThemeData theme,
      AppLocalizations appLocalizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusChip(project.status, context),
                    ],
                  ),
                ),
                _buildProgressIndicator(context),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              appLocalizations.description,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              project.description,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, ThemeData theme,
      AppLocalizations appLocalizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appLocalizations.project_details,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.straighten,
              label: appLocalizations.project_size,
              value: project.size,
              context: context,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.workspaces,
              label: appLocalizations.project_scope,
              value: project.scope,
              context: context,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: appLocalizations.start_date,
              value: DateFormat.yMMMMd().format(project.startDate),
              context: context,
            ),
            if (project.endDate != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.event,
                label: appLocalizations.end_date_label,
                value: DateFormat.yMMMMd().format(project.endDate!),
                context: context,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(BuildContext context, ThemeData theme,
      AppLocalizations appLocalizations) {
    final daysElapsed = DateTime.now().difference(project.startDate).inDays;
    final totalDays = project.endDate?.difference(project.startDate).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appLocalizations.timeline,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '${appLocalizations.started}: ${DateFormat.yMMMMd().format(project.startDate)}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${appLocalizations.days_elapsed}: $daysElapsed ${appLocalizations.days}',
                ),
              ],
            ),
            if (project.endDate != null && totalDays != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.flag, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '${appLocalizations.total_duration}: $totalDays ${appLocalizations.days}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (daysElapsed / totalDays).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor((daysElapsed / totalDays).clamp(0.0, 1.0)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations appLocalizations,
    List<ProjectEmployees> employes,
  ) {
    print('employes: $employes');
    // This section would show assigned employees if that data is available
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appLocalizations.assigned_employers,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // For now, show a placeholder. In a real app, you'd display actual assignments
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  for (final employe in employes)
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            employe.role?.name ??
                                appLocalizations.assignment_info_placeholder,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ProjectStatus status, BuildContext context) {
    Color chipColor;
    IconData icon;

    switch (status) {
      case ProjectStatus.planning:
        chipColor = Colors.orange;
        icon = Icons.schedule;
        break;
      case ProjectStatus.active:
        chipColor = Colors.blue;
        icon = Icons.play_arrow;
        break;
      case ProjectStatus.completed:
        chipColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case ProjectStatus.onHold:
        chipColor = Colors.grey;
        icon = Icons.pause;
        break;
      default:
        chipColor = Colors.red;
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            status.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    if (project.endDate == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(Icons.all_inclusive, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              'Ongoing',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final progress = _calculateProgress();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor:
                  AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress() {
    if (project.endDate == null) return 0.0;

    final now = DateTime.now();
    final totalDuration = project.endDate!.difference(project.startDate).inDays;
    final elapsedDuration = now.difference(project.startDate).inDays;

    if (totalDuration <= 0) return 1.0;
    if (elapsedDuration <= 0) return 0.0;

    final progress = elapsedDuration / totalDuration;
    return progress.clamp(0.0, 1.0);
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider(
        create: (_) => ProjectManagementController(),
        child: Consumer<ProjectManagementController>(
          builder: (context, controller, child) {
            return EditProjectPage(
              project: project,
              controller: controller,
            );
          },
        ),
      ),
    );
  }
}

class EditProjectPage extends StatefulWidget {
  final Project project;
  final ProjectManagementController controller;

  const EditProjectPage({
    super.key,
    required this.project,
    required this.controller,
  });

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _sizeController;
  late TextEditingController _scopeController;
  DateTime? _startDate;
  DateTime? _endDate;
  ProjectStatus? _status;
  List<Map<String, String>> _assignments = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController =
        TextEditingController(text: widget.project.description);
    _sizeController = TextEditingController(text: widget.project.size);
    _scopeController = TextEditingController(text: widget.project.scope);
    _startDate = widget.project.startDate;
    _endDate = widget.project.endDate;
    _status = widget.project.status;
    _assignments = List.from(widget.project.assignments ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _scopeController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
            dialogBackgroundColor: Theme.of(context).colorScheme.surface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
            dialogBackgroundColor: Theme.of(context).colorScheme.surface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate) {
      setState(() => _endDate = picked);
    }
  }

  // void _addAssignment(String employerId, ProjectRole role) {
  //   if (role == ProjectRole.peopleManager &&
  //       _assignments.any((a) => a['role'] == 'People Manager')) {
  //     return; // Prevent adding multiple People Managers
  //   }
  //   setState(() {
  //     _assignments.add({
  //       'employer_id': employerId,
  //       'role': role.value,
  //     });
  //   });
  // }

  // void _removeAssignment(String employerId) {
  //   setState(() {
  //     _assignments
  //         .removeWhere((assignment) => assignment['employer_id'] == employerId);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final formController = context.watch<ProjectFormController>();
    final employeeController = context.watch<EmployeeManagementController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appLocalizations.edit_project,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.project_name,
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        prefixIcon:
                            Icon(Icons.title, color: theme.colorScheme.primary),
                      ),
                      validator: (value) => value!.trim().isEmpty
                          ? appLocalizations.name_required
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.description,
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        prefixIcon: Icon(Icons.description,
                            color: theme.colorScheme.primary),
                      ),
                      maxLines: 4,
                      validator: (value) => value!.trim().isEmpty
                          ? appLocalizations.description
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Project Size
                    TextFormField(
                      controller: _sizeController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.project_size,
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        prefixIcon:
                            Icon(Icons.scale, color: theme.colorScheme.primary),
                      ),
                      validator: (value) => value!.trim().isEmpty
                          ? appLocalizations.project_size
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Project Scope
                    TextFormField(
                      controller: _scopeController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.project_scope,
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        prefixIcon:
                            Icon(Icons.score, color: theme.colorScheme.primary),
                      ),
                      validator: (value) => value!.trim().isEmpty
                          ? appLocalizations.project_scope
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Start Date
                    InkWell(
                      onTap: () => _selectStartDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: appLocalizations.start_date,
                          labelStyle:
                              TextStyle(color: theme.colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withOpacity(0.1),
                          suffixIcon: Icon(Icons.calendar_today,
                              color: theme.colorScheme.primary),
                        ),
                        child: Text(
                          _startDate != null
                              ? DateFormat.yMMMd().format(_startDate!)
                              : appLocalizations.select_date,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // End Date
                    InkWell(
                      onTap: () => _selectEndDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: appLocalizations.end_date_label,
                          labelStyle:
                              TextStyle(color: theme.colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withOpacity(0.1),
                          suffixIcon: Icon(Icons.calendar_today,
                              color: theme.colorScheme.primary),
                        ),
                        child: Text(
                          _endDate != null
                              ? DateFormat.yMMMd().format(_endDate!)
                              : appLocalizations.not_set,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status Dropdown
                    DropdownButtonFormField<ProjectStatus>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: appLocalizations.status,
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        prefixIcon: Icon(Icons.stairs,
                            color: theme.colorScheme.primary),
                      ),
                      items: ProjectStatus.values
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.value),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _status = value),
                      validator: (value) => value == null
                          ? appLocalizations.status_required
                          : null,
                    ),
                    const SizedBox(height: 24),
                    // Employer Assignments Section
                    _buildEmployerAssignmentSection(
                        context, formController, employeeController),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: Text(
                            appLocalizations.cancel,
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () =>
                              _saveProject(context, formController, _formKey),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            elevation: 2,
                          ),
                          child: Text(appLocalizations.update),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProjectFormPage extends StatelessWidget {
  const ProjectFormPage({super.key});

  static final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final formController = context.watch<ProjectFormController>();
    final employeeController = context.watch<EmployeeManagementController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          formController.project == null
              ? appLocalizations.create_project
              : appLocalizations.edit_project,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Name
                    TextFormField(
                      controller: formController.nameController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.project_name,
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        prefixIcon:
                            Icon(Icons.title, color: theme.colorScheme.primary),
                      ),
                      validator: (value) => value!.trim().isEmpty
                          ? appLocalizations.name_required
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Description
                    TextFormField(
                      controller: formController.descriptionController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.description,
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        prefixIcon: Icon(Icons.description,
                            color: theme.colorScheme.primary),
                      ),
                      maxLines: 4,
                      validator: (value) => value!.trim().isEmpty
                          ? appLocalizations.description
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Project Size
                    TextFormField(
                      controller: formController.sizeController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.project_size,
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        prefixIcon:
                            Icon(Icons.scale, color: theme.colorScheme.primary),
                      ),
                      validator: (value) => value!.trim().isEmpty
                          ? appLocalizations.project_size
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Project Scope
                    TextFormField(
                      controller: formController.scopeController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.project_scope,
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        prefixIcon:
                            Icon(Icons.score, color: theme.colorScheme.primary),
                      ),
                      validator: (value) => value!.trim().isEmpty
                          ? appLocalizations.project_scope
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Start Date
                    InkWell(
                      onTap: () => _selectDate(context, formController, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: appLocalizations.start_date,
                          labelStyle:
                              TextStyle(color: theme.colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withOpacity(0.1),
                          suffixIcon: Icon(Icons.calendar_today,
                              color: theme.colorScheme.primary),
                        ),
                        child: Text(
                          DateFormat.yMMMd().format(formController.startDate),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // End Date
                    InkWell(
                      onTap: () => _selectDate(context, formController, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: appLocalizations.end_date_label,
                          labelStyle:
                              TextStyle(color: theme.colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withOpacity(0.1),
                          suffixIcon: Icon(Icons.calendar_today,
                              color: theme.colorScheme.primary),
                        ),
                        child: Text(
                          formController.endDate == null
                              ? appLocalizations.not_set
                              : DateFormat.yMMMd()
                                  .format(formController.endDate!),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status Dropdown
                    DropdownButtonFormField<ProjectStatus>(
                      value: formController.status,
                      decoration: InputDecoration(
                        labelText: appLocalizations.status,
                        labelStyle: TextStyle(color: theme.colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.1),
                        prefixIcon: Icon(Icons.stairs,
                            color: theme.colorScheme.primary),
                      ),
                      items: ProjectStatus.values
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.value),
                              ))
                          .toList(),
                      onChanged: (value) => formController.setStatus(value!),
                    ),
                    const SizedBox(height: 24),
                    // Employer Assignments Section
                    _buildEmployerAssignmentSection(
                      context,
                      formController,
                      employeeController,
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: Text(
                            appLocalizations.cancel,
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () =>
                              _saveProject(context, formController, _formKey),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            elevation: 2,
                          ),
                          child: Text(
                            formController.project == null
                                ? appLocalizations.create
                                : appLocalizations.update,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context,
      ProjectFormController formController, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? formController.startDate
          : (formController.endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
            dialogBackgroundColor: Theme.of(context).colorScheme.surface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (isStartDate) {
        formController.setStartDate(picked);
      } else {
        formController.setEndDate(picked);
      }
    }
  }
}

Future<void> _saveProject(BuildContext context,
    ProjectFormController formController, GlobalKey<FormState> formKey) async {
  if (formKey.currentState!.validate()) {
    final controller = context.read<ProjectManagementController>();
    bool success;
    if (formController.project == null) {
      success = await controller.createProject(
        name: formController.nameController.text,
        description: formController.descriptionController.text,
        startDate: formController.startDate,
        endDate: formController.endDate,
        size: formController.sizeController.text,
        scope: formController.scopeController.text,
        status: formController.status,
        employerAssignments: formController.assignments,
      );
    } else {
      success = await controller.updateProject(
        projectId: formController.project!.id,
        name: formController.nameController.text,
        description: formController.descriptionController.text,
        startDate: formController.startDate,
        endDate: formController.endDate,
        size: formController.sizeController.text,
        scope: formController.scopeController.text,
        status: formController.status,
        employerAssignments: formController.assignments,
      );
    }
    if (success && context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formController.project == null
              ? 'project_create_success'
              : 'project_update_success'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

void _showEmployerSelectionDialog(
  BuildContext context,
  ProjectFormController formController,
  EmployeeManagementController employeeController,
) {
  showDialog(
    context: context,
    builder: (context) {
      final appLocalizations = AppLocalizations.of(context)!;
      final theme = Theme.of(context);
      final hasPeopleManager =
          formController.assignments.any((a) => a['role'] == 'People Manager');

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          appLocalizations.select_employer,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: employeeController.employees
                .where((e) => !formController.assignments
                    .any((a) => a['employer_id'] == e.id))
                .map((employer) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          employer.name ?? employer.id,
                          style: theme.textTheme.bodyLarge,
                        ),
                        onTap: () async {
                          final role = await showDialog<ProjectRole>(
                            context: context,
                            builder: (context) => SimpleDialog(
                              title: Text('select_role'),
                              children: ProjectRole.values
                                  .where((role) =>
                                      !hasPeopleManager ||
                                      role != ProjectRole.peopleManager)
                                  .map((role) => SimpleDialogOption(
                                        onPressed: () =>
                                            Navigator.pop(context, role),
                                        child: Text(role.value),
                                      ))
                                  .toList(),
                            ),
                          );
                          if (role != null) {
                            formController.addAssignment(employer.id, role);
                            Navigator.of(context).pop(); // close main dialog
                          }
                        },
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(appLocalizations.cancel,
                style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      );
    },
  );
}

Widget _buildEmployerAssignmentSection(
    BuildContext context,
    ProjectFormController formController,
    EmployeeManagementController employeeController) {
  final appLocalizations = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        appLocalizations.assigned_employers,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
      const SizedBox(height: 12),
      if (formController.assignments.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: formController.assignments.map((assignment) {
            final employer = employeeController.employees.firstWhere(
              (e) => e.id == assignment['employer_id'],
              orElse: () => Employer(
                id: assignment['employer_id']!,
                roles: [AppRole(id: 'employer')],
              ),
            );
            return Chip(
              label: Text(
                '${employer.name ?? employer.id} (${assignment['role']})',
                style: theme.textTheme.bodyMedium,
              ),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () =>
                  formController.removeAssignment(assignment['employer_id']!),
              backgroundColor: assignment['role'] == 'People Manager'
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surface,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            );
          }).toList(),
        )
      else
        Text(
          'no_employers_assigned',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: () => _showEmployerSelectionDialog(
            context, formController, employeeController),
        icon: const Icon(Icons.person_add),
        label: Text(appLocalizations.add_employer),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 2,
        ),
      ),
    ],
  );
}

class ProjectFormController extends ChangeNotifier {
  final Project? project;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();
  final _scopeController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  ProjectStatus _status = ProjectStatus.planning;
  ProjectRole _role = ProjectRole.worker;
  List<Map<String, String>> _assignments = [];

  ProjectFormController(this.project) {
    if (project != null) {
      _nameController.text = project!.name;
      _descriptionController.text = project!.description;
      _sizeController.text = project!.size;
      _scopeController.text = project!.scope;
      _startDate = project!.startDate;
      _endDate = project!.endDate;
      _status = project!.status;
    }
  }

  TextEditingController get nameController => _nameController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get sizeController => _sizeController;
  TextEditingController get scopeController => _scopeController;
  DateTime get startDate => _startDate;
  DateTime? get endDate => _endDate;
  ProjectStatus get status => _status;
  ProjectRole get role => _role;
  List<Map<String, String>> get assignments => _assignments;

  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime? date) {
    _endDate = date;
    notifyListeners();
  }

  void setStatus(ProjectStatus status) {
    _status = status;
    notifyListeners();
  }

  void setRole(ProjectRole role) {
    _role = role;
    notifyListeners();
  }

  void addAssignment(String employerId, ProjectRole role) {
    _assignments.add({'employer_id': employerId, 'role': role.value});
    notifyListeners();
  }

  void removeAssignment(String employerId) {
    _assignments.removeWhere((a) => a['employer_id'] == employerId);
    notifyListeners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _scopeController.dispose();
    super.dispose();
  }
}
