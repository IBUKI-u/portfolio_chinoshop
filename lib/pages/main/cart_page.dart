import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class CartPage extends StatefulWidget {
  final String userId;
  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isLoading = false;
  bool isLabMate = false;
  late Future<List<Map<String, dynamic>>> _cartFuture;

  @override
  void initState() {
    super.initState();
    _checkRoleLabMate();
    _cartFuture = _loadCartItems();
  }

  Future<void> _checkRoleLabMate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // ドキュメントが存在し、データが取得できた場合
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        setState(() {
          // role フィールドが"labMate"に一致すれば True に設定
          isLabMate = (data['role'] == 'labMate');
        });
      } else {
        setState(() {
          isLabMate = false; // ドキュメントが存在しない場合
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadCartItems() async {
    final List<Map<String, dynamic>> cartData = [];

    final cartSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('cartItems')
        .get();

    for (var doc in cartSnapshot.docs) {
      final itemId = doc.id;
      final quantity = doc['quantity'] ?? 1;

      final itemSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .doc(itemId)
          .get();

      if (itemSnapshot.exists) {
        final itemData = itemSnapshot.data()!;
        cartData.add({
          'itemId': itemId,
          'quantity': quantity,
          'name': itemData['name'] ?? '名前なし',
          'price': itemData['price'] ?? 0,
          'stock': itemData['stock'] ?? 0,
          'imgBase64': itemData['imgBase64'] ?? '',
        });
      }
    }

    return cartData;
  }

  Future<void> _updateQuantity(String itemId, int newQuantity) async {
    setState(() => isLoading = true);

    try {
      if (newQuantity <= 0) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('cartItems')
            .doc(itemId)
            .delete();
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('cartItems')
            .doc(itemId)
            .update({'quantity': newQuantity});
      }

      setState(() => _cartFuture = _loadCartItems());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitOrder(List<Map<String, dynamic>> cartItems, {required bool isNormalPurchase}) async {
    setState(() => isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      final userCartRef = userRef.collection('cartItems');

      // 在庫チェック
      for (var item in cartItems) {
        final itemRef = FirebaseFirestore.instance.collection('items').doc(item['itemId']);
        final itemSnapshot = await itemRef.get();

        if (!itemSnapshot.exists) {
          throw Exception('${item['name']} は存在しません');
        }

        final currentStock = itemSnapshot.data()?['stock'] ?? 0;
        if (currentStock < item['quantity']) {
          throw Exception('${item['name']} の在庫が不足しています（残り: $currentStock）');
        }
      }

      // 合計金額計算
      int totalAmount = cartItems.fold(0, (sum, item) {
        final price = (item['price'] ?? 0) as int;
        final quantity = (item['quantity'] ?? 0) as int;
        return sum + price * quantity;
      });

      // ユーザー情報取得
      final userSnapshot = await userRef.get();
      final username = userSnapshot.data()?['username'] ?? '名無し';

      // 注文データ作成
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final orderId = orderRef.id;
      final now = FieldValue.serverTimestamp();

      final orderData = {
        'userId': widget.userId,
        'orderDate': now,
        'totalAmount': totalAmount,
        'accountTitle': isNormalPurchase ? 'normal_purchase' : 'tsuke_purchase',
        'paymentStatus': isNormalPurchase ? 'paid' : 'unpaid',
        'notes': '',
      };

      batch.set(orderRef, orderData);

      // 注文アイテム作成
      for (var item in cartItems) {
        final orderItemRef = orderRef.collection('orderItems').doc(item['itemId']);
        batch.set(orderItemRef, {
          'itemName': item['name'],
          'quantity': item['quantity'],
          'unitPrice': item['price'],
          'subtotal': item['price'] * item['quantity'],
        });

        // 在庫減少
        final itemRef = FirebaseFirestore.instance.collection('items').doc(item['itemId']);
        batch.update(itemRef, {'stock': FieldValue.increment(-item['quantity'])});

        // カートから削除
        batch.delete(userCartRef.doc(item['itemId']));
      }

      // 取引記録作成（通常購入の場合のみ即座に残高反映）
      final transactionRef = FirebaseFirestore.instance.collection('transactions').doc(orderId);
      final transactionData = {
        'safeId': 'safe', // デフォルトで金庫
        'accountTitle': isNormalPurchase ? 'normal_purchase' : 'tsuke_purchase',
        'amount': totalAmount,
        'orderId': orderId,
        'transactionDate': now,
        'relatedUserId': widget.userId,
        'notes': '$username ${userSnapshot.id}',
        'paymentStatus': isNormalPurchase ? 'paid' : 'unpaid',
      };

      batch.set(transactionRef, transactionData);

      // 通常購入の場合は残高更新
      if (isNormalPurchase) {
        final safeRef = FirebaseFirestore.instance.collection('safes').doc('safe');
        final safeSnapshot = await safeRef.get();
        final currentBalance = safeSnapshot.exists ? (safeSnapshot.data()?['balance'] ?? 0) : 0;
        final newBalance = currentBalance + totalAmount;

        batch.update(safeRef, {
          'balance': newBalance,
          'lastUpdated': now,
        });

        // 取引後残高を記録
        batch.update(transactionRef, {'balanceAfterTransaction': newBalance});
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isNormalPurchase ? '通常' : 'ツケ'}購入が完了しました')),
        );
        setState(() => _cartFuture = _loadCartItems());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _quantityButton(String symbol, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(4),
          color: onTap == null ? Colors.grey[300] : Colors.white,
        ),
        child: Text(
          symbol,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カート')),
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _cartFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
              }

              final cartItems = snapshot.data ?? [];
              if (cartItems.isEmpty) return const Center(child: Text('カートは空です'));

              int total = cartItems.fold(0, (sum, item) {
                final price = (item['price'] ?? 0) as int;
                final quantity = (item['quantity'] ?? 0) as int;
                return sum + price * quantity;
              });

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item['imgBase64'].isNotEmpty
                                      ? Image.memory(
                                          base64Decode(item['imgBase64']),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image_not_supported),
                                          ),
                                        )
                                      : Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image_not_supported),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '¥${item['price']}',
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                      Text(
                                        '在庫: ${item['stock']}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _updateQuantity(item['itemId'], 0),
                                            child: const Text(
                                              '削除する',
                                              style: TextStyle(color: Colors.red, fontSize: 13),
                                            ),
                                          ),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              _quantityButton(
                                                '-',
                                                item['quantity'] > 1
                                                    ? () => _updateQuantity(item['itemId'], item['quantity'] - 1)
                                                    : null,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Text('${item['quantity']}', style: const TextStyle(fontSize: 16)),
                                              ),
                                              _quantityButton(
                                                '+',
                                                item['quantity'] < item['stock']
                                                    ? () => _updateQuantity(item['itemId'], item['quantity'] + 1)
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (isLabMate) Text('ゲストユーザーは通常購入のみ可能です'),
                        Text(
                          '合計: ¥$total',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: cartItems.isEmpty || isLoading || isLabMate
                                    ? null
                                    : () => _submitOrder(cartItems, isNormalPurchase: false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLabMate
                                      ? Colors.grey[500]
                                      : Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('ツケ購入', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: cartItems.isEmpty || isLoading
                                    ? null
                                    : () => _submitOrder(cartItems, isNormalPurchase: true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('通常購入', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}