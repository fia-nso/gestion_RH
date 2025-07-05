// screens/shared/widgets/bottom_navigation.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.label,
  });
}

class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final List<BottomNavItem> items;
  final ValueChanged<int> onTap;

  const CustomBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          tabs: items
              .map((item) => GButton(
                    icon: item.icon,
                    text: item.label,
                    semanticLabel: item.label,
                  ))
              .toList(),
          selectedIndex: selectedIndex,
          onTabChange: onTap,
        ),
      ),
    );
  }
}