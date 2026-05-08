import 'package:flutter/material.dart';

import '../shop_models.dart';
import '../theme/app_theme.dart';
import 'product_description_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({
    super.key,
    required this.wishlistItems,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.onToggleWishlist,
  });

  final List<Product> wishlistItems;
  final Future<bool> Function(Product, ProductWeightOption, int) onAddToCart;
  final Future<bool> Function(Product, ProductWeightOption, int) onBuyNow;
  final Future<bool> Function(Product) onToggleWishlist;

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final Set<String> _addingProductIds = <String>{};

  bool _isNetworkImage(String imagePath) {
    return imagePath.startsWith('http://') || imagePath.startsWith('https://');
  }

  ProductWeightOption _defaultWeight(Product item) {
    if (item.weightOptions.isNotEmpty) {
      return item.weightOptions.first;
    }

    return ProductWeightOption(
      id: 'default',
      label: 'Default',
      price: item.basePrice,
    );
  }

  Widget _productImage(BuildContext context, String imagePath) {
    if (_isNetworkImage(imagePath)) {
      return Image.network(
        imagePath,
        width: 82,
        height: 82,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    }

    return Image.asset(
      imagePath,
      width: 82,
      height: 82,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      color: context.cakeTheme.softSurface,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        color: context.cakeTheme.mutedText,
      ),
    );
  }

  void _openProduct(Product item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDescriptionPage(
          product: item,
          onAddToCart: widget.onAddToCart,
          onBuyNow: widget.onBuyNow,
          onToggleWishlist: widget.onToggleWishlist,
          isWishlisted: true,
        ),
      ),
    );
  }

  bool _isAdding(Product item) => _addingProductIds.contains(item.id);

  Future<void> _addToCart(Product item) async {
    if (_isAdding(item)) return;

    final selectedWeight = _defaultWeight(item);
    setState(() => _addingProductIds.add(item.id));

    final didAdd = await widget.onAddToCart(item, selectedWeight, 1);
    if (!mounted) return;

    setState(() => _addingProductIds.remove(item.id));
    if (!didAdd) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} (${selectedWeight.label}) added to cart'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.cakeTheme;
    final scheme = context.colorScheme;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(title: const Text('Wishlist')),
      body: widget.wishlistItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 72,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your wishlist is empty',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the heart icon on cakes you want to save here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.mutedText),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.wishlistItems.length,
              itemBuilder: (context, index) {
                final item = widget.wishlistItems[index];

                return GestureDetector(
                  onTap: () => _openProduct(item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _productImage(context, item.image),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.category,
                                style: TextStyle(color: palette.mutedText),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'From \u20B9${item.basePrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              onPressed: () async {
                                await widget.onToggleWishlist(item);
                              },
                              icon: Icon(Icons.favorite, color: scheme.primary),
                            ),
                            ElevatedButton(
                              onPressed: _isAdding(item)
                                  ? null
                                  : () => _addToCart(item),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(0, 30),
                              ),
                              child: Text(
                                _isAdding(item) ? 'Adding...' : 'Add to Cart',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
