import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';

@injectable
class GetTransactionByIdUseCase {
  final TransactionRepository repository;

  GetTransactionByIdUseCase(this.repository);

  Future<Transaction> call(String id) async {
    return await repository.getTransactionById(id);
  }
}
