import 'package:flutter/material.dart';
import '../models/mood_entry_model.dart';
import '../services/database_service.dart';

class MoodProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<MoodEntryModel> _moodEntries = [];
  bool _isLoading = false;

  List<MoodEntryModel> get moodEntries => _moodEntries;
  bool get isLoading => _isLoading;

  MoodProvider() {
    fetchMoodEntries();
  }

  Future<void> fetchMoodEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Get everything from the Database
      final data = await _dbService.getMoodEntries();

      // 2. --- AUTO-CLEAR LOGIC ---
      // Define the cutoff date (7 days ago)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      // Remove entries from the list that are older than 7 days
      // (This filters the UI list. The data remains in DB unless you delete it there too)
      data.removeWhere((entry) => entry.timestamp.isBefore(sevenDaysAgo));

      // 3. Sort data: Newest first (Descending order by timestamp)
      data.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _moodEntries = data;
    } catch (e) {
      debugPrint("Error fetching mood entries: $e");
      _moodEntries = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMoodEntry(String mood, String notes) async {
    // We send id: 0, but the Model's toMap() will now strip it out
    // so the DB creates a fresh ID.
    final newEntry = MoodEntryModel(
      id: 0,
      timestamp: DateTime.now(),
      mood: mood,
      notes: notes,
    );

    await _dbService.insertMoodEntry(newEntry);
    await fetchMoodEntries(); // Refresh list to get the new data and apply cleanup
  }

  Future<void> deleteEntry(int id) async {
    // Uncomment when DatabaseService has deleteMoodEntry
    // await _dbService.deleteMoodEntry(id);
    // await fetchMoodEntries();
  }
}
