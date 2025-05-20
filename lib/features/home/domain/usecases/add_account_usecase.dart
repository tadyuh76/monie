import 'package:injectable/injectable.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

@injectable
class AddAccountUseCase {
  final AccountRepository repository;

  AddAccountUseCase(this.repository);

  Future<Account> call(Account account) async {
    return await repository.createAccount(account);
  }
}
