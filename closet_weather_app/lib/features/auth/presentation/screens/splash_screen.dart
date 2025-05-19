import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isLoading = true;
  bool _isAnimationComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimationComplete = true;
        });
        _checkAuthAndNavigate();
      }
    });

    // 3 saniye sonra bir sonraki ekrana geçiş yapacak
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }
  
  void _checkAuthAndNavigate() {
    if (!_isAnimationComplete || !_isLoading) return;
    
    setState(() {
      _isLoading = false;
    });
    
    // Önce Firebase'ten doğrudan kontrol et (bu daha güvenilir)
    final firebaseUser = FirebaseAuth.instance.currentUser;
    debugPrint("🔄 SplashScreen: Firebase kullanıcı kontrolü: ${firebaseUser != null ? 'Oturum açık' : 'Oturum kapalı'}");
    
    // Provider'daki durumu da kontrol et
    final authState = ref.read(authProvider);
    debugPrint("🔄 SplashScreen: AuthProvider kullanıcı kontrolü: ${authState.isAuthenticated ? 'Oturum açık' : 'Oturum kapalı'}");
    
    // Eğer Firebase'ten doğrudan kontrol edildiğinde kullanıcı varsa ama provider'da yoksa, provider'ı güncelle
    if (firebaseUser != null && !authState.isAuthenticated) {
      debugPrint("⚠️ SplashScreen: Firebase'de kullanıcı var ama Provider'da yok, durumu düzeltiyoruz");
      // Provider'ı güncelleme burada manuel olarak yapılmıyor, çünkü AuthService içindeki listener bunu otomatik yapacak
    }
    
    // Yönlendirme kararı
    if (firebaseUser != null || authState.isAuthenticated) {
      debugPrint("✅ SplashScreen: Kullanıcı oturumu açık, Ana Sayfaya yönlendiriliyor");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      debugPrint("ℹ️ SplashScreen: Kullanıcı oturumu kapalı, Giriş Sayfasına yönlendiriliyor");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ve İsim
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        // Logo ikonu
                        Container(
                          width: size.width * 0.4,
                          height: size.width * 0.4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.cloud_outlined,
                              size: size.width * 0.25,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Uygulama adı
                        Text(
                          'Dolap & Hava Durumu',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                blurRadius: 5.0,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Slogan
                        Text(
                          'Hava durumuna uygun kombin önerileri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Yükleniyor indikatörü
                if (_isLoading)
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
                      ),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
} 