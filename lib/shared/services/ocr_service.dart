import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:medshelf/core/constants/app_constants.dart';

class OcrMedicationResult {
  final String? name;
  final String? expiryRaw;
  final String? activeSubstance;
  final String? dosage;
  final String? manufacturer;

  const OcrMedicationResult({
    this.name,
    this.expiryRaw,
    this.activeSubstance,
    this.dosage,
    this.manufacturer,
  });
}

class OcrPrescriptionResult {
  final String? medicationName;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? doctorName;
  final String? patientName;
  final String? instructions;

  const OcrPrescriptionResult({
    this.medicationName,
    this.dosage,
    this.frequency,
    this.duration,
    this.doctorName,
    this.patientName,
    this.instructions,
  });
}

class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  /// Core Claude API call. [model] defaults to claudeModelFast.
  Future<String?> _askClaude({
    required List<Map<String, dynamic>> content,
    String model = AppConstants.claudeModelFast,
    int maxTokens = 1024,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.claudeApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': AppConstants.claudeApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': maxTokens,
          'messages': [
            {'role': 'user', 'content': content},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final contentList = data['content'] as List<dynamic>;
        if (contentList.isNotEmpty) {
          return contentList[0]['text'] as String?;
        }
      } else {
        // ignore: avoid_print
        print('Claude API error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Claude API exception: $e');
    }
    return null;
  }

  String _encodeImage(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    return base64Encode(bytes);
  }

  String _mimeType(File imageFile) {
    final ext = imageFile.path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Extract medication info from up to 2 images (front + back of box).
  /// Falls back to individual calls if the combined call fails.
  Future<OcrMedicationResult> extractMedicationInfo(
    List<File> images,
  ) async {
    assert(images.isNotEmpty, 'At least one image required');

    // Build content with all images + prompt
    final content = <Map<String, dynamic>>[];

    for (final img in images.take(2)) {
      content.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': _mimeType(img),
          'data': _encodeImage(img),
        },
      });
    }

    content.add({
      'type': 'text',
      'text':
          '''You are a pharmacy assistant. Analyze the medication box image(s) and extract:
1. Medication name (brand name preferred, include generic if visible)
2. Expiry date (exact text as printed, e.g. "12/2026", "EXP: 06/2025")
3. Active substance / generic name
4. Dosage strength (e.g. "500mg", "10mg/5ml")
5. Manufacturer name

Respond ONLY with a JSON object in this exact format (use null for missing fields):
{
  "name": "...",
  "expiry_raw": "...",
  "active_substance": "...",
  "dosage": "...",
  "manufacturer": "..."
}''',
    });

    String? raw = await _askClaude(
      content: content,
      model: AppConstants.claudeModelFast,
    );

    if (raw != null) {
      final result = _parseMedicationJson(raw);
      if (result != null) return result;
    }

    // Fallback: try each image individually and merge
    OcrMedicationResult? merged;
    for (final img in images.take(2)) {
      final singleContent = <Map<String, dynamic>>[
        {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': _mimeType(img),
            'data': _encodeImage(img),
          },
        },
        {
          'type': 'text',
          'text': '''Extract medication details from this image.
Respond ONLY with JSON:
{
  "name": "...",
  "expiry_raw": "...",
  "active_substance": "...",
  "dosage": "...",
  "manufacturer": "..."
}''',
        },
      ];

      final singleRaw = await _askClaude(
        content: singleContent,
        model: AppConstants.claudeModelFast,
      );

      if (singleRaw != null) {
        final r = _parseMedicationJson(singleRaw);
        if (r != null) {
          merged = _mergeMedicationResults(merged, r);
        }
      }
    }

    return merged ?? const OcrMedicationResult();
  }

  /// Extract prescription info from an image using the smarter model.
  Future<OcrPrescriptionResult> extractPrescriptionInfo(File image) async {
    final content = <Map<String, dynamic>>[
      {
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': _mimeType(image),
          'data': _encodeImage(image),
        },
      },
      {
        'type': 'text',
        'text':
            '''You are a medical assistant. Carefully read this prescription and extract:
1. Medication name (exact as written)
2. Dosage (e.g. "500mg", "1 tablet")
3. Frequency (e.g. "twice daily", "every 8 hours", "3 times a day")
4. Duration (e.g. "7 days", "2 weeks", "1 month")
5. Doctor name
6. Patient name
7. Special instructions (e.g. "take with food", "avoid alcohol")

Respond ONLY with a JSON object in this exact format (use null for missing fields):
{
  "medication_name": "...",
  "dosage": "...",
  "frequency": "...",
  "duration": "...",
  "doctor_name": "...",
  "patient_name": "...",
  "instructions": "..."
}''',
      },
    ];

    final raw = await _askClaude(
      content: content,
      model: AppConstants.claudeModelSmart,
      maxTokens: 1024,
    );

    if (raw != null) {
      final result = _parsePrescriptionJson(raw);
      if (result != null) return result;
    }

    return const OcrPrescriptionResult();
  }

  OcrMedicationResult? _parseMedicationJson(String raw) {
    try {
      final jsonStr = _extractJson(raw);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return OcrMedicationResult(
        name: _nonEmpty(map['name']),
        expiryRaw: _nonEmpty(map['expiry_raw']),
        activeSubstance: _nonEmpty(map['active_substance']),
        dosage: _nonEmpty(map['dosage']),
        manufacturer: _nonEmpty(map['manufacturer']),
      );
    } catch (_) {
      return null;
    }
  }

  OcrPrescriptionResult? _parsePrescriptionJson(String raw) {
    try {
      final jsonStr = _extractJson(raw);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return OcrPrescriptionResult(
        medicationName: _nonEmpty(map['medication_name']),
        dosage: _nonEmpty(map['dosage']),
        frequency: _nonEmpty(map['frequency']),
        duration: _nonEmpty(map['duration']),
        doctorName: _nonEmpty(map['doctor_name']),
        patientName: _nonEmpty(map['patient_name']),
        instructions: _nonEmpty(map['instructions']),
      );
    } catch (_) {
      return null;
    }
  }

  String _extractJson(String raw) {
    // Strip markdown code fences if present
    final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(raw);
    if (fenceMatch != null) return fenceMatch.group(1)!.trim();
    // Find first { ... }
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return raw.substring(start, end + 1);
    }
    return raw.trim();
  }

  String? _nonEmpty(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty || s == 'null' || s == 'N/A' || s == 'n/a') return null;
    return s;
  }

  OcrMedicationResult _mergeMedicationResults(
    OcrMedicationResult? a,
    OcrMedicationResult b,
  ) {
    if (a == null) return b;
    return OcrMedicationResult(
      name: a.name ?? b.name,
      expiryRaw: a.expiryRaw ?? b.expiryRaw,
      activeSubstance: a.activeSubstance ?? b.activeSubstance,
      dosage: a.dosage ?? b.dosage,
      manufacturer: a.manufacturer ?? b.manufacturer,
    );
  }
}
