import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/home/domain/usecases/add_account_usecase.dart';
import 'package:monie/features/home/domain/usecases/delete_account_usecase.dart';
import 'package:monie/features/home/domain/usecases/get_accounts_usecase.dart';
import 'package:monie/features/home/domain/usecases/update_account_usecase.dart';

// Events
abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class AddAccountEvent extends AccountEvent {
  final Account account;

  const AddAccountEvent({required this.account});

  @override
  List<Object?> get props => [account];
}

class GetAccountsEvent extends AccountEvent {
  final String userId;
  const GetAccountsEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UpdateAccountEvent extends AccountEvent {
  final Account account;

  const UpdateAccountEvent({required this.account});

  @override
  List<Object?> get props => [account];
}

class DeleteAccountEvent extends AccountEvent {
  final Account account;

  const DeleteAccountEvent({required this.account});

  @override
  List<Object?> get props => [account];
}

// States
abstract class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {}

class AddAccountState extends AccountState {
  final Account account;

  const AddAccountState({required this.account});

  @override
  List<Object?> get props => [account];
}

class UpdateAccountState extends AccountState {
  final List<Account> accounts;

  const UpdateAccountState({required this.accounts});

  @override
  List<Object?> get props => [accounts];
}

class GetAccountsState extends AccountState {
  final List<Account> accounts;

  const GetAccountsState({required this.accounts});

  @override
  List<Object?> get props => [accounts];
}

class DeleteAccountState extends AccountState {
  final List<Account> accounts;

  const DeleteAccountState({required this.accounts});

  @override
  List<Object?> get props => [accounts];
}

class Loading extends AccountState {
  const Loading();
}

class Error extends AccountState {
  final String message;

  const Error(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
@injectable
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final GetAccountsUseCase getAccountsUseCase;
  final AddAccountUseCase addAccountUseCase;
  final UpdateAccountUseCase updateAccountUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;

  AccountBloc({
    required this.getAccountsUseCase,
    required this.addAccountUseCase,
    required this.updateAccountUseCase,
    required this.deleteAccountUseCase,
  }) : super(AccountInitial()) {
    on<GetAccountsEvent>(_getAccounts);
    on<AddAccountEvent>(_addAccount);
    on<UpdateAccountEvent>(_updateAccount);
    on<DeleteAccountEvent>(_deleteAccount);
  }

  Future<void> _getAccounts(
    GetAccountsEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(const Loading());
    try {
      final accounts = await getAccountsUseCase(event.userId);
      emit(GetAccountsState(accounts: accounts));
    } catch (e) {
      emit(Error(e.toString()));
    }
  }

  Future<void> _addAccount(
    AddAccountEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(const Loading());
    try {
      // Add to repository
      await addAccountUseCase(event.account);
      emit(AddAccountState(account: event.account));
    } catch (e) {
      emit(Error(e.toString()));
    }
  }

  Future<void> _updateAccount(
    UpdateAccountEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(const Loading());
    try {
      // Add to repository
      await updateAccountUseCase(event.account);
      final accounts = await getAccountsUseCase(event.account.userId);
      emit(UpdateAccountState(accounts: accounts));
    } catch (e) {
      emit(Error(e.toString()));
    }
  }

  Future<void> _deleteAccount(
    DeleteAccountEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(const Loading());
    try {
      // Add to repository
      await deleteAccountUseCase(event.account.accountId!);
      final accounts = await getAccountsUseCase(event.account.userId);
      emit(DeleteAccountState(accounts: accounts));
    } catch (e) {
      emit(Error(e.toString()));
    }
  }
}
