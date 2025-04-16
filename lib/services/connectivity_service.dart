import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'local_storage.dart';
import 'firebase_service.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isOnline = true;

  // 싱글톤 패턴
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  Future<void> initialize() async {
    // 초기 연결 상태 확인
    _isOnline = await _checkConnection();

    // 연결 상태 변화 감지
    _subscription = _connectivity.onConnectivityChanged.listen((result) async {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      // 오프라인에서 온라인으로 전환될 때 동기화
      if (!wasOnline && _isOnline) {
        await _syncWithFirebase();
      }
    });
  }

  Future<bool> _checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> _syncWithFirebase() async {
    try {
      final unsyncedItems = await LocalStorage.getUnsyncedItems();

      for (var key in unsyncedItems) {
        if (key.startsWith('idea_')) {
          final ideaId = key.substring(5);
          final idea = await LocalStorage.getIdea(ideaId);
          if (idea != null) {
            final categoryId = idea.id.split('_')[0]; // 카테고리 ID 추출
            await _firebaseService.updateIdea(categoryId, idea);
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
    }
  }

  bool get isOnline => _isOnline;

  void dispose() {
    _subscription?.cancel();
  }
}
