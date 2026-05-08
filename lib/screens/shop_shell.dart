import 'package:flutter/material.dart';

import '../data/product_repository.dart';
import '../data/shop_repository.dart';
import '../shop_models.dart';
import '../theme/app_theme.dart';
import 'cart_page.dart';
import 'checkout_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'product_description_page.dart';
import 'wishlist_page.dart';

class ShopShell extends StatefulWidget {
  const ShopShell({super.key});

  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  final ProductRepository _productRepository =
      const FirestoreProductRepository();
  final UserShopRepository _shopRepository = UserShopRepository();
  late final Stream<List<Product>> _productsStream = _productRepository
      .watchProducts(onlyActive: true);
  late final Stream<UserShopData> _shopDataStream = _shopRepository
      .watchShopData();

  int selectedBottom = 0;

  Future<bool> addToCart(
    Product product,
    ProductWeightOption selectedWeight,
    int quantity,
  ) async {
    try {
      await _shopRepository.addToCart(product, selectedWeight, quantity);
      if (mounted) {
        setState(() => selectedBottom = 1);
      }
      return true;
    } catch (error) {
      _showPersistenceError(
        error,
        fallback: 'Unable to add this cake to cart.',
      );
      return false;
    }
  }

  Future<bool> updateCartQuantity(CartItem item, int quantity) async {
    try {
      await _shopRepository.updateCartQuantity(item, quantity);
      return true;
    } catch (error) {
      _showPersistenceError(
        error,
        fallback: 'Unable to update this cart item right now.',
      );
      return false;
    }
  }

  Future<bool> buyNow(
    Product product,
    ProductWeightOption selectedWeight,
    int quantity,
  ) async {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckoutPage(
            items: [
              CartItem(
                product: product,
                selectedWeight: selectedWeight,
                quantity: quantity,
              ),
            ],
            onPlaceOrder: placeOrder,
          ),
        ),
      );
      return true;
    } catch (error) {
      _showPersistenceError(
        error,
        fallback: 'Unable to open checkout right now.',
      );
      return false;
    }
  }

  Future<bool> placeOrder(
    List<CartItem> items,
    String paymentMethod,
  ) async {
    try {
      await _shopRepository.placeOrder(items, paymentMethod: paymentMethod);
      if (mounted) {
        setState(() => selectedBottom = 0);
      }
      return true;
    } catch (error) {
      _showPersistenceError(
        error,
        fallback: 'Unable to place your order right now.',
      );
      return false;
    }
  }

  bool isWishlisted(Product product, List<Product> wishlistItems) {
    return wishlistItems.any((item) => item.id == product.id);
  }

  Future<bool> toggleWishlist(Product product) async {
    try {
      await _shopRepository.toggleWishlist(product);
      return true;
    } catch (error) {
      _showPersistenceError(
        error,
        fallback: 'Unable to update your wishlist right now.',
      );
      return false;
    }
  }

  void _showPersistenceError(Object error, {required String fallback}) {
    if (!mounted) return;

    final message = switch (error) {
      StateError stateError => stateError.message,
      _ => fallback,
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        final palette = context.cakeTheme;
        final scheme = context.colorScheme;

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: palette.pageBackground,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 64, color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load products',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.mutedText),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final products = snapshot.data ?? const <Product>[];
        return StreamBuilder<UserShopData>(
          stream: _shopDataStream,
          initialData: const UserShopData(),
          builder: (context, shopSnapshot) {
            final shopData = shopSnapshot.data ?? const UserShopData();
            final cartItems = shopData.cartItems;
            final wishlistItems = shopData.wishlistItems;
            final totalCartCount = shopData.totalCartCount;

            final pages = [
              HomePage(
                products: products,
                onAddToCart: addToCart,
                onBuyNow: buyNow,
                onToggleWishlist: toggleWishlist,
                isWishlisted: (product) => isWishlisted(product, wishlistItems),
                onOpenCart: () => setState(() => selectedBottom = 1),
                currentCartCount: totalCartCount,
              ),
              CartPage(
                items: cartItems,
                onQuantityChanged: updateCartQuantity,
                onContinueShopping: () => setState(() => selectedBottom = 0),
                onOrderPlaced: placeOrder,
                onOpenProduct: (item) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDescriptionPage(
                        product: item.product,
                        onAddToCart: addToCart,
                        onBuyNow: buyNow,
                        onToggleWishlist: toggleWishlist,
                        isWishlisted: isWishlisted(
                          item.product,
                          wishlistItems,
                        ),
                        initialSelectedWeight: item.selectedWeight,
                      ),
                    ),
                  );
                },
              ),
              WishlistPage(
                wishlistItems: wishlistItems,
                onAddToCart: addToCart,
                onBuyNow: buyNow,
                onToggleWishlist: toggleWishlist,
              ),
              const ProfilePage(),
            ];

            return Scaffold(
              body: pages[selectedBottom],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: selectedBottom,
                onTap: (value) => setState(() => selectedBottom = value),
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_cart_outlined),
                        if (totalCartCount > 0)
                          Positioned(
                            right: -8,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$totalCartCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: 'Cart',
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.favorite_border),
                        if (wishlistItems.isNotEmpty)
                          Positioned(
                            right: -8,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${wishlistItems.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: 'Wishlist',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    label: 'Profile',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
