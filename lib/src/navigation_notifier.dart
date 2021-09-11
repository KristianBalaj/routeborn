import 'dart:collection';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:routeborn/src/app_page.dart';
import 'package:routeborn/src/app_page_nodes_stack_utils.dart';
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

typedef OnUnassignNavKeyCallback = void Function(VoidCallback);

class NavigationStack {
  final UnmodifiableListView<AppPageNode> pageNodesStack;

  NavigationStack(List<AppPageNode> pageNodesStack)
      : pageNodesStack = UnmodifiableListView(pageNodesStack);

  @override
  String toString() {
    return pageNodesStack.toString();
  }

  Iterable<AppPage> activeStackFlattened() {
    return pageNodesStack.expand(
      (e) sync* {
        yield e.page;
        if (e.crossroad != null) {
          yield* e.crossroad!.activeBranchStack.activeStackFlattened();
        }
      },
    );
  }

  NavigationStack pushPage(AppPageNode page) {
    return NavigationStack([...pageNodesStack, page]);
  }

  NavigationStack replaceLastWith(AppPageNode page) {
    final res = [...pageNodesStack]
      ..removeLast()
      ..add(page);
    return NavigationStack(res);
  }

  NavigationStack replaceAllWith(List<AppPageNode> pages) {
    return NavigationStack([...pages]);
  }

  NavigationStack popPage() {
    final res = [...pageNodesStack];
    if (res.length == 1) {
      throw NavigationStackError('Cannot pop the last page');
    }
    return NavigationStack(res..removeLast());
  }
}

class NavigationCrossroad {
  /// This is used in case we want a single router covering all the branches.
  final GlobalKey<NavigatorState> navigatorKey;

  /// This is used when we want single router per branch.
  late final UnmodifiableMapView<NestingBranch, GlobalKey<NavigatorState>>
      navigatorKeys;

  /// This is the currently selected branch.
  final NestingBranch activeBranch;
  final UnmodifiableMapView<NestingBranch, NavigationStack> availableBranches;

  NavigationStack get activeBranchStack => availableBranches[activeBranch]!;

  NavigationCrossroad({
    required this.activeBranch,
    Map<NestingBranch, NavigationStack>? availableBranches,
    GlobalKey<NavigatorState>? navigatorKey,
    Map<NestingBranch, GlobalKey<NavigatorState>>? navigatorKeys,
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
  factory NavigationCrossroad.fromBranches(NestedBranches branches) {
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

  NavigationCrossroad copyWith({
    NestingBranch? activeBranch,
    Map<NestingBranch, NavigationStack>? availableBranches,
  }) {
    return NavigationCrossroad(
      navigatorKey: navigatorKey,
      navigatorKeys: navigatorKeys,
      activeBranch: activeBranch ?? this.activeBranch,
      availableBranches: availableBranches != null
          ? UnmodifiableMapView(availableBranches)
          : this.availableBranches,
    );
  }

  NavigationCrossroad copyWithActiveBranchStack(
    NavigationStack stack,
  ) {
    final res = Map<NestingBranch, NavigationStack>.from(availableBranches);
    res[activeBranch] = stack;

    return NavigationCrossroad(
      navigatorKey: navigatorKey,
      activeBranch: activeBranch,
      availableBranches: res,
    );
  }

  @override
  String toString() {
    return '{- navKey: $navigatorKey, activeBranch: $activeBranch,  availableBranches: $availableBranches -}';
  }

  NavigationCrossroad pushToActiveBranch(AppPageNode page) {
    return copyWithActiveBranchStack(activeBranchStack.pushPage(page));
  }
}

class AppPageNode {
  final AppPage page;
  final NavigationCrossroad? crossroad;

  AppPageNode({
    required this.page,
    this.crossroad,
  });

  /// Creates [AppPageNode] from [BranchInitNode] defined in routes.
  /// Creates a [NavigationCrossroad] parameter when there are any nested routes.
  factory AppPageNode.fromBranchInitNode(BranchInitNode initNode) {
    return AppPageNode(
      page: initNode.node.appPageBuilder.fold(
          (l) => throw NavigationStackError(
              'Branch initial node cannot have parametrized constructor'),
          (r) => r()),
      crossroad: initNode.node.nestedBranches == null
          ? null
          : NavigationCrossroad.fromBranches(
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
  AppPageNode copyWithNestedStack(List<AppPageNode> stack, int nestingLevel) {
    if (crossroad == null) {
      throw Exception('This app page node is not a navigation crossroad');
    }

    final activeBranch = crossroad!.activeBranchStack;
    final res =
        Map<NestingBranch, NavigationStack>.of(crossroad!.availableBranches);

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

  AppPageNode copyWith({
    AppPage? page,
    NavigationCrossroad? crossroad,
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

enum NestingBranch {
  shop,
  categories,
  cart,
  favorites,
  orders,
  account,
  help,
}

class NavigationNotifier extends ChangeNotifier {
  final GlobalKey<NavigatorState> rootNavKey;
  NavigationStack _rootPageStack;
  final Map<String, RouteNode> _routes;

  NavigationStack get rootPageNodes => _rootPageStack;

  set _rootPageNodesSetter(NavigationStack newStack) {
    try {
      final res =
          AppPageNodesStackUtil.fillMissingNestedBranches(newStack, _routes);

      _rootPageStack = res;
    } catch (err) {
      throw NavigationStackError('${err.toString()}.\n'
          'This was the stack that failed to be set: $newStack');
    }
  }

  List<AppPage> get rootPages =>
      _rootPageStack.pageNodesStack.map((e) => e.page).toList();

  NavigationNotifier(
    this._routes,
  )   : _rootPageStack = NavigationStack([]),
        rootNavKey = GlobalKey<NavigatorState>();

  /// Find the closest ancestor [AppPageNode] from the [context].
  AppPageNode? _findAncestorPageNode(BuildContext context) {
    final page = ModalRoute.of(context)!.settings;

    if (page is! AppPage) {
      throw FlutterError('Closest ancestor page is not an AppPage.\n'
          'You are probably calling the method from dialog context.');
    }

    final uniqueKeyToFind = page.uniqueKey;

    AppPageNode? _internalFind(NavigationStack stack) {
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
  Tuple4<GlobalKey<NavigatorState>, String, NestingBranch, List<AppPage>>
      findNestedNavKeyWithPages(
    BuildContext context, {

    /// Set this branch only when you want to use separate [Router] for each
    /// branch.
    /// By setting this parameter you get the navigator key
    /// for the given branch from the [NavigationCrossroad.navigatorKeys].
    /// Otherwise, the [NavigationCrossroad.navigatorKey] is used.
    NestingBranch? branch,
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

  NestingBranch getCurrentNestingBranch(
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
          navState!.widget.key!, rootPageNodes);

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
  void setCurrentNestingBranch(
    BuildContext context,
    NestingBranch branch, {
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
        (previousCrossroad) => previousCrossroad.copyWith(activeBranch: branch),
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
          (previousCrossroad) =>
              previousCrossroad.copyWith(activeBranch: branch),
        );
      }
    }

    notifyListeners();
  }

  bool isCurrentPage<T extends AppPage>() {
    return <AppPage>[..._rootPageStack.activeStackFlattened()].last is T;
  }

  bool containsPage<T extends AppPage>() {
    return <AppPage>[
      ..._rootPageStack.activeStackFlattened(),
    ].any((e) => e is T);
  }

  void pushPage(
    BuildContext context,
    AppPageNode page, {
    bool toParent = false,
  }) {
    if (toParent) {
      final navState = context.findAncestorStateOfType<NavigatorState>();
      pushPage(navState!.context, page);
    } else {
      final navState = context.findAncestorStateOfType<NavigatorState>();

      final key = navState!.widget.key;

      if (key == rootNavKey) {
        _rootPageNodesSetter = _rootPageStack.pushPage(page);
      } else {
        _rootPageNodesSetter = AppPageNodesStackUtil.updateNestedStack(
          key!,
          _rootPageStack,
          (previousCrossroad) => previousCrossroad.copyWithActiveBranchStack(
            previousCrossroad.activeBranchStack.pushPage(page),
          ),
        );
      }

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

    final key = navState!.widget.key;

    if (key == rootNavKey) {
      _rootPageNodesSetter = _rootPageStack.popPage();
    } else {
      _rootPageNodesSetter = AppPageNodesStackUtil.updateNestedStack(
        key!,
        _rootPageStack,
        (previousCrossroad) => previousCrossroad.copyWithActiveBranchStack(
          previousCrossroad.activeBranchStack.popPage(),
        ),
      );
    }

    notifyListeners();
  }

  void replaceRootStackWith(List<AppPageNode> pages) {
    _rootPageNodesSetter = _rootPageStack.replaceAllWith(pages);

    notifyListeners();
  }

  void replaceLastWith(BuildContext context, AppPageNode page) {
    final navState = context.findAncestorStateOfType<NavigatorState>();

    final key = navState!.widget.key;

    if (key == rootNavKey) {
      _rootPageNodesSetter = _rootPageStack.replaceLastWith(page);
    } else {
      _rootPageNodesSetter = AppPageNodesStackUtil.updateNestedStack(
        key!,
        _rootPageStack,
        (previousCrossroad) => previousCrossroad.copyWithActiveBranchStack(
          previousCrossroad.activeBranchStack.replaceLastWith(page),
        ),
      );
    }
    notifyListeners();
  }

  void replaceAllWith(BuildContext context, List<AppPageNode> pages) {
    final navState = context.findAncestorStateOfType<NavigatorState>();

    final key = navState!.widget.key;

    if (key == rootNavKey) {
      _rootPageNodesSetter = _rootPageStack.replaceAllWith(pages);
    } else {
      _rootPageNodesSetter = AppPageNodesStackUtil.updateNestedStack(
        key!,
        _rootPageStack,
        (previousCrossroad) => previousCrossroad.copyWithActiveBranchStack(
          previousCrossroad.activeBranchStack.replaceAllWith(pages),
        ),
      );
    }

    notifyListeners();
  }

  void reloadLast(BuildContext context) {
    throw UnimplementedError();
  }
}