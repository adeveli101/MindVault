// lib/themes/theme_config.dart (YENİ - Kayıt Merkezi - YARDIMCI FONKSİYONLAR DOLDURULDU)

import 'package:flutter/foundation.dart'; // kDebugMode için eklendi
import 'package:flutter/material.dart';
// ========== !!! IMPORT YOLUNU KONTROL ET VE TUTARLI YAP !!! ==========
// Paket adınız 'mindvault' ise aşağıdaki gibi olmalı. Değilse düzeltin.
// BU DOSYADAKİ VE DİĞER TÜM DOSYALARDAKİ YOLLAR AYNI OLMALI!
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/antique_theme_style.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/blueprint_theme_style.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/dark_theme_style.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/japanese_theme_style.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/leather_theme_style.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/light_theme_style.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/scrapbook_theme_style.dart';
import 'package:mindvault/features/journal/screens/themes/theme_data/watercolor_theme_style.dart'; // Kullanılmıyorsa kaldırılabilir


// =====================================================================


enum ThemeSize { small, medium, large }

class ThemeConfig {

  // --- Ana Tema Listesi ---
  // Farklı stil dosyalarından tüm tema varyantlarını toplar
  // Sıralama önemlidir, index'e göre erişim yapılır.
  static final List<AppThemeData> themes = [
    // Aydınlık
    LightThemeStyle.small, LightThemeStyle.medium, LightThemeStyle.large,
    // Karanlık (Altın Vurgu)
    DarkThemeStyle.small, DarkThemeStyle.medium, DarkThemeStyle.large,
    // Deri
    LeatherThemeStyle.small, LeatherThemeStyle.medium, LeatherThemeStyle.large,
    // Antika
    AntiqueThemeStyle.small, AntiqueThemeStyle.medium, AntiqueThemeStyle.large,
    // Blueprint
    BlueprintThemeStyle.small, BlueprintThemeStyle.medium, BlueprintThemeStyle.large,
    // Scrapbook
    ScrapbookThemeStyle.small, ScrapbookThemeStyle.medium, ScrapbookThemeStyle.large,
    // Japanese
    JapaneseThemeStyle.small, JapaneseThemeStyle.medium, JapaneseThemeStyle.large,
    // Watercolor
    WatercolorThemeStyle.small, WatercolorThemeStyle.medium, WatercolorThemeStyle.large,
  ];

  // stacked_themes için Material Tema listesi
  static List<ThemeData> get materialThemes => themes.map((t) => t.materialTheme).toList();

  // === UI YARDIMCI FONKSİYONLARI (DOLDURULDU) ===

  // UI'da gösterilecek temaları kullanıcının premium durumuna göre döndürür
  static List<AppThemeData> getAvailableThemes(bool isPremium) {
    final allThemes = getBaseThemeRepresentations();
    if (isPremium) {
      return allThemes; // Premium kullanıcılar tüm temalara erişebilir
    } else {
      return allThemes.where((theme) => theme.isFree).toList(); // Freemium kullanıcılar sadece ücretsiz temalara erişebilir
    }
  }

  // Tema seçimini kontrol eder ve uygular
  static bool canApplyTheme(AppThemeData theme, bool isPremium) {
    if (theme.isFree) return true; // Ücretsiz temalar her zaman uygulanabilir
    return isPremium; // Premium temalar sadece premium kullanıcılara uygulanabilir
  }

  // Tema tipinden (enum) okunabilir bir stil adı (String) döndürür
  static String getThemeDisplayName(NotebookThemeType type) {
    String typeName = type.toString().split('.').last;
    typeName = typeName
        .replaceAll('Small', '')
        .replaceAll('Medium', '')
        .replaceAll('Large', '');

    switch (typeName) {
      case 'defaultLight':
        return "Aydınlık";
      case 'defaultDark':
        return "Altın Vurgu";
      case 'classicLeather':
        return "Deri";
      case 'antique':
        return "Antika";
      case 'blueprint':
        return "Mimari";
      case 'scrapbook':
        return "Karalama";
      case 'japanese':
        return "Minimalist";
      case 'watercolor':
        return "Suluboya";
      default:
        return typeName;
    }
  }

  // UI'da gösterilecek temsilci temalar (Orta boyutlular)
  static List<AppThemeData> getBaseThemeRepresentations() {
    // Eğer herhangi bir stil dosyası eksikse veya import edilmemişse burada hata alırsınız.
    return [
      LightThemeStyle.medium.copyWith(isFree: true),  // Ücretsiz
      DarkThemeStyle.medium.copyWith(isFree: true),   // Ücretsiz
      LeatherThemeStyle.medium.copyWith(isFree: false),  // Premium
      AntiqueThemeStyle.medium.copyWith(isFree: false),  // Premium
      BlueprintThemeStyle.medium.copyWith(isFree: false),  // Premium
      ScrapbookThemeStyle.medium.copyWith(isFree: false),  // Premium
      JapaneseThemeStyle.medium.copyWith(isFree: false),  // Premium
      WatercolorThemeStyle.medium.copyWith(isFree: false),  // Premium
    ];
  }

  // Verilen tipin temel stilini döndürür (Güncellenmiş)
  static NotebookThemeType getBaseStyle(NotebookThemeType type) {
    String typeName = type.toString().split('.').last;
    // Enum isimlerine göre kontrol yapılıyor
    if (typeName.startsWith('defaultLight')) return NotebookThemeType.defaultLightMedium;
    if (typeName.startsWith('defaultDark')) return NotebookThemeType.defaultDarkMedium; // Dark için medium
    if (typeName.startsWith('classicLeather')) return NotebookThemeType.classicLeatherMedium;
    if (typeName.startsWith('antique')) return NotebookThemeType.antiqueMedium;
    if (typeName.startsWith('blueprint')) return NotebookThemeType.blueprintMedium;
    if (typeName.startsWith('scrapbook')) return NotebookThemeType.scrapbookMedium;
    if (typeName.startsWith('japanese')) return NotebookThemeType.japaneseMedium;
    if (typeName.startsWith('watercolor')) return NotebookThemeType.watercolorMedium;

    // Eğer tema bulunamazsa varsayılan döndür ve debug modda uyar
    if (kDebugMode) {
      print("Uyarı: getBaseStyle bilinmeyen tip: $type. Varsayılan kullanılıyor.");
    }
    return NotebookThemeType.defaultLightMedium; // Varsayılan
  }

  // Verilen tipin boyutunu döndürür
  static ThemeSize getThemeSize(NotebookThemeType type) {
    String typeName = type.toString().split('.').last;
    // Enum isimleri küçük harfle bittiği için (small, medium, large)
    if (typeName.endsWith('Small')) return ThemeSize.small;
    if (typeName.endsWith('Large')) return ThemeSize.large;
    return ThemeSize.medium; // Diğer tüm durumlar için medium varsayılır
  }

  // Stil ve boyuta göre tam tema tipini bulur
  static NotebookThemeType? findThemeTypeByStyleAndSize(NotebookThemeType baseStyle, ThemeSize size) {
    // baseStyle'dan temel adı al (örn: antiqueMedium -> antique)
    String baseName = baseStyle.toString().split('.').last.replaceAll('Medium', '');
    // size enum'dan isim al (örn: ThemeSize.small -> small)
    String sizeName = size.toString().split('.').last;
    // Hedef enum ismini oluştur (örn: antique + Small -> antiqueSmall)
    // Enum isimleri büyük harfle başladığı için: small -> Small
    String targetTypeName = baseName + sizeName[0].toUpperCase() + sizeName.substring(1);
    try {
      // Enum değerleri içinde bu isme sahip olanı bul
      return NotebookThemeType.values.firstWhere(
              (e) => e.toString().split('.').last == targetTypeName
      );
    } catch (e) {
      // Eşleşme bulunamazsa uyar ve null döndür
      if (kDebugMode) {
        print("Uyarı: Tema tipi bulunamadı - Stil: $baseName, Boyut: $sizeName");
      }
      return null;
    }
  }

  // Stil ve boyuta göre tema indeksini bulur
  static int findThemeIndexByStyleAndSize(NotebookThemeType baseStyle, ThemeSize size) {
    final NotebookThemeType? targetType = findThemeTypeByStyleAndSize(baseStyle, size);
    if (targetType != null) {
      // themes listesindeki indeksi bul
      final index = themes.indexWhere((theme) => theme.type == targetType);
      if (index != -1) {
        return index; // Bulunduysa indeksi döndür
      }
    }
    // Bulunamadıysa veya hata oluştuysa uyar ve -1 döndür
    if (kDebugMode) {
      print("Uyarı: Tema indeksi bulunamadı - Stil: $baseStyle, Boyut: $size");
    }
    return -1;
  }

  // Index ve Type ile ilgili standart yardımcılar
  static AppThemeData getAppThemeDataByIndex(int index) {
    // Index kontrolü
    if (index >= 0 && index < themes.length) {
      return themes[index];
    }
    // Geçersiz index için varsayılan tema döndür
    if (kDebugMode) {
      print("Uyarı: Geçersiz tema index'i: $index. Varsayılan tema kullanılıyor.");
    }
    // Varsayılan tema: Light Medium (veya başka bir güvenli varsayılan)
    return LightThemeStyle.medium;
  }

  static NotebookThemeType getThemeTypeByIndex(int index) {
    // Önce AppThemeData'yı al, sonra tipini döndür
    return getAppThemeDataByIndex(index).type;
  }

  static int getIndexByThemeType(NotebookThemeType type) {
    // Verilen tipe sahip temanın indeksini bul
    final index = themes.indexWhere((theme) => theme.type == type);
    // Bulunamazsa varsayılan temanın indeksini döndür
    return index != -1 ? index : themes.indexOf(LightThemeStyle.medium);
  }
}