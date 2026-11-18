import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/shopify_client.dart';
import '../../data/datasources/cart_remote_data_source.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/usecases/add_cart_item.dart';
import '../../domain/usecases/create_cart.dart';
import '../../domain/usecases/get_cart.dart';
import '../../domain/usecases/remove_cart_item.dart';
import '../../domain/usecases/update_cart_item_quantity.dart';

// Data source
final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  final dio = ref.watch(shopifyClientProvider);

  return CartRemoteDataSource(dio);
});

// Repository exposed through its domain contract
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final dataSource = ref.watch(cartRemoteDataSourceProvider);

  return CartRepositoryImpl(dataSource);
});

// Use cases
final createCartProvider = Provider<CreateCart>((ref) {
  final repository = ref.watch(cartRepositoryProvider);

  return CreateCart(repository);
});

final getCartProvider = Provider<GetCart>((ref) {
  final repository = ref.watch(cartRepositoryProvider);

  return GetCart(repository);
});

final addCartItemProvider = Provider<AddCartItem>((ref) {
  final repository = ref.watch(cartRepositoryProvider);

  return AddCartItem(repository);
});

final updateCartItemQuantityProvider = Provider<UpdateCartItemQuantity>((ref) {
  final repository = ref.watch(cartRepositoryProvider);

  return UpdateCartItemQuantity(repository);
});

final removeCartItemProvider = Provider<RemoveCartItem>((ref) {
  final repository = ref.watch(cartRepositoryProvider);

  return RemoveCartItem(repository);
});
