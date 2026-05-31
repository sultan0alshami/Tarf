import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

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

  /// Loads from the bundled asset.
  static Future<DhikrRepository> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final raw = await b.loadString('assets/dhikr/dhikr.json');
    return DhikrRepository.fromJsonString(raw);
  }
}
