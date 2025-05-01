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
    required this.isFree,
  });

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
}