import 'package:injectable/injectable.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/domain/repositories/budget_repository.dart';

@injectable
class UpdateBudgetUseCase {
  final BudgetRepository repository;

  UpdateBudgetUseCase(this.repository);

  Future<void> call(Budget budget) async {
    return await repository.updateBudget(budget);
  }
} 