import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide et Guide d\'utilisation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Fonctionnalités Clés'),
            _buildHelpItem(
              context,
              'Ajout dynamique',
              'Vous pouvez ajouter de nouvelles Catégories, de nouveaux Fournisseurs, et de nouveaux Modes de Paiement directement depuis le formulaire de saisie en utilisant les boutons (+).',
            ),
            _buildHelpItem(
              context,
              'Champ "Destinataire Budget"',
              'Ce champ est une liste déroulante où vous pouvez sélectionner une personne ou un service responsable du budget si cela est différent du "Demandeur" (l\'utilisateur connecté).\n\nSa valeur n\'apparaît **que dans le PDF de la "Demande d\'Achat"** et uniquement si elle est différente du "Demandeur". Elle n\'est **jamais** utilisée dans les rapports Excel.',
            ),
            _buildHelpItem(
              context,
              'Champ "Mode de paiement" (pour l\'Export Excel)',
              'Saisissez ici la méthode de paiement utilisée pour l\'achat (ex: "Virement Bancaire", "Espèces").\n\nSi vous utilisez un format comme **`PREMIERE_PARTIE / DEUXIEME_PARTIE`** (ex: "ESP / ESP"), la première partie sera utilisée pour la colonne `Mise_AD_budget` dans le rapport Excel, et la deuxième partie pour la colonne `Mode_Rglt`. Si vous n\'utilisez pas de `/`, les deux colonnes Excel contiendront la même valeur que le champ. Ce champ est indépendant du "Destinataire Budget" pour le PDF.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Gestion des articles'),
            _buildHelpItem(
              context,
              'Catégories hiérarchiques',
              'L\'application utilise un système de catégories à 3 niveaux : Catégorie -> Sous-catégorie 1 -> Sous-catégorie 2 / Article. La sélection d\'une catégorie filtre les options disponibles pour la sous-catégorie suivante.',
            ),
             _buildHelpItem(
              context,
              'Montants en XAF',
              'Tous les montants monétaires (Prix Unitaire, Total, etc.) sont gérés en tant qu\'entiers pour représenter les XAF. Les champs de saisie n\'acceptent que des chiffres.',
            ),
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
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, String title, String content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubHelpItem(BuildContext context, String content, [List<String>? examples]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $content',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (examples != null)
            Padding(
              padding: const EdgeInsets.only(left: 24.0, top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: examples.map((e) => Text('- $e')).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCodeSnippet(BuildContext context, String code) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        code,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontFamily: 'monospace',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
