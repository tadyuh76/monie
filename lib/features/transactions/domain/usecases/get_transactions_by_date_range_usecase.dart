import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';

@injectable
class GetTransactionsByDateRangeUseCase {
  final TransactionRepository repository;

  GetTransactionsByDateRangeUseCase(this.repository);

  Future<List<Transaction>> call({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await repository.getTransactionsByDateRange(userId, startDate, endDate);
  }
}
