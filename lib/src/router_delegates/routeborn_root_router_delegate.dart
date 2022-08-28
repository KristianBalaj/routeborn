import 'package:flutter/material.dart';
import 'package:routeborn/src/navigation_notifier.dart';
import 'package:routeborn/src/pages_configuration.dart';

class RoutebornRootRouterDelegate<T>
    extends RouterDelegate<PagesConfiguration<T>>
    with
        ChangeNotifier,
        PopNavigatorRouterDelegateMixin<PagesConfiguration<T>> {
  @override
  GlobalKey<NavigatorState> navigatorKey;

  final NavigationNotifier<T> navigationNotifier;
  final List<NavigatorObserver> observers;

  @override
  PagesConfiguration<T> get currentConfiguration =>
      PagesConfiguration(pagesStack: navigationNotifier.rootPageStack);

  RoutebornRootRouterDelegate(
    this.navigationNotifier, {
    this.observers = const [],
  }) : navigatorKey = navigationNotifier.rootNavKey {
    navigationNotifier.addListener(notifyListeners);
  }

  @override
  void dispose() {
    navigationNotifier.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = navigationNotifier.rootPages;

    /// Pages are empty on the app startup. The pages stack gets
    /// initially filled with pages when the [RouteInformationParser]
    /// parses route information.
    if (pages.isEmpty) {
      return Scaffold();
    }

    // _logger.info('Root pages stack: $pages');

    return Navigator(
      observers: observers,
      key: navigatorKey,
      pages: pages,
      onPopPage: (route, dynamic result) {
        // TODO: Implement this
        // final res = navigationNotifier.popPage();
        // if (res) return route.didPop(result);
        // return false;
        // navigationNotifier.popPage();
        return false;
      },
      // transitionDelegate: NoAnimationTransitionDelegate(),
    );
  }

  @override
  Future<bool> popRoute() {
    // TODO: implement this
    // if (navigationNotifier.canPop()) {
    //   navigationNotifier.popPage();
    //   return Future.microtask(() => true);
    // } else {
    return Future.microtask(() => false);
    // }
  }

  @override
  Future<void> setNewRoutePath(PagesConfiguration<T> configuration) {
    return Future.microtask(
      () => navigationNotifier
          .replaceRootStackWith(configuration.pagesStack.pageNodesStack),
    );
  }
}
