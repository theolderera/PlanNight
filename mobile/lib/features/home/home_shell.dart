import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';

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
        (icon: Icons.today_outlined, selected: Icons.today_rounded, label: l10n.navToday),
        (icon: Icons.event_note_outlined, selected: Icons.event_note_rounded, label: l10n.navPlan),
        (icon: Icons.bar_chart_outlined, selected: Icons.bar_chart_rounded, label: l10n.navStats),
        (icon: Icons.history_outlined, selected: Icons.history_rounded, label: l10n.navHistory),
        (icon: Icons.settings_outlined, selected: Icons.settings_rounded, label: l10n.navSettings),
      ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.paper,
          border: Border(top: BorderSide(color: c.divider)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
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
        ),
      ),
    );
  }
}
