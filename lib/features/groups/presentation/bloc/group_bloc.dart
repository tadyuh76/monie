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
import 'package:monie/features/groups/domain/usecases/settle_group.dart'
    as settle;
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
        // and also skip the fetch if we already have all the data
        needsLoading = false;

        // If we already have complete data for this group, just return without fetching
        if (currentGroupState.transactions != null &&
            currentGroupState.transactions!.isNotEmpty) {
          return; // Skip re-fetching if we already have complete data
        }
      }
    }

    if (needsLoading && currentGroupState?.group.id != event.groupId) {
      // Only emit loading if we don't have the correct group data already
      emit(const GroupLoading());
    }

    // Fetch the group data
    final result = await getGroupById(
      get_group.GroupIdParams(groupId: event.groupId),
    );

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      group,
    ) {
      // If we already have transactions, keep them
      if (currentGroupState != null &&
          currentGroupState.group.id == event.groupId) {
        // Only update with new group data, keep transactions and debts
        emit(
          SingleGroupLoaded(
            group: group,
            transactions: currentGroupState.transactions,
            debts: currentGroupState.debts,
          ),
        );
      } else {
        // New group, emit with just the group data
        emit(SingleGroupLoaded(group: group));

        // Also load transactions for this group, but don't reload if we're already loading
        if (state is! GroupLoading) {
          add(GetGroupTransactionsEvent(groupId: event.groupId));
          // And calculate debts
          add(CalculateDebtsEvent(groupId: event.groupId));
        }
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
      // After success, trigger data refreshes.
      add(
        GetGroupByIdEvent(groupId: event.groupId),
      ); // Refresh specific group details
      add(const GetGroupsEvent()); // Refresh the list of groups
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

      // Check if we already have debts calculated for this group to avoid unnecessary refreshes
      if (currentGroupState.group.id == event.groupId &&
          currentGroupState.debts != null &&
          currentGroupState.debts!.isNotEmpty) {
        // We already have valid debts data, no need to recalculate
        return;
      }
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

      // Refresh the group data
      add(GetGroupByIdEvent(groupId: event.groupId));

      // Also refresh the transactions
      add(GetGroupTransactionsEvent(groupId: event.groupId));

      // If we were in the groups list view, refresh that too
      if (currentState is GroupsLoaded) {
        add(const GetGroupsEvent());
      }
    });
  }

  Future<void> _onGetGroupTransactions(
    GetGroupTransactionsEvent event,
    Emitter<GroupState> emit,
  ) async {
    // Don't show loading state if we already have a SingleGroupLoaded state
    // Just keep the current state while loading in the background
    final currentState = state;

    // Check if we already have transactions for this group to avoid unnecessary refreshes
    if (currentState is SingleGroupLoaded &&
        currentState.group.id == event.groupId &&
        currentState.transactions != null &&
        currentState.transactions!.isNotEmpty) {
      // We already have valid transaction data, no need to reload
      return;
    }

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
    final result = await getGroupMembers(
      get_members.GroupIdParams(groupId: event.groupId),
    );

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      members,
    ) {
      // Emit a new state with the members data
      emit(GroupMembersLoaded(members: members));
    });
  }
}
