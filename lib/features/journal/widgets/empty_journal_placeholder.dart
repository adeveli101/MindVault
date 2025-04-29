import 'package:flutter/material.dart';

/// Günlük listesi boş olduğunda gösterilecek olan yer tutucu widget.
/// Kullanıcıya bilgi verir ve yeni girdi eklemeye teşvik eder.
class EmptyJournalPlaceholder extends StatelessWidget {
  const EmptyJournalPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // Temadan renkleri ve metin stillerini alalım
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Center(
      child: Padding(
        // Kenarlardan biraz boşluk bırakalım
        padding: const EdgeInsets.all(32.0),
        child: Column(
          // Ortala
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. İkon: Konuyla ilgili hoş bir ikon
            Icon(
              Icons.auto_stories_outlined, // Veya Icons.edit_note, Icons.sentiment_satisfied_alt
              size: 80.0,
              // Temanın ikincil rengini veya yüzey renginin üzerindeki rengi hafif opaklıkla kullan
              color: colorScheme.secondary.withOpacity(0.7), // Veya onSurface.withOpacity(0.5)
            ),
            const SizedBox(height: 24.0), // İkon ile metin arasına boşluk

            // 2. Ana Mesaj: Dikkat çekici ama bunaltıcı olmayan bir stil
            Text(
              'Zihin Kasası Boş', // Veya "Henüz Günlük Yok"
              textAlign: TextAlign.center,
              // Temadan gelen başlık stilini kullanalım (Cinzel veya Cabin)
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12.0), // Ana mesaj ile alt mesaj arasına boşluk

            // 3. Açıklayıcı/Teşvik Edici Mesaj
            Text(
              "İlk düşüncelerinizi, hislerinizi veya gününüzü kaydetmek için aşağıdaki '+' düğmesine dokunun.",
              textAlign: TextAlign.center,
              // Temadan gelen gövde metni stilini kullanalım (Cabin)
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.5, // Satır yüksekliği
              ),
            ),
            const SizedBox(height: 40.0), // Alt mesaj ile potansiyel diğer öğeler arasına boşluk
            // İsteğe bağlı: Belki buraya direkt bir "Ekle" butonu da konulabilir?
            // ElevatedButton.icon(
            //   onPressed: () {
            //     // TODO: Yeni ekleme ekranına gitme eylemini tetikle (BLoC event veya Navigator)
            //   },
            //   icon: Icon(Icons.add),
            //   label: Text("İlk Girdiyi Oluştur"),
            // )
          ],
        ),
      ),
    );
  }
}