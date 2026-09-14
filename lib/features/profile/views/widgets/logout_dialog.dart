import '../../../../core/app_exports.dart';
import '../../../auth/provider/auth_provider.dart';

class LogoutDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
          'Are you sure you want to log out from QuickPlate?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (overlayContext) =>
                    const Center(child: CircularProgressIndicator()),
              );

              await context.read<AuthProvider>().logout();

              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.loginScreen,
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
