import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/discount_rule.dart';

class AppProvider with ChangeNotifier {
  bool _isSellMode = true;
  List<Product> _products = [];
  List<CartItem> _cart = [];
  List<DiscountRule> _discounts = [];

  bool get isSellMode => _isSellMode;
  List<Product> get products => _products;
  List<CartItem> get cart => _cart;
  List<DiscountRule> get discounts => _discounts;

  double get cartTotal {
    double total = 0;
    for (var item in _cart) {
      total += item.total;
    }
    // Apply discounts
    total = applyDiscounts(total);
    return total;
  }

  int get cartItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  int getCartQuantity(String productId) {
    final item = _cart.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(productId: '', name: '', price: 0, quantity: 0),
    );
    return item.productId.isNotEmpty ? item.quantity : 0;
  }

  void toggleMode() {
    _isSellMode = !_isSellMode;
    notifyListeners();
  }

  Future<void> loadData() async {
    var productBox = await Hive.openBox<Product>('products');
    var cartBox = await Hive.openBox<CartItem>('cart');
    var discountBox = await Hive.openBox<DiscountRule>('discounts');

    _products = productBox.values.toList();
    _cart = cartBox.values.toList();
    _discounts = discountBox.values.toList();

    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    var box = await Hive.openBox<Product>('products');
    await box.put(product.id, product);
    _products.add(product);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    var box = await Hive.openBox<Product>('products');
    await box.put(product.id, product);
    int index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    var box = await Hive.openBox<Product>('products');
    await box.delete(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void addToCart(Product product) {
    if (product.stock > 0) {
      var existing = _cart.firstWhere(
        (item) => item.productId == product.id,
        orElse: () => CartItem(productId: '', name: '', price: 0, quantity: 0),
      );
      if (existing.productId.isNotEmpty) {
        existing.quantity++;
      } else {
        _cart.add(
          CartItem(
            productId: product.id,
            name: product.name,
            price: product.price,
            quantity: 1,
          ),
        );
      }
      product.stock--;
      updateProduct(product);
      saveCart();
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    var item = _cart.firstWhere((item) => item.productId == productId);
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _cart.remove(item);
    }
    // Return stock
    var product = _products.firstWhere((p) => p.id == productId);
    product.stock++;
    updateProduct(product);
    saveCart();
    notifyListeners();
  }

  void updateCartQuantity(String productId, int quantity) {
    var item = _cart.firstWhere((item) => item.productId == productId);
    quantity = max(0, quantity);
    var product = _products.firstWhere((p) => p.id == productId);
    if (quantity > item.quantity) {
      final available = product.stock;
      final requestedIncrease = quantity - item.quantity;
      final allowedIncrease = min(requestedIncrease, available);
      quantity = item.quantity + allowedIncrease;
    }

    final diff = quantity - item.quantity;
    if (quantity == 0) {
      _cart.remove(item);
    } else {
      item.quantity = quantity;
    }

    product.stock -= diff;
    updateProduct(product);
    saveCart();
    notifyListeners();
  }

  void clearCart() {
    for (var item in _cart) {
      var product = _products.firstWhere((p) => p.id == item.productId);
      product.stock += item.quantity;
      updateProduct(product);
    }
    _cart.clear();
    saveCart();
    notifyListeners();
  }

  Future<void> completeSale() async {
    _cart.clear();
    await saveCart();
    notifyListeners();
  }

  Future<void> saveCart() async {
    var box = await Hive.openBox<CartItem>('cart');
    await box.clear();
    for (var item in _cart) {
      await box.put(item.productId, item);
    }
  }

  double applyDiscounts(double total) {
    if (total <= 0 || _discounts.isEmpty) {
      return total;
    }

    final totalItems = cartItemCount;
    if (totalItems == 0) return total;

    final averageUnit = total / totalItems;
    double bestTotal = total;

    for (var rule in _discounts) {
      if (totalItems < rule.minQuantity) {
        continue;
      }

      if (rule.type == 'bundle') {
        final bundles = totalItems ~/ rule.minQuantity;
        if (bundles > 0) {
          final remainder = totalItems - bundles * rule.minQuantity;
          final candidateTotal =
              bundles * rule.discountValue + remainder * averageUnit;
          bestTotal = min(bestTotal, candidateTotal);
        }
      } else if (rule.type == 'percentage') {
        final candidateTotal = total * (1 - rule.discountValue / 100);
        bestTotal = min(bestTotal, candidateTotal);
      }
    }

    return bestTotal;
  }

  Future<void> addDiscount(DiscountRule discount) async {
    var box = await Hive.openBox<DiscountRule>('discounts');
    await box.put(discount.id, discount);
    _discounts.add(discount);
    notifyListeners();
  }
}
