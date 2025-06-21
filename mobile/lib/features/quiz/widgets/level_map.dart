import 'package:flutter/material.dart';
import '../../../core/models/quiz_models.dart';
import '../../../core/services/quiz_service.dart';
import '../screens/questions_screen.dart';
import 'path_painter.dart';

class LevelMap extends StatefulWidget {
  final QuizTheme theme;
  final String category;
  final List<String> levels;
  final QuizService quizService;

  const LevelMap({
    Key? key,
    required this.theme,
    required this.category,
    required this.levels,
    required this.quizService,
  }) : super(key: key);

  @override
  State<LevelMap> createState() => _LevelMapState();
}

class _LevelMapState extends State<LevelMap> {
  int _completedLevelsCount = 0;
  bool _isLoading = true;
  List<String> _completedLevelIds = [];

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sortedLevels = List<String>.from(widget.levels)..sort();
      _completedLevelIds = [];

      // Check each level if it's completed
      for (final levelId in sortedLevels) {
        final isCompleted = await widget.quizService.isLevelCompleted(
            widget.category,
            widget.theme.id,
            levelId
        );

        if (isCompleted) {
          _completedLevelIds.add(levelId);
        } else {
          // Stop checking once we find an incomplete level
          // (assuming levels must be completed in order)
          break;
        }
      }

      setState(() {
        _completedLevelsCount = _completedLevelIds.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user progress: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedLevels = List<String>.from(widget.levels)..sort();

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: PathPainter(
                  levelCount: sortedLevels.length,
                  completedLevels: _completedLevelsCount,
                ),
              ),
            ),
            ..._buildLevelPositions(context, sortedLevels, constraints),
          ],
        );
      },
    );
  }

  List<Widget> _buildLevelPositions(BuildContext context, List<String> levels, BoxConstraints constraints) {
    return List.generate(
      levels.length,
          (index) {
        final levelNumber = index + 1;
        final levelId = levels[index];
        final progress = index / (levels.length - 1);
        final y = constraints.maxHeight * (0.9 - progress * 0.8);
        final x = constraints.maxWidth * (index % 2 == 0 ? 0.7 : 0.3);

        return Positioned(
          left: x - 40,
          top: y - 40,
          child: _buildLevelButton(context, levelNumber, levelId),
        );
      },
    );
  }

  Widget _buildLevelButton(BuildContext context, int levelNumber, String levelId) {
    final sortedLevels = List<String>.from(widget.levels)..sort();
    final isCompleted = _completedLevelIds.contains(levelId);
    final isUnlocked = isCompleted || levelNumber == 1 ||
        (levelNumber > 1 && _completedLevelIds.contains(sortedLevels[levelNumber - 2]));

    return GestureDetector(
      onTap: isUnlocked
          ? () => _navigateToQuestions(context, levelId, levelNumber)
          : () => _showLockedMessage(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isCompleted
              ? Colors.green
              : (isUnlocked ? Colors.blue : Colors.grey),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? Colors.green.withOpacity(0.3)
                  : (isUnlocked ? Colors.blue.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isCompleted)
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 30,
              )
            else if (isUnlocked)
              Text(
                '$levelNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const Icon(
                Icons.lock,
                color: Colors.white,
                size: 30,
              ),
            if (isUnlocked && !isCompleted)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.7),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLockedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complete previous levels first!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToQuestions(BuildContext context, String levelId, int levelNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionsScreen(
          theme: widget.theme,
          category: widget.category,
          levelId: levelId,
          levelNumber: levelNumber,
          quizService: widget.quizService,
        ),
      ),
    ).then((_) {
      // Refresh the progress when returning from questions screen
      _loadUserProgress();
    });
  }
}
