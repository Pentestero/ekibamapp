import 'package:flutter/material.dart';

class AppBrand extends StatelessWidget {
  final double height;
  final bool showText;

  const AppBrand({super.key, this.height = 28, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/icons/EKIBAM.jpg',
              height: height,
              width: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) {
                return Container(
                  height: height,
                  width: height,
                  decoration: BoxDecoration(
                    color: color.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.store, color: color, size: height * 0.6),
                );
              },
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Text(
            'ekibam',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
          ),
        ]
      ],
    );
  }
}
