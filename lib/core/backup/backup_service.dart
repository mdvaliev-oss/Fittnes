import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  static const int schemaVersion = 1;

  Future<String> export() async {
    final history = await _ref.read(workoutRepositoryProvider).history();
    final data = <String, dynamic>{
      'app': 'fittnes',
      'version': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': _ref.read(profileProvider).toJson(),
      'settings': _ref.read(appSettingsProvider).toJson(),
      'customPrograms':
          _ref.read(customProgramsProvider).map((p) => p.toJson()).toList(),
      'sessions': history.map((s) => s.toJson()).toList(),
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

    return BackupImportResult(sessions: sessions, programs: programs);
  }
}

final backupServiceProvider = Provider<BackupService>(BackupService.new);
