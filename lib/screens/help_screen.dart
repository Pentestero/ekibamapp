import 'package:flutter/material.dart';
import 'package:provisions/widgets/animations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 24,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            const Text("Aide et Guide d'utilisation"),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: StaggeredList(
          itemDelay: const Duration(milliseconds: 50),
          children: [
            _buildSectionTitle(context, 'Fonctionnalités Clés'),
            _buildHelpItem(
              context,
              'Ajout dynamique',
              'Vous pouvez ajouter de nouvelles Catégories, de nouveaux Fournisseurs, et de nouveaux Modes de Paiement directement depuis le formulaire de saisie en utilisant les boutons (+).',
              Icons.add_circle_outline,
            ),
            _buildHelpItem(
              context,
              'Champ "Destinataire Budget"',
              "Ce champ est une liste déroulante où vous pouvez sélectionner une personne ou un service responsable du budget si cela est différent du \"Demandeur\" (l'utilisateur connecté).\n\nSa valeur n'apparaît que dans le PDF de la \"Demande d'Achat\" et uniquement si elle est différente du \"Demandeur\". Elle n'est jamais utilisée dans les rapports Excel.",
              Icons.account_balance_wallet_outlined,
            ),
            _buildHelpItem(
              context,
              'Mode de paiement (pour Export Excel)',
              'Saisissez ici la méthode de paiement utilisée pour l\'achat (ex: "Virement Bancaire", "Espèces").\n\nSi vous utilisez un format comme "PREMIERE_PARTIE / DEUXIEME_PARTIE" (ex: "ESP / ESP"), la première partie sera utilisée pour la colonne "Mise_AD_budget" dans le rapport Excel, et la deuxième pour "Mode_Rglt". Sans "/", les deux colonnes contiendront la même valeur.',
              Icons.payment_outlined,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Gestion des articles'),
            _buildHelpItem(
              context,
              'Catégories hiérarchiques',
              "L'application utilise un système de catégories à 3 niveaux : Catégorie -> Sous-catégorie 1 -> Sous-catégorie 2 / Article. La sélection d'une catégorie filtre les options disponibles pour la sous-catégorie suivante.",
              Icons.category_outlined,
            ),
            _buildHelpItem(
              context,
              'Montants en XAF',
              'Tous les montants monétaires (Prix Unitaire, Total, etc.) sont gérés en tant qu\'entiers pour représenter les XAF. Les champs de saisie n\'acceptent que des chiffres.',
              Icons.monetization_on_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(
      BuildContext context, String title, String content, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(content,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
