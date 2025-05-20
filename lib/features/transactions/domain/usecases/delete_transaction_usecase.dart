import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';

@injectable
class DeleteTransactionUseCase {
  final TransactionRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<bool> call(String transactionId) async {
    return await repository.deleteTransaction(transactionId);
  }
}
