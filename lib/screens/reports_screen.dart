import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/widgets/supplier_chart.dart';
import 'package:provisions/widgets/project_type_chart.dart';
import 'package:intl/intl.dart';
import 'package:provisions/widgets/animations.dart';

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

  void _applyFilter() {}

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _customStartDate ??
          DateTime.now().subtract(const Duration(days: 30)),
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 24,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Rapports Avancés'),
          ],
        ),
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final Map<String, int> filteredSupplierTotals =
              provider.supplierTotals;
          final Map<String, int> filteredProjectTypeTotals =
              provider.projectTypeTotals;
          final Map<String, int> filteredCategoryTotals =
              provider.categoryTotals;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: StaggeredList(
              itemDelay: const Duration(milliseconds: 50),
              children: [
                _buildFilterSection(context, cs),
                const SizedBox(height: 24),
                if (provider.errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.error.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: cs.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(provider.errorMessage,
                                style: TextStyle(color: cs.error)),
                          ),
                        ],
                      ),
                    ),
                  ),
                _buildSectionHeader(context, 'Dépenses par Catégorie'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: SupplierChart(data: filteredCategoryTotals),
                ),
                const SizedBox(height: 28),
                _buildSectionHeader(context, 'Dépenses par Fournisseur'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: SupplierChart(data: filteredSupplierTotals),
                ),
                const SizedBox(height: 28),
                _buildSectionHeader(
                    context, 'Dépenses par Type de Projet'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildFilterSection(BuildContext context, ColorScheme cs) {
    String dateRangeText = 'Sélectionner la période';
    if (_selectedFilter == ReportFilter.currentMonth) {
      dateRangeText = 'Mois en cours';
    } else if (_selectedFilter == ReportFilter.last3Months) {
      dateRangeText = '3 derniers mois';
    } else if (_selectedFilter == ReportFilter.currentYear) {
      dateRangeText = 'Année en cours';
    } else if (_selectedFilter == ReportFilter.allTime) {
      dateRangeText = 'Depuis toujours';
    } else if (_selectedFilter == ReportFilter.custom &&
        _customStartDate != null &&
        _customEndDate != null) {
      dateRangeText =
          '${DateFormat('dd/MM/yyyy').format(_customStartDate!)} - ${DateFormat('dd/MM/yyyy').format(_customEndDate!)}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Filtres de rapport'),
            const SizedBox(height: 20),
            DropdownButtonFormField<ReportFilter>(
              initialValue: _selectedFilter,
              decoration: const InputDecoration(
                labelText: 'Période',
              ),
              items: const [
                DropdownMenuItem(
                    value: ReportFilter.currentMonth,
                    child: Text('Mois en cours')),
                DropdownMenuItem(
                    value: ReportFilter.last3Months,
                    child: Text('3 derniers mois')),
                DropdownMenuItem(
                    value: ReportFilter.currentYear,
                    child: Text('Année en cours')),
                DropdownMenuItem(
                    value: ReportFilter.allTime,
                    child: Text('Depuis toujours')),
                DropdownMenuItem(
                    value: ReportFilter.custom,
                    child: Text('Plage personnalisée')),
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
            if (_selectedFilter == ReportFilter.custom &&
                (_customStartDate == null ||
                    _customEndDate == null))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        _selectCustomDateRange(context),
                    child:
                        const Text('Sélectionner la plage personnalisée'),
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
