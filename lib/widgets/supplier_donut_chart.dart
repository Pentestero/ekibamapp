import 'dart:math' as math;

import 'package:flutter/material.dart';

class SupplierDonutChart extends StatefulWidget {
  final Map<String, int> data;
  final double size;

  const SupplierDonutChart({
    super.key,
    required this.data,
    this.size = 132,
  });

  @override
  State<SupplierDonutChart> createState() => _SupplierDonutChartState();
}

class _DonutSegment {
  final String label;
  final double fraction;
  final Color color;

  const _DonutSegment({
    required this.label,
    required this.fraction,
    required this.color,
  });
}

class _SupplierDonutChartState extends State<SupplierDonutChart> {
  List<_DonutSegment> _segments = const [];
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _segments = _computeSegments();
  }

  @override
  void didUpdateWidget(covariant SupplierDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _segments = _computeSegments();
    }
  }

  List<_DonutSegment> _computeSegments() {
    final cs = Theme.of(context).colorScheme;
    final sorted = widget.data.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = sorted.fold<int>(0, (sum, e) => sum + e.value);
    if (total <= 0) return const [];

    final palette = [cs.primary, cs.secondary, cs.tertiary];
    final segments = <_DonutSegment>[];

    final top = sorted.take(3).toList();
    final rest = sorted.skip(3);
    for (var i = 0; i < top.length; i++) {
      segments.add(_DonutSegment(
        label: top[i].key,
        fraction: top[i].value / total,
        color: palette[i % palette.length],
      ));
    }
    final restTotal = rest.fold<int>(0, (sum, e) => sum + e.value);
    if (restTotal > 0) {
      segments.add(_DonutSegment(
        label: 'Autres',
        fraction: restTotal / total,
        color: cs.tertiary,
      ));
    }
    return segments;
  }

  String _formatPercent(double fraction) {
    final pct = fraction * 100;
    final rounded = pct.round();
    if ((pct - rounded).abs() < 0.05) return '$rounded %';
    return '${pct.toStringAsFixed(1)} %';
  }

  void _selectSegment(int? index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = widget.size;

    if (_segments.isEmpty) {
      return Center(
        child: Text(
          'Aucune donnée disponible',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withAlpha(150),
              ),
        ),
      );
    }

    final selected = _selectedIndex != null ? _segments[_selectedIndex!] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: GestureDetector(
            onTapUp: (details) {
              final box = context.findRenderObject() as RenderBox?;
              final local = box?.globalToLocal(details.globalPosition);
              if (local == null) return;
              final center = Offset(size / 2, size / 2);
              final delta = local - center;
              final dist = delta.distance;
              final inner = size * 0.10;
              final outer = size / 2;
              if (dist < inner || dist > outer) return;
              var angle =
                  math.atan2(delta.dx, -delta.dy) + math.pi / 2;
              if (angle < 0) angle += 2 * math.pi;
              if (angle >= 2 * math.pi) angle -= 2 * math.pi;
              var cursor = 0.0;
              int? hit;
              for (var i = 0; i < _segments.length; i++) {
                cursor += _segments[i].fraction * 2 * math.pi;
                if (angle <= cursor) {
                  hit = i;
                  break;
                }
              }
              _selectSegment(hit);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _DonutPainter(
                    segments: _segments,
                    trackColor: cs.surfaceContainerLow,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selected == null ? '100 %' : _formatPercent(selected.fraction),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                    ),
                    SizedBox(
                      width: size * 0.7,
                      child: Text(
                        selected?.label ?? 'Global',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_segments.length, (i) {
              final segment = _segments[i];
              final isActive = _selectedIndex == i;
              return InkWell(
                onTap: () => _selectSegment(i),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? cs.surfaceContainerHigh
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: segment.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          segment.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: cs.onSurface,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatPercent(segment.fraction),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final Color trackColor;

  const _DonutPainter({required this.segments, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.12;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final gap = segments.length > 1 ? 0.02 : 0.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    paint.color = trackColor;
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, paint);

    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = (segment.fraction * 2 * math.pi) - gap;
      paint.color = segment.color;
      canvas.drawArc(arcRect, start, sweep, false, paint);
      start += segment.fraction * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.trackColor != trackColor;
  }
}