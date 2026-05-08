import 'package:flutter/material.dart';

import '../shop_models.dart';
import '../theme/app_theme.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({
    super.key,
    required this.items,
    required this.onQuantityChanged,
    required this.onContinueShopping,
    required this.onOrderPlaced,
    required this.onOpenProduct,
  });

  final List<CartItem> items;
  final Future<bool> Function(CartItem, int) onQuantityChanged;
  final VoidCallback onContinueShopping;
  final Future<bool> Function(
    List<CartItem>,
    String paymentMethod,
  )
  onOrderPlaced;
  final ValueChanged<CartItem> onOpenProduct;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Set<String> _selectedItemKeys = <String>{};
  final Set<String> _updatingItemKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedItemKeys.addAll(widget.items.map((item) => item.cartKey));
  }

  @override
  void didUpdateWidget(covariant CartPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final previousKeys = oldWidget.items.map((item) => item.cartKey).toSet();
    final currentKeys = widget.items.map((item) => item.cartKey).toSet();

    _selectedItemKeys.removeWhere((key) => !currentKeys.contains(key));
    _updatingItemKeys.removeWhere((key) => !currentKeys.contains(key));

    for (final key in currentKeys.difference(previousKeys)) {
      _selectedItemKeys.add(key);
    }
  }

  List<CartItem> get _selectedItems => widget.items
      .where((item) => _selectedItemKeys.contains(item.cartKey))
      .toList(growable: false);

  double get subtotal =>
      _selectedItems.fold<double>(0, (sum, item) => sum + item.totalPrice);

  int get _selectedUnitCount =>
      _selectedItems.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get _allItemsSelected =>
      widget.items.isNotEmpty &&
      widget.items.every((item) => _selectedItemKeys.contains(item.cartKey));

  bool _isUpdating(CartItem item) => _updatingItemKeys.contains(item.cartKey);

  void _toggleItemSelection(CartItem item, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedItemKeys.add(item.cartKey);
      } else {
        _selectedItemKeys.remove(item.cartKey);
      }
    });
  }

  void _toggleSelectAll(bool shouldSelect) {
    setState(() {
      if (shouldSelect) {
        _selectedItemKeys
          ..clear()
          ..addAll(widget.items.map((item) => item.cartKey));
      } else {
        _selectedItemKeys.clear();
      }
    });
  }

  Future<void> _changeQuantity(CartItem item, int quantity) async {
    final itemKey = item.cartKey;
    if (_updatingItemKeys.contains(itemKey)) return;

    setState(() => _updatingItemKeys.add(itemKey));
    await widget.onQuantityChanged(item, quantity);
    if (!mounted) return;

    setState(() => _updatingItemKeys.remove(itemKey));
  }

  bool _isNetworkImage(String imagePath) {
    return imagePath.startsWith('http://') || imagePath.startsWith('https://');
  }

  Widget _productImage(BuildContext context, String imagePath) {
    if (_isNetworkImage(imagePath)) {
      return Image.network(
        imagePath,
        width: 82,
        height: 82,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageFallback(context),
      );
    }

    return Image.asset(
      imagePath,
      width: 82,
      height: 82,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _imageFallback(context),
    );
  }

  Widget _imageFallback(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final palette = context.cakeTheme;

    if (widget.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                size: 80,
                color: palette.mutedText,
              ),
              const SizedBox(height: 20),
              Text(
                'Your cart is empty',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add some delicious cakes to get started!',
                style: TextStyle(color: palette.mutedText, fontSize: 14),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 190,
                height: 48,
                child: ElevatedButton(
                  onPressed: widget.onContinueShopping,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Browse Cakes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final scheme = context.colorScheme;
    final selectedItems = _selectedItems;
    final selectedProductCount = selectedItems.length;
    final deliveryFee = selectedItems.isEmpty ? 0.0 : 5.0;
    final total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(title: const Text('Cart')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _allItemsSelected,
                      onChanged: (value) => _toggleSelectAll(value ?? false),
                      activeColor: scheme.primary,
                    ),
                    Expanded(
                      child: Text(
                        'Select all items',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '$selectedProductCount/${widget.items.length}',
                      style: TextStyle(
                        color: palette.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Choose the cakes you want to buy now. Tap a product to review its details.',
                  style: TextStyle(color: palette.mutedText, height: 1.4),
                ),
              ],
            ),
          ),
          ...widget.items.map((item) => _cartItemCard(context, item)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: [
                _priceRow(context, 'Subtotal', subtotal),
                const SizedBox(height: 8),
                _priceRow(context, 'Delivery', deliveryFee),
                const Divider(height: 24),
                _priceRow(context, 'Total', total, emphasized: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedItems.isEmpty
                    ? 'Select at least one cake to continue to checkout.'
                    : '$_selectedUnitCount item${_selectedUnitCount == 1 ? '' : 's'} ready for checkout.',
                style: TextStyle(color: palette.mutedText),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedItems.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutPage(
                                items: selectedItems,
                                onPlaceOrder: widget.onOrderPlaced,
                              ),
                            ),
                          );
                        },
                  child: Text(
                    selectedItems.isEmpty
                        ? 'Select items to checkout'
                        : 'Proceed to Checkout - \u20B9${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartItemCard(BuildContext context, CartItem item) {
    final palette = context.cakeTheme;
    final scheme = context.colorScheme;
    final isSelected = _selectedItemKeys.contains(item.cartKey);
    final isUpdating = _isUpdating(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.24)
              : palette.border,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) => _toggleItemSelection(item, value ?? false),
            activeColor: scheme.primary,
          ),
          Expanded(
            child: InkWell(
              onTap: () => widget.onOpenProduct(item),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 8, 14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _productImage(context, item.product.image),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.selectedWeight.label,
                            style: TextStyle(color: palette.mutedText),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to view details',
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '\u20B9${item.totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                IconButton(
                  onPressed: isUpdating
                      ? null
                      : () => _changeQuantity(item, item.quantity + 1),
                  icon: Icon(Icons.add_circle, color: scheme.primary),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isUpdating
                      ? SizedBox(
                          key: ValueKey('${item.cartKey}-loading'),
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        )
                      : Text(
                          '${item.quantity}',
                          key: ValueKey('${item.cartKey}-${item.quantity}'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                ),
                IconButton(
                  onPressed: isUpdating
                      ? null
                      : () => _changeQuantity(item, item.quantity - 1),
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    BuildContext context,
    String title,
    double value, {
    bool emphasized = false,
  }) {
    final palette = context.cakeTheme;
    final scheme = context.colorScheme;
    final style = TextStyle(
      fontSize: emphasized ? 18 : 15,
      fontWeight: emphasized ? FontWeight.bold : FontWeight.w500,
      color: emphasized ? scheme.primary : palette.mutedText,
    );

    return Row(
      children: [
        Text(title, style: style),
        const Spacer(),
        Text('\u20B9${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
