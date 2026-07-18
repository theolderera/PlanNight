import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// -----------------------------------------------------------------------------
/// Reusable building blocks for the PlanNight design system: the brand mark, a
/// progress ring, a standard surface card, and a small section header. Screens
/// compose these so spacing, radii and shadows stay consistent everywhere.
/// -----------------------------------------------------------------------------

/// The PlanNight brand mark: a deep-navy rounded square holding a crescent moon
/// with a check — "plan the night, tick it off". Drawn (not an asset) so it
/// scales crisply and recolours with the theme.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.radius = 22});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.navy,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: c.navy.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 14),
            spreadRadius: -10,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _LogoPainter(moon: c.navyRingFill, navy: c.navy),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.moon, required this.navy});
  final Color moon;
  final Color navy;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2, cy = size.height / 2;
    final r = s * 0.30;

    // Crescent = big disc minus an offset disc.
    final outer = Path()..addOval(Rect.fromCircle(center: Offset(cx - r * 0.15, cy), radius: r));
    final cut = Path()..addOval(Rect.fromCircle(center: Offset(cx + r * 0.55, cy - r * 0.5), radius: r * 0.82));
    final crescent = Path.combine(PathOperation.difference, outer, cut);
    canvas.drawPath(crescent, Paint()..color = moon..isAntiAlias = true);

    // Check mark, in the navy background colour, sitting over the moon.
    final check = Path()
      ..moveTo(cx - r * 0.55, cy + r * 0.05)
      ..lineTo(cx - r * 0.12, cy + r * 0.48)
      ..lineTo(cx + r * 0.62, cy - r * 0.42);
    canvas.drawPath(
      check,
      Paint()
        ..color = navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.06
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.moon != moon || old.navy != navy;
}

/// A circular progress ring with a rounded cap, optionally wrapping a [child]
/// (e.g. the percentage label). Used in the Today hero and elsewhere.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 88,
    this.stroke = 9,
    required this.trackColor,
    required this.fillColor,
    this.child,
  });

  final double progress; // 0..1
  final double size;
  final double stroke;
  final Color trackColor;
  final Color fillColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0, 1),
          stroke: stroke,
          track: trackColor,
          fill: fillColor,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.stroke, required this.track, required this.fill});
  final double progress;
  final double stroke;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    if (progress <= 0) return;
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fillPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.fill != fill || old.track != track;
}

/// The standard white surface card: rounded corners + a soft shadow, matching
/// every card in the design. Replaces repetitive Container/BoxDecoration.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: [
          BoxShadow(color: c.shadow, blurRadius: 12, offset: const Offset(0, 3), spreadRadius: -4),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// A pill segmented control — a rounded track with a sliding white pill for the
/// active option. Used for Today/Tomorrow, priority, and theme selection.
class PillSegment extends StatelessWidget {
  const PillSegment({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.trackBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected == i ? c.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected == i
                        ? [BoxShadow(color: c.shadow, blurRadius: 6, offset: const Offset(0, 1), spreadRadius: -2)]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    options[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontSize: 12.5,
                      fontWeight: selected == i ? FontWeight.w700 : FontWeight.w600,
                      color: selected == i ? c.ink : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A tappable field-style tile (white surface, rounded, leading icon) used for
/// date/time pickers and navigation rows on forms and settings.
class FieldTile extends StatelessWidget {
  const FieldTile({
    super.key,
    required this.child,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  });

  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final row = Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(child: child),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }
}

/// A small field caption above an input, in the design's muted label style.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(text,
          style: TextStyle(
              fontFamily: AppFonts.sans,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary)),
    );
  }
}

/// A small all-caps section label ("НАМОИШ"), used above grouped settings.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(4, 0, 4, 10)});
  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: context.colors.textMuted,
        ),
      ),
    );
  }
}
