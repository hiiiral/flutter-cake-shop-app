import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AppUserRole { admin, customer }

extension AppUserRoleX on AppUserRole {
  String get value {
    switch (this) {
      case AppUserRole.admin:
        return 'admin';
      case AppUserRole.customer:
        return 'customer';
    }
  }

  String get label {
    switch (this) {
      case AppUserRole.admin:
        return 'Admin';
      case AppUserRole.customer:
        return 'Customer';
    }
  }
}

AppUserRole appUserRoleFromValue(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'admin':
      return AppUserRole.admin;
    case 'customer':
    default:
      return AppUserRole.customer;
  }
}

class AdminAccess {
  const AdminAccess._();

  static Future<AppUserRole> resolveRole(User user) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snapshot.data();
      final role = appUserRoleFromValue(data?['role'] as String?);
      final isAdmin = data?['isAdmin'] == true;

      if (isAdmin || role == AppUserRole.admin) {
        return AppUserRole.admin;
      }
    } catch (_) {
      // Fall through to customer role on read failures.
    }

    return AppUserRole.customer;
  }

  static Future<bool> isAdminUser(User user) async {
    return (await resolveRole(user)) == AppUserRole.admin;
  }
}
