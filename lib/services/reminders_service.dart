import '../services/api_client.dart';

class ReminderItem {
  const ReminderItem({required this.id, required this.title, required this.dueAt});

  final String id;
  final String title;
  final DateTime dueAt;

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'] as String,
      title: json['title'] as String,
      dueAt: DateTime.parse(json['due_at'] as String),
    );
  }
}

/// Lit les rappels en attente créés par l'agent d'automatisation
/// (étape 5) — alimente le panneau "Prochaines échéances" du tableau
/// de bord (étape 9). Lecture seule : la création passe toujours par
/// une conversation avec Jarvis, jamais directement depuis cet écran.
class RemindersService {
  RemindersService(this._api);

  final ApiClient _api;

  Future<List<ReminderItem>> listUpcoming() async {
    final response = await _api.dio.get('/reminders');
    final data = response.data as List<dynamic>;
    return data.map((item) => ReminderItem.fromJson(item as Map<String, dynamic>)).toList();
  }
}
