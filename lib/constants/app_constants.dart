// constants/app_constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // Collections
  static const String ordersCollection = 'orders';
  static const String orderItemsCollection = 'orderItems';

  // Account Titles
  static const String normalPurchase = 'normal_purchase';
  static const String tsukePurchase = 'tsuke_purchase';
  static const String procurement = 'procurement';
  static const String other = 'other';

  // Payment Status
  static const String paid = 'paid';
  static const String unpaid = 'unpaid';

  // Colors
  static const Color primaryColor = Colors.orange;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
}
