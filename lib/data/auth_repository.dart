import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/admin_access.dart';

class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUserRole> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final credential = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password.trim(),
    );

    final user = credential.user!;
    final role = await AdminAccess.resolveRole(user);

    try {
      await _saveUserDocument(
        user: user,
        email: normalizedEmail,
        name: user.displayName,
        updateLastLogin: true,
        password: password.trim(),
      );
    } catch (_) {
      // Sign-in should still work even if profile sync fails.
    }

    return role;
  }

  Future<void> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();
    final normalizedPassword = password.trim();
    User? createdUser;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password.trim(),
      );
      createdUser = credential.user;

      await createdUser!.updateDisplayName(normalizedName);
      await _saveUserDocument(
        user: createdUser,
        name: normalizedName,
        email: normalizedEmail,
        password: normalizedPassword,
        phone: normalizedPhone,
        role: AppUserRole.customer,
        includeCreatedAt: true,
        updateLastLogin: true,
      );

      await _auth.signOut();
    } catch (error) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          await _auth.signOut();
        }
      }
      rethrow;
    }
  }

  Future<void> _saveUserDocument({
    required User user,
    required String email,
    required String password,
    String? name,
    String? phone,
    AppUserRole? role,
    bool includeCreatedAt = false,
    bool updateLastLogin = false,
  }) {
    final data = <String, Object?>{
      'uid': user.uid,
      'email': email,
      'password': password,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (role != null) 'role': role.value,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      if (updateLastLogin) 'lastLoginAt': FieldValue.serverTimestamp(),
    };

    return _firestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }
}
