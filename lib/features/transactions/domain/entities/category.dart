import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String? userId;
  final String name;
  final String? icon;
  final String? color;
  final bool isIncome;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    this.userId,
    this.icon,
    this.color,
    this.isIncome = false,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    icon,
    color,
    isIncome,
    isDefault,
  ];
}
