import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/nfc_gate/presentation/screens/nfc_gate_screen.dart';
import '../../features/compose_share/presentation/screens/compose_share_screen.dart';
import '../../features/auto_share/presentation/screens/auto_share_screen.dart';
import '../../features/receive/presentation/screens/receive_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../constants/routes.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.compose,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.nfcGate,
        builder: (context, state) => const NfcGateScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            extendBody: true,
            body: RepaintBoundary(child: navigationShell),
            bottomNavigationBar: _FloatingGlassNavBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: const [
                _NavDestinationItem(
                  icon: Icons.wifi_tethering_outlined,
                  selectedIcon: Icons.wifi_tethering_rounded,
                  semanticLabel: 'Share',
                ),
                _NavDestinationItem(
                  icon: Icons.offline_bolt_outlined,
                  selectedIcon: Icons.offline_bolt_rounded,
                  semanticLabel: 'Auto-Share',
                ),
                _NavDestinationItem(
                  icon: Icons.inbox_outlined,
                  selectedIcon: Icons.inbox_rounded,
                  semanticLabel: 'History',
                ),
                _NavDestinationItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                  semanticLabel: 'Settings',
                ),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.compose,
                builder: (context, state) => const ComposeShareScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.autoShare,
                builder: (context, state) => const AutoShareScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.receive,
        builder: (context, state) => ReceiveScreen(
          payload: state.extra as Map<String, dynamic>?,
        ),
      ),
    ],
  );
}

class _NavDestinationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String semanticLabel;

  const _NavDestinationItem({
    required this.icon,
    required this.selectedIcon,
    required this.semanticLabel,
  });
}

class _FloatingGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_NavDestinationItem> destinations;

  const _FloatingGlassNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const double barHeight = 60.0;
    const double circleDiameter = 46.0;

    return RepaintBoundary(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 14),
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(120),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(22), // Sleek translucent glass fill
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withAlpha(35), // Fine glass border
                      width: 1.0,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tabCount = destinations.length;
                      final tabWidth = constraints.maxWidth / tabCount;
                      final topOffset = (barHeight - circleDiameter) / 2;

                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Animated Circular Glass Cover on Selected Part
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            left: selectedIndex * tabWidth + (tabWidth - circleDiameter) / 2,
                            top: topOffset,
                            width: circleDiameter,
                            height: circleDiameter,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primary.withAlpha(48),
                                border: Border.all(
                                  color: cs.primary.withAlpha(140),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withAlpha(65),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Row of Icon-Only Tabs (No background flash / tap ripple)
                          Row(
                            children: [
                              for (int i = 0; i < destinations.length; i++)
                                Expanded(
                                  child: _NavTabButton(
                                    item: destinations[i],
                                    isSelected: selectedIndex == i,
                                    activeColor: cs.primary,
                                    onTap: () {
                                      if (selectedIndex != i) {
                                        HapticFeedback.selectionClick();
                                        onDestinationSelected(i);
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabButton extends StatelessWidget {
  final _NavDestinationItem item;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavTabButton({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Colors.white.withAlpha(140);

    return Semantics(
      label: item.semanticLabel,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Center(
            child: AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 25,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

