import 'package:flutter/material.dart';

import '../../data/admin_repository.dart';
import '../admin_theme.dart';
import '../widgets/admin_widgets.dart';

const List<String> _statusOptions = [
  'New',
  'Preparing',
  'Awaiting dispatch',
  'On the way',
  'Delivered',
  'Cancelled',
];

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final AdminRepository _repository = AdminRepository();
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<AdminOrderRecord>> _ordersStream = _repository
      .watchOrders();
  String _searchQuery = '';
  String? _updatingOrderId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminOrderRecord>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const AdminCard(
            child: Text(
              'Unable to load admin orders right now.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AdminTheme.muted),
            ),
          );
        }

        final orders = snapshot.data ?? const <AdminOrderRecord>[];
        final filteredOrders = orders.where(_matchesSearch).toList();
        final newCount = orders
            .where((order) => order.normalizedStatus == 'new')
            .length;
        final preparingCount = orders
            .where((order) => order.normalizedStatus == 'preparing')
            .length;
        final dispatchCount = orders
            .where(
              (order) =>
                  order.normalizedStatus == 'awaiting dispatch' ||
                  order.normalizedStatus == 'on the way',
            )
            .length;
        final doneCount = orders
            .where((order) => order.normalizedStatus == 'delivered')
            .length;

        return Column(
          children: [
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminSectionTitle(
                    title: 'Order Pipeline',
                    subtitle:
                        'Everything here is loaded live from Firestore and updates in real time.',
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth < 560
                          ? (constraints.maxWidth - 10) / 2
                          : (constraints.maxWidth - 30) / 4;

                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            [
                                  _SmallCount(
                                    title: 'New',
                                    value: '$newCount',
                                    color: AdminTheme.pink,
                                  ),
                                  _SmallCount(
                                    title: 'Preparing',
                                    value: '$preparingCount',
                                    color: const Color(0xFFFFA24D),
                                  ),
                                  _SmallCount(
                                    title: 'Dispatch',
                                    value: '$dispatchCount',
                                    color: const Color(0xFF5E9BFF),
                                  ),
                                  _SmallCount(
                                    title: 'Done',
                                    value: '$doneCount',
                                    color: const Color(0xFF36B37E),
                                  ),
                                ]
                                .map(
                                  (item) =>
                                      SizedBox(width: itemWidth, child: item),
                                )
                                .toList(),
                      );
                    },
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
                    title: 'Live Order Queue',
                    subtitle:
                        'Search the live order list, then use Edit to change the order status.',
                  ),
                  const SizedBox(height: 16),
                  AdminSearchField(
                    controller: _searchController,
                    hintText:
                        'Search by order id, customer, item, payment or status',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (filteredOrders.isEmpty)
                    const _EmptyOrderSearchState()
                  else
                    Column(
                      children: filteredOrders.map((order) {
                        return _AdminOrderTile(
                          order: order,
                          isUpdating: _updatingOrderId == order.id,
                          onEdit: () => _editOrderStatus(order),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _matchesSearch(AdminOrderRecord order) {
    if (_searchQuery.isEmpty) return true;

    final searchableText = [
      order.id,
      order.customerLabel,
      order.email,
      order.phone,
      order.displayStatus,
      order.paymentMethod,
      order.itemsSummary,
      order.deliverySummary,
      order.totalAmount.toStringAsFixed(2),
    ].join(' ').toLowerCase();

    return searchableText.contains(_searchQuery);
  }

  Future<void> _editOrderStatus(AdminOrderRecord order) async {
    final selectedStatus = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var currentValue = _editableStatus(order);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Order Status'),
              content: DropdownButtonFormField<String>(
                value: currentValue,
                decoration: const InputDecoration(
                  labelText: 'Order status',
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions
                    .map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => currentValue = value);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, currentValue),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted ||
        selectedStatus == null ||
        selectedStatus == order.displayStatus) {
      return;
    }

    setState(() => _updatingOrderId = order.id);
    try {
      await _repository.updateOrderStatus(
        orderId: order.id,
        status: selectedStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.shortId} updated to $selectedStatus.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update order: $error')));
    } finally {
      if (mounted) {
        setState(() => _updatingOrderId = null);
      }
    }
  }
}

String _editableStatus(AdminOrderRecord order) {
  final status = order.displayStatus;
  if (_statusOptions.contains(status)) return status;
  return 'New';
}

class _AdminOrderTile extends StatelessWidget {
  const _AdminOrderTile({
    required this.order,
    required this.onEdit,
    required this.isUpdating,
  });

  final AdminOrderRecord order;
  final VoidCallback onEdit;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final statusColor = _orderStatusColor(order.displayStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECEAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Icon(Icons.cake_outlined, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.shortId}  ${order.customerLabel}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.itemsSummary,
                      style: const TextStyle(
                        color: AdminTheme.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AdminBadge(label: order.displayStatus, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          _OrderMeta(
            icon: Icons.currency_rupee_rounded,
            text: _orderCurrency(order.totalAmount),
          ),
          const SizedBox(height: 8),
          _OrderMeta(icon: Icons.payments_outlined, text: order.paymentMethod),
          const SizedBox(height: 8),
          _OrderMeta(
            icon: Icons.location_on_outlined,
            text: order.deliverySummary,
          ),
          const SizedBox(height: 8),
          _OrderMeta(
            icon: Icons.schedule_outlined,
            text: _orderDate(order.activityTime),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: isUpdating ? null : onEdit,
              icon: Icon(
                isUpdating ? Icons.sync : Icons.edit_outlined,
                size: 18,
              ),
              label: Text(isUpdating ? 'Saving...' : 'Edit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallCount extends StatelessWidget {
  const _SmallCount({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _OrderMeta extends StatelessWidget {
  const _OrderMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AdminTheme.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(color: AdminTheme.muted)),
        ),
      ],
    );
  }
}

class _EmptyOrderSearchState extends StatelessWidget {
  const _EmptyOrderSearchState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFFFEEF5),
            child: Icon(Icons.search_off_outlined, color: AdminTheme.pink),
          ),
          SizedBox(height: 14),
          Text(
            'No orders match your search',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AdminTheme.text,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try searching with another order id, customer name, status, or item.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AdminTheme.muted),
          ),
        ],
      ),
    );
  }
}

Color _orderStatusColor(String status) {
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

String _orderCurrency(double value) {
  return 'Rs ${value.toStringAsFixed(value >= 100 ? 0 : 2)}';
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
