import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/screens/help_screen.dart';
import 'package:provisions/screens/library_management_screen.dart';
import 'package:provisions/screens/purchase_detail_screen.dart';
import 'package:provisions/screens/reports_screen.dart';
import 'package:provisions/services/auth_service.dart';
import 'package:provisions/widgets/animations.dart';
import 'package:provisions/widgets/filter_panel.dart';
import 'package:provisions/widgets/history_filter_sheet.dart';
import 'package:provisions/widgets/history_skeleton.dart';

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
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

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
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    final provider = context.read<PurchaseProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: HistoryFilterSheet(
              initialFilters: _filterState,
              onFilterChanged: (newFilters) {
                setState(() => _filterState = newFilters);
                provider.loadPurchases(newFilters);
              },
            ),
          ),
        );
      },
    );
  }

  void _applySearch(String text, {required bool immediate}) {
    if (!immediate) {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 350), () {
        _applySearch(text, immediate: true);
      });
      return;
    }
    setState(() {
      _filterState = _filterState.copyWith(searchQuery: text.trim());
    });
    context.read<PurchaseProvider>().loadPurchases(_filterState);
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _filterState = _filterState.copyWith(searchQuery: '');
    });
    context.read<PurchaseProvider>().loadPurchases(_filterState);
    _searchFocusNode.requestFocus();
  }

  void _resetAllFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _filterState = FilterState();
    });
    context.read<PurchaseProvider>().loadPurchases(_filterState);
  }

  Future<void> _onExport(List<Purchase> purchasesToExport) async {
    final cs = Theme.of(context).colorScheme;
    if (purchasesToExport.isEmpty) {
      final warningColor = cs.errorContainer;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: cs.onErrorContainer),
              const SizedBox(width: 8),
              Text('Aucun achat à exporter.',
                  style: TextStyle(color: cs.onErrorContainer)),
            ],
          ),
          backgroundColor: warningColor,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    await context.read<PurchaseProvider>().exportToExcel(purchasesToExport);
    if (mounted) {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.secondaryFixed),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Excel généré avec succès',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(
                              color: cs.onInverseSurface,
                              fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Rapport_Achats_$timestamp.xlsx',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: cs.onInverseSurface.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
    }
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

  void _selectAll(List<Purchase> purchasesToDisplay) {
    setState(() {
      _selectedPurchaseIds =
          purchasesToDisplay.map((p) => p.id!).toSet();
    });
  }

  Future<void> _confirmBatchDelete() async {
    final count = _selectedPurchaseIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les achats ?'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer définitivement $count commande${count > 1 ? 's' : ''} sélectionnée${count > 1 ? 's' : ''} ? Cette opération est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = context.read<PurchaseProvider>();
    for (final id in _selectedPurchaseIds.toList()) {
      await provider.deletePurchase(id);
    }
    if (mounted) {
      setState(() => _selectedPurchaseIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$count commande${count > 1 ? 's' : ''} supprimée${count > 1 ? 's' : ''}.'),
        ),
      );
    }
  }

  String _buildInitials(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    final first = words.first.substring(0, 1);
    final last = words.length > 1 ? words.last.substring(0, 1) : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<PurchaseProvider>();
    final purchasesToDisplay = provider.purchases;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
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
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EKIBAM ATELIER',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Historique',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: _buildAppBarActions(cs),
      ),
      body: _buildBody(provider, purchasesToDisplay, cs),
    );
  }

  List<Widget> _buildAppBarActions(ColorScheme cs) {
    return [
      IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'Recherche rapide',
        visualDensity: VisualDensity.compact,
        onPressed: () => _searchFocusNode.requestFocus(),
      ),
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        tooltip: 'Notifications',
        visualDensity: VisualDensity.compact,
        onPressed: () {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(const SnackBar(
              content: Text('Aucune notification pour le moment.'),
              behavior: SnackBarBehavior.floating,
            ));
        },
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: "Menu d'options",
        onSelected: (value) {
          if (value == 'help') {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HelpScreen()));
          } else if (value == 'library') {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const LibraryManagementScreen()));
          } else if (value == 'reports') {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ReportsScreen()));
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'help',
            child: ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Aide'),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'library',
            child: ListTile(
              leading: Icon(Icons.library_books_outlined),
              title: Text('Ma Bibliothèque'),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'reports',
            child: ListTile(
              leading: Icon(Icons.bar_chart_outlined),
              title: Text('Rapports'),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      _buildProfileButton(context, cs),
    ];
  }

  Widget _buildProfileButton(BuildContext context, ColorScheme cs) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final name =
            authService.currentUser?.userMetadata?['name'] as String? ??
                'Utilisateur';
        final email = authService.currentUser?.email;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 56),
          child: PopupMenuButton<String>(
            tooltip: 'Profil',
            onSelected: (value) {
              if (value == 'logout') {
                AuthService.instance.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (email != null) ...[
                      const SizedBox(height: 2),
                      Text(email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Se déconnecter'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: cs.primary.withValues(alpha: 0.2),
                child: Text(
                  _buildInitials(name),
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(PurchaseProvider provider,
      List<Purchase> purchasesToDisplay, ColorScheme cs) {
    if (provider.isLoading && purchasesToDisplay.isEmpty) {
      return const HistorySkeleton();
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
            _buildSearchBar(cs),
            _buildControlsBar(cs, purchasesToDisplay),
            if (purchasesToDisplay.isNotEmpty) ...[
              _buildActiveFilterChips(cs),
              if (_isSelectionMode) _buildSelectionBanner(cs, purchasesToDisplay),
            ],
            Expanded(
              child: purchasesToDisplay.isEmpty
                  ? _buildEmptyStateWidget(cs)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: purchasesToDisplay.length + 1,
                      itemBuilder: (context, index) {
                        if (index == purchasesToDisplay.length) {
                          return _TotalizerCard(
                            count: purchasesToDisplay.length,
                            total: purchasesToDisplay.fold(
                                0, (sum, p) => sum + p.grandTotal),
                          );
                        }
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

  Widget _buildSearchBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: Theme.of(context).textTheme.bodyMedium,
                textInputAction: TextInputAction.search,
                onChanged: (value) => _applySearch(value, immediate: false),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Rechercher par Réf DA, Demandeur, Fournisseur...',
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _searchController.text.isNotEmpty
                  ? IconButton(
                      key: const ValueKey('clear'),
                      icon: const Icon(Icons.close, size: 18),
                      color: cs.onSurfaceVariant,
                      tooltip: 'Effacer la recherche',
                      onPressed: _clearSearch,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsBar(
      ColorScheme cs, List<Purchase> purchasesToDisplay) {
    final activeFilterCount = _activeFilterCount();
    final isExportEnabled =
        !_isSelectionMode || _selectedPurchaseIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildToolstripButton(
            cs: cs,
            icon: Icons.tune,
            iconColor: cs.primary,
            label: 'Filtres',
            activeBadge: activeFilterCount,
            onTap: _isSelectionMode ? null : _showFilterSheet,
          ),
          _buildToolstripButton(
            cs: cs,
            icon: Icons.checklist,
            iconColor: cs.tertiary,
            label: _isSelectionMode ? 'Annuler' : 'Sélection',
            onTap: _toggleSelectionMode,
          ),
          _buildToolstripButton(
            cs: cs,
            icon: Icons.file_download,
            iconColor: cs.primary,
            label: 'Export Excel',
            emphasized: true,
            onTap: isExportEnabled
                ? () {
                    final list = _isSelectionMode
                        ? purchasesToDisplay
                            .where(
                                (p) => _selectedPurchaseIds.contains(p.id!))
                            .toList()
                        : purchasesToDisplay;
                    _onExport(list);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  int _activeFilterCount() {
    var count = 0;
    if (_filterState.searchQuery.isNotEmpty) count++;
    if (_filterState.startDate != null || _filterState.endDate != null) count++;
    if (_filterState.sortOption != SortOption.dateDesc) count++;
    return count;
  }

  Widget _buildToolstripButton({
    required ColorScheme cs,
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback? onTap,
    int? activeBadge,
    bool emphasized = false,
  }) {
    final effectiveColor = onTap == null ? cs.onSurface.withValues(alpha: 0.38) : iconColor;
    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: effectiveColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: emphasized
                          ? cs.primary
                          : effectiveColor,
                      fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
              if (activeBadge != null && activeBadge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeBadge',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _sortLabel(SortOption option) {
    switch (option) {
      case SortOption.amountDesc:
        return 'Montant décroissant';
      case SortOption.amountAsc:
        return 'Montant croissant';
      case SortOption.dateAsc:
        return 'Date plus ancienne';
      case SortOption.dateDesc:
        return 'Date récente';
    }
  }

  Widget _buildActiveFilterChips(ColorScheme cs) {
    final provider = context.read<PurchaseProvider>();
    final chips = <Widget>[];

    if (_filterState.searchQuery.isNotEmpty && _searchController.text.isNotEmpty) {
      chips.add(_ActiveChip(
        label: 'Recherche: ${_filterState.searchQuery}',
        onRemove: _clearSearch,
      ));
    }
    if (_filterState.startDate != null || _filterState.endDate != null) {
      final start = _filterState.startDate != null
          ? DateFormat('dd/MM/yyyy').format(_filterState.startDate!)
          : '…';
      final end = _filterState.endDate != null
          ? DateFormat('dd/MM/yyyy').format(_filterState.endDate!)
          : '…';
      chips.add(_ActiveChip(
        label: 'Période: $start → $end',
        onRemove: () {
          setState(() {
            _filterState =
                _filterState.copyWith(resetStartDate: true, resetEndDate: true);
          });
          provider.loadPurchases(_filterState);
        },
      ));
    }
    if (_filterState.sortOption != SortOption.dateDesc) {
      chips.add(_ActiveChip(
        icon: Icons.arrow_downward,
        label: _sortLabel(_filterState.sortOption),
        onRemove: () {
          setState(() {
            _filterState = _filterState.copyWith(
                sortOption: SortOption.dateDesc);
          });
          provider.loadPurchases(_filterState);
        },
      ));
    }

    if (chips.isEmpty && _activeFilterCount() == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...chips,
            if (_activeFilterCount() > 0) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: _resetAllFilters,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  child: Text(
                    'Tout effacer',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: cs.primary.withValues(alpha: 0.4),
                        ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBanner(
      ColorScheme cs, List<Purchase> purchasesToDisplay) {
    final count = _selectedPurchaseIds.length;
    final isAllSelected = purchasesToDisplay.isNotEmpty &&
        _selectedPurchaseIds.length == purchasesToDisplay.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_box, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$count commande${count > 1 ? 's' : ''} sélectionnée${count > 1 ? 's' : ''}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact),
              onPressed: isAllSelected
                  ? () => setState(() => _selectedPurchaseIds.clear())
                  : () => _selectAll(purchasesToDisplay),
              child: Text(isAllSelected ? 'Aucune' : 'Tout'),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: cs.error,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: count > 0 ? _confirmBatchDelete : null,
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Supprimer'),
            ),
          ],
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.history, size: 36, color: cs.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Text('Aucun achat trouvé',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
              _activeFilterCount() > 0
                  ? 'Aucun achat ne correspond aux filtres actuels.'
                  : 'Aucun achat enregistré pour le moment.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
        ]),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final IconData? icon;

  const _ActiveChip({required this.label, required this.onRemove, this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 14,
                color: cs.tertiary),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.cancel, size: 14, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
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

  ({Color bg, Color fg, Color dot, IconData icon}) _projectTypeStyle(
      ColorScheme cs, String projectType) {
    switch (projectType) {
      case 'Interne':
        return (
          bg: cs.tertiaryContainer.withValues(alpha: 0.18),
          fg: cs.tertiary,
          dot: cs.tertiary,
          icon: Icons.pending_actions,
        );
      case 'Mixte':
        return (
          bg: cs.secondaryContainer.withValues(alpha: 0.22),
          fg: cs.onSurfaceVariant,
          dot: cs.secondaryContainer,
          icon: Icons.account_balance_wallet_outlined,
        );
      case 'Client':
      default:
        return (
          bg: cs.primary.withValues(alpha: 0.10),
          fg: cs.primary,
          dot: cs.primary,
          icon: Icons.receipt_long,
        );
    }
  }

  String get _supplierName {
    for (final item in purchase.items) {
      if (item.supplierName != null && item.supplierName!.isNotEmpty) {
        return item.supplierName!;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style =
        _projectTypeStyle(cs, purchase.projectType);
    final itemsCount = purchase.items.length;
    final articlesPreview = purchase.items
        .map((item) => item.subCategory2 ?? item.subCategory1)
        .where((s) => s.isNotEmpty)
        .take(2)
        .join(', ');
    final date = DateFormat('dd/MM/yyyy').format(purchase.date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: isSelectionMode ? onToggleSelection : null,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              width: 128,
              height: 128,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        cs.primary.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius:
                        const BorderRadius.only(topRight: Radius.circular(16)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isSelectionMode) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 10, top: 2),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (value) => onToggleSelection(),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: style.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(style.icon, size: 20, color: style.fg),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    purchase.refDA ?? 'N/A',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _buildProjectTypePill(context, cs, style),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _supplierName.isNotEmpty
                                        ? '$date • $_supplierName'
                                        : date,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.tertiary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isSelectionMode)
                        InkWell(
                          onTap: () => _showCardMenu(context),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            child: Icon(Icons.more_vert,
                                size: 20, color: cs.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Demandeur',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: cs.tertiary)),
                              const SizedBox(height: 2),
                              Text(
                                purchase.demander,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Projet affecté',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: cs.tertiary)),
                              const SizedBox(height: 2),
                              Text(
                                purchase.projectType == 'Client' &&
                                        (purchase.clientName?.isNotEmpty ?? false)
                                    ? '${purchase.projectType} (${purchase.clientName})'
                                    : purchase.projectType,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              PurchaseDetailScreen(purchase: purchase)));
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 16, color: cs.tertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$itemsCount article${itemsCount > 1 ? 's' : ''}'
                              '${articlesPreview.isNotEmpty ? ' ($articlesPreview${itemsCount > 2 ? '...' : ''})' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Détails',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  )),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'MONTANT TOTAL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.tertiary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          NumberFormat('#,##0', 'fr_FR')
                              .format(purchase.grandTotal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('XAF',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectTypePill(BuildContext context, ColorScheme cs,
      ({Color bg, Color fg, Color dot, IconData icon}) style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            purchase.projectType,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: style.fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  void _showCardMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.read<PurchaseProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(purchase.refDA ?? 'Achat',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: cs.onSurfaceVariant,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _ContextMenuItem(
                  icon: Icons.picture_as_pdf,
                  color: cs.primary,
                  label: 'Télécharger le Bon de Commande (PDF)',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    provider.exportInvoiceToPdf(purchase);
                  },
                ),
                _ContextMenuItem(
                  icon: Icons.edit,
                  color: cs.tertiary,
                  label: 'Modifier la réquisition',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onEditPurchase?.call(purchase);
                  },
                ),
                _ContextMenuItem(
                  icon: Icons.delete,
                  color: cs.error,
                  label: 'Supprimer cet achat',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showDeleteDialog(context, provider);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(
      BuildContext context, PurchaseProvider provider) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer l\'achat ?'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer définitivement la commande ${purchase.refDA ?? ''} ? Cette opération est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.deletePurchase(purchase.id!);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ContextMenuItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalizerCard extends StatelessWidget {
  final int count;
  final int total;

  const _TotalizerCard({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.payments, color: cs.onPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count commande${count > 1 ? 's' : ''} affichée${count > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.tertiary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text('Cumul réquisitions',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Total',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.tertiary)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      NumberFormat('#,##0', 'fr_FR').format(total),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Text('XAF',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            )),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}