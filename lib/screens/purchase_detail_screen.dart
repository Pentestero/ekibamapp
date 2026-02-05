import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/purchase_item.dart';

class PurchaseDetailScreen extends StatelessWidget {
  final Purchase purchase;
  const PurchaseDetailScreen({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails Achat: ${purchase.refDA ?? 'N/A'}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Informations Générales'),
            _buildDetailRow(context, 'Référence DA', purchase.refDA ?? 'N/A'),
            _buildDetailRow(context, 'Date', DateFormat('dd/MM/yyyy').format(purchase.date)),
            _buildDetailRow(context, 'Date de création', DateFormat('dd/MM/yyyy HH:mm').format(purchase.createdAt)),
            if (purchase.modifiedAt != null && purchase.modifiedAt!.difference(purchase.createdAt).inSeconds > 5) // Display modifiedAt only if significantly different
              _buildDetailRow(context, 'Dernière modification', DateFormat('dd/MM/yyyy HH:mm').format(purchase.modifiedAt!)),
            _buildDetailRow(context, 'Demandeur', purchase.demander),
            _buildDetailRow(context, 'Type de Projet', purchase.projectType),
            if (purchase.clientName != null && purchase.clientName!.isNotEmpty)
              _buildDetailRow(context, 'Client', purchase.clientName!),
            _buildDetailRow(context, 'Mode de Paiement', purchase.paymentMethod),
            if (purchase.miseADBudget != null && purchase.miseADBudget!.isNotEmpty)
              _buildDetailRow(context, 'Destinataire Budget', purchase.miseADBudget!),
            
            _buildDetailRow(context, 'Commentaires Généraux', purchase.comments.isNotEmpty ? purchase.comments : 'Aucun'),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'Articles de l\'Achat'),
            _buildItemsTable(context, purchase.items, currencyFormat),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'Totaux'),
            _buildDetailRow(context, 'Montant Total', '${currencyFormat.format(purchase.grandTotal)} XAF', isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label :',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 18 : 16,
                color: isTotal ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(BuildContext context, List<PurchaseItem> items, NumberFormat currencyFormat) {
    if (items.isEmpty) {
      return const Text('Aucun article pour cet achat.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) { // Mobile view: ListView of Cards
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final productName = item.subCategory2 ?? item.subCategory1;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Catégorie: ${item.category}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Produit: $productName'),
                      if (item.expenseDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Date de dépense: ${DateFormat('dd/MM/yyyy').format(item.expenseDate!)}',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Qté: ${item.quantity.toStringAsFixed(1)}'),
                          Text('PU: ${currencyFormat.format(item.unitPrice)} XAF'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          'Total: ${currencyFormat.format(item.total)} XAF',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      if (item.comment != null && item.comment!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Commentaire: ${item.comment}', style: Theme.of(context).textTheme.bodySmall),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        } else { // Desktop view: DataTable
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Catégorie')),
                DataColumn(label: Text('Produit')),
                DataColumn(label: Text('Date de Dépense')), // Updated header
                DataColumn(label: Text('Qté')),
                DataColumn(label: Text('PU (XAF)')),
                DataColumn(label: Text('Total (XAF)')),
                DataColumn(label: Text('Com.')),
              ],
              rows: items.map((item) {
                final productName = item.subCategory2 ?? item.subCategory1; // More specific product name
                return DataRow(
                  cells: [
                    DataCell(Text(item.category)),
                    DataCell(Text(productName)),
                    DataCell(Text(item.expenseDate != null ? DateFormat('dd/MM/yyyy').format(item.expenseDate!) : '')), // Updated content
                    DataCell(Text(item.quantity.toStringAsFixed(1))),
                    DataCell(Text(currencyFormat.format(item.unitPrice))),
                    DataCell(Text(currencyFormat.format(item.total))),
                    DataCell(Text(item.comment ?? '')),
                  ],
                );
              }).toList(),
            ),
          );
        }
      },
    );
  }
}
