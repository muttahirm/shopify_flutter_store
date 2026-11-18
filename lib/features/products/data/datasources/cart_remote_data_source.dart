import 'package:dio/dio.dart';

import '../models/cart/cart_model.dart';

class CartRemoteDataSource {
  final Dio _dio;

  const CartRemoteDataSource(this._dio);

  static const _cartFields = r'''
    fragment CartFields on Cart {
      id
      checkoutUrl
      totalQuantity
      cost {
        subtotalAmount {
          amount
          currencyCode
        }
        totalAmount {
          amount
          currencyCode
        }
      }
      lines(first: 100) {
        nodes {
          id
          quantity
          cost {
            totalAmount {
              amount
              currencyCode
            }
          }
          merchandise {
            __typename
            ... on ProductVariant {
              id
              title
              image {
                url
              }
              product {
                title
              }
            }
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  ''';

  static const _createCartMutation =
      r'''
    mutation CreateCart {
      cartCreate(input: {}) {
        cart {
          ...CartFields
        }
        userErrors {
          field
          message
          code
        }
      }
    }
  ''' +
      _cartFields;

  Future<CartModel> createCart() async {
    final data = await _execute(_createCartMutation);

    final payload = data['cartCreate'] as Map<String, dynamic>?;

    if (payload == null) {
      throw const FormatException('Missing cartCreate response.');
    }

    final userErrors = payload['userErrors'] as List<dynamic>;

    if (userErrors.isNotEmpty) {
      final messages = userErrors
          .map((error) {
            final details = error as Map<String, dynamic>;
            return details['message'] as String;
          })
          .join('; ');

      throw CartRemoteException(messages);
    }

    final cart = payload['cart'] as Map<String, dynamic>?;

    if (cart == null) {
      throw const CartRemoteException('Shopify did not return a cart.');
    }

    return CartModel.fromJson(cart);
  }

  Future<Map<String, dynamic>> _execute(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '',
      data: {'query': query, 'variables': ?variables},
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

      throw CartRemoteException(messages);
    }

    final data = body['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw const FormatException('Missing Shopify response data.');
    }

    return data;
  }
}

class CartRemoteException implements Exception {
  final String message;

  const CartRemoteException(this.message);

  @override
  String toString() => 'CartRemoteException: $message';
}
