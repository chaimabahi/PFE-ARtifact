import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/quiz_models.dart';
import '../../../core/providers/locale_provider.dart';
import '../screens/level_map_screen.dart';

class ThemeCard extends StatelessWidget {
  final QuizTheme theme;
  final String category;

  const ThemeCard({
    Key? key,
    required this.theme,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLang = localeProvider.locale.languageCode;

    return GestureDetector(
      onTap: () => _navigateToLevelMap(context),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildThemeImage(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                theme.getTitle(currentLang), // Use localized title
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeImage() {
    if (theme.imageUrl.isNotEmpty && Uri.tryParse(theme.imageUrl)?.isAbsolute == true) {
      return Image.network(
        theme.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Stack(
            alignment: Alignment.center,
            children: [
              _buildPlaceholder(),
              CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white,
              ),
            ],
          );
        },
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    final themeTitle = theme.getTitle('en'); // Use English for placeholder
    final themeInitial = themeTitle.isNotEmpty ? themeTitle[0].toUpperCase() : '?';

    return Container(
      color: _getColorForTheme(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              themeInitial,
              style: const TextStyle(
                fontSize: 53,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.image_not_supported,
              size: 24,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForTheme() {
    final themeTitle = theme.getTitle('en'); // Use English for consistent color
    if (themeTitle.isEmpty) return Colors.grey[700]!;

    int hash = 0;
    for (var i = 0; i < themeTitle.length; i++) {
      hash = themeTitle.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final hue = (hash % 360).abs();
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.4).toColor();
  }

  void _navigateToLevelMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelMapScreen(
          theme: theme,
          category: category,
        ),
      ),
    );
  }
}