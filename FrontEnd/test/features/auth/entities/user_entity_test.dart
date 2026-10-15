import 'package:dentspace/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserEntity.fromJson', () {
    test('parses a patient', () {
      final u = UserEntity.fromJson(const {
        'id': 1,
        'full_name': 'Test Patient',
        'email': 'a@b.c',
        'phone': '0900000000',
        'role': 'patient',
        'gender': 'male',
        'age': 30,
        'is_email_verified': true,
        'is_verified_by_admin': false,
      });

      expect(u.id, 1);
      expect(u.role, 'patient');
      expect(u.isPatient, isTrue);
      expect(u.isDoctor, isFalse);
      expect(u.isAdmin, isFalse);
      expect(u.isEmailVerified, isTrue);
    });

    test('parses a doctor with university_id', () {
      final u = UserEntity.fromJson(const {
        'id': 2,
        'full_name': 'Dr. X',
        'email': 'd@b.c',
        'phone': '0900000001',
        'role': 'doctor',
        'university_id': 'UNI123',
        'is_verified_by_admin': true,
      });

      expect(u.isDoctor, isTrue);
      expect(u.universityId, 'UNI123');
      expect(u.isVerifiedByAdmin, isTrue);
    });

    test('missing optional fields default safely', () {
      final u = UserEntity.fromJson(const {'id': 1});
      expect(u.fullName, '');
      expect(u.email, '');
      expect(u.phone, '');
      expect(u.role, 'patient');
      expect(u.gender, isNull);
      expect(u.age, isNull);
      expect(u.isEmailVerified, isFalse);
    });
  });

  group('UserEntity.toJson', () {
    test('round-trips through JSON', () {
      const original = UserEntity(
        id: 42,
        fullName: 'Ahmad',
        email: 'a@b.c',
        phone: '0900000000',
        role: 'doctor',
        gender: 'male',
        age: 35,
        universityId: 'UNI9',
        isEmailVerified: true,
        isVerifiedByAdmin: true,
      );

      final restored = UserEntity.fromJson(original.toJson());

      expect(restored.id, 42);
      expect(restored.fullName, 'Ahmad');
      expect(restored.universityId, 'UNI9');
      expect(restored.isEmailVerified, isTrue);
    });
  });

  group('copyWith', () {
    test('changes only the specified fields', () {
      const u = UserEntity(
        id: 1,
        fullName: 'Old Name',
        email: 'a@b.c',
        phone: '0900000000',
        role: 'patient',
      );

      final updated = u.copyWith(fullName: 'New Name', age: 25);

      expect(updated.fullName, 'New Name');
      expect(updated.age, 25);
      expect(updated.email, u.email);
      expect(updated.id, u.id);
    });
  });

  group('role helpers', () {
    test('isPatient / isDoctor / isAdmin', () {
      const p = UserEntity(
        id: 1, fullName: 'x', email: 'x@y.z',
        phone: '0900000000', role: 'patient',
      );
      const d = UserEntity(
        id: 2, fullName: 'x', email: 'x@y.z',
        phone: '0900000000', role: 'doctor',
      );
      const a = UserEntity(
        id: 3, fullName: 'x', email: 'x@y.z',
        phone: '0900000000', role: 'admin',
      );

      expect(p.isPatient, isTrue);
      expect(d.isDoctor, isTrue);
      expect(a.isAdmin, isTrue);
      expect(p.isDoctor, isFalse);
    });
  });
}