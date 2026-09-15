import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../services/integrations_service.dart';
import '../../widgets/holographic/glow_container.dart';
import '../../widgets/holographic/holo_background.dart';

/// Écran Réglages (étape 9) — comble le manque laissé depuis l'étape 7 :
/// jusqu'ici, connecter Google n'était possible qu'en récupérant l'URL
/// d'autorisation manuellement. Le flux OAuth s'ouvre dans le
/// navigateur système (pas de WebView intégrée) — c'est le comportement
/// standard recommandé par Google pour ce type d'autorisation.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  IntegrationsStatus? _status;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = IntegrationsService(ref.read(apiClientProvider));
      final status = await service.getStatus();
      setState(() => _status = status);
    } catch (_) {
      setState(() => _error = "Impossible de charger l'état des intégrations.");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _connectGoogle() async {
    try {
      final service = IntegrationsService(ref.read(apiClientProvider));
      final authUrl = await service.getGoogleAuthUrl();
      final uri = Uri.parse(authUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir la page de connexion Google.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: HoloBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadStatus,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Intégrations', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryGlow)),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (_error != null)
                  Text(_error!, style: const TextStyle(color: AppColors.danger))
                else ...[
                  _IntegrationTile(
                    icon: Icons.calendar_month_rounded,
                    name: 'Google Agenda & Gmail',
                    connected: _status?.google ?? false,
                    onConnect: _connectGoogle,
                  ),
                  const SizedBox(height: 12),
                  _IntegrationTile(
                    icon: Icons.chat_rounded,
                    name: 'WhatsApp',
                    connected: _status?.whatsapp ?? false,
                    subtitle: _status?.whatsapp == false ? 'Configuré par le serveur, pas par utilisateur' : null,
                    onConnect: null, // pas de connexion par utilisateur, voir whatsapp_service.py côté backend
                  ),
                ],
                const SizedBox(height: 32),
                Text('Compte', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryGlow)),
                const SizedBox(height: 12),
                GlowContainer(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                    title: const Text('Se déconnecter'),
                    onTap: () => ref.read(authStateProvider.notifier).logout(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  const _IntegrationTile({
    required this.icon,
    required this.name,
    required this.connected,
    required this.onConnect,
    this.subtitle,
  });

  final IconData icon;
  final String name;
  final bool connected;
  final String? subtitle;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    return GlowContainer(
      glowIntensity: connected ? 0.35 : 0.15,
      child: Row(
        children: [
          Icon(icon, color: connected ? AppColors.success : AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name),
                Text(
                  subtitle ?? (connected ? 'Connecté' : 'Non connecté'),
                  style: TextStyle(
                    fontSize: 12,
                    color: connected ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!connected && onConnect != null)
            TextButton(onPressed: onConnect, child: const Text('Connecter')),
        ],
      ),
    );
  }
}
