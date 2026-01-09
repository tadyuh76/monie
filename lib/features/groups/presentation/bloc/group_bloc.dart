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
    // Check if already have group's data to avoid flashing loading state
    bool needsLoading = true;
    SingleGroupLoaded? currentGroupState;

    if (state is SingleGroupLoaded) {
      currentGroupState = state as SingleGroupLoaded;
      if (currentGroupState.group.id == event.groupId) {
        // Already have this group's data with the same ID, don't show loading
        needsLoading = false;
      }
    }

    if (needsLoading && currentGroupState?.group.id != event.groupId) {
      // Only emit loading if don't have the correct group data already
      emit(const GroupLoading());
    }

    // Always fetch the group data to ensure have the latest information
    final result = await getGroupById(
      get_group.GroupIdParams(groupId: event.groupId),
    );

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      group,
    ) {
      // Don't preserve any existing data - always start fresh
      // This prevents race conditions when manually refreshing
      emit(
        SingleGroupLoaded(
          group: group,
          transactions: null,
          debts: null,
          members: null,
        ),
      );

      // After emitting the group state, automatically load missing data
      // This ensures data loads in the correct sequence: group first, then related data
      add(GetGroupTransactionsEvent(groupId: event.groupId));
      add(CalculateDebtsEvent(groupId: event.groupId));
      add(GetGroupMembersEvent(groupId: event.groupId));
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
    final currentState = state;
    
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
      // If have SingleGroupLoaded, emit it with a success message
      if (currentState is SingleGroupLoaded) {
        emit(currentState.copyWith(successMessage: 'Member added successfully'));
      }
      // Then refresh members
      add(GetGroupMembersEvent(groupId: event.groupId));
    });
  }

  Future<void> _onCalculateDebts(
    CalculateDebtsEvent event,
    Emitter<GroupState> emit,
  ) async {
    // Don't change loading state - just calculate and update debts
    
    print('[GroupBloc] _onCalculateDebts: Starting for groupId ${event.groupId}');
    print('[GroupBloc] Current state: ${state.runtimeType}');
    
    // Calculate debts
    final debtsResult = await calculateDebts(
      calc.GroupIdParams(groupId: event.groupId),
    );

    debtsResult.fold(
      (failure) {
        print('[GroupBloc] _onCalculateDebts: Failed - ${failure.message}');
        // Only emit error if we don't have any state yet
        if (state is! SingleGroupLoaded) {
          emit(GroupError(message: failure.message));
        }
      },
      (debts) {
        print('[GroupBloc] _onCalculateDebts: Success - ${debts.length} debts calculated');
        // Get the CURRENT state at emit time
        final currentState = state;
        
        if (currentState is SingleGroupLoaded && currentState.group.id == event.groupId) {
          print('[GroupBloc] _onCalculateDebts: Emitting updated state with debts');
          // Update existing state with debts
          emit(currentState.copyWith(debts: debts));
        } else if (currentState is GroupLoading || currentState is GroupInitial) {
          print('[GroupBloc] _onCalculateDebts: State is still loading, skipping');
          // Wait - the group is still loading, CalculateDebts will be called again
        } else {
          print('[GroupBloc] _onCalculateDebts: State is ${currentState.runtimeType}, not emitting');
        }
        // If state is something else (like GroupOperationSuccess), 
        // the debts will be loaded when GetGroupByIdEvent is processed
      },
    );
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

    // Don't emit loading - keep current state active during the operation

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
      // Don't emit GroupOperationSuccess yet - wait for data to reload
      // Instead, refresh data first based on current state
      if (currentState is GroupsLoaded) {
        // Refresh the groups list
        add(const GetGroupsEvent());
      } else if (currentState is SingleGroupLoaded) {
        // Refresh all data for the single group view
        add(GetGroupByIdEvent(groupId: event.groupId));
        add(GetGroupTransactionsEvent(groupId: event.groupId));
        add(GetGroupMembersEvent(groupId: event.groupId));
        // Calculate debts will be triggered by GetGroupByIdEvent
      } else {
        // Default: refresh groups
        add(const GetGroupsEvent());
      }
      
      // Now emit success after events are queued
      emit(const GroupOperationSuccess(message: 'Expense added successfully'));
    });
  }

  Future<void> _onGetGroupTransactions(
    GetGroupTransactionsEvent event,
    Emitter<GroupState> emit,
  ) async {
    // Only emit loading if  have no state at all
    if (state is! SingleGroupLoaded && state is! GroupLoading) {
      emit(const GroupLoading());
    }

    final params = get_transactions.GroupIdParams(groupId: event.groupId);
    final result = await getGroupTransactions(params);

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      transactions,
    ) {
      // Get the CURRENT state at emit time, not the old state from when started
      final currentState = state;
      
      if (currentState is SingleGroupLoaded) {
        // Update the current SingleGroupLoaded state with transactions
        final groupState = currentState;

        // Only update if this data is for the correct group
        if (groupState.group.id == event.groupId) {
          emit(groupState.copyWith(transactions: transactions, clearMessage: true));
        } else {
          // Have group data for a different group, get the correct group first
          add(GetGroupByIdEvent(groupId: event.groupId));
        }
      }
      // If no state yet, just wait - the group is likely still loading
      // Don't trigger another GetGroupByIdEvent as it would create a race condition
    });
  }

  Future<void> _onApproveGroupTransaction(
    ApproveGroupTransactionEvent event,
    Emitter<GroupState> emit,
  ) async {
    // Store current state
    final currentState = state;

    // Don't emit loading - keep current state active

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
      
      // If have SingleGroupLoaded, emit it with a success message
      if (currentState is SingleGroupLoaded) {
        emit(currentState.copyWith(successMessage: message));
        
        // Then refresh only the transactions (like member operations do)
        add(GetGroupTransactionsEvent(groupId: currentState.group.id));
        
        // Don't refresh GetGroupsEvent here - it would emit GroupsLoaded and break SingleGroupLoaded state
        // The groups list will be refreshed when user navigates back
      } else {
        // Fallback if not in SingleGroupLoaded state
        emit(GroupOperationSuccess(message: message));
        add(const GetGroupsEvent());
      }
    });
  }

  Future<void> _onGetGroupMembers(
    GetGroupMembersEvent event,
    Emitter<GroupState> emit,
  ) async {
    // Don't show loading if already have group data
    if (state is! SingleGroupLoaded) {
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
        // Get the CURRENT state at emit time, not the old state from when started
        final currentState = state;
        
        // If have a SingleGroupLoaded state, update it with members
        if (currentState is SingleGroupLoaded && currentState.group.id == event.groupId) {
          emit(currentState.copyWith(members: members, clearMessage: true));
        } else if (currentState is SingleGroupLoaded) {
          // Have a different group loaded, get the correct group first
          add(GetGroupByIdEvent(groupId: event.groupId));
        } else {
          // No SingleGroupLoaded state, emit GroupMembersLoaded for pages that need just the members list
          emit(GroupMembersLoaded(members: members));
        }
      },
    );
  }

  Future<void> _onRemoveMember(
    RemoveMemberEvent event,
    Emitter<GroupState> emit,
  ) async {
    final currentState = state;
    
    final result = await removeMember(
      RemoveMemberParams(groupId: event.groupId, userId: event.userId),
    );

    result.fold((failure) => emit(GroupError(message: failure.message)), (
      success,
    ) {
      // If have SingleGroupLoaded, emit it with a success message
      if (currentState is SingleGroupLoaded) {
        emit(currentState.copyWith(successMessage: 'Member removed successfully'));
      }
      // Then refresh members
      add(GetGroupMembersEvent(groupId: event.groupId));
    });
  }

  Future<void> _onUpdateMemberRole(
    UpdateMemberRoleEvent event,
    Emitter<GroupState> emit,
  ) async {
    final currentState = state;
    
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
      // If have SingleGroupLoaded, emit it with a success message
      if (currentState is SingleGroupLoaded) {
        emit(currentState.copyWith(successMessage: 'Member role updated successfully'));
      }
      // Then refresh members
      add(GetGroupMembersEvent(groupId: event.groupId));
    });
  }
}
