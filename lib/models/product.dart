import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  int stock;

  @HiveField(4)
  String category;

  @HiveField(5)
  int lowStockThreshold;

  @HiveField(6)
  Uint8List? imageBytes;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    required this.lowStockThreshold,
    this.imageBytes,
  });

  bool get isLowStock => stock <= lowStockThreshold;
}
