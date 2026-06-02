import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/numerals.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/tarf_wheel_picker.dart';
import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../application/saved_timers_controller.dart';
import '../domain/saved_timer.dart';
import '../domain/timer_sound_catalog.dart';

const _presetMinutes = [1, 5, 10, 20, 30, 40];

/// Create/edit a saved timer. Reuses the calm wheel picker (HH·MM·SS) + the
/// preset grid for duration, a labeled row, and a sound bottom-sheet.
class SavedTimerEditorScreen extends ConsumerStatefulWidget {
  const SavedTimerEditorScreen({super.key, this.existing});
  final SavedTimer? existing;
  @override
  ConsumerState<SavedTimerEditorScreen> createState() =>
      _SavedTimerEditorScreenState();
}

class _SavedTimerEditorScreenState
    extends ConsumerState<SavedTimerEditorScreen> {
  late int _h, _m, _s;
  late String _label;
  late String _sound;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final d = e?.duration ?? const Duration(minutes: 5);
    _h = d.inHours.clamp(0, 23);
    _m = d.inMinutes % 60;
    _s = d.inSeconds % 60;
    _label = e?.label ?? '';
    _sound = e?.soundId ?? kDefaultTimerSoundId;
  }

  Duration get _duration => Duration(hours: _h, minutes: _m, seconds: _s);

  // Navigator.maybePop works whether pushed by go_router or a bare Navigator
  // (and is a no-op in a router-less test host).
  void _close() => Navigator.of(context).maybePop();

  void _save() {
    if (_duration <= Duration.zero) return;
    final id =
        widget.existing?.id ?? 't${DateTime.now().millisecondsSinceEpoch}';
    ref.read(savedTimersControllerProvider.notifier).upsert(
          SavedTimer(
            id: id,
            label: _label.trim(),
            duration: _duration,
            soundId: _sound,
          ),
        );
    _close();
  }

  String _soundLabel(AppLocalizations l, String id) =>
      switch (timerSoundL10nKey(id)) {
        'soundBell' => l.soundBell,
        'soundChime' => l.soundChime,
        'soundCalm' => l.soundCalm,
        _ => l.soundDefault,
      };

  Future<void> _editLabel() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: _label);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.timerLabelHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
    if (result != null) setState(() => _label = result);
  }

  Future<void> _editSound() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final id in timerSoundIds)
                ListTile(
                  title: Text(_soundLabel(l10n, id)),
                  trailing: id == _sound
                      ? Icon(Icons.check, color: scheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _sound = id);
                    Navigator.of(ctx).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final n = ref.watch(
      settingsControllerProvider.select((s) => s.effectiveNumerals),
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _close,
        ),
        title: Text(
            widget.existing == null ? l10n.timerAddSaved : l10n.timerEditSaved),
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
          TarfWheelPicker(columns: [
            TarfWheelColumn(
              values: [for (var x = 0; x < 24; x++) Numerals.padded(x, n)],
              selected: _h,
              onSelected: (i) => setState(() => _h = i),
              separator: ':',
            ),
            TarfWheelColumn(
              values: [for (var x = 0; x < 60; x++) Numerals.padded(x, n)],
              selected: _m,
              onSelected: (i) => setState(() => _m = i),
              separator: ':',
            ),
            TarfWheelColumn(
              values: [for (var x = 0; x < 60; x++) Numerals.padded(x, n)],
              selected: _s,
              onSelected: (i) => setState(() => _s = i),
            ),
          ]),
          const SizedBox(height: TarfTokens.space4),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: TarfTokens.space3,
            crossAxisSpacing: TarfTokens.space3,
            childAspectRatio: 2.4,
            children: [
              for (final x in _presetMinutes)
                TarfPresetChip(
                  label: Numerals.timer(Duration(minutes: x), n),
                  selected: _duration == Duration(minutes: x),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _h = 0;
                      _m = x;
                      _s = 0;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: TarfTokens.space4),
          TarfGroup(children: [
            TarfListRow(
              icon: Icons.label_outline,
              title: l10n.timerLabel,
              trailing: _trailing(_label.isEmpty ? '—' : _label, scheme),
              onTap: _editLabel,
            ),
            TarfListRow(
              icon: Icons.music_note_outlined,
              title: l10n.soundLabel,
              trailing: _trailing(_soundLabel(l10n, _sound), scheme),
              onTap: _editSound,
            ),
          ]),
          if (widget.existing != null) ...[
            const SizedBox(height: TarfTokens.space4),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.errorContainer,
                foregroundColor: scheme.onErrorContainer,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () {
                ref
                    .read(savedTimersControllerProvider.notifier)
                    .remove(widget.existing!.id);
                _close();
              },
              child: Text(l10n.actionDelete),
            ),
          ],
        ],
      ),
    );
  }

  Widget _trailing(String s, ColorScheme scheme) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(
        child: Text(s,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ),
      const SizedBox(width: 4),
      Icon(rtl ? Icons.chevron_left : Icons.chevron_right,
          size: 20, color: scheme.onSurfaceVariant),
    ]);
  }
}
