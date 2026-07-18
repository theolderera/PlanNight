import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';

/// The signed-in app shell: an IndexedStack of the five main tabs with a
/// Material 3 NavigationBar. Each tab keeps its own navigation state.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Built per-build rather than held in a `static const`: the labels are
  /// translated, so they change with the locale.
  List<({IconData icon, IconData selected, String label})> _destinations(
    AppLocalizations l10n,
  ) =>
      [
        (icon: Icons.today_outlined, selected: Icons.today, label: l10n.navToday),
        (icon: Icons.event_note_outlined, selected: Icons.event_note, label: l10n.navPlan),
        (icon: Icons.insights_outlined, selected: Icons.insights, label: l10n.navStats),
        (icon: Icons.calendar_month_outlined, selected: Icons.calendar_month, label: l10n.navHistory),
        (icon: Icons.settings_outlined, selected: Icons.settings, label: l10n.navSettings),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the active tab again pops it to its root.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final d in _destinations(context.l10n))
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
