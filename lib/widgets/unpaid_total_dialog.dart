// widgets/unpaid_total_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UnpaidTotalDialog extends StatelessWidget {
  final int unpaidTotal;

  const UnpaidTotalDialog({
    super.key,
    required this.unpaidTotal,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: _buildTitle(),
      content: _buildContent(),
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
  }

  Widget _buildTitle() {
    return Row(
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
    );
  }

  Widget _buildContent() {
    return Column(
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
    );
  }
}