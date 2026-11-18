import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';

class ProductDetailsPage extends StatelessWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: product.imageUrl == null
                  ? const Center(
                      child: Icon(Icons.image_not_supported_outlined, size: 64),
                    )
                  : Image.network(
                      product.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image_outlined, size: 64),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            Text(product.title, style: textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'From ${product.priceAmount} ${product.currencyCode}',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(product.availableForSale ? 'Available' : 'Out of stock'),
            const SizedBox(height: 24),
            if (product.description.isNotEmpty)
              Text(product.description, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
