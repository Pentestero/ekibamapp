import 'package:flutter/material.dart';
import 'package:provisions/widgets/shimmer_loading.dart';

class HistorySkeleton extends StatelessWidget {
  const HistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          // Summary header placeholder
          Container(
            height: 60,
            width: double.infinity,
            color: Colors.white,
            margin: const EdgeInsets.all(16.0),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: 10, // Placeholder for a few items
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(width: 100, height: 16, color: Colors.white),
                            Container(width: 80, height: 16, color: Colors.white),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 4),
                        Container(width: 150, height: 14, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(width: 200, height: 14, color: Colors.white),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(width: 120, height: 16, color: Colors.white),
                            Container(width: 80, height: 14, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
