import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/account/presentation/bloc/account_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/budgets/presentation/pages/budgets_page.dart';
import 'package:monie/features/groups/presentation/pages/groups_page.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';
import 'package:monie/features/home/presentation/pages/home_page.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:monie/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:monie/features/transactions/presentation/pages/transactions_page.dart';
import 'package:monie/features/transactions/presentation/widgets/add_transaction_form.dart';
import 'package:monie/main.dart'; // Import for rootScaffoldMessengerKey
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';

// Global key for accessing MainScreen state from anywhere
// Using a global key without exposing the private type
final GlobalKey<State<MainScreen>> mainScreenKey =
    GlobalKey<State<MainScreen>>();

// Navigate to a specific tab in the MainScreen
void navigateToTab(int tabIndex) {
  final state = mainScreenKey.currentState;
  if (state != null && state is _MainScreenState) {
    state.switchTab(tabIndex);
  }
}

class MainScreen extends StatefulWidget {
  // Cannot use const constructor with a global key
  MainScreen({Key? key}) : super(key: mainScreenKey);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Public method that can be used via mainScreenKey to switch tabs
  void switchTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Private method for internal use
  void _switchTab(int index) => switchTab(index);

  // Use a getter for screens to rebuild them each time they're accessed
  List<Widget> get _screens => [
    const HomePage(),
    const TransactionsPage(),
    const BudgetsPage(),
    const GroupsPage(),
  ];

  // Global method to show snackbars
  void _showGlobalSnackBar(
    String message, {
    Color backgroundColor = Colors.black,
  }) {
    // Clear any existing snackbars first
    rootScaffoldMessengerKey.currentState?.clearSnackBars();

    // Show the new snackbar at the very bottom of the screen
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: backgroundColor,
        behavior:
            SnackBarBehavior.fixed, // Use fixed behavior for bottom display
        duration: const Duration(seconds: 3),
        // Remove shape and margin properties to get the default bottom behavior
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // When user is signed out, the AuthWrapper will handle navigation
            // This ensures consistent behavior across the app
          },
        ),
        BlocListener<TransactionsBloc, TransactionsState>(
          listenWhen: (previous, current) {
            return true; // Listen to all state changes
          },
          listener: (context, state) {
            if (state is TransactionActionInProgress) {
              // Do nothing, transaction is in progress
            } else if (state is TransactionActionSuccess) {
              // Transaction action successful, reload data
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                // Reload all transactions first
                context.read<TransactionsBloc>().add(
                  LoadTransactions(userId: authState.user.id),
                );

                // Also reload the home page data
                context.read<HomeBloc>().add(LoadHomeData(authState.user.id));

                // And reload the TransactionBloc data to keep both synced
                context.read<TransactionBloc>().add(
                  LoadTransactionsEvent(authState.user.id),
                );
              }
            } else if (state is TransactionsError) {
              // Show error globally
              _showGlobalSnackBar(state.message, backgroundColor: Colors.red);
            }
          },
        ),
        // Add listener for TransactionBloc
        BlocListener<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionCreated || state is TransactionUpdated) {
              // Transaction created or updated - reload home data
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                context.read<HomeBloc>().add(LoadHomeData(authState.user.id));
              }
            }
          },
        ),
      ],
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black, width: 0.5)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _switchTab,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: 'Transactions',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pie_chart_rounded),
                  label: 'Budgets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group),
                  label: 'Expense Group',
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddTransactionModal(context);
          },
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          foregroundColor: AppColors.background,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  void _showAddTransactionModal(BuildContext context) {
    // Get blocs from parent context before opening modal
    final transactionsBloc = BlocProvider.of<TransactionsBloc>(context);
    final transactionBloc = BlocProvider.of<TransactionBloc>(context);
    final authBloc = BlocProvider.of<AuthBloc>(context);
    final categoriesBloc = BlocProvider.of<CategoriesBloc>(context);
    final accountBloc = BlocProvider.of<AccountBloc>(context);
    final budgetsBloc = BlocProvider.of<BudgetsBloc>(context);

    // Get auth state
    final authState = authBloc.state;

    // Show error message using global snackbar
    void showLoadingError(String message) {
      _showGlobalSnackBar(message, backgroundColor: Colors.red);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: transactionsBloc),
            BlocProvider.value(value: transactionBloc),
            BlocProvider.value(value: categoriesBloc),
            BlocProvider.value(value: accountBloc),
            BlocProvider.value(value: budgetsBloc),
          ],
          child: AddTransactionForm(
            onSubmit: (Map<String, dynamic> transaction) async {
              // Use a try-catch block to handle any errors gracefully
              try {
                if (authState is Authenticated) {
                  // Create transaction object
                  final newTransaction = Transaction(
                    transactionId: transaction['id'],
                    userId: authState.user.id,
                    title: transaction['title'],
                    amount: transaction['amount'],
                    description: transaction['description'] ?? '',
                    date: DateTime.parse(transaction['date']),
                    categoryName: transaction['category_name'],
                    color: transaction['category_color'],
                    accountId: transaction['account_id'],
                    budgetId: transaction['budget_id'],
                  );

                  // Create and add CreateTransactionEvent to the TransactionBloc only
                  // This will create a single transaction
                  final createTransactionEvent = CreateTransactionEvent(
                    newTransaction,
                  );
                  transactionBloc.add(createTransactionEvent);

                  // Recalculate account balance if accountId is provided
                  if (transaction['account_id'] != null) {
                    final accountBloc = context.read<AccountBloc>();
                    accountBloc.add(
                      RecalculateAccountBalanceEvent(transaction['account_id']),
                    );
                  }

                  // Reload home data immediately
                  if (context.mounted) {
                    context.read<HomeBloc>().add(
                      LoadHomeData(authState.user.id),
                    );
                  }
                } else {
                  showLoadingError('You must be logged in to add transactions');
                }
              } catch (e) {
                showLoadingError('Error adding transaction: $e');
              }
            },
          ),
        );
      },
    );
  }
}
