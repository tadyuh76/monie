import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/core/utils/spending_forecast_service.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';
import 'dart:math' as math;

class SpendingForecastWidget extends StatelessWidget {
  const SpendingForecastWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDarkMode
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.insights, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('spending_forecast_title'),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              if (state is TransactionLoading) {
                return SizedBox(
                  height: 180,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('spending_forecast_loading'),
                          style: textTheme.bodySmall?.copyWith(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is TransactionsLoaded) {
                final forecastResult = SpendingForecastService.generateForecast(
                  state.transactions,
                );

                if (!forecastResult.isSuccess) {
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.tr('spending_forecast_insufficient_data'),
                              style: textTheme.bodyMedium?.copyWith(
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: _buildForecastChart(
                        context,
                        forecastResult.actualData,
                        forecastResult.predictedData,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCategoryForecasts(
                      context,
                      forecastResult.categoryForecasts,
                    ),
                  ],
                );
              }

              return SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    context.tr('spending_forecast_error'),
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? Colors.red[300] : Colors.red,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForecastChart(
    BuildContext context,
    List<double> actualData,
    List<double> predictedData,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: const Size(double.infinity, 180),
      painter: ForecastChartPainter(
        actualData: actualData,
        predictedData: predictedData,
        isDarkMode: isDarkMode,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                context,
                context.tr('spending_forecast_actual'),
                AppColors.primary,
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                context,
                context.tr('spending_forecast_predicted'),
                AppColors.secondary,
                isDashed: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    Color color, {
    bool isDashed = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 30,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child:
              isDashed
                  ? LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          5,
                          (index) =>
                              Container(width: 4, height: 3, color: color),
                        ),
                      );
                    },
                  )
                  : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryForecasts(
    BuildContext context,
    List<CategoryForecast> forecasts,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    if (forecasts.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('spending_forecast_category_forecasts'),
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...forecasts.map((forecast) => _buildForecastItem(context, forecast)),
      ],
    );
  }

  Widget _buildForecastItem(BuildContext context, CategoryForecast forecast) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final isIncrease = forecast.isIncrease;
    final color = isIncrease ? AppColors.expense : AppColors.income;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _localizeCategory(context, forecast.category),
              style: textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.formatCurrency(forecast.current),
              style: textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.formatCurrency(forecast.forecast),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${isIncrease ? '+' : ''}${forecast.changePercent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _localizeCategory(BuildContext context, String category) {
    // Try to localize common categories
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
      case 'dining':
        return context.tr('spending_forecast_food_dining');
      case 'transportation':
      case 'transport':
        return context.tr('spending_forecast_transportation');
      case 'entertainment':
        return context.tr('spending_forecast_entertainment');
      case 'shopping':
        return context.tr('spending_forecast_shopping');
      case 'utilities':
        return context.tr('spending_forecast_utilities');
      case 'healthcare':
      case 'health':
        return context.tr('spending_forecast_healthcare');
      default:
        return category.isEmpty
            ? context.tr('spending_forecast_other')
            : category;
    }
  }
}

class ForecastChartPainter extends CustomPainter {
  final List<double> actualData;
  final List<double> predictedData;
  final bool isDarkMode;

  ForecastChartPainter({
    required this.actualData,
    required this.predictedData,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height - 30; // Leave space for legend

    if (actualData.isEmpty && predictedData.isEmpty) return;

    // Find min and max values for scaling
    final allData = [...actualData, ...predictedData];
    final double minValue = allData.isEmpty ? 0 : allData.reduce(math.min);
    final double maxValue = allData.isEmpty ? 100 : allData.reduce(math.max);
    final double valueRange = maxValue - minValue;

    if (valueRange == 0) return;

    // Calculate x and y positions for monthly data
    final totalMonths = actualData.length + predictedData.length;
    final double xStep =
        totalMonths > 1 ? width / (totalMonths - 1) : width / 2;

    // Draw grid lines
    final gridPaint =
        Paint()
          ..color =
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05)
          ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = height - (height * i / 4);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Vertical grid lines (one for each month)
    for (int i = 0; i < totalMonths; i++) {
      final x = i * xStep;
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }

    // Draw actual data line
    final actualPaint =
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    if (actualData.isNotEmpty) {
      final actualPath = Path();
      for (int i = 0; i < actualData.length; i++) {
        final x = i * xStep;
        final y = height - ((actualData[i] - minValue) / valueRange * height);

        if (i == 0) {
          actualPath.moveTo(x, y);
        } else {
          actualPath.lineTo(x, y);
        }
      }

      canvas.drawPath(actualPath, actualPaint);
    }

    // Draw prediction line (dashed)
    final predictionPaint =
        Paint()
          ..color = AppColors.secondary
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

    if (predictedData.isNotEmpty && actualData.isNotEmpty) {
      // Starting point for prediction (last point of actual data)
      final startX = (actualData.length - 1) * xStep;
      final startY =
          height - ((actualData.last - minValue) / valueRange * height);

      // Draw dashed prediction line
      for (int i = 0; i < predictedData.length; i++) {
        final x = (actualData.length + i) * xStep;
        final y =
            height - ((predictedData[i] - minValue) / valueRange * height);

        if (i == 0) {
          // Connect to the last actual data point
          _drawDashedLine(
            canvas,
            Offset(startX, startY),
            Offset(x, y),
            predictionPaint,
          );
        } else {
          final prevX = (actualData.length + i - 1) * xStep;
          final prevY =
              height -
              ((predictedData[i - 1] - minValue) / valueRange * height);

          // Draw dashed line between predicted points
          _drawDashedLine(
            canvas,
            Offset(prevX, prevY),
            Offset(x, y),
            predictionPaint,
          );
        }
      }
    }

    // Draw points for actual data
    final pointPaint =
        Paint()
          ..color = isDarkMode ? Colors.white : Colors.white
          ..style = PaintingStyle.fill;

    final pointStrokePaint =
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    for (int i = 0; i < actualData.length; i++) {
      final x = i * xStep;
      final y = height - ((actualData[i] - minValue) / valueRange * height);

      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5, pointStrokePaint);
    }

    // Draw points for predicted data
    final predictPointStrokePaint =
        Paint()
          ..color = AppColors.secondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    for (int i = 0; i < predictedData.length; i++) {
      // Start predicted points from the next position after actual data
      final x = (actualData.length + i) * xStep;
      final y = height - ((predictedData[i] - minValue) / valueRange * height);

      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5, predictPointStrokePaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final double width = end.dx - start.dx;
    final double height = end.dy - start.dy;
    final double distance = math.sqrt(width * width + height * height);

    if (distance == 0) return;

    final double dashWidth = 5.0;
    final double dashSpace = 5.0;
    final double dashCount = distance / (dashWidth + dashSpace);

    for (int i = 0; i < dashCount.floor(); i++) {
      final double startFraction = i * (dashWidth + dashSpace) / distance;
      final double endFraction =
          (i * (dashWidth + dashSpace) + dashWidth) / distance;

      final double dashStartX = start.dx + width * startFraction;
      final double dashStartY = start.dy + height * startFraction;
      final double dashEndX = start.dx + width * endFraction;
      final double dashEndY = start.dy + height * endFraction;

      canvas.drawLine(
        Offset(dashStartX, dashStartY),
        Offset(dashEndX, dashEndY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
