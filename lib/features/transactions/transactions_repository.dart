import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker_mobile/models/transaction.dart';

class TransactionsRepository {
  TransactionsRepository(this._api);
  final ApiClient _api;

  Future<List<MoneyTransaction>> list({int? page, int? pageSize, String? type, String? startDate, String? endDate, int? categoryId}) async {
    final query = <String, String>{};
    if (page != null) query['page'] = '$page';
    if (pageSize != null) query['pageSize'] = '$pageSize';
    if (type != null) query['type'] = type;
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;
    if (categoryId != null) query['categoryId'] = '$categoryId';
    final res = await _api.getJson('/transactions', query: query.isEmpty ? null : query);
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(MoneyTransaction.fromJson).toList();
  }

  Future<MoneyTransaction> getById(int id) async {
    final res = await _api.getJson('/transactions/$id');
    return MoneyTransaction.fromJson(res as Map<String, dynamic>);
  }

  Future<MoneyTransaction> create({
    required String type,
    required double amount,
    required int categoryId,
    String? description,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await _api.postJson('/transactions', {
      'type': type,
      'amount': amount,
      'categoryId': categoryId,
      'description': description ?? '',
      'date': dateStr,
    });
    return MoneyTransaction.fromJson(res as Map<String, dynamic>);
  }

  Future<MoneyTransaction> update(int id, {
    String? type,
    double? amount,
    int? categoryId,
    String? description,
    DateTime? date,
  }) async {
    final body = <String, dynamic>{};
    if (type != null) body['type'] = type;
    if (amount != null) body['amount'] = amount;
    if (categoryId != null) body['categoryId'] = categoryId;
    if (description != null) body['description'] = description;
    if (date != null) body['date'] = DateFormat('yyyy-MM-dd').format(date);
    final res = await _api.putJson('/transactions/$id', body);
    return MoneyTransaction.fromJson(res as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _api.delete('/transactions/$id');
  }
}
