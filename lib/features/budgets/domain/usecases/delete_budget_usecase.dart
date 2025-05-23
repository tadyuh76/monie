import 'package:injectable/injectable.dart';
import 'package:monie/features/budgets/domain/repositories/budget_repository.dart';

@injectable
class DeleteBudgetUseCase {
  final BudgetRepository repository;

  DeleteBudgetUseCase(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteBudget(id);
  }
} 