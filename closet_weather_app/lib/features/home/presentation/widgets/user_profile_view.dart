import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/screens/style_preferences_screen.dart';

class UserProfileView extends ConsumerWidget {
  const UserProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userData = authState.userData;
    
    // Fotoğraf URL'sini güvenli bir şekilde kontrol et
    String? photoUrl;
    
    try {
      photoUrl = userData?.photoUrl;
    } catch (e) {
      debugPrint('❌ Fotoğraf URL alınırken hata: $e');
      photoUrl = null;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          
          // Profil fotoğrafı
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          
          // Kullanıcı adı
          Text(
            userData?.name ?? 'Kullanıcı',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          
          // Kullanıcı e-postası
          Text(
            userData?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 32),
          
          // Profil menüsü
          _buildProfileMenuItem(
            context,
            icon: Icons.account_circle_outlined,
            title: 'Profil Bilgilerim',
            onTap: () {
              // Profil düzenleme sayfasına git
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const ProfileScreen())
              );
            },
          ),
          _buildProfileMenuItem(
            context,
            icon: Icons.style_outlined,
            title: 'Stil Tercihlerim',
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const StylePreferencesScreen(),
                ),
              );
            },
          ),
          _buildProfileMenuItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Ayarlar',
            onTap: () {
              // Ayarlar sayfasına git
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bu özellik henüz hazır değil'),
                ),
              );
            },
          ),
          _buildProfileMenuItem(
            context,
            icon: Icons.help_outline,
            title: 'Yardım ve Destek',
            onTap: () {
              // Yardım sayfasına git
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bu özellik henüz hazır değil'),
                ),
              );
            },
          ),
          
          const Spacer(),
          
          // Çıkış yap butonu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              onPressed: () async {
                try {
                  await ref.read(authProvider.notifier).signOut();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Çıkış yapılırken hata oluştu: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
} 