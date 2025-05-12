import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failure.dart';
import 'package:monie/features/transactions/data/datasources/category_remote_data_source.dart';
import 'package:monie/features/transactions/data/models/category_model.dart';
import 'package:monie/features/transactions/domain/entities/category.dart';
import 'package:monie/features/transactions/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Category>>> getCategories({
    bool? isIncome,
  }) async {
    try {
      final categories = await remoteDataSource.getCategories(
        isIncome: isIncome,
      );
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory(Category category) async {
    try {
      final categoryModel =
          category is CategoryModel
              ? category
              : CategoryModel.fromEntity(category);

      final createdCategory = await remoteDataSource.createCategory(
        categoryModel,
      );
      return Right(createdCategory);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
