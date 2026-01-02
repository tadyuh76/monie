import 'package:equatable/equatable.dart';

class GroupDebt extends Equatable {
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final double amount;

  const GroupDebt({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
  });

  @override
  List<Object?> get props => [
        fromUserId,
        fromUserName,
        toUserId,
        toUserName,
        amount,
      ];
}
