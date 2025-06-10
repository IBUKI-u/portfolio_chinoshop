// widgets/order_items_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';

class OrderItemsWidget extends StatelessWidget {
  final String orderId;
  final OrderService _orderService = OrderService();

  OrderItemsWidget({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _orderService.getOrderItemsStream(orderId),
      builder: (context, itemsSnapshot) {
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

        if (!itemsSnapshot.hasData || itemsSnapshot.data == null) {
          print('OrderItems: No data available for order $orderId');
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
        
        if (orderItems.isEmpty) {
          print('OrderItems: Empty collection for order $orderId');
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
    );
  }
}