import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Singleton service for managing Gemini AI interactions
class GeminiService {
  static GeminiService? _instance;
  late final GenerativeModel _model;
  late final GenerativeModel _chatModel;
  ChatSession? _chatSession;

  GeminiService._internal() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    // Model for general content generation
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      ),
    );

    // Model for chat sessions
    _chatModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 4096,
      ),
    );
  }

  /// Get the singleton instance
  static GeminiService get instance {
    _instance ??= GeminiService._internal();
    return _instance!;
  }

  /// Generate content from a prompt
  Future<String?> generateContent(String prompt) async {
    try {
      debugPrint('GeminiService: Generating content...');
      final response = await _model.generateContent([Content.text(prompt)]);
      debugPrint('GeminiService: Content generated successfully');
      return response.text;
    } catch (e) {
      debugPrint('GeminiService Error: $e');
      return null;
    }
  }

  /// Generate structured JSON content
  Future<Map<String, dynamic>?> generateStructuredContent(
    String prompt,
    String expectedFormat,
  ) async {
    try {
      debugPrint('GeminiService: Generating structured content...');

      final fullPrompt = '''
$prompt

IMPORTANT: Respond ONLY with valid JSON in this exact format:
$expectedFormat

Do not include any markdown formatting, code blocks, or explanations.
Just return the raw JSON object.
''';

      final response = await _model.generateContent([Content.text(fullPrompt)]);
      final text = response.text;

      if (text == null || text.isEmpty) {
        debugPrint('GeminiService: Empty response');
        return null;
      }

      // Clean the response - remove markdown code blocks if present
      String cleanedText = text.trim();
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      } else if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      cleanedText = cleanedText.trim();

      debugPrint('GeminiService: Parsing JSON response...');
      return jsonDecode(cleanedText) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('GeminiService Error: $e');
      return null;
    }
  }

  /// Start a new chat session with system context
  void startChatSession(String systemContext) {
    debugPrint('GeminiService: Starting chat session...');
    _chatSession = _chatModel.startChat(
      history: [
        Content.text('''
You are a helpful financial assistant for Monie app. 
Your role is to help users understand their spending habits, 
provide financial advice, and answer questions about their finances.

$systemContext

Guidelines:
- Be concise and helpful
- Use the user's financial data to provide personalized advice
- If asked about specific transactions or budgets, reference the data provided
- Suggest practical ways to save money and manage finances
- Be encouraging and supportive
- Respond in the same language as the user's question
'''),
        Content.model([TextPart('Understood! I\'m ready to help with your financial questions. How can I assist you today?')]),
      ],
    );
    debugPrint('GeminiService: Chat session started');
  }

  /// Send a message in the current chat session
  Future<String?> sendChatMessage(String message) async {
    if (_chatSession == null) {
      debugPrint('GeminiService: No active chat session, creating one...');
      // Create a basic session if none exists
      startChatSession('No financial data available yet.');
    }

    try {
      debugPrint('GeminiService: Sending chat message: $message');
      final response = await _chatSession!.sendMessage(Content.text(message));
      debugPrint('GeminiService: Chat response received: ${response.text?.substring(0, 50)}...');
      return response.text;
    } catch (e) {
      debugPrint('GeminiService Chat Error: $e');
      // Try to recreate session and retry once
      try {
        debugPrint('GeminiService: Retrying with new session...');
        startChatSession('Financial assistant ready to help.');
        final retryResponse = await _chatSession!.sendMessage(Content.text(message));
        return retryResponse.text;
      } catch (retryError) {
        debugPrint('GeminiService Retry Error: $retryError');
        return null;
      }
    }
  }

  /// Clear the current chat session
  void clearChatSession() {
    _chatSession = null;
    debugPrint('GeminiService: Chat session cleared');
  }

  /// Analyze spending patterns
  Future<Map<String, dynamic>?> analyzeSpendingPatterns({
    required String startDate,
    required String endDate,
    required double totalSpending,
    required double avgDailySpending,
    required int transactionCount,
    required Map<String, double> categoryBreakdown,
    required double totalIncome,
    required double savingsRate,
  }) async {
    final prompt = '''
Analyze the following spending data and provide insights:

Period: $startDate to $endDate
Total Spending: \$${totalSpending.toStringAsFixed(2)}
Total Income: \$${totalIncome.toStringAsFixed(2)}
Savings Rate: ${(savingsRate * 100).toStringAsFixed(1)}%
Average Daily Spending: \$${avgDailySpending.toStringAsFixed(2)}
Number of Transactions: $transactionCount

Category Breakdown:
${categoryBreakdown.entries.map((e) => '- ${e.key}: \$${e.value.toStringAsFixed(2)}').join('\n')}

Please analyze this data and provide:
1. A brief summary of spending habits (2-3 sentences)
2. The top spending category
3. Spending trend (increasing, decreasing, or stable)
4. Any unusual patterns detected
5. 3 actionable recommendations
6. A financial health score from 0-100
7. Insights about areas doing well and needing improvement
''';

    final expectedFormat = '''
{
  "summary": "string",
  "topCategory": "string",
  "spendingTrend": "increasing|decreasing|stable",
  "unusualPatterns": ["string"],
  "recommendations": ["string"],
  "financialHealthScore": number,
  "insights": {
    "bestPerformingArea": "string",
    "areasForImprovement": ["string"],
    "seasonalObservations": "string"
  }
}
''';

    return generateStructuredContent(prompt, expectedFormat);
  }

  /// Generate spending predictions
  Future<Map<String, dynamic>?> predictSpending({
    required List<Map<String, dynamic>> historicalData,
    required String period,
    required Map<String, double> categoryTrends,
  }) async {
    final prompt = '''
Based on the following historical spending data, predict future spending:

Historical Monthly Data:
${historicalData.map((d) => '- ${d['month']}: \$${d['amount']}').join('\n')}

Category Trends (average monthly):
${categoryTrends.entries.map((e) => '- ${e.key}: \$${e.value.toStringAsFixed(2)}').join('\n')}

Prediction Period: $period

Please predict:
1. Total predicted spending for the next period
2. Confidence score (0-100)
3. Spending trend
4. Category-wise predictions
5. Key insights about the prediction
''';

    final expectedFormat = '''
{
  "predictedAmount": number,
  "confidenceScore": number,
  "trend": "increasing|decreasing|stable",
  "categoryPredictions": {
    "category_name": {
      "amount": number,
      "change": number
    }
  },
  "insights": ["string"]
}
''';

    return generateStructuredContent(prompt, expectedFormat);
  }

  /// Detect anomalies in transactions
  Future<Map<String, dynamic>?> detectAnomalies({
    required List<Map<String, dynamic>> recentTransactions,
    required Map<String, double> categoryAverages,
  }) async {
    final prompt = '''
Analyze these recent transactions for anomalies:

Recent Transactions:
${recentTransactions.take(20).map((t) => '- ${t['date']}: ${t['title']} - \$${t['amount']} (${t['category']})').join('\n')}

Category Averages (per transaction):
${categoryAverages.entries.map((e) => '- ${e.key}: \$${e.value.toStringAsFixed(2)}').join('\n')}

Detect:
1. Transactions with unusually high amounts compared to category average
2. Duplicate or similar transactions in short time periods
3. Unusual spending patterns
4. Any suspicious activity
''';

    final expectedFormat = '''
{
  "anomalies": [
    {
      "transactionId": "string",
      "type": "high_amount|duplicate|unusual_pattern|suspicious",
      "severity": "low|medium|high",
      "description": "string"
    }
  ],
  "overallRisk": "low|medium|high",
  "summary": "string"
}
''';

    return generateStructuredContent(prompt, expectedFormat);
  }

  /// Parse a voice command into transaction data using AI
  Future<Map<String, dynamic>?> parseVoiceCommand(String voiceText) async {
    final today = DateTime.now();
    final prompt = '''
Parse this voice command into transaction data. The command may be in Vietnamese or English.
Today's date is: ${today.toIso8601String().split('T')[0]}

Voice command: "$voiceText"

CRITICAL - Amount Parsing Rules:
- "k", "K" = multiply by 1,000 (e.g., "50k" = 50,000)
- "nghìn", "ngàn", "thousand" = multiply by 1,000 (e.g., "50 nghìn" = 50,000, "100 thousand" = 100,000)
- "tr", "triệu", "m", "M", "million" = multiply by 1,000,000 (e.g., "1tr" = 1,000,000, "2 triệu" = 2,000,000)
- "trăm", "hundred" = multiply by 100 (e.g., "5 trăm" = 500)
- Numbers without multipliers should be taken literally (e.g., "1000" = 1000, "5000" = 5000)
- Numbers with dots as thousand separators: "50.000" = 50,000

CRITICAL - Transaction Type Detection:
- EXPENSE keywords (isIncome = false): chi, tiêu, mua, thanh toán, trả, spend, spent, paid, bought, purchased, pay, expense
- INCOME keywords (isIncome = true): thu, nhận, lương, tiền về, receive, received, got, get, earned, salary, income, bonus, from

CRITICAL - Title vs Description:
- title: SHORT transaction name (2-4 words max) - what was the transaction for?
- description: DETAILED notes/context (can be longer) - additional information or same as title if no extra context

Examples:
- "chi 50k cho ăn uống" → amount: 50000, title: "Ăn uống", description: "Chi tiêu cho ăn uống", isIncome: false, category: "Dining"
- "thu 500 nghìn tiền lương" → amount: 500000, title: "Lương tháng", description: "Thu nhập tiền lương", isIncome: true, category: "Salary"
- "spend 100 thousand on groceries" → amount: 100000, title: "Groceries", description: "Spent on groceries shopping", isIncome: false, category: "Groceries"
- "received 1 million salary" → amount: 1000000, title: "Monthly Salary", description: "Received 1 million from salary", isIncome: true, category: "Salary"
- "Get 1000 from salary" → amount: 1000, title: "Salary Income", description: "Received 1000 from salary", isIncome: true, category: "Salary"
- "mua 200k đồ ăn" → amount: 200000, title: "Đồ ăn", description: "Mua đồ ăn", isIncome: false, category: "Dining"
- "nhận 2 triệu học bổng" → amount: 2000000, title: "Học bổng", description: "Nhận 2 triệu học bổng", isIncome: true, category: "Scholarship"
- "for eating" → amount: 0, title: "Eating", description: "For eating", isIncome: false, category: "Dining"

Available EXPENSE categories: Bills, Debt, Dining, Donate, Education, Electricity, Entertainment, Gifts, Groceries, Healthcare, Housing, Insurance, Investment, Loans, Pets, Rent, Saving, Shopping, Tax, Technology, Transport, Travel

Available INCOME categories: Salary, Scholarship, Insurance Payout, Family Support, Stock, Commission, Allowance

Parse the command and extract:
1. amount: The FULL numerical amount after applying multipliers (NEVER return the base number without multiplier). If no amount mentioned, use 0.
2. category: Best matching category from the available lists above (use exact category name)
3. title: SHORT transaction name (2-4 words) - the main purpose of the transaction
4. description: DETAILED notes with more context - can include amount and category details
5. isIncome: true if it's income (thu, nhận, receive, get, earned, salary, from), false if expense (chi, tiêu, mua, spend, paid, for)
6. date: The date mentioned (use ISO format YYYY-MM-DD), or null if not mentioned. Handle relative dates like "yesterday", "hôm qua", "last week", "tuần trước"
7. confidence: Your confidence in this parsing (0.0 to 1.0)
''';

    final expectedFormat = '''
{
  "amount": number,
  "category": "string or null",
  "title": "string",
  "description": "string",
  "isIncome": boolean,
  "date": "YYYY-MM-DD or null",
  "confidence": number
}
''';

    return generateStructuredContent(prompt, expectedFormat);
  }
}
