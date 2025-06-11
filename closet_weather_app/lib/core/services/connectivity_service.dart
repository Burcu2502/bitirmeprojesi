import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _hasShownSnackBar = false;
  bool _isConnected = true; // Başlangıçta bağlı varsayıyoruz
  DateTime? _lastMessageTime;
  bool _showMessages = false; // Varsayılan olarak mesajları kapatıyoruz
  
  void initialize(BuildContext context, {bool showMessages = false}) {
    _showMessages = showMessages;
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final isCurrentlyConnected = result != ConnectivityResult.none;
      final now = DateTime.now();
      
      // Eğer durum değişmediyse hiçbir şey yapma
      if (_isConnected == isCurrentlyConnected) {
        return;
      }
      
      // Mesajlar kapalıysa sadece internal state'i güncelle
      if (!_showMessages) {
        _isConnected = isCurrentlyConnected;
        return;
      }
      
      // Son mesajdan en az 3 saniye geçmiş olmalı (spam'i önlemek için)
      if (_lastMessageTime != null && now.difference(_lastMessageTime!).inSeconds < 3) {
        return;
      }
      
      _isConnected = isCurrentlyConnected;
      _lastMessageTime = now;
      
      if (!mounted(context)) return;
      
      if (!_isConnected) {
        // İnternet bağlantısı koptuğunda
        if (!_hasShownSnackBar) {
          _hasShownSnackBar = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('İnternet bağlantınız yok'),
                  ),
                ],
              ),
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // İnternet bağlantısı geldiğinde - ama sadece önceden kopmuşsa göster
        if (_hasShownSnackBar) {
          _hasShownSnackBar = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('İnternet bağlantınız yeniden sağlandı'),
                  ),
                ],
              ),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }
  
  // Context'in hala geçerli olup olmadığını kontrol et
  bool mounted(BuildContext context) {
    try {
      return context.mounted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final isConnected = connectivityResult != ConnectivityResult.none;
    _isConnected = isConnected;
    return isConnected;
  }
  
  bool get isConnected => _isConnected;

  void dispose() {
    _connectivitySubscription.cancel();
  }
} 