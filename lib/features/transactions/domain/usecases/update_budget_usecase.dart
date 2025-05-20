import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/budget.dart';
import 'package:monie/features/transactions/domain/repositories/budget_repository.dart';

@injectable
class UpdateBudgetUseCase {
  final BudgetRepository repository;

  UpdateBudgetUseCase(this.repository);

  Future<Budget> call(Budget budget) async {
    return await repository.updateBudget(budget);
  }
}
