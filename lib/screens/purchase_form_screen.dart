import 'package:file_picker/file_picker.dart';
import 'package:provisions/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provisions/models/library_item.dart'; // NEW IMPORT
import 'package:provisions/models/purchase.dart';
import 'package:provisions/providers/purchase_provider.dart';
import 'package:intl/intl.dart';
import 'package:provisions/widgets/add_requester_dialog.dart'; // Import new dialog
import 'package:provisions/widgets/add_payment_method_dialog.dart'; // Import new dialog
import 'package:provisions/widgets/add_supplier_dialog.dart'; // Required for _PurchaseItemCard's dialog
import 'package:provisions/widgets/add_category_dialog.dart'; // Required for _PurchaseItemCard's dialog
import 'package:provisions/widgets/library_item_selection_dialog.dart'; // NEW IMPORT

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
  final Function(bool isEditing)? onSubmissionSuccess; // Callback
  const PurchaseFormScreen({super.key, this.purchase, this.onSubmissionSuccess});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  final _clientNameController = TextEditingController();
  final bool _isAiProcessing = false;

  Future<void> _scanInvoiceWithAI() async {
    // Subscription check simulation
    if (mounted) {
      final infoColor = Theme.of(context).colorScheme.brightness == Brightness.light ? Colors.blue.shade600 : Colors.blue.shade400;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimary),
              const SizedBox(width: 8),
              const Text("Cette fonctionnalité nécessite un abonnement mensuel pour l'utiliser."),
            ],
          ),
          backgroundColor: infoColor,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    return; // Prevent further execution

    // Original code follows (commented out or removed for this simulation)
    // setState(() {
    //   _isAiProcessing = true;
    // });

    // try {
    //   final result = await FilePicker.platform.pickFiles(
    //     type: FileType.custom,
    //     allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    //   );

    //   if (result != null && result.files.single.path != null) {
    //     final file = result.files.single;
    //     final extractedData = await AIService.analyseInvoice(file);

    //     // Call provider to pre-fill the form
    //     context.read<PurchaseProvider>().prefillFormFromAI(extractedData);

    //     if (mounted) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(
    //           content: Text('Données extraites avec succès ! Le formulaire a été pré-rempli.'),
    //           backgroundColor: Colors.green,
    //         ),
    //       );
    //     }

    //   }
    // } catch (e) {
    //   if (mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text("Erreur lors de l'analyse : $e"),
    //         backgroundColor: Colors.red,
    //       ),
    //     );
    //   }
    // } finally {
    //   if (mounted) {
    //     setState(() {
    //       _isAiProcessing = false;
    //     });
    //   }
    // }
  }



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
      body: Stack(
        children: [
          Consumer<PurchaseProvider>(
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
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _isAiProcessing ? null : _scanInvoiceWithAI,
                          icon: const Icon(Icons.document_scanner_outlined),
                          label: const Text('Analyser un document (IA)'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
          if (_isAiProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Analyse du document en cours...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
              trailing: null, // Always null as it's not modifiable
              onTap: null,   // Always null as it's not modifiable
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withAlpha(128)),
              ),
              tileColor: Theme.of(context).disabledColor.withOpacity(0.1), // Always visually disabled
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
                    initialValue: provider.purchaseBuilder.miseADBudget,
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
                          ,
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
              initialValue: provider.purchaseBuilder.projectType,
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
                    initialValue: provider.paymentMethods
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
                    'Appuyez sur "Ajouter un article" ou "Depuis la Biblio" pour commencer.',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
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
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final selectedItem = await showDialog<LibraryItem>(
                        context: context,
                        builder: (ctx) => ChangeNotifierProvider.value(
                          value: provider,
                          child: const LibraryItemSelectionDialog(),
                        ),
                      );
                      if (selectedItem != null) {
                        provider.addItemFromLibrary(selectedItem);
                      }
                    },
                    icon: const Icon(Icons.collections_bookmark_outlined),
                    label: const Text('Depuis la Biblio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Theme.of(context).colorScheme.onTertiary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
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
        final warningColor = Theme.of(context).colorScheme.brightness == Brightness.light ? Colors.orange.shade700 : Colors.orange.shade400;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.onPrimary),
                const SizedBox(width: 8),
                const Text('Veuillez ajouter au moins un article.'),
              ],
            ),
            backgroundColor: warningColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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

      // Debug: Check provider.isEditing before submission
      debugPrint('PurchaseFormScreen: _submitForm: provider.isEditing before submission: ${provider.isEditing}');

      if (resultPurchase != null) {
        final successMessage = provider.isEditing
            ? 'Mise à jour réussie avec succès ! N°: ${resultPurchase.refDA}'
            : 'Achat enregistré avec succès ! N°: ${resultPurchase.refDA}';

        final successColor = Theme.of(context).colorScheme.brightness == Brightness.light ? Colors.green.shade600 : Colors.green.shade400;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.onPrimary),
                const SizedBox(width: 8),
                Text(successMessage),
              ],
            ),
            backgroundColor: successColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        debugPrint('PurchaseFormScreen: _submitForm: Success message displayed: $successMessage');
        debugPrint('PurchaseFormScreen: _submitForm: Calling onSubmissionSuccess with isEditing: ${provider.isEditing}');
        widget.onSubmissionSuccess?.call(provider.isEditing); // Call the callback
      } else {
        debugPrint('PurchaseFormScreen: _submitForm: resultPurchase is null. Error occurred.');
        final isNetworkError = provider.errorMessage.contains('Failed to fetch');
        final errorMessage = isNetworkError
            ? 'Erreur de connexion. Impossible d\'enregistrer.'
            : 'Erreur: ${provider.errorMessage}';

        final errorColor = Theme.of(context).colorScheme.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onError),
                const SizedBox(width: 8),
                Text(errorMessage),
              ],
            ),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 6), // Longer duration for errors
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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

  Future<void> _selectExpenseDate(BuildContext context) async {
    final provider = context.read<PurchaseProvider>();
    final item = provider.itemsBuilder[widget.index];

    final purchaseCreationDate = provider.purchaseBuilder.date;

    // Last selectable date: cannot be in the future, and cannot be after the purchase creation date
    final lastSelectableDate =
        DateTime.now().isBefore(purchaseCreationDate) ? DateTime.now() : purchaseCreationDate;

    // Ensure initialDate is not after lastSelectableDate
    DateTime initialDate = item.expenseDate ?? DateTime.now();
    if (initialDate.isAfter(lastSelectableDate)) {
      initialDate = lastSelectableDate; // Clamp initialDate
    }
    // Also ensure initialDate is not before firstDate
    if (initialDate.isBefore(DateTime(2020))) {
        initialDate = DateTime(2020);
    }


    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020), // Can be adjusted as needed
      lastDate: lastSelectableDate,
    );

    if (newDate != null) {
      provider.updateItem(widget.index, expenseDate: newDate);
    }
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
      if (newSupplier != null) {
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
            ListTile( // Moved and modified ListTile for expense date
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              leading: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
              title: Text(
                item.expenseDate == null
                    ? 'Ajouter une date de dépense' // Renamed label
                    : 'Date de dépense: ${DateFormat('dd/MM/yyyy').format(item.expenseDate!)}', // Renamed label
              ),
              trailing: item.expenseDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Effacer la date',
                      onPressed: () {
                        provider.updateItem(widget.index, clearExpenseDate: true); // Updated to clearExpenseDate
                      },
                    )
                  : null,
              onTap: () => _selectExpenseDate(context), // Updated function call
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: item.category,
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
              initialValue: subCategories1.isEmpty
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
                initialValue: subCategories2.isEmpty
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
                    initialValue: item.supplierId ?? -1, // Use -1 for Aucun if supplierId is null
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
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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