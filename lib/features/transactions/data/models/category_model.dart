import 'package:monie/features/transactions/domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    super.userId,
    super.icon,
    super.color,
    super.isIncome,
    super.isDefault,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['category_id'],
      name: json['name'],
      userId: json['user_id'],
      icon: json['icon'],
      color: json['color'],
      isIncome: json['is_income'] ?? false,
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': id,
      'name': name,
      'user_id': userId,
      'icon': icon,
      'color': color,
      'is_income': isIncome,
      'is_default': isDefault,
    };
  }

  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      userId: entity.userId,
      icon: entity.icon,
      color: entity.color,
      isIncome: entity.isIncome,
      isDefault: entity.isDefault,
    );
  }
}
