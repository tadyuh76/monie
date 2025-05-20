import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/budget.dart';
import 'package:monie/features/transactions/domain/repositories/budget_repository.dart';

@injectable
class GetBudgetByIdUseCase {
  final BudgetRepository repository;

  GetBudgetByIdUseCase(this.repository);

  Future<Budget?> call(String budgetId) async {
    return await repository.getBudgetById(budgetId);
  }
}
