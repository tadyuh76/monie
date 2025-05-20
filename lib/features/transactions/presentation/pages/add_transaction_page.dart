import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:monie/features/transactions/presentation/widgets/transaction_form_widget.dart';

class AddTransactionPage extends StatelessWidget {
  final String userId;
  final Transaction? transaction;

  const AddTransactionPage({super.key, required this.userId, this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          transaction == null
              ? context.tr('add_transaction')
              : context.tr('edit_transaction'),
        ),
      ),
      body: BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionCreated || state is TransactionUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state is TransactionCreated
                      ? context.tr('transaction_created_success')
                      : context.tr('transaction_updated_success'),
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is TransactionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: TransactionFormWidget(
            userId: userId,
            transaction: transaction,
          ),
        ),
      ),
    );
  }
}
