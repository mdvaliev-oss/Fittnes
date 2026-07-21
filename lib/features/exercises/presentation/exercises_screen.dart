import 'package:flutter/material.dart';

import '../../../core/widgets/module_placeholder.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Упражнения',
      icon: Icons.fitness_center_rounded,
      module: 'База 500+ упражнений, техника и подсветка мышц — Модуль 1',
    );
  }
}
