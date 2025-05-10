import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_usecase.dart';

// Events
abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionsEvent {
  const LoadTransactions();
}

class FilterTransactionsByType extends TransactionsEvent {
  final String? type;

  const FilterTransactionsByType(this.type);

  @override
  List<Object?> get props => [type];
}

class FilterTransactionsByMonth extends TransactionsEvent {
  final DateTime month;

  const FilterTransactionsByMonth(this.month);

  @override
  List<Object?> get props => [month];
}

// States
abstract class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {
  const TransactionsInitial();
}

class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();
}

class TransactionsLoaded extends TransactionsState {
  final List<Transaction> transactions;
  final double totalExpense;
  final double totalIncome;
  final double netAmount;
  final String? activeFilter;
  final DateTime? selectedMonth;

  const TransactionsLoaded({
    required this.transactions,
    required this.totalExpense,
    required this.totalIncome,
    required this.netAmount,
    this.activeFilter,
    this.selectedMonth,
  });

  @override
  List<Object?> get props => [
    transactions,
    totalExpense,
    totalIncome,
    netAmount,
    activeFilter,
    selectedMonth,
  ];
}

class TransactionsError extends TransactionsState {
  final String message;

  const TransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
@injectable
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final GetTransactionsUseCase getTransactionsUseCase;
  List<Transaction> _allTransactions = [];
  String? _activeFilter;
  DateTime? _selectedMonth;

  TransactionsBloc({required this.getTransactionsUseCase})
    : super(const TransactionsInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<FilterTransactionsByType>(_onFilterTransactionsByType);
    on<FilterTransactionsByMonth>(_onFilterTransactionsByMonth);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(const TransactionsLoading());

    try {
      _allTransactions = await getTransactionsUseCase();
      _emitLoadedState(emit);
    } catch (e) {
      emit(TransactionsError(e.toString()));
    }
  }

  Future<void> _onFilterTransactionsByType(
    FilterTransactionsByType event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(const TransactionsLoading());
    _activeFilter = event.type;
    _emitLoadedState(emit);
  }

  Future<void> _onFilterTransactionsByMonth(
    FilterTransactionsByMonth event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(const TransactionsLoading());
    _selectedMonth = event.month;
    _emitLoadedState(emit);
  }

  void _emitLoadedState(Emitter<TransactionsState> emit) {
    List<Transaction> filteredTransactions = _allTransactions;

    // Filter by type if active
    if (_activeFilter != null) {
      filteredTransactions =
          filteredTransactions.where((t) => t.type == _activeFilter).toList();
    }

    // Filter by month if selected
    if (_selectedMonth != null) {
      filteredTransactions =
          filteredTransactions
              .where(
                (t) =>
                    t.date.month == _selectedMonth!.month &&
                    t.date.year == _selectedMonth!.year,
              )
              .toList();
    }

    // Sort by date (newest first)
    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals
    final totalExpense = filteredTransactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalIncome = filteredTransactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, t) => sum + t.amount);

    emit(
      TransactionsLoaded(
        transactions: filteredTransactions,
        totalExpense: totalExpense,
        totalIncome: totalIncome,
        netAmount: totalIncome - totalExpense,
        activeFilter: _activeFilter,
        selectedMonth: _selectedMonth,
      ),
    );
  }
}
