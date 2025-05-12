import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';

@injectable
class AddTransactionUseCase {
  final TransactionRepository repository;

  AddTransactionUseCase(this.repository);

  Future<void> call(Transaction transaction) async {
    return await repository.addTransaction(transaction);
  }
}
