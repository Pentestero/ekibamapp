import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/purchase_item.dart';
import 'package:provisions/models/supplier.dart';
import 'package:provisions/services/database_service.dart';
import 'package:provisions/services/excel_service.dart';
import 'package:provisions/services/pdf_service.dart';

const List<String> _projectTypes = ['Client', 'Interne', 'Mixte'];

class PurchaseProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;
  User? _user;

  List<Purchase> _purchases = [];
  List<Purchase> _allPurchases = []; // For admin view
  List<Supplier> _suppliers = [];
  List<String> _requesters = [];
  List<String> _paymentMethods = [];

  Map<String, Map<String, List<String>>> _categories = {};

  bool _isLoading = true;
  String _errorMessage = '';
  int? _editingPurchaseId;

  Purchase _purchaseBuilder = Purchase(
    date: DateTime.now(),
    demander: '',
    projectType: _projectTypes.first,
    paymentMethod: '',
    createdAt: DateTime.now(),
  );
  List<PurchaseItem> _itemsBuilder = [];

  List<Purchase> get purchases => _purchases;
  List<Purchase> get allPurchases => _allPurchases; // Getter for admin
  List<Supplier> get suppliers => _suppliers;
  List<String> get requesters => _requesters;
  List<String> get projectTypes => _projectTypes;
  List<String> get paymentMethods => _paymentMethods;
  Map<String, Map<String, List<String>>> get categories => _categories;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isEditing => _editingPurchaseId != null;

  String? get currentUserId => _user?.id;

  Map<String, int> get supplierTotals => _calculateAnalytics(
      (item) => item.supplierName ?? 'Aucun', (item) => item.total);
  Map<String, int> get projectTypeTotals => _calculateAnalytics(
      (purchase) => purchase.projectType, (purchase) => purchase.grandTotal,
      isPurchaseLevel: true);
  int get totalSpent =>
      _purchases.fold(0, (sum, p) => sum + p.grandTotal);
  int get totalPurchases => _purchases.length;

  // Admin analytics
  int get grandTotalSpentAll => _allPurchases.fold(0, (sum, p) => sum + p.grandTotal);
  int get totalNumberOfPurchasesAll => _allPurchases.length;
  Map<String, int> get topSpenders => _calculateAdminAnalytics(
        (p) => p.demander, (p) => p.grandTotal);
  Map<String, int> get topPaymentMethods => _calculateAdminAnalytics(
        (p) => p.paymentMethod, (p) => p.grandTotal);

  Purchase get purchaseBuilder => _purchaseBuilder;
  List<PurchaseItem> get itemsBuilder => _itemsBuilder;
  int get grandTotalBuilder =>
      _itemsBuilder.fold(0, (sum, item) => sum + item.total);

  Future<void> initialize(User user) async {
    _user = user;
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadPurchases(notify: false),
      _loadSuppliers(),
      _loadRequesters(),
      _loadPaymentMethods(),
      _loadCategories(),
    ]);
    _resetPurchaseBuilder();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPurchases({bool notify = true}) async {
    if (_user == null) return;
    if (notify) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    }

    try {
      _purchases = await _dbService.getAllPurchases();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur chargement achats: $e';
    } finally {
      if (notify) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadAllPurchases({bool notify = true}) async {
    if (_user == null) return;
    if (notify) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    }

    try {
      _allPurchases = await _dbService.getAllPurchasesForAdmin();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Erreur chargement de tous les achats (admin): $e';
    } finally {
      if (notify) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<Purchase?> addPurchase() async {
    if (_user == null) {
      _errorMessage = 'Utilisateur non authentifié.';
      notifyListeners();
      return null;
    }
    if (_itemsBuilder.isEmpty) {
      _errorMessage = 'Veuillez ajouter au moins un article.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final purchaseToSave = await _preparePurchaseForSaving();
      final newPurchase =
          await _dbService.addPurchase(purchaseToSave, _user!.id);

      _purchases.insert(0, newPurchase);
      clearForm();
      return newPurchase;
    } catch (e) {
      _errorMessage = "Erreur lors de l'ajout: $e";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Purchase?> updatePurchase() async {
    if (!isEditing || _editingPurchaseId == null) {
      _errorMessage = "Aucun achat n'est en cours de modification.";
      notifyListeners();
      return null;
    }
    if (_itemsBuilder.isEmpty) {
      _errorMessage = 'Veuillez ajouter au moins un article.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final purchaseToSave = await _preparePurchaseForSaving();
      final updatedPurchase = await _dbService.updatePurchase(purchaseToSave);

      final index = _purchases.indexWhere((p) => p.id == _editingPurchaseId);
      if (index != -1) {
        _purchases[index] = updatedPurchase;
      } else {
        await loadPurchases(notify: false); // Fallback
      }

      clearForm();
      return updatedPurchase;
    } catch (e) {
      _errorMessage = "Erreur lors de la mise à jour: $e";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePurchase(int id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _dbService.deletePurchase(id);
      _purchases.removeWhere((purchase) => purchase.id == id);
      _errorMessage = '';
    } catch (e) {
      _errorMessage = "Erreur lors de la suppression: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadPurchaseForEditing(Purchase purchase) {
    _editingPurchaseId = purchase.id;
    _purchaseBuilder = purchase.copyWith();
    _itemsBuilder =
        List<PurchaseItem>.from(purchase.items.map((item) => item.copyWith()));
    notifyListeners();
  }

  void clearForm() {
    _editingPurchaseId = null;
    _resetPurchaseBuilder();
    _itemsBuilder = [];
    notifyListeners();
  }

  void _resetPurchaseBuilder() {
    if (_user == null) return;
    String initialPaymentMethod =
        _paymentMethods.isNotEmpty ? _paymentMethods.first : '';
    // Determine initial category values for new items
    String initialCategory = '';
    String initialSubCategory1 = '';
    String? initialSubCategory2;

    if (_categories.isNotEmpty) {
      initialCategory = _categories.keys.first;
      if (_categories[initialCategory] != null && _categories[initialCategory]!.isNotEmpty) {
        initialSubCategory1 = _categories[initialCategory]!.keys.first;
        if (_categories[initialCategory]![initialSubCategory1] != null && _categories[initialCategory]![initialSubCategory1]!.isNotEmpty) {
          initialSubCategory2 = _categories[initialCategory]![initialSubCategory1]!.first;
        }
      }
    }

    _purchaseBuilder = Purchase(
      date: DateTime.now(),
      demander: _user?.userMetadata?['name'] ?? '',
      projectType: _projectTypes.first,
      paymentMethod: initialPaymentMethod,
      createdAt: DateTime.now(),
      miseADBudget: null,
    );
  }

  Future<Purchase> _preparePurchaseForSaving() async {
    final now = DateTime.now();

    return _purchaseBuilder.copyWith(
      id: _editingPurchaseId,
      demander: _user?.userMetadata?['name'] ?? _purchaseBuilder.demander,
      items: _itemsBuilder,
      createdAt: _editingPurchaseId == null ? now : _purchaseBuilder.createdAt,
      modeRglt: _purchaseBuilder.paymentMethod,
    );
  }

  String? addNewItem() {
    if (_categories.isEmpty) {
      final error = "Veuillez ajouter au moins une catégorie via le bouton (+).";
      _errorMessage = error;
      notifyListeners();
      return error;
    }
    if (_suppliers.isEmpty) {
      final error = "Veuillez ajouter au moins un fournisseur via le bouton (+).";
      _errorMessage = error;
      notifyListeners();
      return error;
    }

    // Safely get the first category and subcategories
    String firstCategory = _categories.keys.first;
    String firstSubCategory1 = '';
    String? firstSubCategory2;

    if (_categories[firstCategory] != null && _categories[firstCategory]!.isNotEmpty) {
      firstSubCategory1 = _categories[firstCategory]!.keys.first;
      if (_categories[firstCategory]![firstSubCategory1] != null && _categories[firstCategory]![firstSubCategory1]!.isNotEmpty) {
        firstSubCategory2 = _categories[firstCategory]![firstSubCategory1]!.first;
      }
    }

    // Safely get the first supplier
    final firstSupplier = _suppliers.first;
    final int? supplierId = (firstSupplier.id == -1) ? null : firstSupplier.id;
    final String? supplierName = (firstSupplier.id == -1) ? null : firstSupplier.name;


    final newItem = PurchaseItem(
      purchaseId: _editingPurchaseId ?? 0,
      category: firstCategory,
      subCategory1: firstSubCategory1,
      subCategory2: firstSubCategory2,
      supplierId: supplierId,
      quantity: 1.0,
      unitPrice: 0,
      supplierName: supplierName,
    );
    _itemsBuilder.add(newItem);
    _errorMessage = '';
    notifyListeners();
    return null;
  }

  void removeItem(int index) {
    if (index >= 0 && index < _itemsBuilder.length) {
      _itemsBuilder.removeAt(index);
      notifyListeners();
    }
  }

  void updateItem(
    int index, {
    String? category,
    String? subCategory1,
    String? subCategory2,
    int? supplierId,
    double? quantity,
    String? unit,
    int? unitPrice,
  }) {
    if (index < 0 || index >= _itemsBuilder.length) return;
    final oldItem = _itemsBuilder[index];

    // --- Supplier Logic (preserved) ---
    final int effectiveSupplierId = supplierId ?? oldItem.supplierId ?? -1;
    final Supplier selectedSupplier = _suppliers.firstWhere(
      (s) => s.id == effectiveSupplierId,
      orElse: () => _suppliers.firstWhere((s) => s.id == -1),
    );
    final int? itemSupplierId = (selectedSupplier.id == -1) ? null : selectedSupplier.id;
    final String? itemSupplierName = (selectedSupplier.id == -1) ? null : selectedSupplier.name;

    // --- New Category Logic ---
    // This correctly handles updates. If a category or subcategory1 is changed,
    // we take the new subCategory2 value as authoritative (even if it's null).
    // Otherwise (e.g., updating quantity), we preserve the old subCategory2.
    final bool isCategoryUpdate = category != null || subCategory1 != null;
    final String? finalSubCategory2 = isCategoryUpdate
        ? subCategory2
        : (subCategory2 ?? oldItem.subCategory2);

    _itemsBuilder[index] = PurchaseItem(
      id: oldItem.id,
      localId: oldItem.localId,
      purchaseId: oldItem.purchaseId,
      category: category ?? oldItem.category,
      subCategory1: subCategory1 ?? oldItem.subCategory1,
      subCategory2: finalSubCategory2, // Use the corrected value
      supplierId: itemSupplierId,
      quantity: quantity ?? oldItem.quantity,
      unit: unit ?? oldItem.unit,
      unitPrice: unitPrice ?? oldItem.unitPrice,
      paymentFee: oldItem.paymentFee,
      supplierName: itemSupplierName,
      comment: oldItem.comment,
    );
    notifyListeners();
  }

  void updateItemComment(int index, String? comment) {
    if (index < 0 || index >= _itemsBuilder.length) return;
    final oldItem = _itemsBuilder[index];
    _itemsBuilder[index] = PurchaseItem(
      id: oldItem.id,
      localId: oldItem.localId,
      purchaseId: oldItem.purchaseId,
      category: oldItem.category,
      subCategory1: oldItem.subCategory1,
      subCategory2: oldItem.subCategory2,
      supplierId: oldItem.supplierId,
      quantity: oldItem.quantity,
      unit: oldItem.unit,
      unitPrice: oldItem.unitPrice,
      paymentFee: oldItem.paymentFee,
      supplierName: oldItem.supplierName,
      comment: (comment == null || comment.isEmpty) ? null : comment, // Explicitly nullify if empty
    );
    notifyListeners();
  }

  void updatePurchaseHeader({
    DateTime? date,
    String? demander,
    String? projectType,
    String? clientName,
    String? paymentMethod,
    String? comments,
    String? miseADBudget,
  }) {
    _purchaseBuilder = _purchaseBuilder.copyWith(
      date: date,
      demander: demander,
      projectType: projectType,
      clientName: clientName,
      paymentMethod: paymentMethod,
      comments: comments,
      miseADBudget: miseADBudget,
    );
    notifyListeners();
  }

  Future<void> _loadSuppliers() async {
    List<Supplier> fetchedSuppliers = await _dbService.getSuppliers();
    
    // Remove "Aucun" if it exists from the DB list, to avoid duplicates
    fetchedSuppliers.removeWhere((s) => s.name == 'Aucun');
    
    // Sort the rest alphabetically
    fetchedSuppliers.sort((a, b) => a.name.compareTo(b.name));

    // Add our special "Aucun" at the beginning with a dummy ID
    _suppliers = [Supplier(id: -1, name: 'Aucun'), ...fetchedSuppliers];
  }
  Future<void> _loadRequesters() async {
    _requesters = ['CET', 'AOW', 'CNO', 'JMV', 'MNG'];
  }

  Future<void> _loadPaymentMethods() async {
    _paymentMethods = await _dbService.getPaymentMethods();
  }

  Future<String> addNewPaymentMethod({required String name}) async {
    if (_user == null) throw Exception('User not authenticated');
    final savedPaymentMethod =
        await _dbService.insertPaymentMethod(name);
    await _loadPaymentMethods();
    updatePurchaseHeader(paymentMethod: savedPaymentMethod);
    return savedPaymentMethod;
  }

  Future<void> _loadCategories() async {
    final rawCategories = await _dbService.getCategories();
    _categories = {};
    for (var cat in rawCategories) {
      final category = cat['name_category'] as String;
      final subCategory1 = cat['name_subcategory1'] as String;
      final subCategory2 = cat['name_subcategory2'] as String?;

      _categories.putIfAbsent(category, () => {});
      _categories[category]!.putIfAbsent(subCategory1, () => []);
      if (subCategory2 != null) {
        _categories[category]![subCategory1]!.add(subCategory2);
      }
    }
  }

  Future<Map<String, dynamic>> addNewCategory({
    required String category,
    required String subCategory1,
    String? subCategory2,
  }) async {
    final newCat = await _dbService.insertCategory(
      nameCategory: category,
      nameSubcategory1: subCategory1,
      nameSubcategory2: subCategory2,
    );
    await _loadCategories();
    notifyListeners();
    return newCat;
  }

  Future<Supplier> addNewSupplier({required String name}) async {
    if (_user == null) throw Exception('User not authenticated');
    final newSupplier =
        await _dbService.insertSupplier(Supplier(name: name));
    await _loadSuppliers();
    notifyListeners();
    return newSupplier;
  }

  Future<String> addNewRequester({required String name}) async {
    if (!_requesters.contains(name)) {
      _requesters.add(name);
      _requesters.sort();
      notifyListeners();
    }
    return name;
  }

  Future<void> exportToExcel(List<Purchase> purchasesToExport) async {
    _isLoading = true;
    notifyListeners();
    await ExcelService.shareExcelReport(purchasesToExport);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> exportInvoiceToPdf(Purchase purchase) async {
    _isLoading = true;
    notifyListeners();
    await PdfService.generateInvoicePdf(purchase);
    _isLoading = false;
    notifyListeners();
  }

  // NOTE: This method was removed as per the new PDF service.
  // Future<void> exportPurchaseListToPdf() async {
  //   _isLoading = true;
  //   notifyListeners();
  //   await PdfService.generatePurchaseListPdf(_purchases);
  //   _isLoading = false;
  //   notifyListeners();
  // }

  Map<String, int> _calculateAnalytics(
      Function(dynamic) getKey, Function(dynamic) getValue,
      {bool isPurchaseLevel = false}) {
    final Map<String, int> totals = {};
    final Iterable<dynamic> items =
        isPurchaseLevel ? _purchases : _purchases.expand((p) => p.items);
    for (final item in items) {
      final key = getKey(item);
      totals[key] = (totals[key] ?? 0) + (getValue(item) as int);
    }
    return totals;
  }

  Map<String, int> _calculateAdminAnalytics(
      String Function(Purchase) getKey, int Function(Purchase) getValue) {
    final Map<String, int> totals = {};
    for (final purchase in _allPurchases) {
      final key = getKey(purchase);
      totals[key] = (totals[key] ?? 0) + getValue(purchase);
    }
    return totals;
  }


}