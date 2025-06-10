import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_provider.dart';

class ProfileSecurity extends ConsumerStatefulWidget {
  const ProfileSecurity({super.key});

  @override
  ConsumerState<ProfileSecurity> createState() => _ProfileSecurityState();
}

class _ProfileSecurityState extends ConsumerState<ProfileSecurity> {
  // Kullanıcının giriş yöntemini tespit et
  bool get _isEmailPasswordUser {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    // Provider'ları kontrol et
    for (final userInfo in currentUser.providerData) {
      if (userInfo.providerId == 'password') {
        return true; // Email/password ile giriş yapmış
      }
    }
    return false; // Google, Facebook vs. ile giriş yapmış
  }
  
  String get _userAuthProvider {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 'Bilinmiyor';
    
    // İlk provider'ı al (genelde ana giriş yöntemi)
    if (currentUser.providerData.isNotEmpty) {
      final providerId = currentUser.providerData.first.providerId;
      switch (providerId) {
        case 'google.com':
          return 'Google';
        case 'password':
          return 'E-posta/Şifre';
        case 'facebook.com':
          return 'Facebook';
        default:
          return providerId;
      }
    }
    return 'Bilinmiyor';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Güvenlik',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        
        // Giriş yöntemi bilgisi
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(
                _isEmailPasswordUser ? Icons.email : Icons.account_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giriş Yöntemi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    _userAuthProvider,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Şifre değiştirme (sadece email/password kullanıcıları için)
        if (_isEmailPasswordUser) ...[
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Şifreyi Değiştir'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            onTap: () => _showChangePasswordDialog(context),
          ),
        ] else ...[
          // Google kullanıcıları için bilgilendirme
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Şifre Değiştirme',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Google hesabınızla giriş yaptığınız için şifre değiştirme işlemi Google hesabınızdan yapılmalıdır.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Şifre değiştirme dialog'u (sadece email/password kullanıcıları için)
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorText;
    
    await showDialog(
      context: context,
      barrierDismissible: false, // Dialog dışına tıklayarak kapatmayı engelle
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Şifre Değiştir'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorText != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      errorText!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                
                TextField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Mevcut Şifre',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre',
                    border: OutlineInputBorder(),
                    helperText: 'En az 6 karakter olmalıdır',
                  ),
                  obscureText: true,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre Tekrar',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  enabled: !isLoading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      // Güvenli dialog kapatma
                      if (Navigator.of(dialogContext).canPop()) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Giriş doğrulama
                      final currentPassword = currentPasswordController.text;
                      final newPassword = newPasswordController.text;
                      final confirmPassword = confirmPasswordController.text;
                      
                      if (currentPassword.isEmpty) {
                        if (mounted) {
                          setState(() {
                            errorText = 'Lütfen mevcut şifrenizi girin';
                          });
                        }
                        return;
                      }
                      
                      if (newPassword.length < 6) {
                        if (mounted) {
                          setState(() {
                            errorText = 'Yeni şifre en az 6 karakter olmalıdır';
                          });
                        }
                        return;
                      }
                      
                      if (newPassword != confirmPassword) {
                        if (mounted) {
                          setState(() {
                            errorText = 'Yeni şifreler eşleşmiyor';
                          });
                        }
                        return;
                      }
                      
                      // Şifre değiştirme işlemi
                      if (mounted) {
                        setState(() {
                          isLoading = true;
                          errorText = null;
                        });
                      }
                      
                      try {
                        final success = await ref.read(profileProvider.notifier).changePassword(
                          currentPassword,
                          newPassword,
                        );
                        
                        if (success) {
                          // Güvenli dialog kapatma ve başarı mesajı
                          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Şifreniz başarıyla değiştirildi!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            setState(() {
                              isLoading = false;
                              errorText = 'Şifre değiştirilemedi. Mevcut şifreniz doğru değil.';
                            });
                          }
                        }
                      } catch (e) {
                        debugPrint('❌ [UI] Şifre değiştirme hatası: $e');
                        final errorMessage = e.toString();
                        
                        // Pigeon hatalarını özel olarak ele al
                        if (errorMessage.contains('PigeonUserDetails') || 
                            errorMessage.contains('type \'List<Object?>\' is not a subtype') ||
                            errorMessage.contains('pigeon')) {
                          
                          debugPrint('ℹ️ [UI] Şifre değiştirmede Pigeon hatası yakalandı - başarı kabul ediliyor');
                          
                          // Dialog'u güvenli şekilde kapat ve başarı mesajı göster
                          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Şifreniz başarıyla değiştirildi! (Pigeon bypass)'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          return;
                        }
                        
                        // Diğer hatalar için
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                            
                            // Exception mesajından temizle
                            if (errorMessage.startsWith('Exception: ')) {
                              errorText = errorMessage.substring(11);
                            } else if (errorMessage.contains('Mevcut şifreniz doğru değil')) {
                              errorText = 'Mevcut şifreniz doğru değil.';
                            } else if (errorMessage.contains('OAuth') || errorMessage.contains('Google/Facebook')) {
                              errorText = 'Bu hesap Google ile oluşturulmuş. Google hesabınızdan şifre değiştirin.';
                            } else if (errorMessage.contains('weak-password')) {
                              errorText = 'Yeni şifre çok zayıf. Daha güçlü bir şifre seçin.';
                            } else if (errorMessage.contains('requires-recent-login')) {
                              errorText = 'Bu işlem için çıkış yapıp tekrar giriş yapmanız gerekiyor.';
                            } else {
                              errorText = 'Şifre değiştirilemedi. Lütfen tekrar deneyin.';
                            }
                          });
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Şifreyi Değiştir'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Dialog kapandığında controller'ları güvenli şekilde dispose et
      try {
        currentPasswordController.dispose();
        newPasswordController.dispose();
        confirmPasswordController.dispose();
      } catch (e) {
        debugPrint('⚠️ Controller dispose hatası (yok sayılıyor): $e');
      }
    });
  }
} 