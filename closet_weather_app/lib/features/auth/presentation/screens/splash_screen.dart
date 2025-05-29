import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/env.dart';

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
  String? _errorMessage;
  bool _isRetrying = false;

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
  }
  
  Future<void> _initializeApp() async {
    if (_isRetrying) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isRetrying = true;
    });

    try {
      // İnternet bağlantısını kontrol et
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception("İnternet bağlantısı bulunamadı");
      }

      // API'lerin çalışıp çalışmadığını kontrol et
      await _checkApiStatus();
      
      // Firebase hazır mı kontrol et
      await _waitForFirebase();
      
      if (mounted) {
        _checkAuthStatus();
      }
    } catch (e) {
      debugPrint("❌ Uygulama başlatma hatası: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e);
          _isRetrying = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      if (error.toString().contains("İnternet bağlantısı bulunamadı")) {
        return "İnternet bağlantınızı kontrol edip tekrar deneyin";
      } else if (error.toString().contains("API")) {
        return "Sunucu bağlantısı kurulamadı. Lütfen daha sonra tekrar deneyin";
      } else if (error.toString().contains("Firebase")) {
        return "Uygulama servisleri başlatılamadı. Lütfen tekrar deneyin";
      }
    }
    return "Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin";
  }

  Future<void> _checkApiStatus() async {
    try {
      // API sağlık kontrolü
      final response = await http.get(
        Uri.parse(Environment.healthCheckEndpoint),
      ).timeout(
        Environment.connectionTimeout,
        onTimeout: () => throw Exception("API yanıt vermiyor"),
      );
      
      if (response.statusCode != 200) {
        throw Exception("API bağlantı hatası: HTTP ${response.statusCode}");
      }
      
    } catch (e) {
      throw Exception("API bağlantı hatası: $e");
    }
  }

  Future<void> _waitForFirebase() async {
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
        _navigateToHome();
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint("❌ Auth kontrol hatası: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Oturum kontrolü yapılamadı. Lütfen tekrar deneyin";
        _isRetrying = false;
      });
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
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo/app_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Uygulama ismi
                        Text(
                          'BNG',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yapay Zeka Destekli\nGardırop Asistanı',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Hata mesajı veya yükleniyor
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isRetrying ? null : _initializeApp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(_isRetrying ? 'Tekrar Deneniyor...' : 'Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                else if (_isLoading)
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Uygulama Başlatılıyor...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
} 