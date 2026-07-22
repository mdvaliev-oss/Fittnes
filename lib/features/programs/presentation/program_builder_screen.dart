import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../exercises/domain/entities/exercise_enums.dart';
import '../../workout/presentation/widgets/exercise_picker_sheet.dart';
import '../domain/workout_program.dart';
import 'programs_providers.dart';

class _DayDraft {
  _DayDraft(this.name, this.exercises);
  String name;
  final List<ProgramExercise> exercises;
}

/// Builds and saves a user-created program.
class ProgramBuilderScreen extends ConsumerStatefulWidget {
  const ProgramBuilderScreen({super.key});

  @override
  ConsumerState<ProgramBuilderScreen> createState() =>
      _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends ConsumerState<ProgramBuilderScreen> {
  final _name = TextEditingController();
  ProgramCategory _category = ProgramCategory.fullBody;
  ExperienceLevel _level = ExperienceLevel.intermediate;
  final List<_DayDraft> _days = [_DayDraft('День 1', [])];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _addDay() =>
      setState(() => _days.add(_DayDraft('День ${_days.length + 1}', [])));

  Future<void> _addExercise(_DayDraft day) async {
    final exercise = await showExercisePicker(context);
    if (exercise == null) return;
    setState(
      () => day.exercises.add(
        ProgramExercise(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
        ),
      ),
    );
  }

  Future<void> _renameDay(_DayDraft day) async {
    final controller = TextEditingController(text: day.name);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Название дня'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() => day.name = result.trim());
    }
  }

  void _save() {
    final messenger = ScaffoldMessenger.of(context);
    if (_name.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Введите название программы')),
      );
      return;
    }
    final days = _days.where((d) => d.exercises.isNotEmpty).toList();
    if (days.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы одно упражнение')),
      );
      return;
    }
    final program = WorkoutProgram(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      description: 'Пользовательская программа',
      category: _category,
      level: _level,
      isCustom: true,
      days: [
        for (final d in days)
          ProgramDay(name: d.name, exercises: List.of(d.exercises)),
      ],
    );
    ref.read(customProgramsProvider.notifier).save(program);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Text('Новая программа', style: text.headlineMedium),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xxl * 2,
                  ),
                  children: [
                    TextField(
                      controller: _name,
                      style: text.headlineMedium,
                      decoration: const InputDecoration(
                        hintText: 'Название программы',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ChipRow<ProgramCategory>(
                      label: 'Сплит',
                      values: ProgramCategory.values,
                      labelOf: (c) => c.label,
                      selected: _category,
                      onSelected: (v) => setState(() => _category = v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ChipRow<ExperienceLevel>(
                      label: 'Уровень',
                      values: ExperienceLevel.values,
                      labelOf: (l) => l.label,
                      selected: _level,
                      onSelected: (v) => setState(() => _level = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final day in _days)
                      _DayCard(
                        day: day,
                        onRename: () => _renameDay(day),
                        onAddExercise: () => _addExercise(day),
                        onRemoveExercise: (i) =>
                            setState(() => day.exercises.removeAt(i)),
                        onEditExercise: (i, e) =>
                            setState(() => day.exercises[i] = e),
                        onRemoveDay: _days.length > 1
                            ? () => setState(() => _days.remove(day))
                            : null,
                      ),
                    TextButton.icon(
                      onPressed: _addDay,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Добавить день'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'Сохранить программу',
                      icon: Icons.check_rounded,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.onRename,
    required this.onAddExercise,
    required this.onRemoveExercise,
    required this.onEditExercise,
    required this.onRemoveDay,
  });

  final _DayDraft day;
  final VoidCallback onRename;
  final VoidCallback onAddExercise;
  final ValueChanged<int> onRemoveExercise;
  final void Function(int index, ProgramExercise updated) onEditExercise;
  final VoidCallback? onRemoveDay;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(day.name, style: text.titleLarge)),
                IconButton(
                  onPressed: onRename,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                ),
                if (onRemoveDay != null)
                  IconButton(
                    onPressed: onRemoveDay,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
              ],
            ),
            for (var i = 0; i < day.exercises.length; i++)
              _ExerciseEditor(
                exercise: day.exercises[i],
                onChanged: (e) => onEditExercise(i, e),
                onRemove: () => onRemoveExercise(i),
              ),
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Добавить упражнение'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseEditor extends StatelessWidget {
  const _ExerciseEditor({
    required this.exercise,
    required this.onChanged,
    required this.onRemove,
  });

  final ProgramExercise exercise;
  final ValueChanged<ProgramExercise> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: text.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.danger.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _Stepper(
                label: 'Подх.',
                value: exercise.sets,
                min: 1,
                max: 10,
                onChanged: (v) => onChanged(exercise.copyWith(sets: v)),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Stepper(
                label: 'Мин',
                value: exercise.targetMin,
                min: 1,
                max: exercise.targetMax,
                onChanged: (v) => onChanged(exercise.copyWith(targetMin: v)),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Stepper(
                label: 'Макс',
                value: exercise.targetMax,
                min: exercise.targetMin,
                max: 30,
                onChanged: (v) => onChanged(exercise.copyWith(targetMax: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Btn(
              icon: Icons.remove_rounded,
              onTap: value > min ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 24,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontWeight: FontWeight.w700, color: glass.textHi),
              ),
            ),
            _Btn(
              icon: Icons.add_rounded,
              onTap: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: glass.fill,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? glass.textLow : glass.textHi,
        ),
      ),
    );
  }
}

class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
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
                backgroundColor: glass.fill,
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: v == selected ? Colors.white : glass.textMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
