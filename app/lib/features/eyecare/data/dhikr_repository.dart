import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart'
    show AssetBundle, AssetManifest, rootBundle;

import '../domain/dhikr.dart';

/// Provides the bundled adhkar set and rotates through it deterministically
/// (never random-repeat, so the user sees variety without surprise duplicates).
class DhikrRepository {
  DhikrRepository(List<Dhikr> all) : _all = List.unmodifiable(all);

  final List<Dhikr> _all;

  List<Dhikr> get all => _all;
  int get length => _all.length;
  bool get isEmpty => _all.isEmpty;

  /// Returns the dhikr at [rotationIndex], wrapping around the set so callers
  /// can simply increment a persisted counter each break.
  Dhikr at(int rotationIndex) {
    assert(_all.isNotEmpty, 'Dhikr set must not be empty');
    final i = rotationIndex % _all.length;
    return _all[i < 0 ? i + _all.length : i];
  }

  /// Parses a repository from the raw JSON string of `dhikr.json`.
  factory DhikrRepository.fromJsonString(String raw) {
    final json = jsonDecode(raw) as Map<String, Object?>;
    final list = (json['dhikr']! as List)
        .cast<Map<String, Object?>>()
        .map(Dhikr.fromJson)
        .toList();
    return DhikrRepository(list);
  }

  /// Loads from the bundled asset, then auto-resolves recitation clips so that
  /// dropping `assets/audio/recitation/<id>.<ext>` into the bundle makes that
  /// dhikr play it — zero JSON editing required. An explicit `audio` in
  /// `dhikr.json` always wins. If the asset manifest can't be read (e.g. an
  /// older bundle), loading degrades gracefully to the unresolved set.
  static Future<DhikrRepository> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final raw = await b.loadString('assets/dhikr/dhikr.json');
    final base = DhikrRepository.fromJsonString(raw);
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(b);
      return DhikrRepository(resolveAudio(base.all, manifest.listAssets()));
    } catch (e) {
      // Reverence + robustness: a missing/unreadable manifest must never block
      // the break. Fall back to whatever audio the JSON declared explicitly.
      debugPrint('DhikrRepository: recitation auto-resolve skipped ($e)');
      return base;
    }
  }

  /// Directory that owner-supplied recitation clips are dropped into.
  static const String recitationDir = 'assets/audio/recitation/';

  /// Recitation container extensions, in PREFERENCE order. OGG/Opus and M4A/AAC
  /// (small, broadly supported, well-suited to a short normalized phrase) are
  /// preferred over MP3/WAV. When several files exist for one id, the earliest
  /// match wins.
  static const List<String> recitationExtensions = [
    'ogg',
    'oga',
    'm4a',
    'aac',
    'mp3',
    'wav',
  ];

  /// Pure resolver (no I/O): for every dhikr whose `audio` is null, look for a
  /// dropped clip named `<id>.<ext>` under [recitationDir] among [assetKeys]
  /// (e.g. an [AssetManifest.listAssets] result) and assign the first match in
  /// [recitationExtensions] order. A dhikr that already declares `audio` is left
  /// untouched (explicit wins). Matching is exact on the full `<dir><id>.<ext>`
  /// path, so `la-hawla-extra.ogg` never matches `la-hawla`.
  static List<Dhikr> resolveAudio(
    List<Dhikr> dhikr,
    Iterable<String> assetKeys,
  ) {
    final available = assetKeys.toSet();
    return [
      for (final d in dhikr)
        if (d.audio != null)
          d
        else
          d.withAudio(_recitationFor(d.id, available)),
    ];
  }

  static String? _recitationFor(String id, Set<String> available) {
    for (final ext in recitationExtensions) {
      final candidate = '$recitationDir$id.$ext';
      if (available.contains(candidate)) return candidate;
    }
    return null;
  }
}
