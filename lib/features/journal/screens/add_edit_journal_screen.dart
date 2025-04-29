import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // FontStyle için

// Kendi proje yollarınızı kullanın
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart'; // Mood enum'u hala emoji seçimi için kullanılabilir

// Özel ikonlar için (Yorumlarda belirtilecek)
// import 'package:mindvault/core/icons/mind_vault_icons.dart';

class AddEditJournalScreen extends StatefulWidget {
  final JournalEntry? entry; // Düzenleme için mevcut girdi

  const AddEditJournalScreen({super.key, this.entry});

  @override
  State<AddEditJournalScreen> createState() => _AddEditJournalScreenState();
}

class _AddEditJournalScreenState extends State<AddEditJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _contentController;
  // Başlık kaldırıldı
  // Mood state kaldırıldı (metne eklenecek)
  List<String> _tags = []; // Etiketler hala metadata olabilir
  bool _isFavorite = false; // Favori hala metadata olabilir
  DateTime _entryDate = DateTime.now(); // Girdinin tarihi (oluşturma/düzenleme anı)

  final FocusNode _contentFocusNode = FocusNode();
  final double _notebookPageMaxWidth = 600;
  final double _notebookPageVerticalPadding = 15.0;
  final double _notebookPageHorizontalPadding = 12.0;
  final ScrollController _scrollController = ScrollController(); // Uzun yazılarda kaydırma

  bool get _isEditing => widget.entry != null;

  // --- Stil Sabitleri (Daha sonra temadan gelecek) ---
  final Color _pageBackgroundColor = const Color(0xFFFFFDF9); // Daha açık kağıt
  final Color _pageBorderColor = Colors.grey.shade300;
  final Color _deskBackgroundColor = const Color(0xFFE0E0E0); // Açık gri masa
  final Color _primaryAccentColor = Colors.indigo.shade700; // Farklı vurgu
  final Color _secondaryAccentColor = Colors.pink.shade600; // Farklı ikincil vurgu
  final Color _baseTextColor = const Color(0xFF303030); // Koyu gri metin
  final String _decorativeFontFamily = 'DancingScript'; // Örnek dekoratif font (pubspec'a eklenmeli)
  final String _bodyFontFamily = 'Lato'; // Örnek gövde fontu (pubspec'a eklenmeli)
  // --- ---

  @override
  void initState() {
    super.initState();
    // Başlık yok
    _contentController = TextEditingController(text: widget.entry?.content ?? '');
    _tags = List<String>.from(widget.entry?.tags ?? []);
    _isFavorite = widget.entry?.isFavorite ?? false;
    _entryDate = widget.entry?.createdAt ?? _entryDate; // Düzenlemedeyse eski tarihi al
    // İçerik değiştiğinde rebuild tetikle (kelime sayacı vb. için)
    _contentController.addListener(() {
      if(mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Metne karakter/emoji ekleme fonksiyonu
  void _insertText(String textToInsert) {
    final currentText = _contentController.text;
    final selection = _contentController.selection;
    final newText = currentText.replaceRange(selection.start, selection.end, textToInsert);
    // İmleci eklenen metnin sonuna taşı
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + textToInsert.length),
    );
    // Ekledikten sonra içerik alanına odaklan
    FocusScope.of(context).requestFocus(_contentFocusNode);
  }

  // Emoji seçme dialogunu gösterir (Basit örnek)
  void _showEmojiPicker() {
    // Gerçek uygulamada daha gelişmiş bir emoji picker paketi kullanılabilir
    // örn: emoji_picker_flutter
    showModalBottomSheet(
      context: context,
      builder: (context) => GridView.count(
        crossAxisCount: 8,
        children: ['😀', '😂', '😍', '🤔', '😢', '😠', '👍', '🙏', '🎉', '❤️', '✨', '✏️']
            .map((emoji) => IconButton(
          icon: Text(emoji, style: const TextStyle(fontSize: 24)),
          onPressed: () {
            _insertText(emoji);
            Navigator.pop(context); // Dialogu kapat
          },
        ))
            .toList(),
      ),
    );
  }

  // Mood'a karşılık gelen emojiyi seçme dialogunu gösterir
  void _showMoodEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: Mood.values.where((m) => m != Mood.unknown).map((mood) {
          final emoji = _getEmojiForMood(mood); // Mood'a karşılık gelen emoji
          return ListTile(
            leading: Text(emoji, style: const TextStyle(fontSize: 24)),
            title: Text(_getMoodDisplayName(mood)),
            onTap: () {
              _insertText(' $emoji '); // Başına ve sonuna boşluk ekle
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _saveEntry() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      // Başlık olmadığı için content'in bir kısmını başlık gibi kullanabiliriz (isteğe bağlı)
      // String impliedTitle = _contentController.text.length > 30
      //     ? '${_contentController.text.substring(0, 30)}...'
      //     : _contentController.text;

      final journalEntry = JournalEntry(
        id: widget.entry?.id,
        title: null, // Başlık yok
        content: _contentController.text.trim(),
        createdAt: _isEditing ? widget.entry!.createdAt : _entryDate, // Oluşturma tarihini koru
        updatedAt: now, // Güncelleme tarihi her zaman şimdiki zaman
        mood: null, // Ayrı mood metadatası yok (metin içinde)
        tags: _tags.isNotEmpty ? List<String>.from(_tags) : null,
        isFavorite: _isFavorite,
      );

      if (_isEditing) {
        context.read<JournalBloc>().add(UpdateJournalEntry(journalEntry));
      } else {
        context.read<JournalBloc>().add(AddJournalEntry(journalEntry));
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final notebookWidth = (screenSize.width - 2 * _notebookPageHorizontalPadding)
        .clamp(0.0, _notebookPageMaxWidth);

    return Scaffold(
      backgroundColor: _deskBackgroundColor,
      resizeToAvoidBottomInset: true, // Klavye açılınca ekranı yeniden boyutlandır
      appBar: _buildAppBar(), // Basitleştirilmiş AppBar
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Container(
            width: notebookWidth,
            margin: EdgeInsets.only(
              top: _notebookPageVerticalPadding,
              // Klavye görünürlüğünü kontrol et ve ona göre boşluk ayarla
              bottom: MediaQuery.of(context).viewInsets.bottom > 0
                  ? MediaQuery.of(context).viewInsets.bottom // Klavye yüksekliği kadar
                  : _notebookPageVerticalPadding, // Normal boşluk
            ),
            decoration: _buildNotebookPageDecoration(), // Sayfa görünümü
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Column(
                children: [
                  // Sayfa içeriği (Kaydırılabilir)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                      child: Stack( // Üstteki elemanları konumlandırmak için
                        children: [
                          // Ana Metin Giriş Alanı (Stack'in en altında)
                          _buildContentArea(),

                          // Tarih/Saat (Sol Üst)
                          _buildDateTimeDisplay(),

                          // Emoji/Mood Butonları (Sağ Üst)
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                  // Alt Toolbar (Kelime Sayacı vb.)
                  _buildBottomInfoBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- AppBar ---
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text( // Geri butonuna daha çok yer bırakmak için başlığı ortala
        _isEditing ? 'Düzenle' : 'Yeni Girdi',
        style: TextStyle(fontFamily: _bodyFontFamily, fontSize: 18, color: _baseTextColor),
      ),
      centerTitle: true, // Başlığı ortala
      backgroundColor: _deskBackgroundColor, // Masa rengiyle aynı
      elevation: 0,
      foregroundColor: _baseTextColor.withOpacity(0.8),
      iconTheme: IconThemeData(color: _baseTextColor.withOpacity(0.8)),
      actions: [
        // Favori butonu AppBar'da kalabilir
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.bookmark : Icons.bookmark_border,
            color: _isFavorite ? _secondaryAccentColor : _baseTextColor.withOpacity(0.6),
          ),
          tooltip: 'Favorilere Ekle/Kaldır',
          onPressed: () => setState(() => _isFavorite = !_isFavorite),
        ),
        // Kaydet butonu
        IconButton(
          icon: Icon(Icons.check_rounded, color: _primaryAccentColor, size: 28),
          tooltip: 'Kaydet',
          onPressed: _saveEntry,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- Defter Sayfası Görünümü ---
  BoxDecoration _buildNotebookPageDecoration() {
    // Tema entegrasyonunda bu asset yolu dinamik olacak
    // String pageTexturePath = currentTheme.pageBackgroundAssetPath;
    String pageTexturePath = 'assets/pages/clean_paper.png'; // Placeholder

    return BoxDecoration(
      color: _pageBackgroundColor,
      // image: DecorationImage(image: AssetImage(pageTexturePath), fit: BoxFit.cover), // Asset varsa
      borderRadius: BorderRadius.circular(8.0), // Daha az yuvarlak köşe
      border: Border.all(color: _pageBorderColor.withOpacity(0.5), width: 1.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // --- Tarih/Saat Gösterimi (Sol Üst) ---
  Widget _buildDateTimeDisplay() {
    return Positioned(
      top: 8.0,
      left: 0.0,
      child: Text(
        DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(_entryDate),
        style: TextStyle(
          fontFamily: _decorativeFontFamily, // Dekoratif font
          fontStyle: FontStyle.italic,
          fontSize: 15,
          color: _baseTextColor.withOpacity(0.6),
        ),
      ),
    );
  }

  // --- Emoji/Mood Butonları (Sağ Üst) ---
  Widget _buildActionButtons() {
    return Positioned(
      top: 0.0,
      right: 0.0,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.mood_rounded, // Veya MindVaultIcons.mood
              color: _primaryAccentColor.withOpacity(0.8),
              size: 26,
            ),
            tooltip: 'Ruh Hali Ekle',
            onPressed: _showMoodEmojiPicker, // Mood emojilerini göster
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(), // Butonun kendi padding'ini kaldır
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.emoji_emotions_outlined, // Veya MindVaultIcons.emoji
              color: _primaryAccentColor.withOpacity(0.8),
              size: 26,
            ),
            tooltip: 'Emoji Ekle',
            onPressed: _showEmojiPicker, // Emoji klavyesini göster
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // --- Ana İçerik Alanı ---
  Widget _buildContentArea() {
    // Çizgili defter görünümü için CustomPainter (isteğe bağlı)
    // final linesPainter = _JournalLinesPainter(
    //   lineColor: _pageBorderColor.withOpacity(0.3),
    //   lineSpacing: 26.0, // Font boyutuna göre ayarla
    // );

    return Padding(
      // Üstteki tarih ve butonlara yer açmak için padding
      padding: const EdgeInsets.only(top: 45.0),
      child: Form( // Formu buraya taşıdık
        key: _formKey,
        child: Scrollbar( // Uzun yazılarda kaydırma çubuğu
          controller: _scrollController,
          thumbVisibility: true, // Her zaman görünür yapabiliriz
          child: CustomPaint( // Çizgileri çizmek için
            // foregroundPainter: linesPainter, // Çizgi çizerini etkinleştir
            child: TextFormField(
              controller: _contentController,
              focusNode: _contentFocusNode,
              scrollController: _scrollController, // TextFormField'un kendi kaydırmasını kullan
              style: TextStyle(
                fontFamily: _bodyFontFamily,
                fontSize: 16,
                color: _baseTextColor,
                height: 1.65, // Çizgi aralığı ile uyumlu
              ),
              decoration: const InputDecoration(
                hintText: '...', // Hint kaldırılabilir veya soluklaştırılabilir
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero, // İç padding yok
              ),
              maxLines: null, // Sınırsız satır
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'İçerik boş olamaz.'; // Hata mesajı gizlenebilir veya farklı gösterilebilir
                }
                return null;
              },
              // Hata mesajını göstermek için farklı bir yöntem gerekebilir
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
        ),
      ),
    );
  }

  // --- Alt Bilgi Çubuğu ---
  Widget _buildBottomInfoBar() {
    int wordCount = _contentController.text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    if (_contentController.text.trim().isEmpty) wordCount = 0; // Boşsa 0 yap

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _pageBorderColor.withOpacity(0.3), width: 0.8)),
        color: _pageBackgroundColor.withOpacity(0.9),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // Sağa yasla
        children: [
          Text(
            '$wordCount Kelime',
            style: TextStyle(
              fontSize: 11,
              color: _baseTextColor.withOpacity(0.6),
              fontFamily: _bodyFontFamily,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }


  // --- Helper Metotlar ---
  String _getEmojiForMood(Mood mood) {
    // Mood enum'una karşılık gelen temel emojiler
    switch (mood) {
      case Mood.happy: return '😊';
      case Mood.sad: return '😢';
      case Mood.neutral: return '😐';
      case Mood.excited: return '🎉';
      case Mood.anxious: return '😟';
      case Mood.calm: return '😌';
      case Mood.angry: return '😠';
      case Mood.grateful: return '🙏';
      case Mood.stressed: return '😥';
      case Mood.tired: return '😴';
      case Mood.unknown:
      default: return '?';
    }
  }

  String _getMoodDisplayName(Mood mood) {
    switch (mood) {
      case Mood.happy: return 'Mutlu';
      case Mood.sad: return 'Üzgün';
      case Mood.neutral: return 'Nötr';
      case Mood.excited: return 'Heyecanlı';
      case Mood.anxious: return 'Endişeli';
      case Mood.calm: return 'Sakin';
      case Mood.angry: return 'Kızgın';
      case Mood.grateful: return 'Minnettar';
      case Mood.stressed: return 'Stresli';
      case Mood.tired: return 'Yorgun';
      case Mood.unknown:
      default: return 'Bilinmiyor';
    }
  }
}


// İsteğe Bağlı: Çizgili Defter Görünümü için CustomPainter
class _JournalLinesPainter extends CustomPainter {
  final Color lineColor;
  final double lineSpacing;

  _JournalLinesPainter({required this.lineColor, required this.lineSpacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    // Üstten başlayarak çizgileri çiz
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Sol kenar çizgisi (isteğe bağlı, kırmızı olabilir)
    final marginPaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(30, 0), Offset(30, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // Çizgiler değişmiyorsa tekrar çizmeye gerek yok
  }
}