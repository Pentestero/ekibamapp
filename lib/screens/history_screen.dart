

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:provisions/models/purchase.dart';
import 'package:intl/intl.dart';
import 'package:provisions/widgets/app_brand.dart';
import 'package:provisions/screens/purchase_form_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Tous';
  late List<String> _filterOptions;

  @override
  void initState() {
    super.initState();
    _filterOptions = ['Tous', 'Cette semaine', 'Ce mois'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBrand(),
        actions: [
          _buildFilterMenu(),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => context.read<PurchaseProvider>().exportToExcel(),
          ),
        ],
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.purchases.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage.isNotEmpty) {
            return _buildErrorWidget(context, provider);
          }

          final filteredPurchases = _getFilteredPurchases(provider.purchases);

          if (filteredPurchases.isEmpty) {
            return _buildEmptyStateWidget(context);
          }

          return RefreshIndicator(
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
          );
        },
      ),
    );
  }

  PopupMenuButton<String> _buildFilterMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) => setState(() => _selectedFilter = value),
      itemBuilder: (context) => _filterOptions.map((option) => PopupMenuItem(
        value: option,
        child: Text(option, style: TextStyle(fontWeight: _selectedFilter == option ? FontWeight.bold : FontWeight.normal)),
      )).toList(),
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
      const SizedBox(height: 16), Text(_selectedFilter == 'Tous' ? 'Aucun achat enregistré' : 'Aucun achat pour ce filtre'),
    ]));
  }

  Container _buildSummaryHeader(BuildContext context, List<Purchase> purchases) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface.withAlpha(100),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filtre: $_selectedFilter (${purchases.length})'),
                const SizedBox(height: 8),
                Text('Total: ${NumberFormat('#,##0', 'fr_FR').format(_getTotalAmount(purchases))} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtre: $_selectedFilter (${purchases.length})'),
                Text('Total: ${NumberFormat('#,##0', 'fr_FR').format(_getTotalAmount(purchases))} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            );
          }
        },
      ),
    );
  }

  List<Purchase> _getFilteredPurchases(List<Purchase> purchases) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Cette semaine':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return purchases.where((p) => p.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))).toList();
      case 'Ce mois':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return purchases.where((p) => p.date.isAfter(startOfMonth.subtract(const Duration(days: 1)))).toList();
      default:
        return purchases;
    }
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(purchase.refDA ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Demandeur: ${purchase.demander}'),
            Text(subtitleText),
            const SizedBox(height: 4),
            Text(
              '${NumberFormat('#,##0', 'fr_FR').format(purchase.grandTotal)} FCFA • $formattedDate',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) { // Pour les petits écrans
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
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        const Text('Générer PDF'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text('Modifier'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        const Text('Supprimer'),
                      ],
                    ),
                  ),
                ],
              );
            } else { // Pour les écrans larges
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
        ),
        isThreeLine: true,
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