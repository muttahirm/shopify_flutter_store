class CartLine {
  final String id;
  final String variantId;
  final String productTitle;
  final String variantTitle;
  final String? imageUrl;
  final int quantity;
  final String totalAmount;
  final String currencyCode;

  const CartLine({
    required this.id,
    required this.variantId,
    required this.productTitle,
    required this.variantTitle,
    this.imageUrl,
    required this.quantity,
    required this.totalAmount,
    required this.currencyCode,
  });
}
