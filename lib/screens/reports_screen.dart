// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/widgets/supplier_chart.dart'; // Reusing for generic data
import 'package:provisions/widgets/project_type_chart.dart'; // Reusing for generic data
import 'package:intl/intl.dart';

enum ReportFilter {
  currentMonth,
  last3Months,
  currentYear,
  allTime,
  custom,
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportFilter _selectedFilter = ReportFilter.currentMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  void _applyFilter() {
    final provider = context.read<PurchaseProvider>();
    // Logic to filter data from provider based on _selectedFilter
    // This will likely require new methods in PurchaseProvider to return filtered data
    // For now, we'll just use the existing totals and will add filtering later if requested.
    // provider.filterReports(filter: _selectedFilter, startDate: _customStartDate, endDate: _customEndDate);
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _customStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _customEndDate ?? DateTime.now(),
    );

    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
      helpText: 'Sélectionner une plage de dates',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      saveText: 'Enregistrer',
    );

    if (newDateRange != null) {
      setState(() {
        _customStartDate = newDateRange.start;
        _customEndDate = newDateRange.end;
        _selectedFilter = ReportFilter.custom;
      });
      _applyFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports Avancés'),
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Placeholder for filtered data - in a real scenario, provider would return filtered maps
          final Map<String, int> filteredSupplierTotals = provider.supplierTotals;
          final Map<String, int> filteredProjectTypeTotals = provider.projectTypeTotals;
          // You'd also need a filtered category total here
          final Map<String, int> filteredCategoryTotals = provider.categoryTotals; // Use actual category totals

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterSection(context),
                const SizedBox(height: 24),

                if (provider.errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Erreur: ${provider.errorMessage}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red),
                    ),
                  ),

                Text('Dépenses par Catégorie', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: SupplierChart(data: filteredCategoryTotals), // Use Category Chart
                ),
                const SizedBox(height: 24),

                Text('Dépenses par Fournisseur', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: SupplierChart(data: filteredSupplierTotals),
                ),
                const SizedBox(height: 24),

                Text('Dépenses par Type de Projet', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: ProjectTypeChart(data: filteredProjectTypeTotals),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    String dateRangeText = 'Sélectionner la période';
    if (_selectedFilter == ReportFilter.currentMonth) {
      dateRangeText = 'Mois en cours';
    } else if (_selectedFilter == ReportFilter.last3Months) {
      dateRangeText = '3 derniers mois';
    } else if (_selectedFilter == ReportFilter.currentYear) {
      dateRangeText = 'Année en cours';
    } else if (_selectedFilter == ReportFilter.allTime) {
      dateRangeText = 'Depuis toujours';
    } else if (_selectedFilter == ReportFilter.custom && _customStartDate != null && _customEndDate != null) {
      dateRangeText = '${DateFormat('dd/MM/yyyy').format(_customStartDate!)} - ${DateFormat('dd/MM/yyyy').format(_customEndDate!)}';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtres de rapport', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReportFilter>(
              initialValue: _selectedFilter,
              decoration: const InputDecoration(
                labelText: 'Période',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: ReportFilter.currentMonth, child: Text('Mois en cours')),
                DropdownMenuItem(value: ReportFilter.last3Months, child: Text('3 derniers mois')),
                DropdownMenuItem(value: ReportFilter.currentYear, child: Text('Année en cours')),
                DropdownMenuItem(value: ReportFilter.allTime, child: Text('Depuis toujours')),
                DropdownMenuItem(value: ReportFilter.custom, child: Text('Plage personnalisée')),
              ],
              onChanged: (filter) {
                if (filter != null) {
                  setState(() {
                    _selectedFilter = filter;
                    if (filter == ReportFilter.custom) {
                      _selectCustomDateRange(context);
                    } else {
                      _customStartDate = null;
                      _customEndDate = null;
                      _applyFilter();
                    }
                  });
                }
              },
            ),
            if (_selectedFilter == ReportFilter.custom && (_customStartDate == null || _customEndDate == null))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => _selectCustomDateRange(context),
                    child: const Text('Sélectionner la plage personnalisée'),
                  ),
                ),
              ),
            if (_selectedFilter != ReportFilter.custom)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Période actuelle: $dateRangeText'),
              ),
          ],
        ),
      ),
    );
  }
}
