import '../../domain/entities/user_entity.dart';

/// Data-layer model — knows how to parse the API response.
class UserModel {
  const UserModel({
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
  final String role;
  final String? gender;
  final int? age;
  final String? profileImageUrl;
  final String? universityId;
  final bool isEmailVerified;
  final bool isVerifiedByAdmin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
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
  }

  UserEntity toEntity() => UserEntity(
    id: id,
    fullName: fullName,
    email: email,
    phone: phone,
    role: role,
    gender: gender,
    age: age,
    profileImageUrl: profileImageUrl,
    universityId: universityId,
    isEmailVerified: isEmailVerified,
    isVerifiedByAdmin: isVerifiedByAdmin,
  );
}