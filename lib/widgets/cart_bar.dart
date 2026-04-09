import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'cart_expanded.dart';

class CartBar extends StatelessWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Items: ${provider.cartItemCount}',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          Text(
            'Total: \$${provider.cartTotal.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          ElevatedButton(
            onPressed: () => _showCartDialog(context),
            child: const Text('View Cart'),
          ),
        ],
      ),
    );
  }

  void _showCartDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => CartExpanded(),
    );
  }
}
