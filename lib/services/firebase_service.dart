import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/portfolio_model.dart';
import '../models/mind_map_model.dart';
import '../models/idea_model.dart';
import '../models/project_model.dart';
import '../models/category.dart';
import '../models/idea.dart';
import 'local_storage.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authentication
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Portfolio
  Future<List<PortfolioModel>> getPortfolios() async {
    final snapshot = await _firestore.collection('portfolios').get();
    return snapshot.docs
        .map((doc) => PortfolioModel.fromFirestore(doc))
        .toList();
  }

  Future<PortfolioModel> getPortfolio(String id) async {
    final doc = await _firestore.collection('portfolios').doc(id).get();
    return PortfolioModel.fromFirestore(doc);
  }

  Future<void> createPortfolio(PortfolioModel portfolio) async {
    await _firestore
        .collection('portfolios')
        .doc(portfolio.id)
        .set(portfolio.toFirestore());
  }

  Future<void> updatePortfolio(PortfolioModel portfolio) async {
    await _firestore
        .collection('portfolios')
        .doc(portfolio.id)
        .update(portfolio.toFirestore());
  }

  Future<void> deletePortfolio(String id) async {
    await _firestore.collection('portfolios').doc(id).delete();
  }

  // Mind Map
  Future<List<MindMapModel>> getMindMaps() async {
    final snapshot = await _firestore.collection('mind_maps').get();
    return snapshot.docs.map((doc) => MindMapModel.fromFirestore(doc)).toList();
  }

  Future<MindMapModel> getMindMap(String id) async {
    final doc = await _firestore.collection('mind_maps').doc(id).get();
    return MindMapModel.fromFirestore(doc);
  }

  Future<void> createMindMap(MindMapModel mindMap) async {
    await _firestore
        .collection('mind_maps')
        .doc(mindMap.id)
        .set(mindMap.toFirestore());
  }

  Future<void> updateMindMap(MindMapModel mindMap) async {
    await _firestore
        .collection('mind_maps')
        .doc(mindMap.id)
        .update(mindMap.toFirestore());
  }

  Future<void> deleteMindMap(String id) async {
    await _firestore.collection('mind_maps').doc(id).delete();
  }

  // Category operations
  Future<void> createCategory(Category category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .set(category.toMap());
  }

  Stream<List<Category>> getCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Category.fromMap(doc.data());
      }).toList();
    });
  }

  Future<void> updateCategory(Category category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  // Idea operations
  Future<QuerySnapshot> getPaginatedIdeas(int limit,
      {DocumentSnapshot? startAfter}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        // Return an empty query result
        final emptyQuery = _firestore.collection('ideas').limit(0);
        return await emptyQuery.get();
      }

      Query query = _firestore
          .collection('ideas')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      return await query.get();
    } catch (e) {
      print('Error getting paginated ideas: $e');
      // Return an empty query result
      final emptyQuery = _firestore.collection('ideas').limit(0);
      return await emptyQuery.get();
    }
  }

  Stream<List<Idea>> getIdeas(String projectId) {
    try {
      return _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ideas')
          .snapshots()
          .map((snapshot) {
        final ideas =
            snapshot.docs.map((doc) => Idea.fromMap(doc.data())).toList();

        // Sync with local storage
        for (var idea in ideas) {
          LocalStorage.saveIdea(idea);
        }

        return ideas;
      });
    } catch (e) {
      // If Firebase fails, return from local storage
      return Stream.fromFuture(LocalStorage.getIdeas());
    }
  }

  Future<Idea?> getIdea(String projectId, String ideaId) async {
    final doc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('ideas')
        .doc(ideaId)
        .get();

    if (!doc.exists) return null;
    return Idea.fromMap(doc.data()!);
  }

  Future<void> createIdea(Idea idea, String projectId) async {
    try {
      final docRef = _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ideas')
          .doc(idea.id);

      await docRef.set(idea.toMap());
      await LocalStorage.saveIdea(idea);
    } catch (e) {
      // If Firebase fails, save to local storage only
      await LocalStorage.saveIdea(idea);
      throw Exception('Failed to create idea: $e');
    }
  }

  Future<void> updateIdea(Idea idea, String projectId) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ideas')
          .doc(idea.id)
          .update(idea.toMap());
      await LocalStorage.saveIdea(idea);
    } catch (e) {
      // If Firebase fails, update local storage only
      await LocalStorage.saveIdea(idea);
      throw Exception('Failed to update idea: $e');
    }
  }

  Future<void> deleteIdea(String ideaId, String projectId) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ideas')
          .doc(ideaId)
          .delete();
      // TODO: Implement local storage deletion when needed
    } catch (e) {
      throw Exception('Failed to delete idea: $e');
    }
  }

  Future<void> updateIdeaPosition(
      String projectId, String ideaId, double x, double y) async {
    await _firestore.collection('ideas').doc(ideaId).update({
      'x': x,
      'y': y,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Portfolio Analysis
  Future<void> saveToPortfolio(String projectId, String ideaId,
      Map<String, dynamic> analysisData) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ideas')
          .doc(ideaId)
          .collection('portfolio_analysis')
          .doc('latest')
          .set({
        ...analysisData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save portfolio analysis: $e');
    }
  }

  // Project operations
  Stream<List<ProjectModel>> getProjects() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return Stream.value([]);

      return _firestore
          .collection('projects')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        final projects = snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList();

        // Sync with local storage
        for (var project in projects) {
          LocalStorage.saveProject(project);
        }

        return projects;
      });
    } catch (e) {
      // If Firebase fails, return from local storage
      return Stream.fromFuture(LocalStorage.getProjects());
    }
  }

  Future<ProjectModel?> getProject(String projectId) async {
    try {
      final doc = await _firestore.collection('projects').doc(projectId).get();
      if (!doc.exists) return null;
      return ProjectModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting project: $e');
      return null;
    }
  }

  Future<void> createProject(ProjectModel project) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final docRef = _firestore.collection('projects').doc();
      final projectWithId = project.copyWith(
        id: docRef.id,
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(projectWithId.toFirestore());
      await LocalStorage.saveProject(projectWithId);
    } catch (e) {
      // If Firebase fails, save to local storage only
      await LocalStorage.saveProject(project);
      throw Exception('Failed to create project: $e');
    }
  }

  Future<void> updateProject(ProjectModel project) async {
    await _firestore
        .collection('projects')
        .doc(project.id)
        .update(project.toFirestore());
  }

  Future<void> deleteProject(String projectId) async {
    await _firestore.collection('projects').doc(projectId).delete();
  }

  // Community
  Stream<List<Idea>> getSharedIdeas() {
    return _firestore
        .collectionGroup('ideas')
        .where('isShared', isEqualTo: true)
        .orderBy('sharedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Idea.fromMap(doc.data())).toList();
    });
  }

  // Implementation Plan
  Future<Map<String, dynamic>> generateImplementationPlan(
      Map<String, dynamic> data) async {
    try {
      // TODO: Implement local implementation plan generation
      return {
        'status': 'success',
        'message': 'Implementation plan generated locally',
        'data': data
      };
    } catch (e) {
      print('Error generating implementation plan: $e');
      throw Exception('Failed to generate implementation plan');
    }
  }

  Stream<List<DocumentSnapshot>> getRecentIdeas() {
    return _firestore
        .collection('ideas')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> assignIdeaToProject(
      String ideaId, String projectId, String projectName) {
    return _firestore.collection('ideas').doc(ideaId).update({
      'projectId': projectId,
      'projectName': projectName,
    });
  }

  Stream<List<Idea>> getIdeasForProject(String projectId) {
    return _firestore
        .collection('ideas')
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          projectId: data['projectId'] ?? '',
          x: data['x']?.toDouble() ?? 0.0,
          y: data['y']?.toDouble() ?? 0.0,
          connectedIdeas: List<String>.from(data['connectedIdeas'] ?? []),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  Future<void> saveIdea(Idea idea) async {
    await _firestore.collection('ideas').doc(idea.id).set(idea.toMap());
  }

  Future<void> shareIdea(String ideaId) async {
    await _firestore.collection('ideas').doc(ideaId).update({
      'isShared': true,
      'sharedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unshareIdea(String ideaId) async {
    await _firestore.collection('ideas').doc(ideaId).update({
      'isShared': false,
      'sharedAt': null,
    });
  }

  Future<Map<String, dynamic>> exportIdeas({bool sharedOnly = false}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final QuerySnapshot snapshot;
    if (sharedOnly) {
      snapshot = await _firestore
          .collection('ideas')
          .where('userId', isEqualTo: userId)
          .where('isShared', isEqualTo: true)
          .get();
    } else {
      snapshot = await _firestore
          .collection('ideas')
          .where('userId', isEqualTo: userId)
          .get();
    }

    final ideas = snapshot.docs.map((doc) => doc.data()).toList();
    final projects = await _firestore
        .collection('projects')
        .where('userId', isEqualTo: userId)
        .get();

    return {
      'ideas': ideas,
      'projects': projects.docs.map((doc) => doc.data()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'userId': userId,
    };
  }

  // Sync local changes to Firebase
  Future<void> syncLocalChanges() async {
    try {
      final unsyncedItems = await LocalStorage.getUnsyncedItems();
      for (var item in unsyncedItems) {
        if (item.startsWith('idea_')) {
          final ideaId = item.substring(5);
          final idea = await LocalStorage.getIdea(ideaId);
          if (idea != null && idea.projectId != null) {
            await updateIdea(idea, idea.projectId!);
          }
        } else if (item.startsWith('project_')) {
          final projectId = item.substring(8);
          final project = await LocalStorage.getProject(projectId);
          if (project != null) {
            await createProject(project);
          }
        }
      }
    } catch (e) {
      print('Error syncing local changes: $e');
    }
  }
}
