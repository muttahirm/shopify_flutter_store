import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/cart_controller.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage>
    with WidgetsBindingObserver {
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _wasInBackground = true;
    }

    if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;

      final cartState = ref.read(cartControllerProvider);

      if (cartState.cart != null && !cartState.isLoading) {
        ref.read(cartControllerProvider.notifier).refreshCart();
      }
    }
  }

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(cartControllerProvider.notifier).refreshCart();
  }

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    void showMessage(String message) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }

    final initialState = ref.read(cartControllerProvider);

    if (initialState.isLoading || initialState.requiresRefresh) {
      return;
    }

    final refreshed = await ref
        .read(cartControllerProvider.notifier)
        .refreshCart();

    if (!context.mounted) return;

    if (!refreshed) {
      showMessage('Unable to refresh the cart. Please try again.');
      return;
    }

    final cart = ref.read(cartControllerProvider).cart;

    if (cart == null || cart.lines.isEmpty) {
      showMessage('Your cart is empty.');
      return;
    }

    final uri = Uri.tryParse(cart.checkoutUrl);

    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      showMessage('The checkout URL is invalid.');
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);

      if (!opened) {
        showMessage('Unable to open checkout.');
      }
    } catch (error) {
      showMessage('Unable to open checkout. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartControllerProvider);
    final cart = state.cart;
    final controller = ref.read(cartControllerProvider.notifier);

    final canModify = !state.isLoading && !state.requiresRefresh;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart (${cart?.totalQuantity ?? 0})'),
        actions: [
          IconButton(
            tooltip: 'Refresh cart',
            onPressed: state.isLoading ? null : () => _refresh(ref),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: state.isLoading ? null : () => _refresh(ref),
                    child: const Text('Refresh cart'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: cart == null || cart.lines.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : RefreshIndicator(
                    onRefresh: () => _refresh(ref),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: cart.lines.length,
                      separatorBuilder: (_, _) => const Divider(height: 32),
                      itemBuilder: (context, index) {
                        final line = cart.lines[index];

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: line.imageUrl == null
                                  ? const Icon(
                                      Icons.image_not_supported_outlined,
                                    )
                                  : Image.network(
                                      line.imageUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.productTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(line.variantTitle),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Line total: ${line.totalAmount} '
                                    '${line.currencyCode}',
                                  ),
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      IconButton(
                                        tooltip: 'Decrease quantity',
                                        onPressed:
                                            canModify && line.quantity > 1
                                            ? () async {
                                                await controller
                                                    .updateItemQuantity(
                                                      lineId: line.id,
                                                      quantity:
                                                          line.quantity - 1,
                                                    );
                                              }
                                            : null,
                                        icon: const Icon(Icons.remove),
                                      ),
                                      Text('${line.quantity}'),
                                      IconButton(
                                        tooltip: 'Increase quantity',
                                        onPressed: canModify
                                            ? () async {
                                                await controller
                                                    .updateItemQuantity(
                                                      lineId: line.id,
                                                      quantity:
                                                          line.quantity + 1,
                                                    );
                                              }
                                            : null,
                                        icon: const Icon(Icons.add),
                                      ),
                                      IconButton(
                                        tooltip: 'Remove item',
                                        onPressed: canModify
                                            ? () async {
                                                await controller.removeItem(
                                                  line.id,
                                                );
                                              }
                                            : null,
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
          if (cart != null && cart.lines.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text(
                          '${cart.cost.subtotalAmount} '
                          '${cart.cost.currencyCode}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated total'),
                        Text(
                          '${cart.cost.totalAmount} '
                          '${cart.cost.currencyCode}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canModify
                            ? () => _checkout(context, ref)
                            : null,
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Continue to checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (state.warnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cart updated with notices',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  for (final warning in state.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(warning.message),
                    ),
                  TextButton(
                    onPressed: controller.dismissWarnings,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
