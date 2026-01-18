import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:intl/intl.dart';
import 'package:provisions/widgets/add_requester_dialog.dart'; // Import new dialog
import 'package:provisions/widgets/add_payment_method_dialog.dart'; // Import new dialog
import 'package:provisions/widgets/add_supplier_dialog.dart'; // Required for _PurchaseItemCard's dialog
import 'package:provisions/widgets/add_category_dialog.dart'; // Required for _PurchaseItemCard's dialog

String? _wordCountValidator(String? value) {
  if (value == null || value.isEmpty) {
    return null; // No validation needed for empty field
  }
  final words = value.trim().split(RegExp(r'\s+'));
  if (words.length > 150) {
    return 'Max 150 mots autorisés. Actuellement: ${words.length} mots.';
  }
  return null;
}

class PurchaseFormScreen extends StatefulWidget {
  final Purchase? purchase; // Optional purchase for editing
  const PurchaseFormScreen({super.key, this.purchase});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  final _clientNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PurchaseProvider>();
      if (widget.purchase != null) {
        provider.loadPurchaseForEditing(widget.purchase!);
        _commentsController.text = widget.purchase!.comments;
        _clientNameController.text = widget.purchase!.clientName ?? '';
      } else {
        provider.clearForm();
        _commentsController.clear();
        _clientNameController.clear();
      }
    });
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _clientNameController.dispose();
    super.dispose();
  }

  void _showAddRequesterDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<PurchaseProvider>(),
          child: AddRequesterDialog(), // Use new public dialog
        );
      },
    );
  }

  void _showAddPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<PurchaseProvider>(),
          child: AddPaymentMethodDialog(), // Use new public dialog
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<PurchaseProvider>(
          builder: (context, provider, child) {
            return Text(
                provider.isEditing ? 'Modifier l\'achat' : 'Nouvel Achat');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PurchaseProvider>().clearForm();
              _commentsController.clear();
              _clientNameController.clear();
            },
          ),
        ],
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          // Update controllers if provider's builder state changes
          if (_commentsController.text != provider.purchaseBuilder.comments) {
            _commentsController.text = provider.purchaseBuilder.comments;
          }
          if (_clientNameController.text != (provider.purchaseBuilder.clientName ?? '')) {
            _clientNameController.text = provider.purchaseBuilder.clientName ?? '';
          }

          if (provider.isLoading && provider.requesters.isEmpty && !provider.isEditing) {
            return const Center(child: CircularProgressIndicator()); // Keep default loading for now
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(context, provider),
                  const SizedBox(height: 24),
                  _buildItemsSection(context, provider),
                  const SizedBox(height: 24),
                  _buildTotalsCard(context, provider),
                  const SizedBox(height: 32),
                  _buildSubmitButton(context, provider),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, PurchaseProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations Générales',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(
                  DateFormat('dd/MM/yyyy').format(provider.purchaseBuilder.date)),
              trailing: Icon(Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary),
              onTap: () => _selectDate(context, provider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withAlpha(128)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: provider.purchaseBuilder.demander,
              decoration: InputDecoration(
                labelText: 'Demandeur',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              enabled: false, // Make it read-only
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: provider.purchaseBuilder.miseADBudget,
                    decoration: InputDecoration(
                        labelText: 'Destinataire Budget (si different)',
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Aucun'),
                      ),
                      ...provider.requesters
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                    ],
                    onChanged: (value) {
                      provider.updatePurchaseHeader(miseADBudget: value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add_circle,
                      color: Theme.of(context).colorScheme.primary),
                  tooltip: 'Créer un nouveau destinataire',
                  onPressed: _showAddRequesterDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: provider.purchaseBuilder.projectType,
              decoration: InputDecoration(
                  labelText: 'Type de Projet', prefixIcon: const Icon(Icons.work), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              items: provider.projectTypes
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (value) {
                provider.updatePurchaseHeader(projectType: value);
                if (value != 'Client' && value != 'Mixte') {
                  _clientNameController.clear();
                  provider.updatePurchaseHeader(clientName: '');
                }
              },
            ),
            if (provider.purchaseBuilder.projectType == 'Client' ||
                provider.purchaseBuilder.projectType == 'Mixte') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _clientNameController,
                decoration: InputDecoration(
                    labelText: 'Nom du Client ou projet client',
                    prefixIcon: const Icon(Icons.person_pin), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                onChanged: (value) =>
                    provider.updatePurchaseHeader(clientName: value),
                validator: (value) {
                  if ((provider.purchaseBuilder.projectType == 'Client' ||
                          provider.purchaseBuilder.projectType == 'Mixte') &&
                      (value == null || value.isEmpty)) {
                    return 'Le nom du client/projet est requis';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: provider.paymentMethods
                            .contains(provider.purchaseBuilder.paymentMethod)
                        ? provider.purchaseBuilder.paymentMethod
                        : null,
                    decoration: InputDecoration(
                        labelText: 'Mode de paiement',
                        prefixIcon: const Icon(Icons.payment), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    items: provider.paymentMethods
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (value) =>
                        provider.updatePurchaseHeader(paymentMethod: value),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Champ requis' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add_circle,
                      color: Theme.of(context).colorScheme.primary),
                  tooltip: 'Créer un nouveau mode de paiement',
                  onPressed: _showAddPaymentMethodDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentsController,
              decoration: InputDecoration(
                  labelText: 'Commentaire Général',
                  prefixIcon: const Icon(Icons.comment), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              onChanged: (value) =>
                  provider.updatePurchaseHeader(comments: value),
              validator: _wordCountValidator, // Apply the word count validator
              maxLines: 5, // Increased maxLines for better visibility
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, PurchaseProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Articles',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 16),
            if (provider.itemsBuilder.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    'Appuyez sur "Ajouter un article" pour commencer.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.itemsBuilder.length,
              itemBuilder: (context, index) {
                // Use the item itself as the ValueKey, relies on PurchaseItem's operator== and hashCode
                return _PurchaseItemCard(key: ValueKey(provider.itemsBuilder[index]), index: index);
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  final error = provider.addNewItem();
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error), backgroundColor: Colors.orange),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un article'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context, PurchaseProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('GRAND TOTAL',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    )),
            Expanded( // Wrap in Expanded
              child: Text(
                '${NumberFormat('#,##0', 'fr_FR').format(provider.grandTotalBuilder)} XAF',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                textAlign: TextAlign.end, // Align to end
                softWrap: false, // Prevent wrapping
                overflow: TextOverflow.ellipsis, // Show ellipsis if overflows
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, PurchaseProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed:
            provider.isLoading ? null : () => _submitForm(context, provider),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        icon: provider.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save),
        label: Text(provider.isLoading
            ? 'Enregistrement...'
            : (provider.isEditing
                ? 'Mettre à jour l\'achat'
                : 'Enregistrer l\'Achat')),
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, PurchaseProvider provider) async {
    final date = await showDatePicker(
      context: context,
      initialDate: provider.purchaseBuilder.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      provider.updatePurchaseHeader(date: date);
    }
  }

  Future<void> _submitForm(
      BuildContext context, PurchaseProvider provider) async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        provider.itemsBuilder.isEmpty) {
      if (provider.itemsBuilder.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez ajouter au moins un article.'),
              backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer l\'enregistrement'),
          content: const Text(
              'Êtes-vous sûr de vouloir enregistrer cet achat ? Veuillez vérifier que toutes les informations sont correctes.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Confirmer'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      Purchase? resultPurchase;
      if (provider.isEditing) {
        resultPurchase = await provider.updatePurchase();
      } else {
        resultPurchase = await provider.addPurchase();
      }

      if (!context.mounted) return;
      if (resultPurchase != null) {
        final successMessage = provider.isEditing
            ? 'Mise à jour réussie avec succès ! N°: ${resultPurchase.refDA}'
            : 'Achat enregistré avec succès ! N°: ${resultPurchase.refDA}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );

        // Pop only after editing, stay on form for new entry
        if (provider.isEditing && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } else {
        final isNetworkError = provider.errorMessage.contains('Failed to fetch');
        final errorMessage = isNetworkError
            ? 'Erreur de connexion. Impossible d\'enregistrer.'
            : 'Erreur: ${provider.errorMessage}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _PurchaseItemCard extends StatefulWidget {
  final int index;
  const _PurchaseItemCard({super.key, required this.index});

  @override
  State<_PurchaseItemCard> createState() => _PurchaseItemCardState();
}

class _PurchaseItemCardState extends State<_PurchaseItemCard> {
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    final item = context.read<PurchaseProvider>().itemsBuilder[widget.index];
    _quantityController =
        TextEditingController(text: item.quantity.toString());
    _unitController = TextEditingController(text: item.unit ?? ''); // Handle null
    _priceController = TextEditingController(text: item.unitPrice.toString());
    _commentController = TextEditingController(text: item.comment ?? ''); // Handle null
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _showAddSupplierDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<PurchaseProvider>(),
          child: AddSupplierDialog(), // Use new public dialog
        );
      },
    ).then((newSupplier) {
      if (!mounted) return;
      if (newSupplier != null) { // Supplier is already typed as Supplier from dialog, no need to check is Supplier
        context
            .read<PurchaseProvider>()
            .updateItem(widget.index, supplierId: newSupplier.id);
      }
    });
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<PurchaseProvider>(),
          child: AddCategoryDialog(), // Use new public dialog
        );
      },
    ).then((_) {
      // After adding a category, refresh the item card to update dropdowns
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();
    final item = provider.itemsBuilder[widget.index];

    final categories = provider.categories.keys.toList();
    final subCategories1 =
        provider.categories[item.category]?.keys.toList() ?? [];
    final subCategories2 =
        provider.categories[item.category]?[item.subCategory1] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Article #${widget.index + 1}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error),
                  onPressed: () => provider.removeItem(widget.index),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.category,
                    decoration: InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final sub1Keys = provider.categories[value]?.keys;
                        final newSub1 = (sub1Keys != null && sub1Keys.isNotEmpty)
                            ? sub1Keys.first
                            : '';
                        
                        final sub2Values = provider.categories[value]?[newSub1];
                        final newSub2 = (sub2Values != null && sub2Values.isNotEmpty)
                            ? sub2Values.first
                            : null;
                            
                        provider.updateItem(widget.index,
                            category: value,
                            subCategory1: newSub1,
                            subCategory2: newSub2);
                      }
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add_circle,
                      color: Theme.of(context).colorScheme.primary),
                  tooltip: 'Créer une nouvelle catégorie',
                  onPressed: _showAddCategoryDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category 2
            DropdownButtonFormField<String>(
              value: subCategories1.isEmpty
                  ? null
                  : (subCategories1.contains(item.subCategory1)
                      ? item.subCategory1
                      : subCategories1.first),
              decoration: InputDecoration(labelText: 'Sous-catégorie 1', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              items: subCategories1
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  final newSub2Values = provider.categories[item.category]?[value];
                  final newSub2 = (newSub2Values != null && newSub2Values.isNotEmpty)
                      ? newSub2Values.first
                      : null;
                  provider.updateItem(widget.index,
                      subCategory1: value, subCategory2: newSub2);
                }
              },
              isExpanded: true,
            ),
            const SizedBox(height: 12),

            // Category 3
            if (subCategories2.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: subCategories2.isEmpty
                    ? null
                    : (subCategories2.contains(item.subCategory2)
                        ? item.subCategory2
                        : subCategories2.first),
                decoration: InputDecoration(
                    labelText: 'Sous-catégorie 2 / Article', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                items: subCategories2
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    provider.updateItem(widget.index, subCategory2: value);
                  }
                },
                isExpanded: true,
              ),
              const SizedBox(height: 12),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: item.supplierId ?? -1, // Use -1 for Aucun if supplierId is null
                    decoration: InputDecoration(labelText: 'Fournisseur', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    items: provider.suppliers
                        .map((s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: (value) {
                      // Handle the case where "Aucun" is selected (id: -1)
                      final int? finalSupplierId = (value == -1) ? null : value;
                      provider.updateItem(widget.index, supplierId: finalSupplierId);
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add_circle,
                      color: Theme.of(context).colorScheme.primary),
                  tooltip: 'Créer un nouveau fournisseur',
                  onPressed: _showAddSupplierDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) { // Adjust breakpoint as needed
                  return Column(
                    children: [
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(labelText: 'Quantité', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]+'))
                        ],
                        onChanged: (value) {
                          final qty =
                              double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                          context.read<PurchaseProvider>().updateItem(widget.index, quantity: qty);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _unitController,
                        decoration: InputDecoration(labelText: 'Unité', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        onChanged: (value) {
                          context.read<PurchaseProvider>().updateItem(widget.index, unit: value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                            labelText: 'Prix Unitaire', suffixText: 'XAF', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          final price = int.tryParse(value) ?? 0;
                          context.read<PurchaseProvider>().updateItem(widget.index, unitPrice: price);
                        },
                      ),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(labelText: 'Quantité', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]+'))
                          ],
                          onChanged: (value) {
                            final qty =
                                double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                            context.read<PurchaseProvider>().updateItem(widget.index, quantity: qty);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _unitController,
                          decoration: InputDecoration(labelText: 'Unité', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          onChanged: (value) {
                            context.read<PurchaseProvider>().updateItem(widget.index, unit: value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                              labelText: 'Prix Unitaire', suffixText: 'XAF', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (value) {
                            final price = int.tryParse(value) ?? 0;
                            context.read<PurchaseProvider>().updateItem(widget.index, unitPrice: price);
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(
                  labelText: 'Commentaire (par article)',
                  prefixIcon: const Icon(Icons.comment), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              onChanged: (value) { // Reverted to onChanged
                context.read<PurchaseProvider>().updateItemComment(widget.index, value);
              },
              validator: _wordCountValidator, // Apply the word count validator
              maxLines: 5, // Increased maxLines for better visibility
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Article:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Expanded( // Wrap in Expanded
                    child: Text(
                      '${NumberFormat('#,##0', 'fr_FR').format(item.total)} XAF',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.end, // Align to end
                      softWrap: false, // Prevent wrapping
                      overflow: TextOverflow.ellipsis, // Show ellipsis if overflows
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}