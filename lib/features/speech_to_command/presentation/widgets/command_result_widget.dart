import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/core/services/device_info_service.dart';
import 'package:monie/core/services/permission_service.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_bloc.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_event.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_state.dart';
import 'package:url_launcher/url_launcher.dart';

class CommandResultWidget extends StatelessWidget {
  const CommandResultWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpeechBloc, SpeechState>(
      builder: (context, state) {
        if (state is PermissionRequired) {
          return _buildPermissionRequired(context, state);
        } else if (state is SpeechResultReceived) {
          return _buildResultText(context, state.text, null);
        } else if (state is CommandParsed) {
          return _buildParsedCommand(context, state);
        } else if (state is CommandParseError) {
          return _buildError(context, state.message, state.originalText);
        } else if (state is TransactionCreated) {
          return _buildSuccess(context, state.transaction);
        } else if (state is SpeechError) {
          return _buildError(context, state.message, null);
        } else if (state is GoogleServicesRequired) {
          return _buildGoogleServicesError(context, state);
        } else if (state is ManufacturerRestriction) {
          return _buildManufacturerRestrictionError(context, state);
        } else if (state is SpeechNotAvailable) {
          return _buildError(context, state.message, null);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildResultText(
    BuildContext context,
    String text,
    String? error,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: error != null ? AppColors.expense : AppColors.primary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error != null ? 'Error' : 'Recognized Text',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: error != null ? AppColors.expense : AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: AppColors.expense,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParsedCommand(BuildContext context, CommandParsed state) {
    final command = state.command;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: command.isIncome ? AppColors.income : AppColors.expense,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                command.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: command.isIncome ? AppColors.income : AppColors.expense,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                command.isIncome ? 'Income' : 'Expense',
                style: TextStyle(
                  color: command.isIncome ? AppColors.income : AppColors.expense,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // AI confidence indicator
              if (command.confidence < 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(command.confidence).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: _getConfidenceColor(command.confidence),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(command.confidence * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getConfidenceColor(command.confidence),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatCurrency(command.amount),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (command.categoryName != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    command.categoryName!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          // Date display
          if (command.date != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(command.date!),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          if (command.description != null && command.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 8),
            const Text(
              'Description',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              command.description!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppColors.income;
    if (confidence >= 0.5) return Colors.orange;
    return AppColors.expense;
  }

  Widget _buildError(BuildContext context, String message, String? originalText) {
    // Check if this is a service unavailable error
    final isServiceUnavailable = message.toLowerCase().contains('service') &&
        message.toLowerCase().contains('not available');

    if (isServiceUnavailable) {
      return _buildServiceUnavailableError(context, message);
    }

    return _buildResultText(
      context,
      originalText ?? 'Error occurred',
      message,
    );
  }

  Widget _buildServiceUnavailableError(BuildContext context, String message) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 350),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange,
              width: 2,
            ),
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            const Text(
              'Speech Recognition Unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Speech recognition requires special permissions on Vivo/Oppo devices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'For Vivo/Oppo Users:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildTroubleshootingStep('1', 'Allow microphone permission'),
                  _buildTroubleshootingStep('2', 'Enable auto-start for Monie'),
                  _buildTroubleshootingStep('3', 'Disable battery optimization'),
                  _buildTroubleshootingStep('4', 'Restart app completely'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Retry speech recognition
                      context.read<SpeechBloc>().add(const StartListeningEvent());
                    },
                    icon: const Icon(
                      Icons.refresh,
                      size: 18,
                    ),
                    label: const Text(
                      'Retry',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Open Play Store to install/update Google app
                      final uri = Uri.parse(
                          'https://play.google.com/store/apps/details?id=com.google.android.googlequicksearchbox');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(
                      Icons.download,
                      size: 18,
                    ),
                    label: const Text(
                      'Get App',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildTroubleshootingStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, transaction) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.income.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.income,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.income,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transaction Created!',
                  style: TextStyle(
                    color: AppColors.income,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Amount: ${Formatters.formatCurrency(transaction.amount)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequired(
      BuildContext context, PermissionRequired state) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.isPermanentlyDenied ? Icons.settings : Icons.mic_off,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              state.isPermanentlyDenied
                  ? 'Permission Required'
                  : 'Microphone Access',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                state.isPermanentlyDenied
                    ? 'Enable microphone in app settings to use voice commands.'
                    : 'Grant microphone permission to add transactions by voice.',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (state.isPermanentlyDenied) {
                    context.read<SpeechBloc>().add(const OpenAppSettingsEvent());
                  } else {
                    context
                        .read<SpeechBloc>()
                        .add(const RequestPermissionEvent());
                  }
                },
                icon: Icon(
                  state.isPermanentlyDenied ? Icons.settings : Icons.mic,
                  size: 20,
                ),
                label: Text(
                  state.isPermanentlyDenied ? 'Open Settings' : 'Grant Permission',
                  style: const TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Device-Specific Error UI =====

  /// Build Google Services error UI
  Widget _buildGoogleServicesError(BuildContext context, GoogleServicesRequired state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          const Text(
            'Google App Required',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Speech recognition requires the Google app to be installed and updated.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.google.android.googlequicksearchbox';
              final uri = Uri.parse(playStoreUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Get Google App'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              context.read<SpeechBloc>().add(const RetryPermissionCheckEvent());
            },
            child: const Text('I\'ve installed it - Retry'),
          ),
        ],
      ),
    );
  }

  /// Build manufacturer restriction error with guided steps
  Widget _buildManufacturerRestrictionError(BuildContext context, ManufacturerRestriction state) {
    final currentIssue = state.currentIssue;
    final isCritical = currentIssue.severity == IssueSeverity.critical;

    // Get device-specific color
    Color deviceColor = AppColors.primary;
    if (state.deviceCategory == DeviceCategory.vivo) {
      deviceColor = Colors.blue;
    } else if (state.deviceCategory == DeviceCategory.oppo) {
      deviceColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: deviceColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isCritical ? Icons.error_outline : Icons.info_outline,
                size: 24,
                color: isCritical ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.deviceCategory == DeviceCategory.vivo
                          ? 'Vivo Settings Required'
                          : state.deviceCategory == DeviceCategory.oppo
                              ? 'Oppo Settings Required'
                              : 'Device Settings Required',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (state.totalSteps > 1)
                      Text(
                        'Step ${state.currentStepIndex + 1} of ${state.totalSteps}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current permission step card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCritical ? Colors.orange.withOpacity(0.5) : Colors.blue.withOpacity(0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isCritical ? Colors.orange : Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${state.currentStepIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentIssue.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currentIssue.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<SpeechBloc>().add(
                          ExecutePermissionActionEvent(issue: currentIssue),
                        );
                  },
                  icon: const Icon(Icons.settings, size: 18),
                  label: Text(currentIssue.actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deviceColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Retry button
          OutlinedButton.icon(
            onPressed: () {
              context.read<SpeechBloc>().add(const RetryPermissionCheckEvent());
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Test Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: deviceColor,
              side: BorderSide(color: deviceColor.withOpacity(0.5)),
            ),
          ),

          // Show remaining steps indicator
          if (state.hasMoreSteps) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_forward, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    '${state.totalSteps - state.currentStepIndex - 1} more step${state.totalSteps - state.currentStepIndex - 1 > 1 ? 's' : ''} after this',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

