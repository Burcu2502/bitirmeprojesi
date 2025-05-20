import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

class ProfileSecurity extends ConsumerStatefulWidget {
  const ProfileSecurity({super.key});

  @override
  ConsumerState<ProfileSecurity> createState() => _ProfileSecurityState();
}

class _ProfileSecurityState extends ConsumerState<ProfileSecurity> {
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
        const SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.delete_forever, color: Colors.red.shade600),
          title: Text('Hesabı Sil', style: TextStyle(color: Colors.red.shade600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.red.shade200),
          ),
          tileColor: Colors.red.shade50,
          onTap: () => _showDeleteAccountDialog(context),
        ),
      ],
    );
  }

  // Şifre değiştirme dialog'u
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    bool isLoading = false;
    String? errorText;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Şifreyi Değiştir'),
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
                  textInputAction: TextInputAction.next,
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
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre (Tekrar)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
                        setState(() {
                          errorText = 'Lütfen mevcut şifrenizi girin';
                        });
                        return;
                      }
                      
                      if (newPassword.length < 6) {
                        setState(() {
                          errorText = 'Yeni şifre en az 6 karakter olmalıdır';
                        });
                        return;
                      }
                      
                      if (newPassword != confirmPassword) {
                        setState(() {
                          errorText = 'Yeni şifreler eşleşmiyor';
                        });
                        return;
                      }
                      
                      // Şifre değiştirme işlemi
                      setState(() {
                        isLoading = true;
                        errorText = null;
                      });
                      
                      try {
                        final success = await ref.read(profileProvider.notifier).changePassword(
                          currentPassword,
                          newPassword,
                        );
                        
                        if (success) {
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Şifreniz başarıyla değiştirildi'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          setState(() {
                            isLoading = false;
                            errorText = 'Şifre değiştirilemedi. Mevcut şifreniz doğru değil.';
                          });
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                          errorText = 'Hata: $e';
                        });
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
    );
    
    // Temizleme
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  // Hesap silme dialog'u
  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? errorText;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Hesabı Sil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'UYARI: Bu işlem geri alınamaz. Hesabınız ve tüm verileriniz kalıcı olarak silinecektir.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
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
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifrenizi Girin',
                    border: OutlineInputBorder(),
                    helperText: 'Hesabınızı silmek için şifrenizi girin',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (passwordController.text.isEmpty) {
                        setState(() {
                          errorText = 'Lütfen şifrenizi girin';
                        });
                        return;
                      }
                      
                      setState(() {
                        isLoading = true;
                        errorText = null;
                      });
                      
                      try {
                        final success = await ref.read(profileProvider.notifier).deleteAccount(
                          passwordController.text,
                        );
                        
                        if (success) {
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            // Ana ekrana yönlendir
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        } else {
                          setState(() {
                            isLoading = false;
                            errorText = 'Hesap silinemedi. Şifreniz doğru değil.';
                          });
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                          errorText = 'Hata: $e';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Hesabımı Sil',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
    
    // Temizleme
    passwordController.dispose();
  }
} 