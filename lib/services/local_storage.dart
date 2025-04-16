import 'package:hive_flutter/hive_flutter.dart';
import '../models/idea.dart';
import '../models/category.dart';

class LocalStorage {
  static const String _ideasBox = 'ideas';
  static const String _categoriesBox = 'categories';
  static const String _syncStatusBox = 'sync_status';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(IdeaAdapter());
    Hive.registerAdapter(CategoryAdapter());

    // Open boxes
    await Hive.openBox<Idea>(_ideasBox);
    await Hive.openBox<Category>(_categoriesBox);
    await Hive.openBox<Map>(_syncStatusBox);
  }

  // Ideas
  static Future<void> saveIdea(Idea idea) async {
    final box = await Hive.openBox<Idea>(_ideasBox);
    await box.put(idea.id, idea);
    _updateSyncStatus('idea_${idea.id}', false);
  }

  static Future<List<Idea>> getIdeas() async {
    final box = await Hive.openBox<Idea>(_ideasBox);
    return box.values.toList();
  }

  static Future<Idea?> getIdea(String id) async {
    final box = await Hive.openBox<Idea>(_ideasBox);
    return box.get(id);
  }

  // Categories
  static Future<void> saveCategory(Category category) async {
    final box = await Hive.openBox<Category>(_categoriesBox);
    await box.put(category.id, category);
    _updateSyncStatus('category_${category.id}', false);
  }

  static Future<List<Category>> getCategories() async {
    final box = await Hive.openBox<Category>(_categoriesBox);
    return box.values.toList();
  }

  static Future<Category?> getCategory(String id) async {
    final box = await Hive.openBox<Category>(_categoriesBox);
    return box.get(id);
  }

  // Sync Status
  static Future<void> _updateSyncStatus(String key, bool isSynced) async {
    final box = await Hive.openBox<Map>(_syncStatusBox);
    await box.put(key, {'isSynced': isSynced, 'lastUpdated': DateTime.now()});
  }

  static Future<List> getUnsyncedItems() async {
    final box = await Hive.openBox<Map>(_syncStatusBox);
    return box.values
        .where((status) => !status['isSynced'])
        .map((status) => status['key'])
        .toList();
  }

  static Future<void> markAsSynced(String key) async {
    await _updateSyncStatus(key, true);
  }

  // Clear local data
  static Future<void> clearAll() async {
    final ideasBox = await Hive.openBox<Idea>(_ideasBox);
    final categoriesBox = await Hive.openBox<Category>(_categoriesBox);
    final syncStatusBox = await Hive.openBox<Map>(_syncStatusBox);

    await ideasBox.clear();
    await categoriesBox.clear();
    await syncStatusBox.clear();
  }
}
