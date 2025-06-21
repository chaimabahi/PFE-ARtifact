import 'package:cloud_firestore/cloud_firestore.dart';

class Blog {
  final String id;
  final Map<String, String> title; 
  final Map<String, String> content; 
  final Map<String, String> excerpt; 
  final String author;
  final DateTime createdAt;
  final List<String> images;
  final int views;
  final String? modelPath;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.author,
    required this.createdAt,
    required this.images,
    required this.views,
    this.modelPath,
  });

  factory Blog.fromMap(String id, Map<String, dynamic> map) {
    // Helper function to convert dynamic map to String map with fallback
    Map<String, String> convertLangMap(dynamic value) {
      if (value is String) {
        return {'en': value}; // Handle old string format
      } else if (value is Map) {
        // Convert Map<dynamic, dynamic> to Map<String, String>
        return Map<String, String>.fromEntries(
            (value as Map).entries.map((e) =>
                MapEntry(e.key.toString(), e.value.toString())
            ));
            }
            return {'en': ''}; // Fallback for invalid types
        }

    return Blog(
      id: id,
      title: convertLangMap(map['title']),
      content: convertLangMap(map['content']),
      excerpt: convertLangMap(map['excerpt']),
      author: map['author'] ?? 'Unknown',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      images: List<String>.from(map['images'] ?? []),
      views: map['views'] ?? 0,
      modelPath: map['modelPath'] ?? map['ModelPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'author': author,
      'createdAt': Timestamp.fromDate(createdAt),
      'images': images,
      'views': views,
      if (modelPath != null) 'modelPath': modelPath,
    };
  }

  // Helper methods to get text in specific language
  String getTitle(String languageCode) => title[languageCode] ?? title['en'] ?? '';
  String getContent(String languageCode) => content[languageCode] ?? content['en'] ?? '';
  String getExcerpt(String languageCode) => excerpt[languageCode] ?? excerpt['en'] ?? '';
}