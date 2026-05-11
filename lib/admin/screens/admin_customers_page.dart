import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/admin_access.dart';
import '../../data/admin_repository.dart';
import '../admin_theme.dart';
import '../widgets/admin_widgets.dart';

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  final AdminRepository _repository = AdminRepository();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _updatingUsers = <String>{};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateUserRole({
    required AdminUserAccount user,
    required AppUserRole role,
  }) async {
    if (_updatingUsers.contains(user.id)) return;

    setState(() => _updatingUsers.add(user.id));
    try {
      await _repository.updateUserRole(userId: user.id, role: role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} is now ${role.label.toLowerCase()}.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update role: $error')));
    } finally {
      if (mounted) {
        setState(() => _updatingUsers.remove(user.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<AdminUserAccount>>(
      stream: _repository.watchUsers(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? const <AdminUserAccount>[];
        final filteredUsers = users.where(_matchesSearch).toList();
        final adminCount = users
            .where((user) => user.role == AppUserRole.admin)
            .length;
        final customerCount = users
            .where((user) => user.role == AppUserRole.customer)
            .length;

        return Column(
          children: [
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminSectionTitle(
                    title: 'Customer Roles',
                    subtitle:
                        'Review registered users and promote or demote access without opening Firebase Console.',
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _CustomerCount(
                        title: 'Total Users',
                        value: '${users.length}',
                        color: AdminTheme.pink,
                      ),
                      _CustomerCount(
                        title: 'Admins',
                        value: '$adminCount',
                        color: AdminTheme.purple,
                      ),
                      _CustomerCount(
                        title: 'Customers',
                        value: '$customerCount',
                        color: const Color(0xFF2AA876),
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
                    title: 'Manage Roles',
                    subtitle:
                        'Changes apply directly to the `users` collection and will affect the next login flow.',
                  ),
                  const SizedBox(height: 16),
                  AdminSearchField(
                    controller: _searchController,
                    hintText: 'Search by name, email, phone or role',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      users.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (users.isEmpty)
                    const _EmptyCustomersState()
                  else if (filteredUsers.isEmpty)
                    const _EmptyCustomerSearchState()
                  else
                    Column(
                      children: filteredUsers.map((user) {
                        final isCurrentUser = user.id == currentUserId;
                        final isUpdating = _updatingUsers.contains(user.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CustomerTile(
                            user: user,
                            isCurrentUser: isCurrentUser,
                            isUpdating: isUpdating,
                            onRoleChanged: isCurrentUser
                                ? null
                                : (role) =>
                                      _updateUserRole(user: user, role: role),
                          ),
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

  bool _matchesSearch(AdminUserAccount user) {
    if (_searchQuery.isEmpty) return true;

    final searchableText = [
      user.name,
      user.email,
      user.phone,
      user.role.label,
    ].join(' ').toLowerCase();

    return searchableText.contains(_searchQuery);
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.user,
    required this.isCurrentUser,
    required this.isUpdating,
    required this.onRoleChanged,
  });

  final AdminUserAccount user;
  final bool isCurrentUser;
  final bool isUpdating;
  final ValueChanged<AppUserRole>? onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFD),
        borderRadius: BorderRadius.circular(22),
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
                backgroundColor: user.role == AppUserRole.admin
                    ? AdminTheme.purple.withValues(alpha: 0.12)
                    : AdminTheme.pink.withValues(alpha: 0.12),
                child: Icon(
                  user.role == AppUserRole.admin
                      ? Icons.admin_panel_settings_outlined
                      : Icons.person_outline,
                  color: user.role == AppUserRole.admin
                      ? AdminTheme.purple
                      : AdminTheme.pink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.text,
                            fontSize: 16,
                          ),
                        ),
                        AdminBadge(
                          label: user.role.label,
                          color: user.role == AppUserRole.admin
                              ? AdminTheme.purple
                              : AdminTheme.pink,
                        ),
                        if (isCurrentUser)
                          const AdminBadge(
                            label: 'Current account',
                            color: Color(0xFF2AA876),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email.isEmpty ? 'No email available' : user.email,
                      style: const TextStyle(color: AdminTheme.muted),
                    ),
                    if (user.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.phone,
                        style: const TextStyle(color: AdminTheme.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetaPill(label: 'Joined', value: _formatDate(user.createdAt)),
              _MetaPill(
                label: 'Last Login',
                value: _formatDate(user.lastLoginAt),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<AppUserRole>(
                  initialValue: user.role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: AppUserRole.values.map((role) {
                    return DropdownMenuItem<AppUserRole>(
                      value: role,
                      child: Text(role.label),
                    );
                  }).toList(),
                  onChanged: isUpdating || isCurrentUser
                      ? null
                      : (role) {
                          if (role != null) {
                            onRoleChanged?.call(role);
                          }
                        },
                ),
              ),
              if (isUpdating) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ],
            ],
          ),
          if (isCurrentUser) ...[
            const SizedBox(height: 8),
            const Text(
              'Your own role is locked here to avoid accidentally removing current admin access.',
              style: TextStyle(color: AdminTheme.muted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AdminTheme.muted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AdminTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCount extends StatelessWidget {
  const _CustomerCount({
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Text(title, style: const TextStyle(color: AdminTheme.muted)),
        ],
      ),
    );
  }
}

class _EmptyCustomersState extends StatelessWidget {
  const _EmptyCustomersState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFFFEEF5),
            child: Icon(Icons.groups_2_outlined, color: AdminTheme.pink),
          ),
          SizedBox(height: 14),
          Text(
            'No registered users yet',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AdminTheme.text,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Users will appear here after they create an account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AdminTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _EmptyCustomerSearchState extends StatelessWidget {
  const _EmptyCustomerSearchState();

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
            'No customers match your search',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AdminTheme.text,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different name, email, phone number, or role.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AdminTheme.muted),
          ),
        ],
      ),
    );
  }
}
