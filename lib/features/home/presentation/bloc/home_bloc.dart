import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/home/domain/usecases/get_accounts_usecase.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {
  const LoadHomeData();
}

class LoadPinnedAccounts extends HomeEvent {
  const LoadPinnedAccounts();
}

class PinAccount extends HomeEvent {
  final String accountId;
  const PinAccount(this.accountId);
  @override
  List<Object?> get props => [accountId];
}

class UnpinAccount extends HomeEvent {
  final String accountId;
  const UnpinAccount(this.accountId);
  @override
  List<Object?> get props => [accountId];
}

// States
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<Account> accounts;
  final List<Transaction> recentTransactions;
  final double totalBalance;
  final double totalExpense;
  final double totalIncome;
  final int transactionCount;
  final Set<String> pinnedAccountIds;

  const HomeLoaded({
    required this.accounts,
    required this.recentTransactions,
    required this.totalBalance,
    required this.totalExpense,
    required this.totalIncome,
    required this.transactionCount,
    required this.pinnedAccountIds,
  });

  List<Account> get pinnedAccounts =>
      accounts.where((a) => pinnedAccountIds.contains(a.id)).toList();

  @override
  List<Object?> get props => [
    accounts,
    recentTransactions,
    totalBalance,
    totalExpense,
    totalIncome,
    transactionCount,
    pinnedAccountIds,
  ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetAccountsUseCase getAccountsUseCase;
  final GetTransactionsUseCase getTransactionsUseCase;

  static const _pinnedKey = 'pinned_account_ids';

  HomeBloc({
    required this.getAccountsUseCase,
    required this.getTransactionsUseCase,
  }) : super(const HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<LoadPinnedAccounts>(_onLoadPinnedAccounts);
    on<PinAccount>(_onPinAccount);
    on<UnpinAccount>(_onUnpinAccount);
  }

  Future<Set<String>> _getPinnedAccountIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pinnedKey)?.toSet() ?? <String>{};
  }

  Future<void> _savePinnedAccountIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pinnedKey, ids.toList());
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    try {
      final accounts = await getAccountsUseCase();
      final transactions = await getTransactionsUseCase();
      final pinnedAccountIds = await _getPinnedAccountIds();

      // Calculate totals
      final totalBalance = accounts.fold<double>(
        0,
        (sum, account) => sum + account.balance,
      );

      // Calculate totals with updated transaction model
      // Positive amounts are income, negative are expenses
      final totalExpense = transactions
          .where((t) => t.amount < 0)
          .fold<double>(0, (sum, t) => sum + t.amount.abs());

      final totalIncome = transactions
          .where((t) => t.amount >= 0)
          .fold<double>(0, (sum, t) => sum + t.amount);

      // Sort transactions by date (newest first) and take only 5
      final recentTransactions =
          transactions..sort((a, b) => b.date.compareTo(a.date));

      final recentTransactionsLimited = recentTransactions.take(5).toList();

      emit(
        HomeLoaded(
          accounts: accounts,
          recentTransactions: recentTransactionsLimited,
          totalBalance: totalBalance,
          totalExpense: totalExpense,
          totalIncome: totalIncome,
          transactionCount: transactions.length,
          pinnedAccountIds: pinnedAccountIds,
        ),
      );
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onLoadPinnedAccounts(
    LoadPinnedAccounts event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;
      final pinnedAccountIds = await _getPinnedAccountIds();
      emit(current.copyWith(pinnedAccountIds: pinnedAccountIds));
    }
  }

  Future<void> _onPinAccount(
    PinAccount event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;
      final newPinned = Set<String>.from(current.pinnedAccountIds)..add(event.accountId);
      await _savePinnedAccountIds(newPinned);
      emit(current.copyWith(pinnedAccountIds: newPinned));
    }
  }

  Future<void> _onUnpinAccount(
    UnpinAccount event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;
      final newPinned = Set<String>.from(current.pinnedAccountIds)..remove(event.accountId);
      await _savePinnedAccountIds(newPinned);
      emit(current.copyWith(pinnedAccountIds: newPinned));
    }
  }
}

extension HomeLoadedCopyWith on HomeLoaded {
  HomeLoaded copyWith({
    List<Account>? accounts,
    List<Transaction>? recentTransactions,
    double? totalBalance,
    double? totalExpense,
    double? totalIncome,
    int? transactionCount,
    Set<String>? pinnedAccountIds,
  }) {
    return HomeLoaded(
      accounts: accounts ?? this.accounts,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      totalBalance: totalBalance ?? this.totalBalance,
      totalExpense: totalExpense ?? this.totalExpense,
      totalIncome: totalIncome ?? this.totalIncome,
      transactionCount: transactionCount ?? this.transactionCount,
      pinnedAccountIds: pinnedAccountIds ?? this.pinnedAccountIds,
    );
  }
}
