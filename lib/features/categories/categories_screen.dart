import 'package:flutter/material.dart';
import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/features/categories/categories_repository.dart';
import 'package:money_tracker_mobile/models/category.dart';

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
                itemBuilder: (context, i) {
                  final c = items[i];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: _parseColor(c.color)),
                    title: Text(c.name),
                    subtitle: Text(c.type),
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

