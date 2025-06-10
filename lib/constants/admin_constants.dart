// constants/admin_constants.dart
import 'package:flutter/material.dart';

class AdminConstants {
  // コレクション名
  static const String transactionsCollection = 'transactions';
  static const String safesCollection = 'safes';
  static const String itemsCollection = 'items';
  static const String categoriesCollection = 'categories';
  static const String usersCollection = 'users';

  // 勘定科目マップ
  static const Map<String, String> accountTitleMap = {
    'all': '全て',
    'normal_purchase': '通常購入',
    'tsuke_purchase': 'ツケ購入',
    'procurement': '仕入れ',
    'other': 'その他',
  };

  // ユーザーロールマップ
  static const Map<String, String> userRoleMap = {
    'admin': '管理者',
    'labMate': '研究室メンバー',
    'user': '一般ユーザー',
  };

  // 金庫タイプ
  static const Map<String, String> safeTypeMap = {
    'safe': '金庫',
    'wallet': '財布',
  };

  // カラー定義
  static const Color lowStockColor = Colors.red;
  static final Color lowStockBackgroundColor = Colors.red[100]!;
  static const Color normalStockColor = Colors.green;
  static const Color hiddenItemColor = Colors.grey;
  static final Color hiddenItemBackgroundColor = Colors.grey[300]!; 
  static final Color hiddenItemIconColor = Colors.grey[600]!;
}