import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/models/Blogs_model.dart';
import '../../core/providers/theme_provider.dart';
import '../home/screens/home_animations.dart';
import 'blog_details.dart';
import '../../../shared/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';


class BlogsScreen extends StatelessWidget {
  const BlogsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final currentLang = localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Back Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  FadeSlideTransition(
                    delay: 100,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
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
                  // Blog Articles Title
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FadeSlideTransition(
                        delay: 150,
                        child: Text(
                          localizations.translate('blog_articles'),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDarkMode ? Colors.white : Colors.grey[900],
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  // Empty container for balance
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Blogs List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('blogs').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: isDarkMode ? Colors.red[300] : Colors.red[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            localizations.translate('error_occurred'),
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white70 : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final blogs = snapshot.data!.docs.map((doc) {
                    return Blog.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: blogs.length,
                    itemBuilder: (context, index) {
                      final blog = blogs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FadeSlideTransition(
                          delay: 200 + (index * 100),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlogDetailsScreen(blog: blog),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[800] : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Blog Image
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: blog.images.isNotEmpty
                                        ? CachedNetworkImage(
                                      imageUrl: blog.images.first,
                                      height: 220,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        height: 220,
                                        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        height: 220,
                                        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 48,
                                          color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                        ),
                                      ),
                                    )
                                        : Container(
                                      height: 220,
                                      width: double.infinity,
                                      color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                      child: Icon(
                                        Icons.article,
                                        size: 48,
                                        color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                  // Blog Content
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          blog.title[currentLang] ?? blog.title['en']!,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: isDarkMode ? Colors.white : Colors.grey[900],
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          blog.excerpt[currentLang] ?? blog.excerpt['en']!,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                            height: 1.4,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 16,
                                                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${localizations.translate('by')} ${blog.author}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.visibility,
                                                  size: 16,
                                                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${blog.views} ${localizations.translate('views')}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}