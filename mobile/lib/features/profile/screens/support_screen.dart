import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/animation.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/l10n/app_localizations.dart';


class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final messageController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button with Animation
                Hero(
                  tag: 'back_button',
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.black12 : Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black87, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title with Animation
                Hero(
                  tag: 'support_title',
                  child: AnimatedDefaultTextStyle(
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Theme.of(context).primaryColor,
                      letterSpacing: 1.2,
                    ),
                    duration: const Duration(milliseconds: 500),
                    child: Text(AppLocalizations.of(context).translate('help_support')),
                  ),
                ),
                const SizedBox(height: 20),
                // Centered Help Image
                Center(
                  child: Hero(
                    tag: 'help_image',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16)
                      ),
                      child: Image.asset(
                        'assets/images/help.png',
                        width: 250,
                        height: 250,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Form Card with Modern Design
                Card(
                  elevation: 0,
                  color: isDarkMode ? Colors.grey[900] : Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('contact support'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white70 : Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            initialValue: authProvider.user?.email ?? '',
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).translate('email'),
                              prefixIcon: Icon(Icons.email_outlined, color: isDarkMode ? Colors.white70 : Theme.of(context).primaryColor),
                              filled: true,
                              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDarkMode ? Colors.white : Theme.of(context).primaryColor, width: 2),
                              ),
                              labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                            ),
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: messageController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).translate('message'),
                              prefixIcon: Icon(Icons.message_outlined, color: isDarkMode ? Colors.white70 : Theme.of(context).primaryColor),
                              filled: true,
                              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDarkMode ? Colors.white : Theme.of(context).primaryColor, width: 2),
                              ),
                              labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                            ),
                            maxLines: 5,
                            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context).translate('message_required');
                              }
                              if (value.length < 10) {
                                return AppLocalizations.of(context).translate('message_too_short');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: StatefulBuilder(
                              builder: (context, setState) => AnimatedOpacity(
                                opacity: isLoading ? 0.5 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                    if (formKey.currentState!.validate()) {
                                      setState(() => isLoading = true);
                                      try {
                                        await FirestoreService().submitSupportRequest(
                                          email: authProvider.user!.email!,
                                          message: messageController.text,
                                        );
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context).translate('support_request_submitted')),
                                            backgroundColor: Theme.of(context).primaryColor,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context).translate('error_submitting_support_request')),
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                        );
                                      } finally {
                                        setState(() => isLoading = false);
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    backgroundColor: isDarkMode ? Colors.grey[700] : Theme.of(context).primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 4,
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
                                    AppLocalizations.of(context).translate('submit'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }
}