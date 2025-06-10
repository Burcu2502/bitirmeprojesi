import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/auth_service.dart';
import '../../../home/presentation/screens/home_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() != true) return;
    
    // Şifrelerin uyumunu kontrol et
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'auth.passwordMismatch'.tr();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth kayıt hatası: ${e.code} - ${e.message}');
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'auth.emailAlreadyInUse'.tr();
            break;
          case 'invalid-email':
            _errorMessage = 'auth.invalidEmail'.tr();
            break;
          case 'weak-password':
            _errorMessage = 'auth.weakPassword'.tr();
            break;
          case 'operation-not-allowed':
            _errorMessage = 'auth.operationNotAllowed'.tr();
            break;
          case 'too-many-requests':
            _errorMessage = 'auth.tooManyRequests'.tr();
            break;
          case 'network-request-failed':
            _errorMessage = 'auth.checkConnection'.tr();
            break;
          default:
            debugPrint('❌ Bilinmeyen Firebase Auth kayıt hatası: ${e.code}');
            _errorMessage = 'auth.registerError'.tr();
        }
      });
    } catch (e) {
      debugPrint("❌ Kayıt hatası: $e");
      
      if (mounted) {
        final errorString = e.toString();
        
        // Pigeon hatalarını özel olarak ele al
        if (errorString.contains('PigeonUserDetails') || 
            errorString.contains('type \'List<Object?>\' is not a subtype') ||
            errorString.contains('pigeon')) {
          
          debugPrint('ℹ️ Kayıt sırasında Pigeon hatası yakalandı, Firebase Auth durumu kontrol ediliyor');
          
          // Firebase Auth durumunu kontrol et
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            debugPrint("✅ Pigeon hatası olmasına rağmen kullanıcı kayıt olmuş: ${user.uid}");
            
            // Başarılı mesaj göster
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('auth.registerSuccess'.tr()),
                backgroundColor: Colors.green,
              ),
            );
            
            // Ana sayfaya yönlendir
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            return;
          }
        }
        
        // Diğer hatalar için genel mesaj
        setState(() {
          _errorMessage = 'auth.registerError'.tr();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('auth.register'.tr()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo ve Başlık
                      const Icon(
                        Icons.wb_sunny_outlined,
                        size: 64,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'appTitle'.tr(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'auth.createAccount'.tr(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 32),

                      // Hata Mesajı
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Kayıt Formu
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Ad Soyad alanı
                            TextFormField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'auth.fullName'.tr(),
                                hintText: 'auth.enterFullName'.tr(),
                                prefixIcon: const Icon(Icons.person_outline),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'auth.pleaseEnterFullName'.tr();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // E-posta alanı
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'auth.email'.tr(),
                                hintText: 'auth.enterEmail'.tr(),
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'auth.pleaseEnterEmail'.tr();
                                }
                                
                                // Basit email formatı - gerisi Firebase'e kalsın
                                final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'auth.enterValidEmail'.tr();
                                }
                                
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Şifre alanı
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'auth.password'.tr(),
                                hintText: 'auth.enterPassword'.tr(),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'auth.pleaseEnterPassword'.tr();
                                }
                                if (value.length < 6) {
                                  return 'auth.passwordMinLength'.tr();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Şifre tekrar alanı
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'auth.confirmPassword'.tr(),
                                hintText: 'auth.enterPasswordAgain'.tr(),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'auth.pleaseEnterPasswordAgain'.tr();
                                }
                                if (value != _passwordController.text) {
                                  return 'auth.passwordMismatch'.tr();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Kayıt Ol Butonu
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _register,
                                child: Text(
                                  'auth.register'.tr(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Geri Dön Butonu
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('auth.backToLogin'.tr()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
} 