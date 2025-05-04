// lib/features/journal/screens/home/home_screen.dart (Eski Tasarıma Yakın, Geliştirilmiş)
// Değişiklikler: TextButton kaldırıldı, sadece ikon kullanıldı, sağ üste yeniden konumlandırıldı (3:4 oranlı boşluk).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mindvault/features/journal/screens/home/onboarding_screen.dart'; // Tarih formatlama için




class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mevcut temayı ve renkleri al (ThemeConfig ile yapılandırıldığı varsayılır)
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Görüntülenecek tarih
    final now = DateTime.now();
    // Türkçe format için intl paketi kullanılır (main.dart'ta initializeDateFormatting yapılmalı)
    final formattedDate = DateFormat('dd MMMM yyyy, EEEE' , 'tr_TR').format(now);

    // MainScreen zaten ThemedBackground ve Scaffold sağlıyor.
    // Biz sadece Scaffold'un body'si için içeriği döndüreceğiz.
    // Ortalanmış içerik ve sabit alt/üst elemanlar için Stack kullanıyoruz.
    return Stack(
      children: [
        // 1. Ortalanmış Ana İçerik
        Center(
          child: Padding(
            // Kenarlardan biraz boşluk bırak, ikon ve alt yazı için dikey boşluk ayarla
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 80.0), // Dikey padding korunuyor
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Dikeyde ortala
              crossAxisAlignment: CrossAxisAlignment.center, // Yatayda ortala
              children: [
                // Uygulama İkonu
                Icon(
                  Icons.auto_stories_rounded, // Dolgun ikon
                  size: 70,
                  color: colorScheme.primary.withOpacity(0.9), // Primary renk, hafif opaklık
                ),

                // Uygulama Adı
                Text(
                  'Mind Vault',
                  style: textTheme.headlineLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Günün Tarihi
                Text(
                  formattedDate,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 85),

                // İlham Verici Söz veya Yazma İstemi
                Text(
                  '"Düşünceleriniz sizin özel alanınızdır."',
                  style: textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withOpacity(0.75),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // 2. "Why Mind Vault?" İkonu (Sağ Üst, 3:4 Oranlı Uzaklık)
        Positioned(
          // ****** DEĞİŞİKLİK: Konum güncellendi (3:4 oranlı boşluk) ******
          top: 35.0,  // Üstten 3 birim (örnek değer)
          right: 30.0, // Sağdan 4 birim (örnek değer)
          // left: null, // left kaldırıldı
          child: IconButton( // TextButton yerine IconButton
            icon: Icon(
              // ****** DEĞİŞİKLİK: Kalın/Belirgin ikon, renk ve opaklık isteğe göre ******
              Icons.info_outline, // veya Icons.security_rounded, Icons.help_rounded
              color: colorScheme.primary.withOpacity(0.8), // Primary olmayan, opak bir renk (örn: secondary)
              size: 31//Belirgin boyut
            ),
            tooltip: 'Neden Mind Vault?', // Tıklandığında veya üzerine gelindiğinde görünen yazı
            // IconButton'un etrafında varsayılan olarak bir miktar boşluk bulunur (hitbox için)
            // padding: EdgeInsets.zero, // Gerekirse iç boşluğu sıfırla
            constraints: const BoxConstraints(), // Gerekirse boyut kısıtlamalarını kaldır
            onPressed: () {
              // OnboardingScreen'e yönlendirme
              // Kendi OnboardingScreen importunuzu ve yönlendirmenizi ekleyin
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
          ),
        ),

        // 3. En Alt Ortadaki Gizlilik Bilgisi Metni (Konumu aynı)
      ],
    );
  }
}