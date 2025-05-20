import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_form.dart';
import '../widgets/profile_security.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    
    // Profil bilgilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: _buildBody(profileState),
    );
  }

  Widget _buildBody(ProfileState state) {
    switch (state.status) {
      case ProfileStatus.initial:
      case ProfileStatus.loading:
        if (state.profile == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        // Veri varsa yükleniyor göstergesini üstte göster, ama mevcut verileri de göster
        return _buildProfileContent(state, isRefreshing: true);
        
      case ProfileStatus.loaded:
        return _buildProfileContent(state);
        
      case ProfileStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'Profil bilgileri yüklenemedi',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(profileProvider.notifier).loadUserProfile();
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildProfileContent(ProfileState state, {bool isRefreshing = false}) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(profileProvider.notifier).loadUserProfile();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isRefreshing)
              const LinearProgressIndicator(),
            const SizedBox(height: 24),
            // Profil fotoğrafı
            const ProfileAvatar(
              size: 120,
            ),
            const SizedBox(height: 32),
            // Profil formu
            const ProfileForm(),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            // Güvenlik ayarları
            const ProfileSecurity(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
} 