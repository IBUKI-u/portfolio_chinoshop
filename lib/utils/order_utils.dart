// utils/order_utils.dart
import 'package:flutter/material.dart';

class OrderUtils {
  static Color getAccountTitleColor(String accountTitle) {
    switch (accountTitle) {
      case 'normal_purchase':
        return Colors.green;
      case 'tsuke_purchase':
        return Colors.blue;
      case 'procurement':
        return Colors.purple;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  static String getAccountTitleText(String accountTitle) {
    switch (accountTitle) {
      case 'normal_purchase':
        return '通常購入';
      case 'tsuke_purchase':
        return 'つけ購入';
      case 'procurement':
        return '調達';
      case 'other':
        return 'その他';
      default:
        return '不明';
    }
  }
}