import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/budget.dart';
import 'package:monie/features/transactions/domain/repositories/budget_repository.dart';

@injectable
class GetBudgetsUseCase {
  final BudgetRepository repository;

  GetBudgetsUseCase(this.repository);

  Future<List<Budget>> call(String userId) async {
    return await repository.getBudgets(userId);
  }
}
