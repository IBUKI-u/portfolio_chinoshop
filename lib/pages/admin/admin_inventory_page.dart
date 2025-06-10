import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_inventory_service.dart';
import '../../widgets/admin_dialog.dart';
import '../../widgets/admin_filter_chip_list.dart';
import '../../widgets/admin_empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../constants/admin_constants.dart';
import '../../utils/admin_formatter.dart';

class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
  final AdminInventoryService _inventoryService = AdminInventoryService();
  final searchController = TextEditingController();
  String selectedCategory = 'すべて';
  String searchQuery = '';
  bool showHiddenItems = true;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _adjustStock(String itemId, int currentStock, String itemName) async {
    final result = await AdminDialog.showInputDialog(
      context: context,
      title: '在庫数を調整',
      labelText: '新しい在庫数',
      initialValue: currentStock.toString(),
      hintText: '数量を入力してください',
      keyboardType: TextInputType.number,
      titleIcon: Icons.inventory_2,
    );

    if (result != null) {
      final newStock = int.tryParse(result);
      if (newStock != null && newStock >= 0) {
        try {
          await _inventoryService.adjustStock(itemId, newStock);
          if (mounted) {
            AdminDialog.showSnackBar(
              context: context,
              message: '$itemNameの在庫を${newStock}個に更新しました',
            );
          }
        } catch (e) {
          if (mounted) {
            AdminDialog.showSnackBar(
              context: context,
              message: 'エラー: $e',
              isError: true,
            );
          }
        }
      } else {
        if (mounted) {
          AdminDialog.showSnackBar(
            context: context,
            message: '有効な数値を入力してください',
            isError: true,
          );
        }
      }
    }
  }

  void _editItem(String itemId) async {
    final itemDoc = await _inventoryService.itemsRef.doc(itemId).get();
    if (!itemDoc.exists) return;

    final itemData = itemDoc.data()!;
    final nameController = TextEditingController(text: itemData['name']);
    final remarkController = TextEditingController(text: itemData['remark']);
    final priceController = TextEditingController(text: itemData['price'].toString());
    final descriptionController = TextEditingController(text: itemData['description']);
    String selectedCategoryLocal = itemData['category'] ?? '';

    final categories = await _inventoryService.fetchCategories();
    categories.removeWhere((cat) => cat == 'すべて');

    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('商品情報の編集'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '商品名 *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.shopping_bag),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '価格 (円)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.monetization_on),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '説明',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarkController,
                decoration: InputDecoration(
                  labelText: '備考',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategoryLocal.isEmpty ? null : selectedCategoryLocal,
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => selectedCategoryLocal = val ?? '',
                decoration: InputDecoration(
                  labelText: 'カテゴリ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (shouldUpdate == true) {
      await _inventoryService.itemsRef.doc(itemId).update({
        'name': nameController.text.trim(),
        'price': int.tryParse(priceController.text.trim()) ?? 0,
        'description': descriptionController.text.trim(),
        'remark': remarkController.text.trim(),
        'category': selectedCategoryLocal,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品情報を更新しました')),
        );
      }
    }
  }

  void _addItem() async {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final remarkController = TextEditingController();
    String selectedCategoryLocal = '';

    final categories = await _inventoryService.fetchCategories();
    categories.removeWhere((cat) => cat == 'すべて');

    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('新規商品を追加'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '商品名 *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.shopping_bag),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '在庫数 *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.inventory),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '価格 (円)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.monetization_on),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '説明',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarkController,
                decoration: InputDecoration(
                  labelText: '備考',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategoryLocal.isEmpty ? null : selectedCategoryLocal,
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => selectedCategoryLocal = val ?? '',
                decoration: InputDecoration(
                  labelText: 'カテゴリ *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (shouldAdd == true) {
      final name = nameController.text.trim();
      final stock = int.tryParse(stockController.text.trim()) ?? 0;
      final price = int.tryParse(priceController.text.trim()) ?? 0;
      final description = descriptionController.text.trim();
      final remark = remarkController.text.trim();

      if (name.isNotEmpty && selectedCategoryLocal.isNotEmpty) {
        await _inventoryService.itemsRef.add({
          'name': name,
          'stock': stock,
          'price': price,
          'description': description,
          'remark': remark,
          'category': selectedCategoryLocal,
          'imgBase64': '',
          'isVisible': true,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$nameを追加しました')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('商品名とカテゴリは必須です')),
          );
        }
      }
    }
  }

  void _toggleVisibility(String itemId, String itemName, bool currentVisibility) async {
    try {
      await _inventoryService.toggleItemVisibility(itemId, currentVisibility);
      if (mounted) {
        AdminDialog.showSnackBar(
          context: context,
          message: currentVisibility 
            ? '$itemNameを非表示に変更しました' 
            : '$itemNameを表示に変更しました',
        );
      }
    } catch (e) {
      if (mounted) {
        AdminDialog.showSnackBar(
          context: context,
          message: 'エラー: $e',
          isError: true,
        );
      }
    }
  }

  void _deleteItem(String itemId, String itemName) async {
    final shouldDelete = await AdminDialog.showConfirmDialog(
      context: context,
      title: '商品を削除',
      content: '「$itemName」を削除してもよろしいですか？\nこの操作は取り消せません。',
      icon: Icons.warning,
    );

    if (shouldDelete == true) {
      try {
        await _inventoryService.deleteItem(itemId);
        if (mounted) {
          AdminDialog.showSnackBar(
            context: context,
            message: '$itemNameを削除しました',
          );
        }
      } catch (e) {
        if (mounted) {
          AdminDialog.showSnackBar(
            context: context,
            message: 'エラー: $e',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          '商品管理',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(showHiddenItems ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                showHiddenItems = !showHiddenItems;
              });
            },
            tooltip: showHiddenItems ? '非表示商品を表示' : '表示商品のみを表示',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addItem,
            tooltip: '新規商品追加',
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索・フィルターセクション
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                // 検索バー
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: '商品を検索',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // カテゴリフィルター
                FutureBuilder<List<String>>(
                  future: _inventoryService.fetchCategories(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    
                    return AdminFilterChipList(
                      items: snapshot.data!,
                      selectedItem: selectedCategory,
                      onSelected: (category) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          // 商品リスト
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _inventoryService.getItemsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LoadingWidget(message: '商品を読み込んでいます...');
                }

                final allItems = snapshot.data!.docs;
                final filteredItems = allItems.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final category = data['category'] ?? '';
                  final isVisible = data['isVisible'] ?? true;
                  
                  final matchesSearch = searchQuery.isEmpty || name.contains(searchQuery);
                  final matchesCategory = selectedCategory == 'すべて' || category == selectedCategory;
                  final matchesVisibility = showHiddenItems == isVisible;
                  
                  return matchesSearch && matchesCategory && matchesVisibility;
                }).toList();

                if (filteredItems.isEmpty) {
                  return AdminEmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: searchQuery.isNotEmpty || selectedCategory != 'すべて'
                        ? '該当する商品がありません'
                        : '商品がありません',
                    actionLabel: searchQuery.isEmpty && selectedCategory == 'すべて' 
                        ? '最初の商品を追加' 
                        : null,
                    onAction: searchQuery.isEmpty && selectedCategory == 'すべて' 
                        ? _addItem 
                        : null,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final doc = filteredItems[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildItemCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? '未設定';
    final stock = data['stock'] ?? 0;
    final price = data['price'] ?? 0;
    final remark = data['remark'] ?? '';
    final category = data['category'] ?? '';
    final isVisible = data['isVisible'] ?? true;
    final isLowStock = stock < 2;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: !isVisible 
            ? AdminConstants.hiddenItemBackgroundColor
            : isLowStock 
              ? AdminConstants.lowStockBackgroundColor
              : Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            !isVisible 
              ? Icons.visibility_off 
              : isLowStock 
                ? Icons.warning 
                : Icons.inventory_2,
            color: !isVisible 
              ? AdminConstants.hiddenItemIconColor
              : isLowStock 
                ? AdminConstants.lowStockColor 
                : Theme.of(context).primaryColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: !isVisible ? Colors.grey[600] : null,
                      decoration: !isVisible ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLowStock ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLowStock ? Colors.red[200]! : Colors.green[200]!,
                      ),
                    ),
                    child: Text(
                      '在庫: $stock個',
                      style: TextStyle(
                        color: isLowStock ? Colors.red[700] : Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isVisible)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '非表示',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(id, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 4),
            if (price > 0)
              Text(AdminFormatter.formatCurrency(price), 
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            if (category.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('カテゴリ: $category', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
            if (remark.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(remark, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'adjust':
                _adjustStock(id, stock, name);
                break;
              case 'edit':
                _editItem(id);
                break;
              case 'toggle_visibility':
                _toggleVisibility(id, name, isVisible);
                break;
              case 'delete':
                _deleteItem(id, name);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'adjust',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 8),
                  Text('在庫調整'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('編集'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_visibility',
              child: Row(
                children: [
                  Icon(isVisible ? Icons.visibility_off : Icons.visibility),
                  const SizedBox(width: 8),
                  Text(isVisible ? '非表示にする' : '表示する'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('削除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _adjustStock(id, stock, name),
      ),
    );
  }
}