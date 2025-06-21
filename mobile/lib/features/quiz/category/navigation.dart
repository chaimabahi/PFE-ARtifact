import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/theme_provider.dart';


class CategoryChipsRow extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryChipsRow({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCategoryChip(
            context,
            "History",
            selected: selectedCategory == "History",
            isDarkMode: isDarkMode,
          ),
          const SizedBox(width: 20),
          _buildCategoryChip(
            context,
            "Geography",
            selected: selectedCategory == "Geography",
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
      BuildContext context,
      String text, {
        bool selected = false,
        required bool isDarkMode,
      }) {
    return GestureDetector(
      onTap: () => onCategorySelected(text),
      child: Container(
        width: 160, // Increased width for larger chips
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // Increased padding
        decoration: BoxDecoration(
          color: selected
              ? (isDarkMode ? Colors.blue[700] : Colors.blue[500])
              : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18, // Increased font size
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? Colors.white
                : (isDarkMode ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}