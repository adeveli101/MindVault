// ignore_for_file: use_build_context_synchronously, unused_local_variable, unused_field

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mindvault/features/journal/services/drawing_service.dart';
import 'package:mindvault/features/journal/screens/themes/themed_background.dart';
import 'package:mindvault/features/journal/screens/themes/theme_config.dart';
import 'package:mindvault/features/journal/screens/themes/app_theme_data.dart';
import 'package:mindvault/features/journal/screens/themes/notebook_theme_type.dart';

class DrawingScreen extends StatefulWidget {
  final String? initialDrawingData;
  final Function(String) onSave;

  const DrawingScreen({
    super.key,
    this.initialDrawingData,
    required this.onSave,
  });

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<Path> _paths = [];
  final List<Color> _pathColors = [];
  final List<double> _pathWidths = [];
  Path? _currentPath;
  late Color _currentColor;
  double _strokeWidth = 5.0;
  bool _isEraser = false;
  final DrawingService _drawingService = DrawingService();
  late AppThemeData _currentTheme;
  bool _isUndoEnabled = false;
  bool _isRedoEnabled = false;
  final List<List<Path>> _undoStack = [];
  final List<List<Color>> _undoColors = [];
  final List<List<double>> _undoWidths = [];
  final List<List<Path>> _redoStack = [];
  final List<List<Color>> _redoColors = [];
  final List<List<double>> _redoWidths = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialDrawingData != null) {
      _loadInitialDrawing();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mevcut temayı al
    _currentTheme = ThemeConfig.getAppThemeDataByIndex(
      ThemeConfig.getIndexByThemeType(Theme.of(context).brightness == Brightness.light 
        ? NotebookThemeType.defaultLightMedium 
        : NotebookThemeType.defaultDarkMedium)
    );
    // Tema rengini varsayılan çizim rengi olarak ayarla
    if (!_isEraser) {
      _currentColor = Theme.of(context).colorScheme.primary;
    }
  }

  Future<void> _loadInitialDrawing() async {
    final image = await _drawingService.base64ToDrawing(widget.initialDrawingData!);
    // TODO: Base64'ten çizim verilerini yükle
    }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final toolbarWidth = screenWidth * 0.85;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.drawing),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        leading: const SizedBox(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 40.0, top: 20.0, bottom: 50.0),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.save, color: colorScheme.onSurfaceVariant),
                tooltip: l10n.save,
                onPressed: _saveDrawing,
                iconSize: 24,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Tema Arka Planı
          const ThemedBackground(
            applyOverlay: false,
            child: SizedBox(),
          ),
          // Ana İçerik
          SafeArea(
            child: Column(
              children: [
                // Çizim Alanı
                Expanded(
                  child: Center(
                    child: Container(
                      width: toolbarWidth,
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onPanStart: (details) {
                            setState(() {
                              _currentPath = Path();
                              _currentPath!.moveTo(details.localPosition.dx, details.localPosition.dy);
                              _paths.add(_currentPath!);
                              _pathColors.add(_isEraser ? Colors.transparent : _currentColor);
                              _pathWidths.add(_strokeWidth);
                            });
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              _currentPath!.lineTo(details.localPosition.dx, details.localPosition.dy);
                            });
                          },
                          onPanEnd: (details) {
                            setState(() {
                              _currentPath = null;
                              _undoStack.add(List.from(_paths));
                              _undoColors.add(List.from(_pathColors));
                              _undoWidths.add(List.from(_pathWidths));
                              _isUndoEnabled = true;
                              _isRedoEnabled = false;
                            });
                          },
                          child: CustomPaint(
                            painter: DrawingPainter(
                              paths: _paths,
                              pathColors: _pathColors,
                              pathWidths: _pathWidths,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Alt Araç Çubuğu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest.withOpacity(0.9),
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: toolbarWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Üst Araç Çubuğu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Geri Al
                              IconButton(
                                icon: Icon(
                                  Icons.undo,
                                  color: _isUndoEnabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                ),
                                tooltip: l10n.undo,
                                onPressed: _isUndoEnabled ? _undo : null,
                              ),
                              // İleri Al
                              IconButton(
                                icon: Icon(
                                  Icons.redo,
                                  color: _isRedoEnabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                ),
                                tooltip: l10n.redo,
                                onPressed: _isRedoEnabled ? _redo : null,
                              ),
                              // Renk Seçici
                              IconButton(
                                icon: Icon(Icons.color_lens, color: _currentColor),
                                tooltip: l10n.selectColor,
                                onPressed: _showColorPicker,
                              ),
                              // Silgi
                              IconButton(
                                icon: Icon(
                                  Icons.auto_fix_high,
                                  color: _isEraser ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                ),
                                tooltip: l10n.eraser,
                                onPressed: () {
                                  setState(() {
                                    _isEraser = !_isEraser;
                                    if (_isEraser) {
                                      _currentColor = Colors.transparent;
                                    } else {
                                      _currentColor = colorScheme.primary;
                                    }
                                  });
                                },
                              ),
                              // Temizle
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: colorScheme.onSurfaceVariant),
                                tooltip: l10n.clear,
                                onPressed: _clearCanvas,
                              ),
                            ],
                          ),
                          // Kalınlık Ayarı
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Icon(Icons.line_weight, color: colorScheme.onSurfaceVariant),
                                Expanded(
                                  child: Slider(
                                    value: _strokeWidth,
                                    min: 1.0,
                                    max: 20.0,
                                    activeColor: colorScheme.primary,
                                    inactiveColor: colorScheme.primaryContainer,
                                    onChanged: (value) {
                                      setState(() {
                                        _strokeWidth = value;
                                      });
                                    },
                                  ),
                                ),
                                Text(
                                  '${_strokeWidth.toInt()}',
                                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectColor),
        backgroundColor: colorScheme.surface,
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _currentColor,
            onColorChanged: (color) {
              setState(() {
                _currentColor = color;
                _isEraser = false;
              });
            },
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            labelTypes: const [],
            paletteType: PaletteType.hsv,
            pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok, style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _undo() {
    if (_paths.isNotEmpty) {
      setState(() {
        _redoStack.add(List.from(_paths));
        _redoColors.add(List.from(_pathColors));
        _redoWidths.add(List.from(_pathWidths));
        _paths.clear();
        _pathColors.clear();
        _pathWidths.clear();
        if (_undoStack.isNotEmpty) {
          _paths.addAll(_undoStack.removeLast());
          _pathColors.addAll(_undoColors.removeLast());
          _pathWidths.addAll(_undoWidths.removeLast());
        }
        _isUndoEnabled = _undoStack.isNotEmpty;
        _isRedoEnabled = _redoStack.isNotEmpty;
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _undoStack.add(List.from(_paths));
        _undoColors.add(List.from(_pathColors));
        _undoWidths.add(List.from(_pathWidths));
        _paths.clear();
        _pathColors.clear();
        _pathWidths.clear();
        _paths.addAll(_redoStack.removeLast());
        _pathColors.addAll(_redoColors.removeLast());
        _pathWidths.addAll(_redoWidths.removeLast());
        _isUndoEnabled = _undoStack.isNotEmpty;
        _isRedoEnabled = _redoStack.isNotEmpty;
      });
    }
  }

  void _clearCanvas() {
    if (_paths.isNotEmpty) {
      setState(() {
        _undoStack.add(List.from(_paths));
        _undoColors.add(List.from(_pathColors));
        _undoWidths.add(List.from(_pathWidths));
        _paths.clear();
        _pathColors.clear();
        _pathWidths.clear();
        _isUndoEnabled = true;
        _isRedoEnabled = false;
      });
    }
  }

  Future<void> _saveDrawing() async {
    if (_paths.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final base64Data = await _drawingService.drawingToBase64(
      _paths,
      _pathColors,
      _pathWidths,
      Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
    );

    if (base64Data != null) {
      Navigator.pop(context, base64Data);
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<Path> paths;
  final List<Color> pathColors;
  final List<double> pathWidths;

  DrawingPainter({
    required this.paths,
    required this.pathColors,
    required this.pathWidths,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < paths.length; i++) {
      final paint = Paint()
        ..color = pathColors[i]
        ..strokeWidth = pathWidths[i]
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(paths[i], paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return true;
  }
} 