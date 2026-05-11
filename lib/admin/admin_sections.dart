import 'package:flutter/material.dart';

enum AdminSection {
  dashboard,
  orders,
  products,
  reviews,
  customers,
  settings,
}

extension AdminSectionX on AdminSection {
  String get title {
    switch (this) {
      case AdminSection.dashboard:
        return 'Dashboard';
      case AdminSection.orders:
        return 'Orders';
      case AdminSection.products:
        return 'Products';
      case AdminSection.reviews:
        return 'Reviews';
      case AdminSection.customers:
        return 'Customers';
      case AdminSection.settings:
        return 'Settings';
    }
  }

  String get subtitle {
    switch (this) {
      case AdminSection.dashboard:
        return 'Quick bakery overview and live activity.';
      case AdminSection.orders:
        return 'Track every order from new to delivered.';
      case AdminSection.products:
        return 'Manage cakes, pricing, and stock highlights.';
      case AdminSection.reviews:
        return 'Approve customer ratings and reviews before they go live.';
      case AdminSection.customers:
        return 'See loyalty, spend, and customer feedback.';
      case AdminSection.settings:
        return 'Adjust admin preferences and access.';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminSection.dashboard:
        return Icons.dashboard_customize_outlined;
      case AdminSection.orders:
        return Icons.receipt_long_outlined;
      case AdminSection.products:
        return Icons.cake_outlined;
      case AdminSection.reviews:
        return Icons.rate_review_outlined;
      case AdminSection.customers:
        return Icons.groups_2_outlined;
      case AdminSection.settings:
        return Icons.settings_suggest_outlined;
    }
  }
}
