import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// A single destination shown identically across mobile (bottom bar) and
/// desktop/web/tablet (navigation rail).
class TarfDestination {
  const TarfDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;

  /// Resolves the localized label.
  final String Function(AppLocalizations l10n) label;
}

final tarfDestinations = <TarfDestination>[
  TarfDestination(
    icon: Icons.center_focus_weak_outlined,
    selectedIcon: Icons.center_focus_strong,
    label: (l) => l.tabFocus,
  ),
  TarfDestination(
    icon: Icons.timer_outlined,
    selectedIcon: Icons.timer,
    label: (l) => l.tabTimer,
  ),
  TarfDestination(
    icon: Icons.alarm_outlined,
    selectedIcon: Icons.alarm,
    label: (l) => l.tabAlarm,
  ),
  TarfDestination(
    icon: Icons.av_timer_outlined,
    selectedIcon: Icons.av_timer,
    label: (l) => l.tabStopwatch,
  ),
];

/// Responsive shell. Bottom navigation bar below 600px; navigation rail at or
/// above 600px. The same destinations, order, and labels everywhere.
///
/// [accessory] is the persistent active-session slot (timer/focus/break) shown
/// above the bottom bar on mobile and at the rail footer on wide layouts.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.navigationShell,
    this.accessory,
  });

  final StatefulNavigationShell navigationShell;
  final Widget? accessory;

  void _onSelect(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 600;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onSelect,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in tarfDestinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label(l10n)),
                  ),
              ],
              trailing: accessory == null
                  ? null
                  : Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: accessory,
                        ),
                      ),
                    ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?accessory,
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onSelect,
            destinations: [
              for (final d in tarfDestinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label(l10n),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
