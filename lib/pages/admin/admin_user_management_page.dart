// pages/admin/admin_user_management_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/admin_constants.dart';
import '../../widgets/admin_dialog.dart';
import '../../widgets/loading_widget.dart';
import '../../services/admin_user_service.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final AdminUserService _userService = AdminUserService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'ユーザー管理',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _userService.getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'ユーザー情報を読み込んでいます...');
          }

          if (snapshot.hasError) {
            return const Center(child: Text('エラーが発生しました'));
          }

          final users = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userId = user.id;
              final userData = user.data() as Map<String, dynamic>;
              
              return _UserListTile(
                userId: userId,
                userData: userData,
                onDelete: () => _deleteUser(userId, userData['username'] ?? '未設定'),
              );
            },
          );
        },
      ),
    );
  }

  void _deleteUser(String userId, String username) async {
    // 自分自身を削除しないように防止
    if (userId == FirebaseAuth.instance.currentUser?.uid) {
      AdminDialog.showSnackBar(
        context: context,
        message: '自分自身は削除できません',
        isError: true,
      );
      return;
    }

    final confirm = await AdminDialog.showConfirmDialog(
      context: context,
      title: 'ユーザー削除の確認',
      content: 'ユーザー "$username" を削除しますか？\nFirestoreから削除され、ログインできなくなります。',
      icon: Icons.warning,
    );

    if (confirm == true) {
      try {
        await _userService.deleteUser(userId);
        if (mounted) {
          AdminDialog.showSnackBar(
            context: context,
            message: 'Firestoreから削除しました。\nFirebaseAuthの削除はCloud Functions等で対応が必要です。',
          );
        }
      } catch (e) {
        if (mounted) {
          AdminDialog.showSnackBar(
            context: context,
            message: '削除に失敗しました: $e',
            isError: true,
          );
        }
      }
    }
  }
}

class _UserListTile extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final VoidCallback onDelete;

  const _UserListTile({
    required this.userId,
    required this.userData,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final username = userData['username'] ?? '未設定';
    final userRole = userData['role'] ?? '';
    final roleText = AdminConstants.userRoleMap[userRole] ?? '不明なユーザー';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            _getRoleIcon(userRole),
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          username,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(userRole).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getRoleColor(userRole).withOpacity(0.3)),
              ),
              child: Text(
                roleText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getRoleColor(userRole),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userId,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
          tooltip: 'ユーザーを削除',
        ),
        onLongPress: onDelete,
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'labMate':
        return Icons.science;
      case 'user':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'labMate':
        return Colors.blue;
      case 'user':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}