import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════
// Status enum
// ═══════════════════════════════════════════════════════════════
enum OrderStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed;

  static OrderStatus fromString(String value) => OrderStatus.values.firstWhere(
        (e) => e.name == value,
    orElse: () => OrderStatus.pending,
  );

  bool get isPending => this == OrderStatus.pending;
  bool get isApproved => this == OrderStatus.approved;
  bool get isRejected => this == OrderStatus.rejected;
  bool get isCancelled => this == OrderStatus.cancelled;
  bool get isCompleted => this == OrderStatus.completed;
  bool get isActive => isPending || isApproved;
}

// ═══════════════════════════════════════════════════════════════
// Nested briefs
// ═══════════════════════════════════════════════════════════════
class OrderToolBrief extends Equatable {
  const OrderToolBrief({
    required this.id,
    required this.name,
    required this.category,
    required this.condition,
    required this.price,
    required this.imageUrls,
    required this.status,
  });

  final int id;
  final String name;
  final String category;
  final String condition;
  final double price;
  final List<String> imageUrls;
  final String status; // tool status (available/reserved/sold/archived)

  factory OrderToolBrief.fromJson(Map<String, dynamic> json) => OrderToolBrief(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? '',
    condition: json['condition'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    imageUrls: List<String>.from(json['image_urls'] ?? []),
    status: json['status'] as String? ?? 'available',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'condition': condition,
    'price': price,
    'image_urls': imageUrls,
    'status': status,
  };

  @override
  List<Object?> get props => [id, status];
}

class OrderUserBrief extends Equatable {
  const OrderUserBrief({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  final int id;
  final String fullName;
  final String phone;

  factory OrderUserBrief.fromJson(Map<String, dynamic> json) => OrderUserBrief(
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
// Main entity
// ═══════════════════════════════════════════════════════════════
class Order extends Equatable {
  const Order({
    required this.id,
    required this.status,
    required this.createdAt,
    this.message,
    this.respondedAt,
    this.tool,
    this.buyer,
    this.seller,
  });

  final int id;
  final OrderStatus status;
  final DateTime createdAt;
  final String? message;
  final DateTime? respondedAt;
  final OrderToolBrief? tool;
  final OrderUserBrief? buyer;
  final OrderUserBrief? seller;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: (json['id'] as num).toInt(),
    status: OrderStatus.fromString(
      json['status'] as String? ?? 'pending',
    ),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
    message: json['message'] as String?,
    respondedAt: json['responded_at'] != null
        ? DateTime.tryParse(json['responded_at'] as String)
        : null,
    tool: json['tool'] != null
        ? OrderToolBrief.fromJson(json['tool'] as Map<String, dynamic>)
        : null,
    buyer: json['buyer'] != null
        ? OrderUserBrief.fromJson(json['buyer'] as Map<String, dynamic>)
        : null,
    seller: json['seller'] != null
        ? OrderUserBrief.fromJson(json['seller'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'message': message,
    'responded_at': respondedAt?.toIso8601String(),
    'tool': tool?.toJson(),
    'buyer': buyer?.toJson(),
    'seller': seller?.toJson(),
  };

  @override
  List<Object?> get props => [id, status];
}