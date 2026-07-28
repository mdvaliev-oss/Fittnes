import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../domain/entities/food_item.dart';
import 'models/food_dto.dart';

/// Loads the curated food catalog from a bundled JSON asset (macros per 100 g).
class FoodLocalDataSource {
  FoodLocalDataSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const String _assetPath = 'assets/nutrition/foods_seed.json';

  Future<List<FoodItem>> loadAll() async {
    final raw = await _bundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => FoodDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
