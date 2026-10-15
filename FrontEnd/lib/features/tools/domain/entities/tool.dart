import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════
// Status enum
// ═══════════════════════════════════════════════════════════════
enum ToolStatus {
  available,   // متاح للبيع
  reserved,    // محجوز — طلب شراء معتمد
  sold,        // مبيع
  archived;    // مؤرشف — لا يظهر للآخرين

  static ToolStatus fromString(String value) {
    return ToolStatus.values.firstWhere(
          (e) => e.name == value,
      orElse: () => ToolStatus.available,
    );
  }

  bool get isAvailable => this == ToolStatus.available;
  bool get isReserved => this == ToolStatus.reserved;
  bool get isSold => this == ToolStatus.sold;
  bool get isArchived => this == ToolStatus.archived;

  /// Only `available` items can be edited / have images changed.
  /// Reserved has an active order; sold / archived are frozen.
  bool get isEditable => this == ToolStatus.available;
}

// ═══════════════════════════════════════════════════════════════
// Nested brief
// ═══════════════════════════════════════════════════════════════
class ToolSellerBrief extends Equatable {
  const ToolSellerBrief({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  final int id;
  final String fullName;
  final String phone;

  factory ToolSellerBrief.fromJson(Map<String, dynamic> json) =>
      ToolSellerBrief(
        id: (json['id'] as num).toInt(),
        fullName: json['full_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
  };

  @override
  List<Object?> get props => [id, fullName, phone];
}

// ═══════════════════════════════════════════════════════════════
// Main entity — mirrors `ToolResponse` from the backend.
// ═══════════════════════════════════════════════════════════════
class Tool extends Equatable {
  const Tool({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.category,
    required this.condition,
    required this.price,
    required this.imageUrls,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.seller,
  });

  final int id;
  final int sellerId;
  final String name;
  final String description;
  final String category;
  final String condition;
  final double price;
  final List<String> imageUrls;
  final ToolStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ToolSellerBrief? seller;

  // ─── Convenience ──────────────────────────────────────
  bool get hasImages => imageUrls.isNotEmpty;
  int get imageCount => imageUrls.length;
  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  bool get canBeEdited => status.isEditable;
  bool get canBeOrdered => status.isAvailable;

  // ─── JSON round-trip (network + cache) ─────────────────
  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
    id: (json['id'] as num).toInt(),
    sellerId: (json['seller_id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? '',
    condition: json['condition'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    imageUrls: List<String>.from(json['image_urls'] ?? []),
    status: ToolStatus.fromString(
      json['status'] as String? ?? 'available',
    ),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
    updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
        DateTime.now(),
    seller: json['seller'] != null
        ? ToolSellerBrief.fromJson(
      json['seller'] as Map<String, dynamic>,
    )
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_id': sellerId,
    'name': name,
    'description': description,
    'category': category,
    'condition': condition,
    'price': price,
    'image_urls': imageUrls,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'seller': seller?.toJson(),
  };

  @override
  List<Object?> get props => [id, status, name, price,imageUrls];
}