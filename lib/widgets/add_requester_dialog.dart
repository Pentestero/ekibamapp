import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provisions/providers/purchase_provider.dart';

// Dialog for adding a new requester
class AddRequesterDialog extends StatefulWidget {
  const AddRequesterDialog({super.key});

  @override
  _AddRequesterDialogState createState() => _AddRequesterDialogState();
}

class _AddRequesterDialogState extends State<AddRequesterDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un nouveau demandeur'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: const InputDecoration(labelText: 'Nom du demandeur'),
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
              await context.read<PurchaseProvider>().addNewRequester(name: _name);
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
