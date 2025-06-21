import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/animated_slide_transition.dart';
import '../../navigation/screens/main_navigation.dart';
import '../../auth/widgets/auth_form_field.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final imageUploadService = Provider.of<ImageUploadService>(context, listen: false);

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await imageUploadService.uploadImage(_imageFile!);
      }

      await firestoreService.updateUserData(authProvider.user!.uid, {
        'username': _usernameController.text.trim(),
        'age': int.parse(_ageController.text), // Use parse since validated as integer
        'phoneNumber': _phoneController.text.trim(), // Use trim to remove whitespace
        'imageUrl': imageUrl,
      });

      authProvider.updateUserProfile(
        username: _usernameController.text.trim(),
        age: int.parse(_ageController.text),
        imageUrl: imageUrl,
        phoneNumber: _phoneController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainNavigation(initialIndex: 0),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : null,
                      child: _imageFile == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedSlideTransition(
                  delay: 100,
                  child: AuthFormField(
                    controller: _usernameController,
                    hintText: 'username',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSlideTransition(
                  delay: 200,
                  child: AuthFormField(
                    controller: _ageController,
                    hintText: 'age',
                    prefixIcon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your age';
                      }
                      final age = int.tryParse(value);
                      if (age == null) {
                        return 'Age must be a valid integer';
                      }
                      if (age < 13 || age > 120) {
                        return 'Please enter a valid age (13-120)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSlideTransition(
                  delay: 300,
                  child: AuthFormField(
                    controller: _phoneController,
                    hintText: 'phoneNumber',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      final phone = int.tryParse(value);
                      if (phone == null) {
                        return 'Phone number must be a valid integer';
                      }
                      if (value.startsWith('0')) {
                        return 'Phone number cannot start with 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedSlideTransition(
                  delay: 400,
                  child: AnimatedButton(
                    onPressed: _isLoading ? null : _submitProfile,
                    isLoading: _isLoading,
                    text: 'Complete Profile',
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