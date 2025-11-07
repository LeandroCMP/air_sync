import 'package:air_sync/models/order_draft_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderDraftStorage {
  static const _storageKey = 'orders.drafts.v1';

  Future<List<OrderDraftModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? const [];
    return rawList
        .map(OrderDraftModel.fromJson)
        .toList()
      ..sort(
        (a, b) => b.updatedAt.compareTo(a.updatedAt),
      );
  }

  Future<OrderDraftModel?> getById(String id) async {
    final drafts = await getAll();
    for (final draft in drafts) {
      if (draft.id == id) return draft;
    }
    return null;
  }

  Future<void> save(OrderDraftModel draft) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getAll();
    final index = drafts.indexWhere((element) => element.id == draft.id);
    if (index >= 0) {
      drafts[index] = draft;
    } else {
      drafts.add(draft);
    }
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await prefs.setStringList(
      _storageKey,
      drafts.map((d) => d.toJson()).toList(),
    );
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getAll();
    drafts.removeWhere((element) => element.id == id);
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await prefs.setStringList(
      _storageKey,
      drafts.map((d) => d.toJson()).toList(),
    );
  }
}
