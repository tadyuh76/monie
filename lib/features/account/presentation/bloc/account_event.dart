import 'package:equatable/equatable.dart';
import 'package:monie/features/account/domain/entities/account.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class LoadAccountsEvent extends AccountEvent {
  final String userId;

  const LoadAccountsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadAccountByIdEvent extends AccountEvent {
  final String accountId;

  const LoadAccountByIdEvent(this.accountId);

  @override
  List<Object?> get props => [accountId];
}

class CreateAccountEvent extends AccountEvent {
  final Account account;

  const CreateAccountEvent(this.account);

  @override
  List<Object?> get props => [account];
}

class UpdateAccountEvent extends AccountEvent {
  final Account account;

  const UpdateAccountEvent(this.account);

  @override
  List<Object?> get props => [account];
}

class DeleteAccountEvent extends AccountEvent {
  final String accountId;

  const DeleteAccountEvent(this.accountId);

  @override
  List<Object?> get props => [accountId];
}

class UpdateAccountBalanceEvent extends AccountEvent {
  final String accountId;
  final double amount;

  const UpdateAccountBalanceEvent({
    required this.accountId,
    required this.amount,
  });

  @override
  List<Object?> get props => [accountId, amount];
}

class RecalculateAccountBalanceEvent extends AccountEvent {
  final String accountId;

  const RecalculateAccountBalanceEvent(this.accountId);

  @override
  List<Object?> get props => [accountId];
}
