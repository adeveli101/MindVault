// lib/features/journal/widgets/mood_selector_widget.dart (Popover Paketini Kullanarak Yeniden Yazıldı)

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:popover/popover.dart'; // Popover paketi import edildi
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// İkon paketleri için öneri (pubspec.yaml'a ekleyip import edin)
// import 'package:iconsax/iconsax.dart';
// import 'package:line_awesome_flutter/line_awesome_flutter.dart';

// Model import (Yolu kontrol edin)
import 'package:mindvault/features/journal/model/journal_entry.dart';

/// Kullanıcının bir ruh hali seçmesini sağlayan, dokunulduğunda matris şeklinde
/// açılır pencere (popover) gösteren widget.
class MoodSelectorWidget extends StatefulWidget {
  final Mood? initialMood;
  final ValueChanged<Mood?> onMoodSelected;
  final double buttonSize; // Ana buton boyutu
  final double popoverWidth; // Açılır pencere genişliği
  final int gridCrossAxisCount; // Matris sütun sayısı
  final double gridItemSize; // Matris içindeki her bir mood ikonunun boyutu
  final double gridSpacing; // Matris elemanları arası boşluk
  final IconData defaultIcon; // Seçim yokken gösterilecek ikon

  const MoodSelectorWidget({
    super.key,
    this.initialMood,
    required this.onMoodSelected,
    this.buttonSize = 42.0,
    this.popoverWidth = 150.0, // 3'lü grid için yaklaşık genişlik
    this.gridCrossAxisCount = 4,
    this.gridItemSize = 30.0,
    this.gridSpacing = 8.0,
    this.defaultIcon = Icons.add_reaction_outlined,
    // Alternatif: Iconsax.emoji_happy, LineAwesomeIcons.smiling_face,
  });

  @override
  State<MoodSelectorWidget> createState() => _MoodSelectorWidgetState();
}

class _MoodSelectorWidgetState extends State<MoodSelectorWidget> {
  Mood? _selectedMood;

  // Mood ikonları (Material veya eklenen paketlerden ikonlar kullanılabilir)
  // Öneri: Daha çeşitli ikonlar için bir ikon paketi kullanın.

  final Map<Mood, IconData> moodIcons = {
    // Pozitif Duygular
    Mood.happy: FontAwesomeIcons.faceSmile, // Mutlu
    Mood.excited: FontAwesomeIcons.bolt, // Heyecanlı, enerjik
    Mood.ecstatic: FontAwesomeIcons.star, // Coşkulu, çok mutlu
    Mood.grateful: FontAwesomeIcons.handsPraying, // Minnettar
    Mood.peaceful: FontAwesomeIcons.dove, // Huzurlu
    Mood.calm: FontAwesomeIcons.spa, // Sakin
    Mood.content: FontAwesomeIcons.faceSmileBeam, // Memnun, tatmin olmuş
    Mood.confident: FontAwesomeIcons.crown, // Özgüvenli
    Mood.inspired: FontAwesomeIcons.lightbulb, // İlham almış
    Mood.hopeful: FontAwesomeIcons.seedling, // Umutlu

    // Nötr Duygular
    Mood.neutral: FontAwesomeIcons.faceMeh, // Nötr
    Mood.contemplative: FontAwesomeIcons.brain, // Düşünceli
    Mood.curious: FontAwesomeIcons.magnifyingGlass, // Meraklı
    Mood.focused: FontAwesomeIcons.bullseye, // Odaklanmış
    Mood.indifferent: FontAwesomeIcons.faceRollingEyes, // Kayıtsız
    Mood.nostalgic: FontAwesomeIcons.clockRotateLeft, // Nostaljik

    // Negatif Duygular
    Mood.sad: FontAwesomeIcons.faceSadTear, // Üzgün
    Mood.melancholic: FontAwesomeIcons.cloudRain, // Hüzünlü, melankolik
    Mood.anxious: FontAwesomeIcons.personCircleExclamation, // Endişeli
    Mood.stressed: FontAwesomeIcons.fire, // Stresli
    Mood.overwhelmed: FontAwesomeIcons.volcano, // Bunalmış
    Mood.tired: FontAwesomeIcons.batteryQuarter, // Yorgun
    Mood.exhausted: FontAwesomeIcons.bed, // Bitkin
    Mood.angry: FontAwesomeIcons.faceAngry, // Kızgın
    Mood.frustrated: FontAwesomeIcons.personBurst, // Hayal kırıklığına uğramış
    Mood.jealous: FontAwesomeIcons.eye, // Kıskanç
    Mood.guilty: FontAwesomeIcons.scaleUnbalanced, // Suçlu
    Mood.embarrassed: FontAwesomeIcons.faceDizzy, // Mahcup, utanmış
    Mood.bored: FontAwesomeIcons.faceMehBlank, // Sıkılmış

    // Karma Duygular
    Mood.bittersweet: FontAwesomeIcons.yinYang, // Tatlı-acı
    Mood.amused: FontAwesomeIcons.faceGrinWide, // Eğlenmiş
    Mood.awed: FontAwesomeIcons.solidStar, // Hayran kalmış
    Mood.determined: FontAwesomeIcons.personWalking, // Kararlı
    Mood.vulnerable: FontAwesomeIcons.heartCrack, // Savunmasız

    // Fizyolojik Duygular
    Mood.hungry: FontAwesomeIcons.utensils, // Aç
    Mood.energetic: FontAwesomeIcons.batteryFull, // Enerjik
    Mood.sleepy: FontAwesomeIcons.moon, // Uykulu
    Mood.refreshed: FontAwesomeIcons.shower, // Tazelenmiş

    // Diğer
    Mood.unknown: FontAwesomeIcons.circleQuestion, // Bilinmeyen
    Mood.creative: FontAwesomeIcons.wandMagicSparkles, // Yaratıcı
    Mood.motivated: FontAwesomeIcons.rocket, // Motive olmuş
    Mood.inLove: FontAwesomeIcons.heartPulse, // Aşık
    Mood.generous: FontAwesomeIcons.gift, // Cömert
    Mood.proud: FontAwesomeIcons.medal, // Gururlu
  };



  // Gösterilecek mood listesi (Unknown hariç)
  late List<Mood> _allDisplayMoods;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood;
    _allDisplayMoods = Mood.values.where((m) => m != Mood.unknown).toList();
  }

  @override
  void didUpdateWidget(covariant MoodSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMood != oldWidget.initialMood) {
      if (mounted) {
        setState(() {
          _selectedMood = widget.initialMood;
        });
      }
    }
  }

  // --- Tema ve Renk Yardımcıları ---

// Tooltip için mood isimleri (Türkçeleştirilebilir)
  String _getMoodName(Mood mood) {
    switch (mood) {
    // Pozitif Duygular
      case Mood.happy: return "Mutlu";
      case Mood.excited: return "Heyecanlı";
      case Mood.ecstatic: return "Coşkulu";
      case Mood.grateful: return "Minnettar";
      case Mood.peaceful: return "Huzurlu";
      case Mood.calm: return "Sakin";
      case Mood.content: return "Memnun";
      case Mood.confident: return "Özgüvenli";
      case Mood.inspired: return "İlham Almış";
      case Mood.hopeful: return "Umutlu";

    // Nötr Duygular
      case Mood.neutral: return "Nötr";
      case Mood.contemplative: return "Düşünceli";
      case Mood.curious: return "Meraklı";
      case Mood.focused: return "Odaklanmış";
      case Mood.indifferent: return "Kayıtsız";
      case Mood.nostalgic: return "Nostaljik";

    // Negatif Duygular
      case Mood.sad: return "Üzgün";
      case Mood.melancholic: return "Melankolik";
      case Mood.anxious: return "Endişeli";
      case Mood.stressed: return "Stresli";
      case Mood.overwhelmed: return "Bunalmış";
      case Mood.tired: return "Yorgun";
      case Mood.exhausted: return "Bitkin";
      case Mood.angry: return "Kızgın";
      case Mood.frustrated: return "Hayal Kırıklığına Uğramış";
      case Mood.jealous: return "Kıskanç";
      case Mood.guilty: return "Suçlu";
      case Mood.embarrassed: return "Mahcup";
      case Mood.bored: return "Sıkılmış";
      case Mood.confused: return "Kafası Karışık";

    // Karma Duygular
      case Mood.bittersweet: return "Tatlı-Acı";
      case Mood.amused: return "Eğlenmiş";
      case Mood.surprised: return "Şaşırmış";
      case Mood.awed: return "Hayran";
      case Mood.determined: return "Kararlı";
      case Mood.vulnerable: return "Savunmasız";
      case Mood.reflective: return "Düşünceli";

    // Fizyolojik Duygular
      case Mood.hungry: return "Aç";
      case Mood.energetic: return "Enerjik";
      case Mood.sleepy: return "Uykulu";
      case Mood.refreshed: return "Tazelenmiş";

    // Diğer
      case Mood.unknown: return "Bilinmiyor";
      case Mood.creative: return "Yaratıcı";
      case Mood.motivated: return "Motive Olmuş";
      case Mood.inLove: return "Aşık";
      case Mood.generous: return "Cömert";
      case Mood.proud: return "Gururlu";
      case Mood.relieved: return "Rahatlamış";
    }
  }

  Color _getColorForMood(Mood mood, ColorScheme colorScheme) {
    switch (mood) {
    // Pozitif Duygular
      case Mood.happy: return Colors.amber.shade600;
      case Mood.excited: return Colors.orange.shade600;
      case Mood.ecstatic: return Colors.orange.shade800; // Daha yoğun turuncu
      case Mood.grateful: return Colors.pink.shade300;
      case Mood.peaceful: return Colors.teal.shade200; // Açık mavi-yeşil
      case Mood.calm: return colorScheme.secondary;
      case Mood.content: return Colors.lightGreen.shade400; // Açık yeşil
      case Mood.confident: return Colors.amber.shade800; // Koyu amber
      case Mood.inspired: return Colors.deepPurple.shade300; // Mor
      case Mood.hopeful: return Colors.lightGreen.shade600; // Yeşil

    // Nötr Duygular
      case Mood.neutral: return colorScheme.onSurfaceVariant;
      case Mood.contemplative: return Colors.blueGrey.shade400; // Mavi-gri
      case Mood.curious: return Colors.cyan.shade400; // Açık mavi
      case Mood.focused: return Colors.indigo.shade400; // Koyu mavi
      case Mood.indifferent: return Colors.grey.shade400; // Gri
      case Mood.nostalgic: return Colors.amber.shade200; // Açık amber

    // Negatif Duygular
      case Mood.sad: return Colors.blue.shade600;
      case Mood.melancholic: return Colors.blue.shade800; // Koyu mavi
      case Mood.anxious: return Colors.purple.shade300;
      case Mood.stressed: return colorScheme.error;
      case Mood.overwhelmed: return Colors.deepPurple.shade900; // Çok koyu mor
      case Mood.tired: return Colors.brown.shade400;
      case Mood.exhausted: return Colors.brown.shade700; // Koyu kahverengi
      case Mood.angry: return colorScheme.errorContainer;
      case Mood.frustrated: return Colors.deepOrange.shade700; // Koyu turuncu
      case Mood.jealous: return Colors.green.shade900; // Koyu yeşil
      case Mood.guilty: return Colors.deepPurple.shade700; // Koyu mor
      case Mood.embarrassed: return Colors.pink.shade400; // Pembe
      case Mood.bored: return Colors.grey.shade500; // Gri
      case Mood.confused: return Colors.amber.shade300; // Açık amber

    // Karma Duygular
      case Mood.bittersweet: return Colors.deepOrange.shade300; // Turuncu
      case Mood.amused: return Colors.lime.shade400; // Açık yeşil
      case Mood.surprised: return Colors.purple.shade200; // Açık mor
      case Mood.awed: return Colors.indigo.shade300; // Mavi
      case Mood.determined: return Colors.red.shade500; // Kırmızı
      case Mood.vulnerable: return Colors.pink.shade200; // Açık pembe
      case Mood.reflective: return Colors.blueGrey.shade300; // Açık mavi-gri

    // Fizyolojik Duygular
      case Mood.hungry: return Colors.amber.shade700; // Koyu amber
      case Mood.energetic: return Colors.yellow.shade700; // Sarı
      case Mood.sleepy: return Colors.indigo.shade100; // Çok açık mavi
      case Mood.refreshed: return Colors.lightBlue.shade400; // Açık mavi

    // Diğer
      case Mood.unknown: return colorScheme.outline;
      case Mood.creative: return Colors.purple.shade400; // Mor
      case Mood.motivated: return Colors.red.shade300; // Kırmızı
      case Mood.inLove: return Colors.pink.shade500; // Koyu pembe
      case Mood.generous: return Colors.deepPurple.shade200; // Açık mor
      case Mood.proud: return Colors.indigo.shade500; // Koyu mavi
      case Mood.relieved: return Colors.teal.shade300; // Açık yeşil-mavi
    }
  }


  Color _getOnColorForMood(Color moodColor, BuildContext context) {
    // (Önceki koddan aynı mantık kullanılabilir)
    final Brightness colorBrightness = ThemeData.estimateBrightnessForColor(moodColor);
    return colorBrightness == Brightness.dark ? Colors.white : Colors.black;
  }

  // --- Popover İçeriği Oluşturucular ---

  /// Popover içinde gösterilecek matris (grid) yapısını oluşturur.
  Widget _buildMoodGrid(BuildContext popoverContext) {
    // Popover context'inden tema alınabilir, ancak ana context'ten almak daha güvenli olabilir.
    final theme = Theme.of(context);

    // GridView yüksekliğini hesapla (satır sayısı * eleman yüksekliği + boşluklar)
    final rowCount = (_allDisplayMoods.length / widget.gridCrossAxisCount).ceil();
    final gridHeight = rowCount * widget.gridItemSize + (rowCount -1) * widget.gridSpacing + 16; // + Dış padding

    return Container(
      width: widget.popoverWidth,
      height: gridHeight, // Hesaplanan yükseklik
      padding: const EdgeInsets.all(8.0), // Grid etrafına padding
      child: GridView.builder(
        padding: EdgeInsets.zero, // GridView'ın kendi padding'ini sıfırla
        itemCount: _allDisplayMoods.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.gridCrossAxisCount,
          crossAxisSpacing: widget.gridSpacing,
          mainAxisSpacing: widget.gridSpacing,
        ),
        itemBuilder: (context, index) {
          final mood = _allDisplayMoods[index];
          return _buildMoodGridItem(mood, theme, popoverContext);
        },
      ),
    );
  }

  /// Matris içindeki tek bir mood ikonunu oluşturur.
  Widget _buildMoodGridItem(Mood mood, ThemeData theme, BuildContext popoverContext) {
    final colorScheme = theme.colorScheme;
    final Color moodColor = _getColorForMood(mood, colorScheme);
    final Color bgColor = moodColor.withOpacity(0.15);
    final Color iconColor = moodColor;
    final IconData iconData = moodIcons[mood] ?? Icons.sentiment_neutral; // Fallback ikon
    final String moodName = _getMoodName(mood);

    return Tooltip(
      message: moodName,
      child: InkWell(
        onTap: () {
          if (mounted) {
            setState(() {
              _selectedMood = mood; // Ana butonu güncelle
            });
          }
          widget.onMoodSelected(_selectedMood); // Dışarıya bildir
          Navigator.pop(popoverContext); // Popover'ı kapat
        },
        borderRadius: BorderRadius.circular(widget.gridItemSize / 2), // Yuvarlak yap
        splashColor: moodColor.withOpacity(0.3),
        highlightColor: moodColor.withOpacity(0.2),
        child: Container(
          width: widget.gridItemSize,
          height: widget.gridItemSize,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle, // Tamamen yuvarlak
          ),
          child: Center(
            child: Icon(
              iconData,
              size: widget.gridItemSize * 0.55, // İkon boyutu, item boyutuna oranlı
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  // --- Ana Buton Oluşturucu ---

  /// Popover'ı açan ana butonu oluşturur.
  Widget _buildMainButton(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final bool isSelected = _selectedMood != null;
    final l10n = AppLocalizations.of(context)!;

    final IconData currentIcon;
    final Color buttonBgColor;
    final Color iconFgColor;
    final String tooltipText;

    if (isSelected) {
      currentIcon = moodIcons[_selectedMood!] ?? widget.defaultIcon;
      buttonBgColor = _getColorForMood(_selectedMood!, colorScheme);
      iconFgColor = _getOnColorForMood(buttonBgColor, context);
      tooltipText = _getMoodName(_selectedMood!);
    } else {
      currentIcon = widget.defaultIcon;
      buttonBgColor = colorScheme.surfaceContainerHighest.withOpacity(0.7);
      iconFgColor = colorScheme.onSurfaceVariant;
      tooltipText = l10n.selectMood;
    }

    // Kenarlık rengi seçiliyken mood rengi, değilken outline
    final Color borderColor = isSelected ? buttonBgColor.withOpacity(0.8) : colorScheme.outline.withOpacity(0.5);

    return Tooltip(
      message: tooltipText,
      child: GestureDetector( // InkWell yerine GestureDetector kullandık, popover'ı tetiklemek için
        onTap: () {
          // Popover'ı göster
          showPopover(
            context: context, // Bu context, main button'ın context'i olmalı
            bodyBuilder: (popoverContext) => _buildMoodGrid(popoverContext),
            // ----- Popover Ayarları -----
            direction: PopoverDirection.bottom, // Tercih edilen yön (otomatik ayarlayabilir)
            // Açılır pencere genişliğini widget parametresinden al
            width: widget.popoverWidth,
            // Yüksekliği içerik belirleyecek (Grid'den hesaplandı)
            // height: gridHeight, // VEYA bodyBuilder'a bırakılabilir
            arrowHeight: 10, // Ok yüksekliği
            arrowWidth: 20, // Ok genişliği
            backgroundColor: colorScheme.surfaceContainerHigh, // Popover arkaplan rengi
            barrierColor: colorScheme.scrim.withOpacity(0.5), // Arkadaki karartma
            radius: 12, // Popover köşe yuvarlaklığı
            // Diğer ayarlar: transitionDuration, constraints, arrowDxOffset, vb.
            transitionDuration: const Duration(milliseconds: 200),
          );
        },
        child: Container( // Tıklanabilir alan
          width: widget.buttonSize,
          height: widget.buttonSize,
          decoration: BoxDecoration(
            color: buttonBgColor, // Renk geçişi artık yok, anlık değişim
            // shape: BoxShape.circle, // Tam yuvarlak ana buton
            borderRadius: BorderRadius.circular(widget.buttonSize / 2),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [ BoxShadow( color: buttonBgColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)) ]
                : [ BoxShadow( color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)) ],
          ),
          child: Center(
            child: Icon(
              currentIcon,
              size: widget.buttonSize * 0.55, // İkon boyutu, buton boyutuna oranlı
              color: iconFgColor,
            ),
          ),
        ),
      ),
    );
  }

  // --- Ana Build Metodu ---
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Builder widget'ı, Popover'ın doğru context'i almasını sağlar
    return Builder(
      builder: (buttonContext) {
        return _buildMainButton(buttonContext, theme);
      },
    );
  }
}