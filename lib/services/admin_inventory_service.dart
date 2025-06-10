// services/admin_inventory_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/admin_constants.dart';

class AdminInventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // リファレンス取得
  CollectionReference<Map<String, dynamic>> get itemsRef =>
      _firestore.collection('items');

  // カテゴリ取得
  Future<List<String>> fetchCategories() async {
    final snapshot = await _firestore.collection(AdminConstants.categoriesCollection).get();
    final categories = snapshot.docs.map((doc) => doc['name'] as String).toList();
    return ['すべて', ...categories];
  }

  // 在庫調整
  Future<void> adjustStock(String itemId, int newStock) async {
    await _firestore
        .collection(AdminConstants.itemsCollection)
        .doc(itemId)
        .update({'stock': newStock});
  }

  // 商品情報更新
  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AdminConstants.itemsCollection)
        .doc(itemId)
        .update(data);
  }

  // 商品追加
  Future<void> addItem(Map<String, dynamic> data) async {
    await _firestore.collection(AdminConstants.itemsCollection).add({
      ...data,
      'imgBase64': '',
      'isVisible': true,
    });
  }

  // 商品削除
  Future<void> deleteItem(String itemId) async {
    await _firestore
        .collection(AdminConstants.itemsCollection)
        .doc(itemId)
        .delete();
  }

  // 商品の表示/非表示切り替え
  Future<void> toggleItemVisibility(String itemId, bool isVisible) async {
    await _firestore
        .collection(AdminConstants.itemsCollection)
        .doc(itemId)
        .update({'isVisible': !isVisible});
  }

  // 商品ストリーム取得
  Stream<QuerySnapshot> getItemsStream() {
    return _firestore
        .collection(AdminConstants.itemsCollection)
        .orderBy('name')
        .snapshots();
  }
}