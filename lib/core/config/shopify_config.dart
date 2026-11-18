class ShopifyConfig {
  ShopifyConfig._();

  static const storeDomain = String.fromEnvironment('SHOPIFY_STORE_DOMAIN');

  static const storefrontToken = String.fromEnvironment(
    'SHOPIFY_STOREFRONT_TOKEN',
  );

  static const apiVersion = '2026-10';

  static String get endpoint =>
      'https://$storeDomain/api/$apiVersion/graphql.json';

  static void validate() {
    if (storeDomain.isEmpty || storefrontToken.isEmpty) {
      throw StateError(
        'Provide SHOPIFY_STORE_DOMAIN and '
        'SHOPIFY_STOREFRONT_TOKEN using --dart-define.',
      );
    }

    final uri = Uri.tryParse('https://$storeDomain');

    if (uri == null ||
        uri.host != storeDomain ||
        !storeDomain.endsWith('.myshopify.com')) {
      throw StateError(
        'SHOPIFY_STORE_DOMAIN must look like '
        'your-store.myshopify.com, without https:// or a path.',
      );
    }
  }
}
