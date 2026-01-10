import 'package:monie/core/constants/transaction_categories.dart';
import 'package:monie/features/speech_to_command/domain/entities/speech_command.dart';

/// Utility class to parse natural language commands into SpeechCommand
/// Supports both Vietnamese and English
class CommandParser {
  // Vietnamese keywords
  static const List<String> vietnameseExpenseKeywords = [
    'chi',
    'tiêu',
    'mua',
    'thanh toán',
    'trả',
    'expense',
    'spend',
  ];

  static const List<String> vietnameseIncomeKeywords = [
    'thu',
    'nhận',
    'lương',
    'tiền',
    'income',
    'earn',
    'receive',
  ];

  static const List<String> vietnameseCategoryKeywords = [
    'cho',
    'về',
    'category',
    'loại',
  ];

  // Category mappings (Vietnamese to English)
  static const Map<String, String> categoryMappings = {
    // Expense categories
    'ăn uống': 'Dining',
    'dining': 'Dining',
    'thức ăn': 'Dining',
    'food': 'Dining',
    'mua sắm': 'Shopping',
    'shopping': 'Shopping',
    'tạp hóa': 'Groceries',
    'groceries': 'Groceries',
    'grocery': 'Groceries',
    'đi lại': 'Transport',
    'transport': 'Transport',
    'giao thông': 'Transport',
    'xăng': 'Transport',
    'gas': 'Transport',
    'giải trí': 'Entertainment',
    'entertainment': 'Entertainment',
    'y tế': 'Healthcare',
    'healthcare': 'Healthcare',
    'sức khỏe': 'Healthcare',
    'health': 'Healthcare',
    'nhà ở': 'Housing',
    'housing': 'Housing',
    'thuê nhà': 'Rent',
    'rent': 'Rent',
    'điện': 'Electricity',
    'electricity': 'Electricity',
    'hóa đơn': 'Bills',
    'bills': 'Bills',
    'bill': 'Bills',
    'giáo dục': 'Education',
    'education': 'Education',
    'học': 'Education',
    'study': 'Education',
    'quà tặng': 'Gifts',
    'gifts': 'Gifts',
    'gift': 'Gifts',
    'du lịch': 'Travel',
    'travel': 'Travel',
    'công nghệ': 'Technology',
    'technology': 'Technology',
    'tech': 'Technology',
    'đầu tư': 'Investment',
    'investment': 'Investment',
    'bảo hiểm': 'Insurance',
    'insurance': 'Insurance',
    'nợ': 'Debt',
    'debt': 'Debt',
    'vay': 'Loans',
    'loans': 'Loans',
    'loan': 'Loans',
    'thú cưng': 'Pets',
    'pets': 'Pets',
    'pet': 'Pets',
    'từ thiện': 'Donate',
    'donate': 'Donate',
    'donation': 'Donate',
    'thuế': 'Tax',
    'tax': 'Tax',
    'tiết kiệm': 'Saving',
    'saving': 'Saving',
    'savings': 'Saving',
    // Income categories
    'lương': 'Salary',
    'salary': 'Salary',
    'học bổng': 'Scholarship',
    'scholarship': 'Scholarship',
    'cổ phiếu': 'Stock',
    'stock': 'Stock',
    'hoa hồng': 'Commission',
    'commission': 'Commission',
    'trợ cấp': 'Allowance',
    'allowance': 'Allowance',
    'hỗ trợ gia đình': 'Family Support',
    'family support': 'Family Support',
  };

  /// Parse text command into SpeechCommand
  static SpeechCommand parse(String text) {
    final normalizedText = text.toLowerCase().trim();
    
    // Determine if it's income or expense
    bool isIncome = false;
    for (final keyword in vietnameseIncomeKeywords) {
      if (normalizedText.contains(keyword)) {
        isIncome = true;
        break;
      }
    }

    // Extract amount
    double? amount = _extractAmount(normalizedText);
    if (amount == null) {
      // Try to extract from numbers in the text
      final numbers = _extractNumbers(text);
      if (numbers.isNotEmpty) {
        amount = numbers.first;
      }
    }

    // Extract category
    String? categoryName = _extractCategory(normalizedText);

    // Extract description (remaining text after removing amount and category keywords)
    String? description = _extractDescription(text, normalizedText, categoryName);

    return SpeechCommand(
      amount: amount ?? 0,
      categoryName: categoryName,
      description: description,
      isIncome: isIncome,
    );
  }

  /// Extract amount from text
  /// Handles Vietnamese and English number formats including:
  /// - Plain numbers: 50000, 50.000, 50 000
  /// - Shortcuts: 50k, 50K, 1tr, 1m, 1M
  /// - Vietnamese words: 50 nghìn, 50 ngàn, 1 triệu, 2 trăm
  /// - English words: 50 thousand, 1 million, 2 hundred
  static double? _extractAmount(String text) {
    // First, try to match number with multiplier suffix/word
    final amountWithMultiplier = _extractAmountWithMultiplier(text);
    if (amountWithMultiplier != null && amountWithMultiplier > 0) {
      return amountWithMultiplier;
    }

    // Fallback: Pattern for number formats: "50000", "50.000", "50 000", "50,000"
    final patterns = [
      RegExp(r'(\d{1,3}(?:[.,\s]\d{3})*(?:\.\d+)?)'),
      RegExp(r'(\d+(?:\.\d+)?)'),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        // Remove thousand separators (dots, commas, spaces)
        final numberStr = match.group(1)?.replaceAll(RegExp(r'[.,\s]'), '');
        if (numberStr != null) {
          final amount = double.tryParse(numberStr);
          if (amount != null && amount > 0) {
            return amount;
          }
        }
      }
    }

    return null;
  }

  /// Extract amount with multiplier words/suffixes
  /// Supports: k, K, nghìn, ngàn, thousand, tr, triệu, million, m, M, trăm, hundred
  static double? _extractAmountWithMultiplier(String text) {
    // Patterns for number + multiplier (handles both suffix and word forms)
    final multiplierPatterns = [
      // Vietnamese: "50k", "50K", "1tr", "1m", "1M" (suffix form, no space)
      RegExp(r'(\d+(?:[.,]\d+)?)\s*(k|K|tr|triệu|m|M|nghìn|ngàn|trăm)\b', caseSensitive: false),
      // Vietnamese with space: "50 nghìn", "1 triệu", "2 trăm"
      RegExp(r'(\d+(?:[.,]\d+)?)\s+(nghìn|ngàn|triệu|trăm|thousand|million|hundred)\b', caseSensitive: false),
      // English: "50 thousand", "1 million", "2 hundred"
      RegExp(r'(\d+(?:[.,]\d+)?)\s+(thousand|million|hundred)\b', caseSensitive: false),
    ];

    // Multiplier values
    const multipliers = {
      'k': 1000.0,
      'nghìn': 1000.0,
      'ngàn': 1000.0,
      'thousand': 1000.0,
      'tr': 1000000.0,
      'triệu': 1000000.0,
      'm': 1000000.0,
      'million': 1000000.0,
      'trăm': 100.0,
      'hundred': 100.0,
    };

    for (final pattern in multiplierPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final numberStr = match.group(1)?.replaceAll(',', '.');
        final multiplierKey = match.group(2)?.toLowerCase();

        if (numberStr != null && multiplierKey != null) {
          final baseAmount = double.tryParse(numberStr);
          final multiplier = multipliers[multiplierKey];

          if (baseAmount != null && multiplier != null) {
            return baseAmount * multiplier;
          }
        }
      }
    }

    return null;
  }

  /// Extract all numbers from text
  static List<double> _extractNumbers(String text) {
    final pattern = RegExp(r'\d+(?:\.\d+)?');
    final matches = pattern.allMatches(text);
    return matches
        .map((m) => double.tryParse(m.group(0) ?? ''))
        .whereType<double>()
        .where((n) => n > 0)
        .toList();
  }

  /// Extract category from text
  static String? _extractCategory(String normalizedText) {
    // Check for category keywords
    for (final entry in categoryMappings.entries) {
      if (normalizedText.contains(entry.key)) {
        // Verify the category exists in TransactionCategories
        final category = TransactionCategories.getCategoryByName(entry.value);
        if (category != null) {
          return entry.value;
        }
      }
    }

    // Try to find category after keywords like "cho", "về", "for", "on"
    for (final keyword in vietnameseCategoryKeywords) {
      final index = normalizedText.indexOf(keyword);
      if (index != -1) {
        final afterKeyword = normalizedText.substring(index + keyword.length).trim();
        for (final entry in categoryMappings.entries) {
          if (afterKeyword.contains(entry.key)) {
            final category = TransactionCategories.getCategoryByName(entry.value);
            if (category != null) {
              return entry.value;
            }
          }
        }
      }
    }

    return null;
  }

  /// Extract description from text
  static String? _extractDescription(
    String originalText,
    String normalizedText,
    String? categoryName,
  ) {
    // Remove amount patterns
    String description = originalText;
    description = description.replaceAll(RegExp(r'\d+(?:[.\s]\d{3})*(?:\.\d+)?'), '');
    
    // Remove category keywords
    if (categoryName != null) {
      for (final entry in categoryMappings.entries) {
        if (entry.value == categoryName) {
          description = description.replaceAll(RegExp(entry.key, caseSensitive: false), '');
        }
      }
    }

    // Remove common keywords
    final allKeywords = [
      ...vietnameseExpenseKeywords,
      ...vietnameseIncomeKeywords,
      ...vietnameseCategoryKeywords,
    ];
    for (final keyword in allKeywords) {
      description = description.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }

    // Clean up
    description = description.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    if (description.isEmpty || description.length < 3) {
      return null;
    }

    return description;
  }
}

