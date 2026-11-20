import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_mutation_result.dart';
import '../../domain/entities/cart_warning.dart';
import 'cart_providers.dart';
import 'cart_state.dart';

final cartControllerProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);

class CartController extends Notifier<CartState> {
  bool _requestRunning = false;

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
          final created = await ref.read(createCartProvider)();
          cart = created.cart;

          state = CartState(
            cart: cart,
            isLoading: true,
            warnings: created.warnings,
          );

          await ref.read(cartLocalDataSourceProvider).saveCartId(cart.id);
        }

        final result = await ref.read(addCartItemProvider)(
          cartId: cart.id,
          variantId: variantId,
          quantity: quantity,
        );

        return CartMutationResult(
          cart: result.cart,
          warnings: [...state.warnings, ...result.warnings],
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

  Future<bool> refreshCart() {
    return _run(
      mutation: false,
      action: () async {
        final storage = ref.read(cartLocalDataSourceProvider);
        final cartId = state.cart?.id ?? await storage.readCartId();

        if (cartId == null) return null;

        final cart = await ref.read(getCartProvider)(cartId);

        if (cart == null) return null;

        return CartMutationResult(cart: cart);
      },
    );
  }

  void dismissWarnings() {
    state = CartState(
      cart: state.cart,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      requiresRefresh: state.requiresRefresh,
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
    required Future<CartMutationResult?> Function() action,
  }) async {
    if (_requestRunning) return false;
    if (mutation && state.isLoading) return false;

    if (mutation && state.requiresRefresh) {
      state = CartState(
        cart: state.cart,
        warnings: state.warnings,
        requiresRefresh: true,
        errorMessage: 'Refresh the cart before making another change.',
      );

      return false;
    }

    _requestRunning = true;

    state = CartState(
      cart: state.cart,
      isLoading: true,
      requiresRefresh: state.requiresRefresh,
      warnings: mutation ? const [] : state.warnings,
    );

    try {
      final result = await action();
      final storage = ref.read(cartLocalDataSourceProvider);
      final cart = result?.cart;

      final warnings = mutation
          ? result!.warnings
          : cart == null
          ? const <CartWarning>[]
          : state.warnings;

      state = CartState(cart: cart, isLoading: true, warnings: warnings);

      if (cart == null) {
        await storage.clearCartId();
      } else {
        await storage.saveCartId(cart.id);
      }

      state = CartState(cart: cart, warnings: warnings);

      return true;
    } catch (error) {
      state = CartState(
        cart: state.cart,
        warnings: state.warnings,
        requiresRefresh: true,
        errorMessage:
            'Unable to synchronize the cart. Refresh before continuing.',
      );

      return false;
    } finally {
      _requestRunning = false;
    }
  }
}
