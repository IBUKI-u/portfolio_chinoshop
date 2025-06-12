// pages/admin/widgets/manual_transaction_dialog.dart
import 'package:flutter/material.dart';
import '../../../constants/admin_constants.dart';
import '../../../models/transaction_model.dart';
import '../../../services/admin_transaction_service.dart';
import '../../../services/user_management_service.dart';
import '../../../widgets/admin_dialog.dart';
import '../../../widgets/user_selector_dialog.dart';
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
  UserInfo? _selectedUser;
  bool _isLoadingUser = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// 購入系の取引かどうかを判定
  bool get _isPurchaseTransaction => 
      _accountTitle == 'normal_purchase' || _accountTitle == 'tsuke_purchase';

  /// ユーザー選択が必要かどうかを判定
  bool get _needsUserSelection => _isPurchaseTransaction;

  /// 備考欄のデフォルト値を更新（シンプル版）
  void _updateNotesDefault() {
    if (_isPurchaseTransaction && _selectedUser != null) {
      // 購入系の場合は常に「ユーザー名 ユーザーID」を設定
      _notesController.text = '${_selectedUser!.username} ${_selectedUser!.id}';
    } else if (!_isPurchaseTransaction) {
      // 購入系以外の場合は備考をクリア
      _notesController.clear();
    }
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
                onChanged: (value) {
                  setState(() {
                    _accountTitle = value!;
                    // カテゴリ変更時にユーザー選択をリセット
                    if (!_needsUserSelection) {
                      _selectedUser = null;
                    }
                    // 備考欄のデフォルト値を更新
                    _updateNotesDefault();
                  });
                },
              ),
              const SizedBox(height: 16),

              // ユーザー選択（購入系の場合のみ表示）
              if (_needsUserSelection) ...[
                _buildUserSelector(),
                const SizedBox(height: 16),
              ],
              
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
                  helperText: _isPurchaseTransaction 
                      ? 'ユーザー選択時に「ユーザー名 ユーザーID」が自動入力されます\n購入者変更時は備考欄が再設定されます'
                      : null,
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
          onPressed: _canSave() ? _saveTransaction : null,
          child: const Text('保存'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildUserSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: const Icon(Icons.person),
        title: Text(_selectedUser != null ? '購入者' : '購入者を選択'),
        subtitle: _selectedUser != null 
            ? Text(
                _selectedUser!.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : const Text('購入者を選択してください'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoadingUser) 
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.arrow_forward_ios),
          ],
        ),
        onTap: _isLoadingUser ? null : _selectUser,
      ),
    );
  }

  Future<void> _selectUser() async {
    setState(() {
      _isLoadingUser = true;
    });

    try {
      final selectedUser = await showDialog<UserInfo>(
        context: context,
        builder: (context) => UserSelectorDialog(
          initialUserId: _selectedUser?.id,
          title: '購入者を選択',
        ),
      );

      if (selectedUser != null) {
        setState(() {
          _selectedUser = selectedUser;
        });
        // ユーザー選択後に備考欄を常に更新
        _updateNotesDefault();
      }
    } catch (e) {
      if (mounted) {
        AdminDialog.showSnackBar(
          context: context,
          message: 'ユーザー選択でエラーが発生しました: $e',
          isError: true,
        );
      }
    } finally {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  bool _canSave() {
    if (_needsUserSelection && _selectedUser == null) {
      return false;
    }
    return true;
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

    if (_needsUserSelection && _selectedUser == null) {
      AdminDialog.showSnackBar(
        context: context,
        message: '購入者を選択してください',
        isError: true,
      );
      return;
    }

    try {
      final amount = int.parse(_amountController.text);
      
      // 関連ユーザーIDを決定
      String relatedUserId;
      if (_needsUserSelection && _selectedUser != null) {
        relatedUserId = _selectedUser!.id;
      } else {
        relatedUserId = widget.currentUserId; // 管理者の取引として記録
      }
      
      // 備考欄の最終確認と設定
      String finalNotes = _notesController.text;
      if (_isPurchaseTransaction && _selectedUser != null) {
        // 購入系の場合は「ユーザー名 ユーザーID」を設定（手動で変更されていなければ）
        if (finalNotes.isEmpty) {
          finalNotes = '${_selectedUser!.username} ${_selectedUser!.id}';
        }
      }
      
      final transaction = TransactionModel(
        id: '', // Firestoreが自動生成
        safeId: widget.safeId,
        accountTitle: _accountTitle,
        amount: amount,
        transactionDate: _transactionDate,
        relatedUserId: relatedUserId,
        notes: finalNotes,
        paymentStatus: _accountTitle == 'tsuke_purchase' ? _paymentStatus : 'paid',
      );

      await _transactionService.createTransaction(transaction);

      if (context.mounted) {
        Navigator.pop(context);
        AdminDialog.showSnackBar(
          context: context,
          message: _needsUserSelection 
              ? '${_selectedUser!.username}さんの取引を登録しました'
              : '取引を登録しました',
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