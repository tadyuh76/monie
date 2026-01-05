# 🤖 AI Features Overview - Monie App

## Tổng quan

Ứng dụng Monie tích hợp **Google Gemini AI** (gemini-2.5-flash) để cung cấp các tính năng phân tích và hỗ trợ tài chính thông minh. Hệ thống AI giúp người dùng hiểu rõ hơn về thói quen chi tiêu, dự đoán xu hướng và tối ưu hóa ngân sách cá nhân.

---

## 🎯 Các tính năng AI chính

### 1. 📊 Spending Pattern Analysis (Phân tích xu hướng chi tiêu)

**Module**: `ai_insights`

**Chức năng**:
- Phân tích chi tiêu theo danh mục và thời gian
- Xác định xu hướng chi tiêu: tăng/giảm/ổn định
- Tính toán Financial Health Score (điểm sức khỏe tài chính)
- Phát hiện thói quen chi tiêu bất thường

**API Endpoint**: `analyzeSpendingPatterns()`

**Input**:
```dart
{
  "startDate": "2025-01-01",
  "endDate": "2025-01-31",
  "totalSpending": 1500.00,
  "avgDailySpending": 50.00,
  "transactionCount": 45,
  "categoryBreakdown": {
    "Food": 500.00,
    "Transport": 300.00,
    "Entertainment": 200.00
  }
}
```

**Output**:
```json
{
  "summary": "Tóm tắt 2-3 câu về thói quen chi tiêu",
  "topCategory": "Danh mục chi tiêu cao nhất",
  "spendingTrend": "increasing|decreasing|stable",
  "unusualPatterns": ["Mẫu bất thường 1", "Mẫu bất thường 2"],
  "recommendations": ["Đề xuất 1", "Đề xuất 2", "Đề xuất 3"],
  "financialHealthScore": 75,
  "insights": {
    "bestPerformingArea": "Mảng làm tốt",
    "areasForImprovement": ["Cần cải thiện 1", "Cần cải thiện 2"],
    "seasonalObservations": "Nhận xét theo mùa"
  }
}
```

**UI Components**:
- `SpendingAnalysisPage`: Trang phân tích chi tiết
- `PatternSummaryCard`: Card tóm tắt pattern
- `FinancialHealthGauge`: Đồng hồ đo điểm tài chính
- `CategoryBreakdownChart`: Biểu đồ breakdown theo danh mục
- `AIInsightCard`: Card hiển thị insights

**Use Case**: `AnalyzeSpendingPatternUseCase`

---

### 2. 💡 Financial Insights (Đề xuất tối ưu ngân sách)

**Module**: `ai_insights` + `home`

**Chức năng**:
- Phân tích mức độ tuân thủ ngân sách
- Đề xuất điều chỉnh ngân sách theo thu nhập/chi tiêu
- Cảnh báo vượt ngân sách
- Gợi ý cách tiết kiệm hiệu quả
- So sánh chi tiêu với kỳ trước

**Tích hợp trong UI**:
- `AIAnalysisWidget` trên Home Page
- Hiển thị insights real-time dựa trên dữ liệu giao dịch
- Auto-refresh khi có giao dịch mới

**Ví dụ insights**:
- "Bạn đã chi 120% ngân sách Food tháng này. Nên cắt giảm 15% để đạt mục tiêu."
- "Chi tiêu Entertainment giảm 30% so với tháng trước. Tuyệt vời!"
- "Nên tạo ngân sách cho danh mục Transport vì đã chi 300$ nhưng chưa có budget."

---

### 3. 💬 AI Chat (Trợ lý tài chính cá nhân)

**Module**: `ai_chat`

**Chức năng**:
- Chat tương tác với AI về tài chính cá nhân
- Trả lời câu hỏi về thu chi, ngân sách
- Phân tích dữ liệu tài chính theo yêu cầu
- Đưa ra lời khuyên tài chính cá nhân hóa

**Context Builder**: `FinancialContextBuilder`

**Financial Context được gửi kèm**:
```
User ID: xxx
Current Balance: $5,000
Monthly Income: $3,000
Monthly Expenses: $2,200

Active Budgets:
- Food: $500 / $600 (83% used)
- Transport: $200 / $300 (67% used)

Recent Transactions (5 latest):
- $25.00 at Starbucks on 3/1
- $50.00 at Uber on 2/1
...
```

**Chat Session**: Sử dụng `ChatSession` của Gemini với history duy trì

**UI Components**:
- `AIChatPage`: Trang chat full-screen
- `DraggableChatBubble`: Bubble chat có thể kéo thả
- `ChatBubbleManager`: Quản lý hiển thị bubble
- `ChatInputField`: Input field gửi tin nhắn
- `TypingIndicator`: Hiệu ứng typing khi AI đang trả lời

**Ví dụ câu hỏi**:
- "Tôi nên tiết kiệm bao nhiêu mỗi tháng?"
- "Tại sao chi tiêu Food tháng này cao?"
- "Phân tích chi tiêu 3 tháng gần đây của tôi"
- "Đề xuất ngân sách cho tháng sau"

---

### 4. 🔮 Spending Predictions (Dự đoán chi phí tương lai)

**Module**: `predictions`

**Chức năng**:
- Dự đoán tổng chi tiêu cho kỳ tiếp theo
- Dự đoán chi tiêu theo từng danh mục
- Tính toán confidence score (độ tin cậy)
- Phân tích xu hướng lịch sử để dự báo
- So sánh actual vs predicted

**Algorithm**: `PredictionAnalyzer`

**Phương pháp**:
- Moving Average (trung bình động)
- Trend Analysis (phân tích xu hướng)
- Seasonal Pattern Recognition (nhận dạng mẫu theo mùa)
- Historical Growth Rate (tốc độ tăng trưởng lịch sử)

**Entity**: `SpendingPrediction`
```dart
class SpendingPrediction {
  final double predictedAmount;
  final double confidenceScore;  // 0.0 - 1.0
  final String period;           // "next_month", "next_week"
  final Map<String, CategoryPrediction> categoryPredictions;
  final String trend;            // "increasing", "decreasing", "stable"
  final List<String> insights;
}
```

**UI Components**:
- `SpendingForecastPage`: Trang dự báo chi tiêu
- `PredictionGaugeWidget`: Đồng hồ hiển thị prediction
- `CategoryForecastChart`: Biểu đồ dự báo theo danh mục
- `ConfidenceIndicator`: Chỉ số độ tin cậy
- `ForecastSummaryWidget`: Widget tóm tắt trên Home

**Use Case**: `PredictSpendingUseCase`

**Ví dụ output**:
```
Predicted spending for February 2026: $2,450
Confidence: 85%

Category breakdown:
- Food: $550 (↑12% vs last month)
- Transport: $280 (stable)
- Entertainment: $320 (↓15% vs last month)

Insights:
- Food spending likely to increase due to holiday season
- Consider setting higher budget for Food category
```

---

### 5. 🚨 Anomaly Detection (Cảnh báo giao dịch bất thường)

**Module**: Tích hợp trong `ai_insights` và `transactions`

**Chức năng**:
- Phát hiện giao dịch bất thường về số tiền
- Cảnh báo chi tiêu vượt mức bình thường
- Detect duplicate transactions (giao dịch trùng lặp)
- Nhận diện giao dịch nghi ngờ
- Pattern-based fraud detection

**Triggers**:
- Giao dịch > 3x mức trung bình của danh mục
- 2+ giao dịch giống nhau trong 1 giờ
- Chi tiêu đột ngột tăng > 200% so với trung bình tuần
- Giao dịch vào thời điểm bất thường (3AM - 5AM)

**Notification**:
- Push notification real-time khi phát hiện anomaly
- Badge màu đỏ trên transaction
- Alert trong `unusualPatterns` của Spending Pattern Analysis

**Ví dụ cảnh báo**:
- "⚠️ Giao dịch $500 tại Restaurant bất thường. Trung bình của bạn là $30."
- "⚠️ Phát hiện 2 giao dịch giống nhau: $50 at Starbucks trong 30 phút."
- "🔍 Chi tiêu Shopping tuần này: $800 (cao hơn 250% so với trung bình)."

---

## 🏗️ Architecture Overview

### Service Layer

**`GeminiService`** (`lib/core/services/gemini_service.dart`)
- Singleton service quản lý Gemini API
- Methods:
  - `generateContent(prompt)`: Generate text từ prompt
  - `startChatSession(systemContext)`: Tạo chat session
  - `generateStructuredContent(prompt, expectedFormat)`: Generate JSON response
  - `analyzeSpendingPatterns(spendingData)`: Wrapper cho spending analysis

**Configuration**:
```dart
GenerativeModel(
  model: 'gemini-2.5-flash',
  apiKey: GEMINI_API_KEY,
  generationConfig: GenerationConfig(
    temperature: 0.7,
    topK: 40,
    topP: 0.95,
    maxOutputTokens: 8192,
  ),
)
```

### Data Flow

```
User Action
    ↓
Presentation (BLoC Event)
    ↓
Use Case
    ↓
Repository
    ↓
Data Source (Analyzer/Remote)
    ↓
GeminiService → Gemini API
    ↓
Process Response
    ↓
Entity/Model
    ↓
State Update
    ↓
UI Render
```

### BLoC Pattern

Mỗi feature có BLoC riêng:
- `SpendingPatternBloc`: Quản lý spending analysis
- `AIChatBloc`: Quản lý chat messages và session
- `PredictionBloc`: Quản lý spending predictions

---

## 🔐 Security & Privacy

### API Key Management
- API key stored in `.env` file
- Never committed to Git
- Loaded via `flutter_dotenv`

### Data Privacy
- Chỉ gửi metadata và tổng hợp, không gửi raw personal data
- Transaction details được anonymize trước khi gửi
- User có thể opt-out AI features trong Settings

### Rate Limiting
- Caching results để giảm API calls
- Debounce user input trong chat
- Maximum 50 requests/user/day

---

## 📊 Usage Statistics

### AI Feature Adoption
- **Spending Analysis**: Tự động chạy mỗi tuần
- **AI Chat**: Accessible via floating bubble on Home
- **Predictions**: Auto-generate đầu tháng
- **Insights**: Real-time trên Dashboard

### Performance
- Average response time: < 3s
- Structured JSON parsing: 95% success rate
- Cache hit rate: 70% (24h cache)

---

## 🚀 Future Enhancements

### Planned Features
1. **Voice-to-Text**: Nói chuyện với AI bằng giọng nói
2. **Receipt OCR**: Scan hóa đơn và tự động tạo transaction
3. **Investment Advice**: Tư vấn đầu tư dựa trên profile
4. **Goal-based Planning**: Lập kế hoạch tài chính cho mục tiêu cụ thể
5. **Multi-currency Support**: AI analysis cho nhiều loại tiền tệ
6. **Family Finance**: Phân tích tài chính cho cả gia đình
7. **Bill Reminders**: AI nhắc nhở thanh toán hóa đơn định kỳ
8. **Expense Splitting AI**: AI tự động chia bill trong nhóm

### API Improvements
- Migrate to Gemini Pro khi cần higher limits
- Fine-tuning model với financial domain data
- Support for multimodal input (text + images)

---

## 🛠️ Development Guide

### Setup Gemini API

1. Get API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Add to `.env`:
```env
GEMINI_API_KEY=your_api_key_here
```

### Testing AI Features

```bash
# Run specific AI feature tests
flutter test test/features/ai_insights/
flutter test test/features/ai_chat/
flutter test test/features/predictions/

# Mock Gemini responses for testing
# See: test/mocks/mock_gemini_service.dart
```

### Adding New AI Feature

1. Create feature module in `lib/features/your_feature/`
2. Define entity in `domain/entities/`
3. Create use case in `domain/usecases/`
4. Implement analyzer in `data/datasources/`
5. Create BLoC in `presentation/bloc/`
6. Build UI in `presentation/pages/` and `presentation/widgets/`
7. Register dependencies in `lib/di/injection.dart`

### Prompt Engineering Tips

- Sử dụng structured format để dễ parse JSON
- Provide context đầy đủ (user data, historical trends)
- Clear instructions với expected output format
- Handle edge cases (empty data, null values)
- Test với nhiều scenarios khác nhau

---

## 📝 Code Examples

### 1. Analyze Spending Pattern

```dart
final spendingPatternBloc = context.read<SpendingPatternBloc>();

spendingPatternBloc.add(
  AnalyzeSpendingPatternEvent(
    userId: userId,
    startDate: DateTime.now().subtract(Duration(days: 30)),
    endDate: DateTime.now(),
  ),
);

// Listen to state
BlocBuilder<SpendingPatternBloc, SpendingPatternState>(
  builder: (context, state) {
    if (state is SpendingPatternLoaded) {
      return PatternSummaryCard(pattern: state.pattern);
    }
    return LoadingWidget();
  },
)
```

### 2. AI Chat

```dart
final chatBloc = context.read<AIChatBloc>();

// Send message
chatBloc.add(SendMessageEvent(
  userId: userId,
  message: "Phân tích chi tiêu tháng này",
));

// Display messages
BlocBuilder<AIChatBloc, AIChatState>(
  builder: (context, state) {
    return ListView.builder(
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        return ChatBubble(
          message: message.content,
          isUser: message.isUser,
        );
      },
    );
  },
)
```

### 3. Get Spending Predictions

```dart
final predictionBloc = context.read<PredictionBloc>();

predictionBloc.add(
  PredictSpendingEvent(
    userId: userId,
    period: 'next_month',
  ),
);

// Show prediction
BlocBuilder<PredictionBloc, PredictionState>(
  builder: (context, state) {
    if (state is PredictionLoaded) {
      return PredictionGaugeWidget(
        prediction: state.prediction,
      );
    }
    return CircularProgressIndicator();
  },
)
```

---

## 📚 Related Documentation

- [Gemini API Documentation](https://ai.google.dev/docs)
- [Flutter BLoC Pattern](https://bloclibrary.dev/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Monie Project Charter](PROJECT_CHARTER.md)
- [Integration Guide](integration.md)

---

## 👥 Contributors

- **AI/ML Integration**: Lê Văn C (Fullstack Developer 1)
- **Architecture Design**: Nguyễn Văn A (Team Leader)
- **Testing**: Vũ Thị F (QA/QC Engineer)

---

## 📄 License

This project is part of Monie - Personal Finance Management App.
© 2025 UEH University. All rights reserved.

---

**Last Updated**: January 4, 2026  
**Version**: 1.0.0  
**Status**: ✅ Production Ready
