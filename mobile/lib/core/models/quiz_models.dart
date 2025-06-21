import 'package:cloud_firestore/cloud_firestore.dart';

class QuizTheme {
  final String id;
  final Map<String, String> title; // Changed to Map for multilingual support
  final String imageUrl;

  QuizTheme({
    required this.id,
    required this.title,
    required this.imageUrl,
  });

  factory QuizTheme.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Get the image URL
    String imageUrl = '';
    if (data.containsKey('image') && data['image'] != null) {
      imageUrl = data['image'].toString();
    } else if (data.containsKey('imageUrl') && data['imageUrl'] != null) {
      imageUrl = data['imageUrl'].toString();
    }

    // Clean up the URL if needed
    if (imageUrl.startsWith('"') && imageUrl.endsWith('"')) {
      imageUrl = imageUrl.substring(1, imageUrl.length - 1);
    }

    // Handle title with proper type conversion
    final Map<String, String> titleMap;
    if (data['title'] is String) {
      titleMap = {'en': data['title'] as String};
    } else if (data['title'] is Map) {
      titleMap = (data['title'] as Map).map<String, String>(
            (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } else {
      titleMap = {'en': 'Unknown Theme'};
    }

    return QuizTheme(
      id: doc.id,
      title: titleMap,
      imageUrl: imageUrl,
    );
  }

  // Helper method to get title in specific language
  String getTitle(String languageCode) => title[languageCode] ?? title['en'] ?? 'Unknown Theme';
}

class QuizLevel {
  final String id;
  final int number;

  QuizLevel({
    required this.id,
    required this.number,
  });
}