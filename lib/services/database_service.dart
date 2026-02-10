import 'package:provisions/models/purchase_item.dart'; // NEW IMPORT
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/library_item.dart';
import 'package:provisions/models/supplier.dart';
import 'package:intl/intl.dart';
import '../widgets/filter_panel.dart';

class DatabaseService {
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  final _supabase = Supabase.instance.client;

  PostgrestTransformBuilder<List<Map<String, dynamic>>> _applyFiltersAndSorting(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> initialQuery,
    FilterState filters, {
    bool includeUserIdFilter = true,
  }) {
    // Start with the initial query. This will remain a PostgrestFilterBuilder until .order() is called.
    PostgrestFilterBuilder<List<Map<String, dynamic>>> filterableQuery = initialQuery;

    if (includeUserIdFilter) {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        filterableQuery = filterableQuery.eq('user_id', userId);
      }
    }

    if (filters.searchQuery.isNotEmpty) {
      final queryText = filters.searchQuery.toLowerCase();
      filterableQuery = filterableQuery.or(
        'ref_da.ilike.*$queryText*,'
        'demander.ilike.*$queryText*,'
        'client_name.ilike.*$queryText*',
      );
    }

    // Now, apply ordering. This operation changes the type of the builder
    // from PostgrestFilterBuilder to PostgrestTransformBuilder.
    // We return this transformed builder.
    switch (filters.sortOption) {
      case SortOption.amountDesc:
        debugPrint('Warning: Attempting server-side sorting by grand_total (descending).');
        return filterableQuery.order('grand_total', ascending: false); // Assuming 'grand_total' exists in the database.
      case SortOption.amountAsc:
        debugPrint('Warning: Attempting server-side sorting by grand_total (ascending).');
        return filterableQuery.order('grand_total', ascending: true); // Assuming 'grand_total' exists in the database.
      case SortOption.dateDesc: // Fallback to id ordering if dateDesc is selected
      case SortOption.dateAsc: // Fallback to id ordering if dateAsc is selected
      default:
        return filterableQuery.order('id', ascending: false); // Default ordering
    }
  }

  String? _formatDateForRpc(DateTime? date) {
    if (date == null) return null;
    return date.toIso8601String();
  }

  Future<List<Purchase>> getAllPurchases(FilterState filters) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Handle year/month filters or specific start/end dates
      DateTime? effectiveStartDate;
      DateTime? effectiveEndDate;

      if (filters.year != null) {
        effectiveStartDate = DateTime(filters.year!, 1, 1);
        effectiveEndDate = DateTime(filters.year!, 12, 31, 23, 59, 59);

        if (filters.month != null) {
          effectiveStartDate = DateTime(filters.year!, filters.month!, 1);
          effectiveEndDate = DateTime(filters.year!, filters.month! + 1, 0, 23, 59, 59);
        }
      }
      
      // Override with specific startDate/endDate if provided
      if (filters.startDate != null) {
        effectiveStartDate = DateTime(filters.startDate!.year, filters.startDate!.month, filters.startDate!.day, 0, 0, 0);
      }
      if (filters.endDate != null) {
        effectiveEndDate = DateTime(filters.endDate!.year, filters.endDate!.month, filters.endDate!.day, 23, 59, 59);
      }

      // Ensure all RPC parameters are always present, even if null, for function matching
      final rpcParams = <String, dynamic>{
        'user_id_param': userId,
        'search_query_param': filters.searchQuery.isNotEmpty ? filters.searchQuery : null,
        'start_date_param': _formatDateForRpc(effectiveStartDate),
        'end_date_param': _formatDateForRpc(effectiveEndDate),
        'sort_option_param': filters.sortOption.toString().split('.').last,
      };

      final List<dynamic> rpcResult = await _supabase.rpc(
        'get_filtered_purchases_by_item_date',
        params: rpcParams,
      );
      
      // rpcResult is a list of dynamic maps (JSON objects) where each map is a Purchase record
      List<Purchase> purchases = rpcResult.map((p) => Purchase.fromMap(p as Map<String, dynamic>)).toList();
      
      return purchases;
    } catch (e) {
      debugPrint("Erreur lors de la récupération des achats filtrés via RPC: $e");
      rethrow;
    }
  }

  Future<List<Purchase>> getAllPurchasesForAdmin(FilterState filters) async {
    final userId = _supabase.auth.currentUser?.id; // Admin user ID
    if (userId == null) return []; // Should not happen for an authenticated admin

    try {
      // Handle year/month filters or specific start/end dates
      DateTime? effectiveStartDate;
      DateTime? effectiveEndDate;

      if (filters.year != null) {
        effectiveStartDate = DateTime(filters.year!, 1, 1);
        effectiveEndDate = DateTime(filters.year!, 12, 31, 23, 59, 59);

        if (filters.month != null) {
          effectiveStartDate = DateTime(filters.year!, filters.month!, 1);
          effectiveEndDate = DateTime(filters.year!, filters.month! + 1, 0, 23, 59, 59);
        }
      }
      
      // Override with specific startDate/endDate if provided
      if (filters.startDate != null) {
        effectiveStartDate = DateTime(filters.startDate!.year, filters.startDate!.month, filters.startDate!.day, 0, 0, 0);
      }
      if (filters.endDate != null) {
        effectiveEndDate = DateTime(filters.endDate!.year, filters.endDate!.month, filters.endDate!.day, 23, 59, 59);
      }

      // Ensure all RPC parameters are always present, even if null, for function matching
      final rpcParams = <String, dynamic>{
        'user_id_param': null, // Pass null for admin to see all purchases
        'search_query_param': filters.searchQuery.isNotEmpty ? filters.searchQuery : null,
        'start_date_param': _formatDateForRpc(effectiveStartDate),
        'end_date_param': _formatDateForRpc(effectiveEndDate),
        'sort_option_param': filters.sortOption.toString().split('.').last,
      };


      final List<dynamic> rpcResult = await _supabase.rpc(
        'get_filtered_purchases_by_item_date',
        params: rpcParams,
      );
      
      List<Purchase> purchases = rpcResult.map((p) => Purchase.fromMap(p as Map<String, dynamic>)).toList();
      
      return purchases;
    } catch (e) {
      debugPrint("Erreur lors de la récupération de tous les achats (admin) via RPC: $e");
      rethrow;
    }
  }

  Future<Purchase> addPurchase(Purchase purchase, String userId) async {
    try {
      // Prepare the parameters for the RPC call
      final params = {
        'purchase_date': purchase.date.toIso8601String(),
        'demander_name': purchase.demander,
        'project_type_name': purchase.projectType,
        'client_name_text': purchase.clientName,
        'payment_method_name': purchase.paymentMethod,
        'mise_ad_budget_text': purchase.miseADBudget,
        'mode_rglt_text': purchase.modeRglt,
        'comments_text': purchase.comments,
        'creator_user_id': userId,
        'purchase_items': [], // Sending an empty list to the RPC, as items will be inserted separately.
      };

      // Call the database function
      final rpcResult = await _supabase.rpc(
        'create_purchase_with_ref_da',
        params: params,
      );

      // Assuming rpcResult is a Map<String, dynamic> containing the newly created purchase.
      // Adjust this parsing based on the actual return type of your RPC function if it's different.
      final newPurchaseId = rpcResult['id'] as int;

      // Insert purchase items separately, linking them to the newly created purchase ID.
      if (purchase.items.isNotEmpty) {
        final itemsToInsert = purchase.items.map((item) => {
          'purchase_id': newPurchaseId, // Link item to the new purchase ID
          'category': item.category,
          'sub_category_1': item.subCategory1,
          'sub_category_2': item.subCategory2,
          'supplier_id': item.supplierId,
          'quantity': item.quantity,
          'unit': item.unit,
          'unit_price': item.unitPrice,
          'payment_fee': item.paymentFee,
          'comment': item.comment,
          'expense_date': item.expenseDate.toIso8601String(),
          'created_at': item.createdAt?.toIso8601String(),
          'modified_at': item.modifiedAt?.toIso8601String(),
        }).toList();
        await _supabase.from('purchase_items').insert(itemsToInsert);
      }

      // Now, fetch the complete purchase record including its newly inserted items.
      final fetchedPurchaseData = await _supabase
          .from('purchases')
          .select('*, purchase_items(*, suppliers(*))')
          .eq('id', newPurchaseId)
          .single();

      return Purchase.fromMap(fetchedPurchaseData);

    } catch (e) {
      debugPrint("Erreur lors de l'appel RPC pour ajouter l'achat: $e");
      rethrow;
    }
  }

  Future<Purchase> updatePurchase(Purchase purchase) async {
    try {
      final purchaseToUpdate = {
        'ref_da': purchase.refDA,
        'date': purchase.date.toIso8601String(),
        'demander': purchase.demander,
        'project_type': purchase.projectType,
        'client_name': purchase.clientName,
        'payment_method': purchase.paymentMethod,
        'mise_ad_budget': purchase.miseADBudget,
        'mode_rglt': purchase.modeRglt,
        'comments': purchase.comments,
        'modified_at': purchase.modifiedAt?.toIso8601String(),
      };

      await _supabase
          .from('purchases')
          .update(purchaseToUpdate)
          .eq('id', purchase.id!);

      await _supabase
          .from('purchase_items')
          .delete()
          .eq('purchase_id', purchase.id!);

      if (purchase.items.isNotEmpty) {
        final itemsToInsert = purchase.items.map((item) => {
          'purchase_id': purchase.id,
          'category': item.category,
          'sub_category_1': item.subCategory1,
          'sub_category_2': item.subCategory2,
          'supplier_id': item.supplierId,
          'quantity': item.quantity,
          'unit': item.unit,
          'unit_price': item.unitPrice,
          'payment_fee': item.paymentFee,
          'comment': item.comment,
          'expense_date': item.expenseDate.toIso8601String(),
          'created_at': item.createdAt?.toIso8601String(),
          'modified_at': item.modifiedAt?.toIso8601String(),
        }).toList();

        await _supabase.from('purchase_items').insert(itemsToInsert);
      }

      final fetchedPurchaseData = await _supabase
          .from('purchases')
          .select('*, purchase_items(*, suppliers(*))')
          .eq('id', purchase.id!)
          .single();

      return Purchase.fromMap(fetchedPurchaseData);
    } catch (e) {
      if (e is PostgrestException) {
        debugPrint("PostgrestException lors de la mise à jour de l'achat: ${e.message}, Code: ${e.code}, Details: ${e.details}");
      } else {
        debugPrint("Erreur inconnue lors de la mise à jour de l'achat: $e");
      }
      rethrow;
    }
  }

  Future<void> deletePurchase(int id) async {
    try {
      await _supabase.from('purchase_items').delete().eq('purchase_id', id);
      await _supabase.from('purchases').delete().eq('id', id);
    } catch (e) {
      debugPrint("Erreur lors de la suppression de l'achat: $e");
      rethrow;
    }
  }

  Future<List<Supplier>> getSuppliers() async {
    // Suppliers are assumed to be global or not user-specific for now.
    // If they need to be user-specific, the 'user_id' column must exist in the 'suppliers' table.
    try {
      final data = await _supabase.from('suppliers').select();
      return data.map((item) => Supplier.fromMap(item)).toList();
    }
    catch (e) {
      debugPrint("Erreur lors de la récupération des fournisseurs: $e");
      return [];
    }
  }

  Future<Supplier> insertSupplier(Supplier supplier) async {
    try {
      final insertedSupplier = await _supabase
          .from('suppliers')
          .insert({'name': supplier.name})
          .select()
          .single();
      return Supplier.fromMap(insertedSupplier);
    } catch (e) {
      debugPrint("Erreur lors de l'insertion du fournisseur: $e");
      rethrow;
    }
  }

  // --- Payment Methods ---
  Future<List<String>> getPaymentMethods() async {
    try {
      final data = await _supabase.from('payment_methods').select('name');
      return data.map((item) => item['name'] as String).toList();
    } catch (e) {
      debugPrint("Erreur lors de la récupération des modes de paiement: $e");
      return [];
    }
  }

  Future<String> insertPaymentMethod(String name) async {
    try {
      final List existing = await _supabase
          .from('payment_methods')
          .select('name')
          .eq('name', name);

      if (existing.isNotEmpty) {
        return existing.first['name'] as String;
      }

      final inserted = await _supabase
          .from('payment_methods')
          .insert({'name': name})
          .select('name')
          .single();

      return inserted['name'] as String;
    } catch (e) {
      debugPrint("Erreur lors de l'insertion du mode de paiement: $e");
      rethrow;
    }
  }

  // --- Categories ---
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final data = await _supabase.from('categories').select();
      return data.map((item) => item).toList();
    } catch (e) {
      debugPrint("Erreur lors de la récupération des catégories: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> insertCategory({
    required String nameCategory,
    required String nameSubcategory1,
    String? nameSubcategory2,
  }) async {
    try {
      final inserted = await _supabase
          .from('categories')
          .insert({
            'name_category': nameCategory,
            'name_subcategory1': nameSubcategory1,
            'name_subcategory2': nameSubcategory2,
          })
          .select()
          .single();
      return inserted;
    } catch (e) {
      debugPrint("Erreur lors de l'insertion de la catégorie: $e");
      rethrow;
    }
  }

  // --- Library Items ---

  Future<List<LibraryItem>> getLibraryItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final data = await _supabase
          .from('item_library')
          .select()
          .eq('user_id', userId)
          .order('template_name', ascending: true);
      return data.map((item) => LibraryItem.fromMap(item)).toList();
    } catch (e) {
      debugPrint("Erreur lors de la récupération de la bibliothèque d'articles: $e");
      rethrow;
    }
  }

  Future<LibraryItem> addLibraryItem(LibraryItem item) async {
    try {
      final data = await _supabase
          .from('item_library')
          .insert(item.toMap())
          .select()
          .single();
      return LibraryItem.fromMap(data);
    } catch (e) {
      debugPrint("Erreur lors de l'ajout à la bibliothèque d'articles: $e");
      rethrow;
    }
  }

  Future<LibraryItem> updateLibraryItem(LibraryItem item) async {
    try {
      final data = await _supabase
          .from('item_library')
          .update(item.toMap())
          .eq('id', item.id!)
          .select()
          .single();
      return LibraryItem.fromMap(data);
    } catch (e) {
      debugPrint("Erreur lors de la mise à jour de la bibliothèque d'articles: $e");
      rethrow;
    }
  }

  Future<void> deleteLibraryItem(int id) async {
    try {
      await _supabase.from('item_library').delete().eq('id', id);
    } catch (e) {
      debugPrint("Erreur lors de la suppression de la bibliothèque d'articles: $e");
      rethrow;
    }
  }


  /// Vérifie si l'utilisateur actuel est un administrateur en consultant la table app_admins.
  Future<bool> isCurrentUserAdmin() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final data = await _supabase
          .from('app_admins')
          .select('user_id')
          .eq('user_id', userId)
          .single();
      // ignore: unnecessary_null_comparison
      return data != null; // If a row is returned, the user is an admin
    } catch (e) {
      // If no row is found, a PostgrestException might be thrown (no rows)
      // or other errors. In any case, if we can't confirm admin, assume false.
      debugPrint("Erreur vérification admin: $e");
      return false;
    }
  }
}
