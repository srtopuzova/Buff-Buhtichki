import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:medshelf/core/constants/app_constants.dart';
import 'package:medshelf/features/med_shelf/models/medication_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  static const _systemBase = '''You are a pharmacy assistant embedded in the MedShelf app.

The user has scanned their medication boxes and the app has stored only the brand name, active substance, dosage, and expiry date — nothing else. This is intentional: the app relies on YOUR complete pharmacological knowledge to understand what each medication does.

Your task: when the user describes symptoms, use your full knowledge of each medication (by brand name and active substance) to determine which ones can help. The list below tells you only WHICH medications are physically available — it does NOT limit what you know about them.

STRICT RULES:

1. ONLY recommend medications from the available list. Never mention any medication not in the list.

2. Apply your complete pharmacological knowledge. You know exactly what every medication treats — by brand name AND active substance. A medication like LinForte (loperamide) treats diarrhea; Nurofen (ibuprofen) treats pain/fever/inflammation; etc. Never say you are "limited to the listed fields" — you know far more about each drug than what is stored in the app.

3. Answer ONLY the symptoms the user described. Do not introduce unrelated conditions, do not speculate about other causes, do not suggest extra tests.

4. If symptoms sound serious (chest pain, difficulty breathing, fever above 39 °C, blood in stool/urine, severe or worsening pain) — tell the user to see a doctor. Do not recommend self-medication.

5. If none of the available medications are appropriate — say so directly. Do not invent or stretch indications.

6. Be concise. End every response with exactly: "This is not medical advice — consult a pharmacist or doctor if unsure."

7. Language: this app is used in Bulgaria. If the user writes in Cyrillic, always respond in Bulgarian (Български). If the user writes in English, respond in English.''';

  /// [history] is the full conversation so far as [{role, content}] pairs.
  Future<String> sendMessage({
    required List<Map<String, String>> history,
    required List<MedicationModel> availableMeds,
  }) async {
    final medList = _buildMedList(availableMeds);
    final system = '$_systemBase\n\nAvailable medications in MedShelf:\n$medList';

    for (final model in [AppConstants.claudeModelSmart, AppConstants.claudeModelFast]) {
      try {
        final response = await http
            .post(
              Uri.parse(AppConstants.claudeApiUrl),
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': AppConstants.claudeApiKey,
                'anthropic-version': '2023-06-01',
              },
              body: jsonEncode({
                'model': model,
                'max_tokens': 512,
                'system': system,
                'messages': history,
              }),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final content = data['content'] as List<dynamic>;
          if (content.isNotEmpty) return content[0]['text'] as String;
        }

        // 529 = API overloaded — try next model
        if (response.statusCode == 529) {
          debugPrint('ChatService: $model overloaded, retrying with next model');
          continue;
        }

        debugPrint('ChatService HTTP ${response.statusCode}: ${response.body}');
        break;
      } catch (e) {
        debugPrint('ChatService error ($model): $e');
        break;
      }
    }

    return 'Sorry, something went wrong. Please try again.';
  }

  String _buildMedList(List<MedicationModel> meds) {
    final available =
        meds.where((m) => !m.isExpired && m.quantity > 0).toList();
    if (available.isEmpty) {
      return '(none — MedShelf is empty or all medications are expired)';
    }

    return available.map((m) {
      final detail = [
        if (m.activeSubstance != null) m.activeSubstance!,
        if (m.dosage != null) m.dosage!,
      ].join(' ');
      final suffix = detail.isEmpty ? '' : ' ($detail)';
      final qty = m.quantity;
      final indicationLine =
          m.indications != null ? '\n  Usage: ${m.indications}' : '';
      return '• ${m.name}$suffix — ${m.category.label}, $qty pack${qty == 1 ? '' : 's'} (boxes)$indicationLine';
    }).join('\n');
  }
}
