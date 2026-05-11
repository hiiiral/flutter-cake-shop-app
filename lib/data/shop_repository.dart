import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../shop_models.dart';

const double _deliveryCharge = 5.0;

class UserShopData {
  const UserShopData({
    this.cartItems = const <CartItem>[],
    this.wishlistItems = const <Product>[],
  });

  final List<CartItem> cartItems;
  final List<Product> wishlistItems;

  int get totalCartCount => cartItems.fold<int>(
    0,
    (runningTotal, item) => runningTotal + item.quantity,
  );

  UserShopData copyWith({
    List<CartItem>? cartItems,
    List<Product>? wishlistItems,
  }) {
    return UserShopData(
      cartItems: cartItems ?? this.cartItems,
      wishlistItems: wishlistItems ?? this.wishlistItems,
    );
  }

  factory UserShopData.fromUserDocument(Map<String, dynamic>? data) {
    return UserShopData(
      cartItems: _readCartItems(data?['cartItems']),
      wishlistItems: _readWishlistItems(data?['wishlistItems']),
    );
  }
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.items,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    this.createdAt,
  });

  final String id;
  final List<CartItem> items;
  final String status;
  final double totalAmount;
  final String paymentMethod;
  final DateTime? createdAt;

  int get totalItems =>
      items.fold<int>(0, (itemTotal, item) => itemTotal + item.quantity);

  String get title {
    if (items.isEmpty) return 'Cake Order';
    if (items.length == 1) return items.first.product.name;
    return '${items.first.product.name} +${items.length - 1} more';
  }

  factory ShopOrder.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return ShopOrder(
      id: snapshot.id,
      items: _readCartItems(data['items']),
      status: (data['status'] as String?)?.trim() ?? 'New',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod:
          (data['paymentMethod'] as String?)?.trim() ?? 'Cash on Delivery',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class UserShopRepository {
  UserShopRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<UserShopData> watchShopData() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<UserShopData>.value(const UserShopData());
      }

      return _userDocument(user.uid).snapshots().map(
        (snapshot) => UserShopData.fromUserDocument(snapshot.data()),
      );
    });
  }

  Stream<List<ShopOrder>> watchMyOrders() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<ShopOrder>>.value(const <ShopOrder>[]);
      }

      return _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
            final orders = snapshot.docs.map(ShopOrder.fromDocument).toList();
            orders.sort(
              (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                a.createdAt ?? DateTime(0),
              ),
            );
            return orders;
          });
    });
  }

  Future<void> addToCart(
    Product product,
    ProductWeightOption selectedWeight,
    int quantity,
  ) {
    return _mutateShopData((current) {
      final nextCartItems = List<CartItem>.from(current.cartItems);
      final existingIndex = nextCartItems.indexWhere(
        (item) => item.matches(product, selectedWeight),
      );

      if (existingIndex >= 0) {
        final existingItem = nextCartItems[existingIndex];
        nextCartItems[existingIndex] = existingItem.copyWith(
          product: product,
          selectedWeight: selectedWeight,
          quantity: existingItem.quantity + quantity,
        );
      } else {
        nextCartItems.add(
          CartItem(
            product: product,
            selectedWeight: selectedWeight,
            quantity: quantity,
          ),
        );
      }

      return current.copyWith(cartItems: nextCartItems);
    });
  }

  Future<void> updateCartQuantity(CartItem item, int quantity) {
    return _mutateShopData((current) {
      final nextCartItems = List<CartItem>.from(current.cartItems);
      final itemIndex = nextCartItems.indexWhere(
        (cartItem) => cartItem.matches(item.product, item.selectedWeight),
      );

      if (itemIndex < 0) {
        return current;
      }

      if (quantity <= 0) {
        nextCartItems.removeAt(itemIndex);
      } else {
        nextCartItems[itemIndex] = nextCartItems[itemIndex].copyWith(
          quantity: quantity,
        );
      }

      return current.copyWith(cartItems: nextCartItems);
    });
  }

  Future<void> clearCart() {
    return _mutateShopData(
      (current) => current.copyWith(cartItems: const <CartItem>[]),
    );
  }

  Future<void> placeOrder(
    List<CartItem> items, {
    required String paymentMethod,
    bool clearCart = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to place your order.');
    }
    if (items.isEmpty) {
      throw StateError('Your cart is empty.');
    }

    final userDocument = _userDocument(user.uid);
    final orderDocument = _firestore.collection('orders').doc();
    final subtotal = items.fold<double>(
      0,
      (runningTotal, item) => runningTotal + item.totalPrice,
    );
    final totalAmount = subtotal + _deliveryCharge;
    final itemCount = items.fold<int>(
      0,
      (runningCount, item) => runningCount + item.quantity,
    );

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDocument);
      final userData = snapshot.data() ?? const <String, dynamic>{};
      final currentCartItems = _readCartItems(userData['cartItems']);
      final remainingCartItems = clearCart
          ? _removeOrderedItems(currentCartItems, items)
          : currentCartItems;
      final deliveryAddress = _readDeliveryAddress(userData);
      final name = _firstText(
        deliveryAddress?['name'],
        _firstText(
          userData['name'] as String?,
          user.displayName,
          fallback: 'Sweet Delights Customer',
        ),
      );
      final email = _firstText(userData['email'] as String?, user.email);
      final phone = _firstText(
        deliveryAddress?['phone'],
        userData['phone'] as String?,
      );
      final deliveryAddressData = deliveryAddress == null
          ? null
          : <String, Object?>{'deliveryAddress': deliveryAddress};

      transaction.set(orderDocument, {
        'id': orderDocument.id,
        'userId': user.uid,
        'customerName': name,
        'email': email,
        'phone': phone,
        ...?deliveryAddressData,
        'items': items.map((item) => item.toMap()).toList(),
        'itemCount': itemCount,
        'subtotal': subtotal,
        'deliveryCharge': _deliveryCharge,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'status': 'New',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final userPayload = <String, Object?>{
        'ordersCount': FieldValue.increment(1),
        'spentAmount': FieldValue.increment(totalAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (clearCart) {
        userPayload['cartItems'] = remainingCartItems
            .map((item) => item.toMap())
            .toList();
        userPayload['cartItemCount'] = remainingCartItems.fold<int>(
          0,
          (runningCount, item) => runningCount + item.quantity,
        );
      }

      if (snapshot.exists) {
        transaction.set(userDocument, userPayload, SetOptions(merge: true));
        return;
      }

      transaction.set(userDocument, {
        'uid': user.uid,
        'email': email,
        if (name.isNotEmpty) 'name': name,
        if (phone.isNotEmpty) 'phone': phone,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        ...userPayload,
      }, SetOptions(merge: true));
    });
  }

  Future<void> toggleWishlist(Product product) {
    return _mutateShopData((current) {
      final nextWishlistItems = List<Product>.from(current.wishlistItems);
      final itemIndex = nextWishlistItems.indexWhere(
        (item) => item.id == product.id,
      );

      if (itemIndex >= 0) {
        nextWishlistItems.removeAt(itemIndex);
      } else {
        nextWishlistItems.add(product);
      }

      return current.copyWith(wishlistItems: nextWishlistItems);
    });
  }

  DocumentReference<Map<String, dynamic>> _userDocument(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  Future<void> _mutateShopData(
    UserShopData Function(UserShopData current) update,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to manage your cart and wishlist.');
    }

    final userDocument = _userDocument(user.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDocument);
      final currentData = UserShopData.fromUserDocument(snapshot.data());
      final nextData = update(currentData);
      final payload = <String, Object?>{
        'cartItems': nextData.cartItems.map((item) => item.toMap()).toList(),
        'wishlistItems': nextData.wishlistItems
            .map((product) => product.toMap())
            .toList(),
        'cartItemCount': nextData.totalCartCount,
        'favoritesCount': nextData.wishlistItems.length,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (snapshot.exists) {
        transaction.set(userDocument, payload, SetOptions(merge: true));
        return;
      }

      final displayName = user.displayName?.trim() ?? '';
      transaction.set(userDocument, {
        'uid': user.uid,
        'email': user.email?.trim() ?? '',
        if (displayName.isNotEmpty) 'name': displayName,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        ...payload,
      }, SetOptions(merge: true));
    });
  }
}

List<CartItem> _removeOrderedItems(
  List<CartItem> cartItems,
  List<CartItem> orderedItems,
) {
  final orderedKeys = orderedItems.map((item) => item.cartKey).toSet();
  return cartItems
      .where((item) => !orderedKeys.contains(item.cartKey))
      .toList();
}

String _firstText(String? first, String? second, {String fallback = ''}) {
  for (final value in [first, second]) {
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return fallback;
}

Map<String, String>? _readDeliveryAddress(Map<String, dynamic> userData) {
  final addresses = userData['addresses'];
  if (addresses is! List) return null;

  Map<String, dynamic>? selected;
  for (final item in addresses) {
    if (item is! Map) continue;

    final address = Map<String, dynamic>.from(item);
    selected ??= address;
    if (address['isDefault'] == true) {
      selected = address;
      break;
    }
  }

  if (selected == null) return null;

  final label = _firstText(selected['label'] as String?, '');
  final name = _firstText(selected['name'] as String?, '');
  final phone = _firstText(selected['phone'] as String?, '');
  final address = _firstText(selected['address'] as String?, '');

  if (label.isEmpty && name.isEmpty && phone.isEmpty && address.isEmpty) {
    return null;
  }

  return {
    if (label.isNotEmpty) 'label': label,
    if (name.isNotEmpty) 'name': name,
    if (phone.isNotEmpty) 'phone': phone,
    if (address.isNotEmpty) 'address': address,
  };
}

List<CartItem> _readCartItems(dynamic value) {
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

List<Product> _readWishlistItems(dynamic value) {
  return (value as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map>()
      .map((item) {
        final productMap = Map<String, dynamic>.from(item);
        return Product.fromMap(
          productMap,
          id: productMap['id'] as String? ?? '',
        );
      })
      .where((product) => product.id.isNotEmpty)
      .toList();
}
