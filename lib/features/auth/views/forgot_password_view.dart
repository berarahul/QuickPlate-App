import '../../../core/app_exports.dart';
import '../provider/auth_provider.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _otpSent = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _requestOtp(BuildContext context) async {
    if (_step1FormKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.forgotPassword(email);

      if (!context.mounted) return;

      if (success) {
        setState(() {
          _otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.successMessage ??
                  'Password reset OTP sent to your email!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to send OTP'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _resetPassword(BuildContext context) async {
    if (_step2FormKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final otp = _otpController.text.trim();
      final newPassword = _newPasswordController.text.trim();

      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset successfully! Please sign in.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Password reset failed'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: _otpSent
              ? _buildStep2Widget(context)
              : _buildStep1Widget(context),
        ),
      ),
    );
  }

  Widget _buildStep1Widget(BuildContext context) {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 32,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text('Reset Password', style: AppTextStyles.displayLarge),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email address to receive a 6-digit verification code.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'you@college.edu',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value!.isEmpty ? 'Enter your email' : null,
          ),
          const SizedBox(height: 24),
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
                text: 'Send Reset OTP',
                leading: const Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: AppColors.white,
                ),
                onPressed: () => _requestOtp(context),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Widget(BuildContext context) {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.verified_user_rounded,
              size: 32,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text('Enter OTP & New Password', style: AppTextStyles.displayLarge),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code sent to ${_emailController.text} and your new password.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _otpController,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: '6-Digit OTP',
              hintText: '123456',
              prefixIcon: Icon(Icons.shield_outlined, size: 20),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (value) {
              if (value == null || value.trim().length != 6) {
                return 'Enter valid 6-digit OTP';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
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
                text: 'Update Password',
                leading: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                  color: AppColors.white,
                ),
                onPressed: () => _resetPassword(context),
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _otpSent = false),
            child: const Text('Change email or resend OTP'),
          ),
        ],
      ),
    );
  }
}
