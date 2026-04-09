// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    Uint8List? imageBytes;
    final imageField = fields[6];
    if (imageField == null) {
      imageBytes = null;
    } else if (imageField is Uint8List) {
      imageBytes = imageField;
    } else if (imageField is String) {
      try {
        imageBytes = base64Decode(imageField);
      } catch (_) {
        imageBytes = null;
      }
    } else {
      imageBytes = null;
    }

    return Product(
      id: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as double,
      stock: fields[3] as int,
      category: fields[4] as String,
      lowStockThreshold: fields[5] as int,
      imageBytes: imageBytes,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.stock)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.lowStockThreshold)
      ..writeByte(6)
      ..write(obj.imageBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
