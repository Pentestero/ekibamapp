import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsChart extends StatelessWidget {
  final String title;
  final Map<String, int> data;

  const AdminAnalyticsChart({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final sortedData = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5Data = sortedData.take(5).toList();
    final currencyFormat = NumberFormat('#,##0', 'fr_FR');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            if (top5Data.isEmpty)
              const Center(child: Text('Aucune donnée disponible.'))
            else
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(
                    majorGridLines: MajorGridLines(width: 0),
                    labelIntersectAction: AxisLabelIntersectAction.rotate45,
                    labelStyle: TextStyle(fontSize: 11),
                  ),
                  primaryYAxis: NumericAxis(
                    numberFormat: currencyFormat,
                    majorGridLines: const MajorGridLines(width: 0.5),
                  ),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: <CartesianSeries>[
                    BarSeries<MapEntry<String, int>, String>(
                      dataSource: top5Data,
                      xValueMapper: (entry, _) {
                        const maxLength = 15;
                        if (entry.key.length > maxLength) {
                          return '${entry.key.substring(0, maxLength)}...';
                        }
                        return entry.key;
                      },
                      yValueMapper: (entry, _) => entry.value,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        textStyle: TextStyle(fontSize: 10),
                      ),
                      name: title,
                      // Apply a gradient color
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
