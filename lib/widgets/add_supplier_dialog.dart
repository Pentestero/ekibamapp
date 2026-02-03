import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/models/supplier.dart';
import 'package:provisions/providers/purchase_provider.dart';

// Dialog for adding a new supplier
class AddSupplierDialog extends StatefulWidget {
  const AddSupplierDialog({super.key});

  @override
  _AddSupplierDialogState createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<AddSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PurchaseProvider>();

    return AlertDialog(
      title: const Text('Créer un nouveau fournisseur'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: const InputDecoration(labelText: 'Nom du fournisseur'),
          onSaved: (value) => _name = value ?? '',
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Champ requis' : null,
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
              final newSupplier = await provider.addNewSupplier(name: _name);
              if (!context.mounted) return;
              Navigator.of(context).pop(newSupplier);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
