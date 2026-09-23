import 'package:html/parser.dart' show parseFragment;

/// Klartext aus dem HTML der Meldung: Absätze als Zeilen, Entities aufgelöst.
String? htmlToText(String? html) {
  if (html == null || html.trim().isEmpty) return null;
  final doc = parseFragment(html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>|</li>|</div>', caseSensitive: false), '\n'));
  final text = doc.text ?? '';
  return text
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((l) => l.isNotEmpty)
      .join('\n');
}
