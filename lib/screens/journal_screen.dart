import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Ensure you have intl package or use manual formatting
import '../providers/mood_provider.dart';
import '../models/mood_entry_model.dart'; // Verify this import path

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final moodProvider = Provider.of<MoodProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    // 1. Group entries by Date String
    final groupedEntries = <String, List<dynamic>>{}; // List<MoodEntryModel>

    for (var entry in moodProvider.moodEntries) {
      // Create a key like "Wednesday, Dec 24, 2025"
      final dateKey = DateFormat.yMMMMEEEEd().format(entry.timestamp);

      if (!groupedEntries.containsKey(dateKey)) {
        groupedEntries[dateKey] = [];
      }
      groupedEntries[dateKey]!.add(entry);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: moodProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupedEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada jurnal minggu ini",
                    style: TextStyle(color: colorScheme.outline),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                80,
              ), // Bottom padding for FAB
              itemCount: groupedEntries.length,
              itemBuilder: (context, index) {
                final dateKey = groupedEntries.keys.elementAt(index);
                final dayEntries = groupedEntries[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- DATE SEPARATOR ---
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              dateKey, // e.g. "Wednesday, Dec 24, 2025"
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(indent: 12)),
                        ],
                      ),
                    ),

                    // --- ENTRIES FOR THIS DATE ---
                    ...dayEntries.map((entry) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getMoodColor(
                              entry.mood,
                              colorScheme,
                            ).withValues(alpha: 0.2),
                            child: Text(
                              _getMoodEmoji(entry.mood),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            entry.mood,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: entry.notes.isNotEmpty
                              ? Text(entry.notes)
                              : null,
                          trailing: Text(
                            DateFormat('HH:mm').format(entry.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        onPressed: () => _showAddMoodDialog(context, moodProvider),
        icon: const Icon(Icons.add),
        label: const Text("Catat Mood"),
      ),
    );
  }

  // Helper for Emoji based on string
  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'Sangat Senang':
        return '🤩';
      case 'Senang':
        return '🙂';
      case 'Netral':
        return '😐';
      case 'Sedih':
        return '😔';
      case 'Lelah':
        return '😫';
      case 'Stres':
        return '🤯'; // Added Stres
      default:
        return '😐';
    }
  }

  // Helper for Color based on mood
  Color _getMoodColor(String mood, ColorScheme scheme) {
    switch (mood) {
      case 'Sangat Senang':
        return Colors.green;
      case 'Senang':
        return Colors.lightGreen;
      case 'Netral':
        return Colors.grey;
      case 'Sedih':
        return Colors.blue;
      case 'Lelah':
        return Colors.orange;
      case 'Stres':
        return Colors.red;
      default:
        return scheme.primary;
    }
  }

  void _showAddMoodDialog(BuildContext context, MoodProvider provider) {
    String selectedMood = 'Netral';
    TextEditingController notesController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Catat Mood Anda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Mood',
                  border: OutlineInputBorder(),
                ),
                value: selectedMood,
                items:
                    [
                          'Sangat Senang',
                          'Senang',
                          'Netral',
                          'Sedih',
                          'Lelah',
                          'Stres',
                        ]
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Text(_getMoodEmoji(value)),
                                const SizedBox(width: 8),
                                Text(value),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) selectedMood = newValue;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              onPressed: () {
                provider.addMoodEntry(selectedMood, notesController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
