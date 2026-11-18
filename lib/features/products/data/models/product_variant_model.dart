import '../../domain/entities/product_variant.dart';

class ProductVariantModel {
  final String id;
  final String title;
  final String priceAmount;
  final String currencyCode;
  final bool availableForSale;
  final Map<String, String> selectedOptions;

  ProductVariantModel({
    required this.id,
    required this.title,
    required this.priceAmount,
    required this.currencyCode,
    required this.availableForSale,
    required Map<String, String> selectedOptions,
  }) : selectedOptions = Map.unmodifiable(selectedOptions);

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    final price = json['price'] as Map<String, dynamic>;
    final options = json['selectedOptions'] as List<dynamic>;

    return ProductVariantModel(
      id: json['id'] as String,
      title: json['title'] as String,
      priceAmount: price['amount'] as String,
      currencyCode: price['currencyCode'] as String,
      availableForSale: json['availableForSale'] as bool,
      selectedOptions: {
        for (final option in options)
          (option as Map<String, dynamic>)['name'] as String:
              option['value'] as String,
      },
    );
  }

  ProductVariant toEntity() {
    return ProductVariant(
      id: id,
      title: title,
      priceAmount: priceAmount,
      currencyCode: currencyCode,
      availableForSale: availableForSale,
      selectedOptions: selectedOptions,
    );
  }
}
