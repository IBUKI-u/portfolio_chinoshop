// pages/admin/admin_money_management_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/admin_constants.dart';
import '../../models/transaction_model.dart';
import '../../services/admin_transaction_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/transaction_card.dart';
import '../../widgets/manual_transaction_dialog.dart';
import '../../widgets/balance_card.dart';

class MoneyManagementPage extends StatefulWidget {
  const MoneyManagementPage({super.key});

  @override
  State<MoneyManagementPage> createState() => _MoneyManagementPageState();
}

class _MoneyManagementPageState extends State<MoneyManagementPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentUserId();
  }

  void _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: LoadingWidget(message: 'ユーザー情報を確認中...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          '取引＆資金管理',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: AdminConstants.safeTypeMap.entries.map((entry) => 
            Tab(text: entry.value)
          ).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: AdminConstants.safeTypeMap.keys.map((safeId) =>
          MoneyTab(safeId: safeId, currentUserId: _currentUserId!)
        ).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final safeIds = AdminConstants.safeTypeMap.keys.toList();
          final currentSafeId = safeIds[_tabController.index];
          
          showDialog(
            context: context,
            builder: (context) => ManualTransactionDialog(
              safeId: currentSafeId,
              currentUserId: _currentUserId!,
              onSaved: () => setState(() {}),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MoneyTab extends StatefulWidget {
  final String safeId;
  final String currentUserId;
  
  const MoneyTab({
    super.key, 
    required this.safeId, 
    required this.currentUserId,
  });

  @override
  State<MoneyTab> createState() => _MoneyTabState();
}

class _MoneyTabState extends State<MoneyTab> {
  final AdminTransactionService _transactionService = AdminTransactionService();
  String selectedFilter = 'all';
  bool showUnpaidOnly = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 残高表示
        BalanceCard(safeId: widget.safeId),
        
        // フィルター
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedFilter,
                  decoration: const InputDecoration(
                    labelText: 'カテゴリフィルター',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: AdminConstants.accountTitleMap.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedFilter = value!),
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('未払いのみ'),
                selected: showUnpaidOnly,
                onSelected: (selected) => setState(() => showUnpaidOnly = selected),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 取引履歴
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _transactionService.getTransactionsStream(
              safeId: widget.safeId,
              accountTitle: selectedFilter,
              showUnpaidOnly: showUnpaidOnly,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: '取引履歴を読み込んでいます...');
              }
              
              if (snapshot.hasError) {
                print('エラー: ${snapshot.error}');
                return Center(child: Text('エラー: ${snapshot.error}'));
              }
              
              final transactions = snapshot.data?.docs ?? [];
              
              if (transactions.isEmpty) {
                return const Center(child: Text('取引履歴がありません'));
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final doc = transactions[index];
                  final transaction = TransactionModel.fromFirestore(doc);
                  
                  return TransactionCard(
                    transaction: transaction,
                    currentUserId: widget.currentUserId,
                    onUpdate: () => setState(() {}),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}