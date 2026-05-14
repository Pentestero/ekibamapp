import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/models/purchase.dart';
import 'package:intl/intl.dart';
import 'package:provisions/widgets/app_brand.dart';
import 'package:provisions/widgets/history_skeleton.dart';
import 'package:provisions/widgets/filter_panel.dart';
import 'package:provisions/widgets/animations.dart';

class HistoryScreen extends StatefulWidget {
  final Function(Purchase purchase)? onEditPurchase;
  const HistoryScreen({super.key, this.onEditPurchase});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _contentController;
  late final Animation<double> _contentFadeAnimation;

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
    debugPrint(
        'HistoryScreen: _showFilterPanel opened. Current _filterState: ${_filterState.searchQuery}, Year: ${_filterState.year}, Month: ${_filterState.month}');
    final provider = context.read<PurchaseProvider>();
    final availableYears =
        provider.purchases.map((p) => p.date.year).toSet().toList();
    availableYears.sort((a, b) => b.compareTo(a));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return FilterPanel(
          initialFilters: _filterState,
          availableYears: availableYears,
          onFilterChanged: (newFilters) {
            setState(() => _filterState = newFilters);
            debugPrint(
                'HistoryScreen: _showFilterPanel: Filter changed to: ${newFilters.searchQuery}, Year: ${newFilters.year}, Month: ${newFilters.month}');
            provider.loadPurchases(newFilters);
            if (mounted &&
                (newFilters.startDate != null ||
                    newFilters.endDate != null)) {
              final infoColor = Theme.of(context).brightness == Brightness.light
                  ? Colors.green.shade600
                  : Colors.green.shade400;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color:
                              Theme.of(context).colorScheme.onPrimary),
                      const SizedBox(width: 8),
                      const Text('Filtre par date appliqué'),
                    ],
                  ),
                  backgroundColor: infoColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    ).then((_) {
      if (mounted) {
        debugPrint(
            'HistoryScreen: _showFilterPanel closed. Reloading purchases with _filterState: ${_filterState.searchQuery}, Year: ${_filterState.year}, Month: ${_filterState.month}');
        provider.loadPurchases(_filterState);
      }
    });
  }

  void _onExport(List<Purchase> purchasesToExport) {
    if (purchasesToExport.isEmpty) {
      final warningColor = Theme.of(context).brightness == Brightness.light
          ? Colors.orange.shade700
          : Colors.orange.shade400;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.onPrimary),
              const SizedBox(width: 8),
              const Text('Aucun achat à exporter.'),
            ],
          ),
          backgroundColor: warningColor,
          duration: const Duration(seconds: 3),
        ),
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
    final cs = Theme.of(context).colorScheme;
    debugPrint(
        'HistoryScreen: build method called. Current _filterState: ${_filterState.searchQuery}, Year: ${_filterState.year}, Month: ${_filterState.month}');
    final provider = context.watch<PurchaseProvider>();
    final purchasesToDisplay = provider.purchases;

    final isAllSelected = _isSelectionMode &&
        purchasesToDisplay.isNotEmpty &&
        _selectedPurchaseIds.length == purchasesToDisplay.length;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedPurchaseIds.length} sélectionné(s)')
            : const AppBrand(),
        actions: _buildAppBarActions(
            provider, purchasesToDisplay, isAllSelected, cs),
      ),
      body: _buildBody(provider, purchasesToDisplay, cs),
    );
  }

  List<Widget> _buildAppBarActions(PurchaseProvider provider,
      List<Purchase> purchasesToDisplay, bool isAllSelected, ColorScheme cs) {
    if (_isSelectionMode) {
      return [
        Checkbox(
          value: isAllSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedPurchaseIds =
                    purchasesToDisplay.map((p) => p.id!).toSet();
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
                  final selected = provider.purchases
                      .where((p) => _selectedPurchaseIds.contains(p.id!))
                      .toList();
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
          tooltip: 'Télécharger la liste filtrée (Excel)',
          onPressed: () => _onExport(purchasesToDisplay),
        ),
      ];
    }
  }

  Widget _buildBody(PurchaseProvider provider,
      List<Purchase> purchasesToDisplay, ColorScheme cs) {
    if (provider.isLoading && purchasesToDisplay.isEmpty) {
      return HistorySkeleton();
    }
    if (provider.errorMessage.isNotEmpty) {
      return _buildErrorWidget(context, provider);
    }

    return FadeTransition(
      opacity: _contentFadeAnimation,
      child: RefreshIndicator(
        onRefresh: () => provider.loadPurchases(_filterState),
        child: Column(
          children: [
            _buildFilterChipsBar(cs),
            Expanded(
              child: purchasesToDisplay.isEmpty
                  ? _buildEmptyStateWidget(cs)
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: purchasesToDisplay.length,
                      itemBuilder: (context, index) {
                        final purchase = purchasesToDisplay[index];
                        final card = StaggeredItem(
                          index: index,
                          itemDelay: const Duration(milliseconds: 40),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          child: PurchaseCard(
                            purchase: purchase,
                            isSelectionMode: _isSelectionMode,
                            isSelected:
                                _selectedPurchaseIds.contains(purchase.id),
                            onToggleSelection: () =>
                                _togglePurchaseSelection(purchase.id!),
                            onEditPurchase: widget.onEditPurchase,
                          ),
                        );
                        return _isSelectionMode
                            ? card
                            : SwipeToDismiss(
                                dismissKey:
                                    ValueKey('dismiss_${purchase.id}'),
                                onDelete: () {
                                  context
                                      .read<PurchaseProvider>()
                                      .deletePurchase(purchase.id!);
                                },
                                confirmLabel:
                                    'Supprimer l\'achat ${purchase.refDA ?? ''} ?',
                                child: card,
                              );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipsBar(ColorScheme cs) {
    List<Widget> chips = [];
    final provider = context.read<PurchaseProvider>();

    if (_filterState.searchQuery.isNotEmpty) {
      chips.add(Chip(
        label: Text('Recherche: "${_filterState.searchQuery}"'),
        onDeleted: () {
          setState(() {
            _filterState = _filterState.copyWith(searchQuery: '');
          });
          provider.loadPurchases(_filterState);
        },
      ));
    }
    if (_filterState.year != null) {
      chips.add(Chip(
        label: Text('Année: ${_filterState.year}'),
        onDeleted: () {
          setState(() {
            _filterState = _filterState.copyWith(resetYear: true);
          });
          provider.loadPurchases(_filterState);
        },
      ));
    }
    if (_filterState.month != null) {
      chips.add(Chip(
        label: Text(
            'Mois: ${_filterState.month != null ? DateFormat.MMMM('fr_FR').format(DateTime(0, _filterState.month!)) : ''}'),
        onDeleted: () {
          setState(() {
            _filterState = _filterState.copyWith(resetMonth: true);
          });
          provider.loadPurchases(_filterState);
        },
      ));
    }
    if (_filterState.startDate != null) {
      chips.add(Chip(
        label: Text(
            'Date début: ${DateFormat('dd/MM/yyyy').format(_filterState.startDate!)}'),
        onDeleted: () {
          setState(() {
            _filterState = _filterState.copyWith(resetStartDate: true);
          });
          provider.loadPurchases(_filterState);
        },
      ));
    }
    if (_filterState.endDate != null) {
      chips.add(Chip(
        label: Text(
            'Date fin: ${DateFormat('dd/MM/yyyy').format(_filterState.endDate!)}'),
        onDeleted: () {
          setState(() {
            _filterState = _filterState.copyWith(resetEndDate: true);
          });
          provider.loadPurchases(_filterState);
        },
      ));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: cs.surfaceContainerHighest.withAlpha(80),
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
    final cs = Theme.of(context).colorScheme;
    final isNetworkError = provider.errorMessage.contains('Failed to fetch');
    final errorMessage = isNetworkError
        ? 'Erreur de connexion.\nVeuillez vérifier votre connexion internet et réessayer.'
        : provider.errorMessage;

    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
            isNetworkError ? Icons.wifi_off : Icons.error_outline,
            size: 64,
            color: cs.error),
        const SizedBox(height: 16),
        Text(errorMessage, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: () => provider.loadPurchases(_filterState),
            child: const Text('Réessayer')),
      ]),
    );
  }

  Widget _buildEmptyStateWidget(ColorScheme cs) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: cs.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(24),
          ),
          child:
              Icon(Icons.history, size: 36, color: cs.primary.withAlpha(120)),
        ),
        const SizedBox(height: 16),
        Text('Aucun achat trouvé',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Aucun achat ne correspond aux filtres actuels.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurface.withAlpha(150))),
      ]),
    );
  }
}

class PurchaseCard extends StatelessWidget {
  final Purchase purchase;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final Function(Purchase purchase)? onEditPurchase;

  const PurchaseCard({
    super.key,
    required this.purchase,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onToggleSelection,
    this.onEditPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: InkWell(
        onTap: isSelectionMode ? onToggleSelection : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
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
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: cs.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildTrailingActions(context, cs),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.person_outline, purchase.demander, cs),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                        Icons.work_outline,
                        purchase.projectType == 'Client' &&
                                (purchase.clientName?.isNotEmpty ?? false)
                            ? 'Projet: ${purchase.projectType} (${purchase.clientName})'
                            : 'Projet: ${purchase.projectType}',
                        cs),
                    if (purchase.items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Articles (${purchase.items.length}): ${purchase.items.map((item) => item.subCategory2 ?? item.subCategory1).take(2).join(', ')}${purchase.items.length > 2 ? '...' : ''}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${NumberFormat('#,##0', 'fr_FR').format(purchase.grandTotal)} XAF',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(purchase.date),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurface.withAlpha(120)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Créé le: ${DateFormat('dd/MM/yyyy').format(purchase.createdAt.toLocal())}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurface.withAlpha(100)),
                    ),
                    if (purchase.modifiedAt != null &&
                        purchase.modifiedAt!
                                .difference(purchase.createdAt)
                                .inSeconds >
                            5)
                      Text(
                        'Modifié le: ${DateFormat('dd/MM/yyyy').format(purchase.modifiedAt!.toLocal())}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurface.withAlpha(100)),
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

  Widget _buildInfoRow(IconData icon, String text, ColorScheme cs) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurface.withAlpha(120)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withAlpha(180))),
        ),
      ],
    );
  }

  Widget _buildTrailingActions(BuildContext context, ColorScheme cs) {
    if (isSelectionMode) {
      return const SizedBox.shrink();
    }

    final provider = context.read<PurchaseProvider>();

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'pdf') {
          provider.exportInvoiceToPdf(purchase);
        } else if (value == 'edit') {
          onEditPurchase?.call(purchase);
        } else if (value == 'delete') {
          _showDeleteDialog(context, provider, purchase, cs);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pdf',
          child: Row(children: [
            Icon(Icons.picture_as_pdf, color: Colors.red.shade600, size: 20),
            const SizedBox(width: 8),
            const Text('Télécharger PDF'),
          ]),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            const Text('Modifier'),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete, color: cs.error, size: 20),
            const SizedBox(width: 8),
            const Text('Supprimer'),
          ]),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, PurchaseProvider provider,
      Purchase purchase, ColorScheme cs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'achat'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer cet achat du ${DateFormat('dd/MM/yyyy').format(purchase.date)} ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler')),
          TextButton(
            child: Text('Supprimer',
                style: TextStyle(color: cs.error)),
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
