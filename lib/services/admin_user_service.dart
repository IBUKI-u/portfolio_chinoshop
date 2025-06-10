// services/admin_user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/admin_constants.dart';

class AdminUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ユーザー一覧のストリーム取得
  Stream<QuerySnapshot> getUsersStream() {
    return _firestore
        .collection(AdminConstants.usersCollection)
        .snapshots();
  }

  // ユーザー削除
  Future<void> deleteUser(String userId) async {
    await _firestore
        .collection(AdminConstants.usersCollection)
        .doc(userId)
        .delete();
  }

  // ユーザー情報更新
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AdminConstants.usersCollection)
        .doc(userId)
        .update(data);
  }

  // ユーザーロール変更
  Future<void> updateUserRole(String userId, String newRole) async {
    await _firestore
        .collection(AdminConstants.usersCollection)
        .doc(userId)
        .update({'role': newRole});
  }
}