import '../../../../core/network/dio_client.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._client);
  final DioClient _client;

  static const _base = '/notifications';

  Future<List<AppNotification>> list() async {
    final r = await _client.get<Map<String, dynamic>>(_base);
    final items = (r.data?['items'] as List? ?? []);
    return items
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int id) async {
    await _client.post('$_base/$id/read');
  }

  Future<int> markAllRead() async {
    final r = await _client.post<Map<String, dynamic>>('$_base/read-all');
    final msg = r.data?['message'] as String? ?? '';
    final match = RegExp(r'\d+').firstMatch(msg);
    return match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
  }

  Future<void> delete(int id) async {
    await _client.delete('$_base/$id');
  }

  Future<int> deleteRead() async {
    final r = await _client.delete<Map<String, dynamic>>(_base);
    final msg = r.data?['message'] as String? ?? '';
    final match = RegExp(r'\d+').firstMatch(msg);
    return match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
  }
}