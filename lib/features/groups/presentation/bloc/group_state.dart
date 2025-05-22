import 'package:equatable/equatable.dart';
import 'package:monie/features/groups/data/models/group_member_model.dart';
import 'package:monie/features/groups/domain/entities/expense_group.dart';
import 'package:monie/features/groups/domain/entities/group_transaction.dart';

abstract class GroupState extends Equatable {
  const GroupState();

  @override
  List<Object?> get props => [];
}

class GroupInitial extends GroupState {
  const GroupInitial();
}

class GroupLoading extends GroupState {
  const GroupLoading();
}

class GroupsLoaded extends GroupState {
  final List<ExpenseGroup> groups;

  const GroupsLoaded({required this.groups});

  @override
  List<Object?> get props => [groups];
}

class SingleGroupLoaded extends GroupState {
  final ExpenseGroup group;
  final Map<String, double>? debts;
  final List<GroupTransaction>? transactions;

  const SingleGroupLoaded({required this.group, this.debts, this.transactions});

  @override
  List<Object?> get props => [group, debts, transactions];

  SingleGroupLoaded copyWith({
    ExpenseGroup? group,
    Map<String, double>? debts,
    List<GroupTransaction>? transactions,
  }) {
    return SingleGroupLoaded(
      group: group ?? this.group,
      debts: debts ?? this.debts,
      transactions: transactions ?? this.transactions,
    );
  }
}

class GroupTransactionsLoaded extends GroupState {
  final List<GroupTransaction> transactions;

  const GroupTransactionsLoaded({required this.transactions});

  @override
  List<Object?> get props => [transactions];
}

class GroupMembersLoaded extends GroupState {
  final List<GroupMemberModel> members;

  const GroupMembersLoaded({required this.members});

  @override
  List<Object?> get props => [members];
}

class GroupOperationSuccess extends GroupState {
  final String message;

  const GroupOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class GroupError extends GroupState {
  final String message;

  const GroupError({required this.message});

  @override
  List<Object?> get props => [message];
}
