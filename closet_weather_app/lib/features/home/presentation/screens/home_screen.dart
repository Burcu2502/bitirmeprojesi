import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../weather/presentation/screens/weather_screen.dart';
import '../../../wardrobe/presentation/screens/wardrobe_screen.dart';
import '../widgets/outfit_suggestion_view.dart';
import '../widgets/user_profile_view.dart';
import '../../../../core/providers/firestore_providers.dart';
import '../../../wardrobe/presentation/providers/wardrobe_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoggingOut = false;
  
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      const WeatherScreen(),
      const WardrobeScreen(), 
      const OutfitSuggestionView(),
      const UserProfileView(),
    ];
  }
  
  Future<void> _signOut() async {
    if (_isLoggingOut) return;
    
    setState(() {
      _isLoggingOut = true;
    });
    
    try {
      await ref.read(authProvider.notifier).signOut();
      debugPrint('✅ Home screen: Çıkış başarılı');
    } catch (e) {
      debugPrint('❌ Home screen: Çıkış yaparken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.logoutError'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Auth durumunu kontrol et
    final authState = ref.watch(authProvider);
    
    // Kullanıcı giriş yapmamışsa login ekranına yönlendir
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('navigation.home'.tr()),
        actions: [
          if (_isLoggingOut)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'auth.logout'.tr(),
              onPressed: _signOut,
            ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // Kıyafet verilerini gösteren tab'lara geçildiğinde provider'ları yenile
          if (index == 1 || index == 2) { // Wardrobe veya Outfit Suggestion
            ref.invalidate(userClothingItemsProvider);
            ref.invalidate(clothingItemsProvider);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.cloud_outlined),
            activeIcon: const Icon(Icons.cloud),
            label: 'navigation.weatherForecast'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            activeIcon: const Icon(Icons.grid_view),
            label: 'navigation.myClosets'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            activeIcon: const Icon(Icons.add_circle),
            label: 'navigation.createOutfit'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'navigation.profile'.tr(),
          ),
        ],
      ),
    );
  }
} 