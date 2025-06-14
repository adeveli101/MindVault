import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter/material.dart';

class MarkdownService {
  // Markdown'ı HTML'e dönüştürme
  String markdownToHtml(String markdown) {
    return md.markdownToHtml(
      markdown,
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
      ),
    );
  }

  // Markdown widget'ı oluşturma
  Widget buildMarkdownWidget(String markdown) {
    return Markdown(
      data: markdown,
      selectable: true,
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
      ),
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        p: const TextStyle(fontSize: 16),
        code: const TextStyle(
          backgroundColor: Color(0xFFF5F5F5),
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  // Markdown şablonları
  static const Map<String, String> templates = {
    'Günlük': '''# Günlük Girişi

## Bugün neler yaptım?

## Duygularım

## Yarın için planlarım

''',
    'Not': '''# Not

## Ana Başlık

- Madde 1
- Madde 2
- Madde 3

## Alt Başlık

1. Sıralı madde 1
2. Sıralı madde 2
3. Sıralı madde 3

''',
    'Fikir': '''# Fikir

## Açıklama

## Avantajlar
- 

## Dezavantajlar
- 

## Sonuç

''',
  };
} 