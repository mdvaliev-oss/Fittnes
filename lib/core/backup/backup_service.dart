import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/nutrition/domain/entities/food_entry.dart';
import '../../features/nutrition/domain/entities/food_item.dart';
import '../../features/nutrition/presentation/providers/nutrition_providers.dart';
import '../../features/profile/domain/user_profile.dart';
import '../../features/profile/presentation/profile_providers.dart';
import '../../features/programs/domain/workout_program.dart';
import '../../features/programs/presentation/programs_providers.dart';
import '../../features/workout/domain/entities/workout_session.dart';
import '../../features/workout/presentation/providers/workout_providers.dart';
import '../settings/app_settings.dart';

/// Outcome of a data import.
class BackupImportResult {
  const BackupImportResult({required this.sessions, required this.programs});
  final int sessions;
  final int programs;
}

/// Thrown when a backup can't be imported (malformed JSON or a newer schema).
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Serializes the whole app state (profile, settings, custom programs and
/// workout history) to JSON and restores it. Enables data export / import.
class BackupService {
  BackupService(this._ref);
  final Ref _ref;

  // v2 added nutrition (food diary + custom foods).
  static const int schemaVersion = 2;

  Future<String> export() async {
    final history = await _ref.read(workoutRepositoryProvider).history();
    final nutrition = _ref.read(nutritionRepositoryProvider);
    final data = <String, dynamic>{
      'app': 'fittnes',
      'version': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': _ref.read(profileProvider).toJson(),
      'settings': _ref.read(appSettingsProvider).toJson(),
      'customPrograms':
          _ref.read(customProgramsProvider).map((p) => p.toJson()).toList(),
      'sessions': history.map((s) => s.toJson()).toList(),
      'customFoods':
          (await nutrition.customFoods()).map((f) => f.toJson()).toList(),
      'foodEntries':
          (await nutrition.allEntries()).map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<BackupImportResult> import(String raw) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException('Не удалось прочитать JSON бэкапа.');
    }

    // Reject a backup written by a newer schema than we understand, rather
    // than silently importing fields we can't interpret.
    final version = (data['version'] as num?)?.toInt();
    if (version != null && version > schemaVersion) {
      throw BackupException(
        'Бэкап новее версии приложения (v$version). Обновите приложение.',
      );
    }

    if (data['profile'] is Map) {
      await _ref.read(profileProvider.notifier).update(
            UserProfile.fromJson(data['profile'] as Map<String, dynamic>),
          );
    }
    if (data['settings'] is Map) {
      await _ref.read(appSettingsProvider.notifier).replace(
            AppSettings.fromJson(data['settings'] as Map<String, dynamic>),
          );
    }

    var programs = 0;
    for (final p in (data['customPrograms'] as List?) ?? const []) {
      await _ref
          .read(customProgramsProvider.notifier)
          .save(WorkoutProgram.fromJson(p as Map<String, dynamic>));
      programs++;
    }

    var sessions = 0;
    final repo = _ref.read(workoutRepositoryProvider);
    for (final s in (data['sessions'] as List?) ?? const []) {
      await repo.save(WorkoutSession.fromJson(s as Map<String, dynamic>));
      sessions++;
    }
    _ref.invalidate(workoutHistoryProvider);

    // Nutrition (v2+): custom foods then diary entries.
    final nutrition = _ref.read(nutritionRepositoryProvider);
    for (final f in (data['customFoods'] as List?) ?? const []) {
      // Force a fresh insert — the old row id won't exist in this database.
      final food =
          FoodItem.fromJson(f as Map<String, dynamic>).copyWith(id: '');
      await nutrition.saveCustomFood(food);
    }
    for (final e in (data['foodEntries'] as List?) ?? const []) {
      await nutrition.addEntry(FoodEntry.fromJson(e as Map<String, dynamic>));
    }
    _ref
      ..invalidate(customFoodsProvider)
      ..invalidate(dailyNutritionProvider)
      ..invalidate(todayNutritionProvider);

    return BackupImportResult(sessions: sessions, programs: programs);
  }
}

final backupServiceProvider = Provider<BackupService>(BackupService.new);
