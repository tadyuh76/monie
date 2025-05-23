import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:uuid/uuid.dart';

class BudgetModel extends Budget {
  // budgetId can be null for a new model before it's saved to the DB
  const BudgetModel({
    String? budgetId, // Made nullable to handle new models before saving
    required super.userId,
    required super.name,
    required super.amount,
    required super.startDate,
    super.endDate,
    super.isRecurring,
    super.isSaving,
    super.frequency,
    super.color,
    super.spent,
  }) : super(
         budgetId: budgetId ?? '',
       ); // Pass empty string if null, entity expects non-null

  // Create a new BudgetModel from Supabase data
  factory BudgetModel.fromSupabaseJson(Map<String, dynamic> json) {
    final amount =
        json['amount'] != null ? (json['amount'] as num).toDouble() : 0.0;
    final startDate = DateTime.parse(json['start_date']);
    final endDate =
        json['end_date'] != null
            ? DateTime.parse(json['end_date'])
            : startDate.add(const Duration(days: 30));

    // Parse spent amount if available
    double? spent;
    if (json['spent'] != null) {
      spent = (json['spent'] as num).toDouble();
    }

    return BudgetModel(
      budgetId: json['budget_id'],
      userId: json['user_id'],
      name: json['name'] ?? 'Budget', // Default name if not provided
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      isRecurring: json['is_recurring'] ?? false,
      isSaving: json['is_saving'] ?? false,
      frequency: json['frequency'],
      color: json['color'],
      spent: spent,
    );
  }

  // Convert to Supabase json format for insertion/update
  Map<String, dynamic> toSupabaseJson() {
    final json = {
      'budget_id': budgetId,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'start_date':
          startDate.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'end_date': endDate?.toIso8601String().split('T')[0],
      'is_recurring': isRecurring,
      'is_saving': isSaving,
      'frequency': frequency,
    };

    // Ensure color is not null when saving to database
    if (color != null && color!.isNotEmpty) {
      json['color'] = color;
    } else {
      json['color'] = 'FF4CAF50'; // Default to green if no color
    }

    return json;
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    double? spent;
    if (json['spent'] != null) {
      spent = (json['spent'] as num).toDouble();
    }

    return BudgetModel(
      budgetId: json['budget_id'],
      userId: json['user_id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isRecurring: json['is_recurring'] ?? false,
      isSaving: json['is_saving'] ?? false,
      frequency: json['frequency'],
      color: json['color'],
      spent: spent,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'name': name,
      'amount': amount,
      'start_date': startDate.toIso8601String().split('T')[0], // Date only
      'is_recurring': isRecurring,
      'is_saving': isSaving,
    };
    if (budgetId.isNotEmpty) {
      // Only include budget_id if it exists (for updates)
      data['budget_id'] = budgetId;
    }
    if (endDate != null) {
      data['end_date'] = endDate!.toIso8601String().split('T')[0]; // Date only
    }
    if (frequency != null) {
      data['frequency'] = frequency;
    }
    if (color != null) {
      data['color'] = color;
    }
    // spent is calculated from transactions, don't include in JSON for database
    return data;
  }

  factory BudgetModel.fromEntity(Budget entity) {
    return BudgetModel(
      budgetId: entity.budgetId, // Entity will always have a budgetId
      userId: entity.userId,
      name: entity.name,
      amount: entity.amount,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isRecurring: entity.isRecurring,
      isSaving: entity.isSaving,
      frequency: entity.frequency,
      color: entity.color,
      spent: entity.spent,
    );
  }

  // Create a new budget with default values
  factory BudgetModel.create({
    required String name,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
    bool isRecurring = false,
    bool isSaving = false,
    String? frequency,
    String? color,
  }) {
    final id = const Uuid().v4();

    return BudgetModel(
      budgetId: id,
      userId: userId!,
      name: name,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      isRecurring: isRecurring,
      isSaving: isSaving,
      frequency: frequency,
      color: color,
    );
  }
}

// Extension to provide computed properties for Budget
extension BudgetExtension on Budget {
  // Get the effective end date (either the actual end date or a default)
  DateTime get effectiveEndDate =>
      endDate ?? startDate.add(const Duration(days: 30));

  // Calculate days remaining from now until end date
  int get daysRemaining {
    final now = DateTime.now();
    return effectiveEndDate.difference(now).inDays < 0
        ? 0
        : effectiveEndDate.difference(now).inDays;
  }

  // Calculate spent amount (this would be fetched from transactions in a real app)
  double get spentAmount =>
      0.0; // Placeholder - should be calculated from transactions

  // Calculate remaining amount
  double get remainingAmount => amount - spentAmount;

  // Calculate progress percentage
  double get progressPercentage =>
      amount > 0 ? (spentAmount / amount * 100) : 0.0;

  // Calculate daily saving target
  double get dailySavingTarget =>
      daysRemaining > 0 ? remainingAmount / daysRemaining : remainingAmount;
}
