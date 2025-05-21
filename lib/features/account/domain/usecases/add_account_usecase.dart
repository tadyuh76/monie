import 'package:injectable/injectable.dart';
import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/account/domain/repositories/account_repository.dart';

@injectable
class AddAccountUseCase {
  final AccountRepository repository;

  AddAccountUseCase(this.repository);

  Future<Account> call(Account account) async {
    return await repository.createAccount(account);
  }
}
