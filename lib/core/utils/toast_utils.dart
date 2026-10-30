import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
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
      closeButtonShowType: CloseButtonShowType.always,
      dragToClose: true,
      backgroundColor: AppColors.surface,
      primaryColor: AppColors.success,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      boxShadow: highModeShadow,
    );
  }

  static void showError(BuildContext context, String error) {
    String cleanError = error.replaceAll('Exception: ', '');
    if (cleanError.contains('Failed host lookup') || cleanError.contains('Connection refused') || cleanError.contains('SocketException')) {
      cleanError = "Internet tarmog'iga ulanishda xatolik";
    }

    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: Text(cleanError, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.always,
      dragToClose: true,
      backgroundColor: AppColors.surface,
      primaryColor: AppColors.error,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      boxShadow: highModeShadow,
    );
  }
}
