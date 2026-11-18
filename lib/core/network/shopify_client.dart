import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shopifyClientProvider = Provider<Dio>((ref) {
  const domain = String.fromEnvironment('SHOPIFY_STORE_DOMAIN');
  const token = String.fromEnvironment('SHOPIFY_STOREFRONT_TOKEN');

  if (domain.isEmpty || token.isEmpty) {
    throw StateError('Missing Shopify domain or public Storefront token.');
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://$domain/api/2026-10/graphql.json',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'X-Shopify-Storefront-Access-Token': token,
      },
    ),
  );

  ref.onDispose(() => dio.close());
  return dio;
});
