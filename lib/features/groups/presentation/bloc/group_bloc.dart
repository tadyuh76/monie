import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/groups/domain/usecases/add_group_expense.dart';
import 'package:monie/features/groups/domain/usecases/add_member.dart';
import 'package:monie/features/groups/domain/usecases/approve_group_transaction.dart';
import 'package:monie/features/groups/domain/usecases/calculate_debts.dart'
    as calc;
import 'package:monie/features/groups/domain/usecases/create_group.dart';
import 'package:monie/features/groups/domain/usecases/get_group_by_id.dart'
    as get_group;
import 'package:monie/features/groups/domain/usecases/get_group_members.dart'
    as get_members;
import 'package:monie/features/groups/domain/usecases/get_group_transactions.dart'
    as get_transactions;
import 'package:monie/features/groups/domain/usecases/get_groups.dart';
import 'package:monie/features/groups/domain/usecases/remove_member.dart';
import 'package:monie/features/groups/domain/usecases/settle_group.dart'
    as settle;
import 'package:monie/features/groups/domain/usecases/update_member_role.dart';
import 'package:monie/features/groups/presentation/bloc/group_event.dart';
import 'package:monie/features/groups/presentation/bloc/group_state.dart';

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final GetGroups getGroups;
  final get_group.GetGroupById getGroupById;
  final CreateGroup createGroup;
  final AddMember addMember;
  final calc.CalculateDebts calculateDebts;
  final settle.SettleGroup settleGroup;
  final AddGroupExpense addGroupExpense;
  final get_transactions.GetGroupTransactions getGroupTransactions;
  final ApproveGroupTransaction approveGroupTransaction;
  final get_members.GetGroupMembers getGroupMembers;
  final RemoveMember removeMember;
  final UpdateMemberRole updateMemberRole;

  GroupBloc({
    required this.getGroups,
    required this.getGroupById,
    required this.createGroup,
    required this.addMember,
    required this.calculateDebts,
    required this.settleGroup,
    required this.addGroupExpense,
    required this.getGroupTransactions,
    required this.approveGroupTransaction,
    required this.getGroupMembers,
    required this.removeMember,
    required this.updateMemberRole,
  }) : super(const GroupInitial()) {
    on<GetGroupsEvent>(_onGetGroups);
    on<GetGroupByIdEvent>(_onGetGroupById);
    on<CreateGroupEvent>(_onCreateGroup);
    on<AddMemberEvent>(_onAddMember);
    on<CalculateDebtsEvent>(_onCalculateDebts);
    on<SettleGroupEvent>(_onSettleGroup);
    on<AddGroupExpenseEvent>(_onAddGroupExpense);
    on<GetGroupTransactionsEvent>(_onGetGroupTransactions);
    on<ApproveGroupTransactionEvent>(_onApproveGroupTransaction);
    on<GetGroupMembersEvent>(_onGetGroupMembers);
    on<RemoveMemberEvent>(_onRemoveMember);
    on<UpdateMemberRoleEvent>(_onUpdateMemberRole);
  }

  Future<void> _onGetGroups(
    GetGroupsEvent event,
    Emitter<GroupState> emit,
  ) async {
    // Only show loading if we're not already in GroupsLoaded state
    final bool isFirstLoad = state is! GroupsLoaded;

    if (isFirstLoad) {
      emit(const GroupLoading());
    }

    final result = await getGroups();

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      groups,
    ) {
      // Emit new loaded state with groups
      emit(GroupsLoaded(groups: groups));
    });
  }

  Future<void> _onGetGroupById(
    GetGroupByIdEvent event,
    Emitter<GroupState> emit,
  ) async {
    // Check if we already have this group's data to avoid flashing loading state
    bool needsLoading = true;
    SingleGroupLoaded? currentGroupState;

    if (state is SingleGroupLoaded) {
      currentGroupState = state as SingleGroupLoaded;
      if (currentGroupState.group.id == event.groupId) {
        // We already have this group's data with the same ID, don't show loading
        needsLoading = false;
      }
    }

    if (needsLoading && currentGroupState?.group.id != event.groupId) {
      // Only emit loading if we don't have the correct group data already
      emit(const GroupLoading());
    }

    // Always fetch the group data to ensure we have the latest information
    final result = await getGroupById(
      get_group.GroupIdParams(groupId: event.groupId),
    );

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      group,
    ) {
      // Preserve existing transactions and debts if we're refreshing the same group
      final existingTransactions =
          currentGroupState?.group.id == event.groupId
              ? currentGroupState?.transactions
              : null;
      final existingDebts =
          currentGroupState?.group.id == event.groupId
              ? currentGroupState?.debts
              : null;

      // Emit the new group data with preserved transactions/debts if available
      emit(
        SingleGroupLoaded(
          group: group,
          transactions: existingTransactions,
          debts: existingDebts,
        ),
      );

      // Only load transactions and debts if we don't have them or if this is a new group
      if (existingTransactions == null ||
          currentGroupState?.group.id != event.groupId) {
        add(GetGroupTransactionsEvent(groupId: event.groupId));
      }

      if (existingDebts == null ||
          currentGroupState?.group.id != event.groupId) {
        add(CalculateDebtsEvent(groupId: event.groupId));
      }
    });
  }

  Future<void> _onCreateGroup(
    CreateGroupEvent event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading());
    final result = await createGroup(
      CreateGroupParams(name: event.name, description: event.description),
    );
    result.fold((failure) => emit(GroupError(message: failure.message)), (
      group,
    ) {
      emit(GroupOperationSuccess(message: 'Group created successfully'));
      add(const GetGroupsEvent());
    });
  }

  Future<void> _onAddMember(
    AddMemberEvent event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading()); // Indicate operation started

    final result = await addMember(
      AddMemberParams(
        groupId: event.groupId,
        email: event.email,
        role: event.role,
      ),
    );

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      success,
    ) {
      emit(GroupOperationSuccess(message: 'Member added successfully'));

      // Immediately refresh the group data to show the new member
      // Use a microtask to ensure the success message is shown first
      Future.microtask(() {
        add(GetGroupByIdEvent(groupId: event.groupId));
        add(const GetGroupsEvent()); // Refresh the list of groups
      });
    });
  }

  Future<void> _onCalculateDebts(
    CalculateDebtsEvent event,
    Emitter<GroupState> emit,
  ) async {
    // Keep current state if it's SingleGroupLoaded
    SingleGroupLoaded? currentGroupState;
    if (state is SingleGroupLoaded) {
      currentGroupState = state as SingleGroupLoaded;
    } else {
      emit(const GroupLoading());
    }

    // First get the group if we don't already have it
    final groupResult =
        currentGroupState != null && currentGroupState.group.id == event.groupId
            ? null // Skip loading group if we already have it
            : await getGroupById(
              get_group.GroupIdParams(groupId: event.groupId),
            );

    // Then calculate debts
    final debtsResult = await calculateDebts(
      calc.GroupIdParams(groupId: event.groupId),
    );

    if (groupResult != null) {
      groupResult.fold(
        (failure) => emit(GroupError(message: failure.message)),
        (group) {
          debtsResult.fold(
            (failure) => emit(
              SingleGroupLoaded(
                group: group,
                transactions: currentGroupState?.transactions,
              ),
            ),
            (debts) => emit(
              SingleGroupLoaded(
                group: group,
                debts: debts,
                transactions: currentGroupState?.transactions,
              ),
            ),
          );
        },
      );
    } else {
      // Use current group data
      debtsResult.fold(
        (failure) => emit(currentGroupState!),
        (debts) => emit(currentGroupState!.copyWith(debts: debts)),
      );
    }
  }

  Future<void> _onSettleGroup(
    SettleGroupEvent event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading());
    final result = await settleGroup(
      settle.GroupIdParams(groupId: event.groupId),
    );
    result.fold((failure) => emit(GroupError(message: failure.message)), (
      success,
    ) {
      emit(GroupOperationSuccess(message: 'Group settled successfully'));

      // Refresh both the groups list and current group detail
      add(const GetGroupsEvent());
      add(GetGroupByIdEvent(groupId: event.groupId));
    });
  }

  Future<void> _onAddGroupExpense(
    AddGroupExpenseEvent event,
    Emitter<GroupState> emit,
  ) async {
    // Store current state to restore aspects of it later
    final currentState = state;

    emit(const GroupLoading());

    final params = AddGroupExpenseParams(
      groupId: event.groupId,
      title: event.title,
      amount: event.amount,
      description: event.description,
      date: event.date,
      paidBy: event.paidBy,
      categoryName: event.categoryName,
      color: event.color,
    );

    final result = await addGroupExpense(params);

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      transaction,
    ) {
      emit(const GroupOperationSuccess(message: 'Expense added successfully'));

      // Only refresh the group data once - this will automatically load transactions and debts
      // Use a microtask to ensure the success message is shown first
      Future.microtask(() {
        add(GetGroupByIdEvent(groupId: event.groupId));

        // Only refresh the groups list if we were in the groups list view
        if (currentState is GroupsLoaded) {
          add(const GetGroupsEvent());
        }
      });
    });
  }

  Future<void> _onGetGroupTransactions(
    GetGroupTransactionsEvent event,
    Emitter<GroupState> emit,
  ) async {
    // Don't show loading state if we already have a SingleGroupLoaded state
    // Just keep the current state while loading in the background
    final currentState = state;

    // Only emit loading if we have no state at all
    if (state is! SingleGroupLoaded && state is! GroupLoading) {
      emit(const GroupLoading());
    }

    final params = get_transactions.GroupIdParams(groupId: event.groupId);
    final result = await getGroupTransactions(params);

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      transactions,
    ) {
      if (currentState is SingleGroupLoaded) {
        // Update the current SingleGroupLoaded state with transactions
        final groupState = currentState;

        // Only update if this data is for the correct group
        if (groupState.group.id == event.groupId) {
          emit(groupState.copyWith(transactions: transactions));
        } else {
          // We have group data for a different group, get the correct group first
          add(GetGroupByIdEvent(groupId: event.groupId));
        }
      } else {
        // If we're not in a SingleGroupLoaded state, get the group first
        add(GetGroupByIdEvent(groupId: event.groupId));
      }
    });
  }

  Future<void> _onApproveGroupTransaction(
    ApproveGroupTransactionEvent event,
    Emitter<GroupState> emit,
  ) async {
    // Store current state
    final currentState = state;

    emit(const GroupLoading());

    final params = TransactionApprovalParams(
      transactionId: event.transactionId,
      approved: event.approved,
    );

    final result = await approveGroupTransaction(params);

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      success,
    ) {
      final message =
          event.approved
              ? 'Transaction approved successfully'
              : 'Transaction rejected';
      emit(GroupOperationSuccess(message: message));

      // If we're in a SingleGroupLoaded state, refresh the transactions
      if (currentState is SingleGroupLoaded) {
        final groupState = currentState;

        // Refresh both the group and transactions
        add(GetGroupByIdEvent(groupId: groupState.group.id));
        add(GetGroupTransactionsEvent(groupId: groupState.group.id));

        // Also refresh the groups list since approval affects totals
        add(const GetGroupsEvent());
      }
    });
  }

  Future<void> _onGetGroupMembers(
    GetGroupMembersEvent event,
    Emitter<GroupState> emit,
  ) async {
    // Only emit loading if we don't already have members data
    if (state is! GroupMembersLoaded) {
      emit(const GroupLoading());
    }

    final result = await getGroupMembers(
      get_members.GroupIdParams(groupId: event.groupId),
    );

    result.fold(
      (failure) {
        emit(GroupError(message: failure.message));
      },
      (members) {
        // Emit a new state with the members data
        emit(GroupMembersLoaded(members: members));
      },
    );
  }

  Future<void> _onRemoveMember(
    RemoveMemberEvent event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading());

    final result = await removeMember(
      RemoveMemberParams(groupId: event.groupId, userId: event.userId),
    );

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      success,
    ) {
      emit(GroupOperationSuccess(message: 'Member removed successfully'));

      // Refresh both the group data and members list
      Future.microtask(() {
        add(GetGroupByIdEvent(groupId: event.groupId));
        add(GetGroupMembersEvent(groupId: event.groupId)); // Refresh members
        add(const GetGroupsEvent()); // Refresh the list of groups
      });
    });
  }

  Future<void> _onUpdateMemberRole(
    UpdateMemberRoleEvent event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading());

    final result = await updateMemberRole(
      UpdateMemberRoleParams(
        groupId: event.groupId,
        userId: event.userId,
        role: event.role,
      ),
    );

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      success,
    ) {
      emit(GroupOperationSuccess(message: 'Member role updated successfully'));

      // Refresh both the group data and members list
      Future.microtask(() {
        add(GetGroupByIdEvent(groupId: event.groupId));
        add(GetGroupMembersEvent(groupId: event.groupId)); // Refresh members
        add(const GetGroupsEvent()); // Refresh the list of groups
      });
    });
  }
}
