import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/mind_map_screen.dart';
import '../screens/ai/portfolio_development_screen.dart';
import '../screens/edit_idea_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // 임시로 인증 체크 비활성화
    return null;

    // 원래 코드
    /*
    final auth = FirebaseAuth.instance;
    final isAuth = auth.currentUser != null;
    final isAuthRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/signup';

    if (!isAuth && !isAuthRoute) {
      return '/login';
    }
    if (isAuth && isAuthRoute) {
      return '/';
    }
    return null;
    */
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
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
      builder: (context, state) => MindMapScreen(
        projectId: state.pathParameters['projectId']!,
      ),
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
