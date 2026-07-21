import 'package:fittnes/core/utils/one_rep_max.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OneRepMax', () {
    test('epley returns the weight for a single rep', () {
      expect(OneRepMax.epley(100, 1), 100);
    });

    test('epley increases with reps', () {
      expect(OneRepMax.epley(100, 10), closeTo(133.33, 0.01));
      expect(OneRepMax.epley(100, 5), closeTo(116.67, 0.01));
    });

    test('guards against non-positive input', () {
      expect(OneRepMax.epley(0, 5), 0);
      expect(OneRepMax.epley(100, 0), 0);
      expect(OneRepMax.brzycki(100, 40), 0);
    });

    test('weightFor is the inverse of epley', () {
      final e1rm = OneRepMax.epley(100, 8);
      expect(OneRepMax.weightFor(e1rm, 8), closeTo(100, 0.001));
    });
  });
}
