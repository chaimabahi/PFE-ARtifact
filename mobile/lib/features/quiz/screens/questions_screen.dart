import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/models/quiz_models.dart';
import '../../../core/models/quiz_question_model.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../shared/l10n/app_localizations.dart';

class QuestionsScreen extends StatefulWidget {
  final QuizTheme theme;
  final String category;
  final String levelId;
  final int levelNumber;
  final QuizService quizService;

  QuestionsScreen({
    Key? key,
    required this.theme,
    required this.category,
    required this.levelId,
    required this.levelNumber,
    QuizService? quizService,
  })  : quizService = quizService ?? QuizService(),
        super(key: key);

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  late Future<List<QuizQuestion>> _questionsFuture;
  int _currentQuestionIndex = 0;
  QuizQuestion? _currentQuestion;
  int? _selectedAnswerIndex;
  bool _answerSubmitted = false;
  int _correctAnswersCount = 0;
  bool _levelCompleted = false;

  @override
  void initState() {
    super.initState();
    _questionsFuture = widget.quizService.getRandomQuestions(
      widget.category,
      widget.theme.id,
      widget.levelId,
      5,
    );
    _checkLevelCompletion();
  }

  Future<void> _checkLevelCompletion() async {
    final isCompleted = await widget.quizService.isLevelCompleted(
      widget.category,
      widget.theme.id,
      widget.levelId,
    );
    setState(() {
      _levelCompleted = isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLang = localeProvider.locale.languageCode;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade100,
              Colors.purple.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<QuizQuestion>>(
            future: _questionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('${localizations.translate('error')}: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildNoQuestionsFound(localizations);
              }

              final questions = snapshot.data!;
              _currentQuestion ??= questions[_currentQuestionIndex];

              return Column(
                children: [
                  _buildAppBar(localizations, currentLang),
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / questions.length,
                    backgroundColor: Colors.grey[200],
                    color: Colors.indigo,
                    minHeight: 8,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white.withAlpha(243), // Adjusted opacity
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildQuestionHeader(questions.length, localizations, currentLang),
                              const SizedBox(height: 24),
                              Text(
                                _currentQuestion!.getQuestionText(currentLang),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 32),
                              ..._buildAnswerOptions(_currentQuestion!, currentLang),
                              if (_answerSubmitted) _buildAnswerFeedback(_currentQuestion!, currentLang, localizations),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildNavigationButtons(questions, localizations),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations localizations, String currentLang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            '${widget.theme.getTitle(currentLang)} - ${localizations.translate('level')} ${widget.levelNumber}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (_levelCompleted)
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(int totalQuestions, AppLocalizations localizations, String languageCode) {
    return Row(
      children: [
        CircularPercentIndicator(
          radius: 30.0,
          lineWidth: 5.0,
          percent: (_currentQuestionIndex + 1) / totalQuestions,
          center: Text(
            '${_currentQuestionIndex + 1}/$totalQuestions',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          progressColor: Colors.indigo,
          backgroundColor: Colors.grey.shade200,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            localizations.translate('question'),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAnswerOptions(QuizQuestion question, String languageCode) {
    final options = question.getOptions(languageCode);

    return options.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;

      Color buttonColor = Colors.white;
      Color borderColor = Colors.grey.shade300;
      if (_answerSubmitted) {
        if (index == question.getCorrectAnswerIndex(languageCode)) {
          buttonColor = Colors.green.shade100;
          borderColor = Colors.green;
        } else if (index == _selectedAnswerIndex) {
          buttonColor = Colors.red.shade100;
          borderColor = Colors.red;
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(51), // Adjusted opacity
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _answerSubmitted ? null : () {
                setState(() {
                  _selectedAnswerIndex = index;
                  _answerSubmitted = true;
                  if (question.isCorrectAnswer(option, languageCode)) {
                    _correctAnswersCount++;
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAnswerFeedback(QuizQuestion question, String languageCode, AppLocalizations localizations) {
    final isCorrect = _selectedAnswerIndex == question.getCorrectAnswerIndex(languageCode);
    final correctAnswer = question.getOptions(languageCode)[question.getCorrectAnswerIndex(languageCode)];

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: AnimatedOpacity(
        opacity: _answerSubmitted ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            Text(
              isCorrect ? localizations.translate('correct') : localizations.translate('wrong_answer'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 12),
              Text(
                '${localizations.translate('correct_answer')}: $correctAnswer',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(List<QuizQuestion> questions, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentQuestionIndex > 0)
            _buildNavigationButton(
              text: localizations.translate('previous'),
              onPressed: () {
                setState(() {
                  _currentQuestionIndex--;
                  _currentQuestion = questions[_currentQuestionIndex];
                  _selectedAnswerIndex = null;
                  _answerSubmitted = false;
                });
              },
            )
          else
            const SizedBox(width: 100),
          if (_currentQuestionIndex < questions.length - 1)
            _buildNavigationButton(
              text: localizations.translate('next'),
              onPressed: _answerSubmitted ? () {
                setState(() {
                  _currentQuestionIndex++;
                  _currentQuestion = questions[_currentQuestionIndex];
                  _selectedAnswerIndex = null;
                  _answerSubmitted = false;
                });
              } : null,
            )
          else
            _buildNavigationButton(
              text: localizations.translate('finish'),
              onPressed: _answerSubmitted ? () {
                _showQuizCompletionDialog(context, questions.length, localizations);
              } : null,
              isPrimary: true,
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({required String text, required VoidCallback? onPressed, bool isPrimary = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.indigo : Colors.grey.shade200,
          foregroundColor: isPrimary ? Colors.white : Colors.black87,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showQuizCompletionDialog(BuildContext context, int totalQuestions, AppLocalizations localizations) async {
    final scorePercentage = (_correctAnswersCount / totalQuestions * 100);
    await widget.quizService.saveLevelCompletion(
      widget.category,
      widget.theme.id,
      widget.levelId,
      _correctAnswersCount,
      totalQuestions,
    );

    setState(() {
      _levelCompleted = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localizations.translate('quiz_completed'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${localizations.translate('you_got')} $_correctAnswersCount ${localizations.translate('out_of')} $totalQuestions ${localizations.translate('correct')}!',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            CircularPercentIndicator(
              radius: 60.0,
              lineWidth: 8.0,
              percent: scorePercentage / 100,
              center: Text(
                '${scorePercentage.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              progressColor: Colors.indigo,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 16),
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('level_completed'),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('review_answers')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(localizations.translate('done')),
          ),
        ],
      ),
    );
  }

  Widget _buildNoQuestionsFound(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz, size: 80, color: Colors.indigo),
          const SizedBox(height: 24),
          Text(
            '${localizations.translate('no_questions_found')} ${localizations.translate('level')} ${widget.levelNumber}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${localizations.translate('path')}: /quizze/${widget.category.toLowerCase()}/themes/${widget.theme.id}/levels/${widget.levelId}/questions',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 40),
          _buildNavigationButton(
            text: localizations.translate('back_to_level_map'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}