import 'package:injectable/injectable.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/home/domain/repositories/account_repository.dart';

@injectable
class AddAccountUseCase {
  final AccountRepository repository;

  AddAccountUseCase(this.repository);

  Future<void> call(Account account) async {
    return await repository.addAccount(account);
  }
}
