import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/about/about_screen.dart';
import '../screens/gallery/gallery_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/liveness/liveness_screen.dart';
import '../screens/result/result_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/camera',
      builder: (context, state) => const LivenessScreen(),
    ),
    // Legacy paths redirect to the manual Capture camera flow.
    GoRoute(
      path: '/liveness',
      redirect: (context, state) => '/camera',
    ),
    GoRoute(
      path: '/document',
      redirect: (context, state) => '/camera',
    ),
    GoRoute(
      path: '/gallery',
      builder: (context, state) => const GalleryScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final json = state.extra as String? ?? '';
        return ResultScreen(json: json);
      },
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
  ],
);

void goResult(BuildContext context, String json) {
  context.pushReplacement('/result', extra: json);
}
