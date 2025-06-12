// models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String safeId;
  final String accountTitle;
  final int amount;
  final DateTime transactionDate;
  final String relatedUserId;
  final String notes;
  final String paymentStatus;
  final String? orderId;

  TransactionModel({
    required this.id,
    required this.safeId,
    required this.accountTitle,
    required this.amount,
    required this.transactionDate,
    required this.relatedUserId,
    required this.notes,
    required this.paymentStatus,
    this.orderId,
  });

  /// copyWithメソッド
  TransactionModel copyWith({
    String? id,
    String? safeId,
    String? accountTitle,
    int? amount,
    DateTime? transactionDate,
    String? relatedUserId,
    String? notes,
    String? paymentStatus,
    String? orderId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      safeId: safeId ?? this.safeId,
      accountTitle: accountTitle ?? this.accountTitle,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      notes: notes ?? this.notes,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderId: orderId ?? this.orderId,
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      safeId: data['safeId'] ?? '',
      accountTitle: data['accountTitle'] ?? '',
      amount: data['amount'] ?? 0,
      transactionDate: (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      relatedUserId: data['relatedUserId'] ?? '',
      notes: data['notes'] ?? '',
      paymentStatus: data['paymentStatus'] ?? 'paid',
      orderId: data['orderId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'safeId': safeId,
      'accountTitle': accountTitle,
      'amount': amount,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'relatedUserId': relatedUserId,
      'notes': notes,
      'paymentStatus': paymentStatus,
      if (orderId != null) 'orderId': orderId,
    };
  }
}