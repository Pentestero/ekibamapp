import 'package:flutter/foundation.dart';

@immutable
class LibraryItem {
  final int? id;
  final String userId;
  final String templateName;
  final String category;
  final String subCategory1;
  final String? subCategory2;
  final int? unitPrice;
  final String? unit;
  final DateTime createdAt;

  const LibraryItem({
    this.id,
    required this.userId,
    required this.templateName,
    required this.category,
    required this.subCategory1,
    this.subCategory2,
    this.unitPrice,
    this.unit,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'template_name': templateName,
      'category': category,
      'sub_category_1': subCategory1,
      'sub_category_2': subCategory2,
      'unit_price': unitPrice,
      'unit': unit,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LibraryItem.fromMap(Map<String, dynamic> map) {
    return LibraryItem(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      templateName: map['template_name'] as String,
      category: map['category'] as String,
      subCategory1: map['sub_category_1'] as String,
      subCategory2: map['sub_category_2'] as String?,
      unitPrice: map['unit_price'] as int?,
      unit: map['unit'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  LibraryItem copyWith({
    int? id,
    String? userId,
    String? templateName,
    String? category,
    String? subCategory1,
    ValueGetter<String?>? subCategory2,
    ValueGetter<int?>? unitPrice,
    ValueGetter<String?>? unit,
    DateTime? createdAt,
  }) {
    return LibraryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateName: templateName ?? this.templateName,
      category: category ?? this.category,
      subCategory1: subCategory1 ?? this.subCategory1,
      subCategory2: subCategory2 != null ? subCategory2() : this.subCategory2,
      unitPrice: unitPrice != null ? unitPrice() : this.unitPrice,
      unit: unit != null ? unit() : this.unit,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
