import 'package:flutter/material.dart';

/// This class provides comprehensive lists of income and expense categories with their color codes
class TransactionCategories {
  // ==================== INCOME CATEGORIES ====================
  static final List<Map<String, dynamic>> incomeCategories = [
    // Employment Income
    {'name': 'Salary', 'color': '#4CAF50', 'icon': Icons.work},
    {'name': 'Wages', 'color': '#43A047', 'icon': Icons.monetization_on},
    {'name': 'Bonus', 'color': '#388E3C', 'icon': Icons.star},
    {'name': 'Commission', 'color': '#2E7D32', 'icon': Icons.trending_up},
    {'name': 'Overtime', 'color': '#1B5E20', 'icon': Icons.schedule},
    {'name': 'Tips', 'color': '#81C784', 'icon': Icons.thumb_up},

    // Business Income
    {'name': 'Business Profit', 'color': '#00BCD4', 'icon': Icons.business},
    {'name': 'Freelance', 'color': '#00ACC1', 'icon': Icons.laptop},
    {'name': 'Self-Employment', 'color': '#0097A7', 'icon': Icons.person},
    {
      'name': 'Side Hustle',
      'color': '#00838F',
      'icon': Icons.volunteer_activism,
    },
    {'name': 'Consulting', 'color': '#006064', 'icon': Icons.support_agent},

    // Investment Income
    {'name': 'Dividends', 'color': '#3F51B5', 'icon': Icons.pie_chart},
    {'name': 'Interest', 'color': '#3949AB', 'icon': Icons.account_balance},
    {'name': 'Capital Gains', 'color': '#303F9F', 'icon': Icons.trending_up},
    {'name': 'Rental Income', 'color': '#283593', 'icon': Icons.home},
    {'name': 'Royalties', 'color': '#1A237E', 'icon': Icons.copyright},
    {'name': 'Stocks', 'color': '#7986CB', 'icon': Icons.show_chart},
    {'name': 'Crypto', 'color': '#9FA8DA', 'icon': Icons.currency_bitcoin},
    {'name': 'P2P Lending', 'color': '#C5CAE9', 'icon': Icons.handshake},

    // Retirement Income
    {
      'name': 'Pension',
      'color': '#FF9800',
      'icon': Icons.account_balance_wallet,
    },
    {'name': 'Social Security', 'color': '#FB8C00', 'icon': Icons.security},
    {'name': '401(k)/IRA', 'color': '#F57C00', 'icon': Icons.savings},
    {'name': 'Annuity', 'color': '#EF6C00', 'icon': Icons.calendar_today},

    // Government Benefits
    {'name': 'Tax Refund', 'color': '#9C27B0', 'icon': Icons.receipt_long},
    {'name': 'Unemployment', 'color': '#8E24AA', 'icon': Icons.attach_money},
    {'name': 'Child Support', 'color': '#7B1FA2', 'icon': Icons.child_care},
    {'name': 'Disability', 'color': '#6A1B9A', 'icon': Icons.accessible},
    {'name': 'Food Stamps', 'color': '#4A148C', 'icon': Icons.fastfood},
    {'name': 'Housing Assistance', 'color': '#CE93D8', 'icon': Icons.house},

    // Gifts & Support
    {'name': 'Gift', 'color': '#673AB7', 'icon': Icons.card_giftcard},
    {
      'name': 'Family Support',
      'color': '#5E35B1',
      'icon': Icons.family_restroom,
    },
    {'name': 'Inheritance', 'color': '#512DA8', 'icon': Icons.account_balance},
    {'name': 'Alimony', 'color': '#4527A0', 'icon': Icons.history_edu},
    {'name': 'Donations', 'color': '#311B92', 'icon': Icons.volunteer_activism},

    // Sales
    {'name': 'Sale of Items', 'color': '#607D8B', 'icon': Icons.local_offer},
    {'name': 'Garage Sale', 'color': '#546E7A', 'icon': Icons.store},
    {'name': 'Online Sales', 'color': '#455A64', 'icon': Icons.computer},
    {'name': 'Vehicle Sale', 'color': '#37474F', 'icon': Icons.directions_car},
    {'name': 'Property Sale', 'color': '#263238', 'icon': Icons.domain},

    // Miscellaneous Income
    {'name': 'Lottery', 'color': '#E91E63', 'icon': Icons.casino},
    {'name': 'Gambling', 'color': '#D81B60', 'icon': Icons.sports_esports},
    {'name': 'Cash Back', 'color': '#C2185B', 'icon': Icons.replay},
    {
      'name': 'Insurance Payout',
      'color': '#AD1457',
      'icon': Icons.health_and_safety,
    },
    {'name': 'Legal Settlement', 'color': '#880E4F', 'icon': Icons.gavel},
    {'name': 'Awards', 'color': '#F48FB1', 'icon': Icons.emoji_events},
    {'name': 'Scholarship', 'color': '#F8BBD0', 'icon': Icons.school},
    {'name': 'Grants', 'color': '#FCE4EC', 'icon': Icons.fact_check},
    {
      'name': 'Reimbursement',
      'color': '#FFEB3B',
      'icon': Icons.assignment_return,
    },
    {'name': 'Other Income', 'color': '#9E9E9E', 'icon': Icons.more_horiz},
  ];

  // ==================== EXPENSE CATEGORIES ====================
  static final List<Map<String, dynamic>> expenseCategories = [
    // Housing
    {'name': 'Rent', 'color': '#F44336', 'icon': Icons.home},
    {'name': 'Mortgage', 'color': '#E53935', 'icon': Icons.house},
    {'name': 'Property Tax', 'color': '#D32F2F', 'icon': Icons.description},
    {'name': 'HOA Fees', 'color': '#C62828', 'icon': Icons.people},
    {'name': 'Maintenance', 'color': '#B71C1C', 'icon': Icons.build},
    {'name': 'Furniture', 'color': '#EF9A9A', 'icon': Icons.chair},
    {'name': 'Home Insurance', 'color': '#FFCDD2', 'icon': Icons.policy},

    // Utilities
    {'name': 'Electricity', 'color': '#FF9800', 'icon': Icons.bolt},
    {'name': 'Water', 'color': '#2196F3', 'icon': Icons.water_drop},
    {'name': 'Gas', 'color': '#FFA726', 'icon': Icons.local_fire_department},
    {'name': 'Internet', 'color': '#0D47A1', 'icon': Icons.wifi},
    {'name': 'Phone', 'color': '#00BFA5', 'icon': Icons.phone_android},
    {'name': 'Streaming Services', 'color': '#FF5252', 'icon': Icons.movie},
    {'name': 'Cable TV', 'color': '#3949AB', 'icon': Icons.tv},
    {'name': 'Garbage', 'color': '#795548', 'icon': Icons.delete},

    // Food & Dining
    {'name': 'Groceries', 'color': '#8BC34A', 'icon': Icons.shopping_basket},
    {'name': 'Restaurants', 'color': '#FFA000', 'icon': Icons.restaurant},
    {'name': 'Fast Food', 'color': '#FF6F00', 'icon': Icons.fastfood},
    {'name': 'Coffee Shops', 'color': '#A1887F', 'icon': Icons.coffee},
    {'name': 'Alcohol', 'color': '#7B1FA2', 'icon': Icons.wine_bar},
    {
      'name': 'Food Delivery',
      'color': '#FF7043',
      'icon': Icons.delivery_dining,
    },

    // Transportation
    {'name': 'Gas/Fuel', 'color': '#1E88E5', 'icon': Icons.local_gas_station},
    {'name': 'Car Payment', 'color': '#1976D2', 'icon': Icons.directions_car},
    {'name': 'Car Insurance', 'color': '#1565C0', 'icon': Icons.security},
    {'name': 'Car Maintenance', 'color': '#0D47A1', 'icon': Icons.build_circle},
    {
      'name': 'Public Transit',
      'color': '#42A5F5',
      'icon': Icons.directions_bus,
    },
    {'name': 'Parking', 'color': '#90CAF9', 'icon': Icons.local_parking},
    {'name': 'Tolls', 'color': '#BBDEFB', 'icon': Icons.money},
    {'name': 'Ride Sharing', 'color': '#64B5F6', 'icon': Icons.local_taxi},

    // Shopping
    {'name': 'Clothing', 'color': '#EC407A', 'icon': Icons.shopping_bag},
    {'name': 'Electronics', 'color': '#5C6BC0', 'icon': Icons.devices},
    {'name': 'Personal Care', 'color': '#AB47BC', 'icon': Icons.spa},
    {
      'name': 'Household Items',
      'color': '#26A69A',
      'icon': Icons.cleaning_services,
    },
    {'name': 'Gifts', 'color': '#9C27B0', 'icon': Icons.card_giftcard},

    // Health & Wellness
    {
      'name': 'Health Insurance',
      'color': '#4CAF50',
      'icon': Icons.health_and_safety,
    },
    {'name': 'Medical', 'color': '#43A047', 'icon': Icons.medical_services},
    {'name': 'Dental', 'color': '#66BB6A', 'icon': Icons.add_reaction},
    {'name': 'Vision', 'color': '#A5D6A7', 'icon': Icons.visibility},
    {'name': 'Pharmacy', 'color': '#E8F5E9', 'icon': Icons.medication},
    {'name': 'Gym & Fitness', 'color': '#7CB342', 'icon': Icons.fitness_center},

    // Entertainment
    {'name': 'Movies', 'color': '#BA68C8', 'icon': Icons.movie_filter},
    {'name': 'Concerts', 'color': '#D500F9', 'icon': Icons.music_note},
    {'name': 'Games', 'color': '#7E57C2', 'icon': Icons.sports_esports},
    {'name': 'Hobbies', 'color': '#5E35B1', 'icon': Icons.brush},
    {'name': 'Books', 'color': '#D81B60', 'icon': Icons.book},
    {'name': 'Subscriptions', 'color': '#8E24AA', 'icon': Icons.subscriptions},

    // Financial
    {
      'name': 'Credit Card Payment',
      'color': '#0288D1',
      'icon': Icons.credit_card,
    },
    {'name': 'Loan Payment', 'color': '#0277BD', 'icon': Icons.account_balance},
    {'name': 'Bank Fees', 'color': '#01579B', 'icon': Icons.money_off},
    {'name': 'Investments', 'color': '#4FC3F7', 'icon': Icons.trending_up},
    {'name': 'Taxes', 'color': '#B3E5FC', 'icon': Icons.request_quote},
    {'name': 'Savings', 'color': '#29B6F6', 'icon': Icons.savings},

    // Education
    {'name': 'Tuition', 'color': '#FFC107', 'icon': Icons.school},
    {'name': 'Books & Supplies', 'color': '#FFB300', 'icon': Icons.menu_book},
    {'name': 'Student Loans', 'color': '#FFA000', 'icon': Icons.money},
    {'name': 'Courses', 'color': '#FF8F00', 'icon': Icons.cast_for_education},

    // Children
    {'name': 'Childcare', 'color': '#FF5722', 'icon': Icons.child_care},
    {
      'name': 'Baby Supplies',
      'color': '#F4511E',
      'icon': Icons.baby_changing_station,
    },
    {'name': 'Toys', 'color': '#E64A19', 'icon': Icons.toys},
    {'name': 'Allowance', 'color': '#D84315', 'icon': Icons.attach_money},
    {'name': 'Other Expenses', 'color': '#9E9E9E', 'icon': Icons.more_horiz},
  ];

  // Get all categories combined
  static List<Map<String, dynamic>> getAllCategories() {
    return [
      ...incomeCategories.map((category) => {...category, 'isIncome': true}),
      ...expenseCategories.map((category) => {...category, 'isIncome': false}),
    ];
  }

  // Get a category by name
  static Map<String, dynamic>? getCategoryByName(String name) {
    final allCategories = getAllCategories();
    try {
      return allCategories.firstWhere((category) => category['name'] == name);
    } catch (e) {
      return null;
    }
  }

  // Get a category color by name
  static String getCategoryColorByName(String name) {
    final category = getCategoryByName(name);
    return category?['color'] ?? '#9E9E9E'; // Default to grey if not found
  }

  // Convert hex color string to Color object
  static Color hexToColor(String hexString) {
    hexString = hexString.replaceAll('#', '');
    if (hexString.length == 6) {
      hexString = 'FF$hexString';
    }
    return Color(int.parse(hexString, radix: 16));
  }
}
