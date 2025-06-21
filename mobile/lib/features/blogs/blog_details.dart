import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/Blogs_model.dart';
import '../../../shared/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../home/screens/home_animations.dart';


class BlogDetailsScreen extends StatefulWidget {
  final Blog blog;

  const BlogDetailsScreen({Key? key, required this.blog}) : super(key: key);

  @override
  State<BlogDetailsScreen> createState() => _BlogDetailsScreenState();
}

class _BlogDetailsScreenState extends State<BlogDetailsScreen> {
  bool _isFavorite = false;
  bool _isLoading = true;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (userDoc.exists) {
        final favorites = List<String>.from(userDoc.data()?['favorites'] ?? []);
        if (mounted) {
          setState(() {
            _isFavorite = favorites.contains(widget.blog.id);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).translate('error_occurred')}: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(_userId);

      if (_isFavorite) {
        await userRef.update({
          'favorites': FieldValue.arrayRemove([widget.blog.id])
        });
      } else {
        await userRef.update({
          'favorites': FieldValue.arrayUnion([widget.blog.id])
        });
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).translate('error_occurred')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final currentLang = localeProvider.locale.languageCode;
    final blog = widget.blog;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Carousel with Favorite and Back Buttons
              Stack(
                children: [
                  if (blog.images.isNotEmpty)
                    SizedBox(
                      height: 300,
                      child: PageView.builder(
                        itemCount: blog.images.length,
                        itemBuilder: (context, index) {
                          return FadeSlideTransition(
                            delay: 100,
                            child: CachedNetworkImage(
                              imageUrl: blog.images[index],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 300,
                      width: double.infinity,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      child: Icon(
                        Icons.article,
                        size: 64,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  // Back Button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          size: 24,
                          color: isDarkMode ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.black26 : Colors.grey[300]!.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red[600] : isDarkMode ? Colors.white70 : Colors.grey[600],
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Content Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blog Title
                    FadeSlideTransition(
                      delay: 200,
                      child: Text(
                        blog.title[currentLang] ?? blog.title['en']!,
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.w800,
                          color: isDarkMode ? Colors.white : Colors.grey[900],
                          height: 1.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Metadata
                    FadeSlideTransition(
                      delay: 300,
                      child: Row(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 18.0,
                                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${localizations.translate('by')} ${blog.author}',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 18.0,
                                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${blog.views} ${localizations.translate('views')}',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18.0,
                                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${blog.createdAt.day}/${blog.createdAt.month}/${blog.createdAt.year}',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Blog Excerpt
                    FadeSlideTransition(
                      delay: 400,
                      child: Text(
                        blog.excerpt[currentLang] ?? blog.excerpt['en']!,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white70 : Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Blog Content
                    FadeSlideTransition(
                      delay: 500,
                      child: Text(
                        blog.content[currentLang] ?? blog.content['en']!,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: isDarkMode ? Colors.white70 : Colors.grey[900],
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}