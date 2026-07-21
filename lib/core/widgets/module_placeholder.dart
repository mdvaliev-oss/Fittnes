import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/glass_theme.dart';
import 'ambient_background.dart';
import 'glass_card.dart';

/// Temporary placeholder for feature screens delivered in later modules.
///
/// Keeps navigation fully functional in Module 0 without duplicating scaffold
/// code across screens.
class ModulePlaceholder extends StatelessWidget {
  const ModulePlaceholder({
    super.key,
    required this.title,
    required this.icon,
    required this.module,
  });

  final String title;
  final IconData icon;
  final String module;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;

    return AmbientBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.headlineLarge),
              const Spacer(),
              Center(
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 48, color: glass.textMid),
                      const SizedBox(height: AppSpacing.md),
                      Text('Скоро', style: text.titleLarge),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(module,
                          style: text.bodyMedium, textAlign: TextAlign.center,),
                    ],
                  ),
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
