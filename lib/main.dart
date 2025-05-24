import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/core/themes/app_theme.dart';
// import 'package:monie/core/themes/color_extensions.dart';
import 'package:monie/di/injection.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/authentication/presentation/pages/auth_wrapper.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/groups/presentation/bloc/group_bloc.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';
import 'package:monie/features/home/presentation/pages/home_page.dart';
import 'package:monie/core/widgets/main_screen.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';
import 'package:monie/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:monie/features/settings/presentation/bloc/settings_event.dart';
import 'package:monie/features/settings/presentation/bloc/settings_state.dart';
import 'package:monie/features/settings/presentation/pages/settings_page.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:monie/features/groups/presentation/pages/group_detail_page.dart';
import 'package:monie/features/groups/presentation/pages/add_group_expense_page.dart';

// Global key for ScaffoldMessenger to manage snackbars app-wide
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase client
  await SupabaseClientManager.initialize();

  // Setup dependency injection
  await configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => sl<AuthBloc>()..add(GetCurrentUserEvent()),
        ),
        BlocProvider<HomeBloc>(
          create: (context) {
            final authState = sl<AuthBloc>().state;
            if (authState is Authenticated) {
              return sl<HomeBloc>()..add(LoadHomeData(authState.user.id));
            }
            return sl<HomeBloc>();
          },
        ),
        BlocProvider<TransactionsBloc>(
          create: (context) {
            final authState = sl<AuthBloc>().state;
            if (authState is Authenticated) {
              return sl<TransactionsBloc>()
                ..add(LoadTransactions(userId: authState.user.id));
            }
            return sl<TransactionsBloc>();
          },
        ),
        BlocProvider<TransactionBloc>(
          create: (context) => sl<TransactionBloc>(),
        ),
        BlocProvider<AccountBloc>(create: (context) => sl<AccountBloc>()),
        BlocProvider<BudgetsBloc>(
          create: (context) => sl<BudgetsBloc>()..add(const LoadBudgets()),
        ),
        BlocProvider<CategoriesBloc>(create: (context) => sl<CategoriesBloc>()),
        BlocProvider<SettingsBloc>(
          create:
              (context) => sl<SettingsBloc>()..add(const LoadSettingsEvent()),
        ),
        BlocProvider<GroupBloc>(create: (context) => sl<GroupBloc>()),
        BlocProvider<NotificationBloc>(
          create: (context) => sl<NotificationBloc>(),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          // Get theme mode from settings state, default to dark theme
          final themeMode =
              state is SettingsLoaded
                  ? state.settings.themeMode
                  : state is ProfileLoaded
                  ? state.settings.themeMode
                  : state is SettingsUpdateSuccess
                  ? state.settings.themeMode
                  : state is ProfileUpdateSuccess
                  ? state.settings.themeMode
                  : ThemeMode.dark;

          // Get language from settings state, default to English
          final appLanguage =
              state is SettingsLoaded
                  ? state.settings.language
                  : state is ProfileLoaded
                  ? state.settings.language
                  : state is SettingsUpdateSuccess
                  ? state.settings.language
                  : state is ProfileUpdateSuccess
                  ? state.settings.language
                  : AppLanguage.english;

          return MaterialApp(
            title: 'Monie',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            home: const AuthWrapper(),
            routes: {
              '/home': (context) => MainScreen(),
              '/settings': (context) => const SettingsPage(),
              '/group-details':
                  (context) => GroupDetailPage(
                    groupId:
                        ModalRoute.of(context)!.settings.arguments as String,
                  ),
              '/add-group-expense':
                  (context) => AddGroupExpensePage(
                    groupId:
                        ModalRoute.of(context)!.settings.arguments as String,
                  ),
              // For transactions and budgets, we'll use the tab navigation
              // from within the MainScreen rather than these routes
            },
            debugShowCheckedModeBanner: false,

            // Localization setup
            locale: appLanguage.toLocale,
            supportedLocales: const [Locale('en', 'US'), Locale('vi', 'VN')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            onGenerateRoute: (settings) {
              // Handle dynamic routes here if needed in the future
              return null;
            },
            onUnknownRoute: (settings) {
              // Fallback for unknown routes
              return MaterialPageRoute(builder: (context) => const HomePage());
            },
          );
        },
      ),
    );
  }
}
