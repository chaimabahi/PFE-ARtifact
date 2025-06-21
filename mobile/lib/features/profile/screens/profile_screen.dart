import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../shared/l10n/app_localizations.dart';
import '../../auth/screens/login_screen.dart';
import '../../favorite/favorites_screen.dart';
import '../../payment/screens/payment_screen.dart';
import '../screens/password_security_screen.dart';
import '../screens/support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final userData = authProvider.userData;

    // Format createdAt to show only date
    final createdAt = userData?['createdAt'] != null
        ? (userData!['createdAt'] is Timestamp
        ? DateFormat('yyyy-MM-dd').format(userData['createdAt'].toDate())
        : DateFormat('yyyy-MM-dd').format(DateTime.parse(userData['createdAt'])))
        : 'Recently';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  // Profile image
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: authProvider.user?.imageUrl != null
                        ? CircleAvatar(
                      radius: 80,
                      backgroundImage:
                      NetworkImage(authProvider.user!.imageUrl!),
                    )
                        : CircleAvatar(
                      radius: 80,
                      backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Plan badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      userData?['plan'] ?? 'Basic',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Profile Edit section
            _buildSection(
              context,
              title: AppLocalizations.of(context).translate('profile'),
              items: [
                _buildListItem(
                  context,
                  icon: Icons.edit,
                  title: AppLocalizations.of(context).translate('Personal details'),
                  subtitle: AppLocalizations.of(context).translate('Accout privacy'),
                  onTap: () => _showEditProfileDialog(context, authProvider),
                ),
                _buildListItem(
                  context,
                  icon: Icons.favorite,
                  title: AppLocalizations.of(context).translate('Saved'),
                  subtitle: AppLocalizations.of(context).translate('saved blogs'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SectionDivider(),
            // Theme and Language section
            _buildSection(
              context,
              title: AppLocalizations.of(context).translate('appearance'),
              items: [
                _buildThemeSelector(context, themeProvider),
                _buildLanguageSelector(context, localeProvider),
              ],
            ),
            const SectionDivider(),
            // Account section
            _buildSection(
              context,
              title: AppLocalizations.of(context).translate('account'),
              items: [
                _buildPinnedCard(
                  context,
                  icon: Icons.email_outlined,
                  title: authProvider.user?.email ?? '',
                  subtitle: AppLocalizations.of(context).translate('email'),
                ),
                _buildPinnedCard(
                  context,
                  icon: Icons.calendar_today_outlined,
                  title: createdAt,
                  subtitle: AppLocalizations.of(context).translate('joined'),
                ),
              ],
            ),
            const SectionDivider(),
            // Subscription section
            _buildSection(
              context,
              title: AppLocalizations.of(context).translate('subscription'),
              items: [
                _buildListItem(
                  context,
                  icon: Icons.star_outline,
                  title: AppLocalizations.of(context).translate('current_plan'),
                  subtitle: userData?['plan'] ?? 'Basic',
                  trailing: userData?['plan'] == 'Basic'
                      ? TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PaymentScreen()),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('upgrade'),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                      : null,
                ),
              ],
            ),
            const SectionDivider(),
            // Settings section
            _buildSection(
              context,
              title: AppLocalizations.of(context).translate('settings'),
              items: [
                _buildListItem(
                  context,
                  icon: Icons.lock_outline,
                  title: AppLocalizations.of(context).translate('password_security'),
                  subtitle: AppLocalizations.of(context).translate('change_password'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasswordSecurityScreen(),
                      ),
                    );
                  },
                ),
                _buildListItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: AppLocalizations.of(context).translate('notifications'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      _showNotificationDialog(context);
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
                _buildListItem(
                  context,
                  icon: Icons.help_outline,
                  title: AppLocalizations.of(context).translate('help_support'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupportScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SectionDivider(),
            // Sign Out button
            Center(
              child: _AnimatedCard(
                onTap: () async {
                  await authProvider.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).translate('sign_out'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          AppLocalizations.of(context).translate('notifications'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        content: Text(
          'Don\'t worry, you will receive all notifications via SMS.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('ok'),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    final usernameController = TextEditingController(text: authProvider.user?.username ?? '');
    final phoneController = TextEditingController(text: authProvider.user?.phoneNumber ?? '');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Text(
                    AppLocalizations.of(context).translate('Edit Profile'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Form
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).translate('username'),
                            prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                            filled: true,
                            fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context).translate('username_required');
                            }
                            if (value.length < 3) {
                              return AppLocalizations.of(context).translate('username_too_short');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).translate('phone_number'),
                            prefixIcon: Icon(Icons.phone_outlined, color: Theme.of(context).primaryColor),
                            filled: true,
                            fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) {
                                return AppLocalizations.of(context).translate('invalid_phone_number');
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppLocalizations.of(context).translate('cancel'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            try {
                              await authProvider.updateUserProfile(
                                username: usernameController.text,
                                phoneNumber: phoneController.text,
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).translate('profile_updated')),
                                  backgroundColor: Theme.of(context).primaryColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).translate('error_updating_profile')),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            } finally {
                              setState(() => isLoading = false);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text(
                          AppLocalizations.of(context).translate('save'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildPinnedCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
      }) {
    return _AnimatedCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    return _AnimatedCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context).translate('theme'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildThemeOption(
                  context,
                  title: AppLocalizations.of(context).translate('light'),
                  icon: Icons.light_mode,
                  isSelected: themeProvider.themeMode == ThemeMode.light,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                ),
                _buildThemeOption(
                  context,
                  title: AppLocalizations.of(context).translate('dark'),
                  icon: Icons.dark_mode,
                  isSelected: themeProvider.themeMode == ThemeMode.dark,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                ),
                _buildThemeOption(
                  context,
                  title: AppLocalizations.of(context).translate('system'),
                  icon: Icons.settings_brightness,
                  isSelected: themeProvider.themeMode == ThemeMode.system,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
      BuildContext context, {
        required String title,
        required IconData icon,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(
      BuildContext context,
      LocaleProvider localeProvider,
      ) {
    return _AnimatedCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: Theme.of(context).primaryColor,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context).translate('language'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLanguageOption(
                  context,
                  title: AppLocalizations.of(context).translate('english'),
                  locale: const Locale('en', ''),
                  isSelected: localeProvider.locale.languageCode == 'en',
                  onTap: () => localeProvider.setLocale(const Locale('en', '')),
                ),
                _buildLanguageOption(
                  context,
                  title: AppLocalizations.of(context).translate('french'),
                  locale: const Locale('fr', ''),
                  isSelected: localeProvider.locale.languageCode == 'fr',
                  onTap: () => localeProvider.setLocale(const Locale('fr', '')),
                ),
                _buildLanguageOption(
                  context,
                  title: AppLocalizations.of(context).translate('arabic'),
                  locale: const Locale('ar', ''),
                  isSelected: localeProvider.locale.languageCode == 'ar',
                  onTap: () => localeProvider.setLocale(const Locale('ar', '')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
      BuildContext context, {
        required String title,
        required Locale locale,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {
        required String title,
        required List<Widget> items,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildListItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    return _AnimatedCard(
      onTap: onTap,
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 26,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        )
            : null,
        trailing: trailing,
      ),
    );
  }
}

class _AnimatedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _AnimatedCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 32);
  }
}