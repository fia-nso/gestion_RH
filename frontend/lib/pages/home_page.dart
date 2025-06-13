import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/controller_provider/update_provider.dart';
import 'package:frontend/l10n/generated/app_localizations.dart';
import 'package:frontend/models/auth_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/uttils/navigator.dart';
import 'package:http/http.dart' as http;
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
import 'package:google_nav_bar/google_nav_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => EmployerUpdateController(context)),
        ChangeNotifierProvider(create: (_) => EmployeeManagementController()),
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

  // Variables pour la gestion des projets
  TextEditingController _projectNameController = TextEditingController();
  TextEditingController _projectDescriptionController = TextEditingController();
  DateTime? _projectStartDate;
  DateTime? _projectEndDate;
  String _projectSize = 'medium';
  String _projectScope = '';
  String _projectStatus = 'Planning';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectDescriptionController.dispose();
    super.dispose();
  }

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
      pages.add(const ProjectManagementView()); // Add Projects page first
      navButtons.add(
        GButton(
          icon: Icons.folder,
          text: AppLocalizations.of(context)!.projects,
          semanticLabel: AppLocalizations.of(context)!.projects,
        ),
      );
    }

    // Add Project Management page for relevant roles (e.g., admin or employer)
    if (userRole == 'admin' || userRole == 'employer') {
      pages.add(_buildProjectManagement(context));
      navButtons.add(
        GButton(
          icon: Icons.work,
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

  Widget _buildProjectManagement(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion des Projets',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _projectNameController,
              decoration: InputDecoration(labelText: 'Nom du projet'),
              validator: (value) => value!.isEmpty ? 'Le nom est requis' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _projectDescriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectProjectDate(context, true),
                    child: Text(_projectStartDate == null
                        ? 'Sélectionner la date de début'
                        : 'Début: ${_projectStartDate!.toLocal()}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectProjectDate(context, false),
                    child: Text(_projectEndDate == null
                        ? 'Sélectionner la date de fin'
                        : 'Fin: ${_projectEndDate!.toLocal()}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _projectSize == 0 ? null : _projectSize.toString(),
              items: ['small', 'medium', 'large']
                  .map((size) => DropdownMenuItem(
                        value: size,
                        child: Text(size),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _projectSize = value ?? 'medium'),
              decoration: InputDecoration(labelText: 'Taille du projet'),
              validator: (value) =>
                  value == null ? 'La taille est requise' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(labelText: 'Portée du projet'),
              onChanged: (value) => _projectScope = value,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _projectStatus,
              items: ['Planning', 'Active', 'On Hold', 'Completed']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _projectStatus = value!),
              decoration: InputDecoration(labelText: 'Statut du projet'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitProjectForm,
              child: Text('Soumettre'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectProjectDate(
      BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _projectStartDate = picked;
        } else {
          _projectEndDate = picked;
        }
      });
    }
  }

  Future<void> _submitProjectForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_projectStartDate == null || _projectEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Veuillez sélectionner les dates de début et de fin')),
      );
      return;
    }

    if (_projectStartDate!.isAfter(_projectEndDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('La date de début doit être antérieure à la date de fin')),
      );
      return;
    }

    final authController = context.read<AuthController>();
    final token = authController.user.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Aucun token d\'authentification trouvé. Veuillez vous connecter.')),
      );
      return;
    }

    print({
      'name': _projectNameController.text,
      'description': _projectDescriptionController.text,
      'startDate': _projectStartDate?.toIso8601String(),
      'endDate': _projectEndDate?.toIso8601String(),
      'size': _projectSize,
      'scope': _projectScope,
      'status': _projectStatus,
    });

    final response = await http.post(
      Uri.parse('http://192.168.100.54:3000/projects'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Inclure le token
      },
      body: jsonEncode({
        'name': _projectNameController.text,
        'description': _projectDescriptionController.text,
        'startDate': _projectStartDate?.toIso8601String(),
        'endDate': _projectEndDate?.toIso8601String(),
        'size': _projectSize,
        'scope': _projectScope,
        'status': _projectStatus,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Projet créé avec succès')),
      );
      _projectNameController.clear();
      _projectDescriptionController.clear();
      setState(() {
        _projectStartDate = null;
        _projectEndDate = null;
        _projectSize = 'medium';
        _projectScope = '';
        _projectStatus = 'Planning';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${response.body}')),
      );
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
    final userName = authController.user.name;
    final userStatus = authController.user.status;
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

class EditProjectDialog extends StatefulWidget {
  final Project project;
  final ProjectManagementController controller;

  const EditProjectDialog({
    super.key,
    required this.project,
    required this.controller,
  });

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _sizeController;
  late TextEditingController _scopeController;
  DateTime? _startDate;
  DateTime? _endDate;
  ProjectStatus? _status;

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
      helpText: 'Sélectionner la date de début',
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
      helpText: 'Sélectionner la date de fin',
    );
    if (picked != null && picked != _endDate) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Modifier le projet'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nom du projet'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Le nom du projet est requis'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'La description est requise'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sizeController,
                decoration: InputDecoration(labelText: 'Taille'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'La taille est requise'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scopeController,
                decoration: InputDecoration(labelText: 'Portée'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'La portée est requise'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date de début',
                  hintText: _startDate == null
                      ? 'Sélectionner la date'
                      : DateFormat.yMMMd().format(_startDate!),
                ),
                onTap: () => _selectStartDate(context),
                validator: (value) =>
                    _startDate == null ? 'La date de début est requise' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date de fin (optionnelle)',
                  hintText: _endDate == null
                      ? 'Sélectionner la date'
                      : DateFormat.yMMMd().format(_endDate!),
                ),
                onTap: () => _selectEndDate(context),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProjectStatus>(
                value: _status,
                decoration: InputDecoration(labelText: 'Statut'),
                items: ProjectStatus.values
                    .map((status) => DropdownMenuItem(
                        value: status, child: Text(status.value)))
                    .toList(),
                onChanged: (value) => setState(() => _status = value),
                validator: (value) =>
                    value == null ? 'Le statut est requis' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final success = await widget.controller.updateProject(
                projectId: widget.project.id,
                name: _nameController.text,
                description: _descriptionController.text,
                startDate: _startDate,
                endDate: _endDate,
                size: _sizeController.text,
                scope: _scopeController.text,
                status: _status,
              );

              if (context.mounted) {
                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Projet mis à jour avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.controller.error ??
                          'Erreur lors de la mise à jour'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          child: Text('Mettre à jour'),
        ),
      ],
    );
  }
}

// 2. Mise à jour du ProjectManagementView (remplacez votre code existant)

class ProjectManagementView extends StatelessWidget {
  const ProjectManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectManagementController(),
      child: Scaffold(
        body: Consumer<ProjectManagementController>(
          builder: (context, controller, child) {
            if (controller.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.error != null) {
              return Center(child: Text(controller.error!));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.projects.length,
              itemBuilder: (context, index) {
                final project = controller.projects[index];
                return ProjectCard(
                  project: project,
                  onEdit: () =>
                      _showEditProjectDialog(context, project, controller),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showProjectDialog(context),
          child: const Icon(Icons.add),
          tooltip: 'Créer un projet',
        ),
      ),
    );
  }

  void _showEditProjectDialog(BuildContext context, Project project,
      ProjectManagementController controller) {
    showDialog(
      context: context,
      builder: (context) => EditProjectDialog(
        project: project,
        controller: controller,
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
        child: const ProjectFormDialog(),
      ),
    );
  }
}

// 3. Mise à jour du ProjectCard (remplacez votre code existant)

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onEdit;

  const ProjectCard({super.key, required this.project, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Vous pouvez ajouter une navigation vers les détails du projet ici
        },
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
                  _buildStatusChip(project.status, context),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoItem(
                    icon: Icons.calendar_today,
                    label:
                        '${DateFormat.yMMMd().format(project.startDate)} - ${project.endDate != null ? DateFormat.yMMMd().format(project.endDate!) : 'En cours'}',
                    context: context,
                  ),
                  const Spacer(),
                  _buildInfoItem(
                    icon: Icons.info_outline,
                    label: '${project.size} / ${project.scope}',
                    context: context,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text('Modifier'),
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
    switch (status) {
      case ProjectStatus.planning:
        chipColor = Colors.orange;
        break;
      case ProjectStatus.active:
        chipColor = Colors.blue;
        break;
      case ProjectStatus.completed:
        chipColor = Colors.green;
        break;
      case ProjectStatus.onHold:
        chipColor = Colors.grey;
        break;
      case ProjectStatus.values:
        chipColor = Colors.red;
        break;
    }

    return Chip(
      label: Text(
        status.value,
        style: TextStyle(color: Colors.white, fontSize: 12),
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
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
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

  void addAssignment(String employerId, String role) {
    _assignments.add({'employer_id': employerId, 'role': role});
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

class ProjectFormDialog extends StatelessWidget {
  const ProjectFormDialog({super.key});

  static final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final formController = context.watch<ProjectFormController>();
    final employeeController = context.watch<EmployeeManagementController>();

    return AlertDialog(
      title: Text(formController.project == null
          ? appLocalizations.create_project
          : appLocalizations.edit_project),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: formController.nameController,
                decoration: InputDecoration(
                  labelText: appLocalizations.project_name,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value!.trim().isEmpty
                    ? appLocalizations.name_required
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: formController.descriptionController,
                decoration: InputDecoration(
                  labelText: appLocalizations.description,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value!.trim().isEmpty ? appLocalizations.description : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: formController.sizeController,
                decoration: InputDecoration(
                  labelText: appLocalizations.project_size,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value!.trim().isEmpty
                    ? appLocalizations.project_size
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: formController.scopeController,
                decoration: InputDecoration(
                  labelText: appLocalizations.project_scope,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value!.trim().isEmpty
                    ? appLocalizations.project_scope
                    : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context, formController, true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: appLocalizations.start_date,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat.yMMMd().format(formController.startDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context, formController, false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: appLocalizations.end_date_label,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(formController.endDate == null
                      ? appLocalizations.not_set
                      : DateFormat.yMMMd().format(formController.endDate!)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProjectStatus>(
                value: formController.status,
                decoration: InputDecoration(
                  labelText: appLocalizations.status,
                  border: const OutlineInputBorder(),
                ),
                items: ProjectStatus.values
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.value),
                        ))
                    .toList(),
                onChanged: (value) => formController.setStatus(value!),
              ),
              const SizedBox(height: 16),
              _buildEmployerAssignmentSection(
                context,
                formController,
                employeeController,
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
          onPressed: () => _saveProject(context, formController, _formKey),
          child: Text(formController.project == null
              ? appLocalizations.create
              : appLocalizations.update),
        ),
      ],
    );
  }
}

Widget _buildEmployerAssignmentSection(
    BuildContext context,
    ProjectFormController formController,
    EmployeeManagementController employeeController) {
  final appLocalizations = AppLocalizations.of(context)!;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        appLocalizations.assigned_employers,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      const SizedBox(height: 8),
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
              label: Text(employer.name ?? employer.id),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () =>
                  formController.removeAssignment(assignment['employer_id']!),
            );
          }).toList(),
        ),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        onPressed: () => _showEmployerSelectionDialog(
            context, formController, employeeController),
        icon: const Icon(Icons.person_add),
        label: Text(appLocalizations.add_employer),
      ),
    ],
  );
}

Future<void> _selectDate(BuildContext context, ProjectFormController controller,
    bool isStartDate) async {
  final initialDate =
      isStartDate ? controller.startDate : controller.endDate ?? DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime.now().subtract(const Duration(days: 365)),
    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
  );
  if (date != null) {
    if (isStartDate) {
      controller.setStartDate(date);
    } else {
      controller.setEndDate(date);
    }
  }
}

void _showEmployerSelectionDialog(
    BuildContext context,
    ProjectFormController formController,
    EmployeeManagementController employeeController) {
  showDialog(
    context: context,
    builder: (context) {
      final roleController = TextEditingController();
      Employer? selectedEmployer;

      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.select_employer),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Employer>(
                  decoration: const InputDecoration(
                    labelText: 'Employer',
                    border: OutlineInputBorder(),
                  ),
                  items: employeeController.employees
                      .where((e) => !formController.assignments
                          .any((a) => a['employer_id'] == e.id))
                      .map((employer) => DropdownMenuItem(
                            value: employer,
                            child: Text(employer.name ?? employer.id),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedEmployer = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: roleController,
                  decoration: const InputDecoration(
                    labelText: 'Role (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedEmployer != null) {
                formController.addAssignment(
                    selectedEmployer!.id, roleController.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      );
    },
  );
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
