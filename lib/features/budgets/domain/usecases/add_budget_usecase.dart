import 'package:injectable/injectable.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/domain/repositories/budget_repository.dart';

@injectable
class AddBudgetUseCase {
  final BudgetRepository repository;

  AddBudgetUseCase(this.repository);

  Future<void> call(Budget budget) async {
    return await repository.addBudget(budget);
  }
} 