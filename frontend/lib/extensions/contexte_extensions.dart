import 'package:flutter/material.dart';
import 'package:frontend/l10n/generated/app_localizations.dart';

extension BuildContextExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}
