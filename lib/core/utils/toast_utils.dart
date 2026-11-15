import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';

class ToastUtils {
  static void showSuccess(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: true,
      closeButton: const ToastCloseButton(),
      dragToClose: true,
      backgroundColor: AppColors.surface,
      primaryColor: AppColors.success,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      boxShadow: highModeShadow,
    );
  }

  static void showError(BuildContext context, String error) {
    final String cleanError = cleanErrorMessage(error);

    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: Text(cleanError, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: true,
      closeButton: const ToastCloseButton(),
      dragToClose: true,
      backgroundColor: AppColors.surface,
      primaryColor: AppColors.error,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      boxShadow: highModeShadow,
    );
  }

  static String cleanErrorMessage(String error) {
    String clean = error
        .replaceAll('Exception: ', '')
        .replaceAll('AuthApiException: ', '')
        .replaceAll('PostgrestException: ', '')
        .trim();
    final lower = clean.toLowerCase();

    if (lower.contains('invalid login credentials') || lower.contains('invalid_credentials')) {
      return 'errors.invalid_credentials'.tr();
    }
    if (lower.contains('email not confirmed')) {
      return 'errors.email_not_confirmed'.tr();
    }
    if (lower.contains('user already registered') || lower.contains('user_already_exists')) {
      return 'errors.user_exists'.tr();
    }
    if (lower.contains('password should be at least 6') || lower.contains('password_too_short')) {
      return 'errors.weak_password'.tr();
    }
    if (lower.contains('402') || lower.contains('insufficient balance')) {
      return 'errors.ai_balance_empty'.tr();
    }
    if (lower.contains('401') || lower.contains('invalid api key')) {
      return 'errors.ai_key_invalid'.tr();
    }
    if (lower.contains('429') || lower.contains('rate limit')) {
      return 'errors.ai_rate_limit'.tr();
    }
    if (lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('socketexception') ||
        lower.contains('network is unreachable') ||
        lower.contains('clientexception')) {
      return 'errors.network_error'.tr();
    }
    if (lower.contains('timeoutexception') || lower.contains('timed out')) {
      return 'errors.server_error'.tr();
    }
    if (clean.length > 120) {
      return 'errors.unknown_error'.tr();
    }
    return clean;
  }
}
