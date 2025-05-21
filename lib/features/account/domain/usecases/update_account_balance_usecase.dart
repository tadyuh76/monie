import 'package:injectable/injectable.dart';
import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/account/domain/repositories/account_repository.dart';

@injectable
class UpdateAccountBalanceUseCase {
  final AccountRepository repository;

  UpdateAccountBalanceUseCase(this.repository);

  Future<Account> call(String accountId, double newBalance) async {
    // The repository's updateBalance method might need to be adjusted
    // if it currently returns void or bool instead of Account
    return await repository.updateBalance(accountId, newBalance);
  }
}
