import 'package:injectable/injectable.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/budgets/data/models/budget_model.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/domain/repositories/budget_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@Injectable(as: BudgetRepository)
class BudgetRepositoryImpl implements BudgetRepository {
  final SupabaseClientManager _supabaseClient;

  BudgetRepositoryImpl(this._supabaseClient);

  @override
  Future<List<Budget>> getBudgets() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseClient.client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: false);

      return response.map<Budget>((json) => 
          BudgetModel.fromSupabaseJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get budgets: $error');
    }
  }

  @override
  Future<Budget> getBudgetById(String id) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseClient.client
          .from('budgets')
          .select()
          .eq('budget_id', id)
          .eq('user_id', userId)
          .single();

      return BudgetModel.fromSupabaseJson(response);
    } catch (error) {
      throw Exception('Failed to get budget: $error');
    }
  }

  @override
  Future<List<Budget>> getActiveBudgets() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabaseClient.client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .gte('end_date', today)
          .order('start_date', ascending: true);

      return response.map<Budget>((json) => 
          BudgetModel.fromSupabaseJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get active budgets: $error');
    }
  }

  @override
  Future<void> addBudget(Budget budget) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final budgetModel = budget is BudgetModel 
          ? budget 
          : BudgetModel.fromEntity(budget);

      // Ensure userId is set
      final Map<String, dynamic> budgetData = budgetModel.toSupabaseJson();
      budgetData['user_id'] = userId;

      await _supabaseClient.client
          .from('budgets')
          .insert(budgetData);
    } catch (error) {
      throw Exception('Failed to add budget: $error');
    }
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final budgetModel = budget is BudgetModel 
          ? budget 
          : BudgetModel.fromEntity(budget);

      await _supabaseClient.client
          .from('budgets')
          .update(budgetModel.toSupabaseJson())
          .eq('budget_id', budget.id)
          .eq('user_id', userId);
    } catch (error) {
      throw Exception('Failed to update budget: $error');
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabaseClient.client
          .from('budgets')
          .delete()
          .eq('budget_id', id)
          .eq('user_id', userId);
    } catch (error) {
      throw Exception('Failed to delete budget: $error');
    }
  }
}
