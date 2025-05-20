import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getBudgets(String userId);
  Future<Budget?> getBudgetById(String budgetId);
  Future<Budget> createBudget(Budget budget);
  Future<Budget> updateBudget(Budget budget);
  Future<bool> deleteBudget(String budgetId);
}
