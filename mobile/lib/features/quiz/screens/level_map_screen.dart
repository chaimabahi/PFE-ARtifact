import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/quiz_models.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/providers/locale_provider.dart';
import '../widgets/level_map.dart';

class LevelMapScreen extends StatelessWidget {
  final QuizTheme theme;
  final String category;
  final QuizService quizService;

  LevelMapScreen({
    Key? key,
    required this.theme,
    required this.category,
    QuizService? quizService,
  })  : quizService = quizService ?? QuizService(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLang = localeProvider.locale.languageCode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade200.withAlpha(179),
              Colors.green.shade600.withAlpha(128),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                'https://i.pinimg.com/736x/73/eb/87/73eb87b7865cc9c4d169d91f1ce157ae.jpg',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          theme.getTitle(currentLang),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 5,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                        _buildLanguageDropdown(context, localeProvider, currentLang),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 16),
                  _buildLevelTitle(),
                  const SizedBox(height: 16),
                  _buildLevelMap(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(BuildContext context, LocaleProvider localeProvider, String currentLang) {
    const languageOptions = [
      {'code': 'en', 'label': 'English', 'flag': 'https://flagcdn.com/w40/us.png'},
      {'code': 'ar', 'label': 'العربية', 'flag': 'https://flagcdn.com/w40/tn.png'},
      {'code': 'fr', 'label': 'Français', 'flag': 'https://flagcdn.com/w40/fr.png'},
    ];

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Container(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: languageOptions.map((option) {
                  return ListTile(
                    leading: Image.network(
                      option['flag'] as String,
                      width: 24,
                      height: 24,
                    ),
                    title: Text(
                      option['label'] as String,
                      style: const TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      final newValue = option['code'] as String;
                      if (newValue != currentLang) {
                        localeProvider.setLocale(Locale(newValue));
                      }
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(100),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Image.network(
            languageOptions.firstWhere((option) => option['code'] == currentLang)['flag'] as String,
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        'Select a Level',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 5,
              offset: Offset(1, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelMap() {
    return Expanded(
      child: StreamBuilder<List<String>>(
        stream: quizService.getLevels(category, theme.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(204),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          final levels = snapshot.data ?? _generateDefaultLevels();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LevelMap(
              theme: theme,
              category: category,
              levels: levels,
              quizService: quizService,
            ),
          );
        },
      ),
    );
  }

  List<String> _generateDefaultLevels() {
    return List.generate(5, (index) => 'level${index + 1}');
  }
}