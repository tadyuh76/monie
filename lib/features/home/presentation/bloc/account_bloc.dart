import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

// Events
abstract class AccountEvent {}

class LoadAccounts extends AccountEvent {
  final String userId;
  LoadAccounts(this.userId);
}

class CreateAccount extends AccountEvent {
  final Account account;
  CreateAccount(this.account);
}

class UpdateAccount extends AccountEvent {
  final Account account;
  UpdateAccount(this.account);
}

class DeleteAccount extends AccountEvent {
  final String accountId;
  DeleteAccount(this.accountId);
}

class ToggleArchiveAccount extends AccountEvent {
  final String accountId;
  final bool archived;
  ToggleArchiveAccount(this.accountId, this.archived);
}

class TogglePinAccount extends AccountEvent {
  final String accountId;
  final bool pinned;
  TogglePinAccount(this.accountId, this.pinned);
}

class UpdateAccountBalance extends AccountEvent {
  final String accountId;
  final double newBalance;
  UpdateAccountBalance(this.accountId, this.newBalance);
}

// States
abstract class AccountState {}

class AccountInitial extends AccountState {}

class AccountLoading extends AccountState {}

class AccountsLoaded extends AccountState {
  final List<Account> accounts;
  AccountsLoaded(this.accounts);
}

class AccountOperationSuccess extends AccountState {
  final Account? account;
  final String message;
  AccountOperationSuccess({this.account, required this.message});
}

class AccountError extends AccountState {
  final String message;
  AccountError(this.message);
}

/// BLoC for managing account-related state and events
@injectable
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository _repository;

  AccountBloc(this._repository) : super(AccountInitial()) {
    on<LoadAccounts>(_onLoadAccounts);
    on<CreateAccount>(_onCreateAccount);
    on<UpdateAccount>(_onUpdateAccount);
    on<DeleteAccount>(_onDeleteAccount);
    on<ToggleArchiveAccount>(_onToggleArchiveAccount);
    on<TogglePinAccount>(_onTogglePinAccount);
    on<UpdateAccountBalance>(_onUpdateAccountBalance);
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(AccountLoading());
      final accounts = await _repository.getAccounts(event.userId);
      emit(AccountsLoaded(accounts));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onCreateAccount(
    CreateAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(AccountLoading());
      final account = await _repository.createAccount(event.account);
      emit(
        AccountOperationSuccess(
          account: account,
          message: 'Account created successfully',
        ),
      );
      add(LoadAccounts(event.account.userId));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onUpdateAccount(
    UpdateAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(AccountLoading());
      final account = await _repository.updateAccount(event.account);
      emit(
        AccountOperationSuccess(
          account: account,
          message: 'Account updated successfully',
        ),
      );
      add(LoadAccounts(event.account.userId));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(AccountLoading());
      await _repository.deleteAccount(event.accountId);
      emit(AccountOperationSuccess(message: 'Account deleted successfully'));
      // Note: LoadAccounts event should be added by the UI layer since we don't have userId here
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onToggleArchiveAccount(
    ToggleArchiveAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(AccountLoading());
      final account = await _repository.toggleArchiveAccount(
        event.accountId,
        event.archived,
      );
      emit(
        AccountOperationSuccess(
          account: account,
          message:
              'Account ${event.archived ? 'archived' : 'unarchived'} successfully',
        ),
      );
      // Note: LoadAccounts event should be added by the UI layer since we don't have userId here
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onTogglePinAccount(
    TogglePinAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(AccountLoading());
      final account = await _repository.togglePinAccount(
        event.accountId,
        event.pinned,
      );
      emit(
        AccountOperationSuccess(
          account: account,
          message:
              'Account ${event.pinned ? 'pinned' : 'unpinned'} successfully',
        ),
      );
      // Note: LoadAccounts event should be added by the UI layer since we don't have userId here
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onUpdateAccountBalance(
    UpdateAccountBalance event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(AccountLoading());
      final account = await _repository.updateBalance(
        event.accountId,
        event.newBalance,
      );
      emit(
        AccountOperationSuccess(
          account: account,
          message: 'Account balance updated successfully',
        ),
      );
      // Note: LoadAccounts event should be added by the UI layer since we don't have userId here
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }
}
