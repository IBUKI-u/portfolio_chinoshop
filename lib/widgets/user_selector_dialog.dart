// widgets/user_selector_dialog.dart
import 'package:flutter/material.dart';
import '../services/user_management_service.dart';

class UserSelectorDialog extends StatefulWidget {
  final String? initialUserId;
  final String title;

  const UserSelectorDialog({
    super.key,
    this.initialUserId,
    this.title = 'ユーザーを選択',
  });

  @override
  State<UserSelectorDialog> createState() => _UserSelectorDialogState();
}

class _UserSelectorDialogState extends State<UserSelectorDialog> {
  final UserManagementService _userService = UserManagementService();
  final TextEditingController _searchController = TextEditingController();
  
  List<UserInfo> _allUsers = [];
  List<UserInfo> _filteredUsers = [];
  UserInfo? _selectedUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getAllUsers(); // 全ユーザー対象
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
        
        // 初期選択ユーザーを設定
        if (widget.initialUserId != null) {
          _selectedUser = users.firstWhere(
            (user) => user.id == widget.initialUserId,
            orElse: () => users.isNotEmpty ? users.first : UserInfo(id: '', username: '', email: '', role: 'user'),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ユーザーリストの読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers
            .where((user) => 
                user.username.toLowerCase().contains(query.toLowerCase()) ||
                user.email.toLowerCase().contains(query.toLowerCase())
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_search, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(widget.title),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // 検索フィールド
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'ユーザー名・メールアドレスで検索',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterUsers,
            ),
            const SizedBox(height: 16),
            
            // ユーザーリスト
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('ユーザーが見つかりません'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final isSelected = _selectedUser?.id == user.id;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected 
                                      ? Theme.of(context).primaryColor 
                                      : Colors.grey[400],
                                  child: Text(
                                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.username,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (user.email.isNotEmpty) 
                                      Text(user.email, style: const TextStyle(fontSize: 12)),
                                    if (user.createdAt != null)
                                      Text(
                                        '登録日: ${_formatDate(user.createdAt!)}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                  ],
                                ),
                                trailing: isSelected 
                                    ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedUser = user;
                                  });
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _selectedUser != null
              ? () => Navigator.pop(context, _selectedUser)
              : null,
          child: const Text('選択'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
  }
}