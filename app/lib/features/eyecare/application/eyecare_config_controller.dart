import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/data/tarf_repository.dart';
import '../domain/eyecare_config.dart';

/// Holds the persisted [EyeCareConfig].
class EyeCareConfigController extends Notifier<EyeCareConfig> {
  @override
  EyeCareConfig build() {
    final raw = ref.watch(tarfRepositoryProvider).read(StorageKey.eyecareConfig);
    if (raw is! Map) return const EyeCareConfig();
    try {
      return EyeCareConfig.fromJson(raw.cast<String, Object?>());
    } catch (_) {
      return const EyeCareConfig();
    }
  }

  Future<void> update(EyeCareConfig config) async {
    state = config;
    await ref.read(tarfRepositoryProvider).write(StorageKey.eyecareConfig, config.toJson());
  }
}

final eyeCareConfigProvider =
    NotifierProvider<EyeCareConfigController, EyeCareConfig>(
  EyeCareConfigController.new,
);
