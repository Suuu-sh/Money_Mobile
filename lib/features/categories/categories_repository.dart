import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/models/category.dart';

class CategoriesRepository {
  CategoriesRepository(this._api);
  final ApiClient _api;

  Future<List<Category>> list({String? type}) async {
    final res = await _api.getJson('/categories', query: type == null ? null : {'type': type});
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(Category.fromJson).toList();
  }

  Future<Category> create(Category category) async {
    final res = await _api.postJson('/categories', {
      'name': category.name,
      'type': category.type,
      'color': category.color,
      'icon': category.icon,
      'description': category.description,
    });
    return Category.fromJson(res as Map<String, dynamic>);
  }

  Future<Category> update(int id, {String? name, String? type, String? color, String? icon, String? description}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (type != null) body['type'] = type;
    if (color != null) body['color'] = color;
    if (icon != null) body['icon'] = icon;
    if (description != null) body['description'] = description;
    final res = await _api.putJson('/categories/$id', body);
    return Category.fromJson(res as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _api.delete('/categories/$id');
  }
}

