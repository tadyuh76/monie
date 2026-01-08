import 'package:monie/features/groups/domain/entities/group_debt.dart';

class GroupDebtModel extends GroupDebt {
  const GroupDebtModel({
    required super.fromUserId,
    required super.fromUserName,
    required super.toUserId,
    required super.toUserName,
    required super.amount,
  });

  factory GroupDebtModel.fromJson(Map<String, dynamic> json) {
    return GroupDebtModel(
      fromUserId: json['from_user_id'],
      fromUserName: json['from_user_name'],
      toUserId: json['to_user_id'],
      toUserName: json['to_user_name'],
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_user_id': fromUserId,
      'from_user_name': fromUserName,
      'to_user_id': toUserId,
      'to_user_name': toUserName,
      'amount': amount,
    };
  }
}
