import 'package:flutter_riverpod/flutter_riverpod.dart';

// Varsayılan konum provider
final currentLocationProvider = StateProvider<String>((ref) {
  return 'Istanbul'; // Varsayılan olarak İstanbul
});