// models/order_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String id;
  final String itemName;
  final int quantity;
  final int subtotal;
  final int unitPrice;

  OrderItemModel({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.subtotal,
    required this.unitPrice,
  });

  factory OrderItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderItemModel(
      id: doc.id,
      itemName: data['itemName'] ?? '商品名不明',
      quantity: data['quantity'] ?? 0,
      subtotal: data['subtotal'] ?? 0,
      unitPrice: data['unitPrice'] ?? 0,
    );
  }
}