import 'package:flutter/material.dart';
import 'package:monie/features/home/domain/entities/account.dart';
// TODO: Import your transaction model and bloc/cubit for fetching transactions

class AccountTransactionsPage extends StatelessWidget {
  final Account account;

  const AccountTransactionsPage({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual BLoC/Cubit provider and listener if needed
    // final transactionsBloc = BlocProvider.of<TransactionsBloc>(context);
    // transactionsBloc.add(FetchTransactionsForAccount(account.id)); // Assuming you have an event like this

    return Scaffold(
      appBar: AppBar(title: Text(account.name)),
      body: Center(
        // Placeholder: Replace with a ListView.builder to display transactions
        child: Text('Transactions for ${account.name} will be shown here.'),
      ),
      // TODO: Add a FloatingActionButton to navigate to AddTransactionPage for this account
    );
  }
}
