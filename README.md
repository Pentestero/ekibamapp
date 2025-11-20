# EKIBAM - Application de Gestion des Achats

EKIBAM est une application multiplateforme (Web, Android, iOS) conçue pour simplifier et professionnaliser la gestion des achats au sein d'une entreprise. Elle permet de suivre les demandes, de gérer les articles, d'analyser les dépenses et de générer des documents officiels comme des factures et des rapports.

## ✨ Fonctionnalités Principales

L'application offre une suite complète d'outils pour une gestion transparente :

### Gestion des Achats
- **Création d'Achats :** Un formulaire dynamique et intuitif pour enregistrer de nouveaux achats.
- **Ajout d'Articles :** Possibilité d'ajouter plusieurs articles à chaque achat, en spécifiant le produit, le fournisseur, la quantité et le prix.
- **Champ Client Dynamique :** Un champ "Nom du client" apparaît automatiquement lorsque le type de projet "Client" est sélectionné, assurant un suivi précis.
- **Mise à Jour et Suppression :** Modifiez ou supprimez facilement des achats existants directement depuis l'historique.

### Historique et Suivi
- **Vue d'Ensemble :** Un écran d'historique liste tous les achats passés avec les informations clés visibles en un coup d'œil.
- **Actions Rapides :** Chaque achat dispose de boutons pour générer une facture PDF, modifier ou supprimer l'enregistrement.
- **Filtres :** Filtrez les achats par période (semaine, mois) pour une analyse ciblée.

### Export et Rapports
- **Factures PDF Uniques :** Générez une facture PDF professionnelle et unique pour n'importe quel achat en un seul clic.
- **Rapports Excel :** Exportez un rapport détaillé de tous les achats au format `.xlsx` pour une analyse approfondie ou un archivage.

### Tableau de Bord (Dashboard)
- **Analyses Visuelles :** Des graphiques présentent des statistiques sur les dépenses, notamment par fournisseur et par type de projet.
- **Indicateurs Clés :** Suivez le total des dépenses et le nombre total d'achats.

### Authentification
- **Système Sécurisé :** Connexion et inscription des utilisateurs pour sécuriser l'accès aux données.

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
2.  Dans l'éditeur SQL, exécutez les commandes pour créer les tables (`purchases`, `purchase_items`, `products`, etc.). Assurez-vous que les politiques de sécurité (RLS) sont activées et configurées pour autoriser les opérations `SELECT`, `INSERT`, `UPDATE`, et `DELETE` pour les utilisateurs authentifiés.
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