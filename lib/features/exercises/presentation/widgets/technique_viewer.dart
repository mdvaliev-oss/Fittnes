import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/exercise.dart';
import 'technique/keyframes.dart';
import 'technique_animation.dart';

/// Shows the exercise technique as an infinitely looping visual.
///
/// When [Exercise.mediaUrl] points at a WebP/GIF it loops that; otherwise it
/// renders an [AnimatedTechniqueFigure] that performs the movement with the
/// right view, fixture and muscle glow, plus phase / tempo pills and
/// play-pause / slow-motion controls.
class TechniqueViewer extends StatefulWidget {
  const TechniqueViewer({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<TechniqueViewer> createState() => _TechniqueViewerState();
}

class _TechniqueViewerState extends State<TechniqueViewer>
    with SingleTickerProviderStateMixin {
  static const _normal = Duration(milliseconds: 2400);
  static const _slow = Duration(milliseconds: 5200);

  late final AnimationController _c;
  bool _slowMotion = false;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _normal)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  void _toggleSpeed() {
    setState(() => _slowMotion = !_slowMotion);
    _c.duration = _slowMotion ? _slow : _normal;
    if (_playing) _c.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.exercise.mediaUrl;

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: _bgGradient),
          child: media != null
              ? Image.network(media, fit: BoxFit.cover)
              : _AnimatedPreview(
                  controller: _c,
                  exercise: widget.exercise,
                  playing: _playing,
                  slowMotion: _slowMotion,
                  onTogglePlay: _togglePlay,
                  onToggleSpeed: _toggleSpeed,
                ),
        ),
      ),
    );
  }

  static const _bgGradient = LinearGradient(
    colors: [Color(0xFF161620), Color(0xFF0E0E16)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class _AnimatedPreview extends StatelessWidget {
  const _AnimatedPreview({
    required this.controller,
    required this.exercise,
    required this.playing,
    required this.slowMotion,
    required this.onTogglePlay,
    required this.onToggleSpeed,
  });

  final AnimationController controller;
  final Exercise exercise;
  final bool playing;
  final bool slowMotion;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleSpeed;

  @override
  Widget build(BuildContext context) {
    final pattern = exercise.pattern;
    final spec = PatternSpec.of(pattern);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final forward = controller.status != AnimationStatus.reverse;
        final lifting = spec.liftsForward ? forward : !forward;
        // Glow breathes with the rep and burns brighter while lifting.
        final pulse = 0.5 + 0.5 * math.sin(controller.value * math.pi);
        final glow = spec.isStatic
            ? 0.45 + 0.25 * pulse
            : (lifting ? 0.55 : 0.2) + 0.35 * pulse;

        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: AnimatedTechniqueFigure(
                  progress: controller.value,
                  pattern: pattern,
                  equipment: exercise.equipment,
                  glow: glow,
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.md,
              child: _PhasePill(
                label: spec.isStatic
                    ? 'Удержание'
                    : lifting
                        ? 'Подъём'
                        : 'Опускание',
                icon: spec.isStatic
                    ? Icons.pause_rounded
                    : lifting
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                color: lifting || spec.isStatic
                    ? AppColors.accent
                    : AppColors.primaryBright,
              ),
            ),
            if (exercise.tempo != null)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.md,
                child: _Pill('Темп ${exercise.tempo!}'),
              ),
            Positioned(
              left: AppSpacing.md,
              bottom: AppSpacing.sm,
              child: _Pill(pattern.label),
            ),
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.xs,
              child: Row(
                children: [
                  _ControlButton(
                    icon: Icons.slow_motion_video_rounded,
                    active: slowMotion,
                    tooltip: 'Медленнее',
                    onTap: onToggleSpeed,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  _ControlButton(
                    icon: playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    tooltip: playing ? 'Пауза' : 'Играть',
                    onTap: onTogglePlay,
                  ),
                ],
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: 0,
              child: _RepBar(value: controller.value),
            ),
          ],
        );
      },
    );
  }
}

class _PhasePill extends StatelessWidget {
  const _PhasePill({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        foregroundColor: active ? AppColors.accent : Colors.white,
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

class _RepBar extends StatelessWidget {
  const _RepBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 3,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        valueColor: const AlwaysStoppedAnimation(AppColors.primaryBright),
      ),
    );
  }
}
