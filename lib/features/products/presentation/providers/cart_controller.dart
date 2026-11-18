import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cart.dart';
import 'cart_providers.dart';
import 'cart_state.dart';

final cartControllerProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  Future<bool> addItem({required String variantId, int quantity = 1}) {
    return _run(
      mutation: true,
      action: () async {
        var cart = state.cart;

        if (cart == null) {
          cart = await ref.read(createCartProvider)();

          // Retain the new cart if adding the item later fails.
          state = CartState(cart: cart, isLoading: true);
        }

        return ref.read(addCartItemProvider)(
          cartId: cart.id,
          variantId: variantId,
          quantity: quantity,
        );
      },
    );
  }

  Future<bool> updateItemQuantity({
    required String lineId,
    required int quantity,
  }) {
    return _run(
      mutation: true,
      action: () {
        final cart = _requireCart();

        return ref.read(updateCartItemQuantityProvider)(
          cartId: cart.id,
          lineId: lineId,
          quantity: quantity,
        );
      },
    );
  }

  Future<bool> removeItem(String lineId) {
    return _run(
      mutation: true,
      action: () {
        final cart = _requireCart();

        return ref.read(removeCartItemProvider)(
          cartId: cart.id,
          lineId: lineId,
        );
      },
    );
  }

  Future<bool> refreshCart() {
    return _run(
      mutation: false,
      action: () async {
        final cart = state.cart;

        if (cart == null) {
          return null;
        }

        return ref.read(getCartProvider)(cart.id);
      },
    );
  }

  Cart _requireCart() {
    final cart = state.cart;

    if (cart == null) {
      throw StateError('No active cart.');
    }

    return cart;
  }

  Future<bool> _run({
    required bool mutation,
    required Future<Cart?> Function() action,
  }) async {
    // Reject overlapping requests.
    if (state.isLoading) {
      return false;
    }

    if (mutation && state.requiresRefresh) {
      state = CartState(
        cart: state.cart,
        requiresRefresh: true,
        errorMessage: 'Refresh the cart before making another change.',
      );

      return false;
    }

    state = CartState(
      cart: state.cart,
      isLoading: true,
      requiresRefresh: state.requiresRefresh,
    );

    try {
      final cart = await action();

      state = CartState(cart: cart);

      return true;
    } catch (error) {
      final requiresRefresh =
          state.cart != null && (mutation || state.requiresRefresh);

      state = CartState(
        cart: state.cart,
        requiresRefresh: requiresRefresh,
        errorMessage: requiresRefresh
            ? 'Unable to confirm the cart state. Refresh before continuing.'
            : 'Unable to complete the cart request. Please try again.',
      );

      return false;
    }
  }
}
