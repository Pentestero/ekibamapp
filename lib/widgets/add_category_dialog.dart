import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';

// Dialog for adding a new Category
class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  _AddCategoryDialogState createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subCategory1Controller = TextEditingController();
  final TextEditingController _subCategory2Controller = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    _subCategory1Controller.dispose();
    _subCategory2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer une nouvelle catégorie'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _subCategory1Controller,
                decoration: const InputDecoration(labelText: 'Sous-catégorie 1'),
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _subCategory2Controller,
                decoration: const InputDecoration(labelText: 'Sous-catégorie 2 / Article (optionnel)'),
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              await context.read<PurchaseProvider>().addNewCategory(
                    category: _categoryController.text,
                    subCategory1: _subCategory1Controller.text,
                    subCategory2: _subCategory2Controller.text.isNotEmpty
                        ? _subCategory2Controller.text
                        : null,
                  );
              if (!context.mounted) return;
              Navigator.of(context).pop();
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
