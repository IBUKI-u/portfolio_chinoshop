// services/user_management_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 全ユーザーのリストを取得（インデックス不要）
  Future<List<UserInfo>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      
      final users = snapshot.docs.map((doc) => UserInfo.fromFirestore(doc)).toList();
      
      // クライアント側でusername順にソート
      users.sort((a, b) => a.username.compareTo(b.username));
      
      return users;
    } catch (e) {
      throw Exception('ユーザーリストの取得に失敗しました: $e');
    }
  }

  /// 特定のユーザー情報を取得
  Future<UserInfo?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        return UserInfo.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('ユーザー情報の取得に失敗しました: $e');
    }
  }

  /// ユーザーを検索
  Future<List<UserInfo>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllUsers();
      }

      // 全ユーザーを取得してクライアント側でフィルタリング
      final allUsers = await getAllUsers();
      
      return allUsers.where((user) => 
        user.username.toLowerCase().contains(query.toLowerCase()) ||
        user.email.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      throw Exception('ユーザー検索に失敗しました: $e');
    }
  }
}

/// ユーザー情報クラス
class UserInfo {
  final String id;
  final String username;
  final String email;
  final String role;
  final DateTime? createdAt;

  UserInfo({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory UserInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserInfo(
      id: doc.id,
      username: data['username'] ?? '名前不明',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'role': role,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  @override
  String toString() => username;
}