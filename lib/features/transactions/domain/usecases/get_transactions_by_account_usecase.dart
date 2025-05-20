import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';

@injectable
class GetTransactionsByAccountUseCase {
  final TransactionRepository repository;

  GetTransactionsByAccountUseCase(this.repository);

  Future<List<Transaction>> call(String accountId) async {
    return await repository.getTransactionsByAccount(accountId);
  }
}
