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
import 'package:monie/features/authentication/presentation/pages/auth_wrapper.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/budgets/presentation/pages/budgets_page.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';
import 'package:monie/features/home/presentation/pages/home_page.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';
import 'package:monie/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:monie/features/settings/presentation/bloc/settings_event.dart';
import 'package:monie/features/settings/presentation/bloc/settings_state.dart';
import 'package:monie/features/settings/presentation/pages/settings_page.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:monie/features/transactions/presentation/pages/transactions_page.dart';

import 'features/account/presentation/pages/edit_accounts_page.dart';

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
          create: (context) => getIt<AuthBloc>()..add(GetCurrentUserEvent()),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => getIt<HomeBloc>()..add(const LoadHomeData()),
        ),
        BlocProvider<TransactionsBloc>(
          create:
              (context) =>
                  getIt<TransactionsBloc>()..add(const LoadTransactions()),
        ),
        BlocProvider<BudgetsBloc>(
          create: (context) => getIt<BudgetsBloc>()..add(const LoadBudgets()),
        ),
        BlocProvider<CategoriesBloc>(
          create: (context) => getIt<CategoriesBloc>(),
        ),
        BlocProvider<SettingsBloc>(
          create:
              (context) =>
                  getIt<SettingsBloc>()..add(const LoadSettingsEvent()),
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
              '/home': (context) => const HomePage(),
              '/transactions': (context) => const TransactionsPage(),
              '/budgets': (context) => const BudgetsPage(),
              '/settings': (context) => const SettingsPage(),
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
