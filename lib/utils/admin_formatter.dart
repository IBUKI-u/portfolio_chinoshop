// utils/admin_formatter.dart
import 'package:intl/intl.dart';

class AdminFormatter {
  // 数値を通貨形式に変換
  static String formatCurrency(int amount) {
    return '¥${NumberFormat('#,###').format(amount)}';
  }

  // 日時フォーマット
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  // 日付フォーマット
  static String formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  // 時刻フォーマット
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
}