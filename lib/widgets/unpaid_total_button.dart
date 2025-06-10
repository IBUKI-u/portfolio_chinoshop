// widgets/unpaid_total_button.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/order_service.dart';
import 'unpaid_total_dialog.dart';

class UnpaidTotalButton extends StatelessWidget {
  final String userId;
  final OrderService _orderService = OrderService();

  UnpaidTotalButton({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showUnpaidTotalDialog(context),
      icon: Stack(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.orange,
            size: 28,
          ),
          _buildNotificationBadge(),
        ],
      ),
      tooltip: 'ツケ未払い総計を確認',
    );
  }

  Widget _buildNotificationBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _orderService.getUnpaidOrdersStream(userId),
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
    );
  }

  void _showUnpaidTotalDialog(BuildContext context) async {
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
      final unpaidTotal = await _orderService.calculateUnpaidTotal(userId);
      Navigator.of(context).pop();
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return UnpaidTotalDialog(unpaidTotal: unpaidTotal);
        },
      );
    } catch (e) {
      Navigator.of(context).pop();
      
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
}