import '../../models/document_item.dart';

/// Smart Categories — automatically organizes documents into intelligent
/// collections (Work / Study / Personal / Others) using on-device heuristics
/// over titles, tags and OCR text. Fully offline & deterministic.
class SmartCategories {
  static const List<String> names = ['Work', 'Study', 'Personal', 'Others'];

  static const Map<String, List<String>> _keywords = {
    'Work': ['invoice', 'contract', 'proposal', 'business', 'report', 'meeting', 'agenda', 'salary', 'payroll', 'client', 'vendor', 'receipt', 'tax', 'budget', 'project', 'agreement', 'offer', 'resume', 'cv'],
    'Study': ['study', 'lecture', 'notes', 'chapter', 'exam', 'assignment', 'thesis', 'research', 'syllabus', 'homework', 'course', 'university', 'school', 'class', 'tutorial'],
    'Personal': ['personal', 'passport', 'id card', 'identity', 'license', 'licence', 'medical', 'prescription', 'family', 'photo', 'letter', 'bank', 'utility', 'bill', 'insurance', 'card'],
  };

  static String categorize(DocumentItem doc) {
    final haystack = '${doc.title} ${doc.tags.join(' ')} ${doc.ocrText ?? ''}'.toLowerCase();
    for (final name in const ['Work', 'Study', 'Personal']) {
      for (final kw in _keywords[name]!) {
        if (haystack.contains(kw)) return name;
      }
    }
    return 'Others';
  }

  static Map<String, List<DocumentItem>> group(List<DocumentItem> docs) {
    final map = {for (final n in names) n: <DocumentItem>[]};
    for (final d in docs) {
      map[categorize(d)]!.add(d);
    }
    return map;
  }

  static List<DocumentItem> filter(List<DocumentItem> docs, String category) {
    if (category == 'All' || !names.contains(category)) return docs;
    return docs.where((d) => categorize(d) == category).toList();
  }
}
