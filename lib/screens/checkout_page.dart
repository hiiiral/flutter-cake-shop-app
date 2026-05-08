import 'package:flutter/material.dart';

import '../shop_models.dart';
import '../theme/app_theme.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.items,
    required this.onPlaceOrder,
  });

  final List<CartItem> items;
  final Future<bool> Function(List<CartItem>, String paymentMethod)
  onPlaceOrder;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String selectedPaymentMethod = 'Cash on Delivery';
  bool isPlacingOrder = false;

  double get subtotal =>
      widget.items.fold<double>(0, (sum, item) => sum + item.totalPrice);

  @override
  Widget build(BuildContext context) {
    const deliveryCharge = 5.0;
    final grandTotal = subtotal + deliveryCharge;
    final palette = context.cakeTheme;
    final itemCount = widget.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            context,
            title: 'Delivery Address',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default profile address',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text('This order uses the address saved in your profile.'),
                Text('Open Profile > Addresses if you want to change it.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _sectionCard(
            context,
            title: 'Order Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemCount item${itemCount == 1 ? '' : 's'} selected for checkout',
                  style: TextStyle(color: palette.mutedText),
                ),
                const SizedBox(height: 12),
                for (final item in widget.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.product.name} (${item.selectedWeight.label}) x${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '\u20B9${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                _priceLine(context, 'Subtotal', subtotal),
                const SizedBox(height: 6),
                _priceLine(context, 'Delivery', deliveryCharge),
                const SizedBox(height: 8),
                _priceLine(context, 'Total', grandTotal, emphasized: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _sectionCard(
            context,
            title: 'Payment Method',
            child: RadioGroup<String>(
              groupValue: selectedPaymentMethod,
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedPaymentMethod = value);
                }
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'Cash on Delivery',
                    selected: selectedPaymentMethod == 'Cash on Delivery',
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cash on Delivery'),
                    subtitle: const Text('Temporary payment option'),
                  ),
                  RadioListTile<String>(
                    value: 'Online Payment (Coming Soon)',
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Online Payment'),
                    subtitle: const Text('Coming soon'),
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isPlacingOrder || widget.items.isEmpty
                  ? null
                  : () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      setState(() => isPlacingOrder = true);
                      final didPlaceOrder = await widget.onPlaceOrder(
                        widget.items,
                        selectedPaymentMethod,
                      );
                      if (!mounted) return;

                      setState(() => isPlacingOrder = false);
                      if (!didPlaceOrder) return;

                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Order placed with $selectedPaymentMethod successfully.',
                          ),
                        ),
                      );
                      navigator.popUntil((route) => route.isFirst);
                    },
              child: Text(
                'Place Order - \u20B9${grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final palette = context.cakeTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _priceLine(
    BuildContext context,
    String label,
    double value, {
    bool emphasized = false,
  }) {
    final palette = context.cakeTheme;
    final scheme = context.colorScheme;
    final style = TextStyle(
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
      color: emphasized ? scheme.primary : palette.mutedText,
      fontSize: emphasized ? 16 : 14,
    );

    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text('\u20B9${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
