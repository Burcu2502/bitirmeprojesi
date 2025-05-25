import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'login_screen.dart';
import 'package:firebase_core/firebase_core.dart';

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
        _initializeApp();
      }
    });

    // 3 saniye sonra bir sonraki ekrana geçiş yapacak
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _initializeApp();
      }
    });
  }
  
  Future<void> _initializeApp() async {
    try {
      // Minimum splash süresi (çok kısa)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Firebase hazır mı kontrol et
      await _waitForFirebase();
      
      if (mounted) {
        _checkAuthStatus();
      }
    } catch (e) {
      debugPrint("❌ Uygulama başlatma hatası: $e");
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  Future<void> _waitForFirebase() async {
    // Firebase'in hazır olmasını bekle (maksimum 3 saniye)
    int attempts = 0;
    while (Firebase.apps.isEmpty && attempts < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    if (Firebase.apps.isEmpty) {
      throw Exception("Firebase başlatılamadı");
    }
  }

  void _checkAuthStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint("🔄 SplashScreen: Firebase kullanıcı kontrolü: ${currentUser != null ? 'Oturum açık' : 'Oturum kapalı'}");
      
      if (currentUser != null) {
        // Kullanıcı oturum açmış, ana sayfaya git
        _navigateToHome();
      } else {
        // Oturum kapalı, login'e git
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint("❌ Auth kontrol hatası: $e");
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _navigateToLogin() {
    if (mounted) {
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