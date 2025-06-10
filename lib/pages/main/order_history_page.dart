// pages/order_history_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/common_app_bar.dart';
import '../../widgets/unpaid_total_button.dart';
import '../../widgets/order_card.dart';
import '../../widgets/empty_orders_widget.dart';
import '../../widgets/custom_error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../services/order_service.dart';
import '../../constants/app_constants.dart';

class OrderHistoryPage extends StatefulWidget {
  final String userId;
  
  const OrderHistoryPage({super.key, required this.userId});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  CommonAppBar _buildAppBar() {
    return CommonAppBar(
      title: '注文履歴',
      actions: [
        UnpaidTotalButton(userId: widget.userId),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: _orderService.getOrdersStream(widget.userId),
      builder: (context, snapshot) {
        // エラーハンドリング
        if (snapshot.hasError) {
          return CustomErrorWidget(error: snapshot.error);
        }

        // ローディング状態
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(
            message: '注文履歴を読み込んでいます...',
            color: AppConstants.primaryColor,
          );
        }

        // データなし
        if (!snapshot.hasData || snapshot.data == null) {
          return const EmptyOrdersWidget(
            message: 'データを取得できませんでした',
          );
        }

        final orders = snapshot.data!.docs;
        
        // 注文履歴が空の場合
        if (orders.isEmpty) {
          return const EmptyOrdersWidget(
            message: '注文履歴がありません',
          );
        }

        // 注文履歴のリスト表示
        return RefreshIndicator(
          onRefresh: () async {
            // 手動リフレッシュ時の処理（StreamBuilderなので自動更新されるが、ユーザビリティのため）
            setState(() {});
          },
          color: AppConstants.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return OrderCard(orderDoc: orders[index]);
            },
          ),
        );
      },
    );
  }
}