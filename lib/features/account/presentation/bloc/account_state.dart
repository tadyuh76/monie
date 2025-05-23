import 'package:equatable/equatable.dart';
import 'package:monie/features/account/domain/entities/account.dart';

abstract class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {}

class AccountLoading extends AccountState {}

class AccountsLoaded extends AccountState {
  final List<Account> accounts;

  const AccountsLoaded(this.accounts);

  @override
  List<Object?> get props => [accounts];
}

class AccountLoaded extends AccountState {
  final Account account;

  const AccountLoaded(this.account);

  @override
  List<Object?> get props => [account];
}

class AccountCreated extends AccountState {
  final Account account;

  const AccountCreated(this.account);

  @override
  List<Object?> get props => [account];
}

class AccountUpdated extends AccountState {
  final Account account;

  const AccountUpdated(this.account);

  @override
  List<Object?> get props => [account];
}

class AccountDeleted extends AccountState {
  final String accountId;

  const AccountDeleted(this.accountId);

  @override
  List<Object?> get props => [accountId];
}

class AccountBalanceUpdated extends AccountState {
  final String accountId;
  final double newBalance;

  const AccountBalanceUpdated({
    required this.accountId,
    required this.newBalance,
  });

  @override
  List<Object?> get props => [accountId, newBalance];
}

class AccountBalanceRecalculated extends AccountState {
  final Account account;

  const AccountBalanceRecalculated(this.account);

  @override
  List<Object?> get props => [account];
}

class AccountError extends AccountState {
  final String message;

  const AccountError(this.message);

  @override
  List<Object?> get props => [message];
}
