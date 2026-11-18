import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/product_providers.dart';
import 'product_details_page.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shopify Products')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unable to load products.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  ref.invalidate(productsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(productsProvider.future),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final product = products[index];

                return ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProductDetailsPage(product: product),
                      ),
                    );
                  },
                  trailing: const Icon(Icons.chevron_right),
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 56,
                    height: 56,
                    child: product.imageUrl == null
                        ? const Icon(Icons.image_not_supported_outlined)
                        : Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                  title: Text(product.title),
                  subtitle: Text(
                    'From ${product.priceAmount} ${product.currencyCode}'
                    '${product.availableForSale ? '' : '\nOut of stock'}',
                  ),
                  isThreeLine: !product.availableForSale,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
