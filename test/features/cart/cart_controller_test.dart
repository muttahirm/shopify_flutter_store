import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:shopify_flutter_store/features/products/data/datasources/cart_local_data_source.dart';
import 'package:shopify_flutter_store/features/products/domain/entities/cart.dart';
import 'package:shopify_flutter_store/features/products/domain/entities/cart_cost.dart';
import 'package:shopify_flutter_store/features/products/domain/entities/cart_mutation_result.dart';
import 'package:shopify_flutter_store/features/products/domain/entities/cart_warning.dart';
import 'package:shopify_flutter_store/features/products/domain/repositories/cart_repository.dart';
import 'package:shopify_flutter_store/features/products/presentation/providers/cart_controller.dart';
import 'package:shopify_flutter_store/features/products/presentation/providers/cart_providers.dart';
import 'package:shopify_flutter_store/features/products/presentation/providers/cart_state.dart';

class MockCartRepository extends Mock implements CartRepository {}

class MockCartLocalDataSource extends Mock implements CartLocalDataSource {}

const savedCartId = 'saved-cart-id';
const newCartId = 'new-cart-id';
const variantId = 'variant-id';

Cart makeCart(String id) {
  return Cart(
    id: id,
    checkoutUrl: 'https://example.com/checkout',
    totalQuantity: 0,
    lines: const [],
    cost: const CartCost(
      subtotalAmount: '0.00',
      totalAmount: '0.00',
      currencyCode: 'EUR',
    ),
  );
}

// Wait for automatic startup restoration without arbitrary sleeps.
Future<void> waitUntilIdle(ProviderContainer container) async {
  final completer = Completer<void>();

  final subscription = container.listen<CartState>(cartControllerProvider, (
    previous,
    next,
  ) {
    if (!next.isLoading && !completer.isCompleted) {
      completer.complete();
    }
  }, fireImmediately: true);

  try {
    await completer.future.timeout(const Duration(seconds: 5));
  } finally {
    subscription.close();
  }
}

void main() {
  late MockCartRepository repository;
  late MockCartLocalDataSource storage;
  late ProviderContainer container;

  setUp(() {
    repository = MockCartRepository();
    storage = MockCartLocalDataSource();

    when(() => storage.readCartId()).thenAnswer((_) async => savedCartId);

    when(() => storage.saveCartId(any())).thenAnswer((_) async {});

    when(() => storage.clearCartId()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(repository),
        cartLocalDataSourceProvider.overrideWithValue(storage),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('exposes mutation warnings and allows dismissal', () async {
    final cart = makeCart(savedCartId);

    when(() => repository.getCart(savedCartId)).thenAnswer((_) async => cart);

    const warning = CartWarning(
      code: 'MERCHANDISE_NOT_ENOUGH_STOCK',
      message: 'The quantity was adjusted to available stock.',
      targetId: 'line-id',
    );

    when(
      () => repository.addItem(
        cartId: savedCartId,
        variantId: variantId,
        quantity: 3,
      ),
    ).thenAnswer(
      (_) async => CartMutationResult(cart: cart, warnings: [warning]),
    );

    await waitUntilIdle(container);

    final controller = container.read(cartControllerProvider.notifier);

    final success = await controller.addItem(variantId: variantId, quantity: 3);

    final state = container.read(cartControllerProvider);

    expect(success, isTrue);
    expect(state.cart?.id, savedCartId);
    expect(state.warnings, hasLength(1));
    expect(state.warnings.single.code, warning.code);
    expect(state.warnings.single.message, warning.message);
    expect(state.requiresRefresh, isFalse);
    expect(state.errorMessage, isNull);

    controller.dismissWarnings();

    expect(container.read(cartControllerProvider).warnings, isEmpty);
    expect(container.read(cartControllerProvider).cart?.id, savedCartId);
  });

  test('clears an unavailable cart and creates one on next add', () async {
    when(() => repository.getCart(savedCartId)).thenAnswer((_) async => null);

    final newCart = makeCart(newCartId);

    when(() => repository.createCart())
        .thenAnswer((_) async => CartMutationResult(cart: newCart));

    when(
      () => repository.addItem(
        cartId: newCartId,
        variantId: variantId,
        quantity: 1,
      ),
    ).thenAnswer((_) async => CartMutationResult(cart: newCart));

    await waitUntilIdle(container);

    final restoredState = container.read(cartControllerProvider);

    expect(restoredState.cart, isNull);
    expect(restoredState.requiresRefresh, isFalse);
    expect(restoredState.noticeMessage, isNotNull);

    verify(() => storage.clearCartId()).called(1);

    // Restoration must not create a replacement cart eagerly.
    verifyNever(() => repository.createCart());

    final success = await container
        .read(cartControllerProvider.notifier)
        .addItem(variantId: variantId);

    expect(success, isTrue);
    expect(container.read(cartControllerProvider).cart?.id, newCartId);

    verify(() => repository.createCart()).called(1);

    verify(
      () => repository.addItem(
        cartId: newCartId,
        variantId: variantId,
        quantity: 1,
      ),
    ).called(1);

    verify(() => storage.saveCartId(newCartId)).called(greaterThanOrEqualTo(1));
  });

  test('preserves the saved ID on network failure and recovers', () async {
    when(() => repository.getCart(savedCartId))
        .thenAnswer((_) async => throw const SocketException('Offline'));

    await waitUntilIdle(container);

    final failedState = container.read(cartControllerProvider);

    expect(failedState.cart, isNull);
    expect(failedState.isLoading, isFalse);
    expect(failedState.requiresRefresh, isTrue);
    expect(failedState.errorMessage, isNotNull);

    verifyNever(() => storage.clearCartId());
    verifyNever(() => storage.saveCartId(any()));
    verifyNever(() => repository.createCart());

    final controller = container.read(cartControllerProvider.notifier);

    // Block a new purchase until the saved cart is recovered.
    final added = await controller.addItem(variantId: variantId);

    expect(added, isFalse);
    verifyNever(() => repository.createCart());

    // Simulate connectivity returning.
    when(() => repository.getCart(savedCartId))
        .thenAnswer((_) async => makeCart(savedCartId));

    final refreshed = await controller.refreshCart();

    final recoveredState = container.read(cartControllerProvider);

    expect(refreshed, isTrue);
    expect(recoveredState.cart?.id, savedCartId);
    expect(recoveredState.requiresRefresh, isFalse);
    expect(recoveredState.errorMessage, isNull);

    verifyNever(() => storage.clearCartId());
    verify(() => storage.saveCartId(savedCartId)).called(1);
  });
}
