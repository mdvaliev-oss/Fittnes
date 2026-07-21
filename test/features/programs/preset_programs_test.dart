import 'dart:convert';
import 'dart:io';

import 'package:fittnes/features/programs/data/preset_programs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every preset program exercise id exists in the seed catalog', () {
    final raw = File('assets/exercises/exercises_seed.json').readAsStringSync();
    final ids = {
      for (final e in jsonDecode(raw) as List<dynamic>)
        (e as Map<String, dynamic>)['id'] as String,
    };

    for (final program in PresetPrograms.all) {
      for (final day in program.days) {
        for (final pe in day.exercises) {
          expect(
            ids.contains(pe.exerciseId),
            isTrue,
            reason: 'Программа "${program.name}" ссылается на несуществующее '
                'упражнение: ${pe.exerciseId}',
          );
        }
      }
    }
  });

  test('program days and exercises are well-formed', () {
    for (final program in PresetPrograms.all) {
      expect(program.days, isNotEmpty);
      for (final day in program.days) {
        expect(day.exercises, isNotEmpty);
        for (final pe in day.exercises) {
          expect(pe.sets, greaterThan(0));
          expect(pe.targetMin, lessThanOrEqualTo(pe.targetMax));
        }
      }
    }
  });
}
