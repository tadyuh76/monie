import 'package:equatable/equatable.dart';

abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoriesEvent {
  final bool? isIncome;

  const LoadCategories({this.isIncome});

  @override
  List<Object?> get props => [isIncome];
}

class CreateCategory extends CategoriesEvent {
  final String name;
  final String icon;
  final String color;
  final bool isIncome;

  const CreateCategory({
    required this.name,
    required this.icon,
    required this.color,
    this.isIncome = false,
  });

  @override
  List<Object?> get props => [name, icon, color, isIncome];
}
