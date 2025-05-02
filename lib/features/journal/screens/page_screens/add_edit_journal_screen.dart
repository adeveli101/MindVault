// lib/features/journal/screens/entry/add_edit_journal_screen.dart
// Tema entegrasyonu iyileştirildi. Başlık kaldırıldı, tarih başlık olarak kullanıldı.
// Hint değiştirildi, input font boyutu ayarlandı (bodyMedium).
// Alt kontroller (IconButton, Buton, Mood) ortak alanda (arka plansız), Spacer ile simetrik hizalandı.
// Boyutlar/Padding'ler görsel simetri için ayarlandı. Klavye ile otomatik hareket ediyor ve biraz yukarıda.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
// İkon paketleri için örnek import (kullanmak isterseniz paketi ekleyin ve import edin)
// import 'package:iconsax/iconsax.dart'; // Örnek: Iconsax paketi

// BLoC, Model ve Widget yollarını kendi projenize göre güncelleyin
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
import 'package:mindvault/features/journal/screens/widgets/mood_selector_widget.dart';
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

  Mood? _selectedMood;
  late DateTime _displayDate;
  bool get _isEditing => widget.existingEntry != null;


  @override
  void initState() {
    super.initState();
    _displayDate = widget.existingEntry?.createdAt ?? DateTime.now();
    _selectedMood = widget.existingEntry?.mood;

    if (_isEditing && widget.existingEntry!.content.isNotEmpty) {
      _addPageController(text: widget.existingEntry!.content);
    } else {
      _addPageController();
    }
  }

  void _addPageController({String text = ''}) {
    final controller = TextEditingController(text: text);
    _pageControllers.add(controller);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _pageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleMoodSelected(Mood? newMood) {
    if (mounted) {
      setState(() {
        _selectedMood = newMood;
      });
    }
  }

  Future<void> _saveEntry() async {
    final combinedContent = _pageControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n\n');

    if (combinedContent.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Günlük içeriği boş olamaz.',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    final entryId = widget.existingEntry?.id;

    final entryToSave = JournalEntry(
      id: entryId,
      content: combinedContent,
      mood: _selectedMood,
      createdAt: _isEditing ? widget.existingEntry!.createdAt : _displayDate,
      updatedAt: now,
      isFavorite: widget.existingEntry?.isFavorite ?? false,
      tags: widget.existingEntry?.tags,
    );

    if (mounted) {
      if (_isEditing) {
        context.read<JournalBloc>().add(UpdateJournalEntry(entryToSave));
      } else {
        context.read<JournalBloc>().add(AddJournalEntry(entryToSave));
      }
      Navigator.of(context).pop();
    }
  }

  // Sayfa Ekleme Fonksiyonu
  void _addNewPage() {
    final newController = TextEditingController();
    if (mounted) {
      setState(() {
        _pageControllers.add(newController);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.animateToPage(
            _pageControllers.length - 1,
            duration: const Duration(milliseconds: 400),
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
    final textTheme = theme.textTheme;
    final String saveButtonText = _isEditing ? 'Güncelle' : 'Kaydet';

    // Metin stilleri
    final headerTextStyle = textTheme.headlineSmall?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w500,
    );
    final contentTextStyle = textTheme.bodyMedium?.copyWith(
      height: 1.5,
      color: colorScheme.onSurface,
    );
    final infoTextStyle = textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.8));

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Klavye için varsayılan davranış (true) aktif
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.appBarTheme.iconTheme?.color ?? colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // --- Üst Kısım: Tarih (Başlık olarak) ---
              Padding(
                padding: const EdgeInsets.fromLTRB(40.0, 5.0, 40.0, 15.0),
                child: Text(
                  DateFormat('dd MMMM, EEEE HH:mm', 'tr_TR').format(_displayDate),
                  textAlign: TextAlign.center,
                  style: headerTextStyle,
                ),
              ),

              // --- Orta Kısım: İçerik Sayfaları (Genişleyebilir alan) ---
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pageControllers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(40.0, 0.0, 40.0, 10.0),
                      child: TextFormField(
                        controller: _pageControllers[index],
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        scrollPadding: EdgeInsets.zero,
                        textAlignVertical: TextAlignVertical.top,
                        textCapitalization: TextCapitalization.sentences,
                        style: contentTextStyle,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          hintText: index == 0 ? 'Notlarınız...' : 'Devam et...',
                          hintStyle: contentTextStyle?.copyWith(color: theme.hintColor),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- Alt Kısım: Gösterge, Bilgi ve Kontrollerin Ortak Alanı ---
              Padding(
                // Alanı hafif yukarı taşımak için alt padding
                padding: const EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 40.0), // Yan padding azaltıldı, alt padding ayarlandı
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gösterge ve Bilgi Metni Alanı
                    SizedBox(
                      height: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Gösterge sadece birden fazla sayfa varsa görünür
                          if (_pageControllers.length > 1)
                            SmoothPageIndicator(
                              controller: _pageController,
                              count: _pageControllers.length,
                              effect: ScrollingDotsEffect(
                                dotHeight: 6, dotWidth: 6,
                                activeDotScale: 1.5,
                                activeDotColor: colorScheme.primary,
                                dotColor: colorScheme.onSurface.withOpacity(0.3),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Son Güncelleme Bilgisi
                    if (_isEditing && widget.existingEntry != null && widget.existingEntry!.updatedAt.isAfter(widget.existingEntry!.createdAt))
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                        child: Text(
                          'Son Güncelleme: ${DateFormat('dd MMMM, HH:mm', 'tr_TR').format(widget.existingEntry!.updatedAt)}',
                          style: infoTextStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (!(_isEditing && widget.existingEntry != null && widget.existingEntry!.updatedAt.isAfter(widget.existingEntry!.createdAt)) && _pageControllers.length <= 1)
                      const SizedBox(height: 8.0),

                    const SizedBox(height: 10), // Kontrollere kadar boşluk

                    // ****** DEĞİŞİKLİK: Ortak Kontrol Alanı (Row + Spacer ile Simetrik) ******
                    // Container yok, arka plan yok.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Sol: Sayfa Ekle İkon Butonu
                        // ****** DEĞİŞİKLİK: Daha fazla padding ile görsel denge ******
                        Padding( // IconButton'a dıştan padding
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: IconButton(
                            onPressed: _addNewPage,
                            icon: const Icon( Icons.post_add_rounded ),
                            iconSize: 26, // Boyut biraz artırıldı
                            tooltip: 'Yeni Sayfa Ekle',
                            color: colorScheme.secondary,
                            padding: const EdgeInsets.all(10.0),
                            constraints: const BoxConstraints(),
                          ),
                        ),

                        const Spacer(), // Sol boşluk

                        // Orta: Kaydet Butonu
                        ElevatedButton(
                          onPressed: _saveEntry,
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 28, vertical: 12), // Padding biraz artırıldı
                            ),
                          ),
                          child: Text(
                            saveButtonText,
                            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),

                        const Spacer(), // Sağ boşluk

                        // Sağ: Mood Seçici
                        // ****** DEĞİŞİKLİK: Daha fazla padding ile görsel denge ******
                        Padding( // MoodSelector'a dıştan padding
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: MoodSelectorWidget(
                            initialMood: _selectedMood,
                            onMoodSelected: _handleMoodSelected,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}