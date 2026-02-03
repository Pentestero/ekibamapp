// lib/screens/library_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:provisions/models/library_item.dart';
import 'package:provisions/providers/purchase_provider.dart';

class LibraryManagementScreen extends StatelessWidget {
  const LibraryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Bibliothèque d\'Articles'),
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.libraryItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.libraryItems.isEmpty) {
            return const Center(
              child: Text('Votre bibliothèque est vide. Ajoutez un premier article !'),
            );
          }
          return ListView.builder(
            itemCount: provider.libraryItems.length,
            itemBuilder: (context, index) {
              final item = provider.libraryItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _showAddEditLibraryItemDialog(context, item: item),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _confirmDelete(context, item),
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditLibraryItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditLibraryItemDialog(BuildContext context, {LibraryItem? item}) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<PurchaseProvider>(),
        child: AddEditLibraryItemDialog(item: item),
      ),
    );
  }

  void _confirmDelete(BuildContext context, LibraryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'article'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${item.templateName}" de votre bibliothèque ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PurchaseProvider>().deleteLibraryItem(item.id!);
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class AddEditLibraryItemDialog extends StatefulWidget {
  final LibraryItem? item;
  const AddEditLibraryItemDialog({super.key, this.item});

  @override
  State<AddEditLibraryItemDialog> createState() => _AddEditLibraryItemDialogState();
}

class _AddEditLibraryItemDialogState extends State<AddEditLibraryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _templateNameController;
  String? _selectedCategory;
  String? _selectedSubCategory1;
  String? _selectedSubCategory2;
  late TextEditingController _unitPriceController;
  late TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _templateNameController = TextEditingController(text: widget.item?.templateName ?? '');
    _selectedCategory = widget.item?.category;
    _selectedSubCategory1 = widget.item?.subCategory1;
    _selectedSubCategory2 = widget.item?.subCategory2;
    _unitPriceController = TextEditingController(text: widget.item?.unitPrice?.toString() ?? '');
    _unitController = TextEditingController(text: widget.item?.unit ?? '');
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    _unitPriceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _saveLibraryItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = context.read<PurchaseProvider>();
      final currentUserId = provider.currentUserId;

      if (currentUserId == null) {
        // Handle error: user not logged in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non authentifié.'), backgroundColor: Colors.red),
        );
        return;
      }

      final libraryItem = LibraryItem(
        id: widget.item?.id,
        userId: currentUserId,
        templateName: _templateNameController.text.trim(),
        category: _selectedCategory!,
        subCategory1: _selectedSubCategory1!,
        subCategory2: _selectedSubCategory2,
        unitPrice: int.tryParse(_unitPriceController.text),
        unit: _unitController.text.isNotEmpty ? _unitController.text : null,
        createdAt: widget.item?.createdAt ?? DateTime.now(),
      );

      if (widget.item == null) {
        await provider.addLibraryItem(libraryItem);
      } else {
        await provider.updateLibraryItem(libraryItem);
      }
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();
    final categories = provider.categories.keys.toList();

    List<String> subCategories1 = [];
    if (_selectedCategory != null && provider.categories[_selectedCategory] != null) {
      subCategories1 = provider.categories[_selectedCategory]!.keys.toList();
    }

    List<String> subCategories2 = [];
    if (_selectedCategory != null && _selectedSubCategory1 != null &&
        provider.categories[_selectedCategory]?[_selectedSubCategory1] != null) {
      subCategories2 = provider.categories[_selectedCategory]![_selectedSubCategory1]!;
    }

    return AlertDialog(
      title: Text(widget.item == null ? 'Ajouter un article à la bibliothèque' : 'Modifier l\'article'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _templateNameController,
                decoration: const InputDecoration(labelText: 'Nom du modèle (ex: Stylo Bic Bleu)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom du modèle est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedSubCategory1 = null;
                    _selectedSubCategory2 = null;
                  });
                },
                validator: (value) => value == null ? 'Catégorie requise' : null,
              ),
              const SizedBox(height: 16),
              if (subCategories1.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubCategory1,
                  decoration: const InputDecoration(labelText: 'Sous-catégorie 1'),
                  items: subCategories1.map((sub1) => DropdownMenuItem(value: sub1, child: Text(sub1))).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubCategory1 = value;
                      _selectedSubCategory2 = null;
                    });
                  },
                  validator: (value) => value == null ? 'Sous-catégorie 1 requise' : null,
                ),
              const SizedBox(height: 16),
              if (subCategories2.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubCategory2,
                  decoration: const InputDecoration(labelText: 'Sous-catégorie 2 / Article'),
                  items: subCategories2.map((sub2) => DropdownMenuItem(value: sub2, child: Text(sub2))).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubCategory2 = value;
                    });
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(labelText: 'Prix Unitaire (XAF)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Unité (ex: pièce, kg)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveLibraryItem,
          child: Text(widget.item == null ? 'Ajouter' : 'Modifier'),
        ),
      ],
    );
  }
}
