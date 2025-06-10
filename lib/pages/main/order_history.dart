import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends StatefulWidget {
  final String userId;
  const OrderHistoryPage({super.key, required this.userId});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPage();
}

class _OrderHistoryPage extends State<OrderHistoryPage> {
  // 未払い総計を計算する関数
  Future<int> _calculateUnpaidTotal() async {
    try {
      final QuerySnapshot unpaidOrders = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: widget.userId)
          .where('accountTitle', isEqualTo: 'tsuke_purchase')
          .where('paymentStatus', isEqualTo: 'unpaid')
          .get();

      int total = 0;
      for (var doc in unpaidOrders.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['totalAmount'] ?? 0) as int;
      }
      return total;
    } catch (e) {
      print('Error calculating unpaid total: $e');
      return 0;
    }
  }

  // 未払い総計を表示するダイアログ
  void _showUnpaidTotalDialog() async {
    // ローディングダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        );
      },
    );

    try {
      final unpaidTotal = await _calculateUnpaidTotal();
      
      // ローディングダイアログを閉じる
      Navigator.of(context).pop();

      // 結果ダイアログを表示
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ツケ未払い総計',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: unpaidTotal > 0 ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: unpaidTotal > 0 ? Colors.red : Colors.green,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        unpaidTotal > 0 ? '未払い金額' : '未払いなし',
                        style: TextStyle(
                          fontSize: 14,
                          color: unpaidTotal > 0 ? Colors.red[700] : Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¥${NumberFormat('#,###').format(unpaidTotal)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: unpaidTotal > 0 ? Colors.red[700] : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (unpaidTotal > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, 
                             size: 20, 
                             color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ツケ購入の未払い分があります。\n早めのお支払いをお願いします。',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  '閉じる',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // ローディングダイアログを閉じる
      Navigator.of(context).pop();
      
      // エラーダイアログを表示
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('エラー'),
            content: Text('未払い総計の計算中にエラーが発生しました。\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: Image.asset(
          'assets/images/SHOP_logo0.png',
          height: kToolbarHeight,
          width: kToolbarHeight,
          fit: BoxFit.contain,
        ),
        title: const Text(
          '注文履歴',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          // 未払い総計確認ボタン
          IconButton(
            onPressed: _showUnpaidTotalDialog,
            icon: Stack(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.orange,
                  size: 28,
                ),
                // 未払いがある場合の通知バッジ（StreamBuilderで動的に表示）
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('userId', isEqualTo: widget.userId)
                      .where('accountTitle', isEqualTo: 'tsuke_purchase')
                      .where('paymentStatus', isEqualTo: 'unpaid')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${snapshot.data!.docs.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            tooltip: 'ツケ未払い総計を確認',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // エラーハンドリング
          if (snapshot.hasError) {
            print('Orders error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'エラーが発生しました',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // 接続状態のチェック
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            );
          }

          // データがない場合
          if (!snapshot.hasData || snapshot.data == null) {
            print('Orders: No data available for userId: ${widget.userId}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'データを取得できませんでした',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;
          print('Orders found: ${orders.length} for userId: ${widget.userId}');
          
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '注文履歴がありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final order = orderDoc.data() as Map<String, dynamic>;
              final orderDate = (order['orderDate'] as Timestamp?)?.toDate();
              final totalAmount = order['totalAmount'] ?? 0;
              final accountTitle = order['accountTitle'] ?? '';
              final paymentStatus = order['paymentStatus'] ?? '';
              final notes = order['notes'] ?? '';

              // つけ購入かどうかの判定
              final isTsuke = accountTitle == 'tsuke_purchase';
              final isPaid = paymentStatus == 'paid';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ヘッダー部分
                      Row(
                        children: [
                          // Container(
                          //   padding: const EdgeInsets.all(8),
                          //   decoration: BoxDecoration(
                          //     color: Colors.orange.withOpacity(0.1),
                          //     borderRadius: BorderRadius.circular(8),
                          //   ),
                          //   child: const Icon(
                          //     Icons.receipt,
                          //     color: Colors.orange,
                          //     size: 20,
                          //   ),
                          // ),
                          // const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  orderDate != null 
                                      ? DateFormat('[yyyy/MM/dd]').format(orderDate)
                                      : '日付不明',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  orderDate != null 
                                      ? DateFormat(' HH:mm').format(orderDate)
                                      : '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 支払いステータス
                          if (isTsuke) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isPaid ? Colors.green[50] : Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPaid ? Colors.green : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPaid ? Icons.check_circle : Icons.schedule,
                                    color: isPaid ? Colors.green[700] : Colors.red[700],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isPaid ? '支払い済み' : '未払い',
                                    style: TextStyle(
                                      color: isPaid ? Colors.green[700] : Colors.red[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(),
                          ],
                          SizedBox(width: 16),
                          // 購入タイプバッジ
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getAccountTitleColor(accountTitle).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getAccountTitleColor(accountTitle),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getAccountTitleText(accountTitle),
                              style: TextStyle(
                                color: _getAccountTitleColor(accountTitle),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 商品リスト（orderItemsサブコレクションから取得）
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('orders')
                            .doc(orderDoc.id)
                            .collection('orderItems')
                            .snapshots(),
                        builder: (context, itemsSnapshot) {
                          // エラーハンドリング
                          if (itemsSnapshot.hasError) {
                            print('OrderItems error: ${itemsSnapshot.error}');
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'エラー: 商品情報を取得できませんでした',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            );
                          }

                          // データが読み込み中の場合
                          if (itemsSnapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }

                          // データがない場合（nullやスナップショットが存在しない）
                          if (!itemsSnapshot.hasData || itemsSnapshot.data == null) {
                            print('OrderItems: No data available for order ${orderDoc.id}');
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '商品情報がありません',
                                style: TextStyle(fontSize: 14),
                              ),
                            );
                          }

                          final orderItems = itemsSnapshot.data!.docs;
                          
                          // orderItemsが空の場合
                          if (orderItems.isEmpty) {
                            print('OrderItems: Empty collection for order ${orderDoc.id}');
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '商品情報が見つかりません',
                                style: TextStyle(fontSize: 14),
                              ),
                            );
                          }
                          
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: orderItems.map<Widget>((itemDoc) {
                                final item = itemDoc.data() as Map<String, dynamic>;
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${item['itemName'] ?? '商品名不明'}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '× ${item['quantity'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        '¥${NumberFormat('#,###').format(item['subtotal'] ?? 0)}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 備考がある場合は表示
                      if (notes.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.note, size: 16, color: Colors.blue[700]),
                                  const SizedBox(width: 6),
                                  Text(
                                    '備考',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notes,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // 合計金額と支払い状況
                      Align(
                            alignment: Alignment.bottomRight, // 右下寄せ
                            child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '合計 ¥${NumberFormat('#,###').format(totalAmount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // accountTitleに応じた色を返す
  Color _getAccountTitleColor(String accountTitle) {
    switch (accountTitle) {
      case 'normal_purchase':
        return Colors.green;
      case 'tsuke_purchase':
        return Colors.blue;
      case 'procurement':
        return Colors.purple;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // accountTitleに応じたテキストを返す
  String _getAccountTitleText(String accountTitle) {
    switch (accountTitle) {
      case 'normal_purchase':
        return '通常購入';
      case 'tsuke_purchase':
        return 'つけ購入';
      case 'procurement':
        return '調達';
      case 'other':
        return 'その他';
      default:
        return '不明';
    }
  }
}