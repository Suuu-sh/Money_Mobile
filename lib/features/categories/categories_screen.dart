import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/models/category.dart';
import 'package:money_tracker_mobile/core/category_icons.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _repo = CategoriesRepository(ApiClient());
  late Future<List<Category>> _future;
  String? _type;

  @override
  void initState() {
    super.initState();
    _future = _repo.list();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repo.list(type: _type));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('すべて')),
              ButtonSegment(value: 'income', label: Text('収入')),
              ButtonSegment(value: 'expense', label: Text('支出')),
            ],
            selected: {_type ?? 'all'},
            onSelectionChanged: (s) {
              final v = s.first;
              setState(() => _type = v == 'all' ? null : v);
              _refresh();
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Category>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('読み込みエラー: ${snapshot.error}'));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) return const Center(child: Text('カテゴリがありません'));
              return ListView.builder(
                itemCount: items.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, i) {
                  final c = items[i];
                  final color = _parseColor(c.color);
                  final icon = c.icon.isNotEmpty 
                      ? CategoryIcons.getIcon(c.icon)
                      : CategoryIcons.guessIcon(c.name, c.type);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      title: Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        c.type == 'income' ? '収入' : '支出',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c.color,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0x999999;
    return Color(0xFF000000 | value);
  }
}

