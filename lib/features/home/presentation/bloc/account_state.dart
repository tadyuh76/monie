// import 'package:equatable/equatable.dart';
// import 'package:monie/features/home/domain/entities/account.dart';

// /// Base state class for account management
// abstract class AccountState extends Equatable {
//   const AccountState();

//   @override
//   List<Object?> get props => [];
// }

// /// Initial state
// class AccountInitial extends AccountState {}

// /// Loading state
// class AccountLoading extends AccountState {}

// /// State when accounts are loaded successfully
// class AccountsLoaded extends AccountState {
//   final List<Account> accounts;

//   const AccountsLoaded(this.accounts);

//   @override
//   List<Object?> get props => [accounts];
// }

// /// State when a single account operation is completed
// class AccountOperationSuccess extends AccountState {
//   final Account? account;
//   final String message;

//   const AccountOperationSuccess({this.account, required this.message});

//   @override
//   List<Object?> get props => [account, message];
// }

// /// Error state
// class AccountError extends AccountState {
//   final String message;

//   const AccountError(this.message);

//   @override
//   List<Object?> get props => [message];
// }
