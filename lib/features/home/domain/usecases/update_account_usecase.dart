import 'package:injectable/injectable.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

@injectable
class UpdateAccountUseCase {
  final AccountRepository repository;

  UpdateAccountUseCase(this.repository);

  Future<Account> call(Account account) async {
    return await repository.updateAccount(account);
  }
}
