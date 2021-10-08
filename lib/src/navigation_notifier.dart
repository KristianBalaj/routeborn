import 'dart:collection';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:routeborn/src/app_page_nodes_stack_utils.dart';
import 'package:routeborn/src/routeborn_page.dart';
import 'package:routeborn/src/routeborn_route_info_parser.dart';

class NavigationStackError extends Error {
  final String message;
  NavigationStackError(this.message);

  @override
  String toString() {
    return 'NavigationStackError: $message\n\n'
        'StackTrace: $stackTrace';
  }
}

class NavigationStack<T> {
  final UnmodifiableListView<AppPageNode<T>> pageNodesStack;

  NavigationStack(List<AppPageNode<T>> pageNodesStack)
      : pageNodesStack = UnmodifiableListView(pageNodesStack);

  @override
  String toString() {
    return pageNodesStack.toString();
  }

  Iterable<RoutebornPage> activeStackFlattened() {
    return pageNodesStack.expand(
      (e) sync* {
        yield e.page;
        if (e.crossroad != null) {
          yield* e.crossroad!.activeBranchStack.activeStackFlattened();
        }
      },
    );
  }

  NavigationStack<T> pushPage(AppPageNode<T> page) {
    return NavigationStack([...pageNodesStack, page]);
  }

  NavigationStack<T> replaceLastWith(AppPageNode<T> page) {
    final res = [...pageNodesStack]
      ..removeLast()
      ..add(page);
    return NavigationStack(res);
  }

  NavigationStack<T> replaceAllWith(List<AppPageNode<T>> pages) {
    return NavigationStack([...pages]);
  }

  NavigationStack<T> popPage() {
    final res = [...pageNodesStack];
    if (res.length == 1) {
      throw NavigationStackError('Cannot pop the last page');
    }
    return NavigationStack(res..removeLast());
  }

  NavigationStack<T> popUntil(bool Function(RoutebornPage) predicate) {
    final res = [...pageNodesStack];
    return NavigationStack(res.reversed
        .skipWhile((value) => !predicate(value.page))
        .toList()
        .reversed
        .toList());
  }
}

/// Generic parameter [T] is a type for annotating nested branches.
/// Most common type is an enum.
class NavigationCrossroad<T> {
  /// This is used in case we want a single router covering all the branches.
  final GlobalKey<NavigatorState> navigatorKey;

  /// This is used when we want single router per branch.
  late final UnmodifiableMapView<T, GlobalKey<NavigatorState>> navigatorKeys;

  /// This is the currently selected branch.
  final T activeBranch;
  final UnmodifiableMapView<T, NavigationStack<T>> availableBranches;

  NavigationStack<T> get activeBranchStack => availableBranches[activeBranch]!;

  NavigationCrossroad({
    required this.activeBranch,
    Map<T, NavigationStack<T>>? availableBranches,
    GlobalKey<NavigatorState>? navigatorKey,
    Map<T, GlobalKey<NavigatorState>>? navigatorKeys,
  })  : availableBranches = UnmodifiableMapView(availableBranches ?? {}),
        navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>() {
    this.navigatorKeys = UnmodifiableMapView(
      navigatorKeys != null
          ? {
              ...navigatorKeys,
              ...Map.fromEntries(this
                  .availableBranches
                  .keys
                  .toSet()
                  .difference(navigatorKeys.keys.toSet())
                  .map((e) => MapEntry(e, GlobalKey<NavigatorState>()))),
            }
          : Map.fromEntries(
              this.availableBranches.keys.map(
                    (e) => MapEntry(e, GlobalKey<NavigatorState>()),
                  ),
            ),
    );

    assert(() {
      if (!setEquals(this.navigatorKeys.keys.toSet(),
          this.availableBranches.keys.toSet())) {
        throw NavigationStackError(
            'There are missing keys for in the navigatorKeys. '
            'It has to match the same branches as in availableBranches.');
      }
      return true;
    }());
  }

  /// Create the default navigation crossroad from [NestedBranches] defined in routes.
  /// The default is that every branch stack has the first [AppPageNode] and the
  /// active branch is based on the [NestedBranches.defaultBranch].
  factory NavigationCrossroad.fromBranches(NestedBranches<T> branches) {
    return NavigationCrossroad(
      activeBranch: branches.defaultBranch,
      availableBranches: branches.branches.map(
        (key, value) => MapEntry(
          key,
          NavigationStack([AppPageNode.fromBranchInitNode(value)]),
        ),
      ),
    );
  }

  NavigationCrossroad<T> copyWith({
    T? activeBranch,
    Map<T, NavigationStack<T>>? availableBranches,

    /// Resets the stack of the given branch.
    /// Meaning it will be filled with default stack based on routes.
    bool resetBranch = false,
  }) {
    final tmp = NavigationCrossroad(
      navigatorKey: navigatorKey,
      navigatorKeys: navigatorKeys,
      activeBranch: activeBranch ?? this.activeBranch,
      availableBranches: availableBranches != null
          ? UnmodifiableMapView(availableBranches)
          : this.availableBranches,
    );

    if (resetBranch) {
      final branches = Map<T, NavigationStack<T>>.from(tmp.availableBranches);

      /// When set to empty stack, it will be automatically filled.
      branches[tmp.activeBranch] = NavigationStack([]);
      return tmp.copyWith(availableBranches: branches);
    }

    return tmp;
  }

  NavigationCrossroad<T> copyWithActiveBranchStack(
    NavigationStack<T> stack,
  ) {
    final res = Map<T, NavigationStack<T>>.from(availableBranches);
    res[activeBranch] = stack;

    return NavigationCrossroad(
      navigatorKey: navigatorKey,
      navigatorKeys: navigatorKeys,
      activeBranch: activeBranch,
      availableBranches: res,
    );
  }

  @override
  String toString() {
    return '{- navKey: $navigatorKey, activeBranch: $activeBranch,  availableBranches: $availableBranches -}';
  }

  NavigationCrossroad<T> pushToActiveBranch(AppPageNode<T> page) {
    return copyWithActiveBranchStack(activeBranchStack.pushPage(page));
  }
}

class AppPageNode<T> {
  final RoutebornPage page;
  final NavigationCrossroad<T>? crossroad;

  AppPageNode({
    required this.page,
    this.crossroad,
  });

  /// Creates [AppPageNode] from [BranchInitNode] defined in routes.
  /// Creates a [NavigationCrossroad] parameter when there are any nested routes.
  factory AppPageNode.fromBranchInitNode(BranchInitNode<T> initNode) {
    return AppPageNode(
      page: initNode.node.appPageBuilder.fold(
          (l) => throw NavigationStackError(
              'Branch initial node cannot have parametrized constructor'),
          (r) => r()),
      crossroad: initNode.node.nestedBranches == null
          ? null
          : NavigationCrossroad<T>.fromBranches(
              initNode.node.nestedBranches!,
            ),
    );
  }

  bool canPop() {
    if (crossroad != null) {
      if (crossroad!.activeBranchStack.pageNodesStack.length > 1) {
        return true;
      }
      return crossroad!.activeBranchStack.pageNodesStack.any((e) => e.canPop());
    }
    return false;
  }

  /// Replaces the active pages stack on the given nesting level.
  /// [nestingLevel] of 0 is the current node's nestedNodes active stack.
  AppPageNode<T> copyWithNestedStack(
      List<AppPageNode<T>> stack, int nestingLevel) {
    if (crossroad == null) {
      throw Exception('This app page node is not a navigation crossroad');
    }

    final activeBranch = crossroad!.activeBranchStack;
    final res = Map<T, NavigationStack<T>>.of(crossroad!.availableBranches);

    if (nestingLevel == 0) {
      res[crossroad!.activeBranch] = NavigationStack(stack);
    } else {
      res[crossroad!.activeBranch] = NavigationStack([
        ...activeBranch.pageNodesStack
            .take(res[crossroad!.activeBranch]!.pageNodesStack.length - 1),
        activeBranch.pageNodesStack.last
            .copyWithNestedStack(stack, nestingLevel - 1),
      ]);
    }

    return copyWith(crossroad: crossroad!.copyWith(availableBranches: res));
  }

  AppPageNode<T> copyWith({
    RoutebornPage? page,
    NavigationCrossroad<T>? crossroad,
  }) {
    return AppPageNode(
      page: page ?? this.page,
      crossroad: crossroad ?? this.crossroad,
    );
  }

  @override
  String toString() {
    return '(- page: $page, crossroad: $crossroad -)';
  }
}

class NavigationNotifier<T> extends ChangeNotifier {
  final GlobalKey<NavigatorState> rootNavKey;
  NavigationStack<T> _rootPageStack;
  final Map<String, RouteNode<T>> _routes;

  NavigationStack<T> get rootPageStack => _rootPageStack;

  set _rootPageNodesSetter(NavigationStack<T> newStack) {
    try {
      final res =
          AppPageNodesStackUtil.fillMissingNestedBranches(newStack, _routes);

      _rootPageStack = res;
    } catch (err) {
      throw NavigationStackError('${err.toString()}.\n'
          'This was the stack that failed to be set: $newStack');
    }
  }

  List<RoutebornPage> get rootPages =>
      _rootPageStack.pageNodesStack.map((e) => e.page).toList();

  NavigationNotifier(
    this._routes,
  )   : _rootPageStack = NavigationStack([]),
        rootNavKey = GlobalKey<NavigatorState>();

  /// Find the closest ancestor [AppPageNode] from the [context].
  AppPageNode<T>? _findAncestorPageNode(BuildContext context) {
    final page = ModalRoute.of(context)!.settings;

    if (page is! RoutebornPage) {
      throw FlutterError('Closest ancestor page is not an AppPage.\n'
          'You are probably calling the method from dialog context.');
    }

    final uniqueKeyToFind = page.uniqueKey;

    AppPageNode<T>? _internalFind(NavigationStack<T> stack) {
      for (var i = 0; i < stack.pageNodesStack.length; i++) {
        if (stack.pageNodesStack[i].page.uniqueKey == uniqueKeyToFind) {
          return stack.pageNodesStack[i];
        }

        if (stack.pageNodesStack[i].crossroad != null) {
          return stack.pageNodesStack[i].crossroad!.availableBranches.values
              .map(_internalFind)
              .singleWhere((e) => e != null, orElse: () => null);
        }
      }
    }

    return _internalFind(_rootPageStack);
  }

  /// The second return parameter is the AppPage type's name.
  /// This is purposed to be called from [NestedRouterDelegate].
  Tuple4<GlobalKey<NavigatorState>, String, T, List<RoutebornPage>>
      findNestedNavKeyWithPages(
    BuildContext context, {

    /// Set this branch only when you want to use separate [Router] for each
    /// branch.
    /// By setting this parameter you get the navigator key
    /// for the given branch from the [NavigationCrossroad.navigatorKeys].
    /// Otherwise, the [NavigationCrossroad.navigatorKey] is used.
    T? branch,
  }) {
    final node = _findAncestorPageNode(context);

    if (node == null) {
      throw NavigationStackError(
          'Could not find AppPageNode from the current route.\n'
          'Given context Route is not in the pages stack.');
    }

    if (node.crossroad == null) {
      throw NavigationStackError(
          'Ancestor AppPageNode of the context does not have '
          'a navigation crossroad.');
    }

    if (branch == null) {
      return Tuple4(
        node.crossroad!.navigatorKey,
        node.page.runtimeType.toString(),
        node.crossroad!.activeBranch,
        node.crossroad!.activeBranchStack.pageNodesStack
            .map((e) => e.page)
            .toList(),
      );
    } else {
      return Tuple4(
        node.crossroad!.navigatorKeys[branch]!,
        node.page.runtimeType.toString(),
        branch,
        node.crossroad!.availableBranches[branch]!.pageNodesStack
            .map((e) => e.page)
            .toList(),
      );
    }
  }

  T getNestingBranch(
    BuildContext context, {
    bool inChildNavigator = false,
  }) {
    if (inChildNavigator) {
      final parentPageNode = _findAncestorPageNode(context);

      if (parentPageNode == null) {
        throw NavigationStackError(
            'Could not find AppPageNode from the current route.\n'
            'Given context Route is not in the pages stack.');
      }

      if (parentPageNode.crossroad == null) {
        throw NavigationStackError(
            'The given context\'s page does not have nested navigation.\n');
      }

      return parentPageNode.crossroad!.activeBranch;
    } else {
      final navState = context.findAncestorStateOfType<NavigatorState>();

      final crossroad = AppPageNodesStackUtil.findCrossroadInActiveStackByKey(
          navState!.widget.key!, rootPageStack);

      if (crossroad == null) {
        throw NavigationStackError(
            'There is no such navigation key in the active stack');
      }

      return crossroad.activeBranch;
    }
  }

  /// Sets the active nesting branch of the closest parent crossroad.
  ///
  /// Setting [inChildNavigator] to true finds the closest child
  /// navigator (crossroad) of a page that is the closest ancestor of the [context].
  ///
  /// To reset the stack of the branch to be set,
  /// set the parameter [resetBranchStack] to [true].
  /// While reset meaning to fill the stack with the initial page.
  void setNestingBranch(
    BuildContext context,
    T branch, {
    bool inChildNavigator = false,
    bool resetBranchStack = false,
  }) {
    if (inChildNavigator) {
      final parentPageNode = _findAncestorPageNode(context);

      if (parentPageNode == null) {
        throw NavigationStackError(
            'Could not find AppPageNode from the current route.\n'
            'Given context Route is not in the pages stack.');
      }

      if (parentPageNode.crossroad == null) {
        throw NavigationStackError(
            'The given context\'s page does not have nested navigation.\n');
      }

      _rootPageNodesSetter = AppPageNodesStackUtil.updateNestedStack(
        parentPageNode.crossroad!.navigatorKey,
        _rootPageStack,
        (previousCrossroad) => previousCrossroad.copyWith(
          activeBranch: branch,
          resetBranch: resetBranchStack,
        ),
      );
    } else {
      final navState = context.findAncestorStateOfType<NavigatorState>();

      final key = navState!.widget.key;

      if (key == rootNavKey) {
        throw NavigationStackError('Cannot set branch on root navigator');
      } else {
        _rootPageNodesSetter = AppPageNodesStackUtil.updateNestedStack(
          key!,
          _rootPageStack,
          (previousCrossroad) => previousCrossroad.copyWith(
            activeBranch: branch,
            resetBranch: resetBranchStack,
          ),
        );
      }
    }

    notifyListeners();
  }

  bool isCurrentPage<E extends RoutebornPage>() {
    return <RoutebornPage>[..._rootPageStack.activeStackFlattened()].last is E;
  }

  bool containsPage<E extends RoutebornPage>() {
    return <RoutebornPage>[
      ..._rootPageStack.activeStackFlattened(),
    ].any((e) => e is E);
  }

  NavigationStack<T> _handleStackAction(
    NavigationStack<T> Function(NavigationStack<T> currentStack) action,
    Key navigatorKey,
  ) {
    if (navigatorKey == rootNavKey) {
      return action(_rootPageStack);
    } else {
      return AppPageNodesStackUtil.updateNestedStack(
        navigatorKey,
        _rootPageStack,
        (previousCrossroad) => previousCrossroad.copyWithActiveBranchStack(
            action(previousCrossroad.activeBranchStack)),
      );
    }
  }

  void pushPage(
    BuildContext context,
    AppPageNode<T> page, {
    bool toParent = false,
  }) {
    if (toParent) {
      final navState = context.findAncestorStateOfType<NavigatorState>();
      if (navState == null) {
        throw NavigationStackError(
          'There is no Navigator in the given context. '
          'Because of this a page cannot be pushed to parent navigator. '
          'You can pushPage only with parameter toParent = false',
        );
      }

      pushPage(navState.context, page);
    } else {
      final navState = context.findAncestorStateOfType<NavigatorState>();
      final key = navState?.widget.key ?? rootNavKey;

      _rootPageNodesSetter = _handleStackAction(
        (currentStack) => currentStack.pushPage(page),
        key,
      );

      notifyListeners();
    }
  }

  bool canPop() {
    if (_rootPageStack.pageNodesStack.length == 1) {
      return _rootPageStack.pageNodesStack.last.canPop();
    } else {
      return true;
    }
  }

  void popPage(BuildContext context) {
    final navState = context.findAncestorStateOfType<NavigatorState>();

    final key = navState?.widget.key ?? rootNavKey;

    _rootPageNodesSetter = _handleStackAction(
      (currentStack) => currentStack.popPage(),
      key,
    );

    notifyListeners();
  }

  void replaceRootStackWith(List<AppPageNode<T>> pages) {
    _rootPageNodesSetter = _rootPageStack.replaceAllWith(pages);

    notifyListeners();
  }

  void replaceLastWith(BuildContext context, AppPageNode<T> page) {
    final navState = context.findAncestorStateOfType<NavigatorState>();

    final key = navState?.widget.key ?? rootNavKey;

    _rootPageNodesSetter = _handleStackAction(
      (currentStack) => currentStack.replaceLastWith(page),
      key,
    );

    notifyListeners();
  }

  void replaceAllWith(
    BuildContext context,
    List<AppPageNode<T>> pages, {
    bool inChildNavigator = false,
  }) {
    if (inChildNavigator) {
      final parentPageNode = _findAncestorPageNode(context);

      if (parentPageNode == null) {
        throw NavigationStackError(
            'Could not find AppPageNode from the current route.\n'
            'Given context Route is not in the pages stack.');
      }

      if (parentPageNode.crossroad == null) {
        throw NavigationStackError(
            'The given context\'s page does not have nested navigation.\n');
      }

      _rootPageNodesSetter = AppPageNodesStackUtil.updateNestedStack(
        parentPageNode.crossroad!.navigatorKey,
        _rootPageStack,
        (previousCrossroad) =>
            previousCrossroad.copyWithActiveBranchStack(NavigationStack(pages)),
      );
    } else {
      final navState = context.findAncestorStateOfType<NavigatorState>();

      final key = navState?.widget.key ?? rootNavKey;

      _rootPageNodesSetter = _handleStackAction(
        (currentStack) => currentStack.replaceAllWith(pages),
        key,
      );
    }

    notifyListeners();
  }

  /// Pops pages from the current stack until the predicate returns [true].
  ///
  void popUntil(
    BuildContext context,
    bool Function(RoutebornPage page) predicate,
  ) {
    final navState = context.findAncestorStateOfType<NavigatorState>();

    final key = navState?.widget.key ?? rootNavKey;

    _rootPageNodesSetter = _handleStackAction(
      (currentStack) => currentStack.popUntil(predicate),
      key,
    );

    notifyListeners();
  }

  NavigationStack<T> getNavigationStack(BuildContext context) {
    final navState = context.findAncestorStateOfType<NavigatorState>();

    if (navState?.widget.key != null) {
      final crossroad = AppPageNodesStackUtil.findCrossroadInActiveStackByKey(
        navState!.widget.key!,
        _rootPageStack,
      );

      return crossroad?.activeBranchStack ?? _rootPageStack;
    } else {
      return _rootPageStack;
    }
  }
}
