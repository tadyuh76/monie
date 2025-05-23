import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';

@injectable
class GetTransactionsByBudgetUseCase {
  final TransactionRepository repository;

  GetTransactionsByBudgetUseCase(this.repository);

  Future<List<Transaction>> call(String budgetId) async {
    return await repository.getTransactionsByBudget(budgetId);
  }
}
