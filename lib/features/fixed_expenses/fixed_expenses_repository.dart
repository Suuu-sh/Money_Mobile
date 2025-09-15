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
}

