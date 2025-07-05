import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primary = Color.fromARGB(255, 25, 118, 210); // #1976D2
  static const Color primaryDark = Color.fromARGB(255, 13, 71, 161); // #0D47A1
  static const Color primaryLight =
      Color.fromARGB(255, 187, 222, 251); // #BBDEFB

  // Couleur secondaire
  static const Color secondary = Color.fromARGB(255, 67, 160, 71); // #43A047

  // Accentuation / Alerte
  static const Color accent = Color.fromARGB(255, 251, 140, 0); // #FB8C00

  // Erreur
  static const Color error = Color.fromARGB(255, 229, 57, 53); // #E53935

  // Arrière-plan général
  static const Color background = Color.fromARGB(255, 245, 245, 245); // #F5F5F5

  // Surface (ex: cartes)
  static const Color surface = Color.fromARGB(255, 255, 255, 255); // #FFFFFF


  // Texte principal
  static const Color textPrimary = Color.fromARGB(255, 33, 33, 33); // #212121

  // Texte secondaire
  static const Color textSecondary =
      Color.fromARGB(255, 117, 117, 117);

  static copyWith({required Color primary, required Color onPrimary, required Color surface, required colorScheme, required Color dialogBackgroundColor}) {} // #757575
}
