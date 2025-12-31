import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../constants/app_colors.dart'; // Only for danger color if needed

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: Removed ChangeNotifierProvider here because it is already provided in main.dart

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(context, 'Batas Penggunaan'),
              _buildDailyLimitSetting(context, settingsProvider),

              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Notifikasi'),
              _buildNotificationSettings(context, settingsProvider),

              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Tampilan'),
              _buildAppearanceSettings(context, settingsProvider),

              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Data'),
              _buildDataSettings(context, settingsProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          // FIX: Use colorScheme.primary instead of primaryColor
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDailyLimitSetting(
    BuildContext context,
    SettingsProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Batas Waktu Layar Harian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: provider.dailyLimitHours.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    activeColor: colorScheme.primary,
                    thumbColor: colorScheme.primary,
                    onChanged: (value) {
                      provider.setDailyLimit(value.round());
                    },
                  ),
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${provider.dailyLimitHours}h',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Text(
              'Anda akan mendapat peringatan jika melebihi batas ini',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings(
    BuildContext context,
    SettingsProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSwitchTile(
              context: context,
              title: 'Aktifkan Notifikasi',
              subtitle: 'Terima pengingat dan peringatan',
              value: provider.notificationsEnabled,
              onChanged: provider.toggleNotifications,
            ),
            const Divider(),
            _buildSwitchTile(
              context: context,
              title: 'Pengingat Istirahat',
              subtitle: 'Ingatkan untuk beristirahat secara berkala',
              value: provider.breakReminderEnabled,
              onChanged: provider.toggleBreakReminder,
            ),
            if (provider.breakReminderEnabled) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Interval Pengingat'),
                  DropdownButton<int>(
                    value: provider.reminderIntervalMinutes,
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 menit')),
                      DropdownMenuItem(value: 60, child: Text('1 jam')),
                      DropdownMenuItem(value: 120, child: Text('2 jam')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        provider.setReminderInterval(value);
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSettings(
    BuildContext context,
    SettingsProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildSwitchTile(
          context: context,
          title: 'Mode Gelap',
          subtitle: 'Gunakan tema gelap untuk aplikasi',
          value: provider.darkModeEnabled,
          onChanged: provider.toggleDarkMode,
        ),
      ),
    );
  }

  Widget _buildDataSettings(BuildContext context, SettingsProvider provider) {
    // FIX: Use colorScheme.primary to ensure correct color in Dark Mode
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.restore, color: primaryColor),
              title: const Text('Reset Pengaturan'),
              subtitle: const Text('Kembalikan ke pengaturan default'),
              onTap: () => _showResetDialog(context, provider),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info, color: primaryColor),
              title: const Text('Tentang Aplikasi'),
              subtitle: const Text('Versi 1.0.0'),
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Future<void> Function(bool) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(
            context,
          ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
        ),
      ),
      trailing: Switch(
        value: value,
        activeTrackColor: colorScheme.primary,
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return Colors.grey.shade400;
        }),
        onChanged: onChanged,
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Pengaturan'),
          content: const Text(
            'Apakah Anda yakin ingin mengembalikan semua pengaturan ke default?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                provider.resetToDefaults();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Pengaturan berhasil direset'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
              child: const Text(
                'Reset',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Digital Wellbeing',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.phone_android,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: [
        const Text(
          'Aplikasi untuk membantu Anda memantau dan mengelola penggunaan perangkat digital secara sehat.',
        ),
      ],
    );
  }
}
