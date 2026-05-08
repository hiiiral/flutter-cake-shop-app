import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'profile_section_pages.dart';
import '../theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return _ProfileScaffold(
        profileData: const _ProfileData.guest(),
        isGuest: true,
        onLogout: () => _goToLogin(context),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final profileData = _ProfileData.fromSources(
          authUser: currentUser,
          firestoreData: snapshot.data?.data(),
        );

        return _ProfileScaffold(
          profileData: profileData,
          isGuest: false,
          onLogout: () => _logout(context),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await _showLogoutDialog(context);
    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      _goToLogin(context);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to logout right now. Please try again.'),
        ),
      );
    }
  }

  void _goToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}

BoxDecoration _profileCardDecoration(
  BuildContext context, {
  Color? color,
  double radius = 22,
}) {
  final palette = context.cakeTheme;

  return BoxDecoration(
    color: color ?? palette.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: palette.border),
    boxShadow: [
      BoxShadow(
        color: palette.heroShadow.withValues(alpha: 0.14),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class _ProfileScaffold extends StatelessWidget {
  const _ProfileScaffold({
    required this.profileData,
    required this.isGuest,
    required this.onLogout,
  });

  final _ProfileData profileData;
  final bool isGuest;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final palette = context.cakeTheme;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            children: [
              _HeaderCard(
                profileData: profileData,
                initials: profileData.initials,
                isGuest: isGuest,
                onSignIn: () => Navigator.pushNamed(context, '/login'),
              ),
              Transform.translate(
                offset: const Offset(0, -26),
                child: _StatsRow(profileData: profileData),
              ),
              const SizedBox(height: 4),
              ..._buildMenuItems(profileData).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MenuTile(item: item),
                ),
              ),
              _LogoutTile(onTap: onLogout),
              const SizedBox(height: 28),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: palette.mutedText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.profileData,
    required this.initials,
    required this.isGuest,
    required this.onSignIn,
  });

  final _ProfileData profileData;
  final String initials;
  final bool isGuest;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final palette = context.cakeTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: palette.heroGradient,
        boxShadow: [
          BoxShadow(
            color: palette.heroShadow,
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileData.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profileData.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                if (isGuest)
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: onSignIn,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: const Text('Sign In'),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (profileData.phone.isNotEmpty)
                        _HeaderInfoPill(
                          icon: Icons.call_outlined,
                          label: profileData.phone,
                        ),
                      const _HeaderInfoPill(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Sweet Member',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profileData});

  final _ProfileData profileData;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(value: '${profileData.orders}', label: 'Orders'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '${profileData.favorites}',
            label: 'Favorites',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(value: '\u20B9${profileData.spent}', label: 'Spent'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = context.cakeTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _profileCardDecoration(context, radius: 18),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 14, color: palette.mutedText)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});

  final _ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = context.cakeTheme;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: item.pageBuilder),
        ),
        child: Ink(
          decoration: _profileCardDecoration(context, radius: 18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.softSurface,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    item.icon,
                    color: ProfilePalette.primaryPink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: palette.mutedText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.badge != null)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: palette.softSurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.badge!,
                      style: const TextStyle(
                        color: ProfilePalette.primaryPink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.mutedText,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderInfoPill extends StatelessWidget {
  const _HeaderInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.cakeTheme;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: _profileCardDecoration(context, radius: 18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Icon(Icons.logout_rounded, color: palette.danger, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: palette.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> _showLogoutDialog(BuildContext context) {
  final palette = context.cakeTheme;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: _profileCardDecoration(context, radius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.danger.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: palette.danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Logout',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.mutedText),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.danger,
                      ),
                      child: const Text('Yes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ProfileData {
  const _ProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.orders,
    required this.favorites,
    required this.spent,
  });

  const _ProfileData.guest()
    : name = 'Guest User',
      email = 'guest@sweetdelights.com',
      phone = '',
      orders = 0,
      favorites = 0,
      spent = 0;

  final String name;
  final String email;
  final String phone;
  final int orders;
  final int favorites;
  final int spent;

  factory _ProfileData.fromSources({
    required User authUser,
    Map<String, dynamic>? firestoreData,
  }) {
    final firestoreName = (firestoreData?['name'] as String?)?.trim() ?? '';
    final firestoreEmail = (firestoreData?['email'] as String?)?.trim() ?? '';
    final phone = (firestoreData?['phone'] as String?)?.trim() ?? '';

    final name = firestoreName.isNotEmpty
        ? firestoreName
        : (authUser.displayName?.trim().isNotEmpty == true
              ? authUser.displayName!.trim()
              : _nameFromEmail(authUser.email));

    final email = firestoreEmail.isNotEmpty
        ? firestoreEmail
        : (authUser.email?.trim().isNotEmpty == true
              ? authUser.email!.trim()
              : 'guest@sweetdelights.com');
    final favoritesCount =
        _toNullableInt(firestoreData?['favoritesCount']) ??
        _listLength(firestoreData?['wishlistItems']);

    return _ProfileData(
      name: name,
      email: email,
      phone: phone,
      orders: _toInt(firestoreData?['ordersCount']),
      favorites: favoritesCount,
      spent: _toInt(firestoreData?['spentAmount']),
    );
  }

  String get initials {
    final parts = name
        .split(' ')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'GU';
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _nameFromEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Guest User';
    }

    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'Guest User';
    }

    return localPart
        .split(RegExp(r'[._-]+'))
        .where((value) => value.isNotEmpty)
        .map((value) => '${value[0].toUpperCase()}${value.substring(1)}')
        .join(' ');
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    return _toInt(value);
  }

  static int _listLength(dynamic value) {
    if (value is List) return value.length;
    return 0;
  }
}

class _ProfileMenuItem {
  const _ProfileMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.pageBuilder,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function(BuildContext context) pageBuilder;
  final String? badge;
}

List<_ProfileMenuItem> _buildMenuItems(_ProfileData profileData) {
  return [
    _ProfileMenuItem(
      title: 'Edit Profile',
      subtitle: 'Update your personal details and saved preferences',
      icon: Icons.person_outline_rounded,
      badge: 'Live',
      pageBuilder: (_) => EditProfilePage(
        initialName: profileData.name,
        initialEmail: profileData.email,
        initialPhone: profileData.phone,
      ),
    ),
    const _ProfileMenuItem(
      title: 'My Orders',
      subtitle: 'Browse your recent orders and delivery progress',
      icon: Icons.shopping_bag_outlined,
      pageBuilder: _profileOrdersBuilder,
    ),
    const _ProfileMenuItem(
      title: 'Favorites',
      subtitle: 'See the cakes you love in a dedicated profile view',
      icon: Icons.favorite_border_rounded,
      pageBuilder: _profileFavoritesBuilder,
    ),
    const _ProfileMenuItem(
      title: 'Addresses',
      subtitle: 'Manage your delivery spots for faster checkout',
      icon: Icons.location_on_outlined,
      pageBuilder: _profileAddressesBuilder,
    ),
    const _ProfileMenuItem(
      title: 'Settings',
      subtitle: 'Fine-tune preferences for checkout and account experience',
      icon: Icons.settings_outlined,
      pageBuilder: _profileSettingsBuilder,
    ),
  ];
}

Widget _profileOrdersBuilder(BuildContext _) => const ProfileOrdersPage();
Widget _profileFavoritesBuilder(BuildContext _) => const ProfileFavoritesPage();
Widget _profileAddressesBuilder(BuildContext _) => const ProfileAddressesPage();
Widget _profileSettingsBuilder(BuildContext _) => const ProfileSettingsPage();
