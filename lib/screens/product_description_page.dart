import 'package:flutter/material.dart';

import '../data/review_repository.dart';
import '../shop_models.dart';
import '../theme/app_theme.dart';

class ProductDescriptionPage extends StatefulWidget {
  const ProductDescriptionPage({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.onToggleWishlist,
    required this.isWishlisted,
    this.initialSelectedWeight,
  });

  final Product product;
  final Future<bool> Function(Product, ProductWeightOption, int) onAddToCart;
  final Future<bool> Function(Product, ProductWeightOption, int) onBuyNow;
  final Future<bool> Function(Product) onToggleWishlist;
  final bool isWishlisted;
  final ProductWeightOption? initialSelectedWeight;

  @override
  State<ProductDescriptionPage> createState() => _ProductDescriptionPageState();
}

class _ProductDescriptionPageState extends State<ProductDescriptionPage> {
  final ReviewRepository _reviewRepository = ReviewRepository();
  final TextEditingController _reviewController = TextEditingController();

  late final Stream<List<ProductReview>> _approvedReviewsStream;
  late final Stream<ProductReview?> _myReviewStream;
  late ProductWeightOption selectedWeight;
  late bool isWishlisted;
  bool isSavingWishlist = false;
  bool isSavingCart = false;
  bool isBuyingNow = false;
  bool isSubmittingReview = false;
  int quantity = 1;
  int selectedRating = 5;

  @override
  void initState() {
    super.initState();
    selectedWeight = widget.product.weightOptions.firstWhere(
      (option) => option.id == widget.initialSelectedWeight?.id,
      orElse: () => widget.product.weightOptions.first,
    );
    isWishlisted = widget.isWishlisted;
    _approvedReviewsStream = _reviewRepository.watchApprovedReviews(
      widget.product.id,
    );
    _myReviewStream = _reviewRepository.watchMyReview(widget.product.id);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  double get totalPrice => selectedWeight.price * quantity;

  Future<void> _toggleWishlist() async {
    if (isSavingWishlist) return;

    setState(() => isSavingWishlist = true);
    final didUpdate = await widget.onToggleWishlist(widget.product);
    if (!mounted) return;

    setState(() {
      if (didUpdate) {
        isWishlisted = !isWishlisted;
      }
      isSavingWishlist = false;
    });
  }

  Future<void> _addToCart() async {
    if (isSavingCart) return;

    setState(() => isSavingCart = true);
    final product = widget.product;
    final didAdd = await widget.onAddToCart(product, selectedWeight, quantity);
    if (!mounted) return;

    setState(() => isSavingCart = false);
    if (!didAdd) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} (${selectedWeight.label}) added to cart',
        ),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _buyNow() async {
    if (isBuyingNow) return;

    setState(() => isBuyingNow = true);
    final product = widget.product;
    final openedCheckout = await widget.onBuyNow(
      product,
      selectedWeight,
      quantity,
    );
    if (!mounted) return;

    setState(() => isBuyingNow = false);
    if (!openedCheckout) return;
  }

  Future<void> _submitReview() async {
    if (isSubmittingReview) return;

    final reviewText = _reviewController.text.trim();
    if (reviewText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a short review.')),
      );
      return;
    }

    setState(() => isSubmittingReview = true);
    try {
      await _reviewRepository.submitReview(
        product: widget.product,
        rating: selectedRating,
        review: reviewText,
      );
      if (!mounted) return;

      _reviewController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review sent for admin approval.')),
      );
    } catch (error) {
      if (!mounted) return;

      final message = switch (error) {
        StateError stateError => stateError.message.toString(),
        _ => 'Unable to send your review right now.',
      };

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => isSubmittingReview = false);
      }
    }
  }

  double _averageRating(List<ProductReview> reviews) {
    if (reviews.isEmpty) return 0;
    final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }

  String _reviewCountLabel(int count) {
    return '$count review${count == 1 ? '' : 's'}';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Just now';
    return '${value.day}/${value.month}/${value.year}';
  }

  Widget _buildReviewForm(BuildContext context, ProductReview? myReview) {
    final palette = context.cakeTheme;
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.softSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap a star to rate this cake',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            children: List.generate(5, (index) {
              final value = index + 1;
              return InkWell(
                onTap: isSubmittingReview
                    ? null
                    : () => setState(() => selectedRating = value),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    value <= selectedRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 30,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share what you liked about this cake',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (myReview != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: myReview.isApproved
                    ? const Color(0xFFF1F9F4)
                    : const Color(0xFFFFF7E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                myReview.isApproved
                    ? 'Your latest review is live. If you update it, admin will approve it again.'
                    : 'Your latest review is waiting for admin approval.',
                style: TextStyle(
                  color: myReview.isApproved
                      ? const Color(0xFF246B45)
                      : const Color(0xFF8A5B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              'Your review will appear here after admin approval.',
              style: TextStyle(color: palette.mutedText),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmittingReview ? null : _submitReview,
              child: Text(
                isSubmittingReview
                    ? 'Sending...'
                    : myReview == null
                    ? 'Send Review'
                    : 'Update Review',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedReviews(
    BuildContext context,
    AsyncSnapshot<List<ProductReview>> snapshot,
    List<ProductReview> approvedReviews,
  ) {
    if (snapshot.hasError) {
      return _reviewMessage(
        context,
        'Approved reviews are not available right now.',
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (approvedReviews.isEmpty) {
      return _reviewMessage(
        context,
        'No approved reviews yet. Be the first to share feedback.',
      );
    }

    return Column(
      children: approvedReviews.map((review) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _reviewTile(context, review),
        );
      }).toList(),
    );
  }

  Widget _reviewMessage(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cakeTheme.softSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cakeTheme.border),
      ),
      child: Text(
        message,
        style: TextStyle(color: context.cakeTheme.mutedText, height: 1.4),
      ),
    );
  }

  Widget _reviewTile(BuildContext context, ProductReview review) {
    final palette = context.cakeTheme;
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.softSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 2,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.authorLabel,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(color: palette.mutedText, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.review,
            style: TextStyle(color: palette.mutedText, height: 1.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final palette = context.cakeTheme;
    final scheme = context.colorScheme;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            onPressed: isSavingWishlist ? null : _toggleWishlist,
            icon: Icon(
              isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: scheme.primary,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductReview>>(
        stream: _approvedReviewsStream,
        builder: (context, reviewSnapshot) {
          final approvedReviews =
              reviewSnapshot.data ?? const <ProductReview>[];
          final visibleRating = reviewSnapshot.hasData
              ? _averageRating(approvedReviews)
              : product.rating;
          final visibleReviews = reviewSnapshot.hasData
              ? approvedReviews.length
              : product.reviews;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.25,
                  child: _productImage(context, product.image),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    border: Border(top: BorderSide(color: palette.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              visibleReviews == 0
                                  ? 'No approved reviews yet'
                                  : '${visibleRating.toStringAsFixed(1)} (${_reviewCountLabel(visibleReviews)})',
                              style: TextStyle(color: palette.mutedText),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: palette.softSurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              product.category,
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'From \u20B9${product.basePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: TextStyle(height: 1.5, color: palette.mutedText),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Select Weight',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: product.weightOptions.map((option) {
                          final isSelected =
                              option.label == selectedWeight.label;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => selectedWeight = option),
                            child: Container(
                              width: 110,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? scheme.primary
                                    : palette.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? scheme.primary
                                      : palette.border,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    option.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? scheme.onPrimary
                                          : scheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\u20B9${option.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white70
                                          : palette.mutedText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Text(
                            'Quantity',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          _quantityButton(
                            context: context,
                            icon: Icons.remove,
                            onTap: () {
                              if (quantity > 1) {
                                setState(() => quantity--);
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$quantity',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          _quantityButton(
                            context: context,
                            icon: Icons.add,
                            onTap: () => setState(() => quantity++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: palette.softSurface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(
                              '\u20B9${totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: OutlinedButton(
                                onPressed: isSavingCart || isBuyingNow
                                    ? null
                                    : _addToCart,
                                child: const Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: isSavingCart || isBuyingNow
                                    ? null
                                    : _buyNow,
                                child: Text(
                                  isBuyingNow ? 'Opening...' : 'Buy Now',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Write a Review',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customers can see your review only after admin approval.',
                        style: TextStyle(color: palette.mutedText),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<ProductReview?>(
                        stream: _myReviewStream,
                        builder: (context, myReviewSnapshot) {
                          return _buildReviewForm(
                            context,
                            myReviewSnapshot.data,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Customer Reviews',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildApprovedReviews(
                        context,
                        reviewSnapshot,
                        approvedReviews,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _quantityButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.cakeTheme.softSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: context.colorScheme.primary),
      ),
    );
  }

  Widget _productImage(BuildContext context, String imagePath) {
    final isNetworkImage =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imagePath,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageFallback(context),
      );
    }

    return Image.asset(
      imagePath,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _imageFallback(context),
    );
  }

  Widget _imageFallback(BuildContext context) {
    return Container(
      color: context.cakeTheme.softSurface,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        size: 56,
        color: context.cakeTheme.mutedText,
      ),
    );
  }
}
