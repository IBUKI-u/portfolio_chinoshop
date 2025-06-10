// pages/admin/widgets/transaction_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/transaction_model.dart';
import '../../../services/admin_transaction_service.dart';
import '../../../constants/admin_constants.dart';
import '../../../widgets/admin_dialog.dart';
import '../../../utils/admin_formatter.dart';
import 'edit_transaction_dialog.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final String currentUserId;
  final VoidCallback onUpdate;
  final AdminTransactionService _transactionService = AdminTransactionService();

  TransactionCard({
    super.key,
    required this.transaction,
    required this.currentUserId,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: transaction.amount >= 0 
              ? Colors.green.shade100 
              : Colors.red.shade100,
            child: Icon(
              transaction.amount >= 0 ? Icons.add : Icons.remove,
              color: transaction.amount >= 0 ? Colors.green : Colors.red,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AdminFormatter.formatCurrency(transaction.amount.abs()),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: transaction.amount >= 0 ? Colors.green : Colors.red,
                ),
              ),
              if (transaction.paymentStatus == 'unpaid')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '未払い',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('勘定科目: ${AdminConstants.accountTitleMap[transaction.accountTitle] ?? transaction.accountTitle}'),
              Text('日付: ${AdminFormatter.formatDateTime(transaction.transactionDate)}'),
              if (transaction.notes.isNotEmpty) 
                Text('備考: ${transaction.notes}'),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              if (transaction.paymentStatus == 'unpaid' && 
                  transaction.accountTitle == 'tsuke_purchase')
                const PopupMenuItem(
                  value: 'mark_paid', 
                  child: Text('支払い確認'),
                ),
              const PopupMenuItem(
                value: 'edit', 
                child: Text('編集'),
              ),
              const PopupMenuItem(
                value: 'delete', 
                child: Text('削除'),
              ),
            ],
          ),
          children: [
            if (transaction.orderId != null)
              FutureBuilder<QuerySnapshot>(
                future: _transactionService.getOrderItems(transaction.orderId!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final items = snapshot.data!.docs;
                  if (items.isEmpty) return const SizedBox.shrink();
                  
                  return Column(
                    children: items.map((item) {
                      final itemData = item.data() as Map<String, dynamic>;
                      return ListTile(
                        dense: true,
                        title: Text(itemData['itemName'] ?? ''),
                        subtitle: Text('¥${itemData['unitPrice']} × ${itemData['quantity']}'),
                        trailing: Text(AdminFormatter.formatCurrency(itemData['subtotal'] ?? 0)),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    switch (action) {
      case 'mark_paid':
        await _markAsPaid(context);
        break;
      case 'edit':
        _showEditDialog(context);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  Future<void> _markAsPaid(BuildContext context) async {
    try {
      await _transactionService.markAsPaid(transaction.id, transaction);
      
      if (context.mounted) {
        AdminDialog.showSnackBar(
          context: context,
          message: '支払いを確認しました',
        );
      }
      onUpdate();
    } catch (e) {
      if (context.mounted) {
        AdminDialog.showSnackBar(
          context: context,
          message: 'エラー: $e',
          isError: true,
        );
      }
    }
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditTransactionDialog(
        transaction: transaction,
        currentUserId: currentUserId,
        onUpdate: onUpdate,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) async {
    final shouldDelete = await AdminDialog.showConfirmDialog(
      context: context,
      title: '取引を削除',
      content: 'この取引を削除しますか？',
      icon: Icons.warning,
    );

    if (shouldDelete == true) {
      try {
        await _transactionService.deleteTransaction(transaction.id, transaction);
        
        if (context.mounted) {
          AdminDialog.showSnackBar(
            context: context,
            message: '取引を削除しました',
          );
        }
        onUpdate();
      } catch (e) {
        if (context.mounted) {
          AdminDialog.showSnackBar(
            context: context,
            message: 'エラー: $e',
            isError: true,
          );
        }
      }
    }
  }
}