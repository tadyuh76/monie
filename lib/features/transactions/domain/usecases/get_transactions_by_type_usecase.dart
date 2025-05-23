import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';

@injectable
class GetTransactionsByTypeUseCase {
  final TransactionRepository repository;

  GetTransactionsByTypeUseCase(this.repository);

  Future<List<Transaction>> call(String userId, String type) async {
    return await repository.getTransactionsByType(userId, type);
  }
}
