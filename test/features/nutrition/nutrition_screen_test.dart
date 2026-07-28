import 'package:fittnes/features/nutrition/data/nutrition_repository_memory.dart';
import 'package:fittnes/features/nutrition/domain/entities/food_entry.dart';
import 'package:fittnes/features/nutrition/domain/entities/meal_type.dart';
import 'package:fittnes/features/nutrition/presentation/nutrition_screen.dart';
import 'package:fittnes/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

FoodEntry _e(MealType meal, String name) => FoodEntry(
      day: DateTime.now(),
      meal: meal,
      name: name,
      grams: 100,
      kcal: 200,
      protein: 20,
      fat: 5,
      carb: 20,
      createdAt: DateTime.now(),
    );

void main() {
  testWidgets('renders meals, day label and logged foods', (tester) async {
    final repo = NutritionRepositoryMemory();
    await repo.addEntry(_e(MealType.breakfast, 'Овсянка на воде'));
    await repo.addEntry(_e(MealType.lunch, 'Куриная грудка'));

    await pumpApp(
      tester,
      const NutritionScreen(),
      overrides: [nutritionRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();

    expect(find.text('Питание'), findsOneWidget);
    expect(find.text('Сегодня'), findsOneWidget);
    // All four meal sections.
    expect(find.text('Завтрак'), findsOneWidget);
    expect(find.text('Обед'), findsOneWidget);
    expect(find.text('Ужин'), findsOneWidget);
    expect(find.text('Перекус'), findsOneWidget);
    // Logged foods appear under their meals.
    expect(find.text('Овсянка на воде'), findsOneWidget);
    expect(find.text('Куриная грудка'), findsOneWidget);
    // One "Добавить" per meal.
    expect(find.text('Добавить'), findsNWidgets(4));
  });

  testWidgets('empty day shows meals with no entries', (tester) async {
    await pumpApp(
      tester,
      const NutritionScreen(),
      overrides: [
        nutritionRepositoryProvider
            .overrideWithValue(NutritionRepositoryMemory()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Завтрак'), findsOneWidget);
    expect(find.text('Добавить'), findsNWidgets(4));
  });
}
