// lib/features/journal/screens/entry/add_edit_journal_screen.dart
// Etiket UI Chip'lere dönüştürüldü, Kaydedilmemiş Değişiklik Uyarısı eklendi.

// ignore_for_file: use_build_context_synchronously, unused_local_variable

// listEquals için
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // listEquals için
import 'dart:io';

// BLoC, Model ve Widget yolları
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart';
import 'package:mindvault/features/journal/screens/drawing_screen.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
import 'package:mindvault/features/journal/screens/widgets/mood_selector_widget.dart';
import 'package:mindvault/features/journal/services/drawing_service.dart';
import 'package:mindvault/features/journal/services/markdown_service.dart';
import 'package:mindvault/features/journal/services/media_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class AddEditJournalScreen extends StatefulWidget {
  final JournalEntry? existingEntry;

  const AddEditJournalScreen({super.key, this.existingEntry});

  @override
  State<AddEditJournalScreen> createState() => _AddEditJournalScreenState();
}

class _AddEditJournalScreenState extends State<AddEditJournalScreen> {
  // Sayfa Yönetimi
  final PageController _pageController = PageController();
  final List<TextEditingController> _pageControllers = [];

  // Etiket Yönetimi
  final TextEditingController _newTagController = TextEditingController();
  final FocusNode _newTagFocusNode = FocusNode();
  List<String> _currentTags = []; // Mevcut etiketleri tutan liste (state)

  // Diğer State'ler
  Mood? _selectedMood;
  late DateTime _displayDate;
  bool get _isEditing => widget.existingEntry != null;

  // Kaydedilmemiş değişiklik kontrolü için başlangıç değerleri
  String _initialContent = '';
  List<String> _initialTags = [];
  Mood? _initialMood;
  bool _hasUnsavedChanges = false; // Değişiklik bayrağı

  // Yeni servisler
  final MediaService _mediaService = MediaService();
  final MarkdownService _markdownService = MarkdownService();
  final DrawingService _drawingService = DrawingService();

  // Yeni state'ler
  bool _isMarkdownMode = false;
  List<MediaItem> _currentMediaItems = [];
  String? _currentDrawingData;

  @override
  void initState() {
    super.initState();
    _displayDate = widget.existingEntry?.createdAt ?? DateTime.now();
    _selectedMood = widget.existingEntry?.mood;
    // Başlangıç etiketlerini kopyalayarak al (referans tip sorununu önlemek için)
    _currentTags = List<String>.from(widget.existingEntry?.tags ?? []);

    // Mevcut girdinin içeriğini yükle ve başlangıç değerlerini ayarla
    if (_isEditing && widget.existingEntry != null) {
      // TODO: İçerik çok uzunsa ve '\n\n' ile bölünmüşse sayfalara ayırma eklenebilir.
      // Şimdilik tüm içeriği ilk sayfaya yüklüyoruz.
      _addPageController(text: widget.existingEntry!.content);
      _initialContent = widget.existingEntry!.content; // Başlangıç içeriğini kaydet
      _initialTags = List<String>.from(_currentTags); // Başlangıç etiketlerini kaydet (kopya)
      _initialMood = _selectedMood; // Başlangıç mood'unu kaydet
      _currentMediaItems = List<MediaItem>.from(widget.existingEntry!.mediaItems ?? []);
      _currentDrawingData = widget.existingEntry!.drawingData;
      _isMarkdownMode = widget.existingEntry!.isMarkdown;
    } else {
      _addPageController(); // Yeni girdi için boş sayfa
      // Başlangıç değerleri varsayılanlar
      _initialContent = '';
      _initialTags = [];
      _initialMood = null;
    }

    // Değişiklikleri dinlemek için listener'lar ekle
    // Çoklu sayfa yönetimi eklendiğinde tüm controller'lar için listener eklenmeli.
    for (var controller in _pageControllers) {
      controller.addListener(_checkForChanges);
    }
    // _newTagController için listener gerekmez, ekleme anında kontrol edilir.
    // Mood seçimi _handleMoodSelected içinde kontrol edilir.
  }

  /// Yeni içerik sayfası için controller ekler ve listener atar.
  void _addPageController({String text = ''}) {
    final controller = TextEditingController(text: text);
    // Yeni eklenen controller için de listener ekle
    controller.addListener(_checkForChanges);
    _pageControllers.add(controller);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _newTagController.dispose();
    _newTagFocusNode.dispose();
    // Listener'ları kaldır ve controller'ları dispose et
    for (var controller in _pageControllers) {
      controller.removeListener(_checkForChanges);
      controller.dispose();
    }
    super.dispose();
  }

  // --- Değişiklik Kontrolü ---

  /// İçerikte, etiketlerde veya mood'da değişiklik olup olmadığını kontrol eder.
  void _checkForChanges() {
    // Tüm sayfa içeriklerini birleştir
    final currentContent = _pageControllers.map((c) => c.text).join('\n\n');
    // Listeleri karşılaştırırken ListEquality kullanmak en güvenlisidir
    final tagsChanged = !const ListEquality().equals(_currentTags, _initialTags);
    final contentChanged = currentContent != _initialContent;
    final moodChanged = _selectedMood != _initialMood;

    final changed = tagsChanged || contentChanged || moodChanged;

    // Sadece state farklıysa ve widget hala ağaçtaysa güncelle
    // (Gereksiz setState çağrılarını önler)
    if (_hasUnsavedChanges != changed && mounted) {
      setState(() {
        _hasUnsavedChanges = changed;
      });
    }
  }

  // --- Etiket İşlemleri ---

  /// Yeni etiket ekleme alanından etiket ekler.
  void _addNewTag() {
    final String newTag = _newTagController.text.trim();
    // Boş değilse ve zaten listede yoksa (büyük/küçük harf duyarsız) ekle
    if (newTag.isNotEmpty && !_currentTags.any((t) => t.toLowerCase() == newTag.toLowerCase())) {
      if (mounted) {
        setState(() {
          _currentTags.add(newTag); // State listesine ekle
        });
        _newTagController.clear(); // Metin alanını temizle
        _checkForChanges(); // Değişiklik kontrolünü tetikle
      }
    } else {
      _newTagController.clear(); // Boşsa veya zaten varsa yine temizle
    }
    // Odağı kaybetmek isteğe bağlıdır:
    // _newTagFocusNode.unfocus();
  }

  /// Belirtilen etiketi listeden kaldırır.
  void _removeTag(String tagToRemove) {
    if (mounted) {
      setState(() {
        _currentTags.remove(tagToRemove); // State listesinden kaldır
      });
      _checkForChanges(); // Değişiklik kontrolünü tetikle
    }
  }

  // --- Diğer İşlemler ---

  /// Mood seçildiğinde state'i günceller ve değişiklik kontrolü yapar.
  void _handleMoodSelected(Mood? newMood) {
    if (mounted) {
      setState(() { _selectedMood = newMood; });
      _checkForChanges(); // Mood değişince de kontrol et
    }
  }

  /// Günlük girdisini kaydeder veya günceller.
  Future<void> _saveEntry() async {
    // İçeriği birleştir
    final combinedContent = _pageControllers.map((c) => c.text.trim()).where((text) => text.isNotEmpty).join('\n\n');

    // İçerik boş kontrolü
    if (combinedContent.isEmpty) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.journalContentEmpty, style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    final entryId = widget.existingEntry?.id;
    // Etiketleri state listesinden al (boşsa null yap)
    final List<String>? tags = _currentTags.isNotEmpty ? List.from(_currentTags) : null;

    // Yeni veya güncellenmiş girdiyi oluştur
    final entry = JournalEntry(
      id: entryId,
      content: combinedContent,
      createdAt: _isEditing ? widget.existingEntry!.createdAt : now,
      updatedAt: now,
      mood: _selectedMood,
      tags: tags,
      isFavorite: widget.existingEntry?.isFavorite ?? false,
      mediaItems: _currentMediaItems.isNotEmpty ? List.from(_currentMediaItems) : null,
      drawingData: _currentDrawingData,
      isMarkdown: _isMarkdownMode,
    );

    // BLoC'a kaydetme/güncelleme olayını gönder
    if (_isEditing) {
      context.read<JournalBloc>().add(UpdateJournalEntry(entry));
    } else {
      context.read<JournalBloc>().add(AddJournalEntry(entry));
    }

    // Başarılı kayıt sonrası değişiklik bayrağını sıfırla
    if (mounted) {
      setState(() {
        _hasUnsavedChanges = false;
        _initialContent = combinedContent;
        _initialTags = List.from(_currentTags);
        _initialMood = _selectedMood;
      });
    }

    // Kullanıcıya geri bildirim ver
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? l10n.journalUpdated : l10n.journalSaved),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Yeni içerik sayfası ekler.
  void _addNewPage() {
    if (mounted) {
      final newController = TextEditingController();
      newController.addListener(_checkForChanges); // Listener ekle
      setState(() { _pageControllers.add(newController); });
      // Yeni sayfaya animasyonla git
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.animateToPage(
              _pageControllers.length - 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut
          );
        }
      });
      // Yeni sayfa eklenince de değişiklik kontrolü yap
      _checkForChanges();
    }
  }

  /// Geri gitme denendiğinde onay iletişim kutusunu gösterir.
  Future<bool> _showDiscardDialog() async {
    // Eğer değişiklik yoksa direkt true dön (çıkışa izin ver)
    if (!_hasUnsavedChanges) {
      return true;
    }
    // Değişiklik varsa dialog göster
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Dışarı tıklayarak kapatmayı engelle
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.discardChangesTitle),
        content: Text(AppLocalizations.of(context)!.discardChangesContent),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.discard, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    // Kullanıcı bir seçim yaparsa (true/false) onu döndür, yapmazsa (null) false döndür (çıkışı engelle)
    return result ?? false;
  }

  // Medya ekleme metodları
  Future<void> _addImage() async {
    final mediaItem = await _mediaService.pickImage();
    if (mediaItem != null && mounted) {
      setState(() {
        _currentMediaItems.add(mediaItem);
      });
      _checkForChanges();
    }
  }

  Future<void> _addVideo() async {
    final mediaItem = await _mediaService.pickVideo();
    if (mediaItem != null && mounted) {
      setState(() {
        _currentMediaItems.add(mediaItem);
      });
      _checkForChanges();
    }
  }

  Future<void> _addAudio() async {
    final mediaItem = await _mediaService.pickAudio();
    if (mediaItem != null && mounted) {
      setState(() {
        _currentMediaItems.add(mediaItem);
      });
      _checkForChanges();
    }
  }

  void _removeMediaItem(MediaItem item) {
    setState(() {
      _currentMediaItems.remove(item);
    });
    _checkForChanges();
  }

  // Çizim metodları
  void _startDrawing() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingScreen(
          initialDrawingData: _currentDrawingData,
          onSave: (drawingData) {
            setState(() {
              _currentDrawingData = drawingData;
            });
          },
        ),
      ),
    );
  }

  // Markdown metodları
  void _toggleMarkdownMode() {
    setState(() {
      _isMarkdownMode = !_isMarkdownMode;
    });
    _checkForChanges();
  }

  // Şablon seçimi
  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectTemplate),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: MarkdownService.templates.length,
            itemBuilder: (context, index) {
              final template = MarkdownService.templates.entries.elementAt(index);
              return ListTile(
                title: Text(template.key),
                onTap: () {
                  if (_pageControllers.isNotEmpty) {
                    _pageControllers[0].text = template.value;
                    _checkForChanges();
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Build Metodu ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;
    final String saveButtonText = _isEditing ? l10n.update : l10n.save;

    // Stiller
    final headerTextStyle = textTheme.headlineMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w500);
    final contentTextStyle = textTheme.bodyMedium?.copyWith(height: 1.5, color: colorScheme.onSurface);
    final infoTextStyle = textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.8));
    final tagInputLabelStyle = textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant); // Etiket TextField stili
    final tagChipLabelStyle = textTheme.bodySmall?.copyWith(fontSize: 11); // Chip etiket boyutu

    // PopScope: Geri gitme denemesini yakalar
    return PopScope(
      canPop: !_hasUnsavedChanges, // Değişiklik yoksa direkt pop edilebilir
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // Eğer canPop=false olduğu için pop engellendiyse (didPop=false)
        if (didPop) return;
        // Geri gitme engellendiyse (değişiklik var), dialogu göster
        final shouldPop = await _showDiscardDialog();
        // *** DÜZELTME: use_build_context_synchronously uyarısı için mounted kontrolü ***
        if (shouldPop && mounted) {
          Navigator.pop(context); // Dialog onaylarsa pop et
        }
      },
      child: ThemedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true, // Klavye açılınca boyutlandır
          appBar: AppBar(
            backgroundColor: Colors.transparent, elevation: 0,
            leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.appBarTheme.iconTheme?.color ?? colorScheme.onSurface),
                tooltip: l10n.back,
                // Geri butonuna basıldığında da onay mekanizmasını tetikle
                onPressed: () async {
                  if (await _showDiscardDialog()) { // Önce onayı al
                    if (mounted) Navigator.pop(context); // Onaylanırsa çık
                  }
                }
            ),
            // İsteğe bağlı: Kaydet butonu AppBar'da
            // actions: [ Padding( padding: const EdgeInsets.only(right: 12.0), child: TextButton(onPressed: _hasUnsavedChanges ? _saveEntry : null, child: Text(saveButtonText)), ) ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Üst Kısım: Tarih
                Padding(
                  padding: const EdgeInsets.fromLTRB(40.0, 5.0, 40.0, 15.0),
                  child: Text(
                    DateFormat('dd MMMM, EEEE HH:mm', l10n.localeName).format(_displayDate),
                    textAlign: TextAlign.center,
                    style: headerTextStyle,
                  ),
                ),

                // Zengin İçerik Araç Çubuğu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Markdown Modu
                        IconButton(
                          icon: Icon(
                            Icons.code,
                            color: _isMarkdownMode 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          tooltip: l10n.markdownMode,
                          onPressed: _toggleMarkdownMode,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 32,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _isMarkdownMode 
                                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                : null,
                          ),
                        ),
                        // Şablonlar
                        IconButton(
                          icon: Icon(
                            Icons.description_outlined,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          tooltip: l10n.templates,
                          onPressed: _showTemplateDialog,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 32,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        // Medya Araçları
                        IconButton(
                          icon: Icon(
                            Icons.image_outlined,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          tooltip: l10n.addImage,
                          onPressed: _addImage,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 32,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.videocam_outlined,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          tooltip: l10n.addVideo,
                          onPressed: _addVideo,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 32,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.audio_file_outlined,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          tooltip: l10n.addAudio,
                          onPressed: _addAudio,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 32,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        // Çizim Aracı
                        IconButton(
                          icon: Icon(
                            Icons.draw_outlined,
                            color: _currentDrawingData != null 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          tooltip: l10n.draw,
                          onPressed: _startDrawing,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 32,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _currentDrawingData != null 
                                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // İçerik Alanı
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pageControllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 16.0),
                        child: _isMarkdownMode
                            ? Column(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _pageControllers[index],
                                      maxLines: null,
                                      expands: true,
                                      style: contentTextStyle,
                                      textAlign: TextAlign.justify,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        filled: false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerLowest.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: _markdownService.buildMarkdownWidget(_pageControllers[index].text),
                                    ),
                                  ),
                                ],
                              )
                            : TextField(
                                controller: _pageControllers[index],
                                maxLines: null,
                                expands: true,
                                style: contentTextStyle,
                                textAlign: TextAlign.justify,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  filled: false,
                                ),
                              ),
                      );
                    },
                  ),
                ),

                // Medya Önizleme Alanı
                if (_currentMediaItems.isNotEmpty)
                  Container(
                    height: 80, // %20 küçültme (100'den 80'e)
                    padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 8.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _currentMediaItems.length,
                      itemBuilder: (context, index) {
                        final item = _currentMediaItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            children: [
                              Container(
                                width: 64, // %20 küçültme (80'den 64'e)
                                height: 64, // %20 küçültme (80'den 64'e)
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: item.type == MediaType.image
                                      ? Image.file(File(item.path), fit: BoxFit.cover)
                                      : item.type == MediaType.video && item.thumbnailPath != null
                                          ? Image.file(File(item.thumbnailPath!), fit: BoxFit.cover)
                                          : Icon(
                                              item.type == MediaType.audio
                                                  ? Icons.audio_file
                                                  : Icons.video_file,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () => _removeMediaItem(item),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // Çizim Önizleme
                if (_currentDrawingData != null)
                  Container(
                    height: 80, // %20 küçültme (100'den 80'e)
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: FutureBuilder<Image>(
                      future: _drawingService.base64ToDrawing(_currentDrawingData!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: snapshot.data,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),

                // --- Etiket Alanı (Chip'ler ve Ekleme - Kompakt) ---
                Padding(
                    padding: const EdgeInsets.fromLTRB(35.0, 0.0, 35.0, 5.0), // Dikey padding azaltıldı
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mevcut Etiketler (Scrollable Wrap)
                        if (_currentTags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 60), // Maksimum yükseklik
                              child: Scrollbar( // Dikey kaydırma çubuğu (taşarsa)
                                thumbVisibility: true, // Her zaman görünür (isteğe bağlı)
                                child: SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 6.0, runSpacing: 2.0, // runSpacing ayarlandı
                                    children: _currentTags.map((tag) => InputChip(
                                      label: Text(tag),
                                      labelStyle: tagChipLabelStyle, // Daha küçük font
                                      onDeleted: () => _removeTag(tag), // Silme işlevi
                                      deleteIconColor: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                      deleteIcon: const Icon(Icons.cancel_rounded, size: 16), // İkon boyutu
                                      backgroundColor: colorScheme.surfaceContainer.withOpacity(0.7),
                                      shape: StadiumBorder(side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4))),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                      visualDensity: const VisualDensity(horizontal: 0.0, vertical: -2), // Daha sıkışık
                                    )).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Yeni Etiket Ekleme Alanı
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newTagController,
                                focusNode: _newTagFocusNode,
                                style: tagInputLabelStyle,
                                decoration: InputDecoration(
                                  hintText: l10n.newTagHint,
                                  hintStyle: tagInputLabelStyle?.copyWith(color: theme.hintColor.withOpacity(0.7)),
                                  isDense: true,
                                  border: InputBorder.none,
                                  // Sol padding ile imleci sağa kaydır
                                  contentPadding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0), // Dikey padding ayarlandı
                                ),
                                onSubmitted: (_) => _addNewTag(), // Enter ile ekle
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline_rounded, size: 22, color: colorScheme.primary),
                              onPressed: _addNewTag,
                              tooltip: l10n.addTag,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 6), // Padding ayarlandı
                            )
                          ],
                        ),
                        Divider(height: 0.5, thickness: 0.5, color: colorScheme.outlineVariant.withOpacity(0.5)), // Ayırıcı çizgi
                      ],
                    )
                ),
                // --- Etiket Alanı Sonu ---

                // --- Alt Kısım: Gösterge, Bilgi ve Kontroller ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 15.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sayfa Göstergesi
                      SizedBox(
                        height: 15,
                        child: (_pageControllers.length > 1)
                            ? SmoothPageIndicator(
                            controller: _pageController,
                            count: _pageControllers.length,
                            effect: ScrollingDotsEffect(
                                dotHeight: 6, dotWidth: 6, activeDotScale: 1.5,
                                activeDotColor: colorScheme.primary,
                                dotColor: colorScheme.onSurface.withOpacity(0.3)
                            )
                        )
                            : const SizedBox(height: 15), // Tek sayfaysa da aynı yüksekliği kapla
                      ),
                      // Son Güncelleme Bilgisi
                      if (_isEditing && widget.existingEntry != null && widget.existingEntry!.updatedAt.isAfter(widget.existingEntry!.createdAt))
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                          child: Text(
                            l10n.lastUpdated(DateFormat('dd MMMM, HH:mm', l10n.localeName).format(widget.existingEntry!.updatedAt)),
                            style: infoTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        )
                      else // Yeni eklemede veya gösterge yoksa boşluk
                        const SizedBox(height: 12.0),

                      // Kontrol Butonları
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Sol: Sayfa Ekle Butonu
                          Padding( padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child:
                              IconButton(
                                  onPressed: _addNewPage,
                                  icon: const
                                  Icon(
                                      Icons.post_add_rounded ), iconSize: 28,
                                  tooltip: l10n.addPage,
                                  color: colorScheme.inverseSurface.withOpacity(0.7),
                                  padding: const EdgeInsets.all(10.0),
                                  constraints: const BoxConstraints())),
                          const Spacer(),
                          // Orta: Kaydet Butonu
                          ElevatedButton.icon(
                            icon: Icon(_isEditing ? Icons.check_circle_outline_rounded : Icons.save_alt_rounded, size: 18),
                            label: Text(saveButtonText),
                            // Değişiklik yapılmadıysa butonu pasif yap (isteğe bağlı)
                            onPressed: _hasUnsavedChanges || !_isEditing ? _saveEntry : null,
                            style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                          ),
                          const Spacer(),
                          // Sağ: Mood Seçici
                          Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0), child: MoodSelectorWidget( initialMood: _selectedMood, onMoodSelected: _handleMoodSelected)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}