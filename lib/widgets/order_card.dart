// widgets/order_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/order_utils.dart';
import 'order_items_widget.dart';

class OrderCard extends StatelessWidget {
  final QueryDocumentSnapshot orderDoc;

  OrderCard({
    super.key, 
    required this.orderDoc,
  });

  @override
  Widget build(BuildContext context) {
    final order = orderDoc.data() as Map<String, dynamic>;
    final orderDate = (order['orderDate'] as Timestamp?)?.toDate();
    final totalAmount = order['totalAmount'] ?? 0;
    final accountTitle = order['accountTitle'] ?? '';
    final paymentStatus = order['paymentStatus'] ?? '';
    final isManualEntry = order['isManualEntry'] ?? false; // 手動入力フラグ

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
            _buildHeader(orderDate, accountTitle, paymentStatus, isManualEntry),
            const SizedBox(height: 16),
            OrderItemsWidget(orderId: orderDoc.id),
            const SizedBox(height: 16),
            _buildTotalAmount(totalAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime? orderDate, String accountTitle, String paymentStatus, bool isManualEntry) {
    final isTsuke = accountTitle == 'tsuke_purchase';
    final isPaid = paymentStatus == 'paid';

    return Column(
      children: [
        Row(
          children: [
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
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: OrderUtils.getAccountTitleColor(accountTitle).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: OrderUtils.getAccountTitleColor(accountTitle),
                  width: 1,
                ),
              ),
              child: Text(
                OrderUtils.getAccountTitleText(accountTitle),
                style: TextStyle(
                  color: OrderUtils.getAccountTitleColor(accountTitle),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        
        // 手動入力バッジを追加
        if (isManualEntry) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Icon(
                  Icons.edit,
                  size: 14,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTotalAmount(int totalAmount) {
    return Align(
      alignment: Alignment.bottomRight,
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
    );
  }
}