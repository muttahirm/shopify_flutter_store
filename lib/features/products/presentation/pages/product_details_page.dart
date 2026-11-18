import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product.dart';
import '../../domain/entities/product_variant.dart';
import '../providers/product_providers.dart';

class ProductDetailsPage extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends ConsumerState<ProductDetailsPage> {
  String? _selectedVariantId;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final textTheme = Theme.of(context).textTheme;
    final variantsAsync = ref.watch(productVariantsProvider(product.id));

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
            const SizedBox(height: 16),
            variantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Unable to load product options.'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      ref.invalidate(productVariantsProvider(product.id));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (variants) {
                if (variants.isEmpty) {
                  return const Text('No product options available.');
                }

                final selectedVariant = _findSelectedVariant(variants);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedVariant == null
                          ? 'From ${product.priceAmount} '
                                '${product.currencyCode}'
                          : '${selectedVariant.priceAmount} '
                                '${selectedVariant.currencyCode}',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVariantId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select an option',
                        border: OutlineInputBorder(),
                      ),
                      items: variants.map((variant) {
                        return DropdownMenuItem<String>(
                          value: variant.id,
                          enabled: variant.availableForSale,
                          child: Text(
                            '${variant.title}'
                            '${variant.availableForSale ? '' : ' — Out of stock'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (variantId) {
                        setState(() {
                          _selectedVariantId = variantId;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedVariant != null
                          ? 'Available'
                          : variants.any((v) => v.availableForSale)
                          ? 'Choose an option to continue.'
                          : 'Out of stock',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            if (product.description.isNotEmpty)
              Text(product.description, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  ProductVariant? _findSelectedVariant(List<ProductVariant> variants) {
    for (final variant in variants) {
      if (variant.id == _selectedVariantId) {
        return variant;
      }
    }

    return null;
  }
}
