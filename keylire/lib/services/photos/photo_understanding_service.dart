import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../data/db/database.dart';
import '../nutrition/nutrition_service.dart';

/// Every photo gets a description, a key hint, any readable text, and a
/// food recognition on every device, offline. Nutrition needs a serving and confirmation.
///
/// Floor (all devices): ML Kit image labelling (400+ labels, small model
/// bundled at install) + ML Kit text recognition for screenshots, boards,
/// receipts, timetables.
/// Top (flagships with AICore / Apple Intelligence): platform image
/// description via [PlatformCaptioner], if a plugin is wired. When absent
/// or unsupported, the floor's result stands - nobody sees a gap.
///
/// Cloud vision is not part of this service. If it ever returns it is a
/// separate opt-in that runs AFTER this, never instead of it.
class PhotoUnderstandingService {
  PhotoUnderstandingService(this.db, {this.captioner});

  final AppDatabase db;
  final PlatformCaptioner? captioner;

  final _labeler =
      ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.55));
  final _ocr = TextRecognizer(script: TextRecognitionScript.latin);

  Future<PhotoUnderstanding> understand(File image) async {
    final input = InputImage.fromFile(image);
    List<ImageLabel> labels = const [];
    String ocr = '';
    try {
      labels = await _labeler.processImage(input);
    } catch (_) {}
    try {
      final t = await _ocr.processImage(input);
      ocr = t.text.trim();
    } catch (_) {}

    final names = labels.map((l) => l.label.toLowerCase()).toList();
    final kind = _kind(names, ocr);
    final keyHint = _keyHint(kind, names, ocr);

    String description = _describe(kind, names, ocr);
    if (captioner != null) {
      try {
        final c = await captioner!.describe(image);
        if (c != null && c.trim().isNotEmpty) description = c.trim();
      } catch (_) {}
    }

    return PhotoUnderstanding(
      kind: kind,
      description: description,
      labels: names.take(6).toList(),
      text: ocr.isEmpty ? null : ocr,
      keyHint: keyHint,
    );
  }

  /// Write the result onto the event: description becomes the line unless
  /// the user typed one; labels/text/kcal go to metadata.
  Future<void> applyToEvent(int eventId, PhotoUnderstanding u,
      {required bool keepUserText}) async {
    final initial = await db.eventById(eventId);
    final path = initial?.photoPath;
    final signature =
        path == null ? null : await NutritionService.signature(File(path));
    final suggestion = signature == null
        ? null
        : await NutritionService(db).suggestPhoto(signature);
    await db.transaction(() async {
      final e = await db.eventById(eventId);
      if (e == null || e.deletedAt != null) return;
      final meta = <String, dynamic>{};
      if (e.metadata != null && e.metadata!.isNotEmpty) {
        try {
          meta.addAll(jsonDecode(e.metadata!) as Map<String, dynamic>);
        } catch (_) {}
      }
      meta['ai_pending'] = false;
      meta['photo_kind'] = u.kind;
      meta['photo_labels'] = u.labels;
      if (u.text != null) {
        meta['ocr'] = u.text!.length > 600 ? u.text!.substring(0, 600) : u.text;
      }
      if (signature != null) meta['food_signature'] = signature;
      if (meta['nutrition_source'] == null) {
        if (suggestion != null) meta['meal_suggestion'] = suggestion['id'];
        if (u.kind == 'food' || suggestion != null) {
          meta['nutrition_needs_review'] = true;
        }
      }
      await db.updateEvent(
          eventId,
          EventsCompanion(
            rawText: keepUserText ||
                    e.editedAt != null ||
                    meta['nutrition_source'] != null
                ? const Value.absent()
                : Value(u.description),
            metadata: Value(jsonEncode(meta)),
          ));
    });
  }

  void dispose() {
    _labeler.close();
    _ocr.close();
  }

  // ------------------------------------------------------------ rules

  static const _food = {
    'food',
    'dish',
    'meal',
    'cuisine',
    'breakfast',
    'lunch',
    'dinner',
    'snack',
    'dessert',
    'pizza',
    'bread',
    'rice',
    'noodle',
    'pasta',
    'salad',
    'soup',
    'curry',
    'burger',
    'sandwich',
    'fruit',
    'vegetable',
    'cake',
    'cookie',
    'coffee',
    'tea',
    'drink',
    'juice',
    'egg',
    'chicken',
    'meat',
    'fish',
    'seafood',
    'cheese',
    'chocolate',
    'ice cream',
    'plate',
    'bowl',
    'cup',
    'tableware'
  };
  static const _screen = {
    'screenshot',
    'text',
    'font',
    'document',
    'paper',
    'receipt',
    'poster',
    'menu',
    'ticket',
    'website',
    'software',
    'monitor',
    'invoice',
    'bill'
  };
  static const _gym = {
    'gym',
    'fitness',
    'exercise',
    'dumbbell',
    'barbell',
    'treadmill',
    'weights',
    'sports',
    'running',
    'yoga',
    'workout',
    'training'
  };
  static const _place = {
    'building',
    'street',
    'road',
    'city',
    'landscape',
    'beach',
    'mountain',
    'sky',
    'tree',
    'park',
    'architecture',
    'room',
    'interior',
    'restaurant',
    'cafe',
    'shop',
    'store',
    'vehicle',
    'car',
    'nature'
  };
  static const _study = {
    'book',
    'notebook',
    'writing',
    'handwriting',
    'whiteboard',
    'classroom',
    'library',
    'pen',
    'stationery',
    'desk',
    'paper',
    'notes'
  };

  static String kindTest(List<String> l, String ocr) => _kind(l, ocr);
  static String? keyHintTest(String kind, List<String> l, [String? ocr]) =>
      _keyHint(kind, l, ocr);
  static String describeTest(String kind, List<String> l, String ocr) =>
      _describe(kind, l, ocr);

  static String _kind(List<String> l, String ocr) {
    int hits(Set<String> s) =>
        l.where((x) => s.any((k) => x.contains(k))).length;
    final f = hits(_food),
        s = hits(_screen),
        g = hits(_gym),
        p = hits(_place),
        st = hits(_study);
    if (ocr.length > 50 && (s > 0 || f == 0)) return 'screenshot';
    final best = {
      'food': f,
      'gym': g,
      'study': st,
      'place': p,
      'screenshot': s
    };
    final top = best.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return top.value == 0
        ? (ocr.isNotEmpty ? 'screenshot' : (l.isNotEmpty ? 'place' : 'other'))
        : top.key;
  }

  static String? _keyHint(String kind, List<String> l, [String? ocr]) {
    if (ocr != null && ocr.isNotEmpty) {
      final ocrLower = ocr.toLowerCase();
      if (ocrLower.contains('receipt') ||
          ocrLower.contains('invoice') ||
          ocrLower.contains('total') ||
          ocrLower.contains('paid') ||
          ocrLower.contains('₹') ||
          ocrLower.contains('\$')) {
        return 'receipt';
      }
      if (ocrLower.contains('code') ||
          ocrLower.contains('github') ||
          ocrLower.contains('flutter') ||
          ocrLower.contains('debug') ||
          ocrLower.contains('terminal')) {
        return 'work';
      }
      if (ocrLower.contains('exam') ||
          ocrLower.contains('chapter') ||
          ocrLower.contains('lecture') ||
          ocrLower.contains('homework') ||
          ocrLower.contains('study')) {
        return 'study';
      }
      if (ocrLower.contains('workout') ||
          ocrLower.contains('calories') ||
          ocrLower.contains('steps') ||
          ocrLower.contains('fitness') ||
          ocrLower.contains('pace')) {
        return 'gym';
      }
    }
    return switch (kind) {
      'food' => l.any((x) => x.contains('coffee') || x.contains('tea'))
          ? 'coffee'
          : 'food',
      'gym' => 'gym',
      'study' => 'study',
      'screenshot' => 'reading',
      'place' =>
        l.firstWhere((x) => _place.contains(x), orElse: () => 'outdoors'),
      _ => l.isNotEmpty ? l.first : 'photo',
    };
  }

  static String _extractMeaningfulOcr(String ocr) {
    final lines = ocr.split('\n').map((s) => s.trim()).where((s) {
      if (s.length < 2) return false;
      // Filter out pure numbers, clocks, battery % or phone status bar tokens
      if (RegExp(r'^\d+[\s:.\-\/]*\d*$').hasMatch(s)) {
        return false;
      }
      if (RegExp(r'^(100%|\d{1,2}:\d{2}|5G|4G|LTE|AM|PM)$',
              caseSensitive: false)
          .hasMatch(s)) {
        return false;
      }
      return true;
    }).toList();

    if (lines.isEmpty) {
      final anyLine = ocr
          .split('\n')
          .map((s) => s.trim())
          .firstWhere((s) => s.isNotEmpty, orElse: () => 'Screenshot');
      return anyLine;
    }

    // Combine top meaningful lines up to ~100 chars
    final buffer = StringBuffer();
    for (final line in lines.take(3)) {
      if (buffer.length + line.length > 100 && buffer.isNotEmpty) break;
      if (buffer.isNotEmpty) buffer.write(' · ');
      buffer.write(line);
    }
    final res = buffer.toString();
    return res.length > 110 ? '${res.substring(0, 110)}…' : res;
  }

  static String _describe(String kind, List<String> l, String ocr) {
    final specific = l
        .where((x) => !const {
              'food',
              'dish',
              'meal',
              'tableware',
              'plate',
              'text',
              'font',
              'document',
              'photo',
              'image'
            }.contains(x))
        .take(3)
        .map((x) => x.isEmpty ? x : x[0].toUpperCase() + x.substring(1))
        .toList();

    if (ocr.isNotEmpty) {
      final cleanText = _extractMeaningfulOcr(ocr);
      if (cleanText.isNotEmpty && cleanText != 'Screenshot') {
        return cleanText;
      }
    }

    switch (kind) {
      case 'food':
        return specific.isEmpty ? 'Meal / Food' : specific.join(', ');
      case 'screenshot':
        return ocr.isNotEmpty
            ? _extractMeaningfulOcr(ocr)
            : (specific.isEmpty ? 'Screenshot' : specific.join(', '));
      case 'gym':
        return specific.isEmpty ? 'At the gym' : 'Gym: ${specific.join(', ')}';
      case 'study':
        return specific.isEmpty
            ? 'Study notes'
            : 'Notes: ${specific.join(', ')}';
      case 'place':
        return specific.isEmpty ? 'Out somewhere' : specific.join(', ');
      default:
        return specific.isEmpty ? 'Photo' : specific.join(', ');
    }
  }
}

/// Optional top tier. Implement with a platform channel to ML Kit GenAI
/// image description (Android, AICore devices) or Apple's on-device
/// captioning. Return null when unsupported; the floor result is used.
abstract class PlatformCaptioner {
  Future<PhotoModelStatus> status() async => PhotoModelStatus.unsupported;
  Future<void> download() async {}
  Future<String?> describe(File image);
}

enum PhotoModelStatus { unsupported, downloadable, downloading, available }

class PhotoUnderstanding {
  const PhotoUnderstanding({
    required this.kind,
    required this.description,
    required this.labels,
    this.text,
    this.keyHint,
    this.kcalEstimate,
  });
  final String kind; // food | screenshot | gym | study | place | other
  final String description;
  final List<String> labels;
  final String? text;
  final String? keyHint;
  final int? kcalEstimate;
}
