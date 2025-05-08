import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller_provider/locale_provider.dart';
import '../l10n/generated/app_localizations.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.admin),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              final provider =
                  Provider.of<LocaleProvider>(context, listen: false);
              final currentLocale = provider.locale;
              final newLocale = currentLocale.languageCode == 'en'
                  ? const Locale('ar')
                  : const Locale('en');
              provider.changeLocale(newLocale);
            },
            tooltip: 'Change Language',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.bienvenue),
            const SizedBox(height: 20),
           
          ],
        ),
      ),
    );
  }
}


