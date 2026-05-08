import 'package:flutter/material.dart';

import '../shop_models.dart';
import '../theme/app_theme.dart';
import 'product_description_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.products,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.onToggleWishlist,
    required this.isWishlisted,
    required this.onOpenCart,
    required this.currentCartCount,
  });

  final List<Product> products;
  final Future<bool> Function(Product, ProductWeightOption, int) onAddToCart;
  final Future<bool> Function(Product, ProductWeightOption, int) onBuyNow;
  final Future<bool> Function(Product) onToggleWishlist;
  final bool Function(Product) isWishlisted;
  final VoidCallback onOpenCart;
  final int currentCartCount;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = 'All';
  String selectedSort = 'Default';
  bool showSortOptions = false;
  bool showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  final List<String> sortOptions = const [
    'Default',
    'Price: Low to High',
    'Price: High to Low',
    'Highest Rated',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get filteredProducts {
    final effectiveCategory = categories.contains(selectedCategory)
        ? selectedCategory
        : 'All';

    List<Product> list = effectiveCategory == 'All'
        ? List<Product>.from(widget.products)
        : widget.products
              .where((p) => p.category == effectiveCategory)
              .toList();

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    if (selectedSort == 'Price: Low to High') {
      list.sort((a, b) => a.basePrice.compareTo(b.basePrice));
    } else if (selectedSort == 'Price: High to Low') {
      list.sort((a, b) => b.basePrice.compareTo(a.basePrice));
    } else if (selectedSort == 'Highest Rated') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return list;
  }

  List<String> get categories {
    final productCategories =
        widget.products
            .map((product) => product.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return ['All', ...productCategories];
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.cakeTheme;
    final visibleProducts = filteredProducts;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopSection(context),
            _buildCategoryChips(context),
            const SizedBox(height: 8),
            Expanded(
              child: visibleProducts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No active products are available in this section yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.mutedText,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: visibleProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.63,
                          ),
                      itemBuilder: (context, index) =>
                          _cakeCard(context, visibleProducts[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    final palette = context.cakeTheme;
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: palette.heroShadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sweet Delights',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Freshly baked with love',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => showSortOptions = !showSortOptions),
                icon: const Icon(Icons.tune, color: Colors.white),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: widget.onOpenCart,
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.currentCartCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${widget.currentCartCount}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    showSearchBar = !showSearchBar;
                    if (!showSearchBar) {
                      _searchController.clear();
                      searchQuery = '';
                    }
                  });
                },
                icon: const Icon(Icons.search, color: Colors.white),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search cake...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              searchQuery = '';
                            });
                          },
                        ),
                  fillColor: palette.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            crossFadeState: showSearchBar
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sort by',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: sortOptions.map((option) {
                      final selected = option == selectedSort;
                      return GestureDetector(
                        onTap: () => setState(() => selectedSort = option),
                        child: Container(
                          width: 135,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? palette.surface
                                : Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            option,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? scheme.primary : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            crossFadeState: showSortOptions
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final palette = context.cakeTheme;
    final scheme = context.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: categories.map((cat) {
          final selected = cat == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: selected,
              onSelected: (_) => setState(() => selectedCategory = cat),
              selectedColor: scheme.primary,
              labelStyle: TextStyle(
                color: selected ? scheme.onPrimary : scheme.onSurface,
                fontSize: 12,
              ),
              backgroundColor: palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: palette.border),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _cakeCard(BuildContext context, Product item) {
    final palette = context.cakeTheme;
    final scheme = context.colorScheme;
    final wishlisted = widget.isWishlisted(item);

    print("IMAGE URL: ${item.image}");

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDescriptionPage(
            product: item,
            onAddToCart: widget.onAddToCart,
            onBuyNow: widget.onBuyNow,
            onToggleWishlist: widget.onToggleWishlist,
            isWishlisted: wishlisted,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.heroShadow.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: _productImage(
                context,
                item.image,
                height: 110,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      await widget.onToggleWishlist(item);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        wishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: wishlisted ? scheme.primary : palette.mutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '\u2605 ${item.rating} (${item.reviews})',
                style: TextStyle(fontSize: 11, color: palette.mutedText),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Text(
                'From \u20B9${item.basePrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.category,
                      style: TextStyle(fontSize: 10, color: palette.mutedText),
                    ),
                  ),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: scheme.primary,
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _productImage(
  //   BuildContext context,
  //   String imagePath, {
  //   double? height,
  //   double? width,
  // }) {
  //   final isNetworkImage =
  //       imagePath.startsWith('http://') || imagePath.startsWith('https://');

  //   if (isNetworkImage) {
  //     return Image.network(
  //       imagePath,
  //       height: height,
  //       width: width,
  //       fit: BoxFit.cover,
  //       errorBuilder: (context, error, stackTrace) {
  //         return Container(
  //           height: height,
  //           width: width,
  //           color: context.cakeTheme.softSurface,
  //           alignment: Alignment.center,
  //           child: Icon(
  //             Icons.broken_image_outlined,
  //             color: context.cakeTheme.mutedText,
  //           ),
  //         );
  //       },
  //     );
  //   }

  //   return Image.asset(
  //     imagePath,
  //     height: height,
  //     width: width,
  //     fit: BoxFit.cover,
  //     cacheWidth: 600,
  //     filterQuality: FilterQuality.low,
  //     errorBuilder: (context, error, stackTrace) {
  //       return Container(
  //         height: height,
  //         width: width,
  //         color: context.cakeTheme.softSurface,
  //         alignment: Alignment.center,
  //         child: Icon(
  //           Icons.broken_image_outlined,
  //           color: context.cakeTheme.mutedText,
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _productImage(
    BuildContext context,
    String imagePath, {
    double? height,
    double? width,
  }) {
    if (imagePath.isEmpty) {
      return _errorImage(context, height, width);
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _errorImage(context, height, width);
        },
      );
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _errorImage(context, height, width);
        },
      );
    }

    // fallback (important)
    return _errorImage(context, height, width);
  }

  Widget _errorImage(BuildContext context, double? height, double? width) {
    return Container(
      height: height,
      width: width,
      color: context.cakeTheme.softSurface,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        color: context.cakeTheme.mutedText,
      ),
    );
  }
}
