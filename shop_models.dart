import 'package:cloud_firestore/cloud_firestore.dart';

class ProductWeightOption {
  final String id;
  final String label;
  final double price;

  const ProductWeightOption({
    required this.id,
    required this.label,
    required this.price,
  });

  factory ProductWeightOption.fromMap(Map<String, dynamic> map) {
    return ProductWeightOption(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'label': label, 'price': price};
  }
}

class Category {
  final String id;
  final String name;
  final String description;

  const Category({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Category.fromMap(Map<String, dynamic> map, {String? id}) {
    return Category(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description};
  }
}

class Product {
  final String id;
  final String name;
  final double basePrice;
  final double rating;
  final int reviews;
  final String category;
  final String categoryId;
  final String image;
  final String imageStoragePath;
  final String description;
  final bool isActive;
  final int stockQuantity;
  final List<ProductWeightOption> weightOptions;

  const Product({
    required this.id,
    required this.name,
    required this.basePrice,
    this.rating = 0,
    this.reviews = 0,
    required this.category,
    required this.categoryId,
    required this.image,
    this.imageStoragePath = '',
    required this.description,
    required this.isActive,
    required this.stockQuantity,
    required this.weightOptions,
  });

  factory Product.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawWeightOptions = map['weightOptions'] as List<dynamic>? ?? [];
    final parsedWeightOptions = rawWeightOptions
        .whereType<Map>()
        .map(
          (option) =>
              ProductWeightOption.fromMap(Map<String, dynamic>.from(option)),
        )
        .toList();
    final basePrice = (map['basePrice'] as num?)?.toDouble() ?? 0;

    return Product(
      id: id ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      basePrice: basePrice,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviews: (map['reviews'] as num?)?.toInt() ?? 0,
      category: map['category'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      image: _readPreferredImage(map),
      imageStoragePath:
          _readString(map, const ['imageStoragePath', 'storagePath']) ?? '',
      description: map['description'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 0,
      weightOptions: parsedWeightOptions.isEmpty
          ? [
              ProductWeightOption(
                id: 'default',
                label: 'Default',
                price: basePrice,
              ),
            ]
          : parsedWeightOptions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'basePrice': basePrice,
      'rating': rating,
      'reviews': reviews,
      'category': category,
      'categoryId': categoryId,
      'image': image,
      'imageUrl': image,
      'imageStoragePath': imageStoragePath,
      'description': description,
      'isActive': isActive,
      'stockQuantity': stockQuantity,
      'weightOptions': weightOptions.map((option) => option.toMap()).toList(),
    };
  }
}

class ProductReview {
  final String id;
  final String productId;
  final String productName;
  final String userId;
  final String userName;
  final String userEmail;
  final int rating;
  final String review;
  final bool isApproved;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.productName,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.rating,
    required this.review,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
    required this.approvedAt,
  });

  String get authorLabel {
    if (userName.trim().isNotEmpty) return userName.trim();
    if (userEmail.trim().isNotEmpty) return userEmail.trim();
    return 'Customer';
  }

  factory ProductReview.fromMap(Map<String, dynamic> map, {String? id}) {
    return ProductReview(
      id: id ?? map['id'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      rating: _readReviewRating(map['rating']),
      review: map['review'] as String? ?? '',
      isApproved: map['isApproved'] as bool? ?? false,
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
      approvedAt: _readDateTime(map['approvedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'rating': rating,
      'review': review,
      'isApproved': isApproved,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'approvedAt': approvedAt,
    };
  }
}

String _readPreferredImage(Map<String, dynamic> map) {
  return _readString(map, const [
        'image',
        'imageUrl',
        'imageURL',
        'downloadUrl',
        'imagePath',
      ]) ??
      '';
}

String? _readString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

DateTime? _readDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

int _readReviewRating(dynamic value) {
  final rating = (value as num?)?.toInt() ?? 0;
  if (rating < 1) return 1;
  if (rating > 5) return 5;
  return rating;
}

class CartItem {
  final Product product;
  final ProductWeightOption selectedWeight;
  int quantity;

  CartItem({
    required this.product,
    required this.selectedWeight,
    required this.quantity,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final productMap = Map<String, dynamic>.from(
      map['product'] as Map? ?? const <String, dynamic>{},
    );
    final productId =
        map['productId'] as String? ?? productMap['id'] as String? ?? '';
    final product = Product.fromMap(productMap, id: productId);
    final selectedWeightMap = Map<String, dynamic>.from(
      map['selectedWeight'] as Map? ?? const <String, dynamic>{},
    );
    final weightId =
        map['weightId'] as String? ?? selectedWeightMap['id'] as String? ?? '';
    final selectedWeight = selectedWeightMap.isNotEmpty
        ? ProductWeightOption.fromMap(selectedWeightMap)
        : product.weightOptions.firstWhere(
            (option) => option.id == weightId,
            orElse: () => product.weightOptions.first,
          );

    return CartItem(
      product: product,
      selectedWeight: selectedWeight,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  double get totalPrice => selectedWeight.price * quantity;

  String get cartKey => '${product.id}::${selectedWeight.id}';

  bool matches(Product otherProduct, ProductWeightOption otherWeight) {
    return product.id == otherProduct.id && selectedWeight.id == otherWeight.id;
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'weightId': selectedWeight.id,
      'product': product.toMap(),
      'selectedWeight': selectedWeight.toMap(),
      'quantity': quantity,
    };
  }

  CartItem copyWith({
    Product? product,
    ProductWeightOption? selectedWeight,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      selectedWeight: selectedWeight ?? this.selectedWeight,
      quantity: quantity ?? this.quantity,
    );
  }
}
