import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/widgets/apex_text.dart';

class AccessErrorScreen extends ConsumerWidget {
  final String title;
  final String message;

  const AccessErrorScreen({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderDark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, color: orangeWarning, size: 36),
              const SizedBox(height: 16),
              ApexText(
                title,
                fontSize: 18,
                color: const Color(0xFFE8E8E8),
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ApexText(
                message,
                fontSize: 12,
                color: const Color(0xFF888888),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.read(authControllerProvider).signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('SIGN OUT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
