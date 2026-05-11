import 'package:flutter/material.dart';

import '../admin_theme.dart';

class AdminCard extends StatelessWidget {
  const AdminCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AdminTheme.shadow,
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AdminTheme.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AdminTheme.muted,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class AdminHero extends StatelessWidget {
  const AdminHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AdminTheme.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22B13C88),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Sweet Delights Admin',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String value;
  final String note;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(note, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        ],
      ),
    );
  }
}

class AdminBadge extends StatelessWidget {
  const AdminBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class AdminInfoTile extends StatelessWidget {
  const AdminInfoTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.leadingColor = AdminTheme.pink,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color leadingColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AdminTheme.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AdminTheme.muted,
                height: 1.4,
              ),
            ),
          ],
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFBFBFD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFECEAF3)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: leadingColor.withValues(alpha: 0.12),
                          child: Icon(Icons.cake_outlined, color: leadingColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: content),
                      ],
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.centerLeft, child: trailing!),
                    ],
                  ],
                )
              : Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: leadingColor.withValues(alpha: 0.12),
                      child: Icon(Icons.cake_outlined, color: leadingColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: content),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      Flexible(child: trailing!),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class AdminChipRow extends StatelessWidget {
  const AdminChipRow({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.asMap().entries.map((entry) {
          final selected = entry.key == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFEEF6) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? const Color(0xFFFFC7E3) : const Color(0xFFE7E5EF),
                ),
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  color: selected ? AdminTheme.pink : AdminTheme.text,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close),
                tooltip: 'Clear search',
              ),
        filled: true,
        fillColor: const Color(0xFFFBFBFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFECEAF3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFECEAF3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AdminTheme.pink, width: 1.4),
        ),
      ),
    );
  }
}
