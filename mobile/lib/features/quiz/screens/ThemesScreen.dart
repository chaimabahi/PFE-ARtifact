import 'package:flutter/material.dart';
import '../../../core/models/quiz_models.dart';
import '../../../core/services/quiz_service.dart';
import '../widgets/theme_card.dart';

import 'debug_helper.dart';

class ThemesScreen extends StatelessWidget {
  final String category;
  final QuizService quizService;
  final bool showAppBar;
  final bool debugMode;

  ThemesScreen({
    Key? key,
    required this.category,
    this.showAppBar = true,
    this.debugMode = false,
    QuizService? quizService,
  })  : quizService = quizService ?? QuizService(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return showAppBar
        ? Scaffold(
          appBar: AppBar(
            title: const Text('Quiz'),
            backgroundColor: const Color(0xff6200ee),
          ),
          body: _buildThemesList(),
    )
        : _buildThemesList();
  }

  Widget _buildThemesList() {
    return StreamBuilder<List<QuizTheme>>(
      stream: quizService.getThemes(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No themes found'));
        }

        // Debug: Print all themes and their image URLs
        if (debugMode) {
          for (var theme in snapshot.data!) {
            DebugHelper.printThemeInfo(theme);
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final theme = snapshot.data![index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 350,
                    child: ThemeCard(
                      theme: theme,
                      category: category,
                    ),
                  ),
                  if (debugMode) ...[
                    const SizedBox(height: 8),
                    DebugHelper.buildDebugButton(context, theme),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
