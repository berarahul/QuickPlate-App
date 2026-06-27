import '../../../core/app_exports.dart';
import '../model/login_request.dart';
import '../provider/auth_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../notifications/provider/notification_provider.dart';

class StudentLogin extends StatefulWidget {
  const StudentLogin({super.key});

  @override
  State<StudentLogin> createState() => _StudentLoginState();
}

class _StudentLoginState extends State<StudentLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.login(request);

      if (!context.mounted) return;

      if (success) {
        // Synchronize notification token with backend
        NotificationService.instance.syncToken();
        // Pre-fetch notifications history and unread badge count
        context.read<NotificationProvider>().fetchNotifications(
          isRefresh: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.loginResponse?.message ?? 'Login Successful!',
            ),
          ),
        );
        // Navigate to Dashboard screen upon successful login
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardScreen);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
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
                // Brand mark
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 32,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Welcome back', style: AppTextStyles.displayLarge),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue ordering from your campus canteen.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 32),
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
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your password' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.isLoading) {
                      return const CustomElevatedButton(
                        text: '',
                        loading: true,
                        onPressed: null,
                      );
                    }
                    return CustomElevatedButton(
                      text: 'Sign In',
                      leading: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: AppColors.white,
                      ),
                      onPressed: () => _submit(context),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.studentRegistrationScreen,
                        );
                      },
                      child: const Text('Register'),
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
