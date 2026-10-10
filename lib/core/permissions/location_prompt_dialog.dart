import 'package:flutter/material.dart';

import 'package:fund_nexus/core/permissions/permission_coordinator.dart';

enum LocationPromptResult { continueFlow, openSettings }

class LocationPrompt {
  const LocationPrompt({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  factory LocationPrompt.forDecision(LocationAccessDecision decision) {
    if (decision == LocationAccessDecision.serviceDisabled) {
      return const LocationPrompt(
        title: 'Enable Device Location',
        message:
            "Your phone's Location Services are off. Turn them on to confirm "
            'your identity during credit assessment and ensure safe, '
            'authorized account access.',
        confirmLabel: 'Settings',
      );
    }
    return const LocationPrompt(
      title: 'Location Permission Needed',
      message:
          'Location access is required to confirm your identity and ensure '
          'only authorized users can access this account.',
      confirmLabel: 'Continue',
    );
  }

  final String title;
  final String message;
  final String confirmLabel;
}

Future<LocationPromptResult> showLocationPromptDialog(
  BuildContext context,
  LocationPrompt prompt,
) async {
  if (!context.mounted) return LocationPromptResult.continueFlow;
  final result = await showDialog<LocationPromptResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(prompt.title),
      content: Text(prompt.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(
            dialogContext,
          ).pop(LocationPromptResult.continueFlow),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            dialogContext,
          ).pop(LocationPromptResult.openSettings),
          child: Text(prompt.confirmLabel),
        ),
      ],
    ),
  );
  return result ?? LocationPromptResult.continueFlow;
}
