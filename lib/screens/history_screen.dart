import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/models/purchase.dart';
import 'package:intl/intl.dart';
import 'package:provisions/widgets/app_brand.dart';
import 'package:provisions/screens/purchase_form_screen.dart';
import 'package:provisions/widgets/history_skeleton.dart';
import 'package:provisions/widgets/filter_panel.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  // Animation
  late final AnimationController _contentController;
  late final Animation<double> _contentFadeAnimation;

  // State
  FilterState _filterState = FilterState();
  bool _isSelectionMode = false;
  Set<int> _selectedPurchaseIds = {};

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _contentFadeAnimation = CurvedAnimation(parent: _contentController, curve: Curves.easeIn);
    _contentController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _showFilterPanel() {
    final provider = context.read<PurchaseProvider>();
    final availableYears = provider.purchases.map((p) => p.date.year).toSet().toList();
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
          },
        );
      },
    );
  }

  List<Purchase> _getFilteredAndSortedPurchases(List<Purchase> allPurchases) {
    List<Purchase> filteredList = List.from(allPurchases);

    if (_filterState.searchQuery.isNotEmpty) {
      final query = _filterState.searchQuery.toLowerCase();
      filteredList = filteredList.where((p) {
        return (p.refDA?.toLowerCase().contains(query) ?? false) ||
            (p.demander.toLowerCase().contains(query)) ||
            (p.clientName?.toLowerCase().contains(query) ?? false) ||
            p.items.any((item) =>
                item.category.toLowerCase().contains(query) ||
                item.subCategory1.toLowerCase().contains(query) ||
                (item.subCategory2?.toLowerCase().contains(query) ?? false));
      }).toList();
    }

    if (_filterState.year != null) {
      filteredList = filteredList.where((p) => p.date.year == _filterState.year).toList();
    }

    if (_filterState.month != null) {
      filteredList = filteredList.where((p) => p.date.month == _filterState.month).toList();
    }

    switch (_filterState.sortOption) {
      case SortOption.dateAsc:
        filteredList.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.dateDesc:
        filteredList.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.amountAsc:
        filteredList.sort((a, b) => a.grandTotal.compareTo(b.grandTotal));
        break;
      case SortOption.amountDesc:
        filteredList.sort((a, b) => b.grandTotal.compareTo(a.grandTotal));
        break;
    }

    return filteredList;
  }

  void _onExport(List<Purchase> purchasesToExport) {
    if (purchasesToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun achat à exporter.'), backgroundColor: Colors.orange),
      );
      return;
    }
    context.read<PurchaseProvider>().exportToExcel(purchasesToExport);
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
    final provider = context.watch<PurchaseProvider>();
    final allPurchases = provider.purchases;
    final filteredAndSortedPurchases = _getFilteredAndSortedPurchases(allPurchases);

    final isAllSelected = _isSelectionMode &&
        filteredAndSortedPurchases.isNotEmpty &&
        _selectedPurchaseIds.length == filteredAndSortedPurchases.length;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode ? Text('${_selectedPurchaseIds.length} sélectionné(s)') : const AppBrand(),
        actions: _buildAppBarActions(provider, filteredAndSortedPurchases, isAllSelected),
      ),
      body: _buildBody(provider, filteredAndSortedPurchases),
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
          icon: const Icon(Icons.download),
          tooltip: 'Exporter la sélection',
          onPressed: _selectedPurchaseIds.isNotEmpty
              ? () {
                  final selected = provider.purchases.where((p) => _selectedPurchaseIds.contains(p.id!)).toList();
                  _onExport(selected);
                }
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.cancel),
          tooltip: 'Annuler la sélection',
          onPressed: _toggleSelectionMode,
        ),
      ];
    } else {
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
          icon: const Icon(Icons.file_download),
          tooltip: 'Exporter la liste filtrée',
          onPressed: () => _onExport(filteredList),
        ),
      ];
    }
  }

  Widget _buildBody(PurchaseProvider provider, List<Purchase> filteredAndSortedPurchases) {
    if (provider.isLoading && provider.purchases.isEmpty) {
      return HistorySkeleton();
    }
    if (provider.errorMessage.isNotEmpty) {
      return _buildErrorWidget(context, provider);
    }
    
    return FadeTransition(
      opacity: _contentFadeAnimation,
      child: RefreshIndicator(
        onRefresh: () => provider.loadPurchases(),
        child: Column(
          children: [
            _buildFilterChipsBar(),
            Expanded(
              child: filteredAndSortedPurchases.isEmpty
                  ? _buildEmptyStateWidget(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredAndSortedPurchases.length,
                      itemBuilder: (context, index) {
                        final purchase = filteredAndSortedPurchases[index];
                        return PurchaseCard(
                          purchase: purchase,
                          isSelectionMode: _isSelectionMode,
                          isSelected: _selectedPurchaseIds.contains(purchase.id),
                          onToggleSelection: () => _togglePurchaseSelection(purchase.id!),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipsBar() {
    List<Widget> chips = [];
    if (_filterState.searchQuery.isNotEmpty) {
      chips.add(Chip(
        label: Text('Recherche: "${_filterState.searchQuery}"'),
        onDeleted: () => setState(() => _filterState = _filterState.copyWith(searchQuery: '')),
      ));
    }
    if (_filterState.year != null) {
      chips.add(Chip(
        label: Text('Année: ${_filterState.year}'),
        onDeleted: () => setState(() => _filterState = _filterState.copyWith(resetYear: true)),
      ));
    }
    if (_filterState.month != null) {
      chips.add(Chip(
        label: Text('Mois: ${_filterState.month != null ? DateFormat.MMMM('fr_FR').format(DateTime(0, _filterState.month!)) : ''}'),
        onDeleted: () => setState(() => _filterState = _filterState.copyWith(resetMonth: true)),
      ));
    }
    
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          spacing: 8.0,
          children: chips,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, PurchaseProvider provider) {
    final isNetworkError = provider.errorMessage.contains('Failed to fetch');
    final errorMessage = isNetworkError
        ? 'Erreur de connexion.\nVeuillez vérifier votre connexion internet et réessayer.'
        : provider.errorMessage;

    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(isNetworkError ? Icons.wifi_off : Icons.error_outline, size: 64, color: Colors.red),
      const SizedBox(height: 16), Text(errorMessage, textAlign: TextAlign.center),
      const SizedBox(height: 16), ElevatedButton(onPressed: () => provider.loadPurchases(), child: const Text('Réessayer')),
    ]));
  }

  Widget _buildEmptyStateWidget(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.history, size: 64, color: Colors.grey),
      const SizedBox(height: 16), Text('Aucun achat trouvé pour les filtres actuels'),
    ]));
  }
}

class PurchaseCard extends StatelessWidget {
  final Purchase purchase;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelection;

  const PurchaseCard({
    super.key,
    required this.purchase,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      elevation: 3,
      child: InkWell(
        onTap: isSelectionMode ? onToggleSelection : null,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) => onToggleSelection(),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            purchase.refDA ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildTrailingActions(context),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 4),
                    Text('Demandeur: ${purchase.demander}', overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      purchase.projectType == 'Client' && (purchase.clientName?.isNotEmpty ?? false)
                          ? 'Projet: ${purchase.projectType} (${purchase.clientName})'
                          : 'Projet: ${purchase.projectType}',
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 8),
                    if (purchase.items.isNotEmpty) ...[
                      Text(
                        'Articles (${purchase.items.length}): ${purchase.items.map((item) => item.subCategory2 ?? item.subCategory1).take(2).join(', ')}${purchase.items.length > 2 ? '...' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${NumberFormat('#,##0', 'fr_FR').format(purchase.grandTotal)} XAF',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(DateFormat('dd/MM/yyyy').format(purchase.date)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingActions(BuildContext context) {
    if (isSelectionMode) {
      return const SizedBox.shrink(); // Hide actions in selection mode
    }

    final provider = context.read<PurchaseProvider>();

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'pdf') {
          provider.exportInvoiceToPdf(purchase);
        } else if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PurchaseFormScreen(purchase: purchase),
            ),
          );
        } else if (value == 'delete') {
          _showDeleteDialog(context, provider, purchase);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pdf',
          child: Row(children: [
            Icon(Icons.picture_as_pdf, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Générer PDF'),
          ]),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Modifier'),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            const Text('Supprimer'),
          ]),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, PurchaseProvider provider, Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'achat'),
        content: Text('Êtes-vous sûr de vouloir supprimer cet achat du ${DateFormat('dd/MM/yyyy').format(purchase.date)} ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          TextButton(
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop();
              provider.deletePurchase(purchase.id!);
            },
          ),
        ],
      ),
    );
  }
}
