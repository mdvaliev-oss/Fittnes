import 'package:flutter/material.dart';

import '../../../core/widgets/module_placeholder.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Прогресс',
      icon: Icons.insights_rounded,
      module: 'Графики силы, тоннажа и личных рекордов — Модуль 3',
    );
  }
}
