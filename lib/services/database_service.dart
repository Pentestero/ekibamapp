import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/purchase_item.dart';
import 'package:provisions/models/supplier.dart';

class DatabaseService {
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  final _supabase = Supabase.instance.client;

  Future<List<Purchase>> getAllPurchases() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await _supabase
          .from('purchases')
          .select('*, purchase_items(*, suppliers(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final purchases = data.map((p) => Purchase.fromMap(p)).toList();
      return purchases;
    } catch (e) {
      debugPrint("Erreur lors de la récupération des achats: $e");
      rethrow;
    }
  }

  Future<List<Purchase>> getAllPurchasesForAdmin() async {
    try {
      final data = await _supabase
          .from('purchases')
          .select('*, purchase_items(*, suppliers(*))')
          .order('created_at', ascending: false);

      final purchases = data.map((p) => Purchase.fromMap(p)).toList();
      return purchases;
    } catch (e) {
      debugPrint("Erreur lors de la récupération de tous les achats (admin): $e");
      rethrow;
    }
  }

  Future<Purchase> addPurchase(Purchase purchase, String userId) async {
    try {
      final purchaseToInsert = {
        // 'ref_da' is initially null
        'date': purchase.date.toIso8601String(),
        'demander': purchase.demander,
        'project_type': purchase.projectType,
        'client_name': purchase.clientName,
        'payment_method': purchase.paymentMethod,
        'mise_ad_budget': purchase.miseADBudget,
        'mode_rglt': purchase.modeRglt,
        'comments': purchase.comments,
        'created_at': purchase.createdAt.toIso8601String(),
        'user_id': userId,
      };

      // 1. Insert purchase to get the unique ID
      final insertedPurchase = await _supabase
          .from('purchases')
          .insert(purchaseToInsert)
          .select()
          .single();

      final newPurchaseId = insertedPurchase['id'];

      // 2. Generate the new Ref DA
      final dateFormatted = DateFormat('ddMMyyyy').format(purchase.date);
      final newRefDA = 'DA-$dateFormatted-$newPurchaseId';

      // 3. Update the purchase with the new Ref DA
      final updatedPurchase = await _supabase
          .from('purchases')
          .update({'ref_da': newRefDA})
          .eq('id', newPurchaseId)
          .select()
          .single();
          
      // 4. Insert purchase items
      if (purchase.items.isNotEmpty) {
        final itemsToInsert = purchase.items.map((item) => {
          'purchase_id': newPurchaseId,
          'category': item.category,
          'sub_category_1': item.subCategory1,
          'sub_category_2': item.subCategory2,
          'supplier_id': item.supplierId,
          'quantity': item.quantity,
          'unit': item.unit,
          'unit_price': item.unitPrice,
          'payment_fee': item.paymentFee,
          'comment': item.comment,
        }).toList();

        await _supabase.from('purchase_items').insert(itemsToInsert);
      }

      // 5. Return the full purchase object with the new Ref DA
      return purchase.copyWith(id: newPurchaseId, refDA: newRefDA);
    } catch (e) {
      debugPrint("Erreur lors de l'ajout de l'achat: $e");
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
        }).toList();

        await _supabase.from('purchase_items').insert(itemsToInsert);
      }

      return purchase;
    } catch (e) {
      debugPrint("Erreur lors de la mise à jour de l'achat: $e");
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
      return data.map((item) => item as Map<String, dynamic>).toList();
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
      return inserted as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Erreur lors de l'insertion de la catégorie: $e");
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
      return data != null; // If a row is returned, the user is an admin
    } catch (e) {
      // If no row is found, a PostgrestException might be thrown (no rows)
      // or other errors. In any case, if we can't confirm admin, assume false.
      debugPrint("Erreur vérification admin: $e");
      return false;
    }
  }
}
