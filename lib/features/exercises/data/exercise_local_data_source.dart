import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../domain/entities/exercise.dart';
import 'models/exercise_dto.dart';

/// Loads the exercise catalog from a bundled JSON asset.
///
/// The seed ships a curated subset; the full free-exercise-db import replaces
/// this asset without any code change (the DTO already matches its schema).
class ExerciseLocalDataSource {
  ExerciseLocalDataSource({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const String _assetPath = 'assets/exercises/exercises_seed.json';

  Future<List<Exercise>> loadAll() async {
    final raw = await _bundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => ExerciseDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
