import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/models/purchase.dart'; // ADD THIS IMPORT
import 'package:provisions/widgets/admin_dashboard_skeleton.dart';
import 'package:provisions/screens/history_screen.dart'; // Re-using PurchaseCard
import 'package:provisions/widgets/analytics_card.dart';
import 'package:provisions/screens/purchase_detail_screen.dart';
import 'package:provisions/widgets/admin_analytics_chart.dart';
import 'package:intl/intl.dart';
import 'package:provisions/widgets/filter_panel.dart'; // Import the filter panel

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  // State
  FilterState _filterState = FilterState();
  bool _isSelectionMode = false;
  Set<int> _selectedPurchaseIds = {};
  
  // Animation
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
    debugPrint('AdminDashboardScreen: _showFilterPanel opened. Current _filterState: ${_filterState.searchQuery}, Year: ${_filterState.year}, Month: ${_filterState.month}');
    final provider = context.read<PurchaseProvider>();
    final availableYears = provider.allPurchases.map((p) => p.date.year).toSet().toList();
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
            debugPrint('AdminDashboardScreen: _showFilterPanel: Filter changed to: ${newFilters.searchQuery}, Year: ${newFilters.year}, Month: ${newFilters.month}');
            provider.loadAllPurchases(newFilters); // Explicit call
          },
        );
      },
    ).then((_) {
      if (mounted) {
        debugPrint('AdminDashboardScreen: _showFilterPanel closed. Reloading all purchases with _filterState: ${_filterState.searchQuery}, Year: ${_filterState.year}, Month: ${_filterState.month}');
        provider.loadAllPurchases(_filterState); // Explicit call
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
    debugPrint('AdminDashboardScreen: build method called. Current _filterState: ${_filterState.searchQuery}, Year: ${_filterState.year}, Month: ${_filterState.month}');
    final currencyFormat = NumberFormat('#,##0', 'fr_FR');
    final provider = context.watch<PurchaseProvider>();
    final filteredPurchases = provider.allPurchases; // Now directly use pre-filtered list
    
    final isAllSelected = _isSelectionMode &&
        filteredPurchases.isNotEmpty &&
        _selectedPurchaseIds.length == filteredPurchases.length;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode ? Text('${_selectedPurchaseIds.length} sélectionné(s)') : const Text('Dashboard Admin'),
        backgroundColor: Theme.of(context).colorScheme.primary, // Make AppBar attractive
        foregroundColor: Theme.of(context).colorScheme.onPrimary, // Ensure icons and text are visible
        actions: _buildAppBarActions(provider, filteredPurchases, isAllSelected),
      ),
      body: provider.isLoading
          ? AdminDashboardSkeleton()
          : FadeTransition(
              opacity: _contentFadeAnimation,
              child: RefreshIndicator(
                onRefresh: () => provider.loadAllPurchases(_filterState), // Pass current filter state
                child: Column(
                  children: [
                    _buildFilterChipsBar(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          _buildKeyMetrics(currencyFormat, provider),
                          const SizedBox(height: 24),
                          Text('Toutes les Demandes d\'Achat', style: Theme.of(context).textTheme.headlineSmall),
                          const Divider(height: 20),
                          _buildPurchasesList(filteredPurchases),
                          const SizedBox(height: 24),
                          AdminAnalyticsChart(title: 'Top 5 Dépenseurs (Admin)', data: provider.topSpenders),
                          AdminAnalyticsChart(title: 'Top Méthodes de Paiement (Admin)', data: provider.topPaymentMethods),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: _buildFab(provider, filteredPurchases),
    );
  }

  List<Widget> _buildAppBarActions(PurchaseProvider provider, List<Purchase> filteredList, bool isAllSelected) {
    if (_isSelectionMode) {
      return [
        Checkbox(
          value: isAllSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedPurchaseIds = filteredList.map((p) => p.id!).toSet();
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
        onPressed: () => provider.loadAllPurchases(_filterState), // Pass current filter state
      ),
    ];
  }

  Widget _buildFilterChipsBar() {
    // This is identical to the one in HistoryScreen, can be extracted to a common widget later
    List<Widget> chips = [];
    if (_filterState.searchQuery.isNotEmpty) {
      chips.add(Chip(label: Text('Recherche: "${_filterState.searchQuery}"'), onDeleted: () => setState(() => _filterState = _filterState.copyWith(searchQuery: ''))));
    }
    if (_filterState.year != null) {
      chips.add(Chip(label: Text('Année: ${_filterState.year}'), onDeleted: () => setState(() => _filterState = _filterState.copyWith(resetYear: true))));
    }
    if (_filterState.month != null) {
      chips.add(Chip(label: Text('Mois: ${_filterState.month != null ? DateFormat.MMMM('fr_FR').format(DateTime(0, _filterState.month!)) : ''}'), onDeleted: () => setState(() => _filterState = _filterState.copyWith(resetMonth: true))));
    }
    if (_filterState.startDate != null) {
      chips.add(Chip(label: Text('Date début: ${DateFormat('dd/MM/yyyy').format(_filterState.startDate!)}'), onDeleted: () => setState(() => _filterState = _filterState.copyWith(resetStartDate: true))));
    }
    if (_filterState.endDate != null) {
      chips.add(Chip(label: Text('Date fin: ${DateFormat('dd/MM/yyyy').format(_filterState.endDate!)}'), onDeleted: () => setState(() => _filterState = _filterState.copyWith(resetEndDate: true))));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Wrap(spacing: 8.0, children: chips)),
    );
  }

  Widget _buildKeyMetrics(NumberFormat currencyFormat, PurchaseProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          AnalyticsCard(
            title: 'Total Dépensé (Tous)',
            value: '${currencyFormat.format(provider.grandTotalSpentAll)} XAF',
            icon: Icons.monetization_on,
            color: Theme.of(context).colorScheme.primary,
          ),
          AnalyticsCard(
            title: 'Nombre d\'Achats (Tous)',
            value: provider.totalNumberOfPurchasesAll.toString(),
            icon: Icons.receipt_long,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ];
        if (constraints.maxWidth < 600) {
          return Column(children: [cards[0], const SizedBox(height: 12), cards[1]]);
        }
        return Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]);
      },
    );
  }

  Widget _buildPurchasesList(List<Purchase> filteredPurchases) {
    if (filteredPurchases.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('Aucun achat trouvé correspondant aux filtres.'),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredPurchases.length,
      itemBuilder: (context, index) {
        final purchase = filteredPurchases[index];
        return InkWell(
          onTap: () {
            if (!_isSelectionMode) {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => PurchaseDetailScreen(purchase: purchase)));
            } else {
              _togglePurchaseSelection(purchase.id!);
            }
          },
          child: PurchaseCard(
            purchase: purchase,
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedPurchaseIds.contains(purchase.id),
            onToggleSelection: () => _togglePurchaseSelection(purchase.id!),
          ),
        );
      },
    );
  }

  Widget? _buildFab(PurchaseProvider provider, List<Purchase> filteredPurchases) {
    final bool canExport = _isSelectionMode ? _selectedPurchaseIds.isNotEmpty : filteredPurchases.isNotEmpty;
    final String label = _isSelectionMode ? 'Exporter la sélection (${_selectedPurchaseIds.length})' : 'Exporter la liste (${filteredPurchases.length})';
    
    return FloatingActionButton.extended(
      onPressed: canExport ? () {
        final List<Purchase> toExport;
        if (_isSelectionMode) {
          toExport = provider.allPurchases.where((p) => _selectedPurchaseIds.contains(p.id!)).toList();
        } else {
          toExport = filteredPurchases;
        }
        provider.exportToExcel(toExport);
      } : null,
      icon: const Icon(Icons.file_download),
      label: Text(label),
      backgroundColor: canExport ? Theme.of(context).colorScheme.primary : Colors.grey,
    );
  }
}