import 'package:dio/dio.dart';

import '../models/cart/cart_model.dart';
import '../models/cart/cart_mutation_result_model.dart';
import '../models/cart/cart_warning_model.dart';

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
        warnings {
          code
          message
          target
        }
      }
    }
  ''' +
      _cartFields;

  Future<CartMutationResultModel> createCart() async {
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

    return CartMutationResultModel(
      cart: CartModel.fromJson(cart),
      warnings: _parseWarnings(payload),
    );
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

  static const _getCartQuery = r'''
  query GetCart($id: ID!, $after: String) {
    cart(id: $id) {
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
      lines(first: 100, after: $after) {
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
  }
''';

  Future<CartModel?> getCart(String cartId) async {
    final allNodes = <Map<String, dynamic>>[];
    final visitedCursors = <String>{};

    String? cursor;

    while (true) {
      final data = await _execute(
        _getCartQuery,
        variables: {'id': cartId, 'after': cursor},
      );

      if (!data.containsKey('cart')) {
        throw const FormatException('Missing cart response.');
      }

      final cart = data['cart'] as Map<String, dynamic>?;

      if (cart == null) {
        return null;
      }

      final connection = cart['lines'] as Map<String, dynamic>;
      final nodes = connection['nodes'] as List<dynamic>;
      final pageInfo = connection['pageInfo'] as Map<String, dynamic>;

      allNodes.addAll(nodes.map((node) => node as Map<String, dynamic>));

      final hasNextPage = pageInfo['hasNextPage'] as bool;

      if (!hasNextPage) {
        // Merge every page before parsing the cart.
        return CartModel.fromJson({
          ...cart,
          'lines': {...connection, 'nodes': allNodes},
        });
      }

      final nextCursor = pageInfo['endCursor'] as String?;

      if (nextCursor == null ||
          nextCursor.isEmpty ||
          !visitedCursors.add(nextCursor)) {
        throw const FormatException(
          'Invalid or repeated cart-line pagination cursor.',
        );
      }

      cursor = nextCursor;
    }
  }

  static const _addItemMutation = r'''
      mutation AddCartItem($cartId: ID!, $lines: [CartLineInput!]!) {
        cartLinesAdd(cartId: $cartId, lines: $lines) {
          cart {
            id
          }
          userErrors {
            field
            message
            code
          }
          warnings {
            code
            message
            target
          }
        }
      }
    ''';

  Future<CartMutationResultModel> addItem({
    required String cartId,
    required String variantId,
    required int quantity,
  }) async {
    final data = await _execute(
      _addItemMutation,
      variables: {
        'cartId': cartId,
        'lines': [
          {'merchandiseId': variantId, 'quantity': quantity},
        ],
      },
    );

    final payload = data['cartLinesAdd'] as Map<String, dynamic>?;

    if (payload == null) {
      throw const FormatException('Missing cartLinesAdd response.');
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

    final updatedCart = payload['cart'] as Map<String, dynamic>?;

    if (updatedCart == null) {
      throw const CartRemoteException(
        'Shopify did not return the updated cart.',
      );
    }

    final updatedCartId = updatedCart['id'] as String;
    final cart = await getCart(updatedCartId);

    if (cart == null) {
      throw const CartRemoteException(
        'The updated cart is no longer available.',
      );
    }

    return CartMutationResultModel(
      cart: cart,
      warnings: _parseWarnings(payload),
    );
  }

  static const _updateItemQuantityMutation = r'''
  mutation UpdateCartItemQuantity(
    $cartId: ID!,
    $lines: [CartLineUpdateInput!]!
  ) {
    cartLinesUpdate(cartId: $cartId, lines: $lines) {
      cart {
        id
      }
      userErrors {
        field
        message
        code
      }
      warnings {
        code
        message
        target
      }
    }
  }
''';

  Future<CartMutationResultModel> updateItemQuantity({
    required String cartId,
    required String lineId,
    required int quantity,
  }) async {
    final data = await _execute(
      _updateItemQuantityMutation,
      variables: {
        'cartId': cartId,
        'lines': [
          {'id': lineId, 'quantity': quantity},
        ],
      },
    );

    final payload = data['cartLinesUpdate'] as Map<String, dynamic>?;

    if (payload == null) {
      throw const FormatException('Missing cartLinesUpdate response.');
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

    final updatedCart = payload['cart'] as Map<String, dynamic>?;

    if (updatedCart == null) {
      throw const CartRemoteException(
        'Shopify did not return the updated cart.',
      );
    }

    final updatedCartId = updatedCart['id'] as String;
    final cart = await getCart(updatedCartId);

    if (cart == null) {
      throw const CartRemoteException(
        'The updated cart is no longer available.',
      );
    }

    return CartMutationResultModel(
      cart: cart,
      warnings: _parseWarnings(payload),
    );
  }

  static const _removeItemMutation = r'''
  mutation RemoveCartItem($cartId: ID!, $lineIds: [ID!]!) {
    cartLinesRemove(cartId: $cartId, lineIds: $lineIds) {
      cart {
        id
      }
      userErrors {
        field
        message
        code
      }
      warnings {
        code
        message
        target
      }
    }
  }
''';

  Future<CartMutationResultModel> removeItem({
    required String cartId,
    required String lineId,
  }) async {
    final data = await _execute(
      _removeItemMutation,
      variables: {
        'cartId': cartId,
        'lineIds': [lineId],
      },
    );

    final payload = data['cartLinesRemove'] as Map<String, dynamic>?;

    if (payload == null) {
      throw const FormatException('Missing cartLinesRemove response.');
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

    final updatedCart = payload['cart'] as Map<String, dynamic>?;

    if (updatedCart == null) {
      throw const CartRemoteException(
        'Shopify did not return the updated cart.',
      );
    }

    final updatedCartId = updatedCart['id'] as String;
    final cart = await getCart(updatedCartId);

    if (cart == null) {
      throw const CartRemoteException(
        'The updated cart is no longer available.',
      );
    }

    return CartMutationResultModel(
      cart: cart,
      warnings: _parseWarnings(payload),
    );
  }

  List<CartWarningModel> _parseWarnings(Map<String, dynamic> payload) {
    final warnings = payload['warnings'] as List<dynamic>;

    return warnings
        .map(
          (warning) =>
              CartWarningModel.fromJson(warning as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}

class CartRemoteException implements Exception {
  final String message;

  const CartRemoteException(this.message);

  @override
  String toString() => 'CartRemoteException: $message';
}
