import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../shared/l10n/app_localizations.dart';
import '../../../shared/widgets/animated_slide_transition.dart';
import '../../navigation/screens/main_navigation.dart';
import '../widgets/auth_form_field.dart';
import '../../profile/screens/completeProfile.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isVerificationStep = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpControllers.forEach((controller) => controller.dispose());
    _otpFocusNodes.forEach((node) => node.dispose());
    _animationController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  Future<void> _checkEmailAndSendCode() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.generateAndSendVerificationCode(_emailController.text.trim());

      if (authProvider.status == AuthStatus.verifying) {
        setState(() {
          _isVerificationStep = true;
        });
      } else if (authProvider.status == AuthStatus.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.errorMessage)),
          );
        }
      }
    }
  }

  Future<void> _verifyCodeAndSignUp() async {
    final code = _otpControllers.map((controller) => controller.text).join();
    if (_formKey.currentState!.validate() && code.length == 6) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isValidCode = await authProvider.verifyCode(code);

      if (isValidCode) {
        await authProvider.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (authProvider.status == AuthStatus.unauthenticated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Signup successful! Please login')),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        } else if (authProvider.status == AuthStatus.error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authProvider.errorMessage)),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid verification code')),
          );
        }
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();

      if (authProvider.status == AuthStatus.authenticated) {
        await authProvider.refreshUserData();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => authProvider.isProfileComplete
                  ? const MainNavigation(initialIndex: 0)
                  : const CompleteProfileScreen(),
            ),
          );
        }
      } else if (authProvider.status == AuthStatus.error && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
            maxLength: 1,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              if (value.length == 1 && index < 5) {
                _otpFocusNodes[index].unfocus();
                FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
              }
              if (value.isEmpty && index > 0) {
                _otpFocusNodes[index].unfocus();
                FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '';
              }
              if (!RegExp(r'^\d$').hasMatch(value)) {
                return '';
              }
              return null;
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          onPressed: () {
            if (_isVerificationStep) {
              setState(() {
                _isVerificationStep = false;
                _otpControllers.forEach((controller) => controller.clear());
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: Icon(
              Icons.language,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(localizations.translate('language')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('English'),
                        trailing: localeProvider.locale.languageCode == 'en'
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          localeProvider.setLocale(const Locale('en', ''));
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Français'),
                        trailing: localeProvider.locale.languageCode == 'fr'
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          localeProvider.setLocale(const Locale('fr', ''));
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('العربية'),
                        trailing: localeProvider.locale.languageCode == 'ar'
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          localeProvider.setLocale(const Locale('ar', ''));
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 200,
                        height: 150,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _isVerificationStep
                          ? localizations.translate('verify email')
                          : localizations.translate('signup'),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isVerificationStep
                          ? localizations.translate('Enter the code sent to your email')
                          : localizations.translate('Create a new account'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (!_isVerificationStep) ...[
                      AnimatedSlideTransition(
                        delay: 100,
                        child: AuthFormField(
                          controller: _emailController,
                          hintText: localizations.translate('email'),
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.translate('email_required');
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return localizations.translate('invalid_email');
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSlideTransition(
                        delay: 200,
                        child: AuthFormField(
                          controller: _passwordController,
                          hintText: localizations.translate('password'),
                          prefixIcon: Icons.lock_outline,
                          obscureText: !_isPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.translate('password_required');
                            }
                            if (value.length < 6) {
                              return localizations.translate('password_length');
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSlideTransition(
                        delay: 300,
                        child: AuthFormField(
                          controller: _confirmPasswordController,
                          hintText: localizations.translate('confirm_password'),
                          prefixIcon: Icons.lock_outline,
                          obscureText: !_isConfirmPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: _toggleConfirmPasswordVisibility,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.translate('password_required');
                            }
                            if (value != _passwordController.text) {
                              return localizations.translate('passwords_dont_match');
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedSlideTransition(
                        delay: 400,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _checkEmailAndSendCode,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: Text(
                              localizations.translate('continue'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      AnimatedSlideTransition(
                        delay: 100,
                        child: _buildOtpInput(),
                      ),
                      const SizedBox(height: 24),
                      AnimatedSlideTransition(
                        delay: 200,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _verifyCodeAndSignUp,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: Text(
                              localizations.translate('verify'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSlideTransition(
                        delay: 300,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            await authProvider.generateAndSendVerificationCode(_emailController.text.trim());
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Verification code resent')),
                              );
                            }
                          },
                          child: Text(
                            localizations.translate('resend_code'),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    AnimatedSlideTransition(
                      delay: 500,
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              localizations.translate('or_continue_with'),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSlideTransition(
                      delay: 600,
                      child: OutlinedButton(
                        onPressed: _signUpWithGoogle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              localizations.translate('sign_in_with_google'),
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSlideTransition(
                      delay: 700,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            localizations.translate('already_have_account'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              localizations.translate('login'),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
        ),
      ),
    );
  }
}