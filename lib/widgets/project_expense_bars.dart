import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProjectExpenseBars extends StatelessWidget {
  final Map<String, int> data;

  const ProjectExpenseBars({super.key, required this.data});

  static String _projectIconName(String name) {
    final n = name.toLowerCase();
    if (n.contains('interne')) return 'interne';
    if (n.contains('client')) return 'client';
    if (n.contains('mixte')) return 'mixte';
    return 'autre';
  }

  static IconData _iconFor(String name) {
    return switch (_projectIconName(name)) {
      'interne' => Icons.home_repair_service_outlined,
      'client' => Icons.business_outlined,
      'mixte' => Icons.merge_type,
      _ => Icons.work_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat('#,##0', 'fr_FR');

    final sorted = data.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = sorted.fold<int>(0, (sum, e) => sum + e.value);
    if (total <= 0) {
      return Center(
        child: Text(
          'Aucune donnée disponible',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withAlpha(150),
              ),
        ),
      );
    }

    final rows = <MapEntry<String, int>>[];
    final top = sorted.take(3).toList();
    final restTotal = sorted.skip(3).fold<int>(0, (sum, e) => sum + e.value);
    rows.addAll(top);
    if (restTotal > 0) rows.add(MapEntry('Autres', restTotal));

    final palette = [cs.primary, cs.secondary, cs.tertiary];

    return Column(
      children: List.generate(rows.length, (i) {
        final entry = rows[i];
        final fraction = (entry.value / total).clamp(0.0, 1.0);
        final color = palette[i % palette.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(_iconFor(entry.key),
                            size: 16, color: color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${currency.format(entry.value)} XAF',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: 10,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Container(
                          width: constraints.maxWidth * value,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}