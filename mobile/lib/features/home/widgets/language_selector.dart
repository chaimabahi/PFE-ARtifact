import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  final Function(Locale) onLocaleChanged;

  const LanguageSelector({
    Key? key,
    required this.currentLocale,
    required this.onLocaleChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localizations.translate('language'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          _buildLanguageOption(
            context,
            'English',
            const Locale('en', ''),
            'English',
          ),
          _buildLanguageOption(
            context,
            'Français',
            const Locale('fr', ''),
            'French',
          ),
          _buildLanguageOption(
            context,
            'العربية',
            const Locale('ar', ''),
            'Arabic',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String title,
    Locale locale,
    String languageCode,
  ) {
    final isSelected = currentLocale.languageCode == locale.languageCode;
    
    return InkWell(
      onTap: () => onLocaleChanged(locale),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}
