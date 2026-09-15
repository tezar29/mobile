# JARVIS AI — Mobile (Étape 10 — projet complet)

Pour le build de release (Android/iOS) et la checklist de soumission aux stores, voir
**`../DEPLOYMENT.md`** à la racine du projet.

## Ce qui est livré à cette étape

- Projet Flutter structuré (`core/`, `services/`, `providers/`, `screens/`, `widgets/`)
- **Thème holographique** : fond sombre, halos lumineux cyan/violet, typographie Orbitron/Rajdhani (`core/theme/`)
- **Navigation** avec `go_router`, redirection automatique selon l'état d'authentification (splash → login/register → home)
- **Gestion d'état** avec Riverpod : `authStateProvider` piloté par `AuthNotifier`
- **Connexion au backend de l'étape 2** : `ApiClient` (Dio) avec injection automatique du JWT et refresh transparent sur 401, `AuthService` qui appelle `/auth/register`, `/auth/login`, `/auth/refresh`
- **Stockage sécurisé** des tokens (Keychain/Keystore via `flutter_secure_storage`)
- Écrans : Splash, Login, Register, Home (orbe vocal central — visuel uniquement pour l'instant), Chat (squelette UI)
- Widgets holographiques réutilisables : `GlowContainer`, `VoiceOrbButton`

## Important : dossiers natifs android/ios

Cette livraison contient uniquement le code Dart (`lib/`), `pubspec.yaml` et la config d'analyse —
pas les dossiers natifs `android/` et `ios/` générés par l'outil `flutter`. Pour les créer :

```bash
cd mobile
flutter create . --org com.seedsoftengine --project-name jarvis_ai
```

Cette commande génère `android/` et `ios/` sans toucher au code déjà présent dans `lib/`.

## Démarrage rapide

```bash
cd mobile
flutter pub get

# Lancer contre le backend local (émulateur Android : 10.0.2.2 = ton localhost)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# Sur un appareil physique, remplace 10.0.2.2 par l'IP locale de ta machine.
```

## Module vocal (Étape 4)

- `services/voice_recognition_service.dart` : écoute passive du mot-clé **"Jarvis"** puis capture de la
  commande complète, via la reconnaissance vocale native du téléphone (`speech_to_text`) — 100% local,
  faible latence, fonctionne même si le réseau est instable.
- `services/voice_socket_service.dart` : connexion WebSocket vers `/api/v1/voice/ws` du backend — envoie
  le texte transcrit, reçoit la réponse texte + audio (ElevenLabs en base64).
- `services/local_tts_service.dart` : repli sur la synthèse vocale du téléphone si ElevenLabs n'est pas
  configuré côté backend ou indisponible.
- `providers/voice_provider.dart` : orchestre tout le cycle (`VoiceStatus` : idle → wakeListening →
  listening → processing → speaking) et gère l'**annulation** (l'utilisateur touche l'orbe pendant que
  Jarvis répond → coupe l'audio et annule le tour en cours côté backend).
- L'orbe de `HomeScreen` est maintenant branché sur ce cycle réel (plus un simple effet visuel).

### Permissions natives à ajouter après `flutter create .`

**Android** (`android/app/src/main/AndroidManifest.xml`) :
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS** (`ios/Runner/Info.plist`) :
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Jarvis a besoin du micro pour vous écouter.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Jarvis a besoin de la reconnaissance vocale pour comprendre vos commandes.</string>
<key>NSCameraUsageDescription</key>
<string>Jarvis a besoin de l'appareil photo pour analyser des images.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Jarvis a besoin d'accéder à vos photos pour les analyser.</string>
```

### Limite connue

La détection du mot-clé s'appuie sur le moteur de reconnaissance vocale natif du téléphone
(pas un modèle wake-word dédié type Porcupine) : elle consomme plus de batterie en écoute
continue et peut être moins précise que du "vrai" wake-word. À réévaluer selon l'usage réel —
bascule possible vers Porcupine/Snowboy si besoin d'une écoute passive prolongée en arrière-plan.

## Chat texte branché sur l'orchestrateur (Étape 5)

- `services/chat_socket_service.dart` : connexion WebSocket vers `/api/v1/chat/ws` — même
  orchestrateur multi-agent que le module vocal côté backend, juste sans synthèse audio.
- `providers/chat_provider.dart` : gère la connexion et l'historique affiché à l'écran.
- `ChatScreen` envoie et reçoit maintenant de vrais messages (fini la simulation locale) : les
  réponses peuvent déclencher l'agent d'automatisation (ex. "rappelle-moi de..."), l'agent
  productivité (résumés/traduction), ou l'agent conversationnel généraliste — le routage se fait
  côté backend selon le contenu du message.

## Ce qui reste en squelette (prochaines étapes)

- La connexion biométrique (`local_auth` déjà dans `pubspec.yaml`) sera branchée avec l'endpoint
  biométrique du backend.

## Module vision (Étape 8)

- `services/vision_service.dart` : upload multipart (Dio) vers `POST /api/v1/vision/analyze`.
- `screens/vision/vision_screen.dart` : prend une photo ou en choisit une dans la galerie, 3 modes
  prédéfinis (Décrire / OCR / Objets visibles) ou une question libre qui prend le dessus sur le mode
  (ex: "y a-t-il un danger visible sur cette photo ?").
- Accessible depuis l'icône caméra à côté du bouton chat sur `HomeScreen`.
- Contrairement au vocal/chat, pas de WebSocket : c'est un échange ponctuel upload → résultat,
  mais le résultat est persisté côté backend dans l'historique de conversation, donc un message
  vocal ou texte ultérieur peut s'y référer ("et sur cette photo, il y avait écrit quoi ?").

## Interface holographique complète (Étape 9)

- `widgets/holographic/holo_background.dart` : fond animé réutilisable — grille de perspective très
  discrète + ligne de balayage lumineuse en boucle. Appliqué à tous les écrans (login, register,
  home, chat, vision, réglages) pour une identité visuelle cohérente sur toute l'app.
- `widgets/holographic/voice_orb_button.dart` : entièrement revu. L'orbe a maintenant un **anneau de
  sonar** (cercles concentriques qui s'étendent et s'estompent), avec une couleur, une vitesse et une
  icône différentes selon l'état réel du module vocal (`OrbVisualState` — veille, écoute, réflexion,
  réponse, erreur), plutôt qu'un simple booléen "écoute / pas écoute" comme avant.
- `HomeScreen` redevient un vrai **tableau de bord** : orbe central, panneau "Prochaines échéances"
  (rappels en attente, `GET /reminders` — nouveauté backend de cette étape), et accès rapide en un
  tap à la conversation et à la vision.
- `SettingsScreen` (nouveau) : comble un manque laissé depuis l'étape 7 — jusqu'ici, connecter Google
  n'était possible qu'en récupérant l'URL d'autorisation à la main. Affiche l'état des intégrations
  (`GET /integrations/status`) et ouvre le flux OAuth Google dans le navigateur système
  (`url_launcher`, pas de WebView intégrée — c'est le comportement standard recommandé par Google).

## Prochaine étape (Étape 10)

Tests plus poussés, scripts Docker de production, instructions de déploiement.
