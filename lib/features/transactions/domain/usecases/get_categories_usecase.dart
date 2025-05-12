import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failure.dart';
import 'package:monie/features/transactions/domain/entities/category.dart';
import 'package:monie/features/transactions/domain/repositories/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository repository;

  GetCategoriesUseCase(this.repository);

  Future<Either<Failure, List<Category>>> call({bool? isIncome}) async {
    return await repository.getCategories(isIncome: isIncome);
  }
}
