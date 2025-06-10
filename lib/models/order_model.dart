// models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final DateTime? orderDate;
  final int totalAmount;
  final String accountTitle;
  final String paymentStatus;
  final String notes;

  OrderModel({
    required this.id,
    required this.userId,
    this.orderDate,
    required this.totalAmount,
    required this.accountTitle,
    required this.paymentStatus,
    required this.notes,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      orderDate: (data['orderDate'] as Timestamp?)?.toDate(),
      totalAmount: data['totalAmount'] ?? 0,
      accountTitle: data['accountTitle'] ?? '',
      paymentStatus: data['paymentStatus'] ?? '',
      notes: data['notes'] ?? '',
    );
  }

  bool get isTsuke => accountTitle == 'tsuke_purchase';
  bool get isPaid => paymentStatus == 'paid';
  bool get isUnpaid => !isPaid;
}