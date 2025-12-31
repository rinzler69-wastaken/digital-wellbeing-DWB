class MoodEntryModel {
  final int id;
  final DateTime timestamp;
  final String mood; // cth: 'Senang', 'Stres', 'Netral'
  final String notes;

  MoodEntryModel({
    required this.id,
    required this.timestamp,
    required this.mood,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'timestamp': timestamp.millisecondsSinceEpoch,
      'mood': mood,
      'notes': notes,
    };

    // CRITICAL FIX: Only include ID if it's a valid existing ID (> 0).
    // For new entries (id == 0), we exclude it so the Database generates a NEW Auto-Increment ID.
    if (id > 0) {
      map['id'] = id;
    }

    return map;
  }

  factory MoodEntryModel.fromMap(Map<String, dynamic> map) {
    return MoodEntryModel(
      id: map['id'] ?? 0, // Handle null case safely
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      mood: map['mood'] ?? 'Netral',
      notes: map['notes'] ?? '',
    );
  }
}
