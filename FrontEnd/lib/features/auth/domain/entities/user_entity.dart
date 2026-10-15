import 'package:equatable/equatable.dart';

/// Authenticated user — pure domain model.
///
/// Also provides JSON round-trip so it can live in the local cache
/// without leaking data-layer models (UserModel) into the domain.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.gender,
    this.age,
    this.profileImageUrl,
    this.universityId,
    this.isEmailVerified = false,
    this.isVerifiedByAdmin = false,
  });

  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String role; // 'patient' | 'doctor' | 'admin'
  final String? gender; // 'male' | 'female'
  final int? age;
  final String? profileImageUrl;
  final String? universityId;
  final bool isEmailVerified;
  final bool isVerifiedByAdmin;

  bool get isPatient => role == 'patient';
  bool get isDoctor => role == 'doctor';
  bool get isAdmin => role == 'admin';

  // ─── JSON ───────────────────────────────────────────────
  factory UserEntity.fromJson(Map<String, dynamic> json) => UserEntity(
    id: (json['id'] as num).toInt(),
    fullName: json['full_name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    role: json['role'] as String? ?? 'patient',
    gender: json['gender'] as String?,
    age: (json['age'] as num?)?.toInt(),
    profileImageUrl: json['profile_image_url'] as String?,
    universityId: json['university_id'] as String?,
    isEmailVerified: json['is_email_verified'] as bool? ?? false,
    isVerifiedByAdmin: json['is_verified_by_admin'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'role': role,
    'gender': gender,
    'age': age,
    'profile_image_url': profileImageUrl,
    'university_id': universityId,
    'is_email_verified': isEmailVerified,
    'is_verified_by_admin': isVerifiedByAdmin,
  };

  UserEntity copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? gender,
    int? age,
    String? profileImageUrl,
    String? universityId,
    bool? isEmailVerified,
    bool? isVerifiedByAdmin,
  }) {
    return UserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      universityId: universityId ?? this.universityId,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isVerifiedByAdmin: isVerifiedByAdmin ?? this.isVerifiedByAdmin,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    role,
    gender,
    age,
    profileImageUrl,
    universityId,
    isEmailVerified,
    isVerifiedByAdmin,
  ];
}