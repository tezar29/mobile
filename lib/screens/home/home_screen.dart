import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/service_providers.dart';
import '../../providers/voice_provider.dart';
import '../../services/reminders_service.dart';
import '../../widgets/holographic/glow_container.dart';
import '../../widgets/holographic/holo_background.dart';
import '../../widgets/holographic/voice_orb_button.dart';

/// Écran principal — tableau de bord holographique (étape 9) : orbe
/// vocal central, panneaux de statut (prochaines échéances), et accès
/// rapide aux autres modules (chat, vision, réglages). L'ancien écran
/// minimal (orbe seul + une ligne de statut) est remplacé par cette
/// disposition en panneaux, plus proche de l'esprit "JARVIS" recherché.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<ReminderItem>? _reminders;
  bool _loadingReminders = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _loadingReminders = true);
    try {
      final service = RemindersService(ref.read(apiClientProvider));
      final reminders = await service.listUpcoming();
      if (mounted) setState(() => _reminders = reminders);
    } catch (_) {
      // Panneau vide en cas d'échec réseau — pas bloquant pour le reste du tableau de bord.
    } finally {
      if (mounted) setState(() => _loadingReminders = false);
    }
  }

  @override
  void dispose() {
    ref.read(voiceProvider.notifier).deactivate();
    super.dispose();
  }

  OrbVisualState _orbState(VoiceStatus status) {
    switch (status) {
      case VoiceStatus.idle:
        return OrbVisualState.idle;
      case VoiceStatus.wakeListening:
        return OrbVisualState.waking;
      case VoiceStatus.listening:
        return OrbVisualState.listening;
      case VoiceStatus.processing:
        return OrbVisualState.thinking;
      case VoiceStatus.speaking:
        return OrbVisualState.speaking;
      case VoiceStatus.error:
        return OrbVisualState.error;
    }
  }

  String _statusLabel(VoiceStatus status) {
    switch (status) {
      case VoiceStatus.idle:
        return 'Touchez l\'orbe pour activer Jarvis';
      case VoiceStatus.wakeListening:
        return 'En veille — dites "Jarvis"';
      case VoiceStatus.listening:
        return 'Je vous écoute...';
      case VoiceStatus.processing:
        return 'Réflexion en cours...';
      case VoiceStatus.speaking:
        return 'Jarvis répond...';
      case VoiceStatus.error:
        return 'Erreur — touchez pour réessayer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);
    final isActive = voiceState.status != VoiceStatus.idle && voiceState.status != VoiceStatus.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('JARVIS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: HoloBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadReminders,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 12),
                Center(
                  child: VoiceOrbButton(
                    state: _orbState(voiceState.status),
                    onTap: () {
                      final notifier = ref.read(voiceProvider.notifier);
                      if (isActive) {
                        notifier.cancel();
                      } else {
                        notifier.activate();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    voiceState.errorMessage ?? _statusLabel(voiceState.status),
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (voiceState.transcript.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text('« ${voiceState.transcript} »',
                        style: const TextStyle(color: AppColors.primaryGlow), textAlign: TextAlign.center),
                  ),
                ],
                if (voiceState.responseText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GlowContainer(glowIntensity: 0.3, child: Text(voiceState.responseText)),
                ],
                const SizedBox(height: 28),
                _QuickActionsRow(),
                const SizedBox(height: 24),
                _RemindersPanel(reminders: _reminders, loading: _loadingReminders),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Conversation',
            onTap: () => context.go('/chat'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.camera_alt_outlined,
            label: 'Vision',
            onTap: () => context.go('/vision'),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlowContainer(
        glowIntensity: 0.2,
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryGlow),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _RemindersPanel extends StatelessWidget {
  const _RemindersPanel({required this.reminders, required this.loading});

  final List<ReminderItem>? reminders;
  final bool loading;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return isToday ? "Aujourd'hui, $time" : '${date.day}/${date.month} à $time';
  }

  @override
  Widget build(BuildContext context) {
    return GlowContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notifications_none_rounded, color: AppColors.primaryGlow, size: 18),
              SizedBox(width: 8),
              Text('Prochaines échéances', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (reminders == null || reminders!.isEmpty)
            const Text('Aucun rappel en attente.', style: TextStyle(color: AppColors.textSecondary))
          else
            ...reminders!.take(5).map(
                  (r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: AppColors.primaryGlow),
                        const SizedBox(width: 10),
                        Expanded(child: Text(r.title, overflow: TextOverflow.ellipsis)),
                        Text(_formatDate(r.dueAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                ),
        ],
      ),
    );
  }
}
