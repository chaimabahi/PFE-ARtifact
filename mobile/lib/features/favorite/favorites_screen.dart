import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/models/Blogs_model.dart';
import '../blogs/blog_details.dart';
import '../../../shared/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import 'animation.dart'; // Added import for ScaleAnimation

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  Stream<List<Blog>> _getFavoriteBlogs(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return [];

      final favorites = List<String>.from(userDoc.data()?['favorites'] ?? []);
      if (favorites.isEmpty) return [];

      final blogs = await FirebaseFirestore.instance
          .collection('blogs')
          .where(FieldPath.documentId, whereIn: favorites)
          .get();

      return blogs.docs
          .map((doc) => Blog.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> _removeFromFavorites(BuildContext context, String userId, String blogId, String blogTitle) async {
    final localizations = AppLocalizations.of(context);
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.translate('remove_favorite')),
          content: Text(localizations.translate('remove_favorite_confirm').replaceAll('{blogTitle}', blogTitle)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                localizations.translate('remove'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'favorites': FieldValue.arrayRemove([blogId])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('favorite_removed_msg').replaceAll('{blogTitle}', blogTitle)),
          action: SnackBarAction(
            label: localizations.translate('undo'),
            textColor: Colors.white,
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .update({
                'favorites': FieldValue.arrayUnion([blogId])
              });
            },
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final localizations = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLang = localeProvider.locale.languageCode;
    final AnimationController controller = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 1200),
    )..forward();

    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<Blog>>(
            stream: _getFavoriteBlogs(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(localizations.translate('error_occurred')));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final blogs = snapshot.data!;

              if (blogs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.translate('no_favorites'),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.translate('add_favorites'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
                itemCount: blogs.length,
                itemBuilder: (context, index) {
                  final blog = blogs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlogDetailsScreen(blog: blog),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: blog.images.isNotEmpty
                                    ? CachedNetworkImage(
                                  imageUrl: blog.images.first,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 200,
                                    color: Colors.grey[200],
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.error),
                                  ),
                                )
                                    : Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.article,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      blog.getTitle(currentLang),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      blog.getExcerpt(currentLang),
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 16,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${localizations.translate('by')} ${blog.author}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${blog.createdAt.day}/${blog.createdAt.month}/${blog.createdAt.year}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
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
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Material(
                            color: Colors.white.withOpacity(0.9),
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeFromFavorites(context, userId, blog.id, blog.getTitle(currentLang)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            child: ScaleAnimation(
              controller: controller,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
                onPressed: () {
                  controller.dispose(); // Dispose controller to prevent memory leaks
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}