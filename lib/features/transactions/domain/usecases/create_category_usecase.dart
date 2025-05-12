import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failure.dart';
import 'package:monie/features/transactions/domain/entities/category.dart';
import 'package:monie/features/transactions/domain/repositories/category_repository.dart';

class CreateCategoryUseCase {
  final CategoryRepository repository;

  CreateCategoryUseCase(this.repository);

  Future<Either<Failure, Category>> call(CreateCategoryParams params) async {
    return await repository.createCategory(
      Category(
        id: '', // Will be replaced with a generated ID
        name: params.name,
        icon: params.icon,
        color: params.color,
        isIncome: params.isIncome,
      ),
    );
  }
}

class CreateCategoryParams extends Equatable {
  final String name;
  final String icon;
  final String color;
  final bool isIncome;

  const CreateCategoryParams({
    required this.name,
    required this.icon,
    required this.color,
    this.isIncome = false,
  });

  @override
  List<Object?> get props => [name, icon, color, isIncome];
}
