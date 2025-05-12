import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/transactions/data/models/category_model.dart';
import 'package:uuid/uuid.dart';

abstract class CategoryRemoteDataSource {
  /// Fetches all available categories (global and user-specific)
  Future<List<CategoryModel>> getCategories({bool? isIncome});

  /// Creates a new category for the current user
  Future<CategoryModel> createCategory(CategoryModel category);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final SupabaseClientManager _supabaseClient;
  final Uuid _uuid = const Uuid();

  CategoryRemoteDataSourceImpl({required SupabaseClientManager supabaseClient})
    : _supabaseClient = supabaseClient;

  @override
  Future<List<CategoryModel>> getCategories({bool? isIncome}) async {
    try {
      // Get the current user ID
      final currentUser = _supabaseClient.auth.currentUser;
      final String? userId = currentUser?.id;

      // Execute the query for global categories
      final globalCategoriesResponse = await _supabaseClient.client
          .from('categories')
          .select()
          .filter('user_id', 'is', null);

      List<dynamic> allCategoriesData = [...globalCategoriesResponse];

      // If user is logged in, also get their personal categories
      if (userId != null) {
        final userCategoriesResponse = await _supabaseClient.client
            .from('categories')
            .select()
            .eq('user_id', userId);

        allCategoriesData.addAll(userCategoriesResponse);
      }

      // Apply income filter if needed
      if (isIncome != null) {
        allCategoriesData =
            allCategoriesData
                .where((category) => category['is_income'] == isIncome)
                .toList();
      }

      // Convert to CategoryModel objects
      final List<CategoryModel> categories =
          allCategoriesData
              .map((category) => CategoryModel.fromJson(category))
              .toList();

      return categories;
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      // Get the current user ID from Supabase
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to create a category');
      }

      // Generate a new UUID for the category
      final String categoryId = _uuid.v4();

      // Create the category record
      final categoryData = {
        'category_id': categoryId,
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
        'is_income': category.isIncome,
        'is_default': false, // User-created categories are not defaults
        'user_id': currentUser.id,
      };

      await _supabaseClient.client.from('categories').insert(categoryData);

      // Return the created category with the new ID
      return CategoryModel(
        id: categoryId,
        name: category.name,
        userId: currentUser.id,
        icon: category.icon,
        color: category.color,
        isIncome: category.isIncome,
        isDefault: false,
      );
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }
}
