import '../../../domain/entities/product.dart';

class ProductModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String priceAmount;
  final String currencyCode;
  final bool availableForSale;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.priceAmount,
    required this.currencyCode,
    required this.availableForSale,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final image = json['featuredImage'] as Map<String, dynamic>?;
    final priceRange = json['priceRange'] as Map<String, dynamic>;
    final minPrice = priceRange['minVariantPrice'] as Map<String, dynamic>;

    return ProductModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: image?['url'] as String?,
      priceAmount: minPrice['amount'] as String,
      currencyCode: minPrice['currencyCode'] as String,
      availableForSale: json['availableForSale'] as bool,
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      priceAmount: priceAmount,
      currencyCode: currencyCode,
      availableForSale: availableForSale,
    );
  }
}
