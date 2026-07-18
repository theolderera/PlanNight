import 'package:flutter/material.dart';

import '../theme.dart';

/// A small inline error banner used across forms.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: c.dangerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.dangerBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: c.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: c.danger, fontWeight: FontWeight.w600, fontSize: 13, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
