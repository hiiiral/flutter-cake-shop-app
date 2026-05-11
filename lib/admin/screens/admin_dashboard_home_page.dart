import 'package:flutter/material.dart';

import '../../auth/admin_access.dart';
import '../../data/admin_repository.dart';
import '../admin_theme.dart';
import '../widgets/admin_widgets.dart';

class AdminDashboardHomePage extends StatefulWidget {
  const AdminDashboardHomePage({super.key});

  @override
  State<AdminDashboardHomePage> createState() => _AdminDashboardHomePageState();
}

class _AdminDashboardHomePageState extends State<AdminDashboardHomePage> {
  final AdminRepository _repository = AdminRepository();
  late final Stream<List<AdminOrderRecord>> _ordersStream = _repository
      .watchOrders();
  late final Stream<List<AdminUserAccount>> _usersStream = _repository
      .watchUsers();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminOrderRecord>>(
      stream: _ordersStream,
      builder: (context, ordersSnapshot) {
        return StreamBuilder<List<AdminUserAccount>>(
          stream: _usersStream,
          builder: (context, usersSnapshot) {
            if (_isLoading(ordersSnapshot, usersSnapshot)) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (ordersSnapshot.hasError || usersSnapshot.hasError) {
              return const _DashboardMessageCard(
                title: 'Dashboard unavailable',
                subtitle: 'We could not load the latest admin data right now.',
              );
            }

            final orders = ordersSnapshot.data ?? const <AdminOrderRecord>[];
            final users = usersSnapshot.data ?? const <AdminUserAccount>[];
            final width = MediaQuery.of(context).size.width;
            final crossAxisCount = width < 420 ? 1 : 2;
            final childAspectRatio = width < 420 ? 1.8 : 1.2;
            final totalRevenue = orders.fold<double>(
              0,
              (sum, order) => sum + order.totalAmount,
            );
            final activeOrders = orders
                .where((order) => !order.isFinished)
                .toList();
            final newOrders = orders
                .where((order) => order.normalizedStatus == 'new')
                .length;
            final preparingOrders = orders
                .where((order) => order.normalizedStatus == 'preparing')
                .length;
            final dispatchOrders = orders
                .where(
                  (order) =>
                      order.normalizedStatus == 'awaiting dispatch' ||
                      order.normalizedStatus == 'on the way',
                )
                .length;
            final customerCount = users
                .where((user) => user.role == AppUserRole.customer)
                .length;
            final buyingCustomers = orders
                .map((order) => order.userId)
                .where((id) => id.isNotEmpty)
                .toSet()
                .length;
            final averageOrder = orders.isEmpty
                ? 0
                : totalRevenue / orders.length;
            final recentOrders = orders.take(3).toList();

            return Column(
              children: [
                AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle(
                        title: 'Business Snapshot',
                        subtitle:
                            'Live totals from your Firestore orders and users collections.',
                      ),
                      const SizedBox(height: 18),
                      GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: childAspectRatio,
                        children: [
                          AdminStatCard(
                            title: 'Total Orders',
                            value: '${orders.length}',
                            note:
                                '$newOrders new and $preparingOrders preparing',
                            icon: Icons.shopping_bag_outlined,
                            colors: const [
                              Color(0xFFFF7BB0),
                              Color(0xFFFFB36D),
                            ],
                          ),
                          AdminStatCard(
                            title: 'Revenue',
                            value: _currency(totalRevenue),
                            note:
                                'Average order ${_currency(averageOrder.toDouble())}',
                            icon: Icons.trending_up_rounded,
                            colors: const [
                              Color(0xFF9B7BFF),
                              Color(0xFFE07CFF),
                            ],
                          ),
                          AdminStatCard(
                            title: 'Active Orders',
                            value: '${activeOrders.length}',
                            note: '$dispatchOrders waiting for dispatch',
                            icon: Icons.cake_outlined,
                            colors: const [
                              Color(0xFFFF9671),
                              Color(0xFFFF6F91),
                            ],
                          ),
                          AdminStatCard(
                            title: 'Customers',
                            value: '$customerCount',
                            note: '$buyingCustomers shoppers placed orders',
                            icon: Icons.person,
                            colors: const [
                              Color(0xFF41C9B4),
                              Color(0xFF7BE495),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle(
                        title: 'Kitchen Activity',
                        subtitle:
                            'The latest status updates flowing in from live orders.',
                      ),
                      const SizedBox(height: 16),
                      if (recentOrders.isEmpty)
                        const _DashboardMessageCard(
                          title: 'No order activity yet',
                          subtitle:
                              'Place an order from the customer side and it will show up here.',
                          isInnerCard: true,
                        )
                      else
                        ...recentOrders.map((order) {
                          final color = _statusColor(order.displayStatus);
                          return AdminInfoTile(
                            title:
                                '${order.customerLabel} order is ${order.displayStatus.toLowerCase()}',
                            subtitle:
                                '${order.itemsSummary} - ${order.deliverySummary}',
                            trailing: AdminBadge(
                              label: _timeAgo(order.activityTime),
                              color: color,
                            ),
                            leadingColor: color,
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle(
                        title: 'Recent Orders',
                        subtitle:
                            'The latest live orders, sorted by their newest update.',
                      ),
                      const SizedBox(height: 16),
                      if (recentOrders.isEmpty)
                        const _DashboardMessageCard(
                          title: 'No recent orders',
                          subtitle:
                              'New orders will appear here automatically.',
                          isInnerCard: true,
                        )
                      else
                        ...recentOrders.map((order) {
                          final color = _statusColor(order.displayStatus);
                          return AdminInfoTile(
                            title:
                                '#${order.shortId}  ${order.customerLabel}  ${_currency(order.totalAmount)}',
                            subtitle: order.itemsSummary,
                            trailing: AdminBadge(
                              label: order.displayStatus,
                              color: color,
                            ),
                            leadingColor: color,
                          );
                        }),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

bool _isLoading(
  AsyncSnapshot<List<AdminOrderRecord>> ordersSnapshot,
  AsyncSnapshot<List<AdminUserAccount>> usersSnapshot,
) {
  return (ordersSnapshot.connectionState == ConnectionState.waiting &&
          !ordersSnapshot.hasData) ||
      (usersSnapshot.connectionState == ConnectionState.waiting &&
          !usersSnapshot.hasData);
}

String _currency(double value) {
  return 'Rs ${value.toStringAsFixed(value >= 100 ? 0 : 2)}';
}

Color _statusColor(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized == 'new') return AdminTheme.pink;
  if (normalized == 'preparing') return const Color(0xFFFFA24D);
  if (normalized == 'awaiting dispatch' || normalized == 'on the way') {
    return const Color(0xFF5E9BFF);
  }
  if (normalized == 'delivered' || normalized == 'completed') {
    return const Color(0xFF36B37E);
  }
  return AdminTheme.purple;
}

String _timeAgo(DateTime? time) {
  if (time == null) return 'Just now';

  final difference = DateTime.now().difference(time);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes} min ago';
  if (difference.inDays < 1) return '${difference.inHours} hr ago';
  return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
}

class _DashboardMessageCard extends StatelessWidget {
  const _DashboardMessageCard({
    required this.title,
    required this.subtitle,
    this.isInnerCard = false,
  });

  final String title;
  final String subtitle;
  final bool isInnerCard;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFFFEEF5),
          child: Icon(Icons.inbox_outlined, color: AdminTheme.pink),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AdminTheme.text,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AdminTheme.muted, height: 1.4),
        ),
      ],
    );

    if (isInnerCard) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: child,
      );
    }

    return AdminCard(child: child);
  }
}
