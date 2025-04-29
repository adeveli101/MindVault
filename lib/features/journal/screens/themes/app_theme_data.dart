// lib/theme/app_theme_data.dart (GÜNCELLENDİ)

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'notebook_theme_type.dart';

class AppThemeData extends Equatable {
  final NotebookThemeType type;
  final String name;
  // backgroundAssetPath artık tam sayfa görselini tutacak
  final String backgroundAssetPath;
  // overlayAssetPath kaldırıldı
  final ThemeData materialTheme;
  final bool isFree;

  const AppThemeData({
    required this.type,
    required this.name,
    required this.backgroundAssetPath, // Bu artık sayfa görseli yolu
    // overlayAssetPath kaldırıldı
    required this.materialTheme,
    required this.isFree,
  });

  @override
  List<Object?> get props => [
    type,
    name,
    backgroundAssetPath,
    // overlayAssetPath kaldırıldı
    materialTheme,
    isFree,
  ];

  @override
  bool get stringify => true;
}