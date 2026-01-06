# EKIBAM - Application de Gestion des Achats

EKIBAM est une application multiplateforme (Web, Android, iOS) conçue pour simplifier et professionnaliser la gestion des achats au sein d'une entreprise. Elle permet de suivre les demandes, de gérer les articles, d'analyser les dépenses et de générer des documents officiels comme des demandes d'achat et des rapports.

## ✨ Fonctionnalités Principales

L'application offre une suite complète d'outils pour une gestion transparente :

- **Gestion des Achats :** Un formulaire de saisie complet et responsive pour créer et éditer les demandes d'achat.
- **Hiérarchie de Catégories :** Un système de catégories à 3 niveaux (`Catégorie` -> `Sous-catégorie 1` -> `Article`) pour une classification précise des dépenses.
- **Gestion Dynamique des Données :** Possibilité d'ajouter de nouvelles **Catégories**, de nouveaux **Fournisseurs** et de nouveaux **Modes de Paiement** directement depuis l'interface utilisateur.
- **Génération de Référence Unique :** Création automatique d'une `Ref DA` globalement unique pour chaque nouvel achat.
- **Historique et Suivi :** Un écran d'historique responsive liste tous les achats passés avec des filtres par période (semaine, mois).
- **Actions Rapides :** Chaque achat dispose de boutons pour générer une "Demande d'Achat" PDF, modifier ou supprimer l'enregistrement.
- **Export et Rapports :** Exportez un rapport global des dépenses au format `.xlsx` ou générez des PDF individuels pour chaque demande d'achat.
- **Tableau de Bord (Dashboard) :** Des graphiques et indicateurs clés présentent des statistiques sur les dépenses par fournisseur et par type de projet.
- **Interface Personnalisable :** Changez le thème de couleurs et basculez entre le mode clair et sombre.
- **Authentification Sécurisée :** Connexion, inscription et réinitialisation de mot de passe pour sécuriser l'accès aux données.
- **Guide d'utilisation intégré :** Une section d'aide est disponible directement dans l'application pour guider les utilisateurs.
- **Tableau de Bord Administrateur :** Un dashboard sécurisé, visible uniquement par les admins, permettant de voir, rechercher, et exporter tous les achats de tous les utilisateurs.

## 📖 Guide d'utilisation

#### Gestion des champs liés au paiement et au budget

Pour une gestion claire des informations de paiement et du budget, l'application utilise les champs suivants :

*   **Champ "Mode de paiement" (dans le formulaire) :**
    *   Saisissez ici la méthode de paiement utilisée pour l'achat (ex: "Virement Bancaire", "Espèces").
    *   Si vous utilisez un format comme **`PREMIERE_PARTIE / DEUXIEME_PARTIE`** (ex: "ESP / ESP"), la première partie sera utilisée pour la colonne `Mise_AD_budget` dans le rapport Excel, et la deuxième partie pour la colonne `Mode_Rglt`. Si vous n'utilisez pas de `/`, les deux colonnes Excel contiendront la même valeur que le champ.

*   **Champ "Destinataire Budget" (dans le formulaire) :**
    *   Ce champ est une liste déroulante où vous pouvez sélectionner une personne ou un service responsable du budget si cela est différent du "Demandeur" (l'utilisateur connecté).
    *   La valeur sélectionnée ici n'apparaît **que dans le PDF de la "Demande d'Achat"** et uniquement si elle est différente du "Demandeur". Elle n'est **jamais** utilisée dans les rapports Excel.

## 🚧 Fonctionnalités en Cours

- **Amélioration du Tableau de Bord Administrateur :**
  - Ajout de statistiques avancées (ex: "Top 5 des demandeurs", "Top 5 des méthodes de paiement").
  - Intégration de graphiques pour visualiser ces nouvelles statistiques.

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

1.  Créez un projet sur [Supabase](https://app.supabase.com/).
2.  Dans l'éditeur SQL, exécutez les commandes fournies pour créer les tables (`purchases`, `purchase_items`, etc.) et les politiques de sécurité (RLS).
3.  Récupérez votre **URL de projet** et votre **clé publique anonyme (anon public key)** depuis les paramètres API de votre projet Supabase.

### 2. Configuration du Frontend (Flutter)

1.  Clonez ce dépôt.
2.  Modifiez le fichier `lib/main.dart` pour y insérer vos propres clés Supabase :
    ```dart
    // lib/main.dart
    await Supabase.initialize(
      url: 'VOTRE_URL_SUPABASE',
      anonKey: 'VOTRE_CLE_ANON_SUPABASE',
    );
    ```

### 3. Lancement de l'Application

1.  Installez les dépendances :
    ```sh
    flutter pub get
    ```

2.  Lancez l'application sur le web avec un port fixe :
    ```sh
    flutter run -d chrome --web-hostname localhost --web-port 3000
    ```

## Journal des modifications

### Version 1.3.0 - 31/12/2025
- **Mise en Place du Rôle Administrateur**
  - **Gestion des Rôles :** Implémentation d'un système de rôles admin via une table `app_admins` dans la base de données.
  - **Mise à Jour des Politiques de Sécurité (RLS) :** Les politiques de sécurité ont été mises à jour pour permettre aux administrateurs de voir toutes les données des achats.
- **Création du Tableau de Bord Administrateur**
  - **Nouvel Écran Admin :** Un nouvel écran "Dashboard Admin" a été créé, visible uniquement par les utilisateurs admins.
  - **Vue Globale :** Le tableau de bord admin affiche désormais tous les achats de tous les utilisateurs, avec des indicateurs clés globaux.
  - **Détails des Achats :** Chaque achat dans la liste admin est cliquable et mène à une page de détail.
  - **Fonctionnalités de Recherche et Export :** Une barre de recherche et un bouton pour exporter toutes les données vers Excel ont été ajoutés.
- **Améliorations de l'Interface et de l'Expérience Utilisateur**
  - **Écran d'Authentification :** L'écran d'authentification a été rendu "responsive" avec une mise en page améliorée pour les grands écrans.
  - **Messages d'Erreur :** L'affichage des messages d'erreur sur les écrans de connexion et d'inscription a été amélioré pour une meilleure visibilité.
  - **Correction de Text Overflow :** Des problèmes de débordement de texte sur le tableau de bord ont été corrigés.
- **Correction de Bugs Majeurs**
  - **Référence d'Achat (`Ref DA`) :** La logique de génération a été déplacée côté serveur pour garantir une unicité globale et éviter les doublons.
  - **Réinitialisation de Mot de Passe :** Le flux de réinitialisation de mot de passe a été corrigé pour gérer correctement les redirections et éviter l'erreur `Code verifier not found`.
  - **Correction des Erreurs de Compilation :** Multiples erreurs de compilation liées aux dépendances et à la syntaxe ont été résolues.

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
