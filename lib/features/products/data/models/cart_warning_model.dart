import '../../domain/entities/cart_warning.dart';

class CartWarningModel {
  final String code;
  final String message;
  final String targetId;

  const CartWarningModel({
    required this.code,
    required this.message,
    required this.targetId,
  });

  factory CartWarningModel.fromJson(Map<String, dynamic> json) {
    return CartWarningModel(
      code: json['code'] as String,
      message: json['message'] as String,
      targetId: json['target'] as String,
    );
  }

  CartWarning toEntity() {
    return CartWarning(code: code, message: message, targetId: targetId);
  }
}
