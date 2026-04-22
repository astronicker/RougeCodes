import 'package:flutter/material.dart';

/// Displays a reusable confirmation dialog before performing actions (Accept/Reject).
void showConfirmationDialog({
  required BuildContext parentContext,
  required String title,
  required String message,
  required String confirmText,
  required Color confirmColor,
  required VoidCallback onConfirm,
}) {
  showDialog<void>(
    context: parentContext,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          // Cancel Button
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: confirmColor.withAlpha(230)),
            ),
          ),

          // Confirm Button
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () {
              onConfirm();
              Navigator.of(dialogContext).pop(); // Close dialog
            },
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}
