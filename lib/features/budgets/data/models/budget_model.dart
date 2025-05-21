import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:uuid/uuid.dart';

class BudgetModel extends Budget {
  const BudgetModel({
    required super.id,
    required super.name,
    required super.totalAmount,
    required super.spentAmount,
    required super.remainingAmount,
    required super.currency,
    required super.startDate,
    required super.endDate,
    super.category,
    required super.progressPercentage,
    required super.dailySavingTarget,
    required super.daysRemaining,
    super.categoryId,
    super.userId,
    super.isRecurring,
    super.isSaving,
    super.frequency,
    super.color,
  });

  // Create a new BudgetModel from Supabase data
  factory BudgetModel.fromSupabaseJson(Map<String, dynamic> json) {
    // Calculate derived values
    final totalAmount =
        json['amount'] != null ? (json['amount'] as num).toDouble() : 0.0;
    final startDate = DateTime.parse(json['start_date']);
    final endDate =
        json['end_date'] != null
            ? DateTime.parse(json['end_date'])
            : startDate.add(const Duration(days: 30));

    // Calculate days remaining from now until end date
    final now = DateTime.now();
    final daysRemaining =
        endDate.difference(now).inDays < 0 ? 0 : endDate.difference(now).inDays;

    // Default to 0 for spent amount if not provided
    final spentAmount = 0.0; // This will be calculated from transactions
    final remainingAmount = totalAmount - spentAmount;

    // Calculate progress percentage (spent / totalAmount)
    final progressPercentage =
        totalAmount > 0 ? (spentAmount / totalAmount * 100) : 0.0;

    // Calculate daily saving target
    final dailySavingTarget =
        daysRemaining > 0 ? remainingAmount / daysRemaining : remainingAmount;

    return BudgetModel(
      id: json['budget_id'],
      userId: json['user_id'],
      name: json['name'] ?? 'Budget', // Default name if not provided
      categoryId: json['category_id'],
      totalAmount: totalAmount,
      spentAmount: spentAmount,
      remainingAmount: remainingAmount,
      currency: json['currency'] ?? 'USD',
      startDate: startDate,
      endDate: endDate,
      isRecurring: json['is_recurring'] ?? false,
      isSaving: json['is_saving'] ?? false,
      frequency: json['frequency'],
      color: json['color'],
      progressPercentage: progressPercentage,
      dailySavingTarget: dailySavingTarget,
      daysRemaining: daysRemaining,
    );
  }

  // Convert to Supabase json format for insertion/update
  Map<String, dynamic> toSupabaseJson() {
    final json = {
      'budget_id': id,
      'user_id': userId,
      'name': name,
      'amount': totalAmount,
      'start_date':
          startDate.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_recurring': isRecurring,
      'is_saving': isSaving,
      'frequency': frequency,
    };

    // Đảm bảo color không null khi lưu vào database
    if (color != null && color!.isNotEmpty) {
      json['color'] = color;
    } else {
      json['color'] = 'FF4CAF50'; // Default to green if no color
    }

    // Only include categoryId if it's not null
    if (categoryId != null) {
      json['category_id'] = categoryId;
    }

    return json;
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      name: json['name'],
      totalAmount: json['totalAmount'].toDouble(),
      spentAmount: json['spentAmount'].toDouble(),
      remainingAmount: json['remainingAmount'].toDouble(),
      currency: json['currency'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      category: json['category'],
      categoryId: json['categoryId'],
      progressPercentage: json['progressPercentage'].toDouble(),
      dailySavingTarget: json['dailySavingTarget'].toDouble(),
      daysRemaining: json['daysRemaining'],
      userId: json['userId'],
      isRecurring: json['isRecurring'] ?? false,
      isSaving: json['isSaving'] ?? false,
      frequency: json['frequency'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'spentAmount': spentAmount,
      'remainingAmount': remainingAmount,
      'currency': currency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'category': category,
      'categoryId': categoryId,
      'progressPercentage': progressPercentage,
      'dailySavingTarget': dailySavingTarget,
      'daysRemaining': daysRemaining,
      'userId': userId,
      'isRecurring': isRecurring,
      'isSaving': isSaving,
      'frequency': frequency,
      'color': color,
    };
  }

  factory BudgetModel.fromEntity(Budget entity) {
    return BudgetModel(
      id: entity.id,
      name: entity.name,
      totalAmount: entity.totalAmount,
      spentAmount: entity.spentAmount,
      remainingAmount: entity.remainingAmount,
      currency: entity.currency,
      startDate: entity.startDate,
      endDate: entity.endDate,
      category: entity.category,
      categoryId: entity.categoryId,
      progressPercentage: entity.progressPercentage,
      dailySavingTarget: entity.dailySavingTarget,
      daysRemaining: entity.daysRemaining,
      userId: entity.userId,
      isRecurring: entity.isRecurring,
      isSaving: entity.isSaving,
      frequency: entity.frequency,
      color: entity.color,
    );
  }

  // Create a new budget with default values
  factory BudgetModel.create({
    required String name,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
    String? userId,
    bool isRecurring = false,
    bool isSaving = false,
    String? frequency,
    String? color,
  }) {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final daysRemaining =
        endDate.difference(now).inDays < 0 ? 0 : endDate.difference(now).inDays;

    return BudgetModel(
      id: id,
      name: name,
      totalAmount: amount,
      spentAmount: 0,
      remainingAmount: amount,
      currency: 'USD', // Default currency
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      progressPercentage: 0,
      dailySavingTarget: daysRemaining > 0 ? amount / daysRemaining : amount,
      daysRemaining: daysRemaining,
      userId: userId,
      isRecurring: isRecurring,
      isSaving: isSaving,
      frequency: frequency,
      color: color,
    );
  }
}
