// screens/shared/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:frontend/l10n/generated/app_localizations.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onLanguageToggle;
  final VoidCallback onLogout;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.onLanguageToggle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.language),
          onPressed: onLanguageToggle,
          tooltip: appLocalizations.change_language,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: onLogout,
          tooltip: appLocalizations.logout,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}