import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static final RegExp _moneyPattern = RegExp(r'^\d+\.\d{2}$');

  String _normalizeMoneyText(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return text;
    }
    final parsed = double.tryParse(text);
    if (parsed == null) {
      return text;
    }
    return parsed.toStringAsFixed(2);
  }

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
    String? priceError;
    String? stockError;
    String? thresholdError;

    String? validatePrice(String value) {
      final text = value.trim();
      if (text.isEmpty) {
        return 'Price is required.';
      }
      if (!_moneyPattern.hasMatch(text)) {
        return 'Use money format like 11.99.';
      }
      return null;
    }

    void normalizePriceInput() {
      final normalized = _normalizeMoneyText(priceController.text);
      if (normalized != priceController.text) {
        priceController.text = normalized;
        priceController.selection = TextSelection.collapsed(
          offset: normalized.length,
        );
      }
    }

    String? validateStock(String value) {
      final text = value.trim();
      if (text.isEmpty) {
        return 'Stock is required.';
      }
      final stock = int.tryParse(text);
      if (stock == null) {
        return 'Stock must be an integer.';
      }
      if (stock > 10000) {
        return 'Stock must be 10000 or less.';
      }
      return null;
    }

    String? validateThreshold(String value) {
      final text = value.trim();
      if (text.isEmpty) {
        return 'Low stock threshold is required.';
      }
      if (int.tryParse(text) == null) {
        return 'Low stock threshold must be an integer.';
      }
      return null;
    }

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
                  onTapOutside: (_) {
                    normalizePriceInput();
                    setState(() {
                      priceError = null;
                    });
                  },
                  onEditingComplete: () {
                    normalizePriceInput();
                    setState(() {
                      priceError = null;
                    });
                  },
                  onChanged: (value) {
                    final dotCount = '.'.allMatches(value).length;
                    if (dotCount > 1) {
                      // Revert to the value without the extra dot
                      final firstDot = value.indexOf('.');
                      final corrected =
                          value.substring(0, firstDot + 1) +
                          value.substring(firstDot + 1).replaceAll('.', '');
                      priceController.value = TextEditingValue(
                        text: corrected,
                        selection: TextSelection.collapsed(
                          offset: corrected.length,
                        ),
                      );
                      setState(() {
                        priceError = 'Only one decimal point is allowed.';
                      });
                    } else if (priceError != null) {
                      setState(() {
                        priceError = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixText: r'$',
                    hintText: '0.00',
                    errorText: priceError,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                ),
                TextField(
                  controller: stockController,
                  onChanged: (value) {
                    setState(() {
                      stockError = validateStock(value);
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Stock',
                    errorText: stockError,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: thresholdController,
                  onChanged: (value) {
                    setState(() {
                      thresholdError = validateThreshold(value);
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Low Stock Threshold',
                    errorText: thresholdError,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                final priceText = priceController.text.trim();
                final stockText = stockController.text.trim();
                final thresholdText = thresholdController.text.trim();
                setState(() {
                  priceError = validatePrice(priceText);
                  stockError = validateStock(stockText);
                  thresholdError = validateThreshold(thresholdText);
                });

                if (priceError != null ||
                    stockError != null ||
                    thresholdError != null) {
                  return;
                }

                final stock = int.parse(stockText);
                final lowStockThreshold = int.parse(thresholdText);

                final product = Product(
                  id: DateTime.now().toString(),
                  name: nameController.text,
                  price: double.parse(priceText),
                  stock: stock,
                  category: categoryController.text,
                  lowStockThreshold: lowStockThreshold,
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
