import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class CartExpanded extends StatelessWidget {
  const CartExpanded({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Cart', style: TextStyle(fontSize: 24)),
          Expanded(
            child: ListView.builder(
              itemCount: provider.cart.length,
              itemBuilder: (context, index) {
                final item = provider.cart[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    '\$${item.price.toStringAsFixed(2)} x ${item.quantity} = \$${item.total.toStringAsFixed(2)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => provider.updateCartQuantity(
                          item.productId,
                          item.quantity - 1,
                        ),
                      ),
                      Text(item.quantity.toString()),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => provider.updateCartQuantity(
                          item.productId,
                          item.quantity + 1,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Text(
            'Total: \$${provider.cartTotal.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 20),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => provider.clearCart(),
                child: const Text('Clear Cart'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  await provider.completeSale();
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Sale completed!')),
                  );
                },
                child: const Text('Complete Sale'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
