import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/budget.dart';
import 'package:monie/features/transactions/domain/repositories/budget_repository.dart';

@injectable
class CreateBudgetUseCase {
  final BudgetRepository repository;

  CreateBudgetUseCase(this.repository);

  Future<Budget> call(Budget budget) async {
    return await repository.createBudget(budget);
  }
}
