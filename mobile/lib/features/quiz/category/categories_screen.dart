import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/quiz_service.dart';
import '../screens/ThemesScreen.dart';
import 'navigation.dart';


class CategoriesScreen extends StatefulWidget {
  final bool debugMode;

  const CategoriesScreen({
    Key? key,
    this.debugMode = false,
  }) : super(key: key);

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String selectedCategory = 'History';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CategoryChipsRow(
                selectedCategory: selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    selectedCategory = category;
                  });
                },
              ),
            ),
            Expanded(
              child: ThemesScreen(
                category: selectedCategory,
                showAppBar: false,
                debugMode: widget.debugMode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}