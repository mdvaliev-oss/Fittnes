import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/units/weight_format.dart';

/// Drops a "new personal record" banner with a confetti burst over the
/// current screen for a couple of seconds. Fire-and-forget; safe to call
/// from a tap handler.
void showPrCelebration(
  BuildContext context, {
  required String exerciseName,
  required double e1rmKg,
  required WeightUnit unit,
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  HapticFeedback.heavyImpact();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _PrCelebration(
      exerciseName: exerciseName,
      e1rm: formatWeight(e1rmKg, unit),
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _PrCelebration extends StatefulWidget {
  const _PrCelebration({
    required this.exerciseName,
    required this.e1rm,
    required this.onDone,
  });

  final String exerciseName;
  final String e1rm;
  final VoidCallback onDone;

  @override
  State<_PrCelebration> createState() => _PrCelebrationState();
}

class _PrCelebrationState extends State<_PrCelebration>
    with SingleTickerProviderStateMixin {
  static const _life = Duration(milliseconds: 2400);

  late final AnimationController _c =
      AnimationController(vsync: this, duration: _life)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();
  final _particles = ConfettiParticle.burst(48);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // In: 0–0.12, hold, out: 0.85–1.
          final appear = Curves.easeOutBack.transform((t / 0.12).clamp(0, 1));
          final fade = t < 0.85 ? 1.0 : 1 - (t - 0.85) / 0.15;
          return Stack(
            children: [
              if (!reduceMotion)
                Positioned.fill(
                  child: CustomPaint(
                    painter: ConfettiPainter(
                      particles: _particles,
                      t: t,
                      opacity: fade,
                    ),
                  ),
                ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: MediaQuery.paddingOf(context).top + AppSpacing.md,
                child: Opacity(
                  opacity: fade.clamp(0, 1),
                  child: Transform.scale(
                    scale: reduceMotion ? 1 : 0.8 + 0.2 * appear,
                    child: _Banner(
                      exerciseName: widget.exerciseName,
                      e1rm: widget.e1rm,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.exerciseName, required this.e1rm});
  final String exerciseName;
  final String e1rm;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Новый рекорд!',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    exerciseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              e1rm,
              style: AppTypography.numeric(Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

/// One piece of confetti: launched upward from the top-centre, pulled down
/// by gravity, spinning as it falls.
class ConfettiParticle {
  const ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
    required this.drift,
  });

  final double angle, speed, spin, size, drift;
  final Color color;

  static const _palette = [
    AppColors.accent,
    AppColors.primaryBright,
    AppColors.warning,
    Colors.white,
  ];

  static List<ConfettiParticle> burst(int count, {int seed = 1}) {
    final r = math.Random(seed);
    return [
      for (var i = 0; i < count; i++)
        ConfettiParticle(
          angle: -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 0.9,
          speed: 0.55 + r.nextDouble() * 0.6,
          spin: (r.nextDouble() - 0.5) * 14,
          size: 5 + r.nextDouble() * 6,
          color: _palette[r.nextInt(_palette.length)],
          drift: (r.nextDouble() - 0.5) * 0.3,
        ),
    ];
  }
}

class ConfettiPainter extends CustomPainter {
  ConfettiPainter({
    required this.particles,
    required this.t,
    required this.opacity,
  });

  final List<ConfettiParticle> particles;
  final double t;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.18);
    final paint = Paint();
    for (final p in particles) {
      // Simple ballistic path in normalised units of the screen height.
      final vx = math.cos(p.angle) * p.speed + p.drift;
      final vy = math.sin(p.angle) * p.speed;
      final x = origin.dx + vx * t * size.height;
      final y = origin.dy + (vy * t + 0.9 * t * t) * size.height;
      if (y > size.height + 20) continue;
      paint.color = p.color.withValues(alpha: opacity.clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) =>
      old.t != t || old.opacity != opacity;
}
