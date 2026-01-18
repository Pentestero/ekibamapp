

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/models/purchase.dart';
import 'package:intl/intl.dart';
import 'package:provisions/widgets/app_brand.dart';
import 'package:provisions/screens/purchase_form_screen.dart'; // ADDED BACK
import 'package:provisions/widgets/history_skeleton.dart'; // ADDED

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin { // Make sure this mixin is present
  String _selectedFilter = 'Tous';
  int? _selectedYear;
  late List<String> _filterOptions;
  late List<int> _yearOptions;

  late final AnimationController _contentController;
  late final Animation<double> _contentFadeAnimation;
  late final Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    _filterOptions = ['Tous', 'Cette semaine', 'Ce mois'];
    _yearOptions = [];

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _contentFadeAnimation =
        CurvedAnimation(parent: _contentController, curve: Curves.easeIn);
    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic));
    _contentController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get updates and rebuild the UI
    final provider = context.watch<PurchaseProvider>();

    // Derive year options from the full list of purchases
    _yearOptions = provider.purchases.map((p) => p.date.year).toSet().toList();
    _yearOptions.sort((a, b) => b.compareTo(a)); // Sort descending

    return Scaffold(
      appBar: AppBar(
        title: const AppBrand(),
        actions: [
          _buildFilterMenu(),
          _buildYearFilterMenu(), // Added year filter menu
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => provider.exportToExcel(),
          ),
        ],
      ),
      body: _buildBody(provider), // Use a helper for the body
    );
  }

  // New method to build the body, replacing the Consumer
  Widget _buildBody(PurchaseProvider provider) {
    if (provider.isLoading && provider.purchases.isEmpty) {
      return HistorySkeleton();
    }
    if (provider.errorMessage.isNotEmpty) {
      return _buildErrorWidget(context, provider);
    }

    final filteredPurchases = _getFilteredPurchases(provider.purchases);

    if (filteredPurchases.isEmpty) {
      return _buildEmptyStateWidget(context);
    }

    return FadeTransition(
      opacity: _contentFadeAnimation,
      child: SlideTransition(
        position: _contentSlideAnimation,
        child: RefreshIndicator(
          onRefresh: () => provider.loadPurchases(),
          child: Column(
            children: [
              _buildSummaryHeader(context, filteredPurchases),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredPurchases.length,
                  itemBuilder: (context, index) {
                    final purchase = filteredPurchases[index];
                    return PurchaseCard(purchase: purchase);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuButton<String> _buildFilterMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) => setState(() => _selectedFilter = value),
      itemBuilder: (context) => _filterOptions
          .map((option) => PopupMenuItem(
                value: option,
                child: Text(option,
                    style: TextStyle(
                        fontWeight: _selectedFilter == option
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ))
          .toList(),
    );
  }

  // New method for the year filter menu
  PopupMenuButton<int?> _buildYearFilterMenu() {
    return PopupMenuButton<int?>(
      icon: const Icon(Icons.calendar_today_outlined),
      tooltip: 'Filtrer par année',
      onSelected: (value) => setState(() => _selectedYear = value),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<int?>>[
          PopupMenuItem(
            value: null, // Represents "All years"
            child: Text('Toutes les années',
                style: TextStyle(
                    fontWeight: _selectedYear == null
                        ? FontWeight.bold
                        : FontWeight.normal)),
          ),
          if (_yearOptions.isNotEmpty) const PopupMenuDivider(),
        ];
        items.addAll(_yearOptions.map((year) => PopupMenuItem(
              value: year,
              child: Text(year.toString(),
                  style: TextStyle(
                      fontWeight: _selectedYear == year
                          ? FontWeight.bold
                          : FontWeight.normal)),
            )));
        return items;
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, PurchaseProvider provider) {
    final isNetworkError = provider.errorMessage.contains('Failed to fetch');
    final errorMessage = isNetworkError
        ? 'Erreur de connexion.\nVeuillez vérifier votre connexion internet et réessayer.'
        : provider.errorMessage;

    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(isNetworkError ? Icons.wifi_off : Icons.error_outline,
          size: 64, color: Colors.red),
      const SizedBox(height: 16),
      Text(errorMessage, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: () => provider.loadPurchases(),
          child: const Text('Réessayer')),
    ]));
  }

  Widget _buildEmptyStateWidget(BuildContext context) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.history, size: 64, color: Colors.grey),
      const SizedBox(height: 16),
      Text(_selectedFilter == 'Tous' && _selectedYear == null
          ? 'Aucun achat enregistré'
          : 'Aucun achat pour ce filtre'),
    ]));
  }

  Container _buildSummaryHeader(
      BuildContext context, List<Purchase> purchases) {
    // Updated to show year filter
    final yearFilterText = _selectedYear == null ? '' : ' - $_selectedYear';
    final summaryText =
        'Filtre: $_selectedFilter$yearFilterText (${purchases.length})';

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface.withAlpha(100),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summaryText),
                const SizedBox(height: 8),
                Text(
                    'Total: ${NumberFormat('#,##0', 'fr_FR').format(_getTotalAmount(purchases))} XAF',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(summaryText),
                Text(
                    'Total: ${NumberFormat('#,##0', 'fr_FR').format(_getTotalAmount(purchases))} XAF',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            );
          }
        },
      ),
    );
  }

  List<Purchase> _getFilteredPurchases(List<Purchase> purchases) {
    final now = DateTime.now();
    
    // Start with the full list
    List<Purchase> filteredList = List.from(purchases);

    // Apply date range filter
    switch (_selectedFilter) {
      case 'Cette semaine':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        filteredList = filteredList.where((p) => p.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))).toList();
        break;
      case 'Ce mois':
        final startOfMonth = DateTime(now.year, now.month, 1);
        filteredList = filteredList.where((p) => p.date.isAfter(startOfMonth.subtract(const Duration(days: 1)))).toList();
        break;
      default:
        // 'Tous' filter, do nothing
        break;
    }

    // Apply year filter
    if (_selectedYear != null) {
      filteredList = filteredList.where((p) => p.date.year == _selectedYear).toList();
    }

    return filteredList;
  }

  int _getTotalAmount(List<Purchase> purchases) {
    return purchases.fold(0, (sum, p) => sum + p.grandTotal);
  }
}

class PurchaseCard extends StatelessWidget {
  final Purchase purchase;
  const PurchaseCard({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PurchaseProvider>();
    final formattedDate = DateFormat('dd/MM/yyyy').format(purchase.date);
    
    final subtitleText = purchase.projectType == 'Client' && (purchase.clientName?.isNotEmpty ?? false)
        ? 'Projet: ${purchase.projectType} (${purchase.clientName})'
        : 'Projet: ${purchase.projectType}';

    final trailingActions = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) { // For small screens
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
        } else { // For large screens
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                color: Colors.red.shade700,
                tooltip: 'Générer la facture PDF',
                onPressed: () => provider.exportInvoiceToPdf(purchase),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                color: Colors.blue.shade700,
                tooltip: 'Modifier',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PurchaseFormScreen(purchase: purchase),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.grey.shade600,
                tooltip: 'Supprimer',
                onPressed: () => _showDeleteDialog(context, provider, purchase),
              ),
            ],
          );
        }
      },
    );

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    purchase.refDA ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailingActions,
              ],
            ),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              'Demandeur: ${purchase.demander}',
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitleText,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
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
                Text(formattedDate),
              ],
            ),
          ],
        ),
      ),
    );
  }
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