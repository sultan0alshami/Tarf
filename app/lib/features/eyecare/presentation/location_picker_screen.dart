import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/tarf_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../prayer/application/geo_locator.dart';
import '../../prayer/domain/prayer_calc_options.dart';
import '../application/eyecare_config_controller.dart';
import '../domain/eyecare_config.dart';

/// Calm prayer-time location/method picker. Manual-first: lat/lng/city are
/// always editable; device geolocation is an optional convenience that falls
/// back honestly to manual entry. Persists into EyeCareConfig, so the Prayer
/// screen's computed times update immediately (prayerAlarmsProvider watches it).
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});
  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  late TextEditingController _city;
  late TextEditingController _lat;
  late TextEditingController _lng;
  String? _geoNote; // localized fallback note, or null

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(eyeCareConfigProvider);
    _city = TextEditingController(text: cfg.prayerCityLabel);
    _lat = TextEditingController(text: cfg.prayerLatitude.toString());
    _lng = TextEditingController(text: cfg.prayerLongitude.toString());
  }

  @override
  void dispose() {
    _city.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  EyeCareConfig get _cfg => ref.read(eyeCareConfigProvider);
  void _update(EyeCareConfig next) =>
      ref.read(eyeCareConfigProvider.notifier).update(next);

  void _commitText() {
    final lat = double.tryParse(_lat.text) ?? _cfg.prayerLatitude;
    final lng = double.tryParse(_lng.text) ?? _cfg.prayerLongitude;
    _update(_cfg.copyWith(
      prayerCityLabel: _city.text.trim(),
      prayerLatitude: lat,
      prayerLongitude: lng,
    ));
  }

  Future<void> _useMyLocation() async {
    final l10n = AppLocalizations.of(context);
    final geo = ref.read(geoLocatorProvider);
    final fix = await geo.currentLatLng();
    if (!mounted) return;
    if (fix == null) {
      setState(() => _geoNote = l10n.locationDenied);
      return;
    }
    setState(() {
      _lat.text = fix.latitude.toString();
      _lng.text = fix.longitude.toString();
      _geoNote = null;
    });
    _commitText();
  }

  Future<void> _pickOption({
    required String title,
    required List<PrayerOption> options,
    required String current,
    required ValueChanged<String> onPick,
  }) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) {
        final scheme = Theme.of(sheetCtx).colorScheme;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(TarfTokens.space4),
                child:
                    Text(title, style: Theme.of(sheetCtx).textTheme.titleLarge),
              ),
              for (final o in options)
                ListTile(
                  title: Text(_label(l10n, o.l10nKey)),
                  trailing: o.id == current
                      ? Icon(Icons.check, color: scheme.primary)
                      : null,
                  onTap: () {
                    onPick(o.id);
                    Navigator.of(sheetCtx).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Maps an l10n key string to its localized value. Centralized so the option
  // catalogs stay pure (no Flutter import).
  String _label(AppLocalizations l, String key) => switch (key) {
        'prayerMethodUmmAlQura' => l.prayerMethodUmmAlQura,
        'prayerMethodMwl' => l.prayerMethodMwl,
        'prayerMethodEgyptian' => l.prayerMethodEgyptian,
        'prayerMethodKarachi' => l.prayerMethodKarachi,
        'prayerMethodDubai' => l.prayerMethodDubai,
        'prayerMethodQatar' => l.prayerMethodQatar,
        'prayerMethodKuwait' => l.prayerMethodKuwait,
        'prayerMethodNorthAmerica' => l.prayerMethodNorthAmerica,
        'prayerMethodTurkey' => l.prayerMethodTurkey,
        'madhabShafi' => l.madhabShafi,
        _ => l.madhabHanafi,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cfg = ref.watch(eyeCareConfigProvider);
    final geo = ref.watch(geoLocatorProvider);
    final methodKey = kPrayerMethods
        .firstWhere((m) => m.id == cfg.prayerMethod,
            orElse: () => kPrayerMethods.first)
        .l10nKey;
    final madhabKey = kMadhabs
        .firstWhere((m) => m.id == cfg.prayerMadhab,
            orElse: () => kMadhabs.first)
        .l10nKey;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.locationPickerTitle)),
      body: ListView(
        padding: const EdgeInsets.all(TarfTokens.space3),
        children: [
          TarfSectionHeader(l10n.prayerLocationGroup),
          TarfGroup(children: [
            _fieldRow(l10n.prayerCityLabelField, _city,
                hint: l10n.prayerCityHint),
            _fieldRow(l10n.prayerLatitude, _lat, numeric: true),
            _fieldRow(l10n.prayerLongitude, _lng, numeric: true),
          ]),
          if (geo.isSupported) ...[
            const SizedBox(height: TarfTokens.space3),
            OutlinedButton.icon(
              icon: const Icon(Icons.my_location),
              label: Text(l10n.useMyLocation),
              onPressed: _useMyLocation,
            ),
          ],
          if (_geoNote != null)
            Padding(
              padding: const EdgeInsets.only(top: TarfTokens.space2),
              child: Text(_geoNote!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: context.tarf.warningText)),
            ),
          const SizedBox(height: TarfTokens.space2),
          // Method/madhab rows carry their group name as the title (no duplicate
          // section header) and show the current selection as the subtitle.
          TarfGroup(children: [
            TarfListRow(
              icon: Icons.public,
              title: l10n.prayerMethodGroup,
              subtitle: _label(l10n, methodKey),
              onTap: () => _pickOption(
                title: l10n.prayerMethodGroup,
                options: kPrayerMethods,
                current: cfg.prayerMethod,
                onPick: (id) => _update(cfg.copyWith(prayerMethod: id)),
              ),
            ),
            TarfListRow(
              icon: Icons.schedule,
              title: l10n.prayerMadhabGroup,
              subtitle: _label(l10n, madhabKey),
              onTap: () => _pickOption(
                title: l10n.prayerMadhabGroup,
                options: kMadhabs,
                current: cfg.prayerMadhab,
                onPick: (id) => _update(cfg.copyWith(prayerMadhab: id)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _fieldRow(String label, TextEditingController c,
      {bool numeric = false, String? hint}) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: TarfTokens.space3,
        vertical: TarfTokens.space2,
      ),
      child: TextField(
        controller: c,
        // A coordinate is a number, not a clock face: keep it LTR even in RTL.
        textDirection: numeric ? TextDirection.ltr : null,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(signed: true, decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label, hintText: hint),
        onChanged: (_) => _commitText(),
      ),
    );
  }
}
