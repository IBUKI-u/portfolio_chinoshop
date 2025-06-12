// services/admin_transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class AdminTransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 取引履歴のストリームを取得（フィルター機能付き）
  Stream<QuerySnapshot> getTransactionsStream({
    required String safeId,
    String accountTitle = 'all',
    bool showUnpaidOnly = false,
  }) {
    Query query = _firestore
        .collection('transactions')
        .where('safeId', isEqualTo: safeId)
        .orderBy('transactionDate', descending: true);

    // アカウントタイトルでフィルター
    if (accountTitle != 'all') {
      query = query.where('accountTitle', isEqualTo: accountTitle);
    }

    // 未払いのみフィルター
    if (showUnpaidOnly) {
      query = query.where('paymentStatus', isEqualTo: 'unpaid');
    }

    return query.snapshots();
  }

  /// 金庫の残高を取得
  Stream<DocumentSnapshot> getSafeBalance(String safeId) {
    return _firestore.collection('safes').doc(safeId).snapshots();
  }

  /// 注文アイテムを取得
  Future<QuerySnapshot> getOrderItems(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('orderItems')
        .get();
  }

  /// 取引を更新し、対応する注文も同期
  Future<void> updateTransaction(String transactionId, Map<String, dynamic> updates) async {
    final batch = _firestore.batch();
    
    try {
      // トランザクションドキュメントを取得
      final transactionDoc = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();
      
      if (!transactionDoc.exists) {
        throw Exception('取引が見つかりません');
      }
      
      final transaction = TransactionModel.fromFirestore(transactionDoc);
      
      // 支払いステータスの変更がある場合は残高を調整
      if (updates.containsKey('paymentStatus')) {
        final oldStatus = transaction.paymentStatus;
        final newStatus = updates['paymentStatus'] as String;
        
        // 未払い→支払い済みの場合：残高に反映
        if (oldStatus == 'unpaid' && newStatus == 'paid') {
          await _updateSafeBalance(batch, transaction.safeId, transaction.amount);
        }
        // 支払い済み→未払いの場合：残高から差し引き
        else if (oldStatus == 'paid' && newStatus == 'unpaid') {
          await _updateSafeBalance(batch, transaction.safeId, -transaction.amount);
        }
      }
      
      // 金額の変更がある場合は残高を調整
      if (updates.containsKey('amount')) {
        final oldAmount = transaction.amount;
        final newAmount = updates['amount'] as int;
        final amountDifference = newAmount - oldAmount;
        
        // 支払い済みの取引のみ残高に反映
        if (transaction.paymentStatus == 'paid') {
          await _updateSafeBalance(batch, transaction.safeId, amountDifference);
        }
      }
      
      // トランザクションを更新
      batch.update(
        _firestore.collection('transactions').doc(transactionId),
        updates,
      );
      
      // 対応する注文がある場合は同期
      if (transaction.orderId != null) {
        await _syncOrderWithTransaction(batch, transaction, updates);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('取引の更新に失敗しました: $e');
    }
  }

  /// 取引を削除し、対応する注文も同期
  Future<void> deleteTransaction(String transactionId, TransactionModel transaction) async {
    final batch = _firestore.batch();
    
    try {
      // トランザクションを削除
      batch.delete(_firestore.collection('transactions').doc(transactionId));
      
      // 対応する注文がある場合
      if (transaction.orderId != null) {
        // 注文に関連する他の取引があるかチェック
        final relatedTransactions = await _firestore
            .collection('transactions')
            .where('orderId', isEqualTo: transaction.orderId)
            .where(FieldPath.documentId, isNotEqualTo: transactionId)
            .get();
        
        if (relatedTransactions.docs.isEmpty) {
          // 他に関連取引がない場合は注文も削除
          batch.delete(_firestore.collection('orders').doc(transaction.orderId));
          
          // 注文アイテムも削除
          final orderItems = await _firestore
              .collection('orders')
              .doc(transaction.orderId)
              .collection('orderItems')
              .get();
          
          for (final item in orderItems.docs) {
            batch.delete(item.reference);
          }
        } else {
          // 他に関連取引がある場合は金額を再計算
          await _recalculateOrderTotal(batch, transaction.orderId!);
        }
      }
      
      // 支払い済みの取引のみ残高から差し引き
      if (transaction.paymentStatus == 'paid') {
        await _updateSafeBalance(batch, transaction.safeId, -transaction.amount);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('取引の削除に失敗しました: $e');
    }
  }

  /// 手動取引を作成し、必要に応じて注文も作成
  Future<void> createTransaction(TransactionModel transaction) async {
    final batch = _firestore.batch();
    
    try {
      // 新しいトランザクションドキュメントの参照を作成
      final transactionRef = _firestore.collection('transactions').doc();
      final transactionWithId = transaction.copyWith(id: transactionRef.id);
      
      String? orderId;
      
      // 購入系の場合は対応する注文も作成
      if (transaction.accountTitle == 'tsuke_purchase' || transaction.accountTitle == 'normal_purchase') {
        orderId = await _createCorrespondingOrder(batch, transactionWithId);
        // トランザクションにorderIdを設定
        final transactionWithOrderId = transactionWithId.copyWith(orderId: orderId);
        batch.set(transactionRef, transactionWithOrderId.toFirestore());
      } else {
        // 購入系以外の場合はそのまま作成
        batch.set(transactionRef, transactionWithId.toFirestore());
      }
      
      // 支払い済みの取引のみ残高を更新
      // ツケ購入で未払いの場合は残高を変更しない
      if (transaction.paymentStatus == 'paid') {
        await _updateSafeBalance(batch, transaction.safeId, transaction.amount);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('取引の作成に失敗しました: $e');
    }
  }

  /// 支払い確認時の処理（注文も同期）
  Future<void> markAsPaid(String transactionId, TransactionModel transaction) async {
    final batch = _firestore.batch();
    
    try {
      // トランザクションの支払いステータスを更新
      batch.update(
        _firestore.collection('transactions').doc(transactionId),
        {'paymentStatus': 'paid'},
      );
      
      // 対応する注文も更新
      if (transaction.orderId != null) {
        batch.update(
          _firestore.collection('orders').doc(transaction.orderId),
          {'paymentStatus': 'paid'},
        );
      }
      
      // 未払い→支払い済みになる場合のみ残高を更新
      if (transaction.paymentStatus == 'unpaid') {
        await _updateSafeBalance(batch, transaction.safeId, transaction.amount);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('支払い確認に失敗しました: $e');
    }
  }

  /// 注文と取引を同期
  Future<void> _syncOrderWithTransaction(
    WriteBatch batch,
    TransactionModel transaction,
    Map<String, dynamic> updates,
  ) async {
    final orderRef = _firestore.collection('orders').doc(transaction.orderId);
    final orderDoc = await orderRef.get();
    
    if (!orderDoc.exists) return;
    
    final orderUpdates = <String, dynamic>{};
    
    // 支払いステータスの同期
    if (updates.containsKey('paymentStatus')) {
      orderUpdates['paymentStatus'] = updates['paymentStatus'];
    }
    
    // 取引日時の同期
    if (updates.containsKey('transactionDate')) {
      orderUpdates['orderDate'] = updates['transactionDate'];
    }
    
    // 金額の同期
    if (updates.containsKey('amount')) {
      orderUpdates['totalAmount'] = (updates['amount'] as int).abs();
    }
    
    if (orderUpdates.isNotEmpty) {
      batch.update(orderRef, orderUpdates);
    }
  }

  /// 対応する注文を作成（手動取引用）
  Future<String> _createCorrespondingOrder(
    WriteBatch batch,
    TransactionModel transaction,
  ) async {
    final orderRef = _firestore.collection('orders').doc();
    
    // ユーザー側の注文履歴に表示するための注文データを作成
    final orderData = {
      'userId': transaction.relatedUserId, // 重要：購入者のユーザーIDを設定
      'orderDate': Timestamp.fromDate(transaction.transactionDate),
      'totalAmount': transaction.amount.abs(),
      'accountTitle': transaction.accountTitle,
      'paymentStatus': transaction.paymentStatus,
      'isManualEntry': true, // 手動入力フラグ
      'safeId': transaction.safeId, // 金庫IDも保存
      // 注意：管理者側の備考（ユーザー名 ユーザーID）はユーザー側には表示しない
    };
    
    batch.set(orderRef, orderData);
    
    // 手動入力の場合、アイテムは「管理者による手動入力」として作成
    final orderItemRef = orderRef.collection('orderItems').doc();
    final orderItemData = {
      'itemName': '管理者による手動入力',
      'quantity': 1,
      'unitPrice': transaction.amount.abs(),
      'subtotal': transaction.amount.abs(),
      'isManualEntry': true,
    };
    
    batch.set(orderItemRef, orderItemData);
    
    return orderRef.id;
  }

  /// 注文の合計金額を再計算
  Future<void> _recalculateOrderTotal(WriteBatch batch, String orderId) async {
    final relatedTransactions = await _firestore
        .collection('transactions')
        .where('orderId', isEqualTo: orderId)
        .get();
    
    int newTotal = 0;
    String paymentStatus = 'paid';
    
    for (final doc in relatedTransactions.docs) {
      final transaction = TransactionModel.fromFirestore(doc);
      newTotal += transaction.amount.abs();
      
      if (transaction.paymentStatus == 'unpaid') {
        paymentStatus = 'unpaid';
      }
    }
    
    batch.update(
      _firestore.collection('orders').doc(orderId),
      {
        'totalAmount': newTotal,
        'paymentStatus': paymentStatus,
      },
    );
  }

  /// 残高を更新
  Future<void> _updateSafeBalance(WriteBatch batch, String safeId, int amount) async {
    final safeRef = _firestore.collection('safes').doc(safeId);
    
    batch.update(safeRef, {
      'balance': FieldValue.increment(amount),
    });
  }
}