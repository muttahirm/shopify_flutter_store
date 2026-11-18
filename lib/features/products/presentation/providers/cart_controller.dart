import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cart.dart';
import 'cart_providers.dart';
import 'cart_state.dart';

final cartControllerProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);

class CartController extends Notifier<CartState> {
  bool _restored = false;

  @override
  CartState build() {
    // Start restoration after the initial state is available.
    Future.microtask(refreshCart);

    return const CartState(isLoading: true);
  }

  Future<bool> addItem({required String variantId, int quantity = 1}) {
    return _run(
      mutation: true,
      action: () async {
        var cart = state.cart;

        if (cart == null) {
          cart = await ref.read(createCartProvider)();

          // Retain the ID even if saving or adding later fails.
          state = CartState(cart: cart, isLoading: true);

          await ref.read(cartLocalDataSourceProvider).saveCartId(cart.id);
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
        return ref.read(updateCartItemQuantityProvider)(
          cartId: _requireCart().id,
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
        return ref.read(removeCartItemProvider)(
          cartId: _requireCart().id,
          lineId: lineId,
        );
      },
    );
  }

  Future<bool> refreshCart() async {
    // Initial restoration starts with isLoading already true.
    if (state.isLoading && _restored) {
      return false;
    }

    // Prevent another refresh while initial restoration is running.
    if (!_restored) {
      _restored = true;
    }

    return _run(
      mutation: false,
      allowInitialLoading: true,
      action: () async {
        final storage = ref.read(cartLocalDataSourceProvider);
        final cartId = state.cart?.id ?? await storage.readCartId();

        if (cartId == null) {
          return null;
        }

        return ref.read(getCartProvider)(cartId);
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
    bool allowInitialLoading = false,
  }) async {
    if (state.isLoading && !allowInitialLoading) {
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
      final storage = ref.read(cartLocalDataSourceProvider);

      if (cart == null) {
        await storage.clearCartId();
      } else {
        // Keep the latest cart visible even if storage fails.
        state = CartState(cart: cart, isLoading: true);
        await storage.saveCartId(cart.id);
      }

      state = CartState(cart: cart);
      return true;
    } catch (error) {
      // Preserve the saved ID on network failures.
      // Block mutations until restoration/refresh succeeds.
      state = CartState(
        cart: state.cart,
        requiresRefresh: true,
        errorMessage:
            'Unable to synchronize the cart. Refresh before continuing.',
      );

      return false;
    }
  }
}
