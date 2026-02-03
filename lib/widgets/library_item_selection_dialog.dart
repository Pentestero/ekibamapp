// lib/widgets/library_item_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:provisions/providers/purchase_provider.dart';

class LibraryItemSelectionDialog extends StatelessWidget {
  const LibraryItemSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();

    return AlertDialog(
      title: const Text('Sélectionner un article de la bibliothèque'),
      content: SizedBox( // Constrain height for dialog content
        width: double.maxFinite,
        child: provider.libraryItems.isEmpty
            ? const Center(child: Text('Votre bibliothèque est vide.'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: provider.libraryItems.length,
                itemBuilder: (context, index) {
                  final item = provider.libraryItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: ListTile(
                                        key: ValueKey(item.id), // Added key for list item optimization
                                        title: Text(item.templateName),
                                        subtitle: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(text: '${item.category} > ${item.subCategory1} ${item.subCategory2 != null ? '> ${item.subCategory2}' : ''}'),
                                              const TextSpan(text: '\n'),
                                              TextSpan(text: '${item.unitPrice != null ? 'Prix: ${NumberFormat('#,##0', 'fr_FR').format(item.unitPrice)} XAF' : ''} ${item.unit != null ? '/ ${item.unit}' : ''}'),
                                            ],
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.of(context).pop(item); // Return the selected item
                                        },
                                        isThreeLine: true,
                                      ),                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Close dialog without selection
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
