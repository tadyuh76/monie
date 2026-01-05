import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/account/domain/repositories/account_repository.dart';
import 'package:monie/features/ai_chat/data/datasources/ai_chat_datasource.dart';
import 'package:monie/features/ai_chat/domain/entities/chat_message.dart';
import 'package:monie/features/ai_chat/presentation/bloc/ai_chat_event.dart';
import 'package:monie/features/ai_chat/presentation/bloc/ai_chat_state.dart';
import 'package:monie/features/budgets/domain/repositories/budget_repository.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';

/// BLoC for managing AI chat
class AIChatBloc extends Bloc<AIChatEvent, AIChatState> {
  final AIChatDataSource _chatDataSource;
  final AccountRepository _accountRepository;
  final TransactionRepository _transactionRepository;
  final BudgetRepository _budgetRepository;
  final _uuid = const Uuid();

  AIChatBloc({
    required AIChatDataSource chatDataSource,
    required AccountRepository accountRepository,
    required TransactionRepository transactionRepository,
    required BudgetRepository budgetRepository,
  })  : _chatDataSource = chatDataSource,
        _accountRepository = accountRepository,
        _transactionRepository = transactionRepository,
        _budgetRepository = budgetRepository,
        super(const AIChatState()) {
    on<InitializeChatEvent>(_onInitializeChat);
    on<SendMessageEvent>(_onSendMessage);
    on<ClearChatEvent>(_onClearChat);
  }

  Future<void> _onInitializeChat(
    InitializeChatEvent event,
    Emitter<AIChatState> emit,
  ) async {
    try {
      debugPrint('💬 AIChatBloc: Initializing chat session...');

      // Fetch user's financial data
      final accounts = await _accountRepository.getAccounts(event.userId);
      final transactions =
          await _transactionRepository.getTransactions(event.userId);
      final budgets = await _budgetRepository.getBudgets();

      // Start chat session with context
      _chatDataSource.startSession(
        accounts: accounts,
        transactions: transactions,
        budgets: budgets,
      );

      // Add welcome message
      final welcomeMessage = ChatMessage(
        id: _uuid.v4(),
        content:
            'Hello! 👋 I\'m your AI financial assistant. I can help you understand your spending, analyze budgets, and provide personalized financial advice. What would you like to know?',
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        isInitialized: true,
        messages: [welcomeMessage],
        error: null,
      ));

      debugPrint('✅ AIChatBloc: Chat session initialized');
    } catch (e) {
      debugPrint('❌ AIChatBloc Error: $e');
      emit(state.copyWith(
        error: 'Failed to initialize chat: $e',
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<AIChatState> emit,
  ) async {
    if (event.message.trim().isEmpty) return;

    try {
      // Initialize session if not already done
      if (!state.isInitialized) {
        debugPrint('⚠️ AIChatBloc: Session not initialized, initializing first...');
        // Initialize inline instead of adding event
        final accounts = await _accountRepository.getAccounts(event.userId);
        final transactions =
            await _transactionRepository.getTransactions(event.userId);
        final budgets = await _budgetRepository.getBudgets();

        _chatDataSource.startSession(
          accounts: accounts,
          transactions: transactions,
          budgets: budgets,
        );

        emit(state.copyWith(isInitialized: true));
        debugPrint('✅ AIChatBloc: Session initialized inline');
      }

      // Add user message
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        content: event.message,
        isUser: true,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        messages: [...state.messages, userMessage],
        isTyping: true,
        error: null,
      ));

      debugPrint('💬 AIChatBloc: Sending message...');

      // Get AI response
      final response = await _chatDataSource.sendMessage(event.message);

      if (response == null || response.isEmpty) {
        throw Exception('Empty response from AI');
      }

      // Add AI message
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        messages: [...state.messages, aiMessage],
        isTyping: false,
      ));

      debugPrint('✅ AIChatBloc: Response received');
    } catch (e) {
      debugPrint('❌ AIChatBloc Error: $e');

      // Detect quota error
      String errorContent;
      if (e.toString().contains('quota') || e.toString().contains('rate')) {
        errorContent = 'The AI service is temporarily unavailable due to rate limits. Please wait a minute and try again. 🕐';
      } else {
        errorContent = 'Sorry, I couldn\'t process your request. Please try again.';
      }

      // Add error message
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        content: errorContent,
        isUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.error,
      );

      emit(state.copyWith(
        messages: [...state.messages, errorMessage],
        isTyping: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onClearChat(
    ClearChatEvent event,
    Emitter<AIChatState> emit,
  ) async {
    _chatDataSource.clearSession();
    emit(const AIChatState());
    debugPrint('🗑️ AIChatBloc: Chat cleared');
  }
}
