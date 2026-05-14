import 'package:flutter/material.dart';
import '../widgets/shimmer_loading.dart';

class HistorySkeleton extends StatelessWidget {
  const HistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return ShimmerLoading(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}
