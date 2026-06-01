import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/format/numerals.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../eyecare/application/eyecare_config_controller.dart';
import '../application/alarm_derived.dart';
import '../application/alarms_controller.dart';
import '../domain/alarm_item.dart';

enum AlarmMode { standard, prayer }

/// Alarms — a Standard/Prayer segmented surface with a live "Ring in…" readout.
/// Standard alarms are user-created (tap a row or "+" to open the full editor);
/// Prayer rows are computed daily and toggled on/off. Tab branch (no back).
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  // Default mode; `--dart-define=FORCE_PRAYER=true` opens on Prayer (screenshots).
  AlarmMode _mode = const bool.fromEnvironment('FORCE_PRAYER')
      ? AlarmMode.prayer
      : AlarmMode.standard;

  void _openEditor([AlarmItem? item]) =>
      context.push(Routes.alarmEditor, extra: item);

  void _togglePrayer(String id, bool on) {
    final cfg = ref.read(eyeCareConfigProvider);
    final next = {...cfg.prayerAlarmsEnabled};
    if (on) {
      next.add(id);
    } else {
      next.remove(id);
    }
    ref
        .read(eyeCareConfigProvider.notifier)
        .update(cfg.copyWith(prayerAlarmsEnabled: next));
  }

  String _prayerName(AppLocalizations l10n, String id) => switch (id) {
        'fajr' => l10n.prayerFajr,
        'dhuhr' => l10n.prayerDhuhr,
        'asr' => l10n.prayerAsr,
        'maghrib' => l10n.prayerMaghrib,
        _ => l10n.prayerIsha,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final nextIn = ref.watch(nextAlarmProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alarms),
        actions: [
          if (_mode == AlarmMode.standard)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.addAlarm,
              onPressed: () => _openEditor(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(TarfTokens.space3),
        children: [
          if (nextIn != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: TarfTokens.space2,
                bottom: TarfTokens.space3,
              ),
              child: Text(
                l10n.ringInHm(nextIn.inHours, nextIn.inMinutes % 60),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          Center(
            child: SegmentedButton<AlarmMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: AlarmMode.standard, label: Text(l10n.alarmStandard)),
                ButtonSegment(
                    value: AlarmMode.prayer, label: Text(l10n.alarmPrayer)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
          const SizedBox(height: TarfTokens.space4),
          if (_mode == AlarmMode.standard)
            ..._standard(l10n)
          else
            ..._prayer(l10n),
        ],
      ),
    );
  }

  List<Widget> _standard(AppLocalizations l10n) {
    final alarms = ref.watch(alarmsControllerProvider);
    if (alarms.isEmpty) {
      return [
        const SizedBox(height: TarfTokens.space6),
        TarfEmptyState(
          icon: Icons.alarm,
          message: l10n.noAlarms,
          actionLabel: l10n.addAlarm,
          onAction: () => _openEditor(),
        ),
      ];
    }
    final scheme = Theme.of(context).colorScheme;
    return [
      for (final a in alarms)
        Padding(
          padding: const EdgeInsets.only(bottom: TarfTokens.space2),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Dismissible(
              key: ValueKey(a.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: scheme.errorContainer,
                alignment: AlignmentDirectional.centerEnd,
                padding: const EdgeInsetsDirectional.only(end: TarfTokens.space4),
                child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
              ),
              onDismissed: (_) {
                ref.read(alarmsControllerProvider.notifier).remove(a.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.alarmDeleted)),
                );
              },
              child: InkWell(
                onTap: () => _openEditor(a),
                child: _AlarmRow(item: a),
              ),
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: TarfTokens.space4),
        child: Text(
          l10n.alarmNativeNote,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: context.tarf.warningText),
        ),
      ),
    ];
  }

  List<Widget> _prayer(AppLocalizations l10n) {
    final prayers = ref.watch(prayerAlarmsProvider);
    final n = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );
    final scheme = Theme.of(context).colorScheme;
    // Localized month name, but Western digits for day/year (Tarf's numerals
    // rule) — DateFormat would render Arabic-Indic digits for the `ar` locale.
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final date = '${Numerals.padded(now.day, n, width: 1)} '
        '${DateFormat.MMMM(locale).format(now)} '
        '${Numerals.padded(now.year, n, width: 1)}';

    return [
      Padding(
        padding: const EdgeInsetsDirectional.only(
          start: TarfTokens.space2,
          bottom: TarfTokens.space2,
        ),
        child: Text(
          l10n.prayerTimesForDate(date),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: context.tarf.textTertiary),
        ),
      ),
      TarfGroup(
        children: [
          for (final p in prayers)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: TarfTokens.space3,
                vertical: TarfTokens.space2,
              ),
              child: Row(
                children: [
                  Icon(Icons.brightness_3,
                      size: 20, color: scheme.primary),
                  const SizedBox(width: TarfTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TarfTimeText(
                          '${Numerals.padded(p.time.hour, n)}:'
                          '${Numerals.padded(p.time.minute, n)}',
                          style: Theme.of(context).textTheme.headlineSmall,
                          color: p.enabled
                              ? scheme.onSurface
                              : context.tarf.textTertiary,
                        ),
                        Text(
                          _prayerName(l10n, p.id),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: p.enabled,
                    onChanged: (on) => _togglePrayer(p.id, on),
                  ),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: TarfTokens.space3),
      TarfGroup(
        children: [
          TarfListRow(
            icon: Icons.place_outlined,
            title: l10n.locationAndMethod,
            trailing: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: scheme.onSurfaceVariant,
            ),
            onTap: () => context.push(Routes.eyeCareSettings),
          ),
        ],
      ),
    ];
  }
}

/// A single standard-alarm row: big tabular time, label/repeat, enable toggle.
class _AlarmRow extends ConsumerWidget {
  const _AlarmRow({required this.item});

  final AlarmItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final n = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );

    final timeText =
        '${Numerals.padded(item.hour, n)}:${Numerals.padded(item.minute, n)}';
    final repeat = _repeatLabel(item.days, l10n);
    final hasLabel = item.label.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(TarfTokens.space3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TarfTimeText(
                  timeText,
                  style: textTheme.headlineMedium,
                  color: item.enabled
                      ? scheme.onSurface
                      : context.tarf.textTertiary,
                ),
                const SizedBox(height: 2),
                Text(
                  hasLabel ? item.label : repeat,
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (hasLabel)
                  Text(
                    repeat,
                    style: textTheme.bodySmall
                        ?.copyWith(color: context.tarf.textTertiary),
                  ),
              ],
            ),
          ),
          Switch(
            value: item.enabled,
            onChanged: (_) =>
                ref.read(alarmsControllerProvider.notifier).toggle(item.id),
          ),
        ],
      ),
    );
  }

  String _repeatLabel(Set<int> days, AppLocalizations l10n) {
    if (days.isEmpty) return l10n.alarmRepeatOnce;
    if (days.length == 7) return l10n.alarmRepeatDaily;
    final sorted = days.toList()..sort();
    if (_listEquals(sorted, const [1, 2, 3, 4, 5])) {
      return l10n.alarmRepeatWeekdays;
    }
    if (_listEquals(sorted, const [6, 7])) {
      return l10n.alarmRepeatWeekends;
    }
    return l10n.alarmRepeatCustom;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
