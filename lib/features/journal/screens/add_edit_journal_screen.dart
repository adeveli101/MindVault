// lib/features/journal/screens/add_edit_journal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
import 'package:uuid/uuid.dart';

// Proje içindeki ilgili dosyaları import et
import 'package:mindvault/features/journal/bloc/journal_bloc.dart';
import 'package:mindvault/features/journal/model/journal_entry.dart'; //
import 'package:mindvault/features/journal/widgets/mood_selector_widget.dart'; // Mood seçici widget'ı

class AddEditJournalScreen extends StatefulWidget {
  final JournalEntry? editingEntry; //

  const AddEditJournalScreen({
    super.key,
    this.editingEntry,
  });

  @override
  State<AddEditJournalScreen> createState() => _AddEditJournalScreenState();
}

class _AddEditJournalScreenState extends State<AddEditJournalScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  Mood? _selectedMood; //
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool get _isEditing => widget.editingEntry != null;

  // Cilt (spine) genişliği - Ayarlanabilir
  final double _spineWidth = 70.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.editingEntry?.title);
    _contentController = TextEditingController(text: widget.editingEntry?.content);
    _selectedMood = widget.editingEntry?.mood; //
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final now = DateTime.now();
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      try {
        if (_isEditing) {
          final updatedEntry = widget.editingEntry!.copyWith(
            title: title,
            content: content,
            mood: _selectedMood, //
            updatedAt: now,
          );
          context.read<JournalBloc>().add(UpdateJournalEntry(updatedEntry));
        } else {
          final newEntry = JournalEntry( //
            id: const Uuid().v4(),
            title: title,
            content: content,
            mood: _selectedMood, //
            createdAt: now,
            updatedAt: now,
          );
          context.read<JournalBloc>().add(AddJournalEntry(newEntry));
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Günlük güncellendi!' : 'Günlük kaydedildi!')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kaydedilirken bir hata oluştu: $e')),
          );
        }
      } finally {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return ThemedBackground(
      applyOverlay: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. Bölüm: Ana İçerik Alanı (Cilt hariç)
            Positioned(
              left: _spineWidth,
              top: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                left: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: 40.0, left: 20.0, right: 20.0, bottom: 80.0, // FAB için altta daha fazla boşluk
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Tarih ---
                        Text(
                          DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(widget.editingEntry?.createdAt ?? DateTime.now()),
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // --- Başlık ---
                        TextFormField(
                          controller: _titleController,
                          style: textTheme.headlineSmall?.copyWith(
                            fontFamily: 'Cinzel Decorative', // Font ailesi
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Başlık',
                            hintStyle: textTheme.headlineSmall?.copyWith(
                              fontFamily: 'Cinzel Decorative',
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 15),

                        // --- İçerik ---
                        TextFormField(
                          controller: _contentController,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontStyle: FontStyle.italic, height: 1.7,
                          ),
                          maxLines: null, keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: 'Bugün neler oldu?...',
                            hintStyle: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                            border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Günlük içeriği boş bırakılamaz.';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Bölüm: Sol Cilt ve Mood Seçici (DÜZELTİLDİ)
            Positioned(
              left: 6.5,
              top: 10,
              bottom: 0,
              width: _spineWidth,
              child: Container(
                color: Colors.black.withOpacity(0),
                // Padding'i SingleChildScrollView içine alabiliriz veya burada bırakabiliriz.
                // padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: SafeArea(
                  right: false,
                  child: SingleChildScrollView( // <-- YENİ: Kaydırma eklendi
                    child: Padding( // <-- YENİ: İçeriğe padding vermek için
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 4.0), // Yatay padding de ekleyelim
                      child: Column(
                        // mainAxisAlignment: MainAxisAlignment.center, // <-- Kaldırıldı (veya start yapılabilir)
                        // Artık Column scroll edilebildiği için ortalamaya gerek yok, yukarıdan başlasın.
                        children: [
                          // Mood Seçici
                          // Not: MoodSelectorWidget'in dikey ve dar alanda
                          // iyi görünmesi için ayarlanması yine de önerilir.
                          MoodSelectorWidget( //
                            initialMood: _selectedMood, //
                            onMoodSelected: (mood) {
                              setState(() {
                                _selectedMood = mood; //
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Bölüm: Kaydet Butonu
            Positioned(
              bottom: 15,
              right: 15,
              child: FloatingActionButton.extended(
                onPressed: _isLoading ? null : _saveEntry,
                label: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Kaydet'),
                icon: _isLoading ? null : const Icon(Icons.check_rounded),
              ),
            ),

            // 4. Bölüm: Geri Butonu
            Positioned(
              top: 720,
              left: 20,
              child: SafeArea(
                bottom: false, right: false,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new,
                      color: colorScheme.inversePrimary.withOpacity(0.8)), // Rengi biraz soluk yapabiliriz
                  tooltip: 'Geri',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}