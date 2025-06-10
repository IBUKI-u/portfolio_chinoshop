// pages/admin/widgets/manual_transaction_dialog.dart
import 'package:flutter/material.dart';
import '../../../constants/admin_constants.dart';
import '../../../models/transaction_model.dart';
import '../../../services/admin_transaction_service.dart';
import '../../../widgets/admin_dialog.dart';
import '../../../utils/admin_formatter.dart';

class ManualTransactionDialog extends StatefulWidget {
  final String safeId;
  final String currentUserId;
  final VoidCallback onSaved;

  const ManualTransactionDialog({
    super.key,
    required this.safeId,
    required this.currentUserId,
    required this.onSaved,
  });

  @override
  State<ManualTransactionDialog> createState() => _ManualTransactionDialogState();
}

class _ManualTransactionDialogState extends State<ManualTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final AdminTransactionService _transactionService = AdminTransactionService();
  
  String _accountTitle = 'other';
  DateTime _transactionDate = DateTime.now();
  String _paymentStatus = 'paid';

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeName = AdminConstants.safeTypeMap[widget.safeId] ?? widget.safeId;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text('手動入出金 - $safeName'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 金額入力
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: '金額（+入金、-出金）',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.monetization_on),
                  helperText: '入金は正の値、出金は負の値で入力',
                ),
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '金額を入力してください';
                  }
                  if (int.tryParse(value) == null) {
                    return '正しい数値を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // カテゴリ選択
              DropdownButtonFormField<String>(
                value: _accountTitle,
                decoration: InputDecoration(
                  labelText: 'カテゴリ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: AdminConstants.accountTitleMap.entries
                    .where((entry) => entry.key != 'all')
                    .map((entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _accountTitle = value!),
              ),
              const SizedBox(height: 16),
              
              // ツケ購入の場合のみ支払い状況を表示
              if (_accountTitle == 'tsuke_purchase') ...[
                DropdownButtonFormField<String>(
                  value: _paymentStatus,
                  decoration: InputDecoration(
                    labelText: '支払い状況',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'paid', child: Text('支払い済み')),
                    DropdownMenuItem(value: 'unpaid', child: Text('未払い')),
                  ],
                  onChanged: (value) => setState(() => _paymentStatus = value!),
                ),
                const SizedBox(height: 16),
              ],
              
              // 取引日時選択
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
              const SizedBox(height: 16),
              
              // 備考入力
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: '備考',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _saveTransaction,
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

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final amount = int.parse(_amountController.text);
      
      final transaction = TransactionModel(
        id: '', // Firestoreが自動生成
        safeId: widget.safeId,
        accountTitle: _accountTitle,
        amount: amount,
        transactionDate: _transactionDate,
        relatedUserId: widget.currentUserId,
        notes: _notesController.text,
        paymentStatus: _accountTitle == 'tsuke_purchase' ? _paymentStatus : 'paid',
      );

      await _transactionService.createTransaction(transaction);

      if (context.mounted) {
        Navigator.pop(context);
        AdminDialog.showSnackBar(
          context: context,
          message: '取引を登録しました',
        );
      }
      widget.onSaved();
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