import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product.dart';
import '../../domain/entities/product_variant.dart';
import '../providers/product_providers.dart';
import '../providers/cart_controller.dart';
import 'cart_page.dart';

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
    final cartState = ref.watch(cartControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final variantsAsync = ref.watch(productVariantsProvider(product.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopify Products'),
        actions: [
          IconButton(
            tooltip: 'Open cart',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const CartPage()));
            },
          ),
        ],
      ),
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
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            selectedVariant == null ||
                                !selectedVariant.availableForSale ||
                                cartState.isLoading ||
                                cartState.requiresRefresh
                            ? null
                            : () async {
                                final success = await ref
                                    .read(cartControllerProvider.notifier)
                                    .addItem(variantId: selectedVariant.id);

                                if (!context.mounted) return;

                                final latestState = ref.read(
                                  cartControllerProvider,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Cart updated.'
                                          : latestState.errorMessage ??
                                                'Unable to add the item.',
                                    ),
                                  ),
                                );
                              },
                        icon: cartState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_shopping_cart),
                        label: Text(
                          cartState.isLoading
                              ? 'Updating cart…'
                              : 'Add to cart',
                        ),
                      ),
                    ),
                    if (cartState.requiresRefresh) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'The last change could not be confirmed. '
                        'Refresh the cart and check its contents before adding again.',
                      ),
                      TextButton(
                        onPressed: cartState.isLoading
                            ? null
                            : () async {
                                final success = await ref
                                    .read(cartControllerProvider.notifier)
                                    .refreshCart();

                                if (!context.mounted) return;

                                final latestState = ref.read(
                                  cartControllerProvider,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Cart refreshed.'
                                          : latestState.errorMessage ??
                                                'Unable to refresh the cart.',
                                    ),
                                  ),
                                );
                              },
                        child: const Text('Refresh cart'),
                      ),
                    ],
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
