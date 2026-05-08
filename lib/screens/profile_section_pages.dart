import 'package:cake_shop/app.dart';
import 'package:cake_shop/data/shop_repository.dart';
import 'package:cake_shop/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

part 'profile_sections/edit_profile_page.dart';
part 'profile_sections/orders_page.dart';
part 'profile_sections/favorites_page.dart';
part 'profile_sections/addresses_page.dart';
part 'profile_sections/settings_page.dart';
part 'profile_sections/shared_widgets.dart';

class ProfilePalette {
  static const Color primaryPink = AppTheme.brandPink;
  static const Color primaryPurple = AppTheme.brandPurple;
}

BoxDecoration _cardDecoration(
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

OutlineInputBorder _inputBorder(BuildContext context, {Color? color}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color ?? context.cakeTheme.border),
  );
}
