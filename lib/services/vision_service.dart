import 'dart:io';

import 'package:dio/dio.dart';

import 'api_client.dart';

class VisionAnalysisResult {
  const VisionAnalysisResult({required this.text, required this.mode, required this.conversationId});

  final String text;
  final String mode;
  final String conversationId;
}

/// Envoie une image au backend pour analyse (description, OCR, ou
/// détection d'objets — voir `mode`). Contrairement au vocal/chat, pas
/// de WebSocket ici : c'est un échange ponctuel upload → résultat.
class VisionService {
  VisionService(this._api);

  final ApiClient _api;

  Future<VisionAnalysisResult> analyzeImage({
    required File imageFile,
    String mode = 'describe',
    String? question,
    String? conversationId,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
      'mode': mode,
      if (question != null && question.isNotEmpty) 'question': question,
      if (conversationId != null) 'conversation_id': conversationId,
    });

    final response = await _api.dio.post('/vision/analyze', data: formData);

    return VisionAnalysisResult(
      text: response.data['text'] as String,
      mode: response.data['mode'] as String,
      conversationId: response.data['conversation_id'] as String,
    );
  }
}
