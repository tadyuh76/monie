import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failure.dart';
import 'package:monie/features/transactions/domain/entities/category.dart';

abstract class CategoryRepository {
  /// Gets all available categories (both global and user-specific)
  Future<Either<Failure, List<Category>>> getCategories({bool? isIncome});

  /// Creates a new category for the current user
  Future<Either<Failure, Category>> createCategory(Category category);
}
