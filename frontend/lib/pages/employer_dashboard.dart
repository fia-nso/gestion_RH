import 'package:flutter/material.dart';
import 'package:frontend/controller_provider/auth_provider.dart';

import 'package:frontend/controller_provider/update_provider.dart';
import 'package:frontend/l10n/generated/app_localizations.dart';

import 'package:provider/provider.dart';

import '../controller_provider/locale_provider.dart';

class EmployerDashboard extends StatelessWidget {
  const EmployerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmployerUpdateController(),
      child: const _EmployerDashboardBody(),
    );
  }
}

class _EmployerDashboardBody extends StatelessWidget {
  const _EmployerDashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = Provider.of<LocaleProvider>(context);
    final controller = context.watch<EmployerUpdateController>();
    final authController = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.employer),
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
        ],
      ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : controller.error != null
              ? const Center(child: Text("❌ Failed to load user"))
              : Builder(
                  builder: (context) {
                    final employer = authController.emoloyer;
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.bienvenue}, ${employer.name ?? "👤"}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          TextField(controller: controller.nameController),
                          const SizedBox(height: 20),
                          controller.loading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: controller.save,
                                  child: const Text('🖊 Test Update User'),
                                ),
                          // if (_updateMessage != null)
                          //   Padding(
                          //     padding: const EdgeInsets.only(top: 16.0),
                          //     child: Text(
                          //       _updateMessage!,
                          //       style: TextStyle(
                          //         color: _updateMessage!.contains('✅')
                          //             ? Colors.green
                          //             : Colors.red,
                          //         fontWeight: FontWeight.bold,
                          //       ),
                          //     ),
                          //   ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
