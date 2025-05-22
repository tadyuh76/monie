import 'package:equatable/equatable.dart';

abstract class GroupEvent extends Equatable {
  const GroupEvent();

  @override
  List<Object?> get props => [];
}

class GetGroupsEvent extends GroupEvent {
  const GetGroupsEvent();
}

class GetGroupByIdEvent extends GroupEvent {
  final String groupId;

  const GetGroupByIdEvent({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

class CreateGroupEvent extends GroupEvent {
  final String name;
  final String? description;

  const CreateGroupEvent({required this.name, this.description});

  @override
  List<Object?> get props => [name, description];
}

class UpdateGroupEvent extends GroupEvent {
  final String groupId;
  final String? name;
  final String? description;

  const UpdateGroupEvent({required this.groupId, this.name, this.description});

  @override
  List<Object?> get props => [groupId, name, description];
}

class DeleteGroupEvent extends GroupEvent {
  final String groupId;

  const DeleteGroupEvent({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

class AddMemberEvent extends GroupEvent {
  final String groupId;
  final String email;
  final String role;

  const AddMemberEvent({
    required this.groupId,
    required this.email,
    required this.role,
  });

  @override
  List<Object?> get props => [groupId, email, role];
}

class RemoveMemberEvent extends GroupEvent {
  final String groupId;
  final String userId;

  const RemoveMemberEvent({required this.groupId, required this.userId});

  @override
  List<Object?> get props => [groupId, userId];
}

class UpdateMemberRoleEvent extends GroupEvent {
  final String groupId;
  final String userId;
  final String role;

  const UpdateMemberRoleEvent({
    required this.groupId,
    required this.userId,
    required this.role,
  });

  @override
  List<Object?> get props => [groupId, userId, role];
}

class CalculateDebtsEvent extends GroupEvent {
  final String groupId;

  const CalculateDebtsEvent({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

class SettleGroupEvent extends GroupEvent {
  final String groupId;

  const SettleGroupEvent({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

class AddGroupExpenseEvent extends GroupEvent {
  final String groupId;
  final String title;
  final double amount;
  final String description;
  final DateTime date;
  final String paidBy;
  final String? categoryName;
  final String? color;

  const AddGroupExpenseEvent({
    required this.groupId,
    required this.title,
    required this.amount,
    required this.description,
    required this.date,
    required this.paidBy,
    this.categoryName,
    this.color,
  });

  @override
  List<Object?> get props => [
    groupId,
    title,
    amount,
    description,
    date,
    paidBy,
    categoryName,
    color,
  ];
}

class GetGroupTransactionsEvent extends GroupEvent {
  final String groupId;

  const GetGroupTransactionsEvent({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}

class ApproveGroupTransactionEvent extends GroupEvent {
  final String transactionId;
  final bool approved;

  const ApproveGroupTransactionEvent({
    required this.transactionId,
    required this.approved,
  });

  @override
  List<Object?> get props => [transactionId, approved];
}

class GetGroupMembersEvent extends GroupEvent {
  final String groupId;

  const GetGroupMembersEvent({required this.groupId});

  @override
  List<Object?> get props => [groupId];
}
