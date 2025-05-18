import 'package:equatable/equatable.dart';

class Account extends Equatable {
  final String id;
  final String name;
  final String type; // 'bank', 'cash', etc.
  final double balance;
  final String currency;
  final int transactionCount;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.transactionCount,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    balance,
    currency,
    transactionCount,
  ];
}
