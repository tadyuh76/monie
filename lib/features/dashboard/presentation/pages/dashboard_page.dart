import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:monie/core/widgets/theme_toggle.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Dispatch event to check auth status when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(CheckAuthStatusEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            // Add theme toggle
            const ThemeToggle(),
            // Logout button
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthBloc>().add(SignOutEvent());
              },
              tooltip: 'Sign Out',
            ),
          ],
        ),
        drawer: Drawer(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    UserAccountsDrawerHeader(
                      accountName: Text(state.user.name),
                      accountEmail: Text(state.user.email),
                      currentAccountPicture: CircleAvatar(
                        backgroundImage:
                            state.user.photoUrl != null
                                ? NetworkImage(state.user.photoUrl!)
                                : null,
                        child:
                            state.user.photoUrl == null
                                ? Text(state.user.name[0].toUpperCase())
                                : null,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Dashboard'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.account_circle),
                      title: const Text('Profile'),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to profile page when implemented
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to settings page when implemented
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Sign Out'),
                      onTap: () {
                        Navigator.pop(context);
                        context.read<AuthBloc>().add(SignOutEvent());
                      },
                    ),
                  ],
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // Handle initial state more gracefully
            if (state is AuthInitial) {
              // Trigger authentication status check if not already done
              context.read<AuthBloc>().add(CheckAuthStatusEvent());
              return const Center(child: CircularProgressIndicator());
            }

            // Handle loading state
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle authenticated state
            if (state is Authenticated) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${state.user.name}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      const _SummaryCards(),
                      const SizedBox(height: 24),
                      const _RecentTransactions(),
                    ],
                  ),
                ),
              );
            }

            // Handle error state
            if (state is AuthError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(CheckAuthStatusEvent());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Fallback - this should trigger a reload of auth status
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AuthBloc>().add(CheckAuthStatusEvent());
            });
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your dashboard...'),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Implement add transaction functionality
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16.0,
      crossAxisSpacing: 16.0,
      children: const [
        _SummaryCard(
          title: 'Balance',
          value: '\$2,460.00',
          icon: Icons.account_balance_wallet,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: 'Income',
          value: '\$1,840.00',
          icon: Icons.arrow_downward,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'Expenses',
          value: '\$560.00',
          icon: Icons.arrow_upward,
          color: Colors.red,
        ),
        _SummaryCard(
          title: 'Savings',
          value: '\$720.00',
          icon: Icons.savings,
          color: Colors.amber,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final isExpense = index % 2 == 0;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    isExpense ? Colors.red[100] : Colors.green[100],
                child: Icon(
                  isExpense ? Icons.shopping_cart : Icons.attach_money,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
              title: Text(isExpense ? 'Grocery Shopping' : 'Salary Payment'),
              subtitle: Text('May ${10 + index}, 2023'),
              trailing: Text(
                isExpense ? '-\$58.${index}0' : '+\$950.00',
                style: TextStyle(
                  color: isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
