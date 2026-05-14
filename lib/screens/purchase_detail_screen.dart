import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/purchase_item.dart';
import 'package:provisions/widgets/animations.dart';

class PurchaseDetailScreen extends StatelessWidget {
  final Purchase purchase;
  const PurchaseDetailScreen({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat('#,##0', 'fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: Text('Achat: ${purchase.refDA ?? 'N/A'}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: StaggeredList(
          itemDelay: const Duration(milliseconds: 50),
          children: [
            _buildInfoCard(context, cs, currencyFormat),
            const SizedBox(height: 16),
            _buildItemsCard(context, cs, currencyFormat),
            const SizedBox(height: 16),
            _buildTotalCard(context, cs, currencyFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, ColorScheme cs, NumberFormat currencyFormat) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                Text('Informations Générales',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const Divider(height: 24),
            _detailRow(context, 'Référence DA', purchase.refDA ?? 'N/A'),
            _detailRow(context, 'Date',
                DateFormat('dd/MM/yyyy').format(purchase.date)),
            _detailRow(context, 'Date de création',
                DateFormat('dd/MM/yyyy HH:mm').format(purchase.createdAt.toLocal())),
            if (purchase.modifiedAt != null &&
                purchase.modifiedAt!
                        .difference(purchase.createdAt)
                        .inSeconds >
                    5)
              _detailRow(context, 'Dernière modification',
                  DateFormat('dd/MM/yyyy HH:mm').format(purchase.modifiedAt!.toLocal())),
            _detailRow(context, 'Demandeur', purchase.demander),
            _detailRow(context, 'Type de Projet', purchase.projectType),
            if (purchase.clientName != null && purchase.clientName!.isNotEmpty)
              _detailRow(context, 'Client', purchase.clientName!),
            _detailRow(context, 'Mode de Paiement', purchase.paymentMethod),
            if (purchase.miseADBudget != null &&
                purchase.miseADBudget!.isNotEmpty)
              _detailRow(
                  context, 'Destinataire Budget', purchase.miseADBudget!),
            if (purchase.comments.isNotEmpty)
              _detailRow(context, 'Commentaires', purchase.comments),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: TextStyle(
                    color: cs.onSurface.withAlpha(150), fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(
      BuildContext context, ColorScheme cs, NumberFormat currencyFormat) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                Text('Articles',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const Divider(height: 24),
            if (purchase.items.isEmpty)
              const Text('Aucun article pour cet achat.')
            else
              ...purchase.items.map((item) => _buildItemCard(
                  context, purchase.items.indexOf(item), item, currencyFormat, cs)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, int index, PurchaseItem item,
      NumberFormat currencyFormat, ColorScheme cs) {
    final productName = item.subCategory2 ?? item.subCategory1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(80),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Article #${index + 1}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text('Total: ${currencyFormat.format(item.total)} XAF',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Catégorie: ${item.category}',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(180))),
            Text('Produit: $productName',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(180))),
            Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(item.expenseDate)}',
                style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: cs.primary.withAlpha(180))),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Qté: ${item.quantity.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(180))),
                Text('PU: ${currencyFormat.format(item.unitPrice)} XAF',
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(180))),
              ],
            ),
            if (item.comment != null && item.comment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${item.comment}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(
      BuildContext context, ColorScheme cs, NumberFormat currencyFormat) {
    return Card(
      margin: EdgeInsets.zero,
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('MONTANT TOTAL',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: cs.onPrimaryContainer)),
            Text('${currencyFormat.format(purchase.grandTotal)} XAF',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: cs.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}
