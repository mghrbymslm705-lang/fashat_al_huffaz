import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// مستخرج النصوص من ملفات وورد.
///
/// يدعم:
/// - `.docx`: حزمة ZIP تحتوي على word/document.xml (يُفكَّك ويُحلَّل).
/// - `.doc`: صيغة ثنائية قديمة (OLE2) — نستخرج النص العربي المخزّن
///   كتسلسلات UTF-16LE متواصلة، وهو نهج عملي ينجح مع أغلب ملفات وورد العربية.
/// - `.txt`: نص UTF-8 مباشر.
///
/// المخرَج: قائمة أسطر نصية (سطر ≈ فقرة) جاهزة للمعالجة اللاحقة.
class WordTextExtractor {
  WordTextExtractor._();

  /// يستخرج الأسطر النصية من ملف وورد حسب امتداده.
  static List<String> extract(String fileName, List<int> bytes) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.docx')) return extractDocx(bytes);
    if (name.endsWith('.doc')) return extractDoc(bytes);
    return extractPlainText(bytes);
  }

  // -------------------- docx --------------------

  /// قراءة نص مستند docx (ZIP + XML).
  static List<String> extractDocx(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docXml = archive.findFile('word/document.xml');
      if (docXml == null) return const [];

      final xml = utf8.decode(docXml.content as List<int>);
      final document = XmlDocument.parse(xml);

      final lines = <String>[];
      for (final para in document.findAllElements('w:p')) {
        final buffer = StringBuffer();
        for (final run in para.findAllElements('w:t')) {
          buffer.write(run.innerText);
          buffer.write(' ');
        }
        final line = buffer.toString().trim();
        if (line.isNotEmpty) lines.add(line);
      }
      return lines;
    } catch (_) {
      return const [];
    }
  }

  // -------------------- doc (OLE2 ثنائي) --------------------

  /// استخراج نص ملف doc قديم عبر مسح UTF-16LE.
  ///
  /// النص العربي في هذه الملفات يُخزَّن غالبًا كتسلسلات متتالية من
  /// وحدات UTF-16LE (حرفان لكل وحدة). نمسح البايتات ونبني أسطرًا من
  /// الأجزاء المتصلة من الحروف العربية والرموز القابلة للطباعة،
  /// مع قطع السطر عند فواصل الفقرات (\r أو \n أو \x0B).
  static List<String> extractDoc(List<int> bytes) {
    final lines = <String>[];
    final buffer = StringBuffer();
    var inRun = false;

    void flush() {
      if (inRun) {
        final line = _cleanLine(buffer.toString());
        if (line.isNotEmpty) lines.add(line);
        buffer.clear();
        inRun = false;
      }
    }

    // نقرأ بوحدات من 2 بايت (little-endian).
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final lo = bytes[i];
      final hi = bytes[i + 1];
      final code = lo | (hi << 8);

      final isArabic = _isArabicCode(code);
      final isAscii = (code >= 0x20 && code <= 0x7E);
      final isParagraphBreak =
          code == 0x0D || code == 0x0A || code == 0x0B || code == 0x0C;

      if (isParagraphBreak) {
        flush();
      } else if (isArabic || isAscii) {
        buffer.writeCharCode(code);
        inRun = true;
      } else {
        flush();
      }
    }
    flush();
    return lines;
  }

  /// هل الرمز عربي (الكتلة الأساسية + أشكال العرض)؟
  static bool _isArabicCode(int code) {
    return (code >= 0x0600 && code <= 0x06FF) ||
        (code >= 0xFB50 && code <= 0xFDFF) || // أشكال عرض A
        (code >= 0xFE70 && code <= 0xFEFF) || // أشكال عرض B
        (code >= 0x0750 && code <= 0x077F); // تكملة
  }

  /// تنظيف سطر: إزالة الروابط والرموز المشوّهة والحروف المتكررة بلا معنى.
  static String _cleanLine(String raw) {
    final s = raw.replaceAll(RegExp(r'HYPERLINK[^\s]*'), '').trim();
    if (s.isEmpty) return '';

    // نتجاهل السطور التي ليست عربية ولا تحتوي حروفًا مفيدة (رقام/رموز فقط).
    final arabicCount =
        s.codeUnits.where((c) => _isArabicCode(c)).length;
    final letterCount =
        s.codeUnits.where((c) => _isLetter(c)).length;
    if (arabicCount == 0 && letterCount == 0) return '';

    // دمج المسافات المكررة.
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _isLetter(int code) {
    return (code >= 0x0041 && code <= 0x005A) ||
        (code >= 0x0061 && code <= 0x007A);
  }

  // -------------------- نص عادي --------------------

  static List<String> extractPlainText(List<int> bytes) {
    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      try {
        text = latin1.decode(bytes);
      } catch (_) {
        return const [];
      }
    }
    return text
        .split(RegExp(r'\r\n|\r|\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }
}
