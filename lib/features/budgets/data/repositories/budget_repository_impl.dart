import 'package:injectable/injectable.dart';
import 'package:monie/core/utils/mock_data.dart';
import 'package:monie/features/budgets/data/models/budget_model.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/domain/repositories/budget_repository.dart';

@Injectable(as: BudgetRepository)
class BudgetRepositoryImpl implements BudgetRepository {
  @override
  Future<List<Budget>> getBudgets() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.budgets;
  }

  @override
  Future<Budget> getBudgetById(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    final budget = MockData.budgets.firstWhere(
      (budget) => budget.id == id,
      orElse: () => throw Exception('Budget not found'),
    );

    return budget;
  }

  @override
  Future<List<Budget>> getActiveBudgets() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Filter to get only active budgets (where end date is in the future)
    final now = DateTime.now();
    final activeBudgets =
        MockData.budgets
            .where((budget) => budget.endDate.isAfter(now))
            .toList();

    return activeBudgets;
  }

  @override
  Future<void> addBudget(Budget budget) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    final budgetModel = BudgetModel.fromEntity(budget);
    MockData.budgets.add(budgetModel);
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    final index = MockData.budgets.indexWhere((b) => b.id == budget.id);

    if (index >= 0) {
      MockData.budgets[index] = BudgetModel.fromEntity(budget);
    } else {
      throw Exception('Budget not found');
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));

    MockData.budgets.removeWhere((budget) => budget.id == id);
  }
}
