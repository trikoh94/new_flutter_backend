import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/mind_map_screen.dart';
import '../screens/ai/portfolio_development_screen.dart';
import '../screens/edit_idea_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/ideas_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/quick_idea_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final auth = FirebaseAuth.instance;
    final isAuth = auth.currentUser != null;
    final isAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    final isPublicRoute = state.matchedLocation == '/' ||
        state.matchedLocation.startsWith('/assets') ||
        state.matchedLocation == '/manifest.json' ||
        state.matchedLocation.startsWith('/icons') ||
        state.matchedLocation.startsWith('/fonts') ||
        state.matchedLocation.startsWith('/images') ||
        state.matchedLocation.contains('.js') ||
        state.matchedLocation.contains('.css') ||
        state.matchedLocation.contains('.html');

    // 공개 경로는 인증 없이 접근 가능
    if (isPublicRoute) {
      return null;
    }

    // 인증이 필요한 경로에 대한 처리
    if (!isAuth && !isAuthRoute) {
      return '/login';
    }
    if (isAuth && isAuthRoute) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/projects',
      builder: (context, state) => const ProjectsScreen(),
    ),
    GoRoute(
      path: '/projects/:projectId',
      builder: (context, state) => IdeasScreen(
        projectId: state.pathParameters['projectId']!,
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/mind-map/:projectId',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'];
        if (projectId == null || projectId.isEmpty) {
          return const Center(child: Text('Invalid Project ID'));
        }
        return MindMapScreen(projectId: projectId);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/quick-idea',
      builder: (context, state) => const QuickIdeaScreen(),
    ),
    GoRoute(
      path: '/ai/portfolio/:projectId',
      builder: (context, state) => PortfolioDevelopmentScreen(
        projectId: state.pathParameters['projectId']!,
      ),
    ),
    GoRoute(
      path: '/edit-idea/:projectId/:ideaId',
      builder: (context, state) => EditIdeaScreen(
        projectId: state.pathParameters['projectId']!,
        ideaId: state.pathParameters['ideaId']!,
      ),
    ),
  ],
);
