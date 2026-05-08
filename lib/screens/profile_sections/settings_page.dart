part of '../profile_section_pages.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = CakeShopApp.isDarkMode(context);

    return _ProfileSectionScaffold(
      title: 'Settings',
      subtitle: 'Manage your app preferences',
      icon: Icons.settings_outlined,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(context),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  title: 'App Preferences',
                  subtitle: 'Customize your experience',
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _ToggleTile(
                title: 'Dark Mode',
                subtitle: 'Enable the richer evening-friendly palette',
                value: isDarkMode,
                onChanged: (value) => CakeShopApp.setDarkMode(context, value),
              ),
            ),
          ),
          // Container(
          //   padding: const EdgeInsets.all(18),
          //   decoration: _cardDecoration(
          //     context,
          //     color: context.cakeTheme.softSurface,
          //   ),
          // child: const Column(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     _SectionTitle(
          //       title: 'Delivery Preferences',
          //       subtitle: 'Quick selections',
          //     ),
          //     SizedBox(height: 14),
          //     Wrap(
          //       spacing: 10,
          //       runSpacing: 10,
          //       children: [
          //         _PreferenceChip(label: 'Eggless First'),
          //         _PreferenceChip(label: 'Weekend Delivery'),
          //         _PreferenceChip(label: 'Gift Packing'),
          //         _PreferenceChip(label: 'Birthday Notes'),
          //       ],
          //     ),
          //   ],
          // ),
          // ),
        ],
      ),
    );
  }
}
