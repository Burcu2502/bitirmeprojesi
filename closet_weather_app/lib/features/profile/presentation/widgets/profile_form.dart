import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key});

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isFormChanged = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFormValues();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initFormValues() {
    final profile = ref.read(profileProvider).profile;
    if (profile != null) {
      _nameController.text = profile.name;
      _phoneController.text = profile.phoneNumber ?? '';
    }
  }

  void _onFormChanged() {
    final profile = ref.read(profileProvider).profile;
    if (profile == null) return;

    final nameChanged = _nameController.text != profile.name;
    final phoneChanged = _phoneController.text != (profile.phoneNumber ?? '');

    setState(() {
      _isFormChanged = nameChanged || phoneChanged;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final result = await ref.read(profileProvider.notifier).updateProfile(
      name: name,
      phoneNumber: phone.isNotEmpty ? phone : null,
    );

    if (result && mounted) {
      setState(() {
        _isFormChanged = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil başarıyla güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil güncellenirken bir hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final isLoading = profileState.status == ProfileStatus.loading;

    if (profile == null) {
      return const Center(
        child: Text('Profil bilgileri yüklenemedi'),
      );
    }

    return Form(
      key: _formKey,
      onChanged: _onFormChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temel Bilgiler',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Ad Soyad',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Lütfen adınızı girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon Numarası',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
              hintText: 'Örn: +90 500 000 00 00',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          // Email (değiştirilemez)
          TextField(
            enabled: false,
            controller: TextEditingController(text: profile.email),
            decoration: const InputDecoration(
              labelText: 'E-posta',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isFormChanged && !isLoading ? _saveProfile : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
} 