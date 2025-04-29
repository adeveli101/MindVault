// lib/theme/notebook_theme_type.dart

/// Uygulamadaki farklı defter teması türlerini tanımlar.
enum NotebookThemeType {
  // --- Ücretsiz Temalar ---
  /// Varsayılan açık tema (Ücretsiz)
  defaultLight,
  /// Varsayılan koyu tema (Ücretsiz)
  defaultDark,

  // --- Potansiyel Ücretli Temalar ---
  /// Klasik deri görünümü (Potansiyel Ücretli)
  classicLeather,
  /// Modern noktalı kağıt görünümü (Potansiyel Ücretli)
  dottedModern,
  /// Vintage çiçek desenli (Potansiyel Ücretli)
  vintageFloralLight,
  /// Spiral ciltli defter (Potansiyel Ücretli)
  spiralBound,
  // ... İhtiyaç oldukça eklenecek diğer ücretli temalar ...
}