// pages/home.dart
import 'package:chinoshop/services/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import 'cart_page.dart';
import '../admin/admin_main_page.dart';
import '../../widgets/item_detail_dialog.dart';
import '../../widgets/top_banner_widget.dart';
import '../../images/no_img_base64.dart';
import '../../widgets/common_app_bar.dart';
import '../../constants/app_constants.dart';
import '../../widgets/cart_badge.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedCategory;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  final CartService _cartService = CartService();
  bool isAdmin = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _checkAdminStatus();
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists && mounted) {
        setState(() {
          isAdmin = userDoc.data()?['role'] == 'admin';
        });
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }
  }

  Future<List<String>> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();
      
      final categories = snapshot.docs
          .map((doc) => doc.data()['name']?.toString() ?? doc.id)
          .toList();
      
      return ['すべて', ...categories];
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return ['すべて'];
    }
  }

  Stream<QuerySnapshot> _getItemsStream() {
    final query = FirebaseFirestore.instance
        .collection('items')
        .where('isVisible', isEqualTo: true);
    
    if (selectedCategory != null) {
      return query.where('category', isEqualTo: selectedCategory).snapshots();
    }
    
    return query.snapshots();
  }

  List<QueryDocumentSnapshot> _filterItems(List<QueryDocumentSnapshot> docs) {
    if (searchQuery.isEmpty) return docs;
    
    return docs.where((doc) {
      final itemData = doc.data() as Map<String, dynamic>;
      final name = (itemData['name'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppConstants.primaryColor),
        ),
      );
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: 'メニュー一覧',
        automaticallyImplyLeading: false,
        actions: [
          if (isAdmin) _buildAdminButton(),
          _buildCartButton(),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          Expanded(child: _buildItemsList()),
        ],
      ),
    );
  }

  Widget _buildAdminButton() {
    return IconButton(
      icon: const Icon(Icons.admin_panel_settings, size: 32),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminPage()),
        );
      },
      tooltip: '管理者ページ',
    );
  }

  StreamBuilder<int> _buildCartButton() {
    return StreamBuilder<int>(
      stream: _cartService.getCartItemCount(),
      builder: (context, snapshot) {
        final itemCount = snapshot.data ?? 0;
        
        return IconButton(
          icon: CartBadge(
            count: itemCount,
            child: const Icon(Icons.shopping_cart),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CartPage(userId: widget.userId,)),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildCategoryFilter(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        labelText: '商品を検索',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (value) {
        setState(() => searchQuery = value);
      },
    );
  }

  Widget _buildCategoryFilter() {
    return FutureBuilder<List<String>>(
      future: _fetchCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final category = snapshot.data![index];
              final isSelected = selectedCategory == category || 
                  (selectedCategory == null && category == 'すべて');
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = category == 'すべて' ? null : category;
                    });
                  },
                  backgroundColor: Colors.grey[100],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildItemsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getItemsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'エラーが発生しました',
                  style: AppConstants.titleStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: AppConstants.subtitleStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppConstants.primaryColor),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text('データを取得できませんでした'),
          );
        }

        final filteredDocs = _filterItems(snapshot.data!.docs);

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredDocs.length + 2, // +2 for notice and banner
          itemBuilder: (context, index) {
            if (index == 0) return _buildNoticeSection();
            if (index == 1) return const TopBannerCarousel();
            
            final docIndex = index - 2;
            if (docIndex >= filteredDocs.length) {
              return filteredDocs.isEmpty ? _buildEmptyMessage() : const SizedBox.shrink();
            }
            
            return _buildItemCard(filteredDocs[docIndex]);
          },
        );
      },
    );
  }

  Widget _buildNoticeSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        ' お知らせ',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text('メニューがありません'),
      ),
    );
  }

  Widget _buildItemCard(QueryDocumentSnapshot doc) {
    final itemData = doc.data() as Map<String, dynamic>;
    final itemId = doc.id;
    final name = itemData['name'] ?? '名前なし';
    final price = (itemData['price'] ?? 999999).toInt();
    final stock = (itemData['stock'] ?? 999999).toInt();
    final imgBase64 = itemData['imgBase64'] ?? noImgBase64;
    final isOutOfStock = stock <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Opacity(
        opacity: isOutOfStock ? 0.4 : 1.0,
        child: GestureDetector(
          onTap: isOutOfStock ? null : () => _showItemDetail(itemId, imgBase64),
          child: Card(
            elevation: 4,
            color: isOutOfStock ? Colors.grey[300] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                _buildItemImage(imgBase64),
                Expanded(child: _buildItemInfo(name, price, stock)),
                _buildCartBadge(itemId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemImage(String imgBase64) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Image.memory(
        base64Decode(imgBase64),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 100,
          height: 100,
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        ),
      ),
    );
  }

  Widget _buildItemInfo(String name, int price, int stock) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('価格: ¥$price'),
          Text(
            stock > 0 ? '在庫: $stock' : '在庫切れ',
            style: TextStyle(
              color: stock > 0 ? Colors.black : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartBadge(String itemId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('cartItems')
          .doc(itemId)
          .snapshots(),
      builder: (context, cartSnapshot) {
        if (!cartSnapshot.hasData || !cartSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final cartData = cartSnapshot.data!.data() as Map<String, dynamic>;
        final quantity = cartData['quantity'] ?? 0;

        if (quantity == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          constraints: const BoxConstraints(
            minWidth: 24,
            minHeight: 24,
          ),
          child: Text(
            '$quantity',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  void _showItemDetail(String itemId, String imgBase64) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ItemDetailDialog(
          userId: widget.userId,
          itemId: itemId,
          imgBase64: imgBase64,
        );
      },
    );
  }
}