// lib/features/journal/screens/entry/add_edit_journal_screen.dart
// Başlık kaldırıldı. Fontlar ThemeConfig (GoogleFonts, boyut seçenekli) üzerinden gelecek.
// MoodSelectorWidget entegre edildi.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// BLoC, Model ve Widget yollarını kendi projenize göre güncelleyin
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart'; // Mood enum'u da buradan gelmeli
import 'package:mindvault/features/journal/screens/page_screens/widgets/mood_selector_widget.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class AddEditJournalScreen extends StatefulWidget {
  final JournalEntry? existingEntry;

  const AddEditJournalScreen({super.key, this.existingEntry});

  @override
  State<AddEditJournalScreen> createState() => _AddEditJournalScreenState();
}

class _AddEditJournalScreenState extends State<AddEditJournalScreen> {
  final PageController _pageController = PageController();
  final List<TextEditingController> _pageControllers = [];

  Mood? _selectedMood; // Seçili ruh hali state'i
  late DateTime _displayDate;
  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    _displayDate = widget.existingEntry?.createdAt ?? DateTime.now();
    // Mevcut giriş varsa veya state'den geliyorsa başlangıç mood'unu ayarla
    _selectedMood = widget.existingEntry?.mood;

    // İçerik controller'larını başlat
    if (widget.existingEntry != null && widget.existingEntry!.content.isNotEmpty) {
      // İPUCU: İçeriği '\n\n' gibi ayırıcılara göre bölüp
      // birden fazla sayfa oluşturmak için burayı genişletebilirsiniz.
      // List<String> pages = widget.existingEntry!.content.split('\n\n');
      // for (var pageContent in pages) { _addPageController(text: pageContent); }
      _addPageController(text: widget.existingEntry!.content);
    } else {
      // Yeni giriş için veya boş içerikli eski giriş için boş sayfa ekle
      _addPageController();
    }
  }

  void _addPageController({String text = ''}) {
    final controller = TextEditingController(text: text);
    if (mounted) {
      setState(() { _pageControllers.add(controller); });
    } else {
      _pageControllers.add(controller); // initState sırasında doğrudan ekle
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _pageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Seçilen mood'u güncelleyen callback fonksiyonu
  void _handleMoodSelected(Mood? newMood) {
    if (mounted) {
      setState(() {
        _selectedMood = newMood;
      });
    }
  }

  Future<void> _saveEntry() async {
    // İçeriği birleştir (baş/son boşlukları al, boş sayfaları filtrele)
    final combinedContent = _pageControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty) // Boş sayfaları atla
        .join('\n\n'); // Sayfaları çift satırla birleştir

    // İçerik boş mu kontrol et
    if (combinedContent.isEmpty) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Günlük içeriği boş olamaz.', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
      return;
    }

    final now = DateTime.now();

    // Kaydetme/Güncelleme mantığı (Mood dahil)
    if (_isEditing) {
      final updatedEntry = widget.existingEntry!.copyWith(
        content: combinedContent,
        mood: _selectedMood, // Seçili mood'u kaydet
        updatedAt: now,
        // createdAt değişmez
      );
      if (mounted) context.read<JournalBloc>().add(UpdateJournalEntry(updatedEntry));
    } else {
      final newEntry = JournalEntry(
        // id BLoC/Repo katmanında atanmalı
        content: combinedContent,
        mood: _selectedMood, // Seçili mood'u kaydet
        createdAt: _displayDate, // Ekran ilk açıldığındaki tarih
        updatedAt: _displayDate, // İlk kayıtta aynı
      );
      if (mounted) context.read<JournalBloc>().add(AddJournalEntry(newEntry));
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _addNewPage() {
    if (mounted) {
      setState(() {
        _addPageController(); // Yeni boş controller ekle
      });
      // Eklendikten sonra son sayfaya git (güvenli kontrol ile)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients && _pageControllers.isNotEmpty) {
          _pageController.animateToPage(
            _pageControllers.length - 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme; // GoogleFonts ile yapılandırılmış tema
    final String saveButtonText = _isEditing ? 'Güncelle' : 'Kaydet';

    // TextTheme'den stilleri al (Null ise varsayılan ata)
    final dateTextStyle = textTheme.headlineMedium ?? const TextStyle(fontSize: 26, fontWeight: FontWeight.bold);
    final contentTextStyle = textTheme.bodyLarge ?? const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, height: 1.7);
    final buttonTextStyle = textTheme.labelMedium ?? const TextStyle(fontSize: 12);


    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const SizedBox.shrink(), // Başlık yok
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // --- Üst Kısım: Sadece Tarih ---
              Padding(
                padding: const EdgeInsets.fromLTRB(40.0, 15.0, 40.0, 10.0),
                child: Text(
                  // Intl paketini kullanarak tarih formatla
                  DateFormat('dd MMMM yyyy, EEEE HH:mm', 'tr_TR').format(_displayDate),
                  textAlign: TextAlign.center,
                  style: dateTextStyle.copyWith(color: colorScheme.onSurface.withOpacity(0.9)),
                ),
              ),

              // --- Orta Kısım: İçerik Sayfaları ---
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pageControllers.isEmpty ? 1 : _pageControllers.length, // Başlangıçta 1 sayfa göster
                  itemBuilder: (context, index) {
                    if (index >= _pageControllers.length) return const SizedBox.shrink(); // Güvenlik kontrolü

                    return Padding(
                      // Padding ayarlarını isteğe göre düzenleyebilirsiniz
                      padding: const EdgeInsets.fromLTRB(40.0, 5.0, 40.0, 10.0),
                      child: TextFormField(
                        controller: _pageControllers[index],
                        maxLines: null, // Sınırsız satır
                        expands: true, // Alanı doldur
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          border: InputBorder.none, // Tema'dan alınmalı (InputDecorationTheme)
                          filled: false,          // Tema'dan alınmalı
                          hintText: index == 0 ? 'Kalbinden dökülenler...' : 'Devam et...',
                          // Hint stilini temadan al, null ise varsayılana düş
                          hintStyle: (contentTextStyle).copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6), // Hint rengini ayarla
                          ),
                          contentPadding: EdgeInsets.zero, // İç padding sıfırla
                        ),
                        // Yazı stilini temadan al, null ise varsayılana düş
                        style: (contentTextStyle).copyWith(
                          color: colorScheme.onSurface, // Yazı rengini ayarla
                        ),
                        scrollPadding: EdgeInsets.zero,
                        textAlignVertical: TextAlignVertical.top, // Yukarıdan başla
                        textCapitalization: TextCapitalization.sentences, // Cümle başı büyük harf
                      ),
                    );
                  },
                ),
              ),

              // --- Alt Kısım: Mood, Indicator, Bilgi ---
              Padding(
                padding: const EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 5.0),
                child: Column(
                  children: [
                    // === Mood Seçici Widget ===
                    MoodSelectorWidget(
                      initialMood: _selectedMood, // Başlangıç mood'unu ver
                      onMoodSelected: _handleMoodSelected, // Seçim değiştiğinde state'i güncelle
                      // Diğer opsiyonel parametreler (itemSize, iconSize vb.)
                      // itemSize: 40,
                      // iconSize: 22,
                      // verticalSpacing: 6,
                    ),
                    const SizedBox(height: 15), // Mood seçici ile gösterge arasına boşluk

                    // === Sayfa Göstergesi ===
                    if (_pageControllers.length > 1)
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _pageControllers.length,
                        effect: WormEffect( // veya ExpandingDotsEffect, ScrollingDotsEffect vb.
                          dotHeight: 8, dotWidth: 8,
                          activeDotColor: colorScheme.primary,
                          dotColor: colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),

                    // === Son Güncelleme Bilgisi ===
                    if (_isEditing && widget.existingEntry != null && widget.existingEntry!.updatedAt.isAfter(widget.existingEntry!.createdAt))
                      _buildInfoText(context,'Son Güncelleme: ${DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(widget.existingEntry!.updatedAt)}'),

                    // Ekranın altına biraz daha boşluk ekleyebiliriz
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
        // --- En Alt Kısım: Butonlar ---
        bottomNavigationBar: Padding(
          // Klavye açıldığında butonların yukarı itilmesi için viewInsets kullanılır
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 10.0, // Klavye yüksekliği + boşluk
            top: 5.0, left: 30.0, right: 30.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Yeni Sayfa Ekle Butonu
              TextButton.icon(
                onPressed: _addNewPage,
                icon: Icon(Icons.add_to_photos_outlined, size: 18),
                // Buton Text stilini temadan al (labelMedium)
                label: Text('Sayfa', style: buttonTextStyle),
                style: theme.textButtonTheme.style?.copyWith(
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ),
              ),

              // Kaydet Butonu
              ElevatedButton.icon(
                onPressed: _saveEntry,
                style: theme.elevatedButtonTheme.style?.copyWith(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0), // Buton padding
                  ),
                ),
                icon: Icon(_isEditing ? Icons.check_circle_outline : Icons.save_alt_outlined, size: 18),
                // Buton Text stilini temadan al (labelMedium), kalın yap
                label: Text(saveButtonText, style: (buttonTextStyle).copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bilgi metni (Değişiklik yok)
  Widget _buildInfoText(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        // bodySmall stilini temadan al, null ise varsayılana düş
        style: (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 14)).copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6), // Soluk renk
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}