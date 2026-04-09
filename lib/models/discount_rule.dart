import 'package:hive/hive.dart';

part 'discount_rule.g.dart';

@HiveType(typeId: 2)
class DiscountRule extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type; // 'bundle' or 'percentage'

  @HiveField(3)
  int minQuantity; // for bundle or percentage

  @HiveField(4)
  double discountValue; // price for bundle, percentage for percentage

  DiscountRule({
    required this.id,
    required this.name,
    required this.type,
    required this.minQuantity,
    required this.discountValue,
  });
}
