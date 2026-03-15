import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_category.dart';

const _kKey = 'custom_categories_v1';

class CustomCategoryNotifier extends StateNotifier<List<CustomCategory>> {
  CustomCategoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? [];
    state = raw.map(CustomCategory.fromKey).toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kKey, state.map((c) => c.key).toList());
  }

  Future<void> add(CustomCategory cat) async {
    state = [...state, cat];
    await _save();
  }

  Future<void> remove(int index) async {
    final list = [...state];
    list.removeAt(index);
    state = list;
    await _save();
  }

  Future<void> update(int index, CustomCategory cat) async {
    final list = [...state];
    list[index] = cat;
    state = list;
    await _save();
  }
}

final customCategoryProvider =
    StateNotifierProvider<CustomCategoryNotifier, List<CustomCategory>>(
  (_) => CustomCategoryNotifier(),
);
