// services/cart_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // カート内の商品数を取得するストリーム
  Stream<int> getCartItemCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cartItems')
        .snapshots()
        .map((snapshot) {
          int totalCount = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            totalCount += (data['quantity'] as int? ?? 0);
          }
          return totalCount;
        });
  }
  
  // カート内の商品リストを取得
  Stream<QuerySnapshot> getCartItems() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cartItems')
        .snapshots();
  }
}