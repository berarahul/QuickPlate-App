import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/app_exports.dart';
import '../../../../core/network/cloudinary_service.dart';
import '../../../auth/provider/auth_provider.dart';

class EditProfileSheet {
  static void show(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final nameController =
        TextEditingController(text: authProvider.userName ?? '');
    final phoneController =
        TextEditingController(text: authProvider.userPhone ?? '');
    File? selectedImageFile;
    bool isSubmitting = false;
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
                top: 20,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Edit Profile',
                      style: AppTextStyles.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Update your name, contact details & avatar',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Image picker avatar
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: selectedImageFile != null
                                  ? Image.file(
                                      selectedImageFile!,
                                      fit: BoxFit.cover,
                                      width: 84,
                                      height: 84,
                                    )
                                  : (authProvider.userIdCardImage != null &&
                                          authProvider
                                              .userIdCardImage!.isNotEmpty)
                                      ? Image.network(
                                          authProvider.userIdCardImage!,
                                          fit: BoxFit.cover,
                                          width: 84,
                                          height: 84,
                                          errorBuilder: (_, _, _) => Icon(
                                            Icons.person_rounded,
                                            size: 42,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : Icon(
                                          Icons.person_rounded,
                                          size: 42,
                                          color: AppColors.primary,
                                        ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () async {
                                final picker = ImagePicker();
                                final XFile? picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 80,
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedImageFile = File(picked.path);
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surface,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (localError != null) ...[
                      Text(
                        localError!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    CustomElevatedButton(
                      text: isSubmitting ? 'Saving...' : 'Save Changes',
                      loading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final newName = nameController.text.trim();
                              final newPhone = phoneController.text.trim();

                              if (newName.isEmpty) {
                                setState(() {
                                  localError = 'Name cannot be empty';
                                });
                                return;
                              }

                              setState(() {
                                isSubmitting = true;
                                localError = null;
                              });

                              String? imageUrl = authProvider.userIdCardImage;
                              if (selectedImageFile != null) {
                                final uploadedUrl =
                                    await CloudinaryService.uploadImage(
                                        selectedImageFile!);
                                if (uploadedUrl != null) {
                                  imageUrl = uploadedUrl;
                                }
                              }

                              final success = await authProvider.updateProfile(
                                name: newName,
                                phoneNumber: newPhone,
                                idCardImage: imageUrl,
                              );

                              if (!modalContext.mounted) return;

                              if (success) {
                                Navigator.pop(modalContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Profile updated successfully!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                setState(() {
                                  isSubmitting = false;
                                  localError = authProvider.errorMessage ??
                                      'Update failed';
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
