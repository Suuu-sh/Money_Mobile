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

  Future<CategoryBudget> create({
    required int categoryId,
    required int year,
    required int month,
    required double amount,
  }) async {
    final res = await _api.postJson('/category-budgets', {
      'categoryId': categoryId,
      'year': year,
      'month': month,
      'amount': amount,
    });
    return CategoryBudget.fromJson(res as Map<String, dynamic>);
  }

  Future<CategoryBudget> update(
    int id, {
    required int categoryId,
    required int year,
    required int month,
    required double amount,
  }) async {
    final res = await _api.putJson('/category-budgets/$id', {
      'categoryId': categoryId,
      'year': year,
      'month': month,
      'amount': amount,
    });
    return CategoryBudget.fromJson(res as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _api.delete('/category-budgets/$id');
  }
}
