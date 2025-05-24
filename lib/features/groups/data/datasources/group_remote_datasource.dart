import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/features/groups/data/models/expense_group_model.dart';
import 'package:monie/features/groups/data/models/group_member_model.dart';
import 'package:monie/features/groups/data/models/group_transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class GroupRemoteDataSource {
  Future<List<ExpenseGroupModel>> getGroups();
  Future<ExpenseGroupModel> getGroupById(String groupId);
  Future<ExpenseGroupModel> createGroup({
    required String name,
    String? description,
  });
  Future<ExpenseGroupModel> updateGroup({
    required String groupId,
    String? name,
    String? description,
  });
  Future<bool> deleteGroup(String groupId);
  Future<bool> addMember({
    required String groupId,
    required String email,
    required String role,
  });
  Future<bool> removeMember({required String groupId, required String userId});
  Future<bool> updateMemberRole({
    required String groupId,
    required String userId,
    required String role,
  });
  Future<Map<String, double>> calculateDebts(String groupId);
  Future<bool> settleGroup(String groupId);
  Future<List<GroupMemberModel>> getGroupMembers(String groupId);
  Future<double> getGroupTotalAmount(String groupId);
  Future<GroupTransactionModel> addGroupExpense({
    required String groupId,
    required String title,
    required double amount,
    required String description,
    required DateTime date,
    required String paidBy,
    String? categoryName,
    String? color,
  });
  Future<List<GroupTransactionModel>> getGroupTransactions(String groupId);
  Future<bool> approveGroupTransaction({
    required String transactionId,
    required bool approved,
  });
}

class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  final SupabaseClient supabase;

  GroupRemoteDataSourceImpl({required this.supabase});

  @override
  Future<List<ExpenseGroupModel>> getGroups() async {
    try {
      // Get the current user's ID
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw ServerException(message: 'User not authenticated');
      }

      // Query groups where the current user is a member
      final groupsResponse = await supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      if (groupsResponse.isEmpty) {
        return [];
      }

      // Extract group IDs
      final groupIds =
          groupsResponse.map((g) => g['group_id'] as String).toList();

      // Fetch group details
      final groups = await supabase
          .from('groups')
          .select('*')
          .inFilter('group_id', groupIds);

      // Convert to models
      final groupModels =
          groups.map((g) => ExpenseGroupModel.fromJson(g)).toList();

      // Enrich with members and total amounts
      List<ExpenseGroupModel> enrichedGroups = [];
      for (var group in groupModels) {
        final members = await getGroupMembers(group.id);
        final totalAmount = await getGroupTotalAmount(group.id);

        enrichedGroups.add(
          group.copyWith(
            members:
                members
                    .map((m) => '${m.displayName ?? 'Unknown'} (${m.userId})')
                    .toList(),
            totalAmount: totalAmount,
            isSettled: group.isSettled,
          ),
        );
      }

      return enrichedGroups;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ExpenseGroupModel> getGroupById(String groupId) async {
    try {
      final groupResponse =
          await supabase
              .from('groups')
              .select('*')
              .eq('group_id', groupId)
              .single();

      final group = ExpenseGroupModel.fromJson(groupResponse);
      final members = await getGroupMembers(groupId);
      final totalAmount = await getGroupTotalAmount(groupId);

      return group.copyWith(
        members:
            members
                .map((m) => '${m.displayName ?? 'Unknown'} (${m.userId})')
                .toList(),
        totalAmount: totalAmount,
        isSettled: group.isSettled,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ExpenseGroupModel> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw ServerException(message: 'User not authenticated');
      }

      // Create the group
      final insertData = <String, dynamic>{
        'name': name,
        'admin_id': userId,
        'is_settled': false,
      };

      // Only add description if it's not null
      if (description != null) {
        insertData['description'] = description;
      }

      final groupData =
          await supabase.from('groups').insert(insertData).select().single();

      final group = ExpenseGroupModel.fromJson(groupData);

      // Add the creator as an admin member
      await supabase.from('group_members').insert({
        'group_id': group.id,
        'user_id': userId,
        'role': 'admin',
      });

      // Get the user's display name for proper member format
      final userData =
          await supabase
              .from('users')
              .select('display_name')
              .eq('user_id', userId)
              .single();

      final displayName = userData['display_name'] ?? 'Unknown';

      // Return the newly created group
      return group.copyWith(
        members: ['$displayName ($userId)'],
        totalAmount: 0,
        isSettled: false,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ExpenseGroupModel> updateGroup({
    required String groupId,
    String? name,
    String? description,
  }) async {
    try {
      // Update the group
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;

      await supabase.from('groups').update(updates).eq('group_id', groupId);

      // Get the updated group with members and total
      return getGroupById(groupId);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteGroup(String groupId) async {
    try {
      // Check if current user is admin
      final userId = supabase.auth.currentUser?.id;
      final adminCheck =
          await supabase
              .from('groups')
              .select('admin_id')
              .eq('group_id', groupId)
              .eq('admin_id', userId!)
              .single();

      if (adminCheck.isEmpty) {
        throw ServerException(message: 'Only the admin can delete a group');
      }

      // Delete the group (cascade will handle members and transactions)
      await supabase.from('groups').delete().eq('group_id', groupId);
      return true;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> addMember({
    required String groupId,
    required String email,
    required String role,
  }) async {
    try {
      // First check if the email exists in the system
      final userQuery = await supabase
          .from('users')
          .select('user_id, email')
          .eq('email', email);

      if (userQuery.isEmpty) {
        throw ServerException(
          message: 'Email not found. User must register first.',
        );
      }

      final userId = userQuery[0]['user_id'] as String;

      // Check if user is already a member
      final memberCheck = await supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId)
          .eq('user_id', userId);

      if (memberCheck.isNotEmpty) {
        throw ServerException(
          message: 'User is already a member of this group',
        );
      }

      // Add member to the group with specified role
      await supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': role,
      });

      // Send notification to the user
      await supabase.from('notifications').insert({
        'user_id': userId,
        'type': 'group_invitation',
        'title': 'New Group Invitation',
        'message': 'You have been added to a new expense group',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      // Check if current user is admin
      final currentUserId = supabase.auth.currentUser?.id;
      final adminCheck =
          await supabase
              .from('groups')
              .select('admin_id')
              .eq('group_id', groupId)
              .eq('admin_id', currentUserId!)
              .single();

      if (adminCheck.isEmpty && currentUserId != userId) {
        throw ServerException(
          message: 'Only the admin can remove other members',
        );
      }

      // Remove the member
      await supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> updateMemberRole({
    required String groupId,
    required String userId,
    required String role,
  }) async {
    try {
      // Check if current user is admin
      final currentUserId = supabase.auth.currentUser?.id;
      final adminCheck =
          await supabase
              .from('groups')
              .select('admin_id')
              .eq('group_id', groupId)
              .eq('admin_id', currentUserId!)
              .single();

      if (adminCheck.isEmpty) {
        throw ServerException(
          message: 'Only the admin can update member roles',
        );
      }

      // Update the role
      await supabase
          .from('group_members')
          .update({'role': role})
          .eq('group_id', groupId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, double>> calculateDebts(String groupId) async {
    try {
      // Get all transactions for this group
      final groupTransactions = await supabase
          .from('group_transactions')
          .select('transaction_id, status')
          .eq('group_id', groupId)
          .neq('status', 'settled');

      if (groupTransactions.isEmpty) {
        return {};
      }

      // Get the transaction details
      final transactionIds =
          groupTransactions.map((t) => t['transaction_id'] as String).toList();

      final transactions = await supabase
          .from('transactions')
          .select('transaction_id, user_id, amount')
          .inFilter('transaction_id', transactionIds);

      // Get group members
      final members = await getGroupMembers(groupId);

      // Calculate each person's spending and debts
      Map<String, double> memberSpending = {};
      double totalSpent = 0;

      // Initialize spending for each member
      for (var member in members) {
        memberSpending[member.userId] = 0;
      }

      // Calculate what each person has spent
      for (var transaction in transactions) {
        final amount = (transaction['amount'] as num).toDouble();
        final userId = transaction['user_id'] as String;

        if (memberSpending.containsKey(userId)) {
          memberSpending[userId] = (memberSpending[userId] ?? 0) + amount;
          totalSpent += amount;
        }
      }

      // Calculate fair share per person
      final fairShare = totalSpent / members.length;

      // Calculate what each person owes or is owed
      Map<String, double> debts = {};
      for (var member in members) {
        final spent = memberSpending[member.userId] ?? 0;
        debts[member.displayName ?? member.userId] = spent - fairShare;
      }

      return debts;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> settleGroup(String groupId) async {
    try {
      // Mark the group as settled
      await supabase
          .from('groups')
          .update({'is_settled': true})
          .eq('group_id', groupId);

      // Mark all transactions as settled
      await supabase
          .from('group_transactions')
          .update({'status': 'settled'})
          .eq('group_id', groupId);

      // Get group name for notification
      final groupData =
          await supabase
              .from('groups')
              .select('name')
              .eq('group_id', groupId)
              .single();

      final groupName = groupData['name'];

      // Get all group members
      final membersResponse = await supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);

      final List<String> memberIds =
          (membersResponse as List)
              .map((member) => member['user_id'] as String)
              .toList();

      // Create settlement notifications for all members
      final notifications =
          memberIds
              .map(
                (userId) => {
                  'user_id': userId,
                  'type': 'group_settlement',
                  'title': 'Group Settled',
                  'message': 'The group "$groupName" has been settled.',
                  'is_read': false,
                  'created_at': DateTime.now().toIso8601String(),
                },
              )
              .toList();

      if (notifications.isNotEmpty) {
        await supabase.from('notifications').insert(notifications);
      }

      return true;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    try {
      final membersResponse = await supabase
          .from('group_members')
          .select(
            'group_id, user_id, role, users!group_members_user_id_fkey(display_name)',
          )
          .eq('group_id', groupId);

      final members =
          membersResponse.map((m) {
            return GroupMemberModel(
              groupId: m['group_id'],
              userId: m['user_id'],
              role: m['role'],
              displayName: m['users']['display_name'],
            );
          }).toList();

      return members;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<double> getGroupTotalAmount(String groupId) async {
    try {
      // Get all approved transactions for this group
      final transactions = await supabase
          .from('group_transactions')
          .select('transaction_id')
          .eq('group_id', groupId)
          .eq('status', 'approved'); // Only include approved transactions

      if (transactions.isEmpty) {
        return 0;
      }

      // Get the transaction amounts
      final transactionIds =
          transactions.map((t) => t['transaction_id'] as String).toList();

      final amounts = await supabase
          .from('transactions')
          .select('amount')
          .inFilter('transaction_id', transactionIds);

      // Sum up the net total (income - expenses)
      // Income transactions are positive, expense transactions are negative
      double total = 0;
      for (var transaction in amounts) {
        final amount = double.parse(transaction['amount'].toString());
        total +=
            amount; // Direct sum: positive income adds, negative expenses subtract
      }

      return total;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<GroupTransactionModel> addGroupExpense({
    required String groupId,
    required String title,
    required double amount,
    required String description,
    required DateTime date,
    required String paidBy,
    String? categoryName,
    String? color,
  }) async {
    try {
      // Get current user
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw ServerException(message: 'User not authenticated');
      }

      // Get the group admin ID and name
      final groupData =
          await supabase
              .from('groups')
              .select('admin_id, name')
              .eq('group_id', groupId)
              .single();

      final adminId = groupData['admin_id'];
      final groupName = groupData['name'];

      // Get the user's role in the group
      final memberData =
          await supabase
              .from('group_members')
              .select('role')
              .eq('group_id', groupId)
              .eq('user_id', currentUserId)
              .single();

      final userRole = memberData['role'] as String;

      // Determine approval status based on role
      // If admin, automatically approve. If not admin, mark as pending
      final approvalStatus =
          (currentUserId == adminId || userRole == 'admin')
              ? 'approved'
              : 'pending';

      // Set approved_at if auto-approved
      final approvedAt = approvalStatus == 'approved' ? DateTime.now() : null;

      // 1. Create the transaction
      // Determine if this is an income transaction based on amount sign
      final isIncomeTransaction = amount > 0;

      // Store the transaction amount as provided (already signed correctly)
      final transactionAmount = amount;

      final transactionData = {
        'title': title,
        'amount': transactionAmount,
        'description': description,
        'date': date.toIso8601String(),
        'user_id': paidBy, // This must be a valid UUID!
        'category_name': categoryName ?? 'Group',
        'color': color ?? '#4CAF50',
      };

      // Insert the transaction and get its ID
      final transactionResponse =
          await supabase
              .from('transactions')
              .insert(transactionData)
              .select('transaction_id')
              .single();

      final transactionId = transactionResponse['transaction_id'];

      // 2. Create exactly ONE group_transactions link with status and approved_at if approved
      final groupTransactionInsert = {
        'group_id': groupId,
        'transaction_id': transactionId,
        'status': approvalStatus,
        'approved_at': approvedAt?.toIso8601String(),
      };
      await supabase.from('group_transactions').insert(groupTransactionInsert);

      // Create notifications for group members
      if (approvalStatus == 'approved') {
        // If auto-approved, notify all members about the new transaction
        final membersResponse = await supabase
            .from('group_members')
            .select('user_id')
            .eq('group_id', groupId);

        final List<String> memberIds =
            (membersResponse as List)
                .map((member) => member['user_id'] as String)
                .toList();

        final notificationTitle =
            isIncomeTransaction ? 'New Group Income' : 'New Group Expense';
        final notifications =
            memberIds
                .map(
                  (userId) => {
                    'user_id': userId,
                    'amount': amount,
                    'type': 'group_transaction',
                    'title': notificationTitle,
                    'message':
                        '$title in "$groupName" - \$${amount.toStringAsFixed(2)}',
                    'is_read': false,
                    'created_at': DateTime.now().toIso8601String(),
                  },
                )
                .toList();

        if (notifications.isNotEmpty) {
          await supabase.from('notifications').insert(notifications);
        }
      } else {
        // If requires approval, notify group admins
        final adminMembers = await supabase
            .from('group_members')
            .select('user_id')
            .eq('group_id', groupId)
            .eq('role', 'admin');

        final notificationTitle =
            isIncomeTransaction
                ? 'Income Needs Approval'
                : 'Expense Needs Approval';
        final notifications =
            (adminMembers as List)
                .map(
                  (admin) => {
                    'user_id': admin['user_id'],
                    'amount': amount,
                    'type': 'group_transaction',
                    'title': notificationTitle,
                    'message':
                        '$title in "$groupName" - \$${amount.toStringAsFixed(2)}',
                    'is_read': false,
                    'created_at': DateTime.now().toIso8601String(),
                  },
                )
                .toList();

        if (notifications.isNotEmpty) {
          await supabase.from('notifications').insert(notifications);
        }
      }

      // Get all group members for the transaction model
      final groupMembers = await getGroupMembers(groupId);
      final memberIds = groupMembers.map((m) => m.userId).toList();

      // Return the transaction model
      return GroupTransactionModel(
        id: transactionId,
        groupId: groupId,
        title: title,
        amount: transactionAmount,
        description: description,
        date: date,
        paidBy: paidBy,
        splitWith: memberIds,
        approvalStatus: approvalStatus,
        approvedAt: approvedAt,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<GroupTransactionModel>> getGroupTransactions(
    String groupId,
  ) async {
    try {
      // First get all group transactions links
      final groupTransactions = await supabase
          .from('group_transactions')
          .select('transaction_id, status, approved_at')
          .eq('group_id', groupId)
          .order('status');

      if (groupTransactions.isEmpty) {
        return [];
      }

      // Extract transaction IDs
      final transactionIds =
          groupTransactions.map((t) => t['transaction_id'] as String).toList();

      // Get the full transaction details
      final transactions = await supabase
          .from('transactions')
          .select('*, users!transactions_user_id_fkey(display_name)')
          .inFilter('transaction_id', transactionIds);

      // Combine the data to create GroupTransactionModel objects
      final result = <GroupTransactionModel>[];

      for (var i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final groupTransaction = groupTransactions.firstWhere(
          (gt) => gt['transaction_id'] == transaction['transaction_id'],
        );

        // Get the list of members the expense is split with
        // For now we'll just use all group members since the schema doesn't explicitly store this
        final groupMembers = await getGroupMembers(groupId);
        final memberIds = groupMembers.map((m) => m.userId).toList();

        // Create transaction model using the factory method
        final transactionModel = GroupTransactionModel.fromTransactionAndGroup(
          transaction,
          {...groupTransaction, 'group_id': groupId},
        );

        // Add member IDs to split with
        result.add(transactionModel.copyWith(splitWith: memberIds));
      }

      return result;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> approveGroupTransaction({
    required String transactionId,
    required bool approved,
  }) async {
    try {
      // Get the group ID first
      final groupTransactionData =
          await supabase
              .from('group_transactions')
              .select('group_id')
              .eq('transaction_id', transactionId)
              .single();

      final groupId = groupTransactionData['group_id'];

      // Update the transaction status
      await supabase
          .from('group_transactions')
          .update({
            'status': approved ? 'approved' : 'rejected',
            'approved_at': approved ? DateTime.now().toIso8601String() : null,
          })
          .eq('transaction_id', transactionId);

      // Get transaction and group details for notifications
      final transaction =
          await supabase
              .from('transactions')
              .select('title, amount, user_id')
              .eq('transaction_id', transactionId)
              .single();

      final groupData =
          await supabase
              .from('groups')
              .select('name')
              .eq('group_id', groupId)
              .single();

      final title = transaction['title'];
      final amount = transaction['amount'];
      final groupName = groupData['name'];

      // Determine if this is an income transaction
      final isIncomeTransaction = amount > 0;

      // Get all group members
      final membersResponse = await supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);

      final List<String> memberIds =
          (membersResponse as List)
              .map((member) => member['user_id'] as String)
              .toList();

      // Create notifications for all members
      final notificationTitle =
          approved
              ? (isIncomeTransaction ? 'Income Approved' : 'Expense Approved')
              : (isIncomeTransaction ? 'Income Rejected' : 'Expense Rejected');

      final notifications =
          memberIds
              .map(
                (userId) => {
                  'user_id': userId,
                  'amount': amount,
                  'type': 'group_transaction',
                  'title': notificationTitle,
                  'message':
                      '$title in "$groupName" - \$${amount.toStringAsFixed(2)}',
                  'is_read': false,
                  'created_at': DateTime.now().toIso8601String(),
                },
              )
              .toList();

      if (notifications.isNotEmpty) {
        await supabase.from('notifications').insert(notifications);
      }

      return true;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
