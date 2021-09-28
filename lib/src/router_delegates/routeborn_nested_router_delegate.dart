import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:routeborn/src/navigation_notifier.dart';
import 'package:routeborn/src/pages_configuration.dart';

class RoutebornNestedRouterDelegate<T>
    extends RouterDelegate<PagesConfiguration<T>>
    with
        ChangeNotifier,
        PopNavigatorRouterDelegateMixin<PagesConfiguration<T>> {
  @override
  GlobalKey<NavigatorState>? navigatorKey;

  final NavigationNotifier<T> navigationNotifier;
  final List<NavigatorObserver> observers;

  /// This is used in case this [RoutebornNestedRouterDelegate] displays only
  /// one branch of [NavigationCrossroad].
  ///
  /// It is used to select correct [navigatorKey]
  /// from the [NavigationCrossroad.navigatorKeys].
  final T? branch;

  RoutebornNestedRouterDelegate(
    this.navigationNotifier, {
    this.observers = const [],
    this.branch,
  }) {
    navigationNotifier.addListener(notifyListeners);
  }

  @override
  void dispose() {
    navigationNotifier.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = navigationNotifier.findNestedNavKeyWithPages(
      context,
      branch: branch,
    );

    navigatorKey = res.value1;
    // _logger.info(
    //     'Nested router of page [${res.value2}] for branch [${res.value3}] pages stack: ${res.value4}');

    return Navigator(
      key: navigatorKey,
      pages: res.value4,
      onPopPage: (route, dynamic result) {
        // TODO: implement this
        // if(navigationNotifier.canPop()) {
        //
        // }
        // navigationNotifier.popPage();
        return false;
      },
      // transitionDelegate: NoAnimationTransitionDelegate(),
    );
  }

  @override
  Future<void> setNewRoutePath(PagesConfiguration<T> configuration) {
    return SynchronousFuture(null);
  }
}
