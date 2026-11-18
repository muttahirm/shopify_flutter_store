import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/shopify_config.dart';

final shopifyClientProvider = Provider<Dio>((ref) {
  ShopifyConfig.validate();

  final dio = Dio(
    BaseOptions(
      baseUrl: ShopifyConfig.endpoint,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'X-Shopify-Storefront-Access-Token': ShopifyConfig.storefrontToken,
      },
    ),
  );

  ref.onDispose(() => dio.close());

  return dio;
});
