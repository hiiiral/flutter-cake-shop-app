import 'package:cloud_firestore/cloud_firestore.dart';

import '../shop_models.dart';

abstract class ProductRepository {
  Future<List<Product>> fetchProducts({bool onlyActive = true});
  Stream<List<Product>> watchProducts({bool onlyActive = true});
}

class FirestoreProductRepository implements ProductRepository {
  const FirestoreProductRepository();

  @override
  Future<List<Product>> fetchProducts({bool onlyActive = true}) async {
    final snapshot = await _query(onlyActive: onlyActive).get();
    return _mapProducts(snapshot.docs, onlyActive: onlyActive);
  }

  @override
  Stream<List<Product>> watchProducts({bool onlyActive = true}) {
    return _query(onlyActive: onlyActive).snapshots().map(
      (snapshot) => _mapProducts(snapshot.docs, onlyActive: onlyActive),
    );
  }

  Query<Map<String, dynamic>> _query({required bool onlyActive}) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'products',
    );
    if (onlyActive) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query;
  }
}

List<Product> _mapProducts(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
  required bool onlyActive,
}) {
  final products = docs
      .map((doc) => Product.fromMap(doc.data(), id: doc.id))
      .toList();
  products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return _filterProducts(products, onlyActive: onlyActive);
}

List<Product> _filterProducts(
  List<Product> products, {
  required bool onlyActive,
}) {
  return products.where((product) => !onlyActive || product.isActive).toList();
}
