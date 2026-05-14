import 'package:flutter/material.dart';
import '../widgets/shimmer_loading.dart';

class AdminDashboardSkeleton extends StatelessWidget {
  const AdminDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerCard(height: 130),
            const SizedBox(height: 12),
            ShimmerCard(height: 130),
            const SizedBox(height: 24),
            ShimmerCard(height: 24, width: 250),
            const SizedBox(height: 16),
            ...List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerCard(height: 100),
            )),
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
