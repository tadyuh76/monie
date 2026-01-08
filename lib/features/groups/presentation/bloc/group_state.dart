import 'package:equatable/equatable.dart';
import 'package:monie/features/groups/domain/entities/expense_group.dart';
import 'package:monie/features/groups/domain/entities/group_debt.dart';
import 'package:monie/features/groups/domain/entities/group_member.dart';
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
  final List<GroupDebt>? debts;
  final List<GroupTransaction>? transactions;
  final List<GroupMember>? members;
  final String? successMessage; // Optional success message to show

  const SingleGroupLoaded({
    required this.group,
    this.debts,
    this.transactions,
    this.members,
    this.successMessage,
  });

  @override
  List<Object?> get props => [group, debts, transactions, members, successMessage];

  SingleGroupLoaded copyWith({
    ExpenseGroup? group,
    List<GroupDebt>? debts,
    List<GroupTransaction>? transactions,
    List<GroupMember>? members,
    String? successMessage,
    bool clearMessage = false, // Flag to explicitly clear the message
  }) {
    return SingleGroupLoaded(
      group: group ?? this.group,
      debts: debts ?? this.debts,
      transactions: transactions ?? this.transactions,
      members: members ?? this.members,
      successMessage: clearMessage ? null : (successMessage ?? this.successMessage),
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
  final List<GroupMember> members;

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
