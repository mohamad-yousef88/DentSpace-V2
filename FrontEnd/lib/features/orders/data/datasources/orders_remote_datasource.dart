import '../../../../core/network/dio_client.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';

class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this._client);
  final DioClient _client;

  static const _base = '/orders';

  Future<List<Order>> listOrders(ListOrdersParams p) async {
    final r = await _client.get<Map<String, dynamic>>(
      _base,
      queryParameters: {
        'role': p.role,
        if (p.status != null) 'status': p.status!.name,
        'offset': p.offset,
        'limit': p.limit,
      },
    );
    final items = (r.data?['items'] as List? ?? []);
    return items
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> getOrder(int id) async {
    final r = await _client.get<Map<String, dynamic>>('$_base/$id');
    return Order.fromJson(r.data!);
  }

  Future<Order> createOrder(int toolId, String? message) async {
    final r = await _client.post<Map<String, dynamic>>(
      _base,
      data: {
        'tool_id': toolId,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
    );
    return Order.fromJson(r.data!);
  }

  Future<Order> approveOrder(int id) async {
    final r = await _client.post<Map<String, dynamic>>('$_base/$id/approve');
    return Order.fromJson(r.data!);
  }

  Future<Order> rejectOrder(int id) async {
    final r = await _client.post<Map<String, dynamic>>('$_base/$id/reject');
    return Order.fromJson(r.data!);
  }

  Future<Order> completeOrder(int id) async {
    final r = await _client.post<Map<String, dynamic>>('$_base/$id/complete');
    return Order.fromJson(r.data!);
  }

  Future<void> cancelOrder(int id) async {
    await _client.delete('$_base/$id');
  }
}