import 'package:injectable/injectable.dart';
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/transactions/data/models/budget_model.dart';

abstract class BudgetRemoteDataSource {
  Future<List<BudgetModel>> getBudgets(String userId);
  Future<BudgetModel?> getBudgetById(String budgetId);
  Future<BudgetModel> createBudget(BudgetModel budget);
  Future<BudgetModel> updateBudget(BudgetModel budget);
  Future<bool> deleteBudget(String budgetId);
}

@Injectable(as: BudgetRemoteDataSource)
class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final SupabaseClientManager _supabaseClientManager;

  BudgetRemoteDataSourceImpl({
    required SupabaseClientManager supabaseClientManager,
  }) : _supabaseClientManager = supabaseClientManager;

  @override
  Future<List<BudgetModel>> getBudgets(String userId) async {
    try {
      final response = await _supabaseClientManager.client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .order('name');

      return (response as List)
          .map((json) => BudgetModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get budgets: $e');
    }
  }

  @override
  Future<BudgetModel?> getBudgetById(String budgetId) async {
    try {
      final response =
          await _supabaseClientManager.client
              .from('budgets')
              .select()
              .eq('budget_id', budgetId)
              .single();

      return BudgetModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: 'Failed to get budget by ID: $e');
    }
  }

  @override
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    try {
      final budgetData = budget.toJson();

      final response =
          await _supabaseClientManager.client
              .from('budgets')
              .insert(budgetData)
              .select()
              .single();

      return BudgetModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
        throw ServerException(message: 'Budget already exists: $e');
      } else {
        throw ServerException(message: 'Failed to create budget: $e');
      }
    }
  }

  @override
  Future<BudgetModel> updateBudget(BudgetModel budget) async {
    try {
      final response =
          await _supabaseClientManager.client
              .from('budgets')
              .update(budget.toJson())
              .eq('budget_id', budget.budgetId)
              .select()
              .single();

      return BudgetModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: 'Failed to update budget: $e');
    }
  }

  @override
  Future<bool> deleteBudget(String budgetId) async {
    try {
      await _supabaseClientManager.client
          .from('budgets')
          .delete()
          .eq('budget_id', budgetId);
      return true;
    } catch (e) {
      throw ServerException(message: 'Failed to delete budget: $e');
    }
  }
}
