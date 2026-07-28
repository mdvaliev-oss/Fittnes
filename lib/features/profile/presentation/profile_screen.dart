import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_info.dart';
import '../../../core/backup/backup_service.dart';
import '../../../core/reminders/reminder_service.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/units/weight_format.dart';
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

  // Weight fields are stored in kg but shown/edited in the user's unit.
  late WeightUnit _unit;

  static String _n(num? v) =>
      v == null ? '' : (v % 1 == 0 ? v.toStringAsFixed(0) : '$v');

  /// A canonical kg value formatted in [u] for a text field.
  static String _fmtKg(double? kg, WeightUnit u) =>
      kg == null ? '' : formatValue(u.fromKg(kg), u);

  /// Parses a value typed in [_unit] back to canonical kg.
  double? _toKg(double? v) => v == null ? null : _unit.toKg(v);

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _unit = ref.read(appSettingsProvider).unit;
    _name = TextEditingController(text: p.name ?? '');
    _age = TextEditingController(text: p.age?.toString() ?? '');
    _height = TextEditingController(text: _n(p.heightCm));
    _weight = TextEditingController(text: _fmtKg(p.weightKg, _unit));
    _bench = TextEditingController(text: _fmtKg(p.benchMax, _unit));
    _squat = TextEditingController(text: _fmtKg(p.squatMax, _unit));
    _deadlift = TextEditingController(text: _fmtKg(p.deadliftMax, _unit));
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _age,
      _height,
      _weight,
      _bench,
      _squat,
      _deadlift,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save(UserProfile Function(UserProfile) f) {
    ref.read(profileProvider.notifier).update(f(ref.read(profileProvider)));
  }

  Future<void> _setReminders(bool enabled) async {
    final s = ref.read(appSettingsProvider);
    await ref.read(appSettingsProvider.notifier).setReminders(enabled: enabled);
    final reminders = ref.read(reminderServiceProvider);
    if (enabled) {
      await reminders.scheduleDaily(s.reminderHour, s.reminderMinute);
    } else {
      await reminders.cancel();
    }
  }

  Future<void> _pickReminderTime() async {
    final s = ref.read(appSettingsProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: s.reminderTime,
    );
    if (picked == null) return;
    await ref
        .read(appSettingsProvider.notifier)
        .setReminders(hour: picked.hour, minute: picked.minute);
    if (s.remindersEnabled) {
      await ref
          .read(reminderServiceProvider)
          .scheduleDaily(picked.hour, picked.minute);
    }
  }

  Future<void> _exportData() async {
    final json = await ref.read(backupServiceProvider).export();
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Данные скопированы в буфер обмена')),
    );
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Импорт данных'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'Вставьте JSON…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Импорт'),
          ),
        ],
      ),
    );
    if (raw == null || raw.trim().isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(backupServiceProvider).import(raw);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Импортировано: ${result.sessions} трен., ${result.programs} прогр.',
          ),
        ),
      );
    } on BackupException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось прочитать данные')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final settings = ref.watch(appSettingsProvider);
    final text = Theme.of(context).textTheme;

    // The unit switcher lives on this screen — reformat weight fields live when
    // it changes (values stay canonical kg; only the displayed unit differs).
    ref.listen(appSettingsProvider.select((s) => s.unit), (_, next) {
      final p = ref.read(profileProvider);
      _weight.text = _fmtKg(p.weightKg, next);
      _bench.text = _fmtKg(p.benchMax, next);
      _squat.text = _fmtKg(p.squatMax, next);
      _deadlift.text = _fmtKg(p.deadliftMax, next);
      setState(() => _unit = next);
    });

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
                _TextField(
                  controller: _name,
                  label: 'Имя',
                  onChanged: (v) => _save((p) => p.copyWith(name: v)),
                ),
                _NumberField(
                  controller: _age,
                  label: 'Возраст',
                  onChanged: (v) => _save((p) => p.copyWith(age: v?.toInt())),
                ),
                _NumberField(
                  controller: _height,
                  label: 'Рост',
                  suffix: 'см',
                  onChanged: (v) => _save((p) => p.copyWith(heightCm: v)),
                ),
                _NumberField(
                  controller: _weight,
                  label: 'Вес',
                  suffix: _unit.label,
                  onChanged: (v) =>
                      _save((p) => p.copyWith(weightKg: _toKg(v))),
                ),
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
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            Text('Домашние тренировки', style: text.bodyLarge),
                      ),
                      Switch(
                        value: profile.trainsAtHome,
                        onChanged: (v) =>
                            _save((p) => p.copyWith(trainsAtHome: v)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _Section(
              title: 'Максимумы (1ПМ)',
              children: [
                _NumberField(
                  controller: _bench,
                  label: 'Жим лёжа',
                  suffix: _unit.label,
                  onChanged: (v) =>
                      _save((p) => p.copyWith(benchMax: _toKg(v))),
                ),
                _NumberField(
                  controller: _squat,
                  label: 'Присед',
                  suffix: _unit.label,
                  onChanged: (v) =>
                      _save((p) => p.copyWith(squatMax: _toKg(v))),
                ),
                _NumberField(
                  controller: _deadlift,
                  label: 'Становая',
                  suffix: _unit.label,
                  onChanged: (v) =>
                      _save((p) => p.copyWith(deadliftMax: _toKg(v))),
                ),
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
                  onSelected: (v) =>
                      ref.read(appSettingsProvider.notifier).setThemeMode(v),
                ),
                const SizedBox(height: AppSpacing.sm),
                _EnumChips<WeightUnit>(
                  label: 'Единицы',
                  values: WeightUnit.values,
                  labelOf: (u) => u.label,
                  selected: settings.unit,
                  onSelected: (v) =>
                      ref.read(appSettingsProvider.notifier).setUnit(v),
                ),
              ],
            ),
            _Section(
              title: 'Напоминания',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Напоминать о тренировке',
                        style: text.bodyLarge,
                      ),
                    ),
                    Switch(
                      value: settings.remindersEnabled,
                      onChanged: _setReminders,
                    ),
                  ],
                ),
                if (settings.remindersEnabled)
                  Row(
                    children: [
                      Expanded(child: Text('Время', style: text.bodyLarge)),
                      TextButton(
                        onPressed: _pickReminderTime,
                        child: Text(
                          settings.reminderTime.format(context),
                          style: text.titleLarge,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            _Section(
              title: 'Данные',
              children: [
                _DataAction(
                  icon: Icons.ios_share_rounded,
                  label: 'Экспорт данных',
                  subtitle: 'Скопировать резервную копию (JSON)',
                  onTap: _exportData,
                ),
                const SizedBox(height: AppSpacing.xs),
                _DataAction(
                  icon: Icons.download_rounded,
                  label: 'Импорт данных',
                  subtitle: 'Восстановить из JSON',
                  onTap: _importData,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                'Fittnes · версия $kAppVersion',
                style: text.labelSmall?.copyWith(color: context.glass.textLow),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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

class _DataAction extends StatelessWidget {
  const _DataAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: glass.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.bodyLarge),
                  Text(subtitle, style: text.labelSmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: glass.textLow),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });
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
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        onChanged: (raw) =>
            onChanged(double.tryParse(raw.replaceAll(',', '.'))),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          isDense: true,
        ),
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
