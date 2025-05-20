import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/repositories/budget_repository.dart';

@injectable
class DeleteBudgetUseCase {
  final BudgetRepository repository;

  DeleteBudgetUseCase(this.repository);

  Future<bool> call(String budgetId) async {
    return await repository.deleteBudget(budgetId);
  }
}
