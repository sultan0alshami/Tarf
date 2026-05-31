import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';

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
  final String Function(AppLocalizations l10n) label;
}

final tarfDestinations = <TarfDestination>[
  TarfDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: (l) => l.tabHome,
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

/// Responsive shell: a floating glass capsule tab bar below 600px; a navigation
/// rail at/above 600px. Same destinations, order, and labels everywhere.
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.navigationShell, this.accessory});

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
                          // Bound the width so the shelf uses its compact form in
                          // the rail (the full strip needs a finite width).
                          child: SizedBox(width: 72, child: accessory),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?accessory,
              _CapsuleNavBar(
                selectedIndex: navigationShell.currentIndex,
                onSelect: _onSelect,
                l10n: l10n,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapsuleNavBar extends StatelessWidget {
  const _CapsuleNavBar({
    required this.selectedIndex,
    required this.onSelect,
    required this.l10n,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(TarfTokens.radiusL),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(TarfTokens.radiusL),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
          ),
          child: NavigationBar(
            height: 64,
            backgroundColor: Colors.transparent,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelect,
            destinations: [
              for (final d in tarfDestinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label(l10n),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
