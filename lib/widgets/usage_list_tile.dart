import 'package:flutter/material.dart';
import '../models/app_usage_model.dart';

class UsageListTile extends StatelessWidget {
  final AppUsageModel usage;
  final String Function(Duration) formatDuration;

  const UsageListTile({
    super.key,
    required this.usage,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
        child: Icon(Icons.apps, color: colorScheme.primary),
      ),
      title: Text(
        usage.appName,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        "Paket: ${usage.packageName}",
        style: textTheme.bodySmall?.copyWith(
          color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
      ),
      trailing: Text(
        formatDuration(usage.totalTimeUsed),
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
