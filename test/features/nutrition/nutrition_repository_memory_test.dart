import 'package:fittnes/features/nutrition/data/nutrition_repository_memory.dart';
import 'package:fittnes/features/nutrition/domain/entities/food_entry.dart';
import 'package:fittnes/features/nutrition/domain/entities/food_item.dart';
import 'package:fittnes/features/nutrition/domain/entities/meal_type.dart';
import 'package:flutter_test/flutter_test.dart';

FoodEntry _entry(DateTime day, {MealType meal = MealType.lunch}) => FoodEntry(
      day: day,
      meal: meal,
      name: 'Гречка',
      grams: 150,
      kcal: 138,
      protein: 5,
      fat: 1,
      carb: 26,
      createdAt: day.add(const Duration(hours: 12)),
    );

void main() {
  test('entries are stored and read back per day', () async {
    final repo = NutritionRepositoryMemory();
    await repo.addEntry(_entry(DateTime(2026, 5, 1)));
    await repo.addEntry(_entry(DateTime(2026, 5, 1), meal: MealType.dinner));
    await repo.addEntry(_entry(DateTime(2026, 5, 2)));

    final day1 = await repo.entriesForDay(DateTime(2026, 5, 1, 20));
    expect(day1, hasLength(2));
    final day2 = await repo.entriesForDay(DateTime(2026, 5, 2));
    expect(day2, hasLength(1));
  });

  test('removeEntry deletes by id', () async {
    final repo = NutritionRepositoryMemory();
    final id = await repo.addEntry(_entry(DateTime(2026, 5, 1)));
    await repo.removeEntry(id);
    expect(await repo.entriesForDay(DateTime(2026, 5, 1)), isEmpty);
  });

  test('custom foods round-trip and update in place', () async {
    final repo = NutritionRepositoryMemory();
    const food = FoodItem(
      id: '',
      name: 'Мой протеин',
      kcalPer100: 380,
      proteinPer100: 75,
      fatPer100: 5,
      carbPer100: 8,
      isCustom: true,
    );
    final id = await repo.saveCustomFood(food);
    var all = await repo.customFoods();
    expect(all, hasLength(1));
    expect(all.single.id, id);

    await repo.saveCustomFood(all.single.copyWith(name: 'Обновлён'));
    all = await repo.customFoods();
    expect(all, hasLength(1));
    expect(all.single.name, 'Обновлён');

    await repo.deleteCustomFood(id);
    expect(await repo.customFoods(), isEmpty);
  });

  test('recentFoods returns distinct names, newest first', () async {
    final repo = NutritionRepositoryMemory();
    await repo.addEntry(_entry(DateTime(2026, 5, 1)));
    await repo.addEntry(_entry(DateTime(2026, 5, 2)));
    final recent = await repo.recentFoods();
    expect(recent, ['Гречка']);
  });
}
