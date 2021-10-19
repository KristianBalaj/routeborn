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
    final branchParam = res.value5;
    // _logger.info(
    //     'Nested router of page [${res.value2}] for branch [${res.value3}] pages stack: ${res.value4}');

    return RoutebornBranchParams(
      param: branchParam,
      child: Navigator(
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
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(PagesConfiguration<T> configuration) {
    return SynchronousFuture(null);
  }
}

/// This is used for parametrizing a nested branch.
/// The API for switching a nesting branch is by setting the branch
/// and not calling page's constructor directly.
/// Because of this there cannot be parameters passed to the Page.
///
/// This [RoutebornBranchParams] mechanism enables parametrizing
/// the nesting branch even when there are multiple pages
/// in the branch already.
class RoutebornBranchParams extends StatefulWidget {
  final Widget child;
  final Object? param;

  const RoutebornBranchParams({
    Key? key,
    required this.child,
    this.param,
  }) : super(key: key);

  /// Gets the [_RoutebornBranchParamsState] to acquire the page params.
  /// NOTICE: call this from a context in the given branch.
  static _RoutebornBranchParamsState of(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_RoutebornBranchParamsState>();

    assert(() {
      if (state == null) {
        throw NavigationStackError(
          'RoutebornBranchParamsState could not be found '
          'in the given context\'s widget tree.',
        );
      }
      return true;
    }());

    return state!;
  }

  @override
  State<StatefulWidget> createState() => _RoutebornBranchParamsState();
}

class _RoutebornBranchParamsState extends State<RoutebornBranchParams> {
  /// Get the param of the state with its given type.
  /// Throws a type error in case the passed type is incorrect.
  T? getBranchParam<T>() {
    return widget.param as T?;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
