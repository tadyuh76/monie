import 'package:injectable/injectable.dart';
import '../../domain/entities/account.dart';
import 'package:monie/features/account/domain/repositories/account_repository.dart';

@injectable
class UpdateAccountUseCase {
  final AccountRepository repository;

  UpdateAccountUseCase(this.repository);

  Future<Account> call(Account account) async {
    return await repository.updateAccount(account);
  }
}
