import 'package:injectable/injectable.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/domain/repositories/budget_repository.dart';

@injectable
class GetBudgetsUseCase {
  final BudgetRepository repository;

  GetBudgetsUseCase(this.repository);

  Future<List<Budget>> call() async {
    return await repository.getBudgets();
  }
}
