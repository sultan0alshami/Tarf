import 'package:flutter/foundation.dart';

/// A single remembrance shown on the break screen. Treated as immutable,
/// fully-vocalized sacred content.
@immutable
class Dhikr {
  const Dhikr({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.english,
    required this.reference,
    this.virtue,
    this.audio,
  });

  final String id;

  /// Fully-vocalized Arabic. Never altered or truncated.
  final String arabic;
  final String transliteration;
  final String english;

  /// Exact source reference (e.g. "Sahih Muslim 2691").
  final String reference;

  /// Short note on the virtue/reward (optional, shown on "tell me more").
  final String? virtue;

  /// Bundled recitation asset path, or null to fall back to TTS.
  final String? audio;

  /// Returns a copy with [audio] replaced. Only the recitation pointer is ever
  /// rewritten (by the asset-manifest drop-in resolver); the sacred text fields
  /// are never altered, so no other field is exposed here.
  Dhikr withAudio(String? audio) => Dhikr(
        id: id,
        arabic: arabic,
        transliteration: transliteration,
        english: english,
        reference: reference,
        virtue: virtue,
        audio: audio,
      );

  factory Dhikr.fromJson(Map<String, Object?> json) => Dhikr(
        id: json['id']! as String,
        arabic: json['arabic']! as String,
        transliteration: json['transliteration']! as String,
        english: json['english']! as String,
        reference: json['reference']! as String,
        virtue: json['virtue'] as String?,
        audio: json['audio'] as String?,
      );
}
