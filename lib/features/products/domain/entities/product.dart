class Product {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String priceAmount;
  final String currencyCode;
  final bool availableForSale;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.priceAmount,
    required this.currencyCode,
    required this.availableForSale,
  });
}
