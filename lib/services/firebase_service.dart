import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/portfolio_model.dart';
import '../models/mind_map_model.dart';
import '../models/idea_model.dart';
import '../models/project_model.dart';
import '../models/category.dart';
import '../models/idea.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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
  Stream<List<Idea>> getIdeas(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('ideas')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea.fromMap(data);
      }).toList();
    });
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

  Future<void> createIdea(String projectId, Idea idea) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('ideas')
        .doc(idea.id)
        .set(idea.toMap());
  }

  Future<void> updateIdea(String projectId, Idea idea) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('ideas')
        .doc(idea.id)
        .update(idea.toMap());
  }

  Future<void> deleteIdea(String projectId, String ideaId) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('ideas')
        .doc(ideaId)
        .delete();
  }

  Future<void> updateIdeaPosition(
      String projectId, String ideaId, double x, double y) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('ideas')
          .doc(ideaId)
          .update({
        'x': x,
        'y': y,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update idea position: $e');
    }
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
  Stream<List<DocumentSnapshot>> getProjects() {
    return _firestore.collection('projects').snapshots().map((snapshot) {
      return snapshot.docs;
    });
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
    await _firestore
        .collection('projects')
        .doc(project.id)
        .set(project.toFirestore());
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
      final result = await _functions
          .httpsCallable('generateImplementationPlan')
          .call(data);
      return result.data;
    } catch (e) {
      print('Error generating implementation plan: $e');
      throw Exception('Failed to generate implementation plan');
    }
  }
}
