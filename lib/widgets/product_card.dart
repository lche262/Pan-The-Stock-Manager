import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/app_provider.dart';

class ProductCard extends StatelessWidget {
  static final RegExp _moneyPattern = RegExp(r'^\d+\.\d{2}$');

  final Product product;

  const ProductCard({super.key, required this.product});

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
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final quantity = provider.getCartQuantity(product.id);
    final String badgeText = quantity > 99 ? '99+' : quantity.toString();
    const double badgeHeight = 20;
    final double badgeWidth = quantity < 10
        ? 20
        : quantity < 100
        ? 26
        : 30;
    const double badgeCornerAnchorInset = 5;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Card(
          color: product.isLowStock ? Colors.red.shade100 : Colors.white,
          shape: quantity > 0
              ? RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: InkWell(
            onTap: () {
              if (provider.isSellMode) {
                provider.addToCart(product);
              } else {
                // Edit product
                _showEditDialog(context, product);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 4,
                    child: product.imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox.expand(
                              child: Image.memory(
                                product.imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                color: Colors.black38,
                                size: 48,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Stock: ${product.stock}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  if (product.isLowStock) const SizedBox(height: 4),
                  if (product.isLowStock)
                    Text(
                      'LOW STOCK',
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (quantity > 0)
          Positioned(
            top: -(badgeHeight / 2) + badgeCornerAnchorInset,
            right: -(badgeWidth / 2) + badgeCornerAnchorInset,
            child: Container(
              width: badgeWidth,
              height: badgeHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(badgeHeight / 2),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, Product product) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final stockController = TextEditingController(
      text: product.stock.toString(),
    );
    final categoryController = TextEditingController(text: product.category);
    final thresholdController = TextEditingController(
      text: product.lowStockThreshold.toString(),
    );
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

    Uint8List? imageBytes = product.imageBytes;
    final imagePicker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Image.memory(
                      imageBytes!,
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
                        imageBytes = bytes;
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
              onPressed: () {
                Provider.of<AppProvider>(
                  context,
                  listen: false,
                ).deleteProduct(product.id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
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

                final updated = Product(
                  id: product.id,
                  name: nameController.text,
                  price: double.parse(priceText),
                  stock: stock,
                  category: categoryController.text,
                  lowStockThreshold: lowStockThreshold,
                  imageBytes: imageBytes,
                );
                Provider.of<AppProvider>(
                  context,
                  listen: false,
                ).updateProduct(updated);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
