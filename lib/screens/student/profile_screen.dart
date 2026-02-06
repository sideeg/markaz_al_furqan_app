import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:markaz_al_furqan/constants/qiraat_types.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/section_header.dart';
import '../../widgets/profile_field.dart';
import '../../widgets/custom_dropdown_field.dart';
import '../../widgets/change_password_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  /// Selected qiraat stored as the string shown in the dropdown items.
  String? _selectedQiraat;

  bool _isEditing = false;
  bool _isLoading = false;

  /// Convert enum values to strings once for use in the dropdown.
  late final List<String> _qiraatItems;

  @override
  void initState() {
    super.initState();

    // Convert enum to simple strings like "hafs" or "warsh" depending on your enum names
    _qiraatItems =
        QiraatTypes.values.map((e) => e.toString().split('.').last).toList();

    final user = ref.read(authServiceProvider).user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    // Ensure the stored qiraat matches the representation used in items
    // If your backend stores the enum name (e.g. "hafs") set it directly; otherwise adapt:
    _selectedQiraat = user?.qiraat;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
            )
          else
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check_outlined),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            user?.initials ?? 'م',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.name ?? 'الطالب',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          user?.email ?? 'example@email.com',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Personal info
                  SectionHeader(title: 'المعلومات الشخصية'),
                  const SizedBox(height: 16),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        ProfileField(
                          controller: _nameController,
                          label: 'الاسم الكامل',
                          icon: Icons.person_outline,
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال الاسم';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        ProfileField(
                          controller: _emailController,
                          label: 'البريد الإلكتروني',
                          icon: Icons.email_outlined,
                          enabled: false,
                        ),

                        const SizedBox(height: 16),

                        ProfileField(
                          controller: _phoneController,
                          label: 'رقم الجوال',
                          icon: Icons.phone_outlined,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Qiraat: editable dropdown when editing, otherwise read-only display
                        _isEditing
                            ? CustomDropdownField(
                                label: 'نوع القراءة',
                                hint: 'اختر القراءة',
                                value: _selectedQiraat,
                                items: _qiraatItems,
                                prefixIcon: Icons.record_voice_over_outlined,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedQiraat = value;
                                  });
                                },
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'نوع القراءة',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.info),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.record_voice_over_outlined,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _selectedQiraat ?? 'غير محدد',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Account actions
                  SectionHeader(title: 'إعدادات الحساب'),
                  const SizedBox(height: 16),

                  _buildAccountOption(
                    icon: Icons.lock_outlined,
                    title: 'تغيير كلمة المرور',
                    onTap: () => _showChangePasswordDialog(),
                  ),

                  _buildAccountOption(
                    icon: Icons.logout_outlined,
                    title: 'تسجيل الخروج',
                    color: AppColors.error,
                    onTap: () => _logout(context, ref),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountOption({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.onSurface),
        title: Text(
          title,
          style: TextStyle(color: color ?? AppColors.onSurface),
        ),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(authServiceProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          qiraat: _selectedQiraat,
        );

    setState(() {
      _isLoading = false;
      if (success) {
        _isEditing = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(ref.read(authServiceProvider).error ?? 'فشل في التحديث'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (context.mounted) GoRouter.of(context).go('/');
              if (context.mounted) {
                final authService = ref.read(authServiceProvider.notifier);
                authService.logout();
                context.go('/login');
              }
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ChangePasswordDialog(),
    );
  }
}
