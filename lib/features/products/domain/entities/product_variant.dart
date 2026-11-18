class ProductVariant {
  final String id;
  final String title;
  final String priceAmount;
  final String currencyCode;
  final bool availableForSale;
  final Map<String, String> selectedOptions;

  ProductVariant({
    required this.id,
    required this.title,
    required this.priceAmount,
    required this.currencyCode,
    required this.availableForSale,
    required Map<String, String> selectedOptions,
  }) : selectedOptions = Map.unmodifiable(selectedOptions);
}
