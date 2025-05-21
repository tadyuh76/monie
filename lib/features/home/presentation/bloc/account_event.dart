// import 'package:equatable/equatable.dart';
// import 'package:monie/features/home/domain/entities/account.dart';

// /// Base event class for account management
// abstract class AccountEvent extends Equatable {
//   const AccountEvent();

//   @override
//   List<Object?> get props => [];
// }

// /// Event to load all accounts for a user
// class LoadAccounts extends AccountEvent {
//   final String userId;

//   const LoadAccounts(this.userId);

//   @override
//   List<Object?> get props => [userId];
// }

// /// Event to create a new account
// class CreateAccount extends AccountEvent {
//   final Account account;

//   const CreateAccount(this.account);

//   @override
//   List<Object?> get props => [account];
// }

// /// Event to update an existing account
// class UpdateAccount extends AccountEvent {
//   final Account account;

//   const UpdateAccount(this.account);

//   @override
//   List<Object?> get props => [account];
// }

// /// Event to delete an account
// class DeleteAccount extends AccountEvent {
//   final String accountId;

//   const DeleteAccount(this.accountId);

//   @override
//   List<Object?> get props => [accountId];
// }

// /// Event to toggle account archive status
// class ToggleArchiveAccount extends AccountEvent {
//   final String accountId;
//   final bool archived;

//   const ToggleArchiveAccount(this.accountId, this.archived);

//   @override
//   List<Object?> get props => [accountId, archived];
// }

// /// Event to toggle account pin status
// class TogglePinAccount extends AccountEvent {
//   final String accountId;
//   final bool pinned;

//   const TogglePinAccount(this.accountId, this.pinned);

//   @override
//   List<Object?> get props => [accountId, pinned];
// }

// /// Event to update account balance
// class UpdateAccountBalance extends AccountEvent {
//   final String accountId;
//   final double newBalance;

//   const UpdateAccountBalance(this.accountId, this.newBalance);

//   @override
//   List<Object?> get props => [accountId, newBalance];
// }
