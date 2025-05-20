import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/account.dart';
import 'package:monie/features/transactions/domain/repositories/account_repository.dart';

@injectable
class UpdateAccountUseCase {
  final AccountRepository repository;

  UpdateAccountUseCase(this.repository);

  Future<Account> call(Account account) async {
    return await repository.updateAccount(account);
  }
}
