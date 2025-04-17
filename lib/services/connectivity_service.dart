import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'local_storage.dart';
import 'firebase_service.dart';

class ConnectivityStatus {
  final bool isOnline;
  final bool isSyncing;

  ConnectivityStatus({
    required this.isOnline,
    required this.isSyncing,
  });
}

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isOnline = true;
  bool _isSyncing = false;

  // 상태 변경 스트림
  final _statusController = StreamController<ConnectivityStatus>.broadcast();
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  // 싱글톤 패턴
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  Future<void> initialize() async {
    _isOnline = await _checkConnection();
    _notifyStatusChange();

    _subscription = _connectivity.onConnectivityChanged.listen((result) async {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      _notifyStatusChange();

      if (!wasOnline && _isOnline) {
        await _syncWithFirebase();
      }
    });
  }

  void _notifyStatusChange() {
    _statusController.add(ConnectivityStatus(
      isOnline: _isOnline,
      isSyncing: _isSyncing,
    ));
  }

  Future<bool> _checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> _syncWithFirebase() async {
    _isSyncing = true;
    _notifyStatusChange();

    try {
      final unsyncedItems = await LocalStorage.getUnsyncedItems();
      for (var key in unsyncedItems) {
        if (key.startsWith('idea_')) {
          final ideaId = key.substring(5);
          final idea = await LocalStorage.getIdea(ideaId);
          if (idea != null) {
            final categoryId = idea.id.split('_')[0];
            await _firebaseService.updateIdea(idea, categoryId);
            await LocalStorage.markAsSynced(key);
          }
        } else if (key.startsWith('category_')) {
          final categoryId = key.substring(9);
          final category = await LocalStorage.getCategory(categoryId);
          if (category != null) {
            await _firebaseService.updateCategory(category);
            await LocalStorage.markAsSynced(key);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing with Firebase: $e');
    } finally {
      _isSyncing = false;
      _notifyStatusChange();
    }
  }

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
