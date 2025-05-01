// lib/features/journal/screens/home/home_screen.dart (Karşılama Ekranı Olarak Yeniden Düzenlendi)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için
// ========== !!! IMPORT YOLLARINI KONTROL ET VE TUTARLI YAP !!! ==========
// ThemedBackground importu gerekli olabilir, yolu kontrol edin
// import 'package:mindvault/widgets/themed_background.dart';
// Artık BLoC, Model, diğer ekran importlarına burada ihtiyaç yok.
// ==============================================================

class HomeScreen extends StatelessWidget {
  // Artık state yönetimi olmadığı için StatelessWidget olabilir
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mevcut temayı ve renkleri al
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Ekran genişliğini al
    final screenWidth = MediaQuery.of(context).size.width;

    // Görüntülenecek tarih
    final now = DateTime.now();
    // Türkçe format için intl paketi kullanılır (main.dart'ta initializeDateFormatting yapılmalı)
    final formattedDate = DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(now);

    // MainScreen zaten ThemedBackground ve Scaffold sağlıyor.
    // Biz sadece Scaffold'un body'si için içeriği döndüreceğiz.
    // İçeriği ortalamak ve genişliği kısıtlamak için Center ve SizedBox kullanıyoruz.
    return Center(
      child: SizedBox(
        // Genişliği ekranın 3/4'ü olarak ayarla
        width: screenWidth * 0.75,
        // Yüksekliği de kısıtlayabiliriz veya Column'un sarmasına izin verebiliriz
        // height: MediaQuery.of(context).size.height * 0.6, // Örnek yükseklik kısıtlaması
        child: Padding(
          // Widget'ları daha içeri almak için ek padding
          // Bu padding, 3/4 genişliğindeki alanın *içinde* uygulanır.
          padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 16.0), // Dikeyde daha fazla boşluk
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // İçeriği dikeyde ortala
            crossAxisAlignment: CrossAxisAlignment.center, // İçeriği yatayda ortala
            children: [
              // Karşılama Mesajı veya Uygulama Logosu/İkonu
              Icon(
                Icons.auto_stories, // Örnek bir ikon
                size: 80,
                color: colorScheme.primary.withOpacity(0.8),
              ),
              const SizedBox(height: 24),
              Text(
                'Mind Vault', // Veya "Hoş Geldin!"
                style: textTheme.headlineLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Günün Tarihi
              Text(
                formattedDate,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // İlham Verici Söz veya Yazma İstemi
              Text(
                '"Bugün zihninde keşfedilmeyi bekleyen neler var?"', // Örnek
                style: textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              // FAB zaten MainScreen'de olduğu için burada ek butona gerek olmayabilir.
              // Gerekirse eklenebilir:
              // const SizedBox(height: 40),
              // ElevatedButton.icon(
              //   onPressed: () {
              //     Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditJournalScreen()));
              //   },
              //   icon: const Icon(Icons.edit_note_rounded),
              //   label: const Text('Yazmaya Başla'),
              // )
            ],
          ),
        ),
      ),
    );
  }
}