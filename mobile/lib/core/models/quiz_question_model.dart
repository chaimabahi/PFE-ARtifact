import 'package:cloud_firestore/cloud_firestore.dart';

class QuizQuestion {
  final String id;
  final Map<String, String> text; // Multilingual question text
  final Map<String, List<String>> options; // Multilingual options
  final Map<String, String> correct; // Multilingual correct answers

  QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correct,
  });

  factory QuizQuestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Helper function to convert dynamic map to String map
    Map<String, String> convertStringMap(dynamic value) {
      if (value is String) {
        return {'en': value};
      } else if (value is Map) {
        return Map<String, String>.fromEntries(
            (value as Map).entries.map((e) =>
                MapEntry(e.key.toString(), e.value.toString())
            ));
            }
            return {'en': ''};
        }

    // Helper function to convert options map
    Map<String, List<String>> convertOptionsMap(dynamic value) {
      final result = <String, List<String>>{};

      if (value is Map) {
        (value as Map<String, dynamic>).forEach((lang, options) {
          if (options is Map) {
            // Convert numbered options to ordered list
            final sortedKeys = options.keys.toList()
              ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
            result[lang] = sortedKeys.map((key) => options[key].toString()).toList();
          } else if (options is List) {
            result[lang] = List<String>.from(options);
          }
        });
      } else if (value is List) {
        result['en'] = List<String>.from(value);
      }

      return result;
    }

    return QuizQuestion(
      id: doc.id,
      text: convertStringMap(data['question']),
      options: convertOptionsMap(data['options']),
      correct: convertStringMap(data['correct']),
    );
  }

  bool isCorrectAnswer(String answer, String languageCode) {
    return answer == (correct[languageCode] ?? correct['en'] ?? '');
  }

  int getCorrectAnswerIndex(String languageCode) {
    final correctAnswer = correct[languageCode] ?? correct['en'] ?? '';
    final langOptions = options[languageCode] ?? options['en'] ?? [];
    return langOptions.indexOf(correctAnswer);
  }

  Map<String, dynamic> toMap() {
    // Convert options to Firestore-friendly format
    Map<String, dynamic> formattedOptions = {};
    options.forEach((lang, optionList) {
      final Map<String, String> numberedOptions = {};
      for (int i = 0; i < optionList.length; i++) {
        numberedOptions[i.toString()] = optionList[i];
      }
      formattedOptions[lang] = numberedOptions;
    });

    return {
      'question': text,
      'options': formattedOptions,
      'correct': correct,
    };
  }

  // Helper methods to get localized content
  String getQuestionText(String languageCode) =>
      text[languageCode] ?? text['en'] ?? 'Unknown Question';

  List<String> getOptions(String languageCode) =>
      options[languageCode] ?? options['en'] ?? [];

  String getCorrectAnswer(String languageCode) =>
      correct[languageCode] ?? correct['en'] ?? '';

  QuizQuestion copyWith({
    String? id,
    Map<String, String>? text,
    Map<String, List<String>>? options,
    Map<String, String>? correct,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      options: options ?? this.options,
      correct: correct ?? this.correct,
    );
  }

  @override
  String toString() {
    return 'QuizQuestion(id: $id, text: $text, options: $options, correct: $correct)';
  }
}