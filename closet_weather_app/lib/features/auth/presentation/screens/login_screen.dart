import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/auth_service.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth hatası: ${e.code} - ${e.message}');
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'auth.userNotFound'.tr();
            break;
          case 'wrong-password':
            _errorMessage = 'auth.wrongCredentials'.tr();
            break;
          case 'invalid-email':
            _errorMessage = 'auth.invalidEmail'.tr();
            break;
          case 'user-disabled':
            _errorMessage = 'auth.userDisabled'.tr();
            break;
          case 'invalid-credential':
            _errorMessage = 'auth.wrongCredentials'.tr();
            break;
          case 'too-many-requests':
            _errorMessage = 'auth.tooManyRequests'.tr();
            break;
          case 'network-request-failed':
            _errorMessage = 'auth.checkConnection'.tr();
            break;
          default:
            debugPrint('❌ Bilinmeyen Firebase Auth hatası: ${e.code}');
            _errorMessage = 'auth.loginError'.tr();
        }
      });
    } catch (e) {
      debugPrint('❌ Genel login hatası: $e');
      
      if (mounted) {
        final errorString = e.toString();
        
        // Pigeon hatalarını özel olarak ele al
        if (errorString.contains('PigeonUserDetails') || 
            errorString.contains('type \'List<Object?>\' is not a subtype') ||
            errorString.contains('pigeon')) {
          
          debugPrint('ℹ️ Login sırasında Pigeon hatası yakalandı, Firebase Auth durumu kontrol ediliyor');
          
          // Firebase Auth durumunu kontrol et
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            debugPrint("✅ Pigeon hatası olmasına rağmen kullanıcı giriş yapmış: ${user.uid}");
            
            // Başarılı mesaj göster
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Giriş başarılı! (Pigeon bypass)'),
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
        
        setState(() {
          // Daha kullanıcı dostu genel hata mesajı
          _errorMessage = 'auth.loginError'.tr();
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();

      if (mounted) {
        // Başarılı giriş sonrası Firebase oturumunu kontrol et
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          debugPrint("✅ Google ile giriş başarılı, kullanıcı: ${user.uid}, ${user.email}");
          
          // Ana ekrana yönlendir
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          debugPrint("⚠️ Google giriş başarılı olmasına rağmen kullanıcı bulunamadı");
          throw Exception('Giriş doğrulanamadı');
        }
      }
    } catch (e) {
      debugPrint("❌ Google ile giriş hatası: $e");
      
      if (mounted) {
        final errorString = e.toString();
        
        // Pigeon hatalarını özel olarak ele al
        if (errorString.contains('PigeonUserDetails') || 
            errorString.contains('type \'List<Object?>\' is not a subtype') ||
            errorString.contains('pigeon')) {
          
          debugPrint('ℹ️ Pigeon hatası yakalandı, Firebase Auth durumu kontrol ediliyor');
          
          // Firebase Auth durumunu kontrol et
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            debugPrint("✅ Pigeon hatası olmasına rağmen kullanıcı giriş yapmış: ${user.uid}");
            
            // Başarılı mesaj göster
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('auth.googleLoginSuccess'.tr()),
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
        
        // İptal durumu kontrol et
        if (errorString.contains('iptal') || errorString.contains('cancel')) {
          debugPrint('ℹ️ Kullanıcı Google girişini iptal etti');
          setState(() {
            _errorMessage = null; // İptal durumunda hata mesajı gösterme
          });
          return;
        }
        
        // Diğer hatalar için genel mesaj
        setState(() {
          _errorMessage = 'auth.googleLoginError'.tr();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google ile giriş hatası: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
                        size: 80,
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
                        'auth.loginToAccount'.tr(),
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

                      // Giriş Formu
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
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
                            const SizedBox(height: 8),

                            // Şifremi Unuttum Linki
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text('auth.forgotPassword'.tr()),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Giriş Yap Butonu
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _signInWithEmailAndPassword,
                                child: Text(
                                  'auth.login'.tr(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // VEYA ayırıcı
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('auth.or'.tr()),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Google ile Giriş Yap
                      SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            backgroundColor: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('auth.loginWithGoogle'.tr()),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Kayıt Ol Linki
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'auth.noAccount'.tr(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                            children: [
                              TextSpan(
                                text: 'auth.register'.tr(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
} 