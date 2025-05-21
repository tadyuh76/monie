import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/account/domain/usecases/get_accounts_usecase.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_usecase.dart';

// Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {
  final String userId;
  const LoadHomeData(this.userId);

  @override
  List<Object?> get props => [userId];
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

  const HomeLoaded({
    required this.accounts,
    required this.recentTransactions,
    required this.totalBalance,
    required this.totalExpense,
    required this.totalIncome,
    required this.transactionCount,
  });

  @override
  List<Object?> get props => [
    accounts,
    recentTransactions,
    totalBalance,
    totalExpense,
    totalIncome,
    transactionCount,
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
  final GetAccountsUseCase _getAccountsUseCase;
  final GetTransactionsUseCase _getTransactionsUseCase;

  HomeBloc({
    required GetAccountsUseCase getAccountsUseCase,
    required GetTransactionsUseCase getTransactionsUseCase,
  }) : _getAccountsUseCase = getAccountsUseCase,
       _getTransactionsUseCase = getTransactionsUseCase,
       super(const HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    try {
      final accounts = await _getAccountsUseCase(event.userId);
      final transactions = await _getTransactionsUseCase(event.userId);

      // Calculate totals
      final totalBalance = accounts.fold<double>(
        0,
        (sum, account) => sum + (account.balance),
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
        ),
      );
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
