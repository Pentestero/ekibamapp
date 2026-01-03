# EKIBAM - Application de Gestion des Achats

EKIBAM est une application multiplateforme (Web, Android, iOS) conçue pour simplifier et professionnaliser la gestion des achats au sein d'une entreprise. Elle permet de suivre les demandes, de gérer les articles, d'analyser les dépenses et de générer des documents officiels comme des demandes d'achat et des rapports.

## ✨ Fonctionnalités Principales

L'application offre une suite complète d'outils pour une gestion transparente :

- **Gestion des Achats :** Un formulaire de saisie complet et responsive pour créer et éditer les demandes d'achat.
- **Hiérarchie de Catégories :** Un système de catégories à 3 niveaux (`Catégorie` -> `Sous-catégorie 1` -> `Article`) pour une classification précise des dépenses.
- **Gestion Dynamique des Données :** Possibilité d'ajouter de nouvelles **Catégories**, de nouveaux **Fournisseurs** et de nouveaux **Modes de Paiement** directement depuis l'interface utilisateur.
- **Génération de Référence Unique :** Création automatique d'une `Ref DA` unique pour chaque nouvel achat, au format `DA-JJMMAAAA-X`.
- **Historique et Suivi :** Un écran d'historique responsive liste tous les achats passés avec des filtres par période (semaine, mois).
- **Actions Rapides :** Chaque achat dispose de boutons pour générer une "Demande d'Achat" PDF, modifier ou supprimer l'enregistrement.
- **Export et Rapports :** Exportez un rapport global des dépenses au format `.xlsx` ou générez des PDF individuels pour chaque demande d'achat.
- **Tableau de Bord (Dashboard) :** Des graphiques et indicateurs clés présentent des statistiques sur les dépenses par fournisseur et par type de projet.
- **Interface Personnalisable :** Changez le thème de couleurs et basculez entre le mode clair et sombre.
- **Authentification Sécurisée :** Connexion et inscription des utilisateurs pour sécuriser l'accès aux données.
- **Guide d'utilisation intégré :** Une section d'aide est disponible directement dans l'application pour guider les utilisateurs.

## 📖 Guide d'utilisation

#### Gestion des champs liés au paiement et au budget

Pour une gestion claire des informations de paiement et du budget, l'application utilise les champs suivants :

*   **Champ "Mode de paiement" (dans le formulaire) :**
    *   Saisissez ici la méthode de paiement utilisée pour l'achat (ex: "Virement Bancaire", "Espèces").
    *   Si vous utilisez un format comme **`PREMIERE_PARTIE / DEUXIEME_PARTIE`** (ex: "ESP / ESP"), la première partie sera utilisée pour la colonne `Mise_AD_budget` dans le rapport Excel, et la deuxième partie pour la colonne `Mode_Rglt`. Si vous n'utilisez pas de `/`, les deux colonnes Excel contiendront la même valeur que le champ.

*   **Champ "Destinataire Budget" (dans le formulaire) :**
    *   Ce champ est une liste déroulante où vous pouvez sélectionner une personne ou un service responsable du budget si cela est différent du "Demandeur" (l'utilisateur connecté).
    *   La valeur sélectionnée ici n'apparaît **que dans le PDF de la "Demande d'Achat"** et uniquement si elle est différente du "Demandeur". Elle n'est **jamais** utilisée dans les rapports Excel.

## 🛠️ Technologies Utilisées

- **Framework :** [Flutter](https://flutter.dev/)
- **Langage :** [Dart](https://dart.dev/)
- **Backend & Base de Données :** [Supabase](https://supabase.io/)
- **Gestion d'état :** [Provider](https://pub.dev/packages/provider)
- **Génération de documents :** [pdf](https://pub.dev/packages/pdf) & [excel](https://pub.dev/packages/excel)

## 🚀 Démarrage Rapide

Suivez ces étapes pour lancer le projet sur votre machine locale.

### Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installé.
- Un projet [Supabase](https://supabase.com/) configuré avec le schéma de base de données adéquat.

### 1. Configuration du Backend (Supabase)

Avant de lancer l'application, vous devez la connecter à votre propre projet Supabase.

1.  Créez un projet sur [Supabase](https://app.supabase.com/).
2.  Dans l'éditeur SQL, exécutez les commandes fournies pour créer et configurer les tables (`purchases`, `purchase_items`, `suppliers`, `categories`, `payment_methods`, etc.). Assurez-vous que les politiques de sécurité (RLS) sont activées et configurées.
3.  Récupérez votre **URL de projet** et votre **clé publique anonyme (anon public key)** depuis les paramètres API de votre projet Supabase.

### 2. Configuration du Frontend (Flutter)

1.  Clonez ce dépôt :
    ```sh
    git clone <URL_DU_DEPOT>
    cd ekibamapp
    ```

2.  Modifiez le fichier `lib/main.dart` pour y insérer vos propres clés Supabase :
    ```dart
    // lib/main.dart

    void main() async {
      WidgetsFlutterBinding.ensureInitialized();

      await Supabase.initialize(
        url: 'VOTRE_URL_SUPABASE', // Remplacez par votre URL
        anonKey: 'VOTRE_CLE_ANON_SUPABASE', // Remplacez par votre clé
      );

      runApp(const MyApp());
    }
    ```
    *(Pour une meilleure pratique, il est recommandé de stocker ces clés dans des variables d'environnement ou un fichier de configuration non versionné).*

### 3. Lancement de l'Application

1.  Installez les dépendances :
    ```sh
    flutter pub get
    ```

2.  Lancez l'application sur l'appareil de votre choix (Chrome pour le web) :
    ```sh
    flutter run -d chrome
    ```

L'application devrait maintenant démarrer et se connecter à votre instance Supabase.

## Journal des modifications

### Version 1.2.0 - 31/12/2025
- **Améliorations de l'Interface et de l'Expérience Utilisateur**
  - **Gestion de la Responsivité :** Mise à jour des écrans principaux (Tableau de bord, Formulaire d'achat, Historique) pour une meilleure adaptation aux différentes tailles d'écran (web, mobile).
  - **Gestion des valeurs monétaires :** Toutes les sommes sont maintenant gérées et affichées comme des entiers (FCFA) dans toute l'application et les fichiers exportés.
  - **Limite de Mots pour les Commentaires :** Une limite de 150 mots est maintenant appliquée aux champs de commentaires.
  - **Amélioration des Exports PDF :** Le nom du fichier est maintenant "Demande_Achat" et un champ "Destinataire Budget" a été ajouté, dérivé du champ "Destinataire Budget" du formulaire.
- **Personnalisation et Aide**
  - **Nouveau Splash Screen :** Un écran de chargement avec le logo de l'entreprise a été ajouté.
  - **Icônes d'Application :** Remplacement des icônes par défaut de Flutter par le logo de l'entreprise pour Android, iOS et le web.
  - **Section d'Aide :** Ajout d'un guide d'utilisation accessible depuis le tableau de bord pour expliquer les fonctionnalités clés.
- **Corrections de Bugs et Précisions**
  - Correction de multiples erreurs "Bad state: No element" liées au chargement des catégories et à l'initialisation des formulaires.
  - Amélioration de la robustesse des listes déroulantes pour gérer les cas où les données ne sont pas encore disponibles.
  - **Clarification du rôle de "Destinataire Budget" et correction de l'export Excel :** Le champ "Destinataire Budget" est désormais utilisé uniquement pour le PDF. Les colonnes "Mise_AD_budget" et "Mode_Rglt" du rapport Excel sont désormais correctement dérivées du découpage du "Mode de paiement" (ex: "A/B" donne "A" et "B").

### Version 1.1.0 - 31/12/2025
- **Implémentation des Spécifications du Cahier des Charges**
  - **Refactorisation du Modèle de Données :** Mise à jour complète des modèles (`Purchase`, `PurchaseItem`) et de la base de données pour correspondre aux spécifications.
  - **Nouveau Formulaire d'Achat :** Interface mise à jour avec un système de catégories hiérarchique à 3 niveaux et des champs conditionnels (`clientName`).
  - **Génération de `Ref DA` :** Implémentation de la logique de génération de référence unique `DA-JJMMAAAA-X`.
  - **Exports PDF & Excel :** Les services d'export ont été mis à jour pour générer le "Bon de Commande" et le rapport global de dépenses conformément aux formats spécifiés.
- **Fonctionnalités Dynamiques (suite aux retours)**
  - **Gestion Globale :** Les listes de `Catégories`, `Fournisseurs` et `Modes de Paiement` sont maintenant globales (partagées entre tous les utilisateurs) et chargées depuis la base de données.
  - **Ajout depuis l'UI :** Des boutons (+) permettent d'ajouter de nouvelles entrées pour les catégories, fournisseurs et modes de paiement directement depuis le formulaire.
  - **Gestion de "Aucun" Fournisseur :** L'option "Aucun" est maintenant disponible et gérée correctement.
  - **Champ "Unité" :** Un champ "Unité" a été ajouté pour chaque article.
- **Corrections de Bugs**
  - Correction d'un bug majeur où la saisie dans les champs de texte des articles faisait perdre le focus.
  - Correction de multiples erreurs de compilation et d'exécution liées aux changements de modèle et à l'API de la base de données.

### Version 1.0.1 - 02/12/2025
- **Correction du rendu PDF :**
  - Correction d'un bug visuel où la case à cocher (✓) pour le type de projet ne s'affichait pas dans les factures PDF générées.
  - Remplacement de l'implémentation personnalisée par le widget `Checkbox` standard de la bibliothèque `pdf` pour garantir un affichage fiable et correct sur toutes les plateformes.
  - Suppression d'une case à cocher redondante et toujours activée dans la liste des articles du PDF.