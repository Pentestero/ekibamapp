import 'package:flutter/material.dart';
import 'package:provisions/widgets/shimmer_loading.dart';

class AdminDashboardSkeleton extends StatelessWidget {
  const AdminDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Key Metrics placeholders
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Purchases List title placeholder
          Container(
            width: 250,
            height: 24,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
          ),
          // Purchases List placeholders (similar to HistorySkeleton)
          ...List.generate(5, (index) => Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 16, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 14, color: Colors.white),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.bottomRight, child: Container(width: 100, height: 16, color: Colors.white)),
                ],
              ),
            ),
          )),
          const SizedBox(height: 24),
          // Chart title placeholder
          Container(
            width: 200,
            height: 24,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 16),
          ),
          // Chart placeholder
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 24),
          ),
          // Second chart title placeholder
          Container(
            width: 200,
            height: 24,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 16),
          ),
          // Second chart placeholder
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
