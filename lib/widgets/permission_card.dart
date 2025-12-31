import 'package:flutter/material.dart';
import '../services/usage_service.dart';
import '../constants/app_strings.dart';

class PermissionDeniedWidget extends StatelessWidget {
  final UsageService service;

  const PermissionDeniedWidget({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.lock_outline, size: 80, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            AppStrings.permissionTitle,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.permissionDescription,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Buka Pengaturan Izin'),
            onPressed: () => service.checkAndRequestPermission(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}
