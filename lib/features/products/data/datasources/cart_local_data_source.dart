import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CartLocalDataSource {
  final FlutterSecureStorage _storage;
  final String _key;

  const CartLocalDataSource(this._storage, {required String storeDomain})
    : _key = 'shopify_cart_id:$storeDomain';

  Future<String?> readCartId() {
    return _storage.read(key: _key);
  }

  Future<void> saveCartId(String cartId) {
    return _storage.write(key: _key, value: cartId);
  }

  Future<void> clearCartId() {
    return _storage.delete(key: _key);
  }
}
