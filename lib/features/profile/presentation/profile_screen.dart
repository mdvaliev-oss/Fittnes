import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../exercises/domain/entities/exercise_enums.dart';
import '../domain/user_profile.dart';
import 'profile_providers.dart';

/// Editable, persistent athlete profile plus app appearance settings.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _bench;
  late final TextEditingController _squat;
  late final TextEditingController _deadlift;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    String n(num? v) => v == null ? '' : (v % 1 == 0 ? v.toStringAsFixed(0) : '$v');
    _name = TextEditingController(text: p.name ?? '');
    _age = TextEditingController(text: p.age?.toString() ?? '');
    _height = TextEditingController(text: n(p.heightCm));
    _weight = TextEditingController(text: n(p.weightKg));
    _bench = TextEditingController(text: n(p.benchMax));
    _squat = TextEditingController(text: n(p.squatMax));
    _deadlift = TextEditingController(text: n(p.deadliftMax));
  }

  @override
  void dispose() {
    for (final c in [_name, _age, _height, _weight, _bench, _squat, _deadlift]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save(UserProfile Function(UserProfile) f) {
    ref.read(profileProvider.notifier).update(f(ref.read(profileProvider)));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final settings = ref.watch(appSettingsProvider);
    final text = Theme.of(context).textTheme;

    return AmbientBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxl * 2,
          ),
          children: [
            Text('Профиль', style: text.headlineLarge),
            Text(
              '${profile.goal.label} · ${profile.experience.label}',
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),

            _Section(
              title: 'Личные данные',
              children: [
                _TextField(controller: _name, label: 'Имя', onChanged: (v) => _save((p) => p.copyWith(name: v))),
                _NumberField(controller: _age, label: 'Возраст', onChanged: (v) => _save((p) => p.copyWith(age: v?.toInt()))),
                _NumberField(controller: _height, label: 'Рост', suffix: 'см', onChanged: (v) => _save((p) => p.copyWith(heightCm: v))),
                _NumberField(controller: _weight, label: 'Вес', suffix: 'кг', onChanged: (v) => _save((p) => p.copyWith(weightKg: v))),
                const SizedBox(height: AppSpacing.xs),
                _EnumChips<Sex>(
                  label: 'Пол',
                  values: Sex.values,
                  labelOf: (s) => s.label,
                  selected: profile.sex,
                  onSelected: (v) => _save((p) => p.copyWith(sex: v)),
                ),
              ],
            ),

            _Section(
              title: 'Тренировки',
              children: [
                _EnumChips<TrainingGoal>(
                  label: 'Цель',
                  values: TrainingGoal.values,
                  labelOf: (g) => g.label,
                  selected: profile.goal,
                  onSelected: (v) => _save((p) => p.copyWith(goal: v)),
                ),
                const SizedBox(height: AppSpacing.sm),
                _EnumChips<ExperienceLevel>(
                  label: 'Опыт',
                  values: ExperienceLevel.values,
                  labelOf: (l) => l.label,
                  selected: profile.experience,
                  onSelected: (v) => _save((p) => p.copyWith(experience: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Домашние тренировки'),
                  value: profile.trainsAtHome,
                  onChanged: (v) => _save((p) => p.copyWith(trainsAtHome: v)),
                ),
              ],
            ),

            _Section(
              title: 'Максимумы (1ПМ)',
              children: [
                _NumberField(controller: _bench, label: 'Жим лёжа', suffix: 'кг', onChanged: (v) => _save((p) => p.copyWith(benchMax: v))),
                _NumberField(controller: _squat, label: 'Присед', suffix: 'кг', onChanged: (v) => _save((p) => p.copyWith(squatMax: v))),
                _NumberField(controller: _deadlift, label: 'Становая', suffix: 'кг', onChanged: (v) => _save((p) => p.copyWith(deadliftMax: v))),
              ],
            ),

            _Section(
              title: 'Оформление',
              children: [
                _EnumChips<ThemeMode>(
                  label: 'Тема',
                  values: ThemeMode.values,
                  labelOf: _themeLabel,
                  selected: settings.themeMode,
                  onSelected: (v) => ref.read(appSettingsProvider.notifier).setThemeMode(v),
                ),
                const SizedBox(height: AppSpacing.sm),
                _EnumChips<WeightUnit>(
                  label: 'Единицы',
                  values: WeightUnit.values,
                  labelOf: (u) => u.label,
                  selected: settings.unit,
                  onSelected: (v) => ref.read(appSettingsProvider.notifier).setUnit(v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _themeLabel(ThemeMode m) => switch (m) {
        ThemeMode.system => 'Система',
        ThemeMode.light => 'Светлая',
        ThemeMode.dark => 'Тёмная',
      };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.controller, required this.label, required this.onChanged});
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.suffix,
  });
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        onChanged: (raw) => onChanged(double.tryParse(raw.replaceAll(',', '.'))),
        decoration: InputDecoration(labelText: label, suffixText: suffix, isDense: true),
      ),
    );
  }
}

class _EnumChips<T> extends StatelessWidget {
  const _EnumChips({
    required this.label,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final v in values)
              ChoiceChip(
                label: Text(labelOf(v)),
                selected: v == selected,
                onSelected: (_) => onSelected(v),
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: v == selected ? Colors.white : glass.textMid,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: glass.fill,
                selectedColor: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ],
    );
  }
}
