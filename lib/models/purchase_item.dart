import 'package:flutter/foundation.dart';

@immutable
class PurchaseItem {
  final int? id;
  final int _localId; // For stable hashcode on new items
  final int purchaseId;
  final String category;
  final String subCategory1;
  final String? subCategory2;
  final int? supplierId;
  final double quantity; // Quantity can remain double
  final String? unit;
  final int unitPrice;
  final int paymentFee;
  final String? comment;
  final DateTime? choiceDate;

  final String? supplierName;

  PurchaseItem({
    this.id,
    int? localId,
    required this.purchaseId,
    required this.category,
    required this.subCategory1,
    this.subCategory2,
    this.supplierId,
    required this.quantity,
    this.unit,
    required this.unitPrice,
    this.paymentFee = 0,
    this.supplierName,
    this.comment,
    this.choiceDate,
  }) : _localId = localId ?? DateTime.now().millisecondsSinceEpoch;

  int get total => ((quantity * unitPrice) + paymentFee).round();

  int get localId => _localId; // Public getter for _localId


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'category': category,
      'sub_category_1': subCategory1,
      'sub_category_2': subCategory2,
      'supplier_id': supplierId,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'payment_fee': paymentFee,
      'comment': comment,
      'choice_date': choiceDate?.toIso8601String(),
    };
  }

  static PurchaseItem fromMap(Map<String, dynamic> map) {
    final supplierName =
        (map['suppliers'] as Map<String, dynamic>?)?['name'] as String?;

    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: map['purchase_id'] as int? ?? 0,
      category: map['category'] as String? ?? '',
      subCategory1: map['sub_category_1'] as String? ?? '',
      subCategory2: map['sub_category_2'] as String?,
      supplierId: map['supplier_id'] as int?,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String?,
      unitPrice: (map['unit_price'] as num?)?.toInt() ?? 0,
      paymentFee: (map['payment_fee'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String?,
      supplierName: supplierName,
      choiceDate: map['choice_date'] == null
          ? null
          : DateTime.parse(map['choice_date'] as String),
    );
  }

  PurchaseItem copyWith({
    int? id,
    int? localId,
    int? purchaseId,
    String? category,
    String? subCategory1,
    String? subCategory2,
    int? supplierId,
    double? quantity,
    String? unit,
    int? unitPrice,
    int? paymentFee,
    String? supplierName,
    String? comment,
    DateTime? choiceDate,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      localId: localId ?? _localId,
      purchaseId: purchaseId ?? this.purchaseId,
      category: category ?? this.category,
      subCategory1: subCategory1 ?? this.subCategory1,
      subCategory2: subCategory2 ?? this.subCategory2,
      supplierId: supplierId ?? this.supplierId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      paymentFee: paymentFee ?? this.paymentFee,
      supplierName: supplierName ?? this.supplierName,
      comment: comment ?? this.comment,
      choiceDate: choiceDate ?? this.choiceDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          _localId == other._localId;

  @override
  int get hashCode => id.hashCode ^ _localId.hashCode;
}
