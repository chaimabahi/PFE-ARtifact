import 'package:flutter/material.dart';
import '../../../core/models/quiz_models.dart';

class DebugHelper {
  static void printThemeInfo(QuizTheme theme) {
    print('Theme ID: ${theme.id}');
    print('Theme Title: ${theme.title}');
    print('Theme Image URL: ${theme.imageUrl}');
    print('Image URL valid: ${Uri.tryParse(theme.imageUrl)?.isAbsolute == true}');
  }

  static Widget buildDebugButton(BuildContext context, QuizTheme theme) {
    return ElevatedButton(
      onPressed: () {
        printThemeInfo(theme);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme info printed to console: ${theme.title}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: const Text('Debug Theme'),
    );
  }
}
