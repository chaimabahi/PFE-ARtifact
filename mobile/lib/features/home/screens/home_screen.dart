import 'package:ARtifact/core/services/quiz_service.dart';
import 'package:ARtifact/features/quiz/category/categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/models/Blogs_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../shared/l10n/app_localizations.dart';
import '../../blogs/blog_details.dart';
import '../../blogs/blogs_screen.dart';
import '../../events/events_screen.dart';
import '../../quiz/screens/ThemesScreen.dart';
import 'home_animations.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupNotifications();
    _refreshUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUserData(); // Refresh user data when the screen is resumed
    }
  }

  void _refreshUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.refreshUserData(); // Fetch latest user data
  }

  void _setupNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.subscribeToTopic('events');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _unreadNotifications++;
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EventsPage()),
      );
    });
  }

  String _getFlagAsset(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'assets/flags/en.jpg';
      case 'ar':
        return 'assets/flags/tn.png';
      case 'fr':
        return 'assets/flags/fr.png';
      default:
        return 'assets/flags/en.jpg';
    }
  }

  void _toggleLanguage(LocaleProvider localeProvider) {
    final currentLang = localeProvider.locale.languageCode;
    final nextLang = currentLang == 'en' ? 'ar' : currentLang == 'ar' ? 'fr' : 'en';
    localeProvider.setLocale(Locale(nextLang));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final userData = authProvider.userData;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification and Language Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Language Flag Icon
                  GestureDetector(
                    onTap: () => _toggleLanguage(localeProvider),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage(_getFlagAsset(localeProvider.locale.languageCode)),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey[300]!.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Notification Icon (Add your notification icon logic here if needed)
                ],
              ),

              // User Greeting Section
              FadeSlideTransition(
                delay: 100,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[100]!, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey[300]!.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue[600],
                        child: Text(
                          authProvider.user?.username?.substring(0, 2).toUpperCase() ?? 'US',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${localizations.translate('Hello')}, ${authProvider.user?.username ?? 'User'}!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              localizations.translate('lets_explore'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.emoji_events,
                                        size: 16,
                                        color: Colors.blue[800],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${userData?['plan'] ?? 'Basic'}',
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.yellow[800],
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${userData?['TotaleScore'] ?? 200}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                    ],
                                  ),
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

              const SizedBox(height: 24),

              // Featured Section
              FadeSlideTransition(
                delay: 300,
                child: Text(
                  localizations.translate('Featured'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.grey[900],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideTransition(
                delay: 400,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EventsPage()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/vr_event.png'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey[300]!.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discover our events!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Join Now',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recent Blogs Section
              FadeSlideTransition(
                delay: 500,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.translate('recent_blogs'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BlogsScreen()),
                        );
                      },
                      child: Text(
                        localizations.translate('see all'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideTransition(
                delay: 600,
                child: _RecentBlogsPreview(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentBlogsPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final currentLang = localeProvider.locale.languageCode;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('blogs')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: isDarkMode ? Colors.red[300] : Colors.red[400],
                ),
                const SizedBox(height: 12),
                Text(
                  localizations.translate('error_occurred'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.article,
                  size: 40,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  localizations.translate('no_favorites'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final blogs = snapshot.data!.docs.map((doc) {
          return Blog.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();

        return Column(
          children: blogs.asMap().entries.map((entry) {
            final blog = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FadeSlideTransition(
                delay: (200 * (entry.key + 1)).toInt(),
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
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Blog Image
                        Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            image: blog.images.isNotEmpty
                                ? DecorationImage(
                              image: CachedNetworkImageProvider(blog.images.first),
                              fit: BoxFit.cover,
                            )
                                : const DecorationImage(
                              image: AssetImage('assets/images/placeholder.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: blog.images.isNotEmpty
                              ? null
                              : Center(
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode ? Colors.white : Colors.grey[900],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                blog.excerpt[currentLang] ?? blog.excerpt['en']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.blue[900] : Colors.blue[50],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${blog.createdAt.day}/${blog.createdAt.month}/${blog.createdAt.year}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.blue[900] : Colors.blue[50],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          size: 12,
                                          color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${blog.views} ${localizations.translate('views')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
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
          }).toList(),
        );
      },
    );
  }
}