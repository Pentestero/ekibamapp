import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Shimmer.fromColors(
      baseColor: isLight ? const Color(0xFFE8ECF4) : const Color(0xFF2A2A3E),
      highlightColor:
          isLight ? const Color(0xFFF1F5F9) : const Color(0xFF3A3A4E),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}
