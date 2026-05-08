part of '../profile_section_pages.dart';

class ProfileOrdersPage extends StatelessWidget {
  const ProfileOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const _ProfileSectionScaffold(
        title: 'My Orders',
        subtitle: 'Sign in to see the orders you place from the shop.',
        icon: Icons.shopping_bag_outlined,
        child: _SignInPromptCard(),
      );
    }

    return _ProfileSectionScaffold(
      title: 'My Orders',
      subtitle: 'Your latest orders are loaded live from Firebase.',
      icon: Icons.shopping_bag_outlined,
      child: StreamBuilder<List<ShopOrder>>(
        stream: UserShopRepository().watchMyOrders(),
        initialData: const <ShopOrder>[],
        builder: (context, snapshot) {
          final orders = snapshot.data ?? const <ShopOrder>[];
          final activeOrders = orders
              .where((order) => !_isFinishedOrder(order.status))
              .length;
          final totalItems = orders.fold<int>(
            0,
            (sum, order) => sum + order.totalItems,
          );

          if (snapshot.connectionState == ConnectionState.waiting &&
              orders.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return const _OrdersErrorState();
          }

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      value: '${orders.length}',
                      label: 'Total Orders',
                      icon: Icons.cake_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      value: '$activeOrders',
                      label: 'Active',
                      icon: Icons.local_shipping_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      value: '$totalItems',
                      label: 'Items',
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: _cardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                      title: 'Recent Orders',
                      subtitle: 'Each order here is read from your database.',
                    ),
                    const SizedBox(height: 16),
                    if (orders.isEmpty)
                      const _EmptyOrdersState()
                    else
                      ...orders.map(
                        (order) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _OrderCard(
                            order: _OrderPreview(
                              title: order.title,
                              id: _orderId(order.id),
                              date: _orderDate(order.createdAt),
                              amount:
                                  '\u20B9${order.totalAmount.toStringAsFixed(2)}',
                              status: order.status,
                              accent: _statusColor(context, order.status),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

bool _isFinishedOrder(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized == 'delivered' || normalized == 'cancelled';
}

String _orderId(String id) {
  final shortId = id.length <= 6 ? id : id.substring(0, 6);
  return '#${shortId.toUpperCase()}';
}

String _orderDate(DateTime? date) {
  if (date == null) return 'Just now';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';

  return '${date.day} ${months[date.month - 1]}, $hour:$minute $period';
}

Color _statusColor(BuildContext context, String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized == 'delivered') return context.cakeTheme.success;
  if (normalized == 'on the way' || normalized == 'awaiting dispatch') {
    return const Color(0xFF6B9CFF);
  }
  return context.cakeTheme.warning;
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    final palette = context.cakeTheme;

    return Column(
      children: [
        Icon(
          Icons.shopping_bag_outlined,
          size: 52,
          color: palette.mutedText,
        ),
        const SizedBox(height: 12),
        Text(
          'No orders yet',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Use Buy Now or checkout from the cart and your orders will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.mutedText, height: 1.45),
        ),
      ],
    );
  }
}

class _OrdersErrorState extends StatelessWidget {
  const _OrdersErrorState();

  @override
  Widget build(BuildContext context) {
    final palette = context.cakeTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Text(
        'Unable to load your orders right now.',
        textAlign: TextAlign.center,
        style: TextStyle(color: palette.mutedText),
      ),
    );
  }
}
