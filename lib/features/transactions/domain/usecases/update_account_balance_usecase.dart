import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/repositories/account_repository.dart';

@injectable
class UpdateAccountBalanceUseCase {
  final AccountRepository repository;

  UpdateAccountBalanceUseCase(this.repository);

  Future<bool> call(String accountId, double amount) async {
    return await repository.updateAccountBalance(accountId, amount);
  }
}
