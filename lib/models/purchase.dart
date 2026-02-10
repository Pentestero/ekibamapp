import 'package:provisions/models/purchase_item.dart';

class Purchase {
  final int? id;
  final String? refDA;
  final DateTime date;
  final String demander;
  final String projectType;
  final String? clientName;
  final String paymentMethod;
  final String? miseADBudget;
  final String? modeRglt;
  final String comments;
  final DateTime createdAt;
  final DateTime? modifiedAt;

  List<PurchaseItem> items;
  final int grandTotal; // Added grandTotal field

  Purchase({
    this.id,
    this.refDA,
    required this.date,
    required this.demander,
    required this.projectType,
    this.clientName,
    required this.paymentMethod,
    this.miseADBudget,
    this.modeRglt,
    this.comments = '',
    required this.createdAt,
    this.modifiedAt,
    this.items = const [],
    this.grandTotal = 0, // Initialize grandTotal
  });

  // int get totalPaymentFees =>
  //     items.fold(0, (sum, item) => sum + item.paymentFee);

  // int get grandTotal => items.fold(0, (sum, item) => sum + item.total);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'refDA': refDA,
      'date': date.toIso8601String(),
      'demander': demander,
      'projectType': projectType,
      'clientName': clientName,
      'payment_method': paymentMethod,
      'mise_ad_budget': miseADBudget,
      'mode_rglt': modeRglt,
      'comments': comments,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  static Purchase fromMap(Map<String, dynamic> map) {
    final List<PurchaseItem> items =
        ((map['items'] ?? map['purchase_items']) as List<dynamic>?)
                ?.map((itemMap) =>
                    PurchaseItem.fromMap(itemMap as Map<String, dynamic>))
                .toList() ??
            [];

    return Purchase(
      id: map['id'] as int?,
      refDA: map['ref_da'] as String?,
      date:
          map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
      demander: map['demander'] as String? ?? '',
      projectType: map['project_type'] as String? ?? '',
      clientName: map['client_name'] as String?,
      paymentMethod: map['payment_method'] as String? ?? '',
      miseADBudget: map['mise_ad_budget'] as String?,
      modeRglt: map['mode_rglt'] as String?,
      comments: map['comments'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      modifiedAt: map['modified_at'] != null
          ? DateTime.parse(map['modified_at'] as String)
          : null,
      items: items,
      grandTotal: (map['grand_total'] as num?)?.toInt() ??
          items.fold(0, (sum, item) => sum + item.total), // Read grand_total directly and cast to int
    );
  }

  Purchase copyWith({
    int? id,
    String? refDA,
    DateTime? date,
    String? demander,
    String? projectType,
    String? clientName,
    String? paymentMethod,
    String? miseADBudget,
    String? modeRglt,
    String? comments,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<PurchaseItem>? items,
    int? grandTotal,
  }) {
    return Purchase(
      id: id ?? this.id,
      refDA: refDA ?? this.refDA,
      date: date ?? this.date,
      demander: demander ?? this.demander,
      projectType: projectType ?? this.projectType,
      clientName: clientName ?? this.clientName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      miseADBudget: miseADBudget ?? this.miseADBudget,
      modeRglt: modeRglt ?? this.modeRglt,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      items: items ?? this.items,
      grandTotal: grandTotal ?? this.grandTotal,
    );
  }
}