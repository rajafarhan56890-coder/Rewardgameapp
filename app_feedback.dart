import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared feedback helpers so every screen shows errors/success messages
/// with identical styling instead of ad-hoc SnackBars.
class AppFeedback {
  AppFeedback._();

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
      );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
      );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
      );
  }
}

/// Full-screen centered loading spinner for use inside BlocBuilders.
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  const AppLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }
}
