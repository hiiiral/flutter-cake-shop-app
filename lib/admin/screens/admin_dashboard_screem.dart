import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin_sections.dart';
import '../admin_theme.dart';
import '../widgets/admin_widgets.dart';
import 'admin_customers_page.dart';
import 'admin_dashboard_home_page.dart';
import 'admin_orders_page.dart';
import 'admin_products_page.dart';
import 'admin_reviews_page.dart';
import 'admin_settings_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  AdminSection _section = AdminSection.dashboard;

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out right now.')),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout from admin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AdminTheme.pink),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  Widget _page() {
    switch (_section) {
      case AdminSection.dashboard:
        return const AdminDashboardHomePage();
      case AdminSection.orders:
        return const AdminOrdersPage();
      case AdminSection.products:
        return const AdminProductsPage();
      case AdminSection.reviews:
        return const AdminReviewsPage();
      case AdminSection.customers:
        return const AdminCustomersPage();
      case AdminSection.settings:
        return const AdminSettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminTheme.background,
      drawer: _AdminDrawer(
        selected: _section,
        onSelect: (value) {
          setState(() => _section = value);
          Navigator.pop(context);
        },
        onLogout: _confirmLogout,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1F8), AdminTheme.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _AdminTopBar(
                  section: _section,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onLogoutTap: _confirmLogout,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Column(
                    children: [
                      AdminHero(
                        title: _section.title,
                        subtitle: _section.subtitle,
                        icon: _section.icon,
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: KeyedSubtree(
                          key: ValueKey(_section),
                          child: _page(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.section,
    required this.onMenuTap,
    required this.onLogoutTap,
  });

  final AdminSection section;
  final VoidCallback onMenuTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;

        final menuButton = IconButton(
          onPressed: onMenuTap,
          icon: const Icon(Icons.menu_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AdminTheme.text,
          ),
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onLogoutTap,
              icon: const Icon(Icons.logout_rounded),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFFEEF4),
                foregroundColor: AdminTheme.pink,
              ),
            ),
          ],
        );

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AdminTheme.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              section.subtitle,
              style: const TextStyle(color: AdminTheme.muted),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [menuButton, const Spacer(), actions]),
              const SizedBox(height: 8),
              titleBlock,
            ],
          );
        }

        return Row(
          children: [
            menuButton,
            const SizedBox(width: 12),
            Expanded(child: titleBlock),
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.selected,
    required this.onSelect,
    required this.onLogout,
  });

  final AdminSection selected;
  final ValueChanged<AdminSection> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AdminTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AdminTheme.heroGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0x26FFFFFF),
                    child: Icon(Icons.cake_outlined, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Manage orders, products, customers, and store performance.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: AdminSection.values.map((item) {
                  final active = item == selected;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: active
                          ? const Color(0xFFFFF0F8)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => onSelect(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                color: active
                                    ? AdminTheme.pink
                                    : AdminTheme.muted,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: active
                                        ? AdminTheme.pink
                                        : AdminTheme.text,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (active)
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AdminTheme.pink,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.pink,
                    side: const BorderSide(color: Color(0xFFFFD2E6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
