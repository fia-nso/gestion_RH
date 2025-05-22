import 'package:flutter/material.dart';
import 'package:frontend/controller_provider/update_provider.dart';
import 'package:frontend/l10n/generated/app_localizations.dart';
import 'package:frontend/models/auth_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/uttils/navigator.dart';
import 'package:provider/provider.dart';
import '../controller_provider/auth_provider.dart';
import '../controller_provider/employee_management_controller.dart';
import '../controller_provider/locale_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => EmployerUpdateController(context)),
        ChangeNotifierProvider(create: (_) => EmployeeManagementController()),
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

class _HomePageBodyState extends State<_HomePageBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final authController = Provider.of<AuthController>(context, listen: false);
    final userRole = authController.user.currentRole.id;

    int tabCount = userRole == 'admin' ? 2 : 1;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeController = Provider.of<LocaleProvider>(context);
    final authController = context.watch<AuthController>();
    final userRole = authController.user.currentRole.id;
    final userName = authController.user.name;

    List<Tab> tabs = [];
    List<Widget> tabViews = [];

    tabs.add(Tab(text: AppLocalizations.of(context)!.profile));
    tabViews.add(_buildProfileTab(context, authController, userRole));

    if (userRole == 'admin') {
      tabs.add(Tab(text: AppLocalizations.of(context)!.employees));
      tabViews.add(const EmployeeManagementView());
    }

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
        bottom: tabs.length > 1
            ? TabBar(
                controller: _tabController,
                tabs: tabs,
              )
            : null,
      ),
      body: tabs.length > 1
          ? TabBarView(
              controller: _tabController,
              children: tabViews,
            )
          : tabViews.first,
    );
  }

  String _getRoleTitle(BuildContext context, String role) {
    switch (role) {
      case 'admin':
        return AppLocalizations.of(context)!.admin;
      case 'employer':
        return AppLocalizations.of(context)!.employer;
      case 'assistant':
        return AppLocalizations.of(context)!.assistant;
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
    final employer = authController.employer;

    return controller.loading
        ? const Center(child: CircularProgressIndicator())
        : controller.error != null
            ? Center(child: Text(controller.error!))
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.bienvenue}, ${employer.name ?? "👤"}',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            employer.photo != null && employer.photo!.isNotEmpty
                                ? NetworkImage(employer.photo!)
                                : null,
                        onBackgroundImageError: (exception, stackTrace) {
                          print(
                              'Erreur de chargement de l\'image : $exception');
                        },
                        child: employer.photo == null || employer.photo!.isEmpty
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => controller.pickPhoto(context),
                        child: Text(AppLocalizations.of(context)!.upload_photo),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: controller.nameController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.name,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: controller.contactController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.contact,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: controller.detailsController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.details,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${AppLocalizations.of(context)!.status}: ${employer.status ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      controller.loading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () => controller.save(context),
                              child: Text(AppLocalizations.of(context)!.save),
                            ),
                      if (controller.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            controller.error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
  }

  Widget _buildGenericProfile(
      BuildContext context, AuthController authController, String userRole) {
    final userName = authController.user.name;
    final userStatus = authController.user.status;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 20),
          Text(
            '${AppLocalizations.of(context)!.bienvenue}, ${userName ?? "Utilisateur"}',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Rôle : ${userRole.toUpperCase()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Text(
            '${AppLocalizations.of(context)!.status}: ${userStatus ?? 'N/A'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.logout),
          content: Text(AppLocalizations.of(context)!.confirm_logout),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.logout),
              onPressed: () async {
                await EmployerService().signOut();
                Navigator.of(context).pop();
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
}

class EmployeeManagementView extends StatefulWidget {
  const EmployeeManagementView({super.key});

  @override
  State<EmployeeManagementView> createState() => _EmployeeManagementViewState();
}

class _EmployeeManagementViewState extends State<EmployeeManagementView> {
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
                  ? Center(
                      child: Text(appLocalizations.no_employees),
                    )
                  : ListView.builder(
                      itemCount: controller.employees.length,
                      itemBuilder: (context, index) {
                        final employee = controller.employees[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: employee.photo != null &&
                                      employee.photo!.isNotEmpty
                                  ? NetworkImage(employee.photo!)
                                  : null,
                              child: employee.photo == null ||
                                      employee.photo!.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title:
                                Text(employee.name ?? appLocalizations.no_name),
                            subtitle: Text(employee.contact ??
                                appLocalizations.no_contact),
                            trailing: PopupMenuButton<String>(
                              onSelected: (String value) {
                                switch (value) {
                                  case 'edit':
                                    _showEditEmployeeDialog(context, employee);
                                    break;
                                  case 'delete':
                                    _showDeleteEmployeeDialog(
                                        context, employee);
                                    break;
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text(appLocalizations.edit),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text(appLocalizations.delete),
                                ),
                              ],
                            ),
                            onTap: () =>
                                _showEmployeeDetails(context, employee),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEmployeeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEmployeeDetails(BuildContext context, Employer employee) {
    final appLocalizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(employee.name ?? appLocalizations.employee_details),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (employee.photo != null && employee.photo!.isNotEmpty)
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(employee.photo!),
                  ),
                ),
              const SizedBox(height: 16),
              Text('${appLocalizations.name}: ${employee.name ?? 'N/A'}'),
              Text('${appLocalizations.contact}: ${employee.contact ?? 'N/A'}'),
              Text('${appLocalizations.details}: ${employee.details ?? 'N/A'}'),
              Text(
                  '${'start_date'}: ${employee.startDate != null ? DateFormat.yMMMd().format(employee.startDate!) : 'N/A'}'),
              Text('${appLocalizations.status}: ${employee.status ?? 'N/A'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(appLocalizations.close),
          ),
        ],
      ),
    );
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
      setState(() {
        _photo = pickedFile;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations.name_required;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: appLocalizations.email),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations.email_required;
                  }
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
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations.password_required;
                  }
                  if (value.length < 6) {
                    return appLocalizations.password_too_short;
                  }
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
                  labelText: 'start_date',
                  hintText: _startDate == null
                      ? 'Select start date'
                      : DateFormat.yMMMd().format(_startDate!),
                ),
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (_startDate == null) {
                    return appLocalizations.start_date_required;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Status>(
                value: _status,
                decoration: InputDecoration(labelText: appLocalizations.status),
                items: Status.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return appLocalizations.status_required;
                  }
                  return null;
                },
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
              if (context.mounted) Navigator.of(context).pop();
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
        : null;
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
      setState(() {
        _photo = pickedFile;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
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
                  backgroundImage: NetworkImage(widget.employee.photo!),
                ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: appLocalizations.name),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return appLocalizations.name_required;
                  }
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
                  labelText: 'start_date',
                  hintText: _startDate == null
                      ? 'Select start date'
                      : DateFormat.yMMMd().format(_startDate!),
                ),
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (_startDate == null) {
                    return appLocalizations.start_date_required;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Status>(
                value: _status,
                decoration: InputDecoration(labelText: appLocalizations.status),
                items: Status.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return appLocalizations.status_required;
                  }
                  return null;
                },
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
