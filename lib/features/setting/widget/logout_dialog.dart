import 'package:flutter/material.dart';

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({
    super.key,
    required this.onConfirm,
  });

  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: const Text('Sign out'),
      content: const Text(
        'You will need to log in again to use the app on this device.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop(true);
            await onConfirm();
          },
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
