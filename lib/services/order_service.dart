// services/order_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getOrdersStream(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots();
  }

  Future<int> calculateUnpaidTotal(String userId) async {
    try {
      final QuerySnapshot unpaidOrders = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('accountTitle', isEqualTo: 'tsuke_purchase')
          .where('paymentStatus', isEqualTo: 'unpaid')
          .get();

      int total = 0;
      for (var doc in unpaidOrders.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['totalAmount'] ?? 0) as int;
      }
      return total;
    } catch (e) {
      print('Error calculating unpaid total: $e');
      return 0;
    }
  }

  Stream<QuerySnapshot> getUnpaidOrdersStream(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('accountTitle', isEqualTo: 'tsuke_purchase')
        .where('paymentStatus', isEqualTo: 'unpaid')
        .snapshots();
  }

  Stream<QuerySnapshot> getOrderItemsStream(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('orderItems')
        .snapshots();
  }
}