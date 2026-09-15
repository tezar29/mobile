# Plan d'Analyse et Correction des Bugs

Ce plan vise à corriger plusieurs problèmes identifiés dans le projet JARVIS AI, notamment des fuites de mémoire, des problèmes de synchronisation dans le module vocal et des erreurs de structure de fichiers.

## User Review Required

> [!IMPORTANT]
> - La correction du `VoiceNotifier` changera la manière dont les flux audio sont gérés (passage d'un stream listener à un `await`).
> - Le dossier `lib/{core` sera supprimé car il semble être une erreur de création de dossier.
> - L'URL du WebSocket sera normalisée pour correspondre aux commentaires (`/api/v1/voice/ws`).

## Proposed Changes

### 1. Services & Providers

#### [MODIFY] [voice_provider.dart](file:///C:/Users/mzjc6/StudioProjects/JARVIS-AI/mobile/lib/providers/voice_provider.dart)
- Supprimer l'accumulation de listeners sur `_player.playerStateStream`.
- Utiliser `await _player.play()` pour attendre la fin de la lecture audio avant de reprendre l'écoute du wake word.
- Appeler `dispose` sur le service WebSocket lors de la destruction du notifier.

#### [MODIFY] [local_tts_service.dart](file:///C:/Users/mzjc6/StudioProjects/JARVIS-AI/mobile/lib/services/local_tts_service.dart)
- Ajouter un mécanisme pour attendre la fin de la synthèse vocale (completion handler) afin d'éviter que l'application ne s'écoute elle-même.

#### [MODIFY] [api_client.dart](file:///C:/Users/mzjc6/StudioProjects/JARVIS-AI/mobile/lib/services/api_client.dart)
- Empêcher une boucle infinie lors du rafraîchissement du token en utilisant une instance Dio séparée ou un flag dans les options.

#### [MODIFY] [voice_socket_service.dart](file:///C:/Users/mzjc6/StudioProjects/JARVIS-AI/mobile/lib/services/voice_socket_service.dart)
- S'assurer que l'URL construite est cohérente avec les attentes du backend (`/api/v1/voice/ws` vs `/ws/voice/ws`).

### 2. Structure du Projet

#### [DELETE] Dossier `lib/{core`
- Supprimer ce dossier erroné.

## Verification Plan

### Automated Tests
- Je vérifierai la validité de la syntaxe Dart après les modifications.
- (Note: Si des tests unitaires existent, ils devront être lancés).

### Manual Verification
- Vérifier que l'orbe central ne reste pas bloqué en état "speaking".
- Vérifier que le mot-clé "Jarvis" n'est pas détecté pendant que l'assistant parle (via le TTS local).
