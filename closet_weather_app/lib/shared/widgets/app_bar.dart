import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  
  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.background,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.black87
              : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions ?? _defaultActions(context, ref, user),
    );
  }
  
  List<Widget> _defaultActions(BuildContext context, WidgetRef ref, dynamic user) {
    return [
      if (user != null) ...[
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Bildirimler sayfasına yönlendir
          },
        ),
        GestureDetector(
          onTap: () {
            // TODO: Profil sayfasına yönlendir veya profil menüsünü aç
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: user.photoUrl != null
                  ? Image.network(user.photoUrl)
                  : Icon(
                      Icons.person,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
            ),
          ),
        ),
      ],
    ];
  }
} 