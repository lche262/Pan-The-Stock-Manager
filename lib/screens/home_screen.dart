import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_bar.dart';
import '../models/product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // Group products by category
    final Map<String, List<Product>> productsByCategory = {};
    for (final product in provider.products) {
      final category = product.category.isNotEmpty
          ? product.category
          : 'No Category';
      productsByCategory.putIfAbsent(category, () => []).add(product);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('OverPrep POS'),
        actions: [
          Switch(
            value: provider.isSellMode,
            onChanged: (value) => provider.toggleMode(),
            activeTrackColor: Colors.lightGreenAccent,
            activeThumbColor: Colors.green,
          ),
          Text(provider.isSellMode ? 'Sell Mode' : 'Edit Mode'),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: productsByCategory.entries.map((entry) {
                final category = entry.key;
                final products = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          '---$category---',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width < 600
                            ? 2
                            : 5,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ProductCard(product: products[index]);
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (provider.isSellMode) const CartBar(),
        ],
      ),
      floatingActionButton: !provider.isSellMode
          ? FloatingActionButton(
              onPressed: () => _addProductDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _addProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final categoryController = TextEditingController();
    final thresholdController = TextEditingController();

    Uint8List? selectedImageBytes;
    final imagePicker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selectedImageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Image.memory(
                      selectedImageBytes!,
                      height: 90,
                      width: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await imagePicker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 600,
                      maxHeight: 600,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setState(() {
                        selectedImageBytes = bytes;
                      });
                    }
                  },
                  child: const Text('Choose Image'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: thresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Low Stock Threshold',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final product = Product(
                  id: DateTime.now().toString(),
                  name: nameController.text,
                  price: double.parse(priceController.text),
                  stock: int.parse(stockController.text),
                  category: categoryController.text,
                  lowStockThreshold: int.parse(thresholdController.text),
                  imageBytes: selectedImageBytes,
                );
                Provider.of<AppProvider>(
                  context,
                  listen: false,
                ).addProduct(product);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
