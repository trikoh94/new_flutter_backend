import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/idea.dart';
import '../models/category.dart';
import '../models/project_model.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  static const String _ideasBox = 'ideas';
  static const String _projectsBox = 'projects';
  static const String _categoriesBox = 'categories';
  static const String _syncStatusBox = 'sync_status';

  Future<void> init() async {
    if (kIsWeb) {
      Hive.init('mindmap_db');
    } else {
      await Hive.initFlutter();
    }

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(IdeaAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProjectModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CategoryAdapter());
    }

    // Open boxes
    await Hive.openBox<Idea>(_ideasBox);
    await Hive.openBox<ProjectModel>(_projectsBox);
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

  // Projects
  static Future<void> saveProject(ProjectModel project) async {
    final box = await Hive.openBox<ProjectModel>(_projectsBox);
    await box.put(project.id, project);
    _updateSyncStatus('project_${project.id}', false);
  }

  static Future<List<ProjectModel>> getProjects() async {
    final box = await Hive.openBox<ProjectModel>(_projectsBox);
    return box.values.toList();
  }

  static Future<ProjectModel?> getProject(String id) async {
    final box = await Hive.openBox<ProjectModel>(_projectsBox);
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
    await box.put(
        key, {'key': key, 'isSynced': isSynced, 'lastUpdated': DateTime.now()});
  }

  static Future<List<String>> getUnsyncedItems() async {
    final box = await Hive.openBox<Map>(_syncStatusBox);
    return box.values
        .where((status) => !status['isSynced'])
        .map((status) => status['key'] as String)
        .toList();
  }

  static Future<void> markAsSynced(String key) async {
    await _updateSyncStatus(key, true);
  }

  // Clear local data
  static Future<void> clearAll() async {
    final ideasBox = await Hive.openBox<Idea>(_ideasBox);
    final projectsBox = await Hive.openBox<ProjectModel>(_projectsBox);
    final categoriesBox = await Hive.openBox<Category>(_categoriesBox);
    final syncStatusBox = await Hive.openBox<Map>(_syncStatusBox);

    await ideasBox.clear();
    await projectsBox.clear();
    await categoriesBox.clear();
    await syncStatusBox.clear();
  }
}
