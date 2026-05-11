import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/admin_access.dart';
import '../shop_models.dart';

class AdminUserAccount {
  final String id;
  final String name;
  final String email;
  final String phone;
  final AppUserRole role;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const AdminUserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory AdminUserAccount.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();

    return AdminUserAccount(
      id: snapshot.id,
      name: data['name'] as String? ?? 'Unnamed user',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: appUserRoleFromValue(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }
}

class AdminOrderRecord {
  const AdminOrderRecord({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.status,
    required this.paymentMethod,
    required this.totalAmount,
    required this.itemCount,
    required this.items,
    required this.deliveryAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String customerName;
  final String email;
  final String phone;
  final String status;
  final String paymentMethod;
  final double totalAmount;
  final int itemCount;
  final List<CartItem> items;
  final Map<String, String> deliveryAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get customerLabel {
    final name = customerName.trim();
    return name.isEmpty ? 'Sweet Delights Customer' : name;
  }

  String get shortId {
    final safeId = id.trim().toUpperCase();
    if (safeId.length <= 6) return safeId;
    return safeId.substring(0, 6);
  }

  String get normalizedStatus {
    final value = status.trim().toLowerCase();
    if (value == 'completed') return 'delivered';
    return value.isEmpty ? 'new' : value;
  }

  String get displayStatus {
    return switch (normalizedStatus) {
      'new' => 'New',
      'preparing' => 'Preparing',
      'awaiting dispatch' => 'Awaiting dispatch',
      'on the way' => 'On the way',
      'delivered' => 'Delivered',
      'cancelled' => 'Cancelled',
      _ => status.trim().isEmpty ? 'New' : status.trim(),
    };
  }

  bool get isFinished =>
      normalizedStatus == 'delivered' || normalizedStatus == 'cancelled';

  DateTime? get activityTime => updatedAt ?? createdAt;

  String get itemsSummary {
    if (items.isEmpty) {
      return '$itemCount item${itemCount == 1 ? '' : 's'}';
    }

    return items
        .map((item) => '${item.quantity} x ${item.product.name}')
        .join(', ');
  }

  String get deliverySummary {
    final address = deliveryAddress['address']?.trim() ?? '';
    if (address.isNotEmpty) return address;
    return 'No saved delivery address';
  }

  factory AdminOrderRecord.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    final items = _readOrderItems(data['items']);
    final itemCount = (data['itemCount'] as num?)?.toInt();

    return AdminOrderRecord(
      id: snapshot.id,
      userId: data['userId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      status: data['status'] as String? ?? 'New',
      paymentMethod: data['paymentMethod'] as String? ?? 'Cash on Delivery',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      itemCount:
          itemCount ?? items.fold<int>(0, (sum, item) => sum + item.quantity),
      items: items,
      deliveryAddress: _readStringMap(data['deliveryAddress']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<List<Category>> watchCategories() {
    return _categories.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => Category.fromMap(doc.data(), id: doc.id))
          .toList();

      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return items;
    });
  }

  Stream<List<Product>> watchProducts({bool? isActive}) {
    Query<Map<String, dynamic>> query = _products;
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), id: doc.id))
          .toList();

      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return items;
    });
  }

  Stream<List<AdminOrderRecord>> watchOrders() {
    return _orders.snapshots().map((snapshot) {
      final items = snapshot.docs.map(AdminOrderRecord.fromSnapshot).toList();

      items.sort((a, b) {
        final first = a.activityTime ?? DateTime(0);
        final second = b.activityTime ?? DateTime(0);
        return second.compareTo(first);
      });
      return items;
    });
  }

  Stream<List<AdminUserAccount>> watchUsers() {
    return _users.snapshots().map((snapshot) {
      final items = snapshot.docs.map(AdminUserAccount.fromSnapshot).toList();

      items.sort((a, b) {
        final roleCompare = a.role.value.compareTo(b.role.value);
        if (roleCompare != 0) {
          return roleCompare;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return items;
    });
  }

  Future<void> saveCategory({
    String? id,
    required String name,
    required String description,
  }) async {
    final document = id == null || id.isEmpty
        ? _categories.doc()
        : _categories.doc(id);

    final payload = {
      'id': document.id,
      'name': name.trim(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (id == null || id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    };

    if (id == null || id.isEmpty) {
      await document.set(payload, SetOptions(merge: true));
      return;
    }

    final batch = _firestore.batch();
    batch.set(document, payload, SetOptions(merge: true));

    final linkedProducts = await _products.where('categoryId', isEqualTo: id).get();
    for (final product in linkedProducts.docs) {
      batch.update(product.reference, {
        'category': name.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> deleteCategory(Category category) async {
    final batch = _firestore.batch();
    batch.delete(_categories.doc(category.id));

    final linkedProducts = await _products
        .where('categoryId', isEqualTo: category.id)
        .get();

    for (final product in linkedProducts.docs) {
      batch.update(product.reference, {
        'category': 'Uncategorized',
        'categoryId': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> saveProduct(Product product) async {
    final document = product.id.isEmpty
        ? _products.doc()
        : _products.doc(product.id);

    await document.set({
      ...product.toMap(),
      'id': document.id,
      'updatedAt': FieldValue.serverTimestamp(),
      if (product.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }

  Future<void> updateProductStatus({
    required String productId,
    required bool isActive,
  }) async {
    await _products.doc(productId).set({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserRole({
    required String userId,
    required AppUserRole role,
  }) async {
    await _users.doc(userId).set({
      'role': role.value,
      'isAdmin': role == AppUserRole.admin,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _orders.doc(orderId).set({
      'status': status.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

String slugifyValue(String value) {
  final lowered = value.trim().toLowerCase();
  final slug = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return slug.replaceAll(RegExp(r'^-+|-+$'), '');
}

List<CartItem> _readOrderItems(dynamic value) {
  return (value as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map>()
      .map((item) => CartItem.fromMap(Map<String, dynamic>.from(item)))
      .where(
        (item) =>
            item.product.id.isNotEmpty &&
            item.selectedWeight.id.isNotEmpty &&
            item.quantity > 0,
      )
      .toList();
}

Map<String, String> _readStringMap(dynamic value) {
  final raw = value as Map?;
  if (raw == null) return const <String, String>{};

  final result = <String, String>{};
  raw.forEach((key, data) {
    final text = '$data'.trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      result['$key'] = text;
    }
  });
  return result;
}
