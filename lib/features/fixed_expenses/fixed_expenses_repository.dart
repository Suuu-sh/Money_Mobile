import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/models/fixed_expense.dart';

class FixedExpensesRepository {
  FixedExpensesRepository(this._api);
  final ApiClient _api;

  Future<List<FixedExpense>> list() async {
    final res = await _api.getJson('/fixed-expenses');
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(FixedExpense.fromJson).toList();
  }

  Future<FixedExpense> create({
    required String name,
    required double amount,
    required String type,
  }) async {
    final res = await _api.postJson('/fixed-expenses', {
      'name': name,
      'amount': amount,
      'type': type,
    });
    return FixedExpense.fromJson(res as Map<String, dynamic>);
  }

  Future<FixedExpense> update(
    int id, {
    required String name,
    required double amount,
    required String type,
  }) async {
    final res = await _api.putJson('/fixed-expenses/$id', {
      'name': name,
      'amount': amount,
      'type': type,
    });
    return FixedExpense.fromJson(res as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _api.delete('/fixed-expenses/$id');
  }
}
