import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart';

class FilterSheet extends StatefulWidget {
  /// Başlangıçta seçili olan ruh halleri listesi.
  final List<Mood>? initialSelectedMoods;

  const FilterSheet({super.key, this.initialSelectedMoods});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  /// Alt sayfa içinde geçici olarak seçilen ruh hallerini tutar.
  /// Set kullanmak, aynı mood'un tekrar eklenmesini önler ve kontrolü kolaylaştırır.
  late Set<Mood> _tempSelectedMoods;

  @override
  void initState() {
    super.initState();
    // Başlangıç değerlerini al (null veya boş olabilir)
    _tempSelectedMoods = widget.initialSelectedMoods?.toSet() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    // Gösterilecek mood'lar (unknown hariç)
    final availableMoods = Mood.values.where((m) => m != Mood.unknown).toList();

    return Padding(
      // Kenar boşlukları ve klavye için padding (varsa)
      padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, MediaQuery.of(context).viewInsets.bottom + 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // İçeriğe göre boyutlan
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık ve Kapatma Butonu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.filterByMood, style: textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context), // Değişiklik yapmadan kapat
                tooltip: l10n.close,
              ),
            ],
          ),
          const Divider(height: 20),

          // Mood Seçim Alanı (Kaydırılabilir)
          Expanded( // Kalan alana yayıl
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8.0, // Chipler arası yatay boşluk
                runSpacing: 8.0, // Satırlar arası dikey boşluk
                children: availableMoods.map((mood) {
                  final bool isSelected = _tempSelectedMoods.contains(mood);
                  return FilterChip(
                    label: Text(mood.displayName),
                    avatar: FaIcon(
                      mood.icon,
                      size: 16,
                      color: isSelected ? mood.getColor(colorScheme).withOpacity(0.9) : colorScheme.onSurfaceVariant,
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _tempSelectedMoods.add(mood); // Seçildiyse sete ekle
                        } else {
                          _tempSelectedMoods.remove(mood); // Seçim kaldırıldıysa setten çıkar
                        }
                      });
                    },
                    // Seçili chip stilini belirginleştir
                    selectedColor: mood.getColor(colorScheme).withOpacity(0.15),
                    checkmarkColor: mood.getColor(colorScheme), // Checkmark rengi
                    shape: StadiumBorder(side: BorderSide(color: isSelected ? mood.getColor(colorScheme).withOpacity(0.5) : colorScheme.outlineVariant.withOpacity(0.5))),
                    labelStyle: TextStyle(color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 20),

          // Alt Butonlar (Temizle ve Uygula)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Temizle Butonu
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempSelectedMoods.clear(); // Tüm seçimleri kaldır
                  });
                  // İsteğe bağlı: Temizle butonuna basınca sayfayı kapatıp null dönebilir
                  // Navigator.pop(context, <Mood>{}); // Boş set veya null dönebilir
                },
                child: Text(l10n.clearSelection),
              ),
              // Uygula Butonu
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(l10n.applyFilter),
                onPressed: () {
                  // Seçilen mood'ları (Set olarak) geri döndür
                  Navigator.pop(context, _tempSelectedMoods);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}