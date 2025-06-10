// services/admin_transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/admin_constants.dart';
import '../models/transaction_model.dart';

class AdminTransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // トランザクションのストリーム取得
  Stream<QuerySnapshot> getTransactionsStream({
    required String safeId,
    String? accountTitle,
    bool? showUnpaidOnly,
  }) {
    Query query = _firestore
        .collection(AdminConstants.transactionsCollection)
        .where('safeId', isEqualTo: safeId)
        .orderBy('transactionDate', descending: true);

    if (accountTitle != null && accountTitle != 'all') {
      query = query.where('accountTitle', isEqualTo: accountTitle);
    }

    if (showUnpaidOnly == true) {
      query = query.where('paymentStatus', isEqualTo: 'unpaid');
    }

    return query.snapshots();
  }

  // 金庫の残高取得
  Stream<DocumentSnapshot> getSafeBalance(String safeId) {
    return _firestore
        .collection(AdminConstants.safesCollection)
        .doc(safeId)
        .snapshots();
  }

  // 支払い確認
  Future<void> markAsPaid(String transactionId, TransactionModel transaction) async {
    final batch = _firestore.batch();

    // トランザクションを支払い済みに変更
    final transactionRef = _firestore
        .collection(AdminConstants.transactionsCollection)
        .doc(transactionId);
    batch.update(transactionRef, {'paymentStatus': 'paid'});

    // 注文も支払い済みに変更
    if (transaction.orderId != null) {
      final orderRef = _firestore
          .collection('orders')
          .doc(transaction.orderId);
      batch.update(orderRef, {'paymentStatus': 'paid'});
    }

    // 金庫の残高を更新
    final safeRef = _firestore
        .collection(AdminConstants.safesCollection)
        .doc(transaction.safeId);
    batch.update(safeRef, {
      'balance': FieldValue.increment(transaction.amount),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // トランザクション作成
  Future<void> createTransaction(TransactionModel transaction) async {
    final batch = _firestore.batch();

    // トランザクション作成
    final transactionRef = _firestore
        .collection(AdminConstants.transactionsCollection)
        .doc();
    
    batch.set(transactionRef, transaction.toMap());

    // 支払い済みの場合のみ残高更新
    if (transaction.paymentStatus == 'paid') {
      final safeRef = _firestore
          .collection(AdminConstants.safesCollection)
          .doc(transaction.safeId);
      batch.update(safeRef, {
        'balance': FieldValue.increment(transaction.amount),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // トランザクション更新
  Future<void> updateTransaction(String transactionId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AdminConstants.transactionsCollection)
        .doc(transactionId)
        .update(data);
  }

  // トランザクション削除
  Future<void> deleteTransaction(String transactionId, TransactionModel transaction) async {
    final batch = _firestore.batch();
    
    // トランザクション削除
    final transactionRef = _firestore
        .collection(AdminConstants.transactionsCollection)
        .doc(transactionId);
    batch.delete(transactionRef);
    
    // 支払い済みの場合は残高調整
    if (transaction.paymentStatus == 'paid') {
      final safeRef = _firestore
          .collection(AdminConstants.safesCollection)
          .doc(transaction.safeId);
      batch.update(safeRef, {
        'balance': FieldValue.increment(-transaction.amount),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }

  // 注文アイテム取得
  Future<QuerySnapshot> getOrderItems(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('orderItems')
        .get();
  }
}