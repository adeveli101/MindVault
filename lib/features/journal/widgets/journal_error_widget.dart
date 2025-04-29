// lib/features/journal/widgets/journal_error_widget.dart

import 'package:flutter/material.dart';
// Temayı import et

/// Bir hata oluştuğunda gösterilecek widget.
/// Hata mesajını ve isteğe bağlı olarak bir 'tekrar dene' butonu içerir.
class JournalErrorWidget extends StatelessWidget {
  /// Gösterilecek hata mesajı.
  final String errorMessage;
  /// 'Tekrar Dene' butonuna basıldığında çağrılacak fonksiyon.
  /// Eğer null ise buton gösterilmez.
  final VoidCallback? onRetry;

  const JournalErrorWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Card( // Hata mesajını bir kart içinde göstermek görsel ayrım sağlar
          elevation: 0, // Temadaki kart elevasyonunu kullanabilir veya sıfırlayabiliriz
          color: colorScheme.errorContainer.withOpacity(0.5), // Hata konteyner rengi (hafif şeffaf)
          shape: theme.cardTheme.shape, // Temadaki kart şeklini al
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // İçeriğe göre boyutlan
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 56.0,
                  color: colorScheme.error, // Temanın hata rengi
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Bir Sorun Oluştu',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onErrorContainer, // Hata konteyneri üzerindeki renk
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  errorMessage, // BLoC'tan gelen hata mesajı
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer.withOpacity(0.8),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Eğer onRetry fonksiyonu verilmişse butonu göster
                if (onRetry != null) ...[
                  const SizedBox(height: 24.0),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    // Buton stilini temadan al ama belki hata rengiyle uyumlu hale getir?
                    // style: ElevatedButton.styleFrom(
                    //   backgroundColor: colorScheme.error,
                    //   foregroundColor: colorScheme.onError,
                    // ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tekrar Dene'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}