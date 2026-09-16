import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/service_providers.dart';
import '../../services/vision_service.dart';
import '../../widgets/holographic/glow_container.dart';
import '../../widgets/holographic/holo_background.dart';

enum _VisionMode { describe, ocr, objects }

extension on _VisionMode {
  String get apiValue => switch (this) {
        _VisionMode.describe => 'describe',
        _VisionMode.ocr => 'ocr',
        _VisionMode.objects => 'objects',
      };

  String get label => switch (this) {
        _VisionMode.describe => 'Décrire',
        _VisionMode.ocr => 'Lire le texte (OCR)',
        _VisionMode.objects => 'Objets visibles',
      };
}

/// Écran du module vision (étape 8) : prend une photo ou en choisit une
/// dans la galerie, l'envoie à `/vision/analyze`, affiche le résultat.
/// Peut aussi répondre à une question libre sur l'image plutôt que de
/// se limiter aux 3 modes prédéfinis (voir `_questionController`).
class VisionScreen extends ConsumerStatefulWidget {
  const VisionScreen({super.key});

  @override
  ConsumerState<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends ConsumerState<VisionScreen> {
  final _picker = ImagePicker();
  final _questionController = TextEditingController();

  File? _selectedImage;
  _VisionMode _mode = _VisionMode.describe;
  bool _analyzing = false;
  String? _resultText;
  String? _errorText;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;

      setState(() {
        _selectedImage = File(picked.path);
        _resultText = null;
        _errorText = null;
      });
    } catch (_) {
      if (mounted) setState(() => _errorText = 'Impossible d’accéder à la caméra ou à la galerie.');
    }
  }

  Future<void> _analyze() async {
    if (_selectedImage == null) return;

    setState(() {
      _analyzing = true;
      _errorText = null;
    });

    try {
      final visionService = VisionService(ref.read(apiClientProvider));
      final result = await visionService.analyzeImage(
        imageFile: _selectedImage!,
        mode: _mode.apiValue,
        question: _questionController.text.trim().isEmpty ? null : _questionController.text.trim(),
      );
      if (mounted) setState(() => _resultText = result.text);
    } catch (e) {
      if (mounted) setState(() => _errorText = "Échec de l'analyse — vérifie ta connexion et réessaie.");
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vision')),
      body: HoloBackground(
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlowContainer(
                child: _selectedImage == null
                    ? const SizedBox(
                        height: 160,
                        child: Center(
                          child: Text('Aucune image sélectionnée', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, height: 220, fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Caméra'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galerie'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _VisionMode.values.map((mode) {
                  return ChoiceChip(
                    label: Text(mode.label),
                    selected: _mode == mode,
                    onSelected: (_) => setState(() => _mode = mode),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Ou pose une question précise sur l\'image (optionnel)',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedImage == null || _analyzing ? null : _analyze,
                child: _analyzing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('ANALYSER'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Text(_errorText!, style: const TextStyle(color: AppColors.danger)),
              ],
              if (_resultText != null) ...[
                const SizedBox(height: 16),
                GlowContainer(glowIntensity: 0.35, child: Text(_resultText!)),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}
