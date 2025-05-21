import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/features/account/domain/usecases/add_account_usecase.dart';
import 'package:monie/features/account/domain/usecases/delete_account_usecase.dart';
import 'package:monie/features/account/domain/usecases/get_account_by_id_usecase.dart';
import 'package:monie/features/account/domain/usecases/get_accounts_usecase.dart';
import 'package:monie/features/account/domain/usecases/recalculate_account_balance_usecase.dart';
import 'package:monie/features/account/domain/usecases/update_account_balance_usecase.dart';
import 'package:monie/features/account/domain/usecases/update_account_usecase.dart';
import 'package:monie/features/account/presentation/bloc/account_event.dart';
import 'package:monie/features/account/presentation/bloc/account_state.dart';

@injectable
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final GetAccountsUseCase getAccounts;
  final GetAccountByIdUseCase getAccountById;
  final AddAccountUseCase addAccount;
  final UpdateAccountUseCase updateAccount;
  final DeleteAccountUseCase deleteAccount;
  final UpdateAccountBalanceUseCase updateAccountBalance;
  final RecalculateAccountBalanceUseCase recalculateAccountBalance;

  AccountBloc({
    required this.getAccounts,
    required this.getAccountById,
    required this.addAccount,
    required this.updateAccount,
    required this.deleteAccount,
    required this.updateAccountBalance,
    required this.recalculateAccountBalance,
  }) : super(AccountInitial()) {
    on<LoadAccountsEvent>(_onLoadAccounts);
    on<LoadAccountByIdEvent>(_onLoadAccountById);
    on<CreateAccountEvent>(_onCreateAccount);
    on<UpdateAccountEvent>(_onUpdateAccount);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<UpdateAccountBalanceEvent>(_onUpdateAccountBalance);
    on<RecalculateAccountBalanceEvent>(_onRecalculateAccountBalance);
  }

  Future<void> _onLoadAccounts(
    LoadAccountsEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    try {
      final accounts = await getAccounts(event.userId);
      emit(AccountsLoaded(accounts));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onLoadAccountById(
    LoadAccountByIdEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    try {
      final account = await getAccountById(event.accountId);
      if (account != null) {
        emit(AccountLoaded(account));
      } else {
        emit(const AccountError('Account not found'));
      }
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onCreateAccount(
    CreateAccountEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    try {
      final account = await addAccount(event.account);
      emit(AccountCreated(account));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onUpdateAccount(
    UpdateAccountEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    try {
      final account = await updateAccount(event.account);
      emit(AccountUpdated(account));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    try {
      await deleteAccount(event.accountId);
      emit(AccountDeleted(event.accountId));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onUpdateAccountBalance(
    UpdateAccountBalanceEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    try {
      final account = await updateAccountBalance(event.accountId, event.amount);
      emit(
        AccountBalanceUpdated(
          accountId: event.accountId,
          newBalance: account.balance,
        ),
      );
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onRecalculateAccountBalance(
    RecalculateAccountBalanceEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    try {
      final success = await recalculateAccountBalance(event.accountId);
      if (success) {
        // After recalculating, fetch the updated account
        final account = await getAccountById(event.accountId);
        if (account != null) {
          emit(AccountBalanceRecalculated(account));
        } else {
          emit(const AccountError('Account not found after recalculation'));
        }
      } else {
        emit(const AccountError('Failed to recalculate account balance'));
      }
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }
}
