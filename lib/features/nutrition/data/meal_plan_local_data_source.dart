import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../domain/entities/meal_plan.dart';

/// Loads the curated ready-made meal plans from a bundled JSON asset.
class MealPlanLocalDataSource {
  MealPlanLocalDataSource({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const String _assetPath = 'assets/nutrition/meal_plans_seed.json';

  Future<List<MealPlan>> loadAll() async {
    final raw = await _bundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => MealPlan.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
