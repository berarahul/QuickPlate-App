import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/app_exports.dart';
import '../../../core/network/cloudinary_service.dart';
import '../provider/auth_provider.dart';
import '../model/student_registration_request.dart';
import 'package:provider/provider.dart';

class StudentRegistration extends StatefulWidget {
  const StudentRegistration({super.key});

  @override
  State<StudentRegistration> createState() => _StudentRegistrationState();
}

class _StudentRegistrationState extends State<StudentRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  File? _idCardImage;
  bool _isUploadingImage = false;
  bool _obscure = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _idCardImage = File(pickedFile.path);
      });
    }
  }

  void _submit(BuildContext context) async {
    if (_idCardImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Please select an ID Card Image from your device.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploadingImage = true;
      });

      // Upload image to Cloudinary securely
      final uploadedImageUrl = await CloudinaryService.uploadImage(
        _idCardImage!,
      );

      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      if (uploadedImageUrl == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to upload image. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final request = StudentRegistrationRequest(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        idCardImage: uploadedImageUrl,
        role: 'student',
      );

      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.registerStudent(request);

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.registrationResponse?.message ?? 'Registered!',
            ),
          ),
        );
        // Navigate to some success view or login
        Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Registration failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Create account', style: AppTextStyles.displayLarge),
                const SizedBox(height: 8),
                Text(
                  'Register with your college email and verify your ID card.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Alex Student',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'you@college.edu',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: '••••••••',
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your password' : null,
                ),
                const SizedBox(height: 24),

                // Image Picker
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ID Card Image', style: AppTextStyles.labelSmall),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: _idCardImage == null
                          ? AppColors.surfaceAlt
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _idCardImage == null
                            ? AppColors.border
                            : AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    child: _idCardImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              _idCardImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTint,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 24,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Tap to upload ID Card',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PNG or JPG up to 5MB',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.isLoading || _isUploadingImage) {
                      return CustomElevatedButton(
                        text: _isUploadingImage
                            ? 'Uploading ID Card...'
                            : 'Registering...',
                        loading: true,
                        onPressed: null,
                      );
                    }
                    return CustomElevatedButton(
                      text: 'Create Account',
                      leading: const Icon(Icons.arrow_forward_rounded,
                          size: 20, color: AppColors.white),
                      onPressed: () => _submit(context),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: AppTextStyles.bodyMedium),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.loginScreen,
                        );
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
