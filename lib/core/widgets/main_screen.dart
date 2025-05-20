import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/budgets/presentation/pages/budgets_page.dart';
import 'package:monie/features/groups/presentation/pages/groups_page.dart';
import 'package:monie/features/home/presentation/pages/home_page.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:monie/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:monie/features/transactions/presentation/pages/transactions_page.dart';
import 'package:monie/features/transactions/presentation/widgets/add_transaction_form.dart';
import 'package:monie/main.dart'; // Import for rootScaffoldMessengerKey

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Create a method that can be used by child widgets to switch tabs
  void _switchTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

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
            // Add logging to understand state transitions
            return true; // Listen to all state changes
          },
          listener: (context, state) {
            if (state is TransactionLoading) {
              // Do nothing, transaction is in progress
            } else if (state is TransactionLoaded) {
              // Show success message globally
              // _showGlobalSnackBar(state.message, backgroundColor: Colors.green);

              // Ensure transactions are reloaded after successful action
              if (_currentIndex == 1) {
                // If on transactions page, refresh with current month
                context.read<TransactionsBloc>().add(
                  FilterTransactionsByMonth(DateTime.now()),
                );
              } else {
                // Otherwise just reload all transactions
                final authState = context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  context.read<TransactionsBloc>().add(
                    LoadTransactions(userId: authState.user.id),
                  );
                }
              }
            } else if (state is TransactionsError) {
              // Show error globally
              _showGlobalSnackBar(state.message, backgroundColor: Colors.red);
            } else if (state is TransactionLoaded) {
              // Do nothing, transactions loaded successfully
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
                  icon: Icon(Icons.more_horiz),
                  label: 'More',
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
    final authBloc = BlocProvider.of<AuthBloc>(context);
    final categoriesBloc = BlocProvider.of<CategoriesBloc>(context);

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
            BlocProvider.value(value: categoriesBloc),
          ],
          child: AddTransactionForm(
            onSubmit: (Map<String, dynamic> transaction) async {
              // Use a try-catch block to handle any errors gracefully
              try {
                if (authState is Authenticated) {
                  // Create AddNewTransaction event
                  final addTransactionEvent = AddNewTransaction(
                    amount: transaction['amount'],
                    description: transaction['description'] ?? '',
                    title: transaction['title'],
                    date: DateTime.parse(transaction['date']),
                    userId: authState.user.id,
                    categoryName: transaction['category_name'],
                    categoryColor: transaction['category_color'],
                    accountId: null,
                    budgetId: null,
                    isIncome: transaction['amount'] >= 0,
                  );

                  // Add the event to the bloc
                  transactionsBloc.add(addTransactionEvent);

                  // Force refresh transactions view
                  Future.delayed(Duration(milliseconds: 500), () {
                    if (_currentIndex == 1) {
                      transactionsBloc.add(
                        FilterTransactionsByMonth(DateTime.now()),
                      );
                    } else {
                      if (!context.mounted) return;

                      final authState = context.read<AuthBloc>().state;
                      if (authState is Authenticated) {
                        transactionsBloc.add(
                          LoadTransactions(userId: authState.user.id),
                        );
                      }
                    }
                  });
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
