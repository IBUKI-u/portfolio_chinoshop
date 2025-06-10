// pages/admin/widgets/edit_transaction_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/transaction_model.dart';
import '../../../services/admin_transaction_service.dart';
import '../../../widgets/admin_dialog.dart';
import '../../../utils/admin_formatter.dart';

class EditTransactionDialog extends StatefulWidget {
  final TransactionModel transaction;
  final String currentUserId;
  final VoidCallback onUpdate;

  const EditTransactionDialog({
    super.key,
    required this.transaction,
    required this.currentUserId,
    required this.onUpdate,
  });

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  late TextEditingController _notesController;
  late DateTime _transactionDate;
  final AdminTransactionService _transactionService = AdminTransactionService();

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.transaction.notes);
    _transactionDate = widget.transaction.transactionDate;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('取引編集'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 金額（読み取り専用）
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              leading: const Icon(Icons.monetization_on),
              title: const Text('金額'),
              subtitle: Text(
                AdminFormatter.formatCurrency(widget.transaction.amount),
                style: TextStyle(
                  color: widget.transaction.amount >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              tileColor: Colors.grey[50],
            ),
            const SizedBox(height: 16),
            
            // 備考
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: '備考',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.note),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // 取引日時
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              title: const Text('取引日時'),
              subtitle: Text(AdminFormatter.formatDateTime(_transactionDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDateTime,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('保存'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_transactionDate),
      );
      
      if (time != null) {
        setState(() {
          _transactionDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      await _transactionService.updateTransaction(
        widget.transaction.id,
        {
          'notes': _notesController.text,
          'transactionDate': Timestamp.fromDate(_transactionDate),
        },
      );

      if (context.mounted) {
        Navigator.pop(context);
        AdminDialog.showSnackBar(
          context: context,
          message: '取引を更新しました',
        );
      }
      widget.onUpdate();
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