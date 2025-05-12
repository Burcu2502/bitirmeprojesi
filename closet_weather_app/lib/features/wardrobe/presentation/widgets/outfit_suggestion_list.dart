import 'package:flutter/material.dart';

class OutfitSuggestionList extends StatelessWidget {
  const OutfitSuggestionList({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Bu widget ileride tamamlanacak
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Bu özellik yakında eklenecek',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
} 