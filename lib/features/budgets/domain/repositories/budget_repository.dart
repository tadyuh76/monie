import 'package:monie/features/budgets/domain/entities/budget.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getBudgets();
  Future<Budget> getBudgetById(String id);
  Future<List<Budget>> getActiveBudgets();
  Future<void> addBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String id);
  Future<double> calculateBudgetSpentAmount(String budgetId);
}
