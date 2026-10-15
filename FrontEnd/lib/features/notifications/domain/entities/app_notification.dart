import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.body,
    this.payload,
  });

  final int id;
  final String title;
  final String? body;
  final String type;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    body: body,
    type: type,
    payload: payload,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      type: json['type'] as String? ?? 'system',
      payload: json['payload'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// ★ JSON round-trip for local cache (Hive).
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'payload': payload,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, isRead];
}