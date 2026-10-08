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
- **Gestion des Dates de Choix par Article :** Possibilité d'associer une date spécifique à chaque article d'une demande d'achat (DA), visible dans les détails de l'achat, les PDF générés et les exports Excel.
- **Bibliothèque d'Articles Fréquents :** Sauvegardez, gérez et réutilisez des articles fréquemment achetés pour une saisie rapide et efficace dans les formulaires d'achat. Accessible depuis le Tableau de Bord.
- **Rapports Avancés :** Accédez à un nouvel écran de rapports avec des graphiques interactifs des dépenses par catégorie, par fournisseur et par type de projet, incluant des options de filtrage par période.

## 📖 Guide d'utilisation

#### Gestion des champs liés au paiement et au budget

Pour une gestion claire des informations de paiement et du budget, l'application utilise les champs suivants :

*   **Champ "Mode de paiement" (dans le formulaire) :**
    *   Saisissez ici la méthode de paiement utilisée pour l'achat (ex: "Virement Bancaire", "Espèces").
    *   Si vous utilisez un format comme **`PREMIERE_PARTIE / DEUXIEME_PARTIE`** (ex: "ESP / ESP"), la première partie sera utilisée pour la colonne `Mise_AD_budget` dans le rapport Excel, et la deuxième partie pour la colonne `Mode_Rglt`. Si vous n'utilisez pas de `/`, les deux colonnes Excel contiendront la même valeur que le champ.

*   **Champ "Destinataire Budget" (dans le formulaire) :**
    *   Ce champ est une liste déroulante où vous pouvez sélectionner une personne ou un service responsable du budget si cela est différent du "Demandeur" (l'utilisateur connecté).
    *   La valeur sélectionnée ici n'apparaît **que dans le PDF de la "Demande d'Achat"** et uniquement si elle est différente du "Demandeur". Elle n'est **jamais** utilisée dans les rapports Excel.

## 💡 Intégration de l'IA (Scan de Facture)

La fonctionnalité de **Remplissage Automatique des Achats par Scan de Facture grâce à l'IA** est disponible mais nécessite un abonnement mensuel pour être utilisée.

**Objectif de la fonctionnalité :** L'utilisateur pourra prendre une photo ou uploader une facture (image/PDF), et l'application utilisera l'IA pour en extraire automatiquement les informations clés (fournisseur, date, articles, prix, quantités) afin de pré-remplir le formulaire d'achat.

---

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

### 8 Octobre 2026

Refonte visuelle basée sur le design system (Material 3 « Stitch ») et corrections du formulaire d'achat.

-   **Refonte UI/UX :**
    *   **Design System Stitch (M3) :** Alignement complet de la palette de couleurs sur le thème Stitch (seed `#0058BD`, surfaces froides gris-bleu) dans `theme.dart`, en modes clair et sombre.
    *   **Page 1 - Tableau de Bord & Page 2 - Historique :** Intégration du nouveau design (en-têtes, cartes d'achat, filtres, graphiques).
    *   **Page 3 - « Nouvel Achat » :** Formulaire entièrement repensé : bannière IA (Scan de facture / Aperçu), cartes « Informations Générales » et « Articles Commandés », contrôle segmenté du type de projet (Interne / Client / Mixte), sélecteur de fournisseur en bottom sheet, récapitulatif « Grand Total », CTA en dégradé et modales de confirmation.
    *   **Écrans d'Authentification :** Harmonisation de Connexion, Inscription et Réinitialisation du mot de passe (cartes `surfaceContainerLowest`, dégradés `primary → secondaryContainer`).

-   **Corrections de Bugs :**
    *   **Sélecteur de catégories dans « Nouvel Achat » :** Rétablissement du choix de catégorie pour chaque ligne d'article, sous forme d'un sélecteur en cascade (`Catégorie › Sous-catégorie 1 › Sous-catégorie 2 / Article`) ouvert depuis la ligne de catégorie.
    *   **Couleurs codées en dur :** Remplacement des couleurs fixes (`Colors.red`, vert de succès, etc.) par les tokens du thème pour une cohérence totale.
    *   **Robustesse mobile :** Gestion du débordement du montant « Grand Total » sur petits écrans et audit « mobile-first » des écrans restants.

-   **Identité visuelle et PWA :**
    *   **Icônes PWA & Favicon :** Régénération des icônes d'application (`web/icons/*`, y compris *maskable*) et du favicon à partir du logo **EKIBAM**, qui remplace l'icône Flutter par défaut.

### 3 Février 2026

Cette version introduit de nouvelles fonctionnalités majeures et apporte plusieurs corrections :

-   **Nouvelles Fonctionnalités :**
    *   **Date de Choix par Article :** Ajout de la possibilité d'associer une date spécifique à chaque article d'une DA. Cette date est désormais visible dans les détails de l'achat, incluse dans les PDF générés pour les Demandes d'Achat, et présente dans les exports Excel.
    *   **Bibliothèque d'Articles Fréquents :** Implémentation complète d'une bibliothèque pour sauvegarder, gérer (ajouter, modifier, supprimer) et réutiliser des articles fréquemment achetés. Un nouvel écran de gestion est accessible depuis le Tableau de Bord, et la fonction est intégrée au formulaire d'achat pour une saisie rapide.
    *   **Rapports Avancés :** Introduction d'un nouvel écran de rapports accessible depuis le Tableau de Bord. Cet écran propose des graphiques interactifs pour visualiser les dépenses par catégorie, par fournisseur et par type de projet, avec des options de filtrage par période.

-   **Mises à Jour/Corrections :**
    *   **Analyse IA (Scan Facture) :** La fonctionnalité d'analyse de facture par IA est désormais signalée comme nécessitant un abonnement mensuel lorsqu'un utilisateur tente de l'utiliser.
    *   **Affichage de la Date de Choix :** La date de choix des articles est maintenant affichée de manière détaillée dans les cartes d'achat de l'écran d'historique des DA.
    *   **Corrections de Compilation :** Résolution des erreurs de compilation liées au formatage des chaînes de caractères multilignes (`subtitle` des `ListTile`) dans les widgets de la bibliothèque d'articles.
    *   **Optimisation de la Mise à Jour des Articles :** Correction d'un bug dans le `PurchaseProvider` où le champ "commentaire" d'un article n'était pas correctement préservé lors des mises à jour.

### 9 Février 2026

Cette version apporte les corrections de bugs suivantes :

-   **Corrections de Bugs :**
    *   Résolution de l'erreur `RenderFlex overflow` dans `PurchaseFormScreen` pour améliorer la stabilité de l'interface utilisateur.
    *   Correction de l'erreur de chargement des assets pour `EKIBAM.jpg` en ajustant les chemins redondants dans `pdf_service.dart` et `auth_screen.dart`.
    *   Correction des problèmes d'ordre et de nommage des paramètres pour les fonctions RPC de la base de données `get_filtered_purchases_by_item_date` et `create_purchase_with_ref_da` afin d'assurer une récupération correcte des données et la création des achats.

### Version 1.4.0 - Janvier 2026

Cette version apporte une refonte majeure de l'expérience utilisateur, des fonctionnalités avancées de filtrage/export et corrige des bugs critiques.

-   **Refonte UI/UX Générale :**
    *   **Splash Screen Animé :** Nouvelle animation professionnelle au démarrage de l'application.
    *   **Écrans d'Authentification Modernisés :** Design épuré, animations fluides et mise en page optimisée.
    *   **Animations sur le Tableau de Bord :** Ajout d'animations "flip" subtiles aux cartes d'analyse.
    *   **Squelettes de Chargement (Shimmer) :** Remplacement des indicateurs de chargement génériques par des effets "shimmer" pour une meilleure perception des performances sur tous les écrans principaux.
    *   **Styles Unifiés :** Harmonisation des styles de formulaires (InputDecoration avec OutlineInputBorder) et de boutons pour une cohérence visuelle.
    *   **Thème d'AppBar Amélioré :** Refonte des `AppBar` du `DashboardScreen` et `AdminDashboardScreen` pour un look plus moderne et attrayant, avec consolidation des actions secondaires dans un menu "Plus d'options" (`Icons.more_vert`).
    *   **Détails Captivants sur `PurchaseCard` :** Dans l'historique, les cartes d'achat affichent désormais un résumé des articles inclus pour une meilleure densité d'information.

-   **Filtrage et Exportation Avancés :**
    *   **Panneau de Filtres Complet :** Introduction d'un panneau de filtres centralisé (`FilterPanel`) pour l'historique et le tableau de bord admin, incluant :
        *   Recherche par mot-clé (Ref DA, Demandeur, Client, Catégorie, Articles).
        *   Filtrage par Année et par Mois.
        *   Options de Tri (par Date ou par Montant, croissant/décroissant).
    *   **Chips de Filtres Actifs :** Affichage visuel des filtres appliqués sous forme de "chips" dynamiques, avec possibilité de les supprimer individuellement.
    *   **Mode de Sélection pour l'Export :** Ajout d'un mode permettant de cocher manuellement des achats dans la liste. Le bouton d'export s'adapte pour "Exporter la sélection" (désactivé si rien n'est coché) ou "Exporter la liste filtrée" (si aucune sélection active).

-   **Corrections de Bugs Critiques :**
    *   **Référence d'Achat (`Ref DA`) :** Résolution définitive du problème de doublons via une fonction PostgreSQL atomique (`create_purchase_with_ref_da`) utilisant une table de compteurs journaliers.
    *   **Filtre par Mois :** Correction d'un bug où la désélection du filtre de mois provoquait une erreur.
    *   **Débordement de l'AppBar :** Résolution des problèmes de `RenderFlex overflow` dans les `AppBar`s sur petits écrans grâce à la consolidation des actions.
    *   **Débordement du `DataTable` :** Le tableau des articles dans `PurchaseDetailScreen` gère désormais le défilement horizontal sur les écrans plus larges pour éviter les débordements.
    *   **Changement de Devise :** Remplacement global de "FCFA" par "XAF" dans toute l'application et les exports.

-   **Statut du Problème d'Export Excel ('PU' et 'Total' non calculables) :**
    *   Identifié comme une limitation du package `excel` (v4.0.0). Malgré l'utilisation de `IntCellValue`, les tentatives de forcer le format numérique via `NumFormat` ou `cell.cellType` ont échoué en compilation. Les cellules sont exportées comme des entiers bruts, mais leur interprétation par Excel comme "texte" ou "général" qui bloque les calculs ne peut être résolue sans :
        *   Mise à jour du package `excel` (recommandé si la version 4.0.0 est trop ancienne).
        *   Changement de package d'export Excel.
        *   Formatage manuel dans Excel par l'utilisateur.

### Version 1.3.0 - 31/12/2025
-   **Mise en Place du Rôle Administrateur**
    -   **Gestion des Rôles :** Implémentation d'un système de rôles admin via une table `app_admins` dans la base de données.
    -   **Mise à Jour des Politiques de Sécurité (RLS) :** Les politiques de sécurité ont été mises à jour pour permettre aux administrateurs de voir toutes les données des achats.
-   **Création du Tableau de Bord Administrateur**
    -   **Nouvel Écran Admin :** Un nouvel écran "Dashboard Admin" a été créé, visible uniquement par les utilisateurs admins.
    -   **Vue Globale :** Le tableau de bord admin affiche désormais tous les achats de tous les utilisateurs, avec des indicateurs clés globaux.
    -   **Détails des Achats :** Chaque achat dans la liste admin est cliquable et mène à une page de détail.
    -   **Fonctionnalités de Recherche et Export :** Une barre de recherche et un bouton pour exporter toutes les données vers Excel ont été ajoutés.
-   **Améliorations de l'Interface et de l'Expérience Utilisateur**
    -   **Écran d'Authentification :** L'écran d'authentification a été rendu "responsive" avec une mise en page améliorée pour les grands écrans.
    -   **Messages d'Erreur :** L'affichage des messages d'erreur sur les écrans de connexion et d'inscription a été amélioré pour une meilleure visibilité.
    -   **Correction de Text Overflow :** Des problèmes de débordement de texte sur le tableau de bord ont été corrigés.
-   **Correction de Bugs Majeurs**
    -   **Référence d'Achat (`Ref DA`) :** La logique de génération a été déplacée côté serveur pour garantir une unicité globale et éviter les doublons.
    -   **Réinitialisation de Mot de Passe :** Le flux de réinitialisation de mot de passe a été corrigé pour gérer correctement les redirections et éviter l'erreur `Code verifier not found`.
    -   **Correction des Erreurs de Compilation :** Multiples erreurs de compilation liées aux dépendances et à la syntaxe ont été résolues.

### Version 1.1.0 - 31/12/2025
-   **Implémentation des Spécifications du Cahier des Charges**
    -   **Refactorisation du Modèle de Données :** Mise à jour complète des modèles (`Purchase`, `PurchaseItem`) et de la base de données pour correspondre aux spécifications.
    -   **Nouveau Formulaire d'Achat :** Interface mise à jour avec un système de catégories hiérarchique à 3 niveaux et des champs conditionnels (`clientName`).
    -   **Génération de `Ref DA` :** Implémentation de la logique de génération de référence unique `DA-JJMMAAAA-X`.
    -   **Exports PDF & Excel :** Les services d'export ont été mis à jour pour générer le "Bon de Commande" et le rapport global de dépenses conformément aux formats spécifiés.
-   **Fonctionnalités Dynamiques (suite aux retours)**
    -   **Gestion Globale :** Les listes de `Catégories`, `Fournisseurs` et `Modes de Paiement` sont maintenant globales (partagées entre tous les utilisateurs) et chargées depuis la base de données.
    -   **Ajout depuis l'UI :** Des boutons (+) permettent d'ajouter de nouvelles entrées pour les catégories, fournisseurs et modes de paiement directement depuis le formulaire.
    -   **Gestion de "Aucun" Fournisseur :** L'option "Aucun" est maintenant disponible et gérée correctement.
    -   **Champ "Unité" :** Un champ "Unité" a été ajouté pour chaque article.
-   **Corrections de Bugs**
    -   Correction d'un bug majeur où la saisie dans les champs de texte des articles faisait perdre le focus.
    -   Correction de multiples erreurs de compilation et d'exécution liées aux changements de modèle et à l'API de la base de données.

### Version 1.0.1 - 02/12/2025
-   **Correction du rendu PDF :**
    -   Correction d'un bug visuel où la case à cocher (✓) pour le type de projet ne s'affichait pas dans les factures PDF générées.
    -   Remplacement de l'implémentation personnalisée par le widget `Checkbox` standard de la bibliothèque `pdf` pour garantir un affichage fiable et correct sur toutes les plateformes.
    -   Suppression d'une case à cocher redondante et toujours activée dans la liste des articles du PDF.