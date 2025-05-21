import 'package:injectable/injectable.dart';
import 'package:monie/features/account/domain/repositories/account_repository.dart';
// import 'package:monie/features/transactions/domain/repositories/account_repository.dart';

@injectable
class RecalculateAccountBalanceUseCase {
  final AccountRepository repository;

  RecalculateAccountBalanceUseCase(this.repository);

  Future<bool> call(String accountId) async {
    return await repository.recalculateAccountBalance(accountId);
  }
}
