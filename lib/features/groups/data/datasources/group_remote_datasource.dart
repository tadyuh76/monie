import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/features/groups/data/models/expense_group_model.dart';
import 'package:monie/features/groups/data/models/group_debt_model.dart';
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
  Future<List<GroupDebtModel>> calculateDebts(String groupId);
  Future<bool> settleGroup(String groupId);
  Future<List<GroupMemberModel>> getGroupMembers(String groupId);
  Future<double> getGroupTotalAmount(String groupId);
  Future<GroupTransactionModel> addGroupExpense({
    required String groupId,
    required String title,
    required double amount,
    String? description,
    required DateTime date,
    String? categoryName,
    String? color,
  });
  Future<GroupTransactionModel> addGroupIncome({
    required String groupId,
    required String title,
    required double amount,
    required String description,
    required DateTime date,
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

      // Fetch group details with member count in one query
      final groups = await supabase.from('groups').select('''
        *,
        group_members(count)
      ''').inFilter('group_id', groupIds);

      // Convert to models with enhanced data
      List<ExpenseGroupModel> enrichedGroups = [];
      for (var group in groups) {
        // Get member count from the nested query
        final memberCount = group['group_members'][0]['count'] as int? ?? 0;

        // Calculate amounts efficiently
        final amounts = await _getGroupAmounts(group['group_id']);

        enrichedGroups.add(
          ExpenseGroupModel(
            id: group['group_id'],
            adminId: group['admin_id'],
            name: group['name'],
            description: group['description'],
            isSettled: group['is_settled'] ?? false,
            createdAt: DateTime.parse(
              group['created_at'] ?? DateTime.now().toIso8601String(),
            ),
            memberCount: memberCount,
            totalAmount: amounts['total'] ?? 0,
            activeAmount: amounts['active'] ?? 0,
            settledAmount: amounts['settled'] ?? 0,
          ),
        );
      }

      return enrichedGroups;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // Helper method to get group amounts
  Future<Map<String, double>> _getGroupAmounts(String groupId) async {
    try {
      final groupTransactions = await supabase
          .from('group_transactions')
          .select('transaction_id, status')
          .eq('group_id', groupId);

      if (groupTransactions.isEmpty) {
        return {'total': 0, 'active': 0, 'settled': 0};
      }

      final transactionIds =
          groupTransactions.map((t) => t['transaction_id'] as String).toList();

      final transactions = await supabase
          .from('transactions')
          .select('transaction_id, amount')
          .inFilter('transaction_id', transactionIds);

      double activeAmount = 0;
      double settledAmount = 0;

      for (var transaction in transactions) {
        // Use signed amount: positive for income, negative for expense
        // This way total = income - expense, can be negative if expense > income
        final amount = (transaction['amount'] as num).toDouble();
        final groupTx = groupTransactions.firstWhere(
          (gt) => gt['transaction_id'] == transaction['transaction_id'],
        );
        final status = groupTx['status'];

        if (status == 'approved') {
          activeAmount += amount;
        } else if (status == 'settled') {
          settledAmount += amount;
        }
      }

      return {
        'total': activeAmount + settledAmount,
        'active': activeAmount,
        'settled': settledAmount,
      };
    } catch (e) {
      return {'total': 0, 'active': 0, 'settled': 0};
    }
  }

  @override
  Future<ExpenseGroupModel> getGroupById(String groupId) async {
    try {
      final groupResponse = await supabase
          .from('groups')
          .select('''
        *,
        group_members(count)
      ''')
          .eq('group_id', groupId)
          .single();

      // Get member count from the nested query
      final memberCount = groupResponse['group_members'][0]['count'] as int? ?? 0;

      // Calculate amounts efficiently
      final amounts = await _getGroupAmounts(groupId);

      return ExpenseGroupModel(
        id: groupResponse['group_id'],
        adminId: groupResponse['admin_id'],
        name: groupResponse['name'],
        description: groupResponse['description'],
        isSettled: groupResponse['is_settled'] ?? false,
        createdAt: DateTime.parse(
          groupResponse['created_at'] ?? DateTime.now().toIso8601String(),
        ),
        memberCount: memberCount,
        totalAmount: amounts['total'] ?? 0,
        activeAmount: amounts['active'] ?? 0,
        settledAmount: amounts['settled'] ?? 0,
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

      // Return the newly created group with updated counts
      final amounts = await _getGroupAmounts(group.id);

      return group.copyWith(
        memberCount: 1,
        totalAmount: amounts['total'] ?? 0,
        activeAmount: amounts['active'] ?? 0,
        settledAmount: amounts['settled'] ?? 0,
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

      // TODO: Send notification to the user when FCM is implemented
      // await supabase.from('notifications').insert({
      //   'user_id': userId,
      //   'type': 'group_invitation',
      //   'title': 'New Group Invitation',
      //   'message': 'You have been added to a new group',
      //   'created_at': DateTime.now().toIso8601String(),
      // });

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
  Future<List<GroupDebtModel>> calculateDebts(String groupId) async {
    try {
      // Get all approved transactions for this group
      final groupTransactions = await supabase
          .from('group_transactions')
          .select('transaction_id, status')
          .eq('group_id', groupId)
          .eq('status', 'approved'); // Only count approved transactions

      if (groupTransactions.isEmpty) {
        return [];
      }

      // Get the transaction details
      final transactionIds =
          groupTransactions.map((t) => t['transaction_id'] as String).toList();

      final transactions = await supabase
          .from('transactions')
          .select('transaction_id, user_id, amount')
          .inFilter('transaction_id', transactionIds);

      // Get group members with their details
      final members = await getGroupMembers(groupId);

      if (members.length < 2) {
        return []; // No debts if less than 2 members
      }

      // Calculate each person's spending
      Map<String, double> memberSpending = {};
      Map<String, String> memberNames = {};
      double totalSpent = 0;

      // Initialize spending for each member
      for (var member in members) {
        memberSpending[member.userId] = 0;
        memberNames[member.userId] =
            member.displayName ?? member.email.split('@')[0];
      }

      // Calculate what each person has spent (expenses are negative, income is positive)
      for (var transaction in transactions) {
        final amount = (transaction['amount'] as num).toDouble().abs();
        final userId = transaction['user_id'] as String;

        if (memberSpending.containsKey(userId)) {
          memberSpending[userId] = (memberSpending[userId] ?? 0) + amount;
          totalSpent += amount;
        }
      }

      // Calculate fair share per person
      final fairShare = totalSpent / members.length;

      // Calculate net balance for each person
      Map<String, double> balances = {};
      for (var member in members) {
        final spent = memberSpending[member.userId] ?? 0;
        balances[member.userId] =
            spent - fairShare; // Positive = owed, Negative = owes
      }

      // Convert balances to debt list using simplify debts algorithm
      List<GroupDebtModel> debts = [];

      // Separate creditors (owed money) and debtors (omoney)
      List<MapEntry<String, double>> creditors = [];
      List<MapEntry<String, double>> debtors = [];

      balances.forEach((userId, balance) {
        if (balance > 0.01) {
          // Owed money (creditor)
          creditors.add(MapEntry(userId, balance));
        } else if (balance < -0.01) {
          // Owes money (debtor)
          debtors.add(MapEntry(userId, balance.abs()));
        }
      });

      // Sort by amount descending
      creditors.sort((a, b) => b.value.compareTo(a.value));
      debtors.sort((a, b) => b.value.compareTo(a.value));

      // Simplify debts using greedy algorithm
      int creditorIndex = 0;
      int debtorIndex = 0;

      while (creditorIndex < creditors.length &&
          debtorIndex < debtors.length) {
        final creditor = creditors[creditorIndex];
        final debtor = debtors[debtorIndex];

        final settleAmount = creditor.value < debtor.value
            ? creditor.value
            : debtor.value;

        if (settleAmount > 0.01) {
          // Create debt from debtor to creditor
          debts.add(
            GroupDebtModel(
              fromUserId: debtor.key,
              fromUserName: memberNames[debtor.key] ?? 'Unknown',
              toUserId: creditor.key,
              toUserName: memberNames[creditor.key] ?? 'Unknown',
              amount: settleAmount,
            ),
          );

          // Update remaining amounts
          creditors[creditorIndex] =
              MapEntry(creditor.key, creditor.value - settleAmount);
          debtors[debtorIndex] =
              MapEntry(debtor.key, debtor.value - settleAmount);
        }

        // Move to next person if current one is settled
        if (creditors[creditorIndex].value < 0.01) creditorIndex++;
        if (debtors[debtorIndex].value < 0.01) debtorIndex++;
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
            'user_id, role, users!group_members_user_id_fkey(email, display_name, profile_image_url)',
          )
          .eq('group_id', groupId);

      final members = membersResponse.map((m) {
        final userData = m['users'];
        return GroupMemberModel(
          userId: m['user_id'],
          email: userData['email'] ?? '',
          displayName: userData['display_name'],
          profileImageUrl: userData['profile_image_url'],
          role: m['role'],
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
    String? description,
    required DateTime date,
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
        'user_id': currentUserId,
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
        // If auto-approved, notify all members about the new transaction (except creator)
        final membersResponse = await supabase
            .from('group_members')
            .select('user_id')
            .eq('group_id', groupId);

        final List<String> memberIds =
            (membersResponse as List)
                .map((member) => member['user_id'] as String)
                .where((id) => id != currentUserId) // Exclude creator
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

        // Send push notifications to all members except creator
        if (memberIds.isNotEmpty) {
          await _sendGroupNotification(
            userIds: memberIds,
            title: notificationTitle,
            body: '$title in "$groupName" - \$${amount.abs().toStringAsFixed(2)}',
            data: {
              'type': 'group_transaction',
              'group_id': groupId,
              'group_name': groupName,
            },
          );
        }
      } else {
        // If requires approval, notify all members except creator
        final membersResponse = await supabase
            .from('group_members')
            .select('user_id')
            .eq('group_id', groupId);

        final List<String> memberIds =
            (membersResponse as List)
                .map((member) => member['user_id'] as String)
                .where((id) => id != currentUserId) // Exclude creator
                .toList();

        final notificationTitle =
            isIncomeTransaction
                ? 'Income Needs Approval'
                : 'Expense Needs Approval';
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

        // Send push notifications to all members except creator
        if (memberIds.isNotEmpty) {
          await _sendGroupNotification(
            userIds: memberIds,
            title: notificationTitle,
            body: '$title in "$groupName" - \$${amount.abs().toStringAsFixed(2)}',
            data: {
              'type': 'group_transaction',
              'group_id': groupId,
              'group_name': groupName,
              'needs_approval': 'true',
            },
          );
        }
      }

      // Get all group members for the transaction model
      // Get user details for display
      final userData = await supabase
          .from('users')
          .select('display_name, email')
          .eq('user_id', currentUserId)
          .single();

      // Return the transaction model
      return GroupTransactionModel(
        id: transactionId,
        groupId: groupId,
        transactionId: transactionId,
        title: title,
        amount: amount,
        description: description,
        date: date,
        paidByUserId: currentUserId,
        paidByUserName: userData['display_name'] ?? userData['email'] ?? 'Unknown',
        status: approvalStatus,
        approvedAt: approvedAt,
        categoryName: categoryName,
        color: color,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<GroupTransactionModel> addGroupIncome({
    required String groupId,
    required String title,
    required double amount,
    required String description,
    required DateTime date,
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
      final groupData = await supabase
          .from('groups')
          .select('admin_id, name')
          .eq('group_id', groupId)
          .single();

      final adminId = groupData['admin_id'];
      final groupName = groupData['name'];

      // Get the user's role in the group
      final memberData = await supabase
          .from('group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', currentUserId)
          .single();

      final userRole = memberData['role'] as String;

      // Determine approval status based on role
      final approvalStatus =
          (currentUserId == adminId || userRole == 'admin')
              ? 'approved'
              : 'pending';

      final approvedAt = approvalStatus == 'approved' ? DateTime.now() : null;

      // Create the income transaction (amount is positive for income)
      final transactionData = {
        'title': title,
        'amount': amount.abs(), // Ensure positive for income
        'description': description,
        'date': date.toIso8601String(),
        'user_id': currentUserId,
        'category_name': categoryName ?? 'Group Income',
        'color': color ?? '#4CAF50',
      };

      final transactionResponse = await supabase
          .from('transactions')
          .insert(transactionData)
          .select('transaction_id')
          .single();

      final transactionId = transactionResponse['transaction_id'];

      // Create group_transactions link
      final groupTransactionInsert = {
        'group_id': groupId,
        'transaction_id': transactionId,
        'status': approvalStatus,
        'approved_at': approvedAt?.toIso8601String(),
      };
      await supabase.from('group_transactions').insert(groupTransactionInsert);

      // Create notifications
      if (approvalStatus == 'approved') {
        final membersResponse = await supabase
            .from('group_members')
            .select('user_id')
            .eq('group_id', groupId);

        final List<String> memberIds = (membersResponse as List)
            .map((member) => member['user_id'] as String)
            .toList();

        final notifications = memberIds
            .map(
              (userId) => {
                'user_id': userId,
                'amount': amount,
                'type': 'group_transaction',
                'title': 'New Group Income',
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
        final adminMembers = await supabase
            .from('group_members')
            .select('user_id')
            .eq('group_id', groupId)
            .eq('role', 'admin');

        final notifications = (adminMembers as List)
            .map(
              (admin) => {
                'user_id': admin['user_id'],
                'amount': amount,
                'type': 'group_transaction',
                'title': 'Income Needs Approval',
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

      // Get user details for display
      final userData = await supabase
          .from('users')
          .select('display_name, email')
          .eq('user_id', currentUserId)
          .single();

      // Return the transaction model
      return GroupTransactionModel(
        id: transactionId,
        groupId: groupId,
        transactionId: transactionId,
        title: title,
        amount: amount,
        description: description,
        date: date,
        paidByUserId: currentUserId,
        paidByUserName: userData['display_name'] ?? userData['email'] ?? 'Unknown',
        status: approvalStatus,
        approvedAt: approvedAt,
        categoryName: categoryName,
        color: color,
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
      // Get all group transactions with full details using a join
      final data = await supabase
          .from('group_transactions')
          .select('''
            group_transaction_id,
            group_id,
            transaction_id,
            status,
            approved_at,
            transactions!inner(
              title,
              amount,
              description,
              date,
              user_id,
              category_name,
              color,
              users!transactions_user_id_fkey(
                display_name
              )
            )
          ''')
          .eq('group_id', groupId)
          .order('date', referencedTable: 'transactions', ascending: false);

      return data.map((json) {
        final transaction = json['transactions'];
        final user = transaction['users'];
        
        return GroupTransactionModel(
          id: json['group_transaction_id'],
          groupId: json['group_id'],
          transactionId: json['transaction_id'],
          title: transaction['title'],
          amount: (transaction['amount'] as num).toDouble(),
          description: transaction['description'],
          date: DateTime.parse(transaction['date']),
          paidByUserId: transaction['user_id'],
          paidByUserName: user?['display_name'] ?? 'Unknown',
          categoryName: transaction['category_name'],
          color: transaction['color'],
          status: json['status'],
          approvedAt: json['approved_at'] != null
              ? DateTime.parse(json['approved_at'])
              : null,
        );
      }).toList();
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
              .maybeSingle();

      if (groupTransactionData == null) {
        throw ServerException(message: 'Group transaction not found');
      }

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
              .maybeSingle();

      if (transaction == null) {
        throw ServerException(message: 'Transaction not found');
      }

      final groupData =
          await supabase
              .from('groups')
              .select('name')
              .eq('group_id', groupId)
              .maybeSingle();

      if (groupData == null) {
        throw ServerException(message: 'Group not found');
      }

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

      // Create notification title
      final notificationTitle =
          approved
              ? (isIncomeTransaction ? 'Income Approved' : 'Expense Approved')
              : (isIncomeTransaction ? 'Income Rejected' : 'Expense Rejected');

      // Create notifications for all members
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

      // Send push notifications to all members (excluding self will be handled by _sendGroupNotification)
      await _sendGroupNotification(
        userIds: memberIds,
        title: notificationTitle,
        body: '$title in "$groupName" - \$${amount.abs().toStringAsFixed(2)}',
        data: {
          'type': 'group_transaction',
          'group_id': groupId,
          'group_name': groupName,
          'status': approved ? 'approved' : 'rejected',
        },
      );

      return true;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  /// Send push notification via edge function to multiple users
  Future<void> _sendGroupNotification({
    required List<String> userIds,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get current user ID to exclude from notifications
      final currentUserId = supabase.auth.currentUser?.id;
      
      // Filter out current user - don't send notification to yourself
      final recipientIds = userIds.where((id) => id != currentUserId).toList();
      
      if (recipientIds.isEmpty) {
        print('No recipients after filtering current user');
        return;
      }
      
      // Fetch FCM tokens for the specified users (excluding current user)
      final tokensResponse = await supabase
          .from('users')
          .select('fcm_token')
          .inFilter('user_id', recipientIds)
          .not('fcm_token', 'is', null);

      final List<String> tokens =
          (tokensResponse as List)
              .where((user) => user['fcm_token'] != null)
              .map((user) => user['fcm_token'] as String)
              .toList();

      if (tokens.isEmpty) {
        print('No FCM tokens found for notification');
        return;
      }

      print('Sending notification to ${tokens.length} device(s) (excluding self)');

      // Call edge function to send push notification
      await supabase.functions.invoke(
        'send-group-notification',
        body: {
          'tokens': tokens,
          'title': title,
          'body': body,
          'data': data,
        },
      );

      print('Push notification sent successfully');
    } catch (e) {
      // Don't throw error - notification failure shouldn't block the main operation
      print('Failed to send push notification: $e');
    }
  }
}
