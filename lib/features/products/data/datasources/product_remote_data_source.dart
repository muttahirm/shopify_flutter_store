import 'package:dio/dio.dart';

import '../models/product_model.dart';

class ProductRemoteDataSource {
  final Dio _dio;

  const ProductRemoteDataSource(this._dio);

  static const _productsQuery = r'''
    query GetProducts($first: Int!) {
      products(first: $first) {
        nodes {
          id
          title
          description
          availableForSale
          featuredImage {
            url
          }
          priceRange {
            minVariantPrice {
              amount
              currencyCode
            }
          }
        }
      }
    }
  ''';

  Future<List<ProductModel>> getProducts({int limit = 20}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '',
      data: {
        'query': _productsQuery,
        'variables': {'first': limit},
      },
    );

    final body = response.data;

    if (body == null) {
      throw const FormatException('Empty Shopify response.');
    }

    final errors = body['errors'] as List<dynamic>?;

    if (errors != null && errors.isNotEmpty) {
      final messages = errors
          .map((error) {
            final details = error as Map<String, dynamic>;
            return details['message'] as String? ?? 'Unknown GraphQL error';
          })
          .join('; ');

      throw ShopifyGraphqlException(messages);
    }

    final data = body['data'] as Map<String, dynamic>?;
    final products = data?['products'] as Map<String, dynamic>?;
    final nodes = products?['nodes'] as List<dynamic>?;

    if (nodes == null) {
      throw const FormatException('Shopify response is missing product data.');
    }

    return nodes
        .map((node) => ProductModel.fromJson(node as Map<String, dynamic>))
        .toList(growable: false);
  }
}

class ShopifyGraphqlException implements Exception {
  final String message;

  const ShopifyGraphqlException(this.message);

  @override
  String toString() => 'ShopifyGraphqlException: $message';
}
