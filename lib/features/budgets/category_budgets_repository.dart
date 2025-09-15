import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/models/category_budget.dart';

class CategoryBudgetsRepository {
  CategoryBudgetsRepository(this._api);
  final ApiClient _api;

  Future<List<CategoryBudget>> listByMonth(DateTime month) async {
    final y = month.year;
    final m = month.month;
    final res = await _api.getJson('/category-budgets/$y/$m');
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(CategoryBudget.fromJson).toList();
  }
}

