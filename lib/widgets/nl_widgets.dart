import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_theme.dart';

// ──────────────────────────── NL Card
class NLCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const NLCard({super.key, required this.child, this.color, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color ?? NLColors.surface,
        borderRadius: BorderRadius.all(NLRadius.lg),
        border: Border.all(color: NLColors.line2),
        boxShadow: shadowCard,
      ),
      child: child,
    );
  }
}

// ──────────────────────────── NL Section Title
class NLSectionTitle extends StatelessWidget {
  final String label;
  final String? action;

  const NLSectionTitle(this.label, {super.key, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: NLColors.muted,
                  letterSpacing: 1.1)),
          if (action != null)
            Text(action!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: NLColors.accent)),
        ],
      ),
    );
  }
}

// ──────────────────────────── NL Button
class NLButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool full;
  final Widget? icon;

  const NLButton({super.key, required this.label, this.onTap, this.primary = true, this.full = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final bg = primary ? NLColors.ink : NLColors.surface2;
    final fg = primary ? Colors.white : NLColors.ink;
    Widget btn = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.all(NLRadius.pill)),
        child: Row(
          mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg, letterSpacing: -0.2)),
          ],
        ),
      ),
    );
    return full ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// ──────────────────────────── NL Ghost Button
class NLGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const NLGhostButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: NLColors.accent)),
      ),
    );
  }
}

// ──────────────────────────── NL Input
class NLInput extends StatelessWidget {
  final String? placeholder;
  final String? initialValue;
  final bool obscure;
  final Widget? trailing;
  final bool readOnly;

  const NLInput({super.key, this.placeholder, this.initialValue, this.obscure = false, this.trailing, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: NLColors.surface2, borderRadius: BorderRadius.all(NLRadius.md)),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: initialValue != null ? TextEditingController(text: initialValue) : null,
            obscureText: obscure,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: NLColors.muted),
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 16, color: NLColors.ink),
          ),
        ),
        ?trailing,
      ]),
    );
  }
}

// ──────────────────────────── NL Label
class NLLabel extends StatelessWidget {
  final String text;
  const NLLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NLColors.muted, letterSpacing: 0.9)),
    );
  }
}

// ──────────────────────────── NL Toggle
class NLToggle extends StatelessWidget {
  final bool on;
  const NLToggle({super.key, required this.on});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 26,
      decoration: BoxDecoration(
        color: on ? NLColors.accent : NLColors.surface2,
        borderRadius: BorderRadius.all(NLRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Align(
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 2))],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────── NL Segmented
class NLSegmented extends StatelessWidget {
  final List<String> items;
  final String active;
  final ValueChanged<String>? onChange;

  const NLSegmented({super.key, required this.items, required this.active, this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: NLColors.surface2, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: items.map((item) {
          final isActive = item == active;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChange?.call(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? NLColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2, offset: const Offset(0, 1))] : null,
                ),
                alignment: Alignment.center,
                child: Text(item,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? NLColors.ink : NLColors.muted)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ──────────────────────────── NL Top Bar
class NLTopBar extends StatelessWidget {
  final Widget? leading;
  final String? title;
  final Widget? trailing;

  const NLTopBar({super.key, this.leading, this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            SizedBox(width: 44, child: leading),
            Expanded(
              child: Center(
                child: title != null
                    ? Text(title!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: NLColors.ink))
                    : const SizedBox(),
              ),
            ),
            SizedBox(width: 44, child: trailing != null ? Align(alignment: Alignment.centerRight, child: trailing!) : null),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── NL Back Button
class NLBackBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const NLBackBtn({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: NLColors.surface2, shape: BoxShape.circle),
        child: const Icon(Icons.chevron_left_rounded, color: NLColors.ink, size: 22),
      ),
    );
  }
}

// ──────────────────────────── NL Header
class NLHeader extends StatelessWidget {
  final String greeting;
  final String title;
  final List<Widget> actions;

  const NLHeader({super.key, required this.greeting, required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting.toUpperCase(),
                    style: const TextStyle(fontSize: 13, color: NLColors.muted, fontWeight: FontWeight.w500, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: NLColors.ink)),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

// ──────────────────────────── NL Avatar
class NLAvatar extends StatelessWidget {
  final String letter;
  const NLAvatar(this.letter, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NLColors.peach, NLColors.rose],
        ),
      ),
      alignment: Alignment.center,
      child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
    );
  }
}

// ──────────────────────────── NL Icon Button (circle)
class NLCircleBtn extends StatelessWidget {
  final Widget child;
  final Color? bg;
  final VoidCallback? onTap;

  const NLCircleBtn({super.key, required this.child, this.bg, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg ?? NLColors.surface,
          shape: BoxShape.circle,
          boxShadow: shadowCard,
        ),
        child: child,
      ),
    );
  }
}

// ──────────────────────────── NL Stat Badge
class NLStat extends StatelessWidget {
  final int delta;
  final String unit;
  const NLStat({super.key, required this.delta, this.unit = '%'});

  @override
  Widget build(BuildContext context) {
    final isUp = delta > 0;
    final isDown = delta < 0;
    final bg = isUp ? NLColors.roseSoft : isDown ? NLColors.mintSoft : NLColors.surface2;
    final fg = isUp ? NLColors.bad : isDown ? NLColors.good : NLColors.muted;
    final arrow = isUp ? '↑' : isDown ? '↓' : '–';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.all(NLRadius.pill)),
      child: Text('$arrow ${delta.abs()}$unit',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// ──────────────────────────── NL List Row
class NLListRow extends StatelessWidget {
  final Widget? icon;
  final Color? iconBg;
  final String title;
  final String? sub;
  final Widget? right;
  final bool last;

  const NLListRow({
    super.key,
    this.icon,
    this.iconBg,
    required this.title,
    this.sub,
    this.right,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: NLColors.line2, width: 1)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg ?? NLColors.surface2, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: NLColors.ink)),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub!, style: const TextStyle(fontSize: 12, color: NLColors.muted)),
                ],
              ],
            ),
          ),
          if (right != null)
            right!
          else
            const Icon(Icons.chevron_right_rounded, color: NLColors.muted, size: 20),
        ],
      ),
    );
  }
}

// ──────────────────────────── NL List Container
class NLList extends StatelessWidget {
  final List<Widget> children;
  const NLList({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NLColors.surface,
        borderRadius: BorderRadius.all(NLRadius.lg),
        boxShadow: shadowCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

// ──────────────────────────── NL Tile
class NLTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Widget? badge;

  const NLTile({super.key, required this.label, required this.value, this.unit, this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NLColors.surface,
        borderRadius: BorderRadius.all(NLRadius.md),
        boxShadow: shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(fontSize: 12, color: NLColors.muted, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: NLColors.ink)),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(unit!, style: const TextStyle(fontSize: 13, color: NLColors.muted, fontWeight: FontWeight.w500)),
              ],
            ],
          ),
          if (badge != null) ...[const SizedBox(height: 8), badge!],
        ],
      ),
    );
  }
}

// ──────────────────────────── NL Signal Row
class NLSignalRow extends StatelessWidget {
  final String title;
  final String body;
  final NLSignalLevel level;
  final Widget? trailing;

  const NLSignalRow({super.key, required this.title, required this.body, this.level = NLSignalLevel.bad, this.trailing});

  @override
  Widget build(BuildContext context) {
    final bg = level == NLSignalLevel.bad ? NLColors.roseSoft : level == NLSignalLevel.warn ? NLColors.peachSoft : NLColors.skySoft;
    final dot = level == NLSignalLevel.bad ? NLColors.bad : level == NLSignalLevel.warn ? NLColors.warn : NLColors.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.all(NLRadius.md)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 12),
            child: Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: NLColors.ink)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(fontSize: 12, color: NLColors.ink2, height: 1.45)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

enum NLSignalLevel { bad, warn, info }

// ──────────────────────────── NL Ring (Donut)
class NLRing extends StatelessWidget {
  final double value;
  final double max;
  final double size;
  final double stroke;
  final Color color;
  final Color? trackColor;
  final Widget? center;

  const NLRing({
    super.key,
    required this.value,
    this.max = 100,
    this.size = 160,
    this.stroke = 14,
    this.color = NLColors.accent,
    this.trackColor,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              value: value,
              max: max,
              stroke: stroke,
              color: color,
              trackColor: trackColor ?? NLColors.surface2,
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double max;
  final double stroke;
  final Color color;
  final Color trackColor;

  _RingPainter({required this.value, required this.max, required this.stroke, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweep = 2 * math.pi * (value / max);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color;
}

// ──────────────────────────── NL Chart (line + area + dots + threshold)
class NLChart extends StatelessWidget {
  final List<double> data;
  final double? threshold;
  final double height;
  final Color color;
  final Color tinted;
  final List<String>? xLabels;

  const NLChart({
    super.key,
    required this.data,
    this.threshold,
    this.height = 140,
    this.color = NLColors.accent,
    this.tinted = NLColors.accentSoft,
    this.xLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            size: Size.fromHeight(height),
            painter: _ChartPainter(data: data, threshold: threshold, color: color, tinted: tinted),
          ),
        ),
        if (xLabels != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: xLabels!.map((l) => Text(l, style: const TextStyle(fontSize: 11, color: NLColors.muted))).toList(),
          ),
        ],
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final double? threshold;
  final Color color;
  final Color tinted;

  _ChartPainter({required this.data, this.threshold, required this.color, required this.tinted});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const double max = 10, min = 0;
    const double padX = 8, padY = 14;
    final n = data.length;

    double xs(int i) => padX + (i * (size.width - padX * 2)) / (n - 1);
    double ys(double v) => padY + ((max - v) / (max - min)) * (size.height - padY * 2);

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0x141F1B16)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final t in [0.25, 0.5, 0.75]) {
      final y = padY + t * (size.height - padY * 2);
      _drawDashed(canvas, Offset(padX, y), Offset(size.width - padX, y), gridPaint);
    }

    // Threshold
    if (threshold != null) {
      final thPaint = Paint()
        ..color = NLColors.bad.withValues(alpha: 0.7)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      _drawDashed(canvas, Offset(padX, ys(threshold!)), Offset(size.width - padX, ys(threshold!)), thPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: 'порог ${threshold!.round()}',
          style: TextStyle(fontSize: 9, color: NLColors.bad, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - padX - tp.width, ys(threshold!) - 14));
    }

    // Area path
    final path = Path();
    final linePath = Path();
    for (int i = 0; i < n; i++) {
      final x = xs(i), y = ys(data[i]);
      if (i == 0) {
        path.moveTo(x, y);
        linePath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }
    path.lineTo(xs(n - 1), size.height - padY);
    path.lineTo(xs(0), size.height - padY);
    path.close();

    canvas.drawPath(path, Paint()..color = tinted.withValues(alpha: 0.7)..style = PaintingStyle.fill);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Dots
    for (int i = 0; i < n; i++) {
      canvas.drawCircle(Offset(xs(i), ys(data[i])), 3.5,
          Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(xs(i), ys(data[i])), 3.5,
          Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  void _drawDashed(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 4.0, gapLength = 4.0;
    final dx = end.dx - start.dx, dy = end.dy - start.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final steps = (dist / (dashLength + gapLength)).floor();
    final ux = dx / dist, uy = dy / dist;
    for (int i = 0; i < steps; i++) {
      final s = i * (dashLength + gapLength);
      canvas.drawLine(
        Offset(start.dx + ux * s, start.dy + uy * s),
        Offset(start.dx + ux * (s + dashLength), start.dy + uy * (s + dashLength)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.data != data;
}

// ──────────────────────────── NL Scale (bar visualization 0–10)
class NLScale extends StatelessWidget {
  final int value;
  final Color color;
  final Color tint;
  final String? leftLabel;
  final String? rightLabel;
  final String? descriptor;
  // When provided, each bar tap calls onChanged(i). Null → read-only display.
  final ValueChanged<int>? onChanged;

  const NLScale({
    super.key,
    required this.value,
    required this.color,
    required this.tint,
    this.leftLabel,
    this.rightLabel,
    this.descriptor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$value', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: -1.1, color: color, height: 1)),
            const SizedBox(width: 8),
            const Text('/ 10', style: TextStyle(fontSize: 14, color: NLColors.muted, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (descriptor != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.all(NLRadius.pill)),
                child: Text(descriptor!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(11, (i) {
            final isActive = i == value;
            final isPast = i < value;
            final h = 8.0 + i * 1.6;
            return Expanded(
              child: GestureDetector(
                onTap: onChanged != null ? () => onChanged!(i) : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    height: h,
                    decoration: BoxDecoration(
                      color: isActive ? color : isPast ? tint : NLColors.surface2,
                      borderRadius: BorderRadius.circular(3),
                      border: isActive ? Border.all(color: color, width: 2) : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel ?? '', style: const TextStyle(fontSize: 11, color: NLColors.muted)),
            Text(rightLabel ?? '', style: const TextStyle(fontSize: 11, color: NLColors.muted)),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────── NL Slider
class NLSlider extends StatelessWidget {
  final double value;
  final double max;
  final Color color;

  const NLSlider({super.key, required this.value, this.max = 10, this.color = NLColors.accent});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pct = value / max;
        return Column(
          children: [
            SizedBox(
              height: 36,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(height: 6, decoration: BoxDecoration(color: NLColors.surface2, borderRadius: BorderRadius.all(NLRadius.pill))),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.all(NLRadius.pill))),
                  ),
                  Positioned(
                    left: (constraints.maxWidth - 24) * pct,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2))],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('0', style: TextStyle(fontSize: 12, color: NLColors.muted)),
                Text('5', style: TextStyle(fontSize: 12, color: NLColors.muted)),
                Text('10', style: TextStyle(fontSize: 12, color: NLColors.muted)),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────── NL Tab Bar
const _nlTabs = [
  _NLTab(key: 'home', icon: Icons.home_outlined, label: 'Главная'),
  _NLTab(key: 'diary', icon: Icons.book_outlined, label: 'Дневник'),
  _NLTab(key: 'chart', icon: Icons.show_chart_rounded, label: 'Анализ'),
  _NLTab(key: 'profile', icon: Icons.person_outline_rounded, label: 'Профиль'),
];

class _NLTab {
  final String key;
  final IconData icon;
  final String label;
  const _NLTab({required this.key, required this.icon, required this.label});
}

class NLTabBar extends StatelessWidget {
  final String active;
  final VoidCallback? onFab;
  final ValueChanged<String>? onTabChanged;

  const NLTabBar({super.key, required this.active, this.onFab, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 92,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.all(NLRadius.pill),
                  border: Border.all(color: NLColors.line, width: 0.5),
                  boxShadow: [BoxShadow(color: NLColors.ink.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: _nlTabs.map((t) {
                    final isActive = t.key == active;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTabChanged?.call(t.key),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(borderRadius: BorderRadius.all(NLRadius.pill)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(t.icon, size: 22, color: isActive ? NLColors.accent : NLColors.muted),
                              const SizedBox(height: 2),
                              Text(t.label,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                      color: isActive ? NLColors.accent : NLColors.muted)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onFab,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: NLColors.ink,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x331F1B16), blurRadius: 24, offset: Offset(0, 10))],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── NL Divider
class NLDivider extends StatelessWidget {
  const NLDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: NLColors.line, margin: const EdgeInsets.symmetric(vertical: 12));
  }
}

// ──────────────────────────── NL Correlation Bar
class NLCorrelationBar extends StatelessWidget {
  final double r;
  const NLCorrelationBar({super.key, required this.r});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final half = constraints.maxWidth / 2;
        final fillWidth = r.abs() * half;
        final leftStart = r < 0 ? half - fillWidth : half;
        return Stack(
          children: [
            Container(height: 8, decoration: BoxDecoration(color: NLColors.surface2, borderRadius: BorderRadius.all(NLRadius.pill))),
            Positioned(
              left: half - 0.5,
              child: Container(width: 1, height: 8, color: NLColors.line),
            ),
            Positioned(
              left: leftStart,
              child: Container(
                height: 8,
                width: fillWidth,
                decoration: BoxDecoration(
                  color: r < 0 ? NLColors.mint : NLColors.peach,
                  borderRadius: BorderRadius.all(NLRadius.pill),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
