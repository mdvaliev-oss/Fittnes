import '../entities/body_weight_entry.dart';

/// Storage for body-weight measurements.
abstract class BodyWeightRepository {
  /// Every measurement, newest first.
  Future<List<BodyWeightEntry>> all();

  /// The most recent measurement, if any.
  Future<BodyWeightEntry?> latest();

  /// Persists [entry] and returns it with its assigned id.
  Future<BodyWeightEntry> add(BodyWeightEntry entry);

  Future<void> delete(int id);
}
