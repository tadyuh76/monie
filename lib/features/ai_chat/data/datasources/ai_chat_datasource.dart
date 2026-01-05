import 'package:flutter/foundation.dart';
import 'package:monie/core/services/gemini_service.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

/// Builds financial context for AI chat sessions
class FinancialContextBuilder {
  /// Build context string from user's financial data
  static String buildContext({
    required List<Account> accounts,
    required List<Transaction> transactions,
    required List<Budget> budgets,
  }) {
    final buffer = StringBuffer();

    // Account summary
    buffer.writeln('=== USER FINANCIAL DATA ===\n');

    // Accounts
    buffer.writeln('ACCOUNTS:');
    if (accounts.isEmpty) {
      buffer.writeln('- No accounts set up yet');
    } else {
      double totalBalance = 0;
      for (final account in accounts.where((a) => !a.archived)) {
        buffer.writeln(
            '- ${account.name} (${account.type}): ${Formatters.formatCurrency(account.balance)} ${account.currency}');
        totalBalance += account.balance;
      }
      buffer.writeln('Total Balance: ${Formatters.formatCurrency(totalBalance)}');
    }
    buffer.writeln();

    // Calculate monthly income and expenses
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthlyTransactions =
        transactions.where((t) => t.date.isAfter(monthStart)).toList();

    double monthlyIncome = 0;
    double monthlyExpenses = 0;
    for (final t in monthlyTransactions) {
      if (t.amount > 0) {
        monthlyIncome += t.amount;
      } else {
        monthlyExpenses += t.amount.abs();
      }
    }

    buffer.writeln('MONTHLY SUMMARY (${_getMonthName(now.month)} ${now.year}):');
    buffer.writeln('- Income: ${Formatters.formatCurrency(monthlyIncome)}');
    buffer.writeln('- Expenses: ${Formatters.formatCurrency(monthlyExpenses)}');
    buffer.writeln(
        '- Net: ${Formatters.formatCurrency(monthlyIncome - monthlyExpenses)}');
    buffer.writeln();

    // Active budgets
    buffer.writeln('ACTIVE BUDGETS:');
    final activeBudgets = budgets.where((b) {
      final endDate = b.endDate ?? DateTime(2099);
      return b.startDate.isBefore(now) && endDate.isAfter(now);
    }).toList();

    if (activeBudgets.isEmpty) {
      buffer.writeln('- No active budgets');
    } else {
      for (final budget in activeBudgets) {
        final spent = budget.spent ?? 0;
        final percentage = budget.amount > 0 ? (spent / budget.amount * 100) : 0;
        buffer.writeln(
            '- ${budget.name}: ${Formatters.formatCurrency(spent)} / ${Formatters.formatCurrency(budget.amount)} (${percentage.toStringAsFixed(0)}% used)');
      }
    }
    buffer.writeln();

    // Category breakdown for expenses this month
    buffer.writeln('EXPENSE CATEGORIES THIS MONTH:');
    final categoryTotals = <String, double>{};
    for (final t in monthlyTransactions.where((t) => t.amount < 0)) {
      final category = t.categoryName ?? 'Other';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + t.amount.abs();
    }

    if (categoryTotals.isEmpty) {
      buffer.writeln('- No expenses recorded');
    } else {
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedCategories.take(8)) {
        buffer.writeln('- ${entry.key}: ${Formatters.formatCurrency(entry.value)}');
      }
    }
    buffer.writeln();

    // Recent transactions (last 10)
    buffer.writeln('RECENT TRANSACTIONS (last 10):');
    final recentTransactions = transactions.take(10).toList();
    if (recentTransactions.isEmpty) {
      buffer.writeln('- No recent transactions');
    } else {
      for (final t in recentTransactions) {
        final type = t.amount > 0 ? '+' : '';
        final title = t.title.isNotEmpty ? t.title : 'Transaction';
        buffer.writeln(
            '- ${Formatters.formatShortDate(t.date)}: $title $type${Formatters.formatCurrency(t.amount)} (${t.categoryName ?? 'Other'})');
      }
    }

    debugPrint('📝 Financial context built: ${buffer.length} chars');
    return buffer.toString();
  }

  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

/// Data source for AI chat
class AIChatDataSource {
  final GeminiService _geminiService;
  bool _isSessionStarted = false;

  AIChatDataSource(this._geminiService);

  /// Check if session is ready
  bool get isSessionReady => _isSessionStarted;

  /// Start a new chat session with financial context
  void startSession({
    required List<Account> accounts,
    required List<Transaction> transactions,
    required List<Budget> budgets,
  }) {
    try {
      final context = FinancialContextBuilder.buildContext(
        accounts: accounts,
        transactions: transactions,
        budgets: budgets,
      );

      _geminiService.startChatSession(context);
      _isSessionStarted = true;
      debugPrint('✅ AIChatDataSource: Session started successfully');
    } catch (e) {
      debugPrint('❌ AIChatDataSource: Failed to start session: $e');
      _isSessionStarted = false;
      rethrow;
    }
  }

  /// Send a message and get a response
  Future<String?> sendMessage(String message) async {
    debugPrint('💬 AIChatDataSource: Sending message, session ready: $_isSessionStarted');
    try {
      final response = await _geminiService.sendChatMessage(message);
      debugPrint('✅ AIChatDataSource: Got response: ${response?.substring(0, 50) ?? 'null'}...');
      return response;
    } catch (e) {
      debugPrint('❌ AIChatDataSource: Send message error: $e');
      rethrow;
    }
  }

  /// Clear the current session
  void clearSession() {
    _geminiService.clearChatSession();
    _isSessionStarted = false;
  }
}
