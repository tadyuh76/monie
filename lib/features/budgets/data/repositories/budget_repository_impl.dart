import 'package:injectable/injectable.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/budgets/data/models/budget_model.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/domain/repositories/budget_repository.dart';

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

      final budgets =
          response
              .map<BudgetModel>((json) => BudgetModel.fromSupabaseJson(json))
              .toList();

      // Add spent amount to each budget
      return await _addSpentAmountToBudgets(budgets);
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

      final response =
          await _supabaseClient.client
              .from('budgets')
              .select()
              .eq('budget_id', id)
              .eq('user_id', userId)
              .single();

      final budget = BudgetModel.fromSupabaseJson(response);
      // Calculate spent amount for the budget
      final spent = await _calculateBudgetSpentAmount(budget.budgetId);
      return budget.copyWith(spent: spent);
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

      final budgets =
          response
              .map<BudgetModel>((json) => BudgetModel.fromSupabaseJson(json))
              .toList();

      // Add spent amount to each budget
      return await _addSpentAmountToBudgets(budgets);
    } catch (error) {
      throw Exception('Failed to get active budgets: $error');
    }
  }

  // Helper method to calculate spent amount for a budget
  Future<double> _calculateBudgetSpentAmount(String budgetId) async {
    try {
      // First, get the budget to check if it's an income or expense budget
      final budgetResponse =
          await _supabaseClient.client
              .from('budgets')
              .select('is_saving')
              .eq('budget_id', budgetId)
              .single();

      final isSaving = budgetResponse['is_saving'] as bool? ?? false;

      // Query transactions table for transactions related to this budget
      final response = await _supabaseClient.client
          .from('transactions')
          .select('amount')
          .eq('budget_id', budgetId);

      // Sum up the transaction amounts based on budget type
      double totalSpent = 0;
      for (final transaction in response) {
        // Get the transaction amount
        final amount =
            transaction['amount'] is int
                ? transaction['amount'].toDouble()
                : transaction['amount'] as double;

        // For income budgets (is_saving=true), only count positive transactions
        // For expense budgets (is_saving=false), only count negative transactions
        if (isSaving) {
          // Income budget: count only positive amounts toward the budget
          if (amount > 0) {
            totalSpent += amount;
          }
        } else {
          // Expense budget: count only negative amounts (as positive values) toward the budget
          if (amount < 0) {
            totalSpent += amount.abs();
          }
        }
      }

      return totalSpent;
    } catch (error) {
      return 0.0; // Return 0 on error
    }
  }

  // Helper method to add spent amount to a list of budgets
  Future<List<Budget>> _addSpentAmountToBudgets(
    List<BudgetModel> budgets,
  ) async {
    final result = <Budget>[];

    for (final budget in budgets) {
      final spent = await _calculateBudgetSpentAmount(budget.budgetId);
      result.add(budget.copyWith(spent: spent));
    }

    return result;
  }

  @override
  Future<void> addBudget(Budget budget) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final budgetModel =
          budget is BudgetModel ? budget : BudgetModel.fromEntity(budget);

      // Ensure userId is set
      final Map<String, dynamic> budgetData = budgetModel.toSupabaseJson();
      budgetData['user_id'] = userId;

      await _supabaseClient.client.from('budgets').insert(budgetData);
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

      final budgetModel =
          budget is BudgetModel ? budget : BudgetModel.fromEntity(budget);

      await _supabaseClient.client
          .from('budgets')
          .update(budgetModel.toSupabaseJson())
          .eq('budget_id', budgetModel.budgetId)
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

  @override
  Future<double> calculateBudgetSpentAmount(String budgetId) async {
    return await _calculateBudgetSpentAmount(budgetId);
  }
}
