import 'package:flutter/material.dart';
import 'package:provisions/widgets/shimmer_loading.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section placeholder
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 24),
            ),
            // Key metrics placeholders
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Chart title placeholder
            Container(
              width: 200,
              height: 20,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
            ),
            // Chart placeholder
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 24),
            ),
            // Second chart title placeholder
            Container(
              width: 200,
              height: 20,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
            ),
            // Second chart placeholder
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 24),
            ),
            // Recent purchases title placeholder
            Container(
              width: 150,
              height: 20,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
            ),
            // Recent purchases list placeholders
            ...List.generate(2, (index) => Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 12),
            )),
          ],
        ),
      ),
    );
  }
}
