import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _hasShownSnackBar = false;
  
  void initialize(BuildContext context) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        // İnternet bağlantısı koptuğunda
        if (!_hasShownSnackBar && context.mounted) {
          _hasShownSnackBar = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İnternet bağlantınız yok. Bazı özellikler çalışmayabilir.'),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // İnternet bağlantısı geldiğinde
        _hasShownSnackBar = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İnternet bağlantınız tekrar sağlandı.'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  Future<bool> checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }
} 