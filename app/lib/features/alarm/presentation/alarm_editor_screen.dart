import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/audio/audio_providers.dart';
import '../../../core/audio/sound_catalog.dart';
import '../../../core/audio/sound_spec.dart';
import '../../../core/audio/tarf_audio_service.dart';
import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/tarf_wheel_picker.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/alarms_controller.dart';
import '../domain/alarm_item.dart';

/// Full-screen alarm editor (design.md §8.13): a wheel time picker + grouped
/// Repeat / Sound / Label / Ring-duration / Snooze rows + Delete. Pushed for a
/// new alarm (`existing == null`) or to edit one. Calm Sanctuary brand.
class AlarmEditorScreen extends ConsumerStatefulWidget {
  const AlarmEditorScreen({super.key, this.existing});

  final AlarmItem? existing;

  @override
  ConsumerState<AlarmEditorScreen> createState() => _AlarmEditorScreenState();
}

class _AlarmEditorScreenState extends ConsumerState<AlarmEditorScreen> {
  late int _hour; // 0..23
  late int _minute;
  late String _label;
  late Set<int> _days;
  late String _sound;
  late int _ringSec;
  late int _snoozeMin;

  static const _soundIds = ['default', 'bell', 'chime', 'calm'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = TimeOfDay.now();
    _hour = e?.hour ?? now.hour;
    _minute = e?.minute ?? now.minute;
    _label = e?.label ?? '';
    _days = {...?e?.days};
    _sound = e?.sound ?? 'default';
    _ringSec = e?.ringDurationSeconds ?? 60;
    _snoozeMin = e?.snoozeMinutes ?? 5;
  }

  void _save() {
    final id =
        widget.existing?.id ?? 'a${DateTime.now().millisecondsSinceEpoch}';
    final item = AlarmItem(
      id: id,
      hour: _hour,
      minute: _minute,
      label: _label.trim(),
      enabled: widget.existing?.enabled ?? true,
      days: _days,
      sound: _sound,
      ringDurationSeconds: _ringSec,
      snoozeMinutes: _snoozeMin,
    );
    ref.read(alarmsControllerProvider.notifier).upsert(item);
    if (context.canPop()) context.pop();
  }

  // ---- value labels ----
  String _repeatLabel(AppLocalizations l10n) {
    if (_days.isEmpty) return l10n.alarmRepeatOnce;
    if (_days.length == 7) return l10n.alarmRepeatDaily;
    final sorted = _days.toList()..sort();
    if (_listEq(sorted, const [1, 2, 3, 4, 5])) return l10n.alarmRepeatWeekdays;
    if (_listEq(sorted, const [6, 7])) return l10n.alarmRepeatWeekends;
    return l10n.alarmRepeatCustom;
  }

  String _soundLabel(AppLocalizations l10n) => switch (_sound) {
        'bell' => l10n.soundBell,
        'chime' => l10n.soundChime,
        'calm' => l10n.soundCalm,
        _ => l10n.soundDefault,
      };

  String _durLabel(int sec, AppLocalizations l10n) =>
      sec < 60 ? l10n.secondsShort(sec) : l10n.minutesShort(sec ~/ 60);

  // ---- pickers ----
  Future<void> _editDays() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final temp = {..._days};
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TarfTokens.space4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.alarmRepeat,
                    style: Theme.of(sheetCtx).textTheme.titleLarge),
                const SizedBox(height: TarfTokens.space3),
                Wrap(
                  spacing: TarfTokens.space2,
                  runSpacing: TarfTokens.space2,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var w = 1; w <= 7; w++)
                      FilterChip(
                        label: Text(_weekdayLabel(w, locale)),
                        selected: temp.contains(w),
                        onSelected: (on) => setSheet(
                            () => on ? temp.add(w) : temp.remove(w)),
                      ),
                  ],
                ),
                const SizedBox(height: TarfTokens.space3),
                FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                  child: Text(l10n.actionDone),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    setState(() => _days = temp);
  }

  Future<void> _editSound() async {
    final l10n = AppLocalizations.of(context);
    final audio = ref.read(tarfAudioServiceProvider);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) {
        final scheme = Theme.of(sheetCtx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final id in _soundIds)
                ListTile(
                  title: Text(switch (id) {
                    'bell' => l10n.soundBell,
                    'chime' => l10n.soundChime,
                    'calm' => l10n.soundCalm,
                    _ => l10n.soundDefault,
                  }),
                  // Check (when selected) + a preview button that plays the
                  // chosen catalog sound once on the dedicated preview channel
                  // without dismissing the sheet — proving the picker drives
                  // playback.
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (id == _sound)
                        Icon(Icons.check, color: scheme.primary),
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        tooltip: l10n.soundPreview,
                        onPressed: () {
                          final base = SoundCatalog.byId(id);
                          audio.play(
                            SoundSpec.synth(base.id,
                                role: SoundRole.alarm,
                                layers: base.layers,
                                defaultDuration: base.defaultDuration,
                                gain: base.gain),
                            channel: AudioChannel.preview,
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() => _sound = id);
                    Navigator.of(sheetCtx).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editLabel() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: _label);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.alarmLabelHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(MaterialLocalizations.of(dialogCtx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(controller.text),
            child: Text(MaterialLocalizations.of(dialogCtx).okButtonLabel),
          ),
        ],
      ),
    );
    if (result != null) setState(() => _label = result);
  }

  Future<void> _pickPreset({
    required String title,
    required List<int> values,
    required int current,
    required String Function(int) label,
    required ValueChanged<int> onPick,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TarfTokens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(sheetCtx).textTheme.titleLarge),
              const SizedBox(height: TarfTokens.space3),
              Wrap(
                spacing: TarfTokens.space2,
                runSpacing: TarfTokens.space2,
                alignment: WrapAlignment.center,
                children: [
                  for (final v in values)
                    TarfPresetChip(
                      label: label(v),
                      selected: v == current,
                      onTap: () {
                        onPick(v);
                        Navigator.of(sheetCtx).pop();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final n =
        ref.watch(settingsControllerProvider.select((s) => s.effectiveNumerals));
    final use24 = MediaQuery.of(context).alwaysUse24HourFormat;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
          onPressed: () => context.pop(),
        ),
        title: Text(widget.existing == null ? l10n.newAlarm : l10n.editAlarm),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.actionDone,
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(TarfTokens.space3),
        children: [
          const SizedBox(height: TarfTokens.space2),
          _buildWheel(n, use24),
          const SizedBox(height: TarfTokens.space5),
          TarfGroup(children: [
            TarfListRow(
              icon: Icons.repeat,
              title: l10n.alarmRepeat,
              trailing: _value(_repeatLabel(l10n)),
              onTap: _editDays,
            ),
            TarfListRow(
              icon: Icons.music_note_outlined,
              title: l10n.soundLabel,
              trailing: _value(_soundLabel(l10n)),
              onTap: _editSound,
            ),
            TarfListRow(
              icon: Icons.label_outline,
              title: l10n.alarmLabel,
              trailing: _value(_label.isEmpty ? '—' : _label),
              onTap: _editLabel,
            ),
            TarfListRow(
              icon: Icons.notifications_active_outlined,
              title: l10n.alarmRingDuration,
              trailing: _value(_durLabel(_ringSec, l10n)),
              onTap: () => _pickPreset(
                title: l10n.alarmRingDuration,
                values: const [30, 60, 120, 300],
                current: _ringSec,
                label: (v) => _durLabel(v, l10n),
                onPick: (v) => setState(() => _ringSec = v),
              ),
            ),
            TarfListRow(
              icon: Icons.snooze_outlined,
              title: l10n.alarmSnoozeDuration,
              trailing: _value(l10n.minutesShort(_snoozeMin)),
              onTap: () => _pickPreset(
                title: l10n.alarmSnoozeDuration,
                values: const [5, 10, 15],
                current: _snoozeMin,
                label: (v) => l10n.minutesShort(v),
                onPick: (v) => setState(() => _snoozeMin = v),
              ),
            ),
          ]),
          if (widget.existing != null) ...[
            const SizedBox(height: TarfTokens.space5),
            FilledButton(
              onPressed: () {
                ref
                    .read(alarmsControllerProvider.notifier)
                    .remove(widget.existing!.id);
                if (context.canPop()) context.pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: scheme.errorContainer,
                foregroundColor: scheme.onErrorContainer,
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(l10n.actionDelete),
            ),
          ],
        ],
      ),
    );
  }

  Widget _value(String s) {
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            s,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 4),
        Icon(rtl ? Icons.chevron_left : Icons.chevron_right,
            size: 20, color: scheme.onSurfaceVariant),
      ],
    );
  }

  Widget _buildWheel(NumeralSystem n, bool use24) {
    if (use24) {
      return TarfWheelPicker(columns: [
        TarfWheelColumn(
          values: [for (var h = 0; h < 24; h++) Numerals.padded(h, n)],
          selected: _hour,
          onSelected: (i) => setState(() => _hour = i),
          separator: ':',
        ),
        TarfWheelColumn(
          values: [for (var m = 0; m < 60; m++) Numerals.padded(m, n)],
          selected: _minute,
          onSelected: (i) => setState(() => _minute = i),
        ),
      ]);
    }
    final displayHours = [12, for (var h = 1; h < 12; h++) h]; // 12,1..11
    final isPm = _hour >= 12;
    final dh = _hour % 12 == 0 ? 12 : _hour % 12;
    final hourIndex = displayHours.indexOf(dh);
    return TarfWheelPicker(columns: [
      TarfWheelColumn(
        values: [for (final h in displayHours) Numerals.padded(h, n)],
        selected: hourIndex < 0 ? 0 : hourIndex,
        onSelected: (i) => setState(() => _hour = _to24(displayHours[i], isPm)),
        separator: ':',
      ),
      TarfWheelColumn(
        values: [for (var m = 0; m < 60; m++) Numerals.padded(m, n)],
        selected: _minute,
        onSelected: (i) => setState(() => _minute = i),
      ),
      TarfWheelColumn(
        values: const ['AM', 'PM'],
        selected: isPm ? 1 : 0,
        onSelected: (i) => setState(() => _hour = _to24(dh, i == 1)),
      ),
    ]);
  }

  int _to24(int displayHour, bool pm) {
    final h12 = displayHour % 12; // 12 -> 0
    return pm ? h12 + 12 : h12;
  }
}

bool _listEq(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String _weekdayLabel(int weekday, String locale) {
  // 2024-01-01 is a Monday; weekday 1=Mon .. 7=Sun.
  final d = DateTime(2024, 1, 1).add(Duration(days: weekday - 1));
  return DateFormat.E(locale).format(d);
}
