import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemDetailDialog extends StatefulWidget {
  final String userId;
  final String itemId;
  final String imgBase64;

  const ItemDetailDialog({
    super.key,
    required this.userId,
    required this.itemId,
    required this.imgBase64,
  });

  @override
  State<ItemDetailDialog> createState() => _ItemDetailDialogState();
}

class _ItemDetailDialogState extends State<ItemDetailDialog> {
  late ValueNotifier<int> quantityNotifier;
  bool isInCart = false;
  bool _isLoading = true;

  String name = '';
  int price = 0;
  int stock = 0;
  String description = '';

  // bool _isPortrait = true;
  // bool _xxxxx = MediaQuery.of(context).size.height >= MediaQuery.of(context).size.width ? true : width,

  @override
  void initState() {
    super.initState();
    quantityNotifier = ValueNotifier<int>(1);
    _initializeData();
    // _checkPortrait();
  }

  // Future _checkPortrait() async {
  //   if(MediaQuery.of(context).size.height < MediaQuery.of(context).size.width) {
  //     setState(() {
  //       _isPortrait = false;
  //     });
  //   }
  // }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadItemData(),
      _loadCartStatus(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadItemData() async {
    final itemDoc = await FirebaseFirestore.instance
        .collection('items')
        .doc(widget.itemId)
        .get();

    if (itemDoc.exists) {
      final data = itemDoc.data()!;
      name = data['name'] ?? '記載なし';
      price = data['price'] ?? 999999;
      stock = data['stock'] ?? 999999;
      description = data['description'] ?? '特になし';
    }
  }

  Future<void> _loadCartStatus() async {
    final cartDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('cartItems')
        .doc(widget.itemId)
        .get();

    if (cartDoc.exists) {
      final data = cartDoc.data()!;
      quantityNotifier.value = data['quantity'] ?? 1;
      isInCart = true;
    }
  }

  Future<void> _updateCartQuantity() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('cartItems')
        .doc(widget.itemId)
        .set({
      'name': name,
      'price': price,
      'quantity': quantityNotifier.value,
    });
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;
    double screenHeight = MediaQuery.of(context).size.height; // 画面の高さを取得
    double screenWidth = MediaQuery.of(context).size.width; // 画面の幅を取得

    return orientation == Orientation.portrait
        ? _buildPortraitLayout(screenHeight, screenWidth)
        : _buildLandscapeLayout(screenHeight, screenWidth);
  }

  Widget _buildPortraitLayout(double screenHeight, double screenWidth) {
  return AlertDialog(
    contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    content: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.6,
        maxHeight: screenHeight * 0.6,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal:4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(widget.imgBase64),
                      width: screenWidth * 0.8,
                      height: screenHeight * 0.25,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.25,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text('価格: ¥$price', style: const TextStyle(fontSize: 16)),
                        Text('在庫: $stock', style: const TextStyle(fontSize: 16)),
                        Text('説明: $description', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (quantityNotifier.value > 1) {
                          quantityNotifier.value--;
                        }
                      },
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: quantityNotifier,
                      builder: (context, value, _) {
                        return Text('$value', style: const TextStyle(fontSize: 16));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (quantityNotifier.value < stock) {
                          quantityNotifier.value++;
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
    ),
    actions: _isLoading
        ? [const SizedBox(height: 48)]
        : [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateCartQuantity();
              },
              child: Text(isInCart ? '変更' : 'カートに追加'),
            ),
          ],
  );
}


  Widget _buildLandscapeLayout(double screenHeight, double screenWidth) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.7,
          maxHeight: screenHeight * 0.6,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: double.infinity,
                    margin: EdgeInsets.symmetric(vertical:4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(widget.imgBase64),
                        width: screenWidth * 0.3,
                        height: screenHeight * 0.4,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          width: screenWidth * 0.3,
                          height: screenHeight * 0.4,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 26)),
                                  const SizedBox(height: 4),
                                  Text('価格: ¥$price', style: const TextStyle(fontSize: 16)),
                                  Text('在庫: $stock', style: const TextStyle(fontSize: 16)),
                                  Text('説明: $description', style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (quantityNotifier.value > 1) {
                                  quantityNotifier.value--;
                                }
                              },
                            ),
                            ValueListenableBuilder<int>(
                              valueListenable: quantityNotifier,
                              builder: (context, value, _) {
                                return Text('$value', style: const TextStyle(fontSize: 16));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (quantityNotifier.value < stock) {
                                  quantityNotifier.value++;
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      actions: _isLoading
          ? [const SizedBox(height: 48)]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _updateCartQuantity();
                },
                child: Text(isInCart ? '変更' : 'カートに追加'),
              ),
            ],
    );
  }
}












// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:convert';


// class ItemDetailDialog extends StatefulWidget {
//   final String userId;

//   final String itemId;
//   final String name;
//   final int price;
//   final String imgBase64;
  
//   // コメントアウト
//   // final String id;
//   // final int stock;
//   // final String description;
//   // final Map<String, int> cart;
//   // final Function(String, int) onUpdateCart;

//   const ItemDetailDialog({
//     super.key,
//     required this.userId,
    
//     required this.itemId,
//     required this.name,
//     required this.price,
//     required this.imgBase64,


//     // コメントアウト
//     // required this.id,
//     // required this.stock,
//     // required this.description,
//     // required this.cart,
//     // required this.onUpdateCart,
//   });

//   @override
//   State<ItemDetailDialog> createState() => _ItemDetailDialogState();
// }

// class _ItemDetailDialogState extends State<ItemDetailDialog> {
//   int quantity = 1;
//   final doc = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('cartItems').doc(widget.itemId).get().then((DocumentSnapshot doc) {
//     if (doc.exists) {
//       return doc.data() as Map<String, dynamic>;
//     } else {
//       return null;
//     }
//   });

//   Future<>

//   @override
//   void initState() {
//     super.initState();
//     _loadCartData();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       contentPadding: const EdgeInsets.all(16),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.memory(
//                 base64Decode(widget.imgBase64),
//                 height: 150,
//                 width: double.maxFinite,
//                 fit: BoxFit.contain,
//               ),
//             ),
//             const SizedBox(height: 16),




//             // コメントアウト
//             // Align(
//             //   alignment: Alignment.centerLeft,
//             //   child: Text(widget.name, style: const TextStyle(fontSize: 18)),
//             // ),
//             // Align(
//             //   alignment: Alignment.centerLeft,
//             //   child: Text('価格: \u00a5${widget.price}'),
//             // ),
//             // Align(
//             //   alignment: Alignment.centerLeft,
//             //   child: Text('在庫: ${widget.stock}'),
//             // ),
//             // Align(
//             //   alignment: Alignment.centerLeft,
//             //   child: Text('説明: ${widget.description}'),
//             // ),





//             Align(
//               alignment: Alignment.centerLeft,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(widget.name, style: const TextStyle(fontSize: 18)),
//                   Text('価格: \u00a5${widget.price}'),
//                   Text('在庫: ${widget.stock}'),
//                   Text('説明: ${widget.description}'),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.remove),
//                   onPressed: quantity > 1
//                       ? () => setState(() => quantity--)
//                       : null,
//                 ),
//                 Text('$quantity'),
//                 IconButton(
//                   icon: const Icon(Icons.add),
//                   onPressed: quantity < widget.stock
//                       ? () => setState(() => quantity++)
//                       : null,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('閉じる'),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             widget.onUpdateCart(widget.id, quantity);
//           },
//           child: const Text('カートに追加'),
//         ),
//       ],
//     );
//   }
// }
