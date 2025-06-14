// lib/theme/app_theme_data.dart (MEVCUT VE DOĞRU YAPI)

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'notebook_theme_type.dart';

class AppThemeData extends Equatable {
  /// Temanın benzersiz türünü tanımlar (enum).
  final NotebookThemeType type;

  /// Tema seçim ekranında gösterilecek ad.
  final String name;

  /// Bu tema için kullanılacak tam sayfa arka plan görselinin yolu.
  final String backgroundAssetPath;

  /// Flutter'ın Material Design tema verilerini içeren nesne.
  /// Renkler, fontlar, widget stilleri gibi YÜZLERCE parametreyi
  /// bu nesne kendi içinde barındırır.
  final ThemeData materialTheme;

  /// Temanın ücretsiz olup olmadığını belirtir.
  final bool isFree;

  const AppThemeData({
    required this.type,
    required this.name,
    required this.backgroundAssetPath,
    required this.materialTheme, // ThemeData nesnesi burada!
    this.isFree = false, // Varsayılan olarak premium
  });

  /// Yeni bir AppThemeData nesnesi oluşturur, sadece belirtilen alanları değiştirir.
  AppThemeData copyWith({
    NotebookThemeType? type,
    String? name,
    String? backgroundAssetPath,
    ThemeData? materialTheme,
    bool? isFree,
  }) {
    return AppThemeData(
      type: type ?? this.type,
      name: name ?? this.name,
      backgroundAssetPath: backgroundAssetPath ?? this.backgroundAssetPath,
      materialTheme: materialTheme ?? this.materialTheme,
      isFree: isFree ?? this.isFree,
    );
  }

  @override
  List<Object?> get props => [
    type,
    name,
    backgroundAssetPath,
    materialTheme,
    isFree,
  ];

  @override
  bool get stringify => true;

  // Tema tipinden (enum) okunabilir bir stil adı (String) döndürür
  String get displayName {
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
}