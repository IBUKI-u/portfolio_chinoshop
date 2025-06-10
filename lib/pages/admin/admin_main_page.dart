import 'package:flutter/material.dart';

import 'admin_inventory_page.dart';
import 'admin_user_management_page.dart';
import 'admin_money_management_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          '管理者ページ',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminMenuTile(
            icon: Icons.people,
            title: 'ユーザー管理',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminUserManagementPage()),
            ),
          ),
          AdminMenuTile(
            icon: Icons.shopping_basket,
            title: '商品管理',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminInventoryPage()),
            ),
          ),
          AdminMenuTile(
            icon: Icons.receipt_long,
            title: '資金管理',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MoneyManagementPage()),
            ),
          ),
          // AdminMenuTile(
          //   icon: Icons.receipt_long,
          //   title: '購入履歴の確認',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (_) => const AdminOrderHistoryPage()),
          //   ),
          // ),
          // AdminMenuTile(
          //   icon: Icons.bar_chart,
          //   title: '売上集計・人気商品',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (_) => const AdminSalesReportPage()),
          //   ),
          // ),
          // AdminMenuTile(
          //   icon: Icons.text_snippet,
          //   title: 'テスト用ページ',
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (_) => MoneyManagementPage()),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const AdminMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
