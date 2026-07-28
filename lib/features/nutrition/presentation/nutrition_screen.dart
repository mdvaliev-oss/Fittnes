import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ambient_background.dart';

/// Nutrition diary tab. Full UI (calorie ring, meals, add flow) lands in the
/// next module; this is the wired-in placeholder.
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return AmbientBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Питание', style: text.headlineLarge),
              const Spacer(),
              Center(
                child: Text(
                  'Дневник питания скоро появится здесь',
                  style: text.bodyMedium,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
