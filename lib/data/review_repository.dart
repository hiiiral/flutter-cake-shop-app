import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../shop_models.dart';

class ReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('product_reviews');

  Stream<List<ProductReview>> watchApprovedReviews(String productId) {
    return _reviews.where('productId', isEqualTo: productId).snapshots().map((
      snapshot,
    ) {
      final reviews = snapshot.docs
          .map((doc) => ProductReview.fromMap(doc.data(), id: doc.id))
          .where((review) => review.isApproved)
          .toList();

      reviews.sort((a, b) {
        final first = b.createdAt ?? DateTime(0);
        final second = a.createdAt ?? DateTime(0);
        return first.compareTo(second);
      });
      return reviews;
    });
  }

  Stream<ProductReview?> watchMyReview(String productId) {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<ProductReview?>.value(null);
      }

      return _reviews.doc(_reviewId(productId, user.uid)).snapshots().map((
        snapshot,
      ) {
        final data = snapshot.data();
        if (!snapshot.exists || data == null) return null;
        return ProductReview.fromMap(data, id: snapshot.id);
      });
    });
  }

  Future<void> submitReview({
    required Product product,
    required int rating,
    required String review,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to add a review.');
    }

    final reviewText = review.trim();
    if (reviewText.isEmpty) {
      throw StateError('Please write a short review.');
    }
    if (rating < 1 || rating > 5) {
      throw StateError('Please choose a rating from 1 to 5.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? const <String, dynamic>{};
    final reviewDoc = _reviews.doc(_reviewId(product.id, user.uid));
    final existingSnapshot = await reviewDoc.get();
    final existingData = existingSnapshot.data();
    final existingReview = existingData == null
        ? null
        : ProductReview.fromMap(existingData, id: existingSnapshot.id);

    final payload = <String, Object?>{
      'id': reviewDoc.id,
      'productId': product.id,
      'productName': product.name,
      'userId': user.uid,
      'userName': _firstText(
        userData['name'] as String?,
        user.displayName,
        fallback: 'Customer',
      ),
      'userEmail': _firstText(userData['email'] as String?, user.email),
      'rating': rating,
      'review': reviewText,
      'isApproved': false,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existingSnapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
    };

    if (existingSnapshot.exists) {
      payload['approvedAt'] = FieldValue.delete();
    }

    await reviewDoc.set(payload, SetOptions(merge: true));

    if (existingReview?.isApproved == true) {
      await _refreshProductRating(product.id);
    }
  }

  Stream<List<ProductReview>> watchPendingReviews() {
    return _reviews.where('isApproved', isEqualTo: false).snapshots().map((
      snapshot,
    ) {
      final reviews = snapshot.docs
          .map((doc) => ProductReview.fromMap(doc.data(), id: doc.id))
          .toList();

      reviews.sort((a, b) {
        final first = b.createdAt ?? DateTime(0);
        final second = a.createdAt ?? DateTime(0);
        return first.compareTo(second);
      });
      return reviews;
    });
  }

  Future<void> approveReview(ProductReview review) async {
    await _reviews.doc(review.id).set({
      'isApproved': true,
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _refreshProductRating(review.productId);
  }

  Future<void> deleteReview(ProductReview review) async {
    await _reviews.doc(review.id).delete();

    if (review.isApproved) {
      await _refreshProductRating(review.productId);
    }
  }

  Future<void> syncProductData(Product product) async {
    final snapshot = await _reviews
        .where('productId', isEqualTo: product.id)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'productName': product.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> deleteReviewsForProduct(String productId) async {
    final snapshot = await _reviews
        .where('productId', isEqualTo: productId)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _refreshProductRating(String productId) async {
    final snapshot = await _reviews
        .where('productId', isEqualTo: productId)
        .get();

    final approvedReviews = snapshot.docs
        .map((doc) => ProductReview.fromMap(doc.data(), id: doc.id))
        .where((review) => review.isApproved)
        .toList();
    final reviewsCount = approvedReviews.length;
    final totalRating = approvedReviews.fold<int>(
      0,
      (total, review) => total + review.rating,
    );
    final averageRating = reviewsCount == 0 ? 0.0 : totalRating / reviewsCount;

    await _products.doc(productId).set({
      'rating': double.parse(averageRating.toStringAsFixed(1)),
      'reviews': reviewsCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

String _reviewId(String productId, String userId) => '${productId}_$userId';

String _firstText(String? first, String? second, {String fallback = ''}) {
  for (final value in [first, second]) {
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return fallback;
}
