import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/core/errors/failure.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/transactions/data/models/category_model.dart';
import 'package:monie/features/transactions/domain/entities/category.dart';
import 'package:monie/features/transactions/domain/repositories/category_repository.dart';

@Injectable(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  final SupabaseClientManager _supabaseClientManager;

  CategoryRepositoryImpl(this._supabaseClientManager);

  @override
  Future<Either<Failure, List<Category>>> getCategories({
    bool? isIncome,
  }) async {
    try {
      final query = _supabaseClientManager.client.from('categories').select();

      if (isIncome != null) {
        query.eq('is_income', isIncome);
      }

      final response = await query;

      final categories =
          response.map((json) => CategoryModel.fromJson(json)).toList();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure('Failed to get categories: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory(Category category) async {
    try {
      final categoryModel = CategoryModel.fromEntity(category);
      final response =
          await _supabaseClientManager.client
              .from('categories')
              .insert(categoryModel.toJson())
              .select()
              .single();

      return Right(CategoryModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure('Failed to create category: $e'));
    }
  }
}
