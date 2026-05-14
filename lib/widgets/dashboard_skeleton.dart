import 'package:flutter/material.dart';
import '../widgets/shimmer_loading.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerCard(height: 60),
            const SizedBox(height: 24),
            ShimmerCard(height: 130),
            const SizedBox(height: 12),
            ShimmerCard(height: 130),
            const SizedBox(height: 24),
            ShimmerCard(height: 24, width: 200),
            const SizedBox(height: 16),
            ShimmerCard(height: 280),
            const SizedBox(height: 24),
            ShimmerCard(height: 24, width: 200),
            const SizedBox(height: 16),
            ShimmerCard(height: 100),
            const SizedBox(height: 12),
            ShimmerCard(height: 100),
          ],
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerCard({
    super.key,
    this.width = double.infinity,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
