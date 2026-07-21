import 'package:flutter/material.dart';

import '../../../core/widgets/module_placeholder.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Профиль',
      icon: Icons.person_rounded,
      module: 'Замеры, цели, темы, экспорт данных — Модуль 4',
    );
  }
}
