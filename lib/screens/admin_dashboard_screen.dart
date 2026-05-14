import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/widgets/admin_dashboard_skeleton.dart';
import 'package:provisions/screens/history_screen.dart';
import 'package:provisions/widgets/analytics_card.dart';
import 'package:provisions/screens/purchase_detail_screen.dart';
import 'package:provisions/widgets/admin_analytics_chart.dart';
import 'package:intl/intl.dart';
import 'package:provisions/widgets/filter_panel.dart';
import 'package:provisions/widgets/animations.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  FilterState _filterState = FilterState();
  bool _isSelectionMode = false;
  Set<int> _selectedPurchaseIds = {};

  late final AnimationController _contentController;
  late final Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadAllPurchases(_filterState);
    });

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _contentFadeAnimation =
        CurvedAnimation(parent: _contentController, curve: Curves.easeIn);
    _contentController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _showFilterPanel() {
    final provider = context.read<PurchaseProvider>();
    final availableYears =
        provider.allPurchases.map((p) => p.date.year).toSet().toList();
    availableYears.sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FilterPanel(
          initialFilters: _filterState,
          availableYears: availableYears,
          onFilterChanged: (newFilters) {
            setState(() {
              _filterState = newFilters;
            });
            provider.loadAllPurchases(newFilters);
          },
        );
      },
    ).then((_) {
      if (mounted) {
        provider.loadAllPurchases(_filterState);
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedPurchaseIds.clear();
    });
  }

  void _togglePurchaseSelection(int purchaseId) {
    setState(() {
      if (_selectedPurchaseIds.contains(purchaseId)) {
        _selectedPurchaseIds.remove(purchaseId);
      } else {
        _selectedPurchaseIds.add(purchaseId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat('#,##0', 'fr_FR');
    final provider = context.watch<PurchaseProvider>();
    final filteredPurchases = provider.allPurchases;

    final isAllSelected = _isSelectionMode &&
        filteredPurchases.isNotEmpty &&
        _selectedPurchaseIds.length == filteredPurchases.length;

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
            Text(_isSelectionMode
                ? '${_selectedPurchaseIds.length} sélectionné(s)'
                : 'Dashboard Admin'),
          ],
        ),
        actions: _buildAppBarActions(
            provider, filteredPurchases, isAllSelected, cs),
      ),
      body: provider.isLoading
          ? AdminDashboardSkeleton()
          : FadeTransition(
              opacity: _contentFadeAnimation,
              child: RefreshIndicator(
                onRefresh: () =>
                    provider.loadAllPurchases(_filterState),
                child: Column(
                  children: [
                    _buildFilterChipsBar(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildKeyMetrics(currencyFormat, provider, cs),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                              context, 'Toutes les Demandes d\'Achat'),
                          const SizedBox(height: 16),
                          _buildPurchasesList(filteredPurchases, cs),
                          const SizedBox(height: 24),
                          AdminAnalyticsChart(
                              title: 'Top 5 Dépenseurs (Admin)',
                              data: provider.topSpenders),
                          const SizedBox(height: 16),
                          AdminAnalyticsChart(
                              title: 'Top Méthodes de Paiement (Admin)',
                              data: provider.topPaymentMethods),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: _buildFab(provider, filteredPurchases, cs),
    );
  }

  List<Widget> _buildAppBarActions(PurchaseProvider provider,
      List<Purchase> filteredList, bool isAllSelected, ColorScheme cs) {
    if (_isSelectionMode) {
      return [
        Checkbox(
          value: isAllSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedPurchaseIds =
                    filteredList.map((p) => p.id!).toSet();
              } else {
                _selectedPurchaseIds.clear();
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.cancel),
          tooltip: 'Annuler la sélection',
          onPressed: _toggleSelectionMode,
        ),
      ];
    }
    return [
      IconButton(
        icon: const Icon(Icons.filter_list),
        tooltip: 'Filtrer et Trier',
        onPressed: _showFilterPanel,
      ),
      IconButton(
        icon: const Icon(Icons.select_all),
        tooltip: 'Sélectionner des achats',
        onPressed: _toggleSelectionMode,
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => provider.loadAllPurchases(_filterState),
      ),
    ];
  }

  Widget _buildFilterChipsBar() {
    List<Widget> chips = [];
    if (_filterState.searchQuery.isNotEmpty) {
      chips.add(Chip(
          label: Text('Recherche: "${_filterState.searchQuery}"'),
          onDeleted: () => setState(
              () => _filterState = _filterState.copyWith(searchQuery: ''))));
    }
    if (_filterState.year != null) {
      chips.add(Chip(
          label: Text('Année: ${_filterState.year}'),
          onDeleted: () => setState(
              () => _filterState = _filterState.copyWith(resetYear: true))));
    }
    if (_filterState.month != null) {
      chips.add(Chip(
          label: Text(
              'Mois: ${_filterState.month != null ? DateFormat.MMMM('fr_FR').format(DateTime(0, _filterState.month!)) : ''}'),
          onDeleted: () => setState(
              () => _filterState = _filterState.copyWith(resetMonth: true))));
    }
    if (_filterState.startDate != null) {
      chips.add(Chip(
          label: Text(
              'Date début: ${DateFormat('dd/MM/yyyy').format(_filterState.startDate!)}'),
          onDeleted: () => setState(
              () => _filterState = _filterState.copyWith(resetStartDate: true))));
    }
    if (_filterState.endDate != null) {
      chips.add(Chip(
          label: Text(
              'Date fin: ${DateFormat('dd/MM/yyyy').format(_filterState.endDate!)}'),
          onDeleted: () => setState(
              () => _filterState = _filterState.copyWith(resetEndDate: true))));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
      child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(spacing: 8.0, children: chips)),
    );
  }

  Widget _buildKeyMetrics(
      NumberFormat currencyFormat, PurchaseProvider provider, ColorScheme cs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          AnalyticsCard(
            title: 'Total Dépensé (Tous)',
            value: '${currencyFormat.format(provider.grandTotalSpentAll)} XAF',
            icon: Icons.monetization_on,
            color: cs.primary,
          ),
          AnalyticsCard(
            title: "Nombre d'Achats (Tous)",
            value: provider.totalNumberOfPurchasesAll.toString(),
            icon: Icons.receipt_long,
            color: cs.secondary,
          ),
        ];
        if (constraints.maxWidth < 600) {
          return Column(
              children: [cards[0], const SizedBox(height: 12), cards[1]]);
        }
        return Row(children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1])
        ]);
      },
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

  Widget _buildPurchasesList(List<Purchase> filteredPurchases, ColorScheme cs) {
    if (filteredPurchases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.search_off,
                    size: 32, color: cs.primary.withAlpha(120)),
              ),
              const SizedBox(height: 16),
              Text('Aucun achat trouvé',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }
    return StaggeredList(
      itemDelay: const Duration(milliseconds: 40),
      children: filteredPurchases.map((purchase) {
        return ScaleTap(
          onTap: _isSelectionMode
              ? () => _togglePurchaseSelection(purchase.id!)
              : () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          PurchaseDetailScreen(purchase: purchase)));
                },
          child: PurchaseCard(
            purchase: purchase,
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedPurchaseIds.contains(purchase.id),
            onToggleSelection: () =>
                _togglePurchaseSelection(purchase.id!),
          ),
        );
      }).toList(),
    );
  }

  Widget? _buildFab(PurchaseProvider provider,
      List<Purchase> filteredPurchases, ColorScheme cs) {
    final bool canExport = _isSelectionMode
        ? _selectedPurchaseIds.isNotEmpty
        : filteredPurchases.isNotEmpty;
    final String label = _isSelectionMode
        ? 'Exporter la sélection (${_selectedPurchaseIds.length})'
        : 'Exporter la liste (${filteredPurchases.length})';

    return FloatingActionButton.extended(
      onPressed: canExport
          ? () {
              final List<Purchase> toExport;
              if (_isSelectionMode) {
                toExport = provider.allPurchases
                    .where((p) => _selectedPurchaseIds.contains(p.id!))
                    .toList();
              } else {
                toExport = filteredPurchases;
              }
              provider.exportToExcel(toExport);
            }
          : null,
      icon: const Icon(Icons.file_download),
      label: Text(label),
      backgroundColor: canExport ? cs.primary : Colors.grey,
    );
  }
}
